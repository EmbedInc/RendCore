@echo off
rem
rem   BUILD_TOOLS [-dbg]
rem
rem   Build the executable programs that are used to build the library.
rem
setlocal
call build_pasinit

call src_prog %srcdir% make_rend_prim_ins %1
