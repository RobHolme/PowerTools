# dot source private functions
$privateFunctions = Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "..\private\PrivateFunctions.ps1"
. $privateFunctions

function Get-ProcessorUtilisation {
    <#
.NOTES
Function Name   : Get-ProcessorUtilisation
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (16/10/2016)
Requires        : PowerShell V2

.SYNOPSIS
Display the overall processor utilisation and process utilisation stats
.DESCRIPTION
Display the overall processor utilisation and process utilisation stats
.EXAMPLE
Get-ProcessorUtilisation -top 10
.PARAMETER Top
Limit the results to the top results
#>

    [CmdletBinding(DefaultParametersetName = "TopProcesses")]
    Param(
        # limit query to Top x processes
        [Parameter(
            Mandatory = $False,
            ParameterSetName = "TopProcesses"
        )]
        [ValidateRange(1, 1000)] [int] $Top,

        # only display utilisation for specific processes
        [Parameter(
            Mandatory = $False,
            ParameterSetName = "ProcessName",
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True
        )]
        [string[]] $ProcessName
    )

    begin {
        # warn and exit if using powershell core, only supported on Windows Powershell v2, v3, v4 and v5.x
        If ($IsCoreCLR) {
            $abortProcessing = $true
            write-warning "This function is not supported under PowerShell Core. This requires Windows PowerShell."
        }
        else {
            $abortProcessing = $false

            $uniqueProcesses = @()
            # get number of processor cores
            $cpus = Get-WmiObject win32_Processor
            foreach ($cpu in $cpus) {
                $totalCpuCores += $cpu.NumberOfLogicalProcessors
            }
            Write-Verbose "Total CPU cores: $totalCpuCores"
            # get the process and CPU utiltisation
            $counters = (Get-Counter '\Process(*)\% Processor Time').CounterSamples
        }
    }

    # process each item form the pipeline
    process {
        if (!$abortProcessing) {
            $sortedCounters = @()
            # display specific processes only if the ProcessName parameter provided
            If ($ProcessName) {
                foreach ($process in $ProcessName) {
                    # if the process list is piped in, there may be multiple instances of the same process names. Since each iteration returns all matching processes this would result in duplication, so only search for unique process names.
                    if ($uniqueProcesses -notcontains $process) {
                        $uniqueProcesses += $process
                        $sortedCounters += $counters | where-object -FilterScript { $_.InstanceName -eq $process }
                    }
                }
            }

            # display utilisation of all (or top) processes
            else {
                if ($Top) {
                    $sortedCounters = $counters | Sort-Object -Property CookedValue -Descending | Select-Object -First $Top
                }
                else {
                    $sortedCounters = $counters | Sort-Object -Property CookedValue -Descending
                }
            }

            # Get-Process requires elevated rights to get the path for all processes
            if (!(IsAdmin)) {
                write-warning "Run-as Administrator rights needed to list the path for all processes. Some paths will not be displayed."
            }
            $processPaths = @{ }
            $allProcesses = Get-Process
            foreach ($process in $allProcesses) {
                if (!$processPaths.ContainsKey($process.Name)) {
                    $processPaths.Add($process.Name, $process.Path)
                }
            }

            # display the CPU and process utilisation (need to divide the utilisation by the number of cores. eg idle returned on a 8 core system is 800% )
            foreach ($counter in $sortedCounters) {
                $properties = @{
                    ProcessName = $counter.InstanceName
                    CPU         = (($counter.Cookedvalue / 100) / $totalCpuCores).toString('P')
                    Path        = ($processPaths[$counter.InstanceName])
                }
                $outputObject = New-Object -TypeName PSObject -Property $properties
                $outputObject.PSObject.TypeNames.Insert(0, "Powertools.ProcessorUtilisation.Result")
                write-output $outputObject
            }
        }
    }
}
