function Get-NetworkLatency {
		<#
.NOTES
Function Name   : Get-NetworkLatency
Author          : Rob Holme (rob@holme.com.au)

.SYNOPSIS
Reports latency to connect to a remote host 
.DESCRIPTION
Tests connectivity via ICMP to a remote host. Latency stats returned, and optionally saved as a chart.
.EXAMPLE
Get-NetworkLatency -Hostname "www.google.com","www.microsoft.com","www.news.com.au" -Count 15 -Interval 1 -GraphResult ./test.png
.EXAMPLE
Get-NetworkLatency -Hostname "www.google.com" -Count 50 -Interval 2 -ShowAllResults
.PARAMETER Hostname
The Hostname or IP address of the host to connect to. Supply an array of hosts to test multiple hosts
.PARAMETER Count
The number of ICMP connection tests to perform
.PARAMETER Interval
The interval in seconds between tests. If the interval is less than 4 secs, the ICMP timeout will be set to match the interval (timeout remains at 4 secs for larger intervals). 
.PARAMETER ShowAllResults
Display the ICMP response as the tests occur (for each test). No summary stats will be provided with this option
.PARAMETER GraphResult
Supply a filename (.PNG) to save a chart of the latency for each test. 
#>

	[CmdletBinding()]
	param(
		[parameter(
			Position = 0,
			Mandatory = $true,
			ValueFromPipeline = $true
		)]
		[string[]] $Hostname,

		[Parameter(
			Position = 1,
			Mandatory = $false,
			ValueFromPipeline = $false
		)]
		[ValidateRange(1, [int]::MaxValue)]
		[int] $Count = 10,

		[Parameter(
			Position = 2,
			Mandatory = $false,
			ValueFromPipeline = $false
		)]
		[ValidateRange(.6, 300)]
		[int] $Interval = 1,

		[Parameter(
			Position = 3,
			Mandatory = $false,
			ValueFromPipeline = $false
		)]
		[switch] $ShowAllResults,

		[parameter(
			Position = 4,
			Mandatory = $false,
			ValueFromPipeline = $false
		)]
		[string] $GraphResult
	)	

	
	#--------------------------------------
	# One off actions 
	begin {
		# timeout defaults to 4 seconds. Make the timeout the same as the interval if the interval is less than 4 seconds
		[int] $timeout = if ($Interval -lt 4) { $Interval } else { 4 }

		[LatencyResultCollection] $latencyResultList = [LatencyResultCollection]::new()
		
		# Load the ScottPlot library if outputting the result as a graph
		if ($GraphResult) {
			try {
				Add-Type -Path '$PSScriptRoot\lib\net6.0\ScottPlot.dll'
			}
			catch {
				write-warning "Unable to load library '$PSScriptRoot\lib\net6.0\ScottPlot.dll'.`n Graphing functionality will not be available."
				$noGraph = $true
			}
		}
	}
	
	#--------------------------------------
	# process each object from the pipeline
	process {
		# Catch hostname resolution failure. Move onto next host in the input pipeline.
		foreach ($currentHost in $Hostname) {
			try {
				$resolvedIP = [System.Net.Dns]::GetHostaddresses($currentHost) 
				Write-Verbose "$currentHost resolved to $($resolvedIP.IPAddressToString)"
			}
			catch {
				Write-Error "Unable to resolve the Hostname: $currentHost"
				return
			}
		}

		for ($i = 0; $i -lt $Count; $i++) {
			[int] $secondsRemaining = ($Count - $i) * $Interval
			[int] $percentComplete = (($i + 1) / $Count) * 100
			foreach ($currentHost in $Hostname) {
				Write-Progress -SecondsRemaining $secondsRemaining -PercentComplete $percentComplete -Activity "Measuring network latency ..."    
				$latencyResult = TestLatency -DestinationHost $currentHost -Timeout $timeout
				$latencyResultList.AddResult($latencyResult)	
				# show all results as they are returned if -ShowAllResults switch is set 
				if ($ShowAllResults) {
					[PSCustomObject]@{
						PSTypeName  = "Powertools.GetNetworkLatency.ImmediateResult"
						Destination = $currentHost
						Latency     = "$($latencyResult.Latency) ms"
						Status      = $latencyResult.Status
						TimeStamp   = $latencyResult.TimeStamp.ToString("yyyy-MM-dd HH:mm:ss")
					}
				}
			}
			# don't sleep in the last iteration, otherwise sleep based on the $Interval parameter
			if ($i + 1 -lt $Count ) {
				Start-Sleep -Seconds $Interval
			}
		}
		# show summary of results for the current destination if -ShowAllResults switch not set
		if (!$ShowAllResults) {
			foreach ($currentHost in $Hostname) {
				$failedPercent = if ($latencyResultList.TotalCount($currentHost) -gt 0) { [Math]::Round(($latencyResultList.FailedCount($currentHost) / $latencyResultList.TotalCount($currentHost)) * 100) }
				[PSCustomObject]@{
					PSTypeName  = "Powertools.GetNetworkLatency.SummaryResult"
					Destination = $currentHost
					Average     = "$($latencyResultList.AverageLatency($currentHost)) ms"
					Minimum     = "$($latencyResultList.MinLatency($currentHost)) ms"
					Maximum     = "$($latencyResultList.MaxLatency($currentHost)) ms"
					Loss        = "$($latencyResultList.FailedCount($currentHost)) ($failedPercent%)"
				}
			}
		}
	}

	
	#--------------------------------------
	# Final actions after process() has finished for all object from the pipeline
	end {
		if ((!$noGraph) -and ($GraphResult)) {
			$allResultsHash = GetLatencyHashTable -LatencyResults $latencyResultList
			if ($Count -gt 50) {
				GenerateChart -LatencyHashtable $allResultsHash -Filename $GraphResult -Height 900 -Width 1920
			}
			else {
				GenerateChart -LatencyHashtable $allResultsHash -Filename $GraphResult -Height 900 -Width 1200
			}
		}
	}
}


#--------------------------------------
# Stores the result of a single ICMP test to measure the network latency to a remote host
class LatencyResult {
	[string] $source
	[string] $destination
	[int] $latency
	[string] $status
	[datetime] $timeStamp

	LatencyResult([string] $Source, [string] $Destination, [int] $Latency, [string] $Status, [datetime] $TimeStamp) {
		$this.source = $Source
		$this.destination = $Destination
		$this.status = $Status
		$this.timeStamp = $TimeStamp
		$this.latency = $Latency
	}

	# Get the source host 
	[string] Source() {
		return $this.source
	}

	# Get the destination host
	[string] Destination() {
		return $this.destination
	}

	# Get the Latency
	[int] Latency() {
		return $this.latency
	}

	# Get the status of the ICMP connection
	[string] Status() {
		return $this.status
	}
	
	# Get the time of the test
	[datetime] TimeStamp() {
		return $this.timeStamp
	}
}


#--------------------------------------
# A class containing a collection of LatencyResult objects. 
# Summery latency results (min, max, average, num failures) calculated for each destination host are exposed as members
class LatencyResultCollection {
	[Collections.Generic.List[LatencyResult]] $resultList
	[hashtable] $totalCountTable = @{}
	[hashtable] $failedCountTable = @{}
	[hashtable] $maxLatencyTable = @{}
	[hashtable] $minLatencyTable = @{}
	[hashtable] $sumLatencyTable = @{}
	[hashtable] $averageLatencyTable = @{}

	LatencyResultCollection () {
		$this.resultList = New-Object Collections.Generic.List[LatencyResult]
	}

	# Add a LatencyResult object to the collection. Recalculate max, min and average properties
	[void] AddResult ([LatencyResult] $Result) {
		# return if the LatencyResult object received is $null
		if ($null -eq $Result) {
			Write-Verbose "Null LatencyResult object received. Excluding from results."
			return
		}
		$this.resultList.Add($Result)

		# increment the total count for the destination
		if ($this.totalCountTable.ContainsKey($Result.Destination)) {
			$this.totalCountTable[$Result.Destination]++
		}
		else {
			$this.totalCountTable.Add($Result.Destination, 1)
		}

		# increment the failed count for the destination
		if ($Result.Status -ne "Success") {
			if ($this.failedCountTable.ContainsKey($Result.Destination)) {
				$this.failedCountTable[$Result.Destination]++
			}
			else {
				$this.failedCountTable.Add($Result.Destination, 1)
			}
			Write-Warning "Connection timeout to $($Result.Destination)"
		}

		# if a latency value was returned, recalculate the max, min, and average properties
		else {
			# calculate average latency (for the destination host)
			if ($this.sumLatencyTable.ContainsKey($Result.Destination)) {
				$this.sumLatencyTable[$Result.Destination] += $Result.Latency
			}
			else {
				$this.sumLatencyTable.Add($Result.Destination, $Result.Latency)
			}

			if (($this.totalCountTable[$Result.Destination] - $this.failedCountTable[$Result.Destination]) -gt 0) {
				$this.averageLatencyTable[$Result.Destination] = ($this.sumLatencyTable[$Result.Destination]) / ($this.totalCountTable[$Result.Destination] - $this.failedCountTable[$Result.Destination])
			}

			# calculate max latency (for the destination host)
			if ($this.maxLatencyTable.ContainsKey($Result.Destination)) {
				if ($Result.Latency -gt $this.maxLatencyTable[$Result.Destination]) {
					$this.maxLatencyTable[$Result.Destination] = $Result.Latency
				}
			}
			else {
				$this.maxLatencyTable.Add($Result.Destination, $Result.Latency)
			}

			# calculate min latency (for the destination host)
			if ($this.minLatencyTable.ContainsKey($Result.Destination)) {
				if ($Result.Latency -lt $this.minLatencyTable[$Result.Destination]) {
					$this.minLatencyTable[$Result.Destination] = $Result.Latency
				}
			}
			else {
				$this.minLatencyTable.Add($Result.Destination, $Result.Latency)
			}
		}
	}

	# Get the collection of results
	[Collections.Generic.List[LatencyResult]] GetResults() {
		return $this.resultList
	}

	# Get the Max Latency value from all results
	[int] MaxLatency([string] $DestinationHost) {
		if ($this.maxLatencyTable.ContainsKey($DestinationHost)) {
			return $this.maxLatencyTable[$DestinationHost]
		}
		else {
			return 0
		}
	}

	# Get the Min latency value from all results
	[int] MinLatency([string] $DestinationHost) {
		if ($this.minLatencyTable.ContainsKey($DestinationHost)) {
			return $this.minLatencyTable[$DestinationHost]
		}
		else {
			return 0
		}
	}

	# get the total number of results
	[int] TotalCount([string] $DestinationHost) {
		if ($this.totalCountTable.ContainsKey($DestinationHost)) {
			return $this.totalCountTable[$DestinationHost]
		}
		else {
			return 0
		}
	}

	# Get the number os failed/timed out results
	[int] FailedCount([string] $DestinationHost) {
		if ($this.failedCountTable.ContainsKey($DestinationHost)) {
			return $this.failedCountTable[$DestinationHost]
		}
		else {
			return 0
		}
	}

	# Get the average latency for all successful results (failed results omitted)
	[int] AverageLatency([string] $DestinationHost) {
		if ($this.averageLatencyTable.ContainsKey($DestinationHost)) {
			return $this.averageLatencyTable[$DestinationHost]
		}
		else {
			return 0
		}
	}

}


#--------------------------------------
# Test the latency using Test-Connection. 
# Return a LatencyResult object.
function TestLatency() {
	# Return type
	[OutputType([LatencyResult])]
	Param (
		# Destination hostname or IP address
		[parameter(Mandatory = $true)]
		[string] $DestinationHost,
	
		# Timeout for the ICMP connection test
		[parameter(Mandatory = $true)]
		[int] $Timeout
	)

	try {
		$result = Test-Connection -TargetName $DestinationHost -Count 1  -TimeoutSeconds $Timeout
		return New-Object LatencyResult($result.Source, $DestinationHost, $result.Latency, $result.Status, [datetime]::Now)
	}
	catch {
		Write-Warning $_.Exception.Message
		Write-Debug $_.Exception
		return $null
	}
}


#--------------------------------------
# Generate a signal chart (signal plot) of latency results for each host.
function GenerateChart {
	Param (
		[parameter(Mandatory = $true)]
		[Hashtable] $LatencyHashtable,

		[parameter(Mandatory = $true)]
		[string] $Filename,

		[parameter(Mandatory = $false)]
		[int] $Width = 1200,

		[parameter(Mandatory = $false)]
		[int] $Height = 900
	)

	if (!$noGraph) {
		$chart = [ScottPlot.Plot]::new($Width, $Height)
		foreach ($key in $LatencyHashtable.Keys) {
			$plotLine = $chart.AddSignal($LatencyHashtable[$key], 1, $null, $key.ToString())
			$plotLine.LineWidth = 3
			$plotLine.MarkerSize = 7
			$plotLine.MarkerShape = [ScottPlot.MarkerShape]::filledDiamond
			$plotLine.Smooth = $true
			# tighten the smoothing tension if more than 50 samples
			if ($LatencyHashtable[$key].Count -lt 50) {
				$plotLine.SmoothTension = 0.4
			}
			else {
				$plotLine.SmoothTension = 0.2
			}
		} 

		# set chart legend and axis labels
		$legend = $chart.Legend($true, [ScottPlot.Alignment]::UpperLeft)
		$legend.Orientation = [ScottPlot.Orientation]::Horizontal
		$chart.Title("Network Latency", $null)
		$chart.YLabel("Latency (ms)")
		$chart.XLabel("ICMP Requests")

		# Save the chart. If relative path provided base the location on hte current directory.
		[System.IO.Directory]::SetCurrentDirectory($(get-location))
		$Filename = [System.IO.Path]::GetFullPath($Filename)
		try {
			$chartFilename = $chart.SaveFig($Filename)
			Write-Host "Chart saved to $chartFilename" -ForegroundColor green
			& $chartFilename
		}
		catch {
			Write-Warning "Unable to save chart to $Filename"
			Write-Warning $_.Exception.Message
			Write-Debug $_.Exception
		}
	}
}


#--------------------------------------
# Formats the latency result collection as a hash table. The Hostname is used as the table key.
function GetLatencyHashTable() {
	Param (
		[parameter(Mandatory = $true)]
		[LatencyResultCollection] $LatencyResults
	)

	$latencyTable = @{}
	foreach ($result in $LatencyResults.resultList) {
		if ($latencyTable.ContainsKey($result.Destination)) {
			$latencyTable[$result.destination] += $result.Latency
		}
		else {
			$latencyTable[$result.destination] = @($result.Latency)
		}
	}
	return $latencyTable
}
