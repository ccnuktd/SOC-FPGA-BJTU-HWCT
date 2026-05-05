typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;

typedef struct platform_abi_t
{
   uint64_t (*get_cycle_value)(void);
   uint32_t (*get_frequency)(void);
   void (*myprintf)(const char* fmt, ...);
} platform_abi_t;

// PLATFORM 在0x80001000
#define ABI_PTR_ADDR ((platform_abi_t*)0x80001000)

#include "crc.h"
#include "fsm.h"
#include "matrix.h"
#include "prime.h"
#include "sort.h"

Matrix A, B, C1, C2;
int arr1[ARR_LEN];
int arr2[ARR_LEN];

void __attribute__((section(".abi_jump"))) _jump()
{
    ABI_PTR_ADDR->myprintf("sort program start!\n");
    for (int i = 0; i < 5; i ++) {
        init_array(arr1, ARR_LEN, i);
        for (int j = 0; j < ARR_LEN; j ++) arr2[j] = arr1[j];

        sort_insertion(arr1, ARR_LEN);
        sort_selection(arr2, ARR_LEN);

        if (!array_equal(arr1, arr2, ARR_LEN)) {
            ABI_PTR_ADDR->myprintf("sort program failed!\n");
            return;
        }
    }

    ABI_PTR_ADDR->myprintf("prime program start!\n");
    if (!validate_prime_calculation()) {
        ABI_PTR_ADDR->myprintf("prime program failed!\n");
        return;
    }

    ABI_PTR_ADDR->myprintf("crc program start!\n");
    if (!run_crc_test()) {
        ABI_PTR_ADDR->myprintf("crc program failed!\n");
        return;
    }

    ABI_PTR_ADDR->myprintf("matrix program start!\n");
    for (int i = 0; i < 5; i ++) {
        init_matrix(A, i);
        init_matrix(B, 2 * i);

        matmul_naive(A, B, C1);
        matmul_transpose(A, B, C2);

        if (!verify(C1, C2)) {
            ABI_PTR_ADDR->myprintf("matrix program failed!\n");
            return;
        }
    }
    
    ABI_PTR_ADDR->myprintf("fsm program start!\n");
    if (!run_fsm_test()) {
        ABI_PTR_ADDR->myprintf("fsm program failed!\n");
        return;
    }

    ABI_PTR_ADDR->myprintf("Hello from test code!\n");

    uint64_t start = ABI_PTR_ADDR->get_cycle_value();
    ABI_PTR_ADDR->myprintf("tick: %ld\n", start);

    for (int i = 0; i < 10; i++) {
        ABI_PTR_ADDR->myprintf("Test round %d\n", i);
        __asm__ volatile("ecall");
        ABI_PTR_ADDR->myprintf("ecall round %d\n", i);
    }

    uint64_t end = ABI_PTR_ADDR->get_cycle_value();
    uint32_t freq = ABI_PTR_ADDR->get_frequency();
    ABI_PTR_ADDR->myprintf("tick: %ld\n", end);

    ABI_PTR_ADDR->myprintf("tick: %ld\n", end - start);
    ABI_PTR_ADDR->myprintf("second: %ld\n", (end - start) / freq);
}