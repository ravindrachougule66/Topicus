<#Checks if directory 'IndependentOfEpplVersion' is present in the current repo. If not, this script will get the directory and its content from branch 'independentOfEpplVersion' of the remote repo.
  When the directory is present there is a check if a newer version is present. If so, this version is downloaded.
#>

param ($rootDirectory)

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

function restoreIndependentDir {
	#restore directory $independentDirPlusPath within current branch:
	write-host "------------------------------------------------------------------------------------------------------------------------"
	write-host "  Restore directory $independentDir ..."
	write-host "------------------------------------------------------------------------------------------------------------------------"
	$noOutput=@(git.exe restore --source "origin/$independentRepo" $independentDirPlusPath --quiet)
	#update to ensure next execution of the script won't detect the independent branch is behind:
	$noOutput=@(git.exe fetch origin $independentRepo`:$independentRepo --quiet)
}	



#Root directory of git repo found:
if (Test-Path -Path $rootDirectory ) {

$independentDir="/IndependentOfEpplVersion"
$independentDirPlusPath="$rootDirectory$independentDir"
$independentRepo="independentOfEpplVersion"
#Fetch latest from remote branch:
$NoOutput=(git.exe fetch origin "$independentRepo" --quiet)

	if (Test-Path -Path $independentDirPlusPath ) {
		$newVersionAvailable=((git.exe for-each-ref --format="%(refname:short) %(upstream:track) %(upstream:remotename)" "refs/heads/$independentRepo") -match "\s\[behind\s(\d)*]\s")
		if ($newVersionAvailable){
			restoreIndependentDir
		}	
	} else {
		restoreIndependentDir
	}

} else {
	Show-Error  -errorCode 1 -errorLine "No git repo found!"
}