/*
**		Symbolic constants
*/

#define	TRUE						1
#define	FALSE						0

/*
**		Dialog manager modes
*/

#define	DIALOG_MENU_MODE		1
#define	DIALOG_DBOX_MODE		2

/*
**		Field types (use the mnemonic "FLINTSCRP")
*/

#define	FILENAME					1
#define	LIST						2
#define	INTEGER					3
#define	NONBLANK					4
#define	TEXT						5
#define	STRING					6
#define	CHECK						7
#define	RADIO						8
#define	PUSH						9
#define	GROUP						10
#define	ENDGROUP					11

/*
**		Event types for both dialog boxes and menus
*/

#define	DIALOG_INIT				-1
#define	DIALOG_ENTER_FIELD	-2
#define	DIALOG_ENTER_LIST		-3
#define	DIALOG_ALTER_LIST		-4
#define	DIALOG_ALTER_MENU		-5
#define	DIALOG_MOVE_MENU		-5
#define	DIALOG_PICK_MENU		-6
#define	DIALOG_EXIT_FIELD		-7
#define	DIALOG_EXIT_LIST		-8
#define	DIALOG_TERM				-9
#define	DIALOG_ESCAPE			-10
#define	DIALOG_F10				-11
#define	DIALOG_GREY_MINUS		-12
#define	DIALOG_CREATE_MENU	-13
#define	DIALOG_CREATE_DBOX	-14
#define	DIALOG_ENTER_CHECK	-15
#define	DIALOG_PICK_CHECK		-16
#define	DIALOG_EXIT_CHECK		-17
#define	DIALOG_ENTER_RADIO	-18
#define	DIALOG_PICK_RADIO		-19
#define	DIALOG_EXIT_RADIO		-20
#define	DIALOG_ENTER_PUSH		-21
#define	DIALOG_PICK_PUSH		-22
#define	DIALOG_EXIT_PUSH		-23
/*
#define	DIALOG_ENTER_GROUP	???
#define	DIALOG_EXIT_GROUP		???
*/

/*
**		External macro and global variable declarations
*/

int _process_menu (int lx, int by, int rx, int ty, string title,
					string msg, ~string filename, ~int buf_id,
					string action, ~int fast, ~int picked_line,
					~string picked_text);

int _process_dialog_box (int lx, int by, int rx, int ty, string title,
					string msg, ~string filename, ~int buf_id,
					string action);

void _dialog_esc (void);
void _dialog_grey_minus (void);
void _dialog_f10 (void);
void _dialog_check_button (string button, int check);
int _dialog_is_checked (string button);
void _dialog_check_radio (string button, ~string group);
string _dialog_radio_checked (~string group);

#ifndef DIALOG_MAIN
	extern string	_dialog_dir;

	extern int		_dialog_level,
						_dialog_type,
						_dialog_row,
						_dialog_col,
						_dialog_mode;
#endif
