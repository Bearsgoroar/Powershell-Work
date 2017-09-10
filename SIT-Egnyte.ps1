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