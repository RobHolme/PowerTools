# dot source private functions
$privateFunctions = Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "..\private\PrivateFunctions.ps1"
. $privateFunctions


function Show-WordMetadata {
    <#
.NOTES
Function Name   : Show-WordMetadata
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (16/08/2016)
Requires        : Microsoft Office
				: Windows

.SYNOPSIS
Displays document properties for a MS Word Document
.DESCRIPTION
Displays document properties for a MS Word Document
.EXAMPLE
Show-WordMetadata -Path c:\test.doc
.PARAMETER Path
The name of the word document
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
        [string[]] $LiteralPath
    )

    begin {
		# confirm the powershell version and platform supports com objects
		$abortProcessing = $false
		if ($IsCoreCLR) {
			Write-Warning "This function requires Windows Powershell. Powershell Core on Windows is not supported."
			$abortProcessing = $true
		}
    }

    process {
        if (!$abortProcessing) {

            $paths = @()
            # check and expand wildcard paths
            if ($psCmdlet.ParameterSetName -eq 'Path') {
                $paths = ProcessPath $Path
            }
            # check and expand literal paths
            else {
                $paths = ProcessLiteralPath $Path
                
            }

            $application = New-Object -ComObject word.application
            $application.Visible = $false

            foreach ($aPath in $paths) {
                # open the document as read only.
                $document = $application.documents.open($aPath, $false, $true)
                $binding = "System.Reflection.BindingFlags" -as [type]
                $properties = $document.BuiltInDocumentProperties
                $customProperties = $document.CustomDocumentProperties
                # display built-in properties
                foreach ($property in $properties) {
                    $propertyName = [System.__ComObject].InvokeMember("name", $binding::GetProperty, $null, $property, $null)
                    Write-Verbose $propertyName
                    trap [system.exception] {
                        continue
                    }
                    # create a hash table to save properties for output as an object
                    $value = [System.__ComObject].InvokeMember("value", $binding::GetProperty, $null, $property, $null)
                    $properties = @{
                        PropertyName = $propertyName.ToString()
                        Value        = $value.ToString()
                        Filename     = $aPath
                    }
                    $outputObject = New-Object -TypeName PSObject -Property $properties
                    $outputObject.PSObject.TypeNames.Insert(0, "Powertools.ShowWordMetatdata.Result")
                    write-output $outputObject
                }
                # display custom properties
                foreach ($property in $customProperties) {
                    $propertyName = [System.__ComObject].InvokeMember("name", $binding::GetProperty, $null, $property, $null)
                    Write-Verbose $propertyName
                    trap [system.exception] {
                        continue
                    }
                    # create a hash table to save properties for output as an object
                    $value = [System.__ComObject].invokemember("value", $binding::GetProperty, $null, $property, $null)
                    $properties = @{
                        PropertyName = $propertyName.ToString()
                        Value        = $value.ToString()
                        Filename     = $aPath
                    }
                    $outputObject = New-Object -TypeName PSObject -Property $properties
                    $outputObject.PSObject.TypeNames.Insert(0, "Powertools.ShowWordMetatdata.Result")
                    write-output $outputObject
                }
                $application.documents.close($false)
            }
            $application.quit()
        }
    }
}
