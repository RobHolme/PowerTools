function Connect-TCPPort {
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
			Position = 0,
			Mandatory = $True,
			ValueFromPipeline = $True,
			ValueFromPipelineByPropertyName = $true)]
		[string] $Hostname,

		[Parameter(
			Position = 1,
			Mandatory = $True)]
		[ValidateRange(1, 65535)]
		[int[]] $Port
	)

	Begin {
		function TestTCPConnection {
			param (
				$TargetIPAddress,
				$TargetPort
			)
		
			Write-Progress -Activity "Connecting to $($TargetIPAddress):$($TargetPort)" -SecondsRemaining -1 -PercentComplete -1      
		
			$Result = @{
				Connection    = "Failed"
				ElapsedTime   = "0 ms"
				RemoteHost    = $Hostname
				RemoteAddress = $TargetIPAddress
				Port          = $TargetPort
			}

			$TCPClient = [System.Net.Sockets.TcpClient]::new($TargetIPAddress.AddressFamily)
			$connectionTime = $null

			try {
				$connectionTime = measure-command { $null = $TCPClient.ConnectAsync($TargetIPAddress, $TargetPort).GetAwaiter().Getresult() }
				if ($TCPClient.Connected) {
					$Result.Connection = "Successful"
				}
			}
			catch {
				Write-Debug "TCP connect to ($TargetIPAddress : $TargetPort) threw exception: $($_.Exception.Message)"
			}
			finally {
				$Result.ElapsedTime = $connectionTime.TotalMilliseconds
				$TCPClient.Dispose()
			}
			return $Result
		}
	}

	# establish a TCP connection. If the connection fails an exception will be raised.
	Process {
		Write-Verbose "Connecting to $Hostname"
		# resolve the hostname to an IP address
		$Addresses = $null
		try {
			$Addresses = [System.Net.Dns]::GetHostAddressesAsync($Hostname).GetAwaiter().GetResult()
		}
		catch {
			Write-Debug "Name resolution of $Hostname threw exception: $($_.Exception.Message)"
			Write-Warning "Failed to resolve $Hostname"
		}

		# attempt a TCP connection for all ports (for all resolved IP addresses for hostname)
		foreach ($portNumber in $Port) {
			# report failure for each port if name resolution failed, so all results reported consistently
			if ($null -eq $Addresses) {
				[PSCustomObject]@{
					PSTypeName     = "Powertools.TestTCPPort.Result"
					Connection     = "Failed"
					ConnectionTime = "0 ms"
					RemoteHost     = $Hostname
					RemoteAddress  = ""
					Port           = $portNumber
				}
			}
			# test the TCP connection for each resolved IP address
			else {
				$i = 0
				while ($i -lt $Addresses.Count) {
					$ConnectionResult = TestTCPConnection -TargetIPAddress $Addresses[$i++] -TargetPort $portNumber
					[PSCustomObject]@{
						PSTypeName     = "Powertools.TestTCPPort.Result"
						Connection     = $ConnectionResult.Connection
						ConnectionTime = "$([Math]::Round($ConnectionResult.ElapsedTime,1)) ms"
						RemoteHost     = $Hostname
						RemoteAddress  = $ConnectionResult.RemoteAddress
						Port           = $portNumber
					}
				}
			}
		}
	}
}


