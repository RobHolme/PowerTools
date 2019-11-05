function Get-FirewallStatus {
    <#
.NOTES
Function Name   : Get-FirewallStatus
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (21/12/2016)
Requires        :
#>

    if ($IsLinux -or $IsMacOS) {
        write-warning "This function is supported on Windows only."
    }
    else {
        # get the list of profiles from the active store. This is the result of domain (GPO) and local policies.
        $allFirewallProfiles = Get-NetFirewallProfile -PolicyStore ActiveStore
        foreach ($firewallProfile in $allFirewallProfiles) {
            # store the results as an object
            $result = @{
                ProfileName = $firewallProfile.Name
                Enabled     = $firewallProfile.Enabled
            }
            $outputObject = New-Object -Property $result -TypeName psobject
            # write the output object to the pipeline
            write-output $outputObject
        }
    }
}


