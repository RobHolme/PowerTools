# dot source private functions
$privateFunctions = Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) '..\private\PrivateFunctions.ps1'
. $privateFunctions

function Select-Tail() {
    <#
.NOTES
Function Name  : Select-Tail
Author     : Rob Holme (rob@holme.com.au)
Requires   : PowerShell V2  

.SYNOPSIS 
Display the last lines of a log file
.DESCRIPTION 
Display the last lines of a log file
.EXAMPLE 
Select-Tail -Path c:\log.txt -count 20
.EXAMPLE 
Select-Tail -Path c:\log.txt -Wait
.PARAMETER Path 
The name of the file to display. 
.PARAMETER Count 
The number of lines to display. Default to 10. 
.PARAMETER Wait
Keep waiting to display additional lines added to end of file.
#>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    Param(
        [Parameter(
            Position = 0, 
            Mandatory = $True, 
            ParameterSetName = "Path",
            ValueFromPipeline = $True, 
            ValueFromPipelineByPropertyName = $true)] 
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')] [string[]] $Path,

        [Parameter(
            Position = 0,
            Mandatory = $True, 
            ParameterSetName = "LiteralPath",
            ValueFromPipeline = $False,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Literal path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        [string[]] $LiteralPath,
    
        [Parameter(
            Position = 1, 
            Mandatory = $False)] 
        [int] $Count = 10,
        
        [Parameter(
            Position = 2, 
            Mandatory = $False)] 
        [switch] $Wait
    )

    process {

        $paths = @()
        # check and expand wildcard paths
        if ($psCmdlet.ParameterSetName -eq 'Path') {
           $paths = ProcessPath $Path
        }
        # check and expand literal paths
        else {
            $paths = ProcessLiteralPath $LiteralPath
        }

        foreach ($aPath in $paths) {      
            # if the -Wait switch is set, keep waiting to display additional lines added to end of file.
            if ($Wait) {
                Get-Content -LiteralPath $aPath -Tail $Count -Wait
            }
            # don't wait, just display the current tail of the file and exit.
            else {
                Get-Content -LiteralPath $aPath -Tail $Count
            }
        }
    }
}

