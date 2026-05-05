#include<elf.h>
#include<common.h>


#define TYPE_FUNC_IN  0x000000EF // jal ra,***
#define TYPE_FUNC_JALR_A5 0x000780e7
#define TYPE_FUNC_JALR_A4 0x000700e7
#define TYPE_FUNC_RET 0x00008067 //jalr x0, 0(x1) 

void init_ftrace(char* elf_file_name);
void check_addr(uint32_t pre_addr, uint32_t addr, uint32_t inst);

typedef struct symtab_func{
	int start;
	int end;
	char name[128];
	int in;
}symtab_func;