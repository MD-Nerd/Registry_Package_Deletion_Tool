
Write-Warning "Warning: This script is only meant to be used at the discretion of the Microsoft Support Engineer. Future uses without supervisory of a Microsoft Engineer are not supported."
$KB_Number = Read-Host "`nPlease enter the full KB number, for example, KB450765"


$Packages = (Get-item -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\*$($KB_Number)*").Name
$Packages

if($Packages -eq $null)
{
    Read-host "`nInvalid KB or KB does not exist. Press any key to exit."
    Exit
}

$Export_Reg_Key_Prompt = Read-Host "`nWould you like to backup the registry keys before moving forward? Respond 'Y' for Yes or 'N' for No"
if($Export_Reg_Key_Prompt -eq "Y")
{
    $Current_Directory = get-location
    $Location = Read-Host "`nWhere would you like to export the registry keys?"

    ForEach($package in $packages)
    {
        $Package_Name = $package.replace("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\","").trim()
        $Reg_Backup_Location = $Package.replace("HKEY_LOCAL_MACHINE","HKLM")

        if(!(Test-Path "$($Location)\$($Package_Name).reg"))
        {
            reg export $Reg_Backup_Location "$($Location)\$($Package_Name).reg"
        }
        else
        {
            Write-Host "`nA backup of the registry key $($Package_name) currently exists at this location. Please delete these backups before proceeding, or change directories."
        }
    }

}
if($Export_Reg_Key_Prompt -eq "N")
{
    
}
if($Export_Reg_Key_Prompt -ne 'N' -and $Export_Reg_Key_Prompt -ne 'Y')
{
    Read-host "`nInvalid backup option. Press any key to exit."
    Exit
}




$Accept_Consequences = Read-Host "`nThe above packages will be permenantly deleted from the registry. Respond 'Y' to continue"

if($Accept_Consequences -eq 'Y')
{
        forEach($Package in $Packages)
        {
 
                $whoami = whoami
                $Original_Owner = (get-acl $Package.replace("HKEY_LOCAL_MACHINE","HKLM:")).owner

                Write-Host "`nChanging Ownership of the targeted package..."

                $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($Package.replace("HKEY_LOCAL_MACHINE\","") ,[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::takeownership)

                $acl = $key.GetAccessControl([System.Security.AccessControl.AccessControlSections]::None)
                $me = [System.Security.Principal.NTAccount]$whoami
                $acl.SetOwner($me)
                $key.SetAccessControl($acl)

                $acl = $key.GetAccessControl()
                $rule = New-Object System.Security.AccessControl.RegistryAccessRule ($whoami,"FullControl","Allow")
                $acl.SetAccessRule($rule)
                $key.SetAccessControl($acl)

                Write-Host "Package : $($Package) is now:" 
                get-acl $Package.replace("HKEY_LOCAL_MACHINE","HKLM:") | Select Owner | format-list

                Write-Host "Starting deletion of targeted packages...`n"

                Remove-Item -Path $Package.replace("HKEY_LOCAL_MACHINE","HKLM:")  -Force -Verbose -recurse

                if(!(test-path $Package.replace("HKEY_LOCAL_MACHINE","HKLM:")))
                {
                    Write-Host "`nThe registry package entry has been deleted..."
                }
                else
                {
                    Write-Host "`nThe registry package entry was not deleted."
                }
            
           
        }
        
       
}
else
{
    Read-Host "`nInvalid entry. Press any key to exit."
    Exit
}
