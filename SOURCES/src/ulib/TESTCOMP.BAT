rem This script doesn't work correctly with DOSBox
rem but it does work correctly with DOS
@echo off
if "%rec%"=="01" goto recurs1
if "%rec%"=="02" goto recurs2

rem echo Looking for bcc
set rec=01
set fil=bcc.exe
testcomp.bat %path%
goto end

:recurs1
set rec=
rem if "%1"=="" ECHO. %fil% not in current directory or path
if "%1"=="" goto trytcc
rem echo testing %1\%fil%
if exist %1.\%fil% goto foundbcc
shift
goto recurs1

:trytcc
rem echo Looking for tcc
set rec=02
set fil=tcc.exe
testcomp.bat %path%
goto end

:recurs2
set rec=
rem if "%1"=="" ECHO. %fil% not in current directory or path
if "%1"=="" goto end2
rem echo testing %1\%fil%
if exist %1.\%fil% goto foundtcc
shift
goto recurs2

:foundbcc
genulib.bat bcc
goto end

:foundtcc
genulib.bat tcc
goto end

:end2
set fil=
echo Yer facked!  No suitable compiler found!
echo If you are using DOSBox, shift doesn't appear to work
echo correctly, so you may want to validate manually whether
echo you can find bcc or tcc in your path and then manually
echo call "genulib.bat bcc" or "genulib.bat tcc"

:end
