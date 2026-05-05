#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>
#include <limits.h> // Include limits.h for INT_MAX and INT_MIN

#define MAX_BUF_LEN 65536
static char buf[MAX_BUF_LEN] = {};
static char code_buf[MAX_BUF_LEN + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  int result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";

enum { ADD, SUB, MUL, DIV, op_num };
int tk_num = 0;
int buf_index = 0;

void gen_num() {
    buf[buf_index] = ('1' + rand() % 9);
    buf_index++;
    for (int i = 0; i < 1; i++) {
        buf[buf_index] = ('0' + rand() % 10);
        buf_index++;
    }
}

void gen(char c) {
    buf[buf_index] = c;
    buf_index++;
}

void gen_rand_op() {
    int op_index = rand() % op_num;
    switch (op_index) {
        case ADD: buf[buf_index] = '+'; break;
        case SUB: buf[buf_index] = '-'; break;
        case MUL: buf[buf_index] = '*'; break;
        case DIV: buf[buf_index] = '/'; break;
        default: break;
    }
    buf_index++;
}

int choose(int i) {
    return rand() % i;
}

// Function to generate a non-zero value for the right operand of division
void gen_non_zero_num() {
    buf[buf_index] = ('1' + rand() % 9); // Ensure the first digit is not zero
    buf_index++;
    for (int i = 0; i < 1; i++) {
        buf[buf_index] = ('0' + rand() % 10);
        buf_index++;
    }
}
void gen_divisor_num() {
    // Ensure the first digit is between 4 and 9 to make the number greater than 0.3
    buf[buf_index] = ('4' + rand() % 6);
    buf_index++;
    for (int i = 0; i < 1; i++) {
        buf[buf_index] = ('0' + rand() % 10);
        buf_index++;
    }
}

void gen_rand_expr(int i, int allow_zero) {
    if (tk_num >= 29) {
        i = 0;
    }
    switch (i) {
        case 0:
            if (allow_zero) {
                gen_num(); // Can generate zero if allowed
            } else {
                gen_non_zero_num(); // Generate non-zero if not allowed
            }
            break;
        case 1:
            tk_num = tk_num + 3;
            gen('(');
            gen_rand_expr(choose(3), 1); // Allow zero in sub-expressions for parentheses case
            gen(')');
            break;
        default:
            tk_num = tk_num + 2;
            int ago_index=buf_index;
            gen(' ');
            gen_rand_expr(choose(3), 1); // Allow zero in left sub-expression
            gen_rand_op();
            // Check if the current operator is division
            if ( (buf[buf_index - 1] == '/') | buf[buf_index - 1] == '*') {
                // For division, right sub-expression must not be zero
                buf[ago_index]='(';
                if  (buf[buf_index - 1] == '/'){
                gen_divisor_num();
                }
                else{
                gen_rand_expr(choose(3), 1);
                }
                gen(')');
            } else {
                // For other operators, allow zero in right sub-expression
                gen_rand_expr(choose(3), 1);
            }
            break;
    }
}


int main(int argc, char *argv[]) {
    int seed = time(0);
    srand(seed);
    int loop = 1;
    if (argc > 1) {
        sscanf(argv[1], "%d", &loop);
    }
    int i;
    for (i = 0; i < loop; i++) {
        gen_rand_expr(1, 1); // Start with allowing zero
        buf[buf_index] = '\0'; // Null-terminate the buffer properly
        sprintf(code_buf, code_format, buf);

        FILE *fp = fopen("/tmp/.code.c", "w");
        assert(fp != NULL);
        fputs(code_buf, fp);
        fclose(fp);

        int ret = system("gcc /tmp/.code.c -o /tmp/.expr");
        if (ret != 0) continue;

        fp = popen("/tmp/.expr", "r");
        if (fp == NULL) continue;

        int result;
        ret = fscanf(fp, "%u", &result);
        pclose(fp);

        // Check for overflow (result should be <= UINT_MAX)
        if (result > UINT_MAX) {
            // Skip this expression if result overflows
            continue;
        }

        printf("%u %s\n", result, buf);
        buf_index = 0;
        tk_num = 0;
        memset(buf, 0, sizeof(buf));
    }
    return 0;
}