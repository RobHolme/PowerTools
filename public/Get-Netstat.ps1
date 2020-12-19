function Get-Netstat() {
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
			Position = 0,
			Mandatory = $False)]
		[switch] $ResolveIPAddress
	)

	process {
		if ($IsMacOS -or $IsLinux) {
			write-warning "This function is supported on Windows only"
			return
		}
		# get the current list of process names and IDs, store as a hash table
		$allProcesses = Get-Process
		$processHash = @{ }
		foreach ($process in $allProcesses) {
			$processHash.Add($process.ID, $process.ProcessName)
		}

		# list TCP connections
		$tcpConnections = Get-NetTCPConnection
		ForEach ($tcpConnection in $tcpConnections) {
			$remoteHostname = $tcpConnection.RemoteAddress
			if ($ResolveIPAddress) {
				try {
					$remoteHostname = [System.Net.Dns]::GetHostByAddress($tcpConnection.RemoteAddress).HostName
				}
				catch {
					
				}
			}
			# Output the object, create a custom type name 'Powertools.GetNetstatResult' to allow custom formatting to be applied
			[PSCustomObject]@{
				PSTypeName     = 	"Powertools.GetNetstat.Result"
				Protocol        = "TCP"
				LocalIPAddress  = $tcpConnection.LocalAddress
				LocalPort       = $tcpConnection.LocalPort
				RemoteIPAddress = $remoteHostname
				RemotePort      = $tcpConnection.RemotePort
				State           = $tcpConnection.State
				ProcessName     = $processHash[[convert]::ToInt32($tcpConnection.OwningProcess, 10)]
			}
		}
		
		# list UDP endpoints
		$udpEndpoints = Get-NetUDPEndpoint
		ForEach ($udpEndpoint in $udpEndpoints) {
			# Output the object, create a custom type name 'Powertools.GetNetstatResult' to allow custom formatting to be applied
			[PSCustomObject]@{
				PSTypeName     = "Powertools.GetNetstat.Result"	
				Protocol        = "UDP"
				LocalIPAddress  = $udpEndpoint.LocalAddress
				LocalPort       = $udpEndpoint.LocalPort
				RemoteIPAddress = ""
				RemotePort      = ""
				State           = ""
				ProcessName     = $processHash[[convert]::ToInt32($udpEndpoint.OwningProcess, 10)]
			}
		}
	}
}

#----------------------------------------------------
# private function used by Get-Netstat. Returns the IPv4 or IPv6 address from a IP:Port string.
function GetNetStatIPAddress([string] $ipString) {
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
function GetNetStatPort([string] $ipString) {
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


