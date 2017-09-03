	INCLUDE	PAGE.INC
	title	VIDPATCH	Patches Applications to BIOS video calls

;--------------------------------------------------------------------;
;      (C) COPYRIGHT 1984 THE SOFTWARE LINK, INCORPORATED            ;
;                      ALL RIGHTS RESERVED                           ;
;--------------------------------------------------------------------;
;                                                                    ;
;      Modified 10-5-84 D. Morrow to exit with error codes for       ;
;  testing in Batch files with ERRORLEVEL subcommand.  Exit codes    ;
;  are as follows:                                                   ;
;                                                                    ;
;          0 - Requested operation performed without error           ;
;          1 - NOT USED AT PRESENT                                   ;
;          2 - DOS system error                                      ;
;          3 - User error (invalid parameter specified)              ;
;                                                                    ;
;      General purpose scanning routine implemented by Jeffrey S.    ;
;  Weyrich 12/31/85. See description of vidfix table below for in-   ;
;  structions on using the scanner.                                  ;
;                                                                    ;
;      4/1/86 fixed to scan lotus .set files for lotus 2 and symph-  ;
; ony 1.1 to fix any darn thing I tell it. Just build a string and   ;
; set the code to look for it. See the code starting at the label    ;
; PUKE ( yes, that's how I feel about lotus corp. and their products);
; Also added conditional assembly for vidpatch.                      ;
;                                                                    ;
;     9/18/86 S. Hyde Modified PUKE for mode change fixes for Lotus  ;
; 2 and Symphony 1.1.  Since Mode change instructions are so simular ;
; a optimized table search has been added.  This change to PUKE is   ;
; is needed for graphics support.  Does Not alter equiptment flag if ;
; Multilink 4.00 or above.  Also fix bug with lotus vedio addresses  ;
;                                                                    ;
; 2.07 added a flag 0002h to vidfix table to call fakeout routine JSW;
; Also went back to using 100h for an id byte for Lotus 2 / Symphony ;
; and altered PUKE logic for EEh's to nop them out.		     ;
;								     ;
;--------------------------------------------------------------------;
; 9/28/88 RKG fixed bug checking for MultiLink			     ;
;--------------------------------------------------------------------;
; 11/30/89 BWR	Marked messages for foreign language translation.    ;
;--------------------------------------------------------------------;
        include vidpatch.pub

MAINSEG  SEGMENT PARA

         ASSUME CS:MAINSEG,DS:MAINSEG,SS:MAINSEG

TRUE            EQU     1
FALSE           EQU     0
VIDPATCH        EQU     TRUE
MLINT		EQU	7Fh
MLSIGN		EQU	0E9h

         ORG   05CH
FCB      LABEL BYTE
DRIVE    DB    ?             ; DEFAULT DRIVE
FILENAME DB    11 DUP(?)     ; FILENAME & EXTENSION
CURBLOCK DW    ?             ; CURRENT BLOCK
RECSIZE  DW    ?             ; RECORD SIZE
FILESIZE DW    2 DUP(?)      ; FILE SIZE
         DB    12 DUP(?)     ; RESERVED FOR SYSTEM
CURRECNO DB    ?             ; CURRENT RECORD # IN BLOCK
RANRECNO DW    2 DUP(?)      ; RECORD # FOR RANDOM I/O
         ORG   100H
ENTRYPNT LABEL NEAR
         JMP   BEGIN

         PAGE
;--------------------------------------------------------------------;
;  Each supported program has a set of entries in the Patch Table,   ;
;  as follows:                                                       ;
;                                                                    ;
;     30 bytes - Descriptive name                                    ;
;      2 bytes - Offset for identification check                     ;
;      2 bytes - Value  for identification check (do not use 100H)   ;
;      2 bytes - Pointer to next table entry                         ;
;    N*6 bytes - N fields of the following format:                   ;
;         2 bytes - offset to be patched or 0001h to use scanner.    ;
;                   MUST be BEFORE any vidfix offset addresses.      ;
;         2 bytes - value to patch if Foreground or address of code  ;
;                   to scan for. Add the code at the end of pgm.     ;
;         2 bytes - value to patch if Background or the address of   ;
;                   replacement code or 0000h to adjust vidfix addrs ;
;                  or a value of 7777 means to patch in the segment  ;
;                  address of VIDRAM; 0090 is a 1-byte NOP patch     ;
;                  Add replacement code at the end of program        ;
;      6 bytes - FF's to indicate end of patches                     ;
;--------------------------------------------------------------------;
;
;                 --- PATCH HISTORY ---
;
;        RELEASE                  CORRECTION
;
;         1.02               Peachtree Accounting Eagle 2.10
;         1.03               IRMA E78 1.25
;         1.04              [ fixes IRMA for bg  1.04a is for IRMA fg only ]
;         1.04               Volkswriter Deluxe 2.0
;         1.04               REVELATION E
;         1.05               XTALK 3.41  (corrected 8-8-84)
;         1.04               Knowledge Manager 1.06
;         1.04               Excaliber G/L 1.08
;         1.04               PEACHTREE 5000 2.02
;         1.05               Volkswriter Deluxe 2.0 +
;         1.06               CONDOR 2.11 ** 7
;         1.07               FIXES IBM PEACHTEXT MENU/EDIT
;         1.07               WORDSTAR 3.30
;         1.07               VOLKSWRITER DEL 2.1
;         1.07               CONDOR 2.11 ** 8
;         1.07               MULTIPLAN 1.10
;         1.07               Tenkey 1.06
;         1.07               Volkswriter 2.1
;         1.08               Fix Lotus cursor problem
;         1.09               SNA-3270    ??????????
;         1.09               Peachtext 5000 IBM  (fixes patch4)
;                            ... proper placement of patch3b allows patch6
;                            ... to found and executed properly (M.L. 2.08)
;         1.09               Rev (F)
;         1.11               Symphony, PFS:Write, PFS:File
;         1.12               MultiPlan v1.2 for color
;         1.13               SuperCalc 3 v2.0 dated 11-19-84
;
;         1.14               Word Perfect v4.0, Condor **9, Added support
;          4-26-85           for programs larger than 64k (now 32 Meg)
;                            If you want to access the next 64K then set
;                            the offset, and FG/BG values to 0, then use
;                            regular 16 offsets.  In DEBUG just add 1000H to
;                            the segment registers and do additional searches.
;         1.15               MultiMate v3.3
;         1.16               MultiPlan for mono added
;         1.17               IBM Personal Editor, Word Perfect 4.0 dated 3/8/85
;         1.18               WordStar 2000 v. 1.01 Mono/Color Size=164592 (Jeff)
;         1.19               Cross talk 16 v3.5 (Jeff & Dave)
;         1.20               IBM DisplayWrite 3  v1.00 (Jeff)
;         1.21               Open Systems Software Monochrome v1.5 (Jeff)
;         1.22               MBP COBOL v9.0 (Rod)
;         1.23               WordStar 2000 v1.01 Mono/Color Size=164832 (Jeff)
;         1.24               Multimate 3.30 (Jeff)
;         1.24               Condor database v2.11.12 rev level H (Jeff)
;         1.25               Freesytle word processor. (Jeff)
;         1.26               WSCONVRT.EXE for WS2000 (Jeff)
;         1.26               WS2LIST.COM for WS2000 (Jeff)
;         1.26               REVELATION (database) rev G (Jeff)
;         1.26S              SPECIAL VERSION FOR MFCOBOL & SAFEWAY. (Jeff)
;                            RELEASED FOR SAFEWAY 10/3/85. INCLUDED IN 1.27
;         1.27               MFCOBOL v1.1 (Jeff)
;         1.27               SuperCalc 3 v2.1 (Jeff)
;         1.28               Complete MF COBOL v1.1 (Rod)
;         1.28               DW3A0100.PG1 supplemental program for
;                            DisplayWrite 3. (Jeff)
;         1.28-SW            MF COBOL SWDSD10.EXE FOR SAFEWAY -- SPECIAL FIX
;                            NOT IN REGULAR RELEASE.  TEST FOR GREG COLLINS
;                            (Jeff)
;         1.29               Peachtree Accounting v2.3 (Jeff)
;         1.30               InfoStar/StarBurst 1.60/1.02 (Jeff)
;         1.30-SW            SW.EXE & Genterm.com For safeway not released as
;                            regular vidfix (Jeff)
;         1.31               Multimate Advantage v3.5   9 PROGRAMS (Jeff)
;         1.32               Baby/34 v2.30 (Joe) and Smart Software special (Jeff)
;         1.33               General purpose scanner & Lotus 2 monochrome. (JSW)
;         1.33               Symphony 1.1 Monochrome (JSW)
;         1.34               mbpCOBOL v9.0 11/11/85 (JSW)
;         1.35               Lotus 2/symphony 1.1 color .set files (JSW)
;         1.35               dBASE III PLUS Ver 1.0 (JRB)
;         1.36               FINAL fix for that frigging lotus/symphony (JSW)
;         1.37               Norton Editor (JSW)
;         1.38               Volkswriter 3 (JSW & JWO)
;         1.39               PFS Write,Plan & File v. C (JSW)
;         1.40               DisplayWrite (gag-choke) 1.10 (JSW)
;         1.41               CrossTalk v3.6 - 05/06/86 D.A. Morrow
;         1.41               WordStar 2000 rel 2 (JSW) 05/08/86
;         1.41                   "      "   "  " Mailing List Utility (JSW)
;         1.41                   "      "   "  " Document Conversion pgm (jsw)
;         1.41                   "      "   "  " Telmerge.exe (jsw)
;         1.41                   "      "   "  " Index program (jsw)
;         1.42               SuperWriter v1.03 - (JWO & BMW)
;         2.00a              SideKick (jrb)
;         2.01               PFS series write,file,plan,graph,access,report
;         2.03               Fixed Symphony 1.00 bug. It got broke before
;         2.04               Lotus 2.01 (JSW), Microsoft Word v3.0 (JWO)
;         2.04               Norton Editor v1.3 (JSW)
;         2.05               GRAPHICS SUPPORT FOR 4.0 START HERE (SAH)
;         2.05               Lotus 123 1A Graphics Patch (SAH)
;         2.05               Lotus 2.0 / Symphony 1.1 Mode Change Addition (SAH)
;         2.06               PFS:report vB file size 78848 (JSW)
;         2.06               The Twin - a lotus twin (JSW)
;         2.07               Microsoft Word 3.0 (SPELL.COM support) (JWO)
;         2.07               added the fakeout routine (JSW)
;         2.08               Multimate On-File  ver 1.1 (RMW)
;         2.08	      	     Microsoft Word ver 3.0 - German Version (RMW)
;	  2.08		     Added (JWO)'s international Word To main code (RMW)
;			     to keep coherency in the vidfix code. 
;	  2.08		     Wordstar ver 3.40 - German Version (RMW) 
;	  2.08		     Added German Lotus 2.0 to Vidfix screen after 
;			     checking to make sure the PUKE routine fixed it 
;			     (RMW)
;	  2.09	     	     Multimate Advantage 3.60 (RMW)
;         2.09               Microsoft Word 3.10 (JSW)
;         2.09               Correct Link Problems Microsoft Word 3.0 in file (RMW)
;         2.10               Microsoft Word 3.0 Learn.Com (RMW)
;	  2.10               FoxBASE plus single & multiuser
;	  2.11		     Revelation Version G2 (BMW)
;	  2.12               Multimate Advantage 3.60 Universal LAN (BMW)
;         2.12		     Supercalc 4 (BMW) FS=65024
;	  2.12 		     Supercalc 4 (BMW) FS=64256
;         2.13               Multimate Advantage 3.60   fs=302880
;         2.14               Remove links to Microsoft Word 3.0 in order to
;                            take care of the link problems
;
;
;--------------------------------------------------------------------;
;
COPYR  db 13
        IF VIDPATCH
DB'                               VIDPATCH v3.00  (tm)',13,10,10 ;@@XLAT
        ELSE
DB'                                 MLVIDFIX (tm)',13,10,10 ;@@XLAT
DB'                           Direct Video Ram Fix  v2.14',13,10 ;@@XLAT
        ENDIF
DB'             (c) Copyright 1984, 1985, 1986, 1987 The Software Link, Inc.',13,10,10 ;@@XLAT
DB'    ÞßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßÝ',10,13
        IF VIDPATCH
DB'    Þ             THE FOLLOWING PROGRAMS ARE SUPPORTED IN VIDPATCH           Ý',10,13 ;@@XLAT
        ELSE
DB'    Þ              THE FOLLOWING PROGRAMS ARE SUPPORTED IN VIDFIX            Ý',10,13
        ENDIF
DB'    ÞÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÝ',10,10,13
DB'          APPLICATION                   RELEASE           PROGRAM TO PATCH',13,10,10 ;@@XLAT
DB '$'

FILES   DB 13
DB'     Baby/34                             2.30                 RPGRT.EXE',13,10,'$' ;@@XLAT
DB'     Condor (database)  **7, **8, **9    2.11                 DBMS.COM',13,10,'$' ;@@XLAT
DB'     Condor (database)  rev H            2.11.12              DBMS.COM',13,10,'$' ;@@XLAT
DB'     Crosstalk IBM-PC                    3.3, 3.4, 3.41       XTALK.EXE',13,10,'$' ;@@XLAT
DB'     Crosstalk IBM-PC                    3.5, 3.6             XTALK.EXE',13,10,'$' ;@@XLAT
DB'     DataStar                            1.60                 DATASTAR.COM',13,10,'$' ;@@XLAT
DB'     DataStar                            1.60                 REDIT.COM',13,10,'$' ;@@XLAT
DB'     DataStar                            1.60                 RGEN.COM',13,10,'$' ;@@XLAT
DB'     DataStar                            1.60                 REPORT.COM',13,10,'$' ;@@XLAT
DB'     DataStar                            1.60                 FORMGEN.COM',13,10,'$' ;@@XLAT
DB'     dBASE III PLUS                      1.0                  DBA.LD1',13,10,'$' ;@@XLAT
DB'     Excaliber General Ledger            1.8                  GL006891.EXE',13,10,'$' ;@@XLAT
DB'     FoxBASE Plus             fs=250880  1.20                 FOXPLUS.EXE',13,10,'$' ;@@XLAT
DB'     FoxBASE Plus - Multiuser fs=251904  1.21                 MFOXPLUS.EXE',13,10,'$' ;@@XLAT
DB'     Freestyle Word Processor            1.50 -B              FS.EXE',13,10,'$' ;@@XLAT
DB'     IBM DisplayWrite 3                  1.00                 DW3PG.COM',13,10,'$' ;@@XLAT
DB'     IBM DisplayWrite 3                  1.00                 DW3A0100.PG1',13,10,'$' ;@@XLAT
DB'     IBM DisplayWrite 3                  1.10                 DW3PG.COM',13,10,36 ;@@XLAT
DB'     IBM Peachtext                       2.00                 MENU.PSI',13,10,'$' ;@@XLAT
DB'     IBM Peachtext                       2.00                 EDIT.PSI',13,10,'$' ;@@XLAT
DB'     IRMA E78                            1.25                 E78.EXE',13,10,'$' ;@@XLAT
DB'     Knowledge Manager (sp)  color/bw    1.06, 1.07           KTERM.TRM',13,10,'$' ;@@XLAT
DB'     Lotus 1A Mono, Color/B&W            1A                   TD.DRV',13,10,'$' ;@@XLAT
DB'     Lotus 1A Graphics                   1A                   GD.DRV',13,10,'$' ;@@XLAT
DB'     Lotus 2 Mono/Color                  2, 2.01              123.SET',13,10,'$' ;@@XLAT
DB'     MBP COBOL                           9.0                  MBPSIM.EXE',13,10,'$' ;@@XLAT
DB'     MBP COBOL                           9.0 dated 11/11/85   MBPSIM.EXE',13,10,'$' ;@@XLAT
DB'     MF COBOL                            1.1 dated 1/9/85     .COM & .EXE files',13,10,'$' ;@@XLAT
DB'     Microsoft Word - Learn Program      3.0                  LEARN.COM',13,10,'$' ;@@XLAT
if	VIDPATCH
DB'     Microsoft Word                      3.1                  WORD.COM',13,10,36 ;@@XLAT
DB'     Microsoft Word                      3.1                  SPELL.COM',13,10,36 ;@@XLAT
DB'     Microsoft Word - German Version     3.0                  WORD.COM',13,10,36 ;@@XLAT
DB'     Microsoft Word - International Ver. 3.0                  WORD.COM',13,10,36 ;@@XLAT
endif
DB'     Multimate                           3.20,3.22,3.3,3.30   WP.EXE',13,10,'$' ;@@XLAT
DB'     Multimate Advantage                 3.50,3.60            WP.EXE',13,10,'$' ;@@XLAT
DB'     Multimate Advantage                 3.50,3.60            MM.EXE',13,10,'$' ;@@XLAT
DB'     MultiMate Advantage                 3.50,3.60            UTIL.EXE',13,10,'$' ;@@XLAT
DB'     MultiMate Advantage - Universal LAN  ver 3.60            WP.EXE',13,10,'$' ;@@XLAT
DB'     Multimate Advantage                 3.60  fs=302880      WP.EXE',13,10,'$' ;@@XLAT
DB'     Multimate On-File                   1.00                 ONFILE.EXE',13,10,'$' ;@@XLAT
DB'     Multimate On-File                   1.10                 ONFILE.EXE',13,10,'$' ;@@XLAT
DB'     Multimate On-File                   1.00,1.10            OFUT.EXE',13,10,'$' ;@@XLAT
DB'     Multimate On-File                   1.00,1.10            OFUTXXX1.EXE',13,10,'$' ;@@XLAT
DB'     Multimate On-File                   1.00,1.10            OFUTXXX2.EXE',13,10,'$' ;@@XLAT
DB'     Multimate On-File                   1.00,1.10            OFUTXXX3.EXE',13,10,'$' ;@@XLAT
DB'     Multimate On-File                   1.00,1.10            SAVEBOX.EXE',13,10,'$' ;@@XLAT
DB'     Multiplan (Microsoft)               1.10, 1.2            MP.COM',13,10,'$' ;@@XLAT
DB'     Norton Editor                       1.2, 1.3             NE.COM',13,10,36 ;@@XLAT
DB'     Open Systems Software               1.34b, 1.34e & 1.5   TTABLE.286',13,10,'$' ;@@XLAT
DB'     Peachtext 5000                      2.01                 PT.EXE ',13,10,'$' ;@@XLAT
DB'     Peachtext 5000 IBM, Eagle           2.10                 PT.EXE',13,10,'$' ;@@XLAT
DB'     Peachtree Accounting / Compaq       2.10 & 2.20          PEACH.EXE',13,10,'$' ;@@XLAT
DB'     Peachtree Accounting / Eagle        2.10                 PEACH.EXE',13,10,'$' ;@@XLAT
DB'     Peachtree Accounting                2.3                  PEACH.EXE',13,10,'$' ;@@XLAT
DB'     Personal Editor (IBM)               1.00                 PE.EXE',13,10,'$' ;@@XLAT
DB'     PFS:File                            1.00,B,C             FILE.EXE',13,10,'$' ;@@XLAT
DB'     PFS:Write                           1.00                 WRITE.EXE',13,10,'$' ;@@XLAT
DB'     PFS:Write                           B,C & C fs=167552    WRITEDB.BJB',13,10,36 ;@@XLAT
DB'     PFS:Plan                            B,C                  PLANAJR.EXE',13,10,36 ;@@XLAT
DB'     PFS:Access                          C                    ACCESS.PCJ',13,10,36 ;@@XLAT
DB'     PFS:Graph                           B                    GRAPH.EXE',13,10,36 ;@@XLAT
DB'     PFS:Report                          B fs=78402           REPORT.EXE',13,10,36 ;@@XLAT
DB'     PFS:Report                          B fs=78848           REPORT.EXE',13,10,36 ;@@XLAT
DB'     Revelation (relational database)    D, E, F, G           REV.EXE',13,10,'$' ;@@XLAT
DB'     Revelation (relational database)    G2      fs=76158     REV.EXE',13,10,'$' ;@@XLAT
DB'     SideKick                            1.56A                SK.COM',13,10,'$' ;@@XLAT
DB'     StarBurst                           1.02                 SB.OVR',13,10,'$' ;@@XLAT
DB'     SuperCalc II Color                  1.00                 SC2.COM',13,10,'$' ;@@XLAT
DB'     SuperCalc III Color                 1.00                 SC3.COM',13,10,'$' ;@@XLAT
DB'     SuperCalc III ** 11/19/84 **        2.00                 SC3.COM',13,10,'$' ;@@XLAT
DB'     SuperCalc III                       2.1                  SC3.COM',13,10,'$' ;@@XLAT
DB'     SuperCalc IV      FS = 65024        1.0                  SC4.COM',13,10,'$' ;@@XLAT
DB'     SuperCalc IV      FS = 64256        1.0                  SC4.COM',13,10,'$' ;@@XLAT
DB'     SuperWriter                         1.03                 SW.COM',13,10,'$' ;@@XLAT
if	VIDPATCH
DB'     Symphony (Mono)                     1.00                 LOTUS.SET',13,10,'$' ;@@XLAT
db'     Symphony                            1.1                  LOTUS.SET',13,10,36 ;@@XLAT
else
DB'     Symphony                            1.0, 1.1             LOTUS.SET',13,10,'$' ;@@XLAT
endif
DB'     Tenkey                              1.06                 TENKEY.EXE',13,10,'$' ;@@XLAT
db'     The Twin (Mono/Color)               1.30                 TWIN.EXE',13,10,36 ;@@XLAT
db'     The Twin Color-Graphics             1.30                 CGA.DRV',13,10,36 ;@@XLAT
DB'     Volkswriter Deluxe                  2.0, 2.1             VX.EXE',13,10,'$' ;@@XLAT
DB'     Volkswriter Deluxe +                2.0                  VX.EXE',13,10,'$' ;@@XLAT
DB'     Volkswriter 3                       1.0                  VW3.EXE',13,10,36 ;@@XLAT
;DB'     Word Perfect  2/4/85, 3/8/85        4.0                  WP.EXE',13,10,'$' ;@@XLAT
DB'     WordStar                            3.30                 WS.COM',13,10,'$' ;@@XLAT
DB'     WordStar - German                   3.40 - 1.0           WS.COM',13,10,'$'  ;@@XLAT
DB'     WordStar 2000 Mono/Color            1.01  Size=164592    WS2000.EXE',13,10,'$' ;@@XLAT
DB'     WordStar 2000 Mono/Color            1.01  Size=164832    WS2000.EXE',13,10,'$' ;@@XLAT
DB'     WordStar 2000 File Conversion Utility                    WSCONVRT.EXE',13,10,'$' ;@@XLAT
DB'     WordStar 2000 Mailing List Utiilty                       WS2LIST.COM',13,10,'$' ;@@XLAT
DB'       The following WordStar programs are for WordStar 2000 rel 2',13,10,36 ;@@XLAT
DB'     WordStar 2000 Mono/Color            2.00                 WS2.EXE',13,10,36 ;@@XLAT
DB'     WordStar 2000 Mailing List Utility  1.01                 WS2LIST.COM',13,10,36 ;@@XLAT
;DB'     WordStar 2000 File Conversion Utility                    CONVERT.EXE',13,10,36 ;@@XLAT
DB'     WordStar 2000 Rel. 2 Communications program              TELMERGE.EXE',13,10,36 ;@@XLAT
DB'     WordStar 2000 Indexing program                           WS2INDEX.EXE',13,10,36 ;@@XLAT

DB 0	; END OF FILE LIST

CONT   DB 13,10
DB'                           PRESS ANY KEY TO CONTINUE'
DB '$'
;-----------------------------------------------------------------------------;
PATCHTAB LABEL WORD
         DB    'Lotus 1A Monochrome Driver    ' ;@@XLAT
         DW    0100H,002E9H,PATCH
         DW    01D5H,0B000H,7777H
         DW    01E3H,0B000H,7777H
         DW    01F0H,0B000H,7777H
         DW    0203H,0B000H,7777H
         DW    0211H,0B000H,7777H
         DW    0222H,0B000H,7777H
         DW    023FH,0B000H,7777H
         DW    025CH,0B000H,7777H
         DW    02C1H,0B000H,7777H
         DW    031DH,0B000H,7777H
         DW    0382H,0B000H,7777H
         DW    03C9H,0B000H,7777H
         DW    03DAH,0B000H,7777H

         DW    0277H,050B8H,0D588H  ; REPL CURSOR ACCESS WITH BIOS CALL
         DW    0279H,0F700H,05756H
         DW    027BH,003E2H,05355H
         DW    027DH,0BAC8H,002B4H
         DW    027FH,003B4H,0CA89H
         DW    0281H,00EB0H,0DB31H
         DW    0283H,042EEH,010CDH
         DW    0285H,0C58AH,05D5BH
         DW    0287H,04AEEH,05E5FH
         DW    0289H,00FB0H,090CBH

         DW    034FH,061E6H,9090H
         DW    0358H,061E6H,9090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH    LABEL WORD
         DB    'Lotus 1A Color/B&W Driver     ' ;@@XLAT
         DW    017BH,01430H,PATCHG
         DW    1145H,0A8ECH,0A8C3H

         DW    1393H,050B8H,0D588H  ; REPL CURSOR ACCESS WITH BIOS CALL
         DW    1395H,0F700H,05756H
         DW    1397H,003E2H,05355H
         DW    1399H,0BAC8H,002B4H
         DW    139BH,003D4H,0CA89H
         DW    139DH,00EB0H,0DB31H
         DW    139FH,042EEH,010CDH
         DW    13A1H,0C58AH,05D5BH
         DW    13A3H,04AEEH,05E5FH
         DW    13A5H,00FB0H,090CBH

         DW    1489H,061E6H,9090H
         DW    1492H,061E6H,9090H
         DW    149DH,061E6H,9090H
         DW    14BEH,000EEH,0090H
         DW    14D8H,0B800H,7777H
         DW    14F3H,000EEH,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCHG   LABEL WORD
         DB    'Lotus 1A Graphics Driver      ' ;@@XLAT
         DW    0011CH,07247H,PATCH0
         DW    001A7H,0B800H,07777H
         DW    00675H,0B800H,07777H
         DW    00749H,0B800H,07777H
         DW    0077DH,0B800H,07777H
         DW    007EFH,0B800H,07777H
         DW    00936H,0B800H,07777H
         DW    00186H,01EEBH,01EEBH
         DW    001B7H,002B8H,002B8H
         DW    001B9H,08000H,08000H
         DW    001BBH,000FBH,000FBH
         DW    001BDH,00275H,00275H
         DW    001BFH,006B0H,006B0H
         DW    001C1H,010CDH,010CDH
         DW    001C3H,0CBCBH,0CBCBH
         DW    0FFFFH,0FFFFH,0FFFFH

PATCH0   LABEL WORD
         DB    'Word Perfect                  ' ;@@XLAT
         DW    00430H,02ab8H,PATCH0B
         DW    00473H,0B800H,7777H
         DW    004acH,0B000H,7777H
         DW    0FFFFH,0FFFFH,0FFFFH

PATCH0B  LABEL WORD
         DB    'Word Perfect v4.0  2/4/85     ' ;@@XLAT
         DW    00270H,0191AH,PATCH0C
         DW    02BF0H,0B000H,7777H
         DW    02BFEH,0FB75H,9090H
         DW    02C04H,0FB74H,9090H
         DW    00000H,00000H,0000H            ;2 All of the rest are in
         DW    0985BH,0B000H,7777H            ; next 64k
         DW    0982AH,0B800H,7777H
         DW    0FFFFH,0FFFFH,0FFFFH

PATCH0C  LABEL WORD
         DB    'Word Perfect v4.0  3/8/85     ' ;@@XLAT
         DW    00580H,08A0DH,PATCH1
         DW    02C47H,0B000H,7777H
         DW    02C55H,0FB75H,9090H
         DW    02C5BH,0FB74H,9090H
         DW    00000H,00000H,0000H            ;2 All of the rest are in
         DW    097BBH,0B000H,7777H            ; next 64k
         DW    0978AH,0B800H,7777H
         DW    0FFFFH,0FFFFH,0FFFFH


PATCH1   LABEL WORD
         DB    'SuperCalc III V1.00 COLOR     ' ;@@XLAT
         DW   101H,9340H,PATCH1A
         DW   996FH,0B800H,7777H
         DW   99EDH,0B800H,7777H
         DW   9A65H,000EEH,0090H
         DW   9A57H,000EEH,0090H
         DW   1FD0H,000EEH,0090H
         DW   1FF1H,000EEH,0090H
         DW   1FF8H,000EEH,0090H
         DW   2006H,000EEH,0090H
         DW   200EH,000EEH,0090H
         DW   203CH,000EEH,0090H
         DW   2044H,000EEH,0090H
         DW   45ABH,000EEH,0090H
         DW   1EEFH,0FB75H,9090H
         DW   1EF5H,0FB74H,9090H
         DW   1EFEH,0FB75H,9090H
         DW   1F04H,0FB74H,9090H
         DW   1F18H,0FB75H,9090H
         DW   1F1EH,0FB74H,9090H
         DW   0FFFFH,0FFFFH,0FFFFH


PATCH1A   LABEL WORD
         DB    'SuperCalc II  V1.00 COLOR     ' ;@@XLAT
         DW   101H,7B00H,PATCH2
         DW   808AH,0B800H,7777H
         DW   80DEH,000EEH,0090H
         DW   80D0H,000EEH,0090H
         DW   72BCH,000EEH,0090H
         DW   72DDH,000EEH,0090H
         DW   72E4H,000EEH,0090H
         DW   72EBH,000EEH,0090H
         DW   72F2H,000EEH,0090H
         DW   72FAH,000EEH,0090H
         DW   7302H,000EEH,0090H
         DW   730AH,000EEH,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH2	 LABEL WORD
;     This is the Vidfix for the SC4 file with the filesize  65024 (BMW)
	 DB    'SuperCalc IV Ver 1.0  fs=65024' ;@@XLAT
	 DW   	0C84CH,07553H,PATCH2a
	 DW	03112H,0B800H,07777H
	 DW  	035A1H,0FB75H,09090H
	 DW  	035A7H,0FB74H,09090H
	 DW  	035BBH,0FB75H,09090H
	 DW  	035C1H,0FB74H,09090H
	 DW	036F6H,000EEH,00090H
	 DW	03712H,000EEH,00090H
	 DW	06B1CH,0B000H,07777H
	 DW  	0B5BFH,0FB75H,09090H
	 DW  	0B5C5H,0FB74H,09090H
	 DW	0D62CH,000EEH,00090H
	 DW	0D62FH,000EEH,00090H
	 DW	0D632H,000EEH,00090H
	 DW	0D635H,000EEH,00090H
	 DW  	0DA0FH,0FB75H,09090H
	 DW  	0DA15H,0FB74H,09090H
	 DW  	0DA2FH,0FB75H,09090H
	 DW  	0DA35H,0FB74H,09090H
	 DW	0EE77H,0B000H,07777H
	 DW	0EE9CH,0B800H,07777H
	 DW	0F0CCH,0B800H,07777H
	 DW     0FFFFH,0FFFFH,0FFFFH

PATCH2a	 LABEL WORD
;     This is the Vidfix for the SC4 file with the filesize  64256 (BMW)
	 DB    'SuperCalc IV Ver 1.0  fs=64256' ;@@XLAT
	 DW   0C822H,07553H,PATCH3
	 DW   03093H,0B800H,07777H
	 DW   03548H,0FB75H,09090H
	 DW   0354EH,0FB74H,09090H
	 DW   03562H,0FB75H,09090H
	 DW   03568H,0FB74H,09090H
	 DW   0369DH,000EEH,00090H
	 DW   036B9H,000EEH,00090H
	 DW   06AD2H,0B000H,07777H
	 DW   0AF8AH,0B000H,07777H
	 DW   0B60CH,0FB75H,09090H
	 DW   0B612H,0FB74H,09090H
	 DW   0D5FFH,000EEH,00090H
	 DW   0D602H,000EEH,00090H
	 DW   0D605H,000EEH,00090H
	 DW   0D608H,000EEH,00090H
	 DW   0D9E2H,0FB75H,09090H
	 DW   0D9E8H,0FB74H,09090H
	 DW   0DA02H,0FB75H,09090H
	 DW   0DA08H,0FB74H,09090H
	 DW   0EB77H,0B000H,07777H
	 DW   0EB9CH,0B800H,07777H
	 DW   0EDCCH,0B800H,07777H

	 DW   0AF5FH,0B000H,07777H
	 DW   0AF7DH,0B000H,07777H
	 DW   0AFC2H,0B000H,07777H
	 DW   0AFBDH,0B000H,07777H
	 DW   0D76FH,0B000H,07777H
	 DW   0D780H,0B000H,07777H

	 DW   0FFFFH,0FFFFH,0FFFFH


PATCH3   LABEL WORD
         DB    'Peachtext 5000 version 2.01   ' ;@@XLAT
         DW   3541H,049BH,PATCH3a
         DW   3548H,0B000H,7777H
         DW   355AH,0B800H,7777H
         DW   94E5H,000EEH,0090H
         DW   98E5H,000EEH,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH3A  LABEL WORD
         DB    'Peachtext 5000 version 2.02   ' ;@@XLAT
         DW    03566H,09E04H,PATCH3b
         DW    03568H,00B00H,7777H
         DW    0357AH,0B800H,7777H
         DW    0359BH,000EEH,0090H
         DW    035AEH,000EEH,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH3b  LABEL WORD
         DB    'Peachtext 5000 IBM     2.10   ' ;@@XLAT
         DW    3561H,0049BH,PATCH4
         DW    3303H,0FB74H,9090H
         DW    330AH,000EEH,0090H
         DW    331DH,000EEH,0090H
         DW    3360H,0FB74H,9090H
         DW    3384H,0FB74H,9090H
         DW    33F9H,0FB75H,9090H    ;RR 11/02/84
         DW    33FFH,0FB74H,9090H
         DW    347FH,0FB74H,9090H
         DW    3486H,000EEH,0090H
         DW    3496H,000EEH,0090H
         DW    34F2H,0FB74H,9090H
         DW    34F9H,000EEH,0090H
         DW    350CH,000EEH,0090H
         DW    353FH,0FB74H,9090H
         DW    3546H,000EEH,0090H
         DW    3559H,000EEH,0090H
         DW    355BH,00FB4H,02B0H    ;RR 11/02/84
         DW    355DH,010CDH,9090H    ;RR 11/02/84
         DW    3568H,0B000H,7777H
         DW    357AH,0B800H,7777H
         DW    3594H,0FB74H,9090H
         DW    359BH,000EEH,0090H
         DW    359FH,010CDH,9090H    ;RR 11/02/84
         DW    35AEH,000EEH,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH4   LABEL WORD
         DB    'Peachtree Acct. / Compaq 2.20 ' ;@@XLAT
         DW    330dH,0f307H,PATCH5
         DW    35AEH,000EEH,0090H
         DW    35ACH,000EEH,0090H
         DW    330AH,000EEH,0090H
         DW    331DH,000EEH,0090H
         DW    3496H,000EEH,0090H
         DW    34F9H,000EEH,0090H
         DW    350CH,000EEH,0090H
         DW    3546H,000EEH,0090H
         DW    3559H,000EEH,0090H
         DW    359BH,000EEH,0090H
         DW    3568H,0B000H,7777H
         DW    357AH,0B800H,7777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH5   LABEL WORD
         DB    'Revelation release (D)        ' ;@@XLAT
         DW    04B3H,00475H,PATCH5a
         DW    04AEH,0B800H,7777H
         DW    04C5H,0B000H,7777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH5a  LABEL WORD
         DB    'Revelation release (E)        ' ;@@XLAT
         dw    09119h,006dbh,patch5b
         dw    09138h,0b000h,7777h
         dw    09123h,0b800h,7777h
         dw    0936fh,0b000h,7777h
         dw    09358h,0b800h,7777h
         dw   0ffffh,0ffffh,0ffffh

PATCH5b  LABEL WORD
         DB    'Revelation release (F)        ' ;@@XLAT
         dw    099a0h,00422h,patch5C
         dw    099a2h,0b000h,7777h
         dw    099adh,0b800h,7777h
         dw    09bc8h,0b800h,7777h
         dw    09be0h,0b000h,7777h
         dw    09d39h,000eeh,0090h
         dw    09f3ah,000eeh,0090h
         dw    09f5bh,000eeh,0090h
         dw    0a115h,000eeh,0090h
         dw    0a182h,000eeh,0090h
         dw   0ffffh,0ffffh,0ffffh

PATCH5C LABEL WORD
        DB      'Revelation release (G)        ' ;@@XLAT
        DW      00362H,0068CH,PATCH5D
        DW      087F7H,0B000H,7777H
        DW      08AFFH,0B000H,7777H
        DW      08802H,0B800H,7777H
        DW      08AE8H,0B800H,7777H
        DW      08BD2H,0FB75H,9090H
        DW      08BD8H,0FB74H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH5D LABEL WORD
        DB      'Revelation release (G2)       ' ;@@XLAT
        DW      009B9H,03247H,PATCH6
        DW      08DABH,0B000H,7777H
        DW      08DB6H,0B800H,7777H
        DW      090A8H,0B800H,7777H
        DW      090BFH,0B000H,7777H
        DW      09192H,0FB75H,9090H
        DW      09198H,0FB74H,9090H
        DW      092B0H,000EEH,0090H
        DW      094C4H,000EEH,0090H
        DW      094E5H,000EEH,0090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH6   LABEL WORD
         DB    'Peachtree Acct. / Compaq 2.10 ' ;@@XLAT
         DW    354DH,010CDH,PATCH6a
         DW    32FAH,000EEH,0090H
         DW    330DH,000EEH,0090H
         DW    3476H,000EEH,0090H
         DW    3486H,000EEH,0090H
         DW    34E9H,000EEH,0090H
         DW    34FCH,000EEH,0090H
         DW    3536H,000EEH,0090H
         DW    3549H,000EEH,0090H
         DW    3558H,0B000H,7777H
         DW    356AH,0B800H,7777H
         DW    358BH,000EEH,0090H
         DW    359EH,000EEH,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH6a  LABEL WORD
         DB    'Peachtree Accounting / Eagle  ' ;@@XLAT
         DW    3557H,1074H,PATCH6b
         DW    3169H,000EEH,0090H
         DW    317AH,000EEH,0090H
         DW    32D9H,000EEH,0090H
         DW    32F2H,000EEH,0090H
         DW    345EH,000EEH,0090H
         DW    346EH,000EEH,0090H
         DW    34D1H,000EEH,0090H
         DW    3524H,000EEH,0090H
         DW    353DH,000EEH,0090H
         DW    354CH,0B000H,0090H
         DW    355EH,0B800H,7777H
         DW    357FH,000EEH,0090H
         DW    3592H,000EEH,0090H
         DW    32D2H,0FB74H,9090H
         DW    3335H,0FB74H,9090H
         DW    3359H,0FB74H,9090H
         DW    33CEH,0FB75H,9090H
         DW    3457H,0FB74H,9090H
         DW    34CAH,0FB74H,9090H
         DW    351DH,0FB74H,9090H
         DW    3578H,0FB74H,9090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH6b LABEL WORD
        DB      'Peachtree Accounting v2.3     ' ;@@XLAT
        DW      03305H,0FF33H,PATCH7
        DW      03318H,0FB74H,9090H
        DW      0331FH,000EEH,0090H
        DW      0333DH,000EEH,0090H
        DW      03380H,0FB74H,9090H
        DW      033A4H,0FB74H,9090H
        DW      0341FH,0FB75H,9090H
        DW      03424H,0FB74H,9090H
        DW      034B3H,0FB74H,9090H
        DW      034BAH,000EEH,0090H
        DW      034CAH,000EEH,0090H
        DW      03526H,0FB74H,9090H
        DW      0352DH,000EEH,0090H
        DW      03544H,000EEH,0090H
        DW      03577H,0FB74H,9090H
        DW      0357EH,000EEH,0090H
        DW      03595H,000EEH,0090H
        DW      035A4H,0B000H,7777H
        DW      035B6H,0B800H,7777H
        DW      035D0H,0FB74H,9090H
        DW      035D7H,000EEH,0090H
        DW      035DFH,000EEH,0090H
        DW      035F2H,000EEH,0090H
        DW      03608H,000EEH,0090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH7   LABEL WORD
         DB    'IBM Peachtext 2.0 MENU.PSI    ' ;@@XLAT
         DW   01D72H,010CDH,PATCH7B
         DW   01D80H,0B000H,7777H
         DW   01D88H,0B800H,7777H
         DW   0209EH,0B000H,7777H
         DW   020B6H,0B800H,7777H
         DW   020B4H,000EEH,0090H
         DW   02144H,000EEH,0090H
         DW   0216BH,043E6H,9090H
         DW   0216FH,042E6H,9090H
         DW   02173H,042E6H,9090H
         DW   0217BH,061E6H,9090H
         DW   02184H,061E6H,9090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH7B  LABEL WORD
         DB    'IBM Peachtext 2.0 EDIT.PSI    ' ;@@XLAT
         DW   07215H,010CDH,PATCH8
         DW   07223H,0B014H,7777H
         DW   07225H,01274H,9090H
         DW   07227H,006C7H,0681H
         DW   0722BH,0B814H,0014H
         DW   048CCH,000EEH,0090H
         DW   05096H,000EEH,0090H
         DW   06FFDH,000EEH,0090H
         DW   0700FH,000EEH,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH8   LABEL WORD
         DB    'Multimate release 3.20        ' ;@@XLAT
         DW   00306H,050BCH,PATCH9
         DW   0D129H,0B000H,7777H
         DW   0D132H,0B800H,7777H
         DW   0D15BH,0B000H,7777H
         DW   0D181H,0B000H,7777H
         DW   0D1D9H,061E6H,9090H
         DW   0D1E2H,061E6H,9090H
         DW   0D1EDH,061E6H,9090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH9   LABEL WORD
         DB    'Open Systems Mono 1.34b,e 1.5 ' ;@@XLAT
         DW    010CH,00202H,PATCH10
         DW    010EH,0B000H,7777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH10  LABEL WORD
         DB    'Open Systems Color  1.34b & e ' ;@@XLAT
         DW    010CH,00302H,PATCH11
         DW    010EH,0B800H,7777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH11  LABEL WORD
         DB    'Volkswriter Ver. 1.2          ' ;@@XLAT
         DW    1500H,05500H,PATCH11A
         DW    27F5H,0B000H,7777H
         DW    1C1FH,0B800H,7777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH11A LABEL WORD
         DB    'Volkswriter Deluxe Ver. 2.00  ' ;@@XLAT
         DW    3F3DH,0C08EH,PATCH11B              ; UNASSEMBLE  3C3AH ...
         DW    3F3AH,01AA1H,1AB8H                 ; CHG TO IMMEDIATE MOV
         DW    3F3BH,0241AH,7777H                 ; OF SCREEN ADDRESS
         DW    3F49H,00674H,9090H                 ; PLUG IN 5 NOPS
         DW    3F4BH,00035H,9090H
         DW    3F4DH,0A308H,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH11B LABEL WORD
         DB    'Volkswriter Deluxe Ver. 2.00+ ' ;@@XLAT
         DW    3CFAH,0C08EH,PATCH12               ; UNASSEMBLE  3CF7H ...
         DW    3CF7H,03AA1H,1AB8H                 ; CHG TO IMMEDIATE MOV
         DW    3CF8H,0233AH,7777H                 ; OF SCREEN ADDRESS
         DW    3D06H,00674H,9090H                 ; PLUG IN 5 NOPS
         DW    3D08H,00035H,9090H
         DW    3D0AH,0A308H,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH12  LABEL WORD
         DB    'XTALK IBM-PC Ver. 3.3         ' ;@@XLAT
         DW    0C959H,03333H,PATCH13
         DW    6034H,0B000H,7777H
         DW    6041H,0B800H,7777H
         DW    6553H,0A8ECH,0AEBH
         DW    660CH,0A8ECH,09EBH
         DW    662EH,0A8ECH,09EBH
         DW    66ECH,061E6H,9090H
         DW    66F5H,061E6H,9090H
         DW    6740H,061E6H,9090H
         DW    674EH,061E6H,9090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH13  LABEL WORD
         DB    'XTALK IBM-PC Ver. 3.4         ' ;@@XLAT
         DW    0CFE5H,03034H,PATCH13A
         DW    6558H,0B000H,7777H
         DW    6565H,0B800H,7777H
         DW    6B30H,084ECH,09EBH
         DW    6B52H,084ECH,09EBH
         DW    6C10H,061E6H,9090H
         DW    6C19H,061E6H,9090H
         DW    6C64H,061E6H,9090H
         DW    6C72H,061E6H,9090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH13A LABEL WORD
         DB    'XTALK IBM-PC Ver. 3.41        ' ;@@XLAT
         DW    06CE0H,0D8BAH,PATCH14
         DW    065AFH,0B800H,7777H
         DW    0659FH,0B000H,7777H
         DW    06B68H,0A8ECH,09EBH
         DW    06B46H,0A8ECH,09EBH
         DW    06B27H,0A8ECH,09EBH
         DW    06DE6H,061E6H,9090H
         DW    06DD8H,061E6H,9090H
         DW    06D8DH,061E6H,9090H
         DW    06D84H,061E6H,9090H
         DW    06D6DH,000EEH,0090H
         DW    06D5AH,000EEH,0090H
         DW    06CE5H,000EEH,0090H
         DW    06CC3H,000EEH,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH14  LABEL WORD
         DB    'PeachText 5000 Ver. 2.1 EAGLE ' ;@@XLAT
         DW    00553H,03530H,PATCH15
         DW    32E2H,0FB74H,9090H
         DW    3345H,0FB74H,9090H
         DW    3369H,0FB74H,9090H
         DW    33DEH,0FB75H,9090H
         DW    33E4H,0FB74H,9090H
         DW    3467H,0FB74H,9090H
         DW    34DAH,0FB74H,9090H
         DW    352DH,0FB74H,9090H
         DW    3588H,0FB74H,9090H
         DW    32E9H,000EEH,0090H
         DW    3302H,000EEH,0090H
         DW    346EH,000EEH,0090H
         DW    347EH,000EEH,0090H
         DW    34E1H,000EEH,0090H
         DW    34FAH,000EEH,0090H
         DW    3534H,000EEH,0090H
         DW    354DH,000EEH,0090H
         DW    358FH,000EEH,0090H
         DW    35A2H,000EEH,0090H
         DW    355CH,0B000H,7777H
         DW    356EH,0B800H,7777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH15  LABEL WORD
         DB    'MULTIMATE Release 3.22        ' ;@@XLAT
         DW    0306H,090BCH,PATCH15a
         DW    0D50DH,0B000H,7777H
         DW    0D516H,0B800H,7777H
         DW    0D583H,0B000H,7777H
         DW    0D5CBH,0B000H,7777H
         DW    0D65AH,0B000H,7777H
         DW    0D74CH,0B000H,7777H
         DW    0D6ABH,061E6H,9090H
         DW    0D6B4H,061E6H,9090H
         DW    0D6BFH,061E6H,9090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH15a LABEL WORD
         DB    'MULTIMATE Release 3.3         ' ;@@XLAT
         DW    00555H,00E3DH,PATCH16
         DW    0FA8AH,0B000H,7777H
         DW    0FA99H,0B800H,7777H
         DW    0FB84H,0B000H,7777H
         DW    0FBB9H,0B000H,7777H
         DW    0FCCDH,0B000H,7777H
         DW    0FDD6H,0B000H,7777H
         DW    0FD2FH,061E6H,9090H
         DW    0FD38H,061E6H,9090H
         DW    0FD43H,061E6H,9090H
         DW    0FD57H,000EEH,0090H
         DW    0FD6AH,000EEH,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH16  LABEL WORD
         DB    'EXCALIBER General Ledger      ' ;@@XLAT
         DW    2333H,0AF2H,PATCH17
         DW    232BH,0B800H,7777H
         DW    5004H,0B800H,7777H
         DW    4FD9H,0B000H,7777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH17  LABEL WORD
         DB    'KNOWLEDGEMAN -- COLOR         ' ;@@XLAT
         DW    0119H,0201FH,PATCH18
         DW    01AEH,0B800H,07777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH18  LABEL WORD
         DB    'KNOWLEDGEMAN -- MONO          ' ;@@XLAT
         DW    0119H,0201BH,PATCH19
         DW    01AEH,0B000H,07777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH19  LABEL WORD
         DB    'CONDOR (database) 2.11 ** 7   ' ;@@XLAT
         DW    0494H,093b9H,PATCH20
         DW    0471H,0B800H,07777H
         DW    0496H,0B000H,07777H
         DW    04A3H,0B800H,07777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH20  LABEL WORD
         DB    'WordStar v3.30                ' ;@@XLAT
         DW    4FA6H,040B8H,PATCH20b
         DW    2A51H,0FB74H,9090H
         DW    2A58H,000EEH,0090H
         DW    2A5FH,000EEH,0090H
         DW    2ACAH,0FB75H,9090H
         DW    2AD0H,0FB74H,9090H
         DW    2AF3H,0FB74H,9090H
         DW    2AFAH,000EEH,0090H
         DW    2AFFH,000EEH,0090H
         DW    4FAEH,0B800H,07777H
         DW    4FBEH,0B000H,07777H
         DW    0FFFFH,0FFFFH,0FFFFH

PATCH20a LABEL WORD
         DB    'WordStar  release 4.0         ' ;@@XLAT
	 DW    007E7H,03420H,PATCH20b
	 DW    0123FH,0B800H,07777H
	 DW    0122FH,0B000H,07777H
	 DW    01AE1H,0B000H,07777H
	 DW    031BAH,061E6H,09090H
	 DW    031C4H,061E6H,09090H
	 DW    031AFH,042E6H,09090H
	 DW    031B3H,042E6H,09090H
	 DW    031AAH,043E6H,09090H
	 DW    0FFFFH,0FFFFH,0FFFFH
 			
PATCH20b LABEL WORD
	 DB    'WordStar - v3.40 - 1.0  German' ;@@XLAT
	 DW    0600H,7D00H,PATCH21
	 DW    0471H,00EEH,0090H
	 DW    1AC0H,00EEH,0090H
	 DW    2C1EH,0FB74H,09090H
	 DW    32BFH,0FB74H,09090H
	 DW    331EH,0FB75H,09090H
	 DW    3324H,0FB74H,09090H
	 DW    339EH,0FB74H,09090H
	 DW    3DDEH,0FB74H,09090H
	 DW    5E5CH,0B800H,7777H
	 DW    5E6CH,0B000H,7777H
	 DW   0FFFFH,0FFFFH,0FFFFH

PATCH21  LABEL WORD
         DB    'Condor (database) 2.11 ** 8   ' ;@@XLAT
         DW    0472H,0938bH,PATCH21b
         DW    0474H,0B800H,07777H
         DW    0467H,0B000H,07777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH21b LABEL WORD
         DB    'Condor v2.11 ** 9 & v2.11.12H ' ;@@XLAT
         DW    0580H,057E9H,PATCH22
         DW    047BH,0B800H,07777H
         DW    046EH,0B000H,07777H
         DW    04DBH,0FB75H,09090H
         DW    04E0H,0FB74H,09090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH22  LABEL WORD
         DB    'MicroSoft Multiplan 1.10      ' ;@@XLAT
         DW    02BDBH,01fc3H,PATCH22B
         DW    02BDDH,0B800H,7777H
         DW    02C0DH,0B800H,7777H
         DW    03EBDH,000EEH,0090H
         DW    03ECFH,000EEH,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH22B DB    'MicroSoft Multiplan 1.2       '
         DW    00100H,0CDE9H,PATCH23
         DW    01AD6H,09090H,9090H
         DW    02D10H,0B800H,7777H
         DW    02D45H,0B800H,7777H
         DW    02D4BH,000EEH,0090H
         DW    02D84H,000EEH,0090H
         DW    02D87H,000EEH,0090H
         DW    02E2EH,0FB75H,9090H
         DW    02E34H,0FB74H,9090H
         DW    02E4CH,0B000H,7777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH23  LABEL WORD
         DB    'TenKey 1.06                   ' ;@@XLAT
         DW    06E6H,002C0H,PATCH24
         DW    06EEH,0B000H,7777H
         DW    06D5H,0B800H,7777H
         DW    2618H,0B800H,7777H
         DW    2622H,0B000H,7777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH24  LABEL WORD
         DB    'Volkswriter Deluxe 2.1        ' ;@@XLAT
         DW    3986H,0C08EH,PATCH25
         DW    3983H,0D8A1H,1AB8H
         DW    3984H,023D8H,7777H
         DW    3992H,00674H,9090H
         DW    3994H,00035H,9090H
         DW    3996H,0A308H,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH25  LABEL WORD
         DB    'SNA-3270 Ast.                 ' ;@@XLAT
         dw    0a4ah,0a800h,patch26
         DW    0ACAH,61E6H,9090H
         DW    0AD0H,61E6H,9090H
         DW    09EAH,0B000H,7777H
         DW    0A23H,0B800H,7777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH26  LABEL WORD
         DB    'PFS:FILE                      ' ;@@XLAT
         DW    91A0H,006C7H,PATCH27
         DW    91A4H,0B000H,7777H
         DW    91B2H,0B800H,7777H
         DW    9437H,0FB74H,9090H
         DW    943CH,0FB75H,9090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH27  LABEL WORD
         DB    'PFS:WRITE                     ' ;@@XLAT
         DW    211DH,00674H,PATCH27a
         DW    2120H,0B000H,7777H
         DW    2126H,0B800H,7777H
         DW    2146H,000EEH,0090H
         DW    2151H,000EEH,0090H
         DW    215CH,01574H,15EBH
         DW    73CDH,0B800H,7777H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH27a LABEL WORD
        DB      'PFS:FILE v. B,C               ' ;@@XLAT
        dw      01b85h,011cdh,patch27b
        dw      01b9dh,0b000h,7777h
        dw      01bc6h,0b800h,7777h
        dw      01414h,042e6h,9090h
        dw      0140fh,043e6h,9090h
        dw      01418h,042e6h,9090h
        dw      01420h,061e6h,9090h
        dw      01429h,061e6h,9090h
        dw      014b5h,0fb74h,9090h
        dw      014fdh,0fb75h,9090h
        dw      01503h,0fb74h,9090h
        dw      0150dh,0fb75h,9090h
        dw      01513h,0fb74h,9090h
        dw      0ffffh,0ffffh,0ffffh

PATCH27b LABEL WORD
        DB      'PFS:WRITE v. C                ' ;@@XLAT
        DW      020BDH,011CDH,PATCH27c
        DW      020D5H,0B000H,7777H
        DW      020FEH,0B800H,7777H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH27c LABEL WORD
        DB      'PFS:PLAN  v. C                ' ;@@XLAT
        DW      03A80H,011CDH,PATCH27d
        DW      03A98H,0B000H,7777H
        DW      03AC1H,0B800H,7777H
        DW      0FFFFH,0FFFFH,0FFFFH

patch27d label word
        db      'PFS:Write v.C fs=167552       ' ;@@XLAT
        dw      0112h,01ec3h,patch27e
        dw      2047h,0b000h,7777h
        dw      2070h,0b800h,7777h
        dw      1934h,0fb75h,9090h
        dw      193ah,0fb74h,9090h
        dw      1a34h,0fb74h,9090h
        dw      1a7eh,0fb75h,9090h
        dw      1a84h,0fb74h,9090h
        dw      37f1h,0fb75h,9090h
        dw      1993h,043e6h,9090h
        dw      1998h,042e6h,9090h
        dw      199ch,042e6h,9090h
        dw      19a4h,061e6h,9090h
        dw      19adh,061e6h,9090h
        dw      0ffffh,0ffffh,0ffffh

patch27e label word
        db      'PFS:Access v.C fs=125824      ' ;@@XLAT
        dw      0102h,00152h,patch27f
        dw      27e1h,0b000h,7777h
        dw      280ah,0b800h,7777h
        dw      211dh,0fb75h,9090h
        dw      212dh,0fb75h,9090h
        dw      20d5h,0fb74h,9090h
        dw      2123h,0fb74h,9090h
        dw      2133h,0fb74h,9090h
        dw      2040h,061e6h,9090h
        dw      2049h,061e6h,9090h
        dw      2034h,042e6h,9090h
        dw      2038h,042e6h,9090h
        dw      202fh,043e6h,9090h
        dw      0ffffh,0ffffh,0ffffh

patch27f label word
        db      'PFS:Report v.B fs= 78402      ' ;@@XLAT
        dw      0102h,00042h,patch27g
        dw      199dh,0b000h,7777h
        dw      19c6h,0b800h,7777h
        dw      12fdh,0fb75h,9090h
        dw      130dh,0fb75h,9090h
        dw      12b5h,0fb74h,9090h
        dw      1303h,0fb74h,9090h
        dw      1313h,0fb74h,9090h
        dw      1220h,061e6h,9090h
        dw      1229h,061e6h,9090h
        dw      1214h,042e6h,9090h
        dw      1218h,042e6h,9090h
        dw      120fh,043e6h,9090h
        dw      0ffffh,0ffffh,0ffffh

patch27g label word
        db      'PFS:Graph v.B  fs=149440      ' ;@@XLAT
        dw      0102h,000d0h,patch27h
        dw      01c08h,0b000h,7777h
        dw      00c79h,0b800h,7777h
        dw      01cf0h,0b000h,7777h
        dw      02c95h,0b000h,7777h
        dw      01da6h,0b800h,7777h
        dw      02c87h,0b800h,7777h
        dw      017e5h,0fb75h,9090h
        dw      0182eh,0fb75h,9090h
        dw      01b8dh,0fb75h,9090h
        dw      01bbch,0fb75h,9090h
        dw      01bc9h,0fb75h,9090h
        dw      01bd6h,0fb75h,9090h
        dw      01be3h,0fb75h,9090h
        dw      01c1bh,0fb75h,9090h
        dw      01c4ch,0fb75h,9090h
        dw      01c59h,0fb75h,9090h
        dw      01c66h,0fb75h,9090h
        dw      01c73h,0fb75h,9090h
        dw      017eah,0fb74h,9090h
        dw      01834h,0fb74h,9090h
        dw      01b94h,000eeh,0090h
        dw      01b88h,0f874h,9090h
        dw      01ba4h,000eeh,0090h
        dw      01bach,000eeh,0090h
        dw      01bb7h,0f874h,9090h
        dw      01bc4h,0f874h,9090h
        dw      01bd1h,0f874h,9090h
        dw      01bdeh,0f874h,9090h
        dw      01bech,000eeh,0090h
        dw      01c16h,0f874h,9090h
        dw      01c24h,000eeh,0090h
        dw      01c34h,000eeh,0090h
        dw      01c3ch,000eeh,0090h
        dw      01c47h,0f874h,9090h
        dw      01c54h,0f874h,9090h
        dw      01c61h,0f874h,9090h
        dw      01c6eh,0f874h,9090h
        dw      01c7eh,000eeh,0090h
        dw      04d2bh,043e6h,9090h
        dw      04d30h,042e6h,9090h
        dw      04d34h,042e6h,9090h
        dw      04d3ch,061e6h,9090h
        dw      04d45h,061e6h,9090h
        dw      0ffffh,0ffffh,0ffffh

patch27h label word
	db	'PFS:Report   v B  fs=78848    ' ;@@XLAT
	dw	1444h,03438h,patch28
	dw	14d5h,043e6h,9090h
	dw	14dah,042e6h,9090h
	dw	14deh,042e6h,9090h
	dw	14e6h,061e6h,9090h
	dw	14efh,061e6h,9090h
	dw	157bh,0fb74h,9090h
	dw	15c3h,0fb75h,9090h
	dw	15c9h,0fb74h,9090h
	dw	15d3h,0fb75h,9090h
	dw	15d9h,0fb74h,9090h
	dw	1c8bh,0b000h,7777h
	dw	1cb4h,0b800h,7777h
	dw	0ffffh,0ffffh,0ffffh

;----------------------------------------------------------------------------;
; If any changes need to be made to Symphony create a driver for color cards ;
; with display type 4 ,an Okidata text printer, and Numbers first.  Nothing  ;
; else!   For a monochrome driver select display type ?, and Numbers first.  ;
; Nothing else!  Then do a normal vidfix with offsets and patch values in    ;
; the tables, but be sure that the reference offset is the first entry in    ;
; the table and that the type check value is the second entry.               ;
;----------------------------------------------------------------------------;
;PATCHxx  LABEL WORD
;        DB    'Symphony 1.00 Type 4 Display  ' ;@@XLAT
;        DW    0100H,00100H,PATCH29

;        DW    075BH,050B8H,0D588H  ; REPL CURSOR ACCESS WITH BIOS CALL
;        DW    075DH,0F700H,05756H
;        DW    075FH,003E2H,05355H
;        DW    0761H,0BAC8H,002B4H
;        DW    0763H,003D4H,0CA89H
;        DW    0765H,00EB0H,0DB31H
;        DW    0767H,042EEH,010CDH
;        DW    0769H,0C58AH,05D5BH
;        DW    076BH,04AEEH,05E5FH
;        DW    076DH,00FB0H,090CBH


patch28 label word
        db      'Lotus 2/Symphony 1.x .SET file' ;@@XLAT
        dw      00100h,00100h,patch29
        dw      0000fh,0000fh,0000fh
        dw      0ffffh,0ffffh,0ffffh


;PATCH28a LABEL WORD
;	DB      'Lotus 2/Symphony 1.x .SET File' ;@@XLAT
;	DW      00105H,0464FH,PATCH29           ; this table is used just to
;	DW      0000FH,0000FH,0000FH            ; GO TO PUKE
;	DW      0FFFFH,0FFFFH,0FFFFH            ; get into the special lotus
						; symphony scanning routine

;        DB    'Symphony 1.00 Type 1 Display  '
;        DW    0100H,00100H,PATCH28a
;        DW    00001H,SCODE1,RCODE1     ;***
;        DW    00001H,SCODE1A,00000H    ;***
;
;        DW    05D3H,061E6H,9090H   ; REFERENCE OFFSET  ****************
;        DW    04DDH,0B000H,7777H   ; TYPE CHECK VALUE  ****************
;        DW    05DBH,061E6H,9090H
;        DW    05E5H,061E6H,9090H
;        DW    04EEH,0B000H,7777H
;        DW    04FDH,0B000H,7777H
;        DW    0516H,0B000H,7777H
;        DW    0524H,0B000H,7777H
;        DW    0536H,0B000H,7777H
;        DW    0554H,0B000H,7777H
;        DW    0573H,0B000H,7777H
;        DW    05FDH,0B000H,7777H
;        DW    06F2H,0B000H,7777H
;        DW    0706H,0B000H,7777H
;        DW   0FFFFH,0FFFFH,0FFFFH

;******************************************************************************
;*                                                                            *
;* Since we only need to fix Lotus 2 for a background it should be installed  *
;* for a monochrome monitor, no graphics, an OKIDATA printer and renamed      *
;* MONO.SET. It should be invoked using the command "123 MONO.SET".           *
;*                                                                            *
;******************************************************************************

;PATCH28a LABEL WORD
;       DB      'Lotus 2 Mono Display          ' ;@@XLAT
;       DW      00102H,00008H,PATCH29
;       DW      00001H,SCODE2,RCODE1    ;*** SCODE2 is addrs of code to scan for
;       DW      00001H,SCODE2,RCODE1    ;*** RCODE1 is addrs of replacement code
;       DW      00001H,SCODE1A,0000H    ;*** This 0000h causes adjustment of
;                                       ;*** vidfix table offsets, if necessary.
;
;       DW      06A8EH,061E6H,9090H     ; REFERENCE OFFSET ***************
;       DW      04641H,0B000H,7777H     ; TYPE CHECK VALUE ***************
;       DW      06492H,0B000H,7777H
;       DW      06666H,0B000H,7777H
;       DW      06743H,0B800H,7777H
;       DW      06775H,0B800H,7777H
;       DW      067B0H,0B000H,7777H
;       DW      06A96H,061E6H,9090H
;       DW      06AA0H,061E6H,9090H
;       DW      06C79H,0FB75H,9090H
;       DW      06C7EH,0FB74H,9090H
;       DW      070ABH,061E6H,9090H
;       DW      070B3H,061E6H,9090H
;       DW      070BDH,061E6H,9090H
;       DW      0FFFFH,0FFFFH,0FFFFH


PATCH29  LABEL WORD
         DB    'SuperCalc3 Rel 2.0            ' ;@@XLAT
         DW    02121H,0E0D1H,PATCH29a
         DW    02FE6H,0FB75H,9090H
         DW    02FECH,0FB74H,9090H
         DW    030C1H,0FB75H,9090H
         DW    030C7H,0FB74H,9090H
         DW    03179H,000EEH,0090H
         DW    0318DH,000EEH,0090H
         DW    040E1H,0B000H,7777H
         DW    0C8B2H,000EEH,0090H
         DW    0C8D7H,000ECH,0090H
         DW    0C8DAH,000EEH,0090H
         DW    0C8DDH,000EEH,0090H
         DW    0C8E0H,000EEH,0090H
         DW    0C8E3H,000EEH,0090H
         DW    0C8E9H,000EEH,0090H
         DW    0CCDAH,0FB75H,9090H
         DW    0CCE0H,0FB74H,9090H
         DW    0CCFAH,0FB75H,9090H
         DW    0CD00H,0FB74H,9090H
         DW    0D730H,000EEH,0090H
         DW    0D63EH,0B800H,0FF00H
         DW    0D6E5H,0B800H,7777H
         DW    0FFFFH,0FFFFH,0FFFFH

PATCH29a LABEL WORD
        DB      'SuperCalc 3  v2.1             ' ;@@XLAT
        DW      0DF98H,0892EH,PATCH30
        DW      0348FH,0B800H,7777H
        DW      0348FH,0B000H,7777H
        DW      0381EH,0FB75H,9090H
        DW      03824H,0FB74H,9090H
        DW      03957H,000EEH,0090H
        DW      0396BH,000EEH,0090H
        DW      0490EH,0B800H,7777H
        DW      049E6H,0B000H,7777H
        DW      07144H,0B000H,7777H
        DW      096B1H,0B000H,7777H
        DW      0AE7EH,0FB75H,9090H
        DW      0AE84H,0FB74H,9090H
        DW      0AE99H,0B000H,7777H
        DW      0DD7FH,0FB75H,9090H
        DW      0DD85H,0FB74H,9090H
        DW      0DD9FH,0FB75H,9090H
        DW      0DDA5H,0FB74H,9090H
        DW      0EB20H,0B000H,7777H
        DW      0EB45H,0B800H,7777H
        DW      0ED16H,000EEH,0090H
        DW      0ED1BH,000EEH,0090H
        DW      0ED26H,000EEH,0090H
        DW      0ED78H,0B800H,7777H
        DW      0F067H,0B800H,7777H
        DW      0FFFFH,0FFFFH,0FFFFH


PATCH30  LABEL WORD
         DB    'Testing Purposes ONLY . . .   ' ;@@XLAT
         DW    00101H,01234H,PATCH31
         DW    00110H,04646H,4242H
         DW    0FFFFH,0FFFFH,0FFFFH

PATCH31  LABEL WORD
         DB    'IBM Personal Editor v1.0      ' ;@@XLAT
         DW    00456H,00263H,PATCH32
         DW    07695H,0B000H,7777H
         DW    076DBH,0B800H,7777H
         DW    09825H,043E6H,9090H
         DW    0982AH,042E6H,9090H
         DW    0982EH,042E6H,9090H
         DW    09832H,061E6H,9090H
         DW    0983CH,061E6H,9090H
         DW    0A26AH,0B000H,7777H
         DW    0A242H,0B800H,7777H
         DW    0FFFFH,0FFFFH,0FFFFH

PATCH32  LABEL WORD
         DB    'Dayflo v1.1                   ' ;@@XLAT
         DW    037F6H,040B8H,PATCH33
;        DW    00ED6H,043E6H,9090H
;        DW    00EDBH,042E6H,9090H
;        DW    00EDFH,042E6H,9090H
;        DW    00EE7H,061E6H,9090H
;        DW    00EF6H,061E6H,9090H
         DW    037FCH,0B800H,7777H
         DW    0380DH,0B000H,7777H
         DW    0FFFFH,0FFFFH,0FFFFH

PATCH33 LABEL WORD
        DB      'WordStar 2000 V1.01 Mon/Col   ' ;@@XLAT
        DW      0010FH,0C91DH,PATCH34
        DW      033F0H,0B000H,7777H
        DW      03408H,0B800H,7777H
        DW      05FD9H,0B000H,7777H
        DW      0600FH,0B000H,7777H
        DW      06042H,0B000H,7777H
        DW      060ADH,0B000H,7777H
        DW      060BBH,0B800H,7777H
        DW      060D3H,0B000H,7777H
        DW      06053H,0FB75H,9090H
        DW      06058H,0FB74H,9090H
        DW      06102H,0FB75H,9090H
        DW      06107H,0FB74H,9090H
        DW      06116H,000EEH,0090H
        DW      06172H,061E4H,9090H
        DW      06177H,061E6H,9090H
        DW      06180H,061E6H,9090H
        DW      0618BH,061E6H,9090H
        DW      064CDH,0B000H,7777H
        DW      00000H,00000H,00000H
        DW      00000H,08B55H,08B55H
        DW      00000H,00000H,00000H
        DW      03B73H,04C42H,04C42H
        DW      03B75H,0434FH,0434FH
        DW      03B77H,0204BH,0204BH
        DW      03BB3H,04544H,04544H
        DW      03BB5H,0454CH,0454CH
        DW      03BB7H,04554H,04554H
        DW      03BB9H,02E20H,02E20H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH34 LABEL WORD
        DB      'XTALK IBM-PC  v3.5            ' ;@@XLAT
        DW      0FB0EH,010CDH,PATCH34a
        DW      0FB15H,0B000H,7777H
        DW      0FB25H,0B800H,7777H
        DW      00000H,00000H,00000H
        DW      000E2H,0FB75H,9090H
        DW      000EAH,0FB74H,9090H
        DW      00103H,0FB75H,9090H
        DW      00109H,0FB74H,9090H
        DW      00125H,0FB75H,9090H
        DW      0012BH,0FB74H,9090H
        DW      0026BH,0FB74H,9090H
        DW      00272H,000EEH,0090H
        DW      00294H,000EEH,0090H

        DW      002DEH,0DA8BH,0D389H    ; replace direct cursor addressing
        DW      002E0H,0EBD1H,0EBD1H    ; with bios call
        DW      002E2H,08B2EH,0D889H    ;
        DW      002E4H,0C316H,050BBH    ;
        DW      002E6H,0B06AH,03100H    ;
        DW      002E8H,0EE0EH,0F7D2H    ;
        DW      002EAH,08A42H,088F3H    ;
        DW      002ECH,0EEC7H,0B4C6H    ;
        DW      002EEH,0B04AH,0CD02H    ;
        DW      002F0H,0EE0FH,09010H    ;
        DW      002F2H,08A42H,9090H     ;
        DW      002F4H,0EEC3H,9090H     ;

        DW      00309H,000EEH,0090H
        DW      00342H,043E6H,9090H
        DW      00347H,042E6H,9090H
        DW      0034BH,042E6H,9090H
        DW      00353H,061E6H,9090H
        DW      0035CH,061E6H,9090H
        DW      00393H,043E6H,9090H
        DW      00397H,042E6H,9090H
        DW      0039BH,04236H,9090H
        DW      003A8H,061E6H,9090H
        DW      003B6H,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH    ; end of table for xtalk v3.5

PATCH34a LABEL WORD
        DB      'XTALK IBM-PC  v3.6            ' ;@@XLAT
        DW      034B0H,06172H,PATCH35
        DW      0F0A9H,0B000H,7777H
        DW      00000H,00000H,00000H
        DW      01FE0H,0B000H,7777H
        DW      01FC9H,0B800H,7777H
        DW      02683H,0FB75H,9090H
        DW      02691H,0FB74H,9090H
        DW      026BFH,0FB75H,9090H
        DW      026CDH,0FB74H,9090H
        DW      02701H,0FB75H,9090H
        DW      0270FH,0FB74H,9090H
        DW      02742H,0FB75H,9090H
        DW      02750H,0FB74H,9090H
        DW      0289DH,0FB74H,9090H
        DW      028A4H,000EEH,0090H
        DW      028C6H,000EEH,0090H

        DW      02919H,0DA8BH,0D389H    ; replace direct cursor addressing
        DW      0291BH,0EBD1H,0EBD1H    ; with bios call
        DW      0291DH,08B2EH,0D889H    ;
        DW      0291FH,0CB16H,050BBH    ;
        DW      02921H,0B082H,03100H    ;
        DW      02923H,0EE0EH,0F7D2H    ;
        DW      02925H,08A42H,088F3H    ;
        DW      02927H,0EEC7H,0B4C6H    ;
        DW      02929H,0B04AH,0CD02H    ;
        DW      0292BH,0EE0FH,09010H    ;
        DW      0292DH,08A42H,9090H     ;
        DW      0292FH,0EEC3H,9090H     ;

        DW      02961H,000EEH,0090H
        DW      02974H,000EEH,0090H
        DW      0299AH,043E6H,9090H
        DW      0299FH,042E6H,9090H
        DW      029A3H,042E6H,9090H
        DW      029ABH,061E6H,9090H
        DW      029B4H,061E6H,9090H
        DW      029EBH,043E6H,9090H
        DW      029EFH,042E6H,9090H
        DW      029F3H,042E6H,9090H
        DW      02A00H,061E6H,9090H
        DW      02A0EH,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH    ; end of table for xtalk v3.6

PATCH35 LABEL WORD
        DB      'IBM DisplayWrite 3  v1.00     ' ;@@XLAT
        DW      0010EH,006F6H,PATCH35a
        DW      00216H,0B000H,7777H
        DW      0021BH,0B800H,7777H
        DW      00646H,0B000H,7777H
        DW      00663H,0B800H,7777H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH35A LABEL WORD
        DB      'DW3A0100.PG1                  ' ;@@XLAT
        DW      01705H,04340H,PATCH35b
        DW      01810H,061E6H,9090H
        DW      01814H,061E6H,9090H
        DW      07757H,061E6H,9090H
        DW      07757H,043E6H,9090H
        DW      0775BH,042E6H,9090H
        DW      0775FH,042E6H,9090H
        DW      07767H,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH35b LABEL WORD
        DB      'DisplayWrite 3 v1.10          ' ;@@XLAT
        DW      0EFCH,04249H,PATCH36
        DW      024CH,0B000H,7777H
        DW      025AH,0B800H,7777H
        DW      08D9H,0B000H,7777H
        DW      08DEH,0B800H,7777H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH36 LABEL WORD
        DB      'MBP COBOL v9.0                ' ;@@XLAT
        DW      081ADH,010CDH,PATCH36A
        DW      081B4H,00B74H,9090H
        DW      081BAH,0B800H,7777H
        DW      081BFH,0011CH,001CH
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH36A LABEL WORD
        DB      'MBP COBOL Network Version v9.0' ;@@XLAT
        DW      0844DH,010CDH,PATCH36B
        DW      08454H,00B74H,9090H
        DW      0845AH,0B800H,7777H
        DW      0845FH,0011CH,001CH
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH36B LABEL WORD
        DB      'MBP COBOL v9.0 11/11/85       ' ;@@XLAT
        DW      0844FH,010CDH,PATCH37
        DW      08456H,00B74H,9090H
        DW      0845CH,0B800H,7777H
        DW      08461H,0011CH,001CH
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH37 LABEL WORD
        DB      'WS2000 v1.01 Size=164832      ' ;@@XLAT
        DW      00112H,03CCDH,PATCH37A
        DW      03400H,0B000H,7777H
        DW      03418H,0B800H,7777H
        DW      05FADH,0B000H,7777H
        DW      05FE3H,0B000H,7777H
        DW      06016H,0B000H,7777H
        DW      06081H,0B000H,7777H
        DW      0608FH,0B800H,7777H
        DW      060A7H,0B000H,7777H
        DW      064A1H,0B000H,7777H
        DW      0346BH,0FB75H,9090H
        DW      03470H,00E75H,9090H
        DW      03474H,0F775H,9090H
        DW      03479H,0FB74H,9090H
        DW      06027H,0FB75H,9090H
        DW      0602CH,0FB74H,9090H
        DW      0614BH,061E6H,9090H
        DW      06154H,061E6H,9090H
        DW      0615FH,061E6H,9090H
        DW      064C6H,0FB75H,9090H
        DW      064CBH,0FB74H,9090H
        DW      00000H,00000H,00000H
        DW      00000H,0FF04H,0FF04H
        DW      00000H,00000H,00000H
        DW      03C82H,04C42H,04C42H
        DW      03C84H,0434FH,0434FH
        DW      03C86H,0204BH,0204BH
        DW      03CC2H,04544H,04544H
        DW      03CC4H,0454CH,0454CH
        DW      03CC6H,04554H,04554H
        DW      03CC8H,02E20H,02E20H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH37A LABEL WORD
        DB      'WS2000 File Conversion Utility' ;@@XLAT
        DW      0030AH,001DEH,PATCH37B
        DW      08938H,0B000H,7777H
        DW      0896EH,0B000H,7777H
        DW      089A1H,0B000H,7777H
        DW      08A0CH,0B000H,7777H
        DW      08A32H,0B000H,7777H
        DW      08E2CH,0B000H,7777H
        DW      08A1AH,0B800H,7777H
        DW      089B2H,0FB75H,9090H
        DW      089B7H,0FB74H,9090H
        DW      08A61H,0FB75H,9090H
        DW      08A66H,0FB74H,9090H
        DW      08AD6H,061E6H,9090H
        DW      08ADFH,06AE6H,9090H
        DW      08AEAH,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH37B LABEL WORD
        DB      'WS2000 Mailing List Utility   ' ;@@XLAT
        DW      00110H,06BB7H,PATCH37c
        DW      06458H,0B000H,7777H
        DW      06444H,0B800H,7777H
        DW      06908H,0FB75H,9090H
        DW      0690DH,0FB74H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH37C LABEL WORD
        DB      'WordStar 2000 v2.00           ' ;@@XLAT
        DW      03C12H,011CDH,PATCH37D
        DW      03C20H,0B000H,7777H
        DW      03C38H,0B800H,7777H
        DW      09073H,0B000H,7777H
        DW      09076H,0B000H,7777H
        DW      09089H,0B800H,7777H
        DW      0908CH,0B800H,7777H
        DW      090A8H,0B000H,7777H
        DW      090DAH,0B800H,7777H
        DW      09136H,074FBH,9090H
        DW      091A7H,061E6H,9090H
        DW      091B0H,061E6H,9090H
        DW      091BBH,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH37D LABEL WORD
        DB      'WS2000 - WS2LIST.COM 1.01     ' ;@@XLAT
        DW      00110H,06BD1H,PATCH37E
        DW      06472H,0B000H,7777H
        DW      0645EH,0B800H,7777H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH37E LABEL WORD
        DB      'WS2000 - TELMERGE.EXE         ' ;@@XLAT
        DW      08F89H,011CDH,PATCH37G
        DW      08F9EH,0B000H,7777H
        DW      08FA1H,0B000H,7777H
        DW      08FBAH,0B800H,7777H
        DW      08FBDH,0B800H,7777H
        DW      08FD4H,0FB75H,9090H
        DW      08FD9H,0FB74H,9090H
        DW      09029H,0FB75H,9090H
        DW      0902EH,0FB74H,9090H
        DW      09668H,0FB75H,9090H
        DW      0966DH,0FB74H,9090H
        DW      0968BH,061E6H,9090H
        DW      09694H,061E6H,9090H
        DW      0969FH,061E6H,9090H
        DW      0E3B5H,0FB75H,9090H
        DW      0E3BAH,0FB74H,9090H
        DW      0E446H,0B000H,7777H
        DW      0E449H,0B000H,7777H
        DW      0E45CH,0B800H,7777H
        DW      0E45FH,0B800H,7777H
        DW      0E47BH,0B000H,7777H
        DW      0E4ADH,0B000H,7777H
        DW      0E493H,0FB75H,9090H
        DW      0E498H,0FB74H,9090H
        DW      0E57AH,061E6H,9090H
        DW      0E583H,061E6H,9090H
        DW      0E58EH,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

;PATCH37F LABEL WORD
;       DB      'WS2000 - CONVERT.EXE          ' ;@@XLAT
;       DW      0E570H,020E6H,PATCH37G
;       DW      0E3B5H,0FB75H,9090H
;       DW      0E3BAH,0FB74H,9090H
;       DW      0E446H,0B000H,7777H
;       DW      0E449H,0B000H,7777H
;       DW      0E45CH,0B800H,7777H
;       DW      0E45FH,0B800H,7777H
;       DW      0E47BH,0B000H,7777H
;       DW      0E4ADH,0B000H,7777H
;       DW      0E493H,0FB75H,9090H
;       DW      0E498H,0FB74H,9090H
;       DW      0E4FBH,0FB75H,9090H
;       DW      0E500H,0FB74H,9090H
;       DW      0E57AH,061E6H,9090H
;       DW      0E583H,061E6H,9090H
;       DW      0E58EH,061E6H,9090H
;       DW      0E8FDH,0FB75H,9090H
;       DW      0E902H,0FB74H,9090H
;       DW      0FFFFH,0FFFFH,0FFFFH

PATCH37G LABEL WORD
        DB      'WS2000 rel 2 WS2INDEX.EXE     ' ;@@XLAT
        DW      07FFBH,011CDH,PATCH38
        DW      07F7FH,0FB75H,9090H
        DW      07F84H,0FB74H,9090H
        DW      08010H,0B000H,7777H
        DW      08013H,0B000H,7777H
        DW      08026H,0B800H,7777H
        DW      08029H,0B800H,7777H
        DW      08045H,0B000H,7777H
        DW      0805AH,0B800H,7777H
        DW      080A8H,0FB75H,9090H
        DW      080ADH,0FB74H,9090H
        DW      08127H,061E6H,9090H
        DW      08130H,061E6H,9090H
        DW      0813BH,061E6H,9090H
        DW      084AAH,0FB75H,9090H
        DW      084AFH,0FB74H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH38 LABEL WORD
        DB      'Multimate 3.30 Mono/Color     ' ;@@XLAT
        DW      00550H,01AB4H,PATCH38a
        DW      0F80FH,0B000H,7777H
        DW      0F81EH,0B800H,7777H
        DW      0F855H,00800H,7777H
        DW      0F880H,00800H,7777H
        DW      0F898H,00800H,7777H
        DW      0F909H,0B000H,7777H
        DW      0F93EH,0B000H,7777H
        DW      0FA52H,0B000H,7777H
        DW      0FA92H,00800H,7777H
        DW      0FACFH,00800H,7777H
        DW      0FAE2H,00800H,7777H
        DW      0FB5BH,0B000H,7777H
        DW      0F8A8H,0FB74H,9090H
        DW      0F8ECH,0FB75H,9090H
        DW      0F8F1H,0FB74H,9090H
        DW      0F9DEH,0FB74H,9090H
        DW      0FA0CH,0FB74H,9090H
        DW      0FA6CH,0FB75H,9090H
        DW      0FA71H,0FB74H,9090H
        DW      0FAB4H,061E6H,9090H
        DW      0FABDH,061E6H,9090H
        DW      0FAC8H,061E6H,9090H
        DW      0FADCH,000EEH,0090H
        DW      0FAEFH,000EEH,0090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH38a LABEL WORD
        DB      'Multimate v3.50 WP.EXE        ' ;@@XLAT
        DW      036CCH,0D8A0H,PATCH38b
        DW      0EFCAH,0B000H,7777H
        DW      0EFD9H,0B800H,7777H
        DW      0EFF7H,00800H,7777H
        DW      0F08EH,00800H,7777H
        DW      0F103H,0FB75H,9090H
        DW      0F108H,0FB74H,9090H
        DW      0F111H,0FB75H,9090H
        DW      0F116H,0FB74H,9090H
        DW      0F1B2H,0FB74H,9090H
        DW      0F1BBH,0FB75H,9090H
        DW      0F1C0H,0FB74H,9090H
        DW      0F29CH,0FB74H,9090H
        DW      0F2A5H,0FB75H,9090H
        DW      0F2B4H,0FB74H,9090H
        DW      0F325H,0FB75H,9090H
        DW      0F32AH,0FB74H,9090H
        DW      0F333H,0FB75H,9090H
        DW      0F338H,0FB74H,9090H
        DW      0F382H,061E6H,9090H
        DW      0F38BH,061E6H,9090H
        DW      0F396H,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH38b LABEL WORD
        DB      'Multimate v3.50 MM.EXE        ' ;@@XLAT
        DW      008C6H,0303DH,PATCH38c
        DW      008CFH,0B000H,7777H
        DW      008DEH,0B800H,7777H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH38c LABEL WORD
        DB      'On-File v1.00  ONFILE.EXE     ' ;@@XLAT
        DW      012BDH,0E850H,PATCH38d
        DW      096CEH,0B800H,7777H
        DW      096E6H,0FB75H,9090H
        DW      096F0H,0FB74H,9090H
        DW      09703H,0FB75H,9090H
        DW      09709H,0FB74H,9090H
        DW      09714H,0B000H,7777H
        DW      09AEEH,0B800H,7777H
        DW      09B3DH,0FB75H,9090H
        DW      09B43H,0FB74H,9090H
        DW      09B50H,0FB75H,9090H
        DW      09B56H,0FB74H,9090H
        DW      09B5FH,0B000H,7777H
        DW      09D6CH,0FB75H,9090H
        DW      09D72H,0FB74H,9090H
        DW      09D7EH,0FB75H,9090H
        DW      09D84H,0FB74H,9090H
        DW      09D92H,0FB74H,9090H
        DW      09D98H,0FB74H,9090H
        DW      09DA5H,0FB75H,9090H
        DW      09DABH,0FB74H,9090H
        DW      09DB4H,0B000H,7777H
        DW      09C9CH,0B800H,7777H
        DW      0A231H,061E6H,9090H
        DW      0A23DH,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH38d LABEL WORD
        DB      'Multimate v3.50 UTIL.EXE      ' ;@@XLAT
        DW      0120EH,09A50H,PATCH38e
        DW      00F7FH,0B000H,7777H
        DW      06005H,0B000H,7777H
        DW      06007H,0B800H,7777H
        DW      0940CH,0B000H,7777H
        DW      0941BH,0B800H,7777H
        DW      0943BH,00800H,7777H
        DW      094D2H,00800H,7777H
        DW      094E2H,0FB74H,9090H
        DW      09540H,0FB75H,9090H
        DW      09545H,0FB74H,9090H
        DW      0954EH,0FB75H,9090H
        DW      09553H,0FB74H,9090H
        DW      095EFH,0FB74H,9090H
        DW      095F8H,0FB75H,9090H
        DW      095FDH,0FB74H,9090H
        DW      096D4H,0FB74H,9090H
        DW      096DDH,0FB75H,9090H
        DW      096ECH,0FB74H,9090H
        DW      0975DH,0FB75H,9090H
        DW      09762H,0FB74H,9090H
        DW      0976BH,0FB75H,9090H
        DW      09770H,0FB74H,9090H
        DW      097BAH,061E6H,9090H
        DW      097C3H,061E6H,9090H
        DW      097CEH,061E6H,9090H
        DW      0989AH,0B000H,7777H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH38e LABEL WORD
        DB      'Multimate v3.60 WP.EXE        ' ;@@XLAT
        DW      00724H,035CFH,PATCH38e0
        DW      0EEA6H,0B000H,7777H
        DW      0EEB5H,0B800H,7777H
        DW      0EED5H,00800H,7777H
        DW      0EF78H,00800H,7777H
        DW      0EF88H,0FB74H,9090H
        DW      0EFEBH,0FB75H,9090H
        DW      0EFF0H,0FB74H,9090H
        DW      0EFF9H,0FB75H,9090H
        DW      0EFFEH,0FB74H,9090H
        DW      0F09AH,0FB74H,9090H
        DW      0F0A3H,0FB75H,9090H
        DW      0F0A8H,0FB74H,9090H
        DW      0F184H,0FB74H,9090H
        DW      0F18DH,0FB75H,9090H
        DW      0F19CH,0FB74H,9090H
        DW      0F20DH,0FB75H,9090H
        DW      0F21BH,0FB75H,9090H
        DW      0F212H,0FB74H,9090H
        DW      0F220H,0FB74H,9090H
        DW      0F26AH,061E6H,9090H
        DW      0F273H,061E6H,9090H
        DW      0F27EH,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH38e0 LABEL WORD
        DB      'Multimate v3.60 - LAN   WP.EXE' ;@@XLAT
        DW      01E46h,04D4Dh,PATCH38E1
	DW	0F050H,00F75H,09090H
        DW      0F056H,0B000H,07777H
        DW      0F065H,0B800H,07777H
        DW      0F085H,00800H,00000H
        DW      0F128H,00800H,00000H
;	DW	0F4FCH,0B000H,07777H
        DW      0F138H,0FB74H,09090H
        DW      0F19BH,0FB75H,09090H
        DW      0F1A0H,0FB74H,09090H
        DW      0F1A9H,0FB75H,09090H
        DW      0F1AEH,0FB74H,09090H
        DW      0F24AH,0FB74H,09090H
        DW      0F253H,0FB75H,09090H
        DW      0F258H,0FB74H,09090H
        DW      0F334H,0FB74H,09090H
        DW      0F33DH,0FB75H,09090H
        DW      0F34CH,0FB74H,09090H
        DW      0F3BDH,0FB75H,09090H
        DW      0F3CBH,0FB75H,09090H
        DW      0F3C2H,0FB74H,09090H
        DW      0F3D0H,0FB74H,09090H
        DW      0F41AH,061E6H,09090H
        DW      0F423H,061E6H,09090H
        DW      0F42EH,061E6H,09090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH38E1 LABEL WORD
        DB      'Multimate v3.60  fs=302880    ' ;@@XLAT
        DW      01769h,05056h,PATCH38EA
	DW	0ED6CH,00F75H,09090H
        DW      0ED72H,0B000H,07777H
        DW      0ED81H,0B800H,07777H
        DW      0EDA1H,00800H,00000H
        DW      0EE44H,00800H,00000H
;	DW	0F4FCH,0B000H,07777H
        DW      0EE54H,0FB74H,09090H
        DW      0EEB7H,0FB75H,09090H
        DW      0EEBCH,0FB74H,09090H
        DW      0EEC5H,0FB75H,09090H
        DW      0EECAH,0FB74H,09090H
        DW      0EF66H,0FB74H,09090H
        DW      0EF6FH,0FB75H,09090H
        DW      0EF74H,0FB74H,09090H
        DW      0F050H,0FB74H,09090H
        DW      0F059H,0FB75H,09090H
        DW      0F068H,0FB74H,09090H
        DW      0F0D9H,0FB75H,09090H
        DW      0F0E7H,0FB75H,09090H
        DW      0F0DEH,0FB74H,09090H
        DW      0F0ECH,0FB74H,09090H
        DW      0F136H,061E6H,09090H
        DW      0F13FH,061E6H,09090H
        DW      0F14AH,061E6H,09090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH38eA LABEL WORD
        DB      'Multimate v3.60 MM.EXE        ' ;@@XLAT
        DW      00724H,03931H,PATCH38e2
	DW      0158EH,0B000H,7777H
	DW      0159DH,0B800H,7777H
	DW      0FFFFH,0FFFFH,0FFFFH

PATCH38e2 LABEL WORD
        DB      'Multimate v3.60 UTIL.EXE      ' ;@@XLAT
        DW      00724H,000E5H,PATCH38e3
	DW      091F1H,0B000H,7777H
        DW      09200H,0B800H,7777H
	DW      09220H,00800H,7777H
        DW      092C3H,00800H,7777H
        DW      092D3H,0FB74H,9090H
        DW      09331H,0FB75H,9090H
        DW      09336H,0FB74H,9090H
        DW      0933FH,0FB75H,9090H
        DW      09344H,0FB74H,9090H
        DW      093E0H,0FB74H,9090H
        DW      093E9H,0FB75H,9090H
        DW      093EEH,0FB74H,9090H
        DW      094C5H,0FB74H,9090H
        DW      094CEH,0FB75H,9090H
        DW      094DDH,0FB74H,9090H
        DW      095ABH,061E6H,9090H
        DW      095B4H,061E6H,9090H
        DW      095BFH,061E6H,9090H
        DW      0954EH,0FB75H,9090H
        DW      09553H,0FB74H,9090H
        DW      0955CH,0FB75H,9090H
        DW      09561H,0FB74H,9090H
	   DW      0FFFFH,0FFFFH,0FFFFH

PATCH38e3 LABEL WORD
        DB      'On-File v1.0/1.1  OFUT.EXE    ' ;@@XLAT
        DW      01848H,018B9H,PATCH38f
        DW      012A1H,0B800H,7777H
        DW      012BDH,0FB75H,9090H
        DW      012C3H,0FB74H,9090H
        DW      012D6H,0FB75H,9090H
        DW      012DCH,0FB74H,9090H
        DW      012E7H,0B000H,7777H
        DW      015A5H,0B800H,7777H
        DW      01675H,0FB75H,9090H
        DW      0167BH,0FB74H,9090H
        DW      01687H,0FB75H,9090H
        DW      0168DH,0FB74H,9090H
        DW      0169BH,0FB75H,9090H
        DW      016A1H,0FB74H,9090H
        DW      016AEH,0FB75H,9090H
        DW      016B4H,0FB74H,9090H
        DW      016BDH,0B000H,7777H
        DW      01846H,061E6H,9090H
        DW      01852H,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH38f LABEL WORD
        DB	'On-File v1.0/1.1  OFUTXXX1.EXE' ;@@XLAT
        DW      01B27H,0768BH,PATCH38g
        DW      05E0DH,0B800H,7777H
        DW      05EDDH,0FB75H,9090H
        DW      05EE3H,0FB74H,9090H
        DW      05EEFH,0FB75H,9090H
        DW      05EF5H,0FB74H,9090H
        DW      05F03H,0FB75H,9090H
        DW      05F09H,0FB74H,9090H
        DW      05F16H,0FB75H,9090H
        DW      05F1CH,0FB74H,9090H
        DW      05F25H,0B000H,9090H
        DW      06060H,0B800H,7777H
        DW      0607CH,0FB75H,9090H
        DW      06082H,0FB74H,9090H
        DW      06095H,0FB75H,9090H
        DW      0609BH,0FB74H,9090H
        DW      060A6H,0B000H,7777H
        DW      0632AH,0B800H,7777H
        DW      06379H,0FB75H,9090H
        DW      0637FH,0FB74H,9090H
        DW      0638CH,0FB75H,9090H
        DW      06392H,0FB74H,9090H
        DW      0639BH,0B000H,7777H
        DW      064DAH,061E6H,9090H
        DW      064E6H,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH38g LABEL WORD
	DB	'On-FilE v1.0/1.1  OFUTXXX2.EXE' ;@@XLAT
        DW      011B7H,0E58BH,PATCH38h
        DW      02811H,0B800H,7777H
        DW      028E1H,0FB75H,9090H
        DW      028E7H,0FB74H,9090H
        DW      028F3H,0FB75H,9090H
        DW      028F9H,0FB74H,9090H
        DW      02907H,0FB75H,9090H
        DW      0290DH,0FB74H,9090H
        DW      0291AH,0FB75H,9090H
        DW      02920H,0FB74H,9090H
        DW      02929H,0B000H,7777H
        DW      02A64H,0B800H,7777H
        DW      02A80H,0FB75H,9090H
        DW      02A86H,0FB74H,9090H
        DW      02A99H,0FB75H,9090H
        DW      02A9FH,0FB74H,9090H
        DW      02AAAH,0B000H,7777H
        DW      02DF2H,0B800H,7777H
        DW      02E41H,0FB75H,9090H
        DW      02E47H,0FB74H,9090H
        DW      02E54H,0FB75H,9090H
        DW      02E5AH,0FB74H,9090H
        DW      02E63H,0B000H,7777H
        DW      02ED5H,061E6H,9090H
        DW      02EE1H,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH38h LABEL WORD
	DB	'On-FilE v1.0/1.1  OFUTXXX3.EXE' ;@@XLAT
        DW      036A1H,00717H,PATCH38i
        DW      03450H,0B800H,7777H
        DW      0346CH,0FB75H,9090H
        DW      03472H,0FB74H,9090H
        DW      03485H,0FB75H,9090H
        DW      0348BH,0FB74H,9090H
        DW      03496H,0B000H,7777H
        DW      036AEH,0B800H,7777H
        DW      0377EH,0FB75H,9090H
        DW      03784H,0FB74H,9090H
        DW      03790H,0FB75H,9090H
        DW      03796H,0FB74H,9090H
        DW      037A4H,0FB75H,9090H
        DW      037AAH,0FB74H,9090H
        DW      037B7H,0FB75H,9090H
        DW      037BDH,0FB74H,9090H
        DW      037C6H,0B000H,7777H
        DW      0391FH,061E6H,9090H
        DW      0392BH,061E6H,9090H
        DW      044E8H,0B800H,7777H
        DW      04537H,0FB75H,9090H
        DW      0453DH,0FB74H,9090H
        DW      0454AH,0FB75H,9090H
        DW      04550H,0FB74H,9090H
        DW      04559H,0B000H,7777H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH38i LABEL WORD
	DB	'On-FilE v1.0/1.1  SAVEBOX.EXE ' ;@@XLAT
        DW      02329H,0FEE2H,PATCH38m
        DW      0107AH,0B800H,7777H
        DW      01096H,0FB75H,9090H
        DW      0109CH,0FB74H,9090H
        DW      010AFH,0FB75H,9090H
        DW      010B5H,0FB74H,9090H
        DW      010C0H,0B000H,7777H
        DW      011DEH,0B800H,7777H
        DW      0122DH,0FB75H,9090H
        DW      01233H,0FB74H,9090H
        DW      01240H,0FB75H,9090H
        DW      01246H,0FB74H,9090H
        DW      0124FH,0B000H,7777H
        DW      01400H,0B800H,7777H
        DW      014C8H,0FB75H,9090H
        DW      014CEH,0FB74H,9090H
        DW      014DAH,0FB75H,9090H
        DW      014E0H,0FB74H,9090H
        DW      014E0H,0FB74H,9090H
        DW      014EEH,0FB75H,9090H
        DW      014F4H,0FB74H,9090H
        DW      01501H,0FB75H,9090H
        DW      01507H,0FB74H,9090H
        DW      01510H,0B000H,7777H
        DW      02324H,061E6H,9090H
        DW      02330H,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH


PATCH38m LABEL WORD
        DB      'On-File v1.10  ONFILE.EXE     ' ;@@XLAT
	DW 	00600H,081DBH,PATCH39
	DW	09F52H,0B800H,7777H
	DW	09F98H,0B000H,7777H
	DW	0A1AFH,0B800H,7777H
	DW	0A2C7H,0B000H,7777H
	DW	0A4A3H,0B800H,7777H
	DW	0A514H,0B000H,7777H
	DW	0FFFFH,0FFFFH,0FFFFH

PATCH39 LABEL WORD
        DB      'Freestyle v1.50 -B            ' ;@@XLAT
        DW      00300H,0FDE9H,PATCH39S
        DW      00C32H,0B800H,7777H
        DW      003D8H,0B000H,7777H
        DW      006D1H,061E6H,9090H
        DW      006DAH,061E6H,9090H
        DW      006E5H,061E6H,9090H
        DW      007AAH,0FB75H,9090H
        DW      007B0H,0FB74H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH39S LABEL WORD
        DB      'MF COBOL v1.1 "COM" 01/09/85  ' ;@@XLAT
        DW      03E44H,03354H,PATCH39T
        DW      04FEAH,061E6H,9090H
        DW      04FF2H,061E6H,9090H
        DW      04FFCH,061E6H,9090H
        DW      07F6EH,0B000H,7777H
        DW      07F7CH,0B800H,7777H
        DW      08129H,0FB75H,9090H
        DW      0812FH,0FB74H,9090H
        DW      0814AH,0FB75H,9090H
        DW      08150H,0FB74H,9090H
        DW      08170H,0FB75H,9090H
        DW      08176H,0FB74H,9090H
        DW      07FF5H,000EEH,0090H
        DW      07FFFH,000EEH,0090H
        DW      0800FH,000EEH,0090H
        DW      08013H,000EEH,0090H
        DW      08019H,000EEH,0090H
        DW      0801DH,000EEH,0090H
        DW      0806EH,000EEH,0090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH39T LABEL WORD
        DB      'MF COBOL v1.1 "EXE" 01/09/85  ' ;@@XLAT
        DW      04044H,03354H,PATCH39U
        DW      051EAH,061E6H,9090H
        DW      051F2H,061E6H,9090H
        DW      051FCH,061E6H,9090H
        DW      0816EH,0B000H,7777H
        DW      0817CH,0B800H,7777H
        DW      08329H,0FB75H,9090H
        DW      0832FH,0FB74H,9090H
        DW      0834AH,0FB75H,9090H
        DW      08350H,0FB74H,9090H
        DW      08370H,0FB75H,9090H
        DW      08376H,0FB74H,9090H
        DW      081F5H,000EEH,0090H
        DW      081FFH,000EEH,0090H
        DW      0820FH,000EEH,0090H
        DW      08213H,000EEH,0090H
        DW      08219H,000EEH,0090H
        DW      0821DH,000EEH,0090H
        DW      0826EH,000EEH,0090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH39U LABEL WORD
        DB      'SW.EXE                        ' ;@@XLAT
        DW      0810CH,0161BH,PATCH39V

        DW      0547EH,061E6H,9090H
        DW      05486H,061E6H,9090H
        DW      05490H,061E6H,9090H
        DW      084C0H,0B000H,7777H
        DW      084CEH,0B800H,7777H
        DW      0867BH,0FB75H,9090H
        DW      08681H,0FB74H,9090H
        DW      0869CH,0FB75H,9090H
        DW      086A2H,0FB74H,9090H
        DW      086C2H,0FB75H,9090H
        DW      086C8H,0FB74H,9090H
        DW      08547H,000EEH,0090H
        DW      08551H,000EEH,0090H
        DW      08561H,000EEH,0090H
        DW      08565H,000EEH,0090H
        DW      0856BH,000EEH,0090H
        DW      0856FH,000EEH,0090H
        DW      085C0H,000EEH,0090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH39V LABEL WORD
        DB      'GENTERM.COM v2.61/S3          ' ;@@XLAT
        DW      01DF7H,02DB0H,PATCH39w
        DW      01DFBH,0B800H,7777H
        DW      01E01H,0B000H,7777H
        DW      02AE5H,0FB74H,9090H
        DW      03ADDH,061E6H,9090H
        DW      03AE6H,061E6H,9090H
        DW      03AFDH,061E6H,9090H

        DW      03BBDH,08B52H,05350H    ; replace cursor positioning routine
        DW      03BBFH,07116H,0A152H    ; with bios call
        DW      03BC1H,0B005H,00544H
        DW      03BC3H,0EE0EH,0F8D1H
        DW      03BC5H,0A142H,0D231H
        DW      03BC7H,00544H,000BBH
        DW      03BC9H,0F8D1H,08807H
        DW      03BCBH,08A50H,090C6H
        DW      03BCDH,0EEC4H,09090H
        DW      03BCFH,0B04AH,0B490H
        DW      03BD1H,0EE0FH,0CD02H
        DW      03BD3H,05842H,05A10H
        DW      03BD5H,05AEEH,0585BH

        DW      0FFFFH,0FFFFH,0FFFFH

PATCH39w LABEL WORD
        DB      'GENTERM.BIN                   ' ;@@XLAT
        DW      0010BH,0062DH,PATCH41
        DW      00001H,SCODE3,RCODE2
        DW      00001H,SCODE3A,0000H
        DW      03B4CH,061E6H,9090H
        DW      03B55H,061E6H,9090H
        DW      03B6CH,061E6H,9090H
        DW      02B2CH,0FB74H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH41 LABEL WORD
        DB      'DataStar v1.60                ' ;@@XLAT
        DW      003F0H,08DE8H,PATCH41a
        DW      05BE7H,0B000H,7777H
        DW      05BD3H,0B800H,7777H
        DW      06078H,0FB75H,9090H
        DW      0607DH,0FB74H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH41a LABEL WORD
        DB      'DataStar - FORMGEN.COM v1.60  ' ;@@XLAT
        DW      003F3H,009EBH,PATCH41b
        DW      04327H,0B000H,7777H
        DW      04313H,0B800H,7777H
        DW      047B8H,0FB75H,9090H
        DW      047BDH,0FB74H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH41b LABEL WORD
        DB      'DataStar - REPORT.COM v1.60   ' ;@@XLAT
        DW      0258BH,0C032H,PATCH41c
        DW      08CABH,0B000H,7777H
        DW      08C97H,0B800H,7777H
        DW      08F6DH,0FB75H,9090H
        DW      08F72H,0FB74H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH41c LABEL WORD
        DB      'DataStar - RGEN.COM v1.60     ' ;@@XLAT
        DW      00109H,0EEE9H,PATCH41d
        DW      0302FH,0B000H,7777H
        DW      0301BH,0B800H,7777H
        DW      04E53H,0FB75H,9090H
        DW      04E58H,0FB74H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH41d LABEL WORD
        DB      'DataStar - REDIT.COM v1.60    ' ;@@XLAT
        DW      07000H,08AC8H,PATCH42
        DW      06CA1H,0B000H,7777H
        DW      06C8DH,0B800H,7777H
        DW      08DF1H,0FB75H,9090H
        DW      08DF6H,0FB74H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH42 LABEL WORD
        DB      'StarBurst - SB.OVR v1.02      ' ;@@XLAT
        DW      042C7H,00E74H,PATCH40
        DW      042CDH,0B000H,7777H
        DW      04839H,0B000H,7777H
        DW      0490EH,0B000H,7777H
        DW      042DBH,0B800H,7777H
        DW      04844H,0FB75H,9090H
        DW      0484AH,0FB74H,9090H
        DW      04915H,0FB75H,9090H
        DW      0491BH,0FB74H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

 PATCH40 LABEL WORD
        DB      'Smart Software Mono/Color     ' ;@@XLAT
        DW      00111H,09AE9H,PATCH43
        DW      002A2H,0B000H,7777H
        DW      002BEH,0B000H,7777H
        DW      00332H,0B000H,7777H
        DW      003D4H,0B000H,7777H
        DW      003FCH,0B000H,7777H
        DW      00483H,0B000H,7777H
        DW      005D0H,0B000H,7777H
        DW      00605H,0B000H,7777H
        DW      008AFH,0B000H,7777H
        DW      0065BH,061E6H,9090H
        DW      00672H,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

;PATCH30  LABEL WORD
;        DB    'Vedit ver 1.16d               ' ;@@XLAT
;        DW    00624H,0ACBAH,PATCH98
;        DW    00190H,0B000H,7777H
;        DW    001ADH,0B800H,7777H
;        DW    002B0H,0FB75H,9090H
;        DW    002B6H,0FB74H,9090H
;        DW    00374H,000EEH,0090H
;        DW    00378H,000EEH,0090H
;        DW    0037CH,000EEH,0090H
;        DW    00380H,000EEH,0090H
;        DW    0FFFFH,0FFFFH,0FFFFH

;
;;PATCHxx  LABEL WORD
;;         DB    'IBM Fix-Disk-Organizer 1.0    ' ;@@XLAT
;;         DW    0D4D9H,0F08H,PATCH98
;;         DW    0971AH,0B000H,7777H
;;         DW    09812H,000EEH,0090H
;;         DW    09896H,000EEH,0090H
;;         DW    098A1H,000EEH,0090H
;;         DW    0D4D3H,0B800H,7777H
;;         DW    0D4F6H,0B800H,7777H
;;         DW    0D5C6H,0B800H,7777H
;;         DW    0D772H,0B800H,7777H
;;         DW    0D801H,0B800H,7777H
;;         DW    0D8C1H,0B800H,7777H
;;         DW   0FFFFH,0FFFFH,0FFFFH

PATCH43  LABEL WORD
     DB    'Baby/34                       ' ;@@XLAT
     DW    0CA30H,03231H,PATCH44
     DW    0A02CH,0B000H,7777H
     DW    0A036H,0B800H,7777H
     DW   0FFFFH,0FFFFH,0FFFFH


patch44 label   word
        db     'dBASE III PLUS 1.0 - DBPLUS   ' ;@@XLAT
        dw      37ffh,0b5fh,patch45
        dw      311bh,0b74h,0bebh
        dw      313ah,0b000h,7777h
        dw      3140h,0274h,02ebh
        dw      314fh,5eebh,3bebh
        dw      3155h,0b800h,7777h
        dw      31b9h,0fb0h,16ebh
        dw      3366h,1875h,18ebh
        dw      33b0h,0875h,08ebh
        dw      3565h,1774h,17ebh
        dw      35f9h,0b000h,7777h
        dw      363ch,0b800h,7777h
        dw      3669h,0b000h,7777h
        dw      3689h,0b800h,7777h
        dw      36afh,0c75h,0cebh
        dw      374ch,2674h,26ebh
        dw      379dh,1875h,18ebh
        dw      37e4h,0875h,08ebh
        dw      0ffffh,0ffffh,0ffffh

patch45 label word
        db      'dBASE III PLUS 1.0 - DBA      ' ;@@XLAT
        dw      3bfch,0b5fh,patch45a
        dw      3518h,0b74h,0bebh
        dw      3537h,0b000h,7777h
        dw      353dh,0274h,02ebh
        dw      354ch,5eebh,3bebh
        dw      3552h,0b800h,7777h
        dw      35b6h,0fb0h,16ebh
        dw      3763h,1875h,18ebh
        dw      37adh,0875h,08ebh
        dw      3962h,1774h,17ebh
        dw      39f6h,0b000h,7777h
        dw      3a39h,0b800h,7777h
        dw      3a66h,0b000h,7777h
        dw      3a86h,0b800h,7777h
        dw      3aach,0c75h,0cebh
        dw      3b49h,2674h,26ebh
        dw      3b9ah,1875h,18ebh
        dw      3be1h,0875h,08ebh
        dw      0ffffh,0ffffh,0ffffh

PATCH45a LABEL WORD
	DB	'FoxBASE Plus - Multiuser v1.21' ;@@XLAT
	DW	06888H,0464dh,PATCH45b
	DW	06000H,02000H,02000H
	DW	00000H,00000H,00000H
	DW	06000H,08689H,08689H
	DW	00000H,00000H,00000H
	DW	06000H,0478BH,0478BH
;	DW	00000H,00000H,00000H
	DW	0EBABH,0B800H,07777H
	DW	0EBBBH,0B0B7H,09090H
	DW	0FFFFH,0FFFFH,0FFFFH

PATCH45b LABEL WORD
	DB	'FoxBASE Plus  version 1.20    ' ;@@XLAT
	DW	06888H,00372h,PATCH46
	DW	06000H,0CA80H,0CA80H
	DW	00000H,00000H,00000H
	DW	06000H,002C4H,002C4H
	DW	00000H,00000H,00000H
	DW	06000H,05E8BH,05E8BH
;	DW	00000H,00000H,00000H
	DW	0FDE3H,0B800H,07777H
	DW	0FDF3H,0B0B7H,09090H
	DW	0FFFFH,0FFFFH,0FFFFH


PATCH46 LABEL WORD
        DB      'Norton Editor v1.2            ' ;@@XLAT
        DW      0107H,049A8H,PATCH46a
        DW      0383AH,0B800H,7777H
        DW      0389DH,0B800H,7777H
        DW      03904H,0B000H,7777H
        DW      0404BH,061E6H,9090H
        DW      04052H,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

patch46a label word
        DB      'Norton Editor v1.3            ' ;@@XLAT
        DW      0107H,0b1d7H,PATCH47
        DW      03c8aH,0B800H,7777H
        DW      03cc7H,0B800H,7777H
        DW      03d09H,0B000H,7777H
        DW      044ebH,061E6H,9090H
        DW      044f2H,061E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH47 LABEL WORD
        DB      'Volkswriter 3  v1.0           ' ;@@XLAT
        DW      0170H,002CFH,PATCH48
        DW      0110H,00A00H,00A00H
        DW      0000H,0000H,0000H
        DW      0000H,0275H,0275H
        DW      0000H,0000H,0000H
        DW      01071H,0B800H,7777H
        DW      0107EH,0B000H,7777H
        DW      0125AH,0B000H,7777H
        DW      0FFFFH,0FFFFH,0FFFFH

PATCH48 LABEL WORD
        DB      'SuperWriter  v1.03            ' ;@@XLAT
        DW      0102H,05371H,PATCH49
        DW      0BDEH,0B000H,7777H
        DW      0BEEH,0B800H,7777H
        DW      0FFFFH,0FFFFH,0FFFFH

patch49 label word
        db      'SideKick v1.56A               ' ;@@XLAT
        dw      9040h,4256h,patch50
        dw      1275h,0b000h,7777h
        dw      133bh,0b8b7h,9090h
        dw      0ffffh,0ffffh,0ffffh

patch50 label word
        DB      'Microsoft Word v3.0 - German  ' ;@@XLAT
        DW      00600H,0F758H,PATCH50b
        DW      0FFFFH,0FFFFH,0FFFFH

patch50a label word
        DB      'Microsoft Word v3.0           ' ;@@XLAT
        DW      200BH,2A2AH,PATCH50b
        DW      2542H,42E6H,9090H
        DW      2546H,42E6H,9090H
        DW      2548H,42E6H,9090H
        DW      254EH,61E6H,9090H
        DW      255AH,42E6H,9090H
        DW      255EH,42E6H,9090H
        DW      2567H,61E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

patch50b label word
        DB      'Microsoft Word v3.0 Learn     ' ;@@XLAT
        DW      4093H,204CH,PATCH50d
	DW	1A8BH,061E6H,9090H
	DW	1BA0H,0B800H,7777H
	DW	1AA3H,061E6H,9090H
	DW	1ABBH,061E6H,9090H
	DW	1AD4H,061E6H,9090H
	DW	2B97H,0B800H,7777H
	DW	4B9CH,0FB75H,9090H
	DW	583EH,0B800H,7777H
	DW	58C8H,0B800H,7777H
	DW	631CH,0B800H,7777H
	DW	632DH,0B000H,7777H
	DW	6683H,0B800H,7777H
	DW	82B8H,0B800H,7777H
	DW	82C9H,0B800H,7777H
	DW	0FFFFH,0FFFFH,0FFFFH

patch50c label word
        DB      'Microsoft Word v3.0 Spell     ' ;@@XLAT
        DW      022AH,0000H,PATCH50d
        DW      4284H,42E6H,9090H
        DW      4288H,42E6H,9090H
        DW      4290H,61E6H,9090H
        DW      429AH,42E6H,9090H
        DW      429EH,42E6H,9090H
        DW      42A7H,61E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH


patch50d label word
        DB      'Microsoft Word v3.0 - Intl.   ' ;@@XLAT
        DW      2073H,2A2AH,PATCH50e
        DW      256CH,42E6H,9090H
        DW      2570H,42E6H,9090H
        DW      2578H,61E6H,9090H
        DW      2584H,42E6H,9090H
        DW      2588H,42E6H,9090H
        DW      2591H,61E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

patch50e label word
	DB      'Microsoft Word v3.1           ' ;@@XLAT
	DW	1C8DH,5251H,PATCH50f
	DW	2661H,42E6H,9090H
	DW	2665H,42E6H,9090H
	DW	266DH,61E6H,9090H
	DW	2679H,42E6H,9090H
	DW	267DH,42E6H,9090H
	DW	2686H,61E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH

patch50f label word
        DB      'Microsoft Word v3.1 Spell     ' ;@@XLAT
        DW      1C8DH,01B1H,PATCH51
        DW      4276H,42E6H,9090H
        DW      4280H,42E6H,9090H
        DW      4288H,61E6H,9090H
        DW      4292H,42E6H,9090H
        DW      4296H,42E6H,9090H
        DW      429FH,61E6H,9090H
        DW      0FFFFH,0FFFFH,0FFFFH


patch51	label	word
	db	'The Twin v1.30                ' ;@@XLAT
	dw	1025h,04a8dh,patch51a
	dw	27c5h,0fb75h,9090h
	dw	27cah,0fb75h,9090h
	dw	2855h,0fb75h,9090h
	dw	285ah,0fb75h,9090h
	dw	28b8h,0fb75h,9090h
	dw	28bdh,0fb75h,9090h
	dw	2709h,0fb74h,9090h
	dw	27cfh,0fb74h,9090h
	dw	285fh,0fb74h,9090h
	dw	28c2h,0fb74h,9090h
	dw	2b0dh,061e6h,9090h
	dw	2b19h,061e6h,9090h
	dw	2ae0h,042e6h,9090h
	dw	2aefh,042e6h,9090h
	dw	2acbh,043e6h,9090h
	dw	26b3h,0b000h,7777h
	dw	271bh,0b800h,7777h
	dw	278ah,0b000h,7777h
	dw	2791h,0b800h,7777h
	dw	282fh,0b000h,7777h
	dw	2836h,0b800h,7777h
	dw	288ah,0b000h,7777h
	dw	2891h,0b800h,7777h
	dw	28eeh,0b000h,7777h
	dw	28f5h,0b800h,7777h
	dw	29b4h,0b000h,7777h
	dw	29bbh,0b800h,7777h
	dw	66c2h,0b800h,7777h
	dw	2699h,000eeh,0090h
	dw	26a8h,000eeh,0090h
	dw	26abh,000eeh,0090h
	dw	26c3h,000eeh,0090h
	dw	26d0h,000eeh,0090h
	dw	26dbh,000eeh,0090h
	dw	26f2h,000eeh,0090h
	dw	2712h,000eeh,0090h
	dw	2a81h,000efh,0090h
	dw	2a94h,000efh,0090h
;	dw	2a95h,000efh,0090h
	dw	2aa6h,000efh,0090h
	dw	2ab6h,000efh,0090h
	dw	2b2fh,000efh,0090h
	dw	2b53h,000efh,0090h
	dw	2b9ch,000efh,0090h
	dw	2badh,000efh,0090h
	dw	2bbeh,000efh,0090h
	dw	2bcfh,000efh,0090h
	dw	0002h,00002h,0002h	; 2.07 fakeout flag
	dw	0ffffh,0ffffh,0ffffh

patch51a label word
	db	'The Twin v 1.30 Color-Graphics' ;@@XLAT
	dw	057ah,05053h,patch98
	dw	0147h,0b800h,7777h
	dw	01e2h,0b800h,7777h
	dw	0285h,0b800h,7777h
	dw	0ffffh,0ffffh,0ffffh


PATCH98  LABEL WORD                            
         DB    'IRMA E78 VER. 1.25            ' ;@@XLAT
         DW    0511H,03532H,PATCH99
         DW    0600H,061E6H,9090H
         DW    0606H,061E6H,9090H
         DW    0637H,00820H,07D0H
         DW    089EH,000EEH,0090H
         DW    08A3H,000EEH,0090H
         DW    08A7H,000EEH,0090H
         DW    08ABH,000EEH,0090H
         DW    08B3H,000EEH,0090H
         DW    08C4H,000EEH,0090H
         DW    08C8H,000EEH,0090H
         DW    08CCH,000EEH,0090H
         DW    0CD4H,0B800H,7777H
         DW    0D1BH,0B000H,7777H
         DW    0DB1H,0A126H,1CEBH
         DW    0DF3H,067A1H,0EEBH
         DW    0DF5H,00009H,0090H
         DW    0E8DH,00ACFH,0AC3H
         DW    0EFCH,0E086H,44E8H
         DW    0EFEH,061E6H,90FFH
         DW    0E29H,061E6H,9090H
         DW    0E32H,061E6H,9090H
         DW    0E3DH,061E6H,9090H
         DW    0EFAH,061E6H,9090H
         DW    1A8FH,00820H,07D0H
         DW    1AB3H,00820H,07D0H
         DW    1AE8H,000EEH,0090H
         DW    1AF0H,000EEH,0090H
         DW    1AFEH,00572H,9090H
         DW    1B03H,00D75H,9090H
         DW    1B23H,000EEH,0090H
         DW    1B6DH,000EEH,0090H
         DW    1B83H,000EEH,0090H
         DW    1BB1H,084ECH,08EBH
         DW    1BD5H,084ECH,08EBH
         DW    1BF2H,084ECH,08EBH
         DW    1C08H,0A8ECH,39EBH
         DW    1C19H,000EEH,0090H
         DW    1C23H,000EEH,0090H
         DW    1C41H,000EEH,0090H
         DW   0FFFFH,0FFFFH,0FFFFH

PATCH99  LABEL WORD
         DB    '******** END OF TABLE ********' ;@@XLAT
         DB    128 DUP('PATCH   ') ; ROOM FOR PATCHING

         %OUT  CODE
         DB    16 DUP('STACK   ')
STACKEND DW    0
DATASEG  DW    0             ; SEGMENT ADDRESS OF I/O AREA
READSIZE DW    0             ; NUMBER OF BYTES READ
MLINKVER DW    400           ; DEFAULTS TO 4.00

         IF    VIDPATCH
FGBGOFF  DW    4
         ELSE
FGBGOFF  DW    2             ; OR 4 IF BACKGROUND
         ENDIF

RTVIDRAM DW    0             ; SEG ADDRESS OF ALT VIDEO RAM
OKMSG    DB    13,10,'Fixup completed for ' ;@@XLAT
OKMSGDES DB    '??????????????????????????????',13,10,'$'
ERMNOML  DB    13,10,'Multitasking is not active!',13,10,'$' ;@@XLAT
ERMNOVID DB    13,10,'VIDRAM must be executed first!',13,10,'$' ;@@XLAT
ERFNFND  DB    13,10,'Cannot find program to be patched!',13,10,'$' ;@@XLAT
ERBDPATH DB    13,10,'Invalid path specified!',13,10,'$' ;@@XLAT
ERMOPEN  DB    13,10,'File ERROR #' ;@@XLAT
FILERR   DB    '?',13,10
ERMNOSUP DB    13,10,'Program not supported!',13,10,'$' ;@@XLAT
ERMWRITE DB    13,10,'Rewrite to disk failed!',13,10,'$' ;@@XLAT
PRE20    DB    'N'           ;1 Pre DOS 2.0 flag ;@@XLAT
HANDLE   DW    0                ;2 File handle for DOS
RWPTRL   DW    0                ;2 Read/Write Pointer LOW
RWPTRH   DW    0                ;2 Read/Write Pointer HIGH
BLOCKNO  DW    0                ;2 Counter for number of 64k blocks read (you
                                ;2  see we are reading 1 less than 64k)
TWO      DW    0002H
;--------------------------------------------------------------------;
;                          INITIALIZATION                            ;
;--------------------------------------------------------------------;

BEGIN    LABEL NEAR
         MOV   SP,OFFSET STACKEND    ; SET STACK POINTER

         MOV   AH,030H               ;1 Get DOS rev
         INT   21H                   ;1
         CMP   AL,0                  ;1 Is DOS pre 2.0
         JNZ   ITS20                 ;1
         MOV   [PRE20],'Y'           ;1 Set pre 2.0 flag
ITS20:
         MOV   AL,DS:[80H]
         OR    AL,AL
         JNZ   B_2

;**** BEG REWRITE PTR114	 
         LEA   DI,FILES              ; ADDRESS OF FILES SUPPORTED SCREENS
	 
SCR_LOOP:
	 CMP   BYTE PTR [DI],0
	 JZ	FIL_DUN
	 PUSH	DI		; SAVE FILE POINTER
	 CALL  CLEAR                 ; CLEAR THE SCREEN
         MOV   CX,12                 ; COUNTER FOR # OF FILES DISPLAYED
         LEA   DX,COPYR              ; LOAD ADDRESS OF COPYRITE MSG.
         CALL  DISP
	 POP	DI
	 
FIL_LOOP:
	 MOV   DX,DI		     ; DISPLAY FILE NAME
         CALL  DISP
	 MOV	DI,DX		; RETURNS NEXT MESSAGE
	 CMP	BYTE PTR [DI],0
         LOOPNZ  FIL_LOOP
	 
         PUSH  DI
	 MOV	DX,OFFSET CONT
	 CALL	DISP
         MOV      AX,0800H	; FIXED FROM 7 -> 8 TO ALLOW ^C CHECK
         INT      21H		; WAIT FOR KEY
	 POP   DI
	 JMP   SCR_LOOP
; **** END REWRITE PTR114
	 
FIL_DUN: MOV   AL,0                  ;1 ok exit code
         JMP   F_2                   ; RETURN TO DOS
B_2:
         MOV   AX,DS                 ; COMPUTE DTA SEGMENT ADDRESS
         MOV   BX,OFFSET PROGEND
         ADD   BX,15
         MOV   CL,4
         SHR   BX,CL
         ADD   AX,BX
         MOV   [DATASEG],AX
         XOR   AX,AX
         MOV   ES,AX
	 MOV   BX,MLINT * 4		; GET CORRECT INT VECTOR	PTR114
         MOV   AX,WORD PTR ES:[BX+2]	; MLINK installed?		PTR114
         OR    AX,AX			;				PTR114
         JZ    NOTBG			;1 ML not active - patch for FG
	 
         MOV   BX, WORD PTR ES:[BX]    ; 2.05 GET MLINK'S OFFSET	PTR114
         MOV   ES,AX			;				PTR114
	 CMP   BYTE PTR ES:[0],MLSIGN	; TEST SIGNATURE		PTR114
	 JNZ   NOTBG			;				PTR114
	 
         MOV   AX, WORD PTR ES:[BX-3]  ; 2.05 GET VERSION
         MOV   [MLINKVER], BX          ; 2.05 SAVE IT FOR LATER
	 
         MOV   SI,ES:[58H]           ; LOAD CURRGNID
         OR    SI,SI
         JZ    NOTBG
         MOV   [FGBGOFF],4           ; INDICATES BACKGROUND
         MOV   AX,ES:[SI+0D4H]       ; GET RTVIDRAM
         MOV   [RTVIDRAM],AX
         TEST  BYTE PTR ES:[SI+0D6H],01H
         JNZ   NOTBG
         JMP   ERRNOVID
NOTBG:
         XOR   BX,BX                 ;2
         MOV   BL,DS:[80H]           ;2
         ADD   BX,81H                ;2
         MOV   BYTE PTR [BX],0       ;2 End for ASCIIZ
         MOV   DX,82H                ;2 Skip space
         MOV   AX,3D02H              ;2 Open for read/write
         INT   21H                   ;2
         JNC   $+5                   ;2
         JMP   ERROPEN               ;2

         MOV   HANDLE,AX             ;2
         MOV   BX,AX                 ;2
         MOV   CX,-1                 ;2 Try to read 64k
         MOV   AH,3FH                ;2
         PUSH  DS                    ;2
         MOV   DS,[DATASEG]          ;2
         XOR   DX,DX                 ;2
         INT   21H                   ;2
         POP   DS                    ;2
         JNC   $+5                   ;2
         JMP   ERROPEN               ;2
         MOV   [READSIZE],AX         ;2

         MOV   ES,[DATASEG]
         LEA   SI,PATCHTAB

PTCHLOOP LABEL NEAR
         MOV   BX,[SI+30]            ; LOCATION TO TEST
         CMP   BX,0FFFFH             ; CHECK FOR END OF TABLE
         JE    PTCHNSUP
         SUB   BX,0100H
         MOV   AX,[SI+32]            ; VALUE TO TEST FOR
         CMP   AX,ES:[BX]
         JE    PTCHYES
PTCHNEXT LABEL NEAR
         MOV   SI,[SI+34]
         CMP   SI,0FFFFH
         JNE   PTCHLOOP
PTCHNSUP LABEL NEAR
         JMP   ERRNOSUP              ; ERROR - END OF TABLE
PTCHYES  LABEL NEAR
;        CMP   AX,0100H              ; Check for Symphony(100 should be unique)
         MOV   AX,[SI+36]            ;*** See if we are to scan any
         CMP   AX,0000FH
         JNE   $+5                   ; See if we need to enter lotus routine
         JMP   PUKE                  ; An appropriate name.
         CMP   AX,00001H             ;*** Indicates a scan if 1
         JNE   NOSCAN
         JMP   DOSCAN                ;*** ENTER SCANNER
NOSCAN:
         PUSH  SI
         ADD   SI,36
PTCHLOP2 LABEL NEAR
         MOV   BX,SI
         ADD   BX,[FGBGOFF]          ; ADDS 2 IF FG, 4 IF BG
         MOV   AX,[BX]               ; LOAD REPLACEMENT TO AX
         MOV   BX,[SI]               ; TARGET OFFSET
         SUB   BX,0100H
         ADD   BX,[BLOCKNO]          ;2 Add 1 for each 64k block
         CMP   AX,7777H              ; CHECK IF VIDEO RAM SEG PLUG

         IF    VIDPATCH
         JE    PTCHNXT2
         JMP   PTCHREG
         ELSE
         JNE   PTCHREG
         ENDIF

         MOV   AX,[RTVIDRAM]
PTCHREG:
         MOV   ES:[BX],AL
         CMP   WORD PTR [SI+4],0090H ; CHECK IF 1-BYTE PATCH
         JE    PTCHNXT2
         MOV   ES:[BX+1],AH
PTCHNXT2:
         ADD   SI,6
         CMP   WORD PTR [SI],0FFFFH
         JE    PTENDLOOP
	cmp	word ptr [si],0002   ;2.07 check for "fake out" flag
	jne	no_fake		     ;2.07
	call	fakeout		     ;2.07 fake out the program
	jmp	ptchlop2	     ;2.07

no_fake:
         CMP   WORD PTR [SI],0       ;2 Check if in next 64K
         JNE   PTCHLOP2
         PUSH  SI                    ;2
         CALL  NEXT64                ;2 Read in next 64k of file
         INC   [BLOCKNO]             ;2 Up one for each 64k block
         POP   SI
         ADD   SI,6                  ;2 Skip this entry
         JMP   PTCHLOP2              ;2 Continue as usual
PTENDLOOP:
         POP   SI                    ; RECOVER ADDRESS OF DESCRIPTION
WRTFILE:
         LEA   DI,OKMSGDES           ; COPY DESCRIPTION TO MESSAGE AREA
         PUSH  DS
         POP   ES
         MOV   CX,30
         REP   MOVSB

         MOV   AX,4200H              ;2 Set pointer to last 64k read
         MOV   CX,RWPTRH             ;2
         MOV   DX,RWPTRL             ;2
         MOV   BX,[HANDLE]           ;2
         JNC   $+5                   ;2
         JMP   ERROPEN               ;2
         INT   21H                   ;2

         MOV   CX,[READSIZE]         ;2 Amount of last read
         MOV   AH,40H                ;2
         MOV   BX,[HANDLE]           ;2
         PUSH  DS                    ;2
         MOV   DS,[DATASEG]          ;2
         XOR   DX,DX                 ;2
         INT   21H                   ;2 Write it out
         POP   DS                    ;2
         JNC   $+5                   ;2
         JMP   ERROPEN               ;2

         MOV   AH,3EH                ;2 Close file
         MOV   BX,[HANDLE]           ;2
         INT   21H                   ;2
         JNC   $+5                   ;2
         JMP   ERROPEN               ;2
         MOV   AL,0                  ;1 ok exit code
         LEA   DX,OKMSG
         JMP   SHORT FINISH

ERRNOML  LABEL NEAR
         MOV   AL,4                  ;1 No MultiLink error exit code
         LEA   DX,ERMNOML
         JMP   SHORT FINISH
ERRNOVID LABEL NEAR
         MOV   AL,3                  ;1 User error exit code
         LEA   DX,ERMNOVID
         JMP   SHORT FINISH
ERROPEN  LABEL NEAR
         CMP   AL,2
         JNE   ERO2
         LEA   DX,ERFNFND
         JMP   FINISH
ERO2:
         CMP   AL,3
         JNE   ERO3
         LEA   DX,ERBDPATH
         JMP   FINISH
ERO3:
         ADD   AL,'0'
         MOV   [FILERR],AL
         MOV   AL,3                  ;1 User error exit code
         LEA   DX,ERMOPEN
         JMP   SHORT FINISH
ERRNOSUP LABEL NEAR
         MOV   AL,3                  ;1 User error exit code
         LEA   DX,ERMNOSUP
         JMP   SHORT FINISH
ERRWRITE LABEL NEAR
         MOV   AL,2                  ;1 system error exit code
         LEA   DX,ERMWRITE
         JMP   SHORT FINISH

FINISH   LABEL NEAR
         PUSH  AX                    ;1 Save exit code
         MOV   AH,9                  ; WRITE TO CONSOLE
         INT   21H
         POP   AX                    ;1 Restore exit code
F_2:
         CMP   [PRE20],'Y'           ;1 Is DOS pre 2.0
         JE    EXIT11                ;1 Yes
         MOV   AH,04CH               ;1 Terminate process (pass error code AL)
         INT   21H                   ;1
EXIT11:
         INT   20H                   ; TERMINATE
;-----------------------------------------------------------------------------;
; This subroutine will write out the present file buffer and read in up to an ;
; additional 64k of the file.  This method allows for an unlimited file size  ;
; to be fixable.                                                              ;
;-----------------------------------------------------------------------------;
NEXT64   PROC   NEAR

         CMP    [READSIZE],-1           ;2 64k last read?
         JE     $+5
         JMP    ERRTABLE                ;2 Vidfix table error or file error

         MOV    AX,4200H                ;2 Set pointer to last 64k read
         MOV    CX,RWPTRH               ;2
         MOV    DX,RWPTRL               ;2
         MOV    BX,[HANDLE]             ;2
         INT    21H                     ;2
         JNC    $+5                     ;2
         JMP    ERROPEN2                ;2

         MOV    CX,[READSIZE]           ;2 Amount of last read
         MOV    AH,40H                  ;2
         MOV    BX,[HANDLE]             ;2
         PUSH   DS                      ;2
         MOV    DS,[DATASEG]            ;2
         XOR    DX,DX                   ;2
         INT    21H                     ;2 Write it out
         POP    DS                      ;2
         JNC    $+5                     ;2
         JMP    ERROPEN2                ;2

         MOV    AX,4201H                ;2 Find out where new pointer is
         XOR    CX,CX                   ;2
         XOR    DX,DX                   ;2
         MOV    BX,[HANDLE]             ;2
         INT    21H                     ;2
         JNC    $+5                     ;2
         JMP    ERROPEN2                ;2
         MOV    RWPTRL,AX               ;2
         MOV    RWPTRH,DX               ;2

         MOV    BX,[HANDLE]             ;2
         MOV    CX,-1                   ;2 Try to read 64k
         MOV    AH,3FH                  ;2
         PUSH   DS                      ;2
         MOV    DS,[DATASEG]            ;2
         XOR    DX,DX                   ;2
         INT    21H                     ;2
         POP    DS                      ;2
         JNC    $+5                     ;2
         JMP    ERROPEN                 ;2
         MOV    [READSIZE],AX           ;2
         RET


;******************************************************************************
;* This routine changes the equipment flag at 40:10 to make the application   *
;* think it has a monochrome monitor instead of what may be there. This sub-  *
;* routine first checks to see it MultiLink is there, if not it returns. But, *
;* if MultiLink is active it retrieves its region id and then looks to see if *
;* video management is active. If video management is active, it returns.     *
;* Otherwise, it adjusts the equipment flag to make the application think it  *
;* has a black&white monitor. This routine is selectively called. JSW         *
;******************************************************************************

vidswt	dw	1DE8h			; offset into MultiLink 4.0 of MMVIDSWT
RTGRAPH	EQU	8eh			; offset of RTGRAPH

fakeout	label near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es
	xor	ax,ax			; look for MultiLink at 0:1fe
	mov	es,ax
	mov	ax,es:[1feh]
	or	ax,ax			; is MultiLink there ?
	jz	no_need2		; if zero - NO
	mov	es,ax			; address MultiLink
	mov	al,es:[0]
	cmp	al,0e9h			; check for MultiLink's "jump"
	jne	no_need2		; not equal - No MultiLink
	cmp	[mlinkver],303		; is it 3.02 ?
	jb	no_vidswt
	cmp	[mlinkver],303
	jne	its_400
	mov	[vidswt],0fe8h		; offset for 3.03

its_400:
	mov	si,[vidswt]
	mov	ax,es:[si]
	or	ax,ax			; is there video switching
	jnz	no_need2		; yes, return

no_vidswt:
	cmp	[fgbgoff],2	; are we in the foreground?
	je	no_need2	; yes, return
        mov     ax,40h          ; access 40:10 to change equipment flag
        mov     es,ax           ; to reflect a mono monitor
        mov     al,byte ptr es:[10h]
        and     al,30h
        cmp     al,30h
        jz      no_need2
        and     al,0cfh         ; make application think it has b&w
        mov     byte ptr es:[10h],al

no_need2:
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
;******************************************************************************
ERRTABLE:
         MOV    AH,3EH                  ;2 Close file
         MOV    BX,[HANDLE]             ;2
         INT    21H                     ;2
         POP    DX                      ;2 Clear call to this routine
         LEA    DX,ERMTABLE             ;2
         MOV    AL,2                    ;2
         JMP    FINISH                  ;2

ERMTABLE DB     13,10,'VIDFIX table error or file corrupted!',13,10,'$' ;@@XLAT

ERROPEN2:
         PUSH   AX
         MOV    AH,3EH               ;2 Close file
         MOV    BX,[HANDLE]          ;2
         INT    21H                  ;2
         POP    AX
         ADD    AL,'0'
         MOV    [FILERR],AL
         MOV    AL,3                  ;1 User error exit code
         POP    DX                   ;2 Clear call to this subroutine
         LEA    DX,ERMOPEN
         JMP    FINISH

NEXT64   ENDP

;-----------------------------------------------------------------------------;
DISP     PROC     NEAR

         PUSH     CX
         MOV      SI,DX
         CLD
DISPLP:
         LODSB
         CMP      AL,'$'
         JE       DISPEND
         MOV      BX,07
         MOV      AH,14
         INT      10H
         JMP      DISPLP
DISPEND:
         MOV      DX,SI
         MOV      DI,DX
         POP      CX
         RET

DISP     ENDP


;----------------------------------;
CLEAR    PROC    NEAR
;
         MOV     AX,0200H          ; SET CURSOR
         MOV     DX,0              ; TOP LEFT
         MOV     BX,0              ; CURRENT PAGE
         INT     10H
;
         MOV     DX,2479H
         MOV     CX,0
         MOV     AX,600H
         MOV     BH,7
         INT     10H
         RET
CLEAR    ENDP
         PAGE
;----------------------------------------------------------------------------;
; Scanning routine data area

STEXT    DB      'Attempting fix for ' ;@@XLAT
STEXT2   DB      '??????????????????????????????',13,10,'$'
stext3	db	'has not been fixed!',13,10,36 ;@@XLAT

;******************************************************************************
;* The word set_flag is used to indicate whether or not a portion of code has *
;* been altered during the vidfix/vidpatch operation. JSW		      *
;******************************************************************************
set_flag	dw	0			;2.07 (JSW)


ENDSCAN  DW      0                 ; Check length for scans
SAVESCD  DW      0      ;*** Save area for ptr to scode in vidfix table
SAVERCD  DW      0      ;*** Save area for ptr into vidfix table of rcode

;******************************************************************************
;*                                                                            *
;* When a 0001H address is found then it is assumed that the program is to be *
;* scanned either to adjust the address values in the vidfix table or to find *
;* a certain sequence of bytes to replace, such as programming the crt cont-  *
;* roller, or both. Upon entrance to this routine the registers are set as    *
;* follows:                                                                   *
;*      SI - Points to description      ES - Is the data files seg address    *
;*                                                                            *
;* The routine extracts the necessary address and/or information from the vid-*
;* fix table. If it does not find the code that it is to scan for, it adjusts *
;* SI to the next vidfix table and jumps to the label PTCHLOOP, if it finds   *
;* the requested code it looks to see if there is replacement code, indicated *
;* by an address in the 3 entry of the vidfix table or a zero in that place.  *
;* If there is replacement code, then it replaces the code and continues      *
;* checking to see if there is more scanning to do.  If not, it jumps back to *
;* the label PTCHLOP2 with SI pointing to the first address to be altered via *
;* vidfix.                                                                    *
;*               Written 12/31/85   by: Jeffrey S. Weyrich                    *
;*                                                                            *
;* Our heartfelt thanks to David A. Morrow who wrote a scanning routine for   *
;* (gag) Symphony 1.00 and in doing so provided code which I adjusted to make *
;* the scanning general purpose.                                              *
;*                                                                            *
;******************************************************************************

DOSCAN   LABEL   NEAR
         PUSH    SI                ; Save pointer
         PUSH    ES                ;*** Save data area address
         PUSH    DS                ;***
         POP     ES                ;***
         MOV     CX,30             ;***
         LEA     DI,STEXT2         ;*** Copy description to message
         CLD                       ;***
         REP     MOVSB             ;***
         LEA     DX,STEXT          ;*** Print Message
         MOV     AH,9
         INT     21H
         POP     ES
         POP     SI                ;*** Restore SI
         PUSH    SI                ;*** Save it again

SCNRT:   MOV     BX,[SI+38]        ;*** BX points to code to scan for
         MOV     [SAVESCD],BX      ;*** Save ptr to scode addr in vidfix table
         ADD     SI,40             ;*** SI points to rcode addrs
         MOV     [SAVERCD],SI      ;*** Save ptr to rcode addr in vidfix table
         SUB     SI,40             ;*** Reset SI
SCNRT1:  XOR     CH,CH             ;*** Use CX to calc length of scan code
         MOV     CL,BYTE PTR [BX]  ;***
         INC     BX                ;*** BX points to 1st byte to scan for
         MOV     DX,CX             ;***
         ADD     DX,BX             ;*** DX is end of code to find
         MOV     ENDSCAN,DX        ;
         MOV     DX,BX             ;*** DX is remainder of code to find
         INC     DX                ;*** Point to rest of code we're looking for
         MOV     BL,BYTE PTR [BX]  ;*** BL has 1st byte to find
         CALL    SCANIT            ; Scan program for code
         JZ      CKAGAIN           ; Code not found check for already fixed

         MOV     BX,[SAVERCD]      ;*** Code found
         MOV     BX,[BX]           ;*** Get value from vidfix table
         MOV     AX,BX             ;***
         CMP     AX,0000H          ;*** See if we have rcode or to adj table
         JZ      ADJTABLE          ;*** Adjust addresses in vidfix table
         MOV     BX,[SAVESCD]      ;*** Addrs of scode
         MOV     BL,BYTE PTR [BX]  ;*** Get length
         XOR     BH,BH             ;***
         SUB     DI,BX             ;*** Calc dest for replacement code
         MOV     BX,AX             ;***
         XOR     CH,CH             ;***
         MOV     CL,BYTE PTR [BX]  ;***
         MOV     SI,BX             ;***
         INC     SI                ;*** SI points to replacement code
         REP     MOVSB             ; Replace code
         MOV     BX,[SAVERCD]      ;*** Get index into vidfix table for rcode
         INC     BX                ;***
         INC     BX                ;*** BX points to next table entry
         MOV     AX,[BX]           ;***
         CMP     AX,0001H          ;*** see if we need to scan more
         JE      SCAN_MORE         ;*** YUP !!!
         MOV     SI,BX             ;*** NOPE
         JMP     PTCHLOP2          ;*** Table doesn't need altered

SCAN_MORE:
         INC     BX                ;*** Keep scanning
         INC     BX                ;*** BX points to next vidfix table entry
         MOV     AX,BX             ;*** Temp save of BX
         MOV     BX,[BX]           ;***
         MOV     [SAVESCD],BX      ;***
         MOV     BX,AX             ;*** Restore BX to reset SAVERCD
         INC     BX                ;***
         INC     BX                ;***
         MOV     [SAVERCD],BX      ;*** Save ptr into vidfix table
         MOV     BX,[SAVESCD]      ;*** BX points to code to scan for
         JMP     SCNRT1            ;***

ADJTABLE:
         MOV     BX,[SAVERCD]      ;*** BX is index into vidfix table
         INC     BX                ;***
         INC     BX                ;*** BX points to address to adjust
         PUSH    BX                ;*** Save it
         MOV     CX,DI             ; Temp save memory pointer
         SUB     DI,[BX]           ; Calc new offset value
         ADD     DI,0100H          ; Calc DEBUG offset
ADJ1:
         MOV     AX,[BX]           ; Get data address
         CMP     AX,0FFFFH         ; End of table?
         JE      ADJOUT            ; Yes
         ADD     AX,DI             ; Calc new offset value
         MOV     [BX],AX           ; Program new value into vidfix table
         ADD     BX,6              ; Next data address
         JMP     ADJ1              ; Do whole table
ADJOUT:
         POP     SI                ; Restore pointer to description
         JMP     PTCHLOP2          ;*** Continue normal vidfix

CKAGAIN: MOV     BX,[SAVERCD]      ;*** See if there is rcode
         MOV     BX,[BX]           ;*** Get address of rcode into bx
         CMP     BX,0000H          ;*** See if we need to adjust vidfix table
         JZ      ADJTABLE          ;*** YES adjust it
         XOR     CH,CH             ;*** NO
         MOV     CL,BYTE PTR [BX]  ;***
         INC     BX                ;*** BX points to 1st byte of code to find
         MOV     DX,BX             ;***
         ADD     DX,CX             ;***
         MOV     [ENDSCAN],DX      ;***
         DEC     CX
         SUB     DX,CX             ;*** DX is end of code to find
         MOV     BL,BYTE PTR [BX]  ;*** BL has 1st byte to find
         CALL    SCANIT            ;***
         JNZ     TOSCAN1           ;*** Fixed before, see if we need to do more
         POP     SI                ;*** Check rest of vidfix tables
         ADD     SI,34             ;***
         MOV     SI,[SI]           ;*** Pointer to next vidfix table
         JMP     PTCHLOOP          ;***

TOSCAN1:
         JMP     SCNRT1            ;***
;----------------------------------------------------------------------------;
; Scanning routine, on entry BL=1st byte of string, DX=pointer to rest of    ;
; string and the variable 'ENDSCAN' = length of string+1.  On exit zero flag ;
; set if string not found, DI points to end of found string +1.              ;
;----------------------------------------------------------------------------;
SCANIT   LABEL   NEAR
         CLD
         MOV     CX,READSIZE       ;
         XOR     DI,DI
NEXTS:
         MOV     AL,BL             ; Get 1st byte to scan for
         REPNE   SCASB             ; Locate 1st byte
         MOV     SI,DX             ; Code to check for
         REPE    CMPSB             ; Is this the code
         OR      CX,CX             ; Searched through file?
         JNZ     NEXTS2            ; No, not yet
         RET                       ; Code not found return
NEXTS2:
         CMP     SI,ENDSCAN        ; Was all of the search code equal?
         JNZ     NEXTS             ; No, try again.
         OR      CX,CX             ; Clear ZERO flag
         RET                       ; String found, SI -> end of string+1

;******************************************************************************
;*                                                                            *
;* The following sections of code is not executed. It is entered in the vid-  *
;* fix tables and is used by the scanning routine. A new entry must be made if*
;* required by the application. The first byte MUST be the length of the code.*
;* The string to be scanned for must terminate with a NOP and define a word   *
;* at the end of the string to scan for as is done in these entries.          *
;*                                                                            *
;******************************************************************************

SCODE1   LABEL   BYTE
         DB      ENDSC1-SCODE1-1   ;*** LENGTH OF STRING
         MOV     AX,050H           ; This code is to be searched for
         MUL     DX                ;
         ADD     CX,AX             ;
         NOP                       ; This byte will cause termination of loop
ENDSC1   DW      $                 ; This word contains its own address. Used
                                   ; as a check by the scanning routine.

RCODE1   PROC    FAR
         DB      ENDRC1-RCODE1-1   ;*** LENGTH OF CODE OR STRING
         MOV     CH,DL             ; This is the replacement code for SCODE1
         PUSH    SI                ;*** and SCODE2
         PUSH    DI
         PUSH    BP
         PUSH    BX
         MOV     AH,2
         MOV     DX,CX
         XOR     BX,BX
         INT     10H
         POP     BX
         POP     BP
         POP     DI
         POP     SI
         RET                       ; This must be a far return
RCODE1   ENDP
ENDRC1   DW      $                 ; SI will point 1 past check code


SCODE1A  LABEL   BYTE              ;*** Also used by Lotus 2
         DB      ENDSC1A-SCODE1A-1 ;*** LENGTH OF STRING
         DB      002H,0E4H,061H    ; These are the code bytes that preceed
         DB      050H,024H,090H    ; the reference offset for vidram.
ENDSC1A  DW      $


DAT      EQU    0040H                   ;*** Lotus 2 monochrome monitor
SCODE2   LABEL   BYTE
         DB      ENDSC2-SCODE2-1        ;*** LENGTH OF BYTE
         MOV     AX,CS:[DAT]
         MUL     DX
         ADD     CX,AX
         NOP
ENDSC2   DW      $

DAT1    equ     0050h

scode2a label byte                      ;2.04 *** lotus 2.01
        db      endsc2a-scode2a-1
        mov     ax,[dat1]
        mul     dx
        add     cx,ax
        nop
endsc2a dw      $

RCODE2  LABEL   BYTE
        DB      ENDRCD2-RCODE2-1
        DB      053H,050H,0A1H,052H,004H,05CH,0FBH,0D1H,0D2H,031H
        DB      0DBH,031H,0C6H,088H,090H,090H,090H,090H,0B4H,090H
        DB      0CDH,002H,05AH,010H,058H,05BH
ENDRCD2 DW      $

SCODE3  LABEL   BYTE
        DB      ENDSC3-SCODE3-1
        DB      052H,08BH,016H,090H
ENDSC3  DW      $

SCODE3A LABEL   BYTE
        DB      ENDSC3A-SCODE3A-1
        DB      00H,0E4H,061H,050H,024H,0FCH,090H
ENDSC3A DW      $


PUKE    LABEL   NEAR
        PUSH    SI
        PUSH    ES
        PUSH    DS
        POP     ES
        MOV     CX,30           ; COPY NAME TO STRING
        LEA     DI,STEXT2
        CLD
        REP     MOVSB
        LEA     DX,STEXT
        MOV     AH,9
        INT     21H             ; PRINT MESSAGE
        POP     ES
        POP     SI
        PUSH    SI              ; SAVE FOR LATER USE
        MOV     CX,[READSIZE]
        MOV     AL,0E6H         ; BYTE TO SCAN FOR
        XOR     DI,DI           ; DI IS POINTER INTO .SET FILE FOR SCAN

E6_SCAN:
        REPNE   SCASB           ; SEARCH
        CMP     BYTE PTR ES:[DI],61H    ; CHECK FOR 61
        JE      FOUND_E6
        CMP     CX,00H          ; SEE IF SCANNED ENTIRE .SET FILE
        JZ      DO_B000

E6_SCAN1:
        INC     DI
        JMP     E6_SCAN         ; KEEP GOING

NO_MORE_E6:
        POP     CX              ; DISCARD CX
        JMP     DO_B000

FOUND_E6:
        MOV     ES:[DI-1],9090H ; NOP OUT THE BEEP
	dec	[set_flag]	; 2.07 this says that we have changed something
        JMP     E6_SCAN1        ; SEARCH SOME MORE


DO_B000:                        ; YOU GUESS

        IFE     VIDPATCH
        LEA     DI,VID_STR1     ; STRING TO SCAN FOR VIDEO RAM LOCATIONS
        XOR     BX,BX
        MOV     BL,BYTE PTR [DI]
        INC     DI              ; DI POINTS TO REST OF STRING
        MOV     DX,DI
        ADD     DX,VID_STR_LEN-1
        MOV     [ENDSCAN],DX
        SUB     DX,VID_STR_LEN-1
        MOV     CX,8            ; NUMBER OF X TIME LOOK. JUST IN CASE
        PUSH    CX

SCAN_B0:
        CALL    SCANIT          ; LOOK FOR STRING
        JZ      NO_B000         ; NOT FOUND
	dec	[set_flag]	; 2.07 this says that we have changed something
        SUB     DI,5            ; POINT DI IN THE RIGHT DIRECTION
        MOV     AX,[RTVIDRAM]   ; GET VIDRAM ADDRESS INTO AX
        MOV     ES:[DI],AX      ; PUT IT INTO .SET FILE
        ADD     DI,5
        MOV     AX,CX           ; SAVE CX TEMP
        POP     CX
        DEC     CX
        PUSH    CX
        MOV     CX,AX           ; GET IT BACK
        JNZ     SCAN_B0

NO_B000:
        POP     CX              ; DISCARD CX

DO_B800:
        LEA     DI,VID_STR2     ; STRING FOR B800
        XOR     BX,BX           ; CLEAR IT
        MOV     BL,BYTE PTR [DI]
        INC     DI
        MOV     DX,DI
        ADD     DX,VID_STR_LEN-1
        MOV     [ENDSCAN],DX
        SUB     DX,VID_STR_LEN-1
        MOV     CX,8
        PUSH    CX

SCAN_B8:
        CALL    SCANIT
        JZ      NO_B800         ; NOT FOUND
	dec	[set_flag]	; 2.07 this says that we have changed something
        SUB     DI,5
        MOV     AX,[RTVIDRAM]
        MOV     ES:[DI],AX
        ADD     DI,5
        MOV     AX,CX
        POP     CX
        DEC     CX
        PUSH    CX
        MOV     CX,AX
        JNZ     SCAN_B8         ; KEEP LOOKING

NO_B800:
        POP     CX              ; DISCARD IT
        ENDIF

DO_CURPOS:
        LEA     DI,SCODE1
        XOR     BX,BX
        MOV     BL,BYTE PTR [DI]
        INC     DI
        ADD     BX,DI
        MOV     [ENDSCAN],BX
        SUB     BX,DI
        MOV     BL,BYTE PTR [DI]
        INC     DI
        MOV     DX,DI
        MOV     CX,2            ; NUMBER OF TIMES TO SCAN
        PUSH    CX

SCAN_CURP1:
        CALL    SCANIT
        JZ      NO_SCODE1
	dec	[set_flag]	; 2.07 this says that we have changed something
        PUSH    BX
        PUSH    DI
        MOV     DI,DX
        SUB     DI,2
        MOV     BL,BYTE PTR [DI]
        ADD     DI,2
        MOV     DX,DI
        POP     DI
        SUB     DI,BX           ; ADJUST DI FOR REPLACEMENT
        PUSH    CX
        LEA     SI,RCODE1
        XOR     CX,CX
        MOV     CL,BYTE PTR [SI]
        INC     SI              ; SI NOW POINTS TO REPLACEMENT CODE
        REP     MOVSB           ; REPLACE IT
        POP     CX
        INC     DX
        POP     BX
        MOV     AX,CX           ; SAVE CX TEMP
        POP     CX
        DEC     CX
        PUSH    CX
        MOV     CX,AX           ; RESTORE IT
        JNZ     SCAN_CURP1

NO_SCODE1:
        POP     CX              ; DISCARD

DO_SCODE2:
        LEA     DI,SCODE2
        XOR     BX,BX
        MOV     BL,BYTE PTR [DI]
        INC     DI
        ADD     BX,DI
        MOV     [ENDSCAN],BX
        SUB     BX,DI
        MOV     BL,BYTE PTR [DI]
        INC     DI
        MOV     DX,DI
        MOV     CX,2            ; NUMBER OF TIMES TO SCAN
        PUSH    CX              ; SAVE IT

SCAN_CURP2:
        CALL    SCANIT
        JZ      NO_SCODE2
	dec	[set_flag]	; 2.07 this says that we have changed something
        PUSH    BX
        PUSH    DI
        MOV     DI,DX
        DEC     DI
        DEC     DI
        MOV     BL,BYTE PTR [DI]
        INC     DI
        INC     DI
        MOV     DX,DI
        POP     DI
        SUB     DI,BX           ; ADJUST DI FOR REPLACEMENT
        PUSH    CX
        LEA     SI,RCODE1
        XOR     CX,CX
        MOV     CL,BYTE PTR [SI]
        INC     SI              ; SI NOW POINTS TO REPLACEMENT CODE
        REP     MOVSB           ; REPLACE IT
        POP     CX
        INC     DX
        POP     BX
        MOV     AX,CX           ; SAVE CX TEMP
        POP     CX
        DEC     CX
        PUSH    CX
        MOV     CX,AX           ; RESTORE IT
        JNZ     SCAN_CURP2

NO_SCODE2:
        POP     CX              ; DISCARD AGAIN

DO_SCODE3:
        LEA     DI,SCODE3
        XOR     BX,BX
        MOV     BL,BYTE PTR [DI]
        INC     DI
        ADD     BX,DI
        MOV     [ENDSCAN],BX
        SUB     BX,DI
        MOV     BL,BYTE PTR [DI]
        INC     DI
        MOV     DX,DI
        MOV     CX,2            ; NUMBER OF TIMES TO SCAN
        PUSH    CX              ; SAVE IT

SCAN_CURP3:
        CALL    SCANIT
        JZ      NO_SCODE3
	dec	[set_flag]	; 2.07 this says that we have changed something
        PUSH    BX
        PUSH    DI
        MOV     DI,DX
        DEC     DI
        DEC     DI
        MOV     BL,BYTE PTR [DI]
        INC     DI
        INC     DI
        MOV     DX,DI
        POP     DI
        SUB     DI,BX           ; ADJUST DI FOR REPLACEMENT
        PUSH    CX
        LEA     SI,RCODE1
        XOR     CX,CX
        MOV     CL,BYTE PTR [SI]
        INC     SI              ; SI NOW POINTS TO REPLACEMENT CODE
        REP     MOVSB           ; REPLACE IT
        POP     CX
        INC     DX
        POP     BX
        MOV     AX,CX           ; SAVE CX TEMP
        POP     CX
        DEC     CX
        PUSH    CX
        MOV     CX,AX           ; RESTORE IT
        JNZ     SCAN_CURP3

NO_SCODE3:
        POP     CX              ; DISCARD AGAIN

mode_scan2:			; 2.07
        lea     di,modescan2	; 2.07
        xor     bx,bx		; 2.07
        mov     bx,modescan2_len; 2.07
        add     bx,di		; 2.07
        mov     [endscan],bx	; 2.07
        sub     bx,di		; 2.07
        mov     bl,byte ptr [di]; 2.07
	xor	bh,bh		; 2.07
        mov     dx,di		; 2.07
	inc	dx		; 2.07
        mov     cx,4            ; 2.07
        push    cx              ; 2.07

scan_mode2:			; 2.07
        call    scanit		; 2.07
	jz      no_mode2	; 2.07
	dec	[set_flag]	; 2.07 this says that we have changed something
	push    bx		; 2.07
	push    di
	dec     di
	dec     di
	mov     byte ptr es:[di],90h	; nop the out instruction
	pop     di
	pop     bx
	mov     ax,cx	   ; save cx temp
	pop     cx
	dec     cx
	push    cx
	mov     cx,ax	   ; restore it
	jnz     scan_mode2

no_mode2:
	pop     cx	      ; 2.07 discard again

mode_scan3:			; 2.07
        lea     di,modescan3	; 2.07
        xor     bx,bx		; 2.07
        mov     bx,modescan3_len; 2.07
        add     bx,di		; 2.07
        mov     [endscan],bx	; 2.07
        sub     bx,di		; 2.07
        mov     bl,byte ptr [di]; 2.07
	xor	bh,bh		; 2.07
        mov     dx,di		; 2.07
	inc	dx		; 2.07
        mov     cx,4            ; 2.07
        push    cx              ; 2.07

scan_mode3:			; 2.07
        call    scanit		; 2.07
	jz      no_mode3	; 2.07
	dec	[set_flag]	; 2.07 this says that we have changed something
	push    bx		; 2.07
	push    di
	dec     di
	dec     di
	mov     byte ptr es:[di],90h	; nop the out instruction
	pop     di
	pop     bx
	mov     ax,cx	   ; save cx temp
	pop     cx
	dec     cx
	push    cx
	mov     cx,ax	   ; restore it
	jnz     scan_mode3

no_mode3:
	pop     cx	      ; 2.07 discard again

inloop10:			; 2.07
        lea     di,inloop1	; 2.07
        xor     bx,bx		; 2.07
        mov     bx,inloop1len	; 2.07
        add     bx,di		; 2.07
        mov     [endscan],bx	; 2.07
        sub     bx,di		; 2.07
        mov     bl,byte ptr [di]; 2.07
	xor	bh,bh		; 2.07
        mov     dx,di		; 2.07
	inc	dx		; 2.07
        mov     cx,5            ; 2.07
        push    cx              ; 2.07

inloop1a:			; 2.07
        call    scanit		; 2.07
	jz      no_inloop1	; 2.07
	dec	[set_flag]	; 2.07 this says that we have changed something
	push    bx		; 2.07
	push    di
	sub	di,3
	mov     es:[di],9090h	; nop the conditional jump instruction
	pop     di
	pop     bx
	mov     ax,cx	   ; save cx temp
	pop     cx
	dec     cx
	push    cx
	mov     cx,ax	   ; restore it
	jnz     inloop1a

no_inloop1:
	pop     cx	      ; 2.07 discard again

inloop20:			; 2.07
        lea     di,inloop2	; 2.07
        xor     bx,bx		; 2.07
        mov     bx,inloop2len	; 2.07
        add     bx,di		; 2.07
        mov     [endscan],bx	; 2.07
        sub     bx,di		; 2.07
        mov     bl,byte ptr [di]; 2.07
	xor	bh,bh		; 2.07
        mov     dx,di		; 2.07
	inc	dx		; 2.07
        mov     cx,5            ; 2.07
        push    cx              ; 2.07

inloop2a:			; 2.07
        call    scanit		; 2.07
	jz      no_inloop2	; 2.07
	dec	[set_flag]	; 2.07 this says that we have changed something
	push    bx		; 2.07
	push    di
	sub	di,3
	mov     es:[di],9090h	; nop the conditional jump instruction
	pop     di
	pop     bx
	mov     ax,cx	   ; save cx temp
	pop     cx
	dec     cx
	push    cx
	mov     cx,ax	   ; restore it
	jnz     inloop2a

no_inloop2:
	pop     cx	      ; 2.07 discard again

MONOSET:
	LEA     DI,MONOCODE
	XOR     BX,BX
	MOV     BX,MONOCODE_LEN
	ADD     BX,DI
	MOV     [ENDSCAN],BX
	SUB     BX,DI
	MOV     BL,BYTE PTR [DI]
	XOR     BH,BH
	MOV     DX,DI
	CALL    SCANIT
	JZ      MONOMORE
	dec	[set_flag]	; 2.07 this says that we have changed something
	SUB     DI,MONOCODE_LEN 
	MOV     AX,[RTVIDRAM]
	MOV     ES:[DI],AX

MONOMORE:
	LEA     DI,MONOCODE1
	XOR     BX,BX
	MOV     BX,MONOCODE1_LEN
	ADD     BX,DI
	MOV     [ENDSCAN],BX
	SUB     BX,DI
	MOV     BL,BYTE PTR [DI]
	XOR     BH,BH
	MOV     DX,DI
	INC     DX
	CALL    SCANIT
	JZ      WRAP_UP
	dec	[set_flag]	; 2.07 this says that we have changed something
	SUB     DI,3
	MOV     AX,[RTVIDRAM]
	MOV     ES:[DI],AX

WRAP_UP:
	CMP     [FGBGOFF],2     ; SEE IF WE ARE IN THE FOREGROUND
	JE      IN_FG	   ; YES, SKIP THE STUFF
	CMP     [MLINKVER], 400 ; 2.05 TEST FOR MLINK 4.00 OR GREATER
	JAE	IN_FG	   ; 2.05 SKIP THE STUFF (ALSO WITHOUT MLINK)
	PUSH    ES	      ; SAVE IT TEMPORARILY
	MOV     AX,40H	  ; ACCESS 40:10 TO CHANGE EQUIPMENT FLAG
	MOV     ES,AX	   ; TO REFLECT A MONO MONITOR
	MOV     AL,BYTE PTR ES:[10H]
	PUSH    AX
	AND     AL,30H
	CMP     AL,30H
	JZ      IS_MONO
	POP     AX
	AND     AL,0CFH	 ; MAKE LOTUS THINK IT HAS B&W
	MOV     BYTE PTR ES:[10H],AL
	POP     ES
	JMP     IN_FG

IS_MONO:
	POP     AX
	POP     ES

IN_FG:
	cmp	[set_flag],00h	; 2.07 if this flag is still 0, the file's not
	je	$+5		; 2.07 been changed.
	JMP     PTENDLOOP       ; END THE PROGRAM
	pop	si		; 2.07 get pointer to description
	lea	di,stext2	; 2.07 point to message and take out cr,lf,$
	add	di,30		; 2.07
	mov	byte ptr [di],20h	; 2.07
	mov	byte ptr [di+1],20h	; 2.07
	mov	byte ptr [di+2],20h	; 2.07
	lea	dx,stext2	; 2.07
	jmp	finish		; 2.07 print the message and terminate


VID_STR1	DB      0B8H,00H,0B0H,08EH,0C0H,90h
VID_STR_LEN     EQU     $-VID_STR1
VID_STR2	DB      0B8H,00H,0B8H,08EH,0C0H,90h
CRT_STRM	DB      0BAH,0B8H,03H,90H
CRT_STRC	DB      0BAH,0D8H,03H,90H
CRT_STR_LEN     EQU     $-CRT_STRC
MONOCODE	DB      00H,0B0H,0B4H,003H,90H
MONOCODE_LEN    EQU     $-MONOCODE
MONOCODE1       DB      0C7H,06H,84H,00H,00H,0B0H,90H
MONOCODE1_LEN   EQU     $-MONOCODE1

modescan2	db      0bah,0d8h,03h,0eeh,090h		; 2.07
modescan2_len    equ     $-modescan2			; 2.07
modescan3	db      0bah,0d9h,03h,0eeh,090h		; 2.07
modescan3_len    equ     $-modescan3			; 2.07
inloop1		DB      075h,0fbh,90h	; 2.07
inloop1len	EQU     $-inloop1	; 2.07
inloop2		db	074h,0fbh,90h	; 2.07
inloop2len	equ	$-inloop2	; 2.07


PROGEND  LABEL BYTE
MAINSEG  ENDS
	 END   ENTRYPNT
