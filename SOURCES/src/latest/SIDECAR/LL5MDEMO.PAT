;
; This patch is to be applied to the LANSERVE.COM program in
; LANLink 5X Release 2.1 Demo disk for compatibility with PC-MOS Release 5.01
;
;
; To apply this patch, follow these steps:
;
; 1. Change into the directory that contains the file LANSERVE.COM.
;
; 2. Copy the file LL5MDEMO.PAT into that subdirectory.
;
; 3. Enter the following command at the system prompt:
;
;         DEBUG LANSERVE.COM < LL5MDEMO.PAT
;
;    (Make sure that the location of DEBUG.COM is in your
;     path statement, or the DEBUG program won't run.)
;
; This command will automatically load DEBUG, apply the following
; patch for you, and exit DEBUG.
;
;

e cs:3522 90 90 90 90 90 90 90 90
e cs:361c 90 90 90 90 90 90 90 90

w
q
