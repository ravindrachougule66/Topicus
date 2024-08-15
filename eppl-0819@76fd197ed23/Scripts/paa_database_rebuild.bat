@echo off
SETLOCAL EnableDelayedExpansion EnableExtensions

SET ScriptDir=%~dp0
SET ScriptNaam=%~nx0
CALL "n:\EuroPort6\Bin\LastDirPart.bat" %ScriptDir:~0,-1% BasisDir ScriptFolder
CALL "n:\EuroPort6\Bin\LastDirPart.bat" %BasisDir:~0,-1% WorkingDir WorkingFolder
set cdpatch=%WorkingDir:~2,-1%\ws1\oracle\scripts\paa\
if [%2]==[] goto parameterError
set versie=9999
set product=paa
set customer=%1
set local=%2
:begin
echo Rebuild %local% PAA database for customer: %customer%
SET /P Choice="Are you shure [y,n]?" || Set Keuze=n
if /I %choice%==Y  GOTO databaseRecreate
if /I %choice%==N  GOTO eof
echo Invalid choice!
echo.
goto begin

:databaseRecreate
if /I %local% == ONTW (
	set dbhost=%local%_%versie%_%customer%
	) ELSE (
	set dbhost=%local%_%versie%_%customer%_%product%
	)

set username=paa_owner_%customer%
set password=paa_%customer%

cd%cdpatch%ddl-scripts\
sqlplus.exe %username%/%password%@%dbhost% < paa.sql
cd%cdpatch%data-scripts\
sqlplus.exe %username%/%password%@%dbhost% < paa.sql
if /i %local%==ONTW GOTO grandUser
goto eof

:grandUser
sqlplus.exe %username%/%password%@%dbhost% < H:\DBA\Uitvoeren_XPA\UniGrantScripts\UniGrantStart.sql
goto eof

:parameterError
echo This scripts has two parameters:
echo 1. Customer (idb)
echo 2. database(local/ontw)
goto eof

:eof
echo Bye