function Get-ProcessorAffinity {
	<#
.NOTES
Function Name   : Get-ProcessorAffinity
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (08/07/2016)
                : 1.1 (29/09/2016) - Updated parameters to accept ValueFromPipelineByPropertyName, allows get-process to be piped to the function
Requires        : PowerShell V2

.SYNOPSIS
Reports the number of processor cores (incl hyper-threaded 'core') that a process can run on.
.DESCRIPTION
Reports the number of processor cores (incl hyper-threaded 'core') that a process can run on.
.EXAMPLE
Get-ProcessorAffinity -Process "DCMWin" -Cores 2
.PARAMETER ProcessName
The name of the process to query the processor affinity for.
.PARAMETER ProcessID
The ID of the process to query the processor affinity for.
#>
	[CmdletBinding(DefaultParametersetName = "ProcessName")]
	Param(
		[Parameter(
			Position = 0,
			Mandatory = $True,
			ValueFromPipeline = $True,
			ValueFromPipelineByPropertyName = $True,
			ParameterSetName = "ProcessName")]
		[string] $ProcessName,

		[Parameter(
			Mandatory = $True,
			ValueFromPipeline = $True,
			ParameterSetName = "ProcessID")]
		[Alias("Id")]
		[int] $ProcessID
	)

	# set the affinity for each process macthing the process name
	process {
		if ($ProcessName) {
			$processes = Get-Process -Name $ProcessName
		}
		elseif ($ProcessID) {
			$processes = Get-Process -Id $ProcessID
		}
		foreach ($process in $processes) {
			# ProcessorAffinity is a bit mask. 1 core = 1, 2 cores = 3, 3 cores = 7, 4 cores = 15, 5 cores = 31, 6 cores = 63, 7 cores = 127, 8 cores = 255
			[PSCustomObject]@{
				PSTypeName  = "Powertools.SetProcessorAffinity.Result"
				ProcessName = $process.ProcessName
				ProcessID   = $process.Id
				Cores       = [math]::Log($process.ProcessorAffinity + 1, 2)
			}
		}
	}
}
