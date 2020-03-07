# dot source private functions
$privateFunctions = Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) '..\private\PrivateFunctions.ps1'
. $privateFunctions

Function Get-IniValue { 
    <#
.NOTES
Function Name   : Get-IniValue
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (14/09/2016) - initial version
                  1.1 (20/09/2016) - Updated regex match to handle whitespace after the section name and property name
Requires        : PowerShell V2  

.SYNOPSIS 
Gets the value of an item in a INI file
.DESCRIPTION 
Gets the value of an item in a INI file
.EXAMPLE 
Give an example of how to use it 
.PARAMETER  Path
The literal path and filename of the INI file to edit
.PARAMETER  Section
The name of the section that contains the property to edit. If the property is not found a new property will be created
.PARAMETER  Property
The name of the property to change
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
            $sectionMatch = $false
            $propertyFound = $false
            $content = get-content -LiteralPath $iniFile
            # Update values within the section specified only
            foreach ($line in $content) {
                if ($line -match "^\[$section\](\s+)?$") {
                    $sectionMatch = $true
                    continue
                }
                elseif ($line -match "^\[.*\](\s+)?$") {
                    # The end of the section was found without a match
                    $sectionMatch = $false
                    continue
                }
            
                # check each line only if within the Section specified by the user
                if ($sectionMatch) {
                    # If a matching property is found update the value
                    if ($line -match "$Property(\s+)?=(\s+)?\w?") {
                        $propertyFound = $True
                        # create an object for the result to the pipeline
                        $Result = @{
                            Filename = $iniFile
                            Section  = $Section
                            Property = $line.Split("=")[0]
                            Value    = $line.Split("=")[1]
                        }
                    }
                }
            }

            # if the section was not found, create a new section
            if (!$propertyFound) {
                write-warning "The property '$Property' could not be located in the '$Section' section."
            }

            # return the results as an object
            $outputObject = New-Object -Property $Result -TypeName psobject
            $outputObject.PSObject.TypeNames.Insert(0, "Powertools.GetIniValue.Result")
            write-output $outputObject 
        }
    }    
}

