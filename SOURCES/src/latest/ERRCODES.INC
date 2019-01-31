comment ^==============================================================

mjs 12/16/91	dlg mods: converted message format to d5 style.

======================================================================^

; standard error codes.

error_invalid_function		equ	1
error_file_not_found		equ	2
error_path_not_found		equ	3
error_too_many_open_files	equ	4
error_access_denied		equ	5
error_invalid_handle		equ	6
error_arena_trashed		equ	7
error_not_enough_memory		equ	8
error_invalid_block		equ	9
error_bad_environment		equ	10
error_bad_format		equ	11
error_invalid_access		equ	12
error_invalid_data		equ	13

error_invalid_drive		equ	15
error_current_directory		equ	16
error_not_same_device		equ	17
error_no_more_files		equ	18
error_write_protect		equ	19
error_bad_unit			equ	20	
error_not_ready			equ	21
error_bad_command		equ	22
error_crc			equ	23
error_bad_length		equ	24
error_seek			equ	25
error_not_dos_disk		equ	26
error_sector_not_found		equ	27
error_out_of_paper		equ	28
error_write_fault		equ	29
error_read_fault		equ	30
error_gen_failure		equ	31
error_sharing_violation		equ	32
error_lock_violation		equ	33
error_wrong_disk		equ	34
error_fcb_unavailable		equ	35
error_sharing_buffer_exceeded	equ     36

error_not_supported		equ	50
error_rem_not_list		equ	51
error_dup_name			equ	52
error_bad_netpath		equ	53
error_network_busy		equ	54
error_dev_not_exist		equ	55
error_too_many_cmds		equ	56
error_adap_hdw_err		equ	57
error_bad_net_resp		equ	58
error_unexp_net_error		equ	59
error_bad_rem_adap		equ	60
error_printq_full		equ	61
error_no_spool_space		equ	62
error_print_cancelled		equ	63
error_netname_deleted		equ	64
error_network_access_denied	equ	65
error_bad_dev_type		equ	66
error_bad_net_name		equ	67
error_too_many_names		equ	68
error_too_many_sess		equ	69
error_sharing_paused		equ	70
error_req_not_accep		equ	71
error_redir_paused		equ	72

error_file_exists		equ	80
error_dup_fcb			equ	81
error_cannot_make		equ	82
error_fail_i24			equ	83
error_out_of_structures		equ	84
error_already_assigned		equ	85
error_invalid_password		equ	86
error_invalid_parameter		equ	87
error_net_write_fault		equ	88


; extended error codes.

; error types

errclass_outres			equ	1
errclass_tempsit		equ	2
errclass_auth			equ	3
errclass_intrn			equ	4
errclass_hrdfail		equ	5
errclass_sysfail		equ	6
errclass_apperr			equ	7
errclass_notfnd			equ	8
errclass_badfmt			equ	9
errclass_locked			equ	10
errclass_media			equ	11
errclass_already		equ	12
errclass_unk			equ	13

; suggested action codes.

erract_retry			equ	1
erract_dlyret			equ	2
erract_user			equ	3
erract_abort			equ	4
erract_panic			equ	5
erract_ignore			equ	6
erract_intret			equ	7

; location codes.

errloc_unk			equ	1
errloc_disk			equ	2
errloc_net			equ	3
errloc_serdev			equ	4
errloc_mem			equ	5









