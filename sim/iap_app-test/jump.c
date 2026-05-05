typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;

typedef struct platform_abi_t
{
   uint64_t (*get_cycle_value)(void);
   uint32_t (*get_frequency)(void);
   void (*myprintf)(const char* fmt, ...);
} platform_abi_t;

// PLATFORM abi struct in 0x80001000
#define ABI_PTR_ADDR ((platform_abi_t*)0x80001000)

void __attribute__((section(".abi_jump"))) _jump()
{
    ABI_PTR_ADDR->myprintf("start\n");
    
    uint32_t freq = ABI_PTR_ADDR->get_frequency();
    ABI_PTR_ADDR->myprintf("cpu freq: %ld\n", freq);

    uint64_t start = ABI_PTR_ADDR->get_cycle_value();
    ABI_PTR_ADDR->myprintf("tick: %ld\n", start);

    for (int i = 0; i < 10; i++) {
        ABI_PTR_ADDR->myprintf("Test round %d\n", i);
    }

    uint64_t end = ABI_PTR_ADDR->get_cycle_value();
    

    ABI_PTR_ADDR->myprintf("tick: %ld\n", end - start);
    ABI_PTR_ADDR->myprintf("second: %ld\n", (end - start) / freq);
    ABI_PTR_ADDR->myprintf("finished\n");
}