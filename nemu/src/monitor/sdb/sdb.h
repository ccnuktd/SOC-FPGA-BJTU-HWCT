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

#ifndef __SDB_H__
#define __SDB_H__

#include <common.h>

#ifdef CONFIG_PARALLEL_WP
#include <unistd.h>
#include <pthread.h>
int check_watch_points_parallel();
#endif
#ifndef CONFIG_PARALLEL_WP
int check_watch_points(); /*no change return 1,changed return 0*/
#endif

word_t expr(char *e, bool *success);
void init_wp_pool();
int add_wp(char* args);
void display_wp();//show the watchpoints exist
void delete_wp(int no);//delete the watchpoints that use number index
#endif
