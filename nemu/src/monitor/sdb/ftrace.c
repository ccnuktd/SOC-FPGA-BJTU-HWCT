#include <ftrace.h>

static symtab_func *func_list = NULL;
static int func_num = 0;

void init_ftrace(char *elf_file_name)
{
    #ifdef CONFIG_FTRACE
    FILE *elf_file = fopen(elf_file_name, "rb");
    assert(elf_file!=NULL);
    Elf32_Ehdr ehdr;
    // check out is elf file
    assert(1 == fread(&ehdr, sizeof(Elf32_Ehdr), 1, elf_file));
    char elf_flags[4]={'\0'};
    memcpy(elf_flags, (char *)ehdr.e_ident + 1, 3);
    if (strcmp(elf_flags, "ELF") != 0)
    {
        assert(0);
    }
    fseek(elf_file, ehdr.e_shoff, SEEK_SET);
    // find the symbol table and load its points
    Elf32_Shdr shdrs[ehdr.e_shnum];
    Elf32_Shdr *symtab_shdr = NULL;
    // load all the section header
    assert(ehdr.e_shnum == fread(shdrs, sizeof(Elf32_Shdr), ehdr.e_shnum, elf_file));
    for (int i = 0; i < ehdr.e_shnum; i++)
    {
        if (shdrs[i].sh_type == SHT_SYMTAB)
        {
            symtab_shdr = &shdrs[i];
            break;
        }
    }
    // load all the symbol table
    long int symtab_num = symtab_shdr->sh_size / sizeof(Elf32_Sym);
    Elf32_Sym *symtab = (Elf32_Sym *)malloc(symtab_shdr->sh_size);
    fseek(elf_file, symtab_shdr->sh_offset, SEEK_SET);
    assert(symtab_num == fread(symtab, sizeof(Elf32_Sym), symtab_num, elf_file));
    // leach the type function
    for (int i = 0; i < symtab_num; i++)
    {
        if (ELF32_ST_TYPE(symtab[i].st_info) == STT_FUNC)
        {
            func_num++;
        }
    }
    printf("symtab_num:%ld\n",symtab_num);
    func_list = (symtab_func *)malloc(sizeof(symtab_func) * func_num);
    func_num = 0;
    // load all of the string table
    char *strtab = NULL;
    if (symtab_shdr->sh_link < ehdr.e_shnum)
    {
        fseek(elf_file, shdrs[symtab_shdr->sh_link].sh_offset, SEEK_SET);
        strtab = (char *)malloc(shdrs[symtab_shdr->sh_link].sh_size);
        assert(shdrs[symtab_shdr->sh_link].sh_size == fread(strtab, 1, shdrs[symtab_shdr->sh_link].sh_size, elf_file));
    }

    for (int i = 0; i < symtab_num; i++)
    {
        if (ELF32_ST_TYPE(symtab[i].st_info) == STT_FUNC)
        {   
            func_list[func_num].start = symtab[i].st_value;
            func_list[func_num].end = symtab[i].st_value + symtab[i].st_size;
            func_list[func_num].in = 0;
            strcpy(func_list[func_num].name, strtab + symtab[i].st_name);
            //printf("%s\n",func_list[func_num].name);
            func_num++;
        }
    }
    #endif
}

void check_addr(uint32_t pre_addr, uint32_t addr, uint32_t inst)
{
    // addr is next circle's addr
    static int blank = 0;
    for (int i = 0; i < func_num; i++)
    {
        //stdander risc-v function call mode
        // if ((inst & 0xfff) == TYPE_FUNC_IN ||
        //     inst==TYPE_FUNC_JALR_A5 ||
        //     inst==TYPE_FUNC_JALR_A4)
        //this will be used in systemcall table like: systemcall[256](int x,char* s) 
        if (addr == func_list[i].start)
        {
            for (int i = 0; i < blank; i++)
            {
                printf(" ");
            }
            printf("call [%s@0x%08X]\n", func_list[i].name, addr);
            blank++;
            func_list[i].in++;
        }
        else if ((pre_addr > func_list[i].start) && (pre_addr <= func_list[i].end) && ((inst) == (uint32_t)TYPE_FUNC_RET))
        {
            for (int i = 1; i < blank; i++)
            {
                printf(" ");
            }
            printf("ret  [%s@0x%08X]\n", func_list[i].name, addr);
            blank--;
        }
    }
    pre_addr = addr;
}