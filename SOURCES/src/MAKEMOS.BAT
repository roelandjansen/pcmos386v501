rem echo off
cls
REM SHIPPING.MOS CONTAINS THE ACTUAL CODE THAT IS SHIPPING.
REM VERSION 5 UPDATE 6.
path=c:\dos5.0;c:\borlandc;c:\lib;c:\bin;%PATH%
set TMP=c:\TMP
mkdir %TMP%
cd kernel
make -f kernel.mak $$eval.sys
REM make -f kernel.mak $$mos.sys is for internal R & D use only.
del $$mos.sys
ren $$eval.sys $$mos.sys
cd ..\mos5src
make -f makeutil.mak all
rem make -f maketerm.mak all
del $*.*
ren __*.* $$*.*
ren _*.sys $*.sys
rem CD ..\import
rem make -f import.mak import.exe
rem cd ..\export
rem make -f export.mak export.exe
cd \
