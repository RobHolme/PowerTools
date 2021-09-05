function Get-FolderSize {
<#
.SYNOPSIS
Summarise the total size of folders (and files) for a path.
.DESCRIPTION
The nominated path (or current directory) will be examined, and disk utilisation of sub directories reported.
.PARAMETER Path
The path of the root folder to generate report of disk usage. 
.EXAMPLE
# get the size of 'H:\git repos\PowerTools\', sizes reported in KB
PS> Get-FolderSize 'H:\git repos\PowerTools\' -Unit KB

Path                            Files Size(KB) Graph                                          Percent
----                            ----- -------- -----                                          -------
H:\git repos\PowerTools\private     1     3.11                                                0.8%
H:\git repos\PowerTools\public     14    54.07 ■■■■■■■■                                       13.4%
H:\git repos\PowerTools\.git       90   311.02 ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 77.2%
<Total>                           111   402.97
.EXAMPLE
# get the size of the current folder, defaulting to report sizes in MB
PS> Get-FolderSize

Path                                           Files Size(MB) Graph                                         Percent
----                                           ----- -------- -----                                         -------
C:\Program Files\Common Files\Services             1        0                                               0%
C:\Program Files\Common Files\DESIGNER             1     0.02                                               0%
C:\Program Files\Common Files\System              58    10.05 ■                                             1.4%
C:\Program Files\Common Files\microsoft shared   296   157.85 ■■■■■■■■■■■■■■                                22.7%
C:\Program Files\Common Files\Adobe              172      526 ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 75.8%
<Total>                                          528   693.93
#>
	
	[CmdletBinding(SupportsShouldProcess = $true,
		PositionalBinding = $false,
		ConfirmImpact = 'Medium')]
	Param (
		# Param1 help description
		[Parameter(Mandatory = $false,
			Position = 0,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			ValueFromRemainingArguments = $false)]
		$Path,

		[Parameter(Mandatory = $false,
			Position = 1,
			ValueFromPipeline = $false)]
		[ValidateSet("KB", "MB", "GB", "TB")]
		[string] $Unit = "MB"

	)
	
	begin {
		# the max length in characters of the bar char (i.e 100%)
		$maxChartLength = 60

		$abortProcessing = $false
		# use the current path is no Path parameter supplied
		if (!$Path) {
			$Path = Get-Location
		}
		Write-Verbose "Path: $Path"
		# confirm the path can be accessed (and is a folder)
		If (!(Test-Path -Path $Path -PathType Container)) {
			Write-Warning "$Path does not exist, can not be accessed, or is not a folder."
			$abortProcessing = $true
		}
	}
	
	process {
		if ($abortProcessing) {
			return
		}

		if ($pscmdlet.ShouldProcess("$Path", "Get Folder Size")) {
			# create a 60 character horizontal bar graph line
			for ($i = 0; $i -lt $maxChartLength; $i++) {
				#$percentString += [char] 9607
				#$percentString += [char] 9608
				#$percentString += [char] 9604
				$percentString += [char] 9632
			}

			$resultList = New-Object Collections.Generic.List[PSObject]
			$sortedResultList = New-Object Collections.Generic.List[PSObject]
			$allItems = Get-ChildItem -LiteralPath $Path -Force
			foreach ($item in $allItems) {
				if (Test-Path -LiteralPath $item -PathType Container ) {
					$output = Get-ChildItem -LiteralPath $item -Recurse -Force | Measure-Object -Sum -Property Length
					$resultList.Add([PSCustomObject]@{
							Path         = $item.FullName
							Files        = $output.Count
							Size         = $output.Sum
							FormatedSize = $([Math]::Round($output.Sum / "1$Unit", 2))
							Unit         = $Unit
							Graph        = ""
							Percent      = 0
						})
					$totalBytes += $output.Sum
					$totalFiles += $output.Count
				}
				elseif (Test-Path -LiteralPath $item -PathType Leaf) {
					$totalBytes += $item.Length
					$totalFiles += 1
				}
			}
			# calculate percentage of total
			for ($i = 0; $i -lt $resultList.Count; $i++)	{
				$percent = ($resultList[$i].Size/$totalBytes)
				$resultList[$i].Percent = "$([Math]::Round(100*$percent,1))%"
				$resultList[$i].Graph = "$($percentString.Substring(0,$percent * $percentString.Length))"
			}

			$resultList.Add([PSCustomObject]@{
					Path          = "<Total>"
					Files         = $totalFiles
					Size          = $totalBytes
					FormattedSize = $([Math]::Round($totalBytes / "1$Unit", 2))
					Unit          = $Unit
					Graph         = ""
					Percent       = "" 
				})
			$size = @{label = "Size($Unit)"; expression = { $([Math]::Round($_.Size/"1$Unit", 2)) } }
			$sortedResultList = $resultList | Sort-Object -Property Size | Select-Object -Property Path, Files, $size, Graph, Percent | Format-Table -AutoSize
			$sortedResultList
		}
	}

}	
