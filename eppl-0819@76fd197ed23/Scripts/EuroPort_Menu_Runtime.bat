@ECHO OFF
SETLOCAL EnableDelayedExpansion EnableExtensions

SET Straat=%~1
IF [%Straat%]==[] GOTO :FOUT

SET ScriptDir=%~dp0
SET ScriptNaam=%~nx0
CALL "n:\EuroPort\Bin\LastDirPart.bat" %ScriptDir:~0,-1% WorkspaceDir ScriptFolder
CALL "n:\EuroPort\Bin\LastDirPart.bat" %WorkspaceDir:~0,-1% VersionDir WorkspaceFolder
CALL "n:\EuroPort\Bin\LastDirPart.bat" %VersionDir:~0,-1% ProductDir VersionFolder
CALL "n:\EuroPort\Bin\LastDirPart.bat" %ProductDir:~0,-1% RootDir ProductFolder

for /f "usebackq delims=: tokens=1,2*" %%n in (`mode con`) do (
    if "%%n"=="    Lines" if %%~o LSS 35 mode con lines=35
)

COLOR 0A
TITLE Opstart EuroPort+
SET ParameterFile=%TEMP%\%ProductFolder%_%VersionFolder%_%WorkspaceFolder%_%ScriptNaam%.cmd
SET HuidigeDir=%CD%
SET AllowTesting=N
CALL:setPersist AllowTesting=N
SET Omgeving=EPPL
CALL:setPersist Omgeving=EPPL
SET SQLLogging=N
CALL:setPersist SQLLogging=N
SET Logging=N
CALL:setPersist Logging=N
SET Taal=EN
CALL:setPersist Taal=EN
SET Profiler=N
CALL:setPersist Profiler=N
SET Escrow=N
CALL:setPersist Escrow=N
SET Project=
CALL:setPersist Project=
SET Display=STANDARD
call:setPersist Display=STANDARD
call:restorePersistentVars "%ParameterFile%"

IF NOT [%~2]==[] (
	SET Omgeving=%~2
	GOTO STARTMAGIC
)
 
:BEGIN
CLS
ECHO Straat / Versie  : %Straat% / %VersionFolder%  Omgeving     : %Omgeving%          
ECHO QTP Ondersteuning: %AllowTesting%
ECHO Logging          : %Logging%             Profiler     : %Profiler%
ECHO SQL Logging      : %SQLLogging%             Taal         : %Taal%   
ECHO Project          : %Project%              Display      : %Display%
if %Escrow%==Y ECHO Escrow           : %Escrow%
ECHO ========================================================

ECHO Welke omgeving wil je opstarten? ^|                     ^|
ECHO                                  ^|                     ^|
ECHO 1. EPPL                          ^|---------------------^|
ECHO 2. SEM                           ^| NL. Nederlands      ^|
ECHO 3. AZL                           ^| EN. Engels          ^|
ECHO 4. ING                           ^|---------------------^|
ECHO 5. NN                            ^| ST  Standaard       ^|
ECHO 6. ING BElgium                   ^| LT. Laptop          ^|
ECHO 7. AAB                           ^|                     ^|
ECHO 8. ACH                           ^|---------------------^|
ECHO -------------------------------------------------------^|
ECHO Q. QTP ondersteuning             ^| P. Profiler         ^|
ECHO L. Logging                       ^| E. Escrow           ^|
ECHO S. SQL Loging                    ^| H. Help             ^|
ECHO --------------------------------------------------------
ECHO Specifieke project settings?     ^|                     ^|
ECHO PROJ. Project settings?          ^|                     ^|
ECHO --------------------------------------------------------
ECHO 0. Afbreken                        B. Bewaar instelling
ECHO.

SET /P Keuze="Kies optie  of (Enter is starten): " || Set Keuze=M
IF /I %Keuze%==Q  GOTO QTP
IF /I %Keuze%==S  GOTO SQLLOGGING
IF /I %Keuze%==L  GOTO LOGGING
IF /I %Keuze%==NL GOTO TAAL
IF /I %Keuze%==EN GOTO TAAL
IF /I %Keuze%==ST GOTO FONT
IF /I %Keuze%==LT GOTO FONT
IF /I %Keuze%==P  GOTO PROFILER
IF /I %Keuze%==E  GOTO ESCROW
IF /I %Keuze%==H  GOTO HELP
IF /I %Keuze%==1  GOTO OMGEVING
IF /I %Keuze%==2  GOTO OMGEVING
IF /I %Keuze%==3  GOTO OMGEVING
IF /I %Keuze%==4  GOTO OMGEVING
IF /I %Keuze%==5  GOTO OMGEVING
IF /I %Keuze%==6  GOTO OMGEVING
IF /I %Keuze%==7  GOTO OMGEVING
IF /I %Keuze%==8  GOTO OMGEVING
IF /I %Keuze%==9  GOTO OMGEVING
IF /I %Keuze%==M  GOTO STARTMAGIC
IF /I %Keuze%==B  GOTO BEWAAR
IF /I %Keuze%==PROJ GOTO PROJECT
IF /I %Keuze%==0  EXIT /b
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

:HELP
START N:\EuroPort6\Bin\HandleidingOpstartmenuEuroPort6v1.0.pdf
GOTO BEGIN

:PROJECT
set ProjectOK=FALSE
SET /P Project="Geef het project (INGTRANS BROCK WES GUI MIGRATIONNL MIGRATIONBE PAA AZL_BASE AZL_PLAY AAB_BASE AAB_PLAY AUTOMATION): "
for %%d in (INGTRANS BROCK WES GUI MIGRATIONNL MIGRATIONBE PAA AZL_BASE AZL_PLAY AAB_BASE AAB_PLAY AUTOMATION) do (
	if /i x%Project%==x%%d set ProjectOK=TRUE
)
if %ProjectOK%==FALSE (
	echo Ongeldig project!
	set Project=   
	pause
)	
GOTO BEGIN


:OMGEVING
IF %Keuze%==1 SET Omgeving=EPPL
IF %Keuze%==2 SET Omgeving=SEM
if %Keuze%==3 SET Omgeving=AZL
IF %Keuze%==4 SET Omgeving=ING
IF %Keuze%==5 SET Omgeving=NN
IF %Keuze%==6 SET Omgeving=INGBE
IF %Keuze%==7 SET Omgeving=AAB
IF %Keuze%==8 SET Omgeving=ACH

IF %Keuze%==9 SET Omgeving=X

IF %Straat%==QC (
	IF %Keuze%==1 SET Omgeving=EPPL
	IF %Keuze%==2 SET Omgeving=X
	IF %Keuze%==3 SET Omgeving=X
	IF %Keuze%==4 SET Omgeving=X
	IF %Keuze%==5 SET Omgeving=X
	IF %Keuze%==6 SET Omgeving=X
	IF %Keuze%==7 SET Omgeving=X
	IF %Keuze%==8 SET Omgeving=X
	IF %Keuze%==9 SET Omgeving=MENU
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

:FONT
IF /I %Keuze%==ST SET Display=STANDARD
IF /I %Keuze%==LT SET Display=LAPTOP

:BEWAAR
call:savePersistentVars &
GOTO BEGIN

:STARTMAGIC
SET ProcDump=N
IF %AllowTesting%==Y Set Parameter_4=@Ini\AllowTesting.ini
IF %SQLLogging%==Y   Set Parameter_5=@Ini\Debug.ini
IF %Logging%==Y      Set Parameter_6=@Ini\Logging.ini
IF %Taal%==FR        Set Parameter_7=@Ini\Frans.ini
IF %Taal%==EN        Set Parameter_7=@Ini\Engels.ini
IF %Escrow%==Y       Set Parameter_9=@Ini\Escrow.ini
IF %Display%==LAPTOP Set Parameter_10=@Ini\Laptop.ini
IF %Profiler%==Y     Set MGPROF=1
IF not %Project%x==x	Set Parameter_11=@Ini\Proj\Prj_%Project%\%Project%.ini

"%ScriptDir%EuroPort.bat" R %Omgeving% %Straat% %ProcDump% %Parameter_4% %Parameter_5% %Parameter_6% %Parameter_7% %Parameter_8% %Parameter_9% %Parameter_10% %Parameter_11%

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
GOTO :EOF

:FOUT
ECHO 1e parameter is niet gevuld
PAUSE
EXIT
