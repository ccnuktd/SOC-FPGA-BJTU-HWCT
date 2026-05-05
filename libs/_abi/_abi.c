/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 * 2025-5-30      ketted       first version
 */

#include "_abi.h"

platform_abi_t PLATFORM;
extern uint64_t get_cycle_value();
extern void xprintf(const char* fmt, ...);
uint32_t get_frequency() {
    return CPU_FREQ_HZ;
}

platform_abi_t PLATFORM __attribute__((section(".abi_section"))) = {
    .get_cycle_value = get_cycle_value,
    .get_frequency   = get_frequency,
    .myprintf        = xprintf
};