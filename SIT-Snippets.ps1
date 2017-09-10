<#___          _                       _        
 / __|  _ _   (_)  _ __   _ __   ___  | |_   ___
 \__ \ | ' \  | | | '_ \ | '_ \ / -_) |  _| (_-<
 |___/ |_||_| |_| | .__/ | .__/ \___|  \__| /__/
                  |_|    |_|                    
#>

#$users = Import-Csv C:\PSScripts\swisspers.csv
#$users | ForEach-Object { 
#    $UPN = ($_.FirstName[0] + ($_.LastName -replace " ", "") + "@swisspers.onmicrosoft.com")
#    New-MsolUser -UserPrincipalName $UPN -DisplayName ($_.FirstName + " " + $_.LastName) -FirstName $_.FirstName -LastName $_.LastName
#}