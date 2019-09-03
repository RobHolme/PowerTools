<#
Copyright (c) 2016 Robert Holme (rob@holme.com.au)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation 
files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
is furnished to do so, subject to the following conditions:

1) The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

2) THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#>

#----------------------------------------------------
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
            foreach ($aPath in $Path) {
                if (!(Test-Path -Path $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
            
                # Resolve any wildcards that might be in the path
                $provider = $null
                $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
            }
        }
        # check and expand literal paths
        else {
            foreach ($aPath in $LiteralPath) {
                if (!(Test-Path -LiteralPath $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
            
                # Resolve any relative paths
                $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
            }
        }

        foreach ($aPath in $paths) {      
            Get-Content -LiteralPath $aPath -TotalCount $Count
        }
    }
}

#----------------------------------------------------
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
            foreach ($aPath in $Path) {
                if (!(Test-Path -Path $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
            
                # Resolve any wildcards that might be in the path
                $provider = $null
                $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
            }
        }
        # check and expand literal paths
        else {
            foreach ($aPath in $LiteralPath) {
                if (!(Test-Path -LiteralPath $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
            
                # Resolve any relative paths
                $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
            }
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


#----------------------------------------------------
# Set the value of a INI file property (or create it if it doesn't exist)
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
            foreach ($aPath in $Path) {
                if (!(Test-Path -Path $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
	
                # Resolve any wildcards that might be in the path
                $provider = $null
                $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
            }
        }
        # check and expand literal paths
        else {
            foreach ($aPath in $LiteralPath) {
                if (!(Test-Path -LiteralPath $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
	
                # Resolve any relative paths
                $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
            }
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


#----------------------------------------------------
# Gets the value of a INI file property
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
            foreach ($aPath in $Path) {
                if (!(Test-Path -Path $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
	
                # Resolve any wildcards that might be in the path
                $provider = $null
                $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
            }
        }
        # check and expand literal paths
        else {
            foreach ($aPath in $LiteralPath) {
                if (!(Test-Path -LiteralPath $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
	
                # Resolve any relative paths
                $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
            }
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

#----------------------------------------------------
# Removes a property from a INI file
Function Remove-IniValue { 
    <#
.NOTES
Function Name   : Remove-IniValue
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
            foreach ($aPath in $Path) {
                if (!(Test-Path -Path $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
	
                # Resolve any wildcards that might be in the path
                $provider = $null
                $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
            }
        }
        # check and expand literal paths
        else {
            foreach ($aPath in $LiteralPath) {
                if (!(Test-Path -LiteralPath $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
	
                # Resolve any relative paths
                $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
            }
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
            foreach ($aPath in $Path) {
                if (!(Test-Path -Path $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
	
                # Resolve any wildcards that might be in the path
                $provider = $null
                $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
            }
        }
        # check and expand literal paths
        else {
            foreach ($aPath in $LiteralPath) {
                if (!(Test-Path -LiteralPath $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
	
                # Resolve any relative paths
                $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
            }
        }
        foreach ($aPath in $paths) {
            $file = Get-Item -LiteralPath $aPath
            $Result = @{
                OldFilename = $file.Name 
                NewFilename = $file.BaseName + ".$NewExtension"
            }
            if ($PSCmdlet.ShouldProcess($aPath, "Set-Content")) {
                Rename-Item -LiteralPath $aPath -NewName "$($file.BaseName).$NewExtension"
            }
            $outputObject = New-Object -Property $Result -TypeName psobject
            $outputObject.PSObject.TypeNames.Insert(0, "Powertools.RenameExtension.Result")
            write-output $outputObject 
        }
    }
}


#----------------------------------------------------
# Renames part of a filename, based on search string to match and replace.
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

#        [Parameter(
#            Position = 1, 
#           Mandatory = $false,
#           ParameterSetName = "RandomPrefix"
#        )] 
#        [switch] $RandomPrefix
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
            foreach ($aPath in $Path) {
                if (!(Test-Path -Path $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
            
                # Resolve any wildcards that might be in the path
                $provider = $null
                $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
            }
        }
        # check and expand literal paths
        else {
            foreach ($aPath in $LiteralPath) {
                if (!(Test-Path -LiteralPath $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
            
                # Resolve any relative paths
                $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
            }
        }

        foreach ($aPath in $paths) {      
            $file = Get-Item -LiteralPath $aPath
#            If ($RandomPrefix) {
#                $Prefix = ((Get-Random).ToString().Substring(0, 6))
#                $newFilename = "$($Prefix)_$($file.BaseName)"
#            }
#            else {
                $newFilename = $file.BaseName -replace $SearchString, $ReplacementString
 #           }

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


# SIG # Begin signature block
# MIIFrAYJKoZIhvcNAQcCoIIFnTCCBZkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5LTwBvtAP9d/SGnFnwfMW3V1
# PvegggMyMIIDLjCCAhagAwIBAgIQcD9rYqFCcq1F0DEOCWoyGTANBgkqhkiG9w0B
# AQUFADAvMS0wKwYDVQQDDCRTZWxmIFNpZ25lZCBDb2RlIFNpZ25pbmcgKFJvYiBI
# b2xtZSkwHhcNMTgwOTE2MDI0MDIwWhcNMTkwOTE2MDMwMDIwWjAvMS0wKwYDVQQD
# DCRTZWxmIFNpZ25lZCBDb2RlIFNpZ25pbmcgKFJvYiBIb2xtZSkwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCiacpv6833R8nJVUj7yvOFzKGicu7dpLEz
# orI+/1iKeMDFewd/vGzovfeD5nSNjykD5ytrY1JjRbErvKomWEsaVli/0bUn+tH9
# 3zm9gCAp/tz9TsWFFDUbSbxa6jkFd/NwaRl8ALtN1KBm2U/u2hZhpC/7osWZneuz
# KENivdlgn1JNJZY5d1BeMNExt692Ed5yhovtEUB8e4V5I/egRQPvQ++NpIby03K4
# 4yy3Be2E3mcmg8n+usJW1Jio/fQ2mFKu3jcjON3JjUrjQWqq2VyrFIPzBOjqGO6U
# 4jKcE5JZbv2yM+v1X2AkZppK3ETjfRVKWbHZKb5gZUi7hrUcgjupAgMBAAGjRjBE
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU
# 9iGsMPlntS9c8aeHPnNxcdgzumUwDQYJKoZIhvcNAQEFBQADggEBAKHStb/AHUJ1
# uEgO2vlyDDngbcN8Q1rGnLVITfugEP7lAAj/TcXyUsVuCOPb7uXt2NaY30IXJvFQ
# O3DoevkYbQereHtqSKgicqlGDP8fF2gbj5VC/URR4oc7XmfuW2MAWXc7ot3kulZs
# oBvwoN8rL268AXmKrRnn2Zw+NHWCKCDDaKU2RnH0LIDOMvbKpzx+hl3zrUfqCR1J
# /71+1khn7d+iS4Kf7E+MrXPcZ6I+QFuWf9BzamhEKiG3oLTPnBIZXyN8HXTBNWXc
# 0qLDGYRXPMM3nlW6P259OHgqGPnaTO/tOHP3hfNi+5lgaG1m3ot8qmKsgSzF6EjK
# qfYJ6VPdGSYxggHkMIIB4AIBATBDMC8xLTArBgNVBAMMJFNlbGYgU2lnbmVkIENv
# ZGUgU2lnbmluZyAoUm9iIEhvbG1lKQIQcD9rYqFCcq1F0DEOCWoyGTAJBgUrDgMC
# GgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG
# 9w0BCQQxFgQUWdi9GxrLqcQ5fOtmhKQKPq4g5yAwDQYJKoZIhvcNAQEBBQAEggEA
# nwdtcSjLPL6UGuF3z2ssHVdVL4GdVskaBiDLTnZc8pJvbiu9Yo6ovro5e+deSqn2
# M19E932ljoDiT0EZFVY2BvHDBFgUWQ4nBGTJx+azn1TO5aJCWPmiNH91QLsD4T6p
# NZ3L+eEgOoj5cuBl3nFS55DIu27sgA1WjJ+nHmByVEdTPivpBbSQpHLCYEA7lPI4
# 8aWCOMWU7rUjBj6PopuPVhiDE97CfJ9S2StbSe4bGkgeqQ4RqgRIntdNchKCIYyA
# 4flz1YChvHRamwDBB2/L0d6Y/TQFlQxs/6ydyylL5eCepvKgVfg2Du4hZKpgagEn
# L4/ElZMCXPSVJb6GzT101w==
# SIG # End signature block
