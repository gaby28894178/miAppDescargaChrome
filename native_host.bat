@echo off
:: Buscar Python en el PATH del sistema
where python >nul 2>nul
if %errorlevel% neq 0 (
    where python3 >nul 2>nul
    if %errorlevel% neq 0 (
        exit /b 1
    )
    python3 "%~dp0native_host.py"
) else (
    python "%~dp0native_host.py"
)
