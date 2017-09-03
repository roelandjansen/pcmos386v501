.xlist
comment ^
================================================================
========================= XIFS MACROS ==========================
================================================================

These macros are used in conjunction with action chart contructs to
bring structure to assembler language and to make it more like C.

³ÚÄ xif ax == 2 else x1
³³ mov bx,3
³ÀÄ 
³{x1}

The above would be read as:  if ax == 2 then flow through and do the 
mov bx,3; otherwise, jump to the label after the "else" keyword (x1).

Note that the above example is of the 'old literal' style.  Here's the 
same example in the newer, cleaner form:

³ÚÄ xif ax == 2
³³ mov bx,3
³ÀÄ 

This new, simpler form is possible because the cha2asm.exe program will
automatically fill in labels.  One less detail for humans to have to
mess with.

================ General forms for xif statements

xif A op B else label
xif A op B then label
xif flags == X then label
xif flags == X else label

The 'op' represents the operator and the 'X' represents the flags value.
Any of the following may be used for either 'op' or 'X':

e ne z nz a na be nbe ae nae b nb g ng le nle 
l nl ge nge p np pe po o no s ns c nc

The following special operators are also supported.  Any of them can be used
for the 'op' term but only 'zr' and 'cy' may be used for 'X' in an 
'xif flags == X'  type statement.

==  !=  zr  cy  test0  test1

================ Code produced by the macros

The statement  "xif ax == 5 then abc"  would produce the following
instructions:

	cmp	ax,5
	je	abc

The use of 'else' instead of 'then' simply inverts the logic.  For example,
the statement  "xif ax == 5 else abc"  produces:

	cmp	ax,5
	jne	abc

The 'else' term, along with its inverted logic is typically used for 
simple 'if' and 'if/else' statements.  See the action chart example at the 
top of this file.

Regarding the  'flags'  term, the statement  'xif flags == cy then error1'
would simply produce:

	jc	error1

The "test0" and "test1" operators cause a "test" instruction to be 
generated rather than a "cmp".  The statement  "xif cx test1 80h then abc"
would produce the code shown below.  Using the  'test0' operator would 
produce a  'jz'  instruction instead of the  'jnz'.

	test	cx,80h
	jnz	abc

================ Compound forms

xif A op B || C op D else label
xif A op B || C op D then label
xif A op B && C op D else label
xif A op B && C op D then label

Any of these forms can use any of the operators.  For example:

xif A b B || A ae C then label

xif A != B && C test0 D else label

However, be careful with "flags".  The following will not work properly.  
The flags value will be that produced by the expression generated for 
the first test.  Having the flags test second is not a good idea.  
You won't get the test you want.

xif A == B && flags == c then label

Use this format instead:

xif flags == c && A == B then label

Note that the following is OK:

xif flags == zr || flags == cy else label

================ Miscellaneous

Put an "l" in front of any xif macro to make a long jump.  for example:

lxif flags == cy then Error_Handler

Use "<" and ">" around multi-token expressions which must form a single
lvalue or rvalue:

xif <byte ptr es:[17h]> == 3 else label

The case macro is basically an alias for xif for the following type of use:

ÚÄ 
³ÚÄ case <byte ptr cs:[bx]> == 1 else pnt005
³³ mov cx,4
³< jmp pnt015
³³ {pnt005}
³ÃÄ case <byte ptr cs:[bx]> == 2 else pnt010
³³ mov cx,33
³< jmp pnt015
³³ {pnt010}
³ÃÄ ;;default
³³ xor cx,cx
³ÀÄ 
³ {pnt015}
ÀÄ 

^

;=============================================

; This is the master template macro for any conditional branch.
; If the 'elsethen' variable is 0 ('then'), then a positive 
; translation is done.  For example, 'xif ax == 5 then xyz' 
; produces 'cmp ax,5' and 'je xyz'.  When 'elsethen' is 1 ('else'), 
; the logic is inverted.
; The pj and jn entry parameters represent the letters required to 
; form the positive and negative forms respecitively.

xj	macro	destlbl, pj, nj
	local around
if	long eq 0
 if	elsethen eq 0
	j&pj	destlbl
 else
	j&nj	destlbl
 endif
else
 if	elsethen eq 0
	j&nj	around
	jmp	destlbl
around:
 else
	j&pj	around
	jmp	destlbl
around:
 endif
endif
	endm

;=============================================

; The following macros effectively form a lookup table.  For
; each type of branch, information about the positive and 
; negative logic forms is passed on to the xj macro along with
; the label.

xje	macro	destlbl
	xj	destlbl, e, ne
	endm

xjne	macro	destlbl
	xj	destlbl, ne, e
	endm

xjz	macro	destlbl
	xj	destlbl, z, nz
	endm

xjzr	macro	destlbl
	xj	destlbl, z, nz
	endm

xjnz	macro	destlbl
	xj	destlbl, nz ,z
	endm

xja	macro	destlbl
	xj	destlbl, a, na
	endm

xjna	macro	destlbl
	xj	destlbl, na, a
	endm

xjbe	macro	destlbl
	xj	destlbl, be, nbe
	endm

xjnbe	macro	destlbl
	xj	destlbl, nbe, be
	endm

xjae	macro	destlbl
	xj	destlbl, ae, nae
	endm

xjnae	macro	destlbl
	xj	destlbl, nae, ae
	endm

xjb	macro	destlbl
	xj	destlbl, b, nb
	endm

xjnb	macro	destlbl
	xj	destlbl, nb, b
	endm

xjg	macro	destlbl
	xj	destlbl, g, ng
	endm

xjng	macro	destlbl
	xj	destlbl, ng, g
	endm

xjle	macro	destlbl
	xj	destlbl, le, nle
	endm

xjnle	macro	destlbl
	xj	destlbl, nle, le
	endm

xjl	macro	destlbl
	xj	destlbl, l, nl
	endm

xjnl	macro	destlbl
	xj	destlbl, nl, l
	endm

xjge	macro	destlbl
	xj	destlbl, ge, nge
	endm

xjnge	macro	destlbl
	xj	destlbl, nge, ge
	endm

xjp	macro	destlbl
	xj	destlbl, p, np
	endm

xjnp	macro	destlbl
	xj	destlbl, np, p
	endm

xjpe	macro	destlbl
	xj	destlbl, pe, po
	endm

xjpo	macro	destlbl
	xj	destlbl, po, pe
	endm

xjo	macro	destlbl
	xj	destlbl, o, no
	endm

xjno	macro	destlbl
	xj	destlbl, no, o
	endm

xjs	macro	destlbl
	xj	destlbl, s, ns
	endm

xjns	macro	destlbl
	xj	destlbl, ns, s
	endm

xjc	macro	destlbl
	xj	destlbl, c, nc
	endm

xjcy	macro	destlbl
	xj	destlbl, c, nc
	endm

xjnc	macro	destlbl
	xj	destlbl, nc, c
	endm

;============== SETELTH ==================

; This one analyzes the 'else/then' term and sets the
; elsethen variable accordingly.

setelth	macro	p1
ifidni	<p1>,<then>
	elsethen = 0
else
 ifidni	<p1>,<else>
	elsethen = 1
 else
 	err
	%out syntax error in else/then term
	exitm
 endif
endif
	endm

;============== BASICIF ==================

; This level of the translation process decides whether the statement
; is the 'flags ==' type, or whether any of the other special 'op' 
; values is being used.

basicif	macro p1, p2, p3, p4, p5

;; decode the else/then term

setelth	p4

;; handle the  'xif flags == X else/then label'  case

ifidni	<p1>,<flags>
 ifidni <p2>,<==>
	xj&p3	p5
 else
 	err
	%out 'xif flags' must use ==
 endif
	exitm
endif

;; handle the  'xif A test0/1 B else/then label'  cases

ifidni <p2>,<test1>
	test	p1,p3
	xjnz	p5
	exitm
endif

ifidni <p2>,<test0>
	test	p1,p3
	xjz	p5
	exitm
endif

;; if not  'flags =='  or  'test0/1'  then need a compare instruction

	cmp	p1,p3

;; decide which type of branch instruction to use

ifidni <p2>,<=>			;; a != ends up as a = due to special  
 	xjne	p5		;; meaning of ! within macros
	exitm
endif
ifidni <p2>,<==>
	xje	p5
	exitm
endif
	xj&p2	p5
	endm

;============== XOAIF ==================

; This level of the translation process decides whether the statement
; is of a simple or compound form.

xoaif	macro	p1, p2, p3, p4, p5, p6, p7, p8, p9
	local	xyz

;; handle the  'xif ?? op ?? || ?? op ?? else/then label'  case

ifidni	<p4>,<||>

 ;; decode the else/then term

 setelth	p8
 elth2 = 0				;; copy elsethen to a local var
 if	elsethen eq 1
 elth2 = 1
 endif
 if	elth2 eq 0
	basicif <p1> <p2> <p3> then <p9>
	basicif <p5> <p6> <p7> then <p9>
	exitm
 endif
 if	elth2 eq 1
	basicif <p1> <p2> <p3> then xyz
	basicif <p5> <p6> <p7> else <p9>
xyz:
	exitm
 endif
endif

;; handle the  'xif ?? op ?? && ?? op ?? else/then label'  case
;; presuming p4 is a && when get this far and p7 is not null.
;; this is due to the difficulty in testing for && directly.

ifnb	<p7> 

;; decode the else/then term

 setelth	p8
 elth2 = 0				;; copy elsethen to a local var
 if	elsethen eq 1
 elth2 = 1
 endif
 if	elth2 eq 0
	basicif <p1> <p2> <p3> else xyz
	basicif <p5> <p6> <p7> then <p9>
xyz:
	exitm
 endif
 if	elth2 eq 1
	basicif <p1> <p2> <p3> else <p9>
	basicif <p5> <p6> <p7> else <p9>
	exitm
 endif
endif

;; if get this far, p4 wasn't a '||' or a '&&', so this must be
;; a simple xif statement

	basicif <p1> <p2> <p3> <p4> <p5>
	endm

;============== XIF ==================

xif	macro	p1, p2, p3, p4, p5, p6, p7, p8, p9
	long = 0
	xoaif <p1> <p2> <p3> <p4> <p5> <p6> <p7> <p8> <p9>
	endm

;============== LXIF =================

lxif	macro	p1, p2, p3, p4, p5, p6, p7, p8, p9
	long = 1
	xoaif <p1> <p2> <p3> <p4> <p5> <p6> <p7> <p8> <p9>
	endm

;============== OLD FORMS KEPT FOR COMPATIBILITY

; It is no longer necessary to use a different macro name to
; use a compound form.  When all source code which uses these old
; macros is converted, they will be deleted.

xoif	macro	p1, p2, p3, p4, p5, p6, p7, p8, p9
if1
	%out note: xoif usage
endif
	long = 0
	xoaif <p1> <p2> <p3> <p4> <p5> <p6> <p7> <p8> <p9>
	endm

xaif	macro	p1, p2, p3, p4, p5, p6, p7, p8, p9
if1
	%out note: xaif usage
endif
	long = 0
	xoaif <p1> <p2> <p3> <p4> <p5> <p6> <p7> <p8> <p9>
	endm

lxoif	macro	p1, p2, p3, p4, p5, p6, p7, p8, p9
if1
	%out note: lxoif usage
endif
	long = 1
	xoaif <p1> <p2> <p3> <p4> <p5> <p6> <p7> <p8> <p9>
	endm

lxaif	macro	p1, p2, p3, p4, p5, p6, p7, p8, p9
if1
	%out note: lxaif usage
endif
	long = 1
	xoaif <p1> <p2> <p3> <p4> <p5> <p6> <p7> <p8> <p9>
	endm

;============= CASE ===================

case	macro	p1, p2, p3, p4, p5, p6, p7, p8, p9
	long = 0
	xoaif <p1> <p2> <p3> <p4> <p5> <p6> <p7> <p8> <p9>
	endm

;============= LCASE ===================

lcase	macro	p1, p2, p3, p4, p5, p6, p7, p8, p9
	long = 1
	xoaif <p1> <p2> <p3> <p4> <p5> <p6> <p7> <p8> <p9>
	endm

;============= TWOLBL ==================

; this one is used by cha2asm to keep the association between .cha 
; (action chart source) file lines and the resulting asm file lines 
; in a 1:1 correspondance.
; Doing this means that when the assembler reports errors, the line
; numbers can be used directly to find the problem within the
; .cha file (the action chart source file).

twolbl	macro	p1, p2
p1:
p2:
	endm

.list

