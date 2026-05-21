@echo off
chcp 65001 >nul 2>nul
title Descompresor - Radar de Video Pro
echo ============================================
echo   Reconstruyendo archivos ejecutables...
echo ============================================
echo.

set "DIR=%~dp0"

:: ============================================
:: Reconstruir ffmpeg.exe desde partes
:: ============================================
if exist "%DIR%ffmpeg.exe" (
    echo [OK] ffmpeg.exe ya existe, no es necesario reconstruir
    goto :check_ytdlp
)

if exist "%DIR%ffmpeg.zip.001" (
    echo [*] Uniendo partes de ffmpeg.zip...
    copy /b "%DIR%ffmpeg.zip.001"+"%DIR%ffmpeg.zip.002" "%DIR%ffmpeg.zip" >nul
    
    if not exist "%DIR%ffmpeg.zip" (
        echo [ERROR] No se pudieron unir las partes de ffmpeg.zip
        pause
        exit /b 1
    )
    echo [OK] ffmpeg.zip reconstruido desde partes
) else (
    if not exist "%DIR%ffmpeg.zip" (
        echo [ERROR] No se encontraron las partes de ffmpeg (ffmpeg.zip.001, ffmpeg.zip.002)
        echo         ni ffmpeg.zip. Descarga el repositorio completo.
        pause
        exit /b 1
    )
)

echo [*] Extrayendo ffmpeg.exe...
powershell -Command "Expand-Archive -Path '%DIR%ffmpeg.zip' -DestinationPath '%DIR%' -Force"

if exist "%DIR%ffmpeg.exe" (
    echo [OK] ffmpeg.exe extraido correctamente
    del "%DIR%ffmpeg.zip" >nul 2>nul
) else (
    echo [ERROR] No se pudo extraer ffmpeg.exe
    pause
    exit /b 1
)

:: ============================================
:: Reconstruir yt-dlp.exe
:: ============================================
:check_ytdlp
echo.
if exist "%DIR%yt-dlp.exe" (
    echo [OK] yt-dlp.exe ya existe, no es necesario extraer
    goto :done
)

if exist "%DIR%yt-dlp.zip" (
    echo [*] Extrayendo yt-dlp.exe...
    powershell -Command "Expand-Archive -Path '%DIR%yt-dlp.zip' -DestinationPath '%DIR%' -Force"
    
    if exist "%DIR%yt-dlp.exe" (
        echo [OK] yt-dlp.exe extraido correctamente
    ) else (
        echo [ERROR] No se pudo extraer yt-dlp.exe
        pause
        exit /b 1
    )
) else (
    echo [ERROR] No se encontro yt-dlp.zip ni yt-dlp.exe
    pause
    exit /b 1
)

:: ============================================
:: Finalizado
:: ============================================
:done
echo.
echo ============================================
echo   Archivos reconstruidos correctamente!
echo ============================================
echo.
echo   Ahora ejecuta: instalar_host.bat
echo.
pause
