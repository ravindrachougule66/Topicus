@ECHO OFF
SETLOCAL EnableDelayedExpansion EnableExtensions

SET Straat=%~1
IF "%Straat%"=="" SET Straat=ONTW

SET ScriptDir=%~dp0
SET ScriptNaam=%~nx0
CALL "n:\EuroPort\Bin\LastDirPart.bat" %ScriptDir:~0,-1% WorkspaceDir ScriptFolder
CALL "n:\EuroPort\Bin\LastDirPart.bat" %WorkspaceDir:~0,-1% VersionDir WorkspaceFolder
CALL "n:\EuroPort\Bin\LastDirPart.bat" %VersionDir:~0,-1% ProductDir VersionFolder
CALL "n:\EuroPort\Bin\LastDirPart.bat" %ProductDir:~0,-1% RootDir ProductFolder
cd /d %ScriptDir%
for /f "usebackq delims=: tokens=1,2*" %%n in (`mode con`) do (
    if "%%n"=="    Lines" if %%~o LSS 35 mode con lines=35
)
COLOR 0A
for /f %%i in ('git branch --show-current') do set EP_Branch=%%i
TITLE Opstart EuroPort+  [GIT Branch: %EP_Branch%]
SET ParameterFile=%TEMP%\%ProductFolder%_%VersionFolder%_%WorkspaceFolder%_%ScriptNaam%.cmd
SET HuidigeDir=%CD%
SET AllowTesting=N
CALL:setPersist AllowTesting=N
SET Omgeving=EPPL
CALL:setPersist Omgeving=EPPL
SET SQLLogging=N
CALL:setPersist SQLLogging=N
SET ProcDump=N
CALL:setPersist ProcDump=N
SET Logging=N
CALL:setPersist Logging=N
SET Expand=N
CALL:setPersist Expand=N
SET Taal=NL
CALL:setPersist Taal=NL
SET Profiler=N
CALL:setPersist Profiler=N
SET Escrow=N
CALL:setPersist Escrow=N
SET ConnectToBroker=N
CALL:setPersist ConnectToBroker=N
SET Module=lo
CALL:setPersist Module=lo
SET Domein=BBL
CALL:setPersist Domein=BBL
SET Project=
CALL:setPersist Project=
REM Bewust niet persistent JRS



SET Standaard=DEV

call:restorePersistentVars "%ParameterFile%"

:BEGIN
CLS
ECHO Straat / Versie  : %Straat% / %VersionFolder%   Omgeving         : %Omgeving%          
ECHO QTP Ondersteuning: %AllowTesting%             Connect to Broker: %ConnectToBroker%
ECHO Logging          : %Logging%             Profiler         : %Profiler%
ECHO SQL Logging      : %SQLLogging%             Taal             : %Taal%
ECHO Color / Fonts    : %Standaard%           Expand all       : %Expand%
ECHO Project          : %Project%              ProcDump         : %ProcDump%
if %Escrow%==Y ECHO Escrow           : %Escrow%
ECHO ========================================================
ECHO.
ECHO Welke omgeving wil je opstarten? ^| Colors / Fonts      ^|
ECHO                                  ^|                     ^|
ECHO 1. EPPL                          ^| ORG. Orgineel       ^|
ECHO 2. SEM                           ^| DEV. HighContrast   ^|
ECHO 3. AZL                           ^| NEW. Proposed       ^|
ECHO 4. ING                           ^|---------------------^|
ECHO 5. NN                            ^| NL. Nederlands      ^|
ECHO 6. INGBE                         ^| EN. Engels          ^|
ECHO 7. AAB                           ^|                     ^|
ECHO 8. ACH                           ^| C. Connect to Broker^|
ECHO 9. EPPL / OWNER t.b.v GetDef.    ^|                     ^|
ECHO -------------------------------------------------------^|
ECHO Q. QTP ondersteuning             ^| P. Profiler         ^|
ECHO L. Logging                       ^| E. Escrow           ^|
ECHO S. SQL Logging                   ^| H. Help             ^|
ECHO PD. ProcDump                     ^|                     ^|
ECHO --------------------------------------------------------
ECHO Welke module wil je opstarten?   ^| Welk Domein?        ^|
ECHO M. Geef module in  (%Module%)    ^| D. Domein (%Domein%)^|
ECHO --------------------------------------------------------
ECHO PROJ. Project settings?          ^|                     ^|
ECHO EXP. Expand All                  ^|                     ^|
ECHO --------------------------------------------------------
ECHO 0. Afbreken                        B. Bewaar instelling
ECHO.

SET /P Keuze="Maak een keuze (Enter is starten): " || Set Keuze=Y
IF /I %Keuze%==0  EXIT /b
IF /I %Keuze%==1  GOTO OMGEVING
IF /I %Keuze%==2  GOTO OMGEVING
IF /I %Keuze%==3  GOTO OMGEVING
IF /I %Keuze%==4  GOTO OMGEVING
IF /I %Keuze%==5  GOTO OMGEVING
IF /I %Keuze%==6  GOTO OMGEVING
IF /I %Keuze%==7  GOTO OMGEVING
IF /I %Keuze%==8  GOTO OMGEVING
IF /I %Keuze%==9  GOTO OMGEVING
IF /I %Keuze%==B  GOTO BEWAAR
IF /I %Keuze%==C  GOTO CONNECT_BROKER
IF /I %Keuze%==D  GOTO DOMAIN
IF /I %Keuze%==M  GOTO DEFAULTMODULE
IF /I %KEUZE% GEQ MAA IF /I %KEUZE% LEQ MZZ GOTO MODULESWITCH
IF /I %Keuze%==E  GOTO ESCROW
IF /I %Keuze%==H  GOTO HELP
IF /I %Keuze%==L  GOTO LOGGING
IF /I %Keuze%==P  GOTO PROFILER
IF /I %Keuze%==Q  GOTO QTP
IF /I %Keuze%==S  GOTO SQLLOGGING
IF /I %Keuze%==PD  GOTO PROCDUMP
IF /I %Keuze%==X  GOTO STOP_BROKER
IF /I %Keuze%==Y  GOTO STARTMAGIC
IF /I %Keuze%==Z  GOTO START_BROKER
IF /I %Keuze%==NL GOTO TAAL
IF /I %Keuze%==EN GOTO TAAL
IF /I %Keuze%==ORG GOTO STANDAARD
IF /I %Keuze%==DEV GOTO STANDAARD
IF /I %Keuze%==NEW GOTO STANDAARD
IF /I %Keuze%==PROJ GOTO PROJECT
IF /I %Keuze%==EXP GOTO EXPAND 
ECHO Ongeldige keuze!
ECHO.
PAUSE
GOTO BEGIN

:QTP
IF %AllowTesting%==N (
    SET AllowTesting=Y
 ) ELSE ( 
    SET AllowTesting=N
 )
GOTO BEGIN

:SQLLOGGING
IF %SQLLogging%==N (
    SET SQLLogging=Y
 ) ELSE ( 
    SET SQLLogging=N
 )
GOTO BEGIN

:PROCDUMP
IF %ProcDump%==N (
    SET ProcDump=Y
 ) ELSE ( 
    SET ProcDump=N
 )
GOTO BEGIN

:LOGGING
IF %Logging%==N (
    SET Logging=Y
 ) ELSE ( 
    SET Logging=N
 )
GOTO BEGIN

:PROFILER
IF %Profiler%==N (
    SET Profiler=Y
 ) ELSE ( 
    SET Profiler=N
 )
GOTO BEGIN

:ESCROW
IF %Escrow%==N (
    SET Escrow=Y
 ) ELSE ( 
    SET Escrow=N
 )
GOTO BEGIN

:EXPAND

if %Expand%==N (
    SET Expand=Y
 ) ELSE ( 
    SET Expand=N
 )

GOTO BEGIN

:HELP
START N:\EuroPort6\Bin\HandleidingOpstartmenuEuroPort6v1_0.pdf
GOTO BEGIN

:DEFAULTMODULE
SET /P Module="Geef een module: " || Set Module=lo
GOTO BEGIN

:MODULESWITCH
SET Module=%KEUZE:~1,2%
GOTO BEGIN

:DOMAIN
set DomeinOK=FALSE
SET /P Domein="Geef het domein: " 
for %%d in (AGG PAA PAI SCF TAP WES CCC) do (
	if /i x%Domein%==x%%d set DomeinOK=TRUE
)
if %DomeinOK%==FALSE (
	echo Ongeldig domein!
	set Domein=   
	pause
)	
GOTO BEGIN

:PROJECT
set ProjectOK=FALSE
SET /P Project="Geef het project (INGTRANS BROCK ICPERF WES GUI MIGRATIONNL MIGRATIONBE PAA AZL_BASE AZL_PLAY AAB_BASE AAB_PLAY AUTOMATION): "
for %%d in (INGTRANS BROCK ICPERF WES GUI MIGRATIONNL MIGRATIONBE PAA AZL_BASE AZL_PLAY AAB_BASE AAB_PLAY AUTOMATION) do (
	if /i x%Project%==x%%d set ProjectOK=TRUE
)
if %ProjectOK%==FALSE (
	echo Ongeldig project!
	set Project=   
	echo Project=%Project%
	pause
)	
GOTO BEGIN


:OMGEVING
IF %Keuze%==1 SET Omgeving=EPPL
IF %Keuze%==2 SET Omgeving=SEM
IF %Keuze%==3 SET Omgeving=AZL
IF %Keuze%==4 SET Omgeving=ING
IF %Keuze%==5 SET Omgeving=NN
IF %Keuze%==6 SET Omgeving=INGBE
IF %Keuze%==7 SET Omgeving=AAB
IF %Keuze%==8 SET Omgeving=ACH
IF %Keuze%==9 SET Omgeving=EPPO

IF %Straat%==QC (
	IF %Keuze%==1 SET Omgeving=EPPL
	IF %Keuze%==2 SET Omgeving=X
	IF %Keuze%==3 SET Omgeving=X
	IF %Keuze%==4 SET Omgeving=X
	IF %Keuze%==5 SET Omgeving=X
	IF %Keuze%==6 SET Omgeving=X
	IF %Keuze%==7 SET Omgeving=X
	IF %Keuze%==8 SET Omgeving=X
	IF %Keuze%==9 SET Omgeving=X
)

IF %Omgeving%==X (
	ECHO Deze klant kan niet gekozen worden.
	SET Omgeving=EPPL
	PAUSE
	)
GOTO BEGIN

:TAAL
IF /I %Keuze%==NL SET Taal=NL
IF /I %Keuze%==EN SET Taal=EN
IF /I %Keuze%==FR SET Taal=FR
GOTO BEGIN

:STANDAARD
IF /I %Keuze%==ORG SET STANDAARD=ORG
IF /I %Keuze%==NEW SET STANDAARD=NEW
IF /I %Keuze%==DEV SET STANDAARD=DEV
GOTO BEGIN

:BEWAAR
call:savePersistentVars &
GOTO BEGIN

:START_BROKER
CALL "%ScriptDir%Start_Broker.bat"
GOTO BEGIN

:STOP_BROKER
CALL "%ScriptDir%Stop_Broker.bat"
GOTO BEGIN

:CONNECT_BROKER
IF %ConnectToBroker%==N (
    SET ConnectToBroker=Y
 ) ELSE ( 
    SET ConnectToBroker=N
 )
GOTO BEGIN

:STARTMAGIC
IF %AllowTesting%==Y    Set Parameter_4=@Ini\AllowTesting.ini
IF %SQLLogging%==Y      Set Parameter_5=@Ini\Debug.ini
IF %Logging%==Y         Set Parameter_6=@Ini\Logging.ini
IF %Taal%==FR           Set Parameter_7=@Ini\Frans.ini
IF %Taal%==EN           Set Parameter_7=@Ini\Engels.ini
IF %ConnectToBroker%==Y Set Parameter_8=@Ini\Broker.ini
IF %Escrow%==Y          Set Parameter_9=@Ini\Escrow.ini
IF %Profiler%==Y        Set MGPROF=1
IF %STANDAARD%==ORG     Set Parameter_10=@Ini\Ep6orgStandard.ini
IF %STANDAARD%==DEV     Set Parameter_10=@Ini\Ep6HighContrast.ini
IF %STANDAARD%==NEW     Set Parameter_10=@Ini\Ep6newStandard.ini
IF not %Module%x==x		Set Parameter_11="/[MAGIC_ENV]DefaultProject=%%epproj%%%Module%\%Module%.edp"
IF not %Project%x==x	Set Parameter_12=@Ini\Proj\Prj_%Project%\%Project%.ini
IF %Expand%==Y          Set Parameter_13="/[MAGIC_SPECIALS]SpecialInitialExpandAll=Y"

REM Verwijderen van bestanden in VS cache map.
del "%LOCALAPPDATA%\MSE\Magic xpa\" /s /f /q 1>NUL

"%ScriptDir%EuroPort.bat" S %Omgeving% %Straat% %ProcDump% %Parameter_4% %Parameter_5% %Parameter_6% %Parameter_7% %Parameter_8% %Parameter_9% %Parameter_10% %Parameter_11% %Parameter_12% %Parameter_13%
GOTO :EOF

:setPersist -- to be called to initialize persistent variables
::          -- %*: set command arguments
SET %*
GOTO :EOF

:savePersistentVars -- Save values of persistent variables into a file
SETLOCAL
ECHO.>"%ParameterFile%"
CALL :getPersistentVars persvars
FOR %%a IN (%persvars%) DO (ECHO.SET %%a=!%%a!>>"%ParameterFile%")
GOTO :EOF

:getPersistentVars -- returns a comma separated list of persistent variables
::                 -- %~1: reference to return variable
SETLOCAL
SET retlist=
SET parse=findstr /i /c:"call:setPersist" "%~f0%"^|find /v "ButNotThisLine"
FOR /f "tokens=2 delims== " %%a IN ('"%parse%"') DO (SET retlist=!retlist!%%a,)
( ENDLOCAL & REM RETURN VALUES
    IF "%~1" NEQ "" SET %~1=%retlist%
)
GOTO :EOF

:restorePersistentVars -- Restore the values of the persistent variables
::                     -- %~1: batch file name to restore from
IF EXIST "%ParameterFile%" CALL "%ParameterFile%"
GOTO:EOF