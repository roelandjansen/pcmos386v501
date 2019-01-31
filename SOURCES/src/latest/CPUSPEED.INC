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
 last update:	08/28/92

=======================================================================
SAH  08/28/92	Update to service for serial.sys changes.
=======================================================================^

 checkspeed  proc  near
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
            mov   [cpuspeed],ax
            pop   es
            pop   dx
            pop   cx
            pop   ax
            ret
checkspeed endp

