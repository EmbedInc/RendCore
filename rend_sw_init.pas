{   Subroutine REND_SW_INIT (DEV_NAME, PARMS, STAT)
*
*   Init all the state of the REND library, and set up the transfer vector
*   to point to the software-only version of the subroutines.
}
module rend_sw_init;
define rend_sw_init;
%include 'rend_sw2.ins.pas';

const
  rend_max_keys_k = 300;               {max key descriptors storable per device}
  max_msg_parms = 3;                   {max parameters we can pass to a message}

var
  varname_debug: string_var32_t :=     {variable name to set RENDlib debug level}
    [str := 'RENDLIB_DEBUG', len := 13, max := sizeof(varname_debug.str)];

procedure rend_sw_init (               {initializes the base RENDlib device}
  in      dev_name: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {parameters passed from application}
  out     stat: sys_err_t);            {error return code}

var
  i, j: sys_int_machine_t;             {scratch integers and loop counters}
  r1, r2: real;                        {scratch floating point numbers}
  it: rend_iterp_k_t;                  {identifier for current interpolant}
  tparms: rend_text_parms_t;           {user parameters for text}
  vparms: rend_vect_parms_t;           {user parameters for vectors}
  xb2d, yb2d, ofs2d: vect_2d_t;        {used for 2D transform}
  xb3d, yb3d, zb3d, ofs3d: vect_3d_t;  {used for 3D transform}
  suprop_val: rend_suprop_val_t;       {data value for a surface property}
  light1, light2: rend_light_handle_t; {handles to initial light sources}
  save: univ_ptr;                      {saved copy of CHECK_MODES pointer}
  ent_type: rend_vert3d_ent_vals_t;    {ID for a 3D vertex descriptor entry type}
  ncache_flags: rend_ncache_flags_t;   {combined flags word for normal vector caches}
  sz: sys_int_adr_t;                   {amount of memory}
  cmd: string_var32_t;                 {command parsed from PARMS}
  token: string_var32_t;               {scratch token for number conversion}
  pick: sys_int_machine_t;             {number of token picked from list}
  p: string_index_t;                   {parse index for PARMS}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;

label
  parms_loop, cmd_done, done_parms;

begin
  tparms.font.max := sizeof(tparms.font.str); {init local var strings}
  tparms.font.len := 0;
  cmd.max := sizeof(cmd.str);
  token.max := sizeof(token.str);

  sys_error_none (stat);               {init to device open succeeded}
{
*   Set the global RENDlib debug level.
}
  sys_envvar_get (varname_debug, token, stat); {read RENDlib debug env variable}
  if sys_stat_match (sys_subsys_k, sys_stat_envvar_noexist_k, stat)
    then begin                         {debug environment variable not present}
      rend_debug_level := 0;           {default to all debug info suppressed}
      end
    else begin                         {debug environment variable exists}
      string_t_int (token, rend_debug_level, stat); {try to convert value to integer}
      if sys_error(stat) or (rend_debug_level < 0) then begin
        sys_msg_parm_vstr (msg_parm[1], token);
        sys_msg_parm_vstr (msg_parm[2], varname_debug);
        sys_message_bomb ('rend', 'rend_debug_envvar_badstr', msg_parm, 2);
        end;
      end
    ;                                  {debug level all set}

  rend_prim_data_res_version := 0;     {needed by REND_INSTALL_PRIM}
{
*   Directly install primitives into REND_SW_PRIM call table.
}
  rend_install_prim (rend_sw_anti_alias_d, rend_sw_prim.anti_alias);
  rend_install_prim (rend_sw_chain_vect_3d_d, rend_sw_prim.chain_vect_3d);
  rend_install_prim (rend_sw_circle_2dim_d, rend_sw_prim.circle_2dim);
  rend_install_prim (rend_sw_clear_d, rend_sw_prim.clear);
  rend_install_prim (rend_sw_clear_cwind_d, rend_sw_prim.clear_cwind);
  rend_install_prim (rend_sw_disc_2dim_d, rend_sw_prim.disc_2dim);
  rend_install_prim (rend_sw_flip_buf_d, rend_sw_prim.flip_buf);
  rend_install_prim (rend_sw_flush_all_d, rend_sw_prim.flush_all);
  rend_install_prim (rend_sw_image_2dimcl_d, rend_sw_prim.image_2dimcl);
  rend_install_prim (rend_sw_line_3d_d, rend_sw_prim.line_3d);
  rend_install_prim (rend_sw_poly_2d_d, rend_sw_prim.poly_2d);
  rend_install_prim (rend_sw_poly_2dim_d, rend_sw_prim.poly_2dim);
  rend_install_prim (rend_sw_poly_2dimcl_d, rend_sw_prim.poly_2dimcl);
  rend_install_prim (rend_sw_poly_3dpl_d, rend_sw_prim.poly_3dpl);
  rend_install_prim (rend_sw_poly_text_d, rend_sw_prim.poly_text);
  rend_install_prim (rend_sw_quad_3d_d, rend_sw_prim.quad_3d);
  rend_install_prim (rend_sw_ray_trace_2dimi_d, rend_sw_prim.ray_trace_2dimi);
  rend_install_prim (rend_sw_rect_2d_d, rend_sw_prim.rect_2d);
  rend_install_prim (rend_sw_rect_2dim_d, rend_sw_prim.rect_2dim);
  rend_install_prim (rend_sw_rect_2dimcl_d, rend_sw_prim.rect_2dimcl);
  rend_install_prim (rend_sw_rect_2dimi_d, rend_sw_prim.rect_2dimi);
  rend_install_prim (rend_sw_rect_px_2dimcl_d, rend_sw_prim.rect_px_2dimcl);
  rend_install_prim (rend_sw_rect_px_2dimi_d, rend_sw_prim.rect_px_2dimi);
  rend_install_prim (rend_sw_runpx_2dimcl_d, rend_sw_prim.runpx_2dimcl);
  rend_install_prim (rend_sw_runpx_2dimcl_d, rend_sw_prim.runpx_2dimi);
  rend_install_prim (rend_sw_rvect_2d_d, rend_sw_prim.rvect_2d);
  rend_install_prim (rend_sw_rvect_2dim_d, rend_sw_prim.rvect_2dim);
  rend_install_prim (rend_sw_rvect_2dimcl_d, rend_sw_prim.rvect_2dimcl);
  rend_install_prim (rend_sw_rvect_3dpl_d, rend_sw_prim.rvect_3dpl);
  rend_install_prim (rend_sw_rvect_text_d, rend_sw_prim.rvect_text);
  rend_install_prim (rend_sw_span_2dimcl_d, rend_sw_prim.span_2dimcl);
  rend_install_prim (rend_sw_span_2dimcl_d, rend_sw_prim.span_2dimi);
  rend_install_prim (rend_sw_sphere_3d_d, rend_sw_prim.sphere_3d);
  rend_install_prim (rend_sw_text_d, rend_sw_prim.text);
  rend_install_prim (rend_sw_text_raw_d, rend_sw_prim.text_raw);
  rend_install_prim (rend_sw_tri_3d_d, rend_sw_prim.tri_3d);
  rend_install_prim (rend_sw_tstrip_3d_d, rend_sw_prim.tstrip_3d);
  rend_install_prim (rend_sw_tubeseg_3d_d, rend_sw_prim.tubeseg_3d);
  rend_install_prim (rend_sw_vect_2d_d, rend_sw_prim.vect_2d);
  rend_install_prim (rend_sw_vect_2dimcl_d, rend_sw_prim.vect_2dimcl);
  rend_install_prim (rend_sw_vect_fp_2dim_d, rend_sw_prim.vect_fp_2dim);
  rend_install_prim (rend_sw_vect_int_2dim_d, rend_sw_prim.vect_int_2dim);
  rend_install_prim (rend_sw_vect_2dimi_d, rend_sw_prim.vect_2dimi);
  rend_install_prim (rend_sw_vect_3d_d, rend_sw_prim.vect_3d);
  rend_install_prim (rend_sw_vect_3dpl_d, rend_sw_prim.vect_3dpl);
  rend_install_prim (rend_sw_vect_3dw_d, rend_sw_prim.vect_3dw);
  rend_install_prim (rend_sw_vect_text_d, rend_sw_prim.vect_text);
  rend_install_prim (rend_sw_wpix_d, rend_sw_prim.wpix);
{
*   The remaining primitives are the same as ones already installed in other places
*   in the call table.  Copy from the existing call table entry to install these
*   primitives.
}
  rend_install_prim (rend_sw_prim.poly_2d_data_p^, rend_sw_prim.poly_txdraw);
  rend_install_prim (rend_sw_prim.rvect_2d_data_p^, rend_sw_prim.rvect_txdraw);
  rend_install_prim (rend_sw_prim.vect_2d_data_p^, rend_sw_prim.vect_txdraw);
  rend_install_prim (rend_sw_prim.vect_int_2dim_data_p^, rend_sw_prim.vect_2dim);
{
*   Install entry points into the SET call table.
}
  rend_sw_set.aa_radius := addr(rend_sw_aa_radius);
  rend_sw_set.aa_scale := addr(rend_sw_aa_scale);
  rend_sw_set.alloc_bitmap := addr(rend_sw_alloc_bitmap);
  rend_sw_set.alloc_bitmap_handle := addr(rend_sw_alloc_bitmap_handle);
  rend_sw_set.alloc_context := addr(rend_sw_alloc_context);
  rend_sw_set.alpha_func := addr(rend_sw_alpha_func);
  rend_sw_set.alpha_on := addr(rend_sw_alpha_on);
  rend_sw_set.array_bitmap := addr(rend_sw_array_bitmap);
  rend_sw_set.backface := addr(rend_sw_backface);
  rend_sw_set.bench_flags := addr(rend_sw_bench_flags);
  rend_sw_set.cache_version := addr(rend_sw_cache_version);
  rend_sw_set.cirres := addr(rend_sw_cirres);
  rend_sw_set.cirres_n := addr(rend_sw_cirres_n);
  rend_sw_set.clear_cmodes := addr(rend_sw_clear_cmodes);
  rend_sw_set.clip_2dim := addr(rend_sw_clip_2dim);
  rend_sw_set.clip_2dim_delete := addr(rend_sw_clip_2dim_delete);
  rend_sw_set.clip_2dim_on := addr(rend_sw_clip_2dim_on);
  rend_sw_set.close := addr(rend_sw_close);
  rend_sw_set.cmode_vals := addr(rend_sw_cmode_vals);
  rend_sw_set.context := addr(rend_sw_context);
  rend_sw_set.cpnt_2d := addr(rend_sw_cpnt_2d);
  rend_sw_set.cpnt_2dim := addr(rend_sw_cpnt_2dim);
  rend_sw_set.cpnt_2dimi := addr(rend_sw_cpnt_2dimi);
  rend_sw_set.cpnt_3d := addr(rend_sw_cpnt_3d);
  rend_sw_set.cpnt_3dpl := addr(rend_sw_cpnt_3dpl);
  rend_sw_set.cpnt_3dw := addr(rend_sw_cpnt_3dw);
  rend_sw_set.cpnt_text := addr(rend_sw_cpnt_text);
  rend_sw_set.create_light := addr(rend_sw_create_light);
  rend_sw_set.dealloc_bitmap := addr(rend_sw_dealloc_bitmap);
  rend_sw_set.dealloc_bitmap_handle := addr(rend_sw_dealloc_bitmap_handle);
  rend_sw_set.dealloc_context := addr(rend_sw_dealloc_context);
  rend_sw_set.del_all_lights := addr(rend_sw_del_all_lights);
  rend_sw_set.del_light := addr(rend_sw_del_light);
  rend_sw_set.dev_reconfig := addr(rend_sw_dev_reconfig);
  rend_sw_set.dev_restore := addr(rend_sw_dev_restore);
  rend_sw_set.dev_z_curr := addr(rend_sw_dev_z_curr);
  rend_sw_set.disp_buf := addr(rend_sw_disp_buf);
  rend_sw_set.dith_on := addr(rend_sw_dith_on);
  rend_sw_set.draw_buf := addr(rend_sw_draw_buf);
  rend_sw_set.end_group := addr(rend_sw_end_group);
  rend_sw_set.enter_level := addr(rend_sw_enter_level);
  rend_sw_set.enter_rend := addr(rend_sw_enter_rend);
  rend_sw_set.enter_rend_cond := addr(rend_sw_enter_rend_cond);
  rend_sw_set.event_mode_pnt := addr(rend_sw_event_mode_pnt);
  rend_sw_set.event_req_close := addr(rend_sw_event_req_close);
  rend_sw_set.event_req_key_off := addr(rend_sw_event_req_key_off);
  rend_sw_set.event_req_key_on := addr(rend_sw_event_req_key_on);
  rend_sw_set.event_req_scroll := addr(rend_sw_event_req_scroll);
  rend_sw_set.event_req_pnt := addr(rend_sw_event_req_pnt);
  rend_sw_set.event_req_resize := addr(rend_sw_event_req_resize);
  rend_sw_set.event_req_rotate_off := addr(rend_sw_event_req_rotate_off);
  rend_sw_set.event_req_rotate_on := addr(rend_sw_event_req_rotate_on);
  rend_sw_set.event_req_translate := addr(rend_sw_event_req_translate);
  rend_sw_set.event_req_wiped_resize := addr(rend_sw_event_req_wiped_resize);
  rend_sw_set.event_req_wiped_rect := addr(rend_sw_event_req_wiped_rect);
  rend_sw_set.events_req_off := addr(rend_sw_events_req_off);
  rend_sw_set.exit_rend := addr(rend_sw_exit_rend);
  rend_sw_set.eyedis := addr(rend_sw_eyedis);
  rend_sw_set.force_sw_update := addr(rend_sw_force_sw_update);
  rend_sw_set.image_ftype := addr(rend_sw_image_ftype);
  rend_sw_set.image_size := addr(rend_sw_image_size);
  rend_sw_set.image_write := addr(rend_sw_image_write);
  rend_sw_set.iterp_aa := addr(rend_sw_iterp_aa);
  rend_sw_set.iterp_bitmap := addr(rend_sw_iterp_bitmap);
  rend_sw_set.iterp_flat := addr(rend_sw_iterp_flat);
  rend_sw_set.iterp_flat_int := addr(rend_sw_iterp_flat_int);
  rend_sw_set.iterp_iclamp := addr(rend_sw_iterp_iclamp);
  rend_sw_set.iterp_linear := addr(rend_sw_iterp_linear);
  rend_sw_set.iterp_on := addr(rend_sw_iterp_on);
  rend_sw_set.iterp_pclamp := addr(rend_sw_iterp_pclamp);
  rend_sw_set.iterp_pixfun := addr(rend_sw_iterp_pixfun);
  rend_sw_set.iterp_quad := addr(rend_sw_iterp_quad);
  rend_sw_set.iterp_run_ofs := addr(rend_sw_iterp_run_ofs);
  rend_sw_set.iterp_shade_mode := addr(rend_sw_iterp_shade_mode);
  rend_sw_set.iterp_span_ofs := addr(rend_sw_iterp_span_ofs);
  rend_sw_set.iterp_span_on := addr(rend_sw_iterp_span_on);
  rend_sw_set.iterp_src_bitmap := addr(rend_sw_iterp_src_bitmap);
  rend_sw_set.iterp_wmask := addr(rend_sw_iterp_wmask);
  rend_sw_set.light_accur := addr(rend_sw_light_accur);
  rend_sw_set.light_amb := addr(rend_sw_light_amb);
  rend_sw_set.light_dir := addr(rend_sw_light_dir);
  rend_sw_set.light_on := addr(rend_sw_light_on);
  rend_sw_set.light_pnt := addr(rend_sw_light_pnt);
  rend_sw_set.light_pr2 := addr(rend_sw_light_pr2);
  rend_sw_set.light_val := addr(rend_sw_light_val);
  rend_sw_set.lin_geom_2dim := addr(rend_sw_lin_geom_2dim);
  rend_sw_set.lin_vals := addr(rend_sw_lin_vals);
  rend_sw_set.lin_vals_rgba := addr(rend_sw_lin_vals_rgba);
  rend_sw_set.max_buf := addr(rend_sw_max_buf);
  rend_sw_set.min_bits_hw := addr(rend_sw_min_bits_hw);
  rend_sw_set.min_bits_vis := addr(rend_sw_min_bits_vis);
  rend_sw_set.new_view := addr(rend_sw_new_view);
  rend_sw_set.ncache_version := addr(rend_sw_ncache_version);
  rend_sw_set.perspec_on := addr(rend_sw_perspec_on);
  rend_sw_set.pointer := addr(rend_sw_pointer);
  rend_sw_set.pointer_abs := addr(rend_sw_pointer_abs);
  rend_sw_set.poly_parms := addr(rend_sw_poly_parms);
  rend_sw_set.quad_geom_2dim := addr(rend_sw_quad_geom_2dim);
  rend_sw_set.quad_vals := addr(rend_sw_quad_vals);
  rend_sw_set.ray_callback := addr(rend_sw_ray_callback);
  rend_sw_set.ray_delete := addr(rend_sw_ray_delete);
  rend_sw_set.ray_save := addr(rend_sw_ray_save);
  rend_sw_set.rcpnt_2d := addr(rend_sw_rcpnt_2d);
  rend_sw_set.rcpnt_2dim := addr(rend_sw_rcpnt_2dim);
  rend_sw_set.rcpnt_2dimi := addr(rend_sw_rcpnt_2dimi);
  rend_sw_set.rcpnt_3dpl := addr(rend_sw_rcpnt_3dpl);
  rend_sw_set.rcpnt_text := addr(rend_sw_rcpnt_text);
  rend_sw_set.rgb := addr(rend_sw_rgb);
  rend_sw_set.rgba := addr(rend_sw_set_rgba);
  rend_sw_set.rgbz_linear := addr(rend_sw_rgbz_linear);
  rend_sw_set.rgbz_quad := addr(rend_sw_rgbz_quad);
  rend_sw_set.run_config := addr(rend_sw_run_config);
  rend_sw_set.shade_geom := addr(rend_sw_shade_geom);
  rend_sw_set.shnorm_break_cos := addr(rend_sw_shnorm_break_cos);
  rend_sw_set.shnorm_unitized := addr(rend_sw_shnorm_unitized);
  rend_sw_set.span_config := addr(rend_sw_span_config);
  rend_sw_set.start_group := addr(rend_sw_start_group);
  rend_sw_set.suprop_all_off := addr(rend_sw_suprop_all_off);
  rend_sw_set.suprop_diff := addr(rend_sw_suprop_diff);
  rend_sw_set.suprop_emis := addr(rend_sw_suprop_emis);
  rend_sw_set.suprop_on := addr(rend_sw_suprop_on);
  rend_sw_set.suprop_spec := addr(rend_sw_suprop_spec);
  rend_sw_set.suprop_trans := addr(rend_sw_suprop_trans);
  rend_sw_set.suprop_val := addr(rend_sw_suprop_val);
  rend_sw_set.surf_face_curr := addr(rend_sw_surf_face_curr);
  rend_sw_set.surf_face_on := addr(rend_sw_surf_face_on);
  rend_sw_set.text_parms := addr(rend_sw_text_parms);
  rend_sw_set.text_pos_org := addr(rend_sw_text_pos_org);
  rend_sw_set.tmap_accur := addr(rend_sw_tmap_accur);
  rend_sw_set.tmap_changed := addr(rend_sw_tmap_changed);
  rend_sw_set.tmap_dimension := addr(rend_sw_tmap_dimension);
  rend_sw_set.tmap_filt := addr(rend_sw_tmap_filt);
  rend_sw_set.tmap_flims := addr(rend_sw_tmap_flims);
  rend_sw_set.tmap_func := addr(rend_sw_tmap_func);
  rend_sw_set.tmap_method := addr(rend_sw_tmap_method);
  rend_sw_set.tmap_on := addr(rend_sw_tmap_on);
  rend_sw_set.tmap_src := addr(rend_sw_tmap_src);
  rend_sw_set.update_mode := addr(rend_sw_update_mode);
  rend_sw_set.vect_parms := addr(rend_sw_vect_parms);
  rend_sw_set.vert3d_ent_all_off := addr(rend_sw_vert3d_ent_all_off);
  rend_sw_set.vert3d_ent_off := addr(rend_sw_vert3d_ent_off);
  rend_sw_set.vert3d_ent_on := addr(rend_sw_vert3d_ent_on);
  rend_sw_set.vert3d_ent_on_always := addr(rend_sw_vert3d_ent_on_always);
  rend_sw_set.video_sync_int_clr := addr(rend_sw_video_sync_int_clr);
  rend_sw_set.xform_2d := addr(rend_sw_xform_2d);
  rend_sw_set.xform_3d := addr(rend_sw_xform_3d);
  rend_sw_set.xform_3d_postmult := addr(rend_sw_xform_3d_postmult);
  rend_sw_set.xform_3d_premult := addr(rend_sw_xform_3d_premult);
  rend_sw_set.xform_3dpl_2d := addr(rend_sw_xform_3dpl_2d);
  rend_sw_set.xform_3dpl_plane := addr(rend_sw_xform_3dpl_plane);
  rend_sw_set.xform_text := addr(rend_sw_xform_text);
  rend_sw_set.xsec_circle := addr(rend_sw_xsec_circle);
  rend_sw_set.xsec_close := addr(rend_sw_xsec_close);
  rend_sw_set.xsec_create := addr(rend_sw_xsec_create);
  rend_sw_set.xsec_curr := addr(rend_sw_xsec_curr);
  rend_sw_set.xsec_delete := addr(rend_sw_xsec_delete);
  rend_sw_set.xsec_pnt_add := addr(rend_sw_xsec_pnt_add);
  rend_sw_set.z_clip := addr(rend_sw_z_clip);
  rend_sw_set.z_range := addr(rend_sw_z_range);
  rend_sw_set.zfunc := addr(rend_sw_zfunc);
  rend_sw_set.zon := addr(rend_sw_zon);

  rend_sw_set.cpnt_txdraw := univ_ptr(rend_sw_set.cpnt_2d);
  rend_sw_set.rcpnt_txdraw := univ_ptr(rend_sw_set.rcpnt_2d);
{
*   Install entry points into the GET call table.
}
  rend_sw_get.aa_border := addr(rend_sw_get_aa_border);
  rend_sw_get.aa_radius := addr(rend_sw_get_aa_radius);
  rend_sw_get.bench_flags := addr(rend_sw_get_bench_flags);
  rend_sw_get.bits_hw := addr(rend_sw_get_bits_hw);
  rend_sw_get.bits_vis := addr(rend_sw_get_bits_vis);
  rend_sw_get.bxfnv_3d := addr(rend_sw_get_bxfnv_3d);
  rend_sw_get.bxfpnt_2d := addr(rend_sw_get_bxfpnt_2d);
  rend_sw_get.bxfpnt_3d := addr(rend_sw_get_bxfpnt_3d);
  rend_sw_get.bxfpnt_3dpl := addr(rend_sw_get_bxfpnt_3dpl);
  rend_sw_get.bxfv_3d := addr(rend_sw_get_bxfv_3d);
  rend_sw_get.cirres := addr(rend_sw_get_cirres);
  rend_sw_get.clip_2dim_handle := addr(rend_sw_get_clip_2dim_handle);
  rend_sw_get.clip_poly_2dimcl := addr(rend_sw_get_clip_poly_2dimcl);
  rend_sw_get.clip_vect_2dimcl := addr(rend_sw_get_clip_vect_2dimcl);
  rend_sw_get.close_corrupt := addr(rend_sw_get_close_corrupt);
  rend_sw_get.cmode_vals := addr(rend_sw_get_cmode_vals);
  rend_sw_get.cmodes := addr(rend_sw_get_cmodes);
  rend_sw_get.color_xor := addr(rend_sw_get_color_xor);
  rend_sw_get.comments_list := addr(rend_sw_get_comments_list);
  rend_sw_get.context := addr(rend_sw_get_context);
  rend_sw_get.cpnt_2d := addr(rend_sw_get_cpnt_2d);
  rend_sw_get.cpnt_2dim := addr(rend_sw_get_cpnt_2dim);
  rend_sw_get.cpnt_2dimi := addr(rend_sw_get_cpnt_2dimi);
  rend_sw_get.cpnt_3d := addr(rend_sw_get_cpnt_3d);
  rend_sw_get.cpnt_3dpl := addr(rend_sw_get_cpnt_3dpl);
  rend_sw_get.cpnt_3dw := addr(rend_sw_get_cpnt_3dw);
  rend_sw_get.cpnt_text := addr(rend_sw_get_cpnt_text);
  rend_sw_get.dev_id := addr(rend_sw_get_dev_id);
  rend_sw_get.disp_buf := addr(rend_sw_get_disp_buf);
  rend_sw_get.dith_on := addr(rend_sw_get_dith_on);
  rend_sw_get.draw_buf := addr(rend_sw_get_draw_buf);
  rend_sw_get.enter_level := addr(rend_sw_get_enter_level);
  rend_sw_get.event_possible := addr(rend_sw_get_event_possible);
  rend_sw_get.force_sw_update := addr(rend_sw_get_force_sw_update);
  rend_sw_get.image_size := addr(rend_sw_get_image_size);
  rend_sw_get.iterps_on_list := addr(rend_sw_get_iterps_on_list);
  rend_sw_get.iterps_on_set := addr(rend_sw_get_iterps_on_set);
  rend_sw_get.keys := addr(rend_sw_get_keys);
  rend_sw_get.key_sp := addr(rend_sw_get_key_sp);
  rend_sw_get.key_sp_def := addr(rend_sw_get_key_sp_def);
  rend_sw_get.light_eval := addr(rend_sw_get_light_eval);
  rend_sw_get.lights := addr(rend_sw_get_lights);
  rend_sw_get.max_buf := addr(rend_sw_get_max_buf);
  rend_sw_get.min_bits_hw := addr(rend_sw_get_min_bits_hw);
  rend_sw_get.min_bits_vis := addr(rend_sw_get_min_bits_vis);
  rend_sw_get.perspec := addr(rend_sw_get_perspec);
  rend_sw_get.pointer := addr(rend_sw_get_pointer);
  rend_sw_get.pointer_abs := addr(rend_sw_get_pointer_abs);
  rend_sw_get.poly_parms := addr(rend_sw_get_poly_parms);
  rend_sw_get.ray_bounds_3dw := addr(rend_sw_get_ray_bounds_3dw);
  rend_sw_get.ray_callback := addr(rend_sw_get_ray_callback);
  rend_sw_get.reading_sw := addr(rend_sw_get_reading_sw);
  rend_sw_get.reading_sw_prim := addr(rend_sw_get_reading_sw_prim);
  rend_sw_get.rgba := addr(rend_sw_get_rgba);
  rend_sw_get.suprop := addr(rend_sw_get_suprop);
  rend_sw_get.text_parms := addr(rend_sw_get_text_parms);
  rend_sw_get.txbox_text := addr(rend_sw_get_txbox_text);
  rend_sw_get.txbox_txdraw := addr(rend_sw_get_txbox_txdraw);
  rend_sw_get.update_sw := addr(rend_sw_get_update_sw);
  rend_sw_get.update_sw_prim := addr(rend_sw_get_update_sw_prim);
  rend_sw_get.vect_parms := addr(rend_sw_get_vect_parms);
  rend_sw_get.video_sync_int := addr(rend_sw_get_video_sync_int);
  rend_sw_get.wait_exit := addr(rend_sw_get_wait_exit);
  rend_sw_get.xfnorm_3d := addr(rend_sw_get_xfnorm_3d);
  rend_sw_get.xform_2d := addr(rend_sw_get_xform_2d);
  rend_sw_get.xform_3d := addr(rend_sw_get_xform_3d);
  rend_sw_get.xform_3dpl_2d := addr(rend_sw_get_xform_3dpl_2d);
  rend_sw_get.xform_3dpl_plane := addr(rend_sw_get_xform_3dpl_plane);
  rend_sw_get.xform_text := addr(rend_sw_get_xform_text);
  rend_sw_get.xfpnt_2d := addr(rend_sw_get_xfpnt_2d);
  rend_sw_get.xfpnt_3d := addr(rend_sw_get_xfpnt_3d);
  rend_sw_get.xfpnt_3dpl := addr(rend_sw_get_xfpnt_3dpl);
  rend_sw_get.xfpnt_text := addr(rend_sw_get_xfpnt_text);
  rend_sw_get.xfvect_text := addr(rend_sw_get_xfvect_text);
  rend_sw_get.z_bits := addr(rend_sw_get_z_bits);
  rend_sw_get.z_2d := addr(rend_sw_get_z_2d);
  rend_sw_get.z_clip := addr(rend_sw_get_z_clip);

  rend_sw_get.cpnt_txdraw := univ_ptr(rend_sw_get.cpnt_2d);
{
*   install entry points into the INTERNAL call table.
}
  rend_sw_internal.bres_fp := addr(rend_sw_bres_fp);
  rend_sw_internal.check_modes := addr(rend_sw_check_modes);
  rend_sw_internal.check_modes2 := addr(rend_sw_check_modes2);
  rend_sw_internal.ev_possible := addr(rend_sw_get_ev_possible);
  rend_sw_internal.icolor_xor := addr(rend_sw_icolor_xor);
  rend_sw_internal.reset_refresh := addr(rend_sw_reset_refresh);
  rend_sw_internal.setup_iterps := addr(rend_sw_setup_iterps);
  rend_install_prim (rend_sw_update_span_d, rend_sw_internal.update_span);
  rend_install_prim (rend_sw_update_rect_d, rend_sw_internal.update_rect);
  rend_install_prim (rend_sw_tri_cache_3d_d, rend_sw_internal.tri_cache_3d);
  rend_install_prim (rend_sw_tzoid_d, rend_sw_internal.tzoid);

  rend_prim := rend_sw_prim;           {set working copies from SW master copies}
  rend_set := rend_sw_set;
  rend_get := rend_sw_get;
  rend_internal := rend_sw_internal;

  rend_sw_save_cmode (save);           {turn off CHECK_MODES}
{
*   Initialize RENDlib's state.  Whenever possible, this is done thru the
*   user-accessible calls.
}
  rend_iterps.mask_on := [];           {init to no interpolants are ON}
  rend_iterps.n_on := 0;
  for it := firstof(it) to lastof(it) do begin {once for each interpolant}
    rend_iterps.iterp[it].on := false;
    rend_iterps.iterp[it].bitmap_p := nil;
    rend_iterps.iterp[it].bitmap_src_p := nil;
    rend_iterps.iterp[it].width := 8;
    rend_iterps.iterp[it].val_scale := 255.98;
    rend_iterps.iterp[it].val_offset := 0.01;
    rend_iterps.iterp[it].iclamp_max.all := 16#00FFFFFF;
    rend_iterps.iterp[it].iclamp_min.all := 0;
    rend_iterps.iterp[it].int := false;
    end;

  rend_image.ftype.max := sizeof(rend_image.ftype.str);
  rend_image.ftype.len := 0;           {init to IMG library picks image type}
  string_list_init (                   {init comments list for this image}
    rend_image.comm,                   {comments list handle}
    rend_device[rend_dev_id].mem_p^);  {parent memory context to use}
  rend_image.fnam_auto.max := sizeof(rend_image.fnam_auto.str);
  rend_image.fnam_auto.len := 0;       {init to no image to write on device close}
  rend_image.size_fixed := false;      {init to allowed to change image size}

  rend_clips_2dim.n_on := 0;           {init to no 2D image space clip windows}
  rend_clip_2dim.exists := false;      {cause to cache clip window result}
  rend_set.clip_2dim_on^ (1, false);
  for i := 1 to rend_max_clip_2dim do begin {once for each possible 2DIM clip window}
    rend_clips_2dim.clip[i].exists := false; {init to this clip window not exist}
    end;

  rend_vect_state.replaced_prim_entry_p := nil; {init to no VECT --> POLY turned on}
  rend_vect_parms.start_style.style := {invalid to force recompute}
    rend_end_style_invalid_k;
  rend_vect_parms.end_style.style :=   {invalid to force recompute}
    rend_end_style_invalid_k;
  rend_text_parms.font.max :=          {init font name to null for recompute}
    sizeof(rend_text_parms.font.str);
  rend_text_parms.font.len := 0;

  rend_lights.free_p := nil;           {init master data about all light sources}
  rend_lights.used_p := nil;
  rend_lights.on_p := nil;
  rend_lights.n_alloc := 0;
  rend_lights.n_used := 0;
  rend_lights.n_on := 0;
  rend_lights.accuracy := rend_laccu_exact_k;
  rend_lights.changed := false;        {init to no changes in light sources}

  rend_close_corrupt := false;         {init to display is NOT corrupted on close of
                                        device}

  rend_set.zon^ (false);
  rend_set.zfunc^ (rend_zfunc_gt_k);
  rend_set.alpha_on^ (false);
  rend_set.alpha_func^ (rend_afunc_over_k);
  rend_set.tmap_on^ (false);
  rend_set.tmap_accur^ (rend_tmapaccu_dev_k);
  rend_set.tmap_dimension^ (rend_tmapd_uv_k);
  rend_set.tmap_method^ (rend_tmapm_mip_k);
  rend_set.tmap_func^ (rend_tmapf_insert_k);
  rend_set.tmap_flims^ (1.0, 2.0**rend_max_iterp_tmap);
  rend_set.tmap_filt^ ([rend_tmapfilt_maps_k]);
  rend_sw_mipmap_table_init (256, rend_tmap.mip.blend);

  for it := firstof(it) to lastof(it) do begin {once for each interpolant}
    rend_set.iterp_on^ (it, true);
    rend_set.iterp_iclamp^ (it, true);
    rend_set.iterp_pclamp^ (it, true);
    rend_set.iterp_flat^ (it, 0.0);
    rend_set.iterp_pixfun^ (it, rend_pixfun_insert_k);
    rend_set.iterp_shade_mode^ (it, rend_iterp_mode_flat_k);
    rend_set.iterp_wmask^ (it, -1);
    rend_set.iterp_aa^ (it, false);    {turn OFF anti-aliasing}
    rend_set.iterp_span_on^ (it, false); {turn OFF participation in SPAN or RUN prims}
    rend_set.iterp_span_ofs^ (it, 0);
    rend_set.iterp_run_ofs^ (it, 0);
    j := 1;                            {init texture map size for first level}
    for i := 0 to rend_max_iterp_tmap do begin {once for each texture map size}
      rend_set.tmap_src^ (it, nil, 0, j, j, 0, 0); {disable tmap at this level}
      j := j * 2;                      {make size of texture map at next level}
      end;                             {back to init texture map at next level}
    rend_set.iterp_on^ (it, false);    {disable this interpolant}
    end;

  rend_set.iterp_iclamp^ (rend_iterp_z_k, false);
  rend_set.iterp_pclamp^ (rend_iterp_z_k, false);
  rend_iterps.z.width := 16;
  rend_iterps.z.val_scale := 32763.0;
  rend_iterps.z.val_offset := 0.0;
  rend_iterps.z.iclamp_max.all := 16#7FFFFFFF;
  rend_iterps.z.iclamp_min.all := 16#80000000;

  rend_set.iterp_iclamp^ (rend_iterp_i_k, false);
  rend_set.iterp_pclamp^ (rend_iterp_i_k, false);
  rend_iterps.i.width := 32;
  rend_iterps.i.val_scale := 2147480000.0;
  rend_iterps.i.val_offset := 0.0;
  rend_iterps.i.iclamp_max.all := 16#7FFFFFFF;
  rend_iterps.i.iclamp_min.all := 16#80000000;
  rend_set.iterp_flat_int^ (rend_iterp_i_k, 0);

  rend_set.iterp_wmask^ (rend_iterp_u_k, 0);
  rend_iterps.u.val_scale := 8191.98;
  rend_iterps.u.val_offset := 0.01;
  rend_iterps.u.iclamp_max.all := 16#1FFFFFFF;
  rend_iterps.u.iclamp_min.all := 0;

  rend_set.iterp_wmask^ (rend_iterp_v_k, 0);
  rend_iterps.v.val_scale := 8191.98;
  rend_iterps.v.val_offset := 0.01;
  rend_iterps.v.iclamp_max.all := 16#1FFFFFFF;
  rend_iterps.v.iclamp_min.all := 0;

  rend_set.image_size^ (0, 0, 1.0);

  rend_curr_span.dirty := false;       {init to no pending undrawn span pixels}

  xb2d.x := 1.0;                       {set user 2D transform}
  xb2d.y := 0.0;
  yb2d.x := 0.0;
  yb2d.y := 1.0;
  ofs2d.x := 0.0;
  ofs2d.y := 0.0;

  rend_set.xform_2d^ (xb2d, yb2d, ofs2d); {set new 2D model space transform}
  rend_set.cpnt_2d^ (0.0, 0.0);        {init current point}

  vparms.poly_level := rend_space_2dim_k; {force end cap computation the first time}
  vparms.width := 1.0;
  vparms.start_style.style := rend_end_style_rect_k;
  vparms.start_style.nsides := 5;      {not used now, but good default}
  vparms.end_style.style := rend_end_style_rect_k;
  vparms.end_style.nsides := 5;        {not used now, but good default}
  vparms.subpixel := false;
  rend_set.vect_parms^ (vparms);       {force end cap recompute}
  vparms.poly_level := rend_space_none_k; {set to what we really wanted}
  rend_set.vect_parms^ (vparms);       {set to final wakeup defaults}

  tparms.coor_level := rend_space_2d_k;
  tparms.size := 0.05;
  tparms.width := 0.85;
  tparms.height := 1.0;
  tparms.slant := 0.0;
  tparms.rot := 0.0;
  tparms.lspace := 1.0;
  tparms.start_org := rend_torg_ll_k;
  tparms.end_org := rend_torg_down_k;
  tparms.vect_width := 0.08;
  sys_cognivis_dir ('fonts', tparms.font);
  string_appends (tparms.font, '/simplex.h'(0));
  tparms.poly := false;
  rend_set.text_parms^ (tparms);

  rend_set.backface^ (rend_bface_flip_k);
  rend_set.cache_version^ (rend_cache_version_invalid + 1);
  rend_set.eyedis^ (3.3333333);
  rend_set.perspec_on^ (true);
  rend_set.z_clip^ (1.0, -1.0);
  rend_set.z_range^ (1.0, -1.0);
  xb3d.x := 1.0; xb3d.y := 0.0; xb3d.z := 0.0;
  yb3d.x := 0.0; yb3d.y := 1.0; yb3d.z := 0.0;
  zb3d.x := 0.0; zb3d.y := 0.0; zb3d.z := 1.0;
  ofs3d.x := 0.0; ofs3d.y := 0.0; ofs3d.z := 0.0;
  rend_set.xform_3d^ (xb3d, yb3d, zb3d, ofs3d);
  rend_set.new_view^;
  rend_set.cpnt_3d^ (0.0, 0.0, 0.0);

  rend_set.create_light^ (light1);     {set up initial ambient light source}
  rend_set.light_amb^ (light1, 0.25, 0.25, 0.25);

  rend_set.create_light^ (light2);     {set up initial directional light source}
  rend_set.light_dir^ (
    light2,                            {light source handle}
    0.75, 0.75, 0.75,                  {light source color}
    2.0, 4.0, 5.0);                    {direction to light source}

  rend_set.surf_face_curr^ (rend_face_back_k); {back face surface properties}
  rend_set.surf_face_on^ (false);

  rend_set.surf_face_curr^ (rend_face_front_k); {front face surface properties}
  suprop_val.emis_red := 0.0;
  suprop_val.emis_grn := 0.0;
  suprop_val.emis_blu := 0.0;
  rend_set.suprop_val^ (rend_suprop_emis_k, suprop_val);
  rend_set.suprop_on^ (rend_suprop_emis_k, false);

  suprop_val.diff_red := 1.0;
  suprop_val.diff_grn := 1.0;
  suprop_val.diff_blu := 1.0;
  rend_set.suprop_val^ (rend_suprop_diff_k, suprop_val);
  rend_set.suprop_on^ (rend_suprop_diff_k, true);

  suprop_val.spec_red := 1.0;
  suprop_val.spec_grn := 1.0;
  suprop_val.spec_blu := 1.0;
  suprop_val.spec_exp := 15.0;
  rend_set.suprop_val^ (rend_suprop_spec_k, suprop_val);
  rend_set.suprop_on^ (rend_suprop_spec_k, false);

  suprop_val.trans_front := 0.2;
  suprop_val.trans_side := 1.0;
  rend_set.suprop_val^ (rend_suprop_trans_k, suprop_val);
  rend_set.suprop_on^ (rend_suprop_trans_k, false);
  rend_set.surf_face_on^ (true);

  rend_set.dith_on^ (false);
  rend_set.force_sw_update^ (false);   {init to use hardware whenever possible}

  rend_poly_parms.subpixel := true;
  rend_poly_state.saved_poly_2dim := nil;
  rend_shade_geom := rend_iterp_mode_linear_k;

  rend_enter_level := 0;               {init to not in graphics mode}
  rend_enter_cnt := 0;                 {init number of successful ENTER_RENDs}

  for ent_type := firstof(ent_type) to lastof(ent_type) do begin
    rend_set.vert3d_ent_off^ (ent_type);
    rend_vert3d_always[ent_type] := false; {entry not guaranteed to be in use}
    end;

  rend_max_buf := 1;
  rend_curr_draw_buf := 1;
  rend_curr_disp_buf := 1;
  rend_min_bits_vis := 24.0;
  rend_min_bits_hw := 24.0;
  rend_bits_vis := 24.0;
  rend_bits_hw := 24.0;
  rend_set.vert3d_ent_all_off^;
  rend_ncache_flags.all := 0;          {init all, including possibly unused bits}
  ncache_flags.all := -1;
  i := ncache_flags.version;
  rend_set.ncache_version^ (i);
  rend_set.shnorm_break_cos^ (cos(rend_default_break_radians));

  rend_set.xsec_circle^ (              {create RENDlib default crossection}
    16,                                {number of line segments in circle}
    true,                              {turn on smooth shading}
    rend_scope_dev_k,                  {crossect belongs to this device}
    rend_xsec_def_p);                  {returned handle to new crossection}
  rend_set.xsec_curr^ (rend_xsec_def_p^); {set default crossection as current}

  rend_aa.filt_int_p := nil;           {init to no filter kernel allocated}
  rend_aa.filt_fp_p := nil;
  rend_aa.scale_x := 0.0;              {force filter kernel re-evaluation}
  rend_aa.scale_y := 0.0;
  rend_aa.kernel_rad := 1.25;          {init filter kernel radius to "normal"}
  rend_set.aa_scale^ (0.5, 0.5);       {init anti-aliasing state}

  rend_set.span_config^ (
    0);                                {pixel size}
  rend_set.run_config^ (
    0,                                 {pixel size}
    0);                                {offset for run length byte}

  rend_ray.save_on := false;           {not saving primitives for later ray tracing}
  rend_ray.callback := nil;            {init to no application callback routine}
  rend_ray.init := false;              {remaining ray tracing state not initialized}
  rend_set.cirres^ (20);               {init all the CIRRES parameters}
{
*   Init 3DPL space.
}
  rend_3dpl.sp.cpnt.x := 0.0;
  rend_3dpl.sp.cpnt.y := 0.0;
  rend_3dpl.sp.xb.x := 1.0;
  rend_3dpl.sp.xb.y := 0.0;
  rend_3dpl.sp.yb.x := 0.0;
  rend_3dpl.sp.yb.y := 1.0;
  rend_3dpl.sp.ofs.x := 0.0;
  rend_3dpl.sp.ofs.y := 0.0;
  rend_3dpl.sp.invm := 1.0;
  rend_3dpl.sp.inv_ok := true;
  rend_3dpl.sp.right := true;

  rend_3dpl.u_org.x := 0.0;
  rend_3dpl.u_org.y := 0.0;
  rend_3dpl.u_org.z := 0.0;
  rend_3dpl.u_xb.x := 1.0;
  rend_3dpl.u_xb.y := 0.0;
  rend_3dpl.u_xb.z := 0.0;
  rend_3dpl.u_yb.x := 0.0;
  rend_3dpl.u_yb.y := 1.0;
  rend_3dpl.u_yb.z := 0.0;
  rend_3dpl.front.x := 0.0;
  rend_3dpl.front.y := 0.0;
  rend_3dpl.front.z := 1.0;
  rend_3dpl.org := rend_3dpl.u_org;
  rend_3dpl.xb := rend_3dpl.u_xb;
  rend_3dpl.yb := rend_3dpl.u_yb;

  xb2d.x := 1.0; xb2d.y := 0.0;
  yb2d.x := 0.0; yb2d.y := 1.0;
  ofs2d.x := 0.0; ofs2d.y := 0.0;
  rend_set.xform_3dpl_2d^ (xb2d, yb2d, ofs2d); {force internal re-compute}

  rend_pointer.x := 0;                 {init graphics pointer coordinates}
  rend_pointer.y := 0;
  rend_pointer.inside := true;
  rend_pointer.root_x := 0;
  rend_pointer.root_y := 0;
  rend_pointer.root_inside := true;

  {   Set up the top level device descriptor for this device.  The following
  *   fields have already been initialized in REND_OPEN:
  *
  *     SAVE_AREA_P
  *     MEM_P
  *     OPEN
  }
  with rend_device[rend_dev_id]: dev do begin {DEV is our device descriptor}
    dev.keys_enab := 0;                {no individual keys enabled for events}
    dev.keys_max := rend_max_keys_k;   {number of available key descriptors}
    dev.keys_n := 0;                   {number of defined keys in list}
    sz := sizeof(rend_key_t) * dev.keys_max; {mem needed for key descriptors}
    rend_mem_alloc (                   {allocate memory for key descriptors}
      sz, rend_scope_dev_k, false, dev.keys_p);
    dev.ev_req := [];                  {no device events enabled}
    dev.scale_3drot := 1.0;            {init 3D rotation event scale factors}
    dev.pnt_x := 0;
    dev.pnt_y := 0;
    dev.pnt_mode := rend_pntmode_direct_k;
    dev.ev_changed := false;           {event state has not changed yet}
    end;                               {done with DEV abbreviation}

  rend_shnorm_unit := false;           {init user not sending unitized shading norms}
  rend_updmode := rend_updmode_live_k; {keep the device updated "live"}
  rend_dirty_crect := false;           {whole clip rectangle not pending update}
  rend_suprop.changed := true;         {examine SUPROP state next CHECK_MODES}
  rend_sw_bench_init;                  {init REND_BENCH flags}

  rend_save_blocks := 0;               {init number of saved/restored blocks}
  rend_sw_add_sblock (                 {add user-vis common block to save/rest list}
    univ_ptr(sys_int_adr_t(addr(rend_com_start)) + sizeof(rend_com_start)),
    sys_int_adr_t(addr(rend_com_end)) -
      (sys_int_adr_t(addr(rend_com_start)) + sizeof(rend_com_start))
    );
  rend_sw_add_sblock (                 {add SW device common block to save/rest list}
    univ_ptr(sys_int_adr_t(addr(rend_sw_com_start)) + sizeof(rend_sw_com_start)),
    sys_int_adr_t(addr(rend_sw_com_end)) -
      (sys_int_adr_t(addr(rend_sw_com_start)) + sizeof(rend_sw_com_start))
    );

  rend_inhibit_check_modes2 := false;  {make sure CHECK_MODES2 gets run}
  rend_sw_restore_cmode (save);        {restore CHECK_MODES and run it if necessary}
  rend_set.clear_cmodes^;              {init the changed mode flags}
  rend_set.video_sync_int_clr^;        {init the video sync interrupt flag}
{
*   Process possible commands and arguments in the PARMS string.
}
  p := 1;                              {init PARMS parse index}

parms_loop:
  string_token (parms, p, cmd, stat);  {get next command from PARMS}
  if string_eos(stat) then goto done_parms; {hit end of PARMS ?}
  sys_msg_parm_vstr (msg_parm[1], dev_name);
  rend_error_abort (stat, 'rend', 'rend_parm_get_error', msg_parm, 1);
  string_upcase (cmd);
  string_tkpick80 (cmd,
    'IMG SIZE ASPECT',
    pick);
  case pick of
{
*   IMG fnam
}
1:  begin
      string_token (parms, p, rend_image.fnam_auto, stat);
      end;
{
*   SIZE dx dy
}
2:  begin
      string_token_int (parms, p, rend_image.x_size, stat);
      if sys_error(stat) then goto cmd_done;
      string_token_int (parms, p, rend_image.y_size, stat);
      if sys_error(stat) then goto cmd_done;

      rend_image.size_fixed := true;
      rend_image.aspect := rend_image.x_size / rend_image.y_size;
      end;
{
*   ASPECT dx dy
}
3:  begin
      string_token_fpm (parms, p, r1, stat);
      if sys_error(stat) then goto cmd_done;
      string_token_fpm (parms, p, r2, stat);
      if sys_error(stat) then goto cmd_done;

      rend_image.aspect := r1 / r2;
      end;
{
*   Unrecognized command in PARMS string.
}
otherwise
    sys_msg_parm_vstr (msg_parm[1], cmd);
    sys_msg_parm_vstr (msg_parm[2], dev_name);
    rend_message_bomb ('rend', 'rend_parm_opt_bad', msg_parm, 2);
    end;

cmd_done:                              {done processing this last command}
  if not sys_error(stat) then goto parms_loop; {no errors, back for next command ?}
  sys_msg_parm_vstr (msg_parm[1], cmd);
  sys_msg_parm_vstr (msg_parm[2], dev_name);
  rend_message_bomb ('rend', 'rend_parm_parm_error', msg_parm, 2);
done_parms:                            {all done processing PARMS string}

  end;
