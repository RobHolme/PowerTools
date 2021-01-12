function Add-SshAuthorizedKey {
    <#
.NOTES
Function Name   : Add-SSHKey
Author          : Rob Holme (rob@holme.com.au)
Requires        : SSH

.SYNOPSIS
Adds a SSH public key to authorized_keys on a server.
.DESCRIPTION
Adds a SSH public key to authorized_keys on a server.
.PARAMETER Path
The full path of the public key file. Accepts wildcards to match more than one public key.
.PARAMETER LiteralPath
The full path and filename of the file to export the credentials to (Literal Path).
.PARAMETER User
The SSH username.
.PARAMETER Server
The SSH hostname(s).
.PARAMETER OverwriteExistingKeys 
Overwrite all existing keys in authorized_keys file (if this isn;t set the default is to append to this file).
.EXAMPLE
Add-SshAuthorizedKey -Path H:\Documents\.ssh\all-servers_rsa.pub -User rob -Server server1,server2,server3
#>
    [CmdletBinding(DefaultParametersetName = "Path")]
    param(
        [Parameter(
            Position = 0,
            Mandatory = $True,
            ParameterSetName = "Path",
            ValueFromPipeline = $False,
            ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[SupportsWildcards()]
        [Alias('PSPath')]
        [string[]] $Path,

        [Parameter(
            Position = 0,
            Mandatory = $True,
            ParameterSetName = "LiteralPath",
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Literal path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
		[string[]] $LiteralPath,
		
		# Parameter help description
		[Parameter(
			Position=1,
			Mandatory=$True,
			ValueFromPipeline=$False,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage="SSH user"
		)]
		[string] $User,

		# Parameter help description
		[Parameter(
			Position=2,
			Mandatory=$True,
			ValueFromPipeline=$False,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage="SSH Hostname"
		)]
		[Alias('Hostname')]
		[string[]] $Server,

		[Parameter(
			Position=3,
			ValueFromPipeline=$False,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage="Overwrite existing SSH keys for the user"
		)]
		[switch] $OverwriteExistingKeys
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
		
		foreach ($aPath in $paths) {
			foreach ($sshServer in $Server) {
				$publicKey = get-content $aPath
				if ($publicKey[0] -match "PRIVATE") {
					write-error "Private Key detected. Skipping $aPath"
				}
				else {
					# overwrite existing keys in ~\.ssh\authorised_keys with new key
					if ($OverwriteExistingKeys) {
						Write-Verbose "Adding $aPath to $User@$sshServer - Overwriting existing keys"
						$publicKey | ssh $User@$sshServer 'mkdir ~/.ssh; cat > ~/.ssh/authorized_keys' | out-null
					}
					# append new key to existing keys in ~\.ssh\authorised_keys
					else {
						Write-Verbose "Adding $aPath to $User@$sshServer"
						$publicKey | ssh $User@$sshServer 'mkdir ~/.ssh; cat >> ~/.ssh/authorized_keys' | out-null
					}
				}
			}
		}
	}
}


