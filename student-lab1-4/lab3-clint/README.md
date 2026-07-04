# Lab 3: CLINT 测试说明

本实验测试 `pa_core_clint` 的异常和中断控制逻辑。测试台会模拟处理器执行 `ecall`、`ebreak`、`mret`，以及外部中断到来的情况，检查 CLINT 是否能按顺序写入 CSR、请求流水线暂停，并输出正确的跳转地址。

CLINT 负责连接处理器流水线、CSR 和 trap 处理流程。异常发生时，它需要保存异常返回地址和原因；中断发生时，它需要在合适的时机进入 trap；执行 `mret` 时，它需要恢复状态并跳回 `mepc`。

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
- `pc_i`: 当前流水线传入 CLINT 的 PC
- `csr_mtvec_i`: trap 入口地址
- `csr_mepc_i`: `mret` 返回地址
- `csr_mstatus_i`: 机器状态寄存器，`csr_mstatus_i[3]` 是全局中断使能 `MIE`
- `irq_i`: 外部中断请求
- `jump_flag_i` / `jump_addr_i`: 当前流水线是否正在处理跳转及其目标地址
- `hold_flag_i`: 表示流水线前面还有未完成的操作
- `next_pc_i`: 中断返回时应保存到 `mepc` 的下一条 PC
- `inst_retire_i`: 当前指令到达可以安全进入中断的边界
- `csr_waddr_o` / `csr_waddr_vld_o` / `csr_wdata_o`: CLINT 写 CSR 的地址、有效信号和值
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

### 2. External Interrupt

测试产生一次外部中断，并给出有效的 `inst_retire_i` 和 `next_pc_i`。

期望行为：

- `csr_mstatus_i[3] = 1` 时，CLINT 能响应外部中断
- CLINT 在合适时机写入 `mepc`
- 写入 `mstatus` 时关闭全局中断，并保存原来的 `MIE`
- 写入 `mcause = 32'h8000_0003`
- CSR 写入完成后跳转到 `csr_mtvec_i`

这个测试主要检查外部中断进入 trap 的基本流程。

### 3. ECALL Exception

测试设置 `inst_func_i=3'b100`，模拟 `ecall`。

期望行为：

- CLINT 识别 `ecall`
- `mepc` 写入异常返回地址
- `mstatus` 写入 trap 入口状态
- `mcause` 写入 `32'h0000_000b`
- 最后跳转到 `csr_mtvec_i`

这里的 cause 值对应 machine mode 下的 environment call。

### 4. EBREAK Exception

测试设置 `inst_func_i=3'b010`，模拟 `ebreak`。

期望行为：

- CLINT 识别 `ebreak`
- `mepc` 写入异常返回地址
- `mstatus` 写入 trap 入口状态
- `mcause` 写入 `32'h0000_0003`
- 最后跳转到 `csr_mtvec_i`

如果 `ecall` 通过但 `ebreak` 失败，优先检查 `inst_func_i` 的位译码。

### 5. MRET Return

测试设置 `inst_func_i=3'b001`，模拟 `mret`。

期望行为：

- CLINT 写回恢复后的 `mstatus`
- `jump_flag_o = 1`
- `jump_addr_o = csr_mepc_i`

这个测试检查从 trap handler 返回普通程序的路径。

### 6. IRQ Masked When MIE=0

测试把 `csr_mstatus_i[3]` 置 0，再产生外部中断。

期望行为：

- CLINT 不进入 trap
- 不写 CSR
- 不发出 hold 或 jump

如果这里失败，说明全局中断使能判断没有正确接入。

## 失败时看什么

终端会打印当前指令功能码、PC、中断输入、CSR 写地址、CSR 写数据和跳转输出。调试时优先在波形中查看：

- `inst_func_i` 到 `ecall` / `ebreak` / `mret` 的译码
- `irq_i` 与 `csr_mstatus_i[3]` 的中断使能关系
- `next_pc_i` 和 `inst_retire_i` 是否在中断进入时有效
- `csr_waddr_o` 是否按 `mepc`、`mstatus`、`mcause` 顺序输出
- `csr_wdata_o` 是否写入了正确的 PC、状态值和 cause
- `jump_flag_o` / `jump_addr_o` 是否在处理结束时跳到 `mtvec` 或 `mepc`

常见错误：

- IRQ 一来就直接进入 trap，没有等待合适的进入时机
- `mepc` 保存了错误 PC
- `ecall` / `ebreak` 的 cause 写反
- `mstatus` 保存和恢复位处理错误
- `MIE=0` 时仍然响应中断
