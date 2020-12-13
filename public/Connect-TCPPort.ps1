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
				ElapsedTime   = ""
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
					$Result.ElapsedTime = "$([Math]::Round($connectionTime.TotalMilliseconds,1)) ms"
				}
			}
			catch {
				Write-Debug "TCP connect to ($TargetIPAddress : $TargetPort) threw exception: $($_.Exception.Message)"
			}
			finally {
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
		}

		if ($null -eq $Addresses) {
			write-warning "Name resolution of $Hostname failed"
			$ConnectionResult = @{
				Connection    = "Failed"
				ElapsedTime   = ""
				RemoteHost    = $Hostname
				RemoteAddress = ""
				Port          = $Port
			}	
			$outputObject = New-Object -Property $ConnectionResult -TypeName psobject
			$outputObject.PSObject.TypeNames.Insert(0, "Powertools.TestTCPPort.Result")
			write-output $outputObject
		}
		else {
			foreach ($portNumber in $Port) {
				$i = 0
				while ($i -lt $Addresses.Count) {
					$ConnectionResult = TestTCPConnection -TargetIPAddress $Addresses[$i] -TargetPort $portNumber
					$i++
				
					$outputObject = New-Object -Property $ConnectionResult -TypeName psobject
					$outputObject.PSObject.TypeNames.Insert(0, "Powertools.TestTCPPort.Result")
					write-output $outputObject
				}
			}
		}
	}
}


