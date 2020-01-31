Function Start-TCPListener {
    Param ( 
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateRange(1,65535)] 
        [int] $Port
    ) 
    Process {
        Try { 
            # Set up endpoint and start listening
            $endpoint = new-object System.Net.IPEndPoint([ipaddress]::any,$port) 
            $listener = new-object System.Net.Sockets.TcpListener $EndPoint
            $listener.start() 
 
            # Wait for an incoming connection 
            $data = $listener.AcceptTcpClient() 
        
            # Stream setup
            $stream = $data.GetStream() 
            $bytes = New-Object System.Byte[] 1024

            # Read data from stream and write it to host
            while (($i = $stream.Read($bytes,0,$bytes.Length)) -ne 0){
                $EncodedText = New-Object System.Text.ASCIIEncoding
				$data = $EncodedText.GetString($bytes,0, $i)
				
				# format results
				$Result = [ORDERED]@{
					Connection = "Successful"
					RemoteHost = $data.Client.RemoteEndPoint.Address
					RemotePort = $data.Client.RemoteEndPoint.Port
					Data = $data
				}

				# return the results as an object
				$outputObject = New-Object -Property $Result -TypeName psobject
				$outputObject.PSObject.TypeNames.Insert(0,"Powertools.StartTCPListener.Result")
				write-output $outputObject
	
                Write-Output $data
            }
         
            # Close TCP connection and stop listening
            $stream.close()
			$listener.stop()
        }
        Catch {
            "Receive Message failed: `n" + $Error[0]
        }
    }
}