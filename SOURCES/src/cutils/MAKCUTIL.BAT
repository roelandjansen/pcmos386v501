echo off
cls
echo Building HDSETUP.EXE INSTALL.EXE EXPORT.EXE
path=%PATH%;c:\bin
set TMP=c:\TMP
mkdir %TMP%
set DIST=c:\DISTRO
mkdir %DIST%

make -f cutils.mak %1

echo Distributing HDSETUP.EXE and required files
copy HDSETUP.EXE %DIST%
copy HDSETUP.MSG %DIST%

echo Distributing INSTALL.EXE and required files
copy INSTALL.EXE %DIST%
copy INSTALL.MSG %DIST%

echo Distributing EXPORT.EXE
copy EXPORT.EXE %DIST%

echo Distribution complete
