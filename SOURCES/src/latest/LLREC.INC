; FILE: LLREC.INC
;
;  This include file defines the record layout of the LL_RECORD, which
;  is used to keep track of important data that won't fit in the
;  "ports" record.
;
;  _SERIAL.ASM (ie: SERIAL.SYS and EMULINK.SYS) uses the full capability
;  of the PILDS/LL_RECORD constructs by only checking enabled ports that
;  are on the link-list hung off the correct PILDS.  Other drivers
;  only supply a bare-bones LL_RECORD that is needed by the routines
;  in ISRSUB.INC
;


USE_LL_RECORD = true    ; indicate we are using the LL_RECORD

LL_RECORD     struc   ;

IFDEF  USE_PILDS        ; this stuff only exists if we are using a PILDS


LL_NEXT      dw     ? ; near pointer to next LL_RECORD for an
                      ; active port on this same interrupt level.
                      ; If there are no more active ports then
                      ; this field points to the PILDS
                      ; record.  If this LL_RECORD is for an
                      ; inactive port then this field is
                      ; undefined.

LL_PREV      dw     ? ; near pointer to the prior LL_RECORD
                      ; active port on this same interrupt level.
                      ; If this is the first active port then
                      ; this field points back at the PILDS
                      ; record.  If this LL_RECORD is for an
                      ; inactive port then this field is
                      ; undefined.

ENDIF

LL_PORT      dw     ? ; near pointer to the "PORTS" record for
                      ; the port associated with this LL_RECORD.
                      ; This is a static pointer that is
                      ; initialized by the assembler and is
                      ; never changed.

IFDEF   USE_PILDS

LL_DAD       dw    ?  ; near pointer to the PILDS record for the
                      ; port's interrupt level.  This field is
                      ; filled in at initialization time and
                      ; remains valid whether or not the port
                      ; is active.

ENDIF

LL_FCR       db    ?  ; this is an image of the value to be loaded
                      ; into the FIFO control register when initializing
                      ; the port.  The LSBit will only be set if the
                      ; port is a 16550A part and FIFO control is
                      ; requested (IF>0 and/or OF>0).  This field is
                      ; filled in at initialization time and is
                      ; static thereafter.  It should always be a
                      ; zero for ports that do not have FIFO support.

LL_XBURST    db    ?  ; this is the number of bytes to be transmitted
                      ; in a burst when a THRE interrupt occurs.  It
                      ; is the value of OF= from the command line.
                      ; It will always be forced to 1 on a non-16550A
                      ; part.  This field is filled in at initialization
                      ; time and is static thereafter.

LL_UTYPE     dw    ?  ; UART type code.  This value is filled in by
                      ; CheckUarts during initialization.
                      ;    Valid values are:
                      ;          0 = No UART there
                      ;          2 = 8250B
                      ;          4 = 8250A/16450
                      ;          6 = 16550
                      ;          8 = 16550A

LL_RECORD     ends    ;

; The following is a list of UART types.  These are the values that
; should be stored in the field LL_UTYPE.

UT_None  = 0          ;
UT_8250B = 2          ;
UT_8250A = 4          ;
UT_16550 = 6          ;
UT_16550A = 8         ;
