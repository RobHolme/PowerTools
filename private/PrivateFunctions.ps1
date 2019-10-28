#--------------------------------------------------
# Resolve wildcards, expand paths.
function ProcessPath([string[]] $Path) {
	foreach ($aPath in $Path) {
		if (!(Test-Path -Path $aPath)) {
			$ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
			$category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
			$errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
			$psCmdlet.WriteError($errRecord)
			continue
		}

		# Resolve any wildcards that might be in the path
		$provider = $null
		$paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
	}
	return $paths
}


#--------------------------------------------------
# Resolve paths - literal paths, no wildcards.
function ProcessLiteralPath([string[]] $LiteralPath) {
	foreach ($aPath in $LiteralPath) {
		if (!(Test-Path -LiteralPath $aPath)) {
			$ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
			$category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
			$errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
			$psCmdlet.WriteError($errRecord)
			continue
		}

		# Resolve any relative paths
		$paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
	}
	return $paths
}


#--------------------------------------------------
# returns true if the powershell session is running under elevated permissions
function IsAdmin() {
    # confirm the powershell console is running under local admin credentials.
    If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        return $false
    }
    else {
        return $true
    }
}

#--------------------------------------------------
function CalculateHash($ByteArrayToHash, $HashAlgorithm) {
    $StringBuilder = New-Object System.Text.StringBuilder
    switch ($HashAlgorithm) {
        "SHA1" {
            [System.Security.Cryptography.SHA1]::Create().ComputeHash($ByteArrayToHash) | ForEach-Object {
                [Void]$StringBuilder.Append($_.ToString("x2")) }
        }
        "SHA256" {
            [System.Security.Cryptography.SHA256]::Create().ComputeHash($ByteArrayToHash) | ForEach-Object {
                [Void]$StringBuilder.Append($_.ToString("x2")) }
        }
        "SHA344" {
            [System.Security.Cryptography.SHA384]::Create().ComputeHash($ByteArrayToHash) | ForEach-Object {
                [Void]$StringBuilder.Append($_.ToString("x2")) }
        }
        "SHA512" {
            [System.Security.Cryptography.SHA512]::Create().ComputeHash($ByteArrayToHash) | ForEach-Object {
                [Void]$StringBuilder.Append($_.ToString("x2")) }
        }
        "MD5" {
            [System.Security.Cryptography.MD5]::Create().ComputeHash($ByteArrayToHash) | ForEach-Object {
                [Void]$StringBuilder.Append($_.ToString("x2")) }
        }
    }
    return $StringBuilder
}

