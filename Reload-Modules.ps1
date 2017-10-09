function Reload-Modules {
    foreach($Script in (Get-ChildItem -Path C:\SITPOSH -filter "*.ps1")) { Import-Module $Script.PSPath}
}