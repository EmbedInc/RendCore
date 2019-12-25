@echo off
rem
rem   BRAY
rem
rem   Build all the routines that interface with the ray tracer in the RAY
rem   library.  This script is intended for testing after modifications are made
rem   to the RAY library.  Build errors due to incompatibility between the ray
rem   routines here and the RAY library are faster to catch using this script
rem   than to build the whole REND library.
rem
setlocal
call build_pasinit

call src_pas %srcdir% rend_sw_ray
call src_pas %srcdir% rend_sw_ray_delete
call src_pas %srcdir% rend_sw_ray_visprop_new

call src_rendprim %srcdir% rend_sw_sphere_ray_3d
call src_rendprim %srcdir% rend_sw_tri_cache_ray_3d
call src_rendprim %srcdir% rend_sw_ray_trace_2dimi
