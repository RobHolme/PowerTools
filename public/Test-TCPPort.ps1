function Test-TCPPort-DotNetCore
{
<#
.NOTES
Function Name   : Test-TCPPort
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (01/12/2014) - Initial version.
                  1.1 (01/08/2016) - Output returned as an object instead of a string.
                  1.2 (24/08/2016) - updated to work on Linux/.Net Core
Requires        : PowerShell V3. .Net 4.6 or .Net Core

.SYNOPSIS
Tests connectivity to a TCP port on a remote host.
.DESCRIPTION
Tests connectivity to a TCP port on a remote host. Returns true or false. Use Conect-TCPPort if connection information is needed.
.EXAMPLE
Test-TCPPort -Hostname 192.168.0.1 Port 25
.PARAMETER Hostname
The Hostname or IP address of the host to connect to.
.PARAMETER Port
The number of the port to connect to.
.PARAMETER Timeout
The timeout in seconds to wait for the TCP connection
#>
    param(
        [Parameter(
            Position=0,
            Mandatory=$True,
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$true)]
            [string] $Hostname,

        [Parameter(
            Position=1,
            Mandatory=$True)]
            [ValidateRange(1,65535)]
            [int] $Port,

        [Parameter(
            Position=2,
            Mandatory=$False)]
            [uint16] $Timeout = 3
    )

    # establish a TCP connection. If the connection fails an exception will be raised.
    process {
        $TCPTest = New-Object System.Net.Sockets.TcpClient
        $ipAddresses = [System.Net.Dns]::GetHostAddressesAsync($Hostname)
        # if the hostname resolves to  an ip address
        if (!$ipAddresses.IsFaulted) {
            # try to connect on all IP addresses resolved for the hostname. Return success if any connect
            foreach ($ipAddress in $ipAddresses.Result) {
                Write-Verbose "Connecting to $Hostname[$ipAddress]:$($Port) (TCP) ..."
                if ($TCPTest.ConnectAsync($ipAddress, $port).Wait($timeout*1000)) {
                    # if connected, then close the connection
                    if ($PSVersionTable.PSVersion.Major -lt 3) {
                        $TCPTest.Close()
                    }
                    else {
                        $TCPTest.Dispose()
                    }
                    return $true
                }
            }
        }
        else {
            Write-Error "$Hostname could not be resolved"
        }
        return $false
    }
}

#----------------------------------------------------
function Test-TCPPort
{
<#
.NOTES
Function Name   : Test-TCPPort
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (01/12/2014) - Initial version.
                  1.1 (01/08/2016) - Output returned as an object instead of a string.
Requires        : PowerShell V2

.SYNOPSIS
Tests connectivity to a TCP port on a remote host.
.DESCRIPTION
Tests connectivity to a TCP port on a remote host. Returns true or false. Use Conect-TCPPort if connection information is needed.
.EXAMPLE
Test-TCPPort -Hostname 192.168.0.1 Port 25
.PARAMETER Hostname
The Hostname or IP address of the host to connect to.
.PARAMETER Port
The number of the port to connect to.
#>
    param(
        [Parameter(
            Position=0,
            Mandatory=$True,
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$true)]
            [string] $Hostname,

        [Parameter(
            Position=1,
            Mandatory=$True)]
            [ValidateRange(1,65535)]
            [int] $Port
    )

    # establish a TCP connection. If the connection fails an eresolxception will be raised.
    process {
        $TCPTest = New-Object System.Net.Sockets.TcpClient
        Try {
            Write-Verbose "Connecting to $($Hostname):$($Port) (TCP) ..."
            $TCPTest.Connect($Hostname, $Port)
            return $true
        }
        # catch failed connections
        Catch {
            return $false
        }
        Finally {
            # close any open TCP connections
            if ($PSVersionTable.PSVersion.Major -lt 3) {
                $TCPTest.Close() }
            else {
                $TCPTest.Dispose() }
        }
    }
}


