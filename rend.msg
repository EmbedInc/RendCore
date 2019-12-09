/*   Error messages.  These have associated status codes defined in REND.INS.PAS.
/*
msg err1                               /* rend_stat_no_device_k
  lan english -def
    RENDlib inherent device %p1s with parameters "%p2s" is not available.
msg err2                               /* rend_stat_dev_cmd_err_k
  lan english -def
    Error occurred on attempt to open RENDlib device "%p1s".
    Unable to extract command name from paramter string "%p2s".
msg err3                               /* rend_stat_dev_cmd_bad_k
  lan english -def
    Error occurred on attempt to open RENDlib device "%p1s".
    Unrecognized command "%p1s" encountered in parameter string "%p3s".
msg err4                               /* rend_stat_dev_parm_err_k
  lan english -def
    Error occurred on attempt to open RENDlib device "%p1s".
    Unable to extract parameter to command "%p2s" from device parameters
    string "%p3s".
msg err5                               /* rend_stat_dev_parm_bad_k
  lan english -def
    Error occurred on attempt to open RENDlib device "%p1s".
    Bad parameter "%p2s" encountered for command "%p3s" in device parameters
    string.
/*
/*   Message intended for application programs.
/*
msg rend_open
  lan english -def
    Error on opening RENDlib device.
msg rend_open_screen
  lan english -def
    Error on opening RENDlib device for drawing to entire screen.
msg rend_open_sw
  lan english -def
    Error on opening RENDlib software bitmap device.
msg rend_open_video
  lan english -def
    Error on opening RENDlib device for drawing to video.
msg rend_open_wind
  lan english -def
    Error on opening RENDlib device for drawing to current window.
msg rend_read_image
  lan english -def
    Error on reading image into RENDlib bitmap.
msg rend_write_image
  lan english -def
    Error on writing RENDlib bitmap contents to an image file.
/*
/*   Messages used by IMAGE_DISP program.
/*
msg image_disp_cmd_bad
  lan english -def
    Unrecognized command "%p1s" encountered.
msg image_disp_list_err
  lan english -def
    Error reading images list file %p1s on line %p21.
msg image_disp_pix_coor
  lan english -def
    Values for pixel at %p1i,%p2i:
msg image_disp_rect_coor
  lan english -def
    Average values for rectangle of size %p1i x %p2i
    from (%p3i,%p4i) to (%p5i,%p6i):
msg image_disp_values
  lan english -def
    .nfill
                           Red  Green   Blue  Alpha
      0.0 to 1.0 scale:  %p1f5.3  %p2f5.3  %p3f5.3  %p4f5.3
      0 to 255 scale:      %p5f3.0    %p6f3.0    %p7f3.0    %p8f3.0
/*
/*   Message used by "base" RENDlib routines or the SW driver.
/*
msg rend_alpha_func_bad
  lan english -def
    Illegal alpha function ID encountered.  ID value was %p1i.
msg rend_backface_bad
  lan english -def
    Unrecognized or unimplmented backfacing flag value of %p1i encountered.
msg rend_bad_torg
  lan english -def
    Illegal value of %p1i encountered for TORG argument.
msg bench_envvar_token_bad
  lan english -def
    Environment variable RENDLIB_BENCH contain illegal keyword "%p1s".
msg bench_envvar_parse_err
  lan english -def
    Error occurred on attempt to read next token from RENDLIB_BENCH
    environment variable string.
msg rend_cap_too_many_sides
  lan english -def
    Too many sides specified for a vector end cap.
    %p1i were requested, but only %p2i are allowed.
msg rend_clip_complicated_ccwind
  lan english -def
    Complicated clip environments are not supported by CLEAR_CWIND.
    The clip environment must resolve to one draw-inside clip-outside
    rectangle.
msg rend_clip_complicated_cpoly
  lan english -def
    Complicated clip environments are not supported by
    REND_SW_GET_CLIP_POLY_2DIMCL.
    The clip environment must resolve to one draw-inside clip-outside
    rectangle.
msg rend_clip_complicated_cvect
  lan english -def
    Complicated clip environments are not supported by
    REND_SW_GET_CLIP_vect_2DIMCL.
    The clip environment must resolve to one draw-inside clip-outside
    rectangle.
msg rend_debug_envvar_badstr
  lan english -def
    Bad value %p1s encountered for environment variable %p2s.
    This variable may only be set to a string representing an
    integer that is greater than or equal to zero.
msg rend_dev_curr_none
  lan english -def
    No current RENDlib device exists.  A current device is required
    for the requested operation.
msg rend_dev_name_bad
  lan english -def
    Illegal inherent RENDlib device name "%p1s".
msg rend_dev_not_inherent
  lan english -def
    Unable to translate RENDlib logical device name %p1s into
    any inherent RENDlib device name.  No DEV_ALIAS command
    was found for %p1s in the rendlib.dev environment files.
msg rend_dev_table_overflow
  lan english -def
    RENDlib device table overflow.  Unable to open new device.
msg rend_ent_off_always
  lan english -def
    RENDlib 3D vertex desciptor entry is disable, although call was
    made for that entry to REND_SET.VERT3D_ENT_ON_ALWAYS.  The entry
    ID number is %p1i.
msg rend_enter_level_negative
  lan english -def
    REND_SET.ENTER_LEVEL was called with a negative argument.
msg rend_event_id_bad
  lan english -def
    Illegal or unimplemented event ID encountered in RENDlib.
    Event ID number is %p1i.
msg rend_event_pntmode_bad
  lan english -def
    Illegal or unimplemented 2D pointer motion handling strategy
    encountered in REND_EVENT_POINTER_MOVE.  ID was %p1i.
msg rend_event_stack_overflow
  lan english -def
    RENDlib pushed event stack everflow.  Too many events were pushed
    with routine REND_EVENT_PUSH.
msg rend_font_file_open
  lan english -def
    Error in RENDlib on reading "%p1s" font file.
msg rend_font_file_read
  lan english -def
    Error in RENDlib on attempt to open "%p1s" font file.
msg rend_font_table_overflow
  lan english -def
    RENDlib font table overflow.  Error occurred on reading
    font file "%p1s".
msg rend_image_too_tall
  lan english -def
    Image is too tall.  The number of scan lines exceeds RENDlib's limit.
msg rend_iterp_off_flat
  lan english -def
    RENDlib programming error:  Attempt to set interpolant flat value
    while interpolant is OFF.  Interpolant ID is %p1i.
msg rend_iterp_off_linear
  lan english -def
    RENDlib programming error:  Attempt to set interpolant linear values
    while interpolant is OFF.  Interpolant ID is %p1i.
msg rend_iterp_off_quad
  lan english -def
    RENDlib programming error:  Attempt to set interpolant
    quadratic values while interpolant is OFF.  Interpolant ID is %p1i.
msg rend_key_id_bad
  lan english -def
    Key ID %p1i is out of range.  Valid values for this device are
    from 1 to %p2i.
msg rend_light_acc_bad
  lan english -def
    Illegal, unimplemented, or unrecognized lighting accuray switch
    value of %p1i encountered.
msg rend_light_handle_bad
  lan english -def
    Invalid light source handle encountered in REND_SW_LIGHT_ON.
msg rend_light_not_exist
  lan english -def
    Handle to non-existant light source encountered in REND_SW_LIGHT_ON.
    The light source handle is invalid, or it may be a handle for a
    light source in another RENDlib device.
msg rend_light_type_unrecognized
  lan english -def
    Unexpected RENDlib light source ID %p1i encountered.
msg rend_mem_scope_bad
  lan english -def
    Illegal RENDlib memory scope specified.  Scope ID number was %p1i.
msg rend_open_recurse_limit
  lan english -def
    RENDlib device references too deep in renlib.dev environment files.
    This probably indicates circular references between two or more
    logical device names.
msg rend_parm_get_error
  lan english -def
    Error encountered on attempt to read next option from RENDlib
    device parameters string for the RENDlib %p1s device.
msg rend_parm_opt_bad
  lan english -def
    Unrecognized option "%p1s" in parameter string for RENDlib %p2s driver.
msg rend_parm_parm_error
  lan english -def
    Error occurred on processing parameter to %p1s option in RENDlib
    parameters string for device %p2s.
msg rend_parm_parm_bad
  lan english -def
    Bad parameter %p1s to option %p2s in parameters string for RENDlib
    %p3s device.
msg rend_qlock_create
  lan english -def
    Error attempt to create interlock for single threading access to the
    RENDlib event queue.
msg rend_ray_already_traced
  lan english -def
    Attempt was made to save new primitives in the ray tracing data base,
    although it has already been used to trace pixels.  New primitives
    may not be added once pixels are traced.
msg rend_ray_not_initialized
  lan english -def
    Ray tracing data base was never initialized on attempt to draw
    ray traced pixels.  Ray tracer primitive saving must have been
    enabled at least once since the RENDlib device was opened, or
    the last REND_SET.RAY_DELETE call.
msg rend_save_block_not_aligned
  lan english -def
    RENDlib internal error:  Start of new requested save/restore block
    does not have sufficient alignment.
msg rend_save_blocks_too_many
  lan english -def
    RENDlib internal error:  Too many save/restore blocks requested.
msg rend_tbpoint_shade_rule_bad
  lan english -def
    Illegal or unimplemented shading rule selected at a point along an
    extruded tube.  Shading rule ID number is %p1i.
msg rend_tmap_dim_bad
  lan english -def
    Illegal, unimplemented, or unexpected texture mapping dimension
    encountered.
msg rend_tmap_mip_nsquare
  lan english -def
    Texture map of size %p1i,%p2i passed to SET.TMAP_SRC with texture
    mapping method set to MIP-MAPPING.  All MIP-MAP texture maps must
    be square.
msg rend_tmap_nlog2
  lan english -def
    Texture map of size %p1i,%p2i passed to SET.TMAP_SRC.  Texture
    maps must be power of two sizes with the current modes.
msg rend_tmap_size_orange
  lan english -def
    Out of range texture map size of %p1i,%p2i passed to SET.TMAP_SRC.
msg rend_tmap_u_height_bad
  lan english -def
    One-dimensional texture map of height %p1i passed to SET.TMAP_SRC.
    Height may only be 1.
msg rend_tube_endcap_style_bad
  lan english -def
    Illegal or unimplemented tube endcap style.  Endcap style ID number is %p1i.
msg rend_txdraw_space_bad
  lan english -def
    Text has been piped to an illegal coordinate space.  Coordinate space
    ID number is %p1i.
msg rend_vect_end_style_bad
  lan english -def
    Unrecognized vector end style ID.
msg rend_vect_to_poly_space_bad
  lan english -def
    Bad coordinate space specified for vector to polygon conversion.
msg rend_vert_ent_offset_mod_bad
  lan english -def
    Bad vertex entry address offset %p1i.  Vertex address offsets
    must not be negative, and must be a multiple of the size of a pointer.
msg rend_wait_exit_return
  lan english -def
    Hit RETURN to exit:
msg rend_xsec_closed
  lan english -def
    Crossection has already been closed.  Operation not allowed on closed
    crossection definition.
msg rend_xsec_npoints_not_match
  lan english -def
    The number of points in two crossections don't match, although they
    were used along the same tube.
msg rend_zfunc_id_bad
  lan english -def
    Illegal, unimplemented, or unexpected RENDlib Z compare function ID
    encountered.  ID value was %p1i.
/*
/*   Messages used by X windows driver.
/*
msg x_bits_pixel_image
  lan english -def
    Unexpected stored bits per pixel encountered in X image descriptor.
    Found %p1i, expected 8, 16, or 32.
msg x_envvar_visual_not_number
  lan english -def
    Bad value encountered for RENDLIB_VISUAL environment variable.
    This variable, if present, must be set to the ID of a valid visual.
    Use the program X_VISUALS to get a list of available visuals.
msg x_envvar_visual_not_found
  lan english -def
    The environment variable RENDLIB_VISUAL specifies a visual id of
    %p1i, but no such visual exists.
    Use the program X_VISUALS to get a list of available visuals.
msg x_pixform_cpnt
  lan english -def
    INTERNAL ERROR: Unexpected current pixel format encountered
    in REND_X_CPNT_2DIMI.  PIXFORM value was %p1i.
    Please report this error to Cognivision as soon as possible.
    Phone: (508) 392-0881, Fax: (508) 392-0882.
msg x_pixform_checkmodes
  lan english -def
    INTERNAL ERROR: Unexpected current pixel format encountered
    in REND_X_CHECK_MODES.  PIXFORM value was %p1i.
    Please report this error to Cognivision as soon as possible.
    Phone: (508) 392-0881, Fax: (508) 392-0882.
msg x_pixform_update_span
  lan english -def
    INTERNAL ERROR: Unexpected current pixel format encountered
    in REND_X_UPDATE_SPAN.  PIXFORM value was %p1i.
    Please report this error to Cognivision as soon as possible.
    Phone: (508) 392-0881, Fax: (508) 392-0882.
msg x_query_tree
  lan english -def
    Error encountered on call to XQueryTree.
msg x_select_event_zmouse
  lan english -def
    Error from XSelectExtensionEvent on select ZMouse events.
    Function return value was %p1i.
msg x_wind_attr_get
  lan english -def
    Error encountered on call to XGetWindowAttributes.
/*
/*   Messages used to support PEX.
/*
msg pex_clip_not_supported
  lan english -def
    Current RENDlib clipping environment is not supported in the
    RENDlib PEX driver.  There may be at most one 2DIM clip rectangle,
    and it must be draw inside, clip outside type.
msg pex_err_get_pipe_context
  lan english -def
    Call to PEXGetPipelineContext failed.
msg pex_err_get_rend_attr
  lan english -def
    Call to PEXGetRendererAttributes failed.
msg pex_err_get_table_info
  lan english -def
    Call to PEXGetTableInfo failed.
msg pex_err_view_map_mat
  lan english -def
    Call to PEXViewMappingMatrix failed, return value = %p1i.
msg pex_get_enum_info_error
  lan english -def
    Error occurred on call to PEXGetEnumTypeInfo.
msg pex_init_error
  lan english -def
    Error on call to PEXInitialize.  Returned value is %p1i,
    error string is "%p2s".
msg pex_poly_2dim_overflow
  lan english -def
    Too many (%p1i) verticies passed to REND_PEX_POLY_2DIM.
    A maximum of %p2i verticies are allowed.  This value is indicated
    by the constant REND_MAX_VERTS.
/*
/*   Messages used by GL part of X windows driver.
/*
msg xgl_buffer_id_bad
  lan english -def
    Unexpected buffer type encountered in GLX configuration array.
    Buffer ID value is %p1i.
msg xgl_lmdef_ar_overflow
  lan english -def
    INTERNAL ERROR (RENDlib XGL): Overflow of LMDEF_AR in
    REND_XGL_LMODEL_SET.
msg xgl_mode_id_bad
  lan english -def
    Unexpected mode type encountered in GLX configuration array.
    Mode ID value is %p1i.
/*
/*   Messages used by the DBUF driver.
/*
msg dbuf_rewind
  lan english -def
    Error on re-positioning .DBUF file to start of file.
msg dbuf_write
  lan english -def
    Error on trying to write to .DBUF file.
/*
/*   Messages used by GPR driver.
/*
msg gpr_dith_bad_size
  lan english -def
    INTERNAL ERROR: Dither pattern is not of a size for which
    thresholds are available.  Error in RENDlib GPR driver.
    Requested dither pattern size is %p1i x %p2i.
msg gpr_dith_too_big
  lan english -def
    INTERNAL ERROR: Dither pattern too big for internal array
    in RENDlib GPR driver.  Desired dither pattern is %p1i x %p2i.
    Max allowed dither pattern size is %p3i x %p4i.
msg gpr_inq_config
  lan english -def
    Error on call to GPR_$INQ_CONFIG.
msg gpr_lut_size_err
  lan english -def
    INTERNAL ERROR: More color LUT entries used than exist in
    RENDlib GPR driver.  LUT size is %p1i entries, while %p2i
    entries are needed.
msg gpr_lut_too_big
  lan english -def
    INTERNAL_ERROR: Color LUT is too big for internal array
    in RENDlib GPR driver.  Desired LUT size is %p1i.
    Max allowed LUT size is %p2i.
/*
/*   Messages used by GMR driver.
/*
msg gmr_window_resize
  lan english -def
    Attempt to re-size window.  Due to a bug in the Apollo 3D GMR
    library, the window may not be re-sized when 3D GMR is used.
/*
/*   Messages used by TGA driver.
/*
msg tga_dith_bad_size
  lan english -def
    INTERNAL ERROR: Dither pattern is not of a size for which
    thresholds are available.  Error in RENDlib TGA driver.
    Requested dither pattern size is %p1i x %p2i.
msg tga_dith_too_big
  lan english -def
    INTERNAL ERROR: Dither pattern too big for internal array
    in RENDlib TGA driver.  Desired dither pattern is %p1i x %p2i.
    Max allowed dither pattern size is %p3i x %p4i.
/*
/*   Messages used by test routines.
/*
msg test_3dt_pane2
  lan english -def
    Error on opening RENDlib device for drawing into top left window.
msg test_3dt_pane3
  lan english -def
    Error on opening RENDlib device for drawing into bottom left window.
msg test_3dt_gpr_enable
  lan english -def
    Error on GPR call to enable keystroke events.
msg test_3dt_gpr_event
  lan english -def
    Error on GPR call to get next event.
msg test_shade_geom_bad
  lan english -def
    The -GEOM value is out of range.
msg test_shade_geom_lt_iterp
  lan english -def
    The -GEOM value is less than the -ITERP value.
msg test_shade_iterp_bad
  lan english -def
    The -ITERP value is out of range.
