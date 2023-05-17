#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Copy Chrome bookmarks from one PC to another based on matching user profiles.
.PARAMETER SourceComputer
    The name or IP address of the source PC where the Chrome bookmarks will be copied from
.PARAMETER DestinationComputer
    The name or IP address of the destination PC where the Chrome bookmarks will be copied to
.EXAMPLE
    .\Copy-ChromeBookmarks.ps1 -SourceComputer $env:COMPUTERNAME -DestinationComputer ComputerName
.NOTES
    - The script requires admin privileges on both source and destination computer.
    - The script does not check if source or destination computer are online.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$SourceComputer,
    [Parameter(Mandatory=$true)]
    [string]$DestinationComputer
)

$CHROME_BOOKMARKS_PATH = "AppData\Local\Google\Chrome\User Data\Default\Bookmarks"

$SourceProfiles = Get-ChildItem -Path "\\$SourceComputer\c$\users" -Directory
$DestinationProfiles = Get-ChildItem -Path "\\$DestinationComputer\c$\users" -Directory

foreach ($SourceProfile in $SourceProfiles) {
    $DestinationProfile = $DestinationProfiles | Where-Object {$_.Name -eq $SourceProfile.Name}
    if($DestinationProfile){
        $SourcePath = Join-Path -Path $SourceProfile.FullName -ChildPath $CHROME_BOOKMARKS_PATH
        $DestinationPath = Join-Path -Path $DestinationProfile.FullName -ChildPath $CHROME_BOOKMARKS_PATH
        $DestinationFolder = Split-Path $DestinationPath
        if(-not (Test-Path $DestinationFolder)){
            New-item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
        }
        try {
            Copy-Item -Path $SourcePath -Destination $DestinationPath -Force -ErrorAction Stop
            Write-Host "Bookmarks copied for user $($SourceProfile.Name)"            
        }
        catch {
            if (-not $_.Exception -match 'Cannot find path'){
                Write-Error $_
            }
        }
    }
}