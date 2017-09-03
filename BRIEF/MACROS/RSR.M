;**	_init macro.
;**	Do not change this macro (always overwritten by Setup).
(macro _init
	(
		(extern	autosave				;**	External macro declarations
					toggle_re
		)
		(color 1 7 15 7 15 0x80)	;**	Set the screen colors
		(set_mouse_type 2 0)			;**	Set number of mouse buttons, button one location
		(set_ctrl_state 0 1)			;**	Enable close button
		(set_ctrl_state 1 1)			;**	Enable zoom button
		(set_ctrl_state 2 1)			;**	Enable vertical scroll bar
		(set_ctrl_state 3 1)			;**	Enable horizontal scroll bar
		(set_mouse_action "_mouse_action")	;**	Set mouse action macro
		(set_btn2_action 1)			;**	Set default action for mouse button two
	)
)

;**	Initials macro.
;**	Use this macro for additional customization.
(macro RSR
	(
		;**	Put your changes here.
		(return)
	)
)


;**	File Extension Macros, etc.
;**	Macros marked "Overwritable" may be overwritten by SETUP.


;**	Overwritable by Setup
(macro default
	(
		(tabs 9 17)
	)
)
