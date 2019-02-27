echo off
echo Last chance to CTRL-C before erasing build files
pause

cd unterm
del *.sys
cd ..

cd ulib
del *.obj
del ulib.lib
del ulib.bak
cd ..

cd import
del *.exe
del *.obj
del *.map
cd ..

cd acu
del *.exe
del *.obj
del *.map
cd ..

cd cutils
del *.exe
del *.obj
del *.map
cd ..

cd latest
del *.sys
del *.exe
del *.com
del *.obj
del *.map
del *.pub
del *.pss
del *.ndx
cd ..

cd cdlink
del *.sys
del *.exe
del *.com
del *.obj
del *.map
del *.pub
cd ..

echo Build files cleaned
