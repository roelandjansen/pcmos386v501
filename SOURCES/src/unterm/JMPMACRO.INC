	.XLIST

;=============== LONG JUMP MACROS ================

Lje	MACRO	dest
	LOCAL	nojmp
	jne	nojmp
	jmp	dest
nojmp:
	ENDM

Ljne	MACRO	dest
	LOCAL	nojmp
	je	nojmp
	jmp	dest
nojmp:
	ENDM

Ljz	MACRO	dest
	LOCAL	nojmp
	jnz	nojmp
	jmp	dest
nojmp:
	ENDM

Ljnz	MACRO	dest
	LOCAL	nojmp
	jz	nojmp
	jmp	dest
nojmp:
	ENDM


Ljc	MACRO	dest
	LOCAL	nojmp
	jnc	nojmp
	jmp	dest
nojmp:
	ENDM

Ljnc	MACRO	dest
	LOCAL	nojmp
	jc	nojmp
	jmp	dest
nojmp:
	ENDM

Lja	MACRO	dest
	LOCAL	nojmp
	jbe	nojmp
	jmp	dest
nojmp:
	ENDM

Ljb	MACRO	dest
	LOCAL	nojmp
	jae	nojmp
	jmp	dest
nojmp:
	ENDM

Ljae	MACRO	dest
	LOCAL	nojmp
	jb	nojmp
	jmp	dest
nojmp:
	ENDM

Ljbe	MACRO	dest
	LOCAL	nojmp
	ja	nojmp
	jmp	dest
nojmp:
	ENDM

	.LIST
