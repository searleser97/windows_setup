@echo off
:: Step 1: Set execution policy as admin (UAC prompt)
powershell -Command "Start-Process powershell -Verb RunAs -Wait -ArgumentList '-Command Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force'"

:: Step 2: Run logic.ps1 in a new non-admin PowerShell session
powershell -File "%~dp0logic.ps1"
pause
