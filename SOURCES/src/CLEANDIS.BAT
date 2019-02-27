echo off
echo Last chance to CTRL-C before cleaning distribution directory
pause

del c:\distro\*.* /y
del c:\distro\base\*.* /y
del c:\distro\mosfiles\*.* /y
del c:\distro\auxfiles\*.* /y
del c:\distro\cdrom\*.* /y

rmdir c:\distro\base
rmdir c:\distro\mosfiles
rmdir c:\distro\auxfiles
rmdir c:\distro\cdrom

rmdir c:\distro

echo Distribution tree clean
