echo off
cls
echo Building Base Operating System
path=%PATH%;c:\bin
set TMP=c:\TMP
mkdir %TMP%
set DIST=c:\DISTRO
mkdir %DIST%

set INCLUDE=..\..\..\include;..\include
set LIB=..\..\..\lib;..\libs

echo Generating Serial Number
make -f makeser.mak all
echo Creating registration script

echo Building Kernel
make -f kernel.mak $$eval.sys
ren $$EVAL.SYS $$MOS.SYS

echo Distributing Kernel
copy $$MOS.SYS %DIST%

echo Building Utilities
make -f makeutil.mak all

rem Doing this outside makefile in case
rem user doesn't have Turbo Pascal
echo Attempting to build HELP.EXE
echo Requires Turbo Pascal
tpc help

echo Attempting to generate HELP
helpgen

echo Building Drivers
make -f maketerm.mak all

echo Performing renames
ren __SHELL.SYS $$SHELL.SYS
ren MOXCPTSK.COM COMMAND.COM
ren _286N.SYS $286N.SYS
ren _386.SYS $386.SYS
ren _ALL.SYS $ALL.SYS
ren _ARNET.SYS $ARNET.SYS
ren _CHARGE.SYS $CHARGE.SYS
ren _EMS.SYS $EMS.SYS
ren _GIZMO.SYS $GIZMO.SYS
ren _KBBE.SYS $KBBE.SYS
ren _KBCF.SYS $KBCF.SYS
ren _KBDK.SYS $KBDK.SYS
ren _KBFR.SYS $KBFR.SYS
ren _KBGR.SYS $KBGR.SYS
ren _KBIT.SYS $KBIT.SYS
ren _KBLA.SYS $KBLA.SYS
ren _KBNL.SYS $KBNL.SYS
ren _KBNO.SYS $KBNO.SYS
ren _KBPO.SYS $KBPO.SYS
ren _KBSF.SYS $KBSF.SYS
ren _KBSG.SYS $KBSG.SYS
ren _KBSP.SYS $KBSP.SYS
ren _KBSV.SYS $KBSV.SYS
ren _KBUK.SYS $KBUK.SYS
ren _MOUSE.SYS $MOUSE.SYS
ren _NETBIOS.SYS $NETBIOS.SYS
ren _PIPE.SYS $PIPE.SYS
ren _RAMDISK.SYS $RAMDISK.SYS
ren _SERIAL.SYS $SERIAL.SYS

echo Distributing Utilities and Drivers
copy *.COM %DIST%
copy *.EXE %DIST%
copy *.SYS %DIST%
copy *.TXT %DIST%
copy *.NDX %DIST%

echo Distribution Complete
