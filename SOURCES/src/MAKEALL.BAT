echo off
cls
echo Setting up environment
envsize 4096
path=%PATH%;c:\bin
set TMP=C:\TMP
mkdir %TMP%
set DIST=C:\DISTRO
mkdir %DIST%
set CCOMPL=%1
set BDIR=%2
set BORBIN=%3

set INCLUDE=..\..\include;include
set LIB=..\..\lib;libs

echo Copying missing files from sidecar
echo to c:\distro

rem Sidecar holds files that have no source
rem in the repo and the HELP.EXE which
rem requires Turbo Pascal to rebuild
copy latest\sidecar\*.* c:\distro

echo Building Base Operating System

rem Build serial, kernel, utilities, and drivers
cd latest
bosmake.bat
cd ..

rem Build ACU
cd acu
makeacu.bat
cd ..

rem Build unterm terminal driver
cd unterm
makeutrm.bat
cd ..

rem Build import program
cd import
makeimp.bat
cd ..

set PATH=%BORBIN%;C:\BIN;C:\PCMOS
rem Build ULIB library
cd ulib
genulib.bat %CCOMPL%
cd ..

rem Build cutils
cd cutils

make -f cutils.mak -Dbdir=%BDIR%

echo Distributing HDSETUP.EXE and required files
copy HDSETUP.EXE %DIST%
copy HDSETUP.MSG %DIST%

echo Distributing INSTALL.EXE and required files
copy INSTALL.EXE %DIST%
copy INSTALL.MSG %DIST%

echo Distributing EXPORT.EXE
copy EXPORT.EXE %DIST%

cd ..

rem Build CDLINK

cd cdlink
asmcdmos.bat
cd ..

path=c:\bin;c:\pcmos
rem Begin Distribution
cd c:\distro

mkdir base
copy $$mos.sys base
copy $$shell.sys base
copy command.com base
copy msys.com base
copy format.com base
copy hdsetup*.* base
copy install*.* base
copy config.sys base
copy autoexec.bat base
copy auto.bat base
copy readme base
copy export.exe base

mkdir auxfiles
copy help*.* auxfiles
del help*.*
copy ??term.sys auxfiles
del ??term.sys
copy wy99gt.sys auxfiles
del wy99gt.sys
copy *.bin auxfiles
del *.bin
copy $kb*.sys auxfiles
del $kb*.sys
copy *.rom auxfiles
del *.rom
copy $?86*.sys auxfiles
del $?86*.sys
copy acu*.* auxfiles
del acu*.*

mkdir mosfiles
copy *.* mosfiles
del *.* /y

echo Making auxfiles.exe
cd auxfiles
pkzip ..\auxfiles.zip *.*
del *.* /y
cd ..
rmdir auxfiles
zip2exe auxfiles.zip
del auxfiles.zip

echo Making mosfiles.exe
cd mosfiles
pkzip ..\mosfiles.zip *.*
del *.* /y
cd ..
rmdir mosfiles
zip2exe mosfiles.zip
del mosfiles.zip

echo Format target disk a:
base\format a:
echo Making disk bootable
base\msys a:
echo Making disk MOS
cd base
copy *.* a:
cd ..
echo Copying mosfiles.exe
copy mosfiles.exe a:
echo Copying auxfiles.exe
copy auxfiles.exe a:
echo Adding CDLINK
mkdir a:\cdrom
copy cdrom\*.* a:\cdrom
echo Distribution complete
