;
;      Software Link Configuration Utility.  VNA/IONA configuration screen.
;
/MENUID=160
;
;        1         2         3         4         5         6         7         8
;2345678901234567890123456789012345678901234567890123456789012345678901234567890
ษออออ          อออออออออออออออออออออออออออออออออออออออออออออ             ออออออป
บ                                                                              บ
บ   VNA Board #:                        <1>     <2>     <3>     <4>            บ
บ                                                                              บ
บ   I/O Address (hex):                  ___     ___     ___     ___            บ
บ   Interrupt Level:                     __      __      __      __            บ
บ   Install IONA board?                   _       _       _       _            บ
บ                                                                              บ
บ   IONA Board #:                       <1>     <2>     <3>     <4>            บ
บ                                                                              บ
บ   Parallel Port Base Address (hex):   ___     ___     ___     ___            บ
บ   Serial Port Base Address (hex):     ___     ___     ___     ___            บ
บ   Interrupt Level:                     __      __      __      __            บ
บ   Input buffer size (bytes):        _____   _____   _____   _____            บ
บ   Output buffer size (bytes):       _____   _____   _____   _____            บ
บ   Handshake (N,D,X,P,R):                _       _       _       _            บ
บ   Terminal Mode (N,L,R,T):              _       _       _       _            บ
บ   Full Modem Handshake? (Y/N):          _       _       _       _            บ
บ                                                                              บ
บ    ึฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤท    บ
บ    บ Use the arrow keys () to choose a field. Then type in the data บ    บ
บ    บ appropriate to the field.  To get HELP, press F1.  To see options  บ    บ
บ    บ available for the field, press F2.  Press ESC to leave the screen. บ    บ
บ    ำฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฝ    บ
ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
;
;	Standard date and time fields.
;
/field=998, cpos=107, len=8, type=dt, color=11          ;Standard date field.
/field=999, cpos=162, len=11, type=tm, color=10         ;Standard time field.
;
/field=101, cpos=541, len=3, type=hx, color=10          ;Address of VNA #1.
/field=102, cpos=642, len=2, type=u2, color=10          ;Int level, VNA #1.
/field=103, cpos=743, len=1, type=ch, color=10          ;IONA #1 installed?
/field=104, cpos=1141, len=3, type=hx, color=10         ;|| address IONA #1.
/field=105, cpos=1241, len=3, type=hx, color=10         ;S address IONA #1.
/field=106, cpos=1342, len=2, type=u2, color=10         ;Int level IONA #1.
/field=107, cpos=1439, len=5, type=u2, color=10         ;IB IONA #1.
/field=108, cpos=1539, len=5, type=u2, color=10         ;OB IONA #1.
/field=109, cpos=1643, len=1, type=ch, color=10         ;Handshake mode.
/field=110, cpos=1743, len=1, type=ch, color=10         ;Connect mode.
/field=111, cpos=1843, len=1, type=ch, color=10         ;Modem Handshake.
;
/field=201, cpos=549, len=3, type=hx, color=10          ;Address of VNA #2.
/field=202, cpos=650, len=2, type=u2, color=10          ;Int level, VNA #2.
/field=203, cpos=751, len=1, type=ch, color=10          ;IONA #2 installed?
/field=204, cpos=1149, len=3, type=hx, color=10         ;|| address IONA #2.
/field=205, cpos=1249, len=3, type=hx, color=10         ;S address IONA #2.
/field=206, cpos=1350, len=2, type=u2, color=10         ;Int level IONA #2.
/field=207, cpos=1447, len=5, type=u2, color=10         ;IB IONA #2.
/field=208, cpos=1547, len=5, type=u2, color=10         ;OB IONA #2.
/field=209, cpos=1651, len=1, type=ch, color=10         ;Handshake mode.
/field=210, cpos=1751, len=1, type=ch, color=10         ;Connect mode.
/field=211, cpos=1851, len=1, type=ch, color=10         ;Modem Handshake.
;
/field=301, cpos=557, len=3, type=hx, color=10          ;Address of VNA #3.
/field=302, cpos=658, len=2, type=u2, color=10          ;Int level, VNA #3.
/field=303, cpos=759, len=1, type=ch, color=10          ;IONA #3 installed?
/field=304, cpos=1157, len=3, type=hx, color=10         ;|| address IONA #3.
/field=305, cpos=1257, len=3, type=hx, color=10         ;S address IONA #3.
/field=306, cpos=1358, len=2, type=u2, color=10         ;Int level IONA #3.
/field=307, cpos=1455, len=5, type=u2, color=10         ;IB IONA #3.
/field=308, cpos=1555, len=5, type=u2, color=10         ;OB IONA #3.
/field=309, cpos=1659, len=1, type=ch, color=10         ;Handshake mode.
/field=310, cpos=1759, len=1, type=ch, color=10         ;Connect mode.
/field=311, cpos=1859, len=1, type=ch, color=10         ;Modem Handshake.
;
/field=401, cpos=565, len=3, type=hx, color=10          ;Address of VNA #4.
/field=402, cpos=666, len=2, type=u2, color=10          ;Int level, VNA #4.
/field=403, cpos=767, len=1, type=ch, color=10          ;IONA #4 installed?
/field=404, cpos=1165, len=3, type=hx, color=10         ;|| address IONA #4.
/field=405, cpos=1265, len=3, type=hx, color=10         ;S address IONA #4.
/field=406, cpos=1366, len=2, type=u2, color=10         ;Int level IONA #4.
/field=407, cpos=1463, len=5, type=u2, color=10         ;IB IONA #4.
/field=408, cpos=1563, len=5, type=u2, color=10         ;OB IONA #4.
/field=409, cpos=1667, len=1, type=ch, color=10         ;Handshake mode.
/field=410, cpos=1767, len=1, type=ch, color=10         ;Connect mode.
/field=411, cpos=1867, len=1, type=ch, color=10         ;Modem Handshake.
