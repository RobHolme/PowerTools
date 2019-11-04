function Start-NetworkTrace
{
<#
.NOTES
Function Name   : Start-NetworkTrace
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (08/10/2016)
Requires        :

.SYNOPSIS
A wrapper for netsh to start a network trace
.DESCRIPTION
A wrapper for netsh to start a network trace
.PARAMETER TraceFile
The pathname of the file to store the network trace
.PARAMETER Protocol
Filter the trace to a single (or range of) protocols. e.g. -Protocol TCP, -Protocol !TCP, -Protocol (4..10)
.PARAMETER IPv4Address
Filter the trace for source or destination addresses matching this IPv4 address.
.PARAMETER IPv4SourceAddress
Filter the trace for source addreses matching this IPv4 address.
.PARAMETER IPv4DestinationAddress
Filter the trace for destination addreses matching this IPv4 address
.PARAMETER IPv6Address
Filter the trace for source or destination addresses matching this IPv6 address
.PARAMETER IPv6SourceAddress
Filter the trace for source addreses matching this IPv6 address.
.PARAMETER IPv6DestinationAddress
Filter the trace for destination addreses matching this IPv6 address.
.PARAMETER Persistant
Keep the trace running during reboots, until Stop-NetworkTrace CmdLet is run.
.PARAMETER MaxSize
The maximum size of the trace log file in MB. Defaults to 250MB if no prameter supplied.
.PARAMETER overwrite
A swtich to instrct netsh to overwrite any existing trace files.
.EXAMPLE
Start-NetworkTrace -TraceFile C:\temp\trac.etl
.EXAMPLE
Start-NetworkTrace -TraceFile C:\temp\trac.etl -Protocol TCP -IPv4Address 192.168.0.3
.EXAMPLE
Start-NetworkTrace -TraceFile C:\temp\trac.etl -Protocol TCP -IPv4SourceAddress 192.168.0.3 -IPv4DestinationAddress 192.168.0.1
.EXAMPLE
Start-NetworkTrace -TraceFile C:\temp\trac.etl -Protocol UDP -IPv4Address 192.168.0.3 -MaxSize 300
.EXAMPLE
Start-NetworkTrace -TraceFile C:\temp\trac.etl -Protocol !UDP -IPv4Address 192.168.0.3 -Overwrite
.EXAMPLE
Start-NetworkTrace -TraceFile C:\temp\trac.etl -IPv6Address fe80::f090:7a62:9d9:3202%17
#>
    [CmdletBinding(DefaultParametersetName="IPv4")]
    Param (
        # -Path parameter
        [Parameter(
            Mandatory=$True,
            Position = 0,
            HelpMessage='The name of the file to save the capture to.'
        )]
        [Alias('Path')]
        [string]$TraceFile,

        # -Protocol parameter. Filter the trace to a single (or range of) protocols.
        [Parameter(
            Mandatory=$false,
            HelpMessage='The protocol filter applied to the the capture .e.g TCP, UDP, !TCP, 4.'
        )]
        [string]$Protocol,

        # -IPv4Address parameter. Filter the trace for source or destination addresses matching this address.
        [Parameter(
            Mandatory=$false,
            ParameterSetName="IPv4"
        )]
        [string]$IPv4Address,

        # -IPv4SourceAddress parameter. Filter the trace for source addreses matching this address.
        [Parameter(
            Mandatory=$false,
            ParameterSetName="IPv4"
        )]
        [string]$IPv4SourceAddress,

        # -IPv4DestinationAddress parameter. Filter the trace for destination addreses matching this address.
        [Parameter(
            Mandatory=$false,
            ParameterSetName="IPv4"
        )]
        [string]$IPv4DestinationAddress,

        # -IPv6Address parameter. Filter the trace for source or destination addresses matching this address.
        [Parameter(
            Mandatory=$false,
            ParameterSetName="IPv6"
        )]
        [string]$IPv6Address,

        # -IPv6SourceAddress parameter. Filter the trace for source addreses matching this address.
        [Parameter(
            Mandatory=$false,
            ParameterSetName="IPv6"
        )]
        [string]$IPv6SourceAddress,

        # -IPv6DestinationAddress parameter. Filter the trace for destination addreses matching this address.
        [Parameter(
            Mandatory=$false,
            ParameterSetName="IPv6"
        )]
        [string]$IPv6DestinationAddress,

        # -Persistant parameter. Make the trace persistant over reboots.
        [Parameter(
            Mandatory=$false
        )]
        [switch]$Persistant,

        # -MaxSize parameter. The size limit of the capture file in MB. Defaults to 250MB if not set.
        [Parameter(
            Mandatory=$false
        )]
        [int]$MaxSize,

        # -MaxSize parameter. The size limit of the capture file in MB. Defaults to 250MB if not set.
        [Parameter(
            Mandatory=$false
        )]
        [switch]$Overwrite
    )


    begin {
        $abort = $false

        if ($IsLinux -or $IsMacOS) {
            write-warning "This command is supported on Windows platforms only"
            $abort = $true
        }

        # requires admin rights, exit if not running as an administrator
        If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            write-error "The powershell session must be run as an administrator"
            $abort = $true
        }
        # make sure the $traceFile extension is .etl, if not add/change it
        if ([System.IO.Path]::GetExtension($TraceFile).ToUpper() -ne '.ETL') {
            $TraceFile = [System.IO.Path]::ChangeExtension($TraceFile, "etl")
        }
    }

    process {
        if (!$abort) {
            $netshCommand = "netsh trace start capture=yes tracefile=$TraceFile"
            # Set trace options based on user parameter values. Don;t validate the prameters, leave this up to Netsh to do.
            if ($Persistant) {
                $netshCommand += " Persistant=yes"
            }
            if ($MaxSize) {
                $netshCommand += " MaxSize=$MaxSize"
            }
            if ($Overwrite) {
                $netshCommand += " overwrite=yes"
            }
            if ($Protocol) {
                $netshCommand += " Protocol=$Protocol"
            }
            if ($IPv4Address) {
                $netshCommand += " Ethernet.Type=IPv4 IPv4.Address=$IPv4Address"
            }
            if ($IPv4SourceAddress) {
                $netshCommand += " Ethernet.Type=IPv4 IPv4.SourceAddress=$IPv4Address"
            }
            if ($IPv4DestinationAddress) {
                $netshCommand += " Ethernet.Type=IPv4 IPv4.DestinationAddress=$IPv4Address"
            }
            if ($IPv6Address) {
                $netshCommand += " Ethernet.Type=IPv6 IPv6.Address=$IPv6Address"
            }
            if ($IPv6SourceAddress) {
                $netshCommand += " Ethernet.Type=IPv6 IPv6.SourceAddress=$IPv6SourceAddress"
            }
            if ($IPv6DestinationAddress) {
                $netshCommand += " Ethernet.Type=IPv6 IPv6.DestinationAddress=$IPv6DestinationAddress"
            }
            # start the trace
            Invoke-Expression $netshCommand
        }
    }
}


