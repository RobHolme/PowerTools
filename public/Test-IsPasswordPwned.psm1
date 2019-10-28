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
                if ($PSVersionTable.PSVersion -lt 6.1) {
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
