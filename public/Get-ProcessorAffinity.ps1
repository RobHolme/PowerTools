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
The name of the process to query the processor affinity for. Can include wildcards to return more than one process
.PARAMETER ProcessID
The ID of the process to query the processor affinity for.
.EXAMPLE
PS C:\> Get-ProcessorAffinity -ProcessName msedge

ProcessID Cores ProcessName
--------- ----- -----------
     7380     4 msedge
    10376     4 msedge
    12276     4 msedge
    14296     4 msedge
    16004     4 msedge
    18700     4 msedge
    19908     4 msedge
    20144     4 msedge
    21896     4 msedge
    23072     4 msedge
.EXAMPLE
PS C:\> Get-ProcessorAffinity -ProcessName m*

ProcessID Cores ProcessName
--------- ----- -----------
     4520     0 MCEBuddy.Service
     4244     0 mDNSResponder
     2288     0 Memory Compression
    11132     4 Microsoft.Photos
    10708     0 mmc
    19320     4 mobsync
     8384     0 MoUsoCoreWorker
     7380     4 msedge
    10376     4 msedge
    12276     4 msedge
    14296     4 msedge
    16004     4 msedge
    18700     4 msedge
    19908     4 msedge
    20144     4 msedge
    21896     4 msedge
    23072     4 msedge
	 4764     0 MsMpEng
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
