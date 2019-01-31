; FILE:  PILDS.INC
;
;  This include file defines the record layout of the Per-Interrupt-
;  Level-Data-Structure (PILDS) and the Link-List record (LL) as used
;  by _SERIAL.ASM and other serial device drivers.  These structures
;  are used to keep track of the status of serial ports assigned to
;  specific interrupt levels.


USE_PILDS = true      ; indicate that we are using PILDS

; We use the following two data structures to manage the lists
; of ports on each interrupt level.  The "PILDS" (Per-Interrupt-
; Level-Data-Structure) defines all the information that is
; shared for a given interrupt level.  The "LL_RECORD" (Linked-
; List-Record) defines data for a single port.

PILDS     struc

PILDS_FIRST   DW   ?  ; near pointer to first LL_RECORD (see
                      ; below) for an active port on this interrupt
                      ; level.  If there are no active ports then
                      ; this field points to the PILDS record
                      ; itself.

PILDS_LAST    DW    ? ; near pointer to last LL_RECORD for
                      ; an active port on this interrupt level.
                      ; If there are no active ports then this
                      ; field points to the PILDS record itself.

PILDS_IRQNUM  DB    ? ; IRQ number for this PILDS

PILDS_COUNT   DB    ? ; number of ports DEFINED (not necessarily
                      ; active) on this interrupt level.

PILDS_VECOFF  DW    ? ; The offset, in segment 0000, of the
                      ; vector for this interrupt level.

PILDS_ISR     DW    ? ; The offset of the ISR for this interrupt
                      ; level.

PILDS         ends    ;


