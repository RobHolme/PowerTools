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

