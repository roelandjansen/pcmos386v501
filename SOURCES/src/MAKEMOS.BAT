rem echo off
cls
REM SHIPPING.MOS CONTAINS THE ACTUAL CODE THAT IS SHIPPING.
REM VERSION 5 UPDATE 6.
path=%PATH%;c:\bin
set TMP=c:\TMP
mkdir %TMP%

set INCLUDE=..\..\..\include;..\include
set LIB=..\..\..\lib;..\libs

REM ====== The Kernel =====
cd kernel
del $$mos.sys

REM make -f kernel.mak $$eval.sys
REM ren $$eval.sys $$mos.sys

REM this was for internal R & D use only.
make -f kernel.mak $$mos.sys

cd ..
REM =======================

cd mos5src
make -f makeutil.mak all
rem make -f maketerm.mak all
del $*.*
ren __*.* $$*.*
ren _*.sys $*.sys
cd ..

cd import
make -f import.mak import.exe
cd ..

rem cd export
rem make -f export.mak export.exe
rem cd ..
