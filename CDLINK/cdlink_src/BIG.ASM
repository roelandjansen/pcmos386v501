mainseg	segment para
	assume	cs:mainseg
	db	100h dup(?)
start	label	near
	int	20h
	db	32766 dup (0)
mainseg	ends
        end	start
