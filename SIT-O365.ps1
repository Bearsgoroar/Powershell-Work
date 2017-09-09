<#
## This is for a quick setup for demo purposes. None of the data or passwords here are used for anything :)
## Pre-reqs: http://connect.microsoft.com/site1164/Downloads/DownloadDetails.aspx?DownloadID=59185
             http://www.microsoft.com/en-us/download/details.aspx?id=28177

## This'll save you from changing paths in the below code
New-Item -Path C:\ -Name PSScripts -ItemType Directory
New-Item -Path C:\PSScripts -Name Tenants.txt -ItemType File
New-Item -Path C:\PSScripts -Name UPNList.txt -ItemType File

## Creates the encrypted data for connecting to tenants
Set-TenantInformation -Tenant swisspers.onmicrosoft.com -Username administrator@swisspers.onmicrosoft.com -Password "UK0&@51bJJ()"
Set-TenantInformation -Tenant fantasycharacters.onmicrosoft.com -Username administrator@fantasycharacters.onmicrosoft.com -Password "UK0&@51bJJ()"

## Creates our list of UPNs for tab-complete
Create-UPNList

## Reset password
Reset-Password -Type O365
#>


<# ___    ____   __   ___ 
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

## Retrieves Admin User / Pass from encrypted file. Returns as array
function Get-TenantInformation() {
    param(
        [Parameter(Mandatory=$True)][string]$Tenant
    )

    $Data = Get-Content -Path "C:\PSScripts\Tenants.txt"

    foreach($Row in $Data) {
        ## Searching txt file for the Tenant
        if($Row -match $Tenant) {
            ## Basic encryption of tenant data. Only works on the PC that encrypted
            $SecureKey = $Row -replace ".*com=", "" | ConvertTo-SecureString
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureKey)
            $Data = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            
            ## Removing any of the markers I use to make extracting the info easy
            $Username = $Data -replace "-------.*", ""
            $Password = $Data -replace ".*-------", ""
        }
    }

    Return @{"Tenant" = "$Tenant"; "Username" = "$Username"; "Password" = "$Password"}
}

## For adding new Tenants / Admin Users / passwords to the Tenants.txt file.
function Set-TenantInformation() {
    param(
        [Parameter(Mandatory=$True)][string]$Tenant,
        [Parameter(Mandatory=$True)][string]$Username,
        [Parameter(Mandatory=$True)][string]$Password
    )

    $Data = Get-ChildItem -Path "C:\PSScripts\Tenants.txt"

    ## Formating to make it easier to pull data out
    $Key = "$Username-------$Password"

    ## The Magic. This is only decryptable on the same PC as it was encrypted
    ## Won't be used in the final version
    $SecureKey = ConvertTo-SecureString $Key -AsPlainText -Force | ConvertFrom-SecureString
    
    ## Adding now encrypted data to our text file for slightly safe storage
    Add-Content -Path $Data "$Tenant=$SecureKey"
    Write-Host "Added $Tenant=$Key"
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

## Simple Password generator for reading passwords out over the phone
## Because everyone hates a password like Xoza9231
function Get-SimplePassword {
    $ColourArray = @("Red", "Orange", "Blue", "Pink", "Purple", "Green", "Black", "White", "Yellow", "Gold", "Silver")
    $ItemArray = @("Cake","Rabbit","Flower","Bird","Carrot","Cheese","Dog","Cat","Apple", "Horse", "Lizard")
    $SymbolArray = @("!", "@", "#", "$", "%", "&", "*", "?", "+")

    $Colour = $ColourArray[(Get-Random -Maximum $ColourArray.Count)]
    $Item = $ItemArray[(Get-Random -Maximum $ItemArray.Count)]
    $Number = Get-Random -Maximum 99    
    $Symbol = $SymbolArray[(Get-Random -Maximum $SymbolArray.Count)]

    Return ($Colour + $Item + $Number + $Symbol)
}

<#__   __  ___   _  _ 
  \ \ / / | _ \ | \| |
   \ V /  |  _/ | .` |
    \_/   |_|   |_|\_|
VPN is not currently in use
#>

## Will be a check to see if the VPN already exists / created and if not create it
function Resolve-VPNName {
    param([Parameter(Mandatory=$True)][string]$Check)

    foreach($VPN in Get-VPNConnection) {
        if($Check -match $VPN.name) {
            Write-Host "Found requested VPN: $Check"
            Return $True
        }
    }

    else {
        Write-Host "VPN not found!"
        Exit
        #Invoke-WebRequest -uri wiki.com.au
        #Add-VpnConnection
    }
}

## Connects to VPN for AD / Exchange / NAS
function Connect-VPN {
    param(
        [Parameter(Mandatory=$True)][string]$VPNName
    )

    #test-connection to one of your servers on the vpn network
    #get-addomain
    #get-addomaincontroller

    rasdial $VPNName
}

<# 
  ___                        _         
 | __|  __ _   _ _    _  _  | |_   ___ 
 | _|  / _` | | ' \  | || | |  _| / -_)
 |___| \__, | |_||_|  \_, |  \__| \___|
       |___/          |__/  
Egnyte is kinda maybe not currently in use.
#>

function Send-EgnyteAuthRequest {
    $APIKey = "y9x8hp7wtzeapd85tydf3cxz"
    $Username = "bearsgoroar"
    $Password = "UK0&@51bJJ()"

    $BaseURL = "https://bearsgoroar.egnyte.com/puboauth/token?client_id=$APIKey&username=$Username&password=$Password&grant_type=password"

    Return (Invoke-WebRequest -uri $BaseURL -ContentType "application/x-www-form-urlencoded" -Method Post).Content -replace '{"access_token":"', '' -replace '",".*$', ''
}

function Get-EgnyteUserID {
    param(
        [Parameter(Mandatory=$False)][string]$AuthToken,
        [Parameter(Mandatory=$False)][string]$Name,
        [Parameter(Mandatory=$False)][string]$BaseURL = "https://bearsgoroar.egnyte.com"
    )

    $e = @{
        Method  = "Get"
        Uri     = "https://bearsgoroar.egnyte.com/pubapi/v2/users"
        Headers = @{
            Authorization = "Bearer $AuthToken"
            Accept        = "application/json" 
        }
    }

    $Results = Invoke-RestMethod @e

    foreach($Item in $Results.resources) {
        if($Name -match $Item.email) {
            Return $Item.id
        }
    }
}

function Get-EgnyteUserInformation {
    param(
        [Parameter(Mandatory=$True)][string]$AuthToken,
        [Parameter(Mandatory=$True)][string]$UserID,
        [Parameter(Mandatory=$False)][string]$BaseURL = "https://bearsgoroar.egnyte.com"
    )

    $e = @{
        Method  = "Get"
        Uri     = "https://bearsgoroar.egnyte.com/pubapi/v2/users/$UserID"
        Headers = @{
            Authorization = "Bearer $AuthToken"
            Accept        = "application/json" 
        }
    }

    Return Invoke-RestMethod @e
}


<#
████████╗██╗  ██╗███████╗    ███╗   ███╗███████╗ █████╗ ████████╗
╚══██╔══╝██║  ██║██╔════╝    ████╗ ████║██╔════╝██╔══██╗╚══██╔══╝
   ██║   ███████║█████╗      ██╔████╔██║█████╗  ███████║   ██║   
   ██║   ██╔══██║██╔══╝      ██║╚██╔╝██║██╔══╝  ██╔══██║   ██║   
   ██║   ██║  ██║███████╗    ██║ ╚═╝ ██║███████╗██║  ██║   ██║   
   ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝
 #>

## Does as it says
Function Reset-Password {
    param(
        [Parameter(Mandatory=$True)][string][ValidateSet("AD", "O365", "Exchange", "Egnyte", "NAS")]$Type,
        [Parameter(Mandatory=$False)][string]$Password = (Get-SimplePassword),
        [Parameter(Mandatory=$False)][switch]$ForceChangePassword
    )

    ## Pulls data from the UPNList created via Create-UPNList
    DynamicParam {
        ## DynamicParam from https://stackoverflow.com/questions/30111408/powershell-multiple-parameters-for-a-tabexpansion-argumentcompleter

        ## UPN Directory
        $UPNList = "C:\PSScripts\UPNList.txt"
        if(!(Test-Path $UPNList)) { 
            Write-Error -Message "UPNList not found. Attempting to create list at default destination"
            Create-UPNList
        }
        
        $ParamNames = @('UPN')

        #Create Param Dictionary
        $ParamDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary

        ForEach($Name in $ParamNames){
            #Create a container for the new parameter's various attributes, like Manditory, HelpMessage, etc that usually goes in the [Parameter()] part
            $ParamAttribCollecton = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]

            #Create each attribute
            $ParamAttrib = new-object System.Management.Automation.ParameterAttribute
            $ParamAttrib.Mandatory = $False
            $ParamAttrib.Position = 2

            #Create ValidationSet to make tab-complete work
            $arrSet = Get-Content -Path $UPNList
            $ParamValSet = New-Object -type System.Management.Automation.ValidateSetAttribute($arrSet)

            #Add attributes and validationset to the container
            $ParamAttribCollecton.Add($ParamAttrib)
            $ParamAttribCollecton.Add($ParamValSet)

            #Create the actual parameter,  then add it to the Param Dictionary
            $MyParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter($Name, [String], $ParamAttribCollecton)
            $ParamDictionary.Add($Name, $MyParam)
        }

        #Return the param dictionary so the function can add the parameters to itself
        return $ParamDictionary
    }

    begin {
        ## Setting UPN from dynparam
        $UPN = $PsBoundParameters["UPN"]

        ## Setting Tenant param if not supplied
        if([string]::IsNullOrEmpty($Tenant)) { $Tenant = $UPN -replace ".*@", "" }

        ## Getting Tenant login information
        $LoginDetails = Get-TenantInformation -Tenant $Tenant

        ## Setting the value of Forcepasswordchange to true if switch was called
        $Switch1 = $False
        if($ForceChangePassword -eq $True) { $Switch1 = $True}
    }

    process {
        Switch($Type) {
            O365 {
                ## Uses the login details from Get-TenantInformation to login to O365 (Get-MSOLOnline)
                Connect-Office365 -Username $LoginDetails.Username -Password $LoginDetails.Password
                
                ## I'm lazy here and only doing extremely basic error checking. You'll see the error if it fails otherwise
                $NewPassword = Set-MsolUserPassword -UserPrincipalName $UPN -NewPassword $Password -ForceChangePassword:$Switch1
                if($NewPassword -ne $Null) {
                    Write-Host "  Success  " -ForegroundColor White -BackgroundColor Green -NoNewline 
                    Write-Host " New Password is: $NewPassword " -ForegroundColor White -BackgroundColor Black -NoNewline
                }
            }

            ## Egnyte
            Egnyte {
                $Token = Send-EgnyteAuthRequest
                $EgnyteID = Get-EgnyteUserID -Name $UPN -AuthToken $Token
                $User = Get-EgnyteUserInformation -AuthToken $Token -UserID $EgnyteID

                $User.email
            }

            ## Active Directory
            AD {
                if((Resolve-VPNName $Tenant) -eq $True) {
                    Connect-VPN -VPNName $Tenant
                }
            }

            ## Exchange
            Exchange {
                if((Resolve-VPNName $Tenant) -eq $True) {
                    Connect-VPN -VPNName $Tenant
                }
            }
        
            ## NAS
            NAS {
                if((Resolve-VPNName $Tenant) -eq $True) {
                    Connect-VPN -VPNName $Tenant
                }
            }  
        }
    }
}










#$users = Import-Csv C:\PSScripts\swisspers.csv
#$users | ForEach-Object { 
#    $UPN = ($_.FirstName[0] + ($_.LastName -replace " ", "") + "@swisspers.onmicrosoft.com")
#    New-MsolUser -UserPrincipalName $UPN -DisplayName ($_.FirstName + " " + $_.LastName) -FirstName $_.FirstName -LastName $_.LastName
#}