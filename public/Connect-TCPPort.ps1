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

	# establish a TCP connection. If the connection fails an exception will be raised.
	process {
		$portCount = 1
		foreach ($portNumber in $Port) {
			$TCPTest = New-Object System.Net.Sockets.TcpClient
			Try {
				Write-Verbose "Connecting to $($Hostname):$($portNumber) (TCP) ..."
				Write-Progress -Activity "Connecting to $($Hostname):$($portNumber)" -PercentComplete (($portCount++ / $Port.Count) * 100)
				$connectionTime = $null
				$connectionTime = measure-command { $TCPTest.Connect($Hostname, $portNumber) }
				$Result = @{
					Connection  = "Successful"
					ElapsedTime = "$([math]::Round(($connectionTime.TotalSeconds * 1000),1)) ms"
					RemoteHost  = $Hostname
					Port        = $portNumber
				}
			}
			# catch failed connections
			Catch {
				$Result = @{
					Connection  = "Failed"
					ElapsedTime = $connectionTime.TotalSeconds
					RemoteHost  = $Hostname
					Port        = $portNumber
				}
			}
			Finally {
				#return the results as an object
				$outputObject = New-Object -Property $Result -TypeName psobject
				$outputObject.PSObject.TypeNames.Insert(0, "Powertools.TestTCPPort.Result")
				write-output $outputObject

				# close any open TCP connections
				if ($PSVersionTable.PSVersion.Major -lt 3) {
					$TCPTest.Close() 
				}
				else {
					$TCPTest.Dispose() 
				}
			}
		}
	}
}


