@echo off
rem
rem   BUILD_LIB [-dbg]
rem
rem   Build the REND library.
rem
setlocal
call build_pasinit

call src_insall %srcdir% %libname%

call src_pas %srcdir% %libname%_cache_clip_2dim %1
call src_pas %srcdir% %libname%_config_vert3d %1
call src_pas %srcdir% %libname%_context_to_state %1
call src_pas %srcdir% %libname%_dev_save %1
call src_pas %srcdir% %libname%_dev_set %1
call src_pas %srcdir% %libname%_dummy %1
call src_pas %srcdir% %libname%_end %1
call src_pas %srcdir% %libname%_events %1
call src_pas %srcdir% %libname%_evqueue %1
call src_pas %srcdir% %libname%_get_all_prim_access %1
call src_pas %srcdir% %libname%_get_prim_access %1
call src_pas %srcdir% %libname%_install_prim %1
call src_pas %srcdir% %libname%_make_spokes_pnt %1
call src_pas %srcdir% %libname%_make_xf3d_vrad %1
call src_pas %srcdir% %libname%_mem_alloc %1
call src_pas %srcdir% %libname%_mem_dealloc %1
call src_pas %srcdir% %libname%_message %1
call src_pas %srcdir% %libname%_open %1
call src_pas %srcdir% %libname%_open_screen %1
call src_pas %srcdir% %libname%_open_window %1
call src_pas %srcdir% %libname%_prim_restore_sw %1
call src_pas %srcdir% %libname%_reset_call_tables %1
call src_pas %srcdir% %libname%_spokes_to_norm %1
call src_pas %srcdir% %libname%_start %1
call src_pas %srcdir% %libname%_state_to_context %1
call src_pas %srcdir% %libname%_stdin %1
call src_pas %srcdir% %libname%_stdin_sys %1
call src_pas %srcdir% %libname%_sw_aa_radius %1
call src_pas %srcdir% %libname%_sw_aa_scale %1
call src_pas %srcdir% %libname%_sw_add_sblock %1
call src_pas %srcdir% %libname%_sw_alloc_bitmap %1
call src_pas %srcdir% %libname%_sw_alloc_bitmap_handle %1
call src_pas %srcdir% %libname%_sw_alloc_context %1
call src_pas %srcdir% %libname%_sw_alpha_func %1
call src_pas %srcdir% %libname%_sw_alpha_on %1
call src_pas %srcdir% %libname%_sw_array_bitmap %1
call src_pas %srcdir% %libname%_sw_bench %1
call src_pas %srcdir% %libname%_sw_bres_fp %1
call src_pas %srcdir% %libname%_sw_bres_step %1
call src_pas %srcdir% %libname%_sw_cache_version %1
call src_pas %srcdir% %libname%_sw_check_modes %1
call src_pas %srcdir% %libname%_sw_check_modes2 %1
call src_pas %srcdir% %libname%_sw_cirres %1
call src_pas %srcdir% %libname%_sw_clear_cmodes %1
call src_pas %srcdir% %libname%_sw_clip_2dim %1
call src_pas %srcdir% %libname%_sw_clip_2dim_delete %1
call src_pas %srcdir% %libname%_sw_clip_2dim_on %1
call src_pas %srcdir% %libname%_sw_close %1
call src_pas %srcdir% %libname%_sw_cmode_vals %1
call src_pas %srcdir% %libname%_sw_comblock %1
call src_pas %srcdir% %libname%_sw_context %1
call src_pas %srcdir% %libname%_sw_cpnt_2d %1
call src_pas %srcdir% %libname%_sw_cpnt_2dim %1
call src_pas %srcdir% %libname%_sw_cpnt_2dimi %1
call src_pas %srcdir% %libname%_sw_cpnt_3d %1
call src_pas %srcdir% %libname%_sw_cpnt_3dw %1
call src_pas %srcdir% %libname%_sw_cpnt_text %1
call src_pas %srcdir% %libname%_sw_create_light %1
call src_pas %srcdir% %libname%_sw_dealloc_bitmap %1
call src_pas %srcdir% %libname%_sw_dealloc_bitmap_handle %1
call src_pas %srcdir% %libname%_sw_dealloc_context %1
call src_pas %srcdir% %libname%_sw_del_all_lights %1
call src_pas %srcdir% %libname%_sw_del_light %1
call src_pas %srcdir% %libname%_sw_dev_reconfig %1
call src_pas %srcdir% %libname%_sw_dev_restore %1
call src_pas %srcdir% %libname%_sw_dev_z_curr %1
call src_pas %srcdir% %libname%_sw_disp_buf %1
call src_pas %srcdir% %libname%_sw_dith_on %1
call src_pas %srcdir% %libname%_sw_3dpl %1
call src_pas %srcdir% %libname%_sw_draw_buf %1
call src_pas %srcdir% %libname%_sw_dummy_cmode %1
call src_pas %srcdir% %libname%_sw_end_group %1
call src_pas %srcdir% %libname%_sw_enter_level %1
call src_pas %srcdir% %libname%_sw_enter_rend %1
call src_pas %srcdir% %libname%_sw_enter_rend_cond %1
call src_pas %srcdir% %libname%_sw_events %1
call src_pas %srcdir% %libname%_sw_exit_rend %1
call src_pas %srcdir% %libname%_sw_force_sw_update %1
call src_pas %srcdir% %libname%_sw_get_aa_border %1
call src_pas %srcdir% %libname%_sw_get_aa_radius %1
call src_pas %srcdir% %libname%_sw_get_bits_hw %1
call src_pas %srcdir% %libname%_sw_get_bits_vis %1
call src_pas %srcdir% %libname%_sw_get_bxfnv_3d %1
call src_pas %srcdir% %libname%_sw_get_bxfpnt_2d %1
call src_pas %srcdir% %libname%_sw_get_bxfpnt_3d %1
call src_pas %srcdir% %libname%_sw_get_bxfv_3d %1
call src_pas %srcdir% %libname%_sw_get_clip_2dim_handle %1
call src_pas %srcdir% %libname%_sw_get_clip_poly_2dimcl %1
call src_pas %srcdir% %libname%_sw_get_clip_vect_2dimcl %1
call src_pas %srcdir% %libname%_sw_get_close_corrupt %1
call src_pas %srcdir% %libname%_sw_get_cmodes %1
call src_pas %srcdir% %libname%_sw_get_cmode_vals %1
call src_pas %srcdir% %libname%_sw_get_color_xor %1
call src_pas %srcdir% %libname%_sw_get_comments_list %1
call src_pas %srcdir% %libname%_sw_get_context %1
call src_pas %srcdir% %libname%_sw_get_cpnt_2d %1
call src_pas %srcdir% %libname%_sw_get_cpnt_2dim %1
call src_pas %srcdir% %libname%_sw_get_cpnt_2dimi %1
call src_pas %srcdir% %libname%_sw_get_cpnt_3d %1
call src_pas %srcdir% %libname%_sw_get_cpnt_3dw %1
call src_pas %srcdir% %libname%_sw_get_cpnt_text %1
call src_pas %srcdir% %libname%_sw_get_dev_id %1
call src_pas %srcdir% %libname%_sw_get_disp_buf %1
call src_pas %srcdir% %libname%_sw_get_dith_on %1
call src_pas %srcdir% %libname%_sw_get_draw_buf %1
call src_pas %srcdir% %libname%_sw_get_enter_level %1
call src_pas %srcdir% %libname%_sw_get_force_sw_update %1
call src_pas %srcdir% %libname%_sw_get_image_size %1
call src_pas %srcdir% %libname%_sw_get_iterps_on %1
call src_pas %srcdir% %libname%_sw_get_lights %1
call src_pas %srcdir% %libname%_sw_get_light_eval %1
call src_pas %srcdir% %libname%_sw_get_light_eval2 %1
call src_pas %srcdir% %libname%_sw_get_light_eval3 %1
call src_pas %srcdir% %libname%_sw_get_max_buf %1
call src_pas %srcdir% %libname%_sw_get_min_bits_hw %1
call src_pas %srcdir% %libname%_sw_get_min_bits_vis %1
call src_pas %srcdir% %libname%_sw_get_perspec %1
call src_pas %srcdir% %libname%_sw_get_poly_parms %1
call src_pas %srcdir% %libname%_sw_get_ray_bounds_3dw %1
call src_pas %srcdir% %libname%_sw_get_reading_sw %1
call src_pas %srcdir% %libname%_sw_get_reading_sw_prim %1
call src_pas %srcdir% %libname%_sw_get_suprop %1
call src_pas %srcdir% %libname%_sw_get_text_parms %1
call src_pas %srcdir% %libname%_sw_get_txbox_text %1
call src_pas %srcdir% %libname%_sw_get_txbox_txdraw %1
call src_pas %srcdir% %libname%_sw_get_update_sw %1
call src_pas %srcdir% %libname%_sw_get_update_sw_prim %1
call src_pas %srcdir% %libname%_sw_get_vect_parms %1
call src_pas %srcdir% %libname%_sw_get_video_sync_int %1
call src_pas %srcdir% %libname%_sw_get_wait_exit %1
call src_pas %srcdir% %libname%_sw_get_xform_2d %1
call src_pas %srcdir% %libname%_sw_get_xform_text %1
call src_pas %srcdir% %libname%_sw_get_xfpnt_2d %1
call src_pas %srcdir% %libname%_sw_get_xfpnt_text %1
call src_pas %srcdir% %libname%_sw_get_xfvect_text %1
call src_pas %srcdir% %libname%_sw_get_z_bits %1
call src_pas %srcdir% %libname%_sw_get_z_clip %1
call src_pas %srcdir% %libname%_sw_get_z_2d %1
call src_pas %srcdir% %libname%_sw_image_ftype %1
call src_pas %srcdir% %libname%_sw_image_size %1
call src_pas %srcdir% %libname%_sw_image_write %1
call src_pas %srcdir% %libname%_sw_init %1
call src_pas %srcdir% %libname%_sw_interpolate %1
call src_pas %srcdir% %libname%_sw_iterp_aa %1
call src_pas %srcdir% %libname%_sw_iterp_bitmap %1
call src_pas %srcdir% %libname%_sw_iterp_flat %1
call src_pas %srcdir% %libname%_sw_iterp_flat_int %1
call src_pas %srcdir% %libname%_sw_iterp_iclamp %1
call src_pas %srcdir% %libname%_sw_iterp_linear %1
call src_pas %srcdir% %libname%_sw_iterp_on %1
call src_pas %srcdir% %libname%_sw_iterp_pclamp %1
call src_pas %srcdir% %libname%_sw_iterp_pixfun %1
call src_pas %srcdir% %libname%_sw_iterp_quad %1
call src_pas %srcdir% %libname%_sw_iterp_run_ofs %1
call src_pas %srcdir% %libname%_sw_iterp_shade_mode %1
call src_pas %srcdir% %libname%_sw_iterp_span_ofs %1
call src_pas %srcdir% %libname%_sw_iterp_span_on %1
call src_pas %srcdir% %libname%_sw_iterp_src_bitmap %1
call src_pas %srcdir% %libname%_sw_iterp_wmask %1
call src_pas %srcdir% %libname%_sw_light_accur %1
call src_pas %srcdir% %libname%_sw_light_amb %1
call src_pas %srcdir% %libname%_sw_light_dir %1
call src_pas %srcdir% %libname%_sw_light_on %1
call src_pas %srcdir% %libname%_sw_light_pnt %1
call src_pas %srcdir% %libname%_sw_light_pr2 %1
call src_pas %srcdir% %libname%_sw_light_val %1
call src_pas %srcdir% %libname%_sw_lin_geom_2dim %1
call src_pas %srcdir% %libname%_sw_lin_vals %1
call src_pas %srcdir% %libname%_sw_lin_vals_rgba %1
call src_pas %srcdir% %libname%_sw_max_buf %1
call src_pas %srcdir% %libname%_sw_min_bits_hw %1
call src_pas %srcdir% %libname%_sw_min_bits_vis %1
call src_pas %srcdir% %libname%_sw_mipmap_table_init %1
call src_pas %srcdir% %libname%_sw_ncache_version %1
call src_pas %srcdir% %libname%_sw_poly_parms %1
call src_pas %srcdir% %libname%_sw_quad_geom_2dim %1
call src_pas %srcdir% %libname%_sw_quad_vals %1
call src_pas %srcdir% %libname%_sw_ray %1
call src_pas %srcdir% %libname%_sw_ray_delete %1
call src_pas %srcdir% %libname%_sw_ray_visprop_new %1
call src_pas %srcdir% %libname%_sw_rcpnt_2d %1
call src_pas %srcdir% %libname%_sw_rcpnt_2dim %1
call src_pas %srcdir% %libname%_sw_rcpnt_2dimi %1
call src_pas %srcdir% %libname%_sw_rcpnt_text %1
call src_pas %srcdir% %libname%_sw_reset_refresh %1
call src_pas %srcdir% %libname%_sw_restore_cmode %1
call src_pas %srcdir% %libname%_sw_rgb %1
call src_pas %srcdir% %libname%_sw_rgba %1
call src_pas %srcdir% %libname%_sw_rgbz_linear %1
call src_pas %srcdir% %libname%_sw_rgbz_quad %1
call src_pas %srcdir% %libname%_sw_run_config %1
call src_pas %srcdir% %libname%_sw_save_cmode %1
call src_pas %srcdir% %libname%_sw_setup_iterps %1
call src_pas %srcdir% %libname%_sw_shade_geom %1
call src_pas %srcdir% %libname%_sw_shnorm_break_cos %1
call src_pas %srcdir% %libname%_sw_shnorm_unitized %1
call src_pas %srcdir% %libname%_sw_span_config %1
call src_pas %srcdir% %libname%_sw_start_group %1
call src_pas %srcdir% %libname%_sw_suprop_all_off %1
call src_pas %srcdir% %libname%_sw_suprop_diff %1
call src_pas %srcdir% %libname%_sw_suprop_emis %1
call src_pas %srcdir% %libname%_sw_suprop_spec %1
call src_pas %srcdir% %libname%_sw_suprop_trans %1
call src_pas %srcdir% %libname%_sw_surf %1
call src_pas %srcdir% %libname%_sw_text_parms %1
call src_pas %srcdir% %libname%_sw_text_pos_org %1
call src_pas %srcdir% %libname%_sw_tmap %1
call src_pas %srcdir% %libname%_sw_update_mode %1
call src_pas %srcdir% %libname%_sw_update_xf2d %1
call src_pas %srcdir% %libname%_sw_vect_parms %1
call src_pas %srcdir% %libname%_sw_vert3d_ent_all_off %1
call src_pas %srcdir% %libname%_sw_vert3d_ent_off %1
call src_pas %srcdir% %libname%_sw_vert3d_ent_on %1
call src_pas %srcdir% %libname%_sw_vert3d_ent_on_always %1
call src_pas %srcdir% %libname%_sw_video_sync_int_clr %1
call src_pas %srcdir% %libname%_sw_view %1
call src_pas %srcdir% %libname%_sw_xf3d %1
call src_pas %srcdir% %libname%_sw_xform_2d %1
call src_pas %srcdir% %libname%_sw_xform_text %1
call src_pas %srcdir% %libname%_sw_xsec %1
call src_pas %srcdir% %libname%_sw_zfunc %1
call src_pas %srcdir% %libname%_sw_zon %1
call src_pas %srcdir% %libname%_tbpoint_2d_3d %1
call src_pas %srcdir% %libname%_vert3d_ind_adr %1
call src_pas %srcdir% %libname%_vs_to_spokes %1

call src_rendprim %srcdir% %libname%_sw_anti_alias %1
call src_rendprim %srcdir% %libname%_sw_anti_alias2 %1
call src_rendprim %srcdir% %libname%_sw_chain_vect_3d %1
call src_rendprim %srcdir% %libname%_sw_circle_2dim %1
call src_rendprim %srcdir% %libname%_sw_clear %1
call src_rendprim %srcdir% %libname%_sw_anti_alias
call src_rendprim %srcdir% %libname%_sw_anti_alias2
call src_rendprim %srcdir% %libname%_sw_chain_vect_3d
call src_rendprim %srcdir% %libname%_sw_circle_2dim
call src_rendprim %srcdir% %libname%_sw_clear
call src_rendprim %srcdir% %libname%_sw_clear_cwind
call src_rendprim %srcdir% %libname%_sw_disc_2dim
call src_rendprim %srcdir% %libname%_sw_flip_buf
call src_rendprim %srcdir% %libname%_sw_flush_all
call src_rendprim %srcdir% %libname%_sw_image_2dimcl
call src_rendprim %srcdir% %libname%_sw_line_3d
call src_rendprim %srcdir% %libname%_sw_line2_3d
call src_rendprim %srcdir% %libname%_sw_nsubpix_poly_2dim
call src_rendprim %srcdir% %libname%_sw_poly_2d
call src_rendprim %srcdir% %libname%_sw_poly_2dim
call src_rendprim %srcdir% %libname%_sw_poly_2dimcl
call src_rendprim %srcdir% %libname%_sw_poly_3dpl
call src_rendprim %srcdir% %libname%_sw_poly_text
call src_rendprim %srcdir% %libname%_sw_quad_3d
call src_rendprim %srcdir% %libname%_sw_ray_trace_2dimi
call src_rendprim %srcdir% %libname%_sw_rect_2d
call src_rendprim %srcdir% %libname%_sw_rect_2dim
call src_rendprim %srcdir% %libname%_sw_rect_2dimcl
call src_rendprim %srcdir% %libname%_sw_rect_2dimi
call src_rendprim %srcdir% %libname%_sw_rect_px_2dimcl
call src_rendprim %srcdir% %libname%_sw_rect_px_2dimi
call src_rendprim %srcdir% %libname%_sw_runpx_2dimcl
call src_rendprim %srcdir% %libname%_sw_rvect_2d
call src_rendprim %srcdir% %libname%_sw_rvect_2dim
call src_rendprim %srcdir% %libname%_sw_rvect_2dimcl
call src_rendprim %srcdir% %libname%_sw_rvect_3dpl
call src_rendprim %srcdir% %libname%_sw_rvect_text
call src_rendprim %srcdir% %libname%_sw_span_2dimcl
call src_rendprim %srcdir% %libname%_sw_span2_2dimcl
call src_rendprim %srcdir% %libname%_sw_sphere_3d
call src_rendprim %srcdir% %libname%_sw_sphere_ray_3d
call src_rendprim %srcdir% %libname%_sw_text
call src_rendprim %srcdir% %libname%_sw_text_raw
call src_rendprim %srcdir% %libname%_sw_tri_cache_3d
call src_rendprim %srcdir% %libname%_sw_tri_cache2_3d
call src_rendprim %srcdir% %libname%_sw_tri_cache3_3d
call src_rendprim %srcdir% %libname%_sw_tri_cache_ray_3d
call src_rendprim %srcdir% %libname%_sw_tri_3d
call src_rendprim %srcdir% %libname%_sw_tstrip_3d
call src_rendprim %srcdir% %libname%_sw_tubeseg_3d
call src_rendprim %srcdir% %libname%_sw_tzoid
call src_rendprim %srcdir% %libname%_sw_tzoid2
call src_rendprim %srcdir% %libname%_sw_tzoid3
call src_rendprim %srcdir% %libname%_sw_tzoid4
call src_rendprim %srcdir% %libname%_sw_tzoid5
call src_rendprim %srcdir% %libname%_sw_update_rect
call src_rendprim %srcdir% %libname%_sw_update_span
call src_rendprim %srcdir% %libname%_sw_vect_2d
call src_rendprim %srcdir% %libname%_sw_vect_2dimcl
call src_rendprim %srcdir% %libname%_sw_vect_2dimi
call src_rendprim %srcdir% %libname%_sw_vect_3d
call src_rendprim %srcdir% %libname%_sw_vect_3dpl
call src_rendprim %srcdir% %libname%_sw_vect_3dw
call src_rendprim %srcdir% %libname%_sw_vect_fp_2dim
call src_rendprim %srcdir% %libname%_sw_vect_int_2dim
call src_rendprim %srcdir% %libname%_sw_vect_poly
call src_rendprim %srcdir% %libname%_sw_vect_text
call src_rendprim %srcdir% %libname%_sw_wpix

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%
