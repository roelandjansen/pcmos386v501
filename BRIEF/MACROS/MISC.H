/*
**		BRIEF -- Basic Reconfigurable Interactive Editing Facility
**
**		Written by Dave Nanian and Michael Strickman.
*/

/*
**		misc.h:
**
**		This file contains a number of miscellaneous BRIEF functions.
*/

#define REG_MARK	  1
#define COL_MARK	  2
#define LINE_MARK   3
#define NI_MARK	  4

#define NOTHING	  0
#define REPLACE	  1
#define REMOVE 	  2

string add_to_path (string path, string name);
void _col_cut (~int append);
void _col_copy (~int append);
void _col_paste ();
void _col_delete ();
int next_word ();
int previous_word ();

int	_dir,					//	Direction of last search.
		_t_dir, 				//	Direction of last translate.
		_reg_exp,			//	Use regular expressions?
		_block_search,		//	Restrict search to blocks?
		_check_warnings, 	//	Recognize warning-only compiles?
		_background,		//	Perform compilations in the background?
		_package_buf;		//	Parsed language package information.

string	_s_pat, 			//	Value of last search pattern.
			_t_pat, 			//	Value of last translate pattern.
			_r_pat; 			//	Value of last replacement pattern.

/*
**		_init:
**
**		This macro defines the global variables used by the various BRIEF
**	packages that may be restored by the restore macro.  Placing the
**	variables here ensures the macro isn't autoloaded when its variables
**	are referenced.
*/

void _init ()
{
	_reg_exp = _dir = _t_dir = 1;
}

/*
**		delete_char:
**
**		This macro implements block-sensitive delete.
*/

replacement delete_char ()
{
	int	block_type;

	if (inq_called () != "" || !(block_type = inq_marked ()))
		return (delete_char ());
	else if (block_type == COL_MARK)
		_col_delete ();
	else
		{
		int	old_msg_level = inq_msg_level ();

		set_msg_level (0);
		delete_block ();
		set_msg_level (old_msg_level);
		}
}

/*
**		delete_next_word, delete_previous_word:
**
**		These functions use the language-sensitive next_word and previous_word
**	functions to perform word deletion.
*/

int delete_next_word ()
{
	int	line;

	string	line_end = trim (read ());

	save_position ();
	drop_anchor (4);
	inq_position (line);

	if (next_word ())
		{
		int	after_line;

		inq_position (after_line);

		if (after_line != line && line_end != "")
			{
			restore_position ();
			raise_anchor ();
			delete_to_eol ();
			return (1);
			}
		else if (inq_marked ())
			{
			delete_block ();
			return (1);
			}
		}
	restore_position ();
	raise_anchor ();
	returns (0);
}

int delete_previous_word ()
{
	save_position ();
	drop_anchor (4);

	if (previous_word () && inq_marked ())
		{
		delete_block ();
		restore_position (0);
		returns (1);
		}
	else
		{
		restore_position ();
		raise_anchor ();
		returns (0);
		}
}

/*
**		delete_to_bol:
**
**		This routine deletes to the beginning of the line.
*/

int delete_to_bol (void)
{
	drop_anchor (4);

	if (beginning_of_line ())
		{
		delete_block ();
		returns (1);
		}
	else
		{
		raise_anchor ();
		returns (0);
		}
}

/*
**		write_buffer:
**
**		This replacement macro decides what to do when Alt-w is pressed.
**	If a block is marked, then the "write_block" primitive is called.
**	Otherwise, write_buffer is called to write out the entire buffer.
*/

replacement int write_buffer (...)
{
	if (inq_called () != "")
		return (write_buffer ());
	else
		{
		int	old_msg_level = inq_msg_level (),
				ret_code;

		set_msg_level (0);

		if (inq_marked ())
			ret_code = write_block ();
		else
			ret_code = write_buffer ();

		set_msg_level (old_msg_level);
		return (ret_code);
		}
}

/*
**		write_and_exit:
**
**		This command writes all buffers and exits BRIEF.
*/

void write_and_exit (void)
{
	/*
	**		We set the message level to ensure that the informational
	**	messages displayed by exit ("w") can be read by the user.
	*/

	set_msg_level (0);
	exit ("w");
}

/*
**		load_keystroke_macro:
**
**		This routine acts as a front-end to the playback function, prompting
**	for the name of the keystrke macro to load.
*/

int load_keystroke_macro (~string)
{
	int	ret_code,
			old_msg_level = set_msg_level (0);

	string	file_name;

	if (inq_keystroke_macro ())
		ret_code = playback ();
	else if ((ret_code = get_parm (0, file_name, "Keystroke macro file: ")) > 0)
		if (file_name != "")
			ret_code = playback (file_name, NULL, 0);

	set_msg_level (old_msg_level);
	returns (ret_code);
}

/*
**		save_keystroke_macro:
**
**		This replacement for the base save_keystroke_macro displays the path
**	that the macro is going to be saved to.  Rather than save to the current
**	directory as the built-in version does, the replacement cycles through
**	the BPATH.
*/

replacement int save_keystroke_macro (~string)
{
	if (inq_called () != "")
		returns (save_keystroke_macro ());
	else
		{
		int	old_msg_level = set_msg_level (0),
				num_keys,
				ret_code;

		/*
		**		First, we determine whether or not we should bother prompting.
		**	The normal save_keystroke_macro command won't even bother prompting
		**	if we're remembering, playing back, or if there's no macro.  We do
		**	the same, but let the base function display the error message.
		*/

		if (inq_keystroke_macro (num_keys) || num_keys == 0)
			ret_code = save_keystroke_macro ();
		else
			{
			string	prompt,
						bpath,
						file_name,
						curr_dir;

			int	start_loc = 1,
					loc,
					len,
					max_width;

			/*
			**		Here, we display a prompt that should help people save
			**	keystroke macros.  We loop through the BPATH environment
			**	variable, displaying the next directory every time <Enter>
			**	is pressed on a blank line.  This directory is the "base"
			**	directory to save to.
			*/

			inq_screen_size (NULL, max_width);
			max_width -= 32 + 23 + 4;

			if ((bpath = trim (ltrim (compress (inq_environment ("BPATH"))))) == "")
				bpath = ";/brief/macros";

			do
				{
				if (loc = index (substr (bpath, start_loc), ";"))
					{
					curr_dir = trim (ltrim (substr (substr (bpath, start_loc), 1, loc - 1)));
					start_loc += loc;
					}
				else
					{
					curr_dir = trim (ltrim (substr (bpath, start_loc)));
					start_loc = 1;
					}
				if (curr_dir == "" || curr_dir == ".")
					getwd ("", curr_dir);

				if ((len = strlen (curr_dir)) <= max_width)
					sprintf (prompt, "Save keystrokes as [%s]: ", curr_dir);
				else
					{
					int	over = len - max_width,
							mid = len / 2;

					sprintf (prompt, "Save keystrokes as [%s...%s]: ",
											substr (curr_dir, 1, mid - (over / 2) - 3 - (over % 2)),
											substr (curr_dir, mid + (over / 2) + 1));
					}
				}
			while ((ret_code = get_parm (0, file_name, prompt)) && !strlen (file_name));

			/*
			**		At this point, we take the "base" directory (from the BPATH)
			**	and the file name that the user specified, and put them together
			**	in an intelligent way.  If a drive letter is specified, or if
			**	the path specified is absolute, we ignore the base and just use
			**	what the user specified.
			*/

			if (ret_code > 0)
				if (index (file_name, ":") || index ("/\\", substr (file_name, 1, 1)))
					ret_code = save_keystroke_macro (file_name);
				else
					ret_code = save_keystroke_macro (add_to_path (curr_dir, file_name));
			}
		returns (ret_code);
		}
}

/*
**		display_file_name:
**
**		Displays the current buffer's file name on the status line.  If the
**	name is too large, as much of the end as will fit is displayed, with an
**	ellipsis in the middle.
*/

void display_file_name ()
{
#define FILE_PROMPT  "File: "

	string	file_name;

	int	len,
			max_width;

	inq_names (file_name, NULL);
	inq_screen_size (NULL, max_width);

	if (inq_modified ())
		file_name += "*";

	len = strlen (file_name) + strlen( FILE_PROMPT );	// Length of string

	if ( len <= max_width)
		message ("%s%s", FILE_PROMPT, file_name);
	else
		{
		int	over = len - max_width,
				mid = len / 2;

		message ("%s%s...%s", FILE_PROMPT,
					substr (file_name, 1, mid - (over / 2) - 3 - (over % 2)),
					substr (file_name, mid + (over / 2) + 1));
		}
}

/*
**		open_line:
**
**		Adds a blank line after the current line, placing the cursor on the
**	first column of the new line.  The normal macro for the Enter key is
**	used to perform the function after the end of line.
*/

void open_line ()
{
	end_of_line ();

	if (inq_assignment ("<Enter>") == "self_insert" || inq_assignment ("<Enter>") == "open_line")
		insert ("\n");
	else
		execute_macro (inq_assignment ("<Enter>"));
}

/*
**		back_tab:
**
**		Moves back to the previous tab stop.  Deals with the appropriate
**	special cases as well.
*/

void back_tab ()
{
	int	col,
			start_col,
			start_dist = distance_to_tab ();

	inq_position (NULL, start_col);

	/*
	**		If we were on a tab stop to start with, we back up two
	**	characters.  Otherwise, just one.
	*/

	move_rel (0, -1);

	if (distance_to_tab () < start_dist)
		move_rel (0, -1);

	while (distance_to_tab () != 1 && move_rel (0, -1));

	/*
	**		If the last place we were was the first column, we just stay
	**	there.  Also, if there were any one space tabs, we know that
	**	we should not move back to the original tab stop.
	*/

	inq_position (NULL, col);

	if (col != 1 && start_col - col != 1)
		move_rel (0, 1);
}

/*
**		quote:
**
**		This macro inserts the next character from the keyboard as-is.
**	Non-ASCII keys, such as the Alt keys, are pushed back and executed
**	as commands.
*/

void quote ()
{
	int	value;

	while ((value = read_char ()) == -1);

	if (value & 0xff && ((value & 0xff) <= 127 || !(value & 0xff00)))
		insert ("%c", value);
	else
		push_back (value);
}

/*
**		copy:
**
**		This macro checks to see if a block is marked when the "copy" key
**	is pressed.  If so, the block is copied.	If not, a single line is
**	copied.
*/

replacement int copy (~int)
{
	if (inq_called () != "")
		returns (copy ());
	else
		{
		int	block_type;

		if (block_type = inq_marked ())
			{
			if (block_type == COL_MARK)
				{
				int	append;

				get_parm (0, append);
				_col_copy (append);
				}
			else
				{
				int	old_msg_level = inq_msg_level ();

				set_msg_level (0);
				copy ();
				set_msg_level (old_msg_level);
				}
			}
		else
			{
			drop_anchor (LINE_MARK);
			copy ();
			message ("Line copied to scrap.");
			}
		}
}

/*
**		cut:
**
**		This macro checks to see if a block is marked when the "cut" key
**	is pressed.  If so, the block is cut.	If not, a single line is cut.
*/

replacement int cut (~int)
{
	if (inq_called () != "")
		returns (cut ());
	else
		{
		int	block_type;

		if (block_type = inq_marked ())
			{
			if (block_type == COL_MARK)
				{
				int	append;

				get_parm (0, append);
				_col_cut (append);
				}
			else
				{
				int	old_msg_level = inq_msg_level ();

				set_msg_level (0);
				cut ();
				set_msg_level (old_msg_level);
				}
			}
		else
			{
			drop_anchor (LINE_MARK);
			cut ();
			message ("Line cut to scrap.");
			}
		}
}

/*
**		paste:
**
**		This replacement macro checks to see if the current scrap is a column
**	scrap buffer.	If so, it calls the _col_paste routine.
*/

replacement int paste ()
{
	if (inq_called () != "")
		returns (paste ());
	else
		{
		int	scrap_type;

		inq_scrap (NULL, scrap_type);

		if (scrap_type == COL_MARK)
			_col_paste ();
		else
			{
			int	old_msg_level = inq_msg_level ();

			set_msg_level (0);
			paste ();
			set_msg_level (old_msg_level);
			}
		}
}

/*
**		_home/new_home:
**
**		These two macros implement "triple-click" Home logic:
**
**		The first time Home is pressed, it moves to the beginning of the
**	line.
**
**		The second time Home is pressed, it moves to the top of the screen.
**
**		The third time Home is pressed, it moves to the top of the file.
**
**		If any keys are pressed in between presses of Home, this sequence
**	starts back at the beginning.
*/

void _home ()
{
	global int	_new_home;

	if (inq_command () != "new_home")
		{
		_new_home = 0;
		beginning_of_line ();
		assign_to_key ("<Home>", "new_home");
		push_back (key_to_int ("<Home>"));
		}
	else if (++_new_home == 1)
		top_of_window ();
	else
		{
		top_of_buffer ();
		set_top_left (1, 1);
		}
}

void new_home ()
{
	assign_to_key ("<Home>", "_home");
}

/*
**		_end/new_end:
**
**		These two macros implement "triple-click" End logic:
**
**		The first time End is pressed, it moves to the end of the line.
**
**		The second time End is pressed, it moves to the end of the last line
**	on the screen.
**
**		The third time End is pressed, it moves to the end of the file.
**
**		If any keys are pressed in between presses of End, this sequence
**	starts back at the beginning.
*/

void _end ()
{
	global int	_new_end;

	if (inq_command () != "new_end")
		{
		_new_end = 0;
		end_of_line ();
		assign_to_key ("<End>", "new_end");
		push_back (key_to_int ("<End>"));
		}
	else
		{
		int	col,
				win_cols,
				shift;

		inq_window_size (NULL, win_cols, shift);

		if (++_new_end == 1)
			{
			end_of_window ();
			end_of_line ();
			}
		else
			end_of_buffer ();

		inq_position (NULL, col);

		if (shift && col <= win_cols)
			{
			beginning_of_line ();
			refresh ();
			end_of_line ();
			}
		else if (_new_end == 1)
			refresh ();
		}
}

void new_end ()
{
	assign_to_key ("<End>", "_end");
}

/*
**		add_to_path:
**
**		This simple routine adds a filename to a path and returns the
**	result.
*/

string add_to_path (string path, string name)
{
	if (strlen (path) && !index ("/\\:", substr (path, strlen (path))))
		path += "/";

	path += name;
	returns (path);
}

/*
**		escape_re:
**
**		This function changes a string with regular expression characters in
**	it to one without, and returns the result.  Optionally, a different group
**	of "regular expression" characters can be passed.
*/

string escape_re (string original, ~string)
{
	int	curr_pos,
			original_len;

	string	bad_chars,
				escaped,
				curr_char;

	if (!get_parm (1, bad_chars))
		bad_chars = "?*@+\\|%${}[]<>";

	original_len = strlen (original);

	while (original_len--)
		escaped += (index (bad_chars, curr_char = substr (original, ++curr_pos, 1)) ? "\\" : "") + curr_char;

	returns (escaped);
}

/*
**		search_path:
**
**		This routine searches a path, such as the PATH or BPATH environment
**	variable, for the specified file.  It returns the null string if the
**	file wasn't found, or the full path name if it was.
*/

string search_path (string path, string filename)
{
	int	semi_loc;

	string	curr_name;

	/*
	**		Get the directory list to check and append a semicolon to it.
	**	This means we will always check the current directory last
	**	unless we are told to check it sooner.
	*/

	path += ";";

	/*
	**		Search all the directories for the given file name.  As soon
	**	as we find the file, append the name of the file to the
	**	given directory and return the full name.
	*/

	while (semi_loc = index (path, ";"))
		{
		curr_name = add_to_path (substr (path, 1, semi_loc - 1), filename);

		/*
		**		If the file exists in the given directory, we return
		**	the full name without bothering to parse anything else.
		*/

		if (exist (curr_name))
			return (curr_name);

		path = substr (path, semi_loc + 1);
		}
	returns ("");
}

/*
**		gen_block:
**
**		This routine goes through the current block and passes the information
**	from the block to a given routine.	That routine performs an operation
**	on the string, and then tells gen_block to replace, remove or ignore the
**	data.
**
**		Note that no line boundaries are ever removed by this routine.  Also,
**	the anchor is left as is.
*/

void gen_block (string macro_name, string msg)
{
	string	before,
				after;

	int	start_line,
			start_col,
			end_line,
			end_col,
			curr_line,
			num_lines,
			num_chars,
			do_upper,
			lines_per_step,
			curr_step,
			scale_factor,
			type,
			action;

	message (msg + "...");
	save_position ();

	if (!inq_marked ())
		mark (LINE_MARK);

	type = inq_marked (start_line, start_col, end_line, end_col);
	num_lines = (end_line - start_line) + 1;
	curr_line = start_line;

	if (above (num_lines, 100))
		{
		if (above (num_lines, 32767))
			scale_factor = 1;
		else
			scale_factor = 32767 / num_lines;

		lines_per_step = num_lines / 100;
		}
	else
		{
		scale_factor = 100;
		lines_per_step = 1;
		}
	move_abs (start_line, start_col);

	while (below_eq (curr_line, end_line))
		{
		save_position ();
		drop_anchor ();
		move_abs (0, curr_line == end_line || type == COL_MARK ? end_col : 2 * inq_line_length ());
		num_chars = inq_mark_size ();
		raise_anchor ();
		restore_position ();
		after = before = read (num_chars);

		action = execute_macro (macro_name, after);

		if (action == REMOVE || after != before)
			{
			int	test1_col,
					test2_col;

			inq_position (NULL, test1_col);

			if (action == REPLACE && prev_char ())
				{
				next_char ();
				inq_position (NULL, test2_col);

				if (test2_col > test1_col)
					prev_char ();
				}
			if (index (after, "\n"))
				{
				after = substr (after, 1, strlen (after) - 1);
				delete_to_eol ();
				}
			else
				{
				drop_anchor ();
				move_abs (0, end_col);
				delete_block ();
				}
			if (action == REPLACE)
				insert (after);
			}
		move_abs (++curr_line, type == COL_MARK ? start_col : 1);

		if (++curr_step == lines_per_step)
			{
			curr_step = 0;
			message ("%s, %d%% complete...", msg, (100 * (((curr_line - start_line) * scale_factor) / num_lines)) / scale_factor);
			}
		}
	restore_position ();
}

void toupper ()
{
	gen_block ("_do_upper", "Uppercasing block");
	raise_anchor ();
	message ("Uppercasing complete.");
}

int _do_upper (string line)
{
	put_parm (0, upper (line));
	returns (REPLACE);
}

void tolower ()
{
	gen_block ("_do_lower", "Lowercasing block");
	raise_anchor ();
	message ("Lowercasing complete.");
}

int _do_lower (string line)
{
	put_parm (0, lower (line));
	returns (REPLACE);
}
