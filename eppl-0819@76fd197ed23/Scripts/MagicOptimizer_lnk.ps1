<#Start the Magic Optimizer#>

$host.UI.RawUI.WindowTitle = "Start Optimizer"

#get current directory
$currDir = Convert-Path (Get-Location -PSProvider FileSystem)

#get directory of started Script
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath
Set-Location $scriptDir

#get git root directory:
$args = 'rev-parse','--show-toplevel'
$rootDirectory = git.exe $args
 
function ExitWithCode($exitcode) {
  $host.SetShouldExit($exitcode)
  exit $exitcode
}

function Show-Error {
    param(
	[Int]$errorCode,
    [String]$errorLine
    )
	"+++++++++++++++++++++++++++++++++++++++++++"
	"++++             ERROR                 ++++"
	"+++++++++++++++++++++++++++++++++++++++++++"
	"Errorcode: $errorCode $errorLine"
	"+++++++++++++++++++++++++++++++++++++++++++"
	pause
	ExitWithCode $errorCode
}

#Root directory of git repo found:
if (Test-Path -Path $rootDirectory ) {
	$magicOptimizerScriptDir = "$rootDirectory/IndependentOfEpplVersion/Scripts/MagicOptimizer/"
	#goto script directory:
	Set-location $magicOptimizerScriptDir
	
	Powershell.exe 	.\MagicOptimizer.ps1

	#return to original directory:
	Set-location $currDir
} else {
	Show-Error  -errorCode 1 -errorLine "No git repo found!"
}