
const

Buff_size = 4096;
Table_Recs = 90;
Str_Size = 15;

type

dword_type = array[1..2] of integer;

Str_type = array[1..Str_Size] of char;

Table_Type = record
               Key    : Str_type;
               Offset : dword_type;
               Size   : integer
               end;
