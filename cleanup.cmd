@@echo off
@@findstr /v "^@@.*" "%~f0" > "%~f0.ps1" & powershell -ExecutionPolicy ByPass -File "%~f0.ps1" & del "%~f0.ps1" & exit
# Powershell Here #

# Stop processen
TASKKILL /IM MS-Teams.exe /F  
TASKKILL /IM MSEdge.exe /F  
TASKKILL /IM msedgewebview2.exe /F  

# verwijder alle registraties
dsregcmd /cleanupaccounts

# schoon modern apps 
Get-AppxPackage msteams | Reset-AppxPackage
Get-AppxPackage Microsoft.AAD.BrokerPlugin | Reset-AppxPackage
Get-AppxPackage Microsoft.MicrosoftEdge.Stable | Reset-AppxPackage
