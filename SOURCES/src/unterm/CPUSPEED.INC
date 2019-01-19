comment ^===============================================================
		       development specification

 program name:	$serial.sys		assigned to: Rick Ruhl
 module name:	cpuspeed.inc		assign date: 08/10/92
 entry points:	n/a			completed:   08/28/92
 entry from:	n/a
 entry method:	n/a
 calls:		n/a
 purpose:	include file machine independent machine waits
 refer to:	n/a
 last update:	12/11/92

=======================================================================
SAH  08/28/92	Update to service for serial.sys changes.
cbk  11/20/92   fixed to not die when loading dos 5.0 high and using
		himem driver from dos 5.0
SAH  12/11/92	Added option to condition assemble this code out.
		Research is process is see if this techniques is necessary
		with Serial.sys at all...how ever is used and needed by
		Unterm for Printing.
=======================================================================^


IFNDEF DISABLE_CPUSPEED
checkspeed  proc  near
	    pushf	;11/20/92
	    sti		;11/20/92

            push  ax
            push  cx
            push  dx

            push  es

            mov   ax,0
            mov   es,ax
            mov   cx,es:[046ch]
loop1:
            cmp   cx,es:[046ch]    ; wait for beginning of a timer tick
            je    loop1
            xor   ax,ax
            xor   dx,dx
            mov   cx,es:[046ch]
loop2:
            add   ax,1             ; count while waiting for next timer tick
            adc   dx,0
            cmp   cx,es:[046ch]
            je    loop2
 
            mov   al,ah
            mov   ah,dl
            mov   dl,dh
            xor   dh,dh    
                            ;div  256
            mov   cl,3
            shr   ax,cl
            mov   cl,3
            shl   dx,cl
            or    ah,dl
            shr   ax,1
                           ;div 4096
	    or	  ax,ax				; make sure that never 0
	    jnz	  CSpeed1			; or we will wait for long
	    inc	  ax				; time on a slow machine
CSpeed1:
            mov   [cpuspeed],ax
            pop   es
            pop   dx
            pop   cx
            pop   ax
	    popf	;11/20/92
            ret
checkspeed endp
ENDIF
