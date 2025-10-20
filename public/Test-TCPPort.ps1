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
				ElapsedTime   = 0
				SourceAddress = $null
				RemoteHost    = $Hostname
				RemoteAddress = $TargetIPAddress
				Port          = $TargetPort
			}

			$TCPClient = [System.Net.Sockets.TcpClient]::new($TargetIPAddress.AddressFamily)
			$connectionTime = $null

			try {
				$connectionTime = measure-command { $tcpConnectResult = $TCPClient.ConnectAsync($TargetIPAddress, $TargetPort).Wait($Timeout*1000)			}
				Write-Verbose "Result: $tcpConnectResult"
				# capture the source IP address if the connection was successful, and update status to "Successful"
				if ($tcpConnectResult -eq $True) {
					$Result.SourceAddress = $TCPClient.Client.LocalEndPoint.Address.ToString()
					$Result.Connection = "Successful"
				}
				# generate the source IP address from the routing table if the connection was not successful
				else {
					$Result.SourceAddress = Get-SourceIpFromRoute -DestinationIP $TargetIPAddress
				}
			}
			catch {
				Write-Debug "TCP connect to ($TargetIPAddress : $TargetPort) threw exception: $($_.Exception.Message)"
			}
			finally {
				# only report the connection time if it was successful
				if ($tcpConnectResult -eq $True) {
					$Result.ElapsedTime = $connectionTime.TotalMilliseconds
				}
				
				$TCPClient.Dispose()
			}
			return $Result
		}

		#--------------------------------------------------
# Get the source IP address from the routing table for the specified destination
function Get-SourceIpFromRoute {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $DestinationIP
    )

    # Ensure the destination is a valid IP address or hostname
    if (-not [System.Net.IPAddress]::TryParse($DestinationIP, [ref]$null)) {
        Write-Warning "Invalid destination IP address: '$DestinationIP'."
        return $null
    }

    # if running Windows, use Get-NetRoute
    if ($isWindows) {
    
        # Get the routing table
        $Routes = Find-NetRoute -RemoteIPAddress $DestinationIP -ErrorAction SilentlyContinue
        if ($null -eq $Routes) {
            Write-Warning "No route found for destination '$DestinationIP'."
            return $null
        }

        # Return the source IP address from the route
        return $Routes[0].IpAddress
    }   

    # if running Linux, use ip route
    elseif ($isLinux) {
        $Routes = ip route get $DestinationIP
        if ($null -eq $Routes) {
            Write-Warning "No route found for destination '$DestinationIP'."
            return $null
        }

        # Extract the source IP address from the output
        if ($Routes[0] -match '(?<=src )\b((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\b') {
            return $matches[0]
        } else {
            Write-Warning "Could not extract source IP address from routing table."
            return $null
        }
    }

    # MacOS is not supported - unable to test
    Write-Warning "Unsupported operating system for routing table lookup."
    return $null
}
	}

	# establish a TCP connection. If the connection fails an exception will be raised.
	Process {
		Write-Verbose "Connecting to $Hostname ($Timeout secs timeout)"
		# resolve the hostname to an IP address
		$Addresses = $null
		try {
			# filter to only IPv4 addresses
			$Addresses = [System.Net.Dns]::GetHostAddressesAsync($Hostname).GetAwaiter().GetResult() | Where-Object {$_.AddressFamily -eq 'InterNetwork'}
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
					SourceAddress = $null
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
						SourceAddress  = $ConnectionResult.SourceAddress
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


