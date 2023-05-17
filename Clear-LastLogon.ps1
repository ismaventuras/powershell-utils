<#
.SYNOPSIS
    This script enables you to clear the last logged on user from the welcome screen.
    The script will ask for admin credentials on the remote computer if process doesn't have enough admin rights
.NOTES
    Name: Clear-LastLogon
    Version: 1.0
    DateCreated: 17-May-2023
    RequiresAdmin: False
.EXAMPLE
    .\Clear-LastLogon.ps1 ComputerName
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ComputerName
)

if ($ComputerName -eq $env:COMPUTERNAME) {   
    Write-Host "
    This script only works for remote computers. 
    to remove the last logon on your local computer,lease run the following command as admin:
    "
    Write-Host "
        Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\' -Name 'LastLoggedOn*'
    " -ForegroundColor yellow  
    exit(-1)
}


## if its a remote computer, open a new pssession

function Clear-Registry {
    param (
        [System.Management.Automation.Runspaces.PSSession] $Session
    )
    Invoke-Command -Session $Session -ScriptBlock {
        Remove-ItemProperty `
            -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\" `
            -Name "LastLoggedOn*"
    } 
    Write-Host "Removed last logged on user at $ComputerName"
    Remove-PSSession $Session
}

try {
    $Session = New-PSSession $ComputerName -ErrorAction Stop
    Clear-Registry -Session $Session    
}
catch {
    if ($_.Exception -is [System.Management.Automation.Remoting.PSRemotingTransportException]) {
        $Credential = Get-Credential -Message 'Access denied. Please use an account with admin rights'
        $Session = New-PSSession $ComputerName -ErrorAction Stop -Credential $Credential
        Clear-Registry -Session $Session 
    }
    else {
        throw $_
    }
}


