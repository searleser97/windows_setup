@echo off
:: Step 1: Set execution policy as admin (UAC prompt) if not already Unrestricted
powershell -Command "if ((Get-ExecutionPolicy) -ne 'Unrestricted') { Start-Process powershell -Verb RunAs -Wait -ArgumentList '-Command Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force' }"

:: Step 2: Install PowerShell 7+
winget install --id Microsoft.PowerShell --source winget

:: Step 3: Refresh PATH so pwsh is available
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%B"
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USR_PATH=%%B"
set "PATH=%SYS_PATH%;%USR_PATH%"

:: Step 4: Run logic.ps1 with PowerShell 7
pwsh -File "%~dp0logic.ps1"
pause
