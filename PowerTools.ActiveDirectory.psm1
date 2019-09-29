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


#----------------------------------------------------
function Get-ADGroupMembers() {
    <#
.NOTES
Function Name  : Get-ADGroupMembership
Author     : Rob Holme (rob@holme.com.au)  

.SYNOPSIS 
Display the members of an active directory group
.DESCRIPTION 
Display the members of an active directory group
.EXAMPLE 
Get-ADGroupMembership -Name "VPN Users"
.PARAMETER Identity 
The name AD user group 
#>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position = 0, 
            Mandatory = $True, 
            ValueFromPipeline = $True, 
            ValueFromPipelineByPropertyName = $True)] 
        [ValidateNotNullOrEmpty()]
        [string] $Name

    )
    
    begin {
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

            $members = Get-GroupMembers $Name

            if ($members -eq $false) {
                Write-Warning "No group matching '$Name' found"
            }
            elseif ($members.Count -eq 0) {
                Write-Warning "The group '$Name' does not contain any members"
            }
            else {
                foreach ($member in $members) {
                    $memberDetails = [ADSI] "LDAP://$member" 
                  
                    # display the properties or each group member                 
                    $Result = [ORDERED]@{
                        DisplayName    = $memberDetails.displayName.ToString()
                        SamAccountName = $memberDetails.samAccountName.ToString()
                        ObjectClass    = $memberDetails.objectClass[-1]
                        DN             = $member
                    }
                    $outputObject = New-Object -Property $Result -TypeName psobject
                    $outputObject.PSObject.TypeNames.Insert(0, "Powertools.GetADGroupMembers.Result")
                    write-output $outputObject 
                }
            }
        }
    }
}

#----------------------------------------------------
# Return all members of a group. Works around ADSI issue of only 1500 members returned by 'members' property
# Sourced from https://www.adilhindistan.com/2013/01/getting-members-of-large-groups-via.html
function Get-GroupMembers {

    param (
        [string] $group
    )

    if (-not ($group)) { 
        return $false 
    }

    $searcher = new-object System.DirectoryServices.DirectorySearcher   
    $filter = "(&(objectClass=group)(cn=${group}))"
    $searcher.PageSize = 1000
    $searcher.Filter = $filter
    $result = $searcher.FindOne()

    if ($result) {
        $members = $result.properties.item("member")

        ## Either group is empty or has 1500+ members
        if ($members.count -eq 0) {                       

            $retrievedAllMembers = $false           
            $rangeBottom = 0
            $rangeTop = 0

            while (! $retrievedAllMembers) {
                $rangeTop = $rangeBottom + 1499               

                ##this is how it would show up in AD
                $memberRange = "member;range=$rangeBottom-$rangeTop"  

                $searcher.PropertiesToLoad.Clear()
                [void]$searcher.PropertiesToLoad.Add("$memberRange")
                $rangeBottom += 1500

                try {
                    ## should cause and exception if the $memberRange is not valid
                    $result = $searcher.FindOne() 
                    $rangedProperty = $result.Properties.PropertyNames -like "member;range=*"
                    $members += $result.Properties.item($rangedProperty)          
                   
                    #  check for empty group
                    if ($members.count -eq 0) { $retrievedAllMembers = $true }
                }

                catch {
                    $retrievedAllMembers = $true   ## we received all members
                }
            }
        }

        $searcher.Dispose()
        return $members
    }
    return $false   
}


#----------------------------------------------------
function Find-ADGroup() {
    <#
.NOTES
Function Name  : Find-ADGroup
Author     : Rob Holme (rob@holme.com.au)  

.SYNOPSIS 
Searches for groups matching a name
.DESCRIPTION 
Searches for groups matching a name
.EXAMPLE 
Find-ADGroup -Name VPN
.PARAMETER Identity 
The name AD user group 
#>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position = 0, 
            Mandatory = $True, 
            ValueFromPipeline = $True, 
            ValueFromPipelineByPropertyName = $True)] 
        [ValidateNotNullOrEmpty()]
        [string] $Name

    )
    
    begin {
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

            $searcher = new-object System.DirectoryServices.DirectorySearcher   
            $filter = "(&(objectClass=group)(name=*$Name*))"
            $searcher.PageSize = 1000
            $searcher.Filter = $filter
            $searchResult = $searcher.FindAll()

            if ($searchResult.Count -eq 0) {
                write-warning "No matching groups found"
            }
            else {
                foreach ($group in $searchResult) {
                    # determine the type of group
                    $groupType = GetGroupType ([convert]::ToInt32($group.Properties.grouptype, 10))

                    # display the properties of each group              
                    $Result = [ORDERED]@{
                        Name              = $($group.Properties.name).ToString()
                        GroupType         = $groupType
                        distinguishedName = $group.Path
                    }
                    $outputObject = New-Object -Property $Result -TypeName psobject
                    $outputObject.PSObject.TypeNames.Insert(0, "Powertools.FindADGroup.Result")
                    write-output $outputObject 
                }
                $searcher.Dispose()
            }
        }
    }
}


#----------------------------------------------------
function Get-ADObjectGroupMembership() {
    <#
.NOTES
Function Name  	: Get-ADObjectGroupMembership
Author     		: Rob Holme (rob@holme.com.au)  

.SYNOPSIS 
Display the group membership for an AD object.
.DESCRIPTION 
Display the group membership for an AD object. Use Get-ADPrincipalGroupMembership instead if AD powershell module is installed.
.EXAMPLE 
Get-ADObjectGroupMembership -ID Rob
.PARAMETER Identity 
The CN of the AD Object account 
#>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position = 0, 
            Mandatory = $True, 
            ValueFromPipeline = $True, 
            ValueFromPipelineByPropertyName = $True)] 
        [ValidateNotNullOrEmpty()]
        [Alias('ID')] 
		[string] $Identity,
		
		[Parameter(
            Position = 1, 
            Mandatory = $True 
		)] 
		[ValidateSet("User", "Computer", "Group", "Contact")]
        [string] $ObjectType
    )
    
    begin {
        # confirm the powershell version and platform requirements are met if using powershell core
        if ($IsCoreCLR) {
            if (($PSVersionTable.PSVersion -lt 6.1) -or ($PSVersionTable.Platform -ne "Win32NT")) {
                Write-Warning "This function requires Powershell Core 6.1 or greater on Windows."
                $abort = $true
            }
		}
		
		# set default value if ObjectType not specified
		if (!$ObjectType) {
			$ObjectType = "User"
			Write-Warning "ObjectType not set, defaulting to searching User objects"
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
			
			# construct the search filter based on object type
			if ($ObjectType -eq "Computer") {
				Write-Verbose "Searching computer objects matching '$Identity'."
				$searcher.Filter = "(&(objectCategory=computer)(name=$Identity))"
			}
			if ($ObjectType -eq "Group") {
				Write-Verbose "Searching group objects matching '$Identity'."
				$searcher.Filter = "(&(objectCategory=group)(name=$Identity))"
			}
			if ($ObjectType -eq "user") {
				Write-Verbose "Searching user objects matching '$Identity'."
				$searcher.Filter = "(&(objectCategory=person)(objectClass=user)(samAccountName=$Identity))"
			}
			if ($ObjectType -eq "Contact") {
				Write-Verbose "Searching contact objects matching '$Identity'."
				$searcher.Filter = "(&(objectClass=contact)(name=$Identity))"
			}
            $searchResult = $searcher.FindOne() 

            If ($searchResult) {
                $currentObject = $searchResult.GetDirectoryEntry()
                $groups = $currentObject.memberOf
                foreach ($group in $groups) {
                    $groupDetails = [ADSI] "LDAP://$group" 
                    $groupType = GetGroupType ([convert]::ToInt32($groupDetails.Properties.grouptype, 10))
			
                    # display the properties of each group              
                    $result = [ORDERED]@{
                        Name              = $($groupDetails.Properties.name).ToString()
                        GroupType         = $groupType
                        distinguishedName = $group
                    }
                    $outputObject = New-Object -Property $Result -TypeName psobject
                    $outputObject.PSObject.TypeNames.Insert(0, "Powertools.GetADObjectGroupMembership.Result")
                    write-output $outputObject 
                }
            }
            else {
                write-warning "No $ObjectType object matching '$Identity' found."
            }
            $searcher.Dispose()
        }
    }
}


#----------------------------------------------------
# returns a string describing the AD group type
function GetGroupType {
    param (
        [string] $groupTypeID
    )

    if (-not ($groupTypeID)) { 
        return $false 
    }

    Switch ($groupTypeID) {
        2 {
            $groupType = "Global Distribution Group"
            break
        }
        4 {
            $groupType = "Domain Local Distribution Group"
            break
        }
        8 {
            $groupType = "Universal Distribution Group"
            break
        }
        -2147483646 {
            $groupType = "Global Security Group"
            break
        }
        -2147483644 {
            $groupType = "Domain Local Security Group"
            break
        }
        -2147483640 {
            $groupType = "Universal Security Group"
            break
        }
        -2147483643 {
            $groupType = "BuiltIn Group"
            break
        }
    }
    return $groupType
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
