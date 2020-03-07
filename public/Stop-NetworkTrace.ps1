function Stop-NetworkTrace
{
<#
.NOTES
Function Name   : Stop-NetworkCapture
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (08/10/2016)
Requires        :

.SYNOPSIS
A wrapper for netsh to stop a network trace
.DESCRIPTION
A wrapper for netsh to stop a network trace
.EXAMPLE
Stop-NetworkCapture
#>

    begin {
        $abort = $false

        if ($IsLinux -or $IsMacOS) {
            write-warning "This command is supported on Windows platforms only"
            $abort = $true
            return
        }
        
        # requires admin rights, exit if not running as an administrator
        If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            write-error "The powershell session must be run as an administrator"
            $abort = $true
        }
    }

    process {
        if (!$abort) {
            netsh trace stop
        }
    }
}

