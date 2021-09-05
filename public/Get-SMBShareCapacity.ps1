function Get-SMBShareCapacity {
	<#
.NOTES
	Rob Holme (rob@holme.com.au) 15/07/2021
.SYNOPSIS
	Report the total and free capacity for a SMB share.
.DESCRIPTION
	Report the free disk space, total disk spacem and percentage of free disk space for a SMB share. Format results as KB, MB, GB (Default), or TB.
.EXAMPLE
	Get-SMBFreeSpace.ps1 -UNCPath \\nas\homedrives\rob -Unit GB
.PARAMETER UNCPath
	The UNC path of the share to report on. Can include sub folders, but only the total abd free space of the parent share will be reported.
.PARAMETER Units
	Format the free space reported in KB, MB, GB, or TB
#>

	[CmdletBinding(
		SupportsShouldProcess = $true,
		PositionalBinding = $false,
		HelpUri = 'http://github.com/RobHolme/PowerTools#get-smbsharecapacity',
		ConfirmImpact = 'Medium')]

	Param (
		# Param1 help description
		[Parameter(Mandatory = $true,
			Position = 0,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			ValueFromRemainingArguments = $false)]
		[ValidateNotNullOrEmpty()]
		[String] $UNCPath,

		# Param1 help description
		[Parameter(Mandatory = $false,
			Position = 1,
			ValueFromPipeline = $false)]
		[ValidateSet("KB", "MB", "GB", "TB")]
		[String] $Unit = "GB"
		
	)

	begin {
		# Import GetDiskFreeSpaceEx() from Kernel32
		Add-Type @"
			using System;
			using System.Runtime.InteropServices;

  			public class DiskSpace {
				[DllImport("Kernel32", SetLastError=true, CharSet=CharSet.Auto)]
				[return: MarshalAs(UnmanagedType.Bool)]

				public static extern bool GetDiskFreeSpaceEx
				(
					string lpszPath,                    // Must name a folder, must end with '\'.
					ref long lpFreeBytesAvailable,
					ref long lpTotalNumberOfBytes,
					ref long lpTotalNumberOfFreeBytes
				);
			}
"@  
	}
	
	process {
		# validate the UNCPath string is in the correct format
		if ($UNCPath -cnotmatch '^\\\\(\w|\.)+(\\(\w|\$)+)+') {
			Write-Error "$UNCPath is not a valid UNC path."
			return
		}

		# test that the share exists, and is accessible to the user
		try {
			if (!(Test-Path -LiteralPath $UNCPath)) {
				Write-Error "$UNCPath does not exist."
				return
			}
		}
		catch {
			Write-Error "Unable to access $UNCPath. Use -Dubug for exception details"
			Write-Debug "Exception: $($_.Exception.Message)"
			return
		}

		if ($pscmdlet.ShouldProcess($UNCPath, "Get SMB Capacity")) {
			# path must end with a trailing '\'
			if (!$UNCPath.EndsWith("\")) {
				$UNCPath += '\'
			}

			[long] $freeBytesAdvailable = 0
			[long] $totalNumberOfBytes = 0
			[long] $totalNumberofFreeBytes = 0

			if ([DiskSpace]::GetDiskFreeSpaceEx($UNCPath, [ref] $freeBytesAdvailable, [ref] $totalNumberOfBytes, [ref] $totalNumberofFreeBytes)) {
				$formattedFreeSpace = [Math]::Round($freeBytesAdvailable / "1$Unit", 2) 
				$formattedTotalBytes = [Math]::Round($totalNumberOfBytes / "1$Unit", 2) 
				$percentFree = [Math]::Round(($freeBytesAdvailable / $totalNumberOfBytes) * 100, 2)
				[PSCustomObject]@{
					PSTypeName  = "Powertools.GetSMBShareCapacity.Result"
					Share       = $UNCPath
					FreeSpace   = "$formattedFreeSpace $Unit"
					TotalSpace  = "$formattedTotalBytes $Unit"
					PercentFree = "$percentFree%"
				}  
			}
		}
	}

}



