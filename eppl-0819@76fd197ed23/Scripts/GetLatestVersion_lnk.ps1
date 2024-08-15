<#Gets the latest remote version of the current branch. This script is expected to be located in the 'scripts' directory of the 'root'.
#>

$host.UI.RawUI.WindowTitle = "Get Latest Version from remote"

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
	$independentGitScriptDir = "$rootDirectory/IndependentOfEpplVersion/Scripts/GIT/"
	#goto script directory:
	Set-location $independentGitScriptDir
	
	Powershell.exe 	.\GetLatestVersion.ps1

	#return to original directory:
	Set-location $currDir
} else {
	Show-Error  -errorCode 1 -errorLine "No git repo found!"
}