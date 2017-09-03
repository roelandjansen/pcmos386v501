echo off
cls
REM SHIPPING.MOS CONTAINS THE ACTUAL CODE THAT IS SHIPPING.
REM VERSION 5 UPDATE 6.
path=c:\dos5.0;c:\borlandc;c:\lib;c:\bin
set TMP=c:\TMP
cd\kernel
make -f kernel.mak $$eval.sys 
REM make -f kernel.mak $$mos.sys is for internal R & D use only.
ren $$eval.sys $$mos.sys
cd\mos5src
make -f makeutil.mak all
make -f maketerm.mak all
ren __*.* $$*.*
ren _*.* $*.*
rem CD\import
rem make -f import.mak import.exe
rem cd\export
rem make -f export.mak export.exe
cd\
