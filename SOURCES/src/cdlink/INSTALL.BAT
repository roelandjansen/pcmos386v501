echo off
cls
echo This batch file will do the following:
echo - Create the directory CDLINK on your C: drive;
echo - Copy the files from drive A: to the C:\CDLINK directory;
echo - Execute the CD-Link "Administrator" program.
echo If this is not what you want, press Ctrl-Break now!
pause
c:
md \cdlink
cd \cdlink
copy a:\cdrom\*.*
admin
