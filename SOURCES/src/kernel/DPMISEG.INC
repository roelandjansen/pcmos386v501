;
; DPMI Data Segment Definitions
;
Initialized		db	0		; 'Y' means data initialized
OrgUnRegister		dd	0		; Orginal UnRegister
TCBSelector		dw	0		; Selector for TCB
StartBank		dw	0		; Start Bank
SizeBank		dw	0		; Size in Banks
BankTabOffset		dw	0		; offset of Bank Table
RealIntNo		db	0		; real int #
;
; DPMI Real Mode registers
;
RealRegister		label	word
RealAX			dw	0		; AX
RealBX			dw	0		; BX
RealCX			dw	0		; CX
RealDX			dw	0		; DX
RealSI			dw	0		; SI
RealDI			dw	0		; DI
RealBP			dw	0		; BP
RealDS			dw	0		; DS
RealES			dw	0		; ES
;

InternalSelector	label	byte	
InternalBase4		db	0		; Bit 31-24 of base
InternalHighAccess	db	0
InternalLowAccess	db	0
InternalBase3		db	0		; Bit 23-16 of base
InternalBase21		dw	0		; bit 15-0 of base
InternalSegLimit	dw	0		
;
CpuType			db	0		; Processor Type
CurrentPICBase		label	word
MasterPIC 		db	0		; master Pic Value
SlavePIC		db	0		; Slave Pic Value
			db	0
;
DPMIMemoryInfo		label	byte
LargestFreeBlock	dd	0		; largest free block
MaxLockPage		dd	0		; Max Lock Page
MaxUnLockPage		dd	0		; Max UnLock Page
LinearAddrSpace		dd	0		; Linear Address Space
TotalUnlock		dd	0		; Total Unlock Pages
MaxFreePages		dd	0		; Max Free Pages
TotalPhyPages		dd	0		; Total Physical Pages
FreeLinearSpace		dd	0		; Free Linear Space
SizeOfPagingFile	dd	0		; Size of Paging File
			db	12h dup (0)
;
DebugInformation	label	byte
DebugRegisters		dd	8 dup (0)	
DebugSetting1		db	0		; debug setting byte 1
;						  0FFH if Not allocated
;						  Bit 7-4 TYPE 
;					     	          0  EXECUTE
;				     			  1  WRITE
;				     			  2  READ\WRITE
;						  Bit 3-0 LEN
;				     			  1  BYTE
;				                          2  WORD 
;				     			  4  DWORD
DebugStatus1		db	0		; debug status byte 1
;						;  Bit 0 = 1 means active
DebugAddress1		dd	0		; debug address 1
;
DebugSetting2		db	0		; debug setting byte 2
DebugStatus2		db	0		; debug status byte 2
DebugAddress2		dd	0		; debug address 2
;
DebugSetting3		db	0		; debug setting byte 3
DebugStatus3		db	0		; debug status byte 3
DebugAddress3		dd	0		; debug address 3
;
DebugSetting4		db	0		; debug setting byte 4
DebugStatus4		db	0		; debug status byte 4
DebugAddress4		dd	0		; debug address 4
;
;
; The following Must be last entry in DPMI Segment
;
; The following variable items will be store here
;
; BankTab, this will be a word array of handles for allocating extended memory
; there will be one word for each Page, handle 0 means not allocated.
;

TableOff	label	byte


