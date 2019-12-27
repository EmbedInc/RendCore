@echo off
rem
rem   Build everything from this source directory.
rem
setlocal
call godir "(cog)source/rend/core"

call build_tools
call build_lib
call build_doc
call build_progs
