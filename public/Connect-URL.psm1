function Connect-URL {
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
		[string] $URL
	)

	$request = [System.Net.WebRequest]::Create($URL)
	try {
		$timeElapsed = Measure-Command {
			$response = $request.GetResponse()
		}
		$status = [int]$response.StatusCode
		$result = [Ordered]@{
			StatusCode   = $status
			ResponseTime = "$([math]::Round($timeElapsed.Milliseconds,2)) (ms)"  
			URL          = $URL
		} 
		$response.Close()
		$outputObject = New-Object -Property $result -TypeName psobject
		$outputObject.PSObject.TypeNames.Insert(0, "Powertools.ConnectURL.Result")
		Write-Output $outputObject
	}
	catch {
		write-warning "Failed to connect to $URL"
	}
}
