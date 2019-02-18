echo off
cls
echo Building ACU.EXE
path=%PATH%;c:\bin
set TMP=c:\TMP
mkdir %TMP%
set DIST=c:\DISTRO
mkdir %DIST%

set INCLUDE=..\..\..\include;..\include
set LIB=..\..\..\lib;..\libs

make -f makefile.new

echo Distributing ACU.EXE ACU.MNU ACU-HELP.HLP

copy ACU.EXE %DIST%
copy ACU.MNU %DIST%
copy ACU-HELP.HLP %DIST%

echo Distribution complete
