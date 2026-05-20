@echo off
set PATH=%PATH%;C:\Program Files\nodejs;%APPDATA%\npm
python "%~dp0native_host.py"
