﻿<# ___    ____   __   ___ 
  / _ \  |__ /  / /  | __|
 | (_) |  |_ \ / _ \ |__ \
  \___/  |___/ \___/ |___/
#>

## Does the leg work for connecting. Get-TenantInformation passes the User/Pass to it
function Connect-Office365 {
    param(
        [Parameter(Mandatory=$True)][string]$Username,
        [Parameter(Mandatory=$True)]$Password
    )
    ## Making sure our module is loaded
    Import-Module MsOnline -DisableNameChecking

    $Tenant = $Username -replace "^.*@", ""
    
    ## I have a function to do this usually but for portablity purposes.. this'll work
    Write-Host "  Connect  " -ForegroundColor White -BackgroundColor DarkMagenta -NoNewline 
    Write-Host " $Tenant" -ForegroundColor White -BackgroundColor Black
    
    ## Account details. I'm terrible here and actually convert our encrypted string to plain
    ## Text and then back to an encrypted string... defeating the purpose really
    $Password =  $Password | ConvertTo-SecureString -AsPlainText -Force
    $Credentials = New-Object -typename System.Management.Automation.PSCredential($Username, $Password)
    
    ## Importing our O365 commands into the current session if they haven't been already.
    ## Only needs to run once per powershell session
    if((Get-PSSession) -eq $False -or (Get-PSSession) -eq $Null) {
        ## I have a function to do this usually but for portablity purposes.. this'll work
        Write-Host "  Warning  " -ForegroundColor White -BackgroundColor Yellow -NoNewline 
        Write-Host " No O365 commands detected; importing" -ForegroundColor White -BackgroundColor Black

        ## Connecting to O365 to import commands. $a is to silence output
        $Session = New-PSSession -Name "Office365" -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $Credentials -Authentication Basic -AllowRedirection -WarningAction SilentlyContinue
        $a = Import-PSSession $Session -AllowClobber -WarningAction SilentlyContinue -DisableNameChecking
        
        ## I have a function to do this usually but for portablity purposes.. this'll work
        Write-Host "  Success  " -ForegroundColor White -BackgroundColor Green -NoNewline 
        Write-Host " Imported O365 commands" -ForegroundColor White -BackgroundColor Black

        ## This is the bit that actually auths us with the specific O365 tenant
        Connect-MsolService -Credential $Credentials -WarningAction SilentlyContinue
    }

    else { Connect-MsolService -Credential $Credentials -WarningAction SilentlyContinue }
}


## Connects to all the Tenants in Get-TenantInformation and gets a list of users
## for Reset-Passwords Dynamic Param (Tab-Complete)
function Create-UPNList {
    param(
        [Parameter(Mandatory=$False)][string]$Path = "C:\PSScripts\UPNList.txt"
    )
    
    foreach($Item in (Get-Content -Path C:\PSScripts\Tenants.txt)) {
        ## This is the core part of the Get-TenantInformation script
        ## I was to lazy to fix up the actual function to allow me to do this
        ## As it won't be used in the final version
        $SecureKey = $Item -replace ".*com=", "" | ConvertTo-SecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureKey)
        $Data = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        
        ## Removing any of the markers I use to make extracting the info easy
        $Username = $Data -replace "-------.*", ""
        $Password = $Data -replace ".*-------", ""
        $Tenant = $Username -replace ".*@", ""

        ## Connecting to the tenant
        Connect-Office365 -Username $Username -Password $Password
        
        ## Getting all the UPNs and exporting them
        (Get-MsolUser).UserPrincipalName | Out-File -FilePath $Path -Append

        ## I have a function to do this usually but for portablity purposes.. this'll work
        Write-Host "  Success  " -ForegroundColor White -BackgroundColor Green -NoNewline 
        Write-Host " Exported UPNs from $Tenant" -ForegroundColor White -BackgroundColor Black
    }
}



