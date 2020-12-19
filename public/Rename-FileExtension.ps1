function Rename-FileExtension {
	<#
.NOTES
Function Name   : Remove-IniValue
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (19/05/2017) - initial version
Requires        : PowerShell V2  

.SYNOPSIS 
Renames the extension of a filename
.DESCRIPTION 
Renames the extension of a filename
.EXAMPLE 
ls *.temp | Rename-FileExtension -NewExtension txt 
.EXAMPLE 
Rename-FileExtension -Filename .\somefile.temp -NewExtension txt 
.PARAMETER  Path
The file to rename. May include wildcards.
.PARAMETER  Path
The file to rename (literal path)
.PARAMETER  NewExtension
The new file extension
#> 

	[CmdletBinding(SupportsShouldProcess = $True, DefaultParameterSetName = 'Path')] 
	Param(
		[Parameter(
			Position = 0, 
			Mandatory = $True, 
			HelpMessage = 'Which file is to be renamed?',
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
			HelpMessage = "Literal path to the file to rename")]
		[ValidateNotNullOrEmpty()]
		[string[]] $LiteralPath,
    
		# -NewExtension parameter
		[Parameter(
			Mandatory = $true 
		)] 
		[string]$NewExtension
	) 

	# process each file from the pipeline 
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
			[PSCustomObject]@{
				PSTypeName  = "Powertools.RenameExtension.Result"
				OldFilename = $file.Name 
				NewFilename = $file.BaseName + ".$NewExtension"
			}
			if ($PSCmdlet.ShouldProcess($aPath, "Set-Content")) {
				Rename-Item -LiteralPath $aPath -NewName "$($file.BaseName).$NewExtension"
			}
		}
	}
}

