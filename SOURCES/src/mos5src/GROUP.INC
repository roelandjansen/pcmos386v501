;==== segment templates

comment ^

fetch these when you need to add a new segment to a module


gdata	segment
gdata	ends

tcb	segment
tcb	ends

irq	segment
irq	ends

poll	segment
poll	ends

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt     segment
ddt     ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
mosseg	ends

;======================================================== init segment
if 0 eq 0
segment_num = 3
endif
initseg	segment
initseg	ends

^

;==== segment definitions

IFDEF IS_MOSFRONT
gdata	segment page public 'DATA'
gdata	ends
ELSE
gdata	segment word public 'DATA'
gdata	ends
ENDIF

IFDEF IS_MOSFRONT
tcb	segment page public 'DATA'
tcb	ends
ENDIF

irq	segment word public 'DATA'
irq	ends

poll	segment word public 'DATA'
poll	ends

IFDEF IS_MOSFRONT
ddt     segment page public 'CODE2'
ddt     ends
ELSE
ddt     segment word public 'CODE2'
ddt     ends

ENDIF

IFDEF IS_MOSFRONT
mosseg	segment page public 'CODE1'
mosseg	ends
ELSE
mosseg	segment word public 'CODE1'
mosseg	ends
ENDIF

initseg segment para public 'INIT1'
initseg	ends

fcseg	segment word public 'INIT1'
fcseg	ends

;==== group definitions

IFDEF IS_MOSFRONT
grp     group   gdata,tcb,irq,poll
ELSE
grp     group   gdata,irq,poll
ENDIF

mos     group   mosseg

mo2	group	ddt

init	group	initseg,fcseg

