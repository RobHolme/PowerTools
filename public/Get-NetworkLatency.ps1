function Get-NetworkLatency {
	[CmdletBinding()]
	param(
		[parameter(
			Position = 0,
			Mandatory = $true,
			ValueFromPipeline = $true
		)]
		[string] $Hostname,

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

	begin {

		# timeout defaults to 4 seconds. Make the timeout the same as the interval if the interval is less than 4 seconds
		[int] $timeout = if ($Interval -lt 4) { $Interval } else { 4 }

		[LatencyResultCollection] $resultList = New-Object LatencyResultCollection

		# Load the ScottPlot library if outputting the result as a graph
		if ($GraphResult) {
			try {
				Add-Type -Path '.\lib\net6.0\ScottPlot.dll'
			}
			catch {
				write-warning "Unable to load library '.\lib\net6.0\ScottPlot.dll'.`n Graphing functionality will not be available."
				$noGraph = $true
			}
		}
	}
	
	process {
		# Catch hostname resolution failure. Move onto next host in the input pipeline.
		try {
			[System.Net.Dns]::GetHostaddresses($Hostname) | Out-Null
		}
		catch {
			Write-Warning "Unable to resolve the Hostname: $Hostname"
			return
		}

		# Clear summary values from prior hosts (from the input pipeline). Keep individual results for charting etc.
		$resultList.ResetSummary()

		for ($i = 0; $i -lt $Count; $i++) {
			[int] $secondsRemaining = ($Count - $i) * $Interval
			[int] $percentComplete = (($i + 1) / $Count) * 100
			Write-Progress -Activity "Testing $Hostname" -SecondsRemaining $secondsRemaining -PercentComplete $percentComplete -Status "Measuring network latency ..."    
			$latencyResult = TestLatency -DestinationHost $Hostname -Timeout $timeout
			$resultList.AddResult($latencyResult)	
			# show all results as they are returned if -ShowAllResults switch is set 
			if ($ShowAllResults) {
				[PSCustomObject]@{
					PSTypeName  = "Powertools.GetNetworkLatency.ImmediateResult"
					Destination = $Hostname
					Latency     = "$($latencyResult.Latency) ms"
					Status      = $latencyResult.Status
					TimeStamp   = $latencyResult.TimeStamp.ToString("yyyy-MM-dd HH:mm:ss")
				}
			}
			# don't sleep in the last iteration, otherwise sleep based on the $Interval parameter
			if ($i + 1 -lt $Count ) {
				Start-Sleep -Seconds $Interval
			}
		}
		# show summary of results for the current destination if -ShowAllResults switch not set
		if (!$ShowAllResults) {
			$failedPercent = if ($resultList.TotalCount -gt 0) { [Math]::Round(($resultList.FailedCount / $resultList.TotalCount) * 100) }
			[PSCustomObject]@{
				PSTypeName  = "Powertools.GetNetworkLatency.SummaryResult"
				Destination = $Hostname
				Average     = "$($resultList.AverageLatency) ms"
				Minimum     = "$($resultList.MinLatency) ms"
				Maximum     = "$($resultList.MaxLatency) ms"
				Loss        = "$($resultList.FailedCount) ($failedPercent%)"
			}
		}
	}

	end {
		# create graph
		if (!$noGraph) {
			GenerateChart -LatencyResults $resultList -Filename $GraphResult
		}
	}
}


# A class containing a collection of LatencyResult objects. Summery latency results (min, max, average, num failures) from the total collection are provided.
class LatencyResultCollection {
	[Collections.Generic.List[LatencyResult]] $resultList
	[int] $totalCount
	[int] $failedCount
	[int] $maxLatency
	[int] $minLatency
	[int] $sumLatency
	[int] $averageLatency

	LatencyResultCollection () {
		$this.resultList = New-Object Collections.Generic.List[LatencyResult]
		$this.totalCount = 0
		$this.failedCount = 0
		$this.maxLatency = 0
		$this.minLatency = 0
		$this.sumLatency = 0
		$this.averageLatency = 0
	}

	# Add a LatencyResult object to the collection. Recalculate max, min and average properties
	AddResult ([LatencyResult] $Result) {
		# return if the LatencyResult object received is $null
		if ($null -eq $Result) {
			Write-Verbose "Null LatencyResult object received. Excluding from results."
			return
		}

		$this.resultList.Add($Result)
		$this.totalCount++
		if ($Result.Status -ne "Success") {
			$this.failedCount++
			Write-Warning "Connection timeout"
		}
		# if a latency value was returned, recalculate the max,min, and average properties
		else {
			# average latency
			$this.sumLatency += $Result.Latency
			if (($this.totalCount - $this.failedCount) -gt 0) {
				$this.averageLatency = ($this.sumLatency) / ($this.totalCount - $this.failedCount)
			}
			# max latency
			if ($Result.Latency -gt $this.maxLatency) {
				$this.maxLatency = $Result.Latency
			}
			# min latency (if min latency is zero, then use this value for the min latency)
			if (($Result.Latency -lt $this.minLatency) -or ($this.minLatency -eq 0) ) {
				$this.minLatency = $Result.Latency
			}
		}
	}

	# Get the collection of results
	[Collections.Generic.List[LatencyResult]] GetResults() {
		return $this.resultList
	}

	# Get the Max Latency value from all results
	[int] MaxLatency() {
		return $this.maxLatency
	}

	# Get the Min latency value from all results
	[int] MinLatency() {
		return $this.minLatency
	}

	# get the total number of results
	[int] TotalCount() {
		return $this.totalCount
	}

	# Get the number os failed/timed out results
	[int] FailedCount() {
		return $this.failedCount
	}

	# Get the average latency for all successful results (failed results omitted)
	[int] AverageLatency() {
		return $this.averageLatency
	}

	# reset the summary values between hosts
	ResetSummary() {
		$this.totalCount = 0
		$this.failedCount = 0
		$this.maxLatency = 0
		$this.minLatency = 0
		$this.sumLatency = 0
		$this.averageLatency = 0
	}
}


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
		$this.latency = $Latency
		$this.status = $Status
		$this.timeStamp = $TimeStamp
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

# Test the latency using Test-Connection. Return a LatencyResult object.
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
		return New-Object LatencyResult($result.Source, $Hostname, $result.Latency, $result.Status, [datetime]::Now)
	}
	catch [System.Exception] {
		Write-error $_.Exception.Message
		Write-Debug $_.Exception
		return $null
	}
}

function GenerateChart {
	Param (
		[parameter(Mandatory = $true)]
		[LatencyResultCollection] $LatencyResults,

		[parameter(Mandatory = $true)]
		[string] $Filename
		
	)

	if (!$noGraph) {
		$latencyTable = @{}
		foreach ($result in $LatencyResults.resultList) {
			if ($latencyTable.ContainsKey($result.Destination)) {
				# only plot successful results
				if ($result.Status -eq "Success") {
					$latencyTable[$result.destination] += $result.Latency
				}
			}
			else {
				$latencyTable[$result.destination] = @($result.Latency)
			}
		}

		$chart = [ScottPlot.Plot]::new(1200, 900)
		foreach ($key in $latencyTable.Keys) {
			[void] $chart.AddSignal($latencyTable[$key],1,$null,$key.ToString())
			#$chart.AddSignal($latencyTable[$key])
		} 

		[void] $chart.Legend($true, [ScottPlot.Alignment]::UpperLeft)
		$chart.Title("Network Latency",$null)
		$chart.YLabel("Latency (ms)")
		$chart.XLabel("ICMP Requests")
		$chart.SaveFig($Filename)
	}
}

 


