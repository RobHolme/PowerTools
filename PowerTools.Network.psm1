<#
Copyright (c) 2016 Robert Holme (rob@holme.com.au)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
is furnished to do so, subject to the following conditions:

1) The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

2) THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#>

#----------------------------------------------------
function Test-SQLDatabase
{
<#
.NOTES
Function Name   : Test-SQLDatabase
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (31/07/2016)   - Initial version.
                : 1.1 (04/10/2016) - Prompt for password as SecureString, instead of accepting plain test password as parameter
Requires        : PowerShell V2

.SYNOPSIS
Tests connectivity to MS SQL Database. Returns true or false. Ffor connection details use Connect-Database.
.DESCRIPTION
Tests connectivity to MS SQL Database. Supports SQL user authentication, or integrated Windows authentication.
.EXAMPLE
Test-Database -Server 127.0.0.1\SQLExpress -Database NorthWind -Username Northwin-User -Password P@ssword
.EXAMPLE
Test-Database -Server SQLServer01 -Database NorthWind -UseWindowsAuthentication
.PARAMETER Server
The Hostname or IP address of the SQL server to connect to. If connecting to a named instance, include the instance name e.g. server\instance
.PARAMETER Database
The name of the database to connect to
.PARAMETER Username
The SQL user account used to authenticate to the database
.PARAMETER UseWindowsAuthentication
Use the current logged on user's credentials to authenticate using Windows authentication
#>
    [CmdletBinding(DefaultParametersetName="WindowsAuth")]
    param(
        [Parameter(
            Position=0,
            Mandatory=$True,
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$true)]
            [string] $Server,

        [Parameter(
            Position=1,
            Mandatory=$True)]
            [string] $Database,

        [Parameter(
            Position=2,
            Mandatory=$True,
            ParameterSetName="SQLAuth")]
            [string] $Username,

        [Parameter(
            Position=3,
            Mandatory=$False,
            ParameterSetName="SQLAuth")]
            [Security.SecureString] $Password,

        [Parameter(
            Position=2,
            Mandatory=$False,
            ParameterSetName="WindowsAuth")]
            [switch] $UseWindowsAuthentication
    )

    # connect to the database, then immediately close the connection. If an exception occurs it indicates the conneciton was not successful.
    process {
        $dbConnection = New-Object System.Data.SqlClient.SqlConnection
        if ($Username) {
            # prompt for the password if not supplied as a parameter (as a securestring)
            if ($Password.Length -lt 1) {
                $Password = Read-Host -Prompt "Enter password for the $Username SQL account" -AsSecureString
            }
            # get the plain text password
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            $plainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            # create the connection string using SQL user authentication
            $dbConnection.ConnectionString = "Data Source=$Server; uid=$Username; pwd=$plainTextPassword; Database=$Database;Integrated Security=False"
            $authentication = "SQL ($Username)"
        }
        else {
            # create the connection string, use logged on users credentials for authentication
            $dbConnection.ConnectionString = "Data Source=$Server; Database=$Database;Integrated Security=True;"
            $authentication = "Windows ($env:USERNAME)"
        }
        try {
            $dbConnection.Open()
            return $true
        }
        # exceptions will be raised if the database connection failed.
        catch {
            return $false
        }
        Finally{
            # close the database connection
            $dbConnection.Close()
        }
    }
}

#----------------------------------------------------
function Connect-SQLDatabase
{
<#
.NOTES
Function Name   : Test-Database
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (31/07/2016) - Initial version.
                : 1.1 (04/10/2016) - Prompt for password as SecureString, instead of accepting plain test password as parameter
Requires        : PowerShell V2

.SYNOPSIS
Tests connectivity to MS SQL Database. Reports connection details, then closes.
.DESCRIPTION
Tests connectivity to MS SQL Database. Supports SQL user authentication, or integrated Windows authentication.
.EXAMPLE
Connect-Database -Server 127.0.0.1\SQLExpress -Database NorthWind -Username Northwind -User -Password P@ssword
.EXAMPLE
Connect-Database -Server SQLServer01 -Database NorthWind -UseWindowsAuthentication
.PARAMETER Server
The Hostname or IP address of the SQL server to connect to. If connecting to a named instance, include the instance name e.g. server\instance
.PARAMETER Database
The name of the database to connect to
.PARAMETER Username
The SQL user account used to authenticate to the database
.PARAMETER UseWindowsAuthentication
Use the current logged on user's credentials to authenticate using Windows authentication
#>
    [CmdletBinding(DefaultParametersetName="WindowsAuth")]
    param(
        [Parameter(
            Position=0,
            Mandatory=$True,
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$true)]
            [string] $Server,

        [Parameter(
            Position=1,
            Mandatory=$True)]
            [string] $Database,

        [Parameter(
            Position=2,
            Mandatory=$True,
            ParameterSetName="SQLAuth")]
            [string] $Username,

        [Parameter(
            Position=3,
            Mandatory=$False,
            ParameterSetName="SQLAuth")]
            [Security.SecureString] $Password,

        [Parameter(
            Position=2,
            Mandatory=$False,
            ParameterSetName="WindowsAuth")]
            [switch] $UseWindowsAuthentication
    )

    # connect to the database, then immediately close the connection. If an exception occurs it indicates the conneciton was not successful.
    process {
        $dbConnection = New-Object System.Data.SqlClient.SqlConnection
        if ($Username) {
            # prompt for the password if not supplied as a parameter (as a securestring)
            if ($Password.Length -lt 1) {
                $Password = Read-Host -Prompt "Enter password for the $Username SQL account" -AsSecureString
            }
            # get the plain text password
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            $plainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            # create the connection string using SQL user authentication
            $dbConnection.ConnectionString = "Data Source=$Server; uid=$Username; pwd=$plainTextPassword; Database=$Database;Integrated Security=False"
            $authentication = "SQL ($Username)"
        }
        else {
            # create the connection string, use logged on users credentials for authentication
            $dbConnection.ConnectionString = "Data Source=$Server; Database=$Database;Integrated Security=True;"
            $authentication = "Windows ($env:USERNAME)"
        }
        try {
            $connectionTime = measure-command {$dbConnection.Open()}
            $Result = @{
                Connection = "Successful"
                ElapsedTime = $connectionTime.TotalSeconds
                Server = $Server
                Database = $Database
                User = $authentication}
        }
        # exceptions will be raised if the database connection failed.
        catch {
            $Result = @{
                Connection = "Failed"
                ElapsedTime = $connectionTime.TotalSeconds
                Server = $Server
                Database = $Database
                User = $authentication}
        }
        Finally{
            # close the database connection
            $dbConnection.Close()
            #return the results as an object
            $outputObject = New-Object -Property $Result -TypeName psobject
            $outputObject.PSObject.TypeNames.Insert(0,"Powertools.TestDatabase.Result")
            write-output $outputObject
        }
    }
}


#----------------------------------------------------
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


#----------------------------------------------------
function Connect-TCPPort
{
<#
.NOTES
Function Name   : Connect-TCPPort
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (01/12/2014) - Initial version.
                  1.1 (01/08/2016) - Output returned as an object instead of a string.
Requires        : PowerShell V3

.SYNOPSIS
Tests connectivity to a TCP port on a remote host, reporting connection properties.
.DESCRIPTION
Tests connectivity to a TCP port on a remote host. If successful, the time to connect is displayed with the endpoint details.
.EXAMPLE
Connect-TCPPort -Hostname 192.168.0.1 Port 25
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

    # establish a TCP connection. If the connection fails an exception will be raised.
    process {
        $TCPTest = New-Object System.Net.Sockets.TcpClient
        Try {
            Write-Verbose "Connecting to $($Hostname):$($Port) (TCP) ..."
            $connectionTime = measure-command {$TCPTest.Connect($Hostname, $Port)}
            $Result = @{
                Connection = "Successful"
                ElapsedTime = $connectionTime.TotalSeconds
                RemoteHost = $Hostname
                Port = $Port
            }
        }
        # catch failed connections
        Catch {
              $Result = @{
                Connection = "Failed"
                ElapsedTime = $connectionTime.TotalSeconds
                RemoteHost = $Hostname
                Port = $Port
            }
        }
        Finally {
            #return the results as an object
            $outputObject = New-Object -Property $Result -TypeName psobject
            $outputObject.PSObject.TypeNames.Insert(0,"Powertools.TestTCPPort.Result")
            write-output $outputObject

            # close any open TCP connections
            if ($PSVersionTable.PSVersion.Major -lt 3) {
                $TCPTest.Close() }
            else {
                $TCPTest.Dispose() }
        }
    }
}

#----------------------------------------------------
function Get-Netstat()
{
<#
.NOTES
Function Name   : Get-Netstat
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (01/08/2016)
Requires        : PowerShell V3

.SYNOPSIS
A wrapper for netstat that resolves process ID's to process names.
.DESCRIPTION
A wrapper for netstat that resolves process ID's to process names.
.PARAMETER ResolveIPAddress
This switch will resolve remote IP addresses to host names. This will be slower than displaying IP addresses.
.EXAMPLE
Get-Netstat
.EXAMPLE
Get-Netstat -ResolveIPAddresses
#>
    Param([Parameter(
        Position=0,
        Mandatory=$False)]
        [switch] $ResolveIPAddress
    )

    process {
        if ($IsMacOS -or $IsLinux) {
            write-warning "This function is supported on Windows only"
            return
        }
        # get the current list of process names and IDs, store as a hash table
        $allProcesses = Get-Process
        $processHash = @{}
        foreach ($process in $allProcesses) {
            $processHash.Add($process.ID, $process.ProcessName)
        }

        # get the netstat output with IP addresses resolved to hostnames
        if ($ResolveIPAddress) {
            $netstatResult = Netstat -ao
        }
        # get the netstat output without IP addresses resolved to hostnames
        else {
            $netstatResult = Netstat -ano
        }
        #ignore the header and blank lines
        $netstatResult = $netstatResult[4..$netstatResult.count]
        foreach ($line in $netstatResult)
		{
			# remove the white spaces at the start of the line
			$line = $line -replace '^\s+', ''
			# get each property by splitting the line on the blocks of whitespace
			$splitLine = $line -split '\s+'
			# if the remote port is *, the PID is shifted
            If ($splitLine.Count -eq 4) {
                $pid = [int]$splitLine[3]
                $state = ""
            }
           else{
                $pid = [int]$splitLine[4]
                $state = $splitLine[3]
           }
            # properties to output
			$properties = @{
				Protocol = $splitLine[0]
				LocalIPAddress = GetNetStatIPAddress($splitLine[1])
				LocalPort = GetNetStatPort($splitLine[1])
				RemoteIPAddress = GetNetStatIPAddress($splitLine[2])
				RemotePort = GetNetStatPort($splitLine[2])
				State = $state
                ProcessName = $processHash[$pid]
  			}
            # Output the object, create a custom type name 'Powertools.GetNetstatResult' to allow custom formatting to be applied
			$outputObject = New-Object -TypeName PSObject -Property $properties
            $outputObject.PSObject.TypeNames.Insert(0,"Powertools.GetNetstat.Result")
            write-output $outputObject
        }
    }
}

#----------------------------------------------------
# private function used by Get-Netstat. Returns the IPv4 or IPv6 address from a IP:Port string.
function GetNetStatIPAddress([string] $ipString)
{
    # if the address contains an ']' assume it is an IPv6 address
    if ($ipString -match ']') {
        # IPv6 addresses contain ':' within the address, so looks for a ':' immediatly following a ']' (regex lookbehind)
        return ($ipString -split "(?<=]):")[0]
    }
    else {
        # If the address sting doesn't contain a ']' assume it is an IPv4 address, or a resolved hostname
        return ($ipString -split ":")[0]
    }
}

#----------------------------------------------------
# private function used by Get-Netstat. Returns the port number from a IP:Port string.
function GetNetStatPort([string] $ipString)
{
    # if the address contains an ']' assume it is an IPv6 address
    if ($ipString -match ']') {
        # IPv6 addresses contain ':' within the address, so looks for a ':' immediatly following a ']' (regex lookbehind)
        return ($ipString -split "(?<=]):")[1]
    }
    # If the address sting doesn't contain a ']' assume it is an IPv4 address
    else {
        return ($ipString -split ":")[1]
    }
}

#----------------------------------------------------
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

#----------------------------------------------------
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


#----------------------------------------------------
function Get-FirewallStatus
{
<#
.NOTES
Function Name   : Get-FirewallStatus
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (21/12/2016)
Requires        :
#>

    if ($IsCoreCLR) {
        write-warning "This function is only supported on Windows Powershell"
        return
    }

    # get the list of profiles from the active store. This is the result of domain (GPO) and local policies.
    $allFirewallProfiles = Get-NetFirewallProfile -PolicyStore ActiveStore
    foreach ($firewallProfile in $allFirewallProfiles) {
        # store the results as an object
        $result = @{
            ProfileName = $firewallProfile.Name
            Enabled = $firewallProfile.Enabled
        }
        $outputObject = New-Object -Property $result -TypeName psobject
	    # write the output object to the pipeline
	    write-output $outputObject
    }
}





