function Test-TCPPort {
	<#
.NOTES
Function Name   : Test-TCPPort
Author          : Rob Holme (rob@holme.com.au)
Requires        : PowerShell V3

.SYNOPSIS
Tests connectivity to a TCP port on a remote host, reporting connection properties.
.DESCRIPTION
Tests connectivity to a TCP port on a remote host. If successful, the time to connect is displayed with the endpoint details.
.EXAMPLE
Test-TCPPort -Hostname 192.168.0.1 -Port 25
.PARAMETER Hostname
The Hostname or IP address of the host to connect to.
.PARAMETER Port
The number of the port to connect to.
.PARAMETER Timeout
The TCP connection timeout in seconds. Defaults to 5 secs (or default system timeout if lower) if parameter not supplied. 
#>
	param(
		[Parameter(
			Position = 0,
			Mandatory = $True,
			ValueFromPipeline = $True,
			ValueFromPipelineByPropertyName = $true)]
		[Alias('ComputerName')]
		[string] $Hostname,

		[Parameter(
			Position = 1,
			Mandatory = $True)]
		[ValidateRange(1, 65535)]
		[int[]] $Port,

		[Parameter(
			Position = 2,
			Mandatory = $False)]
		[ValidateRange(1, 20)]
		[int] $Timeout = 3
	)

	Begin {
		function TestTCPConnection {
			param (
				$TargetIPAddress,
				$TargetPort,
				$Timeout
			)
			Write-Progress -Activity "Connecting to $($TargetIPAddress):$($TargetPort)" -SecondsRemaining $Timeout -PercentComplete 50 -Status "waiting for response..."    
		
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
				$connectionTime = measure-command { $tcpConnectResult = $TCPClient.ConnectAsync($TargetIPAddress, $TargetPort).Wait($Timeout*1000)			}
				Write-Verbose "Result: $tcpConnectResult"
					if ($tcpConnectResult -eq $True) {
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
		Write-Verbose "Connecting to $Hostname ($Timeout secs timeout)"
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
					$ConnectionResult = TestTCPConnection -TargetIPAddress $Addresses[$i++] -TargetPort $portNumber -Timeout $Timeout
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


