echo off
cls
echo Building IMPORT.EXE
path=%PATH%;c:\bin
set TMP=c:\TMP
mkdir %TMP%
set DIST=c:\DISTRO
mkdir %DIST%

set INCLUDE=..\..\..\include;..\include
set LIB=..\..\..\lib;..\libs

make -f import.mak %1

echo Distributing IMPORT.EXE
copy IMPORT.EXE %DIST%

echo Distribution complete
