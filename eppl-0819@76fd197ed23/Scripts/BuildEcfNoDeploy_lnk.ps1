<#Create Jenkins Job(s) to build new ecf's#>

$host.UI.RawUI.WindowTitle = "Build Ecf"

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
	$independentJenkinsScriptDir = "$rootDirectory/IndependentOfEpplVersion/Scripts/Jenkins/"
	#goto script directory:
	Set-location $independentJenkinsScriptDir
	
	Powershell.exe 	.\BuildEcfNoDeploy.ps1

	#return to original directory:
	Set-location $currDir
} else {
	Show-Error  -errorCode 1 -errorLine "No git repo found!"
}