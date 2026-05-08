# Lab 3: CLINT 测试说明

本实验测试 `pa_core_clint` 的异常和中断控制逻辑。测试参考 `diff-tools/sim_tools_simple` 中的 `tb_clint.v` 和 `tb_interrupt_matrix.v`，重点检查 CLINT 是否能在正确时机写 CSR、请求流水线 hold，并输出正确跳转地址。

CLINT 不是简单地“看到中断就立刻跳转”。外部中断可能发生在普通指令、访存、多周期运算或控制流指令附近，CLINT 需要等到合适的控制流边界，再保存正确的 `mepc` 并进入 trap。

## 运行

```bash
make all
make wave
make clean
```

`make all` 会编译并运行测试。`make wave` 会生成 `clint.vcd`，并用 `clint.gtkw` 打开 GTKWave。`make clean` 清理仿真产物。

## 信号含义

测试台主要观察这些信号：

- `inst_set_i`: 当前指令是否属于 RV32I 指令集合
- `inst_func_i`: 指令功能码，本实验中用于区分 `ecall`、`ebreak`、`mret`
- `pc_i`: 当前 EX 阶段 PC
- `csr_mtvec_i`: trap 入口地址
- `csr_mepc_i`: `mret` 返回地址
- `csr_mstatus_i`: 机器状态寄存器，`csr_mstatus_i[3]` 是全局中断使能 `MIE`
- `irq_i`: 外部中断请求
- `jump_flag_i` / `jump_addr_i`: 后级确认的控制流边界和目标地址
- `hold_flag_i`: 表示前面还有未完成副作用，CLINT 需要等待
- `csr_waddr_o` / `csr_wdata_o`: CLINT 要写入的 CSR 地址和值
- `hold_flag_o`: CLINT 请求暂停流水线
- `jump_flag_o` / `jump_addr_o`: CLINT 请求跳转到 trap 入口或 `mepc`

## 测试内容

### 1. Reset Idle Outputs

复位后，CLINT 不应发起任何操作。

期望行为：

- `csr_waddr_vld_o = 0`
- `hold_flag_o = 0`
- `jump_flag_o = 0`

如果这里失败，通常说明状态机复位不完整，或者输出默认值没有处理好。

### 2. Interrupt Waits for Completed Jump

测试先产生 `irq_i`，但暂时不给 `jump_flag_i`。随后检查 CLINT 不应提前写 CSR。等到 `jump_flag_i=1` 且 `jump_addr_i=32'h8000_0738` 后，CLINT 才进入 trap。

期望行为：

- 中断先进入 pending 状态
- 在控制流边界出现前不写 CSR
- 出现 `jump_flag_i` 后，`mepc` 写入 `jump_addr_i`
- `mstatus` 写入关中断后的值 `32'h0000_1880`
- `mcause` 写入 `32'h8000_0003`
- 最后跳转到 `mtvec`

这个测试说明：中断保存的不是随便一个当前 PC，而是后级确认的目标 PC。

### 3. ECALL Exception

测试设置 `inst_func_i=3'b100`，模拟 `ecall`。

期望行为：

- CLINT 识别 `ecall`
- `mepc` 写入 `pc_i - 8`
- `mstatus` 写入关中断后的值
- `mcause` 写入 `32'h0000_000b`
- 最后跳转到 `mtvec`

这里使用 `pc_i - 8` 是为了匹配当前流水线中 EX 阶段传入 PC 的约定。

### 4. EBREAK Exception

测试设置 `inst_func_i=3'b010`，模拟 `ebreak`。

期望行为：

- CLINT 识别 `ebreak`
- `mepc` 写入 `pc_i - 8`
- `mstatus` 写入关中断后的值
- `mcause` 写入 `32'h0000_0003`
- 最后跳转到 `mtvec`

如果 ecall 通过但 ebreak 失败，优先检查 `inst_func_i` 的位译码。

### 5. MRET Return

测试设置 `inst_func_i=3'b001`，模拟 `mret`。

期望行为：

- CLINT 写回恢复后的 `mstatus`
- `jump_flag_o=1`
- `jump_addr_o=csr_mepc_i`

这个测试检查从 trap 返回普通程序的路径。

### 6. IRQ Masked When MIE=0

测试把 `csr_mstatus_i[3]` 置 0，再产生 `irq_i` 和后续 `jump_flag_i`。

期望行为：

- CLINT 不进入 trap
- 不写 CSR
- 不发出 hold 或 jump

如果这里失败，说明全局中断使能判断没有正确接入。

### 7. Pending IRQ Until Control-Flow Boundary

测试多种“中断先到，但控制流边界稍后才到”的情况：

- 普通 ALU 指令附近
- load/store busy
- 多周期 div/rem busy
- branch-not-taken，直到后续 taken 边界

期望行为：

- `irq_i` 来时先记录 pending
- `hold_flag_i=1` 或没有 `jump_flag_i` 时，不应提前写 CSR
- 后续 `jump_flag_i` 出现后，保存对应 `jump_addr_i`
- 之后按 `mepc`、`mstatus`、`mcause` 的顺序写 CSR，并跳转 `mtvec`

### 8. Immediate Control-Flow Boundary

测试中断后马上遇到 branch taken、jal、jalr 这类控制流边界。

期望行为：

- CLINT 保存对应目标 PC 到 `mepc`
- 不丢失中断
- 不把旧 PC 错写进 `mepc`

### 9. Jump Waits for Older Side Effect

测试 `jump_flag_i` 已经出现，但 `hold_flag_i=1` 表示前面还有旧副作用没处理完。

期望行为：

- CLINT 继续等待
- 等 `hold_flag_i` 变 0 后再进入 trap
- 保存之前捕获到的 `jump_addr_i`

这个测试能发现“太早进入 trap，导致旧指令副作用丢失”的问题。

## 失败时看什么

终端会打印当前指令功能码、PC、中断输入、跳转握手、CSR 写地址和写数据。每个失败项也会打印期望 CSR/跳转和值。调试时优先在波形中查看：

- `inst_func_i` 到 `ecall` / `ebreak` / `mret` 的译码
- `irq_i` 与 `csr_mstatus_i[3]` 的中断使能关系
- `jump_flag_i` / `jump_addr_i` 是否被正确捕获
- `hold_flag_i` 拉高时是否阻止 trap 提前进入
- `csr_waddr_o` 是否按 `mepc`、`mstatus`、`mcause` 顺序输出
- `csr_wdata_o` 是否写入了正确的 PC、状态值和 cause
- `jump_flag_o` / `jump_addr_o` 是否在处理结束时跳到 `mtvec` 或 `mepc`

常见错误：

- IRQ 一来就直接进入 trap，没有等待 `jump_flag_i`
- `mepc` 保存了错误 PC
- ecall/ebreak 的 cause 写反
- `mstatus` 保存和恢复位处理错误
- `hold_flag_i=1` 时仍然写 CSR
- `MIE=0` 时仍然响应中断
