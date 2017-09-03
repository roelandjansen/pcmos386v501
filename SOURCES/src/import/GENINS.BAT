echo off
set dbg=
if (%1) == (d) goto debug
if not (%1) == () goto badparm
goto p1

:debug
set dbg=-Ddebug
if exist install.obj del install.obj
if exist install.exe del install.exe

:p1
tcmake -finstall -Dudir=c:\ulib\ -Dbdir=c:\borlandc\lib\ %dbg% install.exe 
set dbg=
goto end

:badparm
echo.
echo Error: Improper parameter syntax
echo.
echo Proper form:
echo.
echo    GENINS [d]
echo.
echo. where the optional 'd' will produce a debugging version
echo.
echo.

:end


