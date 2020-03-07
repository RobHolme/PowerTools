Function Rename-Filename { 
    <#
.NOTES
Function Name   : Update-Filename
Author          : Rob Holme (rob@holme.com.au)
Requires        : PowerShell V2  

.SYNOPSIS 
Renames/removes part of a filename based on a search string. Only renames the base filename, not the path or extension. Can use regular expressions for the search string. 
.DESCRIPTION 
Renames/removes part of a filename based on a search string. Only renames the base filename, not the path or extension. Can use regular expressions for the search string. 
.EXAMPLE 
Give an example of how to use it 
.PARAMETER  Path
The path and of the file(s) to rename
.PARAMETER  SearchString
The string in the filename to change
.PARAMETER  ReplacementString
The string to replace the value of the -SearchString parameter with. Leave blank ot omit this parameter to delete -SearchString from the file name.
#> 

    [CmdletBinding(SupportsShouldProcess = $True, DefaultParameterSetName = 'Path')]
    Param(
        [Parameter(
            Position = 0, 
            Mandatory = $True, 
            ParameterSetName = "Path",
            ValueFromPipeline = $True, 
            ValueFromPipelineByPropertyName = $true
        )] 
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')] [string[]] $Path,

        [Parameter(
            Position = 0,
            Mandatory = $True, 
            ParameterSetName = "LiteralPath",
            ValueFromPipeline = $False,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Literal path to one or more locations."
        )]
        [ValidateNotNullOrEmpty()]
        [string[]] $LiteralPath,
        

        [Parameter(
            Position = 1,
			Mandatory = $True
		)]
        [ValidateNotNullOrEmpty()]
        [string] $SearchString,
		
        [Parameter(
            Position = 2,
			Mandatory = $True
		)]
        [string] $ReplacementString
    )
	
    begin {
        if (!$ReplacementString) {
            $ReplacementString = ""
        }
    }

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
            $file = Get-Item -LiteralPath $aPath
            $newFilename = $file.BaseName -replace $SearchString, $ReplacementString

            $Result = @{
                OldFilename = $file.Name 
                NewFilename = "$newFilename$($file.Extension)"
            }
            if ($PSCmdlet.ShouldProcess($aPath, "Set-Content")) {
                Rename-Item -LiteralPath $aPath -NewName "$newFilename$($file.Extension)"
            }
            $outputObject = New-Object -Property $Result -TypeName psobject
            $outputObject.PSObject.TypeNames.Insert(0, "Powertools.RenameExtension.Result")
            write-output $outputObject 
        }
    }
}


