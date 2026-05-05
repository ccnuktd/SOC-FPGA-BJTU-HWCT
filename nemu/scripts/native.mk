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

-include $(NEMU_HOME)/../Makefile
include $(NEMU_HOME)/scripts/build.mk

include $(NEMU_HOME)/tools/difftest.mk

compile_git:
	$(call git_commit, "compile NEMU")
$(BINARY):: compile_git

# Some convenient rules

override ARGS ?= --log=$(BUILD_DIR)/nemu-log.txt
override ARGS += $(ARGS_DIFF)

# Command to execute NEMU
IMG ?=
NEMU_EXEC := $(BINARY) $(ARGS) $(IMG)
NEMU_TEST := $(BINARY)  -b -f /home/fisher/2025work/sim_tools/sim/$(ALL)/riscv.elf /home/fisher/2025work/sim_tools/sim/$(ALL)/riscv.bin
run_test: run-env
	$(NEMU_TEST)

# Auto-detect binary and elf files from SIM_PATH
ifneq ($(SIM_PATH),)
  IMG_DETECTED = $(SIM_PATH)/riscv.bin
  ELF_DETECTED = $(SIM_PATH)/riscv.elf
  NEMU_AUTO := $(BINARY)  -f $(ELF_DETECTED) $(IMG_DETECTED) $(ARGS)
  
  run_auto: $(BINARY) $(DIFF_REF_SO)
	@echo "Running with SIM_PATH=$(SIM_PATH)"
	@echo "Binary: $(IMG_DETECTED)"
	@echo "Elf: $(ELF_DETECTED)"
	$(NEMU_AUTO)
endif
	
run-env: $(BINARY) $(DIFF_REF_SO)

run: run-env
	$(call git_commit, "run NEMU")
	$(info $(NEMU_EXEC))
	$(NEMU_EXEC)

gdb: run-env
	$(call git_commit, "gdb NEMU")
	gdb -s $(BINARY) --args $(NEMU_EXEC)

clean-tools = $(dir $(shell find ./tools -maxdepth 2 -mindepth 2 -name "Makefile"))
$(clean-tools):
	-@$(MAKE) -s -C $@ clean
clean-tools: $(clean-tools)
clean-all: clean distclean clean-tools

.PHONY: run gdb run-env clean-tools clean-all $(clean-tools)
