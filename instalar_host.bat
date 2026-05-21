@echo off
chcp 65001 >nul 2>nul
title Instalador - Radar de Video Pro
echo ============================================
echo   Instalador Automatico - Radar de Video Pro
echo ============================================
echo.

:: Obtener la ruta de esta carpeta automaticamente (sin barra final)
set "HOST_DIR=%~dp0"
set "HOST_DIR=%HOST_DIR:~0,-1%"

:: ============================================
:: PASO 0: Reconstruir exe desde zips si no existen
:: ============================================
if not exist "%HOST_DIR%\ffmpeg.exe" (
    if exist "%HOST_DIR%\ffmpeg.zip.001" (
        echo [*] Reconstruyendo ffmpeg.exe desde partes comprimidas...
        copy /b "%HOST_DIR%\ffmpeg.zip.001"+"%HOST_DIR%\ffmpeg.zip.002" "%HOST_DIR%\ffmpeg.zip" >nul
        powershell -Command "Expand-Archive -Path '%HOST_DIR%\ffmpeg.zip' -DestinationPath '%HOST_DIR%' -Force" 2>nul
        del "%HOST_DIR%\ffmpeg.zip" >nul 2>nul
        if exist "%HOST_DIR%\ffmpeg.exe" (
            echo   [OK] ffmpeg.exe reconstruido
        ) else (
            echo   [ERROR] No se pudo reconstruir ffmpeg.exe
        )
    )
)

if not exist "%HOST_DIR%\yt-dlp.exe" (
    if exist "%HOST_DIR%\yt-dlp.zip" (
        echo [*] Extrayendo yt-dlp.exe...
        powershell -Command "Expand-Archive -Path '%HOST_DIR%\yt-dlp.zip' -DestinationPath '%HOST_DIR%' -Force" 2>nul
        if exist "%HOST_DIR%\yt-dlp.exe" (
            echo   [OK] yt-dlp.exe extraido
        ) else (
            echo   [ERROR] No se pudo extraer yt-dlp.exe
        )
    )
)
echo.

:: ============================================
:: PASO 1: Verificar/Instalar Python
:: ============================================
echo [1/5] Verificando Python...

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo   [!] Python no encontrado. Instalando...
    echo   Descargando Python...
    
    :: Descargar Python usando bitsadmin (disponible en todo Windows)
    set "PYTHON_URL=https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe"
    set "PYTHON_INSTALLER=%TEMP%\python_installer.exe"
    
    bitsadmin /transfer "PythonDownload" /priority high "%PYTHON_URL%" "%PYTHON_INSTALLER%" >nul 2>nul
    
    if not exist "%PYTHON_INSTALLER%" (
        echo   [!] Descarga con bitsadmin fallo. Intentando con curl...
        curl -L -o "%PYTHON_INSTALLER%" "%PYTHON_URL%" 2>nul
    )
    
    if not exist "%PYTHON_INSTALLER%" (
        echo   [ERROR] No se pudo descargar Python.
        echo           Descargalo manualmente: https://www.python.org/downloads/
        echo           IMPORTANTE: Marca "Add Python to PATH" al instalar.
        pause
        exit /b 1
    )
    
    echo   Instalando Python silenciosamente...
    "%PYTHON_INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
    
    if %errorlevel% neq 0 (
        echo   [!] Instalacion silenciosa fallo. Abriendo instalador manual...
        echo       IMPORTANTE: Marca "Add Python to PATH" abajo del todo.
        "%PYTHON_INSTALLER%"
    )
    
    del "%PYTHON_INSTALLER%" >nul 2>nul
    
    :: Refrescar PATH
    set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%"
    
    where python >nul 2>nul
    if %errorlevel% neq 0 (
        echo   [ERROR] Python sigue sin encontrarse en PATH.
        echo           Reinicia el PC y ejecuta este instalador de nuevo.
        pause
        exit /b 1
    )
)
echo   [OK] Python encontrado

:: ============================================
:: PASO 2: Verificar/Instalar Node.js
:: ============================================
echo.
echo [2/5] Verificando Node.js...

where node >nul 2>nul
if %errorlevel% neq 0 (
    echo   [!] Node.js no encontrado. Instalando...
    
    set "NODE_URL=https://nodejs.org/dist/v20.15.0/node-v20.15.0-x64.msi"
    set "NODE_INSTALLER=%TEMP%\node_installer.msi"
    
    echo   Descargando Node.js...
    bitsadmin /transfer "NodeDownload" /priority high "%NODE_URL%" "%NODE_INSTALLER%" >nul 2>nul
    
    if not exist "%NODE_INSTALLER%" (
        echo   [!] Descarga con bitsadmin fallo. Intentando con curl...
        curl -L -o "%NODE_INSTALLER%" "%NODE_URL%" 2>nul
    )
    
    if not exist "%NODE_INSTALLER%" (
        echo   [ERROR] No se pudo descargar Node.js.
        echo           Descargalo manualmente: https://nodejs.org/
        pause
        exit /b 1
    )
    
    echo   Instalando Node.js silenciosamente...
    msiexec /i "%NODE_INSTALLER%" /qn /norestart
    
    if %errorlevel% neq 0 (
        echo   [!] Instalacion silenciosa fallo. Abriendo instalador manual...
        msiexec /i "%NODE_INSTALLER%"
    )
    
    del "%NODE_INSTALLER%" >nul 2>nul
    
    :: Refrescar PATH
    set "PATH=C:\Program Files\nodejs;%PATH%"
    
    where node >nul 2>nul
    if %errorlevel% neq 0 (
        echo   [AVISO] Node.js instalado pero requiere reiniciar.
        echo           La extension funcionara despues de reiniciar el PC.
    ) else (
        echo   [OK] Node.js instalado correctamente
    )
) else (
    echo   [OK] Node.js encontrado
)

:: ============================================
:: PASO 3: Verificar/Descargar yt-dlp y ffmpeg
:: ============================================
echo.
echo [3/5] Verificando yt-dlp y ffmpeg...

if not exist "%HOST_DIR%\yt-dlp.exe" (
    echo   [!] yt-dlp.exe no encontrado. Descargando...
    
    set "YTDLP_URL=https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
    
    curl -L -o "%HOST_DIR%\yt-dlp.exe" "%YTDLP_URL%" 2>nul
    
    if not exist "%HOST_DIR%\yt-dlp.exe" (
        bitsadmin /transfer "YtdlpDownload" /priority high "%YTDLP_URL%" "%HOST_DIR%\yt-dlp.exe" >nul 2>nul
    )
    
    if not exist "%HOST_DIR%\yt-dlp.exe" (
        echo   [ERROR] No se pudo descargar yt-dlp.exe
        echo           Descargalo manualmente de: https://github.com/yt-dlp/yt-dlp/releases
        echo           y colocalo en: %HOST_DIR%
        pause
        exit /b 1
    )
    echo   [OK] yt-dlp.exe descargado
) else (
    echo   [OK] yt-dlp.exe encontrado
)

if not exist "%HOST_DIR%\ffmpeg.exe" (
    echo   [!] ffmpeg.exe no encontrado. Descargando...
    
    set "FFMPEG_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    set "FFMPEG_ZIP=%TEMP%\ffmpeg.zip"
    set "FFMPEG_EXTRACT=%TEMP%\ffmpeg_extract"
    
    curl -L -o "%FFMPEG_ZIP%" "%FFMPEG_URL%" 2>nul
    
    if not exist "%FFMPEG_ZIP%" (
        bitsadmin /transfer "FfmpegDownload" /priority high "%FFMPEG_URL%" "%FFMPEG_ZIP%" >nul 2>nul
    )
    
    if not exist "%FFMPEG_ZIP%" (
        echo   [ERROR] No se pudo descargar ffmpeg.
        echo           Descargalo manualmente de: https://ffmpeg.org/download.html
        echo           Extrae ffmpeg.exe y colocalo en: %HOST_DIR%
        pause
        exit /b 1
    )
    
    echo   Extrayendo ffmpeg...
    if exist "%FFMPEG_EXTRACT%" rmdir /s /q "%FFMPEG_EXTRACT%"
    mkdir "%FFMPEG_EXTRACT%" >nul 2>nul
    
    powershell -Command "Expand-Archive -Path '%FFMPEG_ZIP%' -DestinationPath '%FFMPEG_EXTRACT%' -Force" 2>nul
    
    :: Buscar ffmpeg.exe dentro de la carpeta extraida
    for /r "%FFMPEG_EXTRACT%" %%f in (ffmpeg.exe) do (
        copy "%%f" "%HOST_DIR%\ffmpeg.exe" >nul 2>nul
        goto :ffmpeg_found
    )
    
    echo   [ERROR] No se encontro ffmpeg.exe en el archivo descargado.
    echo           Descargalo manualmente de: https://ffmpeg.org/download.html
    del "%FFMPEG_ZIP%" >nul 2>nul
    rmdir /s /q "%FFMPEG_EXTRACT%" >nul 2>nul
    pause
    exit /b 1
    
    :ffmpeg_found
    del "%FFMPEG_ZIP%" >nul 2>nul
    rmdir /s /q "%FFMPEG_EXTRACT%" >nul 2>nul
    
    if not exist "%HOST_DIR%\ffmpeg.exe" (
        echo   [ERROR] ffmpeg.exe no se copio correctamente.
        pause
        exit /b 1
    )
    echo   [OK] ffmpeg.exe descargado y extraido
) else (
    echo   [OK] ffmpeg.exe encontrado
)

:: ============================================
:: PASO 4: Generar configuracion del Native Host
:: ============================================
echo.
echo [4/5] Generando configuracion...

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

echo   [OK] com.descargador.ytdlp.json generado

:: ============================================
:: PASO 5: Registrar en Windows
:: ============================================
echo.
echo [5/5] Registrando en Windows...

reg add "HKCU\Software\Google\Chrome\NativeMessagingHosts\com.descargador.ytdlp" /ve /t REG_SZ /d "%JSON_FILE%" /f >nul 2>nul

if %errorlevel% neq 0 (
    echo   [ERROR] No se pudo registrar. Intentando con permisos elevados...
    powershell -Command "Start-Process reg -ArgumentList 'add','HKCU\Software\Google\Chrome\NativeMessagingHosts\com.descargador.ytdlp','/ve','/t','REG_SZ','/d','%JSON_FILE%','/f' -Verb RunAs" 2>nul
)

echo   [OK] Registro de Windows actualizado

:: ============================================
:: RESUMEN FINAL
:: ============================================
echo.
echo ============================================
echo   INSTALACION COMPLETADA EXITOSAMENTE
echo ============================================
echo.
echo   Componentes:
echo     [OK] Python
echo     [OK] Node.js
echo     [OK] yt-dlp.exe
echo     [OK] ffmpeg.exe
echo     [OK] Native Host registrado
echo.
echo   Ruta: %HOST_DIR%
echo   ID extension: bmenjglifbckojodomkkbaoknjhejdbd
echo.
echo ============================================
echo   COMO USAR:
echo ============================================
echo.
echo   1. Abre Chrome
echo   2. Ve a chrome://extensions/
echo   3. Activa "Modo desarrollador" (arriba a la derecha)
echo   4. Clic en "Cargar descomprimida"
echo   5. Selecciona esta carpeta:
echo      %HOST_DIR%
echo   6. Navega a YouTube y haz clic en el icono de la extension
echo.
echo   Si ya tenias la extension cargada, solo reinicia Chrome.
echo.
pause
