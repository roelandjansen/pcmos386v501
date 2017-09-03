/*
**		Control types for set_ctrl_state() and inq_ctrl_state() 
*/

#define	CLOSE_BTN		0
#define	ZOOM_BTN			1
#define	VERT_SCROLL		2
#define	HORZ_SCROLL		3
#define	VERT_THUMB		4
#define	HORZ_THUMB		5


/*
**		Control states for set_ctrl_state()
*/

#define	DISABLE_CTRL	0	
#define	ENABLE_CTRL		1
#define	HIDE_CTRL		2
#define	SHOW_CTRL		3
#define	SHOW_ZOOMED		4


/*
**		Event codes for mouse action handler.
*/

#define BTN1_MOVE			1			// kb_flags, line, col
#define BTN2_MOVE			2			// kb_flags, line, col
#define BTN3_MOVE			3			// kb_flags, line, col
#define BTN1_DOWN			4			// kb_flags, line, col
#define BTN2_DOWN			5			// kb_flags, line, col
#define BTN3_DOWN			6			// kb_flags, line, col
#define BTN1_UP			7			// kb_flags, line, col
#define BTN2_UP			8			// kb_flags, line, col
#define BTN3_UP			9			// kb_flags, line, col
#define BTN1_CLICK	  10			// kb_flags, line, col
#define BTN2_CLICK	  11			// kb_flags, line, col
#define BTN3_CLICK	  12			// kb_flags, line, col
#define BTN1_DBLCLK	  13			// kb_flags, line, col
#define BTN2_DBLCLK	  14			// kb_flags, line, col
#define BTN3_DBLCLK	  15			// kb_flags, line, col
#define HSCROLL		  16			// kb_flags, SB_*, [thumb_pos]
#define VSCROLL		  17			// kb_flags, SB_*, [thumb_pos]
#define ZOOM_WIN		  18			// kb_flags, win_id
#define CLOSE_WIN		  19			// kb_flags, win_id
#define SET_WIN		  20			// kb_flags, win_id, title|client|frame
#define STATUS_AREA	  21			// kb_flags, BTNn_a, region


/*
**		Scroll-bar event sub-codes for mouse action handler.
*/

#define SB_LINEUP				0
#define SB_LINEDOWN			1
#define SB_PAGEUP				2
#define SB_PAGEDOWN			3
#define SB_THUMBPOSITION	4
#define SB_THUMBTRACK		5
#define SB_TOP					6
#define SB_BOTTOM				7
#define SB_ENDSCROLL			8

#define SB_LEFT				SB_LINEUP
#define SB_RIGHT				SB_LINEDOWN
#define SB_PAGELEFT			SB_PAGEUP
#define SB_PAGERIGHT			SB_PAGEDOWN
#define SB_HOME				SB_TOP
#define SB_END					SB_BOTTOM

/*
**		Keyboard flags for mouse action handler.
*/

#define KB_CTRL			4
#define KB_ALT				8		  
#define KB_SHIFT	 		3

/*
**		Button 2 default actions.
*/

#define QUICK_EDIT		0
#define QUICK_MENU		1

/*
**		SET_WIN -- Client Area or Title
*/

#define CLIENT_AREA		0
#define TITLE_BAR			1
#define FRAME				2	// For pop-up windows only!

/*
**		STATUS_AREA -- Logical region
*/

#define MESSAGE_AREA		0
#define LINE_AREA			1
#define COLUMN_AREA		2
#define FLAGS_AREA		3
#define TIME_AREA			4
