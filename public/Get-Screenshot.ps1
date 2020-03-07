function Get-Screenshot {
    <#
.NOTES
Function Name   : Get-Screenshot
Author          : Rob Holme (rob@holme.com.au)
Requires        : PowerShell V3
				: Windows Vista+

.SYNOPSIS
Captures a screen shot.
.DESCRIPTION
Captures a screen shot. The Image defaults to being saved to the desktop, or can be saved to a file via the -SaveAs parameter.
It defaults to capturing the primary monitor, but can also capture all monitors or the active application window instead.
.PARAMETER ActiveWindow
Switch to specify that only the active window is captured.
.PARAMETER AllMonitors
Switch to specify that the screen from all monitors is captured.
.PARAMETER PrimaryMonitor
Switch to specify that only the primary monitor is captured. This is the default behaviour if no switch is supplied.
.PARAMETER Delay
The time in seconds to delay before the screen shot is taken. Defaults to 5 seconds.
.PARAMETER SaveAs
A file path to save the screen shot to. The following file types are supported: .jpg, .png, .bmp and .gif. If any other (unsupported) file typse are provided in the -SaveAs parameter it will default to a .png file.
For repeated captures, the capture number will be added to the end of the file name.
.PARAMETER RepeatCount
The number of times to capture the screen area. If capturing the active window, the windows original position is used for all captures, it region will
not update if the window is moved, or another window becomes active.
.PARAMETER RepeatInterval
The interval between screen captures in seconds
.EXAMPLE
Get-Screenshot -Delay 4 -ActiveWindow -SaveAs C:\scratch\test.png
.EXAMPLE
Get-Screenshot SaveAs C:\scratch\test.png
.EXAMPLE
Get-Screenshot -AllMonitors
#>
    [CmdletBinding(DefaultParameterSetName = "PrimaryMonitor")]
    param(
        [parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            Position = 1)]
        [int]$Delay = 5,

        [Parameter(
            ParameterSetName = "ActiveWindow",
            Mandatory = $False)]
        [Switch]$ActiveWindow,

        [Parameter(
            ParameterSetName = "PrimaryMonitor",
            Mandatory = $False)]
        [Switch]$PrimaryMonitor,

        [Parameter(
            ParameterSetName = "AllMonitors",
            Mandatory = $False)]
        [Switch]$AllMonitors,

        [Parameter(
            Mandatory = $False)]
        [string] $SaveAs,

        [Parameter(
            Mandatory = $false
        )]
        [uint32] $RepeatCount,

        [Parameter(
            Mandatory = $false
        )]
        [uint32] $RepeatInterval
    )

    begin {
        $abortProcessing = $false
        # validate the RepeatCount and RepeatInterval parameters
        if ($RepeatCount -and !$RepeatInterval) {
            write-warning "The parameter -RepeatInterval must be provided if using -RepeatCount"
            $abortProcessing = $true
        }
        if (!$RepeatCount -and $RepeatInterval) {
            write-warning "The parameter -RepeatCount must be provided if using -RepeatInterval"
            $abortProcessing = $true
        }

        # if a relative path is provided construct the full path
        if ($SaveAs) {
            $SaveAs = ConstructFullPath($SaveAs)
        }
    }

    process {
        if ($abortProcessing) {
            return
        }

        # this relies on System.Windows.Forms, not available under non Windows environments (and early Powershell Core on Windows - pre v6.2?)
        if (($IsLinux) -or ($IsMacOS)) {
            write-warning "This function is only supported under Windows Powershell (not Powershell core)"
            return
        }

        Add-Type -Assembly System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        $width = 0
        $height = 0
        $topLeft = New-Object System.Drawing.Point(0, 0)
        $bottomRight = New-Object System.Drawing.Point(0, 0)

        # delay the start of the screen capture
        for ($i = 0; $i++ -lt $Delay) {
            $secondsRemaining = ($Delay - $i) + 1
            write-host "Screen capture in $secondsRemaining seconds"
            start-sleep -seconds 1
        }

        # check DPI setting, apply scaling factor if required
        $dpiScalingFactor = GetDPIScalingFactor

        # Capture the active window
        if ($ActiveWindow) {
            # Import the GetForegroundWindow() and GetWindowRect() APIs from user32.dll
            Add-Type @"
				using System;
				using System.Runtime.InteropServices;
				public class UserWindows {
					[DllImport("user32.dll")]
					public static extern IntPtr GetForegroundWindow();
					[DllImport("dwmapi.dll")]
    				public static extern int DwmGetWindowAttribute(IntPtr hwnd, int dwAttribute, out RECT pvAttribute, int cbAttribute);
				}

				public struct RECT
				{
					public int Left;        // x position of upper-left corner
					public int Top;         // y position of upper-left corner
					public int Right;       // x position of lower-right corner
					public int Bottom;      // y position of lower-right corner
				}
"@
            [int] $DWMWA_EXTENDED_FRAME_BOUNDS = 9

            $foregroundWindowHandle = [UserWindows]::GetForegroundWindow()
            $rectangle = New-Object RECT
            $return = [UserWindows]::DwmGetWindowAttribute($foregroundWindowHandle, $DWMWA_EXTENDED_FRAME_BOUNDS, [ref]$rectangle, [Runtime.InteropServices.Marshal]::SizeOf($rectangle))
            If ($return -eq 0) {
                Write-Verbose "Window rectangle dimensions - Left:$($rectangle.Left) Top:$($rectangle.Top) Right:$($rectangle.Right) Bottom:$($rectangle.Bottom)"
                # no DPI scaling needed for result from DwmGetWindowAttribute
                $height = ($rectangle.Bottom - $rectangle.Top)
                $width = ($rectangle.Right - $rectangle.Left)
                $topLeft.X = $rectangle.Left
                $topLeft.Y = $rectangle.Top
                $bottomRight.X = $rectangle.Right
                $bottomRight.Y = $rectangle.Bottom
            }
            else {
                Write-Error "Unable to get the active window position"
            }
        }
        # capture all monitors
        elseif ($AllMonitors) {
            # TO DO: DPI scaling can very between monitors - apply per monitor DPI scaling. This will not work correctly if each monitor is scaled differently.
            $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
            $width = [convert]::ToInt32($screen.Width * $dpiScalingFactor)
            $height = [convert]::ToInt32($screen.Height * $dpiScalingFactor)
            $topLeft.X = [convert]::ToInt32($screen.Left * $dpiScalingFactor)
            $topLeft.Y = [convert]::ToInt32($screen.Top * $dpiScalingFactor)
            $bottomRight.X = 0
            $bottomRight.Y = 0
        }
        # default to capture the primary monitor
        else {
            $width = [convert]::ToInt32([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width * $dpiScalingFactor)
            $height = [convert]::ToInt32([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height * $dpiScalingFactor)
            $topLeft.X = 0
            $topLeft.Y = 0
            $bottomRight.X = $width
            $bottomRight.Y = $height
        }

        Write-Verbose "Canvas size ($width,$height)"
        $bitmap = New-Object System.Drawing.Bitmap $width, $height
        $RepeatCount = If ($RepeatCount) { $RepeatCount } Else { 1 }
        Write-Verbose "Repeating $repeat captures"
        for ($repeatIndex = 1; $repeatIndex -le $RepeatCount; $repeatIndex++) {
            $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphic.CopyFromScreen($topLeft.X, $topLeft.Y, 0, 0, $bitmap.Size)

            # Resolve any relative paths
            # Save the screenshot from the clipboard to file.
            if ($SaveAs) {
                if ($RepeatCount -gt 1) {
                    $SaveAsPath = AddRepeatSuffixToFilename $SaveAs $repeatIndex
                }
                else {
                    $SaveAsPath = $SaveAs
                }
                $extension = GetFileExtension $SaveAs
                switch -exact ($extension) {
                    "png" {
                        $bitmap.Save($SaveAsPath, [System.Drawing.Imaging.ImageFormat]::Png)
                        Write-Output "Image saved to $SaveAsPath"
                        break
                    }
                    "jpg" {
                        $bitmap.Save($SaveAsPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                        Write-Output "Image saved to $SaveAsPath"
                        break
                    }
                    "jpeg" {
                        $bitmap.Save($SaveAsPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
                        Write-Output "Image saved to $SaveAsPath"
                        break
                    }
                    "bmp" {
                        $bitmap.Save($SaveAsPath, [System.Drawing.Imaging.ImageFormat]::Bmp)
                        Write-Output "Image saved to $SaveAsPath"
                        break
                    }
                    "gif" {
                        $bitmap.Save($SaveAsPath, [System.Drawing.Imaging.ImageFormat]::Gif)
                        Write-Output "Image saved to $SaveAsPath"
                        break
                    }
                    # default to png format if file extension is missing or not recognised
                    Default {
                        $bitmap.Save($SaveAsPath, [System.Drawing.Imaging.ImageFormat]::Png)
                        Write-Output "Image saved to $SaveAsPath"
                        break
                    }
                }
            }
            # save to the clipboard if not saving to file.
            else {
                [System.Windows.Forms.Clipboard]::SetImage($bitmap)
                Write-Output "Image saved to clipboard"
            }
            # wait for $RepeatInterval seconds before capturing the next screenshot
            if (($RepeatInterval) -and ($repeatIndex -lt $RepeatCount)) {
                write-host "Next screen capture in $RepeatInterval seconds"
                start-sleep -seconds $RepeatInterval
            }
        }
        $bitmap.Dispose()
        $graphic.Dispose()
    }
}


# the following private functions are flagged as malicious if dot sourced from privatefunctions.ps1, but pass if included in the psm1 file.


#--------------------------------------------------
# Return the file extension from a path string
function GetFileExtension([string] $Path) {
    $startOfExtension = $Path.LastIndexOf('.')
    if (($startOfExtension -gt 0) -and ($startOfExtension -lt $Path.Length - 1)) {
        return $Path.Substring($startOfExtension + 1, ($Path.Length - 1) - $startOfExtension)
    }
    else {
        return $null
    }
}


#--------------------------------------------------
# queries the DPI of the primary display. Returns the scaling factor currently applied.
function GetDPIScalingFactor() {
    # check DPI setting, apply scaling factor if required
    $dpi = (Get-ItemProperty 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name AppliedDPI).AppliedDPI
    $dpiScalingFactor = $dpi / 96
    Write-Verbose "DPI Scaling detected at $($dpiScalingFactor * 100)%"
    return $dpiScalingFactor
}


#--------------------------------------------------
# Appends a number to the filename
function AddRepeatSuffixToFilename($Path, $RepeatNumber) {
    $startOfExtension = $Path.LastIndexOf('.')
    $extension = $Path.Substring($startOfExtension, $Path.Length - $startOfExtension)
    $filename = $Path.Substring(0, $startOfExtension)
    return $filename + "-" + $RepeatNumber + $extension
}


#--------------------------------------------------
function ConstructFullPath($path) {
    if ([System.IO.Path]::IsPathRooted($path)) {
        return $path
    }
    else {
        return Join-Path -Path (Get-Location) -ChildPath $path 
    }
}
