function Clear-Clipboard() {
	<#
.SYNOPSIS 
Clear the contents of the clipboard.
.DESCRIPTION 
Clear the contents of the clipboard. Supports Windows only.
.EXAMPLE 
Clear-Clipboard
#>

	if ($IsLinux -or $IsMacOS) {
		write-warning "This function is supported on Windows only."
	}
	else {
		Add-Type -AssemblyName System.Windows.Forms
		[System.Windows.Forms.Clipboard]::Clear()
	}

}