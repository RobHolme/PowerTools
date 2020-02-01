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
			# Create endpoint and start listening
			$endpoint = new-object System.Net.IPEndPoint([ipaddress]::any, $Port) 
			$listener = new-object System.Net.Sockets.TcpListener $endpoint
			$listener.start() 
 
			# Wait for a connection 
			$data = $listener.AcceptTcpClient() 
		
			# Remote endpoint details
			$remoteIP = $data.Client.RemoteEndPoint.Address.IPAddressToString
			$remotePort = $data.Client.RemoteEndPoint.Port

			# default option is to close the connection and report results immediately 
			if (!$WaitForData) {
				# format results
				$result = [ORDERED]@{
					Status     = "Connection Successful"
					RemoteHost = $remoteIP
					RemotePort = $remotePort
				}
				DisplayResult $result
			}

			# -WaitForData switch provided, wait for endpoint to send data and display the data received. No response to the pipeline until data is received.
			else {
				# Stream setup
				$stream = $data.GetStream() 
				$bufferSize = 1024
				$buffer = New-Object System.Byte[]::new($bufferSize)

				# Read data from stream, include in results displayed to console
				while (($i = $stream.Read($buffer, 0, $buffer.Length)) -ne 0) {
					$EncodedText = New-Object System.Text.ASCIIEncoding
					$dataReceived = $EncodedText.GetString($buffer, 0, $i)
				
					$result = [ORDERED]@{
						Status     = "Connection Successful"
						RemoteHost = $remoteIP
						RemotePort = $remotePort
						Data       = $dataReceived
					}
					DisplayResult $result
				}
				$stream.close()
			}

			# Close TCP connection and stop listening
			$listener.stop()
		}
		Catch {
			"Connection failed: `n $($_.Exception.Message)"
		}
	}
}


function DisplayResult($Result) {
	# return the results as an object
	$outputObject = New-Object -Property $Result -TypeName psobject
	$outputObject.PSObject.TypeNames.Insert(0, "Powertools.StartTCPListener.Result")
	write-output $outputObject
}