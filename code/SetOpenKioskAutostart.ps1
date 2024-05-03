param(
  [string]$suppliedUserName
)

<#

*****************************************************************************************************
SetOpenKioskAutostart.ps1   Version 1.00 02-May-2024
A Windows Powerscript to make a registry setting that runs OpenKiosk at login for the specified user.
*****************************************************************************************************

PREREQUISITES:  Need to enable powershell scripts to be run on the computer.
- run Windows Powershell console app as administrator

Then enter the following commands:
Set-ExecutionPolicy unrestricted

powershell -File  "C:\Users\MOTUS_USER\Projects\MOTUS_KIOSK\code\SetOpenKioskAutostart.ps1" MOTUS_USER

Set-ExecutionPolicy restricted

Test: Log out of MOTUS_USER and log back in,  OpenKiosk should start automatically

  Based on a powershell script by Christopher Kibble found at:
  https://christopherkibble.com/posts/making-registry-changes-users-powershell/

*******************************************************************************************************************************
** All code is for demonstration only and should be used at your own risk. I cannot accept liability for unexpected results. **
*******************************************************************************************************************************

Use: You're welcome to use, modify, and distribute this script.  I'd love to hear about how you're using it or 
modifications you've made in the comments section of the original post over at ChristopherKibble.com.

#>

# This key contains all of the profiles on the machine (including non-user profiles)
$profileList = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

# This key contains the path to the folder that contains all the profiles (typically c:\users)
$profileFolder = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList').ProfilesDirectory

# This key contains the path to the default user profile (e.g. C:\Users\Default).  This is **NOT** HKEY_USERS\.DEFAULT!
# We don't do anything with it in this sample script, but it can be loaded and modified just like any other profile.
$defaultFolder = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList').Default

# HKEY_USER key is not loaded into PowerShell by default and we'll need it, so we'll create new PSDrive to reference it.
New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null

if (-not $suppliedUserName) {
  Write-Output "Error: Please supply a user name"
  exit
}

$targetUserString= "C:\Users\$suppliedUserName"

$RegistryPathTail = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon"
$RegistryItemName = "Shell"
$Cmd = '"C:\Program Files\OpenKiosk\OpenKiosk.exe"'
$Arg= 'http://localhost:8081'
$RegistryItemValue = $Cmd + " " + $Arg


$booleanUserFound = $false
$booleanRegistryValueSet = $false

$profileList | % {
	
	$profileKeys = Get-ItemProperty $_.PSPath
	
	$sid = $profileKeys.PSChildName
	$profilePath = $profileKeys.ProfileImagePath
	
	# This is an easy way to exclude profiles outside of the default USERS profile folder, e.g. LocalSystem.
	# You may or may not want to do this depending on your requirements.
	if ($profilePath -like "$($profileFolder)*") {
		#Write-Output "-------------------------------------------"
		# Check if the profile is already loaded.		
		if (Get-ChildItem "HKU:\$sid" -ErrorAction SilentlyContinue) {
			$profileLoaded = $true
		} else {
			$profileLoaded = $false
		}
		
		## Write-Output "For User: $sid \`t $profilePath \`t $profileLoaded"
		
		# Load the key if necessary
		if ($profileLoaded) {
			## Write-Output "USER ONLINE for SID:$sid"
			$RegistryPathHead = "HKU:\$sid"
		} else {
			#Write-Output "USER OFFLINE for SID:$sid  ... LOADING from hive"
			$RegistryPathHead = "HKLM:\TempHive_$sid"
			$null = reg.exe load "HKLM\TempHive_$sid" "$profilePath\ntuser.dat" /wait /nonewwindow /passthru 2>$null
			#& reg.exe load "HKLM\TempHive_$sid" "$profilePath\ntuser.dat"
		}
		
		## Have a user's path, test if its the target user

		if ( $profilePath -eq $targetUserString ) {
                        ##  matches - try to update their registry with our key/value entry
			Write-Output "Found registry for user: $targetUserString"
			$booleanUserFound = $true
			## Write-Output "$RegistryPathHead"
 			$RegistryPath = "$RegistryPathHead\$RegistryPathTail"
                        #Write-Output "Attempt to update registry at: $RegistryPath"
			Write-Output "Attempt to update their registry."	

			try {
				New-ItemProperty -Path $RegistryPath -Name $RegistryItemName -Value $RegistryItemValue -PropertyType String -Force | Out-Null
				$booleanRegistryValueSet = $true
				Write-Output "Success: updated the registry key"
				exit
			} catch {
				
                        	$booleanRegistryValueSet = $false
				Write-Output "Error: Failed to update the registry key"
				exit
			}
		}

		
		if (!$profileLoaded) {
			#Write-Output "UNLOAD OFFLINE USER for SID:$sid"
			$null = reg.exe unload "HKLM\TempHive_$sid" /wait /nonewwindow /passthru 2>$null
			#& reg.exe unload "HKLM\TempHive_$sid"
		}	
	}
	#Write-Output "next user"
}

Remove-PSDrive -Name HKU

if ( -not $booleanUserFound ) {
Write-Output "Error: User named $suppliedUserName not found in registry."
}
if ( -not $booleanRegistryValueSet ) {
Write-Output "Error: Registry value of user $suppliedUserName not set."
}

