@@echo off
@@findstr /v "^@@.*" "%~f0" > "%~f0.ps1" & powershell -ExecutionPolicy ByPass -File "%~f0.ps1" & del "%~f0.ps1" & exit
# Powershell Here #

# ============================================================
#  Edge-beleid zetten onder ELKE geladen HKEY_USERS-hive
#  Uitvoeren als Administrator in PowerShell
# ============================================================

# --- Pas deze 3 regels aan: policy type, naam en waarde ---
$PolicyType  = 'DWord'                     # opties: String, ExpandString, DWord, QWord, Binary
$PolicyName  = 'HomepageLocation'          # bv. HomepageLocation, RestoreOnStartup, ...
$PolicyValue = 'https://intranet.example.nl'   # bij DWord gewoon een getal, bv. 1

# --- Stap 0: Controleer Administrator ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Host "FOUT: start als Administrator." -ForegroundColor Red; exit 1 }

# --- Stap 1: Maak de HKU-drive beschikbaar ---
if (-not (Get-PSDrive HKU -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
}

# --- Stap 2: Alle hives ophalen (diensten/klassen uitsluiten) ---
$hives = Get-ChildItem HKU:\ | Where-Object {
    $n = $_.PSChildName
    $n -notlike '*_Classes' -and
    $n -notmatch '^\.DEFAULT$' -and     # wil je deze ook? haal deze regel weg
    $n.Length -ge 8                     # echte SID's, bv. S-1-5-21-...
}

Write-Host "Gevonden user-hives:" -ForegroundColor Cyan
$hives | ForEach-Object { "  $($_.PSChildName)" }

# --- Stap 3: Overzicht van gebruikersnamen bij de SID's (leesbaar) ---
Write-Host "`nKoppeling SID -> profiel:" -ForegroundColor Cyan
foreach ($h in $hives) {
    $sid = New-Object System.Security.Principal.SecurityIdentifier($h.PSChildName)
    try { "  $($h.PSChildName) -> $($sid.Translate([System.Security.Principal.NTAccount]).Value)" }
    catch { "  $($h.PSChildName) -> (onbekend / niet geladen profiel)" }
}

# --- Stap 4: Samenvatting + bevestiging ---
Write-Host "`nGaat dit zetten:" -ForegroundColor Yellow
Write-Host "  Tree  : HKU\<SID>\SOFTWARE\Policies\Microsoft\Edge"
Write-Host "  Waarde: $PolicyName ($PolicyType) = $PolicyValue"
Write-Host "  Op    : $($hives.Count) hive(s)"
$ok = Read-Host "Doorgaan? (j/n)"
if ($ok -ne 'j') { Write-Host "Afgebroken."; exit }

# --- Stap 5: Toepassen op elke hive ---
foreach ($h in $hives) {
    $pad = "$($h.PSPath)\SOFTWARE\Policies\Microsoft\Edge"
    try {
        if (-not (Test-Path $pad)) {
            New-Item -Path $pad -Force | Out-Null          # Policies\Microsoft\Edge aanmaken indien nodig
        }
        $bestaand = Get-ItemProperty -Path $pad -Name $PolicyName -ErrorAction SilentlyContinue
        if ($bestaand) {
            Write-Host "  $($h.PSChildName): $PolicyName bestond al (oud: $($bestaand.$PolicyName), overschreven)" -ForegroundColor Yellow
        }
        Set-ItemProperty -Path $pad -Name $PolicyName -Value $PolicyValue -Type $PolicyType
        # controle achteraf
        $check = (Get-ItemProperty -Path $pad -Name $PolicyName).($PolicyName)
        Write-Host "  $($h.PSChildName): gezet -> $check" $(if ($check -eq $PolicyValue) { "(OK)" -ForegroundColor Green } else { "(MISMATCH!)" -ForegroundColor Red })
    }
    catch {
        Write-Host "  FOUT bij $($h.PSChildName): $_" -ForegroundColor Red
    }
}

Write-Host "`nKlaar. Edge herstarten (of gpupdate /force) om het beleid actief te zien." -ForegroundColor Green
