;  Patch number : 2
;  Applicable Product : Emulink v3.1
;  Patch Release Date : 06/02/92
;
;  This patch fixes the 40:17 problem with caps, num and scroll lock
;  DEBUG Emulink.com < e32_p2.pat

e 39b5 e9 48 c8 90 90

e 200  75 0b c6 06 55 03 00 c6 06 5f 03 00 c3 3c 6b 75 
e 210  fb e8 14 8b 50 c6 06 a0 01 00 e8 d5 2e 58 1e bb
e 220  40 00 8e db 3e a2 17 00 b4 01 cd 16 1f c6 06 a0 
e 230  01 01 e8 bd 2e c3


e 994a 59


w
q
