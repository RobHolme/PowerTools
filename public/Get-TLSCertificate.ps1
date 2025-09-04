function Get-TLSCertificate {
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
	Will default to using the hostname as the SNI name if not provided. Use a SNI name with a single space to force not using SNI (-SNIName ' ').
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
	# provide a full URL as a hostname
	Get-SSLCertificate Hostname https://www.example.com:8443
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
		[string] $SNIname,

		[Parameter(
			Mandatory = $false,
			Position = 3)]
		[string] $ExportFile,

		[Parameter (
			Mandatory=$false,
			Position=4 )]
		[int] $Timeout = 3
	)


	begin {
		if ($PSEdition -ne "Core") {
			Write-Warning "For best results use PowerShell v7+. Earlier versions (Windows PowerShell v5.x) may fail to negotiate TLS in some situations."
		}
	}

	process {
		# strip any HTTP/S schemes from the hostname if included 
		$Hostname = $Hostname -replace('(HTTPS|HTTP)\://','')
		# extract the port number from the hostname string if supplied instead of using -Port switch (eg https://www.server.com:8443)
		$splitHostname = $Hostname -split ':'
		if ($splitHostname.Count -gt 1) {
			$Hostname = $splitHostname[0]
			# remove path from the URL, extract the port number. Confirm extracted port value is an int.
			try {
				$splitPort = $splitHostname[1] -split "/"
				$Port = [convert]::ToInt32($splitPort[0]) 
			}
			catch{
				Write-Error "Unable to extract port number from URL"
				return
			}
		}
		else {
			# remove  path from the URL
			$Hostname = ($Hostname -split "/")[0]
		}

		# Use a SNI Name if provided. 
		# If not SNI name provided, detect if the hostname is a FQDN, is so then set the SNI Name to be the same value.
		# Very basic FQDN detection, anything ending in a 2 or more letter TLD is accepted.
		# To force not using SNI name, use a string with a single space ' '
		[string] $SniNameValue
		if ($SNIname) {
			$SniNameValue = $SNIname
			write-Verbose "Setting SNI name to $SNIname"
		}
		else {
			if ($Hostname -match "\.[a-z]{2,}$") {
				$SniNameValue = $Hostname
				write-Verbose "Setting SNI name to $Hostname"
			}
			else {
				write-Verbose "No SNI name set"
				$SniNameValue = ' '
			}
		}


		$timeoutMilliseconds = $Timeout * 1000
		$certificate = $null
		$tcpClient = New-Object -TypeName System.Net.Sockets.tcpClient

		try {
			Write-Verbose "Connecting to $($Hostname):$($Port)"
			Write-Verbose "Timeout: $timeoutMilliseconds ms"

			$tcpConnectResult = $tcpClient.ConnectAsync($Hostname, $Port).Wait($timeoutMilliseconds)
			if ($tcpConnectResult -eq $true) {
				$tcpStream = $tcpClient.GetStream()
				$callback = { param($caller, $cert, $chain, $errors) return $true }
				$sslStream = New-Object -TypeName System.Net.Security.sslStream -ArgumentList @($tcpStream, $true, $callback)
				try {
					# optionally provide a SNI name (where a single site supports multiple certs, SNI name identifies the cert requested)
					$sslStream.AuthenticateAsClient($SniNameValue)
					$certificate = $sslStream.RemoteCertificate
				}
				catch {
					Write-Warning "Failed to retrieve certificate from $($Hostname):$($Port). Socket may not support TLS, or client settings may have prevented TLS negotiation."
					Write-Warning "$($_.Exception.InnerException.Message)"
					Write-Debug "$($_.Exception)"
					Write-Host ""
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

				# For some reason $certificate.DnsNameList does not return values all of the time. The following workaround obtains the DNS and IP SANs from the certificate extensions.
				# Seems to be an issue with properties of the type "ScriptProperty" - also impacted $certificate.EnhancedKeyUsageList property.
				foreach ($extension in $certificate.Extensions) {
					[System.Security.Cryptography.AsnEncodedData] $asnData =  [System.Security.Cryptography.AsnEncodedData]::new($extension.Oid, $extension.RawData)
					# SAN OID value
					if ($asnData.Oid.Value -eq "2.5.29.17") {
						$subjectAlternativeNames = $asnData.Format($true) -replace "DNS Name=" -replace "IP Address=" -replace "RFC822 Name=" -replace "URL="
						$subjectAlternativeNames = $subjectAlternativeNames.Split([System.Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries)
					}
				}

				[PSCustomObject]@{
					PSTypeName              = "Powertools.GetSSLCertificate.Result"
					Hostname				= $Hostname
					Verified                = $certificate.Verify()
					Subject                 = $certificate.Subject
					SubjectAlternativeNames = $subjectAlternativeNames
					Issuer                  = $certificate.Issuer
					ValidFrom               = $certificate.NotBefore
					ValidTo          	    = $certificate.NotAfter
					SignatureAlgorithm      = $certificate.SignatureAlgorithm.FriendlyName
					PublicKeyAlgorithm      = $certificate.PublicKey.EncodedKeyValue.Oid.FriendlyName 
					PublicKeySize           = $certificate.PublicKey.Key.KeySize
					Thumbprint              = $certificate.Thumbprint
					Version                 = $certificate.Version
					SerialNumber			= $certificate.SerialNumber
					EnhancedKeyUsage		= $certificate.Extensions.EnhancedKeyUsages.FriendlyName
				}
			}
		}
	}
}
