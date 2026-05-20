@echo off
echo Registrando Native Messaging Host...
reg add "HKCU\Software\Google\Chrome\NativeMessagingHosts\com.descargador.ytdlp" /ve /t REG_SZ /d "C:\Users\PC\Desktop\extencion chrome mia\com.descargador.ytdlp.json" /f
echo.
echo ¡Registrado correctamente!
echo.
echo IMPORTANTE: Ahora necesitas actualizar el ID de la extension.
echo 1. Ve a chrome://extensions/
echo 2. Copia el ID de tu extension (letras debajo del nombre)
echo 3. Edita com.descargador.ytdlp.json y reemplaza EXTENSION_ID por tu ID real
echo.
pause
