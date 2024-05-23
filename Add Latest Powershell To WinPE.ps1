<#
.Synopsis
    Sample script for Deployment Research
.DESCRIPTION
    Created: 2022-07-01
    Version: 1.0
    
    Author : Johan Arwidmark, modified by Dede333 (add $WinPE_Lang for regional and language)
    Twitter: @jarwidmark
    Blog   : https://deploymentresearch.com

    Disclaimer: This script is provided "AS IS" with no warranties, confers no rights and 
    is not supported by the author or DeploymentArtist..
.EXAMPLE
    N/A
#>

#Requires -RunAsAdministrator

# You must create a folder "C:\Setup\" with last powershell version
# You must create a folder "C:\Setup\WinPE_x64
# You must create a folder "C:\Mount"
# You must create a folder "C:\ISO"

$PowerShell7File = "C:\Setup\PowerShell-7.4.2-win-x64.zip"                            # Powershell Filename of last release 
$WinPE_BuildFolder = "C:\Setup\WinPE_x64"                                             # 
$WinPE_Architecture = "amd64" # Or x86                                                # You must change for your architecture used
$WinPE_MountFolder = "C:\Mount"                                                       # point of mount (WinPE)
$WinPE_ISOFolder = "C:\ISO"                                                           # ISO folder
$WinPE_ISOfile = "$WinPE_ISOFolder\WinPE11_x64_PowerShell7.iso"                       # Filename of ISO
$WinPE_Lang = "fr-fr"																  # Regional, Language

$ADK_Path = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit"    # Path to ADK
$WinPE_ADK_Path = $ADK_Path + "\Windows Preinstallation Environment"                  # Path to Windows Preinstallation Environment
$WinPE_OCs_Path = $WinPE_ADK_Path + "\$WinPE_Architecture\WinPE_OCs"                  # Path to WinPE OCs
$DISM_Path = $ADK_Path + "\Deployment Tools" + "\$WinPE_Architecture\DISM"            # Path to DISM from architecture used
$OSCDIMG_Path = $ADK_Path + "\Deployment Tools" + "\$WinPE_Architecture\Oscdimg"      # Path to Oscdimg

# Validate locations
# ADK installation is require
If (!(Test-path $OSCDIMG_Path)){ Write-Warning "OSCDIMG Path does not exist, aborting...";Break}
# Last release of powershell is require
If (!(Test-path $PowerShell7File)){ Write-Warning "PowerShell7File Path does not exist, aborting...";Break}


# Delete existing WinPE build folder (if exist)
try 
{
# Delete all files on $WinPE_BuildFolder
if (Test-Path -path $WinPE_BuildFolder) {Remove-Item -Path $WinPE_BuildFolder -Recurse -ErrorAction Stop}
}
catch
{
    Write-Warning "Oupps, Error: $($_.Exception.Message)"
    Write-Warning "Most common reason is existing WIM still mounted, use DISM /Cleanup-Wim to clean up and run script again"
    Break
}

# Create Mount folder
New-Item -Path $WinPE_MountFolder -ItemType Directory -Force

# Create ISO folder
New-Item -Path $WinPE_ISOFolder -ItemType Directory -Force

# Make a copy of the WinPE boot image from Windows ADK
if (!(Test-Path -path "$WinPE_BuildFolder\Sources")) {New-Item "$WinPE_BuildFolder\Sources" -Type Directory}
Copy-Item "$WinPE_ADK_Path\$WinPE_Architecture\en-us\winpe.wim" "$WinPE_BuildFolder\Sources\boot.wim"

# Copy WinPE boot files
Copy-Item "$WinPE_ADK_Path\$WinPE_Architecture\Media\*" "$WinPE_BuildFolder" -Recurse
 
# Mount the WinPE image
$WimFile = "$WinPE_BuildFolder\Sources\boot.wim"
Mount-WindowsImage -ImagePath $WimFile -Path $WinPE_MountFolder -Index 1
 
# Add native WinPE optional components (using ADK version of dism.exe instead of Add-WindowsPackage)
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\$WinPE_Lang\lp.cab # install language pack
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-WMI.cab # Install WinPE-WMI before you install WinPE-NetFX (dependency)
# & $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\$WinPE_Lang\WinPE-WMI_$WinPE_Lang.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\$WinPE_Lang\WinPE-WMI_$WinPE_Lang.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-NetFx.cab
# & $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\$WinPE_Lang\WinPE-NetFx_$WinPE_Lang.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\$WinPE_Lang\WinPE-NetFx_$WinPE_Lang.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-PowerShell.cab
# & $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\$WinPE_Lang\WinPE-PowerShell_$WinPE_Lang.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\$WinPE_Lang\WinPE-PowerShell_$WinPE_Lang.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\WinPE-DismCmdlets.cab
# & $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\$WinPE_Lang\WinPE-DismCmdlets_$WinPE_Lang.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Add-Package /PackagePath:$WinPE_OCs_Path\$WinPE_Lang\WinPE-DismCmdlets_$WinPE_Lang.cab
& $DISM_Path\dism.exe /Image:$WinPE_MountFolder /Set-AllIntl:$WinPE_Lang

# Add PowerShell 7
Expand-Archive -Path $PowerShell7File -DestinationPath "$WinPE_MountFolder\Program Files\PowerShell\7" -Force

# Update the offline environment PATH for PowerShell 7
$HivePath = "$WinPE_MountFolder\Windows\System32\config\SYSTEM"
reg load "HKLM\OfflineWinPE" $HivePath 
Start-Sleep -Seconds 5

# Add PowerShell 7 Paths to Path and PSModulePath
$RegistryKey = "HKLM:\OfflineWinPE\ControlSet001\Control\Session Manager\Environment"
$CurrentPath = (Get-Item -path $RegistryKey ).GetValue('Path', '', 'DoNotExpandEnvironmentNames')
$NewPath = $CurrentPath + ";%ProgramFiles%\PowerShell\7\"
$Result = New-ItemProperty -Path $RegistryKey -Name "Path" -PropertyType ExpandString -Value $NewPath -Force 

$CurrentPSModulePath = (Get-Item -path $RegistryKey ).GetValue('PSModulePath', '', 'DoNotExpandEnvironmentNames')
$NewPSModulePath = $CurrentPSModulePath + ";%ProgramFiles%\PowerShell\;%ProgramFiles%\PowerShell\7\;%SystemRoot%\system32\config\systemprofile\Documents\PowerShell\Modules\"
$Result = New-ItemProperty -Path $RegistryKey -Name "PSModulePath" -PropertyType ExpandString -Value $NewPSModulePath -Force 


# Add additional environment variables for PowerShell Gallery Support
$APPDATA = "%SystemRoot%\System32\Config\SystemProfile\AppData\Roaming"
$Result = New-ItemProperty -Path $RegistryKey -Name "APPDATA" -PropertyType String -Value $APPDATA -Force 

$HOMEDRIVE = "%SystemDrive%"
$Result = New-ItemProperty -Path $RegistryKey -Name "HOMEDRIVE" -PropertyType String -Value $HOMEDRIVE -Force 

$HOMEPATH = "%SystemRoot%\System32\Config\SystemProfile"
$Result = New-ItemProperty -Path $RegistryKey -Name "HOMEPATH" -PropertyType String -Value $HOMEPATH -Force 

$LOCALAPPDATA = "%SystemRoot%\System32\Config\SystemProfile\AppData\Local"
$Result = New-ItemProperty -Path $RegistryKey -Name "LOCALAPPDATA" -PropertyType String -Value $LOCALAPPDATA -Force 

# Cleanup (to prevent access denied issue unloading the registry hive)
Get-Variable Result | Remove-Variable
Get-Variable RegistryKey | Remove-Variable
[gc]::collect()
Start-Sleep -Seconds 5

# Unload the registry hive
reg unload "HKLM\OfflineWinPE"  

# Write winpeshl.ini that launches PowerShell 7
$winpeshl = @'
[LaunchApps]
%WINDIR%\System32\wpeinit.exe
%ProgramFiles%\PowerShell\7\pwsh.exe
'@ | Out-File "$WinPE_MountFolder\Windows\System32\winpeshl.ini" -Force

# Write unattend.xml file to change screen resolution
$UnattendPEx64 = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <Display>
                <ColorDepth>32</ColorDepth>
                <HorizontalResolution>1280</HorizontalResolution>
                <RefreshRate>60</RefreshRate>
                <VerticalResolution>720</VerticalResolution>
            </Display>
        </component>
    </settings>
</unattend>
'@ | Out-File "$WinPE_MountFolder\Unattend.xml" -Encoding utf8 -Force

# Unmount the WinPE image and save changes
Dismount-WindowsImage -Path $WinPE_MountFolder -Save

# Create a bootable WinPE ISO file (comment out if you don't need the ISO)
$BootData='2#p0,e,b"{0}"#pEF,e,b"{1}"' -f "$OSCDIMG_Path\etfsboot.com","$OSCDIMG_Path\efisys.bin"
  
$Proc = Start-Process -FilePath "$OSCDIMG_Path\oscdimg.exe" -ArgumentList @("-bootdata:$BootData",'-u2','-udfver102',"$WinPE_BuildFolder","$WinPE_ISOfile") -PassThru -Wait -NoNewWindow
if($Proc.ExitCode -ne 0)
{
    Throw "Failed to generate ISO with exitcode: $($Proc.ExitCode)"
}