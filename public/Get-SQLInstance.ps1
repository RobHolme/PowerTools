function Get-SQLInstance {
	<#
	.SYNOPSIS
	Requests a list of instances from the browser service.
	
	.DESCRIPTION
	    Requests a list of instances from the browser service.

	.PARAMETER ComputerName
	    Computer name or IP address to enumerate SQL Instance from.

	.PARAMETER Timeout
	    Timeout in seconds. 

	.EXAMPLE
	    PS C:\> Get-SQLInstance -ComputerName 'sqlsvr01'

	    Contacts the browser service on sqlsvr01 and requests its instance information.

	.NOTES
	    Original Author: Eric Gruber
	#>
			
	[CmdletBinding()]
	param (
		[Parameter(
			Position = 0,
			Mandatory = $true, 
			ValueFromPipeline = $true
		)]
		[string[]] $ComputerName,
			
		[Parameter(
			Position = 1,
			Mandatory = $false, 
			ValueFromPipeline = $false
		)]
		[int] $Timeout = 3
	)
				
	process {
		foreach ($computer in $ComputerName) {
			try {
				# send UDP packet to SQL browser service, listen for response
				$UDPClient = New-Object -TypeName System.Net.Sockets.Udpclient
				$UDPClient.Client.ReceiveTimeout = $Timeout * 1000
				$UDPClient.Connect($computer, 1434)
				$UDPPacket = 0x03
				$UDPEndpoint = New-Object -TypeName System.Net.IpEndPoint -ArgumentList ([System.Net.Ipaddress]::Any, 0)
				$UDPClient.Client.Blocking = $true
				[void] $UDPClient.Send($UDPPacket, $UDPPacket.Length)
				$BytesReceived = $UDPClient.Receive([ref]$UDPEndpoint)
			
				# process the response, write results to pipeline
				$Response = [System.Text.Encoding]::ASCII.GetString($BytesReceived)	
				$Response | Select-String "(ServerName;(\w+);InstanceName;(\w+);IsClustered;(\w+);Version;(\d+\.\d+\.\d+\.\d+);(tcp;(\d+)){0,1})" -AllMatches | Select-Object -ExpandProperty Matches | ForEach-Object {
					[PSCustomObject] @{
						PSTypeName   = "Powertools.GetSQLInstance.Result"
						Hostname     = $computer
						ComputerName = $_.Groups[2].Value
						SqlInstance  = "$($_.Groups[2].Value)\$($_.Groups[3].Value)"
						InstanceName = $_.Groups[3].Value
						Version      = $_.Groups[5].Value
						IsClustered  = "Yes" -eq $_.Groups[4].Value
						TCPPort      = $_.Groups[7].Value
					}
				}
				$UDPClient.Close()
			}
			# catch timeouts waiting on response from SQL browser
			catch [System.Net.Sockets.SocketException] {
				Write-Warning "Failed to receive a response from the SQL Browser Service on $computer"
			}
			# catch all other exceptions
			catch {
				Write-Error -Message $_.Exception.Message
			}
			# close the UDP socket if an exception has occurred. Don't report further exceptions of the socket fails to close.
			finally {
				try {
					$UDPClient.Close()
				}
				catch {
				}
			}
		}
	}
}
			
			