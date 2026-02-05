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
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
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

#--------------------------------------------------
# Determine the public key size of a certificate. Workarounds to support ECC certs and powershell on Linux.
# Copied from Richard M Hicks -  https://www.powershellgallery.com/packages/AOVPNTools/1.9.9/Content/Functions%5CGet-TlsCertificate.ps1
function GetPublicKeySize ($Certificate){
    # Determine key size based on algorithm type
    [System.Int32] $KeySize = $null

    # Try to get key size directly (works for RSA under windows, but not RSA under Linux for ECC (all platforms).
    try {
        if ($Certificate.PublicKey.Key -and $Certificate.PublicKey.Key.KeySize) {
            return $Certificate.PublicKey.Key.KeySize
        }
    }
    catch {
        # Ignore and try alternative methods for determining key size
    }

    # TO DO: support for RSA-PSS, and other algorithms. For now, only RSA and ECC are supported.

    if ($Certificate.PublicKey.Oid.FriendlyName -eq 'RSA' -or $Certificate.PublicKey.Oid.Value -eq '1.2.840.113549.1.1.1') {
        return $certificate.PublicKey.GetRSAPublicKey().KeySize
        # RSA key size can be determined from the modulus length
 #       if ($Certificate.PublicKey.EncodedKeyValue) {
 #           $modulusLength = $Certificate.PublicKey.EncodedKeyValue.RawData.Length
 #           # For RSA, the modulus is typically the key size in bytes, but may include leading zeros
 #           $KeySize = ($modulusLength * 8) - ($Certificate.PublicKey.EncodedKeyValue.RawData | Where-Object { $_ -eq 0 } | Measure-Object).Count * 8
 #       }
    }
    # For EC certificates, need alternative approach
    elseif ($Certificate.PublicKey.Oid.FriendlyName -eq 'ECC' -or $Certificate.PublicKey.Oid.Value -eq '1.2.840.10045.2.1') {
        # Try to get from encoded parameters OID
        if ($Certificate.PublicKey.EncodedParameters -and $Certificate.PublicKey.EncodedParameters.Oid) {
            $Oid = $Certificate.PublicKey.EncodedParameters.Oid
            switch ($Oid.Value) {
                '1.2.840.10045.3.1.7' { $KeySize = 256 }  # secp256r1 (P-256)
                '1.3.132.0.34' { $KeySize = 384 }         # secp384r1 (P-384)
                '1.3.132.0.35' { $KeySize = 521 }         # secp521r1 (P-521)
                Default {
                    # Try to infer from friendly name
                    if ($Oid.FriendlyName -match '256') { $KeySize = 256 }
                    elseif ($Oid.FriendlyName -match '384') { $KeySize = 384 }
                    elseif ($Oid.FriendlyName -match '521') { $KeySize = 521 }
                }
            }
        }
        # if still null, try to determine from the public key data length
        if (-not $KeySize -and $Certificate.PublicKey.EncodedKeyValue) {
            $KeyLength = $Certificate.PublicKey.EncodedKeyValue.RawData.Length
            # EC public keys in uncompressed format: 0x04 + X + Y coordinates
            switch ($KeyLength) {
                65 { $KeySize = 256 }   # P-256: 1 + 32 + 32
                97 { $KeySize = 384 }   # P-384: 1 + 48 + 48
                133 { $KeySize = 521 }  # P-521: 1 + 66 + 66
                # ASN.1 encoded versions (with header bytes)
                { $_ -in 67, 68, 69 } { $KeySize = 256 }
                { $_ -in 99, 100, 101 } { $KeySize = 384 }
                { $_ -in 135, 136, 137 } { $KeySize = 521 }
            }
        }
        return $KeySize
    }
 #   if (-not $KeySize) {
 #       throw "Unable to determine public key size for certificate with algorithm: $($Certificate.PublicKey.Oid.FriendlyName)"
#    }
    # if key size is still null, return 0 to indicate unknown
    return 0
}