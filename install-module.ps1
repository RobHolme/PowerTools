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
    function GetModuleVersion() {
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

    
}

process {
    $moduleVersion = GetModuleVersion
    if ($null -ne $moduleVersion){
        # copy all files, exclude .git folder
        # Copy-Item -Path -Destination -Recurse -Exclude '.git'
    }
    
}



