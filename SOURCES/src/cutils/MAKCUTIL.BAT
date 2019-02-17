echo off
cls
echo Building HDSETUP.EXE INSTALL.EXE EXPORT.EXE
path=%PATH%;c:\bin
set TMP=c:\TMP
mkdir %TMP%
set DIST=c:\DISTRO
mkdir %DIST%
set BDIR=%1%

make -f cutils.mak %BDIR%

echo Distributing HDSETUP.EXE
copy HDSETUP.EXE %DIST%

echo Distributing INSTALL.EXE
copy INSTALL.EXE %DIST%

echo Distributing EXPORT.EXE
copy EXPORT.EXE %DIST%

echo Distribution complete
