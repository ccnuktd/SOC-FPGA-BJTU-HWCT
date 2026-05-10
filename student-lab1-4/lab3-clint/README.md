# Lab 3: CLINT 测试说明

本实验测试 `pa_core_clint` 的异常和中断控制逻辑。测试参考 `diff-tools/sim_tools_simple` 中的 `tb_clint.v` 和 `tb_interrupt_matrix.v`，重点检查 CLINT 是否能在正确时机写 CSR、请求流水线 hold，并输出正确跳转地址。

CLINT 不是简单地“看到中断就立刻跳转”。外部中断可能发生在普通指令、访存、多周期运算或控制流指令附近，CLINT 需要等到顶层给出的精确 retire 边界，再保存正确的 `mepc` 并进入 trap。

## 代码骨架说明

`lab3_clint.v` 的学生版应当和教师版保持同构：学生版保留教师版的状态机、信号命名、CSR 写回顺序、精确中断说明和输出连接，只把关键表达式替换成 TODO 占位。

也就是说，补齐 TODO 后，学生实现应该自然收敛到教师版逻辑，而不是写成另一套结构相近但细节不同的 CLINT。

本实验需要补齐的内容包括：

- `TODO-1`: 译码 `ecall`、`ebreak`、`mret`
- `TODO-2` 到 `TODO-4`: 产生 IRQ 事件、记录 pending，并选择当前 trap 类型
- `TODO-5` 到 `TODO-8`: 计算并选择写入 `mepc` 的异常/中断返回地址
- `TODO-9` 到 `TODO-10`: 选择写入 `mcause` 的异常/中断原因
- `TODO-11` 到 `TODO-12`: 判断何时捕获 trap 信息并进入 CSR 写状态机
- `TODO-13` 到 `TODO-14`: trap 入口和 `mret` 时更新 `mstatus`
- `TODO-15` 到 `TODO-16`: trap 完成后跳转到 `mtvec`，`mret` 后跳转到 `mepc`

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
- `jump_flag_i` / `jump_addr_i`: 当前 EX 指令是否为已完成的跳转及其目标地址，异常路径会用它避开冲突
- `hold_flag_i`: 表示前面还有未完成副作用
- `next_pc_i`: 顶层计算好的中断返回 PC；顺序指令为 `exu_pc + 4`，已完成跳转为跳转目标
- `inst_retire_i`: 顶层给出的精确 retire 边界，中断只能在这个信号有效时进入 trap
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

### 2. Interrupt Waits for Precise Retire

测试先产生 `irq_i`，但暂时不给 `inst_retire_i`。随后检查 CLINT 不应提前写 CSR。等到 `inst_retire_i=1` 且 `next_pc_i=32'h8000_0104` 后，CLINT 才进入 trap。

期望行为：

- 中断先进入 pending 状态
- 在精确 retire 边界出现前不写 CSR
- 出现 `inst_retire_i` 后，`mepc` 写入 `next_pc_i`
- `mstatus` 写入关中断后的值 `32'h0000_1880`
- `mcause` 写入 `32'h8000_0003`
- 最后跳转到 `mtvec`

这个测试说明：中断保存的不是随便一个当前 PC，而是顶层在 retire 边界确认的下一条应执行 PC。

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

测试把 `csr_mstatus_i[3]` 置 0，再产生 `irq_i` 和后续 `inst_retire_i`。

期望行为：

- CLINT 不进入 trap
- 不写 CSR
- 不发出 hold 或 jump

如果这里失败，说明全局中断使能判断没有正确接入。

### 7. Pending IRQ Until Precise Retire Boundary

测试多种“中断先到，但精确 retire 边界稍后才到”的情况：

- 普通 ALU 指令附近
- load/store busy
- 多周期 div/rem busy
- branch-not-taken，直到后续 retire 边界

期望行为：

- `irq_i` 来时先记录 pending
- `hold_flag_i=1` 或没有 `inst_retire_i` 时，不应提前写 CSR
- 后续 `inst_retire_i` 出现后，保存对应 `next_pc_i`
- 之后按 `mepc`、`mstatus`、`mcause` 的顺序写 CSR，并跳转 `mtvec`

### 8. Immediate Retire Boundary

测试中断后马上遇到顺序 retire、branch taken、jal、jalr 这类 retire 边界。

期望行为：

- CLINT 保存 `next_pc_i` 到 `mepc`
- 不丢失中断
- 不把旧 PC 错写进 `mepc`

### 9. Retire Waits for Older Side Effect

测试 `hold_flag_i=1` 表示前面还有旧副作用没处理完。

期望行为：

- CLINT 继续等待
- 等 `hold_flag_i` 变 0 且 `inst_retire_i` 出现后再进入 trap
- 保存此时的 `next_pc_i`

这个测试能发现“太早进入 trap，导致旧指令副作用丢失”的问题。

## 失败时看什么

终端会打印当前指令功能码、PC、中断输入、跳转握手、CSR 写地址和写数据。每个失败项也会打印期望 CSR/跳转和值。调试时优先在波形中查看：

- `inst_func_i` 到 `ecall` / `ebreak` / `mret` 的译码
- `irq_i` 与 `csr_mstatus_i[3]` 的中断使能关系
- `next_pc_i` / `inst_retire_i` 是否按顶层语义接入
- `hold_flag_i` 拉高时是否阻止 trap 提前进入
- `csr_waddr_o` 是否按 `mepc`、`mstatus`、`mcause` 顺序输出
- `csr_wdata_o` 是否写入了正确的 PC、状态值和 cause
- `jump_flag_o` / `jump_addr_o` 是否在处理结束时跳到 `mtvec` 或 `mepc`

常见错误：

- IRQ 一来就直接进入 trap，没有等待 `inst_retire_i`
- `mepc` 保存了错误 PC
- ecall/ebreak 的 cause 写反
- `mstatus` 保存和恢复位处理错误
- `hold_flag_i=1` 时仍然写 CSR
- `MIE=0` 时仍然响应中断
