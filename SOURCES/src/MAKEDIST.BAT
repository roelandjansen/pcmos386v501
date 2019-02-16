echo off
cls
echo Setting up environment
path=%PATH%;c:\bin
set TMP=C:\TMP
mkdir %TMP%
set DIST=C:\DISTRO
mkdir %DIST%

set INCLUDE=..\..\include;include
set LIB=..\..\lib;libs

echo Copying missing files from sidecar
echo to c:\distro

rem Sidecar holds files that have no source
rem in the repo and the HELP.EXE which
rem requires Turbo Pascal to rebuild
copy latest\sidecar\*.* c:\distro

pause

echo Building Base Operating System

rem Build serial, kernel, utilities, and drivers
cd latest
bosmake.bat
cd ..

pause

rem Build ACU
cd acu
makeacu.bat
cd ..

pause

rem Build unterm terminal driver
cd unterm
makeutrm.bat
cd ..

pause

rem Build import program
cd import
makeimp.bat
cd ..

pause

rem Build ULIB library
cd ulib
genulib.bat %1
cd ..

pause

rem Build cutils
cd cutils
makcutil.bat %2
cd ..

pause

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
del *.*

echo Making auxfiles.exe
cd auxfiles
pkzip ..\auxfiles.zip *.*
del *.* 
cd ..
rmdir auxfiles
zip2exe auxfiles.zip
del auxfiles.zip

echo Making mosfiles.exe
cd mosfiles
pkzip ..\mosfiles.zip *.*
del *.*
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
echo Distribution complete
