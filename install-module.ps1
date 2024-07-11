[CmdletBinding()]
param (
    [Parameter(
        Position = 0,
        Mandatory = $True,
        ValueFromPipeline = $false,
        ValueFromPipelineByPropertyName = $True
    )]
    [ValidateSet("CurrentUser", "AllUsers")]
    [string] $Scope = "CurrentUser",

    [Parameter(
        Position = 1,
        Mandatory = $false,
        ValueFromPipeline = $false,
        ValueFromPipelineByPropertyName = $false
    )]
    [switch] $NoClobber
)

begin {  
    function Get-ModuleVersion() {
        try {
            $moduleFile = Get-ChildItem *.psd1
        }
        catch {
            Write-Error "Exception raised while detecting module file, exiting. Use -Debug switch to view exception" 
            Write-Debug $_.Exception
            return $null
        }
        
        # Make sure only one module file is found, otherwise exit.
        if ($moduleFile.Count -eq 1) {
            $versionElement = Get-Content $moduleFile | Select-String "ModuleVersion(\s){0,}=(\s){0,}('|"")\d{1,}(\.{1}\d{1,}){0,}"
            if ($versionElement.Matches.Count -ne 1) {
                Write-Error "ModuleVersion element not detected in manifest"
                return $null
            }
            else {
                # match version number string
                $moduleVersionMatch = ([regex]::Match($versionElement,"\d{1,}(\.{1}\d{1,}){0,}"))
                if (moduleVersionMatch.Success) {
                    return $moduleVersionMatch[0].Value
                }
                else {
                    return $null
                }
            }
        } 
        elseif ($moduleFile.Count -eq 0) {
            Write-Error "Module .psd file not found, exiting."
            return $null
        } 
        elseif ($moduleFile.Count -gt 1) {
            Write-Error "More than 1 .psd file found, exiting."
            return $null
        }
        else {
            Write-Error "Unknown issue detecting module file, exiting." 
            return $null
        }
    }

    # Get the module path based on scope and platform
function Get-PSModulePath {
    param (
        [ValidateSet("CurrentUser", "AllUsers")]
        [string] $Scope = "CurrentUser"
    )

    $psCmdlet = $MyInvocation.MyCommand
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
        $powerShellType = if ($psCmdlet.Host.Version -ge 6) { 
            "PowerShell" 
        } 
        else { 
            "WindowsPowerShell" 
        }
            $localUserDir = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)) $powerShellType
            $allUsersDir = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)) $powerShellType
        
    }
    else {
        # Paths are the same for both Linux and macOS
        $localUserDir = Join-Path (Get-HomeOrCreateTempHome) ".local/share/powershell"
        # Create the default data directory if it doesn't exist.
        if (-not (Test-Path -PathType Container $localUserDir.Value)) {
            New-Item -ItemType Directory -Path $localUserDir.Value | Out-Null
        }
        $allUsersDir = "/usr/local/share/powershell"
    }
    if ($Scope -eq "AllUsers") {
        return $allUsersDir
    }
    else {
        return $localUserDir
    }
    
}

# Helper function to get home directory
function Get-HomeOrCreateTempHome {
    $envHome = [System.Environment]::GetEnvironmentVariable("HOME") ?? $null

    if ($null -ne $envHome) {
        return $envHome
    }
    # Return an empty string in this case so the process working directory will be used.
    else {
        return ""
    }
}


    
}

process {
    $moduleVersion = Get-ModuleVersion
    $moduleRootPath =  Get-HomeOrCreateTempHome
    if ($null -ne $moduleVersion){
        # copy all files, exclude .git folder
        # Copy-Item -Path -Destination -Recurse -Exclude '.*'
    }
    
}





# Example usage
#$localUserDir = ""
#$allUsersDir = ""
#Get-StandardPlatformPaths -psCmdlet $MyInvocation.MyCommand -localUserDir ([ref] $localUserDir) -allUsersDir ([ref] $allUsersDir)
#Write-Host "Local User Dir: $localUserDir"
#Write-Host "All Users Dir: $allUsersDir"

<#

private static void GetStandardPlatformPaths(
    PSCmdlet psCmdlet,
    out string localUserDir,
    out string allUsersDir)
{
    if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
    {
        string powerShellType = (psCmdlet.Host.Version >= PSVersion6) ? "PowerShell" : "WindowsPowerShell";
        localUserDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), powerShellType);
        allUsersDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), powerShellType);
    }
    else
    {
        // paths are the same for both Linux and macOS
        localUserDir = Path.Combine(GetHomeOrCreateTempHome(), ".local", "share", "powershell");
        // Create the default data directory if it doesn't exist.
        if (!Directory.Exists(localUserDir)) {
            Directory.CreateDirectory(localUserDir);
        }

        allUsersDir = System.IO.Path.Combine("/usr", "local", "share", "powershell");
    }
}
#>


