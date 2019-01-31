	subttl vidchk - special video handling routines call by mos
	page
;======================================================================
; .func: vidchk - special video handling routines call by mos
;
; input:
;	ah points to desired function	
;	   00 - task pam switch in
;		currently driver returns 02 which means that we don't
;		support pamswitching
;	   01 - task pam switch out
;		currently does nothing since 00 is not supported
;	   02 - reboot system
;		for general good practice, driver set channel to ffh
;		master console before system is rebooted
;
; output:
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
; SAH 12/18/90	Corrected for VMODE of MONO pamswitching 
;======================================================================

	assume	cs:code,ds:nothing,es:nothing,ss:nothing
vidchk	proc	far
	push	bx
	push	cx
	push	dx
	push	ds
	push	es
	push	cs
	pop	ds
	or	ah,ah
	jnz	vc1
	mov	es,cx			; access tcb of task to switch too
	assume	es:tcb
	xor	ax,ax
	cmp	word ptr [tcbstate],0	; if not vmode ega, always bad
	je	vcbad
	test	byte ptr [tcbega],4	; is task susppend for state logic
	jnz	vcend			; yes...ok to do it
	jmp	short vcbad2
vcbad:
	test	[tcbvram],80h		; is station a master console
	jz	vcend
	cmp	word ptr [tcbscrdd],0	; if no console viewing, ok
	je	vcend
vcbad2:
	mov	bl,[tcbstation]
	cmp	bl,02h
	jb	vcmaybe
	cmp	bl,04h
	jne	vcsorry
vcmaybe:
	push	es
	mov	es,dx		       ; access station's task tcb
	mov	bl,[tcbstation]
	pop	es
	cmp	bl,02h
	jb	vcend
	cmp	bl,04h
	je	vcend
vcsorry:	
;
;	if Both Tasks are at VMODE of Mono, then allow the switch
;
	push	es
	mov	es,dx		       ; access station's task tcb
	mov	bl,[tcbvideo]
	pop	es
	cmp	bl,[tcbvideo]		; must be the same
	jne	vcerr
	and	bl,3fh
	dec	bl			; must be MONO
	jz	vcend
vcerr:
;
	inc	ax
	inc	ax			; no...task is active and can't switch
	jmp	short vcend
vc1:
	cmp	ah,2
	jne	vcend
	call	boot_prep
vcend:
	pop	es
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	ret
vidchk  endp

