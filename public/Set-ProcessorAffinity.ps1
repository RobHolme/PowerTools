function Set-ProcessorAffinity {
    <#
.NOTES
Function Name   : Set-ProcessorAffinity
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (08/07/2016)
Requires        : PowerShell V2

.SYNOPSIS
Limits the number of processor cores (incl hyper-threaded 'core') that a process can run on.
.DESCRIPTION
Limits the number of processor cores (incl hyper-threaded 'core') that a process can run on.
.EXAMPLE
Set-ProcessorAffinity -ProcessName "DCMWin" -Cores 2
.EXAMPLE
Set-ProcessorAffinity -ProcessID 6048 -Cores 4
.PARAMETER ProcessName
The name of the process to set the processor affinity for.
.PARAMETER ProcessID
The ID of the process to set the processor affinity for.
.PARAMETER Cores
The number of cpu cores to limit the process to. This includes hyper threaded cores. Set to 0 to use normal processor scheduling.
.NOTES
Works with linux, however not all processes support changing the processor affinity attribute.
#>
    [CmdletBinding(DefaultParametersetName = "ProcessName")]
    Param(
        [Parameter(
            Position = 0,
            Mandatory = $True,
            ValueFromPipeline = $True,
            ParameterSetName = "ProcessName")]
        [string] $ProcessName,

        [Parameter(
            Position = 0,
            Mandatory = $True,
            ValueFromPipeline = $True,
            ParameterSetName = "ProcessID")]
        [Alias("Id")]
        [int] $ProcessID,

        [Parameter(
            Position = 1,
            Mandatory = $False)]
        [int] $Cores
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
            try {
                # ProcessorAffinity is a bit mask. 1 core = 1, 2 cores = 3, 3 cores = 7, 4 cores = 15, 5 cores = 31, 6 cores = 63, 7 cores = 127, 8 cores = 255
                $process.ProcessorAffinity = [int][math]::pow(2, $cores) - 1
                $properties = @{
                    ProcessName = $process.ProcessName
                    ProcessID   = $process.Id
                    Cores       = $cores
                }
                $outputObject = New-Object -TypeName PSObject -Property $properties
                $outputObject.PSObject.TypeNames.Insert(0, "Powertools.SetProcessorAffinity.Result")
                write-output $outputObject
            }
            catch {
                Write-Error -Exception $_.Exception  -Message  "Failed to set the processor affinity for process $($process.Name)"
            }
        }
    }
}