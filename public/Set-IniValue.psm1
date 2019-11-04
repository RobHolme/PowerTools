# dot source private functions
$privateFunctions = Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) '..\private\PrivateFunctions.ps1'
. $privateFunctions

Function Set-IniValue { 
    <#
.NOTES
Function Name   : Set-IniValue
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (14/09/2016) - initial version
                  1.1 (20/09/2016) - Updated regex match to handle whitespace after the section name and property name
                  1.2 (21/09/2016) - fixed issue where a property wasn't added if it was to be added to the last section of the ini file
Requires        : PowerShell V2  

.SYNOPSIS 
Sets the value of an item in a INI file
.DESCRIPTION 
Sets the value of an item in a INI file
.EXAMPLE 
Give an example of how to use it 
.PARAMETER  Path
The literal path and filename of the INI file to edit
.PARAMETER  Section
The name of the section that contains the property to edit. If the property is not found a new property will be created
.PARAMETER  Property
The name of the property to change
.PARAMETER  Value
The new value of the property to set
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
            HelpMessage = 'Which ini file property would you like to update?'
        )] 
        [string]$Property,

        # -Value parameter
        [Parameter(
            Mandatory = $True, 
            HelpMessage = 'The value of the property to set'
        )] 
        [string]$Value
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
                    if (($sectionMatch -eq $True) -and ($propertyFound -eq $false)) {
                        $newContent += "$Property=$Value"
                        $newContent += $line 
                        # create an object for the result to the pipeline
                        $Result = @{
                            Filename = $iniFile
                            Section  = $Section
                            Property = $Property
                            OldValue = ""
                            NewValue = $Value
                        }
                    }
                    else {
                        $newContent += $line 
                    }
                    $sectionMatch = $false
                    continue
                }
            
                # check each line only if within the Section specified by the users
                if ($sectionMatch) {
                    # If a matching property is found update the value
                    if ($line -match "$Property(\s+)?=(\s+)?\w?") {
                        $newContent += "$Property=$Value"
                        $propertyFound = $True
                        # create an object for the result to the pipeline
                        $Result = @{
                            Filename = $iniFile
                            Section  = $Section
                            Property = $Property
                            OldValue = $line.Split("=")[1]
                            NewValue = $Value
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
            
            # if the section was found, and it was the last section, and the property wasn't found
            if (($sectionMatch -eq $True) -and ($propertyFound -eq $false)) {
                $newContent += "$Property=$Value"
                # create an object for the result to the pipeline
                $Result = @{
                    Filename = $iniFile
                    Section  = $Section
                    Property = $Property
                    OldValue = ""
                    NewValue = $Value
                }
            }

            # if the section was not found, create a new section
            if (!$sectionExists) {
                $newContent += "[$Section]`r`n$Property=$Value"
                # create an object for the result to the pipeline
                $Result = @{
                    Filename = $iniFile
                    Section  = $Section
                    Property = $Property
                    OldValue = ""
                    NewValue = $Value
                }
            }

            # write changes to the ini file
            if ($PSCmdlet.ShouldProcess($iniFile, "Set-Content")) {
                Set-Content -LiteralPath $iniFile -Value $newContent -Confirm:$false
            }
            # return the results as an object
            $outputObject = New-Object -Property $Result -TypeName psobject
            $outputObject.PSObject.TypeNames.Insert(0, "Powertools.SetIniValue.Result")
            write-output $outputObject 
        }
    }    
}
