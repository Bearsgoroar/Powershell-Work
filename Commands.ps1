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