function Get-SSLCertificate {
	<#
.NOTES
	based on https://gist.github.com/jstangroome/5945820
.SYNOPSIS
	Summarise the total size of folders (and files) for a path.
.PARAMETER SiteName
	The remote website name.
.PARAMETER Port
	Optionally provide the TCP port number of the remote website. Defaults to 443 if omitted.
.PARAMETER SNIName
	Optionally provide a SNI (Server Name Indication) name. Where a single site supports multiple certs, SNI name identifies the cert requested.
.EXAMPLE
	Get-SSLCertificate -SiteName www.example.com 
.EXAMPLE
	Get-SSLCertificate -SiteName www.example.com -SNIName www.example.com 
#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[Alias('ComputerName')] 
		[string] $SiteName,

		[Parameter(Mandatory = $false, Position = 1)]
		[ValidateRange(1, 65535)]
		[int] $Port = 443,

		[Parameter(Mandatory = $false, Position = 2)]
		[string] $SNIname = ''
	)

	process {
		$certificate = $null
		$tcpClient = New-Object -TypeName System.Net.Sockets.tcpClient

		try {
			$tcpClient.Connect($SiteName, $Port)
			$tcpStream = $tcpClient.GetStream()
			$callback = { param($caller, $cert, $chain, $errors) return $true }
			$sslStream = New-Object -TypeName System.Net.Security.sslStream -ArgumentList @($tcpStream, $true, $callback)
			try {
				# optionally provide a SNI name (where a single site supports multiple certs, SNI name identifies the cert requested)
				$sslStream.AuthenticateAsClient($SNIname)
				$certificate = $sslStream.RemoteCertificate
			}
			finally {
				$sslStream.Dispose()
			}
		} 
		finally {
			$tcpClient.Dispose()
		}

		if ($certificate) {
			if ($certificate -isnot [System.Security.Cryptography.X509Certificates.X509Certificate2]) {
				$certificate = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $certificate
			}

			[PSCustomObject]@{
				PSTypeName              = "Powertools.Get-SSLCertificate.Result"
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
