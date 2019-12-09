@echo off
rem
rem   Define the variables for running builds from this source library.
rem
set srcdir=rend
set buildname=core
call treename_var "(cog)source/rend/core" sourcedir
set libname=rend
set fwname=
call treename_var "(cog)src/%srcdir%/debug_%fwname%.bat" tnam
make_debug "%tnam%"
call "%tnam%"
