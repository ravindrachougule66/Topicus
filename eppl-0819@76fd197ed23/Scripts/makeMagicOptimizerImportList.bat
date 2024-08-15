@echo off
REM Copyright Remco van Trijp(c) 2022

setlocal EnableDelayedExpansion

SET ScriptDir=%~dp0
CALL "n:\EuroPort6\Bin\LastDirPart.bat" %ScriptDir:~0,-1% workspaceDir scriptFolder
echo %workspaceDir%MagicOptimizer\magicOptimizerImportList.txt| clip


SET MagicOptimizer="%ProgramFiles(x86)%\Magic Optimizer 11\MagicOptimizer.exe"
if not exist %MagicOptimizer% SET MagicOptimizer="%ProgramFiles%\Magic Optimizer 11\MagicOptimizer.exe"
if not exist %MagicOptimizer% SET MagicOptimizer="%ProgramFiles(x86)%\Magic Optimizer 10\MagicOptimizer.exe"
if not exist %MagicOptimizer% SET MagicOptimizer="%ProgramFiles%\Magic Optimizer 10\MagicOptimizer.exe"
if not exist %MagicOptimizer% SET MagicOptimizer="%ProgramFiles(x86)%\Magic Optimizer 9\MagicOptimizer.exe"
if not exist %MagicOptimizer% SET MagicOptimizer="%ProgramFiles%\Magic Optimizer 9\MagicOptimizer.exe"

cd ../

del MagicOptimizer\magicOptimizerImportList.txt 



FOR  /R . %%I in (*.edp) do (
	set module=%%I
	set module=!module:.edp=!
	set module=!module:~-2!
	set moduleFirstChar=!module:~0,1!
	set eciDir=%%I
	set eciDir=!eciDir:~0,-18!
	set eciDir=!eciDir!Eci\
	set checkForProtected=False
	set protectedExists=False

	
	echo "!module!","%%I"  >>MagicOptimizer\magicOptimizerImportList.txt 
	
	
	if "!moduleFirstChar!" == "d" set checkForProtected=True
	if "!moduleFirstChar!" == "e" set checkForProtected=True
	if !checkForProtected! == True (
		if exist "!eciDir!AGG\!module!p.eci" set protectedExists=True
		if exist "!eciDir!CCC\!module!p.eci" set protectedExists=True
		if exist "!eciDir!PAA\!module!p.eci" set protectedExists=True
		if exist "!eciDir!PAI\!module!p.eci" set protectedExists=True
		if exist "!eciDir!SCF\!module!p.eci" set protectedExists=True
		if exist "!eciDir!TAP\!module!p.eci" set protectedExists=True
		if exist "!eciDir!WES\!module!p.eci" set protectedExists=True
		if !protectedExists! == True (
			set protectedModule=!module!p
			echo "!protectedModule!","%%I"  >>MagicOptimizer\magicOptimizerImportList.txt
		)	
	)
	
)

IF NOT EXIST %MagicOptimizer% GOTO OPTIMIZER_NIET_AANWEZIG

echo Your import file is ready to import, the location is already copied to the clipboard of this computer. Magic Optimizer will start after pressing any key.
pause

Start "Magic Optimizer" /D"%workspaceDir%" %MagicOptimizer%

GOTO :EOF
	
:OPTIMIZER_NIET_AANWEZIG
ECHO Je hebt de Magic Optimizer nog niet geinstalleerd.
ECHO.
PAUSE
GOTO :EOF