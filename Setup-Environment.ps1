function Setup-SITEnvironment {
    
    if((Test-Path -LiteralPath C:\SITPOSH) -eq $False) {
        New-Item -Path "C:\" -Name "SITPOSH" -ItemType Directory
        New-Item -Path "C:\SITPOSH" -Name "KeePass" -ItemType Directory
    }


    ## Keepass
    $KeePassURL = "https://downloads.sourceforge.net/project/keepass/KeePass%202.x/2.36/KeePass-2.36.zip?r=&ts=1505019468&use_mirror=nchc"
    Invoke-WebRequest -Uri $KeePassURL -OutFile "C:\SITPOSH\KeePass\KeePass.zip"

    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::ExtractToDirectory("C:\SITPOSH\KeePass\KeePass.zip", "C:\SITPOSH\KeePass")

    New-KeePassDatabaseConfiguration -DatabaseProfileName Work -DatabasePath C:\SITPOSH\KeePass\Work.kdbx -KeyPath E:\Other\AAS-Wiki.ppk


    ## Office 365
    #http://connect.microsoft.com/site1164/Downloads/DownloadDetails.aspx?DownloadID=59185
    #http://www.microsoft.com/en-us/download/details.aspx?id=28177

    ## Github
}