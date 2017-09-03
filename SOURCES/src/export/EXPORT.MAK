###############################################################################
#
#       MAKEFILE FOR:           EXPORT.EXE
#
#       Creation date:          1/8/91
#
#       Revision date:          1/8/91
#
#       Programmer:             B. W. Roeser
#
#       Notes:                  Compiled in small model of MSC
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

OBJECTS =       export.obj  parse.obj  get_next.obj  output.obj \
                compress.obj init_drv.obj term.obj  mos_util.obj \
                globals.obj

OBJLIST =       export +parse +output +get_next +compress +init_drv \
                +term +mos_util +globals

LIBRARIES = ${LIB}\RSASMALL.LIB

export.exe : $(OBJECTS) $(LIBRARIES)
        link $(OBJLIST)/e,,,rsasmall
