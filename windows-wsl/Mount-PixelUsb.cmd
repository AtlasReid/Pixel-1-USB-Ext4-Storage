@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Mount-PixelUsb.ps1"
if errorlevel 1 pause
