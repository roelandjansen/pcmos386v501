;-----------------------------------------------------------------------; 
; the following statement causes the assembler and linker to respect    ;
; our desire that the data in the gdata, mos, irq and poll segments be  ;
; addressable in the grp group                                          ;
;-----------------------------------------------------------------------;
grp     group   gdata,irq,poll
mos     group   mosseg
mo2	group	ddt
