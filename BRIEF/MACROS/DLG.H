/*
**		BRIEF -- Basic Reconfigurable Interactive Editing Facility
**
**
**		dlg.h:
**
**		This file contains the #defines used by the dialog manager, function
**	prototypes for all of the dialog manager's support functions and the
** names of the dialog manager's 'private' global variables.
*/


#define CONTROL_TYPES	"FLINTSCRPGE"
#define FIND_CONTROL		"<[ \t]@\\c[FLINSCRP]"
#define FIND_ANY			"<[ \t]@\\c[FLINTSCRPGE]"
#define FIND_RADIO		"<[ \t]@\\c[RE]"
#define FIND_NEXT			"<[ \t]@\\c[FLINSCPG]"
#define FIND_PREV			"<[ \t]@\\c[FLINSCPE]"

/*
**		The following are for searching in the Radiobutton management file.
*/

#define FIND_RADIO_POS	"<*\"*\"(%d,%d)"
#define FIND_RADIO_LBL	"<%s\"%s\"*%c>"
#define FIND_RADIO_GRP	"<%s\"*\x07>"


#define RADIO_ON			0x07				// Radio-button "On" character
#define RADIO_OFF			0x20				// Radio-button "Off" character
#define RADIO_BTN			"(%c) %s"		// Radio-button graphic template
#define RADIO_ON_STR    ""				// Radio-button "on: character - string version
#define RADIO_OFF_STR   " "				// Radio-button "off" character - string version
#define RADIO_RIGHT		")"				// right delimiter for a radio button

#define CHECK_BOX			"[ ]"
#define CHECK_RGT_SRCH	"]"
#define CHECK_LFT_SRCH	"["				// Unused?

#define CHECKMARK			"û"
#define NOCHECKMARK		" "
#define PUSH_SRCH       "[<®]?*[¯>]"
#define PUSH_RGT_SRCH	"[¯>]"

#define PUSH_SEL_LFT		"®"				// Unused?
#define PUSH_SEL_RGT		"¯"				// Unused?

#define PUSH_NML_LFT		"<"				// Unused?
#define PUSH_NML_RGT		">"				// Unused?
#define PUSH_BUTTON		"< %s >"
#define PUSH_BUTTON_DEF "® %s ¯"

#define BTN_SRCH_STRN	"<[\t ]@%c*(\\c[\t 0-9]+,[\t 0-9]+)*\"%s\"*%s"


int _dialog_exit ();
int _dialog_menu_down ();
int _dialog_menu_up ();
int _dialog_validate (string value);
int _dlg_goto_btn (int btn_type, string button_label, ~string group);
int _menu_highlight ();
int at_eol ();
int is_filename (string name);
replacement void _invalid_key ();
string _dialog_set_globals ();
string _dlg_check_btn ();
string _dlg_push_btn ();
string _dlg_radio_btn ();
string _dlg_radio_grp (void);
string _field_contents ();
string _list_button ();
string _menu_button ();
void _dialog_end ();
void _dialog_enter ();
void _dialog_home ();
void _dialog_menu_end ();
void _dialog_menu_home ();
void _dialog_menu_pgdn ();
void _dialog_menu_pgup ();
void _dialog_menu_pick ();
void _dialog_next ();
void _dialog_next_and_save ();
void _dialog_prev ();
void _dlg_beep (void);
void _dlg_btn_next (void);
void _dlg_btn_prev (void);
void _dlg_btn_tab_next (void);
void _dlg_btn_tab_prev (void);
void _dlg_goto_radio_ctrl (void);
void _dlg_pick_btn (void);
void _dlg_select_push (string button_label, int select);
void _field_bksp ();
void _field_del ();
void _field_del_line (void);
void _field_delete_to_eol (void);
void _field_end ();
void _field_home ();
void _field_insert (int key);
void _field_left ();
void _field_right ();
void _format_dialog ();
void _format_menu ();
void _list_end ();
void _list_go (int key);
void _list_highlight ();
void _list_home ();
void _list_next ();
void _list_prev ();
void _menu_go (int key);
void _remove_dialog_manager (void);
void mou_dlg_mnu_init ();
void mou_mnu_goto ();
void mou_dlg_goto (int ctrl_line);
void mou_mnu_dwn ();
void mou_mnu_up ();
void mou_dlg_exit ();


/*
**		External functions.
*/

extern mouse_dialog_init ();
extern void wait ();
extern void _exit ();
extern string search_path (string path, string filename);
extern void to_bottom (void);
extern void center_line (void);


#ifndef DIALOG_MAIN
	extern int		_dialog_field_keymap;
	extern int		_dialog_list_keymap;
	extern int		_dialog_menu_keymap;
	extern int		_dialog_button_keymap;
	extern int		_dialog_size;
	extern int		_dialog_data_buf;
	extern int		_dialog_disp_buf;
	extern int		_dialog_radio_buf;
	extern int		_dialog_menu_time;
	extern int		_dialog_picked;
	extern int 		_dialog_pb_state;

	extern string	_dialog_action_func;
	extern string	_dialog_menu_prefix;
	extern string	_dialog_default_pb;
#endif
