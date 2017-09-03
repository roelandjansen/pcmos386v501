program help;
uses Dos,Crt,Turbo3;

{

mjs 11/07/88	Corrected spelling of facility.
pw  09/22/89    Add code to clear bottom lines (#24 & #25) of screen properly
bwr 01/12/90	Minor fix to avoid screen clutter in foreign versions
				of messages.
bwr 3/29/90 	Bottom-of-screen messages centered.
}


{$I help.inc }

const

Xlate_size = 19;
disp_lines = 18;

type

topbot = (top,bot);

var


xlate_recs : byte;

Error_Msg : string[40];

{ the following variables are only used in Do_Process.  They are declared   }
{ in the main program segment so they can be addressed via the data segment }

Fname   : array[1..80] of char;

Index_Table : array[1..Table_Recs] of Table_Type;

Xlate_Table : array[1..Xlate_size] of Str_Type;

Disp_Buff : array[1..buff_size] of byte;



procedure Do_Process;                                   { Do_Process }

type

RegPackType = record
         AX,BX,CX,DX,BP,SI,DI,DS,ES,Flags : integer
         end;

var

RegPack     : registers;
TXT         : text;
NDX         : file of Table_Type;
envseg,envofs,pspseg,
Total_Recs,
NdxHandle,
TxtHandle   : integer;
Choice,
L,Lc,x,
LinesPerCol : byte;
outkey,
Ch          : char;
BarLine     : array[1..80] of char;

PageNum,Ytop,
Xstrt,Ystrt,
Xofs,Maxcol,
Xcoord,Ycoord,
Row,Col         : byte;
loopflag,
topmore,
botmore : boolean;

procedure putmore(location : topbot);

procedure writemore;

begin
textcolor(15);
write(' Continued . . .');
textcolor(7);
textbackground(0)
end;

begin
if (location = top) and (not topmore) then begin
  window(1,1,80,25);
  gotoxy(2,2);
  writemore;
  topmore := true
  end
else
  if (location = bot) and (not botmore) then begin
    window(1,1,80,25);
    gotoxy(2,23);
    writemore;
    botmore := true
    end;
window(1,Ytop + 1,80,22)
end;

procedure putbar(location : topbot);

begin
if (location = top) and (topmore) then begin
  window(1,1,80,25);
  gotoxy(2,2);
  write('様様様様様様様様');
  topmore := false
  end
else
  if (location = bot) and (botmore) then begin
    window(1,1,80,25);
    gotoxy(2,23);
    write('様様様様様様様様');
    botmore := false;
    end;
window(1,Ytop + 1,80,22)
end;

procedure beep;                                                { beep }

begin
sound(99);
delay(100);
nosound
end;

procedure Choice2RC;                                       { Choice2RC }

begin
Col := ((Choice - 1) div LinesPerCol) + 1;
Row := Choice - ((Col - 1) * LinesPerCol)
end;

procedure RC2Choice;                                        { RC2Choice }

begin
Choice := ((Col - 1) * LinesPerCol) + Row
end;

procedure RC2XY;                                              { RC2XY }

begin
Xcoord := ((Col - 1) * Xofs) + Xstrt;
Ycoord := Row - 1 + Ystrt
end;

procedure dispkey(choice,attr : byte);                         { dispkey }

var z : byte;
    c : integer;

begin
c := ((Ycoord + Ytop - 2) shl 8) + Xcoord - 1;
with RegPack do
  for z := 1 to Str_Size do begin
    AX := $0900 + ord(Index_Table[choice].Key[z]);
    BX := (PageNum shl 8) + attr;
    CX := 1;
    Intr($10,RegPack);
    AX := $0200;
    BX := (PageNum shl 8);
    DX := c + z;
    Intr($10,RegPack)
    end
end;

procedure LoChoice;                                         { LoChoice }

begin
gotoxy(Xcoord,Ycoord);
dispkey(Choice,7)
end;

procedure HiChoice;                                        { HiChoice }

begin
gotoxy(Xcoord,Ycoord);
dispkey(Choice,$70)
end;

procedure moveleft;                                        { moveleft }

begin
LoChoice;
if Col = 1 then Col := Maxcol
else Col := Col - 1;
RC2Choice;
if Choice > Total_Recs then begin
  Choice := Total_Recs;
  Choice2RC
  end;
RC2XY;
HiChoice
end;

procedure moveright;                                       { moveright }

begin
LoChoice;
if Col = Maxcol then Col := 1
else Col := Col + 1;
RC2Choice;
if Choice > Total_Recs then begin
  Choice := Total_Recs;
  Choice2RC
  end;
RC2XY;
HiChoice
end;

procedure moveup;                                            { moveup }

begin
LoChoice;
if Row = 1 then begin
  Row := LinesPerCol;
  if col > 1 then col := col - 1
  else col := maxcol
  end
else Row := Row - 1;
RC2Choice;
if Choice > Total_Recs then begin
  Choice := Total_Recs;
  Choice2RC
  end;
RC2XY;
HiChoice
end;

procedure movedown;                                          { movedown }

begin
LoChoice;
if Col = Maxcol then
  if Choice = Total_Recs then begin
    Row := 1;
    col := 1
    end
  else
    Row := Row + 1
else
  if Row = LinesPerCol then begin
    Row := 1;
    col := col + 1
    end
  else Row := Row + 1;
RC2Choice;
RC2XY;
HiChoice
end;

procedure menugetkeys;

begin
while(true) do begin
  read(kbd,ch);
  if ch = #27 then
    if keypressed then begin
      read(kbd,ch);
      case ch of
      #71 : begin            { home }
             end;
      #72 : moveup;          { up arrow }
      #73 : begin             { pg up }
             end;
      #77 : moveright;       { right arrow }
      #81 : begin             { pg dn }
             end;
      #80 : movedown;        { down arrow }
      #79 : begin             { end }
             end;
      #75 : moveleft;        { left arrow }
        else beep            { undefined extended key }
        end
      end
    else begin   { simple escape key }
      window(1,1,80,25);
      clrscr;
      halt
      end
  else
    if ch = #13 then exit
    else beep
  end
end;

procedure Menu_Status;                                     { menu_status }

begin
window(1,1,80,25);
gotoxy(1,1); write('                       ');  {BWR: Added a space }
gotoxy(1,24); clreol;                     { Added to clear bottom text - PW }
gotoxy(1,25); clreol;                     { Added to clear bottom text - PW }
gotoxy(15,24); write('Use arrow-keys to select choice, then press <ENTER>');
gotoxy(15,25); write('            Press <ESC> to return to MOS           ');
window(1,Ytop,80,22)
end;

procedure disptext;                                             { disptext }

{ puts up the text based on value of choice }

type

Bindextype = record
               Offset,
               Size   : integer
               end;

var
x,y,
Total_lines,
Curofs,
Curbyte,
topline,
Maxbytes  : integer;
Buff_Index : array[1..201] of Bindextype;  { max of 200 lines }
scrollok,
loop1,
loop2  : boolean;

procedure displine(lnum : integer);                            { displine }

begin
with RegPack do begin
  DS := Dseg;
  DX := Buff_index[lnum].offset;
  CX := Buff_index[lnum].size;
  BX := 1;        { Standard Output }
  AX := $4000
  end;
MsDos(RegPack);
{ basically ignoring error here - probably couldn't report one anyway }
end;  { displine }

procedure scrollup;                                         { scrollup }

begin
if (topline > 1) and scrollok then begin
  topline := topline - 1;
  window(1,Ytop + 1,80,21);
  gotoxy(1,1);
  insline;
  displine(topline);
  window(1,ytop+1,80,22)
  end
end;

procedure scrolldown;                                       { scrolldown }

begin
if (topline + disp_lines - 1 <> total_lines) and scrollok then begin
  topline := topline + 1;
  window(1,Ytop + 1,80,21);
  gotoxy(1,1);
  delline;
  gotoxy(1,disp_lines);
  displine(topline + disp_lines - 1);
  window(1,ytop+1,80,22)
  end
end;

procedure init_text;
var
	y :integer;

begin
clrscr;
if scrollok then begin
  x := disp_lines;
  putmore(bot)
  end
else x := total_lines;
gotoxy(1,1);
for y := 1 to x do displine(y);
topline := 1
end;

procedure PgDn;
var
	y:integer;

begin
if scrollok and ((topline + disp_lines - 1) <> total_lines) then begin
  clrscr;
  gotoxy(1,1);
  if (topline + disp_lines - 1) > (total_lines - disp_lines) then begin
    topline := total_lines - disp_lines + 1;
    end
  else begin
    topline := topline + disp_lines;
    end;
  for y := topline to (topline + disp_lines - 1) do displine(y)
  end
end;

begin   { disptext }
window(1,Ytop,80,22);
clrscr;
window(1,1,80,25);
gotoxy(1,24); clreol;                     { Added to clear bottom text - PW }
gotoxy(1,25); clreol;                     { Added to clear bottom text - PW }
gotoxy(21,24); write('Press "+" or "-" to select next screen.');
gotoxy(21,25); write('  Press <ESC> to return to the menu.   ');
gotoxy(1,1); write('Command: ');
for x := 1 to Str_Size do write(Index_Table[Choice].Key[x]);
window(1,Ytop + 1,80,22);

with RegPack do begin
  DX := Index_Table[Choice].Offset[2];
  CX := index_table[choice].offset[1];
  BX := TxtHandle;
  AX := $4200         { Lseek the offset }
  end;
MsDos(RegPack);

if (RegPack.Flags and 1) > 0 then begin
  Error_Msg := 'Lseek in HELP.TXT';
  exit
  end;

with RegPack do begin
  DS := Dseg;
  DX := ofs(Disp_Buff);
  CX := Index_Table[Choice].size;
  BX := TxtHandle;
  AX := $3f00         { read from the file }
  end;
MsDos(RegPack);

if (RegPack.Flags and 1) > 0 then begin
  Error_Msg := 'Reading from HELP.TXT';
  exit
  end;

Total_lines := 1;
Curofs := ofs(Disp_Buff);
Curbyte := 1;
Maxbytes := Index_Table[Choice].size;

loop1 := true;                    { build an index to each line in the block }
while(loop1) do begin
  Buff_index[Total_Lines].offset := Curofs;
  Buff_index[Total_Lines].size := Curbyte;
  loop2 := true;
  while(loop1 and loop2) do begin
    If Disp_Buff[Curbyte] = 13 then begin
      curbyte := curbyte + 2;
      buff_index[total_lines].size := curbyte - buff_index[total_lines].size;
      curofs := curofs + buff_index[total_lines].size;
      total_lines := total_lines + 1;
      loop2 := false
      end
    else begin
      curbyte := curbyte + 1;
      if curbyte > maxbytes then loop1 := false
      end
    end
  end;
total_lines := total_lines - 1;

putbar(top);
putbar(bot);
scrollok := false;
if total_lines > disp_lines then begin
  scrollok := true;
  window(1,1,80,25);
  gotoxy(1,24); clreol;              { Added to clear bottom text - PW }
  gotoxy(1,25); clreol;              { Added to clear bottom text - PW }
  gotoxy(5,24); write('Use cursor keys to scroll text. Use "+" and "-" to select next screen.');
  gotoxy(5,25); write('                  Press <ESC> to return to the menu.                  ');
  window(1,Ytop + 1,80,22)
  end;

init_text;

while(true) do begin
  read(kbd,ch);
  if ch = #27 then
    if keypressed then begin
      read(kbd,ch);
      case ch of
      #71 : if topline > 1 then init_text;       { home }
      #72 : scrollup;        { up arrow }
      #73 :                  { pg up }
              if (total_lines > disp_lines) and (topline <> 1) then
                if topline > disp_lines then begin
                  topline := topline - disp_lines;
                  clrscr;
                  gotoxy(1,1);
                  for y := topline to (topline + disp_lines - 1) do
                    displine(y);
                  end
                  else init_text;
      #81 : PgDn;            { pg dn }
      #80 : scrolldown;      { down arrow }
      #79 :                  { end key }
            if scrollok then begin
              clrscr;
              gotoxy(1,1);
              topline := total_lines - disp_lines + 1;
              for y := topline to (topline + disp_lines - 1) do displine(y)
              end
            else
        else beep            { undefined extended key }
        end
      end
    else exit  { simple escape key }
  else
    if ch = #13 then PgDn
    else
      if ch in ['+','-'] then begin
        outkey := ch;
        exit
        end
      else beep;
  if scrollok then begin
    if topline > 1 then putmore(top)
    else putbar(top);
    if (topline + disp_lines - 1) <> total_lines then putmore(bot)
    else putbar(bot)
    end
  end
end;  { disptext }

procedure checkparm;                                      { checkparm }

var

x,y,
nomatch,
start      : byte;
parameter  : Str_type;
str : string;

procedure message1;                                        { message1 }

begin
writeln('Unrecognized parameter: ',paramstr(1));
halt
end;

procedure checktable1;
var 
	x,y : integer;
	c : char;

begin
if (length(paramstr(1)) > (Str_Size - start)) then begin
  message1;
  exit
  end;

for x := (start + 1) to (length(paramstr(1)) + start) do
  begin
	str := copy(paramstr(1),(x - start),1);
	parameter[x] := upcase(str[1]);
  end;
x := 0;

while((x <= Total_Recs) and (choice = 0)) do begin
  x := x + 1;
  nomatch := 0;             { search the index table for a match }
  y := 0;
  while((y < Str_Size) and (nomatch = 0)) do begin
    y := y + 1;
    if (upcase(Index_Table[x].key[y]) <> parameter[y]) then nomatch := 1
    end;
  if nomatch = 0 then choice := x
  end
end;

begin     { checkparm }
choice := 0;
if paramcount > 0 then begin
  fillchar(parameter,Str_Size,' ');
  start := 0;
  checktable1;       { see if can match as is }
  if (choice = 0) and (copy(paramstr(1),1,1) <> '.') then begin
    start := 1;
    parameter[1] := '.';       { if match by adding a dot, scold them }
    checktable1;
    if choice > 0 then begin
      writeln('Use:    HELP .',paramstr(1));
      halt
      end
    end;
  if choice = 0 then begin   { didn't match first table, check 2nd }
    x := 0;
    while((x < Xlate_recs) and (choice = 0)) do begin
      x := x + 1;
      if (xlate_table[x] = parameter) then choice := x
      end;
    if choice = 0 then message1 { failed both searches }
    else begin                  { report translation }
      write('Use:    HELP .');
      case choice of
      1 : writeln('DISKID');
      2 : writeln('NEXT');
      3 : writeln('DIRMAP');
      4 : writeln('REL');
      5 : writeln('FILEMODE');
      6 : writeln('KILL');
      7 : writeln('MSYS');
      8 : writeln('SEARCH');
      9 : writeln('RENAME');
     10 : writeln('ALIAS');
     11 : writeln('ALIAS');
     12 : writeln('EXPORT');
     13 : writeln('CD');
     14 : writeln('RD');
     15 : writeln('MD');
     16 : writeln('VERIFY');
     17 : writeln('COMPFILE');
     18 : writeln('IMPORT');
     19 : writeln('MSORT')
        end;
      halt
      end
    end
  end
end;    { checkparm }

begin          { Do_Process }
Xstrt := 4;
Ystrt := 2;
Xofs := 15;
MaxCol := 5;
Row := 1;
Col := 1;
Xcoord := Xstrt;
Ycoord := Ystrt;
topmore := false;
botmore := false;

RegPack.Ax := $0f00;
Intr($10,RegPack);
PageNum := hi(RegPack.Bx);

{ OPEN THE INDEX FILE AND READ INTO ARRAY }

fillchar(Fname,80,#0);
RegPack.AH := $62;
MsDos(RegPack);
pspseg := RegPack.BX;
envseg := memw[pspseg:$2c];
envofs := 0;
while(memw[envseg:envofs] <> 0) do envofs := envofs + 1;
envofs := envofs + 4;
x := 1;
loopflag := true;
while(loopflag) do begin
  Fname[x] := chr(mem[envseg:envofs]);
  if Fname[x] = chr(0) then loopflag := false
  else begin
    x := x + 1;
    envofs := envofs + 1
    end
  end;
x := x - 3;
Fname[x] := 'N';
Fname[x+1] := 'D';
Fname[x+2] := 'X';


with RegPack do begin
  DS := Dseg;
  DX := ofs(Fname);
  AX := $3d20         { open file, deny write, read access }
  end;
MsDos(RegPack);

if (RegPack.Flags and 1) > 0 then begin
  Error_Msg := 'Opening the HELP.NDX file    ';
  exit
  end;

NdxHandle := RegPack.AX;

with RegPack do begin
  DS := Dseg;
  DX := ofs(Index_Table[1]);
  CX := sizeof(Table_Type) * Table_Recs;
  BX := NdxHandle;
  AX := $3f00        { read from file }
  end;
MsDos(RegPack);

if (RegPack.Flags and 1) > 0 then begin
  Error_Msg := 'Reading the HELP.NDX file    ';
  exit
  end;

Total_Recs := RegPack.AX div sizeof(Table_Type);
LinesPerCol := Total_Recs div Maxcol;
if (Maxcol * LinesPerCol) < Total_Recs then LinesPerCol := LinesPerCol + 1;

with Regpack do begin
  AX := $3e00;    { close the file }
  BX := NdxHandle
  end;
MsDos(RegPack);

if (RegPack.Flags and 1) > 0 then begin
  Error_Msg := 'Closing the HELP.NDX file    ';
  exit
  end;

{ OPEN THE TEXT FILE }

Fname[x] := 'T';
Fname[x+1] := 'X';
Fname[x+2] := 'T';

with RegPack do begin
  DS := Dseg;
  DX := ofs(Fname);
  AX := $3d20         { open file, deny write, read access }
  end;
MsDos(RegPack);

if (RegPack.Flags and 1) > 0 then begin
  Error_Msg := 'Opening the HELP.TXT file    ';
  exit
  end;

TxtHandle := RegPack.AX;

textcolor(7);
checkparm;

fillchar(BarLine,80,#205);
clrscr;
gotoxy(29,1); write('PC-MOS HELP UTILITY');
gotoxy(1,2); write(BarLine);
gotoxy(1,23); write(BarLine);
Ytop := 3;

if choice > 0 then begin
  disptext;
  if Error_msg <> '' then exit;
  Choice2RC;
  RC2XY
  end
else Choice := 1;

while(true) do begin
  Menu_Status;
  clrscr;

  L := 1;
  Lc := 1;
  Xcoord := Xstrt;
  Ycoord := Ystrt;
  repeat
    gotoxy(Xcoord,Ycoord);

    dispkey(L,7);

    Ycoord := Ycoord + 1;
    L := L + 1;
    Lc := Lc + 1;
    if Lc > LinesPerCol then begin
      Lc := 1;
      Ycoord := Ystrt;
      Xcoord := Xcoord + Xofs
      end;
  until(L > Total_Recs);

  RC2XY;
  gotoxy(Xcoord,Ycoord);
  hichoice;

  menugetkeys;

  repeat
    outkey := 'x';
    disptext;
    if Error_msg <> '' then exit;
    putbar(top);
    putbar(bot);
    if outkey = '+' then
      if choice < total_recs then choice := choice + 1
      else choice := 1
    else
      if outkey = '-' then
        if choice > 1 then choice := choice - 1
        else choice := total_recs
  until(outkey = 'x');
  Choice2RC;
  RC2XY

  end;

end;  { Do_Process }




begin                                                             { Main }

xlate_recs := 19;
xlate_table[1] :=  '.LABEL         ';
xlate_table[2] :=  '.SHIFT         ';
xlate_table[3] :=  '.TREE          ';
xlate_table[4] :=  '.VER           ';
xlate_table[5] :=  '.ATTRIB        ';
xlate_table[6] :=  '.BREAK         ';
xlate_table[7] :=  '.SYS           ';
xlate_table[8] :=  '.FIND          ';
xlate_table[9] :=  '.REN           ';
xlate_table[10] := '.SUBST         ';
xlate_table[11] := '.ASSIGN        ';
xlate_table[12] := '.BACKUP        ';
xlate_table[13] := '.CHDIR         ';
xlate_table[14] := '.RMDIR         ';
xlate_table[15] := '.MKDIR         ';
xlate_table[16] := '.CHKDSK        ';
xlate_table[17] := '.COMP          ';
xlate_table[18] := '.RESTORE       ';
xlate_table[19] := '.SORT          ';

Error_Msg := '';


Do_Process;

if Error_Msg <> '' then begin
  writeln;
  writeln('Error:  ',Error_Msg);
  writeln;
  halt(1)
  end;

end.    { Main }
