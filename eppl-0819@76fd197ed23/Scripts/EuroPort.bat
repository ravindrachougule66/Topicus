@ECHO off

REM Opstartscript EuroPort6+ Studio trunk
SETLOCAL EnableDelayedExpansion EnableExtensions
 
IF [%1]==[] call :FOUT Dit script is niet om op te starten.

SET Straat=%~3
SET Customer=%~2
IF "%Straat%"=="" SET Straat=ONTW

SET ScriptDir=%~dp0
SET ScriptNaam=%~nx0
CALL "n:\EuroPort\Bin\LastDirPart.bat" %ScriptDir:~0,-1% BasisDir ScriptFolder
CALL "n:\EuroPort\Bin\LastDirPart.bat" %BasisDir:~0,-1% WorkingDir WorkingFolder

IF %MGPROF%x==1x (
	Set MGTLOG=%BasisDir%Temp\magic_log\MGTLOG.TXT
	Set MGTCNF=%BasisDir%Temp\magic_log\MGTCNF.TXT
)	

if %1==S (
    SET MagicExe=MgxpaStudio
	SET MagicIni=Studio
	if not exist %BasisDir%projects\lo\lo.edp call :FOUT Je moet eerst "Kopie Maken Sources" doen!
    
	rem check if in GIT workspace:
	git.exe fetch 1>NUL 2>NUL
	IF ERRORLEVEL 1 (
		SET IsGitWorkspace=N
		rem reset ERRORLEVEL :
		verify >nul
	) else (
		SET IsGitWorkspace=Y
	)

	rem Only execute in GIT workspace :
	if [!IsGitWorkspace!]==[Y] (
		rem get directory 'GetDirIndependentOfEpplVersion' or the latest version of its files:
		START /B /WAIT cmd /c "Powershell.exe -command ""%ScriptDir%\GetDirIndependentOfEpplVersion.ps1 '%BasisDir%'"""
		
		rem add reference to the git tools menu:
		SET Ini-17=@Ini\GIT_ToolsMenu.ini
		
		rem prevent changes in .edp files to be tracked by adding all .edp files to the assume-unchanged list of GIT:
		SET gitScriptDir=%BasisDir%IndependentOfEpplVersion\Scripts\GIT\
		START /B /WAIT cmd /c "Powershell.exe -command ""!gitScriptDir!AddAllProjectsToAssumeUnchangedList.ps1 '%BasisDir%'"""
		
		rem get latest libraries from repo:
		CALL "!gitScriptDir!GetLibrariesFromRepo.bat" "%BasisDir%"
	)
) ELSE ( 
    SET MagicExe=MgxpaRuntime
	SET MagicIni=Runtime
)

rem Set Read Only Flag for Magic.ini (git won't store this attibute) :
attrib +r %BasisDir%ini\Magic.ini

SET BasisDirExtend=%BasisDir:\=\\%

if %MAGICVERSIE%x==x  (
	SET MAGICVERSIE=4.10.0-401
) else (
	if NOT x%MAGICVERSIE%==x2.5e (
			if x%MAGICVERSIE% LSS x3.1b (
				call :FOUT "Magic versie %MAGICVERSIE% wordt hier niet (meer) ondersteund!"
			)	
	)
)

set MAGICCENTRAAL=n:\Magic\xpa %MAGICVERSIE%
set MAGICLOKAAL=c:\Magic\xpa %MAGICVERSIE%
set Software_to_check=Microsoft Visual Studio 2015 Shell (Isolated)

if %MAGICVERSIE% GEQ 3.0 (
	if not "%DISABLECOPY%x" == "TRUEx" (
		rem Magic kan niet meer centraal / op netwerk staan vanaf versie XPA 3.0

		rem Is de help er al?
		robocopy "%MAGICCENTRAAL%\help" "%MAGICLOKAAL%\help" help.txt /W:5 /ndl /njs /njh /xx 
		if errorlevel 4 call :FOUT robocopy MagicDir !ERRORLEVEL!
		if errorlevel 1 (

			robocopy "%MAGICCENTRAAL%\help" "%MAGICLOKAAL%\help" help.zip /W:5 /ndl /njs /xx 
			if errorlevel 4 call :FOUT robocopy MagicDir !ERRORLEVEL!
			rem Errorlevel 1 voor robocopy is toch ok.
			if errorlevel 1 cmd /c "exit /b 0"

			echo.
			echo Uitpakken help files, even geduld aub
			unzip -q -o "%MAGICLOKAAL%\help\Help.zip" -d "%MAGICLOKAAL%"
			if errorlevel 0 del "%MAGICLOKAAL%\help\Help.zip"
		)

		robocopy "%MAGICCENTRAAL%" "%MAGICLOKAAL%" robocopy.txt /W:5 /ndl /njs /njh /xx 
		if errorlevel 4 call :FOUT robocopy MagicDir !ERRORLEVEL!
		if errorlevel 1 (

			robocopy "%MAGICCENTRAAL%" "%MAGICLOKAAL%" /E /W:5 /ndl /njs /xx /xd  "Help"
			if errorlevel 4 call :FOUT robocopy MagicDir !ERRORLEVEL!
			rem Errorlevel 1 voor robocopy is toch ok.
			if errorlevel 1 cmd /c "exit /b 0"

				if %MAGICEXE%==MgxpaStudio (
					if %MAGICVERSIE% GEQ 4.7.1 (
						rem MgxpaStudio prerequisites

						echo.
						echo Er wordt nu gecontroleerd of noodzakelijk software aanwezig is.
						echo Even geduld a.u.b.
						echo.
						echo Controle op: "%Software_to_check%"

						for /f "tokens=2 delims==" %%I in ('wmic product where "Name='%Software_to_check%'" get name /value') do (
							for /f "delims=" %%# in ("%%I") do set "MSVS2015IS=%%~#"
						)	
						
						if /i not "X-!MSVS2015IS!"=="X-%Software_to_check%" (

							echo.
							echo ATTENTIE!
							echo Noodzakelijk software ontbreekt om met Magic xpa v4.7.1 studio te kunnen werken.
							echo Deze software zal nu geinstalleerd worden, volg de stappen van deze installatie.
							echo.
							pause
							call "\\able.nv\dfs-data\Install\Company Portal Apps\EXE Apps - Not in Company Portal\vs_isoshell_2015.exe"
						)
					)
				)
		)
	)
	SET Magic=%MAGICLOKAAL%\%MagicExe%.exe
) else (
	SET Magic=%MAGICCENTRAAL%\%MagicExe%.exe
)

SET Ini-1=Ini\Magic.ini
SET Ini-2=@Ini\%MagicIni%.ini
SET Ini-3=@Ini\%straat%\%Customer%.ini
SET Ini-4=@Ini\Ontw\OMG.ini
SET Ini-5=/[MAGIC_LOGICAL_NAMES]Straat=%Straat% /[MAGIC_LOGICAL_NAMES]Domain=%Domein%
SET PROCDUMPENABLED=%~4
SET Ini-6=%5
SET Ini-7=%~6
SET Ini-8=%~7
SET Ini-9=%~8
SET Ini-10=%~9

rem %10 en verder werkt niet, 5 shiften. Nu zijn %5, %6, %7, %8 en %9 in werkelijkheid de 10e, 11e, 12e, 13e, en 14e opgegeven parameter.
shift
shift
shift
shift
shift
SET Ini-11=%~5
SET Ini-12=%~6
SET Ini-13=%~7
SET Ini-14=%~8
SET Ini-15=@%BasisDir%Temp\info_ws
SET Ini-16=%~9

SET procdump=" "
IF "%PROCDUMPENABLED%x"=="Yx" SET procdump=-PathToProcdumpExe=n:\data\procdump\procdump.exe

SET NLS_LANG=DUTCH_THE NETHERLANDS.WE8ISO8859P15
SET NLS_SORT=BINARY

SET JVMArgs=/[MAGIC_JAVA]JVM_ARGS='-Djava.compiler=NONE -Xms16m -Xmx256m -Dorg.xml.sax.driver=org.apache.xerces.parsers.SAXParser -Dlogfilename=%BasisDirExtend%Temp\\java_log\\log4j2_%Omgeving% -Dlog4j.configurationFile=file:/%BasisDirExtend%Java\\WindowsLog4J2.json -Djacorb.home=/%BasisDirExtend%Java/Ontw/%Customer% -Djacorb.security.keystore=/%BasisDirExtend%Java/Ontw/keystore.jks'
SET MagicEnvPublicName=/[MAGIC_ENV]ApplicationPublicName=EIB_%WorkingFolder%_%COMPUTERNAME%
SET Magic_TCPIP=/[MAGIC_COMMS]TCP/IP= 2, 30, 1500-2005/LocalHost=%COMPUTERNAME%.able.nv
SET Extra_Env=/[MAGIC_LOGICAL_NAMES]EPPLUSCLIENT=*%BasisDir%

rem Set Branch Number information :
SET ScriptCreateBranchInfo=N:\EuroPort\Bin\Branches\CreateBranchInfo.bat
IF %Project%x==x (
	set SCBIParm=%Ini-3:@=%
) else (
	set SCBIParm=Ini\Proj\Prj_%Project%\%Project%.ini
)	

IF EXIST "%ScriptCreateBranchInfo%" (call %ScriptCreateBranchInfo% "%BasisDir%" "%SCBIParm%")

rem Mogelijkheid voor eigen recentlist in de Studio
if %MagicExe%==MgxpaStudio (
	if exist %~dp0\..\temp\xpa-recent.reg (
		for /f %%f in (%~dp0\..\temp\xpa-recent.reg) do set fileSize=%%~zf
		if !fileSize! NEQ 0 regedit /s %~dp0\..\temp\xpa-recent.reg
	)	
)	

Start "Magic" %WAITMAGIC% /D"%BasisDir%" "%Magic%" %procdump% /ini=%Ini-1% %Ini-2% %Ini-3% %Ini-4% %Ini-5% %Ini-6% %Ini-7% %Ini-8% %Ini-9% %Ini-10% %Ini-11% %Ini-12% %Ini-13% %Ini-14% %Ini-15% %Ini-16% %Ini-17% %JVMArgs% %MagicEnvPublicName% %Magic_TCPIP% %Extra_Env%

IF %CALLFROMRDS%x==TRUEx EXIT
GOTO :EOF

:FOUT
ECHO.
ECHO %~1 %~2 %~3 %~4 %~5 %~6 %~7 %~8 %~9
ECHO.
PAUSE
EXIT 1
GOTO :EOF