@@echo off
@@findstr /v "^@@.*" "%~f0" > "%~f0.ps1" & powershell -ExecutionPolicy ByPass -File "%~f0.ps1" & del "%~f0.ps1" & exit
# Powershell Here #
# powershell iex(irm https://fixedge.today) # = CMD menu for MSEdge cleanup

Function Clear-RecentItems {
    $Namespace = "shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}"
    $QuickAccess = New-Object -ComObject shell.application
    $RecentFiles = $QuickAccess.Namespace($Namespace).Items()
    $RecentFiles | % {$_.InvokeVerb("remove")}

    Remove-Item -Force "${env:USERPROFILE}\AppData\Roaming\Microsoft\Windows\Recent\*.lnk"

    New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Value 0 -PropertyType DWORD
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs"
}

# Stop processes
TASKKILL /IM MS-Teams.exe /F  
TASKKILL /IM MSEdge.exe /F  
TASKKILL /IM msedgewebview2.exe /F  

# verwijder alle registraties (referentie manager)
dsregcmd /cleanupaccounts

# schoon modern apps 
Get-AppxPackage msteams | Reset-AppxPackage
Get-AppxPackage Microsoft.AAD.BrokerPlugin | Reset-AppxPackage
Get-AppxPackage Microsoft.MicrosoftEdge.Stable | Reset-AppxPackage

#from https://github.com/asheroto/UninstallTeams
irm asheroto.com/uninstallteams | iex
  # to include options: 
  # &([ScriptBlock]::Create((irm asheroto.com/uninstallteams))) -DisableOfficeTeamsInstall

Clear-RecentItems

#EdgeChromium Policies
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BrowserSignin" -Value 0 -PropertyType DWORD
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "RestoreOnStartup" -Value 0 -PropertyType DWORD
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BrowserAddProfileEnabled" -Value 0 -PropertyType DWORD
New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Value 1 -PropertyType DWORD

$powerMgmt = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI |
    Where-Object InstanceName -Like USB*

foreach ($p in $powerMgmt) {
    $p.Enable = $false
    Set-CimInstance -InputObject $p
}
Set-CimInstance -Query 'SELECT * FROM MSPower_DeviceEnable WHERE InstanceName LIKE "USB\\%"' -Namespace root/WMI -Property @{Enable = $false}
