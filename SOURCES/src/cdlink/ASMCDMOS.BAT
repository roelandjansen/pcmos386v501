echo off
cls
PATH=%PATH%;c:\bin
set TMP=C:\TMP
mkdir %TMP%
set DIST=C:\DISTRO
mkdir %DIST%

echo Building CDLINK
public cdlink
masm cdlink.asm;
link /m cdlink.obj;
exe2bin cdlink.exe cdlink.sys
pause
del cdlink.obj
del cdlink.exe
del cdlink.pub
del cdlink.map
echo Building CDSTAT
public cdstat
masm cdstat.asm;
link /m cdstat.obj;
exe2bin cdstat.exe cdstat.com
pause
del cdstat.obj
del cdstat.exe
del cdstat.pub
del cdstat.map
echo Building ADMIN
public admin
masm admin.asm;
link /m admin.obj;
pause
del admin.obj
del admin.pub
del admin.map
echo Build Complete
echo Distributing
mkdir %DIST%\CDROM
copy cdlink.sys %DIST%\CDROM
copy cdstat.com %DIST%\CDROM
copy admin.exe %DIST%\CDROM
copy cdlink.doc %DIST%\CDROM
copy install.bat %DIST%\CDROM
