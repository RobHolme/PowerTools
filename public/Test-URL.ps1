function Test-URL {
	<#
.NOTES
Function Name   : Connect-TCPPort
Author          : Rob Holme (rob@holme.com.au)
Requires        : PowerShell V3

.SYNOPSIS
Tests connectivity to a URL.
.DESCRIPTION
Tests connectivity to a URL. Reports HTTP status code returned and time taken for the web server to respond, or writes warning if connection failed.
.EXAMPLE
Connect-URL -URL http://somewebsite.com/default.html

.PARAMETER URL
The URL to connect to.

#>
	param(
		[Parameter(
			Position = 0,
			Mandatory = $True,
			ValueFromPipeline = $True,
			ValueFromPipelineByPropertyName = $true)]
		[string] $URL,

		[Parameter(
			Position = 1,
			Mandatory = $False,
			ParameterSetName='SystemProxy')]
		[switch] $UseSystemProxy,

		[Parameter(
			Position = 1,
			Mandatory = $False,
			ParameterSetName='ProxyURI')]
		[string] $ProxyURI,

		[Parameter(
			Position = 1,
			Mandatory = $False)]
		[PSCredential] $ProxyCredential,

		[Parameter(
			Position = 2,
			Mandatory = $False
		)]
		[switch] $PreventRedirect
	)

	process {

		$status = ""
		$request = [System.Net.WebRequest]::Create($URL)
		# prevent redirects if the -PreventRedirect switch is provided
		if ($PreventRedirect) {
			$request.AllowAutoRedirect = $false 
		}
		
		# use system proxy [DOES NOT USE AUTO DETECTED PROXY]
		#if ($UseSystemProxy) {
		#	$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
		#	$request.Proxy = $proxy
		#	write-verbose "Using proxy server: $proxy"
		#}
		#if ($ProxyURI) {
		#	try {
		#		$proxyAddress = [uri]::new($ProxyURI)
		#	}
		#	catch {
		#		Write-Error "ProxyURI parameter does not appear to be correct. You must provide a URI (e.g. http://proxyserver.domain:8181)" 
		#		return
		#	}
		#	$proxy = [System.Net.WebProxy]::new($ProxyURI)
		#}
		#if ($ProxyCredential) {
		#	$proxy.Credentials = $ProxyCredential.GetNetworkCredentials()	
		#}
		#else {
		#	$proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
		#      vvv  OR  ^^^
		#   $proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
		#}

		try {
			$timeElapsed = Measure-Command {
				$response = $request.GetResponse()
			}
			$status = [int]$response.StatusCode
			$response.Close()
		}
		# catch exceptions thrown (401's 404's etc). 
		# Note: Some sites redirect page not found to a custom page via a 302 - these would be mistakenly reported as a 200.
		catch {	
			if ($_.Exception.Message -match "(?<=\()\d{3}") {
				$status = $Matches[0]
			}
			else {	
				write-warning "Failed to connect to $URL"
				write-debug  "Exception thrown: $($_.Exception.Message)"
			}
		}
	
		[PSCustomObject]@{
			PSTypeName   = "Powertools.ConnectURL.Result"
			StatusCode   = $status
			ResponseTime = "$([math]::Round($timeElapsed.Milliseconds,2)) (ms)"  
			URL          = $URL
		} 
	}
}
