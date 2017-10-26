function Reload-Modules {
## Unloading all my modules first because -Force doesn't always work
Get-Module | Remove-Module

## Directory where my scripts are stored
$PSDirAutoload="C:\PSScripts\Autoload"
$PSDirGitScripts="C:\SITPOSH"
Set-Location "C:\PSScripts"

## Load all 'autoload' scripts
foreach($File in (Get-ChildItem $PSDirAutoload -Filter *.ps1)) {
        if($File.Fullname -match ".*~$") { Continue }
        Import-Module $File.fullname -Force
        Unblock-File -Path $File.fullname
        Write-Message -Type Load -Text $File.Name
}

## Load all gitscripts
Import-Module posh-git
Write-Message -Type Load -Text posh-git.psm1
foreach($File in (Get-ChildItem $PSDirGitScripts -Filter *.ps1)) {
        Import-Module $File.fullname -Force
        Unblock-File -Path $File.fullname
        Write-Message -Type Blank -Text $File.Name -Prefix Loaded
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
        Import-Module "$ChocolateyProfile" -force
        Write-Message -Type Load -Text chocolateyProfile.psm1
}

Write-Host "Custom PowerShell Environment Loaded" -ForegroundColor Green -BackgroundColor Black
