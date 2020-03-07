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

