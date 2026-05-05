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
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"
#include <memory/paddr.h>
#include <cpu/cpu.h>

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char *rl_gets()
{
  static char *line_read = NULL;

  if (line_read)
  {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read)
  {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args)
{
  cpu_exec(-1);
  return 0;
}

static int cmd_q(char *args)
{
  nemu_state.state = NEMU_QUIT;
  return -1;
}

static int cmd_si(char *args)
{
  if (args == NULL)
  {
    cpu_exec(1);
    return 0;
  }
  else
  {
    int step = atoi(args);
    if (step == 0)
    {
      printf("please input crate command like 'si 2'\n");
    }
    else
      cpu_exec(atoi(args));
    return 0;
  }
}

static int cmd_info(char *args)
{

  if (strcmp(args, "r") == 0)
  {
    isa_reg_display();
    return 0;
  }
  if (strcmp(args, "w") == 0)
  {
    display_wp();
    return 0;
  }
  printf("unknow option: '%s' please input 'r' or 'w'\n", args);
  return 0;
}

static int cmd_x(char *args)
{
  // x n address
  // char *endptr;
  int n = atoi(strtok(args, " "));
  // paddr_t add = (paddr_t)strtol(strtok(NULL, " "), &endptr, 16);
  bool success = false;
  paddr_t add = (paddr_t)expr(strtok(NULL, " "), &success);
  for (int i = 0; i < n; i++)
  {
    printf("%#X:0X%08X\n", add + i * 4, paddr_read(add + i * 4, 4));
  }
  return 0;
}

static int cmd_p(char *args)
{
  bool succese;
  int result = 0;
  result = expr(args, &succese);
  if (succese)
    printf("0x%08X\n", result);
  return 0;
}

static int cmd_w(char *args)
{
  // bool succese;
  //  int result=expr(args, &succese);
  add_wp(args);
  return 0;
}

static int cmd_d(char *args)
{
  delete_wp(atoi(args));
  return 0;
}

static int cmd_help(char *args);

static struct
{
  const char *name;
  const char *description;
  int (*handler)(char *);
} cmd_table[] = {
    {"help", "Display information about all supported commands", cmd_help},
    {"c", "Continue the execution of the program", cmd_c},
    {"q", "Exit NEMU", cmd_q},
    {"info", "Display register information", cmd_info},
    {"x", "Displays 'n' machine word lengths after the address 'expr'", cmd_x},
    {"si", "If the number of steps is default, the default value is 1", cmd_si},
    {"p", "Find the value of the expression EXPR", cmd_p},
    {"w", "seting a watching points like: w 'expr'", cmd_w},
    {"d", "delete the watching point like d 'no.'", cmd_d}

    /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args)
{
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL)
  {
    /* no argument given */
    for (i = 0; i < NR_CMD; i++)
    {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else
  {
    for (i = 0; i < NR_CMD; i++)
    {
      if (strcmp(arg, cmd_table[i].name) == 0)
      {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode()
{
  is_batch_mode = true;
}

void sdb_mainloop()
{
#ifdef CONFIG_TEST_EXPR
  FILE *fp = fopen("tools/gen-expr/build/input", "r");
  assert(fp != NULL);
  int32_t result;
  int32_t expr_res;
  char exp[512] = {};
  bool su = false;
  while (fscanf(fp, "%u", &result) == 1)
  { // 先读取整数结果
    // 使用fgets读取剩余的行作为表达式
    if (fgets(exp, sizeof(exp), fp) != NULL)
    {
      // 移除换行符（如果有的话）
      exp[strcspn(exp, "\n")] = '\0';
      // printf("%u %s\n", result, exp);
      expr_res = expr(exp, &su); // 假设expr函数用于计算表达式
      if (su)
      {
        assert(result == expr_res);
        printf("expected result: %u true result: %u\n", result, expr_res);
      }
      else
      {
        assert(0);
      }
    }
  }
#endif

  if (is_batch_mode)
  {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL;)
  {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL)
    {
      continue;
    }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end)
    {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i++)
    {
      if (strcmp(cmd, cmd_table[i].name) == 0)
      {
        if (cmd_table[i].handler(args) < 0)
        {
          return;
        }
        break;
      }
    }

    if (i == NR_CMD)
    {
      printf("Unknown command '%s'\n", cmd);
    }
  }
}

void init_sdb()
{
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
