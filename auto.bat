@echo off
setlocal enabledelayedexpansion

echo ======================================
echo   FPGA Project Creation Tool
echo ======================================

cd /d "%~dp0"
set cache_floder=project
set VIVADO_PATH=C:\Xilinx\Vivado\2023.2\bin\vivado.bat

if exist "%~dp0%cache_floder%" (
    echo.
    echo [INFO] The folder '%cache_floder%' already exists.
    echo [INFO] Project creation skipped.
    echo.
) else (
    echo [INFO] Starting Vivado project creation...
    echo [INFO] Script: %~dp0create_project.tcl
    echo.
    
    call "%VIVADO_PATH%" -source create_project.tcl
    
    if errorlevel 1 (
        echo.
        echo [ERROR] Vivado command failed.
        echo [ERROR] Vivado path: %VIVADO_PATH%
        echo.
    ) else (
        echo.
        echo [SUCCESS] Project created successfully!
        echo.
    )
)

pause
exit /b
