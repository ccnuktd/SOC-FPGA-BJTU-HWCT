# SOC-FPGA RISC-V 处理器项目

一个完整的RISC-V片上系统(SoC)项目，支持在NEMU模拟器和Verilator RTL仿真两种环境下运行，可综合到Xilinx FPGA。

## 项目概述

本项目实现了一个基于RISC-V架构的处理器SoC，包含：

- **自研RISC-V处理器核心** - 32位5级流水线设计，支持RV32IM指令集
- **片上外设** - TCM存储器、定时器、UART串口等
- **NEMU模拟器** - 功能级模拟器，用于软件开发调试
- **Verilator仿真** - RTL级仿真，验证硬件设计
- **Vivado项目** - 可部署到Xilinx Kinte-7系列FPGA

---

## 目录结构

```
soc-fpga/
├── rtl/                    # RTL代码（Verilog）
│   ├── core/               # 处理器核心流水线实现
│   │   ├── pa_core_top.v          # 核心顶层模块
│   │   ├── pa_core_idu.v          # 指令译码单元
│   │   ├── pa_core_exu.v          # 执行单元
│   │   ├── pa_core_mau.v          # 内存访问单元
│   │   ├── pa_core_csr.v          # CSR寄存器
│   │   ├── pa_core_xreg.v         # 通用寄存器
│   │   ├── pa_core_rtu.v          # 寄存器重命名
│   │   ├── pa_core_pcgen.v        # PC生成
│   │   ├── pa_core_clint.v        # 中断控制器
│   │   ├── pa_core_exu_mul.v      # 乘法单元
│   │   └── pa_core_exu_div.v      # 除法单元
│   ├── perips/             # 外设模块
│   │   ├── pa_perips_tcm.v        # TCM存储器
│   │   ├── pa_perips_timer.v      # 定时器
│   │   └── pa_perips_uart.v       # UART串口
│   ├── soc/                # SoC互联
│   │   └── pa_soc_rbm.v          # 总线矩阵
│   ├── utils/              # 公共组件
│   │   └── pa_dff.v               # DFF寄存器
│   ├── pa_chip_param.v            # 芯片参数定义
│   └── pa_chip_top.v              # 芯片顶层
│
├── nemu/                    # NEMU模拟器
│   ├── Makefile            # NEMU构建文件
│   ├── Kconfig             # 配置系统
│   ├── configs/            # 预定义配置
│   │   ├── riscv32-am_defconfig   # RISC-V 32位配置
│   │   └── riscv64-am_defconfig   # RISC-V 64位配置
│   ├── include/             # 头文件
│   ├── src/                 # 源代码
│   │   ├── cpu/             # CPU模拟
│   │   ├── isa/             # 指令集模拟
│   │   │   └── riscv32/     # RISC-V 32位支持
│   │   ├── device/          # 设备模拟
│   │   └── monitor/         # 调试监控
│   └── tools/               # 辅助工具
│       ├── kconfig/         # 配置生成工具
│       └── diff-test/      # 差分测试
│
├── sim/                     # 仿真程序目录
│   ├── build.mk             # 通用构建规则
│   ├── config.mk            # 工具链配置
│   ├── simple/              # 简单示例
│   ├── timer/               # 定时器示例
│   ├── uart_recv/          # UART接收示例
│   ├── systick/             # 系统定时器示例
│   ├── xprintf/            # 打印函数示例
│   ├── ecall/               # 系统调用示例
│   ├── iap_app/             # 原地升级应用示例
│   ├── iap_app-test/        # IAP测试程序
│   ├── coremark/            # CoreMark性能测试
│   ├── rtthread-nano/       # RT-Thread Nano实时系统
│   └── bin-creater/         # 二进制创建工具
│
├── diff-tools/              # 差分测试工具
│   ├── sim_tools_simple/    # Verilator仿真环境
│   └── rtl/                 # RTL参考实现
│
├── libs/                    # 公共库
│   ├── _kernel/             # 简易内核（RT-Thread Nano）
│   ├── _sdk/               # SDK驱动
│   │   ├── systick/         # 系统定时器驱动
│   │   ├── timer/           # 定时器驱动
│   │   └── uart/            # UART驱动
│   ├── _abi/                # ABI接口封装
│   ├── _utilities/          # 工具函数（xprintf等）
│   ├── _startup/            # 启动代码
│   │   ├── start.S          # 启动汇编
│   │   └── trap.S           # 中断/异常处理
│   └── link.lds             # 链接脚本
│
├── project/                 # Vivado项目文件
│   ├── soc-fpga.xpr        # 项目文件
│   └── soc-fpga.srcs/      # 源文件集
│
├── tb/                      # Testbench文件
│   ├── core_tb.v           # 核心测试台
│   ├── core_uart_tb.v      # UART测试
│   └── ...
│
├── ipdefs/                  # Xilinx IP核定义
│   ├── clk_wiz_0/          # 时钟管理IP
│   └── blk_mem_gen_0/      # 块存储器IP
│
├── scripts/                # 辅助脚本
│   └── bin2coe.py          # bin转coe格式
│
├── auto.bat                # 一键创建Vivado项目（Windows）
├── clear.bat               # 清理项目（Windows）
├── create_project.tcl       # Vivado项目创建脚本
└── chip_pin.xdc            # 引脚约束文件
```

---

## 快速开始

### 1. 环境要求

**Linux（推荐）：**
```bash
# 安装RISC-V工具链
sudo apt install riscv32-unknown-elf-gcc

# 安装Verilator（用于RTL仿真）
sudo apt install verilator

# 安装Python3
sudo apt install python3
```

**Windows：**
- RISC-V GCC工具链（如 `riscv-none-embed-gcc`）
- Vivado 2023.2
- Python 3.x

### 2. 工具链配置

编辑 `sim/config.mk` 文件：

**Linux配置：**
```makefile
EMBTOOLPREFIX   = riscv32-unknown-elf
CC              = ${EMBTOOLPREFIX}-gcc
PYTHON          = python3
```

**Windows配置：**
```makefile
EMBTOOLPATH     = C:/riscv-none-embed
EMBTOOLPREFIX   = ${EMBTOOLPATH}/bin/riscv-none-embed
PYTHON          = C:/Python/python.exe
```

---

## 编译与运行

### 选择示例程序

进入 `sim/` 目录下的任意示例目录：

```bash
cd sim/simple    # 简单示例
cd sim/timer     # 定时器示例
cd sim/uart_recv # UART示例
cd sim/rtthread-nano # RT-Thread系统
```

### 编译程序

```bash
make build
```

生成文件：
- `riscv.elf` - ELF格式可执行文件
- `riscv.dump` - 反汇编文件
- `riscv.bin` - 二进制文件
- `rom.coe` - FPGA存储器初始化文件

### 运行程序（两种方式）

#### 方式一：使用NEMU模拟器运行

```bash
make run
```

这将：
1. 自动编译C程序
2. 启动NEMU模拟器
3. 在模拟器中加载并运行程序

**适用场景：** 快速开发调试，不涉及硬件时序

#### 方式二：使用Verilator RTL仿真

```bash
make rtl_run
```

这将：
1. 自动编译C程序
2. 调用Verilator编译RTL
3. 在仿真环境中运行处理器模型

**适用场景：** 验证硬件设计正确性

#### 方式三：对比运行（Trace）

```bash
make trace_run
```

用于对比NEMU和RTL仿真的执行结果，确保硬件实现正确。

### 清理生成文件

```bash
make clean        # 清理当前目录
make distclean    # 清理所有（包括NEMU构建）
```

---

## 示例程序说明

| 示例目录 | 功能描述 | 适用场景 |
|---------|---------|---------|
| `simple/` | 最简单的Hello World程序 | 入门学习 |
| `timer/` | 定时器中断示例 | 外设驱动学习 |
| `uart_recv/` | UART接收与发送 | 串口通信 |
| `systick/` | 系统滴答定时器 | 操作系统基础 |
| `xprintf/` | 打印功能测试 | 调试输出 |
| `ecall/` | 系统调用示例 | 了解ABI接口 |
| `iap_app/` | 原地升级应用 | OTA升级实现 |
| `iap_app-test/` | IAP测试程序 | OTA功能验证 |
| `coremark/` | CoreMark性能测试 | 性能评估 |
| `rtthread-nano/` | RT-Thread Nano实时系统 | 学习RTOS |

---

## Vivado FPGA项目

### 创建项目（Windows）

1. 修改 `auto.bat` 中的Vivado路径：
```batch
set VIVADO_PATH=C:\Xilinx\Vivado\2023.2\bin\vivado.bat
```

2. 运行：
```batch
auto.bat
```

### 创建项目（Linux）

需要手动运行Tcl脚本或使用Vivado GUI。

### 综合与实现

1. 打开 `project/soc-fpga.xpr`
2. 运行综合：`Implementation → Run Synthesis`
3. 运行实现：`Implementation → Run Implementation`
4. 生成比特流：`Implementation → Generate Bitstream`

### 烧录FPGA

使用Vivado或Vivado Lab打开生成的比特流文件（`bit/*.bit`），烧录到开发板。

---

## RTL代码架构

### 处理器流水线

```
PC Gen → IDU → EXU → MAU → WB
         ↓
        CSR/RegFile
         ↓
        CLINT(中断)
```

- **PCGen** - 程序计数器生成
- **IDU** - 指令译码单元
- **EXU** - 执行单元（算术逻辑运算）
- **MAU** - 内存访问单元
- **RTU** - 寄存器重命名单元
- **CLINT** - 核心本地中断控制器

### 存储映射

| 地址范围 | 外设 |
|---------|------|
| 0x8000_0000 ~ 0x8000_7FFF | TCM (代码+数据) |
| 0x8000_8000 ~ 0x8000_FFFF | 保留 |
| 0x8001_0000 ~ 0x8001_FFFF | Timer0 |
| 0x8002_0000 ~ 0x8002_FFFF | UART0 |
| 0x8003_0000 ~ 0x8003_FFFF | UART1 |
| 0x8004_0000 ~ 0x8004_FFFF | UART2 |

---

## NEMU模拟器配置

NEMU使用Kconfig系统进行配置。进入NEMU目录：

```bash
cd nemu
make menuconfig
```

常用配置：
- **ISA**: 选择 RISC-V 32 或 64 位
- **Engine**: 选择解释器模式
- **Device**: 配置支持的外设
- **Trace**: 配置指令追踪

保存配置后，重新编译：

```bash
make clean && make
```

---

## 开发工作流

### 1. 软件开发（使用NEMU）
```bash
# 1. 编写C代码
cd sim/simple
vim main.c

# 2. 编译并使用NEMU运行
make run

# 3. 调试直到功能正确
```

### 2. 硬件验证（使用Verilator）
```bash
# 1. 使用RTL仿真验证
make rtl_run

# 2. 如果有问题，对比trace
make trace_run
```

### 3. FPGA部署
```bash
# 1. 生成rom.coe
make build

# 2. 更新Vivado项目中的存储器初始化

# 3. 综合、烧录FPGA
```

---

## 常见问题

### Q: `make run` 报 "only supported on Linux"
A: 当前版本仅支持Linux环境。Windows用户请使用WSL或Git Bash。

### Q: Verilator仿真报错
A: 确保已安装Verilator，并检查 `diff-tools/sim_tools_simple/Makefile` 中的路径配置。

### Q: 编译报错 "riscv-none-embed-gcc not found"
A: 检查 `sim/config.mk` 中的工具链路径是否正确，或已安装RISC-V交叉编译工具链。

---

## 许可证

本项目采用 Apache-2.0 许可证。

---

## 联系方式

如有问题，请提交Issue或联系项目维护者。