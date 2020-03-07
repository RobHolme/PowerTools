function Select-Top() {
    <#
.NOTES
Function Name  : Select-Top
Author     : Rob Holme (rob@holme.com.au)
Requires   : PowerShell V2  

.SYNOPSIS 
Display the top most lines of a log file
.DESCRIPTION 
Display the top most lines of a log file
.EXAMPLE 
Select-Top c:\log.txt -count 20
.PARAMETER Path 
The name of the file to display. 
.PARAMETER Count 
The number of lines to display. Default to 10. 
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
        [Alias('PSPath')] 
        [string[]] $Path,

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
        [int] $Count = 10
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
            Get-Content -LiteralPath $aPath -TotalCount $Count
        }
    }
}


