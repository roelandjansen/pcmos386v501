
PAGE  59,132

;€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€
;€€								         €€
;€€			        BIOS				         €€
;€€								         €€
;€€      Created:						         €€
;€€      Version:						         €€
;€€      Passes:    5	       Analysis Options on: QRS		         €€
;€€      (C)1985-1990, American Megatrends Inc. All Rights	         €€
;€€								         €€
;€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€

.err     Target	Assembler set to NONE, re-assembly not recomended

.386p

.387

vectr_18h_seg	equ	62h			; (0000:0062=0F000h)
vectr_19h_off	equ	64h			; (0000:0064=1680h)
vectr_19h_seg	equ	66h			; (0000:0066=4B8h)
data_18e	equ	68h			; (0000:0068=0FE6Eh)
data_20e	equ	6Ah			; (0000:006A=0F000h)
data_21e	equ	6Ch			; (0000:006C=69Dh)
data_23e	equ	70h			; (0000:0070=0FF53h)
data_25e	equ	72h			; (0000:0072=0F000h)
video_hdw_off	equ	74h			; (0000:0074=85h)
disk_parm_off	equ	78h			; (0000:0078=522h)
disk_parm_seg	equ	7Ah			; (0000:007A=0)
graph_tbl_off	equ	7Ch			; (0000:007C=0E02h)
graph_tbl_seg	equ	7Eh			; (0000:007E=0C000h)
data_27e	equ	80h			; (0000:0080=6B0h)
data_28e	equ	82h			; (0000:0082=10ADh)
data_29e	equ	8Bh			; (0000:008B=3)
data_33e	equ	8Fh			; (0000:008F=2Dh)
data_34e	equ	90h			; (0000:0090=6D6h)
data_36e	equ	92h			; (0000:0092=10ADh)
data_37e	equ	94h			; (0000:0094=16CEh)
data_38e	equ	96h			; (0000:0096=0B8h)
data_39e	equ	97h			; (0000:0097=4)
vectr_40h_off	equ	100h			; (0000:0100=0EC59h)
hdsk2_parm_off	equ	118h			; (0000:0118=0E401h)
data_41e	equ	180h			; (0000:0180=0)
data_42e	equ	1C0h			; (0000:01C0=52h)
data_43e	equ	1D0h			; (0000:01D0=0FFh)
vectr_76h_off	equ	1D8h			; (0000:01D8=117h)
data_44e	equ	1FEh			; (0000:01FE=0)
data_45e	equ	244h			; (0000:0244=0)
data_46e	equ	247h			; (0000:0247=0)
data_47e	equ	280h			; (0000:0280=0)
data_48e	equ	282h			; (0000:0282=0)
data_49e	equ	284h			; (0000:0284=0)
data_50e	equ	286h			; (0000:0286=0)
data_51e	equ	288h			; (0000:0288=0)
data_52e	equ	28Ah			; (0000:028A=0)

data_53e	equ	28Ch			; (0000:028C=0)
data_54e	equ	28Eh			; (0000:028E=0)
data_56e	equ	300h			; (0000:0300=0)
data_59e	equ	588h			; (0000:0588=43h)
data_60e	equ	600h			; (0000:0600=42h)
data_61e	equ	818h			; (0000:0818=4EF0h)
data_62e	equ	81Ah			; (0000:081A=7003h)
data_63e	equ	820h			; (0000:0820=2)
data_64e	equ	822h			; (0000:0822=10h)
data_65e	equ	82Ch			; (0000:082C=2212h)
data_66e	equ	836h			; (0000:0836=19h)
data_67e	equ	848h			; (0000:0848=4)
data_68e	equ	870h			; (0000:0870=5)
data_69e	equ	0C04h			; (0000:0C04=70h)
data_70e	equ	0C08h			; (0000:0C08=70h)
data_76e	equ	2483h			; (0000:2483=36h)
data_78e	equ	2EC9h			; (0000:2EC9=0)
data_84e	equ	40B8h			; (0000:40B8=23h)
data_85e	equ	48C9h			; (0000:48C9=7420h)
data_87e	equ	558Fh			; (0000:558F=0F6h)
data_94e	equ	74D9h			; (0000:74D9=0)
data_95e	equ	7AB2h			; (0000:7AB2=5Ah)
data_102e	equ	8000h			; (0000:8000=1)
data_103e	equ	8010h			; (0000:8010=9)
data_104e	equ	8080h			; (0000:8080=41h)
data_105e	equ	81FAh			; (0000:81FA=68FEh)
data_106e	equ	826Ah			; (0000:826A=36h)
data_108e	equ	8382h			; (0000:8382=0C2h)
data_109e	equ	84C9h			; (0000:84C9=666Ah)
data_111e	equ	8A8Ah			; (0000:8A8A=6D46h)
data_114e	equ	91C9h			; (0000:91C9=70h)
data_115e	equ	99D6h			; (0000:99D6=0ECh)
data_116e	equ	9A56h			; (0000:9A56=0FFh)
data_118e	equ	0A6C9h			; (0000:A6C9=660Bh)
data_119e	equ	0A7C9h			; (0000:A7C9=0Bh)
data_121e	equ	0B3E2h			; (0000:B3E2=0F2h)
data_122e	equ	0B900h			; (0000:B900=5)
data_123e	equ	0B9C1h			; (0000:B9C1=4455h)
data_124e	equ	0BC8Ch			; (0000:BC8C=0EEE9h)
data_126e	equ	0C400h			; (0000:C400=25h)
data_129e	equ	0C928h			; (0000:C928=0A7h)
data_130e	equ	0C930h			; (0000:C930=72h)
data_131e	equ	0C93Ah			; (0000:C93A=1Fh)
data_132e	equ	0C944h			; (0000:C944=0F7h)
data_133e	equ	0C94Eh			; (0000:C94E=0C0h)
data_136e	equ	0D64Eh			; (0000:D64E=8Bh)
data_137e	equ	0D65Eh			; (0000:D65E=26h)
data_138e	equ	0D673h			; (0000:D673=5)
data_139e	equ	0D687h			; (0000:D687=91h)
data_140e	equ	0D69Ah			; (0000:D69A=1Ch)
data_142e	equ	0E260h			; (0000:E260=73h)
data_143e	equ	0E270h			; (0000:E270=0F0h)
data_146e	equ	0E6A6h			; (0000:E6A6=89h)
data_147e	equ	0E6AEh			; (0000:E6AE=6)
data_148e	equ	0EAC9h			; (0000:EAC9=1C00h)
data_156e	equ	0FA80h			; (0000:FA80=77h)
data_159e	equ	0FFFFh			; (0000:FFFF=0C1h)

data_162e	equ	8010h			; (0040:8010=9)
data_166e	equ	0F0h			; (B800:00F0=0DFh)
data_167e	equ	2000h			; (B800:2000=720h)
data_168e	equ	10h			; (C000:0010=30h)
data_169e	equ	11h			; (C000:0011=2Dh)
data_170e	equ	12h			; (C000:0012=30h)
data_171e	equ	17h			; (C000:0017=3Ah)
data_172e	equ	63h			; (C000:0063=382Ch)
data_173e	equ	65h			; (C000:0065=38h)
data_174e	equ	67h			; (C000:0067=3938h)
data_175e	equ	69h			; (C000:0069=412Ch)
data_176e	equ	6Ch			; (C000:006C=204Ch)
data_177e	equ	6Eh			; (C000:006E=4952h)
data_178e	equ	70h			; (C000:0070=47h)
data_179e	equ	72h			; (C000:0072=5354h)
data_180e	equ	96h			; (C000:0096=50h)
data_181e	equ	97h			; (C000:0097=5Ah)
data_182e	equ	0FA6Eh			; (C000:FA6E=0FFh)
data_183e	equ	0			; (F000:0000=55AAh)
data_184e	equ	7D55h			; (F000:7D55=20h)
data_185e	equ	7DE3h			; (F000:7DE3=49h)
data_186e	equ	7E19h			; (F000:7E19=50h)
data_187e	equ	7E3Bh			; (F000:7E3B=50h)
data_188e	equ	7E96h			; (F000:7E96=0Dh)
data_189e	equ	7EA8h			; (F000:7EA8=50h)

;--------------------------------------------------------------	seg_a  ----

seg_a		segment	use16 at 0


						; €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
						; €       Interrupt Vectors       €
						; €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

vector_0h_off	dw	108Ah			; Divide error
						;  xref F000:B0DE, F000:F4C7
						;       F000:F639, F000:F644
vector_0h_seg	dw	116h
vector_1h_off	dw	6F4h			; Single Step
vector_1h_seg	dw	70h			;  xref F000:8270
vector_2h_off	dw	16h			; NMI
vector_2h_seg	dw	35Ch
vector_3h_off	dw	6F4h			; Debug
vector_3h_seg	dw	70h			;  xref F000:95F6
vector_4h_off	dw	6F4h			; Overflow
						;  xref F000:8DF1, F000:B2B7
						;       F000:B4BF, F000:B4C4
						;       F000:B50D
vector_4h_seg	dw	70h			;  xref F000:9516, F000:AE7A
						;       F000:F211, F000:FEA9
vector_5h_off	dw	0FF54h			; Print Screen
vector_5h_seg	dw	0F000h
vector_6h_off	dw	0EB52h			;  xref F000:9C99, F000:9CA3
						;       F000:9CD0, F000:9CD4
						;       F000:9D0B, F000:9D3D
						;       F000:9D4F, F000:9D56

						;       F000:9D78, F000:9E17
						;       F000:9E33, F000:9F67
						;       F000:9F6D, F000:9F7B
						;       F000:9F86, F000:9F9D
						;       F000:9FA4, F000:A1DF
vector_6h_seg	dw	0F000h			;  xref F000:94D8, F000:9E4F
						;       F000:A05A, F000:A144
						;       F000:A19C, F000:A229
						;       F000:A241
vector_7h_off	dw	0EAA6h			;  xref F000:94DB, F000:9E52
						;       F000:A052, F000:A067
						;       F000:A148, F000:A194
						;       F000:A1A4, F000:A22D
vector_7h_seg	dw	0F000h
vector_8h_off	dw	51Bh			; Timer Ticks
						;  xref F000:920A
vector_8h_seg	dw	0CAAh
vector_9h_off	dw	1613h			; Keyboard
vector_9h_seg	dw	4B8h
vector_Ah_off	dw	57h
vector_Ah_seg	dw	35Ch
vector_Bh_off	dw	6Fh			; Serial
vector_Bh_seg	dw	35Ch
vector_Ch_off	dw	87h			; Serial
vector_Ch_seg	dw	35Ch
vector_Dh_off	dw	0C47h			; Disk
vector_Dh_seg	dw	2B1Bh
vector_Eh_off	dw	0B7h			; Diskette
vector_Eh_seg	dw	35Ch
vector_Fh_off	dw	305Eh			; Bad Interrupt
vector_Fh_seg	dw	0CAAh			;  xref F000:AFC8, F000:B180
						;       F000:B277, F000:B4CC
						;       F000:B515, F000:B582
						;       F000:B6A6, F000:B6B5
						;       F000:B6EC, F000:B701
						;       F000:B762, F000:B774
						;       F000:B86F, F000:B94A
						;       F000:B991, F000:B9F2
						;       F000:BC38, F000:BC3F
						;       F000:BC5D, F000:BD70
						;       F000:BD9B, F000:BDBA
vectr_10h_off	dw	68Ch			; Video
						;  xref F000:AFBE, F000:B0EB
						;       F000:BA47, F000:BAE8
						;       F000:CFF7, F000:D049
vectr_10h_seg	dw	10ADh			;  xref F000:926D, F000:B6CA
						;       F000:B789, F000:B95F
						;       F000:B9A6, F000:BA07
						;       F000:BAD8, F000:BCDF
						;       F000:BD50, F000:C036
						;       F000:D000, F000:D04F
vectr_11h_off	dw	0F84Dh			; Equipment
vectr_11h_seg	dw	0F000h
vectr_12h_off	dw	0F841h			; Memory Size
vectr_12h_seg	dw	0F000h
vectr_13h_off	dw	15B5h			; Disk Services
						;  xref F000:A980

vectr_13h_seg	dw	4B8h

		org	400h

@rs232_port_1_	dw	3F8h			; Duplicates
@rs232_port_2_	dw	2F8h			; (see 0040:0000 for
@rs232_port_3_	dw	0			; full information)
@rs232_port_4_	dw	0
@prn_port_1_	dw	278h
@prn_port_2_	dw	3BCh
@prn_port_3_	dw	3BCh
BIOS_data_seg_	dw	0
equip_bits_	dw	0C461h
init_test_flag_	db	0FFh
main_ram_size_	dw	280h
chan_io_size_	dw	0
keybd_flags_1_	db	0
keybd_flags_2_	db	0
keybd_alt_num_	db	0
keybd_q_head_	dw	2Ch
keybd_q_tail_	dw	2Ch
keybd_queue_	dw	186Fh, 1F73h, 1970h
		dw	1C0Dh, 231h, 1579h
		dw	2267h, 3062h, 1E61h
		dw	1474h, 1C0Dh, 1372h
		dw	1675h, 316Eh, 3062h
		dw	1769h
dsk_recal_stat_	db	1
dsk_motor_stat_	db	0
dsk_motor_tmr_	db	4Eh
dsk_ret_code_	db	0
dsk_status_1_	db	0
dsk_status_2_	db	0
dsk_status_3_	db	0
dsk_status_4_	db	0
dsk_status_5_	db	0
dsk_status_6_	db	0Eh
dsk_status_7_	db	2
video_mode_	db	3
video_columns_	dw	50h
video_buf_siz_	dw	1000h
video_segment_	dw	0
vid_curs_pos0_	dw	184Fh
vid_curs_pos1_	dw	0
vid_curs_pos2_	dw	0
vid_curs_pos3_	dw	0
vid_curs_pos4_	dw	0
vid_curs_pos5_	dw	0
vid_curs_pos6_	dw	0
vid_curs_pos7_	dw	0
vid_curs_mode_	dw	2000h
video_page_	db	0
@video_port_	dw	3D4h
video_mode_reg_	db	29h
video_color_	db	30h
@gen_io_ptr_	dw	588h
@gen_io_seg_	dw	9087h

gen_int_occurd_	db	0
timer_low_	dw	2F90h
timer_hi_	dw	0Eh
timer_rolled_	db	0
keybd_break_	db	0
warm_boot_flag_	dw	0
hdsk_status_1_	db	0
hdsk_count_	db	1
hdsk_head_ctrl_	db	8
hdsk_ctrl_port_	db	0
prn_timeout_1_	db	14h
prn_timeout_2_	db	14h
prn_timeout_3_	db	14h
prn_timeout_4_	db	14h
rs232_timeout1_	db	1
rs232_timeout2_	db	1
rs232_timeout3_	db	1
rs232_timeout4_	db	1
@keybd_begin_	dw	1Eh
@keybd_end_	dw	3Eh
video_rows_	db	18h
video_pixels_	dw	10h
video_options_	db	60h
video_switches_	db	9
video_1_resrvd_	db	1
video_2_resrvd_	db	0Bh
dsk_data_rate_	db	5
hdsk_status_2_	db	50h
hdsk_error_	db	0
hdsk_int_flags_	db	0
hdsk_options_	db	37h
hdsk0_media_st_	db	15h
hdsk1_media_st_	db	7
hdsk0_start_st_	db	0
hdsk1_start_st_	db	0
hdsk0_cylinder_	db	0
hdsk1_cylinder_	db	0
keybd_flags_3_	db	10h
keybd_flags_4_	db	10h
@timer_waitoff_	dw	0
@timer_waitseg_	dw	0
timer_clk_low_	dw	0
timer_clk_hi_	dw	0
timer_clk_flag_	db	0
		db	0
		db	0
		db	0
		db	0
		db	0
		db	0
		db	0
		dd	0C0005274h
		db	34 dup (0)
		dw	0

seg_a		ends




;--------------------------------------------------------------	seg_b  ----

seg_b		segment	use16 at 40h


						; €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
						; €    PRIMARY BIOS DATA AREA     €
						; €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

@rs232_port_1	dw	3F8h			; RS-232 port addresses
						;  xref F000:AB54, F000:AB5B
						;       F000:AB6F
@rs232_port_2	dw	2F8h
@rs232_port_3	dw	0
@rs232_port_4	dw	0
@prn_port_1	dw	278h			; Printer port addresses
@prn_port_2	dw	3BCh
@prn_port_3	dw	3BCh
BIOS_data_seg	dw	0			; Extended BIOS data (PS/2)or printer
						;   Printer 4 (PC,XT,AT & compatibles)
equip_bits	dw	0C461h			; Equipment installed info bits
						;  15  14  13   12   11  10   9   8
						;  \    /      game  \       /
						;  # of print  port  # of RS-232
						;  ports 0-3   used   ports 0-4

						;  7   6    5    4    3   2   1   0
						;  \   /    \    /    \   / Math  |
						;  # of   video mode  RAM    uP  no
						;  disk-  at boot up  00=16K    dsk
						;  ettes  00=EGA      01=32K   driv
						;   1-4   01=CGA-40   10=48K   if 0
						;  if bit 10=CGA-80   11=64K
						;  0 = 1  11=MDA-80   (old PCs)

						; Note: bit 13=modem on PC lap-tops
						;       bit  2=mouse on PS/2
						;
						;  xref F000:8609, F000:9221
						;       F000:9232, F000:F854
init_test_flag	db	0FFh			; Initialization test
						;  xref F000:9203, F000:AC8B
						;       F000:ADEC, F000:F126
						;       F000:F195, F000:F1BB
						;       F000:F22B, F000:F2DE
						;       F000:F2F0
main_ram_size	dw	280h			; Base memory size 0-1Meg, 1K steps
						;  xref F000:AC21, F000:AD57
						;       F000:ADCE, F000:BE7E
						;       F000:E9B3, F000:F231
						;       F000:F294, F000:F846
chan_io_size	dw	0			; Channel i/o size
						;  xref F000:F1EE, F000:F2A5
						;       F000:F360


						; €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
						; €         KEYBOARD DATA         €
						; €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

keybd_flags_1	db	0			; Keyboard flag bits
						;   7   6   5   4    3   2   1   0
						; ins- cap num scrl alt ctl lef rig
						; sert --toggles--- --shifts down--

						;  xref F000:9C46, F000:A082
keybd_flags_2	db	0			; Keyboard flag bits
						;    7     6     5     4
						; insert  caps  num  scroll
						; ------now depressed------

						;    3     2     1     0
						;  pause  sys   left right
						;  lock request -alt-down-
						;
keybd_alt_num	db	0			; Alt & digit pad number buffr area
keybd_q_head	dw	2Ch			; Head ptr of circular key queue
						;   empty if head ptr = tail ptr
keybd_q_tail	dw	2Ch			; Tail ptr of circular key queue
						;   empty if head ptr = tail ptr
keybd_queue	dw	186Fh, 1F73h, 1970h	; 15 key queue for keyboard
		dw	1C0Dh, 231h, 1579h
		dw	2267h, 3062h, 1E61h
		dw	1474h, 1C0Dh, 1372h
		dw	1675h, 316Eh, 3062h
		dw	1769h

						; €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
						; €          DISK DATA            €
						; €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

dsk_recal_stat	db	1			;  Recalibrate floppy drive bits
						;     3       2       1       0
						;  drive-3 drive-2 drive-1 drive-0

						;  bit 7 = interrupt flag
						;
						;  xref F000:E837
dsk_motor_stat	db	0			; Motor running status & disk write
						;  bit 7=1 disk write in progress
						;  bits 6&5 = drive selected 0 to 3
						;     3       2       1       0
						;  drive-3 drive-2 drive-1 drive-0
						;  --------- 1=motor on-----------

						;  xref F000:ED20
dsk_motor_tmr	db	49h			; Motor timer, at 0, turn off motor
						;  xref F000:ED15
dsk_ret_code	db	0			; Controller return code
						;  00h = ok
						;  01h = bad command or parameter
						;  02h = can't find address mark
						;  03h = can't write, protected dsk

						;  04h = sector not found
						;  08h = DMA overrun
						;  09h = DMA attempt over 64K bound
						;  10h = bad CRC on disk read
						;  20h = controller failure
						;  40h = seek failure
						;  80h = timeout, no response

dsk_status_1	db	0			; Status bytes-disk controller chip
						;  Note: 7 info bytes returned from
						;  controller are saved here. Refer
						;  to the NEC uPD 765 chip manual
						;  for the specific info, depending
						;  on the previous command issued.
						;  xref F000:A99E
dsk_status_2	db	0
dsk_status_3	db	0
dsk_status_4	db	0
dsk_status_5	db	0
dsk_status_6	db	0Eh
dsk_status_7	db	2

						; €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
						; €          VIDEO DATA           €
						; €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

video_mode	db	3			; Present display mode(see int 10h)
						;  xref F000:8649, F000:87C2
						;       F000:87D0, F000:87F0
						;       F000:886B, F000:88A9
						;       F000:89BB, F000:89EC
						;       F000:89F3, F000:8A3C
						;       F000:8AA5, F000:8AD8
						;       F000:8ADF, F000:8B1B
						;       F000:8B4C, F000:8B53
						;       F000:8BAF, F000:8CD8
						;       F000:8D5F, F000:8D66
						;       F000:8D9E
video_columns	dw	50h			; Number of columns
						;  xref F000:8677, F000:873D
						;       F000:87DD, F000:8899
						;       F000:88BF, F000:88D5
						;       F000:89D5, F000:8A2F
						;       F000:8AC2, F000:8B36
						;       F000:8B9F, F000:8CDB
						;       F000:8D4E, F000:8D77
video_buf_siz	dw	1000h			; Video buffer size in bytes
						;   Note: size may be rounded up to
						;   the nearest 2K boundary.  For
						;   example, 80x25 mode=4000 bytes,
						;   but value may be 4096.
						;  xref F000:8692, F000:8839
						;       F000:89E2, F000:8ACF
						;       F000:8B43
video_segment	dw	0			; Segment of active video memory
						;   MDA=0B000h, CGA=0B800h, etc.


						;  xref F000:8697, F000:8745
						;       F000:87BB, F000:883D
						;       F000:88C9
vid_curs_pos0	dw	184Fh			; Cursor position page 0
						;   bits 15-8=row, bits 7-0=column
						;  xref F000:869D, F000:8A29
						;       F000:8B99
vid_curs_pos1	dw	0			; Cursor position page 1
						;   bits 15-8=row, bits 7-0=column
vid_curs_pos2	dw	0			; Cursor position page 2
						;   bits 15-8=row, bits 7-0=column
vid_curs_pos3	dw	0			; Cursor position page 3
						;   bits 15-8=row, bits 7-0=column
vid_curs_pos4	dw	0			; Cursor position page 4
						;   bits 15-8=row, bits 7-0=column
vid_curs_pos5	dw	0			; Cursor position page 5
						;   bits 15-8=row, bits 7-0=column
vid_curs_pos6	dw	0			; Cursor position page 6
						;   bits 15-8=row, bits 7-0=column
vid_curs_pos7	dw	0			; Cursor position page 7
						;   bits 15-8=row, bits 7-0=column

vid_curs_mode	dw	2000h			; Active cursor, start & end lines
						;   bits 12 to 8 for starting line
						;   bits 4  to 0 for ending line
						;  xref F000:86DD, F000:870D
						;       F000:877A
video_page	db	0			; Present page
						;  xref F000:869A, F000:872C
						;       F000:8833, F000:8C9C
						;       F000:8CE4
@video_port	dw	3D4h			; Video controller base I/O address
						;  xref F000:8645, F000:874F
						;       F000:8783, F000:89FA
						;       F000:8AF4, F000:8B66
						;       F000:8C5E
video_mode_reg	db	29h			; Hardware mode register bits
						;  xref F000:865F, F000:86FE
video_color	db	30h			; Color set in CGA modes
						;  xref F000:8654, F000:8707
						;       F000:8C42, F000:8C5B

						; €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
						; €         GENERAL DATA          €
						; € Note: next 5 bytes also used  €
						; €    for cassette interface in  €
						; €    older PCs.                 €
						; €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

@gen_io_ptr	dw	588h			; ROM initialization pointer
						;  xref F000:9057, F000:AC36
						;       F000:AC4D, F000:AE04
						;       F000:BE7B, F000:BF50
						;       F000:CC0C, F000:CCDB
						;       F000:F2EB
@gen_io_seg	dw	9087h			; ROM i/o segment
						;  xref F000:C097, F000:C8AC

						;       F000:CC12, F000:CCD6
gen_int_occured	db	0			; Unused interrupt occurred
						;  xref F000:EAD5
timer_low	dw	2F97h			; Timer, low word, cnts every 55 ms
						;  xref F000:D02D, F000:D0A4
						;       F000:ECEE, F000:ED49
						;       F000:ED56
timer_hi	dw	0Eh			; Timer, high word
						;  xref F000:ECF1, F000:ED4D
						;       F000:ED5A
timer_rolled	db	0			; Timer overflowed, non-zero when
						;  more than 24 hours have elapsed
						;  xref F000:ED45, F000:ED53
keybd_break	db	0			; Bit 7 set if break key depressed
warm_boot_flag	dw	0			; Boot (reset) type
						;   1234h=warm boot, no memory test
						;   4321h=boot & save memory
						;         (PS/2 with MCA only)
						;  xref F000:8238, F000:924E
						;       F000:C199

						; €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
						; €        HARD DISK DATA         €
						; €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

hdsk_status_1	db	0			; Hard disk status
						;  00h = ok
						;  01h = bad command or parameter
						;  02h = can't find address mark
						;  03h = can't write, protected dsk
						;  04h = sector not found
						;  05h = reset failure
						;  07h = activity failure
						;  08h = DMA overrun
						;  09h = DMA attempt over 64K bound
						;  0Ah = bad sector flag
						;  0Bh = removed bad track
						;  0Dh = wrong # of sectors, format
						;  0Eh = removed control data addr
						;         mark
						;  0Fh = out of limit DMA
						;         arbitration level
						;  10h = bad CRC or ECC, disk read
						;  11h = bad ECC corrected data
						;  20h = controller failure
						;  40h = seek failure
						;  80h = timeout, no response
						;  AAh = not ready
						;  BBh = error occurred, undefined
						;  CCh = write error, selected dsk
						;  E0h = error register = 0
						;  FFh = disk sense failure
						;
						;  xref F000:A31E, F000:A394
						;       F000:A399, F000:A39E
						;       F000:A4B1, F000:A53E
						;       F000:A572, F000:A63A

						;       F000:A644, F000:A672
						;       F000:A6C3, F000:A6F8
						;       F000:A726, F000:A791
						;       F000:A7C1, F000:A7FA
						;       F000:A825, F000:A848
						;       F000:A8A6, F000:A909
						;       F000:A9A7
hdsk_count	db	1			; Number of hard disk drives
						;  xref F000:A372, F000:A386
						;       F000:A4AB, F000:A741
hdsk_head_ctrl	db	8			; Head control (XT only)
						;  xref F000:A520, F000:A590
						;       F000:A921, F000:A928
hdsk_ctrl_port	db	0			; Hard disk control port (XT only)

						; €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
						; € I/O PORT TIMER, KEYBOARD DATA €
						; €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

prn_timeout_1	db	14h			; Countdown timer waits for printer
						;   to respond (printer 1)
						;  xref F000:F88B
prn_timeout_2	db	14h			; Countdown timer waits for printer
						;   to respond
prn_timeout_3	db	14h
prn_timeout_4	db	14h
rs232_timeout_1	db	1			; Countdown timer waits for RS-232
						;   port to respond (port 1)
						;  xref F000:F8EA
rs232_timeout_2	db	1			; Countdown timer waits for RS-232
						;   port to respond
rs232_timeout_3	db	1
rs232_timeout_4	db	1
@keybd_begin	dw	1Eh			; Ptr to beginning of keybd queue
@keybd_end	dw	3Eh			; Ptr to end of keyboard queue

						; €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
						; €  ADVANCED VIDEO DATA, EGA/VGA €
						; €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

video_rows	db	18h			; Rows of characters on display - 1
						;  xref F000:8631, F000:921C
						;       F000:ECB4
video_pixels	dw	10h			; Number of pixels per charactr * 8
video_options	db	60h			; Display adapter options
						;   bit 7 = clear RAM
						;   bits 6,5 = memory on adapter
						;               00 - 64K
						;               01 - 128K
						;               10 - 192K
						;               11 - 256K
						;   bit 4 = unused
						;   bit 3 = 0 if EGA/VGA active
						;   bit 2 = wait for display enable
						;   bit 1 = 1 - mono monitor
						;         = 0 - color monoitor
						;   bit 0 = 0 - handle cursor, CGA

video_switches	db	9			; Switch setting bits from adapter
						;   bits 7-4 = feature connector
						;   bits 3-0 = option switches
video_1_reservd	db	1			; Video reserved 1, EGA/VGA control
						;   bit 7 = 200 line mode
						;   bits 6,5 = unused
						;   bit 4 = 400 line mode
						;   bit 3 = no palette load
						;   bit 2 = mono monitor
						;   bit 1 = gray scale
						;   bit 0 = unused
video_2_reservd	db	0Bh			; Video reserved 2

						; €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
						; € OTHER FLOPPY & HARD DISK DATA €
						; €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

dsk_data_rate	db	5			; Last data rate for diskette
						;  bits 7 & 6 = 00 for 500K bit/sec
						;             = 01 for 300K bit/sec
						;             = 10 for 250K bit/sec
						;  bits 5 & 4 = step rate
hdsk_status_2	db	50h			; Hard disk status
						;  xref F000:A5E2, F000:A666
						;       F000:A7BB, F000:A7F7
						;       F000:A842, F000:A858
						;       F000:A9AC
hdsk_error	db	0			; Hard disk error
						;  xref F000:A35D, F000:A6B7
						;       F000:A87D
hdsk_int_flags	db	0			; Set for hard disk interrupt flag
						;  xref F000:A340, F000:A82B
						;       F000:A8B9, F000:E84B
hdsk_options	db	37h			; Bit 0 = 1 when using 1 controller
						;  card for both hard disk & floppy
						;  xref F000:AF79
hdsk0_media_st	db	15h			; Media state for drive 0
						;  xref F000:AF67, F000:BFA7
hdsk1_media_st	db	7			; Media state for drive 1
						;     7      6      5      4
						;  data xfer rate  two   media
						;   00=500K bit/s  step  known
						;   01=300K bit/s
						;   10=250K bit/s
						;     3      2      1      0
						;  unused  -----state of drive-----
						;          bits floppy  drive state
						;          000=  360K in 360K, ?
						;          001=  360K in 1.2M, ?
						;          010=  1.2M in 1.2M, ?
						;          011=  360K in 360K, ok
						;          100=  360K in 1.2M, ok
						;          101=  1.2M in 1.2M, ok
						;          111=  state not defined

hdsk0_start_st	db	0			; Start state for drive 0
hdsk1_start_st	db	0			; Start state for drive 1

hdsk0_cylinder	db	0			; Track number for drive 0
hdsk1_cylinder	db	0			; Track number for drive 1

						; €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
						; €    ADVANCED KEYBOARD DATA     €
						; €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

keybd_flags_3	db	10h			; Special keyboard type and mode
						;  bit 7 Reading ID of keyboard
						;      6 last char is 1st ID char
						;      5 force num lock
						;      4 101/102 key keyboard
						;      3 right alt key down
						;      2 right ctrl key down
						;      1 E0h hidden code last
						;      0 E1h hidden code last
						;
						;  xref F000:9C19, F000:9C22
						;       F000:9C2B, F000:9C32
						;       F000:9C3F, F000:9C4E
keybd_flags_4	db	10h			; Keyboard Flags (advanced keybd)
						;   7      6       5     4  3 2 1 0
						; xmit   char   Resend  Ack   \   /
						; error was ID  Rec'd  Rec'd   LEDs

						;  xref F000:9BEE, F000:9BF9
						;       F000:A08C, F000:A095
						;       F000:A09C, F000:A0B2
						;       F000:A0B7, F000:A0BB
						;       F000:A0C5, F000:A0D1

						; €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€
						; €  REAL-TIME CLOCK & LAN DATA   €
						; €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

@timer_wait_off	dw	0			; Ptr offset to wait done flag
						;  xref F000:CD3C, F000:EA84
@timer_wait_seg	dw	0			; Ptr segment to wait done flag
						;  xref F000:CD40
timer_clk_low	dw	0			; Timer low word, 1 microsecond clk
						;  xref F000:CD44, F000:EA6A
timer_clk_hi	dw	0			; Timer high word
						;  xref F000:CD48, F000:EA70
timer_clk_flag	db	0			; Timer flag 00h = post acknowledgd
						;            01h = busy
						;            80h = posted
						;  xref F000:CB64, F000:CD2C
						;       F000:CD37, F000:EA7F
lan_1		db	0			; Local area network bytes (7)
lan_2		db	0
lan_3		db	0
lan_4		db	0
lan_5		db	0
lan_6		db	0
lan_7		db	0

						; €ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€

						; €   MORE ADVANCED VIDEO DATA    €
						; €‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€

@video_sav_tbls	dd	0C0005274h		; Pointer to a save table of more
						; pointers for the video system
						;            SAVE TABLE
						;  offset type    pointer to
						;  ƒƒƒƒƒƒ ƒƒƒƒ ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
						;    0     dd  Video parameters
						;    4     dd  Parms save area
						;    8     dd  Alpha char set
						;   0Ch    dd  Graphics char set
						;   10h    dd  2nd save ptr table
						;   14h    dd  reserved (0:0)
						;   18h    dd  reserved (0:0)
						;
						;  2ND SAVE TABLE (from ptr above)
						;  offset type functions & pointers
						;  ƒƒƒƒƒƒ ƒƒƒƒ ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
						;    0     dw  Bytes in this table
						;    2     dd  Combination code tbl
						;    6     dd  2nd alpha char set
						;   0Ah    dd  user palette tbl
						;   0Eh    dd  reserved (0:0)
						;   12h    dd  reserved (0:0)
						;   16h    dd  reserved (0:0)

		db	34 dup (0)
		dw	0
		db	32 dup (0)
		db	 42h, 4Ch, 45h, 56h, 45h, 00h
		db	 3Dh
		db	9 dup (0)
prn_scrn_stat_b	db	0

seg_b		ends



;--------------------------------------------------------------	seg_c  ----

seg_c		segment	use16 at 50h

prn_scrn_stat	db	0			; Print screen status
						;    00h = Print screen ready
						;    01h = Print screen in progress
						;    FFh = Error occurred
						;  xref F000:EC63, F000:ECCC
		db	0

seg_c		ends



;--------------------------------------------------------------	seg_d  ----

seg_d		segment	para public use16

		assume cs:seg_d , ds:seg_a


		org	8000h

begin_text	db	'XXXX88886666----0123AAAAMMMMIIII'	;  xref F000:81BF
		db	' Date:-04/09/90 '
copyright	db	'(C)1985-1990, American Megatrend'
		db	's Inc. All Rights '
		db	'Reserved. 1346 Oakbrook Drive, S'
		db	'uite-120, Norcross, GA-30093, US'
		db	'A.Phone-(404)-263-8181.'
loc_11:						;  xref F000:FED6
		cli				; Disable interrupts
		cld				; Clear direction
		in	al,64h			; port 64h, keyboard status
		test	al,4
		jnz	short loc_12		; Jump if not zero
		mov	al,8Dh
		out	70h,al			; port 70h, RTC addr/enabl NMI
		jmp	loc_19			; (8182)
loc_12:						;  xref F000:80BF
		mov	al,8Fh
		out	70h,al			; port 70h, RTC addr/enabl NMI
						;  al = 8Fh, NMI off/pwr status
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		in	al,71h			; port 71h, RTC clock/RAM data
		mov	ah,0
		mov	si,ax

		mov	al,8Fh
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	70h,al			; port 70h, RTC addr/enabl NMI
						;  al = 8Fh, NMI off/pwr status
		mov	al,0
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	71h,al			; port 71h, RTC clock/RAM data
		mov	ax,cs
		mov	ss,ax
		mov	ax,si
		cmp	al,4
		je	short loc_13		; Jump if equal
		cmp	al,5
		je	short loc_13		; Jump if equal
		cmp	al,0Ah
		jbe	short loc_14		; Jump if below or =
		jmp	loc_23			; (81D0)
loc_13:						;  xref F000:80EE, 80F2
		mov	bx,data_68e		; (0000:0870=5)
		mov	sp,8104h
		jmp	loc_1154		; (EEDC)
		db	 06h, 81h
loc_14:						;  xref F000:80F6
		mov	ax,si
		cmp	al,5
		je	short loc_15		; Jump if equal
		cmp	al,9
		je	short loc_15		; Jump if equal
		cmp	al,0Ah
		jne	short loc_16		; Jump if not equal
loc_15:						;  xref F000:810A, 810E
		smsw	ax			; Store machine stat
		test	ah,0FFh
		jnz	short loc_16		; Jump if not zero
		ror	eax,10h			; Rotate
		mov	cx,ax
		mov	eax,cr0			; Mov reg-control reg
		and	eax,9FFFFFFFh
		mov	cr0,eax			; Mov reg-control reg
		mov	ax,cx
		ror	eax,10h			; Rotate
loc_16:						;  xref F000:8112, 811A
		mov	ax,seg_b
		mov	ds,ax
		mov	al,0
		mov	es,ax
		mov	al,30h			; '0'
		mov	ss,ax
;*		mov	sp,offset loc_10	;*
		db	0BCh, 00h, 01h
		shl	si,1			; Shift w/zeros fill
		jmp	word ptr cs:data_190[si]	;*(F000:814C=81D0h)  7 entries
		db	90h
data_190	dw	offset loc_23		; Data table (indexed access)
						;  xref F000:8146

data_191	dw	offset loc_580		;  xref F000:8146
data_192	dw	offset loc_236		;  xref F000:8146
data_193	dw	offset loc_588		;  xref F000:8146
data_194	dw	offset loc_237		;  xref F000:8146
data_195	dw	offset loc_240		;  xref F000:8146
data_196	dw	offset loc_615		;  xref F000:8146
		db	0D1h,0F5h,0D0h, 81h,0D6h,0CCh
		db	 57h, 90h
loc_17:						;  xref F000:818D, 8196, 81A3
		mov	bp,5
		jmp	loc_191			; (8DFA)
loc_18:						;  xref F000:819E, 81AB
		mov	bx,ax
		mov	cx,bx
		mov	dx,cx
		mov	si,dx
		mov	di,si
		mov	bp,di
		mov	es,bp
		mov	ax,es
		mov	ds,ax
		mov	ax,ds
		mov	ss,ax
		mov	ax,ss
		jmp	sp			;*Register jump
loc_19:						;  xref F000:80C5
		mov	al,1
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	sp,5555h
		cmp	sp,5555h
		jne	loc_17			; Jump if not equal
		mov	sp,0AAAAh
		cmp	sp,0AAAAh
		jne	loc_17			; Jump if not equal
		mov	ax,5555h
		mov	sp,81A0h
		jmp	short loc_18		; (8168)
		xor	ax,5555h
		jnz	loc_17			; Jump if not zero
		mov	ax,0AAAAh
		mov	sp,81ADh
		jmp	short loc_18		; (8168)
		db	 35h,0AAh,0AAh, 75h,0B0h

locloop_20:					;  xref F000:81B2
		loop	locloop_20		; Loop if cx > 0


locloop_21:					;  xref F000:81B4
		loop	locloop_21		; Loop if cx > 0

		mov	al,2
		out	80h,al			; port 80h, diagnostc chkpoint
		xor	bx,bx			; Zero register
		mov	cx,4000h
		mov	si,offset begin_text	; (F000:8000=58h)


locloop_22:					;  xref F000:81C6
		lods word ptr cs:[si]		; String [si] to ax
		add	bx,ax
		loop	locloop_22		; Loop if cx > 0

		jz	short loc_23		; Jump if zero
		mov	bp,offset vector_2h_off+1	; (0000:0009=0)
		jmp	loc_191			; (8DFA)

;ƒƒƒƒƒ Indexed Entry Point ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ

loc_23:						;  xref F000:80F8, 8146, 814C, 81C8
		mov	al,3
		out	80h,al			; port 80h, diagnostc chkpoint
		xor	bp,bp			; Zero register
		mov	ds,bp
		mov	es,bp
		mov	ax,cs
		mov	ss,ax
		in	al,64h			; port 64h, keyboard status
		test	al,4
		jz	short loc_24		; Jump if zero
		jmp	short loc_28		; (81FD)
loc_24:						;  xref F000:81E2
		jmp	short loc_31		; (8243)
loc_25:						;  xref F000:821B
		mov	ah,6
		xor	cx,cx			; Zero register

locloop_26:					;  xref F000:81F2, 81F8
		jmp	short $+2		; delay for I/O
		in	al,64h			; port 64h, keyboard status
		test	al,1
		loopz	locloop_26		; Loop if zf=1, cx>0

		jnz	short loc_27		; Jump if not zero
		dec	ah
		jnz	locloop_26		; Jump if not zero
loc_27:						;  xref F000:81F4
		in	al,60h			; port 60h, keybd scan or sw1
		retn
loc_28:						;  xref F000:81E4
		nop
		mov	sp,8204h
		jmp	loc_224			; (8F84)
		push	es
		xor	byte ptr ds:data_146e[bx+si],64h	; (0000:E6A6=89h) 'd'
		mov	sp,8210h
		jmp	loc_224			; (8F84)
		adc	al,[bp+si+1A8h]
		jz	short loc_29		; Jump if zero
		in	al,60h			; port 60h, keybd scan or sw1
loc_29:						;  xref F000:8214
		mov	sp,821Dh
		jmp	short loc_25		; (81E8)
		pop	ds
		cmp	byte ptr [si],0FFh

		je	short loc_30		; Jump if equal
		mov	dx,460h
		ror	al,3			; Rotate
		or	al,80h
		mov	ah,al
		in	al,dx			; ??io  non-standard i/o port.
		and	ax,0A09Fh
		or	al,ah
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	dx,al			; ??io  non-standard i/o port.
loc_30:						;  xref F000:8221
		cmp	warm_boot_flag_,1234h	; (0000:0472=0)
		jne	short loc_31		; Jump if not equal
		mov	bp,8000h
loc_31:						;  xref F000:81E6, 823E
		xor	cx,cx			; Zero register

locloop_32:					;  xref F000:8256
		jmp	short $+2		; delay for I/O
		in	al,64h			; port 64h, keyboard status
		mov	ah,al
		test	al,1
		jz	short loc_33		; Jump if zero
		jmp	short $+2		; delay for I/O
		in	al,60h			; port 60h, keybd scan or sw1
loc_33:						;  xref F000:824D
		test	ah,2
		loopnz	locloop_32		; Loop if zf=0, cx>0

		mov	al,0AAh
		out	64h,al			; port 64h, kybd cntrlr functn
						;  al = 0AAh, self test
		mov	sp,8262h
		jmp	loc_224			; (8F84)
		cmp	byte ptr fs:data_106e[si],0E9h	; (0000:826A=36h)
;*		jle	loc_34			;*Jump if < or =
		db	 7Eh,0FFh
		insb				; Port dx to es:[di]
		cmp	byte ptr [si],55h	; 'U'
		je	short loc_35		; Jump if equal
		mov	bp,offset vector_1h_seg	; (0000:0006=70h)
		jmp	loc_191			; (8DFA)
loc_35:						;  xref F000:826E
		mov	al,60h			; '`'
		out	64h,al			; port 64h, kybd cntrlr functn
						;  al = 60h, write command byte
		mov	sp,8280h
		jmp	loc_224			; (8F84)
		add	byte ptr [bp+si-9D2h],6
		shl	dl,40h			; '@' Shift w/zeros fill
		mov	al,55h			; 'U'
		jz	short loc_36		; Jump if zero
		mov	al,74h			; 't'
loc_36:						;  xref F000:828A
		out	60h,al			; port 60h, keybd data write
		mov	sp,8296h

		jmp	loc_224			; (8F84)
		cbw				; Convrt byte to word
		xor	byte ptr ds:data_147e[bx+si],64h	; (0000:E6AE=6) 'd'
		mov	sp,82A2h
		jmp	loc_224			; (8F84)
		movsb				; Mov [si] to es:[di]
		xor	byte ptr ds:data_122e[bx],0	; (0000:B900=5)
		inc	ax

locloop_37:					;  xref F000:82B7
		jmp	short $+2		; delay for I/O
		in	al,64h			; port 64h, keyboard status
		and	al,1
		jz	short loc_38		; Jump if zero
		jmp	short $+2		; delay for I/O
		in	al,60h			; port 60h, keybd scan or sw1
loc_38:						;  xref F000:82AF
		cmp	al,52h			; 'R'
		loopnz	locloop_37		; Loop if zf=0, cx>0

		jnz	short loc_39		; Jump if not zero
		or	bp,bp			; Zero ?
		js	short loc_39		; Jump if sign=1
		mov	bh,8
		or	bp,2
loc_39:						;  xref F000:82B9, 82BD
		mov	al,0ADh
		out	64h,al			; port 64h, kybd cntrlr functn
						;  al = 0ADh, disable keyboard
		mov	sp,82CEh
		jmp	loc_224			; (8F84)
		rol	byte ptr [bp+si-4748h],1	; Rotate
		mov	ax,0BC90h
		fiadd	dword ptr [bp+si-5017h]	; st = st + memory
		imul	bx,sp,0FF82h		; reg1 = reg2 * value
		and	al,0F7h
		or	al,bh
		xchg	al,ah
		mov	sp,82E8h
		jmp	loc_1149		; (EE92)
;*		jmp	far ptr loc_9		;*(E604:B082)
		db	0EAh, 82h,0B0h, 04h,0E6h
		cmp	byte ptr ds:data_87e[bx+si],90h	; (0000:558F=0F6h)
		mov	sp,82F8h
		jmp	loc_1149		; (EE92)
		db	0FAh, 82h,0BCh, 00h, 83h
loc_41:						;  xref F000:8378
		jmp	loc_1148		; (EE89)
		add	al,[bp+di-3BCEh]
		jnz	short loc_42		; Jump if not zero
		mov	ax,0AA8Fh
		nop
		mov	sp,8310h
		jmp	loc_1149		; (EE92)
		adc	al,[bp+di+18BCh]
		sub	cx,71h
		imul	bx,word ptr [bp+si],0FF83h	; reg = data * value

		xor	al,ah
		jz	short loc_43		; Jump if zero
loc_42:						;  xref F000:8304
		or	bp,4000h
loc_43:						;  xref F000:831C
		mov	al,8Dh
		mov	sp,832Ah
		jmp	loc_1148		; (EE89)
		sub	al,83h
		or	al,al			; Zero ?
		mov	ax,8E8Eh
		nop
		mov	sp,8338h
		jmp	loc_1148		; (EE89)
		cmp	al,[bp+di+878h]
		or	bp,20h
		or	al,0DCh
		jmp	short loc_48		; (8393)
		nop
		or	al,al			; Zero ?
		js	short loc_46		; Jump if sign=1
		mov	bx,ax
		xor	cx,cx			; Zero register
		xor	dx,dx			; Zero register
		mov	ax,9090h
loc_44:						;  xref F000:8364
		nop
		mov	sp,8358h
		jmp	loc_1148		; (EE89)
		pop	dx
		or	word ptr [bp+si+3C8h],0FFD1h
		inc	ah
		mov	al,ah
		cmp	al,0AEh
		jne	loc_44			; Jump if not equal
		inc	ah
		mov	sp,836Eh
		jmp	loc_1148		; (EE89)
;*		jo	loc_40			;*Jump if overflow=1
		db	 70h, 83h
		xchg	al,ah
		mov	sp,8378h
		jmp	loc_1148		; (EE89)
		jp	loc_41			; Jump if parity=1
		cmp	ax,dx
		mov	ax,bx
		jnz	short loc_45		; Jump if not zero
		or	dx,dx			; Zero ?
		jnz	short loc_47		; Jump if not zero
loc_45:						;  xref F000:837E
		or	al,5Ch			; '\'
		or	bp,80h
		jmp	short loc_48		; (8393)
loc_46:						;  xref F000:8346
		or	bp,40h
		jmp	short loc_48		; (8393)
loc_47:						;  xref F000:8382

		and	al,8Bh
loc_48:						;  xref F000:8341, 838A, 838F
		mov	bx,ax
		mov	ax,8B8Bh
		mov	sp,839Eh
		jmp	loc_1148		; (EE89)
		mov	al,ds:data_76e		; (0000:2483=36h)
		pop	es
		xchg	al,ah
		mov	sp,83AAh
		jmp	loc_1149		; (EE92)
		lodsb				; String [si] to al
		xor	word ptr ds:data_124e[bx+si],0FFB4h	; (0000:BC8C=0EEE9h)
		sub	cx,0FFD5h
		push	0FFB6h
		cmp	word ptr ds:data_111e[bx+si],0FF90h	; (0000:8A8A=6D46h)
		mov	sp,83C0h
		jmp	loc_1148		; (EE89)
		retn	2483h
		db	 0Fh, 75h, 0Ch,0B0h, 26h, 86h
		db	0C4h,0BCh,0D0h, 83h,0E9h,0C2h
		db	 6Ah,0D2h, 83h
		db	0B0h, 94h,0BCh,0DAh, 83h,0E9h
		db	0AFh, 6Ah,0DCh, 83h,0D0h,0E8h
		db	 8Bh,0C3h, 72h, 05h, 83h,0CDh
		db	 40h, 0Ch, 20h
loc_50:						;  xref F000:83E0
		xchg	al,ah
		nop
		mov	sp,83F0h
		jmp	loc_1149		; (EE92)
		db	0F2h, 83h, 0Fh, 01h,0E0h,0F6h
		db	0C4h,0FFh, 75h, 0Eh, 0Fh, 20h
		db	0C0h, 66h, 0Dh, 00h, 00h, 00h
		db	 60h, 0Fh, 22h,0C0h, 0Fh, 08h
		db	 33h,0C0h, 8Eh,0C0h, 8Eh,0D8h
		db	0B0h, 04h,0E6h, 08h,0EBh, 00h
		db	0EBh, 00h,0E6h,0D0h,0B0h, 00h
		db	0EBh, 00h,0EBh, 00h,0E6h, 8Fh
		db	0BBh, 70h, 08h, 90h,0BCh, 2Ah
		db	 84h,0E9h,0B6h, 6Ah, 2Ch, 84h
		db	0B0h, 05h,0E6h, 80h, 33h,0C0h
		db	0BAh,0D8h, 03h,0EEh,0EBh, 00h
		db	0EBh, 00h, 40h,0B2h,0B8h,0EEh
		db	0EBh, 00h,0EBh, 00h,0B2h,0BAh
		db	0ECh,0EBh, 00h,0EBh, 00h,0B2h
		db	0DAh,0ECh,0EBh, 00h,0EBh, 00h
		db	0B2h,0C0h,0B0h, 00h,0EEh,0B0h
		db	 06h,0E6h, 80h,0B0h,0FCh,0E6h
		db	 61h,0EBh, 00h,0EBh, 00h,0E4h
		db	 61h,0A8h, 01h, 74h, 03h, 83h
		db	0CDh, 01h
		db	0B0h,0B4h,0E6h, 43h,0B0h, 55h
		db	0EBh, 00h,0EBh, 00h,0E6h, 42h
		db	0B0h,0AAh,0EBh, 00h,0EBh, 00h
		db	0E6h, 42h,0B0h, 80h,0EBh, 00h
		db	0EBh, 00h,0E6h, 43h,0EBh, 00h

		db	0EBh, 00h,0E4h, 42h, 8Ah,0E0h
		db	0EBh, 00h,0EBh, 00h,0E4h, 42h
		db	 3Dh,0AAh, 55h, 74h, 03h, 83h
		db	0CDh, 01h
loc_53:						;  xref F000:8497
		mov	al,7
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	al,0FDh
		out	61h,al			; port 61h, 8255 B - spkr, etc
		mov	dx,42h
		mov	sp,84ACh
		jmp	short loc_57		; (84D1)
		db	 75h, 03h, 83h,0CDh, 01h
		db	0B0h, 08h,0E6h, 80h,0B2h, 41h
		db	0BCh,0BCh, 84h,0EBh, 15h, 74h
		db	 0Dh,0B0h, 09h,0E6h, 80h,0B2h
		db	40h
		db	0BCh,0C9h, 84h,0EBh, 08h
loc_55:						;  xref F000:84C4
		jnz	short loc_63		; Jump if not zero
loc_56:						;  xref F000:84BC
		mov	bp,4
		jmp	loc_191			; (8DFA)
loc_57:						;  xref F000:84AA, 84BA, 84C7
		mov	al,dl
		and	al,3
		ror	al,2			; Rotate
		mov	bl,al
		or	al,14h
		mov	bh,al
		out	43h,al			; port 43h, 8253 wrt timr mode
		mov	al,0FFh
		mov	ah,al
		mov	cx,20h
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	dx,al			; port 42h, 8253 timer 2 spkr

locloop_58:					;  xref F000:84EC
		loop	locloop_58		; Loop if cx > 0

		mov	al,bl
		out	43h,al			; port 43h, 8253 wrt timr mode
						;  al = 80h, timer 3 count mode
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		in	al,dx			; port 42h, 8253 timer 2 spkr
		sub	ah,al
		jz	short loc_62		; Jump if zero
		mov	al,bh
		jmp	short $+2		; delay for I/O
		out	43h,al			; port 43h, 8253 wrt timr mode
loc_59:						;  xref F000:857A
		mov	al,0CCh
		mov	bh,al
		mov	cl,20h			; ' '
		jmp	short $+2		; delay for I/O

		jmp	short $+2		; delay for I/O
		out	dx,al			; port 42h, 8253 timer 2 spkr

locloop_60:					;  xref F000:850C
		loop	locloop_60		; Loop if cx > 0

		mov	al,bl
		out	43h,al			; port 43h, 8253 wrt timr mode
						;  al = 80h, timer 3 count mode
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		in	al,dx			; port 42h, 8253 timer 2 spkr
		sub	bh,al
		jz	short loc_62		; Jump if zero
		sub	ah,bh
		jnc	short loc_61		; Jump if carry=0
		neg	ah
loc_61:						;  xref F000:851D
		cmp	ah,6
		jb	short loc_62		; Jump if below
		xor	al,al			; Zero register
loc_62:						;  xref F000:84F9, 8519, 8524
		jmp	sp			;*Register jump
loc_63:						;  xref F000:84C9
		mov	al,0Ah
		out	80h,al			; port 80h, diagnostc chkpoint
		in	al,61h			; port 61h, 8255 port B, read
		and	al,0FCh
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	61h,al			; port 61h, 8255 B - spkr, etc
		mov	al,54h			; 'T'
		out	43h,al			; port 43h, 8253 wrt timr mode
		xor	di,di			; Zero register
		mov	cx,8000h
		rep	stosw			; Rep when cx >0 Store ax to es:[di]
		mov	al,12h
		out	41h,al			; port 41h, 8253 timer 1 refsh
		mov	cx,8000h
		rep	stosw			; Rep when cx >0 Store ax to es:[di]
		xor	si,si			; Zero register
		mov	cx,8000h
		rep	lodsw			; Rep when cx >0 String [si] to ax
		mov	al,0Bh
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	al,36h			; '6'
		out	43h,al			; port 43h, 8253 wrt timr mode
		mov	al,0
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	40h,al			; port 40h, 8253 timer 0 clock
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	40h,al			; port 40h, 8253 timer 0 clock
		mov	al,0Ch
		out	80h,al			; port 80h, diagnostc chkpoint
		xor	bx,bx			; Zero register

		mov	ah,10h
		mov	dx,61h
		mov	sp,857Ah
		jmp	loc_209			; (8ED0)
		jl	loc_59			; Jump if <
		jcxz	short loc_71		; Jump if cx=0
		mov	al,0Dh
		out	80h,al			; port 80h, diagnostc chkpoint
loc_67:						;  xref F000:8588
		jmp	short $+2		; delay for I/O
		in	al,61h			; port 61h, 8255 port B, read
		test	al,ah
		jz	loc_67			; Jump if zero
		xor	cx,cx			; Zero register

locloop_68:					;  xref F000:8594
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		in	al,61h			; port 61h, 8255 port B, read
		test	al,ah
		loopnz	locloop_68		; Loop if zf=0, cx>0

		xchg	bx,cx

locloop_69:					;  xref F000:85A0
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		in	al,61h			; port 61h, 8255 port B, read
		test	al,ah
		loopz	locloop_69		; Loop if zf=1, cx>0

		sub	cx,bx
		jns	short loc_70		; Jump if not sign
		neg	cx
loc_70:						;  xref F000:85A4
		cmp	cx,6
		jb	short loc_72		; Jump if below
loc_71:						;  xref F000:857C
		mov	bp,1
		jmp	loc_191			; (8DFA)
loc_72:						;  xref F000:85AB
		jmp	loc_252			; (911A)
data_197	dw	offset sub_7		; Data table (indexed access) (8631)
						;  xref F000:861C
data_198	dw	offset sub_8		; (870D)
						;  xref F000:861C
data_199	dw	offset sub_9		; (8716)
						;  xref F000:861C
data_200	dw	offset sub_12		; (8769)
						;  xref F000:861C
data_201	dw	offset sub_13		; (8781)
						;  xref F000:861C
data_202	dw	offset sub_14		; (8829)
						;  xref F000:861C
data_203	dw	offset sub_15		; (8858)
						;  xref F000:861C
data_204	dw	offset sub_16		; (885C)

						;  xref F000:861C
data_205	dw	offset sub_17		; (89B9)
						;  xref F000:861C
data_206	dw	offset sub_18		; (8AA5)
						;  xref F000:861C
data_207	dw	offset sub_19		; (8B1B)
						;  xref F000:861C
data_208	dw	offset sub_20		; (8C42)
						;  xref F000:861C
data_209	dw	offset sub_21		; (8C67)
						;  xref F000:861C
data_210	dw	offset sub_22		; (8C84)
						;  xref F000:861C
data_211	dw	offset sub_23		; (8C8F)
						;  xref F000:861C
data_212	dw	offset sub_24		; (8CD8)
						;  xref F000:861C
data_213	dw	offset sub_25		; (8CEB)
						;  xref F000:861C
data_214	dw	offset sub_25		; (8CEB)
						;  xref F000:861C
data_215	dw	offset sub_25		; (8CEB)
						;  xref F000:861C
data_216	dw	offset sub_26		; (8CEC)
						;  xref F000:861C


; ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± int 10h ±±±±±
;
;   VIDEO DISPLAY SERVICES
;
;      Called with:  ah	= primary function number
;
;      Returns:	(unless	otherwise indicated)
;		     ax	- altered (some systems may not alter ax)
;
;      Functions:
;        ah = 0	    Set	video display mode in al.
;        ah = 1	    Set	cursor size
;		      Call with:  ch = top line, 0-32
;			          cl = bottom line, 0-32
;        ah = 2	    Set	cursor location
;		      Call with:  bh = page number, 0 = 1st page
;			          dh = row (0 for top row)
;			          dl = column (0 for leftmost)
;        ah = 3	    Get	cursor location
;		      Call with:  bh = page number, 0 = 1st page
;		      Returns:    ch/cl = cursor size (top & bottom)
;			          dh/dl = row and column of cursor
;        ah = 4	    Get	light pen location
;		      Returns:    ah = 0 not on/unsupported & bx,cx,dx changed
;			               1 status valid
;			          bx = pixel column
;			          cx = horizontal line number
;			          dh/dl = row and column
;        ah = 5	    Set	Page number al, 0 = 1st page
;        ah = 6	    Up scroll screen

;		      Call with:  al = # bottom lines to clear,	set 0 for all
;			          bh = attribute to fill cleared lines
;			          ch/cl = row/column of top left scroll corner
;			          dh/dl = row/column of bottom right scroll corner
;        ah = 7	    Down scroll screen
;		      Call with:  al = # top lines to clear, set 0 for all
;			          bh = attribute to fill cleared lines
;			          ch/cl = row/column of top left scroll corner
;			          dh/dl = row/column of bottom right scroll corner
;        ah = 8	    Get	character & attribute at cursor
;		      Call with:  bh = page number, 0 = 1st page
;		      Returns:    ah/al = attribute/character
;        ah = 9	    Write character & attribute at cursor (graphics modes)
;		      Call with:  al = character
;			          bh = page number, 0 = 1st page
;			          bl = attribute, bit 7 = 1 to xor with old color
;			          cx = Number of same characters to write
;        ah = 0Ah   Write character at cursor (graphics modes)
;		      Call with:  al = character
;			          bh = page number, 0 = 1st page
;			          cx = Number of same characters to write
;        ah = 0Bh   Set	colors (typically in low res modes)
;		      Call with:  bh = 0, bl = color low res background, border
;			          bh = 1, bl = 0/1 for low res color group 0/1
;        ah = 0Ch   Write graphics dot
;		      Call with:  al = color, bit 7 = 1 to xor bit with old color
;			          cx/dx = pixel row/pixel column
;        ah = 0Dh   Read graphics dot
;		      Call with:  cx/dx = pixel row/pixel column
;        ah = 0Eh   Write in ASCII mode (cr, lf, bell, and bs as operators)
;		      Call with:  al/bl = character/color
;        ah = 0Fh   Get	video info
;		      Returns:    ah = columns active
;			          al = active video mode
;			          bh = active page, 0 = 1st page
;        ah = 10h   Colors  (EGA/VGA)   Called with al = subfunction
;		      al = 1    bl = color register (0-15)  bh = color to set
;		      al = 2    es:dx = ptr to change all 16 colors & overscan #
;		      al = 3    bl = color high bit as: 0-intensity, 1-blink
;		    For	VGA equipped systems only
;		      al = 7    bl = color register to get in bh
;		      al = 8    bh = returned overscan value
;		      al = 9    es:dx = ptr where to put all 16	colors & overscan
;		      al = 10h  bx = color register to set; ch/cl/dl = grn/blu/red
;		      al = 12h  es:dx = ptr to change color registers
;			        bx = 1st register to set, cx = # of registers
;		      al = 13h  bl = 0, set color page mode in bh
;			        bl = 1, set page;  bh = page number
;		      al = 15h  bx = color reg to read; ch/cl/dl = grn/blu/red
;		      al = 17h  es:dx = ptr where to load color	regs
;			        bx = 1st register to get, cx = # of registers
;		      al = 1Ah  get color page info; bl = mode;	bh = page #
;        ah = 11h   Reset mode with new character set (leave memory as-is)
;		      al = 0    Character set load
;			        es:bp = ptr to table of chars
;			        bl/bh = which block/bytes per char
;			        cx/dx = # of characters/where to start in block

;		      al = 1    bl = block to load the mono character set
;		      al = 2    bl = block to load the double wide character set
;		      al = 3    bl = block select related to attribute
;		      al = 4    bl = block to load the 8 by 16 set (VGA)
;		      al = 10h - 14h same as 0 - 4, must occur after setting mode
;		      al = 20h  es:bp = ptr to table of char, using int 1Fh ptr
;		      al = 21h  es:bp = ptr to table of char, using int 43h ptr
;			        bl = 0-dl=# rows; 1-14 rows; 2-25 rows; 3-43 rows
;			        cx = number of bytes per character in table
;		      al = 22h  use 8 by 14 char set, bl=rows (see al=21h)
;		      al = 23h  use double wide char set, bl=rows (see al=21h)
;		      al = 24h  use 8 by 16 char set, bl=rows (see al=21h)
;		    Get	table pointer and info
;		      al = 30h  es:bp = ptr returned; cx=bytes per char; dl=rows
;			        bh = 0, get int 1Fh      bh = 4, get double wide
;			        bh = 1, get int 43h      bh = 5, get mono 9 by 14
;			        bh = 2, get 8 by 14      bh = 6, get 8 by 16 (VGA)
;			        bh = 3, get double wide  bh = 7, get 9 by 16 (VGA)
;        ah = 12h   Miscellaneous functions, bl = sub-function
;		      bl = 10h  Get info,  bh = 0-now color, 1-now mono
;			        ch/cl = info bits/switches
;		      bl = 20h  Set print screen to work with EGA/VGA
;		    Functions for VGA only (bl = 30-34h return al = 12h)
;		      bl = 30h  Set # of scan lines, 0-200, 1-350, 2-400
;			          activates after mode change
;		      bl = 31h  ax = 0/1  allow/prevent palette	load with new mode
;		      bl = 32h  al = 0/1  video off/on
;		      bl = 33h  al = 0/1  gray scale summing off/on
;		      bl = 34h  al = 0/1  scale cursor size to font off/on
;		      bl = 35h  switch between adapter and motherboard video
;			        al = 0, adapter off, es:dx = save state area
;			        al = 1, motherboard on
;			        al = 2, active video off, es:dx	= save area
;			        al = 3, inactive video on, es:dx = save area
;		      bl = 36h  al = 0/1  screen off/on
;        ah = 13h   Write character string (cr, lf, bell, and bs as operators)
;		      Call with:  al = 0/1 write characters, cursor not/is moved
;			                bl = attribute of all characters
;			             = 2/3 write characters, cursor not/is moved
;			                string alternates character & attribute
;			          bh = page number, 0 = 1st page
;			          cx = number of characters
;			          dh/dl = row and column to start
;			          es:bp = ptr to character string
;        ah = 14h   LCD	display support, al = sub-function
;		       al = 0,    es:di = ptr to font table to load
;			          bl/bh = which block/bytes per	char
;			          cx/dx = # of characters/where	to start in block
;		       al = 1,    bl = block # of ROM font to load
;		       al = 2,    bl = how to support high intensity
;        ah = 15h   LCD	info table ptr returned in es:di
;		       ax = 0      there is no alternate adapter
;		       ax = 5140h  LCD is the alternate
;		       ax = 5153h  CGA is alternate
;		       ax = 5151h  MDA is alternate
;
;			    **** VGA SUPPORT ONLY ****

;        ah = 1Ah   Get/Set types of displays which are operating
;		       al = 0, get displays, returns al = 1Ah
;			       bl = in use display code
;			       bh = alternate display code
;		       al = 1, set codes, returns al = 1Ah
;			       bl = in use display code
;			       bh = alternate display code
;		       codes:   0 = no display
;			        1 = mono display
;			        2 = CGA
;			        4 = EGA, color
;			        5 = EGA, mono
;			        6 = PGA
;			        7 = VGA, mono  (PS/2 MCA only)
;			        8 = VGA, color (PS/2 MCA only)
;			       Bh = VGA, mono  (PS/2 non MCA)
;			       Ch = VGA, color (PS/2 non MCA)
;			      FFh = display type not known
;        ah = 1Bh   Get	video system information
;		       call with:  bx = 0
;			           es:di = ptr to buffer where to put info
;        ah = 1Ch   Video system save & restore, al = sub-function
;		       call with:  al = 0, get buffer size
;			              = 1, save system, buffer at es:bx
;			              = 2, restore system, buffer at es:bx
;			           cx bit 0 = 1 for hardware registers
;			              bit 1 = 1 for software states
;			              bit 2 = 1 for colors & DAC registers

int_10h_video	proc	near			;  xref F000:F065
		sti				; Enable interrupts
		cld				; Clear direction
		cmp	ah,0Eh
		je	short loc_76		; Jump if equal
		cmp	ah,2
		je	short loc_77		; Jump if equal
		cmp	ah,3
		je	short loc_78		; Jump if equal
		cmp	ah,5
		je	short loc_79		; Jump if equal
		pusha				; Save all regs
		push	ds
		push	es
		cmp	ah,13h
		ja	short loc_75		; Jump if above
		push	ax
		mov	al,ah
		cbw				; Convrt byte to word
		mov	di,ax
		mov	ax,seg_b
		mov	ds,ax
		jz	short loc_74		; Jump if zero
		assume	ds:seg_b
		mov	al,byte ptr equip_bits	; (0040:0010=61h)
		and	al,30h			; '0'
		cmp	al,30h			; '0'
		mov	ax,0B000h

		jz	short loc_73		; Jump if zero
		mov	ah,0B8h
loc_73:						;  xref F000:8613
		mov	es,ax
loc_74:						;  xref F000:8607
		pop	ax
		shl	di,1			; Shift w/zeros fill
		call	word ptr cs:data_197[di]	;*(F000:85B6=8631h)  20 entries
loc_75:						;  xref F000:85FA
		pop	es
		pop	ds
		popa				; Restore all regs
		iret				; Interrupt return
int_10h_video	endp

loc_76:						;  xref F000:85E3
		jmp	loc_170			; (8C8F)
loc_77:						;  xref F000:85E8
		jmp	loc_88			; (8716)
loc_78:						;  xref F000:85ED
		jmp	loc_91			; (8769)
loc_79:						;  xref F000:85F2
		jmp	loc_103			; (8829)

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85B6, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_7		proc	near
		mov	video_rows,18h		; (0040:0084=18h)
		mov	dx,es
		cmp	dh,0B0h
		mov	dx,3D4h
		jnz	short loc_80		; Jump if not zero
		mov	dx,3B4h
		mov	al,7
loc_80:						;  xref F000:863E
		mov	@video_port,dx		; (0040:0063=3D4h)
		mov	video_mode,al		; (0040:0049=3)
		mov	ah,3Fh			; '?'
		cmp	al,6
		je	short loc_81		; Jump if equal
		mov	ah,30h			; '0'
loc_81:						;  xref F000:8650
		mov	video_color,ah		; (0040:0066=30h)
		mov	ah,al
		mov	bx,offset video_hdwr_mode	; (F000:F0F4=2Ch)
		xlat cs:[bx]			; al=[al+[bx]] table
		mov	video_mode_reg,al	; (0040:0065=29h)
		and	al,37h			; '7'
		add	dx,4
		out	dx,al			; port 3B8h, MDA video control
		sub	dx,4
		mov	al,28h			; '('
		test	ah,2

		jz	short loc_82		; Jump if zero
		mov	al,50h			; 'P'
loc_82:						;  xref F000:8670
		mov	bl,ah
		cbw				; Convrt byte to word
		mov	video_columns,ax	; (0040:004A=50h)
		mov	ax,800h
		cmp	bl,1
		jbe	short loc_83		; Jump if below or =
		mov	ax,1000h
		cmp	bl,3
		jbe	short loc_83		; Jump if below or =
		cmp	bl,7
		je	short loc_83		; Jump if equal
		mov	ax,4000h
loc_83:						;  xref F000:8680, 8688, 868D
		mov	video_buf_siz,ax	; (0040:004C=1000h)
		xor	ax,ax			; Zero register
		mov	video_segment,ax	; (0040:004E=0)
		mov	video_page,al		; (0040:0062=0)
		mov	di,offset vid_curs_pos0	; (0040:0050=4Fh)
		mov	cx,8

locloop_84:					;  xref F000:86A7
		mov	[di],ax
		inc	di
		inc	di
		loop	locloop_84		; Loop if cx > 0

		push	bx
		push	es
		mov	es,cx
		les	si,dword ptr es:video_hdw_off	; (0000:0074=85h) Load 32 bit ptr
		cmp	bl,6
		jne	short loc_85		; Jump if not equal
		dec	bl
loc_85:						;  xref F000:86B5
		shr	bl,1			; Shift w/zeros fill
		shl	bl,4			; Shift w/zeros fill
		xor	bh,bh			; Zero register
		add	si,bx
		mov	cx,10h

locloop_86:					;  xref F000:86D5
		mov	al,bh
		out	dx,al			; port 3B4h, MDA/EGA reg index
						;  al = 0, horiz char total
		jmp	short $+2		; delay for I/O
		inc	dx
		mov	al,es:[si]
		inc	si
		out	dx,al			; port 3B5h, MDA/EGA indxd data
		jmp	short $+2		; delay for I/O
		inc	bh
		dec	dx
		loop	locloop_86		; Loop if cx > 0


		mov	ax,es:[si-6]
		xchg	al,ah
		mov	vid_curs_mode,ax	; (0040:0060=2000h)
		pop	es
		pop	bx
		mov	cx,800h
		mov	ax,720h
		cmp	bl,7
		je	short loc_87		; Jump if equal
		mov	cx,2000h
		cmp	bl,3
		jbe	short loc_87		; Jump if below or =
		xor	ax,ax			; Zero register
loc_87:						;  xref F000:86EB, 86F3
		xor	di,di			; Zero register
		cli				; Disable interrupts
		cld				; Clear direction
		rep	stosw			; Rep when cx >0 Store ax to es:[di]
		sti				; Enable interrupts
		mov	al,video_mode_reg	; (0040:0065=29h)
		add	dx,4
		out	dx,al			; port 3B8h, MDA video control
		jmp	short $+2		; delay for I/O
		mov	al,video_color		; (0040:0066=30h)
		inc	dx
		out	dx,al			; port 3B9h, CGA color(port3D9)
		retn
sub_7		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85B8, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_8		proc	near
		mov	vid_curs_mode,cx	; (0040:0060=2000h)
		mov	al,0Ah
		jmp	short loc_90		; (874F)
		db	90h

;ﬂﬂﬂﬂ External Entry into Subroutine ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;
;         Called from:	 F000:85BA, 861C

sub_9:
loc_88:						;  xref F000:8628
		push	ds
		push	ax
		push	bx
		push	cx
		push	dx
		mov	ax,seg_b
		mov	ds,ax
		mov	al,bh
		mov	bl,bh

		xor	bh,bh			; Zero register
		shl	bx,1			; Shift w/zeros fill
		mov	[bx+50h],dx
		cmp	al,video_page		; (0040:0062=0)
		jne	short loc_89		; Jump if not equal
		call	sub_10			; (873B)
loc_89:						;  xref F000:8730
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		pop	ds
		iret				; Interrupt return

;ﬂﬂﬂﬂ External Entry into Subroutine ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;
;         Called from:	 F000:8732, 884F

sub_10:
		mov	al,dh
		mul	byte ptr video_columns	; (0040:004A=50h) ax = data * al
		xor	dh,dh			; Zero register
		add	ax,dx
		mov	cx,video_segment	; (0040:004E=0)
		shr	cx,1			; Shift w/zeros fill
		add	cx,ax
		mov	al,0Eh
sub_8		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8846
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_11		proc	near
loc_90:						;  xref F000:8713
		mov	dx,@video_port		; (0040:0063=3D4h)
		out	dx,al			; port 3D4h, CGA/EGA reg index
						;  al = 0Ch, start address high
		jmp	short $+2		; delay for I/O
		inc	dx
		xchg	al,ch
		out	dx,al			; port 3D5h, CGA/EGA indxd data
		inc	ch
		jmp	short $+2		; delay for I/O
		dec	dx
		xchg	al,ch
		out	dx,al			; port 3D4h, CGA/EGA reg index
						;  al = 0Dh, start address low
		jmp	short $+2		; delay for I/O
		inc	dx
		xchg	al,cl
		out	dx,al			; port 3D5h, CGA/EGA indxd data
		retn
sub_11		endp



;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85BC, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_12		proc	near
loc_91:						;  xref F000:862B
		push	ds
		push	bx
		mov	bl,bh
		xor	bh,bh			; Zero register
		shl	bx,1			; Shift w/zeros fill
		mov	dx,seg seg_b
		mov	ds,dx
		mov	dx,[bx+50h]
		mov	cx,vid_curs_mode	; (0040:0060=2000h)
		pop	bx
		pop	ds
		iret				; Interrupt return
sub_12		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85BE, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_13		proc	near
		mov	bp,sp
		mov	dx,@video_port		; (0040:0063=3D4h)
		add	dx,6
		mov	si,dx
		in	al,dx			; port 3DAh, CGA/EGA vid status
		test	al,4
		mov	ah,0
		jz	short loc_92		; Jump if zero
		jmp	loc_101			; (8821)
loc_92:						;  xref F000:8791
		test	al,2
		jnz	short loc_93		; Jump if not zero
		jmp	loc_102			; (8825)
loc_93:						;  xref F000:8798
		sub	dx,6
		mov	al,10h
		mov	ch,11h
		out	dx,al			; port 3D4h, CGA/EGA reg index
						;  al = 10h, light pen high
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		inc	dx
		in	al,dx			; port 3D5h, CGA/EGA indxd data
		xchg	al,ch
		dec	dx

		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	dx,al			; port 3D4h, CGA/EGA reg index
						;  al = 11h, light pen low
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		inc	dx
		in	al,dx			; port 3D5h, CGA/EGA indxd data
		xchg	al,cl
		mov	ax,video_segment	; (0040:004E=0)
		shr	ax,1			; Shift w/zeros fill
		sub	cx,ax
		mov	al,video_mode		; (0040:0049=3)
		mov	bx,offset data_286	; (F000:F0FC=3)
		xlat cs:[bx]			; al=[al+[bx]] table
		sub	cx,ax
		jns	short loc_94		; Jump if not sign
		xor	cx,cx			; Zero register
loc_94:						;  xref F000:87CC
		mov	ah,video_mode		; (0040:0049=3)
		cmp	ah,4
		jb	short loc_95		; Jump if below
		cmp	ah,7
		cmc				; Complement carry
loc_95:						;  xref F000:87D7
		mov	al,byte ptr video_columns	; (0040:004A=50h)
		xchg	ax,cx
		jc	short loc_96		; Jump if carry Set
		mov	cl,28h			; '('
loc_96:						;  xref F000:87E1
		div	cl			; al, ah rem = ax/reg
		mov	ch,al
		xchg	al,ah
		mov	dx,ax
		cbw				; Convrt byte to word
		mov	bx,ax
		mov	ah,video_mode		; (0040:0049=3)
		cmp	ah,4
		jb	short loc_97		; Jump if below
		cmp	ah,7
		cmc				; Complement carry
loc_97:						;  xref F000:87F7
		jc	short loc_98		; Jump if carry Set
		shl	ch,1			; Shift w/zeros fill
		shr	dh,2			; Shift w/zeros fill
		cmp	ah,6
		jne	short loc_99		; Jump if not equal
		shl	dl,1			; Shift w/zeros fill
		shl	bx,4			; Shift w/zeros fill
		jmp	short loc_100		; (8816)
loc_98:						;  xref F000:87FD
		shl	ch,3			; Shift w/zeros fill
loc_99:						;  xref F000:8807
		shl	bx,3			; Shift w/zeros fill
loc_100:					;  xref F000:880E
		mov	[bp+10h],dx
		mov	[bp+13h],ch

		mov	[bp+0Eh],bx
		mov	ah,1
loc_101:					;  xref F000:8793
		mov	dx,si
		inc	dx
		out	dx,al			; port 3DBh, CGA light pen clr
loc_102:					;  xref F000:879A
		mov	[bp+15h],ah
		retn
sub_13		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85C0, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_14		proc	near
loc_103:					;  xref F000:862E
		push	ds
		push	ax
		push	bx
		push	cx
		push	dx
		mov	dx,seg seg_b
		mov	ds,dx
		mov	video_page,al		; (0040:0062=0)
		cbw				; Convrt byte to word
		mov	bx,ax
		mul	video_buf_siz		; (0040:004C=1000h) ax = data * ax
		mov	video_segment,ax	; (0040:004E=0)
		shr	ax,1			; Shift w/zeros fill
		mov	cx,ax
		mov	al,0Ch
		call	sub_11			; (874F)
		shl	bx,1			; Shift w/zeros fill
		mov	dx,[bx+50h]
		call	sub_10			; (873B)
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		pop	ds
		iret				; Interrupt return
sub_14		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85C2, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_15		proc	near
		xor	bl,bl			; Zero register
		jmp	short loc_104		; (8861)


;ﬂﬂﬂﬂ External Entry into Subroutine ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;
;         Called from:	 F000:85C4, 861C

sub_16:
		mov	bl,0FFh
		mov	si,dx
		std				; Set direction flag
loc_104:					;  xref F000:885A
		push	ds
		push	bx
		sub	dx,cx
		add	dx,101h
		push	dx
		push	ax
		mov	ah,video_mode		; (0040:0049=3)
		cmp	ah,4
		jb	short loc_105		; Jump if below
		cmp	ah,7
		cmc				; Complement carry
loc_105:					;  xref F000:8872
		mov	dx,28h
		jnc	short loc_109		; Jump if carry=0
		cmp	ah,2
		je	short loc_106		; Jump if equal
		cmp	ah,3
		jne	short loc_108		; Jump if not equal
loc_106:					;  xref F000:8880
		mov	dx,3DAh
		push	cx
		xor	cx,cx			; Zero register

locloop_107:					;  xref F000:8890
		in	al,dx			; port 3DAh, CGA/EGA vid status
		test	al,8
		loopz	locloop_107		; Loop if zf=1, cx>0

		pop	cx
		mov	al,25h			; '%'
		mov	dx,3D8h
		out	dx,al			; port 3D8h, CGA video control
loc_108:					;  xref F000:8885
		mov	dx,video_columns	; (0040:004A=50h)
loc_109:					;  xref F000:887B
		mov	bp,dx
		shl	bp,1			; Shift w/zeros fill
		and	bl,bl
		jz	short loc_110		; Jump if zero
		neg	bp
		mov	cx,si
loc_110:					;  xref F000:88A3
		mov	ah,video_mode		; (0040:0049=3)
		cmp	ah,4
		jb	short loc_111		; Jump if below
		cmp	ah,7
		cmc				; Complement carry

loc_111:					;  xref F000:88B0
		xchg	ax,cx
		mov	cl,dl
		mov	dx,ax
		jnc	short loc_112		; Jump if carry=0
		mov	al,dh
		mul	byte ptr video_columns	; (0040:004A=50h) ax = data * al
		xor	dh,dh			; Zero register
		add	ax,dx
		shl	ax,1			; Shift w/zeros fill
		add	ax,video_segment	; (0040:004E=0)
		mov	di,ax
		pop	ax
		pop	dx
		jmp	short loc_115		; (8900)
loc_112:					;  xref F000:88BB
		mov	al,dh
		mul	byte ptr video_columns	; (0040:004A=50h) ax = data * al
		shl	ax,2			; Shift w/zeros fill
		xor	dh,dh			; Zero register
		add	ax,dx
		mov	di,ax
		pop	ax
		pop	dx
		shl	dh,2			; Shift w/zeros fill
		cmp	ch,6
		je	short loc_113		; Jump if equal
		shl	di,1			; Shift w/zeros fill
		shl	dl,1			; Shift w/zeros fill
		and	bl,bl
		jz	short loc_113		; Jump if zero
		inc	di
loc_113:					;  xref F000:88EA, 88F2
		and	bl,bl
		jz	short loc_114		; Jump if zero
		add	di,data_166e		; (B800:00F0=0DFh)
loc_114:					;  xref F000:88F7
		shl	al,2			; Shift w/zeros fill
loc_115:					;  xref F000:88D1
		push	es
		pop	ds
		mov	bh,dh
		or	al,al			; Zero ?
		jz	short loc_121		; Jump if zero
		sub	dh,al
		jz	short loc_121		; Jump if zero
		mov	bh,al
		mul	cl			; ax = reg * al
		shl	ax,1			; Shift w/zeros fill
		and	bl,bl
		jz	short loc_116		; Jump if zero
		neg	ax
loc_116:					;  xref F000:8914
		mov	si,di
		add	si,ax
		xor	ah,ah			; Zero register
		xchg	ah,ch

		cmp	ah,4
		jb	short loc_117		; Jump if below
		cmp	ah,7
		cmc				; Complement carry
loc_117:					;  xref F000:8923
		push	bx
		jc	short loc_123		; Jump if carry Set
loc_118:					;  xref F000:894E
		mov	ax,si
		mov	bx,di
		mov	cl,dl
		rep	movsb			; Rep when cx >0 Mov [si] to es:[di]
		mov	di,bx
		mov	si,ax
		add	si,data_167e		; (B800:2000=20h)
		add	di,data_167e		; (B800:2000=20h)
		mov	cl,dl
		rep	movsb			; Rep when cx >0 Mov [si] to es:[di]
		mov	di,bx
		mov	si,ax
		add	si,bp
		add	di,bp
		dec	dh
		jnz	loc_118			; Jump if not zero
		pop	bx
loc_119:					;  xref F000:897D
		pop	ax
		mov	al,ah
		mov	dh,bh
loc_120:					;  xref F000:896C
		mov	bx,di
		mov	cl,dl
		rep	stosb			; Rep when cx >0 Store al to es:[di]
		mov	di,bx
		add	di,data_167e		; (B800:2000=20h)
		mov	cl,dl
		rep	stosb			; Rep when cx >0 Store al to es:[di]
		mov	di,bx
		add	di,bp
		dec	dh
		jnz	loc_120			; Jump if not zero
		pop	ds
		retn
loc_121:					;  xref F000:8906, 890A
		xor	ah,ah			; Zero register
		xchg	ah,ch
		cmp	ah,4
		jb	short loc_122		; Jump if below
		cmp	ah,7
		cmc				; Complement carry
loc_122:					;  xref F000:8977
		jnc	loc_119			; Jump if carry=0
		jmp	short loc_124		; (8996)
loc_123:					;  xref F000:892A, 8993
		mov	ax,si
		mov	bx,di
		mov	cl,dl

		rep	movsw			; Rep when cx >0 Mov [si] to es:[di]
		mov	di,bx
		mov	si,ax
		add	si,bp
		add	di,bp
		dec	dh
		jnz	loc_123			; Jump if not zero
		pop	bx
loc_124:					;  xref F000:897F
		pop	ax
		mov	al,20h			; ' '
		mov	dh,bh
loc_125:					;  xref F000:89A7
		mov	bx,di
		mov	cl,dl
		rep	stosw			; Rep when cx >0 Store ax to es:[di]
		mov	di,bx
		add	di,bp
		dec	dh
		jnz	loc_125			; Jump if not zero
		pop	ds
		assume	ds:seg_a
		cmp	byte ptr vectr_12h_off+1,7	; (0000:0049=0F8h)
		je	short loc_ret_126	; Jump if equal
		mov	al,byte ptr ds:vectr_19h_off+1	; (0000:0065=16h)
		mov	dx,3D8h
		out	dx,al			; port 3D8h, CGA video control

loc_ret_126:					;  xref F000:89AF
		retn
sub_15		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85C6, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_17		proc	near
		mov	bp,sp
		assume	ds:seg_b
		mov	ah,video_mode		; (0040:0049=3)
		cmp	ah,7
		je	short loc_127		; Jump if equal
		cmp	ah,4
		jae	short loc_131		; Jump if above or =
loc_127:					;  xref F000:89C2
		mov	bl,bh
		xor	bh,bh			; Zero register
		shl	bx,1			; Shift w/zeros fill
		mov	dx,[bx+50h]
		mov	al,dh
		mul	byte ptr video_columns	; (0040:004A=50h) ax = data * al
		xor	dh,dh			; Zero register
		add	ax,dx
		shl	ax,1			; Shift w/zeros fill

		shr	bx,1			; Shift w/zeros fill
		xchg	ax,bx
		mul	video_buf_siz		; (0040:004C=1000h) ax = data * ax
		add	ax,bx
		mov	si,ax
		cli				; Disable interrupts
		cld				; Clear direction
		cmp	video_mode,7		; (0040:0049=3)
		je	short loc_130		; Jump if equal
		cmp	video_mode,2		; (0040:0049=3)
		jb	short loc_130		; Jump if below
		mov	dx,@video_port		; (0040:0063=3D4h)
		add	dx,6
		xor	cx,cx			; Zero register

locloop_128:					;  xref F000:8A0E
		sti				; Enable interrupts
		cld				; Clear direction
		cli				; Disable interrupts
		cld				; Clear direction
		in	al,dx			; port 3DAh, CGA/EGA vid status
		test	al,8
		jnz	short loc_130		; Jump if not zero
		test	al,1
		loopnz	locloop_128		; Loop if zf=0, cx>0

		xor	cx,cx			; Zero register

locloop_129:					;  xref F000:8A17
		in	al,dx			; port 3DAh, CGA/EGA vid status
		jmp	short $+2		; delay for I/O
		test	al,9
		loopz	locloop_129		; Loop if zf=1, cx>0

loc_130:					;  xref F000:89F1, 89F8, 8A0A
		lods word ptr es:[si]		; String [si] to ax
		sti				; Enable interrupts
		jmp	loc_136			; (8A9F)
loc_131:					;  xref F000:89C7
		mov	di,ds:[8]		; (B800:0008=0C4h)
		sub	sp,di
		neg	di
		mov	bx,2000h
		mov	dx,vid_curs_pos0	; (0040:0050=184Fh)
		mov	al,dh
		mul	byte ptr video_columns	; (0040:004A=50h) ax = data * al
		shl	ax,2			; Shift w/zeros fill
		xor	dh,dh			; Zero register
		add	ax,dx
		mov	si,ax
		cmp	video_mode,6		; (0040:0049=3)
		mov	cx,es
		mov	ds,cx
		jz	short loc_133		; Jump if zero
		shl	si,1			; Shift w/zeros fill
loc_132:					;  xref F000:8A56
		mov	ax,[si]

		call	sub_30			; (8DBE)
		mov	ax,[bx+si]
		add	si,50h
		call	sub_30			; (8DBE)
		jnz	loc_132			; Jump if not zero
		jmp	short loc_134		; (8A69)
loc_133:					;  xref F000:8A45, 8A67
		mov	al,[si]
		mov	[bp+di],al
		inc	di
		mov	al,[bx+si]
		add	si,50h
		mov	[bp+di],al
		inc	di
		jnz	loc_133			; Jump if not zero
loc_134:					;  xref F000:8A58
		mov	di,ss
		mov	ds,di
		mov	di,cs
		mov	es,di
		mov	di,data_182e		; (C000:FA6E=0FFh)
		xor	al,al			; Zero register
loc_135:					;  xref F000:8A8A, 8A9D
		mov	si,sp
		mov	cx,8
		cli				; Disable interrupts
		cld				; Clear direction
		repe	cmpsb			; Rep zf=1+cx >0 Cmp [si] to es:[di]
		sti				; Enable interrupts
		jz	short loc_136		; Jump if zero
		inc	al
		jz	short loc_136		; Jump if zero
		add	di,cx
		cmp	al,80h
		jne	loc_135			; Jump if not equal
		xor	ax,ax			; Zero register
		mov	es,ax
		les	di,dword ptr es:graph_tbl_off	; (0000:007C=0E02h) Load 32 bit ptr
		mov	cx,es
		or	cx,di
		jz	short loc_136		; Jump if zero
		mov	al,80h
		jmp	short loc_135		; (8A76)
loc_136:					;  xref F000:8A1C, 8A80, 8A84, 8A99
		mov	[bp+14h],ax
		mov	sp,bp
		retn
sub_17		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85C8, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_18		proc	near

		mov	ah,video_mode		; (0040:0049=3)
		cmp	ah,7
		je	short loc_137		; Jump if equal
		cmp	ah,4
		jae	short loc_145		; Jump if above or =
loc_137:					;  xref F000:8AAC
		mov	ah,bl
		push	ax
		mov	bl,bh
		xor	bh,bh			; Zero register
		shl	bx,1			; Shift w/zeros fill
		mov	dx,[bx+50h]
		mov	al,dh
		mul	byte ptr video_columns	; (0040:004A=50h) ax = data * al
		xor	dh,dh			; Zero register
		add	ax,dx
		shl	ax,1			; Shift w/zeros fill
		shr	bx,1			; Shift w/zeros fill
		xchg	ax,bx
		mul	video_buf_siz		; (0040:004C=1000h) ax = data * ax
		add	ax,bx
		mov	di,ax
		pop	ax
		cmp	video_mode,7		; (0040:0049=3)
		je	short loc_138		; Jump if equal
		cmp	video_mode,2		; (0040:0049=3)
		jae	short loc_140		; Jump if above or =
loc_138:					;  xref F000:8ADD
		cli				; Disable interrupts
		cld				; Clear direction
		stosw				; Store ax to es:[di]
		dec	cx
		jz	short loc_139		; Jump if zero
		rep	stosw			; Rep when cx >0 Store ax to es:[di]
loc_139:					;  xref F000:8AEA
		sti				; Enable interrupts
		retn
loc_140:					;  xref F000:8AE4
		mov	bx,ax
		mov	si,cx
		mov	dx,@video_port		; (0040:0063=3D4h)
		add	dx,6
loc_141:					;  xref F000:8B18
		xor	cx,cx			; Zero register

locloop_142:					;  xref F000:8B08
		sti				; Enable interrupts
		cld				; Clear direction
		cli				; Disable interrupts
		cld				; Clear direction
		in	al,dx			; port 3DAh, CGA/EGA vid status
		test	al,8
		jnz	short loc_144		; Jump if not zero
		test	al,1
		loopnz	locloop_142		; Loop if zf=0, cx>0

		xor	cx,cx			; Zero register


locloop_143:					;  xref F000:8B11
		in	al,dx			; port 3DAh, CGA/EGA vid status
		jmp	short $+2		; delay for I/O
		test	al,9
		loopz	locloop_143		; Loop if zf=1, cx>0

loc_144:					;  xref F000:8B04
		mov	ax,bx
		stosw				; Store ax to es:[di]
		sti				; Enable interrupts
		dec	si
		jnz	loc_141			; Jump if not zero
		retn

;ﬂﬂﬂﬂ External Entry into Subroutine ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;
;         Called from:	 F000:85CA, 861C

sub_19:
		mov	ah,video_mode		; (0040:0049=3)
		cmp	ah,7
		je	short loc_146		; Jump if equal
		cmp	ah,4
loc_145:					;  xref F000:8AB1
		jae	short loc_154		; Jump if above or =
loc_146:					;  xref F000:8B22
		push	ax
		mov	bl,bh
		xor	bh,bh			; Zero register
		shl	bx,1			; Shift w/zeros fill
		mov	dx,[bx+50h]
		mov	al,dh
		mul	byte ptr video_columns	; (0040:004A=50h) ax = data * al
		xor	dh,dh			; Zero register
		add	ax,dx
		shl	ax,1			; Shift w/zeros fill
		shr	bx,1			; Shift w/zeros fill
		xchg	ax,bx
		mul	video_buf_siz		; (0040:004C=1000h) ax = data * ax
		add	ax,bx
		mov	di,ax
		pop	ax
		cmp	video_mode,7		; (0040:0049=3)
		je	short loc_147		; Jump if equal
		cmp	video_mode,2		; (0040:0049=3)
		jae	short loc_149		; Jump if above or =
loc_147:					;  xref F000:8B51
		cli				; Disable interrupts
		cld				; Clear direction

locloop_148:					;  xref F000:8B5E
		stosb				; Store al to es:[di]
		inc	di
		loop	locloop_148		; Loop if cx > 0

		sti				; Enable interrupts

		retn
loc_149:					;  xref F000:8B58
		mov	bl,al
		mov	si,cx
		mov	dx,@video_port		; (0040:0063=3D4h)
		add	dx,6
loc_150:					;  xref F000:8B8B
		xor	cx,cx			; Zero register

locloop_151:					;  xref F000:8B7A
		sti				; Enable interrupts
		cld				; Clear direction
		cli				; Disable interrupts
		cld				; Clear direction
		in	al,dx			; port 3DAh, CGA/EGA vid status
		test	al,8
		jnz	short loc_153		; Jump if not zero
		test	al,1
		loopnz	locloop_151		; Loop if zf=0, cx>0

		xor	cx,cx			; Zero register

locloop_152:					;  xref F000:8B83
		in	al,dx			; port 3DAh, CGA/EGA vid status
		jmp	short $+2		; delay for I/O
		test	al,9
		loopz	locloop_152		; Loop if zf=1, cx>0

loc_153:					;  xref F000:8B76
		mov	al,bl
		stosb				; Store al to es:[di]
		sti				; Enable interrupts
		inc	di
		dec	si
		jnz	loc_150			; Jump if not zero
		retn
loc_154:					;  xref F000:8B27
		push	bp
		mov	bp,cx
		push	ax
		and	ax,7Fh
		shl	ax,3			; Shift w/zeros fill
		push	ax
		mov	dx,vid_curs_pos0	; (0040:0050=184Fh)
		mov	al,dh
		mul	byte ptr video_columns	; (0040:004A=50h) ax = data * al
		shl	ax,2			; Shift w/zeros fill
		xor	dh,dh			; Zero register
		add	ax,dx
		mov	di,ax
		mov	si,data_182e		; (C000:FA6E=0FFh)
		mov	dh,video_mode		; (0040:0049=3)
		mov	dl,bl
		push	cs
		pop	ds
		pop	ax
		pop	bx

		and	bl,bl
		jns	short loc_155		; Jump if not sign
		xor	si,si			; Zero register
		mov	ds,si
		lds	si,dword ptr ds:graph_tbl_off	; (0000:007C=0E02h) Load 32 bit ptr
loc_155:					;  xref F000:8BBB
		add	si,ax
		cmp	dh,6
		je	short loc_161		; Jump if equal
		shl	di,1			; Shift w/zeros fill
		mov	al,dl
		and	al,3
		xor	dh,dh			; Zero register
loc_156:					;  xref F000:8BD9
		or	dh,al
		shl	al,2			; Shift w/zeros fill
		jnz	loc_156			; Jump if not zero
loc_157:					;  xref F000:8C0B
		mov	cx,4

locloop_158:					;  xref F000:8C01
		mov	al,[si]
		inc	si
		call	sub_31			; (8DD5)
		jns	short loc_159		; Jump if not sign
		xor	ax,es:[di]
loc_159:					;  xref F000:8BE4
		mov	es:[di],ax
		mov	al,[si]
		inc	si
		call	sub_31			; (8DD5)
		jns	short loc_160		; Jump if not sign
		xor	ax,es:data_167e[di]	; (B800:2000=720h)
loc_160:					;  xref F000:8BF2
		mov	es:data_167e[di],ax	; (B800:2000=720h)
		add	di,50h
		loop	locloop_158		; Loop if cx > 0

		sub	di,13Eh
		sub	si,8
		dec	bp
		jnz	loc_157			; Jump if not zero
		pop	bp
		retn
loc_161:					;  xref F000:8BCA
		shl	dl,1			; Shift w/zeros fill
		lahf				; Load ah from flags
loc_162:					;  xref F000:8C3E
		mov	cx,4

locloop_163:					;  xref F000:8C34
		mov	al,[si]
		inc	si
		sahf				; Store ah into flags
		jnc	short loc_164		; Jump if carry=0
		xor	al,es:[di]
loc_164:					;  xref F000:8C19

		mov	es:[di],al
		mov	al,[si]
		inc	si
		sahf				; Store ah into flags
		jnc	short loc_165		; Jump if carry=0
		xor	al,es:data_167e[di]	; (B800:2000=20h)
loc_165:					;  xref F000:8C25
		mov	es:data_167e[di],al	; (B800:2000=20h)
		add	di,50h
		loop	locloop_163		; Loop if cx > 0

		sub	di,13Fh
		sub	si,8
		dec	bp
		jnz	loc_162			; Jump if not zero
		pop	bp
		retn
sub_18		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85CC, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_20		proc	near
		mov	al,video_color		; (0040:0066=30h)
		and	bh,bh
		jz	short loc_166		; Jump if zero
		or	al,20h			; ' '
		test	bl,1
		jnz	short loc_167		; Jump if not zero
		and	al,0DFh
		jmp	short loc_167		; (8C5B)
loc_166:					;  xref F000:8C47
		and	al,0E0h
		and	bl,1Fh
		or	al,bl
loc_167:					;  xref F000:8C4E, 8C52
		mov	video_color,al		; (0040:0066=30h)
		mov	dx,@video_port		; (0040:0063=3D4h)
		add	dx,5
		out	dx,al			; port 3D9h, CGA color control
		retn
sub_20		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85CE, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_21		proc	near
		mov	bl,al
		call	sub_29			; (8D86)

		mov	ah,bl
		and	bl,ch
		and	ah,ah
		jns	short loc_168		; Jump if not sign
		xor	al,bl
		jmp	short loc_169		; (8C7E)
loc_168:					;  xref F000:8C72
		not	ch
		and	al,ch
		or	al,bl
loc_169:					;  xref F000:8C76
		ror	al,cl			; Rotate
		mov	es:[si],al
		retn
sub_21		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85D0, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_22		proc	near
		call	sub_29			; (8D86)
		and	al,ch
		mov	bp,sp
		mov	[bp+14h],al
		retn
sub_22		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85D2, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_23		proc	near
loc_170:					;  xref F000:8625
		push	ds
		push	ax
		push	bx
		push	cx
		push	dx
		push	ax
		mov	ax,seg_b
		mov	ds,ax
		mov	ah,3
		mov	bh,video_page		; (0040:0062=0)
		int	10h			; Video display   ah=functn 03h
						;  get cursor loc in dx, mode cx
		pop	ax
		cmp	al,0Dh
		jbe	short loc_174		; Jump if below or =
loc_171:					;  xref F000:8CC2
		mov	ah,0Ah

		call	sub_27			; (8D47)
loc_172:					;  xref F000:8CC7, 8CD2, 8CD6
		mov	ah,2
		int	10h			; Video display   ah=functn 02h
						;  set cursor location in dx
loc_173:					;  xref F000:8CCC
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		pop	ds
		iret				; Interrupt return
loc_174:					;  xref F000:8CA5
		jz	short loc_176		; Jump if zero
		cmp	al,8
		je	short loc_177		; Jump if equal
		cmp	al,7
		je	short loc_175		; Jump if equal
		cmp	al,0Ah
		jne	loc_171			; Jump if not equal
		call	sub_28			; (8D56)
		jmp	short loc_172		; (8CAC)
loc_175:					;  xref F000:8CBE
		call	sub_36			; (8E82)
		jmp	short loc_173		; (8CB0)
loc_176:					;  xref F000:8CB6
		xor	dl,dl			; Zero register
loc_177:					;  xref F000:8CBA
		and	dl,dl
		jz	loc_172			; Jump if zero
		dec	dl
		jmp	short loc_172		; (8CAC)
sub_23		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85D4, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_24		proc	near
		mov	al,video_mode		; (0040:0049=3)
		mov	ah,byte ptr video_columns	; (0040:004A=50h)
		mov	bp,sp
		mov	[bp+14h],ax
		mov	al,video_page		; (0040:0062=0)
		mov	[bp+0Fh],al
		retn
sub_24		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85D6, 85D8, 85DA, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹


sub_25		proc	near
		retn
sub_25		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:85DC, 861C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_26		proc	near
		cmp	al,4
		jae	short loc_ret_183	; Jump if above or =
		jcxz	short loc_ret_183	; Jump if cx=0
		cbw				; Convrt byte to word
		mov	di,ax
		mov	si,bx
		xor	bl,bl			; Zero register
		xchg	bl,bh
		xchg	bx,si
		shl	si,1			; Shift w/zeros fill
		push	word ptr [si+50h]
		mov	ah,2
		int	10h			; Video display   ah=functn 02h
						;  set cursor location in dx

locloop_178:					;  xref F000:8D3B
		mov	al,es:[bp]
		inc	bp
		cmp	al,8
		je	short loc_179		; Jump if equal
		cmp	al,0Dh
		je	short loc_179		; Jump if equal
		cmp	al,7
		je	short loc_179		; Jump if equal
		cmp	al,0Ah
		jne	short loc_180		; Jump if not equal
loc_179:					;  xref F000:8D0E, 8D12, 8D16
		mov	ah,0Eh
		int	10h			; Video display   ah=functn 0Eh
						;  write char al, teletype mode
		mov	dx,[si+50h]
		jmp	short loc_182		; (8D37)
loc_180:					;  xref F000:8D1A
		cmp	di,1
		jbe	short loc_181		; Jump if below or =
		mov	bl,es:[bp]
		inc	bp
loc_181:					;  xref F000:8D29
		mov	ah,9
		push	cx
		call	sub_27			; (8D47)
		pop	cx
loc_182:					;  xref F000:8D24
		mov	ah,2

		int	10h			; Video display   ah=functn 02h
						;  set cursor location in dx
		loop	locloop_178		; Loop if cx > 0

		pop	dx
		shr	di,1			; Shift w/zeros fill
		jc	short loc_ret_183	; Jump if carry Set
		mov	ah,2
		int	10h			; Video display   ah=functn 02h
						;  set cursor location in dx

loc_ret_183:					;  xref F000:8CEE, 8CF0, 8D40
		retn
sub_26		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8CA9, 8D33
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_27		proc	near
		mov	cx,1
		int	10h			; Video display   ah=functn 0Ah
						;  set char al at present curs
		inc	dl
		cmp	dl,byte ptr video_columns	; (0040:004A=50h)
		jne	short loc_ret_186	; Jump if not equal
		xor	dl,dl			; Zero register

;ﬂﬂﬂﬂ External Entry into Subroutine ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;
;         Called from:	 F000:8CC4

sub_28:
		inc	dh
		cmp	dh,19h
		jne	short loc_ret_186	; Jump if not equal
		dec	dh
		cmp	video_mode,7		; (0040:0049=3)
		je	short loc_184		; Jump if equal
		cmp	video_mode,4		; (0040:0049=3)
		mov	ah,0
		jnc	short loc_185		; Jump if carry=0
loc_184:					;  xref F000:8D64
		mov	ah,8
		int	10h			; Video display   ah=functn 08h
						;  get char al & attrib ah @curs
loc_185:					;  xref F000:8D6D
		push	bx
		push	dx
		xor	cx,cx			; Zero register
		mov	dl,byte ptr video_columns	; (0040:004A=50h)
		dec	dl
		mov	bx,601h
		xchg	ax,bx

		int	10h			; Video display   ah=functn 06h
						;  scroll up, al=lines
		pop	dx
		pop	bx

loc_ret_186:					;  xref F000:8D52, 8D5B
		retn
sub_27		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8C69, 8C84
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_29		proc	near
		ror	dx,1			; Rotate
		mov	al,50h			; 'P'
		mul	dl			; ax = reg * al
		shl	dh,1			; Shift w/zeros fill
		jnc	short loc_187		; Jump if carry=0
		add	ax,2000h
loc_187:					;  xref F000:8D8E
		mov	si,ax
		mov	ax,cx
		mov	cx,103h
		mov	dl,7
		and	dl,al
		cmp	video_mode,6		; (0040:0049=3)
		jae	short loc_188		; Jump if above or =
		mov	cx,302h
		mov	dl,3
		and	dl,al
		shl	dl,1			; Shift w/zeros fill
		inc	dl
loc_188:					;  xref F000:8DA3
		inc	dl
		shr	ax,cl			; Shift w/zeros fill
		add	si,ax
		mov	cl,dl
		mov	al,es:[si]
		rol	al,cl			; Rotate
		retn
sub_29		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8A4B, 8A53
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_30		proc	near
		mov	dx,ax
		shl	ax,1			; Shift w/zeros fill
		or	ax,dx

		xchg	al,ah
		mov	cx,8

locloop_189:					;  xref F000:8DCF
		shl	ax,1			; Shift w/zeros fill
		rcl	dl,1			; Rotate thru carry
		shl	ax,1			; Shift w/zeros fill
		loop	locloop_189		; Loop if cx > 0

		mov	[bp+di],dl
		inc	di
		retn
sub_30		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8BE1, 8BEF
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_31		proc	near
		mov	ah,8
loc_190:					;  xref F000:8DDF
		shl	al,1			; Shift w/zeros fill
		rcl	bx,1			; Rotate thru carry
		shl	bx,1			; Shift w/zeros fill
		dec	ah
		jnz	loc_190			; Jump if not zero
		mov	ax,bx
		shr	ax,1			; Shift w/zeros fill
		or	ax,bx
		and	al,dh
		and	ah,dh
		xchg	al,ah
		and	dl,dl
		retn
sub_31		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:E8D4
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_32		proc	near
		push	ax
		assume	ds:seg_a
		mov	al,byte ptr vector_4h_off	; (0000:0010=0F4h)
		and	al,30h			; '0'
		cmp	al,30h			; '0'
		pop	ax
		retn
sub_32		endp

loc_191:					;  xref F000:8165, 81CD, 8273, 84CE

						;            85B0, 8E12, 903D, 914D
		mov	dx,bp
loc_192:					;  xref F000:8E08
		mov	sp,offset locloop_193
		jmp	short loc_197		; (8E14)

locloop_193:					;  xref F000:8DFC, 8E01
		loop	locloop_193		; Loop if cx > 0


locloop_194:					;  xref F000:8E03
		loop	locloop_194		; Loop if cx > 0


locloop_195:					;  xref F000:8E05
		loop	locloop_195		; Loop if cx > 0

		dec	dx
		jnz	loc_192			; Jump if not zero
		mov	dx,6

locloop_196:					;  xref F000:8E0D, 8E10
		loop	locloop_196		; Loop if cx > 0

		dec	dx
		jnz	locloop_196		; Jump if not zero
		jmp	short loc_191		; (8DFA)
loc_197:					;  xref F000:8DFF, 8E55
		mov	bx,80h
		in	al,61h			; port 61h, 8255 port B, read
		and	al,0FEh
		jmp	short $+2		; delay for I/O
		jmp	short loc_198		; (8E1F)
loc_198:					;  xref F000:8E1D, 8E32
		or	al,2
		out	61h,al			; port 61h, 8255 B - spkr, etc
		mov	cx,0E0h

locloop_199:					;  xref F000:8E26
		loop	locloop_199		; Loop if cx > 0

		and	al,0FDh
		out	61h,al			; port 61h, 8255 B - spkr, etc
						;  al = 0, disable parity
		mov	cx,0D0h

locloop_200:					;  xref F000:8E2F
		loop	locloop_200		; Loop if cx > 0

		dec	bx
		jnz	loc_198			; Jump if not zero
		jmp	sp			;*Register jump
loc_201:					;  xref F000:9075, 93E7, 93ED, AB19
						;            AB46, CE4B, CE51, CE57
		xor	ax,ax			; Zero register
		int	10h			; Video display   ah=functn 00h
						;  set display mode in al

loc_202:					;  xref F000:E9A2, E9E0, EA0D
		call	sub_33			; (8E5B)
		mov	si,ds:[0D64Eh]		; (F000:D64E=0Dh)
		call	sub_33			; (8E5B)
		call	sub_42			; (8F15)
		test	al,20h			; ' '
		jnz	short loc_205		; Jump if not zero
loc_203:					;  xref F000:8E50
		cli				; Disable interrupts
		call	sub_37			; (8EA9)

locloop_204:					;  xref F000:8E4E
		loop	locloop_204		; Loop if cx > 0

		jmp	short loc_203		; (8E4A)
loc_205:					;  xref F000:8E48
		mov	sp,8E57h
		jmp	short loc_197		; (8E14)
loc_206:					;  xref F000:8E59
		sti				; Enable interrupts
		hlt				; Halt processor
		jmp	short loc_206		; (8E57)

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8E3A, 8E40, 90C2, 90CB, 94F9, 98E0, AE3B
;			      AE50, E9ED, E9F3, F30B, F390
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_33		proc	near
loc_207:					;  xref F000:8E66
		cli				; Disable interrupts
		cld				; Clear direction
		lods byte ptr cs:[si]		; String [si] to al
		and	al,al
		jz	short loc_ret_208	; Jump if zero
		call	sub_35			; (8E74)
		jmp	short loc_207		; (8E5B)

loc_ret_208:					;  xref F000:8E61
		retn
sub_33		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:90BF, 90C5, 90D2, 97ED, 98DD
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_34		proc	near
		mov	al,0Dh
		call	sub_35			; (8E74)
		mov	al,0Ah
		call	sub_35			; (8E74)
		retn

sub_34		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8E63, 8E6B, 8E70, ACD0, AE0E, AE2E, E9FD
;			      EA07, EA31, F2F7, F2FC, F3CC
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_35		proc	near
		mov	ah,0Eh
		int	10h			; Video display   ah=functn 0Eh
						;  write char al, teletype mode
		cli				; Disable interrupts
		cld				; Clear direction
		mov	al,8Dh
		out	70h,al			; port 70h, RTC addr/enabl NMI
		call	sub_39			; (8EE5)
		retn
sub_35		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8CC9, 9401, 9404
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_36		proc	near
		mov	al,0B6h
		out	43h,al			; port 43h, 8253 wrt timr mode
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		mov	al,4
		out	42h,al			; port 42h, 8253 timer 2 spkr
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	42h,al			; port 42h, 8253 timer 2 spkr
		in	al,61h			; port 61h, 8255 port B, read
		push	ax
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		or	al,3
		out	61h,al			; port 61h, 8255 B - spkr, etc
		mov	cx,8000h
		call	sub_279			; (F068)
		pop	ax
		out	61h,al			; port 61h, 8255 B - spkr, etc
		retn
sub_36		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8E4B, 940D, 97C7, 97D0, 987C, 988C, BDE2

;			      EC7A, ECC1
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_37		proc	near
		mov	al,0B6h
		out	43h,al			; port 43h, 8253 wrt timr mode
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		mov	al,5
		out	42h,al			; port 42h, 8253 timer 2 spkr
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	42h,al			; port 42h, 8253 timer 2 spkr
		in	al,61h			; port 61h, 8255 port B, read
		push	ax
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		or	al,3
		out	61h,al			; port 61h, 8255 B - spkr, etc
		mov	cx,3000h
		call	sub_279			; (F068)
		pop	ax
		out	61h,al			; port 61h, 8255 B - spkr, etc
		retn
sub_37		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:92B4, 92BB, 92E0, 92E7
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_38		proc	near
loc_209:					;  xref F000:8577
		xor	cx,cx			; Zero register

locloop_210:					;  xref F000:8ED7
		jmp	short $+2		; delay for I/O
		in	al,dx			; port 2, DMA-1 bas&add ch 1
		test	al,ah
		loopz	locloop_210		; Loop if zf=1, cx>0

		jz	short loc_ret_212	; Jump if zero
		xor	cx,cx			; Zero register

locloop_211:					;  xref F000:8EE2
		jmp	short $+2		; delay for I/O
		in	al,dx			; port 2, DMA-1 bas&add ch 1
		test	al,ah
		loopnz	locloop_211		; Loop if zf=0, cx>0


loc_ret_212:					;  xref F000:8ED9
		retn
sub_38		endp



;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8E7E, 9040, 90E6, 9240, 926A, 957A, 9647
;			      9685, 989B, AB30, AC3F, AD3C, AD80, ADC0
;			      CC88, E9BB
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_39		proc	near
loc_213:					;  xref F000:9121, 9165
		in	al,61h			; port 61h, 8255 port B, read
		or	al,0Ch
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	61h,al			; port 61h, 8255 B - spkr, etc
		and	al,0F3h
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	61h,al			; port 61h, 8255 B - spkr, etc
		retn
sub_39		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8F21, 8F31, 94AB, E8FC, F319, F34B
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_40		proc	near
		call	sub_46			; (8F60)
		jnz	short loc_ret_214	; Jump if not zero
		call	sub_43			; (8F35)
		jz	short loc_216		; Jump if zero
		cmp	al,ah

loc_ret_214:					;  xref F000:8EFB
		retn

;ﬂﬂﬂﬂ External Entry into Subroutine ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;
;         Called from:	 F000:9466

sub_41:
		call	sub_47			; (8F6F)
		jnz	short loc_ret_215	; Jump if not zero
		call	sub_43			; (8F35)
		jz	short loc_216		; Jump if zero
		cmp	al,ah

loc_ret_215:					;  xref F000:8F08
		retn
loc_216:					;  xref F000:8F00, 8F0D
		or	sp,sp			; Zero ?
		retn
sub_40		endp



;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8E43, 9200, F378
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_42		proc	near
		in	al,64h			; port 64h, keyboard status
		test	al,1
		jz	short loc_217		; Jump if zero
		jmp	short $+2		; delay for I/O
		in	al,60h			; port 60h, keybd scan or sw1
loc_217:					;  xref F000:8F19
		mov	al,0C0h
		call	sub_40			; (8EF8)
		retn
sub_42		endp

		in	al,64h			; port 64h, keyboard status
		test	al,1
		jz	short loc_218		; Jump if zero
		jmp	short $+2		; delay for I/O
		in	al,60h			; port 60h, keybd scan or sw1
loc_218:					;  xref F000:8F29
		mov	al,0D0h
		call	sub_40			; (8EF8)
		retn

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8EFD, 8F0A, 946E
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_43		proc	near
		call	sub_44			; (8F3B)
		in	al,60h			; port 60h, keybd scan or sw1
		retn
sub_43		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8F35, 99CE, F6DA
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_44		proc	near
		mov	cx,0Ch

locloop_219:					;  xref F000:8F4A
		push	cx
		xor	cx,cx			; Zero register

locloop_220:					;  xref F000:8F47

		jmp	short $+2		; delay for I/O
		in	al,64h			; port 64h, keyboard status
		test	al,1
		loopz	locloop_220		; Loop if zf=1, cx>0

		pop	cx
		loopz	locloop_219		; Loop if zf=1, cx>0

		retn
sub_44		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8F5C, 8F80
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_45		proc	near
		call	sub_46			; (8F60)
		jnz	short loc_ret_221	; Jump if not zero
		mov	al,ah
		call	sub_47			; (8F6F)

loc_ret_221:					;  xref F000:8F50
		retn
sub_45		endp

		mov	ah,al
		mov	al,0D1h
		call	sub_45			; (8F4D)
		retn

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8EF8, 8F4D, 99CB, AD61, ADC5, F314, F32D
;			      F6D7
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_46		proc	near
		push	ax
		call	sub_49			; (8F84)
		pop	ax
		jnz	short loc_ret_222	; Jump if not zero
		out	64h,al			; port 64h, kybd cntrlr functn
						;  al = 0C0h, read 8042 in port
		push	ax
		call	sub_49			; (8F84)
		pop	ax

loc_ret_222:					;  xref F000:8F65
		retn
sub_46		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ

;			       SUBROUTINE
;
;         Called from:	 F000:8F05, 8F54
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_47		proc	near
		push	ax
		call	sub_49			; (8F84)
		pop	ax
		jnz	short loc_ret_223	; Jump if not zero
		out	60h,al			; port 60h, keybd data write
		call	sub_49			; (8F84)

loc_ret_223:					;  xref F000:8F74
		retn
sub_47		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9485, 94CA, 94D2
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_48		proc	near
		mov	ah,al
		mov	al,60h			; '`'
		call	sub_45			; (8F4D)
		retn
sub_48		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:8F61, 8F6A, 8F70, 8F78, 8F99, 8FA2, 8FAB
;			      8FAF, 8FB8, 8FC1, 8FC6, 8FCF, 8FD8, 8FDE
;			      8FE7, 8FF0, AD64, ADC8, E151
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_49		proc	near
loc_224:					;  xref F000:8201, 820D, 825F, 827D
						;            8293, 829F, 82CB
		xor	cx,cx			; Zero register

locloop_225:					;  xref F000:8F8C
		jmp	short $+2		; delay for I/O
		in	al,64h			; port 64h, keyboard status
		test	al,2
		loopnz	locloop_225		; Loop if zf=0, cx>0

		jz	short loc_ret_227	; Jump if zero

locloop_226:					;  xref F000:8F96
		jmp	short $+2		; delay for I/O
		in	al,64h			; port 64h, keyboard status
		test	al,2

		loopnz	locloop_226		; Loop if zf=0, cx>0


loc_ret_227:					;  xref F000:8F8E
		retn
sub_49		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:AC5D, CCDF
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_50		proc	near
		call	sub_49			; (8F84)
		jnz	short loc_ret_228	; Jump if not zero
		mov	al,0D1h
		out	64h,al			; port 64h, kybd cntrlr functn
						;  al = 0D1h, wrt 8042 out port
		call	sub_49			; (8F84)
		jnz	short loc_ret_228	; Jump if not zero
		mov	al,0DDh
		out	60h,al			; port 60h, keybd data write
		call	sub_49			; (8F84)

loc_ret_228:					;  xref F000:8F9C, 8FA5
		retn
sub_50		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:AC5A, F5D5
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_51		proc	near
		call	sub_49			; (8F84)
		jnz	short loc_ret_229	; Jump if not zero
		mov	al,0D1h
		out	64h,al			; port 64h, kybd cntrlr functn
						;  al = 0D1h, wrt 8042 out port
		call	sub_49			; (8F84)
		jnz	short loc_ret_229	; Jump if not zero
		mov	al,0DDh
		out	60h,al			; port 60h, keybd data write
		call	sub_49			; (8F84)

loc_ret_229:					;  xref F000:8FB2, 8FBB
		retn
sub_51		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;

;         Called from:	 F000:CBA4
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_52		proc	near
		push	cx
		call	sub_49			; (8F84)
		jnz	short loc_230		; Jump if not zero
		mov	al,0D1h
		out	64h,al			; port 64h, kybd cntrlr functn
						;  al = 0D1h, wrt 8042 out port
		call	sub_49			; (8F84)
		jnz	short loc_230		; Jump if not zero
		mov	al,0DFh
		out	60h,al			; port 60h, keybd data write
		call	sub_49			; (8F84)
loc_230:					;  xref F000:8FC9, 8FD2
		pop	cx
		retn
sub_52		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:CBF4
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_53		proc	near
		push	cx
		call	sub_49			; (8F84)
		jnz	short loc_231		; Jump if not zero
		mov	al,0D1h
		out	64h,al			; port 64h, kybd cntrlr functn
						;  al = 0D1h, wrt 8042 out port
		call	sub_49			; (8F84)
		jnz	short loc_231		; Jump if not zero
		mov	al,0DFh
		out	60h,al			; port 60h, keybd data write
		call	sub_49			; (8F84)
loc_231:					;  xref F000:8FE1, 8FEA
		pop	cx
		retn
sub_53		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9254, 9678, 98AF
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_54		proc	near
		cli				; Disable interrupts
		cld				; Clear direction
		push	ds
		mov	ds,bx
		xor	si,si			; Zero register

		lodsw				; String [si] to ax
		xor	ax,0AA55h
		jnz	short loc_234		; Jump if not zero
		mov	cx,80h
		cmp	bx,0E000h
		je	short loc_232		; Jump if equal
		lodsb				; String [si] to al
		mov	cx,ax
loc_232:					;  xref F000:9009
		shl	cx,5			; Shift w/zeros fill
		add	bx,cx
		shl	cx,4			; Shift w/zeros fill
		xor	si,si			; Zero register

locloop_233:					;  xref F000:901B
		lodsb				; String [si] to al
		add	ah,al
		loop	locloop_233		; Loop if cx > 0

		jnz	short loc_235		; Jump if not zero
		sti				; Enable interrupts
		push	es
		push	bx
		push	bp
		push	cs
		push	902Bh
		push	ds
		push	3
		retf
		cli				; Disable interrupts
		cld				; Clear direction
		pop	bp
		pop	bx
		pop	es
		pop	ds
		cmp	sp,sp
		retn
loc_234:					;  xref F000:9000
		add	bx,80h
loc_235:					;  xref F000:901D
		pop	ds
		retn
sub_54		endp


;ƒƒƒƒƒ Indexed Entry Point ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ

loc_236:					;  xref F000:8146, 8150
		mov	bp,7
		jmp	loc_191			; (8DFA)

;ƒƒƒƒƒ Indexed Entry Point ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ

loc_237:					;  xref F000:8146, 8154, 98C4
		call	sub_39			; (8EE5)
		mov	al,0Dh
		out	70h,al			; port 70h, RTC addr/enabl NMI

						;  al = 0Dh, status register D
		int	19h			; Bootstrap loader
loc_238:					;  xref F000:90BD
		mov	al,0AAh
		out	80h,al			; port 80h, diagnostc chkpoint
loc_239:					;  xref F000:904F
		sti				; Enable interrupts
		hlt				; Halt processor
		jmp	short loc_239		; (904D)

;ƒƒƒƒƒ Indexed Entry Point ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ

loc_240:					;  xref F000:8146, 8156
		in	al,60h			; port 60h, keybd scan or sw1
		mov	al,20h			; ' '
		out	20h,al			; port 20h, 8259-1 int command
						;  al = 20h, end of interrupt
		assume	ds:seg_b
		jmp	dword ptr @gen_io_ptr	; (0040:0067=588h)
loc_241:					;  xref F000:E005
		cli				; Disable interrupts
		mov	bp,sp
		mov	ax,cs
		cmp	ax,[bp+2]
		jne	short loc_242		; Jump if not equal
		mov	ax,90BDh
		cmp	ax,[bp]
		jne	short loc_242		; Jump if not equal
		add	sp,6
		jmp	short loc_245		; (90BF)
loc_242:					;  xref F000:9063, 906B
		mov	si,7D8Eh
		jmp	loc_201			; (8E36)


; ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± int 19h ±±±±±
;
;   BOOTSTRAP LOADER
;
;      Floppy drive a: attempts a read from the first sector of	the disk.
;      If read properly	(i.e a boot disk is in drive a:), control is
;      transferred to the loaded program.  The boot sector at track 0,
;      sector 1	is transfered to memory at 0:7C00h.  dh = drive	which
;      was used	(0=A:).	 Control is passed to 0:7C00h.

int_19h_bootup	proc	near			;  xref F000:90D5, E6F2
		xor	ax,ax			; Zero register
		mov	es,ax
		mov	ax,0EFC7h
		mov	di,disk_parm_off	; (0000:0078=22h)
		cli				; Disable interrupts
		cld				; Clear direction
		stosw				; Store ax to es:[di]
		mov	ax,cs
		stosw				; Store ax to es:[di]
		mov	bx,7C00h
		mov	di,bx

		mov	cx,100h
		rep	stosw			; Rep when cx >0 Store ax to es:[di]
		sti				; Enable interrupts
		xor	dx,dx			; Zero register
		xor	ax,ax			; Zero register
		int	13h			; Disk  dl=drive a  ah=func 00h
						;  reset disk, al=return status
		call	sub_55			; (90FD)
		mov	si,7D9Bh
		jcxz	short loc_243		; Jump if cx=0
		mov	si,7DB3h
		jnc	short loc_246		; Jump if carry=0
		mov	si,7DCBh
loc_243:					;  xref F000:909F
		mov	al,0Eh
		call	sub_270			; (EE9F)
		test	al,8
		jnz	short loc_244		; Jump if not zero
		mov	dl,80h
		call	sub_55			; (90FD)
		jcxz	short loc_244		; Jump if cx=0
		jnc	short loc_248		; Jump if carry=0
loc_244:					;  xref F000:90B0, 90B7, 90E4, 90FB
		int	18h			; ROM basic
		jmp	short loc_238		; (9049)
loc_245:					;  xref F000:9070
		call	sub_34			; (8E69)
		call	sub_33			; (8E5B)
		call	sub_34			; (8E69)
		mov	si,data_185e		; (F000:7DE3=49h)
		call	sub_33			; (8E5B)
		mov	ah,0
		int	16h			; Keyboard i/o  ah=function 00h
						;  get keybd char in al, ah=scan
		call	sub_34			; (8E69)
		jmp	short int_19h_bootup	; (9078)
loc_246:					;  xref F000:90A4
		mov	di,bx
		mov	ax,es:[di]
		mov	cx,80h
		cli				; Disable interrupts
		cld				; Clear direction
		repe	scasb			; Rep zf=1+cx >0 Scan es:[di] for al
		sti				; Enable interrupts
		jcxz	loc_244			; Jump if cx=0
loc_247:					;  xref F000:90F9
		call	sub_39			; (8EE5)
		mov	al,0Dh
		out	70h,al			; port 70h, RTC addr/enabl NMI
						;  al = 0Dh, status register D
;*		jmp	far ptr loc_2		;*(0000:7C00)
		db	0EAh, 00h, 7Ch, 00h, 00h
loc_248:					;  xref F000:90B9
		cmp	word ptr es:data_44e[bx],0AA55h	; (0000:01FE=0)
		je	loc_247			; Jump if equal
		jmp	short loc_244		; (90BB)
int_19h_bootup	endp



;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9099, 90B4
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_55		proc	near
		mov	cx,4

locloop_249:					;  xref F000:9116
		push	cx
		mov	cx,1
		mov	ax,201h
loc_250:					;  xref F000:9174
		int	13h			; Disk  dl=drive a  ah=func 02h
						;  read sectors to memory es:bx
		pop	cx
		jnc	short loc_ret_251	; Jump if carry=0
		push	ax
		xor	ax,ax			; Zero register
		int	13h			; Disk  dl=drive a  ah=func 00h
						;  reset disk, al=return status
		pop	ax
		shl	ah,1			; Shift w/zeros fill
		jc	short loc_ret_251	; Jump if carry Set
		loop	locloop_249		; Loop if cx > 0


loc_ret_251:					;  xref F000:910A, 9114
		retn
sub_55		endp

		db	0
loc_252:					;  xref F000:85B3
		mov	al,10h
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	sp,9124h
		jmp	loc_213			; (8EE5)
		db	 26h, 91h, 33h,0FFh,0BEh, 01h
		db	 00h
loc_253:					;  xref F000:915C
		mov	al,0FFh
		mov	bx,di
		mov	[di],ax
		mov	[di+2],ax
loc_254:					;  xref F000:913E
		xor	al,[di]
		jnz	short loc_256		; Jump if not zero
		or	di,di			; Zero ?
		jz	short loc_257		; Jump if zero
		shr	di,1			; Shift w/zeros fill
		jmp	short loc_254		; (9134)
loc_255:					;  xref F000:916C
		mov	sp,9146h
		jmp	loc_622			; (AE94)

		db	 48h, 91h, 74h, 50h
loc_256:					;  xref F000:9136, 9154, 9176, 9194
						;            9198, 919E
		mov	bp,3
		jmp	loc_191			; (8DFA)
loc_257:					;  xref F000:913A
		mov	[bx],al
		xor	al,[bx]
		jnz	loc_256			; Jump if not zero
		mov	di,si
		shl	si,1			; Shift w/zeros fill
		or	di,di			; Zero ?
		jnz	loc_253			; Jump if not zero
		mov	al,11h
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	sp,9168h
		jmp	loc_213			; (8EE5)
		push	0FF91h
		or	bp,bp			; Zero ?
		js	loc_255			; Jump if sign=1
		mov	sp,9174h
		jmp	loc_623			; (AE9E)
		jbe	loc_250			; Jump if below or =
		jnz	loc_256			; Jump if not zero
		dec	cx
		dec	di
		mov	sp,9180h
		jmp	loc_603			; (AD40)
		adc	byte ptr ds:data_59e[bx+di],0E2h	; (0000:0588=43h)
		hlt				; Halt processor
		dec	cx

locloop_258:					;  xref F000:9192
		nop
		mov	sp,918Eh
		jmp	loc_603			; (AD40)
		nop
		xchg	ax,cx
		xor	[di],al
		loopz	locloop_258		; Loop if zf=1, cx>0

		jnz	loc_256			; Jump if not zero
		xor	[si],ah
		jnz	loc_256			; Jump if not zero
loc_259:					;  xref F000:F3B5
		in	al,61h			; port 61h, 8255 port B, read
		test	al,80h
		jnz	loc_256			; Jump if not zero
		mov	al,12h
		out	80h,al			; port 80h, diagnostc chkpoint
		jmp	loc_1182		; (F104)
loc_260:					;  xref F000:F1F6
		xor	ax,ax			; Zero register
		mov	es,ax
		mov	al,40h			; '@'
		mov	ds,ax
		mov	al,30h			; '0'

		mov	ss,ax
		mov	sp,100h
		mov	cx,78h
		mov	ax,0EAA6h
		mov	bx,cs
		xor	di,di			; Zero register

locloop_261:					;  xref F000:91C4
		stosw				; Store ax to es:[di]
		xchg	ax,bx
		stosw				; Store ax to es:[di]
		xchg	ax,bx
		loop	locloop_261		; Loop if cx > 0

		mov	word ptr es:graph_tbl_seg,0	; (0000:007E=0C000h)
		mov	di,data_41e		; (0000:0180=0)
		mov	cx,0Eh
		xor	ax,ax			; Zero register
		rep	stosw			; Rep when cx >0 Store ax to es:[di]
		xor	di,di			; Zero register
		mov	si,offset int_vec_table_0	; (F000:FEE3=0A6h)
		mov	cx,20h

locloop_262:					;  xref F000:91E3
		movs word ptr es:[di],cs:[si]	; Mov [si] to es:[di]
		inc	di
		inc	di
		loop	locloop_262		; Loop if cx > 0

		mov	di,data_42e		; (0000:01C0=52h)
		mov	cx,8

locloop_263:					;  xref F000:91EF
		movs word ptr es:[di],cs:[si]	; Mov [si] to es:[di]
		inc	di
		inc	di
		loop	locloop_263		; Loop if cx > 0

		test	byte ptr cs:data_275,40h	; (F000:E2C0=0BFh) '@'
		jz	short loc_264		; Jump if zero
		mov	di,data_43e		; (0000:01D0=0FFh)
		mov	ax,7976h
		stosw				; Store ax to es:[di]
loc_264:					;  xref F000:91F7
		call	sub_42			; (8F15)
		mov	init_test_flag,al	; (0040:0012=0FFh)
		test	al,20h			; ' '
		jnz	short loc_265		; Jump if not zero
		mov	di,offset vector_8h_off	; (0000:0020=1Bh)
		mov	ax,0FEB4h
		stosw				; Store ax to es:[di]
		mov	ax,cs
		stosw				; Store ax to es:[di]
		mov	al,0FEh
		out	21h,al			; port 21h, 8259-1 int comands
						;  al = 0FEh, IRQ0 (timer) only
loc_265:					;  xref F000:9208

		mov	al,15h
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	video_rows,18h		; (0040:0084=18h)
		or	byte ptr equip_bits,31h	; (0040:0010=61h) '1'
		call	sub_283			; (F4DE)
		mov	ax,7
		int	10h			; Video display   ah=functn 00h
						;  set display mode in al
		mov	al,17h
		out	80h,al			; port 80h, diagnostc chkpoint
		and	byte ptr equip_bits,0CFh	; (0040:0010=61h)
		mov	ax,1
		int	10h			; Video display   ah=functn 00h
						;  set display mode in al
		mov	al,18h
		out	80h,al			; port 80h, diagnostc chkpoint
		call	sub_39			; (8EE5)
		mov	al,19h
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	bx,0C000h
		or	bp,bp			; Zero ?
		jns	short loc_266		; Jump if not sign
		mov	warm_boot_flag,1234h	; (0040:0072=0)
loc_266:					;  xref F000:924C, 925B
		call	sub_54			; (8FF5)
		cmp	bx,0C800h
		jb	loc_266			; Jump if below
		cli				; Disable interrupts
		cld				; Clear direction
		mov	al,1Ah
		out	80h,al			; port 80h, diagnostc chkpoint
		call	sub_287			; (F64B)
		mov	al,8Dh
		out	70h,al			; port 70h, RTC addr/enabl NMI
		call	sub_39			; (8EE5)
		mov	bx,offset vectr_10h_seg	; (0000:0042=0ADh)
		mov	cx,cs
		cmp	es:[bx],cx
		je	short loc_268		; Jump if equal
		mov	al,94h
		call	sub_270			; (EE9F)
		test	al,30h			; '0'
		jz	short loc_267		; Jump if zero
		or	bp,400h
		mov	ax,8E8Eh
		call	sub_270			; (EE9F)
		or	al,20h			; ' '
		xchg	al,ah
		call	sub_271			; (EEAE)
loc_267:					;  xref F000:927E
		jmp	loc_280			; (9397)
loc_268:					;  xref F000:9275
		mov	al,ds:data_170e		; (C000:0012=30h)
		and	al,40h			; '@'
		mov	bx,0B800h
		jz	short loc_269		; Jump if zero
		mov	al,30h			; '0'

		mov	bh,0B0h
loc_269:					;  xref F000:929C
		or	ds:data_168e,al		; (C000:0010=30h)
		call	sub_58			; (941A)
		jnz	short loc_270		; Jump if not zero
		mov	al,1Bh
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	ah,8
		add	dl,2
		call	sub_38			; (8ED0)
		jcxz	short loc_270		; Jump if cx=0
		mov	ah,1
		call	sub_38			; (8ED0)
		jcxz	short loc_270		; Jump if cx=0
		jmp	short loc_273		; (9310)
loc_270:					;  xref F000:92A9, 92B7, 92BE
		xor	byte ptr ds:data_168e,30h	; (C000:0010=30h) '0'
		mov	al,ds:data_168e		; (C000:0010=30h)
		and	al,30h			; '0'
		mov	bh,0B8h
		jz	short loc_271		; Jump if zero
		mov	bh,0B0h
loc_271:					;  xref F000:92CE
		call	sub_58			; (941A)
		jnz	short loc_272		; Jump if not zero
		mov	al,1Ch
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	ah,8
		add	dl,2
		call	sub_38			; (8ED0)
		jcxz	short loc_272		; Jump if cx=0
		mov	ah,1
		call	sub_38			; (8ED0)
		jcxz	short loc_272		; Jump if cx=0
		jmp	short loc_273		; (9310)
loc_272:					;  xref F000:92D5, 92E3, 92EA
		or	byte ptr ds:data_168e,30h	; (C000:0010=30h) '0'
		mov	al,ds:data_170e		; (C000:0012=30h)
		test	al,20h			; ' '
		jz	short loc_273		; Jump if zero
		mov	bx,8
		mov	ax,2B7h
		call	sub_56			; (93F0)
		jz	short loc_273		; Jump if zero
		test	byte ptr cs:data_275,8	; (F000:E2C0=0BFh)
		jz	short loc_273		; Jump if zero
		call	sub_57			; (9401)
loc_273:					;  xref F000:92C0, 92EC, 92F8, 9303
						;            930B
		mov	al,1Dh
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	ax,8E8Eh
		call	sub_270			; (EE9F)
		push	ax
		mov	ah,ds:data_170e		; (C000:0012=30h)
		mov	al,ds:data_168e		; (C000:0010=30h)
		and	al,30h			; '0'

		cmp	al,30h			; '0'
		mov	cl,al
		rol	ah,2			; Rotate
		jz	short loc_274		; Jump if zero
		cmc				; Complement carry
loc_274:					;  xref F000:932B
		jc	short loc_275		; Jump if carry Set
		or	bp,800h
loc_275:					;  xref F000:932E
		mov	al,94h
		call	sub_270			; (EE9F)
		and	al,30h			; '0'
		jz	short loc_277		; Jump if zero
		cmp	al,30h			; '0'
		je	short loc_276		; Jump if equal
		cmp	cl,30h			; '0'
		jne	short loc_278		; Jump if not equal
		jmp	short loc_277		; (934D)
loc_276:					;  xref F000:933F
		cmp	cl,30h			; '0'
		je	short loc_278		; Jump if equal
loc_277:					;  xref F000:933B, 9346
		or	bp,400h
		pop	ax
		or	al,20h			; ' '
		push	ax
loc_278:					;  xref F000:9344, 934B
		pop	ax
		xchg	al,ah
		call	sub_271			; (EEAE)
		mov	al,1Eh
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	al,ds:data_168e		; (C000:0010=30h)
		and	al,30h			; '0'
		cmp	al,30h			; '0'
		mov	ah,7
		jz	short loc_279		; Jump if zero
		mov	al,8Eh
		call	sub_270			; (EE9F)
		test	al,0E0h
		mov	ax,320h
		jnz	short loc_279		; Jump if not zero
		mov	al,94h
		call	sub_270			; (EE9F)
		and	al,30h			; '0'
		cmp	al,20h			; ' '
		je	short loc_279		; Jump if equal
		mov	ax,110h
loc_279:					;  xref F000:9368, 9374, 937F
		and	byte ptr ds:data_168e,0CFh	; (C000:0010=30h)
		or	ds:data_168e,al		; (C000:0010=30h)
		xor	al,al			; Zero register
		xchg	al,ah
		int	10h			; Video display   ah=functn 00h
						;  set display mode in al
		mov	al,1Fh
		out	80h,al			; port 80h, diagnostc chkpoint

loc_280:					;  xref F000:9291
		mov	al,20h			; ' '
		out	80h,al			; port 80h, diagnostc chkpoint
		call	sub_210			; (C8E0)
		jnz	short loc_282		; Jump if not zero
		call	$-1CE5h
		test	bp,4000h
		jnz	short loc_281		; Jump if not zero
		mov	ah,3
		xor	bh,bh			; Zero register
		call	$-1DB8h
		mov	al,21h			; '!'
		out	80h,al			; port 80h, diagnostc chkpoint
		inc	dh
		mov	dl,0
		mov	ah,2
		call	$-1DC5h
		mov	al,22h			; '"'
		out	80h,al			; port 80h, diagnostc chkpoint
;*		call	sub_278			;*(F042)
		db	0E8h, 7Eh, 5Ch
		mov	al,23h			; '#'
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	ah,3
		call	$-1DD5h
		mov	al,24h			; '$'
		out	80h,al			; port 80h, diagnostc chkpoint
		add	dh,2
		mov	dl,0
		mov	ds:data_175e,dx		; (C000:0069=412Ch)
		call	$-1D0Ah
		mov	al,25h			; '%'
		out	80h,al			; port 80h, diagnostc chkpoint
		jmp	loc_576			; (AAD6)
loc_281:					;  xref F000:93A7
		mov	si,7D0Fh
		jmp	loc_201			; (8E36)
loc_282:					;  xref F000:939E
		mov	si,0D622h
		jmp	loc_201			; (8E36)

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9300, 949B, 9529, 97B1
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_56		proc	near
		push	ax
		mov	al,8Eh
		call	sub_270			; (EE9F)
		test	al,0C0h
		pop	ax
		jnz	short loc_ret_283	; Jump if not zero
		call	sub_270			; (EE9F)
		test	al,ah


loc_ret_283:					;  xref F000:93F9
		retn
sub_56		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:930D, 986B, ADE7
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_57		proc	near
		call	sub_36			; (8E82)
		call	sub_36			; (8E82)
		mov	cx,0FFF0h
		call	sub_279			; (F068)
loc_284:					;  xref F000:9417
		call	sub_37			; (8EA9)
		mov	cx,8000h
		call	sub_279			; (F068)
		dec	bx
		jnz	loc_284			; Jump if not zero
		retn
sub_57		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:92A6, 92D2
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_58		proc	near
		xor	ax,ax			; Zero register
		int	10h			; Video display   ah=functn 00h
						;  set display mode in al
		mov	dx,ds:data_172e		; (C000:0063=382Ch)
		add	dl,4
		mov	al,ds:data_173e		; (C000:0065=38h)
		and	al,37h			; '7'
		out	dx,al			; ??io  non-standard i/o port.
		push	es
		push	cx
		mov	es,bx
		mov	bh,8
		call	sub_142			; (AEA1)
		lahf				; Load ah from flags
		push	ax
		xor	ax,ax			; Zero register
		int	10h			; Video display   ah=functn 00h
						;  set display mode in al
		xor	di,di			; Zero register
		mov	cx,28h
		mov	ax,7020h
		rep	stosw			; Rep when cx >0 Store ax to es:[di]
		pop	ax
		sahf				; Store ah into flags

		pop	cx
		pop	es
		retn
sub_58		endp

		db	0
loc_285:					;  xref F000:CE72
		mov	al,70h			; 'p'
		out	80h,al			; port 80h, diagnostc chkpoint
		push	bp
		xor	bp,bp			; Zero register
		xor	cx,cx			; Zero register

locloop_286:					;  xref F000:945D
		jmp	short $+2		; delay for I/O
		in	al,64h			; port 64h, keyboard status
		test	al,1
		jz	short loc_287		; Jump if zero
		in	al,60h			; port 60h, keybd scan or sw1
loc_287:					;  xref F000:9459
		loop	locloop_286		; Loop if cx > 0

		mov	cx,3

locloop_288:					;  xref F000:946A
		push	cx
		mov	ax,0FAFFh
		call	sub_41			; (8F05)
		pop	cx
		loopnz	locloop_288		; Loop if zf=0, cx>0

		jnz	short loc_291		; Jump if not zero
		call	sub_43			; (8F35)
		cmp	al,0AAh
		jne	short loc_291		; Jump if not equal
		mov	al,71h			; 'q'
		out	80h,al			; port 80h, diagnostc chkpoint
		test	byte ptr cs:data_275,40h	; (F000:E2C0=0BFh) '@'
		mov	al,4Dh			; 'M'
		jz	short loc_289		; Jump if zero
		mov	al,6Ch			; 'l'
loc_289:					;  xref F000:9481
		call	sub_48			; (8F7C)
		xor	cx,cx			; Zero register

locloop_290:					;  xref F000:9490
		jmp	short $+2		; delay for I/O
		in	al,64h			; port 64h, keyboard status
		test	al,1
		loopz	locloop_290		; Loop if zf=1, cx>0

		jz	short loc_293		; Jump if zero
		jmp	short $+2		; delay for I/O
		in	al,60h			; port 60h, keybd scan or sw1
loc_291:					;  xref F000:946C, 9473
		mov	ax,1B7h
		call	sub_56			; (93F0)

		jz	short loc_293		; Jump if zero
		test	byte ptr cs:data_275,3	; (F000:E2C0=0BFh)
		jz	short loc_293		; Jump if zero
		mov	ax,0ABh
		call	sub_40			; (8EF8)
		jnz	short loc_292		; Jump if not zero
		or	bp,200h
		jmp	short loc_293		; (94BA)
loc_292:					;  xref F000:94AE
		or	bp,400h
loc_293:					;  xref F000:9492, 949E, 94A6, 94B4
		mov	al,72h			; 'r'
		out	80h,al			; port 80h, diagnostc chkpoint
		test	byte ptr cs:data_275,40h	; (F000:E2C0=0BFh) '@'
		mov	al,45h			; 'E'
		jz	short loc_294		; Jump if zero
		mov	al,64h			; 'd'
		call	sub_48			; (8F7C)
		call	$-1A6Eh
		jmp	short loc_295		; (94D5)
loc_294:					;  xref F000:94C6
		call	sub_48			; (8F7C)
loc_295:					;  xref F000:94D0
		mov	ax,1Eh
		assume	ds:seg_a
		mov	vector_6h_seg,ax	; (0000:001A=0F000h)
		mov	vector_7h_off,ax	; (0000:001C=0EAA6h)
		mov	ds:data_27e,ax		; (0000:0080=6B0h)
		add	ax,20h
		mov	ds:data_28e,ax		; (0000:0082=10ADh)
		in	al,21h			; port 21h, 8259-1 int IMR
		and	al,0B8h
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	21h,al			; port 21h, 8259-1 int comands
		sti				; Enable interrupts
		mov	al,73h			; 's'
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	si,data_187e		; (F000:7E3B=50h)
		call	sub_33			; (8E5B)
		sti				; Enable interrupts
		mov	al,4
		mov	dx,3F6h
		out	dx,al			; port 3F6h, hdsk0 register
						;  al = 4, reset controller
		mov	cx,100h
		call	sub_279			; (F068)
		mov	al,0
		out	dx,al			; port 3F6h, hdsk0 register
		mov	cx,0FFF0h
		call	sub_279			; (F068)
		mov	al,74h			; 't'
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	al,byte ptr vector_4h_seg	; (0000:0012=70h)
		test	al,20h			; ' '
		jz	short loc_297		; Jump if zero
		mov	al,8Eh

		call	sub_270			; (EE9F)
		test	al,0C0h
		jnz	short loc_296		; Jump if not zero
		mov	ax,0FF90h
		call	sub_56			; (93F0)
		jz	short loc_297		; Jump if zero
loc_296:					;  xref F000:9524
		test	byte ptr cs:data_275,30h	; (F000:E2C0=0BFh) '0'
		jz	short loc_297		; Jump if zero
		call	sub_145			; (B4BF)
loc_297:					;  xref F000:951B, 952C, 9534
		sti				; Enable interrupts
		mov	al,75h			; 'u'
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	al,8Eh
		call	sub_270			; (EE9F)
		test	al,0C0h
		jnz	short loc_298		; Jump if not zero
		mov	al,92h
		call	sub_270			; (EE9F)
		or	al,al			; Zero ?
		jz	short loc_298		; Jump if zero
		mov	al,76h			; 'v'
		out	80h,al			; port 80h, diagnostc chkpoint
		call	sub_127			; (A97E)
		sti				; Enable interrupts
		mov	al,77h			; 'w'
		out	80h,al			; port 80h, diagnostc chkpoint
loc_298:					;  xref F000:9545, 954E
		pop	bx
		xchg	bx,bp
		push	bx
		mov	al,78h			; 'x'
		out	80h,al			; port 80h, diagnostc chkpoint
		call	$-1EA9h
		mov	al,79h			; 'y'
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	bx,word ptr vector_4h_seg+1	; (0000:0013=5400h)
		mov	ax,8E8Eh
		call	sub_270			; (EE9F)
		test	al,0C0h
		jnz	short loc_301		; Jump if not zero
		push	ax
		call	sub_39			; (8EE5)
		mov	al,7Ah			; 'z'
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	ax,9596h
		call	sub_62			; (98EE)
		cmp	ax,bx
		je	short loc_299		; Jump if equal
		or	bp,100h
		pop	ax
		or	al,10h
		push	ax
loc_299:					;  xref F000:9589
		mov	ax,0B0B1h
		call	sub_270			; (EE9F)

		xchg	al,ah
		call	sub_270			; (EE9F)
		mov	cx,ax
		mov	ax,9798h
		call	sub_62			; (98EE)
		cmp	ax,cx
		pop	ax
		jz	short loc_300		; Jump if zero
		or	bp,100h
		or	al,10h
loc_300:					;  xref F000:95A9
		xchg	al,ah
		call	sub_271			; (EEAE)
loc_301:					;  xref F000:9577
		mov	al,7Bh			; '{'
		out	80h,al			; port 80h, diagnostc chkpoint
		push	95C1h
		push	offset loc_1272
		retn
		mov	al,7Ch			; '|'
		out	80h,al			; port 80h, diagnostc chkpoint
		call	$-1EF5h
		sti				; Enable interrupts
		mov	al,7Dh			; '}'
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	ax,0B3B3h
		call	sub_270			; (EE9F)
		and	al,7Fh
		cmp	bl,8
		jbe	short loc_302		; Jump if below or =
		or	al,80h
loc_302:					;  xref F000:95D8
		xchg	al,ah
		call	sub_271			; (EEAE)
		mov	ax,bx
		cbw				; Convrt byte to word
		shl	ax,6			; Shift w/zeros fill
		push	ax
		test	byte ptr cs:data_275,40h	; (F000:E2C0=0BFh) '@'
		jz	short loc_303		; Jump if zero
		dec	ax
		mov	cx,ax
		shl	ax,6			; Shift w/zeros fill
		mov	vector_3h_seg,ax	; (0000:000E=70h)
		jmp	short loc_304		; (95FF)
loc_303:					;  xref F000:95EE
		mov	cx,ax
		jmp	short loc_304		; (95FF)
loc_304:					;  xref F000:95F9, 95FD
		mov	word ptr vector_4h_seg+1,cx	; (0000:0013=5400h)
		mov	ax,0B0B1h
		call	sub_270			; (EE9F)
		xchg	al,ah
		call	sub_270			; (EE9F)
		shl	ax,6			; Shift w/zeros fill
		push	ax
		mov	al,0B1h

		call	sub_271			; (EEAE)
		pop	ax
		mov	ah,0B0h
		xchg	al,ah
		call	sub_271			; (EEAE)
		mov	al,7Eh			; '~'
		out	80h,al			; port 80h, diagnostc chkpoint
		call	$-1FB5h
		sti				; Enable interrupts
		mov	word ptr ds:graph_tbl_off,101h	; (0000:007C=0E02h)
		mov	word ptr ds:graph_tbl_seg,101h	; (0000:007E=0C000h)
		mov	word ptr ds:disk_parm_off,1414h	; (0000:0078=522h)
		mov	word ptr ds:disk_parm_seg,1414h	; (0000:007A=0)
		mov	al,7Fh
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	al,8Dh
		out	70h,al			; port 70h, RTC addr/enabl NMI
		call	sub_39			; (8EE5)
		call	sub_130			; (AC9D)
		xor	cx,cx			; Zero register
loc_305:					;  xref F000:965C, 9661
		mov	ah,1
		int	16h			; Keyboard i/o  ah=function 01h
						;  get status, if zf=0  al=char
		jz	short loc_306		; Jump if zero
		mov	ah,0
		int	16h			; Keyboard i/o  ah=function 00h
						;  get keybd char in al, ah=scan
		cmp	ah,53h			; 'S'
		jne	loc_305			; Jump if not equal
		mov	cx,5555h
		jmp	short loc_305		; (964F)
loc_306:					;  xref F000:9653
		push	cx
		xor	ax,ax			; Zero register
		mov	di,data_60e		; (0000:0600=42h)
		mov	cx,7D00h
		cli				; Disable interrupts
		cld				; Clear direction
		rep	stosw			; Rep when cx >0 Store ax to es:[di]
		sti				; Enable interrupts
		mov	al,80h
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	bx,0C800h
loc_307:					;  xref F000:967F
		call	sub_54			; (8FF5)
		cmp	bx,0E000h
		jb	loc_307			; Jump if below
		mov	al,8Dh
		out	70h,al			; port 70h, RTC addr/enabl NMI
		call	sub_39			; (8EE5)
		mov	al,81h
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	al,8Eh
		call	sub_270			; (EE9F)
		test	al,0C0h
		jnz	short loc_310		; Jump if not zero

		mov	ah,2
		int	1Ah			; Real time clock   ah=func 02h
						;  read clock cx=hrs/min, dh=sec
		jc	short loc_309		; Jump if carry Set
		cmp	dh,60h			; '`'
		jae	short loc_309		; Jump if above or =
		cmp	cl,60h			; '`'
		jae	short loc_309		; Jump if above or =
		cmp	ch,24h			; '$'
		jae	short loc_309		; Jump if above or =
		mov	al,dh
		call	sub_61			; (98E4)
		imul	ax,ax,12h		; reg1 = reg2 * value
		xchg	ax,cx
		push	ax
		call	sub_61			; (98E4)
		imul	ax,ax,444h		; reg1 = reg2 * value
		add	cx,ax
		pop	ax
		mov	al,ah
		call	sub_61			; (98E4)
		push	ax
		imul	ax,ax,7			; reg1 = reg2 * value
		add	ax,cx
loc_308:					;  xref F000:96F0
		cli				; Disable interrupts
		mov	ds:data_176e,ax		; (C000:006C=204Ch)
		pop	ax
		adc	ax,0
		mov	ds:data_177e,ax		; (C000:006E=4952h)
		mov	byte ptr ds:data_178e,0	; (C000:0070=47h)
		sti				; Enable interrupts
		jmp	short loc_311		; (96F2)
loc_309:					;  xref F000:9699, 969E, 96A3, 96A8
		or	bp,200h
		mov	ax,8E8Eh
		call	sub_270			; (EE9F)
		or	al,4
		xchg	al,ah
		call	sub_271			; (EEAE)
loc_310:					;  xref F000:9693
		xor	ax,ax			; Zero register
		push	ax
		jmp	short loc_308		; (96C9)
loc_311:					;  xref F000:96DA
		sti				; Enable interrupts
		cld				; Clear direction
		pop	ax
		mov	ds:data_175e,ax		; (C000:0069=412Ch)
		pop	ax
		mov	ds:data_174e,ax		; (C000:0067=3938h)
		xor	bx,bx			; Zero register
		xor	di,di			; Zero register
		mov	dx,3BCh
		call	sub_63			; (98FA)
		mov	dx,378h
		call	sub_63			; (98FA)

		mov	dx,278h
		call	sub_63			; (98FA)
		push	di
		mov	al,82h
		out	80h,al			; port 80h, diagnostc chkpoint
		xor	di,di			; Zero register
		mov	dx,3F8h
		call	sub_64			; (9906)
		mov	dx,2F8h
		call	sub_64			; (9906)
		mov	dx,3E8h
		call	sub_64			; (9906)
		mov	dx,2E8h
		call	sub_64			; (9906)
		pop	ax
		ror	al,3			; Rotate
		or	ax,di
		or	ds:data_169e,al		; (C000:0011=2Dh)
		mov	al,83h
		out	80h,al			; port 80h, diagnostc chkpoint
		and	byte ptr ds:data_168e,0FDh	; (C000:0010=30h)
		fninit				; Initialize math uP
		pusha				; Save all regs
		popa				; Restore all regs
		pusha				; Save all regs
		popa				; Restore all regs
		fnstsw	ax			; Store status word
		and	al,al
		jnz	short loc_312		; Jump if not zero
		or	byte ptr ds:data_168e,2	; (C000:0010=30h)
		in	al,0A1h			; port 0A1h, 8259-2 int IMR
		and	al,0DFh
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	0A1h,al			; port 0A1h, 8259-2 int comands
loc_312:					;  xref F000:974E
		in	al,21h			; port 21h, 8259-1 int IMR
		and	al,0F8h
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	21h,al			; port 21h, 8259-1 int comands
		mov	al,84h
		out	80h,al			; port 80h, diagnostc chkpoint
		in	al,64h			; port 64h, keyboard status
		test	al,10h
		jnz	short loc_313		; Jump if not zero
		or	bp,1000h
loc_313:					;  xref F000:9771
		mov	byte ptr ds:data_171e,0	; (C000:0017=3Ah)
		mov	byte ptr ds:data_180e,0A0h	; (C000:0096=50h)
		mov	al,ds:data_170e		; (C000:0012=30h)
		test	al,20h			; ' '
		jz	short loc_314		; Jump if zero
		mov	al,0F2h
		call	sub_84			; (A0D7)
loc_314:					;  xref F000:9786
		sti				; Enable interrupts

		mov	cx,0FFF0h
		call	sub_279			; (F068)
		and	byte ptr ds:data_180e,1Fh	; (C000:0096=50h)
		and	byte ptr ds:data_181e,7Fh	; (C000:0097=5Ah)
		in	al,0A1h			; port 0A1h, 8259-2 int IMR
		and	al,0FDh
		jmp	short $+2		; delay for I/O
		jmp	short $+2		; delay for I/O
		out	0A1h,al			; port 0A1h, 8259-2 int comands
		mov	al,85h
		out	80h,al			; port 80h, diagnostc chkpoint
		pop	bx
		push	bp
		mov	ax,2B7h
		call	sub_56			; (93F0)
		jnz	short loc_315		; Jump if not zero
		and	bp,0F3FFh
loc_315:					;  xref F000:97B4
		and	bp,7FFFh
		jnz	short loc_316		; Jump if not zero
		or	bx,bx			; Zero ?
		jnz	short loc_316		; Jump if not zero
		jmp	loc_323			; (9849)
loc_316:					;  xref F000:97BE, 97C2
		call	sub_37			; (8EA9)
		mov	cx,8000h
		call	sub_279			; (F068)
		call	sub_37			; (8EA9)
		mov	si,ds:[7AB2h]		; (F000:7AB2=0F2h)
		call	sub_59			; (98C7)
		xchg	bp,bx
		call	sub_59			; (98C7)
		test	bp,20h
		jnz	short loc_317		; Jump if not zero
		test	bx,7E2h
		jz	short loc_318		; Jump if zero
loc_317:					;  xref F000:97E2
		mov	si,7CE8h
		call	sub_34			; (8E69)
		call	sub_60			; (98DD)
		test	byte ptr cs:data_275,80h	; (F000:E2C0=0BFh)
		jz	short loc_318		; Jump if zero
		or	word ptr ds:data_175e,0AAAAh	; (C000:0069=412Ch)
loc_318:					;  xref F000:97E8, 97F9
		mov	si,7CFAh
		call	sub_60			; (98DD)
		mov	al,ds:data_170e		; (C000:0012=30h)
		test	al,20h			; ' '
		jz	short loc_323		; Jump if zero
		mov	al,cs:data_275		; (F000:E2C0=0BFh)
		test	al,80h
		jz	short loc_321		; Jump if zero
		test	al,2
		jnz	short loc_319		; Jump if not zero
		and	bp,0F9FFh
		and	bx,0EFFFh
loc_319:					;  xref F000:9818

		test	al,20h			; ' '
		jnz	short loc_320		; Jump if not zero
		and	bp,0FFFEh
loc_320:					;  xref F000:9824
		or	bp,bp			; Zero ?
		jnz	short loc_322		; Jump if not zero
		or	bx,bx			; Zero ?
		jz	short loc_321		; Jump if zero
		test	bx,4
		jz	short loc_322		; Jump if zero
loc_321:					;  xref F000:9814, 982F
		sti				; Enable interrupts
		mov	cx,0FFF0h
		call	sub_279			; (F068)
		jmp	short loc_323		; (9849)
loc_322:					;  xref F000:982B, 9835, 9847
		mov	ah,0
		int	16h			; Keyboard i/o  ah=function 00h
						;  get keybd char in al, ah=scan
		cmp	ah,3Bh			; ';'
		jne	loc_322			; Jump if not equal
loc_323:					;  xref F000:97C4, 980C, 983E
		pop	bp
		mov	al,ds:data_170e		; (C000:0012=30h)
		test	al,20h			; ' '
		jnz	short loc_326		; Jump if not zero
		sti				; Enable interrupts
		mov	ax,8Fh
		call	sub_271			; (EEAE)
		mov	word ptr ds:data_179e,0	; (C000:0072=5354h)
		mov	al,8Eh
		call	sub_270			; (EE9F)
		test	al,0D0h
		jz	short loc_325		; Jump if zero
loc_324:					;  xref F000:986E
		cli				; Disable interrupts
		mov	bx,3
		call	sub_57			; (9401)
		jmp	short loc_324		; (9867)
loc_325:					;  xref F000:9865
		mov	cx,0FFF0h
		call	sub_279			; (F068)
		mov	cx,0FFF0h
		call	sub_279			; (F068)
		call	sub_37			; (8EA9)
		jmp	loc_1209		; (F396)
loc_326:					;  xref F000:984F
		cmp	word ptr ds:data_175e,0	; (C000:0069=412Ch)
		je	short loc_327		; Jump if equal
		call	sub_172			; (BDE2)
loc_327:					;  xref F000:9887
		call	sub_37			; (8EA9)
		mov	ah,0Fh
		int	10h			; Video display   ah=functn 0Fh
						;  get state, al=mode, bh=page
		xor	ah,ah			; Zero register
		int	10h			; Video display   ah=functn 00h

						;  set display mode in al
		mov	al,0Dh
		out	70h,al			; port 70h, RTC addr/enabl NMI
						;  al = 0Dh, status register D
		call	sub_39			; (8EE5)
		sti				; Enable interrupts
		cld				; Clear direction
		mov	al,86h
		out	80h,al			; port 80h, diagnostc chkpoint
		mov	bx,0E000h
		mov	ds:data_179e,bl		; (C000:0072=54h)
		mov	ax,ds:data_174e		; (C000:0067=3938h)
		push	ax
		call	sub_54			; (8FF5)
		pop	ax
		mov	ds:data_174e,ax		; (C000:0067=3938h)
		mov	al,0
		out	80h,al			; port 80h, diagnostc chkpoint
		call	sub_210			; (C8E0)
		jnz	short loc_328		; Jump if not zero
;*		mov	ax,offset sub_6		;*(0008)
		db	0B8h, 08h, 00h
		call	ax			;*
loc_328:					;  xref F000:98BD
		jmp	loc_237			; (9040)

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:97D6, 97DB
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_59		proc	near
		mov	cx,10h

locloop_330:					;  xref F000:98DA
		cli				; Disable interrupts
		cld				; Clear direction
		lods word ptr cs:[si]		; String [si] to ax
		sti				; Enable interrupts
		ror	bp,1			; Rotate
		jnc	short loc_331		; Jump if carry=0
		push	si
		mov	si,ax
		call	sub_60			; (98DD)
		pop	si
loc_331:					;  xref F000:98D1
		loop	locloop_330		; Loop if cx > 0

		retn
sub_59		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:97F0, 9804, 98D6

;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_60		proc	near
		call	sub_34			; (8E69)
		call	sub_33			; (8E5B)
		retn
sub_60		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:96AC, 96B4, 96C0
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_61		proc	near
		mov	ah,al
		shr	ah,4			; Shift w/zeros fill
		and	al,0Fh
		aad				; Ascii adjust
		retn
sub_61		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9584, 95A3
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_62		proc	near
		call	sub_270			; (EE9F)
		xchg	al,ah
		call	sub_270			; (EE9F)
		shr	ax,6			; Shift w/zeros fill
		retn
sub_62		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9703, 9709, 970F
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_63		proc	near
		call	sub_223			; (CEC4)
		jnz	short loc_ret_332	; Jump if not zero
		mov	[di+8],dx
		inc	di
		inc	di

loc_ret_332:					;  xref F000:98FD
		retn
sub_63		endp



;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:971C, 9722, 9728, 972E
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_64		proc	near
		push	dx
		inc	dx
		inc	dx
		in	al,dx			; port 3FAh, RS232-1 int identy
		test	al,0F8h
		pop	dx
		jnz	short loc_ret_333	; Jump if not zero
		mov	[di+0],dx
		inc	di
		inc	di

loc_ret_333:					;  xref F000:990D
		retn
sub_64		endp

		db	10 dup (0FEh)
		db	0DDh,0F5h, 95h,0B5h, 96h, 66h
		db	 4Eh, 7Eh, 46h, 96h, 7Eh, 5Eh
		db	 7Eh, 36h, 36h, 7Eh, 96h,0A1h

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:A9DB
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_65		proc	near
		push	cx
		mov	di,104h
		mov	ch,9Bh
		jmp	short loc_334		; (9940)

;ﬂﬂﬂﬂ External Entry into Subroutine ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;
;         Called from:	 F000:AA18

sub_66:
		push	cx
		mov	di,118h
		mov	ch,0A4h
loc_334:					;  xref F000:9938
		cli				; Disable interrupts
		cld				; Clear direction
		push	dx
		push	es
		test	byte ptr cs:data_275,40h	; (F000:E2C0=0BFh) '@'
		jnz	short loc_335		; Jump if not zero
		mov	ax,0F7FAh
		jmp	short loc_337		; (9968)
		mov	al,0B8h

		call	sub_270			; (EE9F)
		test	al,10h
		mov	ax,2Dh
		jz	short loc_337		; Jump if zero
loc_335:					;  xref F000:994A
		mov	ax,word ptr vector_4h_seg+1	; (0000:0013=5400h)
		cbw				; Convrt byte to word
		shl	ax,6			; Shift w/zeros fill
		dec	ax
		shl	ax,6			; Shift w/zeros fill
loc_337:					;  xref F000:994F, 995B
		mov	dx,ax
		mov	ax,3Dh
		cmp	ch,9Bh
		je	short loc_339		; Jump if equal
		mov	ax,4Dh
loc_339:					;  xref F000:9970
		stosw				; Store ax to es:[di]
		push	ax
		mov	ax,dx
		stosw				; Store ax to es:[di]
		mov	es,ax
		cmp	ax,0F7FAh
		jne	short loc_340		; Jump if not equal
		call	sub_68			; (99C4)
loc_340:					;  xref F000:997F
		pop	di
		push	es
		call	sub_67			; (99BB)
		call	sub_67			; (99BB)
		call	sub_67			; (99BB)
		xor	ax,ax			; Zero register
		stosw				; Store ax to es:[di]
		call	sub_67			; (99BB)
		call	sub_67			; (99BB)
		xor	al,al			; Zero register
		stosb				; Store al to es:[di]
		call	sub_67			; (99BB)
		xor	ax,ax			; Zero register
		stosw				; Store ax to es:[di]
		stosb				; Store al to es:[di]
		call	sub_67			; (99BB)
		call	sub_67			; (99BB)
		call	sub_67			; (99BB)
		xor	al,al			; Zero register
		stosb				; Store al to es:[di]
		pop	ax
		cmp	ax,0F7FAh
		jne	short loc_343		; Jump if not equal

locloop_342:					;  xref F000:9A31
		call	sub_69			; (99C8)
loc_343:					;  xref F000:99B2
		pop	es
		pop	dx
		pop	cx
		retn

sub_65		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9986, 9989, 998C, 9992, 9995, 999B, 99A2
;			      99A5, 99A8
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_67		proc	near
		mov	al,ch
		inc	ch
		call	sub_270			; (EE9F)
		stosb				; Store al to es:[di]
		retn
sub_67		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9981
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_68		proc	near
		mov	al,0B1h
		jmp	short loc_344		; (99CA)

;ﬂﬂﬂﬂ External Entry into Subroutine ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;
;         Called from:	 F000:99B4

sub_69:
		mov	al,0B9h
loc_344:					;  xref F000:99C6
		push	cx
		call	sub_46			; (8F60)
		call	sub_44			; (8F3B)
		pop	cx
		in	al,60h			; port 60h, keybd scan or sw1
		retn
sub_68		endp

		db	 00h,0F0h, 78h, 79h
		db	 7Ah, 7Bh, 7Ch, 7Dh, 7Eh, 7Fh
		db	 80h, 81h, 82h, 83h,0F0h

locloop_346:					;  xref F000:9A2F
		movsw				; Mov [si] to es:[di]
		adc	[bx+di],dl
		adc	dl,[bp+di]
		adc	al,15h
		push	ss
		pop	ss
		sbb	[bx+di],bl
		db	0F0h,0F0h,0F0h,0FFh, 1Eh, 1Fh

		db	 20h, 21h, 22h, 23h
		db	 24h, 25h, 26h,0F0h,0F0h,0F0h
		db	0FFh,0F0h, 2Ch, 2Dh, 2Eh, 2Fh
		db	 30h, 31h, 32h,0F0h,0F0h,0F0h
		db	0FFh,0F0h,0FFh, 20h,0FFh
		db	'hijklmnopq'
		db	0FFh,0FFh, 07h, 08h, 09h
		db	0F0h, 04h, 05h, 06h,0F0h, 01h
		db	 02h, 03h, 00h, 53h,0FFh,0FFh
		db	0FFh, 8Bh, 8Ch,0BBh,0E2h,0B3h
		db	0E2h, 81h
		db	79h
		db	 31h, 69h,0B1h
		db	0C1h,0B9h, 59h
		db	0FBh,0F2h,0E1h,0E1h,0D1h, 61h
		db	 61h,0FBh, 92h,0D1h, 59h,0B9h
		db	 81h,0D9h, 61h,0FBh,0B2h, 89h
		db	0E1h, 8Bh,0FFh,0FEh, 67h, 04h
		db	 03h,0FFh, 00h, 0Fh
loc_354:					;  xref F000:99D9
		sbb	di,di
		add	bh,bh
		db	0FFh,0FFh, 1Eh,0FFh,0FFh,0FFh
		db	0FFh, 1Fh,0FFh, 7Fh, 94h, 11h
		db	 17h, 05h, 12h, 14h, 19h, 15h
		db	 09h, 0Fh, 10h, 1Bh, 1Dh
loc_355:					;  xref F000:9ABD
		or	bh,bh			; Zero ?
		add	[bp+di],dx
		add	al,6
		pop	es
		or	[bp+si],cl
		or	cx,[si]
		db	0FFh,0FFh,0FFh,0FFh, 1Ch, 1Ah
		db	 18h, 03h, 16h, 02h, 0Eh, 0Dh
		db	0FFh,0FFh, 95h
		db	0FFh, 96h,0FFh, 20h,0FFh
		db	'^_`abcdefgEFw'
		db	 8Dh, 84h, 8Eh, 73h, 8Fh, 74h
		db	 90h, 75h, 91h, 76h, 92h, 93h
		db	0FFh,0FFh,0FFh, 89h, 8Ah, 5Fh
		db	0F2h, 5Bh, 7Fh,0CAh,0CAh
loc_357:					;  xref F000:9B2B
		db	0F2h, 7Fh,0EEh
		db	 5Ah, 62h, 5Ah, 2Eh, 7Ah

locloop_358:					;  xref F000:9B39
		dec	si
		jg	loc_355			; Jump if >
		sbb	dh,[bp+si]
		db	 2Eh, 6Ah, 4Ah, 32h, 4Fh, 7Fh
		db	0DAh,0C6h,0EEh,0DAh,0FAh, 4Fh
		db	 7Fh, 3Bh, 3Bh, 4Bh, 3Bh, 33h
		db	 4Bh, 1Fh

		db	'+', 1Bh, '!@#$'
		db	'%^&*()_+', 8
		db	0
		db	'QWERTYUIOP{}', 0Dh
		db	0FFh
		db	'ASDFGHJKL:"~'
		db	0FFh
		db	'|ZXCVBNM<>?'
		db	0FFh, 2Ah,0FFh, 20h,0FFh
		db	'TUVWXYZ[\]'
		db	0FFh,0FFh
		db	'789-456+123'
		db	 30h, 2Eh,0FFh,0FFh, 7Ch, 87h
		db	 88h
		db	'*56789?/'
		db	0BBh,0E2h,0B3h,0E2h, 81h, 79h
		db	 31h, 69h,0B1h,0C1h,0B9h, 59h
		db	0FBh,0F2h,0E1h,0E1h,0D1h, 61h
		db	 61h,0FBh, 92h,0D1h, 59h,0B9h
		db	 81h,0D9h, 61h,0FBh,0B2h, 89h
		db	0E1h, 8Bh
		db	1Bh, '1234567890-=', 8, 9, 'qwert'
		db	'yuio'
loc_360:					;  xref F000:9AEF, 9B3B
		jo	short loc_362		; Jump if overflow=1
		pop	bp
		or	ax,61FFh
		jnc	short loc_363		; Jump if carry=0
		db	'fghjkl;', 27h, '`'
		db	0FFh
		db	'\zxcvbnm,./'
		db	0FFh, 2Ah,0FFh, 20h,0FFh
		db	';<=>?@ABCD'
		db	0FFh,0FFh, 47h, 48h, 49h, 2Dh
		db	 4Bh,0F0h, 4Dh, 2Bh, 4Fh, 50h
		db	 51h, 52h, 53h,0FFh,0FFh, 5Ch
		db	 85h, 86h, 5Fh,0F2h, 5Bh, 7Fh
		db	0CAh,0CAh,0F2h, 7Fh,0EEh, 5Ah
		db	 62h, 5Ah, 2Eh, 7Ah, 4Eh, 7Fh
		db	0B2h, 1Ah, 32h, 2Eh, 6Ah, 4Ah
		db	 32h, 4Fh, 7Fh,0DAh,0C6h,0EEh
		db	0DAh
loc_362:					;  xref F000:9B6E

		cli				; Disable interrupts
		dec	di
		jg	short loc_368		; Jump if >
		cmp	cx,[bp+di+3Bh]
		xor	cx,[bp+di+1Fh]
		sub	di,bx
		cld				; Clear direction
		pusha				; Save all regs
		push	ds
loc_363:					;  xref F000:9B74
		mov	bp,sp
		push	40h
		pop	ds
		call	sub_78			; (9FE0)
		stc				; Set carry flag
		mov	ah,4Fh			; 'O'
		int	15h			; General services, ah=func 4Fh
						;  change keyboard scan code
		cli				; Disable interrupts
		jnc	short loc_374		; Jump if carry=0
		cmp	al,0FEh
		jne	short loc_366		; Jump if not equal
		assume	ds:seg_b
		or	keybd_flags_4,20h	; (0040:0097=10h) ' '
		jmp	short loc_374		; (9C53)
loc_366:					;  xref F000:9BEC
		cmp	al,0FAh
		jne	short loc_367		; Jump if not equal
		or	keybd_flags_4,10h	; (0040:0097=10h)
		jmp	short loc_374		; (9C53)
loc_367:					;  xref F000:9BF7
		sti				; Enable interrupts
		push	ax
		call	sub_81			; (A082)
		jz	short loc_368		; Jump if zero
		call	sub_82			; (A094)
loc_368:					;  xref F000:9BCD, 9C05
		pop	ax
		cmp	al,0FDh
		je	short loc_370		; Jump if equal
		cmp	al,0FFh
		jne	short loc_371		; Jump if not equal
loc_370:					;  xref F000:9C0D
		call	sub_80			; (A003)
		jmp	loc_438			; (9F59)
loc_371:					;  xref F000:9C11
		test	keybd_flags_3,0C0h	; (0040:0096=10h)
		jz	short loc_375		; Jump if zero
		jns	short loc_372		; Jump if not sign
		and	keybd_flags_3,7Fh	; (0040:0096=10h)
		cmp	al,0ABh
		jne	short loc_374		; Jump if not equal
		or	keybd_flags_3,40h	; (0040:0096=10h) '@'
		jmp	short loc_374		; (9C53)
loc_372:					;  xref F000:9C20
		and	keybd_flags_3,0BFh	; (0040:0096=10h)
		cmp	al,54h			; 'T'

		je	short loc_373		; Jump if equal
		cmp	al,41h			; 'A'
		jne	short loc_374		; Jump if not equal
		test	keybd_flags_3,20h	; (0040:0096=10h) ' '
		jz	short loc_373		; Jump if zero
		or	keybd_flags_1,20h	; (0040:0017=0) ' '
		call	sub_82			; (A094)
loc_373:					;  xref F000:9C39, 9C44
		or	keybd_flags_3,10h	; (0040:0096=10h)
loc_374:					;  xref F000:9BE8, 9BF3, 9BFE, 9C29
						;            9C30, 9C3D, 9C80, 9C8A
		jmp	loc_387			; (9CF7)
loc_375:					;  xref F000:9C1E
		cmp	al,0E1h
		jne	short loc_376		; Jump if not equal
		or	byte ptr ds:data_38e,11h	; (0000:0096=0B8h)
		jmp	short loc_377		; (9C6A)
loc_376:					;  xref F000:9C58
		cmp	al,0E0h
		jne	short loc_378		; Jump if not equal
		or	byte ptr ds:data_38e,12h	; (0000:0096=0B8h)
loc_377:					;  xref F000:9C5F
		jmp	loc_388			; (9CFA)
loc_378:					;  xref F000:9C63
		test	al,80h
		jnz	short loc_379		; Jump if not zero
		jmp	loc_389			; (9CFD)
loc_379:					;  xref F000:9C6F
		and	al,7Fh
		call	sub_90			; (A15B)
		jz	short loc_380		; Jump if zero
		call	sub_75			; (9FC0)
		jz	short loc_388		; Jump if zero
		jmp	short loc_374		; (9C53)
loc_380:					;  xref F000:9C79
		call	sub_89			; (A155)
		jz	short loc_381		; Jump if zero
		call	sub_76			; (9FCC)
		jz	loc_374			; Jump if zero
loc_381:					;  xref F000:9C85
		call	sub_74			; (9FAF)
		jz	short loc_382		; Jump if zero
		mov	ah,80h
		cmp	al,52h			; 'R'
		jne	short loc_383		; Jump if not equal
loc_382:					;  xref F000:9C8F
		not	ah
		assume	ds:seg_a
		and	byte ptr vector_6h_off,ah	; (0000:0018=52h)
		jmp	short loc_387		; (9CF7)
loc_383:					;  xref F000:9C95
		cmp	al,54h			; 'T'
		jne	short loc_384		; Jump if not equal
		and	byte ptr vector_6h_off,0FBh	; (0000:0018=52h)
		mov	ax,8501h
		jmp	loc_394			; (9D5E)
loc_384:					;  xref F000:9CA1

		call	sub_75			; (9FC0)
		jnz	short loc_387		; Jump if not zero
		not	ah
		and	byte ptr vector_5h_seg+1,ah	; (0000:0017=0F0h)
		push	ax
		call	sub_76			; (9FCC)
		pop	ax
		jz	short loc_387		; Jump if zero
		call	sub_89			; (A155)
		xchg	al,ah
		jz	short loc_385		; Jump if zero
		and	ds:data_38e,al		; (0000:0096=0B8h)
		jmp	short loc_386		; (9CD4)
loc_385:					;  xref F000:9CC5
		sar	al,2			; Shift w/sign fill
		and	byte ptr vector_6h_off,al	; (0000:0018=52h)
loc_386:					;  xref F000:9CCB
		mov	al,byte ptr vector_6h_off	; (0000:0018=52h)
		shl	al,2			; Shift w/zeros fill
		or	al,ds:data_38e		; (0000:0096=0B8h)
		and	al,0Ch
		or	byte ptr vector_5h_seg+1,al	; (0000:0017=0F0h)
		xchg	al,ah
		cmp	al,38h			; '8'
		jne	short loc_387		; Jump if not equal
		xor	ax,ax			; Zero register
		xchg	al,byte ptr vector_6h_off+1	; (0000:0019=0EBh)
		and	al,al
		jz	short loc_387		; Jump if zero
		jmp	loc_455			; (A052)
loc_387:					;  xref F000:9C53, 9C9D, 9CB1, 9CBE
						;            9CE8, 9CF2, 9D09, 9D10
						;            9D1D, 9D2D, 9D38, 9D41
						;            9D45, 9D49, 9D54
		jmp	loc_436			; (9F4F)
loc_388:					;  xref F000:9C6A, 9C7E, 9D05
		jmp	loc_437			; (9F54)
loc_389:					;  xref F000:9C71
		call	sub_90			; (A15B)
		jz	short loc_390		; Jump if zero
		call	sub_75			; (9FC0)
		jz	loc_388			; Jump if zero
		cmp	al,45h			; 'E'
		jne	loc_387			; Jump if not equal
		test	byte ptr vector_6h_off,8	; (0000:0018=52h)
		jnz	loc_387			; Jump if not zero
		jmp	loc_411			; (9E17)
loc_390:					;  xref F000:9D00
		call	sub_89			; (A155)
		jz	short loc_391		; Jump if zero
		call	sub_76			; (9FCC)
		jz	loc_387			; Jump if zero
loc_391:					;  xref F000:9D18
		call	sub_75			; (9FC0)
		jnz	short loc_393		; Jump if not zero
		or	byte ptr vector_5h_seg+1,ah	; (0000:0017=0F0h)
		push	ax

		call	sub_76			; (9FCC)
		pop	ax
		jz	loc_387			; Jump if zero
		call	sub_89			; (A155)
		jz	short loc_392		; Jump if zero
		or	ds:data_38e,ah		; (0000:0096=0B8h)
		jmp	short loc_387		; (9CF7)
loc_392:					;  xref F000:9D32
		shr	ah,2			; Shift w/zeros fill
		or	byte ptr vector_6h_off,ah	; (0000:0018=52h)
		jmp	short loc_387		; (9CF7)
loc_393:					;  xref F000:9D22
		and	al,al
		jz	loc_387			; Jump if zero
		cmp	al,58h			; 'X'
		ja	loc_387			; Jump if above
		cmp	al,54h			; 'T'
		jne	short loc_395		; Jump if not equal
		test	byte ptr vector_6h_off,4	; (0000:0018=52h)
		jnz	loc_387			; Jump if not zero
		or	byte ptr vector_6h_off,4	; (0000:0018=52h)
		mov	ax,8500h
loc_394:					;  xref F000:9CAB
		push	ax
		mov	al,20h			; ' '
		out	20h,al			; port 20h, 8259-1 int command
						;  al = 20h, end of interrupt
		call	sub_77			; (9FD7)
		pop	ax
		int	15h			; General services, ah=func 85h
						;  get system request key state
		jmp	loc_439			; (9F5C)
loc_395:					;  xref F000:9D4D
		test	byte ptr vector_5h_seg+1,8	; (0000:0017=0F0h)
		jz	short loc_396		; Jump if zero
		call	sub_88			; (A14F)
		jz	short loc_397		; Jump if zero
		test	byte ptr vector_6h_off,4	; (0000:0018=52h)
		jz	short loc_397		; Jump if zero
loc_396:					;  xref F000:9D71
		jmp	short loc_409		; (9DFA)
		db	90h
loc_397:					;  xref F000:9D76, 9D7D
		test	byte ptr vector_5h_seg+1,4	; (0000:0017=0F0h)
		jz	short loc_399		; Jump if zero
		cmp	al,53h			; 'S'
		jne	short loc_398		; Jump if not equal
		mov	word ptr ds:data_25e,1234h	; (0000:0072=0F000h)
;*		jmp	loc_1061		;*(E05B)
		db	0E9h,0C5h, 42h
loc_398:					;  xref F000:9D8B
		call	sub_247			; (E88E)
		jmp	short loc_400		; (9D9E)
loc_399:					;  xref F000:9D87
		call	sub_70			; (9F62)
loc_400:					;  xref F000:9D99
		call	sub_71			; (9F7B)

		mov	bx,ds:[99D6h]		; (F000:99D6=0F0h)
		call	sub_72			; (9F8E)
		call	sub_89			; (A155)
		jz	short loc_403		; Jump if zero
		mov	byte ptr vector_6h_off+1,0	; (0000:0019=0EBh)
		cmp	ah,1Ch
		jne	short loc_401		; Jump if not equal
		mov	al,0A6h
		jmp	short loc_406		; (9DF3)
loc_401:					;  xref F000:9DB4
		cmp	ah,35h			; '5'
		jne	short loc_402		; Jump if not equal
		mov	al,0A4h
		jmp	short loc_406		; (9DF3)
loc_402:					;  xref F000:9DBD
		mov	al,ah
		add	al,50h			; 'P'
		jmp	short loc_406		; (9DF3)
loc_403:					;  xref F000:9DAA
		cmp	al,0Ah
		jae	short loc_405		; Jump if above or =
		mov	ah,byte ptr vector_6h_off+1	; (0000:0019=0EBh)
		shl	ah,1			; Shift w/zeros fill
		add	al,ah
		shl	ah,2			; Shift w/zeros fill
		add	al,ah
		mov	byte ptr vector_6h_off+1,al	; (0000:0019=0EBh)
loc_404:					;  xref F000:9DE8, 9E15, 9E4A
		jmp	loc_436			; (9F4F)
loc_405:					;  xref F000:9DCB
		mov	byte ptr vector_6h_off+1,0	; (0000:0019=0EBh)
		cmp	ah,53h			; 'S'
		je	loc_404			; Jump if equal
		cmp	ah,39h			; '9'
		je	short loc_408		; Jump if equal
		cmp	al,0F0h
		je	short loc_408		; Jump if equal
loc_406:					;  xref F000:9DB8, 9DC1, 9DC7, 9E74
		mov	ah,0
loc_407:					;  xref F000:9E9B
		xchg	al,ah
loc_408:					;  xref F000:9DED, 9DF1, 9E61
		jmp	loc_455			; (A052)
loc_409:					;  xref F000:9D7F
		test	byte ptr vector_5h_seg+1,4	; (0000:0017=0F0h)
		jnz	short loc_410		; Jump if not zero
		jmp	loc_422			; (9E9E)
loc_410:					;  xref F000:9DFF
		call	sub_71			; (9F7B)
		mov	bx,ds:[9A56h]		; (F000:9A56=1Bh)
		call	sub_72			; (9F8E)
		cmp	ah,45h			; 'E'
		jne	short loc_413		; Jump if not equal
		call	sub_88			; (A14F)
		jnz	loc_404			; Jump if not zero
loc_411:					;  xref F000:9D12
		or	byte ptr vector_6h_off,8	; (0000:0018=52h)

		call	sub_77			; (9FD7)
		mov	al,20h			; ' '
		out	20h,al			; port 20h, 8259-1 int command
						;  al = 20h, end of interrupt
		cmp	byte ptr vectr_12h_off+1,7	; (0000:0049=0F8h)
		je	short loc_412		; Jump if equal
		mov	al,byte ptr ds:vectr_19h_off+1	; (0000:0065=16h)
		push	dx
		mov	dx,3D8h
		out	dx,al			; port 3D8h, CGA video control
		pop	dx
loc_412:					;  xref F000:9E28, 9E38
		test	byte ptr vector_6h_off,8	; (0000:0018=52h)
		jnz	loc_412			; Jump if not zero
		jmp	loc_438			; (9F59)
loc_413:					;  xref F000:9E10
		cmp	ah,46h			; 'F'
		jne	short loc_417		; Jump if not equal
		call	sub_88			; (A14F)
		jz	short loc_415		; Jump if zero
		call	sub_89			; (A155)
loc_414:					;  xref F000:9E89
		jz	loc_404			; Jump if zero
loc_415:					;  xref F000:9E45
		mov	ax,ds:data_27e		; (0000:0080=6B0h)
		mov	vector_6h_seg,ax	; (0000:001A=0F000h)
		mov	vector_7h_off,ax	; (0000:001C=0EAA6h)
		mov	byte ptr ds:data_23e+1,80h	; (0000:0071=0FFh)
		call	sub_77			; (9FD7)
		int	1Bh			; Keyboard break (cntrl-break)
		xor	ax,ax			; Zero register
loc_416:					;  xref F000:9E84, 9E8B, 9E99
		jmp	short loc_408		; (9DF7)
loc_417:					;  xref F000:9E40
		cmp	ah,37h			; '7'
		jne	short loc_420		; Jump if not equal
		call	sub_88			; (A14F)
		jz	short loc_418		; Jump if zero
		call	sub_89			; (A155)
		jz	short loc_419		; Jump if zero
loc_418:					;  xref F000:9E6B
		mov	al,72h			; 'r'
loc_419:					;  xref F000:9E70, 9E7F, 9E8D, 9E92
		jmp	loc_406			; (9DF3)
loc_420:					;  xref F000:9E66
		call	sub_89			; (A155)
		jnz	short loc_421		; Jump if not zero
		cmp	ah,0Fh
		je	loc_419			; Jump if equal
		cmp	ah,39h			; '9'
		je	loc_416			; Jump if equal
		cmp	ah,35h			; '5'
		je	loc_414			; Jump if equal
		jc	loc_416			; Jump if carry Set
		jmp	short loc_419		; (9E74)
loc_421:					;  xref F000:9E7A
		cmp	ah,35h			; '5'

		je	loc_419			; Jump if equal
		cmp	ah,1Ch
		mov	ah,0E0h
		jz	loc_416			; Jump if zero
		jmp	loc_407			; (9DF5)
loc_422:					;  xref F000:9E01
		call	sub_70			; (9F62)
		cmp	al,52h			; 'R'
		je	short loc_423		; Jump if equal
		call	sub_71			; (9F7B)
loc_423:					;  xref F000:9EA3
		cmp	al,37h			; '7'
		jne	short loc_426		; Jump if not equal
		call	sub_88			; (A14F)
		jz	short loc_424		; Jump if zero
		call	sub_89			; (A155)
		jz	short loc_426		; Jump if zero
		jmp	short loc_425		; (9EBF)
loc_424:					;  xref F000:9EAF
		test	byte ptr vector_5h_seg+1,3	; (0000:0017=0F0h)
		jz	short loc_426		; Jump if zero
loc_425:					;  xref F000:9EB6
		call	sub_77			; (9FD7)
		mov	al,20h			; ' '
		out	20h,al			; port 20h, 8259-1 int command
						;  al = 20h, end of interrupt
		push	bp
		int	5			; Print screen (status at 50:0h)
		pop	bp
		and	byte ptr ds:data_38e,0FCh	; (0000:0096=0B8h)
		jmp	loc_438			; (9F59)
loc_426:					;  xref F000:9EAA, 9EB4, 9EBD
		call	sub_89			; (A155)
		jnz	short loc_427		; Jump if not zero
		test	byte ptr vector_5h_seg+1,3	; (0000:0017=0F0h)
		jz	short loc_432		; Jump if zero
		jmp	short loc_431		; (9EF8)
loc_427:					;  xref F000:9ED5
		cmp	al,1Ch
		jne	short loc_428		; Jump if not equal
		mov	ax,0E00Dh
		jmp	short loc_429		; (9EF0)
loc_428:					;  xref F000:9EE2
		cmp	al,35h			; '5'
		jne	short loc_430		; Jump if not equal
		mov	ax,0E02Fh
loc_429:					;  xref F000:9EE7
		jmp	loc_455			; (A052)
loc_430:					;  xref F000:9EEB
		mov	bx,9B56h
		jmp	short loc_433		; (9F29)
loc_431:					;  xref F000:9EDE
		mov	bx,9AD6h
		test	byte ptr vector_5h_seg+1,20h	; (0000:0017=0F0h) ' '
		jz	short loc_434		; Jump if zero
		call	sub_73			; (9F99)
		cmp	al,46h			; 'F'

		jbe	short loc_434		; Jump if below or =
		cmp	al,56h			; 'V'
		jae	short loc_434		; Jump if above or =
		mov	bx,9B56h
		jmp	short loc_434		; (9F2C)
loc_432:					;  xref F000:9EDC
		mov	bx,9B56h
		test	byte ptr vector_5h_seg+1,20h	; (0000:0017=0F0h) ' '
		jz	short loc_433		; Jump if zero
		cmp	al,46h			; 'F'
		jbe	short loc_434		; Jump if below or =
		cmp	al,56h			; 'V'
		jae	short loc_434		; Jump if above or =
		mov	bx,9AD6h
		jmp	short loc_434		; (9F2C)
loc_433:					;  xref F000:9EF6, 9F1A
		call	sub_73			; (9F99)
loc_434:					;  xref F000:9F00, 9F07, 9F0B, 9F10
						;            9F1E, 9F22, 9F27
		call	sub_72			; (9F8E)
		cmp	ah,3Ah			; ':'
		jbe	short loc_435		; Jump if below or =
		cmp	al,3Ah			; ':'
		jbe	short loc_435		; Jump if below or =
		cmp	al,0F0h
		je	short loc_435		; Jump if equal
		cmp	ah,56h			; 'V'
		je	short loc_435		; Jump if equal
		mov	ah,al
		mov	al,0
		call	sub_89			; (A155)
		jz	short loc_435		; Jump if zero
		mov	al,0E0h
loc_435:					;  xref F000:9F32, 9F36, 9F3A, 9F3F
						;            9F48
		jmp	loc_453			; (A02E)
loc_436:					;  xref F000:9CF7, 9DDD, 9F78, 9F8B
						;            9F96, 9FA2
		and	byte ptr ds:data_38e,0FCh	; (0000:0096=0B8h)
loc_437:					;  xref F000:9CFA
		cli				; Disable interrupts
		mov	al,20h			; ' '
		out	20h,al			; port 20h, 8259-1 int command
						;  al = 20h, end of interrupt
loc_438:					;  xref F000:9C16, 9E3A, 9ECF, A063
		call	sub_77			; (9FD7)
loc_439:					;  xref F000:9D69, A07F
		cli				; Disable interrupts
		mov	sp,bp
		pop	ds
		popa				; Restore all regs
		iret				; Interrupt return

;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9D9B, 9E9E

;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_70		proc	near
		call	sub_74			; (9FAF)
		jnz	short loc_ret_441	; Jump if not zero
		test	ah,byte ptr vector_6h_off	; (0000:0018=52h)
		jnz	short loc_440		; Jump if not zero
		or	byte ptr vector_6h_off,ah	; (0000:0018=52h)
		xor	byte ptr vector_5h_seg+1,ah	; (0000:0017=0F0h)
		call	sub_82			; (A094)
loc_440:					;  xref F000:9F6B
		jmp	short loc_436		; (9F4F)

loc_ret_441:					;  xref F000:9F65
		retn
sub_70		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9D9E, 9E04, 9EA5
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_71		proc	near
		test	byte ptr vector_6h_off,8	; (0000:0018=52h)
		jz	short loc_ret_443	; Jump if zero
		cmp	al,45h			; 'E'
		je	short loc_442		; Jump if equal
		and	byte ptr vector_6h_off,0F7h	; (0000:0018=52h)
loc_442:					;  xref F000:9F84
		jmp	short loc_436		; (9F4F)

loc_ret_443:					;  xref F000:9F80
		retn
sub_71		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9DA4, 9E0A, 9F2C
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_72		proc	near
		mov	ah,al
		dec	al
		xlat cs:[bx]			; al=[al+[bx]] table
		cmp	al,0FFh
		je	loc_436			; Jump if equal
		retn
sub_72		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;

;         Called from:	 F000:9F02, 9F29
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_73		proc	near
		cmp	al,52h			; 'R'
		jne	short loc_ret_444	; Jump if not equal
		test	byte ptr vector_6h_off,80h	; (0000:0018=52h)
		jnz	loc_436			; Jump if not zero
		or	byte ptr vector_6h_off,80h	; (0000:0018=52h)
		xor	byte ptr vector_5h_seg+1,80h	; (0000:0017=0F0h)

loc_ret_444:					;  xref F000:9F9B
		retn
sub_73		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9C8C, 9F62
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_74		proc	near
		mov	ah,40h			; '@'
		cmp	al,3Ah			; ':'
		je	short loc_ret_445	; Jump if equal
		mov	ah,20h			; ' '
		cmp	al,45h			; 'E'
		je	short loc_ret_445	; Jump if equal
		mov	ah,10h
		cmp	al,46h			; 'F'

loc_ret_445:					;  xref F000:9FB3, 9FB9
		retn
sub_74		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9C7B, 9CAE, 9D02, 9D1F
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_75		proc	near
		mov	ah,8
		cmp	al,38h			; '8'
		je	short loc_ret_446	; Jump if equal
		mov	ah,4
		cmp	al,1Dh
		je	short loc_ret_446	; Jump if equal

;ﬂﬂﬂﬂ External Entry into Subroutine ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;
;         Called from:	 F000:9C87, 9CBA, 9D1A, 9D29

sub_76:
		mov	ah,2

		cmp	al,2Ah			; '*'
		je	short loc_ret_446	; Jump if equal
		mov	ah,1
		cmp	al,36h			; '6'

loc_ret_446:					;  xref F000:9FC4, 9FCA, 9FD0
		retn
sub_75		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9D63, 9E1C, 9E5A, 9EBF, 9F59, A072, A1D2
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_77		proc	near
		call	sub_79			; (9FED)
		mov	al,0AEh
		out	64h,al			; port 64h, kybd cntrlr functn
						;  al = 0AEh, enable keyboard
		sti				; Enable interrupts
		retn
sub_77		endp


;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;			       SUBROUTINE
;
;         Called from:	 F000:9BDF, A1C4
;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

sub_78		proc	near
		call	sub_79			; (9FED)
		mov	al,0ADh
		out	64h,al			; port 64h, kybd cntrlr functn
						;  al = 0ADh, disable keyboard
		call	