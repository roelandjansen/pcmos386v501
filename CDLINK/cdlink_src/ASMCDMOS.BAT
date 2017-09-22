erase *.pss
set ps=c:\ps
masm cdlink.asm,,cdlink.lst;
pause
link /m cdlink.obj,cdlink.exe,cdlink.map;
pause
exe2bin cdlink.exe cdlink.mos
erase cdlink.obj
erase cdlink.exe
c:\sys\ps\ts cdlink
erase cdlink.map
rename cdlink.pss big.pss
