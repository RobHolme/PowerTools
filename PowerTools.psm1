# Dot source public/private functions

$publicFunctionsPath = Join-Path -Path (Split-Path $script:MyInvocation.MyCommand.Path) -ChildPath '\public\*.ps1'
$privateFunctionsPath = Join-Path -Path (Split-Path $script:MyInvocation.MyCommand.Path) -ChildPath '\private\*.ps1'
$public = @()
$private = @()

# test that the public and private function paths exist, if so load all scripts found.
if (test-path $publicFunctionsPath) {
	$public = @(Get-ChildItem -Path $publicFunctionsPath -Recurse -ErrorAction Stop)
}
if (Test-Path $privateFunctionsPath) {
	$private = @(Get-ChildItem -Path $privateFunctionsPath -Recurse -ErrorAction Stop)
}
foreach ($file in @($public + $private)) {
	try {
		. $file.FullName
	}
	catch {
		throw "Unable to dot source [$($file.FullName)]"
	}
}

# load the correct assemblies, depending if the module was loaded from a powershell core (>= v6) or windows powershell (<= v5.1)
if ($IsCoreCLR) {
    add-type -path "$PSScriptRoot\lib\net6.0\ScottPlot.dll"
}
else {
    add-type -path "$PSScriptRoot\lib\net462\ScottPlot.dll"
}

# export the names of the public functions. Assumes unique file for each public function with base filename matching function name.
Export-ModuleMember -Function $public.BaseName
