param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$UserName
)
<#
##########################################################################################

DisableCtrlAltDelOptions.ps1   Version 1.00 17-Jun-2026
A Windows Powerscript to disable Ctrl+Alt+Delete Options for the specified user.
This would typically be for the MOTUS_USER account.  It prevents someone with access
to the keyboard from being able to break-out of the kiosk and access:
    TaskMgr
    LockWorkstation
    ChangePassword 
    Logoff    
*******************************************************************************************

PREREQUISITES:  Need to enable powershell scripts to be run on the computer.
- run Windows Powershell console app as administrator

Then enter the following commands:

Set-ExecutionPolicy unrestricted

powershell -File  "C:\Users\MOTUS_USER\Projects\MOTUS_KIOSK\code\DisableCtrlAltDelOptions.ps1" MOTUS_USER

Set-ExecutionPolicy restricted

Test: Log out of MOTUS_USER and log back in, type Ctrl+Alt+Del on keyboard. The only
option shown should be "Cancel"  

*******************************************************************************************************************************
** All code is for demonstration only and should be used at your own risk. I cannot accept liability for unexpected results. **
*******************************************************************************************************************************

##########################################################################################
#>
$user = Get-LocalUser -Name $UserName -ErrorAction Stop
$sid = $user.SID.Value
$hku = "Registry::HKEY_USERS\$sid"

$loadedHive = $false

if (-not (Test-Path $hku)) {
    $profile = Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $sid }

    if (-not $profile) {
        throw "User profile for '$UserName' not found. Log in once as that user, then rerun this script."
    }

    $ntuser = Join-Path $profile.LocalPath "NTUSER.DAT"

    reg load "HKU\$sid" "$ntuser" | Out-Null
    $loadedHive = $true
}

try {
    $systemPath   = "$hku\Software\Microsoft\Windows\CurrentVersion\Policies\System"
    $explorerPath = "$hku\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"

    New-Item -Path $systemPath -Force | Out-Null
    New-Item -Path $explorerPath -Force | Out-Null

    # Ctrl+Alt+Del options for this user only
    New-ItemProperty -Path $systemPath   -Name DisableTaskMgr         -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $systemPath   -Name DisableLockWorkstation -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $systemPath   -Name DisableChangePassword  -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $explorerPath -Name NoLogoff               -Value 1 -PropertyType DWord -Force | Out-Null

    Write-Host "Done. Ctrl+Alt+Del options restricted for $UserName only."
}
finally {
    if ($loadedHive) {
        reg unload "HKU\$sid" | Out-Null
    }
}