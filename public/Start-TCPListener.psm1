Function Start-TCPListener {
	Param ( 
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateRange(1, 65535)] 
		[int] $Port,

		[Parameter(Mandatory = $false, Position = 1)]
		[switch] $WaitForData
	) 
	
	Process {
		Try { 
			# Set up endpoint and start listening
			$endpoint = new-object System.Net.IPEndPoint([ipaddress]::any, $Port) 
			$listener = new-object System.Net.Sockets.TcpListener $EndPoint
			$listener.start() 
 
			# Wait for an incoming connection 
			$data = $listener.AcceptTcpClient() 
		
			# Remote endpoint details
			$remoteIP = $data.Client.RemoteEndPoint.Address.IPAddressToString
			$remotePort = $data.Client.RemoteEndPoint.Port
			
			if (!$WaitForData) {

				# format results
				$result = [ORDERED]@{
					Status     = "Connection Successful"
					RemoteHost = $remoteIP
					RemotePort = $remotePort
				}
			
				DisplayResult $result
			}
			else {
				# Stream setup
				$stream = $data.GetStream() 
				$bytes = New-Object System.Byte[] 1024

				# Read data from stream and write it to host
				while (($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
					$EncodedText = New-Object System.Text.ASCIIEncoding
					$data = $EncodedText.GetString($bytes, 0, $i)
				
					$result = [ORDERED]@{
						Status     = "Connection Successful"
						RemoteHost = $remoteIP
						RemotePort = $remotePort
						Data       = $data
					}

					DisplayResult $result
				}
				$stream.close()
			}

			# Close TCP connection and stop listening
			$listener.stop()
		}
		Catch {
			"Receive Message failed: `n" + $_.Message
		}
	}
}


function DisplayResult($Result) {

	# return the results as an object
	$outputObject = New-Object -Property $Result -TypeName psobject
	$outputObject.PSObject.TypeNames.Insert(0, "Powertools.StartTCPListener.Result")
	write-output $outputObject
}