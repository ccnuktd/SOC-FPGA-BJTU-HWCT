#***************************************************************************************
# Copyright (c) 2014-2024 Zihao Yu, Nanjing University
#
# NEMU is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#          http://license.coscl.org.cn/MulanPSL2
#
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
#
# See the Mulan PSL v2 for more details.
#**************************************************************************************/

REPO_PATH = repo

CAPSTONE = $(REPO_PATH)/libcapstone.so.5
$(CAPSTONE):
	@if [ ! -f $(REPO_PATH)/include/capstone/capstone.h ]; then \
		git clone --depth=1 -b 5.0.3 git@github.com:capstone-engine/capstone.git $(REPO_PATH); \
	fi
	cd $(REPO_PATH) && CAPSTONE_ARCHS="x86|mips|riscv|loongarch" bash make.sh

clean:
	@if [ -d $(REPO_PATH) ]; then $(MAKE) -C $(REPO_PATH) clean; fi

all: $(CAPSTONE)
.DEFAULT_GOAL = all

.PHONY: all clean
