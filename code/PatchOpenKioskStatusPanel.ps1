
param(
  [Parameter(Mandatory = $true)]
  [string]$Username
)

<#
##########################################################################################
# PatchOpenKioskStatusPanel.ps1   Version 1.00 09-Feb-2026
# This Windows Powerscript script finds the specified user's profile path from the 
# registry and modifies the users AppData\Roaming\MDG\OpenKiosk profile buy inserting
# a .css file "userChrome.css" and some javascript (user.js) that enables it.

# This hides the annoying URL/status overlay that OpenKiosk (Firefox-based) places at
# the bottom of the screen saying something similar to “localhost:8081#tab…” when navbar
# tabs etc are hovered over. It does this by finding the specified user's profile path
# and then modifies the users AppData\Roaming\MDG\OpenKiosk profile buy inserting a
# file "userChrome.css" and some javascript (user.js) that enables it for all profiles. 


PREREQUISITES:  Need to enable powershell scripts to be run on the computer.

1: Quit OpenKiosk (Shift+F1, enter the openkiosk password and press the quit button.

2: Run the Windows Powershell console app as an Administrator

Then enter the following commands:

3: Set-ExecutionPolicy unrestricted

** Note assumes openKiosk is run as usr= MOTUS_USER 
** if you run the kiosk as some other user, substitute that username in the command below

4: powershell -File  "C:\Users\MOTUS_USER\Projects\MOTUS_KIOSK\code\PatchOpenKioskStatusPanel.ps1" MOTUS_USER

5: Set-ExecutionPolicy restricted

6: Test: Run OpenKiosk, select Detections tabs etc and the “localhost:8081#tab…” should be gone.

##########################################################################################
#>

# --- Find the user's profile path reliably (doesn't assume C:\Users\...) ---
$profilePath = $null
$profileListKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

Get-ChildItem $profileListKey | ForEach-Object {
  $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
  if ($p.ProfileImagePath -and ($p.ProfileImagePath -match "\\$([regex]::Escape($Username))$")) {
    $script:profilePath = $p.ProfileImagePath
  }
}

if (-not $profilePath) {
  throw "Could not find profile path for user '$Username' in ProfileList registry."
}

$okRoot = Join-Path $profilePath "AppData\Roaming\MDG\OpenKiosk"
$profilesRoot = Join-Path $okRoot "Profiles"

if (!(Test-Path $profilesRoot)) {
  throw "OpenKiosk Profiles folder not found for '$Username': $profilesRoot"
}

# --- Files to install ---
$userChromeCss = @"
#statuspanel,
#statuspanel-label {
  display: none !important;
}
"@

$userJsLine = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'

# --- Patch every profile folder (profile IDs vary by machine/install) ---
$profiles = Get-ChildItem -Path $profilesRoot -Directory -ErrorAction Stop
if ($profiles.Count -eq 0) {
  throw "No profile directories found under: $profilesRoot"
}

foreach ($p in $profiles) {
  $profileDir = $p.FullName

  # 1) chrome\userChrome.css
  $chromeDir = Join-Path $profileDir "chrome"
  New-Item -ItemType Directory -Force -Path $chromeDir | Out-Null
  $userChromePath = Join-Path $chromeDir "userChrome.css"
  Set-Content -Path $userChromePath -Value $userChromeCss -Encoding UTF8

  # 2) user.js (create if missing; append pref if not present)
  $userJsPath = Join-Path $profileDir "user.js"
  if (Test-Path $userJsPath) {
    $existing = Get-Content $userJsPath -Raw
    if ($existing -notmatch 'toolkit\.legacyUserProfileCustomizations\.stylesheets') {
      Add-Content -Path $userJsPath -Value "`r`n$userJsLine`r`n" -Encoding UTF8
    }
  } else {
    Set-Content -Path $userJsPath -Value "$userJsLine`r`n" -Encoding UTF8
  }

  Write-Host "Patched OpenKiosk profile:" $profileDir
}

Write-Host "`nDone. Restart OpenKiosk (run it as $Username)."
