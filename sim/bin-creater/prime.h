#ifndef __PRIME_H__
#define __PRIME_H__

#define PRIME_SIZE 3000
int prime_table[PRIME_SIZE + 5];

int is_prime(int num) {
    if (num <= 1) return 0;
    for (int i = 2; i * i <= num; i++)
        if (num % i == 0) return 0;
    return 1;
}

int validate_prime_calculation() {
    int sum = 0, count = 0;

    for (int i = 2; i <= PRIME_SIZE; i++)
        if (is_prime(i)) count++;

    for (int i = 0; i <= PRIME_SIZE; i++) prime_table[i] = 1;
    prime_table[2] = 0;
    for (int i = 2; i <= PRIME_SIZE; i++)
        if (prime_table[i]) {
            sum++;
            for (int j = i * 2; j <= PRIME_SIZE; j += i)
                prime_table[j] = 0;
        }
    return sum == count;
}

#endif