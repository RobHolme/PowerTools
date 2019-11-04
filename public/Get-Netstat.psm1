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
        # IPv6 addresses contain ':' within the address, so looks for a ':' immediately following a ']' (regex lookbehind)
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
        # IPv6 addresses contain ':' within the address, so looks for a ':' immediately following a ']' (regex lookbehind)
        return ($ipString -split "(?<=]):")[1]
    }
    # If the address sting doesn't contain a ']' assume it is an IPv4 address
    else {
        return ($ipString -split ":")[1]
    }
}


