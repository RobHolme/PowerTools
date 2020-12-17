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
