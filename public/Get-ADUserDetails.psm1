# dot source private functions
$activeDirectoryPrivateFunctions = Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "..\private\ActiveDirectory.ps1"
. $activeDirectoryPrivateFunctions

#----------------------------------------------------
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
        [string] $Identity

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
            $searcher = new-Object System.DirectoryServices.DirectorySearcher
            $searcher.SearchRoot = $root
            $searcher.SearchScope = "Subtree"
            write-verbose "Searching for user accounts with a samAccountName exactly matching '$Identity'"
            $searcher.Filter = "(&(objectCategory=person)(samAccountName=$Identity))"
            $results = $searcher.FindAll() 
        
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
            $searcher.Dispose()
        }
    }
}

