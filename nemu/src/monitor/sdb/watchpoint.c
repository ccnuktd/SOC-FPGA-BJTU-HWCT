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
//#include"/home/fisher/tmp_mpi_work/threadpool/src/threadpool.h"
#include "sdb.h"
/*watch points pool size*/
#define NR_WP 32

typedef struct watchpoint
{
  bool used;
  int NO;
  struct watchpoint *next;
  char *exprs;
  uint32_t num; /*the value of theprevious instruction expression*/
} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;
//static threadpool_t* watch_pool = NULL;

void init_wp_pool()
{
  int i;
  for (i = 0; i < NR_WP; i++)
  {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    wp_pool[i].used = false;
  }

  head = NULL;
  free_ = wp_pool;

  //  watch_pool = threadpool_create(8, NR_WP, 0);
  //   if (watch_pool == NULL) {
  //       fprintf(stderr, "Failed to create threadpool.\n");
  //       exit(EXIT_FAILURE);
  //   }

}

WP *new_wp(char *args,bool* expr_success)
{
  /*check whether expr is legal*/
  expr(args,expr_success);
  if(expr_success==false){
    printf("creat watching points error expr is illrgal\n");
    return NULL;
  }
  int len = strlen(args);
  WP *p = NULL;
  if (free_ != NULL)
  {
    p = free_;
    p->exprs = (char *)malloc(len * sizeof(char)+1);
    p->num = expr(args,expr_success);
    free_ = free_->next;
    memcpy(p->exprs, args, len * sizeof(char)+1);
    p->used = true;    
    return p;
  }
  else
    return 0;
}
void free_wp(WP *wp)
{
  if(wp==head){
head=head->next;
  }
  else{
  WP* pre_p=NULL;
  WP* p=head;
  while(p!=wp){
    pre_p=p;
    p=p->next;
  }
  
  pre_p->next=p->next;
}

  wp->used = false; 
  wp->next = free_;
  free_ = wp;
}

int add_wp(char *args)
{
  bool success=false;
  WP *p = new_wp(args,&success);
  if(p==NULL){
    if(success)
    Log("please delete a points that you can add new watching points");
    return 0;
  }
  WP* mid=head;
  head=p;
  p->next=mid;
  return 1;
}

void display_wp()
{
  if(head==NULL)
  Log("no watching points");
  WP *p = head;
  while (p != NULL)
  {
    printf("NO.%d\texpr:%s\tvalue:%d\n", p->NO, p->exprs, p->num);
    p = p->next;
  }
}
void delete_wp(int no)
{
  if (wp_pool[no].used == false)
  {
    Log("no that watchpoints,please input correct watchpoint's index");
    return;
  }
  else
  {
    free_wp(&wp_pool[no]);
    return;
  }
}

int check_watch_points()
{
  bool success=false;
  WP* p=head;
  while(p!=NULL){
    int n_val=expr(p->exprs,&success);
    if(p->num!=n_val){
      p->num=n_val;
    return 0;
    }
    assert(p!=NULL);
    p=p->next;
  }
  return 1;
}

#ifdef CONFIG_PARALLEL_WP
static pthread_mutex_t task_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t task_cond = PTHREAD_COND_INITIALIZER;
static pthread_cond_t change_cond = PTHREAD_COND_INITIALIZER;
static int pending_tasks = 0;
static bool watch_point_changed = false;
 
void check_watch_point(void* arg) {
    WP* wp = (WP*)arg;
    bool success = false;
    int n_val = expr(wp->exprs, &success);   

    pthread_mutex_lock(&task_mutex);

    if (wp->num != n_val) {
        wp->num = n_val;
        watch_point_changed = true;
        pthread_cond_signal(&change_cond);  // 通知主线程监视点发生变化
    }

    pending_tasks--;
    if (pending_tasks == 0) {
        pthread_cond_signal(&task_cond);  // 通知主线程所有任务完成
    }

    pthread_mutex_unlock(&task_mutex);
}

// 使用线程池并行检查所有监视点
int check_watch_points_parallel() {
    WP* p = head;
    pthread_mutex_lock(&task_mutex);
    pending_tasks = 0;
    watch_point_changed = false;
    pthread_mutex_unlock(&task_mutex);

    // 添加任务到线程池
    while (p != NULL) {
        pthread_mutex_lock(&task_mutex);
        pending_tasks++;
        pthread_mutex_unlock(&task_mutex);

        if (threadpool_add(watch_pool, check_watch_point, (void*)p, 0) != 0) {
            fprintf(stderr, "Failed to add task to threadpool.\n");
            return -1;  // 添加任务失败
        }
        p = p->next;
    }

    // 等待监视点发生变化或所有任务完成
    pthread_mutex_lock(&task_mutex);
    while (pending_tasks > 0 && !watch_point_changed) {
        pthread_cond_wait(&task_cond, &task_mutex);
    }

    int result;
    if (watch_point_changed) {
        result = 0;
    } else {
        result = 1;
    }

    pthread_mutex_unlock(&task_mutex);

    // 等待所有任务完成（如果还有未完成的任务）
    if (pending_tasks > 0) {
        pthread_mutex_lock(&task_mutex);
        while (pending_tasks > 0) {
            pthread_cond_wait(&task_cond, &task_mutex);
        }
        pthread_mutex_unlock(&task_mutex);
    }

    return result;
}
#endif
/* TODO: Implement the functionality of watchpoint */
