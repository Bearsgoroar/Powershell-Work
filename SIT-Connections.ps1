<# ___                                  _     _                   
  / __|  ___   _ _    _ _    ___   __  | |_  (_)  ___   _ _    ___
 | (__  / _ \ | ' \  | ' \  / -_) / _| |  _| | | / _ \ | ' \  (_-<
  \___| \___/ |_||_| |_||_| \___| \__|  \__| |_| \___/ |_||_| /__/
#>

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
