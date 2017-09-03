echo off
set dbg=
if (%1) == (d) goto debug
if not (%1) == () goto badparm
goto p1

:debug
set dbg=-Ddebug
if exist export.obj del export.obj
if exist export.exe del export.exe

:p1
tcmake -fexport -Dudir=c:\ulib\ -Dbdir=c:\borlandc\lib\ %dbg% export.exe 
set dbg=
goto end

:badparm
echo.
echo Error: Improper parameter syntax
echo.
echo Proper form:
echo.
echo    GENEXP [d]
echo.
echo. where the optional 'd' will produce a debugging version
echo.
echo.

:end


