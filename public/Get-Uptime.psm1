#--------------------------------------------------
# report the uptime and last boot time for the local host
function Get-Uptime {
    if ($IsMacOS -or $IsLinux) {
        write-warning "This function is supported on Windows only"
    }
    else {
        Get-CimInstance -ClassName win32_operatingsystem | select-object @{Name = "Hostname"; Expression = { $_.csname } }, @{Name = "Uptime (days)"; Expression = { [convert]::ToInt32(((((Get-DAte) - $_.LastBootUpTime).TotalHours) / 24), 1) } }, LastBootUpTime
    }
}

