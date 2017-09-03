echo off
biosp %1 %2 %3 -b
if errorlevel 16 goto exit
echo _________  Copying BIOS Pre-Proceesor output file to BIOS.DEF 
if errorlevel 4 goto mainbios
if errorlevel 2 goto diskbios
if errorlevel 1 goto videobios
copy ubios.def bios.def
goto runsr
:mainbios
copy mbios.def bios.def
goto runsr
:diskbios
copy dbios.def bios.def
goto runsr
:videobios
copy vbios.def bios.def
:runsr
echo _________  Loading SOURCER
sr bios.def %1 %2 %3
:exit
