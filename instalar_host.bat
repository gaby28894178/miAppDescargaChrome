@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>nul
title Instalador - Radar de Video Pro
cls
echo.
echo  ╔══════════════════════════════════════════════╗
echo  ║   INSTALADOR AUTOMATICO                     ║
echo  ║   Radar de Video Pro v2.1                   ║
echo  ╚══════════════════════════════════════════════╝
echo.

:: Obtener la ruta de esta carpeta
set "HOST_DIR=%~dp0"
set "HOST_DIR=%HOST_DIR:~0,-1%"

:: Refrescar PATH con rutas comunes por si acaban de instalar algo
set "PATH=C:\Program Files\nodejs;%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts;C:\Python312;C:\Python311;C:\Python310;%PATH%"

echo  [0/6] Preparando entorno...
echo.

:: ============================================
:: PASO 1: Reconstruir exe desde zips
:: ============================================
echo  [1/6] Verificando ejecutables...

if not exist "%HOST_DIR%\ffmpeg.exe" (
    if exist "%HOST_DIR%\ffmpeg.zip.001" (
        echo    [*] Uniendo partes de ffmpeg.zip...
        copy /b "%HOST_DIR%\ffmpeg.zip.001"+"%HOST_DIR%\ffmpeg.zip.002" "%HOST_DIR%\ffmpeg.zip" >nul 2>nul
        echo    [*] Extrayendo ffmpeg.exe...
        powershell -NoProfile -Command "Expand-Archive -Path '%HOST_DIR%\ffmpeg.zip' -DestinationPath '%HOST_DIR%' -Force" 2>nul
        del "%HOST_DIR%\ffmpeg.zip" >nul 2>nul
        if exist "%HOST_DIR%\ffmpeg.exe" (
            echo    [OK] ffmpeg.exe reconstruido desde partes
        ) else (
            echo    [!] No se pudo reconstruir, se descargara...
        )
    )
)

if not exist "%HOST_DIR%\yt-dlp.exe" (
    if exist "%HOST_DIR%\yt-dlp.zip" (
        echo    [*] Extrayendo yt-dlp.exe...
        powershell -NoProfile -Command "Expand-Archive -Path '%HOST_DIR%\yt-dlp.zip' -DestinationPath '%HOST_DIR%' -Force" 2>nul
        if exist "%HOST_DIR%\yt-dlp.exe" (
            echo    [OK] yt-dlp.exe extraido
        )
    )
)

if exist "%HOST_DIR%\ffmpeg.exe" (
    echo    [OK] ffmpeg.exe listo
)
if exist "%HOST_DIR%\yt-dlp.exe" (
    echo    [OK] yt-dlp.exe listo
)

:: ============================================
:: PASO 2: Python
:: ============================================
echo.
echo  [2/6] Verificando Python...

set "PYTHON_OK=0"
where python >nul 2>nul && set "PYTHON_OK=1"
if "!PYTHON_OK!"=="0" (
    :: Buscar en rutas comunes
    if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
        set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%PATH%"
        set "PYTHON_OK=1"
    )
    if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
        set "PATH=%LOCALAPPDATA%\Programs\Python\Python311;%PATH%"
        set "PYTHON_OK=1"
    )
    if exist "C:\Python312\python.exe" (
        set "PATH=C:\Python312;%PATH%"
        set "PYTHON_OK=1"
    )
    if exist "C:\Python311\python.exe" (
        set "PATH=C:\Python311;%PATH%"
        set "PYTHON_OK=1"
    )
)

if "!PYTHON_OK!"=="0" (
    echo    [!] Python NO encontrado. Descargando e instalando...
    
    set "PYTHON_URL=https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe"
    set "PYTHON_INSTALLER=%TEMP%\python_installer.exe"
    
    curl -L -o "!PYTHON_INSTALLER!" "!PYTHON_URL!" 2>nul
    if not exist "!PYTHON_INSTALLER!" (
        bitsadmin /transfer "PythonDL" /priority high "!PYTHON_URL!" "!PYTHON_INSTALLER!" >nul 2>nul
    )
    
    if exist "!PYTHON_INSTALLER!" (
        echo    [*] Instalando Python 3.12 ...
        "!PYTHON_INSTALLER!" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
        if !errorlevel! neq 0 (
            echo    [!] Instalacion silenciosa fallo. Abriendo instalador...
            echo        MARCA "Add Python to PATH" abajo del todo.
            "!PYTHON_INSTALLER!"
        )
        del "!PYTHON_INSTALLER!" >nul 2>nul
        set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;!PATH!"
    ) else (
        echo    [ERROR] No se pudo descargar Python.
        echo            Instala manualmente: https://www.python.org/downloads/
        echo            MARCA "Add Python to PATH" al instalar.
        pause
        exit /b 1
    )
)

:: Verificacion final de Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo    [ERROR] Python no disponible en PATH.
    echo            Reinicia el PC y ejecuta este instalador de nuevo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo    [OK] %%v

:: ============================================
:: PASO 3: Node.js
:: ============================================
echo.
echo  [3/6] Verificando Node.js...

set "NODE_OK=0"
where node >nul 2>nul && set "NODE_OK=1"
if "!NODE_OK!"=="0" (
    if exist "C:\Program Files\nodejs\node.exe" (
        set "PATH=C:\Program Files\nodejs;!PATH!"
        set "NODE_OK=1"
    )
)

if "!NODE_OK!"=="0" (
    echo    [!] Node.js NO encontrado. Descargando e instalando...
    
    set "NODE_URL=https://nodejs.org/dist/v20.15.0/node-v20.15.0-x64.msi"
    set "NODE_INSTALLER=%TEMP%\node_installer.msi"
    
    curl -L -o "!NODE_INSTALLER!" "!NODE_URL!" 2>nul
    if not exist "!NODE_INSTALLER!" (
        bitsadmin /transfer "NodeDL" /priority high "!NODE_URL!" "!NODE_INSTALLER!" >nul 2>nul
    )
    
    if exist "!NODE_INSTALLER!" (
        echo    [*] Instalando Node.js v20 ...
        msiexec /i "!NODE_INSTALLER!" /qn /norestart
        if !errorlevel! neq 0 (
            echo    [!] Instalacion silenciosa fallo. Abriendo instalador...
            msiexec /i "!NODE_INSTALLER!"
        )
        del "!NODE_INSTALLER!" >nul 2>nul
        set "PATH=C:\Program Files\nodejs;!PATH!"
    ) else (
        echo    [ERROR] No se pudo descargar Node.js.
        echo            Instala manualmente: https://nodejs.org/
        pause
        exit /b 1
    )
)

:: Verificacion final de Node
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo    [AVISO] Node.js instalado pero PATH no actualizado.
    echo            Reinicia el PC para que funcione correctamente.
) else (
    for /f "tokens=*" %%v in ('node --version 2^>^&1') do echo    [OK] Node.js %%v
)

:: ============================================
:: PASO 4: Descargar yt-dlp y ffmpeg si faltan
:: ============================================
echo.
echo  [4/6] Verificando yt-dlp y ffmpeg...

if not exist "%HOST_DIR%\yt-dlp.exe" (
    echo    [!] yt-dlp.exe falta. Descargando ultima version...
    curl -L -o "%HOST_DIR%\yt-dlp.exe" "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" 2>nul
    if not exist "%HOST_DIR%\yt-dlp.exe" (
        bitsadmin /transfer "YtdlpDL" /priority high "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" "%HOST_DIR%\yt-dlp.exe" >nul 2>nul
    )
    if exist "%HOST_DIR%\yt-dlp.exe" (
        echo    [OK] yt-dlp.exe descargado
    ) else (
        echo    [ERROR] No se pudo obtener yt-dlp.exe
        echo            Descarga manual: https://github.com/yt-dlp/yt-dlp/releases
        pause
        exit /b 1
    )
) else (
    echo    [OK] yt-dlp.exe presente
)

if not exist "%HOST_DIR%\ffmpeg.exe" (
    echo    [!] ffmpeg.exe falta. Descargando...
    set "FFMPEG_ZIP=%TEMP%\ffmpeg_full.zip"
    set "FFMPEG_DIR=%TEMP%\ffmpeg_ext"
    
    curl -L -o "!FFMPEG_ZIP!" "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" 2>nul
    if not exist "!FFMPEG_ZIP!" (
        bitsadmin /transfer "FfmpegDL" /priority high "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" "!FFMPEG_ZIP!" >nul 2>nul
    )
    
    if exist "!FFMPEG_ZIP!" (
        echo    [*] Extrayendo ffmpeg.exe...
        if exist "!FFMPEG_DIR!" rmdir /s /q "!FFMPEG_DIR!"
        powershell -NoProfile -Command "Expand-Archive -Path '!FFMPEG_ZIP!' -DestinationPath '!FFMPEG_DIR!' -Force" 2>nul
        for /r "!FFMPEG_DIR!" %%f in (ffmpeg.exe) do (
            copy "%%f" "%HOST_DIR%\ffmpeg.exe" >nul 2>nul
            goto :ffmpeg_ok
        )
        :ffmpeg_ok
        del "!FFMPEG_ZIP!" >nul 2>nul
        rmdir /s /q "!FFMPEG_DIR!" >nul 2>nul
    )
    
    if exist "%HOST_DIR%\ffmpeg.exe" (
        echo    [OK] ffmpeg.exe descargado y extraido
    ) else (
        echo    [ERROR] No se pudo obtener ffmpeg.exe
        echo            Descarga manual: https://ffmpeg.org/download.html
        pause
        exit /b 1
    )
) else (
    echo    [OK] ffmpeg.exe presente
)

:: ============================================
:: PASO 5: Generar configuracion Native Host
:: ============================================
echo.
echo  [5/6] Generando configuracion del Native Host...

set "JSON_FILE=%HOST_DIR%\com.descargador.ytdlp.json"
set "ESCAPED_DIR=%HOST_DIR:\=\\%"

> "%JSON_FILE%" (
    echo {
    echo   "name": "com.descargador.ytdlp",
    echo   "description": "Native host para descargar videos con yt-dlp",
    echo   "path": "%ESCAPED_DIR%\\native_host.bat",
    echo   "type": "stdio",
    echo   "allowed_origins": [
    echo     "chrome-extension://bmenjglifbckojodomkkbaoknjhejdbd/"
    echo   ]
    echo }
)
echo    [OK] com.descargador.ytdlp.json generado

:: ============================================
:: PASO 6: Registrar en Windows
:: ============================================
echo.
echo  [6/6] Registrando Native Host en Windows...

reg add "HKCU\Software\Google\Chrome\NativeMessagingHosts\com.descargador.ytdlp" /ve /t REG_SZ /d "%JSON_FILE%" /f >nul 2>nul
if %errorlevel% neq 0 (
    echo    [!] Intentando con permisos elevados...
    powershell -NoProfile -Command "Start-Process reg -ArgumentList 'add','HKCU\Software\Google\Chrome\NativeMessagingHosts\com.descargador.ytdlp','/ve','/t','REG_SZ','/d','%JSON_FILE%','/f' -Verb RunAs" 2>nul
)
echo    [OK] Registro actualizado

:: ============================================
:: VERIFICACION FINAL
:: ============================================
echo.
echo  ╔══════════════════════════════════════════════╗
echo  ║   VERIFICACION FINAL                        ║
echo  ╚══════════════════════════════════════════════╝
echo.

set "ERRORES=0"

where python >nul 2>nul
if %errorlevel% equ 0 (
    echo    [OK] Python ............. disponible
) else (
    echo    [X]  Python ............. NO ENCONTRADO
    set /a ERRORES+=1
)

where node >nul 2>nul
if %errorlevel% equ 0 (
    echo    [OK] Node.js ........... disponible
) else (
    echo    [X]  Node.js ........... NO ENCONTRADO (reinicia PC)
    set /a ERRORES+=1
)

if exist "%HOST_DIR%\yt-dlp.exe" (
    echo    [OK] yt-dlp.exe ........ presente
) else (
    echo    [X]  yt-dlp.exe ........ FALTA
    set /a ERRORES+=1
)

if exist "%HOST_DIR%\ffmpeg.exe" (
    echo    [OK] ffmpeg.exe ........ presente
) else (
    echo    [X]  ffmpeg.exe ........ FALTA
    set /a ERRORES+=1
)

if exist "%JSON_FILE%" (
    echo    [OK] Native Host JSON .. generado
) else (
    echo    [X]  Native Host JSON .. FALTA
    set /a ERRORES+=1
)

reg query "HKCU\Software\Google\Chrome\NativeMessagingHosts\com.descargador.ytdlp" >nul 2>nul
if %errorlevel% equ 0 (
    echo    [OK] Registro Windows .. configurado
) else (
    echo    [X]  Registro Windows .. NO CONFIGURADO
    set /a ERRORES+=1
)

echo.
if !ERRORES! equ 0 (
    echo  ╔══════════════════════════════════════════════╗
    echo  ║   INSTALACION COMPLETADA - TODO LISTO        ║
    echo  ╚══════════════════════════════════════════════╝
    echo.
    echo   Ruta: %HOST_DIR%
    echo   ID:   bmenjglifbckojodomkkbaoknjhejdbd
    echo.
    echo  ─────────────────────────────────────────────
    echo   ULTIMO PASO (unico manual):
    echo   Se abrira Chrome en extensiones.
    echo     1. Activa "Modo desarrollador"
    echo     2. Clic "Cargar descomprimida"
    echo     3. Selecciona: %HOST_DIR%
    echo  ─────────────────────────────────────────────
    echo.
    echo  Presiona una tecla para abrir Chrome...
    pause >nul
    start "" "chrome" "chrome://extensions/"
) else (
    echo  ╔══════════════════════════════════════════════╗
    echo  ║   INSTALACION CON ERRORES: !ERRORES! problema(s)     ║
    echo  ╚══════════════════════════════════════════════╝
    echo.
    echo   Revisa los items marcados con [X] arriba.
    echo   Si instalaste Python o Node.js, reinicia el PC
    echo   y ejecuta este instalador de nuevo.
    echo.
    pause
)

endlocal
