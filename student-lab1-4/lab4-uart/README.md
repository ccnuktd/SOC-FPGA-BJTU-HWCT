# Lab 4: UART 测试说明

本实验测试 `pa_perips_uart` 的寄存器接口、发送路径和接收路径。测试台会模拟 CPU 通过总线读写 UART 寄存器，也会模拟外部设备通过 `pad_rxd` 向 UART 发送串口数据，并从 `pad_txd` 捕获 UART 发出的数据。

## 运行

```bash
make all
make wave
make clean
```

`make all` 会编译并运行测试。`make wave` 会生成 `uart.vcd`，并用 `uart.gtkw` 打开 GTKWave。`make clean` 清理仿真产物。

## 寄存器约定

测试台使用以下地址：

- `0x00`: `CR`，控制寄存器，测试期望默认 TX/RX 使能
- `0x04`: `SR`，状态寄存器，记录 TX/RX 状态
- `0x08`: `BAUD`，波特率寄存器
- `0x0c`: `RXD`，接收数据寄存器
- `0x10`: `TXD`，发送数据寄存器

## 测试内容

### 1. Default Control Register

复位后读取 `CR`。

期望行为：

- `CR = 32'h0000_0003`
- 表示 TX 和 RX 默认启用

如果失败，优先检查复位值。

### 2. Default Status Register

复位后读取 `SR`。

期望行为：

- `SR = 32'h0000_0000`
- 初始时没有 TX/RX 完成标志

### 3. Baud Rate Register

读取 `BAUD`。

期望行为：

- `BAUD = 115200`

测试台的串口发送/接收延迟按 115200 波特率设计，如果波特率寄存器或内部节拍设计不一致，后续 TX/RX 测试容易失败。

### 4. Write Control Register

向 `CR` 写入 `32'h0000_0003`，再读回。

期望行为：

- 写入后读回仍为 `32'h0000_0003`
- 控制寄存器读写路径正常

### 5. Send Single Byte

测试向 `TXD` 写入 `8'h41`，也就是字符 `A`。随后测试台监测 `pad_txd`，捕获串口帧中的数据位。

期望行为：

- `pad_txd` 先产生起始位 0
- 按 LSB first 发送 8 个数据位
- 最后产生停止位 1
- 捕获到的数据为 `8'h41`

如果失败，优先查看 `pad_txd` 波形是否有完整起始位、数据位、停止位。

### 6. Receive Single Byte

测试台通过 `pad_rxd` 模拟外部串口设备发送 `8'h42`，也就是字符 `B`。等待一段时间后读取 `RXD`。

期望行为：

- UART 能检测 `pad_rxd` 起始位
- 在每个 bit 周期正确采样数据位
- 读 `RXD` 时返回 `8'h42`
- 写 `SR=32'h0000_0002` 后能清除 RX 标志

### 7. Send Multiple Bytes

测试连续写 `TXD` 发送 `Hello`：

- `H`: `8'h48`
- `e`: `8'h65`
- `l`: `8'h6c`
- `l`: `8'h6c`
- `o`: `8'h6f`

期望行为：

- 每次写 `TXD` 都能启动一帧发送
- 每帧数据都正确
- 前一帧结束后，后一帧不会被旧状态影响

### 8. Receive Multiple Bytes

测试台依次从 `pad_rxd` 输入 `Worle`：

- `W`: `8'h57`
- `o`: `8'h6f`
- `r`: `8'h72`
- `l`: `8'h6c`
- `e`: `8'h65`

每接收一个字节后，测试会等待 RX done，读取 `RXD`，并清除 RX flag。

期望行为：

- 每个字节都能独立接收
- 清除 RX flag 后，下一次接收仍然正常
- `RXD` 不应残留上一次数据

### 9. Final Status Register

最后读取 `SR`。

期望行为：

- `SR = 32'h0000_0003`
- 表示测试末尾 TX/RX 状态位达到预期

## 失败时看什么

终端会打印当前测试项、期望值、实际值、总线信号和 UART 引脚状态。调试时优先在波形中查看：

- `data_we_i` 写 `TXD` 后发送状态是否启动
- `pad_txd` 是否按起始位、8 个数据位、停止位输出
- `pad_rxd` 输入后，内部采样时机是否对准数据位中间
- `SR` 的 TX/RX 状态位是否正确置位和清除
- `RXD` 数据寄存器是否保存最近一次接收到的字节
- 写 `SR` 清 flag 后，状态位是否正确变化

常见错误：

- TX 位序写成 MSB first
- 起始位或停止位持续时间不对
- RX 采样太早或太晚
- 写 `TXD` 后没有启动发送状态机
- RX flag 没有置位或无法清除
- 读寄存器地址选择错误
