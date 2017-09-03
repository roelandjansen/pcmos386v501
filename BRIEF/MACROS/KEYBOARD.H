/*
**		BRIEF -- Basic Reconfigurable Interactive Editing Facility
**
**		Written by Dave Nanian and Michael Strickman.
*/

/*
**		keyboard.h:
**
**		This macro file is included and run by startup.m to assign the BRIEF
**	commands to keys.  If you want to change any key assignments in BRIEF,
**	we recommend you do it here.	All of BRIEF's non-built-in functions
**	have their keys assigned in this file.
**
** NOTE:
**   The macro keys.cb searchs this file for assign_to_key statements.
**   If this file is changed without using the keys macro be sure to
**   add assign_to_key statements in this form:
**   assign_to_key ("<key>", "command");
*/

void keyboard ()
{
	/*
	**		The following autoload defines the default BRIEF prompt
	**	handling macro.  This macro provides a history facility as
	**	well as file name completion for a number of prompts.
	**
	**		Note that the macros defined in prompt.cb are the base
	**	level _prompt_begin, _prompt_end and _bad_key macros; they
	**	do not call down to their replacements, as no one is below
	**	them.
	*/

	autoload ("prompt", "_completion_commands",					/*vc*/
		"_complete_edit_file", "_prompt_begin", "_prompt_end",		/*vc*/
		"_bad_key", "_history_buf", "mouse_prompt");							/*vc*/

	/*
	**		The following few lines define the search and translate
	**	keyboard assignments.  The autoload statement tells BRIEF that
	**	the appropriate macros can be found in the file "search.cm".
	**
	**		The default BRIEF search keyboard is as follows:
	**
	**	Command: 			Function:							Key Sequence:
	**	-------- 			---------							-------------
	**	next_word			Move the cursor to the start	Ctrl-Right Arrow
	**							of the next word.
	**
	**	previous_word		Move the cursor to the start	Ctrl-Left Arrow
	**							of the previous word.
	**
	**	search_fwd			Searches forward for the		F5, Alt-s (replacement)
	**							given pattern.  Displays last
	**							pattern as the default.
	**
	**	search_back 		Searches backward for the		Alt-F5 (replacement)
	**							given pattern.  Displays last
	**							pattern as the default.
	**
	**	search_again		Searches in the previous		Shift-F5
	**							direction for the previous
	**							search pattern.
	**
	**	translate			Translates forward in the		F6, Alt-t (replacement)
	**							buffer.	Displays last
	**							pattern and replacement.
	**
	**	translate_back 	Translates back in the			Alt-F6
	**							buffer.	Displays last
	**							pattern and replacement.
	**
	**	translate_again	Translates the last pattern	Shift-F6
	**							and replacement in the last
	**							direction.
	**
	**	toggle_re			Toggles whether or not			Ctrl-F6
	**							regular expressions are used
	**							when searching and translating.
	**
	**	block_search		Toggles block searching.		F10 block_search
	**
	**	i_search 			Does an "incremental" search	F10 i_search
	**							forward in the buffer for the
	**							given pattern.
	**
	**	_marksrch			Marks the located search pattern.
	**							Can be replaced by the user if a
	**							different action is desired.
	*/

	autoload ("search",	"next_word", "_next_word",
								"previous_word", "_previous_word",
								".c_next_word", ".c_previous_word",
								".h_next_word", ".h_previous_word",
								".inc_next_word", ".inc_previous_word",
								".m_next_word", ".m_previous_word",
								".cb_next_word", ".cb_previous_word",
								".asm_next_word", ".asm_previous_word",
								"search_fwd", "search_back",
								"translate", "translate_back",
								"toggle_re", "block_search",
								"search_again", "translate_again",
    							"i_search", "_marksrch" );
	autoload ( "search",		"end_word", "_end_word",
								"begin_word", "_begin_word",
								".c_end_word", ".c_begin_word",
								".h_end_word", ".h_begin_word",
								".inc_end_word", ".inc_begin_word",
								".m_end_word", ".m_begin_word",
								".cb_end_word", ".cb_begin_word",
								".asm_end_word", ".asm_begin_word");

	assign_to_key ("<Ctrl-Right Arrow>", "next_word");
	assign_to_key ("<Ctrl-Left Arrow>", "previous_word");
	assign_to_key ("<Shift-F5>", "search_again");
	assign_to_key ("<Ctrl-F6>", "toggle_re");
	assign_to_key ("<Shift-F6>", "translate_again");
	assign_to_key ("<Alt-F6>", "translate_back");

	/*
	**		The following few lines define the window manipulation
	**	keyboard assignments.  The autoload statement tells BRIEF that
	**	the appropriate macros can be found in the file "windows.cm".
	**
	**		The default BRIEF window keyboard is as follows:
	**
	**	Command: 			Function:							Key Sequence:
	**	-------- 			---------							-------------
	**	change_window		Switch to the specified 		F1 (replacement)
	**							window, and display the name
	**							of the new file.
	**
	**	create_edge 		Create a new window and set	F3 (replacement)
	**							its color.
	**
	**	change_window 0	Switch to the window above 	Shift-Keypad-Up Arrow/
	**							the current one.	Display		Alt-Up Arrow (101key)
	**							the name of the new file.
	**
	**	change_window 1	Switch to the window to the	Shift-Keypad-Right Arrow/
	**							right of the current one.		Alt-Right Arrow (101key)
	**							Display the name of the new
	**							file.
	**
	**	change_window 2	Switch to the window below 	Shift-Keypad Down Arrow/
	**							the current one.	Display the Alt-Down Arrow (101key)
	**							name of the new file.
	**
	**	change_window 3	Switch to the window to the	Shift-Keypad Left Arrow/
	**							left of the current one.		Alt-Left Arrow (101key)
	**							Display the name of the new
	**							file.
	**
	**	to_top				Move the current line to the	Ctrl-t
	**							top of the window.
	**
	**	to_bottom			Move the current line to the	Ctrl-b
	**							bottom of the window, or as
	**							close as possible.
	**
	**	center_line 		Center the current line in 	Ctrl-c/
	**							window, if possible. 			Center (101key)
	**
	**	screen_up			Scroll the screen up one		Ctrl-e
	**							line, leaving the cursor on
	**							the same line, if possible.
	**
	**	screen_down 		Scroll the screen down one 	Ctrl-d
	**							line, leaving the cursor on
	**							the same line, if possible.
	**
	**	left_side			Move the cursor to the left	Shift-Keypad Home/
	**							side of the window.				Alt-Home (101key)
	**
	**	right_side			Move the cursor to the right	Shift-End/
	**							side of the window.				Alt-End (101key)
	**
	**	zoom_window			Zooms and unzooms the current	Alt-F2, Ctrl-z
	**							window.
	*/

	autoload ("windows",	"change_window", "create_edge",
								"to_top", "to_bottom", "center_line",
								"screen_up", "screen_down", "left_side",
								"right_side", "zoom_window");

	/*
	**		Normally, <Shift-Up> is the same as <Keypad-8>.  When the
	**	101key driver is loaded, <Shift-Up> refers to the dedicated
	**	cursor pad, and the BIOS doesn't transmit <Shift-Up>.  We use
	**	this fact to determine if 101key support is installed.
	*/

	if (key_to_int ("<Shift-Up>") == 0)
		{
		assign_to_key ("<Alt-Up>", "change_window 0");
		assign_to_key ("<Alt-Right>", "change_window 1");
		assign_to_key ("<Alt-Down>", "change_window 2");
		assign_to_key ("<Alt-Left>", "change_window 3");
		assign_to_key ("<Alt-Home>", "left_side");
		assign_to_key ("<Alt-End>", "right_side");
		assign_to_key ("<Center>", "center_line");
		}
	else
		{
		assign_to_key ("<Shift-Keypad Up>", "change_window 0");
		assign_to_key ("<Shift-Keypad Right>", "change_window 1");
		assign_to_key ("<Shift-Keypad Down>", "change_window 2");
		assign_to_key ("<Shift-Keypad Left>", "change_window 3");
		assign_to_key ("<Shift-Keypad Home>", "left_side");
		assign_to_key ("<Shift-Keypad End>", "right_side");
		}
	assign_to_key ("<Ctrl-t>", "to_top");
	assign_to_key ("<Ctrl-b>", "to_bottom");
	assign_to_key ("<Ctrl-c>", "center_line");
	assign_to_key ("<Ctrl-e>", "screen_up");
	assign_to_key ("<Ctrl-d>", "screen_down");
	assign_to_key ("<Alt-F2>", "zoom_window");
	assign_to_key ("<Ctrl-z>", "zoom_window");

	/*
	**		The following few lines define the standard buffer manipulation
	**	keyboard assignments.  The autoload statement tells BRIEF that the
	**	appropriate files can be found in the file "buffers.cm".
	**
	**		The default BRIEF buffer manipulation keyboard is as follows:
	**
	**	Command: 			Function:							Key Sequence:
	**	-------- 			---------							-------------
	**	buf_list 			Displays a list of buffers 	Alt-b
	**							which can be examined, edited
	**							written or deleted.
	**
	**	edit_file			Displays the name of the		Alt-e (replacement)
	**							file being edited on the
	**							command line.
	**
	**	_multifile_edit_file	Allows more than one file
	**							to be selected from the file
	**							completion menu.
	**
	**	edit_next_buffer	Switches to the next buffer	Alt-n
	**							in the buffer list.
	**
	**	edit_prev_buffer	Switches to the previous		Alt-minus
	**							buffer in the buffer list.
	**
	**	delete_curr_buffer Deletes the current buffer.	Ctrl-minus
	**
	**	_bad_key 			Adds menus to some commands.
	*/

	autoload ("buffers",	"buf_list", "edit_file", "edit_next_buffer",
								"edit_prev_buffer", "delete_curr_buffer",
								"_bad_key", "mouse_buf_list", "_buf_position" );

	assign_to_key ("<Alt-b>", "buf_list");
	assign_to_key ("<Alt-n>", "edit_next_buffer");
	assign_to_key ("<Alt-minus>", "edit_prev_buffer");
	assign_to_key ("<Ctrl-minus>", "delete_curr_buffer");

	/*
	**		These assignments are for the bookmark key definitions.	<Alt-j> is
	**	built-in.
	*/

	assign_to_key ("<Alt-1>", "drop_bookmark 1");
	assign_to_key ("<Alt-2>", "drop_bookmark 2");
	assign_to_key ("<Alt-3>", "drop_bookmark 3");
	assign_to_key ("<Alt-4>", "drop_bookmark 4");
	assign_to_key ("<Alt-5>", "drop_bookmark 5");
	assign_to_key ("<Alt-6>", "drop_bookmark 6");
	assign_to_key ("<Alt-7>", "drop_bookmark 7");
	assign_to_key ("<Alt-8>", "drop_bookmark 8");
	assign_to_key ("<Alt-9>", "drop_bookmark 9");
	assign_to_key ("<Alt-0>", "drop_bookmark 10");

	/*
	**		The following few lines define the standard file compilation
	**	keyboard assignments.  The autoload statement tells BRIEF that
	**	the appropriate macros can be found in the file "compile.cm".
	**
	**		The default BRIEF file compilation keyboard is as follows:
	**
	**	Command: 			Function:							Key Sequence:
	**	-------- 			---------							-------------
	**	compile_it			Compiles the file in the		Alt-F10
	**							current buffer, using the
	**							compiler appropriate to the
	**							file's extension.
	**
	**	warnings_only		Sets up the compilation 		None
	**							functions to handle compiles
	**							that generate only warning
	**							message, or don't return an
	**							error level.
	**
	**	bgd_compilation	Allows compilation to happen	None
	**							in the background.
	*/

	autoload ("compile", "compile_it", "cc", "cm", "warnings_only", "bgd_compilation");

	assign_to_key ("<Alt-F10>", "compile_it");

	/*
	**		The following few lines define the standard error location
	**	keyboard assignments.  The autoload statement tells BRIEF that
	**	the appropriate macros can be found in the file "errorfix.cm".
	**
	**		The default BRIEF file compilation keyboard is as follows:
	**
	**	Command: 			Function:							Key Sequence:
	**	-------- 			---------							-------------
	**	next_error			Goes to the next error for 	Ctrl-n
	**							the current file, if any.
	**
	**	next_error 1		Displays a window of error 	Ctrl-p
	**							messages, if any.
	*/

	autoload ("errorfix",	"next_error", "_next_error",
									"_previous_error", "_error_info",
									"mouse_errorfix");

	assign_to_key ("<Ctrl-n>", "next_error");
	assign_to_key ("<Ctrl-p>", "next_error 1");

	/*
	**		The following few lines define a number of miscellaneous
	**	keyboard assignments.  The autoload statement tells BRIEF that
	**	the appropriate macros can be found in the file "misc.cm".	Note
	**	that this macro is included in the file "startup.m".
	**
	**		The default BRIEF assignments for these commands are:
	**
	**	Command: 			Function:							Key Sequence:
	**	-------- 			---------							-------------
	**	delete_char 		Do a block-sensitive delete.	Del (replacement)
	**
	**	delete_previous_word 									Ctrl-Backspace
	**							Deletes the word in front of
	**							the cursor.
	**
	**	delete_next_word	Deletes the word after the		Alt-backspace
	**							cursor.								(101key driver only)
	**
	**	delete_to_bol		Deletes to the beginning of	Ctrl-k
	**							the line.
	**
	**	write_buffer		Do a block-sensitive write.	Alt-w (replacement)
	**
	**	write_and_exit		Write all modified buffers		Ctrl-x
	**							and exit BRIEF (same as
	**							Alt-x w).
	**
	**	set_backup			Toggle whether backups should Ctrl-w
	**							be created.  Assigned here,
	**							function is built-in.
	**
	**	display_file_name Display the file name of the	Alt-f
	**							current buffer.
	**
	**	load_keystroke_macro	Loads a keystroke macro.	Alt-F7
	**
	**	open_line			Open up a new line under the	Ctrl-Enter
	**							current one.
	**
	**	back_tab 			Moves to the previous tab		Shift-Tab
	**							stop.
	**
	**	quote 				Allows keys bound to command	Alt-q
	**							to be inserted.
	**
	**	copy					Does a block-sensitive copy.	Grey-plus (replacement)
	**
	**	cut					Does a block-sensitive cut.	Grey-minus (replacement)
	**
	**	_home 				Does a multi-keystroke home.	Home
	**
	**	_end					Does a multi-keystroke end.	End
	*/

	assign_to_key ("<Ctrl-Backspace>", "delete_previous_word");
	assign_to_key ("<Alt-Backspace>", "delete_next_word");
	assign_to_key ("<Ctrl-k>", "delete_to_bol");
	assign_to_key ("<Ctrl-x>", "write_and_exit");
	assign_to_key ("<Ctrl-w>", "set_backup");
	assign_to_key ("<Alt-f>", "display_file_name");
	assign_to_key ("<Alt-F7>", "load_keystroke_macro");
	assign_to_key ("<Ctrl-Enter>", "open_line");
	assign_to_key ("<Shift-Tab>", "back_tab");
	assign_to_key ("<Alt-q>", "quote");
	assign_to_key ("<Home>", "_home");
	assign_to_key ("<End>", "_end");

	/*
	**		The following few lines define the keys needed to perform
	**	the BRIEF help function.  The autoload statement tells BRIEF that
	**	the appropriate macros can be found in the file "help.cm".
	**
	**		In addition, registered macro type 2 (context sensitive help)
	**	is set up here.
	**
	**		The default BRIEF help keyboard is as follows:
	**
	**	Command: 			Function:							Key Sequence:
	**	-------- 			---------							-------------
	**	help					Help out the user!				Alt-h
	*/

	autoload ("help",	"help", "_context_help", "_help_add_button",
							"_user_kbd", "display_help", "process_help_menu",
							"mouse_help_menu", "mouse_help");

	register_macro (2, "_context_help"); 		//	"Assigned" to Alt-h
															//	when prompting.

	assign_to_key ("<Alt-h>", "help");

	/*
	**		The following few lines define some keys that are not used
	**	very often.  The autoload statements tell BRIEF where it can
	**	find the files that the commands are in.
	**
	**		The default BRIEF assignments for these commands are:
	**
	**	Command: 			Function:							Key Sequence:
	**	-------- 			---------							-------------
	**	repeat				Repeat the next command.		Ctrl-r
	**
	**	key					Give me the correct key code	Shift-F10
	**							for the key sequence.
	**
	**	routines 			Present a menu containing all Ctrl-g
	**							of the routines in this file,
	**							and allow me to go to one of
	**							them.
	*/

	autoload ("repeat", "repeat");
	autoload ("key", "key");
	autoload ("routines", "routines");

	assign_to_key ("<Ctrl-r>", "repeat");
	assign_to_key ("<Shift-F10>", "key");
	assign_to_key ("<Ctrl-g>", "routines");

 	/*
	**		These are general autoloads for the various BRIEF macro
	**	packages.
	*/

	autoload ("autosave", "autosave");

	autoload ("indent",	".c_smart_first", ".c_template_first",
								"_regular_first", "r_indent", "slide_in",
								".cb_smart_first", ".cb_template_first",
								"slide_out", ".c_abbrev", "brace_expand",
								"just_brace", "just_cbrace", "just_space",
								".c_open_brace", ".c_close_brace");

	autoload ("wp", "_wp_on", "_wp_off", "center", "reform", "margin");

	autoload ("dialog",	"_process_menu", "_process_dialog_box", "_dialog_level",
								"_dialog_mode", "_dialog_esc", "_dialog_grey_minus",
								"_dialog_dir");

	autoload ("column", "_col_copy", "_col_cut", "_col_delete", "_col_paste");

	autoload ("ada", ".ada_smart_first", ".ada_template_first");

	autoload ("basic",".bas_smart_first", ".bas_template_first");

	autoload ("cobol", ".cob_smart_first",	".cob_template_first");

	autoload ("fortran",	".for_smart_first", ".for_template_first");

	autoload ("modula2",	".mod_smart_first", ".def_smart_first", ".mod_template_first",
					".def_template_first");

	autoload ("pascal", ".pas_smart_first", ".pas_template_first");

	autoload ("popup", "popup_menu", "process_popup_menu");

#include "vc_key.h"		// include Sourcer's Apprentice autoloads
}
