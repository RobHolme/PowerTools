
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
