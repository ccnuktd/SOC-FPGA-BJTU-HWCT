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
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>
#include <npc_difftest.h>

static uint32_t *img;
static uint32_t img_size;
static int load_bin_to_img(const char *bin_path)
{
  FILE *file = NULL;
  size_t file_size, num_words;
  uint8_t *buffer = NULL;

  // 打开二进制文件
  file = fopen(bin_path, "rb");
  if (!file)
  {
    fprintf(stderr, "Error: Cannot open file %s\n", bin_path);
    return -1;
  }

  // 获取文件大小
  fseek(file, 0, SEEK_END);
  file_size = ftell(file);
  fseek(file, 0, SEEK_SET);
  // in test movsx file's size mod 2,too strange -_-
  //  检查文件大小是否为 4 的倍数（每个 uint32_t 需要 4 字节）
  //  if (file_size % 4 != 0) {
  //      fprintf(stderr, "Error: File size (%zu bytes) is not a multiple of 4\n", file_size);
  //      fclose(file);
  //      return -1;
  //  }

  // 计算 uint32_t 数组的大小
  num_words = file_size / 4;

  // 分配临时缓冲区读取文件内容
  buffer = (uint8_t *)malloc(file_size);
  if (!buffer)
  {
    fprintf(stderr, "Error: Memory allocation failed for buffer\n");
    fclose(file);
    return -1;
  }

  // 读取文件内容
  if (fread(buffer, 1, file_size, file) != file_size)
  {
    fprintf(stderr, "Error: Failed to read file %s\n", bin_path);
    free(buffer);
    fclose(file);
    return -1;
  }
  fclose(file);

  // 分配 img 数组
  img = (uint32_t *)malloc(num_words * sizeof(uint32_t));
  if (!img)
  {
    fprintf(stderr, "Error: Memory allocation failed for img array\n");
    free(buffer);
    return -1;
  }

  // 将字节转换为 uint32_t（假设 little-endian）
  for (size_t i = 0; i < num_words; i++)
  {
    img[i] = (uint32_t)buffer[i * 4] |
             (uint32_t)buffer[i * 4 + 1] << 8 |
             (uint32_t)buffer[i * 4 + 2] << 16 |
             (uint32_t)buffer[i * 4 + 3] << 24;
  }

  // 更新全局静态数组
  img_size = num_words;

  // 释放临时缓冲区
  free(buffer);

  printf("Successfully loaded %zu words from %s into img array\n", num_words, bin_path);
  memcpy(guest_to_host(RESET_VECTOR), img, img_size * sizeof(uint32_t));
  free(img);
  return 0;
}

__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction)
{
  assert(0);
}

__EXPORT void difftest_regcpy(void *dut, bool direction)
{
  if (direction == DIFFTEST_TO_REF)
  {
    for (int i = 0; i < 32; i++)
    {
      cpu.gpr[i] = ((NPC_STATUS *)dut)->reg_file[i];
    }
    return;
  }
  else if (direction == DIFFTEST_TO_DUT)
  {
    for (int i = 0; i < 32; i++)
    {
      ((NPC_STATUS *)dut)->reg_file[i] = cpu.gpr[i];
    }
    ((NPC_STATUS *)dut)->pc = cpu.pc;
    return;
  }
  else
    assert(0);
}

__EXPORT void difftest_exec(uint64_t n)
{
  cpu_exec(n);
}

__EXPORT void difftest_raise_intr(word_t NO)
{
  assert(0);
}

__EXPORT void difftest_init(int port, const char *bin_path)
{
  void init_mem();
  init_mem();
  /* Perform ISA dependent initialization. */
  init_isa();
  assert(0 == load_bin_to_img(bin_path));
}
