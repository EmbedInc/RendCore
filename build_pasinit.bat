@echo off
rem
rem   Set up for building a Pascal module.
rem
call build_vars

call src_go %srcdir%
call src_getfrom sys base.ins.pas
call src_getfrom sys sys.ins.pas
call src_getfrom sys sys_sys2.ins.pas
call src_getfrom util util.ins.pas
call src_getfrom string string.ins.pas
call src_getfrom file file.ins.pas
call src_getfrom vect vect.ins.pas
call src_getfrom math math.ins.pas
call src_getfrom imglib img.ins.pas
call src_getfrom ray ray.ins.pas
call src_getfrom ray ray_type1.ins.pas

call src_getfrom rend win win.ins.pas
call src_getfrom rend win win_keys.ins.pas
call src_getfrom rend win win_msg.ins.pas
call src_getfrom rend win win_sys.ins.pas

call src_get %srcdir% %libname%.ins.pas
call src_get %srcdir% %libname%2.ins.pas
call src_get %srcdir% %libname%_sw.ins.pas
call src_get %srcdir% %libname%_sw2.ins.pas
call src_get %srcdir% %libname%_open.ins.pas
call src_get %srcdir% %libname%_sw_sys.ins.pas
call src_get %srcdir% %libname%_events_sys.ins.pas

make_debug debug_switches.ins.pas
call src_builddate "%srcdir%"
