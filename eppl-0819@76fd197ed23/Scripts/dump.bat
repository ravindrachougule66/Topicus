@ECHO off
for /F "delims=" %%R in ('
    tasklist /fi "IMAGENAME eq MgXpaStudio.exe" /fi "CPUtime lt 00:00:02" /svc /fo csv /nh
') do (
    set "FLAG1=" & set "FLAG2="
    for %%C in (%%R) do (
        if defined FLAG1 (
            if not defined FLAG2 (
                start N:\Data\ProcDump\procdump.exe -e -ma %%C N:\Magic_Crashes\ProcDump\PROCESSNAME_%~1_%USERNAME%_YYMMDD_HHMMSS
            )
            set "FLAG2=#"
        )
        set "FLAG1=#"
    )
)
