/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 * 2025-5-30      ketted       first version
 */

#ifndef __ABI_H__
#define __ABI_H__

#include "__def.h"

typedef struct platform_abi_t
{
   uint64_t (*get_cycle_value) ();
   uint32_t (*get_frequency) ();
   void (*myprintf) (const char* str, ...);

} platform_abi_t;


#endif //#ifndef __ABI_H__
 