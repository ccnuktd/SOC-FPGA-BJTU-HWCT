# 使用说明

1.  修改编译工具（文件路径：`sim/config.mk`）

    ```
    EMBTOOLPATH     = C:/riscv-none-embed (实例)
    EMBTOOLPREFIX   = ${EMBTOOLPATH}/bin/riscv-none-embed
    PYTHON          = C:/Users/nana4/AppData/Local/Programs/Python/Python314/python.exe
    ```

2.  编译 simple 程序

    -   生成 `riscv.bin` 文件
    -   生成 `rom.coe` 文件

    ```
    cd sim
    cd simple
    make build
    ```

3.  编译 app 程序

    -   生成 `riscv_app.bin` 文件

    ```
    cd sim
    cd iap_app
    make build_app
    ```

4.  生成Vivado项目

    -   点击 auto.bat 脚本
    -   注意修改路径到自己vivado: set VIVADO_PATH=C:\Xilinx\Vivado\2023.2\bin\vivado.bat

5.  清理项目

    -   点击 clear.bat 脚本