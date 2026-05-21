@echo off
chcp 65001 >nul 2>nul
title Descompresor - Radar de Video Pro
echo ============================================
echo   Descomprimiendo archivos ejecutables...
echo ============================================
echo.

set "DIR=%~dp0"

:: Descomprimir ffmpeg.zip
if exist "%DIR%ffmpeg.zip" (
    if not exist "%DIR%ffmpeg.exe" (
        echo [*] Extrayendo ffmpeg.exe desde ffmpeg.zip...
        powershell -Command "Expand-Archive -Path '%DIR%ffmpeg.zip' -DestinationPath '%DIR%' -Force"
        if exist "%DIR%ffmpeg.exe" (
            echo [OK] ffmpeg.exe extraido correctamente
        ) else (
            echo [ERROR] No se pudo extraer ffmpeg.exe
        )
    ) else (
        echo [OK] ffmpeg.exe ya existe, no es necesario extraer
    )
) else (
    if not exist "%DIR%ffmpeg.exe" (
        echo [ERROR] No se encontro ffmpeg.zip ni ffmpeg.exe
    ) else (
        echo [OK] ffmpeg.exe ya existe
    )
)

:: Descomprimir yt-dlp.zip
if exist "%DIR%yt-dlp.zip" (
    if not exist "%DIR%yt-dlp.exe" (
        echo [*] Extrayendo yt-dlp.exe desde yt-dlp.zip...
        powershell -Command "Expand-Archive -Path '%DIR%yt-dlp.zip' -DestinationPath '%DIR%' -Force"
        if exist "%DIR%yt-dlp.exe" (
            echo [OK] yt-dlp.exe extraido correctamente
        ) else (
            echo [ERROR] No se pudo extraer yt-dlp.exe
        )
    ) else (
        echo [OK] yt-dlp.exe ya existe, no es necesario extraer
    )
) else (
    if not exist "%DIR%yt-dlp.exe" (
        echo [ERROR] No se encontro yt-dlp.zip ni yt-dlp.exe
    ) else (
        echo [OK] yt-dlp.exe ya existe
    )
)

echo.
echo ============================================
echo   Listo! Ahora ejecuta instalar_host.bat
echo ============================================
echo.
pause
