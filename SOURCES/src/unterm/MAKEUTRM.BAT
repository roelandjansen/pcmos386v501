echo off
cls
echo Building UNTERM.SYS
path=%PATH%;c:\bin
set TMP=c:\TMP
mkdir %TMP%
set DIST=c:\DISTRO
mkdir %DIST%

set INCLUDE=..\..\..\include;..\include
set LIB=..\..\..\lib;..\libs

make -f makeutrm.mak

echo Distributing UNTERM.SYS

copy *.SYS %DIST%

echo Distribution complete
