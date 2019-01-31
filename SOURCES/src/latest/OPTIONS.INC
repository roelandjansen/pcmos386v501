;   The following is the definitions file for specific needs of PC-MOS
;
;   MDEBUG - if this is non-zero, this will including the internal console
;	     debugger which was originally internal to MOS during early.
;	     This should always be 0, since this code is no longer updated.
;
MDEBUG equ 0
;
;   VNAHARD - if this is non-zero, this will include code inside MOS which
;	      will verify the existing of VNA hardware, Normally this should
;	      be set to zero.
;
VNAHARD equ 0
;
;   SERVICES - this equate is use to indicate which INTERUPT will be use by
;	       MOS and its utilities for its services. This interupt was
;	       originally INT 38h
;
;	       New MOS services = INT D4h
;
SERVICES equ 0D4h
;
;   BIAS -	controls BIASing the stack during INT 21h and INT 38h calls.
;		Since periscope uses the standard console I/O routines, the
;		stack must be biased to run periscope inside a 21h or 38h
;		function.
;		Note keep this value 0 for release and 256 for debugging
;
BIAS	equ	0
;
;   CODE286 -   This equate means to Include for $286.sys driver. Which was
;		created as 286 Only LOADALL memory management driver. 
;
CODE286	 equ	0
;
;   ACCESSKEY1   These values are access keys use by $$MOS.SYS and
;   ACCESSKEY2   MAKEUSER.COM, changing these values will make different
;   ACCESSKEY3   keys for different Serial #'s
;
IFDEF LLPRO

ACCESSKEY1 equ	 50359		; word value
ACCESSKEY2 equ    8054		; word value
ACCESSKEY3 equ      37		; byte value	


ELSE

ACCESSKEY1 equ	 45323		; word value
ACCESSKEY2 equ    7242		; word value
ACCESSKEY3 equ      29		; byte value	

ENDIF

;
;   ALPHAREL	Nonzero means that Code is PreBeta
;   BETAREL	NonZero means that Code is Beta
;
ALPHAREL  equ	0
BETAREL	  equ   0
;
;
;   PARAKANSI    Number of paragraphs for ANSI Keyboard 
;		 assignment buffer
;
PARAKANSI  equ   12
