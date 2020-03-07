# Dot source public/private functions

$publicFunctionsPath = Join-Path -Path (Split-Path $script:MyInvocation.MyCommand.Path) -ChildPath '\public\*.ps1' 
$privateFunctionsPath = Join-Path -Path (Split-Path $script:MyInvocation.MyCommand.Path) -ChildPath '\private\*.ps1'

Write-Verbose $publicFunctionsPath
$public = @(Get-ChildItem -Path $publicFunctionsPath -Recurse -ErrorAction Stop) 
$private = @(Get-ChildItem -Path $privateFunctionsPath -Recurse -ErrorAction Stop) 
foreach ($file in @($public + $private)) {
	try { 
		. $file.FullName 
	}
	catch {
		throw "Unable to dot source [$($file.FullName)]" 
	}
}