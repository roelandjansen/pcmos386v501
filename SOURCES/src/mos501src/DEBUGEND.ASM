	include page.inc		
        title DEBUGEND.ASM - MOS DEBUG Last Module requirement
;
;*****************************************************************************
;*                                                                           *
;*                        MOS Development Specification                      *
;*                                                                           *
;* Command type: External               Assigned to:        Stewart A. Hyde  *
;* Command name: DEBUG                  Date assigned:      August 20, 1986  *
;*                                      Date completed:                      *
;* Command format: DEBUG d:[path][filename][.ext][parm1][parm2]              *
;* Purpose:  To provide debugging facilities to MOS                          *
;* Refer to: IBM PC-DOS 3.2 DOC and MOSDEBUG.DOC                             *
;* Last Update:                         By:                                  *
;*                                                                           *
;*      External                Values                  Values               *
;*      routines                passed                  returned             *
;* --------------------------------------------------------------------------*
;* (add as many lines as you need here and above to complete the form.)      *
;* --------------------------------------------------------------------------*
;* MOS commands will use the same segment grouping as the MOS kernel. This   *
;* file is a template as is MOSSHELL.ASM. Except that its designed for use in*
;* commands, both internal and external, for MOS. See MOSSHELL.ASM for de-   *
;* tails. The commands should not need to go into as much detail as the kerne*
;* does in keeping track of end of segment pointers in the INC files and such*
;* Our desire is to maintain the same coding standards thruout MOS and to use*
;* code modularity as much as possible. So, use the same group labels in any *
;* routine to keep the code and data segments in the same segment.           *
;*                                                                           *
;*****************************************************************************
;									     ;
;	09/08/88	RKG	Misc Cleanup and internal name change	     ;
;----------------------------------------------------------------------------;
;	02/20/89	SAH	Corrections for MASM 5.10		     ;
;----------------------------------------------------------------------------;
;	03/29/89	SAH	Correct Get8087 for multi-tasking 8087 access;
;----------------------------------------------------------------------------;

       if1
                %out   Pass 1   Started.
        else
                %out   Pass 2   Started.
        endif

        include debugend.pub
	
	.8087

moss    segment word public 'code'
        assume cs:moss;ds:moss;es:moss

	page


extrn   r87all:word

;-------------------------------------------------------------------------;
;       Function: Is8087                                                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;            AL = 0 if no 80x87         1 if 80x87                        ;
;-------------------------------------------------------------------------;

Is8087  proc   near
        int    11h
        test   al, 2
        jnz    s8087
        xor    ax, ax
        ret

s8087   label  near
        mov    ax, 1
        ret
Is8087  endp



;-------------------------------------------------------------------------;
;       Function: Get8087                                                 ;
;                 retrieves 8087 context                                  ;
;       Input:                                                            ;
;       Output:                                                           ;
;-------------------------------------------------------------------------;

Get8087 proc   near
	fsave	r87all
	frstor	r87all
	fwait
	ret
Get8087 endp


endbyte label   byte
;-------------------------------------------------------------------------;
moss    ends

        if1
                %out   Pass 1   Completed.
        else
                %out   Pass 2   Completed.
        endif


        end

