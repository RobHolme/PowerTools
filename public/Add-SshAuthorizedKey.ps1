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
The file containing the public key
.PARAMETER User
The SSH user
.PARAMETER Server
The SSH server(s)

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
			HelpMessage="SSH user"
		)]
		[string[]] $Server
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
					Write-Verbose "Adding $aPath to $User@$sshServer"
					$publicKey | ssh $User@$sshServer 'mkdir ~/.ssh; cat >> ~/.ssh/authorized_keys' | out-null
				}
			}
		}
	}
}


