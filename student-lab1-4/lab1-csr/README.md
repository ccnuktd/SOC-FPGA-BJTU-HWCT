# Lab 1: CSR 测试说明

本实验测试 `pa_core_csr` 的基本 CSR 寄存器读写。测试台会模拟处理器访问 CSR 的行为：先给出写地址、写使能和写数据，再通过读地址检查 `csr_rdata_o` 是否能读回正确内容。

## 运行

```bash
make all
make wave
make clean
```

`make all` 会编译并运行测试。`make wave` 会生成 `csr.vcd`，并用 `csr.gtkw` 打开 GTKWave。`make clean` 清理仿真产物。

## 测试内容

### 1. Cycle Register Initial Value

测试会在复位释放后等待两个时钟周期，然后读取 `cycle` 和 `cycleh`。

期望行为：

- `cycle` 能随时钟递增，测试中期望读到 `32'h0000_0002`
- `cycleh` 初始为 `32'h0000_0000`

如果这里失败，通常说明 cycle 计数器没有在复位后启动，或者读地址 `CSR_CYCLE` / `CSR_CYCLEH` 没有正确译码。

### 2. MTVEC Register

测试向 `mtvec` 写入 `32'hAAAA_AAAA`，然后读回。

期望行为：

- 当 `csr_waddr_i == CSR_MTVEC` 且 `csr_waddr_vld_i == 1` 时，保存 `csr_wdata_i`
- 后续 `csr_raddr_i == CSR_MTVEC` 时，`csr_rdata_o` 输出刚才写入的值

这个测试主要检查机器模式 trap 入口寄存器的写入和读出。

### 3. MEPC Register

测试向 `mepc` 写入 `32'h1234_5678` 并读回。

期望行为：

- `mepc` 可以被 CLINT 或 CSR 写端口更新
- 读 `CSR_MEPC` 时返回保存的异常返回地址

如果失败，后续 CLINT 的 `mret` 返回地址通常也会出问题。

### 4. MCAUSE Register

测试向 `mcause` 写入 `32'h0000_000B` 并读回。

期望行为：

- `mcause` 能保存异常/中断原因
- 读 `CSR_MCAUSE` 时返回写入值

这里的 `0xB` 对应 ecall from machine mode 的原因码。

### 5. MIE Register

测试向 `mie` 写入 `32'h0000_0888` 并读回。

期望行为：

- `mie` 保存机器模式中断使能位
- 不应被其他 CSR 的写入误覆盖

### 6. MIP Register

测试向 `mip` 写入 `32'h0000_0444` 并读回。

期望行为：

- `mip` 保存机器模式中断 pending 位
- 地址译码应和 `mie` 分开

### 7. MTVAL Register

测试向 `mtval` 写入 `32'hDEAD_BEEF` 并读回。

期望行为：

- `mtval` 可以保存 trap 附加信息
- 读回值必须和写入值完全一致

### 8. MSCRATCH Register

测试向 `mscratch` 写入 `32'h5555_5555` 并读回。

期望行为：

- `mscratch` 作为软件 scratch CSR，可普通读写

### 9. MSCRATCHCSWL Register

测试向 `mscratchcswl` 写入 `32'h6666_6666` 并读回。

期望行为：

- 该 CSR 地址能被正确识别
- 写入后读回值不应被其他寄存器影响

### 10. MSTATUS Register

测试向 `mstatus` 写入 `32'h0000_0000` 并读回。

期望行为：

- `mstatus` 保存机器模式全局状态位
- 读 `CSR_MSTATUS` 返回当前保存值

后续 CLINT 测试会依赖 `mstatus.MIE`，所以这里的读写正确性很重要。

## 失败时看什么

终端会打印期望值、实际值、当前读写地址、写使能和写数据。调试时优先在波形中查看：

- `csr_waddr_vld_i` 是否只在写入周期有效
- `csr_waddr_i` 是否等于目标 CSR 地址
- `csr_wdata_i` 是否在写入时被保存
- `csr_raddr_i` 是否切到目标 CSR 地址
- `csr_rdata_o` 是否根据 `csr_raddr_i` 选择了正确寄存器

常见错误：

- 忘记复位寄存器
- 地址常量写错或译码漏掉某个 CSR
- 写使能无效时仍然更新寄存器
- 读数据没有组合输出，导致晚一个周期或读出旧值
