/***************************************************************************************
 * Copyright (c) 2014-2024 Zihao Yu, Nanjing University
 *
 * NEMU is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 *
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
 * EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
 * MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 *
 * See the Mulan PSL v2 for more details.
 ***************************************************************************************/

#include <isa.h>

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>
#include <memory/paddr.h>
/*binocular_operator*/
#define is_binocular_operator(i) ((tokens[i].type == TK_ADD) ||     \
                                  (tokens[i].type == TK_DIV) ||     \
                                  (tokens[i].type == TK_MUL) ||     \
                                  (tokens[i].type == TK_SUB) ||     \
                                  (tokens[i].type == TK_EQ) ||      \
                                  (tokens[i].type == TK_EQORLGT) || \
                                  (tokens[i].type == TK_EQORLST) || \
                                  (tokens[i].type == TK_LGAND) ||   \
                                  (tokens[i].type == TK_LGOR) ||    \
                                  (tokens[i].type == TK_LGXOR) ||   \
                                  (tokens[i].type == TK_NEQ))

#define tokens_len 64
enum
{
  TK_NOTYPE = 256,
  TK_EQ,
  TK_REGS_NAME,
  TK_SUB,
  TK_MUL,
  TK_LPAREN,
  TK_RPAREN,
  TK_DIV,
  TK_NUMBER,
  TK_HEX,
  TK_ADD,
  TK_DEREF,
  TK_MINUS,
  TK_EQORLGT,
  TK_EQORLST,
  TK_LGAND,
  TK_LGOR,
  TK_LGXOR,
  TK_NEQ

  /* TODO: Add more token types */

};

static struct rule
{
  const char *regex;
  int token_type;
} rules[] = {

    /* TODO: Add more rules.
     * Pay attention to the precedence level of different rules.
     */
    {"!=", TK_NEQ},                                                               // not equ
    {"\\|\\|", TK_LGOR},                                                          // logic or must like: ()||()    {"&&",TK_LGAND},
    {"&&", TK_LGAND},                                                             // logic and
    {"\\^", TK_LGXOR},                                                            // logic xor
    {">=", TK_EQORLGT},                                                           // equl or large then
    {"<=", TK_EQORLST},                                                           // equl or less then
    {" +", TK_NOTYPE},                                                            // spaces
    {"\\+", TK_ADD},                                                              // plus
    {"==", TK_EQ},                                                                // equal
    {"\\-", TK_SUB},                                                              // minus
    {"\\*", TK_MUL},                                                              // multiply
    {"/", TK_DIV},                                                                // divide
    {"\\(", TK_LPAREN},                                                           // left parenthesis
    {"\\)", TK_RPAREN},                                                           // right parenthesis
    {"0[xX][0-9a-fA-F]+", TK_HEX},                                                // HEX number,begin with 0X or 0x
    {"[0-9]+", TK_NUMBER},                                                        // number
    {"(\\$0|ra|sp|gp|tp|pc|t[0-9]|t[0-9]|s[0-9]|s[1][0-1]|a[0-7])", TK_REGS_NAME} // register name index
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex()
{
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i++)
  {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0)
    {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token
{
  int type;
  char str[tokens_len];
} Token;

static Token tokens[tokens_len] __attribute__((used)) = {};
static int nr_token __attribute__((used)) = 0;

void match_success(char *substr_start, int substr_len, int rules_index)
{
  tokens[nr_token].type = rules[rules_index].token_type;
  memcpy(tokens[nr_token].str, substr_start, substr_len);
  nr_token++;
}

static bool make_token(char *e)
{
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0')
  {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i++)
    {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0)
      {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        // Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
        //     i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */
        assert(substr_len < tokens_len);
        assert(substr_start != NULL);
        assert(nr_token < ARRLEN(tokens));
        switch (rules[i].token_type)
        {
        case (TK_NUMBER):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_ADD):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_SUB):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_DIV):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_MUL):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_LPAREN):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_RPAREN):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_REGS_NAME):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_HEX):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_LGAND):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_LGOR):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_LGXOR):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_EQ):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_EQORLGT):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_EQORLST):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_NEQ):
          match_success(substr_start, substr_len, i);
          break;
        case (TK_NOTYPE):
          break;
        default:
          assert(0);
        }

        break;
      }
    }

    if (i == NR_REGEX)
    {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }
  // printf("nr_token:>%d<\n", nr_token);
  return true;
}

bool check_parentheses(int p, int q)
{
  int i = p + 1;
  int paren_match = 0;
  if (i == q)
    return false;
  else
  {
    while (i < q)
    {
      if ((tokens[p].type != TK_LPAREN) || (tokens[q].type != TK_RPAREN))
        return false;
      else
      {
        if (paren_match < 0)
          return false;
        if (tokens[i].type == TK_LPAREN)
          paren_match++;
        if (tokens[i].type == TK_RPAREN)
          paren_match--;
      }
      i++;
    }
    if (paren_match == 0)
      return true;
    else
      return false;
  }
}

/*search for binocular operators*/
/*
int find_main_operator(int p, int q)
{
  int op = 0;
  int paren_match = 0;
  int i = p;
  while (i <= q)
  {
    if (paren_match == 0 && is_binocular_operator(i))
      op = i;
    if (tokens[i].type == TK_LPAREN)
      paren_match++;
    if (tokens[i].type == TK_RPAREN)
      paren_match--;
    i++;
  }
  return op;
}
*/
int find_main_operator(int p, int q)
{
    int main_op = 0;
    int max_priority = 0;
    int paren_match = 0;
    int i = p;

    while (i <= q)
    {
        if (paren_match == 0 && is_binocular_operator(i))
        {
            int current_priority = 0;
            if (tokens[i].type == TK_ADD || tokens[i].type == TK_SUB)
                current_priority = 3;
            else if (tokens[i].type == TK_MUL || tokens[i].type == TK_DIV)
                current_priority = 2;
            else if (tokens[i].type == TK_LGAND || tokens[i].type == TK_LGOR || tokens[i].type == TK_LGXOR)
                current_priority = 1;

            if (current_priority > max_priority || (current_priority == max_priority && tokens[i].type != TK_MUL && tokens[i].type != TK_DIV))
            {
                max_priority = current_priority;
                main_op = i;
            }
        }

        if (tokens[i].type == TK_LPAREN)
            paren_match++;
        else if (tokens[i].type == TK_RPAREN)
            paren_match--;

        i++;
    }
    // printf("main_op; %d\n",main_op);
    return main_op;
}

int eval(int p, int q)
{
  int op = 0; /*the position of main operator*/
  int op_type = 0;
  if (p > q)
  {
    /* Bad expression */
    // printf("p:%d-q:%d\n", p, q);
    assert(0);
  }
  else if (p == q)
  {
    /* Single token.
     * For now this token should be a number or a regsiter.
     * Return the value of the number.
     */
    // printf("p:%d-q:%d\n", p, q);
    if (tokens[p].type == TK_NUMBER)
      return atoi(tokens[p].str);
    if (tokens[p].type == TK_REGS_NAME)
    {
      bool success = true;
      int result = 0;
      if (strcmp(tokens[p].str, "pc")==0)
      {
        return cpu.pc;
      }
      else
      {
        result = isa_reg_str2val(tokens[p].str, &success);
        if (success)
        {
          return result;
        }
        else
          assert(0);
      }
    }
    if (tokens[p].type == TK_HEX)
    {
      char *endptr;
      return strtol(tokens[p].str, &endptr, 0);
    }
    return -1;
  }
  else if (check_parentheses(p, q) == true)
  {
    /* The expression is surrounded by a matched pair of parentheses.
     * If that is the case, just throw away the parentheses.
     */
    // printf("()p:%d-q:%d\n", p, q);
    return eval(p + 1, q - 1);
  }
  /*find main operator*/
  else
  {
    // printf("main:p:%d-q:%d\n", p, q);
    op = find_main_operator(p, q);
    if (op == 0)
    {
      op_type = tokens[p].type;
      op = p;
    }
    else
    {
      op_type = tokens[op].type;
    }
    /*the code above dosen't know what's wrong, but it works well for now*/
    // printf("op:%d\n", op);
    // check out whether op_type is monocular
    if (op_type == TK_DEREF || op_type == TK_MINUS)
    {
      // printf("-\n");
      int val3 = eval(op + 1, q);
      switch (op_type)
      {
      case TK_DEREF:
        /*address legal test is default(multiple of four)*/
        return (int)paddr_read(val3, 4);
        break;
      case TK_MINUS:
        return -val3;
        break;
      default:
        assert(0);
      }
    }
    else
    {
      int val1 = eval(p, op - 1);
      int val2 = eval(op + 1, q);

      switch (op_type)
      {
      case TK_ADD:
        return val1 + val2;
      case TK_SUB:
        return val1 - val2;
      case TK_MUL:
        return val1 * val2;
      case TK_DIV:
        return val1 / val2;
      case TK_EQ:
        return (val1 == val2);
      case TK_EQORLGT:
        return (val1 >= val2);
      case TK_EQORLST:
        return (val1 <= val2);
      case TK_LGAND:
        return (val1 && val2);
      case TK_LGOR:
        return (val1 || val2);
      case TK_LGXOR:
        return (val1 ^ val2);
      case TK_NEQ:
        return (val1 != val2);
      default:
        assert(0);
      }
    }
  }
}

word_t expr(char *e, bool *success)
{
  if (!make_token(e))
  {
    *success = false;
    return 0;
  }
  else
  {
    *success = true;
    for (int i = 0; i < nr_token - 1; i++)
    {
      if (tokens[i].type == TK_MUL && (i == 0 || is_binocular_operator(i - 1)))
      {
        tokens[i].type = TK_DEREF;
        // printf("!\n");
      }
      if (tokens[i].type == TK_SUB && (i == 0 || is_binocular_operator(i - 1)))
      {
        tokens[i].type = TK_MINUS;
        // printf("!\n");
      }
    }

    return eval(0, nr_token - 1);
  }
}
