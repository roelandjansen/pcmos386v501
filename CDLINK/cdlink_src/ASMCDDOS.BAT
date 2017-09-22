erase *.pss
set ps=c:\ps
masm cdlink.asm,,cdlink.lst;
pause
link /m cdlink.obj+executor.obj,cdlink.exe,cdlink.map;
pause
exe2bin cdlink.exe cdlink.dos
erase cdlink.obj
erase cdlink.exe
c:\sys\ps\ts cdlink
rename cdlink.pss big.pss
