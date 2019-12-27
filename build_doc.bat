@echo off
rem
rem   Build the documentation associated with this library that is not directly
rem   describing a particular program.
rem
setlocal
call build_vars

call src_doc rendlib
call src_doc rendlib_dev
