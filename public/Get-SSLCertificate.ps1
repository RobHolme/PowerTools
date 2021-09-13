function Get-SSLCertificate {
	<#
.NOTES
	based on https://gist.github.com/jstangroome/5945820
.SYNOPSIS
	Retrieve SSL certificate, display properties.  
.PARAMETER Hostname
	The remote website name / servername.
.PARAMETER Port
	Optionally provide the TCP port number of the remote website. Defaults to 443 if omitted.
.PARAMETER SNIname
	Optionally provide a SNI (Server Name Indication) name. Where a single site supports multiple certs, SNI name identifies the cert requested.
.PARAMETER ExportFile
	Export the certificate to a base64 encoded X.509 certificate file (.CER) 
.EXAMPLE
	Get-SSLCertificate -Hostname www.example.com 
.EXAMPLE
	Get-SSLCertificate -Hostname www.example.com -SNIName www.example.com 
.EXAMPLE
	# Get LDAPS cert form a domain controller
	Get-SSLCertificate -Hostname DC01 -port 636
.EXAMPLE
	Get-SSLCertificate -Hostname www.example.com -ExportFile c:\temp\CertExport.cer
#>

	[CmdletBinding(SupportsShouldProcess = $false, PositionalBinding = $true)]
	param (
		[Parameter(
			Mandatory = $true, 
			ValueFromPipeline = $True, 
			ValueFromPipelineByPropertyName = $true, 
			Position = 0
		)]
		[Alias('ComputerName')] 
		[string] $Hostname,

		[Parameter(
			Mandatory = $false, 
			Position = 1)]
		[ValidateRange(1, 65535)]
		[int] $Port = 443,

		[Parameter(
			Mandatory = $false,
			Position = 2)]
		[string] $SNIname = '',

		[Parameter(
			Mandatory = $false,
			Position = 3)]
		[string] $ExportFile
	)

	process {
		$timeout = 3000
		$certificate = $null
		$tcpClient = New-Object -TypeName System.Net.Sockets.tcpClient

		try {
			Write-Verbose "Connecting to $($Hostname):$($Port)"
			Write-Verbose "Timeout: $timeout ms"

			$tcpConnectResult = $tcpClient.ConnectAsync($Hostname, $Port).Wait($timeout)
			if ($tcpConnectResult -eq $true) {
				$tcpStream = $tcpClient.GetStream()
				$callback = { param($caller, $cert, $chain, $errors) return $true }
				$sslStream = New-Object -TypeName System.Net.Security.sslStream -ArgumentList @($tcpStream, $true, $callback)
				try {
					# optionally provide a SNI name (where a single site supports multiple certs, SNI name identifies the cert requested)
					$sslStream.AuthenticateAsClient($SNIname)
					$certificate = $sslStream.RemoteCertificate
				}
				catch {
					Write-Warning "Failed to retrieve certificate. Socket may not support TLS."
					Write-Warning " $($_.Exception.InnerException.Message)"
					Write-Debug "$($_.Exception)"
				}
				finally {
					$sslStream.Dispose()
				}
			}
			else {
				Write-Warning "Failed to connect to $($Hostname):$($Port) (Connection timed out)."
			}
		} 
		catch {
			Write-Warning "Failed to connect to $($Hostname):$($Port)."
			Write-Warning "$($_.Exception.InnerException.Message)"
			Write-Debug "$($_.Exception)"
		}
		finally {
			$tcpClient.Dispose()
		}

		if ($certificate) {
			# export the certificate to a base64 encoded file (.cer)
			If ($ExportFile) {
				$certBase64 = "-----BEGIN CERTIFICATE-----`n"
				$certBase64 += [System.Convert]::ToBase64String($certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::cert), [System.Base64FormattingOptions]::InsertLineBreaks)
				$certBase64 += "`n-----END CERTIFICATE-----"
				Out-File -FilePath $ExportFile -InputObject $certBase64
				Write-Output "Base64 encoded X.509 certificate (.CER) exported to $ExportFile"
			}
			# write the certificate properties to the pipeline
			else {
				if ($certificate -isnot [System.Security.Cryptography.X509Certificates.X509Certificate2]) {
					$certificate = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $certificate
				}

				[PSCustomObject]@{
					PSTypeName              = "Powertools.GetSSLCertificate.Result"
					Hostname				= $Hostname
					Subject                 = $certificate.Subject
					SubjectAlternativeNames = $certificate.DnsNameList
					Issuer                  = $certificate.Issuer
					Verified                = $certificate.Verify()
					NotBefore               = $certificate.NotBefore
					NotAfter                = $certificate.NotAfter
					SignatureAlgorithm      = $certificate.SignatureAlgorithm.FriendlyName
					PublicKeyAlgorithm      = $certificate.PublicKey.Key.KeyExchangeAlgorithm
					PublicKeySize           = $certificate.PublicKey.Key.KeySize
					Thumbprint              = $certificate.Thumbprint
					Version                 = $certificate.Version
				}
			}
		}
	}
}
