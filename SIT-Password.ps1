<#___                                            _ 
 | _ \  __ _   ___  ___ __ __ __  ___   _ _   __| |
 |  _/ / _` | (_-< (_-< \ V  V / / _ \ | '_| / _` |
 |_|   \__,_| /__/ /__/  \_/\_/  \___/ |_|   \__,_|
 #>

## Simple Password generator for reading passwords out over the phone
## Because everyone hates a password like Xoza9231
function Get-SimplePassword {
    $ColourArray = @("Red", "Orange", "Blue", "Pink", "Purple", "Green", "Black", "White", "Yellow", "Gold", "Silver", "Tall", "Little")
    $ItemArray = @("Cake","Rabbit","Flower","Bird","Carrot","Cheese","Dog","Cat","Apple", "Horse", "Lizard")
    $SymbolArray = @("!", "@", "#", "$", "%", "&", "*", "?", "+")

    $Colour = $ColourArray[(Get-Random -Maximum $ColourArray.Count)]
    $Item = $ItemArray[(Get-Random -Maximum $ItemArray.Count)]
    $Number = Get-Random -Maximum 99    
    $Symbol = $SymbolArray[(Get-Random -Maximum $SymbolArray.Count)]

    Return ($Colour + $Item + $Number + $Symbol)
}


<###############################################################################
    Phasing the below stuff out in favour of KeePass
###############################################################################>

## Retrieves Admin User / Pass from encrypted file. Returns as array
function Get-TenantInformation() {
    param(
        [Parameter(Mandatory=$True)][string]$Tenant
    )

    $Data = Get-KeePassEntry -AsPlainText -DatabaseProfileName work -KeePassEntryGroupPath work/o365 

    foreach($Row in $Data) {
        ## Searching txt file for the Tenant
        if($Row.Title -match $Tenant) {
            $Username = $Row.UserName
            $Password = $Row.Password
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