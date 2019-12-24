@echo off
rem
rem   BPRIM module
rem
rem   Build rend RENDlib graphics primitive.  MODULE is the generic file name
rem   containing the source code for the primitive.
rem
setlocal
call build_pasinit

call src_rendprim %srcdir% %~1
