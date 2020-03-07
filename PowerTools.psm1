# Dot source public/private functions
$publicFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath 'public/*.ps1' 
$privateFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath 'private/*.ps1'
$public = @(Get-ChildItem -Path $publicFunctionPath -Recurse -ErrorAction Stop) 
$private = @(Get-ChildItem -Path $privateFunctionPath -Recurse -ErrorAction Stop) 
foreach ($file in @($public + $private)) {
	try { 
		. $file.FullName 
	}
	catch {
		throw "Unable to dot source [$($file.FullName)]" 
	}
}