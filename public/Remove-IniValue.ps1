Function Remove-IniValue { 
    <#
.NOTES
Function Name   : Remove-IniValue
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (14/09/2016) - initial version
                  1.1 (20/09/2016) - Updated regex match to handle whitespace after the section name and property name
Requires        : PowerShell V2  

.SYNOPSIS 
Removes a property from a INI file
.DESCRIPTION 
Removes a property from a INI file
.EXAMPLE 
Give an example of how to use it 
.PARAMETER  Path
The literal path and filename of the INI file to edit
.PARAMETER  Section
The name of the section that contains the property to delete.
.PARAMETER  Property
The name of the property to delete
#> 

    [CmdletBinding(SupportsShouldProcess = $True, DefaultParameterSetName = 'Path')] 
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
    
        # -Section parameter
        [Parameter(
            Mandatory = $true 
        )] 
        [string]$Section,

        # -Property parameter
        [Parameter(
            Mandatory = $True, 
            HelpMessage = 'Which ini file property would you like to view?'
        )] 
        [string]$Property
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
		
        foreach ($iniFile in $paths) {
            # confirm the path exists (and is a file, not a directory)
            if (!(Test-Path -LiteralPath $iniFile -PathType Leaf)) {
                write-error "The file $iniFile does not exist"
                return
            }
            $sectionMatch = $false
            $propertyFound = $false
            $sectionExists = $false
            $content = get-content -LiteralPath $iniFile
            $newContent = New-Object System.Collections.ArrayList
            # Update values within the section specified only
            foreach ($line in $content) {
                if ($line -match "^\[$section\](\s+)?$") {
                    $sectionMatch = $true
                    $sectionExists = $true
                    $newContent += $line 
                    continue
                }
                elseif ($line -match "^\[.*\](\s+)?$") {
                    # if the end of the section was found without a match, add the property and value to the end of th section
                    $newContent += $line 
                    $sectionMatch = $false
                    continue
                }
            
                # check each line only if within the Section specified by the users
                if ($sectionMatch) {
                    # If a matching property is found discard the current line
                    if ($line -match "$Property(\s+)?=(\s+)?\w?") {
                        $propertyFound = $True
                        # create an object for the result to the pipeline
                        $Result = @{
                            Filename        = $iniFile
                            Section         = $Section
                            DeletedProperty = $line.Split("=")[0]
                            DeletedValue    = $line.Split("=")[1]
                        }
                    }
                    else {
                        $newContent += $line 
                    }
                }
                else {
                    $newContent += $line 
                }
            }

            # if the property was not found write a warning
            if (!$propertyFound) {
                Write-Warning "The property '$Property' was not found in the '$Section' section of the file $iniFile"
            }
            else {
                # write changes to the ini file
                if ($PSCmdlet.ShouldProcess($iniFile, "Set-Content")) {
                    Set-Content -LiteralPath $iniFile -Value $newContent -Confirm:$false
                }
                # return the results as an object
                $outputObject = New-Object -Property $Result -TypeName psobject
                $outputObject.PSObject.TypeNames.Insert(0, "Powertools.RemoveIniValue.Result")
                write-output $outputObject 
            }
        }
    }    
}


