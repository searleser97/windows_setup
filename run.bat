@echo off
:: Step 1: Set execution policy as admin (UAC prompt)
powershell -Command "Start-Process powershell -Verb RunAs -Wait -ArgumentList '-Command Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force'"

:: Step 2: Install PowerShell 7+
winget install --id Microsoft.PowerShell --source winget

:: Step 3: Run logic.ps1 with PowerShell 7
pwsh -File "%~dp0logic.ps1"
pause
