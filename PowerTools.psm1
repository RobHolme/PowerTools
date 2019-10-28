<#
    File Name  : powertools.ps1m
    Author     : Rob Holme (rob@holme.com.au)

Copyright (c) 2018 Robert Holme (rob@holme.com.au)

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
function Set-ProcessorAffinity {
    <#
.NOTES
Function Name   : Set-ProcessorAffinity
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (08/07/2016)
Requires        : PowerShell V2

.SYNOPSIS
Limits the number of processor cores (incl hyper-threaded 'core') that a process can run on.
.DESCRIPTION
Limits the number of processor cores (incl hyper-threaded 'core') that a process can run on.
.EXAMPLE
Set-ProcessorAffinity -ProcessName "DCMWin" -Cores 2
.EXAMPLE
Set-ProcessorAffinity -ProcessID 6048 -Cores 4
.PARAMETER ProcessName
The name of the process to set the processor affinity for.
.PARAMETER ProcessID
The ID of the process to set the processor affinity for.
.PARAMETER Cores
The number of cpu cores to limit the process to. This includes hyper threaded cores. Set to 0 to use normal processor scheduling.
.NOTES
Works with linux, however not all processes support changing the processor affinity attribute.
#>
    [CmdletBinding(DefaultParametersetName = "ProcessName")]
    Param(
        [Parameter(
            Position = 0,
            Mandatory = $True,
            ValueFromPipeline = $True,
            ParameterSetName = "ProcessName")]
        [string] $ProcessName,

        [Parameter(
            Position = 0,
            Mandatory = $True,
            ValueFromPipeline = $True,
            ParameterSetName = "ProcessID")]
        [Alias("Id")]
        [int] $ProcessID,

        [Parameter(
            Position = 1,
            Mandatory = $False)]
        [int] $Cores
    )

    # set the affinity for each process macthing the process name
    process {
        if ($ProcessName) {
            $processes = Get-Process -Name $ProcessName
        }
        elseif ($ProcessID) {
            $processes = Get-Process -Id $ProcessID
        }
        foreach ($process in $processes) {
            try {
                # ProcessorAffinity is a bit mask. 1 core = 1, 2 cores = 3, 3 cores = 7, 4 cores = 15, 5 cores = 31, 6 cores = 63, 7 cores = 127, 8 cores = 255
                $process.ProcessorAffinity = [int][math]::pow(2, $cores) - 1
                $properties = @{
                    ProcessName = $process.ProcessName
                    ProcessID   = $process.Id
                    Cores       = $cores
                }
                $outputObject = New-Object -TypeName PSObject -Property $properties
                $outputObject.PSObject.TypeNames.Insert(0, "Powertools.SetProcessorAffinity.Result")
                write-output $outputObject
            }
            catch {
                Write-Error -Exception $_.Exception  -Message  "Failed to set the processor affinity for process $($process.Name)"
            }
        }
    }
}

#----------------------------------------------------
function Get-ProcessorAffinity {
    <#
.NOTES
Function Name   : Get-ProcessorAffinity
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (08/07/2016)
                : 1.1 (29/09/2016) - Updated parameters to accept ValueFromPipelineByPropertyName, allows get-process to be piped to the function
Requires        : PowerShell V2

.SYNOPSIS
Reports the number of processor cores (incl hyper-threaded 'core') that a process can run on.
.DESCRIPTION
Reports the number of processor cores (incl hyper-threaded 'core') that a process can run on.
.EXAMPLE
Get-ProcessorAffinity -Process "DCMWin" -Cores 2
.PARAMETER ProcessName
The name of the process to query the processor affinity for.
.PARAMETER ProcessID
The ID of the process to query the processor affinity for.
#>
    [CmdletBinding(DefaultParametersetName = "ProcessName")]
    Param(
        [Parameter(
            Position = 0,
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = "ProcessName")]
        [string] $ProcessName,

        [Parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ParameterSetName = "ProcessID")]
        [Alias("Id")]
        [int] $ProcessID
    )

    # set the affinity for each process macthing the process name
    process {
        if ($ProcessName) {
            $processes = Get-Process -Name $ProcessName
        }
        elseif ($ProcessID) {
            $processes = Get-Process -Id $ProcessID
        }
        foreach ($process in $processes) {
            # ProcessorAffinity is a bit mask. 1 core = 1, 2 cores = 3, 3 cores = 7, 4 cores = 15, 5 cores = 31, 6 cores = 63, 7 cores = 127, 8 cores = 255
            $properties = @{
                ProcessName = $process.ProcessName
                ProcessID   = $process.Id
                Cores       = [math]::Log($process.ProcessorAffinity + 1, 2)
            }
            $outputObject = New-Object -TypeName PSObject -Property $properties
            $outputObject.PSObject.TypeNames.Insert(0, "Powertools.SetProcessorAffinity.Result")
            write-output $outputObject
        }
    }
}

#----------------------------------------------------
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


#----------------------------------------------------
function Remove-WordMetadata {
    <#
.NOTES
Function Name   : Remove-WordMetadata
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (16/08/2016)
Requires        : PowerShell V2

.SYNOPSIS
Removes document properties for a MS Word Document
.DESCRIPTION
Removes all document properties for a MS Word Document, including templates, ink annotations, comments, custome properties, etc.
.EXAMPLE
Remove-WordMetadata -Path c:\test.doc
.PARAMETER Path
The name of the word document
.PARAMETER KeepTemplate
Leave the template attached to the document
.PARAMETER KeepInkAnnotations
Leave the template attached to the document
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
            Mandatory = $False)]
        [switch] $KeepTemplate,

        [Parameter(
            Mandatory = $False)]
        [switch] $KeepInkAnnotations,

        [Parameter(
            Mandatory = $False)]
        [switch] $KeepComments,

        [Parameter(
            Mandatory = $False)]
        [switch] $KeepRevisionInformation
    )

    begin {
        # warn and exit if using powershell core, only supported on Windows Powershell v2, v3, v4 and v5.x
        If ($IsCoreCLR) {
            $abortProcessing = $true
            write-warning "This function is not supported under PowerShell Core. This requires Windows PowerShell."
        }
        else {
            $abortProcessing = $false
        }
    }

    process {
        if (!$abortProcessing) {
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
            Add-Type -AssemblyName Microsoft.Office.Interop.Word
            $application = New-Object -ComObject word.application

            foreach ($aPath in $paths) {
                $document = $application.documents.open($aPath)
                $application.Visible = $false
                # suppress warnings to save when comments or ink annotations are present
                $application.Options.WarnBeforeSavingPrintingSendingMarkup = $false
                $WdRemoveDocType = "Microsoft.Office.Interop.Word.WdRemoveDocInfoType" -as [type]
                # remove individual properties from the document.
                Write-Verbose "Removing document properties from $aPath"
                #$document.RemoveDocumentInformation($WdRemoveDocType::wdRDIAll) # remove all properties - not used as I need to provide the option of retaining some properties
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIVersions)
                Write-Verbose "Version information removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIRemovePersonalInformation)
                Write-Verbose "Personal information removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIEmailHeader)
                Write-Verbose "Email header removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIRoutingSlip)
                Write-Verbose "Routing slip removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDISendForReview)
                Write-Verbose "Send for review removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIDocumentProperties)
                Write-Verbose "Document properties removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIDocumentServerProperties)
                Write-Verbose "Document Server properties removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIDocumentManagementPolicy)
                Write-Verbose "Document management policy removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIContentType)
                Write-Verbose "Content Type information removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIDocumentWorkspace)
                Write-Verbose "Document Workspace information removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDITaskpaneWebExtensions)
                Write-Verbose "Task pane web extension removed"
                # preserve the document template if the -KeepTemplate switch is set
                if (!$KeepTemplate) {
                    $document.RemoveDocumentInformation($WdRemoveDocType::wdRDITemplate)
                    Write-Verbose "Document template removed"
                }
                # preserve ink annotations if the -KeepInkAnnotations switch is set
                if (!$KeepInkAnnotations) {
                    $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIInkAnnotations)
                    Write-Verbose "Ink Annotations removed"
                }
                # preserve comments if the -KeepComments is set
                if (!$KeepComments) {
                    $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIComments)
                    Write-Verbose "Comments removed"
                }
                # preserve revision information (change tracking) if the -KeepRevisionInformation switch is set
                if (!$KeepRevisionInformation) {
                    $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIRevisions)
                    Write-Verbose "Revision information removed"
                }
                # if the document doesn't include task pan web extensions or document workspace information, an exception is thrown. Is so just continue.
                trap [system.exception] {
                    continue
                }
                # save and close the document, close down MS Word.
                $document.Save()
                $application.documents.close()
            }
            $application.quit()
        }
    }
}


#----------------------------------------------------
function Convert-ADTimestamp {
    <#
.NOTES
Function Name   : Convert-ADTimestamp
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (06/10/2016)
                : 1.1 (09/01/2019) - checked for 'never expires' timestamps
Requires        : PowerShell V2

.SYNOPSIS
Converts a integer timestamp (e.g. from LDIFDE or some AD CmdLets) to a date/time value.
.DESCRIPTION
Converts a integer timestamp (e.g. from LDIFDE or some AD CmdLets) to a date/time value.
.EXAMPLE
Convert-ADTimestamp -Value 131200456520442703
.PARAMETER Value
The timestamp to convert
#>

    Param(
        [Parameter(
            Position = 0,
            Mandatory = $True,
            ValueFromPipeline = $True
        )]
        [string] $Value)

    process {
        if ($Value -gt [DateTime]::MaxValue.Ticks) {
            write-warning "Time value exceeds max value. This is used identify a time value of never expires."
        }
        else {
            $convertedDateTime = [datetime]::FromFileTime($Value)
            write-output $convertedDateTime
        }
    }
}


#----------------------------------------------------
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
                        $sortedCounters += $counters | where-object -FilterScript {$_.InstanceName -eq $process}
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
            $processPaths = @{}
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

#----------------------------------------------------
function Export-Credential {
    <#
.NOTES
Function Name   : Export-Credential
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (24/01/2017)   - Initial version.
Requires        : PowerShell V3

.SYNOPSIS
Exports a password to a file (as a secure string)
.DESCRIPTION
Exports a password to a file (as a secure string). The file format is XML. The password is encrypted, requiring the same user and host to be able to read the password.
The exported password can not be transported between hosts or users, it will fail to import. Use Import-Password to return the PS Credential object from file.
.EXAMPLE
Export-Credential -Path c:\temp\password.xml
# user is prompted to enter password
.EXAMPLE
Export-Credential -Path c:\temp\password.xml -Password $SecurePassword -Username testdomain\testuser
# store the username associated with the password to the file
.EXAMPLE
Export-Credential -Path c:\temp\password.xml -Credential (Get-Credential)
# store the credential object
.PARAMETER Path
The Hostname or IP address of the SQL server to connect to. If connecting to a named instance, include the instance name e.g. server\instance
.PARAMETER Password
The password (as a securestring)
.PARAMETER Username
The (optional) username to store with the password
#>
    [CmdletBinding(DefaultParameterSetName = "Password")]
    param(
        [Parameter(
            Position = 0,
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullorEmpty()]
        [string] $Path,

        [Parameter(
            Position = 1,
            Mandatory = $True,
            ValueFromPipeline = $True,
            ParameterSetName = "Password")]
        [Security.SecureString] $Password,

        [Parameter(
            Position = 2,
            Mandatory = $False,
            ValueFromPipeline = $True,
            ParameterSetName = "Password")]
        [string] $Username,

        [Parameter(
            Position = 1,
            Mandatory = $False,
            ValueFromPipeline = $True,
            ParameterSetName = "Credential")]
        [PSCredential] $Credential,

        [Parameter(
            Mandatory = $False)]
        [Switch]$NoClobber
    )

    begin {
        # this function is only supported on Windows Platforms
        if ($IsLinux -or $IsMacOs) {
            write-warning "This function is only supported on the Windows platform"
            $abortProcessing = $true
        }
        else {
            $abortProcessing = $false
        }
    }
    process {
        if ($abortProcessing) {
            return
        }

        # exit if the file exists, and the -NoClobber switch was set
        if ($NoClobber -AND (Test-Path -Path $Path)) {
            Write-Warning "The file '$Path' already exists. Omit the '-NoClobber' switch to force overwrite."
            Return
        }

        # convert the secure string to text. Only the current user on the current host will be able to convert the text back to a readabsle password.
        if ($PSCmdlet.ParameterSetName -eq "Credential") {
            $Username = $Credential.UserName
            $passwordText = $Credential.Password | ConvertFrom-SecureString
        }
        else {
            $passwordText = $Password | ConvertFrom-SecureString
        }

        # save the credentials to file, along with meta data on who saved the crentails.
        $result = [ORDERED]@{
            Username   = $Username
            Password   = $passwordText
            ExportUser = "$env:USERDOMAIN\$env:USERNAME"
            ExportHost = "$env:COMPUTERNAME"
            ExportDate = Get-Date
        }
        $outputObject = New-Object -Property $Result -TypeName psobject
        $outputObject.PSObject.TypeNames.Insert(0, "Powertools.ExportedCredentials")
        $outputObject | Export-clixml -Path $Path
    }
}


#----------------------------------------------------
function Import-Credential {
    <#
.NOTES
Function Name   : Import-Credential
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (24/01/2017)   - Initial version.
Requires        : PowerShell V3

.SYNOPSIS
Imports a credential from file (exported by Export-Credential)
.DESCRIPTION
Imports a PSCredentail object from a file (previously exported by Export-Credential). The file format is XML. The password is encrypted, requiring the same user and host to be able to read the password.
The exported password can not be transported between hosts or users, it will fail to import. Use Export-Password to create a file with stored credentials.
.EXAMPLE
$Cred = Import-Credential -Path c:\temp\credential.xml
$Cred.Username  # this is the domain\username
$Cred.GetNetworkCredential().Password  # this is the plain text Password
.PARAMETER Path
This is the name of the XML file that contains cretentails previously exported by Export-Credential. Must be the same user and don the same host to import the credentals.
The XML file will contain metas data indicating the username and the host when the export was performed.
#>
    [CmdletBinding(DefaultParameterSetName = "Password")]
    param(
        [Parameter (
            Position = 0,
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullorEmpty()]
        [ValidateScript( {
                if (Test-Path $_) {
                    $True
                }
                else {
                    Throw "Path not valid: $_"
                }
            })]
        [string] $Path
    )

    process {
        # import the xml file containing the credentials
        $savedCredentials = Import-Clixml -Path $Path
        # [-Verbose] display the metat data from when the file was saved
        Write-Verbose "Credentials saved by      : $($savedCredentials.ExportUser)"
        Write-Verbose "Credentials saved on host : $($savedCredentials.ExportHost)"
        Write-Verbose "Credentials saved at      : $($savedCredentials.ExportDate)"
        # construct and return a PSCredentail object
        try {
            $securePassword = ConvertTo-SecureString $savedCredentials.Password -ErrorAction Stop
            $credentail = New-Object -typename PSCredential -ArgumentList @($savedCredentials.Username, $securePassword)
            return $credentail
        }
        catch {
            Write-Warning $_.exception.message
            return $null
        }
    }
}


# returns true if the powershell session is running under elevated permissions
function IsAdmin() {
    # confirm the powershell console is running under local admin credentials.
    If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        return $false
    }
    else {
        return $true
    }
}


function Get-Screenshot {
    <#
.NOTES
Function Name   : Get-Screenshot
Author          : Rob Holme (rob@holme.com.au)
Requires        : PowerShell V3
				: Windows Vista+

.SYNOPSIS
Captures a screen shot.
.DESCRIPTION
Captures a screen shot. The Image defaults to being saved to the desktop, or can be saved to a file via the -SaveAs parameter.
It defaults to capturing the primary monitor, but can also capture all monitors or the active application window instead.
.PARAMETER ActiveWindow
Switch to specify that only the active window is captured.
.PARAMETER AllMonitors
Switch to specify that the screen from all monitors is captured.
.PARAMETER PrimaryMonitor
Switch to specify that only the primary monitor is captured. This is the default behaviour if no switch is supplied.
.PARAMETER Delay
The time in seconds to delay before the screen shot is taken. Defaults to 5 seconds.
.PARAMETER SaveAs
A file path to save the screen shot to. The following file types are supported: .jpg, .png, .bmp and .gif. If any other (unsupported) file typse are provided in the -SaveAs parameter it will default to a .png file.
For repeated captures, the capture number will be added to the end of the file name.
.PARAMETER RepeatCount
The number of times to capture the screen area. If capturing the active window, the windows original position is used for all captures, it region will
not update if the window is moved, or another window becomes active.
.PARAMETER RepeatInterval
The interval between screen captures in seconds
.EXAMPLE
Get-Screenshot -Delay 4 -ActiveWindow -SaveAs C:\scratch\test.png
.EXAMPLE
Get-Screenshot SaveAs C:\scratch\test.png
.EXAMPLE
Get-Screenshot -AllMonitors
#>
    [CmdletBinding(DefaultParameterSetName = "PrimaryMonitor")]
    param(
        [parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            Position = 1)]
        [int]$Delay = 5,

        [Parameter(
            ParameterSetName = "ActiveWindow",
            Mandatory = $False)]
        [Switch]$ActiveWindow,

        [Parameter(
            ParameterSetName = "PrimaryMonitor",
            Mandatory = $False)]
        [Switch]$PrimaryMonitor,

        [Parameter(
            ParameterSetName = "AllMonitors",
            Mandatory = $False)]
        [Switch]$AllMonitors,

        [Parameter(
            Mandatory = $False)]
        [string] $SaveAs,

        [Parameter(
            Mandatory = $false
        )]
        [uint32] $RepeatCount,

        [Parameter(
            Mandatory = $false
        )]
        [uint32] $RepeatInterval
    )

    begin {
        $abortProcessing = $false
        # validate the RepeatCount and RepeatInterval parameters
        if ($RepeatCount -and !$RepeatInterval) {
            write-warning "The parameter -RepeatInterval must be provided if using -RepeatCount"
            $abortProcessing = $true
        }
        if (!$RepeatCount -and $RepeatInterval) {
            write-warning "The parameter -RepeatCount must be provided if using -RepeatInterval"
            $abortProcessing = $true
        }

        # if a relative path is provided construct the full path
        if ($SaveAs) {
            $SaveAs = ConstructFullPath($SaveAs)
        }
    }

    process {
        if ($abortProcessing) {
            return
        }

        # this relies on System.Windows.Forms, not available under .Net core CLR
        if ($IsCoreCLR) {
            write-warning "This function is only supported under Windows Powershell (not Powershell core)"
            return
        }

        Add-Type -Assembly System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        $width = 0
        $height = 0
        $topLeft = New-Object System.Drawing.Point(0, 0)
        $bottomRight = New-Object System.Drawing.Point(0, 0)

        # delay the start of the screen capture
        for ($i = 0; $i++ -lt $Delay) {
            $secondsRemaining = ($Delay - $i) + 1
            write-host "Screen capture in $secondsRemaining seconds"
            start-sleep -seconds 1
        }

        # check DPI setting, apply scaling factor if required
        $dpiScalingFactor = GetDPIScalingFactor

        # Capture the active window
        if ($ActiveWindow) {
            # Import the GetForegroundWindow() and GetWindowRect() APIs from user32.dll
            Add-Type @"
				using System;
				using System.Runtime.InteropServices;
				public class UserWindows {
					[DllImport("user32.dll")]
					public static extern IntPtr GetForegroundWindow();
					[DllImport("dwmapi.dll")]
    				public static extern int DwmGetWindowAttribute(IntPtr hwnd, int dwAttribute, out RECT pvAttribute, int cbAttribute);
				}

				public struct RECT
				{
					public int Left;        // x position of upper-left corner
					public int Top;         // y position of upper-left corner
					public int Right;       // x position of lower-right corner
					public int Bottom;      // y position of lower-right corner
				}
"@
            [int] $DWMWA_EXTENDED_FRAME_BOUNDS = 9

            $foregroundWindowHandle = [UserWindows]::GetForegroundWindow()
            $rectangle = New-Object RECT
            $return = [UserWindows]::DwmGetWindowAttribute($foregroundWindowHandle, $DWMWA_EXTENDED_FRAME_BOUNDS, [ref]$rectangle, [Runtime.InteropServices.Marshal]::SizeOf($rectangle))
            If ($return -eq 0) {
                Write-Verbose "Window rectangle dimensions - Left:$($rectangle.Left) Top:$($rectangle.Top) Right:$($rectangle.Right) Bottom:$($rectangle.Bottom)"
                # no DPI scaling needed for result from DwmGetWindowAttribute
                $height = ($rectangle.Bottom - $rectangle.Top)
                $width = ($rectangle.Right - $rectangle.Left)
                $topLeft.X = $rectangle.Left
                $topLeft.Y = $rectangle.Top
                $bottomRight.X = $rectangle.Right
                $bottomRight.Y = $rectangle.Bottom
            }
            else {
                Write-Error "Unable to get the active window position"
            }
        }
        # capture all monitors
        elseif ($AllMonitors) {
            # TO DO: DPI scaling can very between monitors - apply per monitor DPI scaling. This will not work correctly if each monitor is scaled differently.
            $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
            $width = [convert]::ToInt32($screen.Width * $dpiScalingFactor)
            $height = [convert]::ToInt32($screen.Height * $dpiScalingFactor)
            $topLeft.X = [convert]::ToInt32($screen.Left * $dpiScalingFactor)
            $topLeft.Y = [convert]::ToInt32($screen.Top * $dpiScalingFactor)
            $bottomRight.X = 0
            $bottomRight.Y = 0
        }
        # default to capture the primary monitor
        else {
            $width = [convert]::ToInt32([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width * $dpiScalingFactor)
            $height = [convert]::ToInt32([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height * $dpiScalingFactor)
            $topLeft.X = 0
            $topLeft.Y = 0
            $bottomRight.X = $width
            $bottomRight.Y = $height
        }

        Write-Verbose "Canvas size ($width,$height)"
        $bitmap = New-Object System.Drawing.Bitmap $width, $height
        $RepeatCount = If ($RepeatCount) {$RepeatCount} Else {1}
        Write-Verbose "Repeating $repeat captures"
        for ($repeatIndex = 1; $repeatIndex -le $RepeatCount; $repeatIndex++) {
            $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphic.CopyFromScreen($topLeft.X, $topLeft.Y, 0, 0, $bitmap.Size)

            # Resolve any relative paths
            # Save the screenshot from the clipboard to file.
            if ($SaveAs) {
                if ($RepeatCount -gt 1) {
                    $SaveAsPath = AddRepeatSuffixToFilename $SaveAs $repeatIndex
                }
                else {
                    $SaveAsPath = $SaveAs
                }
                $extension = GetFileExtension $SaveAs
                switch -exact ($extension) {
                    "png" {
                        $bitmap.Save($SaveAsPath, [System.Drawing.Imaging.ImageFormat]::Png)
                        Write-Output "Image saved to $SaveAsPath"
                        break
                    }
                    "jpg" {
                        $bitmap.Save($SaveAsPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                        Write-Output "Image saved to $SaveAsPath"
                        break
                    }
                    "jpeg" {
                        $bitmap.Save($SaveAsPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                        Write-Output "Image saved to $SaveAsPath"
                        break
                    }
                    "bmp" {
                        $bitmap.Save($SaveAsPath, [System.Drawing.Imaging.ImageFormat]::Bmp)
                        Write-Output "Image saved to $SaveAsPath"
                        break
                    }
                    "gif" {
                        $bitmap.Save($SaveAsPath, [System.Drawing.Imaging.ImageFormat]::Gif)
                        Write-Output "Image saved to $SaveAsPath"
                        break
                    }
                    # default to png format if file extension is missing or not recognised
                    Default {
                        $bitmap.Save($SaveAsPath, [System.Drawing.Imaging.ImageFormat]::Png)
                        Write-Output "Image saved to $SaveAsPath"
                        break
                    }
                }
            }
            # save to the clipboard if not saving to file.
            else {
                [System.Windows.Forms.Clipboard]::SetImage($bitmap)
                Write-Output "Image saved to clipboard"
            }
            # wait for $RepeatInterval seconds before capturing the next screenshot
            if (($RepeatInterval) -and ($repeatIndex -lt $RepeatCount)) {
                write-host "Next screen capture in $RepeatInterval seconds"
                start-sleep -seconds $RepeatInterval
            }
        }
        $bitmap.Dispose()
        $graphic.Dispose()
    }
}


#--------------------------------------------------
# report the uptime and last boot time for the local host
function Get-Uptime {
    Get-CimInstance -ClassName win32_operatingsystem | select-object @{Name = "Hostname"; Expression = {$_.csname}}, @{Name = "Uptime (days)"; Expression = {[convert]::ToInt32(((((Get-DAte) - $_.LastBootUpTime).TotalHours) / 24), 1)}}, LastBootUpTime
}


#--------------------------------------------------
function Get-Hash {
    <#
.NOTES
Function Name   : Get-Hash
Author          : Rob Holme (rob@holme.com.au)
Requires        :

.SYNOPSIS
Generate the hash of a string or file.
.DESCRIPTION
Generate the hash of a string or file. Defaults to MD5.
.PARAMETER String
The string to hash
.PARAMETER Path
The file to hash
.PARAMETER Algorithm
The type of hash to calculate. Accepted values include "SHA1","SHA","MD5","SHA256","SHA-256","SHA384","SHA-384","SHA512","SHA-512"
#>
    [CmdletBinding(DefaultParametersetName = "Path")]
    param(
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

        [parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 1, ParameterSetName = "String")]
        [Alias("PlainText")]
        [string]$String,

        [parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 2)]
        [ValidateSet("SHA1", "MD5", "SHA256", "SHA384", "SHA512")]
        [string] $Algorithm = "MD5"
    )

    process {
        $hash = New-Object System.Text.StringBuilder
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

                # Resolve any wild cards that might be in the path. Only add files, not directories.
                $provider = $null
                if (Test-Path $aPath -PathType Leaf) {
                    $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
                }
                else {
                    Write-Verbose "Ignoring folder $aPath"
                }
            }
        }
        # check and expand literal paths
        if ($psCmdlet.ParameterSetName -eq 'LiteralPath') {
            foreach ($aPath in $LiteralPath) {
                if (!(Test-Path -LiteralPath $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }
                # Resolve any relative paths, ignore directories
                if (Test-Path $aPath -PathType Leaf) {
                    $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
                }
                else {
                    Write-Verbose "Ignoring folder $aPath"
                }
            }
        }

        # calculate and display the hash of all files
        if (($PSCmdlet.ParameterSetName -eq "Path") -or ($PSCmdlet.ParameterSetName -eq "LiteralPath")) {
            foreach ($aPath in $paths) {
                $file = Get-Item -LiteralPath $aPath
                $data = [System.Text.Encoding]::UTF8.GetBytes([System.IO.File]::ReadAllBytes($file))
                $hash = CalculateHash -ByteArrayToHash $data -HashAlgorithm $Algorithm
                $properties = @{
                    Algorithm = $Algorithm
                    Hash      = $hash.ToString()
                    Filename  = $file.Name
                }
                $outputObject = New-Object -TypeName PSObject -Property $properties
                $outputObject.PSObject.TypeNames.Insert(0, "Powertools.GetHash.Result")
                write-output $outputObject
            }
        }

        # calculate and display the hash of the string
        if ($PSCmdlet.ParameterSetName -eq "String") {
            $data = [System.Text.Encoding]::UTF8.GetBytes($String)
            $hash = CalculateHash -ByteArrayToHash $data -HashAlgorithm $Algorithm
            # write the hash to the pipeline
            $properties = @{
                Algorithm = $Algorithm
                Hash      = $hash.ToString()
            }
            $outputObject = New-Object -TypeName PSObject -Property $properties
            $outputObject.PSObject.TypeNames.Insert(0, "Powertools.GetHash.Result")
            write-output $outputObject
        }
    }
}


function CalculateHash($ByteArrayToHash, $HashAlgorithm) {
    $StringBuilder = New-Object System.Text.StringBuilder
    switch ($HashAlgorithm) {
        "SHA1" {
            [System.Security.Cryptography.SHA1]::Create().ComputeHash($ByteArrayToHash) | ForEach-Object {
                [Void]$StringBuilder.Append($_.ToString("x2")) }
        }
        "SHA256" {
            [System.Security.Cryptography.SHA256]::Create().ComputeHash($ByteArrayToHash) | ForEach-Object {
                [Void]$StringBuilder.Append($_.ToString("x2")) }
        }
        "SHA344" {
            [System.Security.Cryptography.SHA384]::Create().ComputeHash($ByteArrayToHash) | ForEach-Object {
                [Void]$StringBuilder.Append($_.ToString("x2")) }
        }
        "SHA512" {
            [System.Security.Cryptography.SHA512]::Create().ComputeHash($ByteArrayToHash) | ForEach-Object {
                [Void]$StringBuilder.Append($_.ToString("x2")) }
        }
        "MD5" {
            [System.Security.Cryptography.MD5]::Create().ComputeHash($ByteArrayToHash) | ForEach-Object {
                [Void]$StringBuilder.Append($_.ToString("x2")) }
        }
    }
    return $StringBuilder
}

function Test-IsPasswordPwned {
    <#
.NOTES
Function Name   : Test-IsPasswordPwned
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (06/02/2018)   - Initial version.
Requires        : PowerShell V3

.SYNOPSIS
Returns $true if the password is included in the list of known breached passwords (via haveibeenpwned.com).
Returns $false if the password is not listed. All passwords are converted to SHA1 hash when submitted to haveibeenpwned.com
.DESCRIPTION
.PARAMETER SecureString
A copy of the password as a securestring
.PARAMETER Password
The password in plain text
.PARAMETER PasswordHash
The SHA1 hash of the password
#>
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = $True,
            ValueFromPipeline = $True,
            ParameterSetName = "SecureString")]
        [Security.SecureString] $SecureStringPassword,

        [Parameter(
            Position = 0,
            Mandatory = $True,
            ValueFromPipeline = $True,
            ParameterSetName = "Password")]
        [string] $PlainTextPassword,

        [Parameter(
            Position = 0,
            Mandatory = $True,
            ValueFromPipeline = $True,
            ParameterSetName = "PasswordHash")]
        [string] $PasswordHashSHA1
    )

    process {
        if ($IsCoreCLR) {
            if ($IsCoreCLR) {
                if ($PSVersionTable.PSVersion -lt 6.1)  {
                    Write-Warning "This function requires Powershell Core 6.1 or greater."
                 return
                }
            }
        }

        # .Net Framework doens't support TLS1.2 by default. .Net Core is OK by default, and doesn't support [System.Net.ServicePointManager]
        if (!$IsCoreCLR) {
            [System.Net.ServicePointManager]::SecurityProtocol = @("Tls12", "Tls11", "Tls", "Ssl3")
        }

        # convert secure string to plain text password
        if ($PSCmdlet.ParameterSetName -eq "SecureString") {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureStringPassword)
            $PlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        }

        # calculate the SHA1 hash of the plaintext password
        if (($PSCmdlet.ParameterSetName -eq "SecureString") -or ($PSCmdlet.ParameterSetName -eq "Password")) {
            $StringBuilder = New-Object System.Text.StringBuilder
            [System.Security.Cryptography.SHA1]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($PlainTextPassword)) | ForEach-Object {
                [Void]$StringBuilder.Append($_.ToString("x2")) }
        }
        $PasswordHash = $StringBuilder.ToString()


        try {
            [bool] $match = $false
            # get the first 5 characters of the hash and submit this to the pwnedpasswords range API. All macthing hashed will be returned (minus the 5 char prefix submitted)
            $passwordHashPrefix = $PasswordHash.Substring(0, 5)
            $response = Invoke-WebRequest -Uri https://api.pwnedpasswords.com/range/$passwordHashPrefix -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Verbose "Password hash: $PasswordHash"
                # Remove the first character (substring(1)) that is prefixed to the actual content.
                # Split each line of the content, compare the partial hashes returned against the password hash.
                foreach ($responseString in $response.Content.Substring(1) -Split "`n") {
                    # hashes are sufixed with a colon and a number indicating the number of times the password appears in breaches. The number of occurrances is discarded.
                    $hash = (($responseString -Split ":")[0])
                    Write-Verbose "hash received: $hash"
                    if ($PasswordHash -match $hash) {
                        $match = $true
                        break
                    }
                }
                Write-Output $match
            }
            # a HTTP response other than 200 indicates something unexpected has happened.
            else {
                Write-Error "Unable to query pwned passwords at this time."
                Write-Error "Status Code returned: $($response.StatusCode)"
            }
        }
        # fatal response codes will generally trigger an exception.
        catch {

            Write-Error "Unable to query pwned passwords at this time."
            Write-Error $_
        }
    }
}


#--------------------------------------------------
# Return the file extension from a path string
function GetFileExtension([string] $Path) {
    $startOfExtension = $Path.LastIndexOf('.')
    if (($startOfExtension -gt 0) -and ($startOfExtension -lt $Path.Length - 1)) {
        return $Path.Substring($startOfExtension + 1, ($Path.Length - 1) - $startOfExtension)
    }
    else {
        return $null
    }
}


#--------------------------------------------------
# queries the DPI of the primary display. Returns the scaling factor currently applied.
function GetDPIScalingFactor() {
    # check DPI setting, apply scaling factor if required
    $dpi = (Get-ItemProperty 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name AppliedDPI).AppliedDPI
    $dpiScalingFactor = $dpi / 96
    Write-Verbose "DPI Scaling detected at $($dpiScalingFactor * 100)%"
    return $dpiScalingFactor
}

#--------------------------------------------------
# Appends a number to the filename
function AddRepeatSuffixToFilename($Path, $RepeatNumber) {
    $startOfExtension = $Path.LastIndexOf('.')
    $extension = $Path.Substring($startOfExtension, $Path.Length - $startOfExtension)
    $filename = $Path.Substring(0, $startOfExtension)
    return $filename + "-" + $RepeatNumber + $extension
}


#--------------------------------------------------
function ConstructFullPath($path) {
    if ([System.IO.Path]::IsPathRooted($path)) {
        return $path
    }
    else {
        return Join-Path -Path (Get-Location) -ChildPath $path 
    }
}


#--------------------------------------------------
# Resolve wildcards, expand paths.
function ProcessPath([string[]] $Path) {
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
	return $paths
}


#--------------------------------------------------
# Resolve paths - literal paths, no wildcards.
function ProcessLiteralPath([string[]] $LiteralPath) {
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
	return $paths
}

