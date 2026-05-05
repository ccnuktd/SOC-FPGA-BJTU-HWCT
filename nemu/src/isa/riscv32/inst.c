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

#include "local-include/reg.h"
#include <cpu/cpu.h>
#include <cpu/ifetch.h>
#include <cpu/decode.h>

#define Reg(i) gpr(i)

 static inline word_t CSR_read(int csr_code) {
  switch (csr_code)
  {
  case MTVEC_CSR:
    return csr_pr(MTVEC_IDX);
  case MEPC_CSR:
    return csr_pr(MEPC_IDX);
  case MSTATUS_CSR:
    return csr_pr(MSTATUS_IDX);
  case MCAUSE_CSR:
    return csr_pr(MCAUSE_IDX);
  case MSCRATCH_CSR:
    return csr_pr(MSCRATCH_IDX);
  case MIE_CSR:
    return csr_pr(MIE_IDX);
  case MIP_CSR:
    return csr_pr(MIP_IDX);
  case MTVAL_CSR:
    return csr_pr(MTVAL_IDX);
  case CYCLE_CSR:
    return (word_t)(cpu.cycle & 0xFFFFFFFF);
  case CYCLEH_CSR:
    return (word_t)((cpu.cycle >> 32) & 0xFFFFFFFF);
  default:
  return -1;
    break;
  }
}

static inline void CSR_write(int csr_code,word_t data){
  switch (csr_code)
  {
  case MTVEC_CSR:
    csr_pr(MTVEC_IDX)=data;
    break;
  case MEPC_CSR:
    csr_pr(MEPC_IDX)=data;
    break;
  case MSTATUS_CSR:
    csr_pr(MSTATUS_IDX)=data;
    break;
  case MCAUSE_CSR:
   csr_pr(MCAUSE_IDX)=data;
   break;
  case MSCRATCH_CSR:
  csr_pr(MSCRATCH_IDX)=data;
  break;
  case MIE_CSR:
    csr_pr(MIE_IDX)=data;
    break;
  case MIP_CSR:
    csr_pr(MIP_IDX)=data;
    break;
  case MTVAL_CSR:
    csr_pr(MTVAL_IDX)=data;
    break;
  default:
    break;
  }
}
#define Mr vaddr_read
#define Mw vaddr_write

enum {
  TYPE_I, TYPE_U, TYPE_S,
  TYPE_N, TYPE_J,TYPE_R,
  TYPE_B,TYPE_IS,TYPE_M,
  TYPE_CSR
};
static word_t shamt_num=0;
static word_t csr_value=0;
static word_t csr=0;
static int64_t mul_num=0;
#define src1R() do { *src1 = Reg(rs1); } while (0)
#define src2R() do { *src2 = Reg(rs2); } while (0)
#define immI() do { *imm = SEXT(BITS(i, 31, 20), 12); } while(0)
#define immU() do { *imm = SEXT(BITS(i, 31, 12), 20) << 12; } while(0)
#define immS() do { *imm = (SEXT(BITS(i, 31, 25), 7) << 5) | BITS(i, 11, 7); } while(0)
#define immJ() do { *imm = (SEXT(BITS(i,31,31),1)<<20 | BITS(i,19,12)<<12 | BITS(i,20,20)<<11| BITS(i,30,21)<<1);}while(0)
#define immB() do { *imm = SEXT(BITS(i,31,31),1)<<12| BITS(i,7,7)<<11 | BITS(i,30,25)<<5 | BITS(i,11,8)<<1;}while (0)
#define get_shamt() do { shamt_num = BITS(i,24,20); }while(0)
#define csrR() do { csr_value = CSR_read(BITS(i, 31, 20)); csr=BITS(i, 31, 20);}while(0)
static void decode_operand(Decode *s, int *rd, word_t *src1, word_t *src2, word_t *imm, int type) {
  uint32_t i = s->isa.inst;
  int rs1 = BITS(i, 19, 15);
  int rs2 = BITS(i, 24, 20);
  *rd     = BITS(i, 11, 7);
  switch (type) {
    case TYPE_I: src1R();          immI(); break;
    case TYPE_U:                   immU(); break;
    case TYPE_S: src1R(); src2R(); immS(); break;
    case TYPE_N: break;
    case TYPE_J: immJ();break;
    case TYPE_R: src1R(); src2R();break;
    case TYPE_B: src1R(); src2R(); immB(); break;
    case TYPE_IS: get_shamt(); src1R(); break;
    case TYPE_CSR: src1R(); csrR(); *imm = rs1; break;
    default: panic("unsupported type = %d", type);
  }
}

static int decode_exec(Decode *s) {
  s->dnpc = s->snpc;

#define INSTPAT_INST(s) ((s)->isa.inst)
#define INSTPAT_MATCH(s, name, type, ... /* execute body */ ) { \
  int rd = 0; \
  word_t src1 = 0, src2 = 0, imm = 0;\
  decode_operand(s, &rd, &src1, &src2, &imm, concat(TYPE_, type)); \
  __VA_ARGS__ ; \
}

  INSTPAT_START();
  /*U_TYPE*/
  INSTPAT("??????? ????? ????? ??? ????? 01101 11", lui    , U, Reg(rd) = imm);
  INSTPAT("??????? ????? ????? ??? ????? 00101 11", auipc  , U, Reg(rd) = s->pc + imm);
  /*B_TYPE*/
  INSTPAT("??????? ????? ????? 000 ????? 11000 11", beq    , B, s->dnpc=(src1==src2)? s->pc + imm : s->pc + 4);
  INSTPAT("??????? ????? ????? 001 ????? 11000 11", bne    , B, s->dnpc=(src1!=src2)? s->pc + imm : s->pc + 4);
  INSTPAT("??????? ????? ????? 100 ????? 11000 11", blt    , B, s->dnpc=((signed)src1<(signed)src2) ?  s->pc + imm : s->pc + 4);
  INSTPAT("??????? ????? ????? 101 ????? 11000 11", bge    , B, s->dnpc=((signed)src1>=(signed)src2)? s->pc + imm : s->pc + 4);
  INSTPAT("??????? ????? ????? 110 ????? 11000 11", bltu   , B, s->dnpc=(((unsigned int)src1)<((unsigned int)src2))? s->pc+imm : s->pc+4);
  INSTPAT("??????? ????? ????? 111 ????? 11000 11", bgeu   , B, s->dnpc=(((unsigned int)src1)>=((unsigned int)src2))? s->pc+imm : s->pc+4);
  
  /*S_TYPE*/
  INSTPAT("??????? ????? ????? 000 ????? 01000 11", sb     , S, Mw(src1 + imm, 1, src2));
  INSTPAT("??????? ????? ????? 010 ????? 01000 11", sw     , S, Mw(src1 + imm, 4, src2));
  INSTPAT("??????? ????? ????? 001 ????? 01000 11", sh     , S, Mw(src1 + imm, 2, src2));
  /*J_TYPE*/
  INSTPAT("??????? ????? ????? ??? ????? 11011 11", jal    , J, Reg(rd) = s->pc +4;
                                                              s->dnpc=(s->pc)+imm);
  /*I_TYPE*/
  INSTPAT("??????? ????? ????? 000 ????? 11001 11", jalr   , I, Reg(rd) = s->pc +4;
                                                              s->dnpc=src1+imm);
  /*ebreak*/
  INSTPAT("0000000 00001 00000 000 00000 11100 11", ebreak , N, NEMUTRAP(s->pc, Reg(10))); // Reg(10) is $a0
  INSTPAT("0000000 00000 00000 000 00000 11100 11", ecall  , N, CSR_write(MEPC_CSR,s->pc);
                                                                CSR_write(MCAUSE_CSR,11);
                                                                CSR_write(MSTATUS_CSR,0x1800);
                                                                #ifdef CONFIG_ETRACE
                                                                printf("exception in pc:0x%08X\n",s->pc);
                                                                #endif
                                                                s->dnpc=CSR_read(MTVEC_CSR));
  /*csr instruction*/
  INSTPAT("??????? ????? ????? 001 ????? 11100 11", csrrw  , CSR, CSR_write(csr,src1); Reg(rd)=csr_value);
  INSTPAT("??????? ????? ????? 010 ????? 11100 11", csrrs  , CSR, Reg(rd)=csr_value;CSR_write(csr,csr_value | src1));
  INSTPAT("??????? ????? ????? 011 ????? 11100 11", csrrc  , CSR, Reg(rd)=csr_value;CSR_write(csr,csr_value & ~src1));
  INSTPAT("??????? ????? ????? 101 ????? 11100 11", csrrwi , CSR, CSR_write(csr,imm); Reg(rd)=csr_value);
  INSTPAT("??????? ????? ????? 110 ????? 11100 11", csrrsi , CSR, Reg(rd)=csr_value;CSR_write(csr,csr_value | imm));
  INSTPAT("??????? ????? ????? 111 ????? 11100 11", csrrci , CSR, Reg(rd)=csr_value;CSR_write(csr,csr_value & ~imm));
  INSTPAT("0011000 00010 00000 000 00000 11100 11", mret   , N, s->dnpc=CSR_read(MEPC_CSR);
                                                                /* Restore MIE from MPIE, set MPIE=1, MPP=11 (machine mode) */
                                                                /* 0x1888 = 0b0001100010001000: MIE=1, MPIE=1, MPP=11 */
                                                                CSR_write(MSTATUS_CSR,0x1888));

  INSTPAT("??????? ????? ????? 000 ????? 00100 11", addi   , I, Reg(rd) = src1+imm);
  INSTPAT("??????? ????? ????? 010 ????? 00100 11", slti   , I, Reg(rd) = ((signed)src1<(signed)imm) ? 1 : 0);
  INSTPAT("??????? ????? ????? 011 ????? 00100 11", sltiu  , I, Reg(rd) = ((unsigned int)src1<(unsigned int)imm) ? 1 : 0);
  INSTPAT("??????? ????? ????? 100 ????? 00100 11", xori   , I, Reg(rd) = src1 ^ imm);
  INSTPAT("??????? ????? ????? 110 ????? 00100 11", ori    , I, Reg(rd) = src1 | imm);
  INSTPAT("??????? ????? ????? 111 ????? 00100 11", andi   , I, Reg(rd) = src1 & imm);
  INSTPAT("0000000 ????? ????? 001 ????? 00100 11", slli   , IS,Reg(rd) = src1 << shamt_num);
  INSTPAT("0000000 ????? ????? 101 ????? 00100 11", srli   , IS,Reg(rd) = (unsigned int)src1 >> shamt_num);
  INSTPAT("0100000 ????? ????? 101 ????? 00100 11", srai   , IS,Reg(rd) = (signed)src1 >> shamt_num);

  INSTPAT("??????? ????? ????? 000 ????? 00000 11", lb     , I, Reg(rd) = SEXT(Mr(src1 + imm, 1),8));
  INSTPAT("??????? ????? ????? 001 ????? 00000 11", lh     , I, Reg(rd) = SEXT(Mr(src1 + imm, 2),16));
  INSTPAT("??????? ????? ????? 010 ????? 00000 11", lw     , I, Reg(rd) = Mr(src1 + imm, 4));
  INSTPAT("??????? ????? ????? 100 ????? 00000 11", lbu    , I, Reg(rd) = BITS(Mr(src1 + imm, 1),7,0));
  INSTPAT("??????? ????? ????? 101 ????? 00000 11", lhu    , I, Reg(rd) = BITS(Mr(src1 + imm, 2),15,0));
  
  /*R_TYPE*/
  INSTPAT("0000000 ????? ????? 000 ????? 01100 11", add    , R, Reg(rd) =  src1+src2);
  INSTPAT("0100000 ????? ????? 000 ????? 01100 11", sub    , R, Reg(rd) =  src1-src2);
  INSTPAT("0000000 ????? ????? 001 ????? 01100 11", sll    , R, Reg(rd) =  src1<<BITS(src2,4,0));
  INSTPAT("0000000 ????? ????? 010 ????? 01100 11", slt    , R, Reg(rd) = ((signed)src1 < (signed)src2) ? 1 : 0);
  INSTPAT("0000000 ????? ????? 011 ????? 01100 11", sltu   , R, Reg(rd) = ((unsigned int)src1 <(unsigned int)src2) ? 1 : 0);
  INSTPAT("0000000 ????? ????? 100 ????? 01100 11", xor    , R, Reg(rd) = src1 ^ src2);
  INSTPAT("0000000 ????? ????? 101 ????? 01100 11", srl    , R, Reg(rd) = (unsigned int)src1 >> BITS(src2,4,0));
  INSTPAT("0100000 ????? ????? 101 ????? 01100 11", sra    , R, Reg(rd) = (signed)src1 >> BITS(src2,4,0));
  INSTPAT("0000000 ????? ????? 110 ????? 01100 11", or     , R, Reg(rd) = src1 | src2);
  INSTPAT("0000000 ????? ????? 111 ????? 01100 11", and    , R, Reg(rd) = src1 & src2);

  /*M_EXTEND R_TYPE*/
  INSTPAT("0000001 ????? ????? 000 ????? 01100 11", mul    , R, mul_num = (signed)src1*(signed)src2; Reg(rd) = BITS(mul_num,31,0));
  INSTPAT("0000001 ????? ????? 001 ????? 01100 11", mulh   , R, mul_num = (int64_t)((signed)src1)*((signed)src2); Reg(rd) = BITS(mul_num, 63,32));
  INSTPAT("0000001 ????? ????? 010 ????? 01100 11", mulhsu , R, mul_num = (int64_t)(int32_t)src1 * (uint64_t)src2; Reg(rd) = BITS(mul_num, 63,32));
  INSTPAT("0000001 ????? ????? 011 ????? 01100 11", mulhu  , R, mul_num = (uint64_t)src1 * (uint64_t)src2; Reg(rd) = BITS(mul_num, 63,32));
  INSTPAT("0000001 ????? ????? 100 ????? 01100 11", _div_  , R, if(src2==0){
                                                                  Reg(rd)=-1;
                                                                  }
                                                                  else if((signed)src1==-2147483648 && (signed)src2==-1){
                                                                    Reg(rd)=-2147483648;
                                                                  }else{
                                                                    Reg(rd)=(signed)src1/(signed)src2;
                                                                  });
  INSTPAT("0000001 ????? ????? 101 ????? 01100 11", divu   , R, if(src2==0){
                                                                  Reg(rd)=(unsigned)src1;
                                                                  }else{
                                                                  Reg(rd)=(unsigned)src1/src2;  
                                                                  });
  INSTPAT("0000001 ????? ????? 110 ????? 01100 11", rem    , R, if(src2==0){
                                                                  Reg(rd)=src1;
                                                                  }else if((signed)src1==-2147483648 && (signed)src2==-1){
                                                                    Reg(rd)=0;
                                                                  }else{
                                                                    Reg(rd)=(signed)src1 % (signed)src2;
                                                                  });
  INSTPAT("0000001 ????? ????? 111 ????? 01100 11", remu    , R, if(src2==0){
                                                                  Reg(rd)=src1;
                                                                  }else if((unsigned)src1==-2147483648 && (unsigned)src2==-1){
                                                                    Reg(rd)=0;
                                                                  }else{
                                                                    Reg(rd)=(unsigned)src1 % (unsigned)src2;
                                                                  });                                                                  
  INSTPAT("??????? ????? ????? ??? ????? ????? ??", inv    , N, INV(s->pc));
  INSTPAT_END();

  Reg(0) = 0; // reset $zero to 0

  return 0;
}

int isa_exec_once(Decode *s) {
  s->isa.inst = inst_fetch(&s->snpc, 4);
  return decode_exec(s);
}
