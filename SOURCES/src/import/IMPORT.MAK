###############################################################################
#
#       MAKEFILE FOR:   IMPORT.EXE
#
#       Creation date:  2/4/91
#
#       Revision date:  2/4/91
#
#       Programmer:     B. W. Roeser
#
#
#               (C) Copyright 1991  The Software Link, Inc.
#                       All Rights Reserved
#
# ----------------------  >> Revision Log <<  --------------------------
#
# Date          Prog    Description of Revision
# ----          ----    -----------------------
#
###############################################################################
#
.c.obj:
        cl -c $<

.asm.obj:
        masm -Mx $*;

OBJECTS =       import.obj  parse.obj  decomp.obj  get_next.obj \
                term.obj  mos_util.obj  globals.obj

OBJLIST =       import +parse +decomp +get_next +term +mos_util +globals

import.exe : $(OBJECTS)
        link $(OBJLIST)/e,,,rsasmall
