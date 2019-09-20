<#
Copyright (c) 2019 Robert Holme (rob@holme.com.au)

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



function Get-ADUserDetails() {
    <#
.NOTES
Function Name  : Get-ADUserDetails
Author     : Rob Holme (rob@holme.com.au)  

.SYNOPSIS 
Display the common properties for an AD user account. User Get-ADUser instead if RSAT tools are installed.
.DESCRIPTION 
Display the common properties for an AD user account. User Get-ADUser instead if RSAT tools are installed. 
Intended for systems were user rights do not permit install of AD RSAT tools.
.EXAMPLE 
Get-ADUserDetails -ID Rob
.PARAMETER Identity 
The logon ID (samAccountName) of the AD user account 
#>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position = 0, 
            Mandatory = $True, 
            ParameterSetName = "Identity",
            ValueFromPipeline = $True, 
            ValueFromPipelineByPropertyName = $True)] 
        [ValidateNotNullOrEmpty()]
        [Alias('ID')] 
        [string[]] $Identity

    )
    
    begin {
        # bit masks for UserAccountControl attribute (in decimal)
        [int] $ACCOUNTDISABLE = 2
        [int] $LOCKOUT = 16
        [int] $PASSWORD_EXPIRED = 8388608

        # confirm the powershell version and platform requirements are met if using powershell core
        if ($IsCoreCLR) {
            if (($PSVersionTable.PSVersion -lt 6.1) -or ($PSVersionTable.Platform -ne "Win32NT")) {
                Write-Warning "This function requires Powershell Core 6.1 or greater on Windows."
                $abort = $true
            }
        }
    }
    
    process {
        if (!$abort) {

            # search the current domain only
            $dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
            $root = $dom.GetDirectoryEntry() 
            $search = new-Object System.DirectoryServices.DirectorySearcher
            $search.SearchRoot = $root
            $search.SearchScope = "Subtree"
            write-verbose "Searching for user accounts with a samAccountName exactly matching '$Identity'"
            $search.Filter = "(&(objectCategory=person)(samAccountName=$Identity))"
        }

        $results = $search.FindAll() # return user directory object if unique, $null if not found or prompt user for selection if more than 1 match.
        If ($results -ne $null) {
            foreach ($result in $results) {
                $currentUser = $result.GetDirectoryEntry()
                    
                # get the account status from the userAccountControl bitmask 
                $userPasswordExpired = $userLockedOut = $userDisabled = $false
                $userAccountControl = $currentUser.UserAccountControl[0]
                if (($userAccountControl -band $ACCOUNTDISABLE) -eq $ACCOUNTDISABLE) {
                    $userDisabled = $true
                }
                if (($userAccountControl -band $LOCKOUT) -eq $LOCKOUT) {
                    $userLockedOut = $true
                }
                if (($userAccountControl -band $PASSWORD_EXPIRED) -eq $PASSWORD_EXPIRED) {
                    $userPasswordExpired = $true
                }

                # check to see if the user must change password on next logon
                $pwdChangeOnNextLogon = $false
                if ($currentUser.ConvertLargeIntegerToInt64($currentUser.pwdLastSet[0]) -eq 0) {
                    $pwdChangeOnNextLogon = $true
                }
                
                # display the account properties                   
                $Result = @{
                    DisplayName               = $currentUser.displayName.ToString()
                    Title                     = $currentUser.title.ToString()
                    PhoneNumber               = $currentUser.telephoneNumber.ToString()
                    Mobile                    = $currentUser.mobile.ToString()
                    OtherIpPhone              = $currentUser.otherIpPhone.ToString()
                    LastLogon                 = ConvertADDateTime $currentUser.ConvertLargeIntegerToInt64($currentUser.lastlogon[0])
                    AccountDisabled           = $userDisabled 
                    AccountLockout            = $userLockedOut
                    PasswordExpired           = $userPasswordExpired
                    AccountExpires            = ConvertADDateTime $currentUser.ConvertLargeIntegerToInt64($currentUser.accountExpires[0])
                    PasswordLastSet           = ConvertADDateTime $currentUser.ConvertLargeIntegerToInt64($currentUser.pwdLastSet[0])
                    ChangePasswordOnNextLogon = $pwdChangeOnNextLogon
                }
                $outputObject = New-Object -Property $Result -TypeName psobject
                $outputObject.PSObject.TypeNames.Insert(0, "Powertools.GetADUserDetails.Result")
                write-output $outputObject 
            }
        }
        Else {
            Write-Warning "No matching user found." 
        }
    }
}


#----------------------------------------------------
# Convert the AD Date/Time field into a Date object
function ConvertADDateTime ($dateTimeValue) {
    if (($dateTimeValue -gt [DateTime]::MaxValue.Ticks) -or ($dateTimeValue -eq 0)) {
        return "Never"
    }
    else {
        return [datetime]::FromFileTime($dateTimeValue)
    }
}




    # SIG # Begin signature block
    # MIIFrAYJKoZIhvcNAQcCoIIFnTCCBZkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
    # gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
    # AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSEK0UnRd82ovNxC9zM92gI75
    # uyWgggMyMIIDLjCCAhagAwIBAgIQcD9rYqFCcq1F0DEOCWoyGTANBgkqhkiG9w0B
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
    # 9w0BCQQxFgQU0JZGOmo0PQ6AV3+kx6GwvmLBA/EwDQYJKoZIhvcNAQEBBQAEggEA
    # I0/kdau3Y35PO3hW4e7yxuZGAEcvzZt9imcw1+GoCv6JdwhtGUfCxJY+CH5pwnpN
    # Rl6fCBtIVA32ZSiUy8UETSUN2JLCUcMjrgFicswoiaIeiIETzhNNVhWdCVi142Rq
    # rfCm0vnxS5Bk8J2au4reZEMmqaScegF4vESdadZDv4rKF7C+In6CQ8ynQSNZVXz1
    # jz3H2smV+X8oeULcmzYCC6UN1JTsXjAd9eDADSlXxkptR5FLS79J6Qlj8AGcUzMI
    # E94/SEZc9YvyccIYRSJ571zlTfWw4lkJhQ/V1d/NstKfXollOuL4ZBUxd0O54lOl
    # AxKavkQXUXmO6eggZHXFag==
    # SIG # End signature bloc
# SIG # Begin signature block
# MIIFrAYJKoZIhvcNAQcCoIIFnTCCBZkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxKp9wbAF1tl2LB8c3CJ0tIDP
# EiSgggMyMIIDLjCCAhagAwIBAgIQINA0nIX3+rpEKhtmvgiUxzANBgkqhkiG9w0B
# AQsFADAvMS0wKwYDVQQDDCRSb2IgSG9sbWUgQ29kZSBTaWduaW5nIChTZWxmIFNp
# Z25lZCkwHhcNMTkwOTE3MDAzODQ3WhcNMjkwOTE3MDA0NjM0WjAvMS0wKwYDVQQD
# DCRSb2IgSG9sbWUgQ29kZSBTaWduaW5nIChTZWxmIFNpZ25lZCkwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCufvdnhvHAAvNYc+A6bynp4ySGTt4Rv0AU
# owO25Yl0IypzvV4PW2PW/r7HDafK/DjGT84Yr5PaFEYBgZGHhqZoBFcIHgUrnbBn
# Forr5Ko2+Nckfdcw+wslXc46TJIGab3IW8HLx3NHzuYOIH9f+9InEatRcMD+FZof
# WBkC4nkQ+bP1n7yx1WSOEFA23/nfXBgFbRCWpjQ+mFCW8PEgG5U91+89TJqK3+09
# 5637JRStXTwZlNZS73eM5wiq+BG0n0DDfdXmDrAOvYZtbiYzKOR4m2OH8hFK8b22
# 02QjGDMkZgN2vK3JDEy64S1WkN6TNJV76zi7qt3EZVO9PGku0HjRAgMBAAGjRjBE
# MA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU
# ZSwaA+sUVQ872xk65xAvqtJ83kcwDQYJKoZIhvcNAQELBQADggEBAKRRSbA7xPCp
# ZuHxV/NnYG6I+GGG0LS1XdXixlL86wR5IwbbsdiPfKqx8nBB8U0D8rLXhMiaqhtE
# nUpR3xBBQO58ogENkZUBvQbvnu0Iq+VCqrJoPXZldMgLpphEdTcUgr553ekAq71t
# AJEvQtWIuuM/Wc2hWGsxbFMQ3+GFIeneyDlSu4B6IjxP1nz8LVX5oi0Vf1K9bPGp
# 1sHyv9UEpif5Pb9ws4IAVCZP6RuRe32W8pOsz6+srlOmuKHv0hZ6s9QrkaiQVjcb
# GFjCXSpVs9PNGj9eRicZJBM0+OSWYLfmHMaDO0zXhtwwLwU4xCxSRLSx2q2U4j4z
# ghSqIS4s3ukxggHkMIIB4AIBATBDMC8xLTArBgNVBAMMJFJvYiBIb2xtZSBDb2Rl
# IFNpZ25pbmcgKFNlbGYgU2lnbmVkKQIQINA0nIX3+rpEKhtmvgiUxzAJBgUrDgMC
# GgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG
# 9w0BCQQxFgQUtKFa7L0fPCs9Jv1ErYD69MfSRZwwDQYJKoZIhvcNAQEBBQAEggEA
# rZa+UwmZ2B31m1nzgMuMHFbteue+dEnjQI4geDJbiQ30yJoW4+TsOFd0o+Ob79wp
# n9bo5mVk4VelcK6bxDvxiGfQc+LEmYYqirAvmG6/2ovMrFYo44zK+5JuhZwMUAyN
# GSZNaH7QCri/d7fLJJDWisiBzHaAL4kJMOzPLaJoGNEn37a3oFjj07vgU6+MF8j/
# 9+NSeI/8WtfTeC1+HgNaX53jCitAGBlsgz7SIdvBDoIkp04YycxVu5XK2P2g78iB
# /Hk149+DHUcdve9ZZFW8N7JmhCFD4Zi7j22cZnwB4NFFUdXEUCLfAa3ZkOJ3GoeQ
# 0lyt6KPzUhaxiVBg69wNoA==
# SIG # End signature block
