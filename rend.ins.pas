{   Public include file for RENDlib.
}
const
  rend_subsys_k = -9;                  {RENDlib's subsystem ID}
{
*   Mnemonics for status values unique to the RENDlib subsystem.
}
  rend_stat_no_device_k = 1;           {no device found on initialization}
  rend_stat_dev_cmd_err_k = 2;         {error getting cmd name from dev PARMS string}
  rend_stat_dev_cmd_bad_k = 3;         {bad command in device PARMS string}
  rend_stat_dev_parm_err_k = 4;        {error getting parm from dev PARMS string}
  rend_stat_dev_parm_bad_k = 5;        {bad parameter in device PARMS string}
  rend_stat_ray_no_bounds_k = 6;       {no bounds exist yet for saved ray primitives}
{
*   Configuration constants.
}
  rend_max_verts = 100;                {max number of verticies in a polygon}
  rend_cache_version_invalid = 16#80000000; {cache version to indicate invalid data}
  rend_max_called_prims = 4;           {max nested primitives called from parent prim}
  rend_max_opens = 8;                  {max simultaneously open graphics connections}
{
*   Special device ID indicating no device.
}
  rend_dev_none_k = 0;                 {indicates no RENDlib device}
{
*   Mnemonic names for the interpolation modes.  The value of each constant
*   reflects the polynomial order of its iterpolation mode.
}
  rend_iterp_mode_none_k = -1;         {for SHADE_MODE, means don't touch iterp}
  rend_iterp_mode_flat_k = 0;          {constant value, no interpolation}
  rend_iterp_mode_linear_k = 1;        {linear interpolation (Gouroud shading)}
  rend_iterp_mode_quad_k = 2;          {quadratic (second order) interpolation}
{
*   Number of distinct CIRRES parameters maintained.  Each cirres (circle
*   resolution) parameter specifies the minimum number of line segments that
*   are allowed to approximate a full circle.  These values effect tessilation
*   "fineness".  There are 1 thru REND_LAST_CIRRES_K independent CIRRES values
*   maintained.  Some primitives may allow different tessilation levels along
*   different dimensions.  CIRRES 1 is for the first or "major" axis, CIRRES 2
*   for the secondary axis, if any, etc.  For example, sphere tessilation is
*   governed only by CIRRES 1, whereas torus tessilation would be governed
*   by CIRRES 1 and 2.
}
  rend_last_cirres_k = 3;              {CIRRES values 1-3 are maintained}

type
  rend_iterp_mode_k_t = sys_int_machine_t;
{
*   The following constants identify particular interpolants.  Any changes
*   to this list must also be made to REND_ITERPS_T in REND_SW.INS.PAS.
}
  rend_iterp_k_t = (
    rend_iterp_red_k,                  {red}
    rend_iterp_grn_k,                  {green}
    rend_iterp_blu_k,                  {blue}
    rend_iterp_z_k,                    {Z (depth)}
    rend_iterp_alpha_k,                {alpha (opacity fraction)}
    rend_iterp_i_k,                    {integer value, used with picking}
    rend_iterp_u_k,                    {horizontal texture map index}
    rend_iterp_v_k);                   {vertical texture map index}

  rend_iterps_t =                      {all possible interpolants in one set}
    set of rend_iterp_k_t;

const
  rend_n_iterps_k =                    {number of RENDlib interpolants}
    ord(lastof(rend_iterp_k_t)) - ord(firstof(rend_iterp_k_t)) + 1;

type
{
*   Mnemonic names for the low level pixel write functions.
}
  rend_pixfun_k_t = (
    rend_pixfun_insert_k,              {pixel <-- new value}
    rend_pixfun_add_k,                 {pixel <-- old + new}
    rend_pixfun_sub_k,                 {pixel <-- old - new}
    rend_pixfun_subi_k,                {pixel <-- new - old}
    rend_pixfun_and_k,                 {pixel <-- old and new (bitwise logical and)}
    rend_pixfun_or_k,                  {pixel <-- old or new (bitwise logical or)}
    rend_pixfun_xor_k,                 {pixel <-- old xor new (bitwise logical xor)}
    rend_pixfun_not_k);                {pixel <-- not new (bitwise invert of new val)}
{
*   Mnemonic names for the Z functions.
}
  rend_zfunc_k_t = (
    rend_zfunc_never_k,                {draw never}
    rend_zfunc_gt_k,                   {draw if new > old}
    rend_zfunc_ge_k,                   {draw if new >= old}
    rend_zfunc_eq_k,                   {draw if new = old}
    rend_zfunc_ne_k,                   {draw if new <> old}
    rend_zfunc_le_k,                   {draw if new <= old}
    rend_zfunc_lt_k,                   {draw if new < old}
    rend_zfunc_always_k);              {draw always}
{
*   Mnemonic names for the ALPHA buffering compositing functions.  See paper by
*   Porter and Duff, "Compositing Digital Images", Computer Graphics, Vol. 18,
*   No. 3, July 1984, pages 253-259.
*
*   The names are from the table on page 256, assuming that the new interpolated
*   value is image A, and the existing image is image B.  The letter "R" in front
*   of the name stands for "reverse" and is used when image B is said to apply to
*   image A.  For example our name "over" is the function called "A over B" in the
*   table.  Our name "rover" is the function called "B over A" in the table.
}
  rend_afunc_k_t = (
    rend_afunc_clear_k,                {val = NEW(0) + OLD(0)}
    rend_afunc_a_k,                    {val = NEW(1) + OLD(0)}
    rend_afunc_b_k,                    {val = NEW(0) + OLD(1)}
    rend_afunc_over_k,                 {val = NEW(1) + OLD(1-Anew)}
    rend_afunc_rover_k,                {val = NEW(1-Aold) + OLD(1)}
    rend_afunc_in_k,                   {val = NEW(Aold) + OLD(0)}
    rend_afunc_rin_k,                  {val = NEW(0) + OLD(Anew)}
    rend_afunc_out_k,                  {val = NEW(1-Aold) + OLD(0)}
    rend_afunc_rout_k,                 {val = NEW(0) + OLD(1-Anew)}
    rend_afunc_atop_k,                 {val = NEW(Aold) + OLD(1-Anew)}
    rend_afunc_ratop_k,                {val = NEW(1-Aold) + OLD(Anew)}
    rend_afunc_xor_k);                 {val = NEW(1-Aold) + OLD(1-Anew)}
{
*   Mnemonic names for all the possible types of interpolation steps.
}
  rend_iterp_step_k_t = (
    rend_iterp_step_a_k,               {edge or vector step in Bresenham A direction}
    rend_iterp_step_b_k,               {edge or vector step in Bresenham B direction}
    rend_iterp_step_h_k);              {horizontal step in trapezoid span}
{
*   Mnemonic names for identifying a particular coordinate space in the rendering
*   pipe.  The floating point coordinate spaces must be in a contiguous block.
}
  rend_space_k_t = (
    rend_space_none_k,                 {no space specified, feature not used}
    rend_space_2dimi_k,                {2D integer image coordinate space}
    rend_space_2dim_k,                 {2D floating point image coordinate space}
    rend_space_2dimcl_k,               {2DIM coordinates before clip}
    rend_space_2d_k,                   {2D model coordinate space (before 2D xform)}
    rend_space_2dcl_k,                 {2D coordinates before clip}
    rend_space_3dw_k,                  {3D world coordinate space (before persp)}
    rend_space_3dwpl_k,                {2D current plane into 3DW space}
    rend_space_3dwcl_k,                {3DW space before clipping}
    rend_space_3d_k,                   {3D model coordinate space}
    rend_space_3dpl_k,                 {2D current plane into 3D space}
    rend_space_text_k,                 {current character cell coordinate space}
    rend_space_txdraw_k);              {space that text output is switched to}

const
  rend_space_firstfp_k = rend_space_2dim_k; {min ID of a floating point coor space}
  rend_space_lastfp_k = rend_space_txdraw_k; {max ID of a floating point coor space}

type
{
*   Mnemonic names for selecting vector end styles.
}
  rend_end_style_k_t = (
    rend_end_style_invalid_k,          {style not set, used internally}
    rend_end_style_rect_k,             {straight rectangular cutoff}
    rend_end_style_circ_k);            {semicircular}
{
*   Mnemonic names for identifying a point associated with a text string.
*   These points are the corners, edge centers, and middle of the box around the text
*   string.  The current point usually starts out and is left at one of these points.
}
  rend_torg_k_t = (
    rend_torg_ul_k,                    {upper left}
    rend_torg_um_k,                    {upper middle}
    rend_torg_ur_k,                    {upper right}
    rend_torg_ml_k,                    {middle left}
    rend_torg_mid_k,                   {middle}
    rend_torg_mr_k,                    {middle right}
    rend_torg_ll_k,                    {lower left}
    rend_torg_lm_k,                    {lower middle}
    rend_torg_lr_k,                    {lower right}
    rend_torg_down_k,                  {down char height + lspace from start point}
    rend_torg_up_k);                   {up char height + lspace from start point}
{
*   Mnemonic names for STATE variable values in CLIP calls.
}
  rend_clip_state_k_t = (
    rend_clip_state_start_k,           {set by caller to indicate first call}
    rend_clip_state_last_k,            {returned with last clipped fragment}
    rend_clip_state_end_k);            {returned with empty fragment, no more left}
{
*   Mnemonic names for texture mapping dimension levels.
}
  rend_tmapd_k_t = (
    rend_tmapd_u_k,                    {one dimensional map, use U only}
    rend_tmapd_uv_k,                   {two dimensional map, use U,V}
    rend_tmapd_uvw_k);                 {three dimensional map, use U,V,W}
{
*   Mnemonic names for texture mapping function identifiers.
}
  rend_tmapf_k_t = (
    rend_tmapf_insert_k,               {use texture map value directly}
    rend_tmapf_ill_k);                 {texture value is diff color, apply lights}
{
*   Mnemonic names for texture mapping method identifiers.
}
  rend_tmapm_k_t = (
    rend_tmapm_mip_k,                  {pyramidal mip-map scheme}
    rend_tmapm_unused_k);              {for internal use only, DON'T USE THIS VALUE}
{
*   Mnemonic names for texture mapping filtering methods.
}
  rend_tmapfilt_k_t = (
    rend_tmapfilt_maps_k,              {blend between adjacent size maps}
    rend_tmapfilt_pix_k);              {blend between adjacent pixels vert and horiz}

  rend_tmapfilt_t =                    {all the filtering flags in one word}
    set of rend_tmapfilt_k_t;
{
*   Mnemonic names for texture mapping accuracy modes.
}
  rend_tmapaccu_k_t = (
    rend_tmapaccu_exact_k,             {exact, SW device is the reference}
    rend_tmapaccu_dev_k);              {limited approximations OK for HW fit, etc.}
{
*   Mnemonic names for all the backfacing operations.
}
  rend_bface_k_t = (
    rend_bface_off_k,                  {polygon drawn with normals "as is"}
    rend_bface_front_k,                {draw polygon only if front side is visible}
    rend_bface_back_k,                 {draw polygon only if back side is visible}
    rend_bface_flip_k);                {if front visible then draw normally, if back
                                        visible, then flip normals, and use surface
                                        properties for back face (if enabled)}
{
*   Mnemonic names for various surface properties.
}
  rend_suprop_k_t = (
    rend_suprop_emis_k,                {emissive color, unefected by lights}
    rend_suprop_diff_k,                {diffuse reflection, unefected by view angle}
    rend_suprop_spec_k,                {specular reflection}
    rend_suprop_trans_k);              {surface transparency}
{
*   Mnemonic names for front/back side of a polygon.
}
  rend_face_k_t = (
    rend_face_front_k,                 {front side of polygon.  This is the visible
                                        side when the verticies are travesed in
                                        counter-clockwise direction}
    rend_face_back_k);                 {back side of polygon}
{
*   Mnemonic names and other constants relating to all the modes that can
*   automatically change when some other state is changed.  These are all the
*   modes that can be returned by the call GET.CMODES.
}
  rend_cmode_k_t = (
    rend_cmode_dithon_k,               {dithering on/off flag}
    rend_cmode_maxbuf_k,               {number of buffers for display or drawing}
    rend_cmode_dispbuf_k,              {current display buffer number}
    rend_cmode_drawbuf_k,              {current drawing buffer number}
    rend_cmode_minbits_vis_k,          {minimum effective visible bits per pixel}
    rend_cmode_minbits_hw_k);          {minimum actual hardware bits per pixel}

const
  rend_n_cmodes_k =                    {total number of changeable modes}
    ord(lastof(rend_cmode_k_t)) - ord(firstof(rend_cmode_k_t)) + 1;

type
{
*   Mnemonic names for describing what what kind of access each primitive requires
*   of the software bitmap.  They must be in order so that if more than one type of
*   access occurs, the higher number is reported.
}
  rend_access_k_t = (
    rend_access_inherited_k,           {access is inherited from called routines}
    rend_access_no_k,                  {this access definately does not occurr}
    rend_access_yes_k);                {this access definately does occurr}
{
*   Mnemonic names for lightsource types.
}
  rend_ltype_k_t = (
    rend_ltype_amb_k,                  {ambient light source}
    rend_ltype_dir_k,                  {directional light source}
    rend_ltype_pnt_k,                  {point light source, no falloff}
    rend_ltype_pr2_k);                 {point light source, 1/R**2 falloff}
{
*   Mnemonic names for lighting calculation accuracy modes.
}
  rend_laccu_k_t = (
    rend_laccu_exact_k,                {exact, SW device is the reference}
    rend_laccu_dev_k);                 {approximations OK if allows faster HW use}
{
*   Mnemonics names to declare scope when allocating memory with RENDlib.
*   This effects when, if ever, RENDlib will automatically deallocate the memory.
}
  rend_scope_t = (
    rend_scope_sys_k,                  {above RENDlib, not released automatically}
    rend_scope_rend_k,                 {all of RENDlib, released on REND_END}
    rend_scope_dev_k);                 {current device, released on REND_SET.CLOSE}
{
*   Mnemonics for flags that get passed to REND_GET.WAIT_EXIT.
}
  rend_waitex_k_t = (
    rend_waitex_msg_k);                {write message explaining what to do to exit}

  rend_waitex_t =                      {all the flags in one word}
    set of rend_waitex_k_t;
{
*   Mnemonic names for each of the separate pieces of information that can be
*   put in a 3D vertex descriptor.
}
  rend_vert3d_ent_vals_t = (
    rend_vert3d_coor_p_k,              {pointer to XYZ coordinate}
    rend_vert3d_norm_p_k,              {pointer to shading normal vector}
    rend_vert3d_diff_p_k,              {pointer to RGBA diffuse override colors}
    rend_vert3d_tmapi_p_k,             {pointer to UVW texture map indicies}
    rend_vert3d_vcache_p_k,            {pointer to vertex cache}
    rend_vert3d_ncache_p_k,            {pointer to shading normal vector cache}
    rend_vert3d_spokes_p_k);           {pointer to spokes list to make shading normal}
{
*   Mnemonics for special RENDlib key IDs.
}
const
  rend_key_none_k = 0;                 {specifically indicates no key}

type
{
*   Mnemonics for RENDlib pre-defined special keys that are referenced by their
*   function.  These keys can be "found" more quickly and simply than arbitrary
*   explicit keys.  A particular special key is usually specified by one of
*   the mnemonics here (except REND_KEY_SP_NONE_K), and some additional data.
*   This is all bound together in REND_KEY_SP_DATA_T.
}
  rend_key_sp_k_t = (                  {IDs for special but common keys}
    rend_key_sp_none_k,                {not a RENDlib special key}
    rend_key_sp_func_k,                {numbered function keys, usually 0-N or 1-N}
    rend_key_sp_pointer_k,             {keys on pointer device 1-N is left to right}
    rend_key_sp_arrow_left_k,          {regular arrow keys}
    rend_key_sp_arrow_right_k,
    rend_key_sp_arrow_up_k,
    rend_key_sp_arrow_down_k);
{
*   Mnemonics for all the modifier keys.  These keys modify the behaviour of
*   other keys.
}
  rend_key_mod_k_t = (                 {IDs for each of the possible modifier keys}
    rend_key_mod_shift_k,              {SHIFT key}
    rend_key_mod_shiftlock_k,          {SHIFT LOCK or CAPS LOCK}
    rend_key_mod_ctrl_k,               {control key}
    rend_key_mod_alt_k);               {ALT or other auxilliary modifier key}

  rend_key_mod_t =                     {state for each modifier key in one word}
    set of rend_key_mod_k_t;
{
*   Mnemonics for each of the possible event types.
}
  rend_ev_k_t = (                      {identifies a RENDlib event type}
    rend_ev_none_k,                    {no event occurred}
    rend_ev_close_k,                   {draw device closed, RENDlib dev still open}
    rend_ev_resize_k,                  {drawing area changed size}
    rend_ev_wiped_rect_k,              {rectangle of pixels wiped out, now redrawable}
    rend_ev_wiped_resize_k,            {all pixels wiped out, now redrawable}
    rend_ev_key_k,                     {a user-pressable key changed state}
    rend_ev_pnt_enter_k,               {pointer entered draw area}
    rend_ev_pnt_exit_k,                {pointer left draw area}
    rend_ev_pnt_move_k,                {pointer location changed}
    rend_ev_close_user_k,              {user requested close of graphics device}
    rend_ev_stdin_line_k,              {line of text has been read from standard in}
    rend_ev_xf3d_k,                    {3D transform}
    rend_ev_app_k,                     {arbitrary application specific event}
    rend_ev_call_k);                   {transparently call routine}
{
*   Mnemonics used to control how the display is updated when primitives are
*   being rendered with software emulation.  These constants are passed to
*   REND_SET.UPDATE_MODE to indicate how much buffering is allowed/desired
*   before the display is updated.  The display is always updated whenever
*   REND_PRIM.FLUSH_ALL is called, regardless of the update mode.  Note that
*   exiting graphics mode causes REND_PRIM.FLUSH_ALL to be called.
}
  rend_updmode_k_t = (
    rend_updmode_live_k,               {little buff, should appear "live" to user}
    rend_updmode_buffall_k);           {buffer as much as possible to gain speed}
{
*   Mnemonic names for the major coordinate axes.
}
  rend_axis_k_t = (                    {ID for each major coordinate axis}
    rend_axis_x_k,
    rend_axis_y_k,
    rend_axis_z_k);

  rend_axes_t =                        {set of all major coordinate axes}
    set of rend_axis_k_t;
{
*   Mnemonic names for the benchmark flags.  These flags can be accessed
*   by the application with explicit SET/GET calls, and are automatically
*   initialized from the environment variable RENDLIB_BENCH.  These flags
*   should all be disabled for normal operation.  The flags are intended
*   to help in timing tests to determine how long it takes to perform
*   specific parts of operations that are otherwise indivisible.
}
  rend_bench_k_t = (                   {ID for each benchmark flag}
    rend_bench_dumprim_k,              {RENDlib primitives just return}
    rend_bench_nogr_k,                 {return before calling underlying graphics}
    rend_bench_dumgr_k,                {dummy calls instead of underlying graphics}
    rend_bench_no2d_k);                {3D prims return before calling 2D layer}

  rend_bench_t =                       {all the benchmark flags in one word}
    set of rend_bench_k_t;
{
*   End of mnemonic constants.
}
  rend_dev_id_t = sys_int_machine_t;   {user handle to a RENDlib device}

  rend_prim_data_pp_t =                {pointer to data block pointer in call table}
    ^rend_prim_data_p_t;

  rend_prim_data_p_t = ^rend_prim_data_t;
  rend_prim_data_t = record            {data block for each PRIM call table entry}
    call_adr: univ_ptr;                {entry point address for this primitive}
    name: string_var32_t;              {full primitive subroutine entry name}
    self_p: rend_prim_data_p_t;        {points to this PRIM_DATA block for self ref}
    sw_read: rend_access_k_t;          {reading SW bitmap, use REND_ACCESS_xxx_K}
    sw_write: rend_access_k_t;         {writing to SW bitmap, use REND_ACCESS_xxx_K}
    sw_read_res: rend_access_k_t;      {SW_READ with inheritance resolved}
    sw_write_res: rend_access_k_t;     {SW_WRITE with inheritance resolved}
    res_version: sys_int_machine_t;    {version ID for resolved flags}
    n_prims: sys_int_machine_t;        {number of nested called primitives}
    called_prims:                      {list of all nested called primitives}
      array[1..rend_max_called_prims] of rend_prim_data_pp_t;
    end;

  rend_cmode_vals_t = record           {saved state of all the changeable modes}
    max_buf: sys_int_machine_t;        {number of buffers available, for double buff}
    disp_buf: sys_int_machine_t;       {current displayed buffer number}
    draw_buf: sys_int_machine_t;       {current drawing buffer number}
    min_bits_vis: real;                {min required eff. color resolution in bits}
    min_bits_hw: real;                 {min required actual hardware color bits}
    dith_on: boolean;                  {dithering on/off flag}
    end;

  rend_poly_parms_t = record           {modes and switches for polygon drawing}
    subpixel: boolean;                 {TRUE if use subpixel addressing}
    end;

  rend_end_style_t = record            {descriptor for vector end style}
    style: rend_end_style_k_t;         {end cap style selector}
    nsides: sys_int_machine_t;         {number of sides for semi-circle style type}
    end;

  rend_vect_parms_t = record           {modes and swithes for vect to poly convert}
    width: real;                       {total width of vector if make polygon}
    poly_level: rend_space_k_t;        {which level, if any, to convert to polygon}
    start_style: rend_end_style_t;     {what shape to make start of vector cap}
    end_style: rend_end_style_t;       {what shape to make end of vector cap}
    subpixel: boolean;                 {TRUE if use supixel adr instead of integer}
    end;

  rend_text_parms_t = record           {state controlling how text is drawn}
    size: real;                        {overall absolute character cell size}
    width: real;                       {relative character cell width}
    height: real;                      {relative character cell height}
    slant: real;                       {radians clockwise character slant}
    rot: real;                         {radians counter-clockwise rotation}
    lspace: real;                      {space between lines is (LSPACE * SIZE)}
    vect_width: real;                  {font vector width in char cell coordinates}
    font: string_treename_t;           {pathname of font file}
    coor_level: rend_space_k_t;        {what coordinate space to draw text into}
    start_org: rend_torg_k_t;          {TORG where string anchored to current point}
    end_org: rend_torg_k_t;            {TORG where current point left after string}
    poly: boolean;                     {TRUE if draw font vectors as polygons}
    end;

  rend_clip_2dim_handle_t =            {user handle to 2D image space clip window}
    sys_int_machine_t;

  rend_bitmap_handle_t = univ_ptr;     {user handle to a bitmap}

  rend_int_ar_t =                      {for variable length integer array call args}
    array[1..1] of sys_int_machine_t;

  rend_int_ar_p_t =                    {pointer to array of integers}
    ^rend_int_ar_t;

  rend_real_ar_t =                     {for variable length real array call args}
    array[1..1] of real;

  rend_real_ar_p_t =                   {pointer to array of scalar real numbers}
    ^rend_real_ar_t;

  rend_2dverts_t =                     {array of 2D polygon verticies}
    array[1..rend_max_verts] of vect_2d_t;

  rend_2dverts_p_t =                   {pointer to list of XY coordinates}
    ^rend_2dverts_t;

  rend_2dvect_t = record               {template for 2D vector start and end coor}
    p1: vect_2d_t;                     {start point}
    p2: vect_2d_t;                     {end point}
    end;

  rend_color3d_t = record              {template for 3D coordinate with color value}
    x, y, z: real;                     {3D coordinate}
    red, grn, blu: real;               {color value in 0.0 to 1.0 range}
    end;

  rend_rgba_p_t = ^rend_rgba_t;
  rend_rgba_t = record                 {red, green, blue, and alpha value}
    case integer of
      1: (                             {individually named fields}
        red: single;
        grn: single;
        blu: single;
        alpha: single);
      2: (                             {for indexing thru colors}
        color: array[0..3] of single);
    end;

  rend_uvw_p_t = ^rend_uvw_t;
  rend_uvw_t = record                  {texture index parameters}
    u, v, w: single;
    end;

  rend_light_p_t = ^rend_light_t;
  rend_light_pp_t = ^rend_light_p_t;
  rend_light_t = record                {internal light source descriptor}
    next_p: rend_light_p_t;            {pointer to next descriptor in chain}
    prev_pp: rend_light_pp_t;          {point to previous lsource's NEXT_P}
    next_on_p: rend_light_p_t;         {pointer to next ON light source in chain}
    prev_on_pp: rend_light_pp_t;       {point to previous ON lsource's NEXT_ON_P}
    ltype: rend_ltype_k_t;             {light source type, use REND_LTYPE_xxx_K}
    used: boolean;                     {TRUE if user has handle to this light source}
    on: boolean;                       {TRUE if this light is turned on}
    case rend_ltype_k_t of             {different data for each type of light source}
rend_ltype_amb_k: (                    {ambient}
      amb_red: real;                   {light source color}
      amb_grn: real;
      amb_blu: real);
rend_ltype_dir_k: (                    {directional}
      dir_red: real;                   {light source color}
      dir_grn: real;
      dir_blu: real;
      dir: vect_3d_t);                 {unit vector to light source}
rend_ltype_pnt_k: (                    {point light source, no falloff}
      pnt_red: real;                   {light source color}
      pnt_grn: real;
      pnt_blu: real;
      pnt: vect_3d_t);                 {light source coordinate}
rend_ltype_pr2_k: (                    {point light source, 1/R**2 falloff}
      pr2_red: real;                   {light source color at radius}
      pr2_grn: real;
      pr2_blu: real;
      pr2_coor: vect_3d_t;             {light source coordinate}
      pr2_r2: real);                   {square of radius at which colors apply}
    end;

  rend_light_handle_t =                {user handle to a light source}
    rend_light_p_t;

  rend_light_handle_ar_t =             {arbitrary array of light source handles}
    array[1..1] of rend_light_handle_t;

  rend_vect3d_ar_t =                   {arbitrary array of XYZ descriptors}
    array[1..1] of vect_3d_t;          {used for call arguments}

  rend_light_val_t = record            {user data for one light source of any type}
    case rend_ltype_k_t of             {different data for each type of light source}
    rend_ltype_amb_k: (                {ambient light source}
      amb_red: real;                   {light source color}
      amb_grn: real;
      amb_blu: real);
    rend_ltype_dir_k: (                {directional light source}
      dir_red: real;                   {light source color}
      dir_grn: real;
      dir_blu: real;
      dir_unorm: vect_3d_t);           {unit normal vector towards light source}
    rend_ltype_pnt_k: (                {point light source, spherical, no fall off}
      pnt_red: real;                   {light source color}
      pnt_grn: real;
      pnt_blu: real;
      pnt_coor: vect_3d_t);            {coordinates of light source}
    rend_ltype_pr2_k: (                {point light source, 1/R**2 fall off}
      pr2_red: real;                   {light source color}
      pr2_grn: real;
      pr2_blu: real;
      pr2_coor: vect_3d_t;             {light source coordinate}
      pr2_r: real);                    {radius at which colors are correct}
    end;

  rend_vcache_p_t = ^rend_vcache_t;
  rend_vcache_t = record               {cached data for one polygon vertex}
    version: sys_int_machine_t;        {must match curr version for cache to be valid}
    clip_mask: sys_int_machine_t;      {each 1 bit indicates outside one clip limit}
    x3dw, y3dw, z3dw: single;          {3D world space coordinate of vertex}
    shnorm: vect_3d_fp1_t;             {unit shading normal used to make colors}
    x, y: single;                      {2DIM coordinates of vertex}
    z: single;                         {Z interpolant value at this vertex}
    color: rend_rgba_t;                {final color value at this vertex}
    illr, illg, illb: single;          {diffuse illumination color}
    colors_valid: boolean;             {TRUE if color/interpolant info is valid}
    flip_shad: boolean;                {TRUE if colors made from flipped normal}
    end;

  rend_ncache_flags_t = packed record case integer of {combined flags word for ncache}
    1:(                                {separate fields}
      unitized: 0..1;                  {1 means normal vector is of unit length}
      version: -1073741824..1073741823); { = REND_NCACHE_VERSION for validity}
    2:(                                {all the fields together}
      all: integer32);
    end;

  rend_ncache_p_t = ^rend_ncache_t;
  rend_ncache_t = record               {cached data about derived shading normal}
    flags: rend_ncache_flags_t;        {UNITIZED and VERSION fields in 32 bits}
    norm: vect_3d_fp1_t;               {shading normal to use for this vertex}
    end;

  rend_vert3d_p_t =                    {pointer to arbitrary vertex descriptor}
    ^rend_vert3d_t;

  rend_spokes_ent_t = record           {one spoke descriptor in spokes list}
    spoke_p: rend_vert3d_p_t;          {points to vertex along spoke}
    cent_p: rend_vert3d_p_t;           {points to center vertex for this V}
    end;

  rend_spokes_t = record               {set of spokes used to make a shading normal}
    max_ind: 0..65535;                 {MAX valid V array index}
    loop: boolean;                     {TRUE if last and first vertex make a V}
    vert_p_ar:                         {one entry for each spoke}
      array[0..0] of rend_spokes_ent_t; {valid array indicies are 0..MAX_IND}
    end;

  rend_spokes_p_t =                    {pointer to normal vector spokes list}
    ^rend_spokes_t;

  rend_spokes_flip_bits_word_t =       {one word of flip bits}
    integer32;                         {1 - flipped, 0 = not flipped for each bit}

  rend_spokes_flip_ar_t =              {flip flag for each V in spokes list}
    array[0..0] of rend_spokes_flip_bits_word_t; {one element for each 32 flip bits}

  rend_spokes_flip_ar_p_t =            {pointer to per-V flip flags array}
    ^rend_spokes_flip_ar_t;

  rend_spokes_lists_t = record         {all the spokes sets for one node}
    n: sys_int_machine_t;              {number of spokes sets}
    first_set: rend_spokes_t;          {first set, var len, others follow directly}
    end;

  rend_spokes_lists_p_t =              {pointer to all spokes sets data of one node}
    ^rend_spokes_lists_t;

  rend_v_list_ent_t = record           {descriptor for one V in V list}
    v1_p: rend_vert3d_p_t;             {pointers to the "other" verts in any order}
    v2_p: rend_vert3d_p_t;
    end;

  rend_v_list_t =                      {list of unsorted Vs for one vertex}
    array[1..1] of rend_v_list_ent_t;

  rend_vert3d_ent_t = record           {possible data for each VERT3D entry}
    case rend_vert3d_ent_vals_t of
      rend_vert3d_coor_p_k: (coor_p: vect_3d_fp1_p_t);
      rend_vert3d_norm_p_k: (norm_p: vect_3d_fp1_p_t);
      rend_vert3d_diff_p_k: (diff_p: rend_rgba_p_t);
      rend_vert3d_tmapi_p_k: (tmapi_p: rend_uvw_p_t);
      rend_vert3d_vcache_p_k: (vcache_p: rend_vcache_p_t);
      rend_vert3d_ncache_p_k: (ncache_p: rend_ncache_p_t);
      rend_vert3d_spokes_p_k: (spokes_p: rend_spokes_p_t);
    end;

  rend_vert3d_t =                      {descriptor for one general 3D polygon vertex}
    array[0..0] of rend_vert3d_ent_t;

  rend_vert3d_p_list_t =               {list of pointers to vertex descriptors}
    array[1..1] of rend_vert3d_p_t;

  rend_suprop_val_t =                  {data for one surface property of any kind}
      record case rend_suprop_k_t of
    rend_suprop_emis_k: (              {emissive color}
      emis_red: real;
      emis_grn: real;
      emis_blu: real);
    rend_suprop_diff_k: (              {diffuse reflection}
      diff_red: real;
      diff_grn: real;
      diff_blu: real);
    rend_suprop_spec_k: (              {specular reflection}
      spec_red: real;
      spec_grn: real;
      spec_blu: real;
      spec_exp: real);                 {specular exponent}
    rend_suprop_trans_k: (             {transparency}
      trans_front: real;               {0.0 to 1.0 opacity for facing eye point}
      trans_side: real);               {0.0 to 1.0 opacity for facing sideways}
    end;

  rend_rgb_t = record                  {one red, green, blue color descriptor}
    red, grn, blu: real;
    end;

  rend_suprop_t = record               {visual properties of a surface}
    emis: rend_rgb_t;                  {emissive color}
    diff: rend_rgb_t;                  {diffuse color}
    trans_front: real;                 {transparency fraction for front facing obj}
    trans_side: real;                  {transparency fraction for side facing obj}
    spcol: rend_rgb_t;                 {specular color}
    spexp: real;                       {specular exponent}
    iexp: sys_int_machine_t;           {nearest integer value of specular exponent}
    on: boolean;                       {TRUE if this surface properties block on}
    emis_on: boolean;                  {TRUE if emissive color on}
    diff_on: boolean;                  {TRUE if diffuse reflection on}
    trans_on: boolean;                 {TRUE if transparency on}
    spec_on: boolean;                  {TRUE if specular reflection on}
    end;

  rend_suprop_p_t =                    {pointer to a visual properties state block}
    ^rend_suprop_t;

  rend_cmodes_list_t =                 {max list of automatically changeable modes}
    array[1..rend_n_cmodes_k] of rend_cmode_k_t;

  rend_context_block_t = record        {info about one saved block in context}
    start_adr: univ_ptr;               {address of first byte of block to save}
    len: sys_int_adr_t;                {block size in machine address units}
    end;

  rend_context_p_t = ^rend_context_t;
  rend_context_t = record              {context save area}
    dev: rend_dev_id_t;                {ID for device context belongs to}
    n_blocks: sys_int_machine_t;       {number of block descriptors to follow}
    block:                             {one descriptor for each block}
      array[1..1] of rend_context_block_t;
    end;

  rend_context_handle_t =              {user handle to context save/restore area}
    rend_context_p_t;

  rend_iterps_list_t =                 {list of interpolants}
    array[1..rend_n_iterps_k] of rend_iterp_k_t;

  rend_ray_value_t = record            {data returned about resolved ray}
    red: real;                         {0.0 to 1.0 color values}
    grn: real;
    blu: real;
    opac: real;                        {0.0 to 1.0 opacity fraction}
    dist: real;                        {ray distance of hit point}
    end;

  rend_raytrace_p_t = ^function (      {pointer to user ray trace entry point}
    in    point: vect_3d_t;            {3DW space ray start point}
    in    dir: vect_3d_t;              {unit ray direction vector}
    in    min_dist, max_dist: real;    {ray distance limits for acceptable hits}
    out   ray_value: rend_ray_value_t) {returned ray value if found hit}
    :boolean;                          {TRUE if found ray hit}
    val_param;
{
*   Data structures for tube crossections.  These data structures are private to
*   RENDlib and should not be used directly by applications programs.  Application
*   programs should only use REND_XSEC_P_T.  The internal format of crossection
*   descriptors may change without notice.
*
*   Crossections should be defined counter-clockwise around the origin.
*   By convention, they are usually scaled to a "radius" of 1.0.  Additional
*   scaling is available when the crossection is actually used.
}
  rend_xsecpnt_flag_k_t = (            {individual flags stored at each xsec point}
    rend_xsecpnt_flag_smooth_k,        {smooth shaded, use NORM_BEF for whole norm}
    rend_xsecpnt_flag_nrmset_k);       {shading normals all set}

  rend_xsecpnt_flag_t =                {all the xsec point flags in one word}
    set of rend_xsecpnt_flag_k_t;

  rend_xsec_point_p_t =                {points to data about one crossection point}
    ^rend_xsec_point_t;

  rend_xsec_point_t = record           {one point in internal crossection descriptor}
    next_p: rend_xsec_point_p_t;       {points to next xsec point in sequence}
    prev_p: rend_xsec_point_p_t;       {points to previous xsec point in sequence}
    coor: vect_2d_t;                   {coordinate, usually near unit circle}
    norm_bef: vect_2d_t;               {2D normal for just before or here}
    norm_aft: vect_2d_t;               {2D normal for just after here}
    flags: rend_xsecpnt_flag_t;        {set of individual one-bit flags}
    end;

  rend_xsec_flag_k_t = (               {individual flags for each crossection}
    rend_xsec_flag_conn_k,             {end/start points are connected}
    rend_xsec_flag_closed_k);          {crossection has been closed}

  rend_xsec_flag_t =                   {all the crossection flags in one word}
    set of rend_xsec_flag_k_t;

  rend_xsec_t = record                 {data for whole crossection definition}
    n: sys_int_machine_t;              {number of points in crossection}
    first_p: rend_xsec_point_p_t;      {points to first crossection point descriptor}
    last_p: rend_xsec_point_p_t;       {points to last crossection point descriptor}
    mem_p: util_mem_context_p_t;       {points to memory context for this xsec}
    flags: rend_xsec_flag_t;           {set of individual one-bit flags}
    end;
{
*   End of RENDlib private data structures.
}
  rend_xsec_p_t =                      {pointer to a crossection definition}
    ^rend_xsec_t;

  rend_tblen_shade_k_t = (             {shading rule along length of a tube}
    rend_tblen_shade_curr_k,           {use current RENDlib global shading rule}
    rend_tblen_shade_facet_k,          {facet shade the tube lengthwise}
    rend_tblen_shade_endplane_k,       {shade norms will be in plane of segment ends}
    rend_tblen_shade_smooth_k);        {blend shading normals between tube segments}

  rend_tube_point_t = record           {data for one point along path of a tube}
    coor_p: vect_3d_fp1_p_t;           {points to XYZ coordinate}
    xb, yb, zb: vect_3d_t;             {basis vectors for end plane and end cap}
    nxb, nyb, nzb: vect_3d_t;          {normal vector transform basis vectors}
    xsec_p: rend_xsec_p_t;             {points to crossection, use curr xsec if NIL}
    rgba_p: rend_rgba_p_t;             {optional ptr to explicit diffuse RGB and A}
    shade: rend_tblen_shade_k_t;       {what shading rule to apply}
    rad0: boolean;                     {TRUE if tube "radius" definately zero here}
    end;

  rend_tube_point_p_t =                {pointer to data for one tube path point}
    ^rend_tube_point_t;

  rend_tbcap_k_t = (                   {cap style for ends of extruded tube}
    rend_tbcap_none_k,                 {no cap, leave end open}
    rend_tbcap_flat_k);                {cap with flat polygon in end plane}
{
*********************************************
*
*   Event-related data structures.
}
  rend_event_p_t = ^rend_event_t;      {pointer to event descriptor}

  rend_key_sp_data_t = record          {data about a special key}
    key: rend_key_sp_k_t;              {ID of the special key, use REND_KEY_SP_xxx_K}
    detail: sys_int_machine_t;         {additional optional detail information}
    end;

  rend_key_id_t = sys_int_machine_t;   {RENDlib ID for a user-pressable key}

  rend_devkey_id_t = sys_int_machine_t; {RENDlib ID for input device containing keys}

  rend_key_t = record                  {data about one key}
    id: rend_key_id_t;                 {ID for this key, 1-N keys array index}
    req: boolean;                      {TRUE if events for this key requested}
    devkey: rend_devkey_id_t;          {ID of input device where this key is found}
    spkey: rend_key_sp_data_t;         {extra info if this is RENDlib special key}
    id_user: sys_int_machine_t;        {user ID for this key, valid only when req}
    name_p: string_var_p_t;            {name for this key with no modifiers pressed}
    name_mod:                          {name when each of the mod keys pressed}
      array[firstof(rend_key_mod_k_t)..lastof(rend_key_mod_k_t)]
      of string_var_p_t;
    val_p: string_var_p_t;             {value of key when pressed with no modifiers}
    val_mod:                           {value when pressed with each of the mod keys}
      array[firstof(rend_key_mod_k_t)..lastof(rend_key_mod_k_t)]
      of string_var_p_t;
    end;

  rend_key_p_t =                       {pointer to one key descriptor}
    ^rend_key_t;

  rend_key_ar_t =                      {array of key descriptors}
    array[1..1] of rend_key_t;         {array index is same as RENDlib key ID}

  rend_key_ar_p_t =                    {pointer to array of key descriptors}
    ^rend_key_ar_t;

  rend_event_wiped_rect_t = record     {data for WIPED_RECT event}
    bufid: sys_int_machine_t;          {ID of effected buffer for double buffering}
    x, y: sys_int_machine_t;           {top left pixel of rectangle}
    dx, dy: sys_int_machine_t;         {size of rectangle in pixels}
    end;

  rend_event_key_t = record            {data for KEY event}
    down: boolean;                     {TRUE if key was pressed, FALSE for released}
    key_p: rend_key_p_t;               {points to descriptor for this key}
    x, y: sys_int_machine_t;           {pointer coordinates when key changed}
    modk: rend_key_mod_t;              {state of modifier keys}
    end;

  rend_event_pnt_t = record            {data for PNT_MOVE, PNT_ENTER, PNT_EXIT events}
    x, y: sys_int_machine_t;           {new pointer coordinates within device}
    end;

  rend_dvclass_k_t = (                 {IDs for device classes that can cause events}
    rend_dvclass_force_k,              {senses force/torque, deltas reported}
    rend_dvclass_rel_k,                {senses relative values, deltas reported}
    rend_dvclass_3dabs_k);             {senses absolute values, abs values reported}

  rend_ev3d_k_t = (                    {separate components of 3D transform event}
    rend_ev3d_abs_k,                   {absolute, not relative transform}
    rend_ev3d_translate_k,             {some translation may be present}
    rend_ev3d_tx_k,                    {may have X translation}
    rend_ev3d_ty_k,                    {may have Y translation}
    rend_ev3d_tz_k,                    {may have Z translation}
    rend_ev3d_scale_k,                 {may have non-unit scaling applied}
    rend_ev3d_dscale_k,                {scaling may be non-uniform}
    rend_ev3d_rot_k,                   {may be rotated}
    rend_ev3d_skew_k,                  {may be skewed (non-orthogonal)}
    rend_ev3d_mflat_k,                 {may be flat (zero volume, no inverse)}
    rend_ev3d_isflat_k,                {definately is flat}
    rend_ev3d_mleft_k,                 {may be left handed}
    rend_ev3d_isleft_k);               {definately is left handed}

  rend_ev3d_t = set of rend_ev3d_k_t;  {all component flags in one word}

  rend_event_xf3d_t = record           {data for 3D transform event}
    dvclass: rend_dvclass_k_t;         {class of originating input device}
    comp: rend_ev3d_t;                 {identifies active components in this event}
    mat: vect_mat3x4_t;                {3D transformation matrix}
    end;

  rend_event_app_t = record            {arbitrary application-specific event}
    i1, i2, i3: sys_int_machine_t;     {arbitrary integers}
    p1, p2, p3: univ_ptr;              {arbitrary pointers}
    f1, f2, f3: real;                  {arbitrary floating point numbers}
    end;

  rend_evcall_p_t = ^procedure (       {routine called by a CALL event}
    in  ev_p: rend_event_p_t);         {event that caused routine to be called}
    val_param;

  rend_event_call_t = record           {subroutine callback event}
    call_p: rend_evcall_p_t;           {pointer to routine to call}
    i1, i2, i3: sys_int_machine_t;     {arbitrary integers}
    p1, p2, p3: univ_ptr;              {arbitrary pointers}
    f1, f2, f3: real;                  {arbitrary floating point numbers}
    end;

  rend_event_t = record                {data for any RENDlib event}
    dev: rend_dev_id_t;                {RENDlib device ID or REND_DEV_NONE_K}
    ev_type: rend_ev_k_t;              {event ID, use REND_EV_xxx_K}
    case rend_ev_k_t of                {remaining data is specific to each event}
rend_ev_none_k: (                      {no event occurred}
      );
rend_ev_close_k: (                     {draw device closed, RENDlib still open}
      );
rend_ev_resize_k: (                    {drawing area changed size}
      );
rend_ev_wiped_rect_k: (                {rect of pixels wiped out, now redrawable}
      wiped_rect: rend_event_wiped_rect_t;
      );
rend_ev_wiped_resize_k: (              {all pixels wiped out, now redrawable}
      );
rend_ev_key_k: (                       {a user-pressable key changed state}
      key: rend_event_key_t;
      );
rend_ev_pnt_enter_k: (                 {pointer entered draw area}
      pnt_enter: rend_event_pnt_t;
      );
rend_ev_pnt_exit_k: (                  {pointer left draw area}
      pnt_exit: rend_event_pnt_t;
      );
rend_ev_pnt_move_k: (                  {pointer location changed}
      pnt_move: rend_event_pnt_t;
      );
rend_ev_close_user_k: (                {user requested close of graphics device}
      );
rend_ev_stdin_line_k: (                {text line available from REND_GET_STDIN_LINE}
      );
rend_ev_xf3d_k: (                      {3D transformation event}
      xf3d: rend_event_xf3d_t;
      );
rend_ev_app_k: (                       {arbitrary application specific event}
      app: rend_event_app_t;
      );
rend_ev_call_k: (                      {transparently call routine}
      call: rend_event_call_t;
      );
    end;

  rend_pntmode_k_t = (                 {how to handle 2D pointer motion}
    rend_pntmode_direct_k,             {report directly as pointer motion event}
    rend_pntmode_pan_k,                {as if pointer moving Z=0 plane}
    rend_pntmode_dolly_k,              {pnt Y translates observer in/out}
    rend_pntmode_rot_k);               {as if pointer moving front of virtual sphere}
{
**************************************************************************************
*
*   Here are all the entry point definitions for the graphics primitive routines.
*   This is the complete list of routines that cause drawing to happen.  As much
*   as possible, these routines are only passed the geometric information about
*   the drawing, and modes and modifiers come from the current state.
*
*   For most primitives, the last part of each subroutine name indicates the
*   coordinate space level it draws into.
}
  rend_prim_t = record

anti_alias: ^procedure (               {anti alias src to dest bitmap, curr scale}
  in      size_x, size_y: sys_int_machine_t; {destination rectangle size}
  in      src_x, src_y: sys_int_machine_t); {maps to top left of top left out pixel}
  val_param;
  anti_alias_data_p: rend_prim_data_p_t;

chain_vect_3d: ^procedure (            {end-to-end chained vectors}
  in      n_verts: sys_int_machine_t;  {number of verticies pointed to by VERT_P_LIST}
  in      vert_p_list: univ rend_vert3d_p_list_t); {vertex descriptor pointer list}
  val_param;
  chain_vect_3d_data_p: rend_prim_data_p_t;

circle_2dim: ^procedure (              {unfilled circle}
  in      radius: real);
  val_param;
  circle_2dim_data_p: rend_prim_data_p_t;

clear: ^procedure;                     {clear whole image to interpolants as set}
  clear_data_p: rend_prim_data_p_t;

clear_cwind: ^procedure;               {clear clip window to interpolants as set}
  clear_cwind_data_p: rend_prim_data_p_t;

disc_2dim: ^procedure (                {filled circle}
  in      radius: real);
  val_param;
  disc_2dim_data_p: rend_prim_data_p_t;

flip_buf: ^procedure;                  {flip buffers and clear new drawing buffer}
  flip_buf_data_p: rend_prim_data_p_t;

flush_all: ^procedure;                 {flush all data, insure image is up to date}
  flush_all_data_p: rend_prim_data_p_t;

image_2dimcl: ^procedure (             {read image from file to current image bitmap}
  in out  img: img_conn_t;             {handle to previously open image file}
  in      x, y: sys_int_machine_t;     {bitmap anchor coordinate}
  in      torg: rend_torg_k_t;         {how image is anchored to X,Y}
  out     stat: sys_err_t);            {returned completion status code}
  val_param;
  image_2dimcl_data_p: rend_prim_data_p_t;

line_3d: ^procedure (                  {draw 3D model space line, curr pnt trashed}
  in      v1, v2: univ rend_vert3d_t;  {descriptors for each line segment endpoint}
  in      gnorm: vect_3d_t);           {geometric normal for Z slope and backface}
  val_param;
  line_3d_data_p: rend_prim_data_p_t;

poly_text: ^procedure (                {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;
  poly_text_data_p: rend_prim_data_p_t;

poly_txdraw: ^procedure (              {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;
  poly_txdraw_data_p: rend_prim_data_p_t;

poly_2d: ^procedure (                  {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;
  poly_2d_data_p: rend_prim_data_p_t;

poly_2dim: ^procedure (                {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;
  poly_2dim_data_p: rend_prim_data_p_t;

poly_2dimcl: ^procedure (              {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;
  poly_2dimcl_data_p: rend_prim_data_p_t;

poly_3dpl: ^procedure (                {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;
  poly_3dpl_data_p: rend_prim_data_p_t;

quad_3d: ^procedure (                  {draw 3D model space quadrilateral}
  in      v1, v2, v3, v4: univ rend_vert3d_t); {pointer info for each vertex}
  val_param;
  quad_3d_data_p: rend_prim_data_p_t;

ray_trace_2dimi: ^procedure (          {ray trace a rectangle of pixels}
  in      idx, idy: sys_int_machine_t); {size from current pixel to opposite corner}
  val_param;
  ray_trace_2dimi_data_p: rend_prim_data_p_t;

rect_2d: ^procedure (                  {axis aligned rectangle at current point}
  in      dx, dy: real);               {displacement from curr pnt to opposite corner}
  val_param;
  rect_2d_data_p: rend_prim_data_p_t;

rect_2dim: ^procedure (                {axis aligned rectangle at current point}
  in      dx, dy: real);               {displacement from curr pnt to opposite corner}
  val_param;
  rect_2dim_data_p: rend_prim_data_p_t;

rect_2dimcl: ^procedure (              {axis aligned rectangle at current point}
  in      dx, dy: real);               {displacement from curr pnt to opposite corner}
  val_param;
  rect_2dimcl_data_p: rend_prim_data_p_t;

rect_2dimi: ^procedure (               {integer image space axis aligned rectangle}
  in      idx, idy: sys_int_machine_t); {pixel displacement to opposite corner}
  val_param;
  rect_2dimi_data_p: rend_prim_data_p_t;

rect_px_2dimcl: ^procedure (           {declare rectangle for RUNs or SPANs}
  in      dx, dy: sys_int_machine_t);  {size from curr pixel to opposite corner}
  val_param;
  rect_px_2dimcl_data_p: rend_prim_data_p_t;

rect_px_2dimi: ^procedure (            {declare rectangle for RUNs or SPANs}
  in      dx, dy: sys_int_machine_t);  {size from curr pixel to opposite corner}
  val_param;
  run_rect_2dimi_data_p: rend_prim_data_p_t;

runpx_2dimcl: ^procedure (             {draw chunk of pixels from runs into RECT_PX}
  in      start_skip: sys_int_machine_t; {pixels to ignore at start of runs}
  in      np: sys_int_machine_t;       {num of pixels in RUNS, including ignored}
  in      runs: univ char);            {runs formatted as currently configured}
  val_param;
  runs_2dimcl_data_p: rend_prim_data_p_t;

runpx_2dimi: ^procedure (              {draw chunk of pixels from runs into RECT_PX}
  in      start_skip: sys_int_machine_t; {pixels to ignore at start of runs}
  in      np: sys_int_machine_t;       {num of pixels in RUNS, including ignored}
  in      runs: univ char);            {runs formatted as currently configured}
  val_param;
  runs_2dimi_data_p: rend_prim_data_p_t;

rvect_text: ^procedure (               {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param;
  rvect_text_data_p: rend_prim_data_p_t;

rvect_txdraw: ^procedure (             {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param;
  rvect_txdraw_data_p: rend_prim_data_p_t;

rvect_2d: ^procedure (                 {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param;
  rvect_2d_data_p: rend_prim_data_p_t;

rvect_2dim: ^procedure (               {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param;
  rvect_2dim_data_p: rend_prim_data_p_t;

rvect_2dimcl: ^procedure (             {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param;
  rvect_2dimcl_data_p: rend_prim_data_p_t;

rvect_3dpl: ^procedure (               {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param;
  rvect_3dpl_data_p: rend_prim_data_p_t;

span_2dimcl: ^procedure (              {write horizontal span of pixels}
  in      len: sys_int_machine_t;      {number of pixels in span}
  in      pixels: univ char);          {span formatted as currently configured}
  val_param;
  span_2dimcl_data_p: rend_prim_data_p_t;

span_2dimi: ^procedure (               {write horizontal span of pixels}
  in      len: sys_int_machine_t;      {number of pixels in span}
  in      pixels: univ char);          {span formatted as currently configured}
  val_param;
  span_2dimi_data_p: rend_prim_data_p_t;

sphere_3d: ^procedure (                {draw a sphere}
  in      x, y, z: real;               {sphere center point}
  in      r: real);                    {radius}
  val_param;
  sphere_3d_data_p: rend_prim_data_p_t;

text: ^procedure (                     {text string, use current text parms}
  in      s: univ string;              {string of bytes}
  in      len: string_index_t);        {number of characters in string}
  val_param;
  text_data_p: rend_prim_data_p_t;

text_raw: ^procedure (                 {text string, assume VECT_TEXT all set up}
  in      s: univ string;              {string of bytes}
  in      len: string_index_t);        {number of characters in string}
  val_param;
  text_raw_data_p: rend_prim_data_p_t;

tri_3d: ^procedure (                   {draw 3D model space triangle}
  in      v1, v2, v3: univ rend_vert3d_t; {pointer info for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  tri_3d_data_p: rend_prim_data_p_t;

tstrip_3d: ^procedure (                {draw connected strip of triangles}
  in      vlist: univ rend_vert3d_p_list_t; {list of pointers to vertex descriptors}
  in      nverts: sys_int_machine_t);  {number of verticies in VLIST}
  val_param;
  tstrip_3d_data_p: rend_prim_data_p_t;

tubeseg_3d: ^procedure (               {draw one segment of extruded tube}
  in      p1: rend_tube_point_t;       {point descriptor for start of tube segment}
  in      p2: rend_tube_point_t;       {point descriptor for end of tube segment}
  in      cap_start: rend_tbcap_k_t;   {selects cap style for segment start}
  in      cap_end: rend_tbcap_k_t);    {selects cap style for segment end}
  val_param;
  tubeseg_3d_data_p: rend_prim_data_p_t;

vect_text: ^procedure (                {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;
  vect_text_data_p: rend_prim_data_p_t;

vect_txdraw: ^procedure (              {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;
  vect_txdraw_data_p: rend_prim_data_p_t;

vect_2d: ^procedure (                  {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;
  vect_2d_data_p: rend_prim_data_p_t;

vect_2dim: ^procedure (                {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;
  vect_2dim_data_p: rend_prim_data_p_t;

vect_2dimcl: ^procedure (              {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;
  vect_2dimcl_data_p: rend_prim_data_p_t;

vect_3d: ^procedure (                  {vector to new current point in 3D space}
  in      x, y, z: real);              {vector end point and new current point}
  val_param;
  vect_3d_data_p: rend_prim_data_p_t;

vect_3dpl: ^procedure (                {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;
  vect_3dpl_data_p: rend_prim_data_p_t;

vect_3dw: ^procedure (                 {vector to new current point in 3DW space}
  in      x, y, z: real);              {vector end point and new current point}
  val_param;
  vect_3dw_data_p: rend_prim_data_p_t;

vect_fp_2dim: ^procedure (             {2D image space vector using subpixel adr}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;
  vect_fp_2dim_data_p: rend_prim_data_p_t;

vect_int_2dim: ^procedure (            {2D image space vector using integer adr}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;
  vect_int_2dim_data_p: rend_prim_data_p_t;

vect_2dimi: ^procedure (               {integer 2D image space vector}
  in      ix, iy: sys_int_machine_t);  {pixel coordinate end point}
  val_param;
  vect_2dimi_data_p: rend_prim_data_p_t;

wpix: ^procedure;                      {write current value at current pixel}
  wpix_data_p: rend_prim_data_p_t;

    end;
{
**************************************************************************************
*
*   Here are all the entry point definitions for the routines that modify
*   the current state.  As much as possible, these cause no drawing to happen, but
*   will have effect on how future drawing is performed.  "State" refers to all the
*   current modes and switches not including any direct bitmap data.
}
  rend_set_t = record

aa_radius: ^procedure (                {set anti-aliasing filter kernal radius}
  in      r: real);                    {radius in output pixels, normal = 1.25}
  val_param;

aa_scale: ^procedure (                 {set scale factors for ANTI_ALIAS primitive}
  in      x_scale: real;               {output size / input size horizontal scale}
  in      y_scale: real);              {output size / input size vertical scale}
  val_param;

alloc_bitmap: ^procedure (             {allocate memory for the pixels}
  in      handle: rend_bitmap_handle_t; {handle to bitmap descriptor}
  in      x_size, y_size: sys_int_machine_t; {number of pixels in each dimension}
  in      pix_size: sys_int_adr_t;     {adr units to allocate per pixel}
  in      scope: rend_scope_t);        {what memory context bitmap to belong to}
  val_param;

alloc_bitmap_handle: ^procedure (      {create a new empty bitmap handle}
  in      scope: rend_scope_t;         {memory context, use REND_SCOPE_xxx_K}
  out     handle: rend_bitmap_handle_t); {returned valid bitmap handle}
  val_param;

alloc_context: ^procedure (            {allocate mem for current device context}
  out     handle: rend_context_handle_t); {handle to this new context block}

alpha_func: ^procedure  (              {set alpha buffering (compositing) function}
  in      afunc: rend_afunc_k_t);      {alpha function ID}
  val_param;

alpha_on: ^procedure (                 {turn alpha compositing on/off}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

array_bitmap: ^procedure (             {declare array to use for bitmap data}
  in      handle: rend_bitmap_handle_t; {handle for this bitmap}
  in      ar: univ sys_size1_t;        {the array of pixels}
  in      x_size, y_size: sys_int_machine_t; {number of pixels in each dimension}
  in      size_pix: sys_int_adr_t;     {adr offset for one pixel to the right}
  in      size_line: sys_int_adr_t);   {adr offset for one scan line down}
  val_param;

backface: ^procedure (                 {set new current backfacing operation}
  in      flag: rend_bface_k_t);       {from constants REND_BFACE_xx_K}
  val_param;

bench_flags: ^procedure (              {explicitly set benchmark flags}
  in      flags: rend_bench_t);        {new benchmark flag settings}
  val_param;

cache_version: ^procedure (            {set version ID tag for valid cache entry}
  in      version: sys_int_machine_t); {new ID for recognizing valid cache data}
  val_param;

cirres: ^procedure (                   {set all CIRRES values simultaneously}
  in      cirres: sys_int_machine_t);  {new value for all CIRRES parameters}
  val_param;

cirres_n: ^procedure (                 {set one specific CIRRES parameter}
  in      n: sys_int_machine_t;        {1-N CIRRES value to set, outrange ignored}
  in      cirres: sys_int_machine_t);  {new val for the particular CIRRES parameter}
  val_param;

clear_cmodes: ^procedure;              {clear all changed mode flags}

clip_2dim: ^procedure (                {set 2D image clip window and turn it on}
  in      handle: rend_clip_2dim_handle_t; {handle to this clip window}
  in      x1, x2: real;                {X coordinate limits}
  in      y1, y2: real;                {y coordinate limits}
  in      draw_inside: boolean);       {TRUE for draw in, FALSE for exclude inside}
  val_param;

clip_2dim_on: ^procedure (             {turn 2D image space clip window on/off}
  in      handle: rend_clip_2dim_handle_t; {handle to this clip window}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

clip_2dim_delete: ^procedure (         {deallocate 2D image space clip window}
  in out  handle: rend_clip_2dim_handle_t); {returned as invalid}

close: ^procedure;                     {close device and release dynamic memory}

cmode_vals: ^procedure (               {set state of all changeable modes}
  in      vals: rend_cmode_vals_t);    {data block with all changeable modes values}

context: ^procedure (                  {restore context from context block}
  in      handle: rend_context_handle_t); {handle of context block to read from}
  val_param;

cpnt_2d: ^procedure (                  {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param;

cpnt_2dim: ^procedure (                {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param;

cpnt_2dimi: ^procedure (               {set current point with absolute coordinates}
  in      x, y: sys_int_machine_t);    {new integer pixel coor of current point}
  val_param;

cpnt_3d: ^procedure (                  {set new current point from 3D model space}
  in      x, y, z: real);              {coordinates of new current point}
  val_param;

cpnt_3dpl: ^procedure (                {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param;

cpnt_3dw: ^procedure (                 {set new current point from 3D world space}
  in      x, y, z: real);              {coordinates of new current point}
  val_param;

cpnt_text: ^procedure (                {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param;

cpnt_txdraw: ^procedure (              {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param;

create_light: ^procedure (             {create new light source and return handle}
  out     h: rend_light_handle_t);     {handle to newly created light source}

dealloc_bitmap: ^procedure (           {release memory allocated with ALLOC_BITMAP}
  in      h: rend_bitmap_handle_t);    {handle to bitmap, still valid but no pixels}
  val_param;

dealloc_bitmap_handle: ^procedure (    {deallocate a bitmap handle}
  in out  handle: rend_bitmap_handle_t); {returned invalid}

dealloc_context: ^procedure (          {release memory for context block}
  in out  handle: rend_context_handle_t); {returned invalid}

del_all_lights: ^procedure;            {delete all light sources, all handles invalid}

del_light: ^procedure (                {delete a light source}
  in out  h: rend_light_handle_t);     {handle to light source, returned invalid}

dev_reconfig: ^procedure;              {look at device parameters and reconfigure}

dev_restore: ^procedure;               {restore device state from RENDlib state}

dev_z_curr: ^procedure (               {indicate whether device Z is current}
  in      curr: boolean);              {TRUE if declare device Z to be current}
  val_param;

disp_buf: ^procedure (                 {set number of new current display buffer}
  in      n: sys_int_machine_t);       {buffer number, first buffer is 1}
  val_param;

dith_on: ^procedure (                  {turn dithering on/off}
  in      on: boolean);                {TRUE for dithering on}
  val_param;

draw_buf: ^procedure (                 {set number of new current drawing buffer}
  in      n: sys_int_machine_t);       {buffer number, first buffer is 1}
  val_param;

end_group: ^procedure;                 {done sending group of only one PRIM type}

enter_level: ^procedure (              {set depth of ENTER_REND nesting level}
  in      level: sys_int_machine_t);   {desired level, 0 = not in graphics mode}
  val_param;

enter_rend: ^procedure;                {enter graphics mode}

enter_rend_cond: ^procedure (          {ENTER_REND only if possible immediately}
  out     entered: boolean);           {TRUE if did ENTER_REND}

event_mode_pnt: ^procedure (           {indicate how to handle pointer motion}
  in      mode: rend_pntmode_k_t);     {interpretation mode, use REND_PNTMODE_xxx_K}
  val_param;

event_req_close: ^procedure (          {request CLOSE, CLOSE_USER events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param;

event_req_key_off: ^procedure (        {request no events for a particular key}
  in      id: rend_key_id_t);          {RENDlib ID of key requesting no events for}
  val_param;

event_req_key_on: ^procedure (         {request events for a particular key}
  in      id: rend_key_id_t;           {RENDlib ID of key requesting events for}
  in      id_user: sys_int_machine_t); {ID returned to user with event data}
  val_param;

event_req_pnt: ^procedure (            {request pnt ENTER, EXIT, MOVE events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param;

event_req_resize: ^procedure (         {request RESIZE events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param;

event_req_rotate_off: ^procedure;      {disable 3D rotation events}

event_req_rotate_on: ^procedure (      {enable 3D rotation events}
  in      scale: real);                {scale factor, 1.0 = "normal"}
  val_param;

event_req_translate: ^procedure (      {enable/disable 3D translation events}
  in      on: boolean);                {TRUE enables these events}
  val_param;

event_req_wiped_resize: ^procedure (   {size change will generate WIPED_RESIZE, and
                                        will be compressed with WIPED_RECT events}
  in      on: boolean);                {TRUE requests these events}
  val_param;

event_req_wiped_rect: ^procedure (     {request WIPED_RECT events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param;

events_req_off: ^procedure;            {disable all device events}

exit_rend: ^procedure;                 {leave graphics mode}

eyedis: ^procedure (                   {set perspective value using eye distance}
  in      e: real);                    {new value as eye distance dimensionless value}
  val_param;

force_sw_update: ^procedure (          {force SW bitmap update ON/OFF}
  in      on: boolean);                {TRUE means force keep SW bitmap up to date}
  val_param;

image_ftype: ^procedure (              {set the image output file type}
  in      ftype: univ string_var_arg_t); {image file type name (IMG, TGA, etc.)}

image_size: ^procedure (               {set size and aspect of current output image}
  in      x_size, y_size: sys_int_machine_t; {number of pixels in each dimension}
  in      aspect: real);               {DX/DY image aspect ratio when displayed}
  val_param;

image_write: ^procedure (              {write rectangle from bitmap to image file}
  in      fnam: univ string_var_arg_t; {generic image output file name}
  in      x_orig: sys_int_machine_t;   {coor where top left image pixel comes from}
  in      y_orig: sys_int_machine_t;
  in      x_size: sys_int_machine_t;   {image size in pixels}
  in      y_size: sys_int_machine_t;
  out     stat: sys_err_t);            {completion status code}
  val_param;

iterp_aa: ^procedure (                 {turn anti-aliasing ON/OFF for this iterp}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {anti-aliasing override interpolator value ON}
  val_param;

iterp_bitmap: ^procedure (             {declare where this interpolant gets written}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      bitmap_handle: rend_bitmap_handle_t; {handle for bitmap to write to}
  in      iterp_offset: sys_int_adr_t); {adr offset into pixel for this interpolant}
  val_param;

iterp_flat: ^procedure (               {set interpolation to flat and init values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      val: real);                  {0.0 to 1.0 interpolant value}
  val_param;

iterp_flat_int: ^procedure (           {set interpolation to flat integer value}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      val: sys_int_machine_t);     {new raw interpolant value}
  val_param;

iterp_iclamp: ^procedure (             {turn interpolator output clamping on/off}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

iterp_linear: ^procedure (             {set interpolation to linear and init values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      point: vect_2d_t;            {X,Y coordinates where VAL valid}
  in      val: real;                   {interpolant value at anchor point}
  in      dx, dy: real);               {first partials of val in X and Y direction}
  val_param;

iterp_on: ^procedure (                 {turn interpolant on/off}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {as if interpolant does not exist when FALSE}
  val_param;

iterp_pclamp: ^procedure (             {turn pixel function output clamping on/off}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

iterp_pixfun: ^procedure (             {set pixel write function}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      pixfun: rend_pixfun_k_t);    {pixel function identifier}
  val_param;

iterp_quad: ^procedure (               {set interpolation to quadratic and init values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      point: vect_2d_t;            {X,Y coordinates where VAL valid}
  in      val: real;                   {interpolant value at anchor point}
  in      dx, dy: real;                {first partials of val in X and Y at anchor}
  in      dxx, dyy, dxy: real);        {second derivatives for X, Y and crossover}
  val_param;

iterp_run_ofs: ^procedure (            {set pixel offset for RUN primitives}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      ofs: sys_int_adr_t);         {machine addresses into pixel for this iterp}
  val_param;

iterp_shade_mode: ^procedure (         {set interpolation mode for implicit colors}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      shmode: sys_int_machine_t);  {one of the REND_ITERP_MODE_xx_K values}
  val_param;

iterp_span_ofs: ^procedure (           {set pixel offset for SPAN primitives}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      ofs: sys_int_adr_t);         {machine addresses into pixel for this iterp}
  val_param;

iterp_span_on: ^procedure (            {iterp participates in SPAN, RUNS ON/OFF}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {TRUE if interpolant does participate}
  val_param;

iterp_src_bitmap: ^procedure (         {declare source mode BITMAP and set bitmap}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      bitmap_handle: rend_bitmap_handle_t; {handle for source bitmap}
  in      iterp_offset: sys_int_adr_t); {adr offset into pixel for this interpolant}
  val_param;

iterp_wmask: ^procedure (              {set write mask for this interpolant}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      wmask: sys_int_machine_t);   {right justified write mask, 1=write}
  val_param;

light_accur: ^procedure (              {set lighting calculation accuracy level}
  in      accur: rend_laccu_k_t);      {new lighting accuracy mode}
  val_param;

light_amb: ^procedure (                {set ambient light source and turn ON}
  in      h: rend_light_handle_t;      {handle to light source}
  in      red, grn, blu: real);        {light source brightness values}
  val_param;

light_dir: ^procedure (                {set directional light source and turn ON}
  in      h: rend_light_handle_t;      {handle to light source}
  in      red, grn, blu: real;         {light source brightness values}
  in      vx, vy, vz: real);           {direction vector, need not be unitized}
  val_param;

light_on: ^procedure (                 {turn light source on/off}
  in      h: rend_light_handle_t;      {handle to light source}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

light_pnt: ^procedure (                {set point light with no falloff, turn ON}
  in      h: rend_light_handle_t;      {handle to light source}
  in      red, grn, blu: real;         {light source brightness values}
  in      x, y, z: real);              {light source coordinate}
  val_param;

light_pr2: ^procedure (                {set point light with falloff, turn ON}
  in      h: rend_light_handle_t;      {handle to light source}
  in      red, grn, blu: real;         {light source brightness values at radius}
  in      r: real;                     {radius where given intensities apply}
  in      x, y, z: real);              {light source coordinate}
  val_param;

light_val: ^procedure (                {set value for a light source}
  in      h: rend_light_handle_t;      {handle to this light source}
  in      ltype: rend_ltype_k_t;       {type of light source}
  in      val: rend_light_val_t);      {LTYPE dependent data values for this light}
  val_param;

lin_geom_2dim: ^procedure (            {set geometric info to compute linear derivs}
  in      p1, p2, p3: vect_2d_t);      {3 points where vals will be specified}
  val_param;

lin_vals: ^procedure (                 {set linear interp by giving corner values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      v1, v2, v3: real);           {values at previously given coordinates}
  val_param;

lin_vals_rgba: ^procedure (            {premult RGB by A, set quad RGB, linear A}
  in      v1, v2, v3: rend_rgba_t);    {RGBA at each previously given coordinate}
  val_param;

max_buf: ^procedure (                  {set max number of desired display/draw bufs}
  in      n: sys_int_machine_t);       {max desired buf num, first buffer is 1}
  val_param;

min_bits_hw: ^procedure (              {set minimum required hardware bits per pixel}
  in      n: real);                    {min desired hardware bits to write into}
  val_param;

min_bits_vis: ^procedure (             {set minimum required effective bits per pixel}
  in      n: real);                    {Log2 of total effective number of colors}
  val_param;

ncache_version: ^procedure (           {set new valid version ID for norm vect cache}
  in      version: sys_int_machine_t);
  val_param;

new_view: ^procedure;                  {make new view parameters take effect}

perspec_on: ^procedure (               {turn perspective on/off}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

pointer: ^procedure (                  {set pointer to location within draw area}
  in      x, y: sys_int_machine_t);    {new location relative to draw area origin}
  val_param;

pointer_abs: ^procedure (              {set pointer to location within "root" device}
  in      x, y: sys_int_machine_t);    {new location in absolute "root" coordinates}
  val_param;

poly_parms: ^procedure (               {set new parameters to control polygon drawing}
  in      parms: rend_poly_parms_t);   {new polygon drawing parameters}

quad_geom_2dim: ^procedure (           {set geometric info to compute quad derivs}
  in      p1, p2, p3, p4, p5, p6: vect_2d_t); {6 points for vals later}

quad_vals: ^procedure (                {set quad interp by giving vals at 6 points}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      v1, v2, v3, v4, v5, v6: real); {values at previously given coordinates}
  val_param;

ray_callback: ^procedure (             {set application routine that resolves rays}
  in      p: rend_raytrace_p_t);       {routine pointer or NIL to disable}
  val_param;

ray_delete: ^procedure;                {delete all primitives saved for ray tracing}

ray_save: ^procedure (                 {turn primitive saving for ray tracing ON/OFF}
  in      on: boolean);                {TRUE will cause primitives to be saved}
  val_param;

rcpnt_text: ^procedure (               {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param;

rcpnt_txdraw: ^procedure (             {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param;

rcpnt_2d: ^procedure (                 {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param;

rcpnt_2dim: ^procedure (               {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param;

rcpnt_2dimi: ^procedure (              {set current point with relative coordinates}
  in      idx, idy: sys_int_machine_t); {integer displacement from old current point}
  val_param;

rcpnt_3dpl: ^procedure (               {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param;

rgb: ^procedure (                      {set flat RGB color}
  in      r, g, b: real);              {0.0-1.0 red, green, blue color values}
  val_param;

rgbz_linear: ^procedure (              {set linear values for RGBZ interpolants}
  in      v1, v2, v3: rend_color3d_t); {XYZ and RGB at three points}

rgbz_quad: ^procedure (                {set quadratic RGB and linear Z values}
  in      v1, v2, v3: rend_color3d_t;  {XYZ,RGB points used to make linear Z}
  in      v4, v5, v6: rend_color3d_t); {extra points used to make quad RGB, Z unused}

run_config: ^procedure (               {configure run length pixel data format}
  in      pxsize: sys_int_adr_t;       {machine adr offset from one run to next}
  in      runlen_ofs: sys_int_adr_t);  {machine address into pixel start for runlen}
  val_param;

shade_geom: ^procedure (               {set geometry mode for implicit color gen}
  in      geom_mode: rend_iterp_mode_k_t); {flat, linear, etc}
  val_param;

shnorm_break_cos: ^procedure (         {set threshold for making break in spokes list}
  in      c: real);                    {COS of max allowed deviation angle}
  val_param;

shnorm_unitized: ^procedure (          {tell whether shading normals will be unitized}
  in      on: boolean);                {future shading norms must be unitized on TRUE}
  val_param;

span_config: ^procedure (              {configure SPAN primitives data format}
  in      pxsize: sys_int_adr_t);      {machine adr offset from one pixel to next}
  val_param;

start_group: ^procedure;               {indicate start sending only one PRIM type}

suprop_all_off: ^procedure;            {turn off all surface properties for this face}

suprop_diff: ^procedure (              {set diffuse property and turn it ON}
  in      r, g, b: real);              {diffuse color}
  val_param;

suprop_emis: ^procedure (              {set emissive property and turn it ON}
  in      r, g, b: real);              {emissive color}
  val_param;

suprop_on: ^procedure (                {turn particular surface property on/off}
  in      suprop: rend_suprop_k_t;     {surf prop ID, use REND_SUPROP_xx_K constants}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

suprop_spec: ^procedure (              {set specular property and turn it ON}
  in      r, g, b: real;               {specular color}
  in      e: real);                    {specular exponent}
  val_param;

suprop_trans: ^procedure (             {set transparency property and turn it ON}
  in      front: real;                 {opaqueness when facing head on}
  in      side: real);                 {opaqueness when facing sideways}
  val_param;

suprop_val: ^procedure (               {set value for particular surface property}
  in      suprop: rend_suprop_k_t;     {surf prop ID, use REND_SUPROP_xx_K constants}
  in      val: rend_suprop_val_t);     {SUPROP dependent data values}
  val_param;

surf_face_curr: ^procedure (           {set which suprop to use for future set/get(s)}
  in      face: rend_face_k_t);        {polygon face select, use REND_FACE_xx_K}
  val_param;

surf_face_on: ^procedure (             {enable surface properties for current face}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

text_parms: ^procedure (               {set parameters and swithces for TEXT primitive}
  in      parms: rend_text_parms_t);   {new values for the modes and switches}

text_pos_org: ^procedure;              {move TEXT origin to TXDRAW current point}

tmap_accur: ^procedure (               {set texture mapping accuracy level}
  in      accur: rend_tmapaccu_k_t);   {new accuracy mode, use REND_TMAPACCU_xxx_K}
  val_param;

tmap_changed: ^procedure;              {indicate that texture map data got changed}

tmap_dimension: ^procedure (           {set texture mapping dimensionality level}
  in      level: rend_tmapd_k_t);      {texture map dimension level ID number}
  val_param;

tmap_filt: ^procedure (                {set texture mapping filtering methods}
  in      filt: rend_tmapfilt_t);      {set of texture mapping filtering flags}
  val_param;

tmap_flims: ^procedure (               {set limits on texture mapping filtering}
  in      min_size: real;              {min size map to use, in pixels accross}
  in      max_size: real);             {max size map to use, in pixels accross}
  val_param;

tmap_func: ^procedure (                {set texture mapping function}
  in      func: rend_tmapf_k_t);       {ID number for new texture mapping function}
  val_param;

tmap_method: ^procedure (              {set texture mapping method}
  in      method: rend_tmapm_k_t);     {texture mapping method ID number}
  val_param;

tmap_on: ^procedure (                  {turn texture mapping on/off}
  in      on: boolean);                {TRUE to turn texture mapping on}
  val_param;

tmap_src: ^procedure (                 {set texture map source for this interpolant}
  in      iterp: rend_iterp_k_t;       {ID of interpolant to set texmap source for}
  in      bitmap: rend_bitmap_handle_t; {handle to bitmap containing source pixels}
  in      offset: sys_int_adr_t;       {adr offset within pixel for this interpolant}
  in      x_size, y_size: sys_int_machine_t; {dimensions of texture map within bitmap}
  in      x_orig, y_orig: sys_int_machine_t); {origin of texture map within bitmap}
  val_param;

update_mode: ^procedure (              {select how display is updated when SW emul}
  in      mode: rend_updmode_k_t);     {update mode, use REND_UPDMODE_xxx_K}
  val_param;

vect_parms: ^procedure (               {set parameters and switches for VECT call}
  in      parms: rend_vect_parms_t);   {new values for the modes and switches}

vert3d_ent_all_off: ^procedure;        {turn off all vertex descriptor entries}

vert3d_ent_off: ^procedure (           {turn off an entry type in vertex descriptor}
  in      ent_type: rend_vert3d_ent_vals_t); {ID of entry type to turn OFF}
  val_param;

vert3d_ent_on: ^procedure (            {turn on an entry type in vertex descriptor}
  in      ent_type: rend_vert3d_ent_vals_t; {ID of entry type to turn ON}
  in      offset: sys_int_adr_t);      {adr offset for this ent from vert desc start}
  val_param;

vert3d_ent_on_always: ^procedure (     {promise vertex entry will always be used}
  in      ent_type: rend_vert3d_ent_vals_t); {ID of entry that will always be used}
  val_param;

video_sync_int_clr: ^procedure;        {clear flag that video sync has been interrupted}

xform_text: ^procedure (               {set new TEXT --> TXDRAW transform}
  in      xb: vect_2d_t;               {X basis vector}
  in      yb: vect_2d_t;               {Y basis vector}
  in      ofs: vect_2d_t);             {offset vector}

xform_2d: ^procedure (                 {set new absolute 2D transform}
  in      xb: vect_2d_t;               {X basis vector}
  in      yb: vect_2d_t;               {Y basis vector}
  in      ofs: vect_2d_t);             {offset vector}

xform_3d: ^procedure (                 {set new 3D to 3DW space transform}
  in      xb, yb, zb: vect_3d_t;       {X, Y, and Z basis vectors}
  in      ofs: vect_3d_t);             {offset (translation) vector (in 3DW space)}
  val_param;

xform_3d_postmult: ^procedure (        {postmult new matrix to old and make current}
  in      m: vect_mat3x4_t);           {new matrix to postmultiply to existing}
  val_param;

xform_3d_premult: ^procedure (         {premult new matrix to old and make current}
  in      m: vect_mat3x4_t);           {new matrix to premultiply to existing}
  val_param;

xform_3dpl_2d: ^procedure (            {set new 2D transform in 3DPL space}
  in      xb: vect_2d_t;               {X basis vector}
  in      yb: vect_2d_t;               {Y basis vector}
  in      ofs: vect_2d_t);             {offset vector}

xform_3dpl_plane: ^procedure (         {set new current plane for 3D space}
  in      org: vect_3d_t;              {origin for 2D space}
  in      xb: vect_3d_t;               {X basis vector}
  in      yb: vect_3d_t);              {Y basis vector}

xsec_circle: ^procedure (              {create new unit-circle crossection}
  in      nseg: sys_int_machine_t;     {number of line segments in the circle}
  in      smooth: boolean;             {TRUE if should smooth shade around circle}
  in      scope: rend_scope_t;         {what scope new crossection will belong to}
  out     xsec_p: rend_xsec_p_t);      {returned handle to new crossection}
  val_param;

xsec_close: ^procedure (               {done adding points, freeze xsec definition}
  in out  xsec: rend_xsec_t;           {crossection to close}
  in      connect: boolean);           {TRUE if connect last point to first point}
  val_param;

xsec_create: ^procedure (              {create new crossection descriptor}
  in      scope: rend_scope_t;         {what scope new crossection will belong to}
  out     xsec_p: rend_xsec_p_t);      {returned user handle to new crossection}
  val_param;

xsec_curr: ^procedure (                {declare current crossection for future use}
  in      xsec: rend_xsec_t);          {crossection to make current}
  val_param;

xsec_delete: ^procedure (              {delete crossection, deallocate resources}
  in out  xsec_p: rend_xsec_p_t);      {crossection handle, will be set to invalid}

xsec_pnt_add: ^procedure (             {add point to end of xsec, full features}
  in out  xsec: rend_xsec_t;           {crossection to add point to}
  in      coor: vect_2d_t;             {coordinate, intended to be near unit circle}
  in      norm_bef: vect_2d_t;         {2D shading normal at or just before here}
  in      norm_aft: vect_2d_t;         {2D shading normal just after here}
  in      smooth: boolean);            {TRUE if NORM_BEF to apply to whole point}
  val_param;

z_clip: ^procedure (                   {set 3DW space Z clip limits}
  in      near: real;                  {objects get clipped when Z > this value}
  in      far: real);                  {objects get clipped when Z < this value}
  val_param;

zfunc: ^procedure (                    {set new current Z compare function}
  in      zfunc: rend_zfunc_k_t);      {the Z compare function number}
  val_param;

zon: ^procedure (                      {turn Z buffering on/off}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

z_range: ^procedure (                  {set 3DW space to full Z buffer range mapping}
  in      near: real;                  {3DW Z coordinate of Z buffer 1.0 value}
  in      far: real);                  {3DW Z coordinate of Z buffer -1.0 value}
  val_param;

    end;
{
***************************************************************************************
*
*   Here are all the entry points that return information, usually about the current
*   state.  These calls are all guaranteed not to alter any RENDlib internal state.
}
  rend_get_t = record

aa_border: ^procedure (                {return border needed for curr AA filter}
  out     xp, yp: sys_int_machine_t);  {pixels border needed for each dimension}

aa_radius: ^procedure (                {return current anti-aliasing filter radius}
  out     r: real);                    {filter kernal radius in output image pixels}

bench_flags: ^function                 {return current benchmark flag settings}
  :rend_bench_t;

bits_hw: ^procedure (                  {get physical bits per pixel actually in use}
  out     n: real);                    {physical bits per pixel}

bits_vis: ^procedure (                 {get effective bits per pixel actually in use}
  out     n: real);                    {effective visible bits per pixel}

bxfnv_3d: ^procedure (                 {transform normal vector from 3DW to 3D space}
  in      in_v: vect_3d_t;             {input normal vector in 3D world space}
  out     out_v: vect_3d_t);           {result in 3D model space, may be IN_V}
  val_param;

bxfpnt_2d: ^procedure (                {transform point backwards thru 2D xform}
  in      in_xy: vect_2d_t;            {input 2DIM space point}
  out     out_xy: vect_2d_t);          {output 2D space point}

bxfpnt_3d: ^procedure (                {transform point from 3DW to 3D space}
  in      in_xyz: vect_3d_t;           {3DW space input coordinate}
  out     out_xyz: vect_3d_t);         {3D space output coordinate, may be IN_XYZ}
  val_param;

bxfpnt_3dpl: ^procedure (              {transform point from 3D to 3DPL space}
  in      ipnt: vect_3d_t;             {input point in 3D space}
  out     opnt: vect_2d_t);            {output point in 3DPL space}
  val_param;

bxfv_3d: ^procedure (                  {transform vector from 3DW to 3D space}
  in      in_v: vect_3d_t;             {input vector in 3D world space}
  out     out_v: vect_3d_t);           {result in 3D model space, may be IN_V}
  val_param;

cirres: ^function (                    {get value of particular CIRRES parameter}
  in      n: sys_int_machine_t)        {1 - REND_LAST_CIRRES_K, clipped to range}
  :sys_int_machine_t;                  {value of selected CIRRES parameter}
  val_param;

clip_poly_2dimcl: ^procedure (         {run polygon thru 2DIMCL clipping}
  in out  state: rend_clip_state_k_t;  {for remembering multiple output fragments}
  in      in_n: sys_int_machine_t;     {number of verticies in input polygon}
  in      in_poly: rend_2dverts_t;     {verticies of input polygon}
  out     out_n: sys_int_machine_t;    {number of verts in this output fragment}
  out     out_poly: rend_2dverts_t);   {verticies in this output fragment}
  val_param;

clip_vect_2dimcl: ^procedure (         {run vector thru 2DIMCL clipping}
  in out  state: rend_clip_state_k_t;  {for remembering multiple output vectors}
  in      in_vect: rend_2dvect_t;      {original unclipped input vector}
  out     out_vect: rend_2dvect_t);    {this fragment of clipped output vector}

clip_2dim_handle: ^procedure (         {make new  handle for 2D image space clip wind}
  out     handle: rend_clip_2dim_handle_t); {return a valid clip window handle}

cmode_vals: ^procedure (               {get current state of all changeable modes}
  out     vals: rend_cmode_vals_t);    {data block with all changeable modes values}

cmodes: ^procedure (                   {get list of automatically changed modes}
  in      maxn: sys_int_machine_t;     {max size list to pass back}
  out     n: sys_int_machine_t;        {actual number of modes passed back in list}
  out     list: univ rend_cmodes_list_t); {buffer filled with N mode IDs}
  val_param;

color_xor: ^procedure (                {get color to XOR between two other colors}
  in      color1, color2: rend_rgb_t;  {two colors to toggle between}
  out     color_xor: rend_rgb_t);      {color value to use with XOR pixel function}
  val_param;

comments_list: ^procedure (            {get handle to current comments list}
  out     list_p: string_list_p_t);    {string list handle, use STRING calls to edit}

context: ^procedure (                  {save current context into context block}
  in      handle: rend_context_handle_t); {handle of context block to write to}
  val_param;

cpnt_text: ^procedure (                {return the current point}
  out     x, y: real);                 {current point in this space}

cpnt_txdraw: ^procedure (              {return the current point}
  out     x, y: real);                 {current point in this space}

cpnt_2d: ^procedure (                  {return the current point}
  out     x, y: real);                 {current point in this space}

cpnt_2dim: ^procedure (                {return the current point}
  out     x, y: real);                 {current point in this space}

cpnt_2dimi: ^procedure (               {return the current point}
  out     ix, iy: sys_int_machine_t);  {integer pixel address of current point}

cpnt_3d: ^procedure (                  {return 3D model space current point}
  out     x, y, z: real);

cpnt_3dpl: ^procedure (                {return the current point}
  out     x, y: real);                 {current point in this space}

cpnt_3dw: ^procedure (                 {return 3D world space current point}
  out     x, y, z: real);

dev_id: ^procedure (                   {find out what device is current}
  out     dev_id: rend_dev_id_t);      {current RENDlib device ID}

disp_buf: ^procedure (                 {return number of current display buffer}
  out     n: sys_int_machine_t);       {current display buffer number}

dith_on: ^procedure (                  {get current state of dithering on/off flag}
  out     on: boolean);                {TRUE if dithering turned on}

draw_buf: ^procedure (                 {return number of current drawing buffer}
  out     n: sys_int_machine_t);       {current drawing buffer number}

enter_level: ^procedure (              {get depth of ENTER_REND nesting level}
  out     level: sys_int_machine_t);   {current nested graphics mode level}

event_possible: ^function (            {find whether event might ever occurr}
  event_id: rend_ev_k_t)               {event type inquiring about}
  :boolean;                            {TRUE when event is possible and enabled}
  val_param;

close_corrupt: ^function: boolean;     {true if display is corrupted on close of device}

force_sw_update: ^procedure (          {return what user last set FORCE_SW_UPDATE to}
  out     on: boolean);                {last user setting of FORCE_SW_UPDATE}

image_size: ^procedure (               {return dimension and aspect ratio of image}
  out     x_size, y_size: sys_int_machine_t; {image width and height in pixels}
  out     aspect: real);               {DX/DY aspect ratio when displayed}

iterps_on_list: ^procedure (           {get list of all the curr ON interpolants}
  out     n: sys_int_machine_t;        {number of interpolants currently ON}
  out     list: rend_iterps_list_t);   {N interpolant IDs}

iterps_on_set: ^function               {get SET indicating the ON interpolants}
  :rend_iterps_t;

keys: ^procedure (                     {get info about all available keys}
  out     keys_p: univ rend_key_ar_p_t; {pointer to array of all the key descriptors}
  out     n: sys_int_machine_t);       {number of valid entries in KEYS}

key_sp: ^function (                    {get ID of a special pre-defined key}
  in      id: rend_key_sp_k_t;         {ID for this special key}
  in      detail: sys_int_machine_t)   {detail info for this key}
  :rend_key_id_t;                      {key ID or REND_KEY_NONE_K}
  val_param;

key_sp_def: ^procedure (               {get "default" or "empty" special key data}
  out     key_sp_data: rend_key_sp_data_t); {returned special key data block}

light_eval: ^procedure (               {get point color by doing lighting evaluation}
  in      vert: univ rend_vert3d_t;    {vertex descriptor to find colors at}
  in out  ca: rend_vcache_t;           {cache data for this vertex}
  in      norm: vect_3d_t;             {unit normal vector at point}
  in      sp: rend_suprop_t);          {visual surface properties descriptor block}

lights: ^procedure (                   {get handles to all light sources}
  in      max_n: sys_int_machine_t;    {max number of light handles to return}
  in      start_n: sys_int_machine_t;  {starting light num, first is 1}
  out     llist: univ rend_light_handle_ar_t; {returned array of light handles}
  out     ret_n: sys_int_machine_t;    {number of light handles returned}
  out     total_n: sys_int_machine_t); {number of lights currently in existance}
  val_param;

max_buf: ^procedure (                  {return max buffers available on device}
  out     n: sys_int_machine_t);       {number of highest buffer, first buffer is 1}

min_bits_hw: ^procedure (              {return current HW_MIN_BITS setting}
  out     n: real);                    {actual number of hardware bits per pixel used}

min_bits_vis: ^procedure (             {return current VIS_MIN_BITS setting}
  out     n: real);                    {Log2 of total effective number of colors}

perspec: ^procedure (                  {get current perspective parameters}
  out     on: boolean;                 {TRUE if perspective projection on}
  out     eyedis: real);               {eye distance perspective value, 3.3 = normal}

pointer: ^function (                   {get current pointer location}
  out     x, y: sys_int_machine_t)     {pointer coordinates within this device}
  :boolean;                            {TRUE if pointer is within this device area}

pointer_abs: ^function (               {get current absolute pointer location}
  out     x, y: sys_int_machine_t)     {pointer coordinates on "root" device}
  :boolean;                            {TRUE if pointer is within root device area}

poly_parms: ^procedure (               {get the current polygon drawing control parms}
  out     parms: rend_poly_parms_t);   {current polygon drawing parameters}

ray_bounds_3dw: ^procedure (           {get current bounds of saved ray primitives}
  out     xmin, xmax: real;            {3D world space axis-aligned bounding box}
  out     ymin, ymax: real;
  out     zmin, zmax: real;
  out     stat: sys_err_t);            {completion status code}

ray_callback: ^function                {return current ray callback entry point}
  :rend_raytrace_p_t;                  {routine pointer or NIL for none}

reading_sw: ^procedure (               {find out if reading SW bitmap}
  out     reading: boolean);           {TRUE if modes require reading SW bitmap}

reading_sw_prim: ^procedure (          {find if specific primitive reads from SW}
  in      prim_p: univ_ptr;            {call table entry for primitive to ask about}
  out     sw_read: boolean);           {TRUE if prim will read from SW bitmap}

suprop: ^procedure (                   {get current state of a surface property}
  in      suprop: rend_suprop_k_t;     {surface property ID, use REND_SUPROP_xxx_K}
  out     on: boolean;                 {TRUE if this surface property turned ON}
  out     val: rend_suprop_val_t);     {current values for this surface property}
  val_param;

text_parms: ^procedure (               {get all current modes and switches for text}
  out     parms: rend_text_parms_t);   {current modes and switches values}

txbox_text: ^procedure (               {get box around text string}
  in      s: univ string;              {text string}
  in      slen: string_index_t;        {number of characters in string}
  out     bv: vect_2d_t;               {baseline vector, along base of char cells}
  out     up: vect_2d_t;               {character cell UP direction and size}
  out     ll: vect_2d_t);              {lower left corner of text string box}
  val_param;

txbox_txdraw: ^procedure (             {get box around text string}
  in      s: univ string;              {text string}
  in      slen: string_index_t;        {number of characters in string}
  out     bv: vect_2d_t;               {baseline vector, along base of char cells}
  out     up: vect_2d_t;               {character cell UP direction and size}
  out     ll: vect_2d_t);              {lower left corner of text string box}
  val_param;

update_sw: ^procedure (                {return current state of UPDATE_SW flag}
  out     on: boolean);                {TRUE if software updates are on}

update_sw_prim: ^procedure (           {find if specific primitive writing to SW}
  in      prim_p: univ_ptr;            {call table entry for primitive to ask about}
  out     sw_write: boolean);          {TRUE if prim will write to SW bitmap}

vect_parms: ^procedure (               {get modes and switches for VECT primitives}
  out     parms: rend_vect_parms_t);   {values of current modes and switches}

video_sync_int: ^function:             {TRUE if video sync has been interrupted since}
  boolean;                             {flag cleared by rend_set.video_sync_int_clr}

wait_exit: ^procedure (                {wait for user to request program exit}
  in      flags: rend_waitex_t);       {set of flags REND_WAITEX_xxx_K}
  val_param;

xfnorm_3d: ^procedure (                {transform normal vector from 3D to 3DW space}
  in      inorm: vect_3d_t;            {vector in 3D space, need not be unit length}
  out     onorm: vect_3d_t);           {unit vect in 3DW space, may be same as INORM}
  val_param;

xform_2d: ^procedure (                 {read back current 2D transform}
  out     xb: vect_2d_t;               {X basis vector}
  out     yb: vect_2d_t;               {Y basis vector}
  out     ofs: vect_2d_t);             {offset vector}

xform_3d: ^procedure (                 {return the current 3D to 3DW transform}
  out     xb, yb, zb: vect_3d_t;       {X, Y, and Z basis vectors}
  out     ofs: vect_3d_t);             {offset (translation) vector (in 3DW space)}

xform_3dpl_2d: ^procedure (            {get 2D transform in 3D current plane}
  out     xb: vect_2d_t;               {X basis vector}
  out     yb: vect_2d_t;               {Y basis vector}
  out     ofs: vect_2d_t);             {offset vector}

xform_3dpl_plane: ^procedure (         {get definition of current plane in 3D space}
  out     org: vect_3d_t;              {origin for 2D space}
  out     xb: vect_3d_t;               {X basis vector}
  out     yb: vect_3d_t);              {Y basis vector}

xform_text: ^procedure (               {get TEXT --> TXDRAW current transform}
  out     xb: vect_2d_t;               {X basis vector}
  out     yb: vect_2d_t;               {Y basis vector}
  out     ofs: vect_2d_t);             {offset vector}

xfpnt_2d: ^procedure (                 {transform point from 2D to 2DIM space}
  in      in_xy: vect_2d_t;            {input point in 2D space}
  out     out_xy: vect_2d_t);          {output point in 2DIM space}

xfpnt_3d: ^procedure (                 {transform point from 3D to 3DW space}
  in      ipnt: vect_3d_t;             {input point in 3D space}
  out     opnt: vect_3d_t);            {3DW space point, may be same as IPNT arg}
  val_param;

xfpnt_3dpl: ^procedure (               {transform point from 3DPL to 3D space}
  in      ipnt: vect_2d_t;             {input point in 3DPL space}
  out     opnt: vect_3d_t);            {output point in 3D space}
  val_param;

xfpnt_text: ^procedure (               {transform point from TEXT to TXDRAW space}
  in      in_xy: vect_2d_t;            {input point in TEXT space}
  out     out_xy: vect_2d_t);          {output point in TXDRAW space}

xfvect_text: ^procedure (              {transform vector from TEXT to TXDRAW space}
  in      in_v: vect_2d_t;             {input vector in TEXT space}
  out     out_v: vect_2d_t);           {output vector in TXDRAW space}

z_2d: ^procedure (                     {return Z coor after transform from 3DW to 2D}
  out     z: real);                    {effective Z coordinate in 2D space}

z_bits: ^procedure (                   {return current Z buffer resolution}
  out     n: real);                    {effective Z buffer resolution in bits}

z_clip: ^procedure (                   {get current 3DW space Z clipping limits}
  out     near, far: real);            {Z limits, normally NEAR > FAR}

  end;
{
******************************************
*
*   Common block to hold the current set of pointers to the various graphics function
*   routines.
}
var (rend)
  rend_com_start: sys_int_machine_t;   {to enable finding adr of common block}
  rend_prim: rend_prim_t;              {entry points for drawing primitive routines}
  rend_set: rend_set_t;                {entry points for state setting routines}
  rend_get: rend_get_t;                {entry points that return information}
  rend_com_end: sys_int_machine_t;     {to enable finding size of common block}
{
******************************************
*
*   Direct entry points that need to be globally known.
*
*   RENDlib control routines:
}
procedure rend_start;                  {must be first REND call}
  extern;

procedure rend_open (                  {open a new RENDlib device}
  in      name: univ string_var_arg_t; {RENDlib device name and parameters}
  out     dev_id: rend_dev_id_t;       {returned device ID for this connection}
  out     stat: sys_err_t);            {completion status code}
  extern;

procedure rend_dev_set (               {swap in new device, ENTER_LEVEL will be 0}
  in      dev_id: sys_int_machine_t);  {RENDlib device ID from REND_OPEN}
  val_param; extern;

procedure rend_end;                    {completely exit RENDlib, close all devices}
  extern;

{
*   Utility routines that can effect RENDlib internally.
}
procedure rend_mem_alloc (             {get memory under specific memory context}
  in      size: sys_int_adr_t;         {size of region to allocate}
  in      scope: rend_scope_t;         {scope of new region, use REND_SCOPE_xxx_K}
  in      ind: boolean;                {TRUE if need to individually deallocate mem}
  out     adr: univ_ptr);              {start adr of region, NIL for unavailable}
  val_param; extern;

procedure rend_mem_dealloc (           {release memory allocated with REND_MEM_ALLOC}
  in out  adr: univ_ptr;               {starting adr of memory, returned NIL}
  in      scope: rend_scope_t);        {scope that memory was allocated under}
  val_param; extern;

procedure rend_error_abort (           {close RENDlib, print msg and bomb if error}
  in      stat: sys_err_t;             {error code}
  in      subsys_name: string;         {subsystem name of caller's message}
  in      msg_name: string;            {name of caller's message within subsystem}
  in      parms: univ sys_parm_msg_ar_t; {array of parameter descriptors}
  in      n_parms: sys_int_machine_t); {number of parameters in PARMS}
  val_param; extern;

procedure rend_event_enqueue (         {add event to end of RENDlib's event queue}
  in      event: rend_event_t);        {this will be last event in the queue}
  extern;

procedure rend_event_get (             {get next RENDlib event when available}
  out     event: rend_event_t);        {returned event descriptor}
  extern;

procedure rend_event_get_nowait (      {get next event, none if queue is empty}
  out     event: rend_event_t);        {returned event descriptor}
  extern;

function rend_event_key_multiple (     {get number of repeated KEY events}
  in      event: rend_event_t)         {key down event that may be repeated}
  :sys_int_machine_t;                  {total repeated key presses, EVENT}
  val_param; extern;

procedure rend_event_push (            {push event onto head of event queue}
  in      event: rend_event_t);        {this will be the next event returned}
  extern;

procedure rend_event_req_stdin_line (  {request STDIN_LINE events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param; extern;

procedure rend_get_stdin_line (        {get next line from standard input}
  in out  s: univ string_var_arg_t);   {returned line of text}
  extern;

procedure rend_message_bomb (          {close RENDlib, print message, then bomb}
  in      subsys: string;              {name of subsystem, used to find message file}
  in      msg: string;                 {message name withing subsystem file}
  in      parms: univ sys_parm_msg_ar_t; {array of parameter descriptors}
  in      n_parms: sys_int_machine_t); {number of parameters in PARMS}
  options (extern, val_param, noreturn);

{
*   Utility routines that are "external" to the rest of RENDlib.  These don't
*   effect any internal RENDlib state.
}
procedure rend_make_spokes_pnt (       {set SPOKES_P field in vertex descriptor}
  in out  vert: univ rend_vert3d_t;    {vertex descriptor in which to set SPOKES_P}
  in      vert1, vert2: univ rend_vert3d_t; {adjacent verticies to VERT}
  in      spokes_lists: univ rend_spokes_lists_t); {all the spokes lists at this coor}
  extern;

procedure rend_spokes_to_norm (        {compute shading normal from vert spokes list}
  in      vert: univ rend_vert3d_t;    {vertex descriptor where want shading normal}
  in      unitize: boolean;            {resulting normals will be unitized if TRUE}
  out     shade_norm: vect_3d_t);      {returned non-unit shading normal vector}
  val_param; extern;

procedure rend_tbpoint_2d_3d (         {make full 3D xforms from XB,YB in tube point}
  in out  tp: rend_tube_point_t);      {will fill in ZB, NXB, NYB, NZB given XB, YB}
  extern;

procedure rend_vs_to_spokes (          {compute vert spokes list from list of Vs}
  in      v_list: univ rend_v_list_t;  {list of Vs in any order}
  in      n_v: sys_int_machine_t;      {number of Vs in V list}
  in      vert: univ rend_vert3d_t;    {center vertex for all the Vs}
  out     spokes_sets_p: rend_spokes_lists_p_t); {spokes sets list is dyn allocated}
  val_param; extern;
