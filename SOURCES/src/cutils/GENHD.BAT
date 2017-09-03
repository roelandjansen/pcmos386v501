echo off
set dbg=
if (%1) == (d) goto debug
if not (%1) == () goto badparm
goto p1

:debug
set dbg=-Ddebug
if exist hdsetup.obj del hdsetup.obj
if exist hdsetup.exe del hdsetup.exe

:p1
tcmake -fhdsetup -Dmdir=c:\ -Dudir=c:\ulib\ -Dbdir=c:\borlandc\lib\ %dbg% hdsetup.exe 
set dbg=
goto end

:badparm
echo.
echo Error: Improper parameter syntax
echo.
echo Proper form:
echo.
echo    GENHD [d]
echo.
echo. where the optional 'd' will produce a debugging version
echo.
echo.

:end


