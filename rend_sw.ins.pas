{   This include file defines the data structures and common block used by all
*   the software-only REND library routines.  It will probably also be used by most
*   device-specific drivers.
}
const
  rend_max_lines = 8192;               {max scan lines allowed in an image}
  rend_max_clip_2dim = 32;             {max number of 2D image space clip windows}
  rend_max_font_index = 16383;         {max index to font data array}
  rend_max_end_nsides = 100;           {max number of poly sides allowed in vect end}
  rend_max_iterp_tmap = 13;            {LOG2 max texmap size in interpolant block}
  rend_default_break_degrees = 10.0;   {default max angle for averaging shading norm}
  rend_max_save_blocks = 8;            {max different mem blocks in save area}
  rend_vert3d_size_simple_k =          {max size vertex descriptor for optimiziation}
    sizeof(univ_ptr) * 8;              {room for eight pointers}

  rend_pi = 3.141592653;               {what it sounds like, don't touch}
  rend_pi2 = 2.0 * rend_pi;            {ditto}
  rend_max_y = rend_max_lines-1;       {max allowable Y pixel coordinate}
  rend_max_end_points = rend_max_end_nsides+1; {max allowed verticies in vect end cap}
  rend_default_break_radians =         {default max angle for averaging shading norm}
    rend_default_break_degrees * rend_pi / 180.0;

  rend_clmask_ty_k = 1;                {clip mask value for past top Y}
  rend_clmask_by_k = 2;                {clip mask value for past bottom Y}
  rend_clmask_lx_k = 4;                {clip mask value for past left X}
  rend_clmask_rx_k = 8;                {clip mask value for past right X}
  rend_clmask_fz_k = 16;               {clip mask value for past far Z}
  rend_clmask_nz_k = 32;               {clip mask value for past near Z}
{
*   Declare data types that depend on processor byte order.
}
%include 'rend_sw_sys.ins.pas';

type
  rend_suprop_state_t = record         {general surface properties info}
    changed: boolean;                  {SUPROP state changed since last CHECK_MODES}
    end;

  rend_dir_k_t = (                     {span writing "direction"}
    rend_dir_right_k,                  {writing trapezoid pixels left to right}
    rend_dir_left_k,                   {writing trapezoid pixels right to left}
    rend_dir_vect_k);                  {writing vector pixels}

  rend_xf3d_t = record                 {3D transform and related data}
    cpnt: vect_3d_t;                   {current point before transform}
    xb, yb, zb, ofs: vect_3d_t;        {forward transformation matrix}
    scale: real;                       {forward scale factor when ROT_SCALE TRUE}
    vxb, vyb, vzb: vect_3d_t;          {normal vector transformation matrix.  Size
                                        adjusted so that vector magnitude preserved
                                        when ROT_SCALE is TRUE}
    rxb, ryb, rzb: vect_3d_t;          {reverse transformation matrix}
    vradx, vrady, vradz: vect_3d_t;    {used for adjusting 3D space vector to
                                        proper magnitude for vector thickness radius
                                        in space vectors get thickned in.  If
                                        sum of squares of dot product with these and
                                        a 3D space vector is 1, then 3D space vector
                                        will map to vector thickness radius.}
    rmat_ok: boolean;                  {TRUE if reverse matrix exists (and is set)}
    right: boolean;                    {TRUE if right handed matrix}
    vrad_ok: boolean;                  {TRUE if VRAD.. fields set correctly}
    rot_scale: boolean;                {TRUE if only rotation and uniform scaling}
    end;

  rend_view_t = record                 {view transform and related data}
    cpnt: vect_3d_t;                   {current point before transform}
    eyedis: real;                      {eye distance dimensionless perspective number}
    zrange_near: real;                 {maps to Z interpolant value 1.0}
    zrange_far: real;                  {maps to Z interpolant value -1.0}
    zmult, zadd: real;                 {linear correction for Z after perspective}
    zclip_near: real;                  {object clipped if less than this value}
    zclip_far: real;                   {object clipped if greater than this value}
    backface: rend_bface_k_t;          {backfacing function ID}
    perspec_on: boolean;               {TRUE if perspective is turned on}
    cpnt_clipped: boolean;             {TRUE if current point outside Z clip range}
    end;

  rend_equation_t = record             {the stuff for one of the linear equations}
    dx: real;                          {coefficient for X delta from vertex 1}
    dy: real;                          {coefficient for Y delta from vertex 1}
    dxx: real;                         {coef for second X derivative}
    dyy: real;                         {coef for second Y derivative}
    dxy: real;                         {coef for crossover derivative}
    di: real;                          {coef for intensity delta from vertex 1}
    end;

  rend_geom_point_t = record           {saved data for one geometry anchor point}
    coor: vect_2d_t;                   {coordinate of this point}
    dx: real;                          {delta X from point 1 * 1/determinant}
    dy: real;                          {delta Y from point 1 * 1/determinant}
    end;

  rend_geom_t = record                 {saved geom data for making derivatives later}
    valid: boolean;                    {TRUE if geom data has sufficient area}
    mat: array[1..5] of rend_equation_t; {lin equations to solve for differentials}
    p1, p2, p3: rend_geom_point_t;     {data for linear surface definition}
    end;

  rend_mipmap_blend_t =                {table of mult fractions for larger map}
    array[0..255] of sys_int_conv24_t; {mult fraction with 16 bits below bin point}

  rend_tmap_mipmap_t = record          {tmap control specific to mip map method}
    min_map: sys_int_machine_t;        {LOG2 pixel width of smallest map to use}
    max_map: sys_int_machine_t;        {LOG2 pixel width of largest map to use}
    blend: rend_mipmap_blend_t;        {table for blend between adjacent size maps}
    end;

  rend_tmap_t = record                 {template for all the texture mapping control}
    on: boolean;                       {TRUE for texture mapping turned on}
    func: rend_tmapf_k_t;              {function select, REND_TMAPF_xxx_K}
    dim: rend_tmapd_k_t;               {dimension level flag, REND_TMAPD_xxx_K}
    accur: rend_tmapaccu_k_t;          {accuracy requirement, REND_TMAPACCU_xxx_K}
    filt: rend_tmapfilt_t;             {filtering methods, set of REND_TMAPFILT_xxx_K}
    method: rend_tmapm_k_t;            {texture mapping method, REND_TMAPM_xxx_K}
    case rend_tmapm_k_t of             {separate data for each tmap method}
rend_tmapm_mip_k: (                    {method is MIP MAPPING}
      mip: rend_tmap_mipmap_t;         {texture mapping control for mipmap method}
      );
    end;

  rend_dith_t = record                 {record for all the dithering information}
    on: boolean;                       {TRUE for on, FALSE for closest approximation}
    end;

  rend_2dspace_t = record              {mandatory data for a 2D coordinate space}
    cpnt: vect_2d_t;                   {current point}
    xb: vect_2d_t;                     {X basis vector}
    yb: vect_2d_t;                     {Y basis vector}
    ofs: vect_2d_t;                    {offset vector}
    invm: real;                        {multiplier for inverse transformation}
    inv_ok: boolean;                   {TRUE if inverse transform exists}
    right: boolean;                    {TRUE if transform is right handed}
    end;
  rend_2dspace_p_t = ^rend_2dspace_t;

  rend_font_ar_entry_t = record case integer of {one entry in font array}
    1:(i: sys_int_fp1_t);              {integer for specifying new indicies}
    2:(f: sys_fp1_t);                  {floating point for coordinate values}
    end;

  rend_text_state_t = record           {internal state for TEXT operations}
    sp: rend_2dspace_t;                {general description for TEXT coordinate space}
    up: vect_2d_t;                     {up direction one char cell high (no slant)}
    font:                              {data from font file}
      array[0..rend_max_font_index] of rend_font_ar_entry_t;
    end;

  rend_vectcap_t = record              {descriptor for one vector->poly end cap}
    n: sys_int_machine_t;              {number of verticies in end cap}
    vert:                              {vertex list for this vector end}
      array[1..rend_max_end_points] of vect_2d_t;
    end;

  rend_poly_proc_t = ^procedure (      {pointer to a 2D polygon draw routine}
    in      n: sys_int_machine_t;      {number of verticies in VERTS}
    in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
    val_param;

  rend_cpnt_proc_t = ^procedure (      {pointer to a 2D current point routine}
    in      x, y: real);               {new coordinates of curr pnt in this space}
    val_param;

  rend_vect_state_t = record           {internal state for VECT primitives}
    poly_proc_p: ^rend_poly_proc_t;    {points to call table entry where polygons
                                        are sent after conversion from vectors}
    poly_proc_data_p: rend_prim_data_p_t; {pnt to data block for polygon primitive}
                                       {address of pointer to procedure that sets
                                        current point in polygon output space}
    cpnt_proc_p: ^rend_cpnt_proc_t;    {points to call table entry for how to set
                                        current point in vect->poly output space}
    cpnt_p: ^vect_2d_t;                {pointer to current point}
    replaced_prim_entry_p: ^univ_ptr;  {addr of routine pointer in PRIM call table
                                        that was switched to REND_SW_VECT_POLY}
    replaced_prim_data_p:              {addr of data block for replaced primitive}
      rend_prim_data_p_t;
    start_cap: rend_vectcap_t;         {descriptor for shape of vector start}
    end_cap: rend_vectcap_t;           {descriptor for shape of vector end}
    end;

  rend_2d_t = record                   {data for 2D model space to image space xform}
    sp: rend_2dspace_t;                {general description for 2D model coor space}
    uxb, uyb, uofs: vect_2d_t;         {user 2D transform without image scale}
    curr_x2dim, curr_y2dim: real;      {floating point 2D image space current point}
    axis: boolean;                     {TRUE if transform preserves axies}
    end;

  rend_3dpl_t = record                 {data about current plane above 3D space}
    sp: rend_2dspace_t;                {mandatory data about a 2D space}
    u_org: vect_3d_t;                  {user definition of current plane}
    u_xb: vect_3d_t;
    u_yb: vect_3d_t;
    front: vect_3d_t;                  {unit vector out from front side of plane}
    org: vect_3d_t;                    {combined plane definition actually used}
    xb: vect_3d_t;
    yb: vect_3d_t;
    xb_inv: vect_2d_t;                 {inverse of combined transform}
    yb_inv: vect_2d_t;
    zb_inv: vect_2d_t;
    inverse: boolean;                  {TRUE if inverse of combined xform exists}
    end;

  rend_clip_2dim_t = record            {data for one 2D clip rectangle}
    xmin, xmax, ymin, ymax: real;      {high and low coordinage limits for X and Y}
    ixmin, ixmax, iymin, iymax: sys_int_machine_t; {edge pixel coordinates still in window}
    on: boolean;                       {TRUE if clip rectangle is turned on}
    draw_inside: boolean;              {TRUE for draw inside, FALSE for exclude inside}
    exists: boolean;                   {TRUE if handle allocated to this clip rect}
    end;

  rend_clips_2dim_t = record           {all the 2D image space clip windows}
    n_on: sys_int_machine_t;           {number of currently turned on clip windows}
    list_on:                           {list of the currently ON clip windows}
      array[1..rend_max_clip_2dim] of sys_int_machine_t;
    clip:                              {the individual clip windows}
      array[1..rend_max_clip_2dim] of rend_clip_2dim_t;
    end;

  rend_bresenham_t = record            {all the state needed by one Bresenham stepper}
    x, y: sys_int_machine_t;           {current pixel coordinate}
    dxa, dxb: sys_int_machine_t;       {value to add to X for A and B steps}
    dya, dyb: sys_int_machine_t;       {value to add to Y for A and B steps}
    err: sys_int_machine_t;            {error accumulator, A step is ERR < 0}
    dea: sys_int_machine_t;            {value to add to ERR on an A step}
    deb: sys_int_machine_t;            {value to add to ERR on a B step}
    length: sys_int_machine_t;         {number of steps left to take}
    end;

  rend_bitmap_desc_t = record          {descriptor for one bitmap}
    x_size: sys_int_machine_t;         {number of pixels in X direction}
    y_size: sys_int_machine_t;         {number of pixels in Y direction}
    x_offset: sys_int_machine_t;       {number of bytes for next pixel to the right}
    scope_handle: rend_scope_t;        {scope this handle was allocated under}
    scope_pixels: rend_scope_t;        {scope that pixels were allocated under}
    line_p:                            {pointers to all the scan lines}
      array[0..rend_max_y] of univ_ptr;
    end;

  rend_bitmap_desc_p_t =               {pointer to a bitmap descriptor}
    ^rend_bitmap_desc_t;

  rend_iterp_data_pnt_t = record case integer of {pointer to bitmap pixel data}
    1:(p8: ^char);                     {pointer for 8 bit data width}
    2:(p16: ^integer16);               {pointer for 16 bit data width}
    3:(p32: ^integer32);               {pointer for 32 bit data width}
    4:(i: sys_int_adr_t);              {used for arithmetic address manipulation}
    end;

  rend_tmap_iterp_map_t = record       {state block for one source texmap in iterp}
    bitmap: rend_bitmap_desc_p_t;      {pointer to bitmap containing src texture map}
    iterp_offset: sys_int_adr_t;       {adr offset from start of pixel for this iterp}
    x_orig, y_orig: sys_int_machine_t; {pixel origin of texmap within this bitmap}
    x_size, y_size: sys_int_machine_t; {pixel width and height of this texture map}
    end;

  rend_iterp_pix_t = record            {pixel coordinate interpolant definition}
    on: boolean;                       {TRUE if this interpolant participates at all}
    iclamp: boolean;                   {TRUE if use clamped interpolation result}
    pclamp: boolean;                   {TRUE if clamp after pixel function operation}
    aa: boolean;                       {TRUE if anti-aliasing enabled}
    span_run: boolean;                 {TRUE if color can come from SPAN or RUNLEN}
    int: boolean;                      {TRUE if VAL set to explicit integer value}
    pixfun: rend_pixfun_k_t;           {what arithmetic pixel write function to use}
    shmode: rend_iterp_mode_k_t;       {interpolation mode to use for implicit colors}
    mode: rend_iterp_mode_k_t;         {interpolation mode actually in use}
    max_mode: rend_iterp_mode_k_t;     {max of MODE and SHMODE}
    width: sys_int_machine_t;          {data width in bits (only 8,16,32 allowed)}
    wmask: sys_int_machine_t;          {write enable mask in low bits}
    bitmap_p: rend_bitmap_desc_p_t;    {pointer to destination bitmap descriptor}
    bitmap_src_p: rend_bitmap_desc_p_t; {pointer to source bitmap descriptor}
    iterp_offset: sys_int_adr_t;       {bytes from start of pixel for this iterp}
    src_offset: sys_int_adr_t;         {offset from start of src bitmap pixel}
    span_offset: sys_int_adr_t;        {our offset into SPAN pixel}
    run_offset: sys_int_adr_t;         {our offset into runlength descriptor}
    curr_adr: rend_iterp_data_pnt_t;   {pointer to current pixel data}
    curr_src: rend_iterp_data_pnt_t;   {pointer to current source pixel data}

    val_scale: real;                   {VAL.ALL <-- ROUND(65536*(  }
    val_offset: real;                  {  float_value*val_scale + val_offset))  }
    x, y: real;                        {anchor point where value defined explicitly}

    aval: real;                        {value at anchor point}
    adx: real;                         {X partial of value at anchor point}
    ady: real;                         {Y partial of value at anchor point}
    adxx: real;                        {second value derivative along X}
    adyy: real;                        {second value derivative along Y}
    adxy: real;                        {crossover second derivative}

    eval: rend_iterp_val_t;            {value at leading edge}
    edh: rend_iterp_val_t;             {H partial derivative at leading edge}
    eda: rend_iterp_val_t;             {A step partial derivative at leading edge}
    edb: rend_iterp_val_t;             {B step partial derivative at leading edge}
    edhh: rend_iterp_val_t;            {H second derivative}
    edaa: rend_iterp_val_t;            {A second derivative}
    edbb: rend_iterp_val_t;            {B second derivative}
    edab: rend_iterp_val_t;            {A-B crossover second derivative}
    edah: rend_iterp_val_t;            {A-H crossover second derivative}
    edbh: rend_iterp_val_t;            {B-H crossover second derivative}

    val: rend_iterp_val_t;             {value at current pixel}
    dh: rend_iterp_val_t;              {H partial at current pixel}
    iclamp_max: rend_iterp_val_t;      {max allowable limit if I clamping on}
    iclamp_min: rend_iterp_val_t;      {min allowable limit if I clamping on}
    value: rend_iterp_val_t;           {final clamped interpolant value}
    tmap:                              {all the possible source texture map sizes}
      array[0..rend_max_iterp_tmap] of rend_tmap_iterp_map_t;
    end;

  rend_iterp_pix_p_t =                 {pointer to one interpolant definition block}
    ^rend_iterp_pix_t;

  rend_iterps_data_t = record          {template for all interpolant info}
    mask_on: rend_iterps_t;
    n_on: sys_int_machine_t;           {number of current interpolants}
    list_on:                           {pointers to current ON interpolants}
      array[1..rend_n_iterps_k] of rend_iterp_pix_p_t;
    case integer of
      1:(                              {separately named interpolants}
        red: rend_iterp_pix_t;
        grn: rend_iterp_pix_t;
        blu: rend_iterp_pix_t;
        z: rend_iterp_pix_t;
        alpha: rend_iterp_pix_t;
        i: rend_iterp_pix_t;
        u: rend_iterp_pix_t;
        v: rend_iterp_pix_t);
      2:(                              {all the interpolants in an array}
        iterp: array[firstof(rend_iterp_k_t)..lastof(rend_iterp_k_t)]
          of rend_iterp_pix_t);
    end;

  rend_image_t = record                {all the state about the current image}
    x_size, y_size: sys_int_machine_t; {number of pixels horizontally and vertically}
    max_run: sys_int_machine_t;        {max manhatten distance in this image}
    aspect: real;                      {DX/DY ratio of displayed whole image}
    comm: string_list_t;               {handle to comment lines about this image}
    ftype: string_var80_t;             {lower case image file type, blank filled}
    fnam_auto: string_treename_t;      {where to write image automatically on close}
    size_fixed: boolean;               {can't change image size on TRUE}
    end;

  rend_uvwder_t = record               {supplemental derivatives for texture mapping}
    dax: rend_iterp_val_t;             {A-X crossover second derivative}
    day: rend_iterp_val_t;             {A-Y crossover second derivative}
    dbx: rend_iterp_val_t;             {B-X crossover second derivative}
    dby: rend_iterp_val_t;             {B-Y crossover second derivative}
    dhx: rend_iterp_val_t;             {H-X crossover second derivative}
    dhy: rend_iterp_val_t;             {H-Y crossover second derivative}
    edx: rend_iterp_val_t;             {X derivative at leading edge}
    edy: rend_iterp_val_t;             {Y deriavtive at leading edge}
    dx: rend_iterp_val_t;              {X derivative at current pixel}
    dy: rend_iterp_val_t;              {Y derivative at current pixel}
    end;

  rend_poly_state_t = record           {internal state for polygon modes and switches}
    saved_poly_2dim: ^procedure (      {saved copy of POLY_2DIM primitive}
      in      n: sys_int_machine_t;    {number of verticies}
      in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
      val_param;
    saved_poly_2dim_data_p: rend_prim_data_p_t; {pnt to data block for poly prim}
    end;

  rend_lights_t = record               {base data about all the light sources}
    free_p: rend_light_p_t;            {point to first descriptor on free chain}
    used_p: rend_light_p_t;            {point to first used light descriptor}
    on_p: rend_light_p_t;              {point to first ON light descriptor}
    dir_p: rend_light_p_t;             {pnt to single directional light source}
    amb_red, amb_grn, amb_blu: real;   {total ambient light}
    n_alloc: sys_int_machine_t;        {number of light descriptors allocated}
    n_used: sys_int_machine_t;         {number of light descriptors in use}
    n_on: sys_int_machine_t;           {number of light sources currently ON}
    n_amb: sys_int_machine_t;          {number of active ambient lights}
    n_dir: sys_int_machine_t;          {number of active directional lights}
    accuracy: rend_laccu_k_t;          {lighting calculation accuracy mode}
    changed: boolean;                  {lights changed since last CHECK_MODES}
    end;

  rend_aa_t = record                   {all the global state for anti-aliasing}
    scale_x, scale_y: real;            {output size / input size scale factors}
    shrink_x, shrink_y: sys_int_machine_t; {integer shrink factors}
    kernel_dx, kernel_dy: sys_int_machine_t; {filter kernel size in subpixels}
    kernel_rad: real;                  {kernal radius in output pixels}
    start_xofs, start_yofs:            {subpix from pix center to kernel top left}
      sys_int_machine_t;
    filt_int_p: rend_int_ar_p_t;       {points to integer filter kernel coeficients}
    filt_fp_p: rend_real_ar_p_t;       {points to floating point kernal coeficients}
    end;

  rend_curr_span_t = record            {info about span drawn on current scan line}
    left_x, right_x: sys_int_machine_t; {horizontal limits of span}
    y: sys_int_machine_t;              {coordinate of scan line span is on}
    dirty: boolean;                    {pixels altered since last told device}
    end;

  rend_span_t = record                 {config data used by SPAN primitives}
    pxsize: sys_int_adr_t;             {offset from one span pixel to the next}
    end;

  rend_run_t = record                  {config and state used by runlength primitives}
    pxsize: sys_int_adr_t;             {offset from one run descriptor to the next}
    len_ofs: sys_int_adr_t;            {machine adr into run to find run length}
    end;

  rend_rectpx_t = record               {data about current RUN/SPAN rectangle}
    xlen: sys_int_machine_t;           {number of pixels to draw horizontally}
    left_line: sys_int_machine_t;      {number of pixels left on current line}
    skip_line: sys_int_machine_t;      {number of pixels to skip between lines}
    skip_curr: sys_int_machine_t;      {pixels currently left to skip}
    end;

  rend_iterp_data_t = record           {cached data about iterps for CHECK_MODES}
    n_on: sys_int_machine_t;           {current number of interpolants}
    n_rgb: sys_int_machine_t;          {number of RED, GREEN, and BLUE iterps ON}
    n_8: sys_int_machine_t;            {number of 8 bit interpolants}
    n_pixfun_ins: sys_int_machine_t;   {number of iterps with PIXFUN INSERT}
    n_iclamp: sys_int_machine_t;       {num iterps with ICLAMP ON}
    n_iclamp_all: sys_int_machine_t;   {num iterps with ICLAMP OFF or whole range}
    n_aa: sys_int_machine_t;           {num iterps enabled for anti-aliasing}
    n_span: sys_int_machine_t;         {num iterps enabled for SPAN/RUNPX}
    n_wmask_all: sys_int_machine_t;    {num iterps with all write mask bits ON}
    n_hflat: sys_int_machine_t;        {num iterps set to horizontally flat}
    n_shmode_none: sys_int_machine_t;  {num iterps with SHMODE NONE}
    n_shmode_flat: sys_int_machine_t;  {num iterps with SHMODE FLAT}
    n_shmode_linear: sys_int_machine_t; {num iterps with SHMODE LINEAR}
    n_shmode_quad: sys_int_machine_t;  {num iterps with SHMODE QUAD}
    end;

  rend_ray_t = record                  {all the state related to ray tracing}
    visprop_p: type1_visprop_p_t;      {points to curr visual properties block}
    visprop_back_p: type1_visprop_p_t; {points to back side properties, if any}
    xmin, xmax, ymin, ymax, zmin, zmax: real; {3DW bounds of saved primitives}
    routines_oct: ray_object_routines_t; {routines for OCTREE object}
    routines_tri: ray_object_routines_t; {routines for TRI object}
    routines_sph: ray_object_routines_t; {routines for SPHERE object}
    top_obj: ray_object_t;             {top level object that holds all others}
    top_parms: type1_object_parms_t;   {contains SHADER, LIPARM_P, and VISPROP_P}
    backg_parms: type1_shader_fixed_data_t; {info passed to background shader}
    context: ray_context_t;            {global context for all our rays}
    callback: rend_raytrace_p_t;       {pointer to application callback routine}
    save_on: boolean;                  {TRUE if saving primitives for ray tracing}
    init: boolean;                     {TRUE if ray state already initialized}
    traced: boolean;                   {TRUE if traced any pixels since reset}
    visprop_old: boolean;              {our current visprop block is obsolete}
    visprop_used: boolean;             {curr visprop block used at least once}
    end;

  rend_pointer_t = record              {info about the graphics pointer}
    x, y: sys_int_machine_t;           {pointer coordinates within this device}
    root_x, root_y: sys_int_machine_t; {pointer coordinates relative to root device}
    inside: boolean;                   {TRUE if pointer within drawing area}
    root_inside: boolean;              {TRUE if pointer on root deviced}
    end;
{
*   Define the template of the transfer vector for internal functions.
}
  rend_internal_t = record             {transfer vector for non-user functions}

bres_fp: ^procedure (                  {set up Bresenham with floating point numbers}
  out     bres: rend_bresenham_t;      {the Bresenham stepper data structure}
  in      x1, y1: real;                {starting point of line}
  in      x2, y2: real;                {ending point of line}
  in      xmajor: boolean);            {TRUE for X is major axis, FALSE for Y major}

check_modes: ^procedure;               {check modes and possibly update routine pntrs}

check_modes2: ^procedure;              {common CHECK_MODES after routines installed}

ev_possible: ^function (               {find whether event might ever occurr}
  event_id: rend_evdev_k_t)            {event type inquiring about}
  :boolean;                            {TRUE when event is possible and enabled}
  val_param;

icolor_xor: ^procedure (               {get integer color to XOR between two others}
  in      color1, color2: img_pixel1_t; {RGB values to toggle between, ALPHA unused}
  out     color_xor: img_pixel1_t);    {color value to write with XOR pixel function}
  val_param;

reset_refresh: ^procedure;             {perform reset in response to window shakeup}

setup_iterps: ^procedure;              {set up interpolants after leading edge setup}

tri_cache_3d: ^procedure (             {3D triangle explicit caches for each vert}
  in      v1, v2, v3: univ rend_vert3d_t; {descriptor for each vertex}
  in out  ca1, ca2, ca3: rend_vcache_t; {explicit cache for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  val_param;
  tri_cache_3d_data_p: rend_prim_data_p_t;

tzoid: ^procedure;                     {draw trapezoid, everything already set up}
  tzoid_data_p: rend_prim_data_p_t;

update_span: ^procedure (              {update device span from SW bitmap}
  in      x: sys_int_machine_t;        {starting X pixel address of span}
  in      y: sys_int_machine_t;        {scan line coordinate span is on}
  in      len: sys_int_machine_t);     {number of pixels in span}
  val_param;
  update_span_data_p: rend_prim_data_p_t;

update_rect: ^procedure (              {update device rectangle from SW bitmap}
  in      x, y: sys_int_machine_t;     {upper left pixel in rectangle}
  in      dx, dy: sys_int_machine_t);  {dimensions of rectangle in pixels}
  val_param;
  update_rect_data_p: rend_prim_data_p_t;

    end;
{
*   Done defining INTERNAL call table.
}
var (rend_sw)
  rend_sw_com_start: sys_int_machine_t; {for finding address of common block}

  rend_dev_id: sys_int_machine_t;      {ID for current device}
  rend_debug_level: sys_int_machine_t; {0 - N, 0 = no debug printing}
  rend_save_blocks: sys_int_machine_t; {number of mem blocks in save area}
  rend_max_allowed_run: sys_int_machine_t; {max manhattan dist allowed for iterp accuracy}
  rend_shade_geom: sys_int_machine_t;  {iterp mode for implicit color gen geometry}
  rend_max_buf: sys_int_machine_t;     {max buffer number device is capable of}
  rend_curr_draw_buf: sys_int_machine_t; {number of current drawing buffer}
  rend_curr_disp_buf: sys_int_machine_t; {number of current display buffer}
  rend_curr_face: rend_face_k_t;       {current suprop SET routines can manipulate}
  rend_cache_version: sys_int_machine_t; {version ID for valid cache entry}
  rend_zfunc: rend_zfunc_k_t;          {current Z function}
  rend_afunc: rend_afunc_k_t;          {current alpha blending function}
  rend_min_bits_vis: real;             {min effective bits to use per pixel}
  rend_min_bits_hw: real;              {min actual hardware bits to use per pixel}
  rend_bits_vis: real;                 {actual effective bits per pixel in use}
  rend_bits_hw: real;                  {actual physical number of bits used per pixel}
  rend_enter_level: sys_int_machine_t; {nested ENTER_REND level}
  rend_curr_x: sys_int_machine_t;      {current X coordinate, even in horizontal scan}
  rend_dir_flag: rend_dir_k_t;         {left-to-right, right-to-left, or vector}
  rend_n_prim: sys_int_machine_t;      {number of primitives in PRIM call table}
  rend_enter_cnt: sys_int_machine_t;   {total number of calls to REND_SET.ENTER_REND}
  rend_break_cos: real;                {COS threshold for including in shading norm}
  rend_coor_p_ind: sys_int_machine_t;  {REND_VERT3D_T index for XYZ pointer}
  rend_norm_p_ind: sys_int_machine_t;  {REND_VERT3D_T index for normal pointer}
  rend_diff_p_ind: sys_int_machine_t;  {REND_VERT3D_T index for RGBA pointer}
  rend_tmapi_p_ind: sys_int_machine_t; {REND_VERT3D_T index for UVW pointer}
  rend_vcache_p_ind: sys_int_machine_t; {REND_VERT3D_T index for cache pointer}
  rend_ncache_p_ind: sys_int_machine_t; {REND_VERT3D_T index for normal vect cache pnt}
  rend_spokes_p_ind: sys_int_machine_t; {REND_VERT3D_T index for V list pointer}
  rend_vert3d_always:                  {TRUE if entry is always in use}
    array[firstof(rend_vert3d_ent_vals_t)..lastof(rend_vert3d_ent_vals_t)]
    of boolean;
  rend_vert3d_bytes: sys_int_adr_t;    {max bytes for current 3D vertex configuration}
  rend_vert3d_last_list_ent: sys_int_machine_t; {last VERT3D_ON_LIST entry used}
  rend_vert3d_on_list:                 {indicies for all the ON 3D vertex fields}
    array[0..ord(lastof(rend_vert3d_ent_vals_t))] of sys_int_machine_t;
  rend_ray: rend_ray_t;                {all the state related to ray tracing}
  rend_xsec_def_p: rend_xsec_p_t;      {points to default RENDlib crossection}
  rend_xsec_curr_p: rend_xsec_p_t;     {points to current crossection}
  rend_pointer: rend_pointer_t;        {info about the graphics pointer}
  rend_cirres:                         {all the saved CIRRES values}
    array[1..rend_last_cirres_k] of sys_int_machine_t;

  rend_save_block:                     {data for each possible save area mem block}
    array[1..rend_max_save_blocks] of rend_context_block_t;
  rend_3dpl: rend_3dpl_t;              {data about 3DPL to 3D transform}
  rend_xf3d: rend_xf3d_t;              {3D to 3DW space transform and other info}
  rend_view: rend_view_t;              {3DW to 2D transform and other info}
  rend_face_front: rend_suprop_t;      {surface properties of front face}
  rend_face_back: rend_suprop_t;       {surface properties of back face}
  rend_suprop: rend_suprop_state_t;    {additional surface properties current state}
  rend_geom: rend_geom_t;              {geom data for making derivatives later}
  rend_u, rend_v, rend_w: rend_uvwder_t; {extra derivatives for texture mapping}
  rend_tmap: rend_tmap_t;              {all the texture mapping control information}
  rend_dith: rend_dith_t;              {all the dithering control information}
  rend_poly_parms: rend_poly_parms_t;  {modes and switches for polygon drawing}
  rend_poly_state: rend_poly_state_t;  {internal state for polygon modes and switches}
  rend_text_parms: rend_text_parms_t;  {user visible text modes and switches}
  rend_text_state: rend_text_state_t;  {internal text modes and switches}
  rend_vect_parms: rend_vect_parms_t;  {user visible VECT modes and switches}
  rend_vect_state: rend_vect_state_t;  {internal VECT modes and switches}
  rend_2d: rend_2d_t;                  {data for 2D model to image space transform}
  rend_clips_2dim: rend_clips_2dim_t;  {all the 2D image space clip window data}
  rend_iterps: rend_iterps_data_t;     {info about all the interpolants}
  rend_lead_edge: rend_bresenham_t;    {used for curr pnt, vectors, leading tzoid edge}
  rend_trail_edge: rend_bresenham_t;   {used for trapezoid trailing edges}
  rend_image: rend_image_t;            {state pertaining to the current image}
  rend_internal: rend_internal_t;      {transfer vector for internal functions}
  rend_lights: rend_lights_t;          {base data about all the light sources}
  rend_prim_data_res_version: sys_int_machine_t; {version ID for resolved access flags in
                                        PRIM_DATA per primitive data blocks}
  rend_clip_2dim: rend_clip_2dim_t;    {2dim clip limits if can be resolved to one
                                        rectangle}
  rend_ncache_flags: rend_ncache_flags_t; {current version ID for normal vect cache}
  rend_sw_prim: rend_prim_t;           {SW driver "fallback" entry points}
  rend_sw_set: rend_set_t;
  rend_sw_get: rend_get_t;
  rend_sw_internal: rend_internal_t;
  rend_aa: rend_aa_t;                  {current anti-aliasing state}
  rend_curr_span: rend_curr_span_t;    {info about current span drawing into}
  rend_span: rend_span_t;              {info about SPAN config}
  rend_run: rend_run_t;                {info and state about RUNLEN}
  rend_rectpx: rend_rectpx_t;          {data about current RUN/SPAN rectangle}
  rend_iterp_data: rend_iterp_data_t;  {cached data about iterps for CHECK_MODES}
  rend_old_fpp_traps:                  {FP trap status before ENTER_REND call}
    sys_fpmode_t;
  rend_updmode: rend_updmode_k_t;      {current display update mode}
  rend_bench: rend_bench_t;            {benchmark flags}

  rend_clip_normal: boolean;           {TRUE on single draw inside clip rectangle}
  rend_dirty_crect: boolean;           {TRUE if whole clip rectangle not updated}
  rend_crect_dirty_ok: boolean;        {OK to cache whole clip rect as dirty}
  rend_shnorm_unit: boolean;           {TRUE if user will send unitized shading norms}
  rend_zon: boolean;                   {TRUE if Z buffer inhibits enabled}
  rend_force_sw: boolean;              {FALSE = allow SW bitmap not to be updated}
  rend_alpha_on: boolean;              {TRUE enables alpha buffer blending}
  rend_mode_changed: boolean;          {TRUE if mode changed without CHECK_MODES call}
  rend_inhibit_check_modes2: boolean;  {TRUE if not run CHECK_MODES2 from CHECK_MODES}
  rend_check_run_size: boolean;        {FALSE if not need break up polygon due to
                                        exceeding max allowed iterp run size}
  rend_cmode:                          {flag for each automatically changeable mode}
    array[firstof(rend_cmode_k_t)..lastof(rend_cmode_k_t)]
    of boolean;                        {TRUE if mode got automatically changed}
  rend_close_corrupt: boolean;         {TRUE if display is corrupted on dev close}
  rend_video_sync_int: boolean;        {TRUE if video sync has been interrupted}

  rend_sw_com_end: sys_int_machine_t;  {for finding length of common block}
{
*************************************************
*
*   Entry points for SW driver utility routines.
}
procedure rend_sw_add_sblock (         {add block to saved/restored block list}
  in      start_adr: univ_ptr;         {starting adr, must be multiple of 4}
  in      len: sys_int_adr_t);         {block length in machine adr units}
  val_param; extern;

procedure rend_sw_bres_step (          {step a Bresenham vector gen by one iteration}
  in out  bres: rend_bresenham_t;      {the Bresenham stepper data structure}
  out     step: rend_iterp_step_k_t);  {type of step taken to get to new coordinate}
  extern;

procedure rend_sw_dummy_cmode;         {used when calls to CHECK_MODES are deferred}
  extern;

procedure rend_sw_init (               {initializes the base RENDlib device}
  in      dev_name: univ string_var_arg_t; {RENDlib inherent device name}
  in      parms: univ string_var_arg_t; {parameters passed from application}
  out     stat: sys_err_t);            {error return code}
  extern;

procedure rend_sw_interpolate (        {advance all interpolants by one step}
  in      step: rend_iterp_step_k_t);  {interpolation step ID}
  val_param; extern;

procedure rend_sw_ray_visprop_new;     {make new current ray tracing visprop block}
  extern;

procedure rend_sw_restore_cmode (      {restore CHECK_MODES ptr and run CHECK_MODES}
  in      save: univ_ptr);             {old CHECK_MODES routine pointer saved earlier}
  val_param; extern;

procedure rend_sw_save_cmode (         {save old CHECK_MODES ptr and set to dummy}
  out     save: univ_ptr);             {old CHECK_MODES routine pointer}
  extern;

procedure rend_sw_mipmap_table_init (  {init mip-map adjacent map blending table}
  in      n: sys_int_machine_t;        {number of discrete blending levels}
  out     table: rend_mipmap_blend_t); {resulting blending table}
  val_param; extern;

procedure rend_sw_update_xf2d;         {update the internal 2D transform}
  extern;
{
*************************************************
*
*   Entry points for SW driver GET routines.
}
procedure rend_sw_get_aa_border (      {return border needed for curr AA filter}
  out     xp, yp: sys_int_machine_t);  {pixels border needed for each dimension}
  extern;

procedure rend_sw_get_aa_radius (      {return current anti-aliasing filter radius}
  out     r: real);                    {filter kernal radius in output image pixels}
  extern;

procedure rend_sw_get_bits_hw (        {get physical bits per pixel actually in use}
  out     n: real);                    {physical bits per pixel}
  extern;

procedure rend_sw_get_bits_vis (       {get effective bits per pixel actually in use}
  out     n: real);                    {effective visible bits per pixel}
  extern;

procedure rend_sw_get_bxfnv_3d (       {transform normal vector from 3DW to 3D space}
  in      in_v: vect_3d_t;             {input normal vector in 3D world space}
  out     out_v: vect_3d_t);           {result in 3D model space, may be IN_V}
  val_param; extern;

procedure rend_sw_get_bxfpnt_2d (      {transform point backwards thru 2D xform}
  in      in_xy: vect_2d_t;            {input 2DIM space point}
  out     out_xy: vect_2d_t);          {output 2D space point}
  extern;

procedure rend_sw_get_bxfpnt_3d (      {transform point from 3DW to 3D space}
  in      in_xyz: vect_3d_t;           {3DW space input coordinate}
  out     out_xyz: vect_3d_t);         {3D space output coordinate, may be IN_XYZ}
  val_param; extern;

procedure rend_sw_get_bxfv_3d (        {transform vector from 3DW to 3D space}
  in      in_v: vect_3d_t;             {input vector in 3D world space}
  out     out_v: vect_3d_t);           {result in 3D model space, may be IN_V}
  val_param; extern;

procedure rend_sw_get_clip_poly_2dimcl ( {run polygon thru 2DIMCL clipping}
  in out  state: rend_clip_state_k_t;  {for remembering multiple output fragments}
  in      in_n: sys_int_machine_t;     {number of verticies in input polygon}
  in      in_poly: rend_2dverts_t;     {verticies of input polygon}
  out     out_n: sys_int_machine_t;    {number of verts in this output fragment}
  out     out_poly: rend_2dverts_t);   {verticies in this output fragment}
  val_param; extern;

procedure rend_sw_get_clip_vect_2dimcl ( {run vector thru 2DIMCL clipping}
  in out  state: rend_clip_state_k_t;  {for remembering multiple output vectors}
  in      in_vect: rend_2dvect_t;      {original unclipped input vector}
  out     out_vect: rend_2dvect_t);    {this fragment of clipped output vector}
  extern;

procedure rend_sw_get_clip_2dim_handle ( {make new  handle for 2D image space clip wind}
  out     handle: rend_clip_2dim_handle_t); {return a valid clip window handle}
  extern;

procedure rend_sw_get_cmode_vals (     {get current state of all changeable modes}
  out     vals: rend_cmode_vals_t);    {data block with all changeable modes values}
  extern;

procedure rend_sw_get_cmodes (         {get list of automatically changed modes}
  in      maxn: sys_int_machine_t;     {max size list to pass back}
  out     n: sys_int_machine_t;        {actual number of modes passed back in list}
  out     list: univ rend_cmodes_list_t); {buffer filled with N mode IDs}
  val_param; extern;

procedure rend_sw_get_comments_list (  {get handle to current comments list}
  out     list_p: string_list_p_t);    {string list handle, use STRING calls to edit}
  extern;

procedure rend_sw_get_context (        {save current context into context block}
  in      handle: rend_context_handle_t); {handle of context block to write to}
  val_param; extern;

procedure rend_sw_get_cpnt_text (      {return the current point}
  out     x, y: real);                 {current point in this space}
  extern;

procedure rend_sw_get_cpnt_txdraw (    {return the current point}
  out     x, y: real);                 {current point in this space}
  extern;

procedure rend_sw_get_cpnt_2d (        {return the current point}
  out     x, y: real);                 {current point in this space}
  extern;

procedure rend_sw_get_cpnt_2dim (      {return the current point}
  out     x, y: real);                 {current point in this space}
  extern;

procedure rend_sw_get_cpnt_2dimi (     {return the current point}
  out     ix, iy: sys_int_machine_t);  {integer pixel address of current point}
  extern;

procedure rend_sw_get_cpnt_3d (        {return 3D model space current point}
  out     x, y, z: real);
  extern;

procedure rend_sw_get_cpnt_3dpl (      {return the current point}
  out     x, y: real);                 {current point in this space}
  extern;

procedure rend_sw_get_cpnt_3dw (       {return 3D world space current point}
  out     x, y, z: real);
  extern;

procedure rend_sw_get_dev_id (         {find out what device is current}
  out     dev_id: rend_dev_id_t);      {current RENDlib device ID}
  extern;

procedure rend_sw_get_disp_buf (       {return number of current display buffer}
  out     n: sys_int_machine_t);       {current display buffer number}
  extern;

procedure rend_sw_get_dith_on (        {get current state of dithering on/off flag}
  out     on: boolean);                {TRUE if dithering turned on}
  extern;

procedure rend_sw_get_draw_buf (       {return number of current drawing buffer}
  out     n: sys_int_machine_t);       {current drawing buffer number}
  extern;

procedure rend_sw_get_enter_level (    {get depth of ENTER_REND nesting level}
  out     level: sys_int_machine_t);   {current nested graphics mode level}
  extern;

function rend_sw_get_close_corrupt: boolean; {true if display is corrupted on close of device}
  extern;

procedure rend_sw_get_force_sw_update ( {return what user last set FORCE_SW_UPDATE to}
  out     on: boolean);                {last user setting of FORCE_SW_UPDATE}
  extern;

procedure rend_sw_get_image_size (     {return dimension and aspect ratio of image}
  out     x_size, y_size: sys_int_machine_t; {image width and height in pixels}
  out     aspect: real);               {DX/DY aspect ratio when displayed}
  extern;

procedure rend_sw_get_iterps_on_list ( {get list of all the curr ON interpolants}
  out     n: sys_int_machine_t;        {number of interpolants currently ON}
  out     list: rend_iterps_list_t);   {N interpolant IDs}
  extern;

function rend_sw_get_iterps_on_set     {get SET indicating the ON interpolants}
  :rend_iterps_t;
  extern;

procedure rend_sw_get_lights (         {get handles to all light sources}
  in      max_n: sys_int_machine_t;    {max number of light handles to return}
  in      start_n: sys_int_machine_t;  {starting light num, first is 1}
  out     llist: univ rend_light_handle_ar_t; {returned array of light handles}
  out     ret_n: sys_int_machine_t;    {number of light handles returned}
  out     total_n: sys_int_machine_t); {number of lights currently in existance}
  val_param; extern;

procedure rend_sw_get_max_buf (        {return max buffers available on device}
  out     n: sys_int_machine_t);       {number of highest buffer, first buffer is 1}
  extern;

procedure rend_sw_get_min_bits_hw (    {return current HW_MIN_BITS setting}
  out     n: real);                    {actual number of hardware bits per pixel used}
  extern;

procedure rend_sw_get_min_bits_vis (   {return current VIS_MIN_BITS setting}
  out     n: real);                    {Log2 of total effective number of colors}
  extern;

procedure rend_sw_get_perspec (        {get current perspective parameters}
  out     on: boolean;                 {TRUE if perspective projection on}
  out     eyedis: real);               {eye distance perspective value, 3.3 = normal}
  extern;

procedure rend_sw_get_poly_parms (     {get the current polygon drawing control parms}
  out     parms: rend_poly_parms_t);   {current polygon drawing parameters}
  extern;

procedure rend_sw_get_ray_bounds_3dw ( {get current bounds of saved ray primitives}
  out     xmin, xmax: real;            {3D world space axis-aligned bounding box}
  out     ymin, ymax: real;
  out     zmin, zmax: real;
  out     stat: sys_err_t);            {completion status code}
  extern;

procedure rend_sw_get_reading_sw (     {find out if reading SW bitmap}
  out     reading: boolean);           {TRUE if modes require reading SW bitmap}
  extern;

procedure rend_sw_get_reading_sw_prim ( {find if specific primitive reads from SW}
  in      prim_p: univ_ptr;            {call table entry for primitive to ask about}
  out     sw_read: boolean);           {TRUE if prim will read from SW bitmap}
  extern;

procedure rend_sw_get_suprop (         {get current state of a surface property}
  in      suprop: rend_suprop_k_t;     {surface property ID, use REND_SUPROP_xxx_K}
  out     on: boolean;                 {TRUE if this surface property turned ON}
  out     val: rend_suprop_val_t);     {current values for this surface property}
  val_param; extern;

procedure rend_sw_get_text_parms (     {get all current modes and switches for text}
  out     parms: rend_text_parms_t);   {current modes and switches values}
  extern;

procedure rend_sw_get_txbox_text (     {get box around text string}
  in      s: univ string;              {text string}
  in      slen: string_index_t;        {number of characters in string}
  out     bv: vect_2d_t;               {baseline vector, along base of char cells}
  out     up: vect_2d_t;               {character cell UP direction and size}
  out     ll: vect_2d_t);              {lower left corner of text string box}
  val_param; extern;

procedure rend_sw_get_txbox_txdraw (   {get box around text string}
  in      s: univ string;              {text string}
  in      slen: string_index_t;        {number of characters in string}
  out     bv: vect_2d_t;               {baseline vector, along base of char cells}
  out     up: vect_2d_t;               {character cell UP direction and size}
  out     ll: vect_2d_t);              {lower left corner of text string box}
  val_param; extern;

procedure rend_sw_get_update_sw (      {return current state of UPDATE_SW flag}
  out     on: boolean);                {TRUE if software updates are on}
  extern;

procedure rend_sw_get_update_sw_prim ( {find if specific primitive writing to SW}
  in      prim_p: univ_ptr;            {call table entry for primitive to ask about}
  out     sw_write: boolean);          {TRUE if prim will write to SW bitmap}
  extern;

procedure rend_sw_get_vect_parms (     {get modes and switches for VECT primitives}
  out     parms: rend_vect_parms_t);   {values of current modes and switches}
  extern;

function rend_sw_get_video_sync_int:   {TRUE if video sync has been interrupted since}
  boolean;                             {clear of flag by rend_set.video_sync_int_clr}
  extern;

procedure rend_sw_get_wait_exit (      {wait for user to request program exit}
  in      flags: rend_waitex_t);       {set of flags REND_WAITEX_xxx_K}
  val_param; extern;

procedure rend_sw_get_xfnorm_3d (      {transform normal vector from 3D to 3DW space}
  in      inorm: vect_3d_t;            {vector in 3D space, need not be unit length}
  out     onorm: vect_3d_t);           {unit vect in 3DW space, may be same as INORM}
  val_param; extern;

procedure rend_sw_get_xform_2d (       {read back current 2D transform}
  out     xb: vect_2d_t;               {X basis vector}
  out     yb: vect_2d_t;               {Y basis vector}
  out     ofs: vect_2d_t);             {offset vector}
  extern;

procedure rend_sw_get_xform_3d (       {return the current 3D to 3DW transform}
  out     xb, yb, zb: vect_3d_t;       {X, Y, and Z basis vectors}
  out     ofs: vect_3d_t);             {offset (translation) vector (in 3DW space)}
  extern;

procedure rend_sw_get_xform_text (     {get TEXT --> TXDRAW current transform}
  out     xb: vect_2d_t;               {X basis vector}
  out     yb: vect_2d_t;               {Y basis vector}
  out     ofs: vect_2d_t);             {offset vector}
  extern;

procedure rend_sw_get_xfpnt_2d (       {transform point from 2D to 2DIM space}
  in      in_xy: vect_2d_t;            {input point in 2D space}
  out     out_xy: vect_2d_t);          {output point in 2DIM space}
  extern;

procedure rend_sw_get_xfpnt_3d (       {transform point from 3D to 3DW space}
  in      ipnt: vect_3d_t;             {input point in 3D space}
  out     opnt: vect_3d_t);            {3DW space point, may be same as IPNT arg}
  val_param; extern;

procedure rend_sw_get_xfpnt_text (     {transform point from TEXT to TXDRAW space}
  in      in_xy: vect_2d_t;            {input point in TEXT space}
  out     out_xy: vect_2d_t);          {output point in TXDRAW space}
  extern;

procedure rend_sw_get_xfvect_text (    {transform vector from TEXT to TXDRAW space}
  in      in_v: vect_2d_t;             {input vector in TEXT space}
  out     out_v: vect_2d_t);           {output vector in TXDRAW space}
  extern;

procedure rend_sw_get_z_2d (           {return Z coor after transform from 3DW to 2D}
  out     z: real);                    {effective Z coordinate in 2D space}
  extern;

procedure rend_sw_get_z_bits (         {return current Z buffer resolution}
  out     n: real);                    {effective Z buffer resolution in bits}
  extern;

procedure rend_sw_get_z_clip (         {get current 3DW space Z clipping limits}
  out     near, far: real);            {Z limits, normally NEAR > FAR}
  extern;
{
*************************************************
*
*   Entry points for SW driver SET routines.
}
procedure rend_sw_aa_radius (          {set anti-aliasing filter kernal radius}
  in      r: real);                    {radius in output pixels, normal = 1.25}
  val_param; extern;

procedure rend_sw_aa_scale (           {set scale factors for ANTI_ALIAS primitive}
  in      x_scale: real;               {output size / input size horizontal scale}
  in      y_scale: real);              {output size / input size vertical scale}
  val_param; extern;

procedure rend_sw_alloc_bitmap (       {allocate memory for the pixels}
  in      handle: rend_bitmap_handle_t; {handle to bitmap descriptor}
  in      x_size, y_size: sys_int_machine_t; {number of pixels in each dimension}
  in      pix_size: sys_int_adr_t;     {adr units to allocate per pixel}
  in      scope: rend_scope_t);        {what memory context bitmap to belong to}
  val_param; extern;

procedure rend_sw_alloc_bitmap_handle ( {create a new empty bitmap handle}
  in      scope: rend_scope_t;         {memory context, use REND_SCOPE_xxx_K}
  out     handle: rend_bitmap_handle_t); {returned valid bitmap handle}
  val_param; extern;

procedure rend_sw_alloc_context (      {allocate mem for current device context}
  out     handle: rend_context_handle_t); {handle to this new context block}
  extern;

procedure rend_sw_alpha_func  (        {set alpha buffering (compositing) function}
  in      afunc: rend_afunc_k_t);      {alpha function ID}
  val_param; extern;

procedure rend_sw_alpha_on (           {turn alpha compositing on/off}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param; extern;

procedure rend_sw_array_bitmap (       {declare array to use for bitmap data}
  in      handle: rend_bitmap_handle_t; {handle for this bitmap}
  in      ar: univ sys_size1_t;        {the array of pixels}
  in      x_size, y_size: sys_int_machine_t; {number of pixels in each dimension}
  in      size_pix: sys_int_adr_t;     {adr offset for one pixel to the right}
  in      size_line: sys_int_adr_t);   {adr offset for one scan line down}
  val_param; extern;

procedure rend_sw_backface (           {set new current backfacing operation}
  in      flag: rend_bface_k_t);       {from constants REND_BFACE_xx_K}
  val_param; extern;

procedure rend_sw_cache_version (      {set version ID tag for valid cache entry}
  in      version: sys_int_machine_t); {new ID for recognizing valid cache data}
  val_param; extern;

procedure rend_sw_clear_cmodes;        {clear all changed mode flags}
  extern;

procedure rend_sw_clip_2dim (          {set 2D image clip window and turn it on}
  in      handle: rend_clip_2dim_handle_t; {handle to this clip window}
  in      x1, x2: real;                {X coordinate limits}
  in      y1, y2: real;                {y coordinate limits}
  in      draw_inside: boolean);       {TRUE for draw in, FALSE for exclude inside}
  val_param; extern;

procedure rend_sw_clip_2dim_on (       {turn 2D image space clip window on/off}
  in      handle: rend_clip_2dim_handle_t; {handle to this clip window}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param; extern;

procedure rend_sw_clip_2dim_delete (   {deallocate 2D image space clip window}
  in out  handle: rend_clip_2dim_handle_t); {returned as invalid}
  extern;

procedure rend_sw_close;               {close device and release dynamic memory}
  extern;

procedure rend_sw_cmode_vals (         {set state of all changeable modes}
  in      vals: rend_cmode_vals_t);    {data block with all changeable modes values}
  extern;

procedure rend_sw_context (            {restore context from context block}
  in      handle: rend_context_handle_t); {handle of context block to read from}
  val_param; extern;

procedure rend_sw_cpnt_2d (            {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param; extern;

procedure rend_sw_cpnt_2dim (          {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param; extern;

procedure rend_sw_cpnt_2dimi (         {set current point with absolute coordinates}
  in      x, y: sys_int_machine_t);    {new integer pixel coor of current point}
  val_param; extern;

procedure rend_sw_cpnt_3d (            {set new current point from 3D model space}
  in      x, y, z: real);              {coordinates of new current point}
  val_param; extern;

procedure rend_sw_cpnt_3dpl (          {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param; extern;

procedure rend_sw_cpnt_3dw (           {set new current point from 3D world space}
  in      x, y, z: real);              {coordinates of new current point}
  val_param; extern;

procedure rend_sw_cpnt_text (          {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param; extern;

procedure rend_sw_cpnt_txdraw (        {set current point with absolute coordinates}
  in      x, y: real);                 {new coordinates of curr pnt in this space}
  val_param; extern;

procedure rend_sw_create_light (       {create new light source and return handle}
  out     h: rend_light_handle_t);     {handle to newly created light source}
  extern;

procedure rend_sw_dealloc_bitmap (     {release memory allocated with ALLOC_BITMAP}
  in      h: rend_bitmap_handle_t);    {handle to bitmap, still valid but no pixels}
  val_param; extern;

procedure rend_sw_dealloc_bitmap_handle ( {deallocate a bitmap handle}
  in out  handle: rend_bitmap_handle_t); {returned invalid}
  extern;

procedure rend_sw_dealloc_context (    {release memory for context block}
  in out  handle: rend_context_handle_t); {returned invalid}
  extern;

procedure rend_sw_del_all_lights;      {delete all light sources, all handles invalid}
  extern;

procedure rend_sw_del_light (          {delete a light source}
  in out  h: rend_light_handle_t);     {handle to light source, returned invalid}
  extern;

procedure rend_sw_dev_reconfig;        {look at device parameters and reconfigure}
  extern;

procedure rend_sw_dev_restore;         {restore device state from RENDlib state}
  extern;

procedure rend_sw_dev_z_curr (         {indicate whether device Z is current}
  in      curr: boolean);              {TRUE if declare device Z to be current}
  val_param; extern;

procedure rend_sw_disp_buf (           {set number of new current display buffer}
  in      n: sys_int_machine_t);       {buffer number, first buffer is 1}
  val_param; extern;

procedure rend_sw_dith_on (            {turn dithering on/off}
  in      on: boolean);                {TRUE for dithering on}
  val_param; extern;

procedure rend_sw_draw_buf (           {set number of new current drawing buffer}
  in      n: sys_int_machine_t);       {buffer number, first buffer is 1}
  val_param; extern;

procedure rend_sw_end_group;           {done sending group of only one PRIM type}
  extern;

procedure rend_sw_enter_level (        {set depth of ENTER_REND nesting level}
  in      level: sys_int_machine_t);   {desired level, 0 = not in graphics mode}
  val_param; extern;

procedure rend_sw_enter_rend;          {enter graphics mode}
  extern;

procedure rend_sw_enter_rend_cond (    {ENTER_REND only if possible immediately}
  out     entered: boolean);           {TRUE if did ENTER_REND}
  extern;

procedure rend_sw_exit_rend;           {leave graphics mode}
  extern;

procedure rend_sw_eyedis (             {set perspective value using eye distance}
  in      e: real);                    {new value as eye distance dimensionless value}
  val_param; extern;

procedure rend_sw_force_sw_update (    {force SW bitmap update ON/OFF}
  in      on: boolean);                {TRUE means force keep SW bitmap up to date}
  val_param; extern;

procedure rend_sw_image_ftype (        {set the image output file type}
  in      ftype: univ string_var_arg_t); {image file type name (IMG, TGA, etc.)}
  extern;

procedure rend_sw_image_size (         {set size and aspect of current output image}
  in      x_size, y_size: sys_int_machine_t; {number of pixels in each dimension}
  in      aspect: real);               {DX/DY image aspect ratio when displayed}
  val_param; extern;

procedure rend_sw_image_write (        {write rectangle from bitmap to image file}
  in      fnam: univ string_var_arg_t; {generic image output file name}
  in      x_orig: sys_int_machine_t;   {coor where top left image pixel comes from}
  in      y_orig: sys_int_machine_t;
  in      x_size: sys_int_machine_t;   {image size in pixels}
  in      y_size: sys_int_machine_t;
  out     stat: sys_err_t);            {completion status code}
  val_param; extern;

procedure rend_sw_iterp_aa (           {turn anti-aliasing ON/OFF for this iterp}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {anti-aliasing override interpolator value ON}
  val_param; extern;

procedure rend_sw_iterp_bitmap (       {declare where this interpolant gets written}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      bitmap_handle: rend_bitmap_handle_t; {handle for bitmap to write to}
  in      iterp_offset: sys_int_adr_t); {adr offset into pixel for this interpolant}
  val_param; extern;

procedure rend_sw_iterp_flat (         {set interpolation to flat and init values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      val: real);                  {0.0 to 1.0 interpolant value}
  val_param; extern;

procedure rend_sw_iterp_flat_int (     {set interpolation to flat integer value}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      val: sys_int_machine_t);     {new raw interpolant value}
  val_param; extern;

procedure rend_sw_iterp_iclamp (       {turn interpolator output clamping on/off}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param; extern;

procedure rend_sw_iterp_linear (       {set interpolation to linear and init values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      point: vect_2d_t;            {X,Y coordinates where VAL valid}
  in      val: real;                   {interpolant value at anchor point}
  in      dx, dy: real);               {first partials of val in X and Y direction}
  val_param; extern;

procedure rend_sw_iterp_on (           {turn interpolant on/off}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {as if interpolant does not exist when FALSE}
  val_param; extern;

procedure rend_sw_iterp_pclamp (       {turn pixel function output clamping on/off}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param; extern;

procedure rend_sw_iterp_pixfun (       {set pixel write function}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      pixfun: rend_pixfun_k_t);    {pixel function identifier}
  val_param; extern;

procedure rend_sw_iterp_quad (         {set interpolation to quadratic and init values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      point: vect_2d_t;            {X,Y coordinates where VAL valid}
  in      val: real;                   {interpolant value at anchor point}
  in      dx, dy: real;                {first partials of val in X and Y at anchor}
  in      dxx, dyy, dxy: real);        {second derivatives for X, Y and crossover}
  val_param; extern;

procedure rend_sw_iterp_run_ofs (      {set pixel offset for RUN primitives}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      ofs: sys_int_adr_t);         {machine addresses into pixel for this iterp}
  val_param; extern;

procedure rend_sw_iterp_shade_mode (   {set interpolation mode for implicit colors}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      shmode: sys_int_machine_t);  {one of the REND_ITERP_MODE_xx_K values}
  val_param; extern;

procedure rend_sw_iterp_span_ofs (     {set pixel offset for SPAN primitives}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      ofs: sys_int_adr_t);         {machine addresses into pixel for this iterp}
  val_param; extern;

procedure rend_sw_iterp_span_on (      {iterp participates in SPAN, RUNS ON/OFF}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {TRUE if interpolant does participate}
  val_param; extern;

procedure rend_sw_iterp_src_bitmap (   {declare source mode BITMAP and set bitmap}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      bitmap_handle: rend_bitmap_handle_t; {handle for source bitmap}
  in      iterp_offset: sys_int_adr_t); {adr offset into pixel for this interpolant}
  val_param; extern;

procedure rend_sw_iterp_wmask (        {set write mask for this interpolant}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      wmask: sys_int_machine_t);   {right justified write mask, 1=write}
  val_param; extern;

procedure rend_sw_light_accur (        {set lighting calculation accuracy level}
  in      accur: rend_laccu_k_t);      {new lighting accuracy mode}
  val_param; extern;

procedure rend_sw_light_amb (          {set ambient light source and turn ON}
  in      h: rend_light_handle_t;      {handle to light source}
  in      red, grn, blu: real);        {light source brightness values}
  val_param; extern;

procedure rend_sw_light_dir (          {set directional light source and turn ON}
  in      h: rend_light_handle_t;      {handle to light source}
  in      red, grn, blu: real;         {light source brightness values}
  in      vx, vy, vz: real);           {direction vector, need not be unitized}
  val_param; extern;

procedure rend_sw_light_on (           {turn light source on/off}
  in      h: rend_light_handle_t;      {handle to light source}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param; extern;

procedure rend_sw_light_pnt (          {set point light with no falloff, turn ON}
  in      h: rend_light_handle_t;      {handle to light source}
  in      red, grn, blu: real;         {light source brightness values}
  in      x, y, z: real);              {light source coordinate}
  val_param; extern;

procedure rend_sw_light_pr2 (          {set point light with falloff, turn ON}
  in      h: rend_light_handle_t;      {handle to light source}
  in      red, grn, blu: real;         {light source brightness values at radius}
  in      r: real;                     {radius where given intensities apply}
  in      x, y, z: real);              {light source coordinate}
  val_param; extern;

procedure rend_sw_light_val (          {set value for a light source}
  in      h: rend_light_handle_t;      {handle to this light source}
  in      ltype: rend_ltype_k_t;       {type of light source}
  in      val: rend_light_val_t);      {LTYPE dependent data values for this light}
  val_param; extern;

procedure rend_sw_lin_geom_2dim (      {set geometric info to compute linear derivs}
  in      p1, p2, p3: vect_2d_t);      {3 points where vals will be specified}
  val_param; extern;

procedure rend_sw_lin_vals (           {set linear interp by giving corner values}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      v1, v2, v3: real);           {values at previously given coordinates}
  val_param; extern;

procedure rend_sw_lin_vals_rgba (      {premult RGB by A, set quad RGB, linear A}
  in      v1, v2, v3: rend_rgba_t);    {RGBA at each previously given coordinate}
  val_param; extern;

procedure rend_sw_max_buf (            {set max number of desired display/draw bufs}
  in      n: sys_int_machine_t);       {max desired buf num, first buffer is 1}
  val_param; extern;

procedure rend_sw_min_bits_hw (        {set minimum required hardware bits per pixel}
  in      n: real);                    {min desired hardware bits to write into}
  val_param; extern;

procedure rend_sw_min_bits_vis (       {set minimum required effective bits per pixel}
  in      n: real);                    {Log2 of total effective number of colors}
  val_param; extern;

procedure rend_sw_ncache_version (     {set new valid version ID for norm vect cache}
  in      version: sys_int_machine_t);
  val_param; extern;

procedure rend_sw_new_view;            {make new view parameters take effect}
  extern;

procedure rend_sw_perspec_on (         {turn perspective on/off}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param; extern;

procedure rend_sw_poly_parms (         {set new parameters to control polygon drawing}
  in      parms: rend_poly_parms_t);   {new polygon drawing parameters}
  extern;

procedure rend_sw_quad_geom_2dim (     {set geometric info to compute quad derivs}
  in      p1, p2, p3, p4, p5, p6: vect_2d_t); {6 points for vals later}
  extern;

procedure rend_sw_quad_vals (          {set quad interp by giving vals at 6 points}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      v1, v2, v3, v4, v5, v6: real); {values at previously given coordinates}
  val_param; extern;

procedure rend_sw_ray_delete;          {delete all primitives saved for ray tracing}
  extern;

procedure rend_sw_ray_save (           {turn primitive saving for ray tracing ON/OFF}
  in      on: boolean);                {TRUE will cause primitives to be saved}
  val_param; extern;

procedure rend_sw_rcpnt_text (         {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param; extern;

procedure rend_sw_rcpnt_txdraw (       {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param; extern;

procedure rend_sw_rcpnt_2d (           {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param; extern;

procedure rend_sw_rcpnt_2dim (         {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param; extern;

procedure rend_sw_rcpnt_2dimi (        {set current point with relative coordinates}
  in      idx, idy: sys_int_machine_t); {integer displacement from old current point}
  val_param; extern;

procedure rend_sw_rcpnt_3dpl (         {set current point with relative coordinates}
  in      dx, dy: real);               {displacement from old current point}
  val_param; extern;

procedure rend_sw_rgb (                {set flat RGB color}
  in      r, g, b: real);              {0.0-1.0 red, green, blue color values}
  val_param; extern;

procedure rend_sw_rgbz_linear (        {set linear values for RGBZ interpolants}
  in      v1, v2, v3: rend_color3d_t); {XYZ and RGB at three points}
  extern;

procedure rend_sw_rgbz_quad (          {set quadratic RGB and linear Z values}
  in      v1, v2, v3: rend_color3d_t;  {XYZ,RGB points used to make linear Z}
  in      v4, v5, v6: rend_color3d_t); {extra points used to make quad RGB, Z unused}
  extern;

procedure rend_sw_run_config (         {configure run length pixel data format}
  in      pxsize: sys_int_adr_t;       {machine adr offset from one run to next}
  in      runlen_ofs: sys_int_adr_t);  {machine address into pixel start for runlen}
  val_param; extern;

procedure rend_sw_shade_geom (         {set geometry mode for implicit color gen}
  in      geom_mode: rend_iterp_mode_k_t); {flat, linear, etc}
  val_param; extern;

procedure rend_sw_shnorm_break_cos (   {set threshold for making break in spokes list}
  in      c: real);                    {COS of max allowed deviation angle}
  val_param; extern;

procedure rend_sw_span_config (        {configure SPAN primitives data format}
  in      pxsize: sys_int_adr_t);      {machine adr offset from one pixel to next}
  val_param; extern;

procedure rend_sw_start_group;         {indicate start sending only one PRIM type}
  extern;

procedure rend_sw_suprop_all_off;      {turn off all surface properties for this face}
  extern;

procedure rend_sw_suprop_diff (        {set diffuse property and turn it ON}
  in      r, g, b: real);              {diffuse color}
  val_param; extern;

procedure rend_sw_suprop_emis (        {set emissive property and turn it ON}
  in      r, g, b: real);              {emissive color}
  val_param; extern;

procedure rend_sw_suprop_on (          {turn particular surface property on/off}
  in      suprop: rend_suprop_k_t;     {surf prop ID, use REND_SUPROP_xx_K constants}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param; extern;

procedure rend_sw_suprop_spec (        {set specular property and turn it ON}
  in      r, g, b: real;               {specular color}
  in      e: real);                    {specular exponent}
  val_param; extern;

procedure rend_sw_suprop_trans (       {set transparenty property and turn it ON}
  in      front: real;                 {opaqueness when facing head on}
  in      side: real);                 {opaqueness when facing sideways}
  val_param; extern;

procedure rend_sw_suprop_val (         {set value for particular surface property}
  in      suprop: rend_suprop_k_t;     {surf prop ID, use REND_SUPROP_xx_K constants}
  in      val: rend_suprop_val_t);     {SUPROP dependent data values}
  val_param; extern;

procedure rend_sw_surf_face_curr (     {set which suprop to use for future set/get(s)}
  in      face: rend_face_k_t);        {polygon face select, use REND_FACE_xx_K}
  val_param; extern;

procedure rend_sw_surf_face_on (       {enable surface properties for current face}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param; extern;

procedure rend_sw_text_parms (         {set parameters and swithces for TEXT primitive}
  in      parms: rend_text_parms_t);   {new values for the modes and switches}
  extern;

procedure rend_sw_tmap_accur (         {set texture mapping accuracy level}
  in      accur: rend_tmapaccu_k_t);   {new accuracy mode, use REND_TMAPACCU_xxx_K}
  val_param; extern;

procedure rend_sw_tmap_changed;        {indicate that texture map data got changed}
  extern;

procedure rend_sw_tmap_dimension (     {set texture mapping dimensionality level}
  in      level: rend_tmapd_k_t);      {texture map dimension level ID number}
  val_param; extern;

procedure rend_sw_tmap_filt (          {set texture mapping filtering methods}
  in      filt: rend_tmapfilt_t);      {set of texture mapping filtering flags}
  val_param; extern;

procedure rend_sw_tmap_flims (         {set limits on texture mapping filtering}
  in      min_size: real;              {min size map to use, in pixels accross}
  in      max_size: real);             {max size map to use, in pixels accross}
  val_param; extern;

procedure rend_sw_tmap_func (          {set texture mapping function}
  in      func: rend_tmapf_k_t);       {ID number for new texture mapping function}
  val_param; extern;

procedure rend_sw_tmap_method (        {set texture mapping method}
  in      method: rend_tmapm_k_t);     {texture mapping method ID number}
  val_param; extern;

procedure rend_sw_tmap_on (            {turn texture mapping on/off}
  in      on: boolean);                {TRUE to turn texture mapping on}
  val_param; extern;

procedure rend_sw_tmap_src (           {set texture map source for this interpolant}
  in      iterp: rend_iterp_k_t;       {ID of interpolant to set texmap source for}
  in      bitmap: rend_bitmap_handle_t; {handle to bitmap containing source pixels}
  in      offset: sys_int_adr_t;       {adr offset within pixel for this interpolant}
  in      x_size, y_size: sys_int_machine_t; {dimensions of texture map within bitmap}
  in      x_orig, y_orig: sys_int_machine_t); {origin of texture map within bitmap}
  val_param; extern;

procedure rend_sw_vect_parms (         {set parameters and switches for VECT call}
  in      parms: rend_vect_parms_t);   {new values for the modes and switches}
  extern;

procedure rend_sw_vert3d_ent_all_off;  {turn off all vertex descriptor entries}
  extern;

procedure rend_sw_vert3d_ent_off (     {turn off an entry type in vertex descriptor}
  in      ent_type: rend_vert3d_ent_vals_t); {ID of entry type to turn OFF}
  val_param; extern;

procedure rend_sw_vert3d_ent_on (      {turn on an entry type in vertex descriptor}
  in      ent_type: rend_vert3d_ent_vals_t; {ID of entry type to turn ON}
  in      offset: sys_int_adr_t);      {adr offset for this ent from vert desc start}
  val_param; extern;

procedure rend_sw_video_sync_int_clr;  {clear flag that video sync has been interrupted}
  extern;

procedure rend_sw_xform_text (         {set new TEXT --> TXDRAW transform}
  in      xb: vect_2d_t;               {X basis vector}
  in      yb: vect_2d_t;               {Y basis vector}
  in      ofs: vect_2d_t);             {offset vector}
  extern;

procedure rend_sw_xform_2d (           {set new absolute 2D transform}
  in      xb: vect_2d_t;               {X basis vector}
  in      yb: vect_2d_t;               {Y basis vector}
  in      ofs: vect_2d_t);             {offset vector}
  extern;

procedure rend_sw_xform_3d (           {set new 3D to 3DW space transform}
  in      xb, yb, zb: vect_3d_t;       {X, Y, and Z basis vectors}
  in      ofs: vect_3d_t);             {offset (translation) vector (in 3DW space)}
  val_param; extern;

procedure rend_sw_xform_3d_postmult (  {postmult new matrix to old and make current}
  in      m: vect_mat3x4_t);           {new matrix to postmultiply to existing}
  val_param; extern;

procedure rend_sw_xform_3d_premult (   {premult new matrix to old and make current}
  in      m: vect_mat3x4_t);           {new matrix to premultiply to existing}
  val_param; extern;

procedure rend_sw_xform_3dpl_2d (      {set new 2D transform in 3DPL space}
  in      xb: vect_2d_t;               {X basis vector}
  in      yb: vect_2d_t;               {Y basis vector}
  in      ofs: vect_2d_t);             {offset vector}
  extern;

procedure rend_sw_xform_3dpl_plane (   {set new current plane for 3DPL space}
  in      org: vect_3d_t;              {origin for 2D space}
  in      xb: vect_3d_t;               {X basis vector}
  in      yb: vect_3d_t);              {Y basis vector}
  extern;

procedure rend_sw_xsec_circle (        {create new unit-circle crossection}
  in      nseg: sys_int_machine_t;     {number of line segments in the circle}
  in      smooth: boolean;             {TRUE if should smooth shade around circle}
  in      scope: rend_scope_t;         {what scope new crossection will belong to}
  out     xsec_p: rend_xsec_p_t);      {returned handle to new crossection}
  val_param; extern;

procedure rend_sw_xsec_close (         {done adding points, freeze xsec definition}
  in out  xsec: rend_xsec_t;           {crossection to close}
  in      connect: boolean);           {TRUE if connect last point to first point}
  val_param; extern;

procedure rend_sw_xsec_create (        {create new crossection descriptor}
  in      scope: rend_scope_t;         {what scope new crossection will belong to}
  out     xsec_p: rend_xsec_p_t);      {returned user handle to new crossection}
  val_param; extern;

procedure rend_sw_xsec_curr (          {declare current crossection for future use}
  in      xsec: rend_xsec_t);          {crossection to make current}
  val_param; extern;

procedure rend_sw_xsec_delete (        {delete crossection, deallocate resources}
  in out  xsec_p: rend_xsec_p_t);      {crossection handle, will be set to invalid}
  extern;

procedure rend_sw_xsec_pnt_add (       {add point to end of xsec, full features}
  in out  xsec: rend_xsec_t;           {crossection to add point to}
  in      coor: vect_2d_t;             {coordinate, intended to be near unit circle}
  in      norm_bef: vect_2d_t;         {2D shading normal at or just before here}
  in      norm_aft: vect_2d_t;         {2D shading normal just after here}
  in      smooth: boolean);            {TRUE if NORM_BEF to apply to whole point}
  val_param; extern;

procedure rend_sw_z_clip (             {set 3DW space Z clip limits}
  in      near: real;                  {objects get clipped when Z > this value}
  in      far: real);                  {objects get clipped when Z < this value}
  val_param; extern;

procedure rend_sw_zfunc (              {set new current Z compare function}
  in      zfunc: rend_zfunc_k_t);      {the Z compare function number}
  val_param; extern;

procedure rend_sw_zon (                {turn Z buffering on/off}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param; extern;

procedure rend_sw_z_range (            {set 3DW space to full Z buffer range mapping}
  in      near: real;                  {3DW Z coordinate of Z buffer 1.0 value}
  in      far: real);                  {3DW Z coordinate of Z buffer -1.0 value}
  val_param; extern;
{
*************************************************
*
*   Entry points for SW driver PRIM routines.
}
procedure rend_sw_anti_alias (         {anti alias src to dest bitmap, curr scale}
  in      size_x, size_y: sys_int_machine_t; {destination rectangle size}
  in      src_x, src_y: sys_int_machine_t); {maps to top left of top left out pixel}
  val_param; extern;

procedure rend_sw_anti_alias2 (        {anti alias src to dest bitmap, curr scale}
  in      size_x, size_y: sys_int_machine_t; {destination rectangle size}
  in      src_x, src_y: sys_int_machine_t); {maps to top left of top left out pixel}
  val_param; extern;

procedure rend_sw_chain_vect_3d (      {end-to-end chained vectors}
  in      n_verts: sys_int_machine_t;  {number of verticies pointed to by VERT_P_LIST}
  in      vert_p_list: univ rend_vert3d_p_list_t); {vertex descriptor pointer list}
  val_param; extern;

procedure rend_sw_circle_2dim (        {unfilled circle}
  in      radius: real);
  val_param; extern;

procedure rend_sw_clear;               {clear whole image to interpolants as set}
  extern;

procedure rend_sw_clear_cwind;         {clear clip window to interpolants as set}
  extern;

procedure rend_sw_disc_2dim (          {filled circle}
  in      radius: real);
  val_param; extern;

procedure rend_sw_flip_buf;            {flip buffers and clear new drawing buffer}
  extern;

procedure rend_sw_flush_all;           {flush all data, insure image is up to date}
  extern;

procedure rend_sw_image_2dimcl (       {read image from file to current image bitmap}
  in out  img: img_conn_t;             {handle to previously open image file}
  in      x, y: sys_int_machine_t;     {bitmap anchor coordinate}
  in      torg: rend_torg_k_t;         {how image is anchored to X,Y}
  out     stat: sys_err_t);            {returned completion status code}
  val_param; extern;

procedure rend_sw_line_3d (            {draw 3D model space line, curr pnt trashed}
  in      v1, v2: univ rend_vert3d_t;  {descriptors for each line segment endpoint}
  in      gnorm: vect_3d_t);           {geometric normal for Z slope and backface}
  val_param; extern;

procedure rend_sw_line2_3d (           {takes into account vector thickening}
  in      v1, v2: univ rend_vert3d_t;  {descriptors for each line segment endpoint}
  in      gnorm: vect_3d_t);           {geometric normal for Z slope and backface}
  extern;

procedure rend_sw_nsubpix_poly_2dim (  {convert subpixel to integer polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param; extern;

procedure rend_sw_poly_text (          {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param; extern;

procedure rend_sw_poly_txdraw (        {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param; extern;

procedure rend_sw_poly_2d (            {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param; extern;

procedure rend_sw_poly_2dim (          {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param; extern;

procedure rend_sw_poly_2dimcl (        {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param; extern;

procedure rend_sw_poly_3dpl (          {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param; extern;

procedure rend_sw_ray_trace_2dimi (    {ray trace a rectangle of pixels}
  in      idx, idy: sys_int_machine_t); {size from current pixel to opposite corner}
  val_param; extern;

procedure rend_sw_rect_2d (            {axis aligned rectangle at current point}
  in      dx, dy: real);               {displacement from curr pnt to opposite corner}
  val_param; extern;

procedure rend_sw_rect_2dim (          {axis aligned rectangle at current point}
  in      dx, dy: real);               {displacement from curr pnt to opposite corner}
  val_param; extern;

procedure rend_sw_rect_2dimcl (        {axis aligned rectangle at current point}
  in      dx, dy: real);               {displacement from curr pnt to opposite corner}
  val_param; extern;

procedure rend_sw_rect_2dimi (         {integer image space axis aligned rectangle}
  in      idx, idy: sys_int_machine_t); {pixel displacement to opposite corner}
  val_param; extern;

procedure rend_sw_rect_px_2dimcl (     {declare rectangle for RUNs or SPANs}
  in      dx, dy: sys_int_machine_t);  {size from curr pixel to opposite corner}
  val_param; extern;

procedure rend_sw_rect_px_2dimi (      {declare rectangle for RUNs or SPANs}
  in      dx, dy: sys_int_machine_t);  {size from curr pixel to opposite corner}
  extern;

procedure rend_sw_runpx_2dimcl (       {draw chunk of pixels from runs into RECT_PX}
  in      start_skip: sys_int_machine_t; {pixels to ignore at start of runs}
  in      np: sys_int_machine_t;       {num of pixels in RUNS, including ignored}
  in      runs: univ char);            {runs formatted as currently configured}
  val_param; extern;

procedure rend_sw_runpx_2dimi (        {draw chunk of pixels from runs into RECT_PX}
  in      start_skip: sys_int_machine_t; {pixels to ignore at start of runs}
  in      np: sys_int_machine_t;       {num of pixels in RUNS, including ignored}
  in      runs: univ char);            {runs formatted as currently configured}
  extern;

procedure rend_sw_rvect_text (         {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param; extern;

procedure rend_sw_rvect_txdraw (       {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param; extern;

procedure rend_sw_rvect_2d (           {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param; extern;

procedure rend_sw_rvect_2dim (         {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param; extern;

procedure rend_sw_rvect_2dimcl (       {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param; extern;

procedure rend_sw_rvect_3dpl (         {relative vector from current point}
  in      dx, dy: real);               {displacement to end point and new curr pnt}
  val_param; extern;

procedure rend_sw_span_2dimcl (        {write horizontal span of pixels}
  in      len: sys_int_machine_t;      {number of pixels in span}
  in      pixels: univ char);          {span formatted as currently configured}
  val_param; extern;

procedure rend_sw_span2_2dimcl (       {write horizontal span of pixels into RECT_PX}
  in      len: sys_int_machine_t;      {number of pixels in span}
  in      pixels: univ char);          {span formatted as currently configured}
  val_param; extern;

procedure rend_sw_text (               {text string, use current text parms}
  in      s: univ string;              {string of bytes}
  in      len: string_index_t);        {number of characters in string}
  val_param; extern;

procedure rend_sw_text_raw (           {text string, assume VECT_TEXT all set up}
  in      s: univ string;              {string of bytes}
  in      len: string_index_t);        {number of characters in string}
  val_param; extern;

procedure rend_sw_tri_3d (             {draw 3D model space triangle}
  in      v1, v2, v3: univ rend_vert3d_t; {pointer info for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  extern;

procedure rend_sw_tri_cache_3d (       {3D triangle, explicit caches for each vert}
  in      v1, v2, v3: univ rend_vert3d_t; {descriptor for each vertex}
  in out  ca1, ca2, ca3: rend_vcache_t; {explicit cache for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  val_param; extern;

procedure rend_sw_tri_cache2_3d (      {3D triangle, explicit caches for each vert}
  in      v1, v2, v3: univ rend_vert3d_t; {descriptor for each vertex}
  in out  ca1, ca2, ca3: rend_vcache_t; {explicit cache for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  val_param; extern;

procedure rend_sw_tri_cache3_3d (      {3D triangle, explicit caches for each vert}
  in      v1, v2, v3: univ rend_vert3d_t; {descriptor for each vertex}
  in out  ca1, ca2, ca3: rend_vcache_t; {explicit cache for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  val_param; extern;

procedure rend_sw_tri_cache_ray_3d (   {3D triangle, explicit caches for each vert}
  in      v1, v2, v3: univ rend_vert3d_t; {descriptor for each vertex}
  in out  ca1, ca2, ca3: rend_vcache_t; {explicit cache for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  val_param; extern;

procedure rend_sw_tstrip_3d (          {draw connected strip of triangles}
  in      vlist: univ rend_vert3d_p_list_t; {list of pointers to vertex descriptors}
  in      nverts: sys_int_machine_t);  {number of verticies in VLIST}
  val_param; extern;

procedure rend_sw_tubeseg_3d (         {draw one segment of extruded tube}
  in      p1: rend_tube_point_t;       {point descriptor for start of tube segment}
  in      p2: rend_tube_point_t;       {point descriptor for end of tube segment}
  in      cap_start: rend_tbcap_k_t;   {selects cap style for segment start}
  in      cap_end: rend_tbcap_k_t);    {selects cap style for segment end}
  val_param; extern;

procedure rend_sw_vect_text (          {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param; extern;

procedure rend_sw_vect_txdraw (        {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param; extern;

procedure rend_sw_vect_2d (            {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param; extern;

procedure rend_sw_vect_poly (          {convert vector to a polygon}
  in      x, y: real);                 {coor of end point and new current point}
  val_param; extern;

procedure rend_sw_vect_2dim (          {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param; extern;

procedure rend_sw_vect_2dimcl (        {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param; extern;

procedure rend_sw_vect_3d (            {vector to new current point in 3D space}
  in      x, y, z: real);              {vector end point and new current point}
  val_param; extern;

procedure rend_sw_vect_3dpl (          {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param; extern;

procedure rend_sw_vect_3dw (           {vector to new current point in 3DW space}
  in      x, y, z: real);              {vector end point and new current point}
  val_param; extern;

procedure rend_sw_vect_fp_2dim (       {2D image space vector using subpixel adr}
  in      x, y: real);                 {coor of end point and new current point}
  val_param; extern;

procedure rend_sw_vect_int_2dim (      {2D image space vector using integer adr}
  in      x, y: real);                 {coor of end point and new current point}
  val_param; extern;

procedure rend_sw_vect_2dimi (         {integer 2D image space vector}
  in      ix, iy: sys_int_machine_t);  {pixel coordinate end point}
  val_param; extern;

procedure rend_sw_wpix;                {write current value at current pixel}
  extern;
{
*************************************************
*
*   Entry points for SW driver routines that go into the INTERNAL call table.
}
procedure rend_sw_bres_fp (            {set up Bresenham with floating point numbers}
  out     bres: rend_bresenham_t;      {the Bresenham stepper data structure}
  in      x1, y1: real;                {starting point of line}
  in      x2, y2: real;                {ending point of line}
  in      xmajor: boolean);            {TRUE for X is major axis, FALSE for Y major}
  extern;

procedure rend_sw_check_modes;         {check modes and possibly update routine pntrs}
  extern;

procedure rend_sw_check_modes2;        {common CHECK_MODES after routines installed}
  extern;

procedure rend_sw_reset_refresh;       {perform reset in response to window shakeup}
  extern;

procedure rend_sw_setup_iterps;        {set up interpolants after leading edge setup}
  extern;

procedure rend_sw_tzoid;               {draw trapezoid, everything already set up}
  extern;

procedure rend_sw_tzoid2;              {trapezoid, linear RGBZ}
  extern;

procedure rend_sw_tzoid3;              {trapezoid, horiz flat RGBZ, no Z compares}
  extern;

procedure rend_sw_tzoid4;              {trapezoid, linear RGBZ, no clamping}
  extern;

procedure rend_sw_tzoid5;              {trapezoid, linear RGB, no clamping}
  extern;

procedure rend_sw_update_span (        {update device span from SW bitmap}
  in      x: sys_int_machine_t;        {starting X pixel address of span}
  in      y: sys_int_machine_t;        {scan line coordinate span is on}
  in      len: sys_int_machine_t);     {number of pixels in span}
  val_param; extern;

procedure rend_sw_event_req_close (    {request CLOSE events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param; extern;

procedure rend_sw_event_req_resize (   {request RESIZE events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param; extern;

procedure rend_sw_event_req_wiped_resize ( {size change will generate WIPED_RESIZE, and
                                        will be compressed with WIPED_RECT events}
  in      on: boolean);                {TRUE requests these events}
  val_param; extern;

procedure rend_sw_event_req_wiped_rect ( {request WIPED_RECT events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param; extern;

procedure rend_sw_event_req_key_on (   {request events for a particular key}
  in      id: rend_key_id_t;           {RENDlib ID of key requesting events for}
  in      id_user: sys_int_machine_t); {ID returned to user with event data}
  val_param; extern;

procedure rend_sw_event_req_key_off (  {request no events for a particular key}
  in      id: rend_key_id_t);          {RENDlib ID of key requesting no events for}
  val_param; extern;

procedure rend_sw_event_req_pnt (      {request pnt ENTER, EXIT, MOVE events on/off}
  in      on: boolean);                {TRUE requests these events}
  val_param; extern;

procedure rend_sw_events_req_off;      {request to disable all events}
  extern;

procedure rend_sw_pointer (            {set pointer to location within draw area}
  in      x, y: sys_int_machine_t);    {new location relative to draw area origin}
  val_param; extern;

procedure rend_sw_pointer_abs (        {set pointer to location within "root" device}
  in      x, y: sys_int_machine_t);    {new location in absolute "root" coordinates}
  val_param; extern;

procedure rend_sw_get_keys (           {get info about all available keys}
  out     keys_p: univ rend_key_ar_p_t; {pointer to array of all the key descriptors}
  out     n: sys_int_machine_t);       {number of valid entries in KEYS}
  extern;

function rend_sw_get_key_sp (          {get ID of a special pre-defined key}
  in      id: rend_key_sp_k_t;         {ID for this special key}
  in      detail: sys_int_machine_t)   {detail info for this key}
  :rend_key_id_t;                      {key ID or REND_KEY_NONE_K}
  val_param; extern;

procedure rend_sw_get_key_sp_def (     {get "default" or "empty" special key data}
  out     key_sp_data: rend_key_sp_data_t); {returned special key data block}
  extern;

function rend_sw_get_pointer (         {get current pointer location}
  out     x, y: sys_int_machine_t)     {pointer coordinates within this device}
  :boolean;                            {TRUE if pointer is within this device area}
  extern;

function rend_sw_get_pointer_abs (     {get current absolute pointer location}
  out     x, y: sys_int_machine_t)     {pointer coordinates on "root" device}
  :boolean;                            {TRUE if pointer is within root device area}
  extern;

procedure rend_sw_shnorm_unitized (    {tell whether shading normals will be unitized}
  in      on: boolean);                {future shading norms must be unitized on TRUE}
  val_param; extern;

procedure rend_sw_vert3d_ent_on_always ( {promise vertex entry will always be used}
  in      ent_type: rend_vert3d_ent_vals_t); {ID of entry that will always be used}
  val_param; extern;

procedure rend_sw_update_mode (        {select how display is updated when SW emul}
  in      mode: rend_updmode_k_t);     {update mode, use REND_UPDMODE_xxx_K}
  val_param; extern;

procedure rend_sw_quad_3d (            {draw 3D model space quadrilateral}
  in      v1, v2, v3, v4: univ rend_vert3d_t); {pointer info for each vertex}
  val_param; extern;

procedure rend_sw_update_rect (        {update device rectangle from SW bitmap}
  in      x, y: sys_int_machine_t;     {upper left pixel in rectangle}
  in      dx, dy: sys_int_machine_t);  {dimensions of rectangle in pixels}
  val_param; extern;

function rend_sw_get_event_possible (  {find whether event might ever occurr}
  event_id: rend_ev_k_t)               {event type inquiring about}
  :boolean;                            {TRUE when event is possible and enabled}
  val_param; extern;

function rend_sw_get_ev_possible (     {internal find whether event might ever occurr}
  event_id: rend_evdev_k_t)            {event type inquiring about}
  :boolean;                            {TRUE when event is possible and enabled}
  val_param; extern;

procedure rend_sw_event_req_rotate_off; {disable relative 3D rotation events}
  extern;

procedure rend_sw_event_req_rotate_on ( {enable relative 3D rotation events}
  in      scale: real);                {scale factor, 1.0 = "normal"}
  val_param; extern;

procedure rend_sw_event_req_translate ( {enable/disable 3D translation events}
  in      on: boolean);                {TRUE enables these events}
  val_param; extern;

procedure rend_sw_get_color_xor (      {get color to XOR between two other colors}
  in      color1, color2: rend_rgb_t;  {two colors to toggle between}
  out     color_xor: rend_rgb_t);      {color value to use with XOR pixel function}
  val_param; extern;

procedure rend_sw_icolor_xor (         {get integer color to XOR between two others}
  in      color1, color2: img_pixel1_t; {RGB values to toggle between, ALPHA unused}
  out     color_xor: img_pixel1_t);    {color value to write with XOR pixel function}
  val_param; extern;

procedure rend_sw_event_mode_pnt (     {indicate how to handle pointer motion}
  in      mode: rend_pntmode_k_t);     {interpretation mode, use REND_PNTMOVE_xxx_K}
  val_param; extern;

procedure rend_sw_ray_callback (       {set application routine that resolves rays}
  in      p: rend_raytrace_p_t);       {routine pointer or NIL to disable}
  val_param; extern;

function rend_sw_get_ray_callback      {return current ray callback entry point}
  :rend_raytrace_p_t;                  {routine pointer or NIL for none}
  extern;
{
*   Dummy routines that may be installed into the call tables, usually
*   due to REND_BENCH flag settings.
}
procedure rend_dummy_poly_2d (         {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param; extern;

procedure rend_dummy_quad_3d (         {draw 3D model space quadrilateral}
  in      v1, v2, v3, v4: univ rend_vert3d_t); {pointer info for each vertex}
  val_param; extern;

procedure rend_dummy_tri_3d (          {draw 3D model space triangle}
  in      v1, v2, v3: univ rend_vert3d_t; {pointer info for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  extern;

procedure rend_dummy_tri_cache_3d (    {3D triangle explicit caches for each vert}
  in      v1, v2, v3: univ rend_vert3d_t; {descriptor for each vertex}
  in out  ca1, ca2, ca3: rend_vcache_t; {explicit cache for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  val_param; extern;

procedure rend_dummy_tstrip_3d (       {draw connected strip of triangles}
  in      vlist: univ rend_vert3d_p_list_t; {list of pointers to vertex descriptors}
  in      nverts: sys_int_machine_t);  {number of verticies in VLIST}
  val_param; extern;

procedure rend_sw_cirres (             {set all CIRRES values simultaneously}
  in      cirres: sys_int_machine_t);  {new value for all CIRRES parameters}
  val_param; extern;

procedure rend_sw_cirres_n (           {set one specific CIRRES parameter}
  in      n: sys_int_machine_t;        {1-N CIRRES value to set, outrange ignored}
  in      cirres: sys_int_machine_t);  {new val for the particular CIRRES parameter}
  val_param; extern;

function rend_sw_get_cirres (          {get value of particular CIRRES parameter}
  in      n: sys_int_machine_t)        {1 - REND_LAST_CIRRES_K, clipped to range}
  :sys_int_machine_t;                  {value of selected CIRRES parameter}
  val_param; extern;

procedure rend_sw_sphere_3d (          {draw a sphere}
  in      x, y, z: real;               {sphere center point}
  in      r: real);                    {radius}
  val_param; extern;

procedure rend_sw_sphere_ray_3d (      {draw a sphere, saves prim for ray tracing}
  in      x, y, z: real;               {sphere center point}
  in      r: real);                    {radius}
  val_param; extern;

var
  rend_sw_poly_3dpl_d: extern rend_prim_data_t;
  rend_sw_rvect_3dpl_d: extern rend_prim_data_t;
  rend_sw_vect_3dpl_d: extern rend_prim_data_t;
  rend_sw_rect_px_2dimcl_d: extern rend_prim_data_t;
  rend_sw_rect_px_2dimi_d: extern rend_prim_data_t;
  rend_sw_runpx_2dimcl_d: extern rend_prim_data_t;
  rend_sw_span_2dimcl_d: extern rend_prim_data_t;
  rend_sw_span2_2dimcl_d: extern rend_prim_data_t;
  rend_sw_anti_alias_d: extern rend_prim_data_t;
  rend_sw_anti_alias2_d: extern rend_prim_data_t;
  rend_sw_chain_vect_3d_d: extern rend_prim_data_t;
  rend_sw_circle_2dim_d: extern rend_prim_data_t;
  rend_sw_clear_d: extern rend_prim_data_t;
  rend_sw_clear_cwind_d: extern rend_prim_data_t;
  rend_sw_disc_2dim_d: extern rend_prim_data_t;
  rend_sw_flip_buf_d: extern rend_prim_data_t;
  rend_sw_flush_all_d: extern rend_prim_data_t;
  rend_sw_image_2dimcl_d: extern rend_prim_data_t;
  rend_sw_line_3d_d: extern rend_prim_data_t;
  rend_sw_line2_3d_d: extern rend_prim_data_t;
  rend_sw_nsubpix_poly_2dim_d: extern rend_prim_data_t;
  rend_sw_poly_2d_d: extern rend_prim_data_t;
  rend_sw_poly_2dim_d: extern rend_prim_data_t;
  rend_sw_poly_2dimcl_d: extern rend_prim_data_t;
  rend_sw_poly_text_d: extern rend_prim_data_t;
  rend_sw_quad_3d_d: extern rend_prim_data_t;
  rend_sw_ray_trace_2dimi_d: extern rend_prim_data_t;
  rend_sw_rect_2d_d: extern rend_prim_data_t;
  rend_sw_rect_2dim_d: extern rend_prim_data_t;
  rend_sw_rect_2dimcl_d: extern rend_prim_data_t;
  rend_sw_rect_2dimi_d: extern rend_prim_data_t;
  rend_sw_rvect_2d_d: extern rend_prim_data_t;
  rend_sw_rvect_2dim_d: extern rend_prim_data_t;
  rend_sw_rvect_2dimcl_d: extern rend_prim_data_t;
  rend_sw_rvect_text_d: extern rend_prim_data_t;
  rend_sw_sphere_3d_d: extern rend_prim_data_t;
  rend_sw_sphere_ray_3d_d: extern rend_prim_data_t;
  rend_sw_text_d: extern rend_prim_data_t;
  rend_sw_text_raw_d: extern rend_prim_data_t;
  rend_sw_tri_3d_d: extern rend_prim_data_t;
  rend_sw_tri_cache_3d_d: extern rend_prim_data_t;
  rend_sw_tri_cache2_3d_d: extern rend_prim_data_t;
  rend_sw_tri_cache3_3d_d: extern rend_prim_data_t;
  rend_sw_tri_cache_ray_3d_d: extern rend_prim_data_t;
  rend_sw_tstrip_3d_d: extern rend_prim_data_t;
  rend_sw_tubeseg_3d_d: extern rend_prim_data_t;
  rend_sw_tzoid_d: extern rend_prim_data_t;
  rend_sw_tzoid2_d: extern rend_prim_data_t;
  rend_sw_tzoid3_d: extern rend_prim_data_t;
  rend_sw_tzoid4_d: extern rend_prim_data_t;
  rend_sw_tzoid5_d: extern rend_prim_data_t;
  rend_sw_update_span_d: extern rend_prim_data_t;
  rend_sw_update_rect_d: extern rend_prim_data_t;
  rend_sw_vect_2d_d: extern rend_prim_data_t;
  rend_sw_vect_2dimcl_d: extern rend_prim_data_t;
  rend_sw_vect_2dimi_d: extern rend_prim_data_t;
  rend_sw_vect_3d_d: extern rend_prim_data_t;
  rend_sw_vect_3dw_d: extern rend_prim_data_t;
  rend_sw_vect_fp_2dim_d: extern rend_prim_data_t;
  rend_sw_vect_int_2dim_d: extern rend_prim_data_t;
  rend_sw_vect_poly_d: extern rend_prim_data_t;
  rend_sw_vect_text_d: extern rend_prim_data_t;
  rend_sw_wpix_d: extern rend_prim_data_t;

  rend_dummy_poly_2d_d: extern rend_prim_data_t;
  rend_dummy_quad_3d_d: extern rend_prim_data_t;
  rend_dummy_tri_3d_d: extern rend_prim_data_t;
  rend_dummy_tri_cache_3d_d: extern rend_prim_data_t;
  rend_dummy_tstrip_3d_d: extern rend_prim_data_t;
