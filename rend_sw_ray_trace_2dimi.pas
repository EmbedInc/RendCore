{   Subroutine REND_SW_RAY_TRACE_2DIMI (IDX,IDY)
*
*   Ray trace a relative rectangle from the current point.
*   IDX and IDY are the signed width and height.  The signs of IDX and IDY
*   indicate the direction the rectangle is to extend from the current point.
*   A size of 0,0 draws nothing, and a size of 1,1 (or -1,-1) draws the
*   current point.
}
module rend_sw_ray_trace_2dimi;
define rend_sw_ray_trace_2dimi;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_ray_trace_2dimi_d.ins.pas';

procedure rend_sw_ray_trace_2dimi (    {ray trace a rectangle of pixels}
  in      idx, idy: sys_int_machine_t); {size from current pixel to opposite corner}
  val_param;

const
  max_msg_parms = 1;                   {max parameters we can pass to a message}

type
  iterp_save_t = record                {save interpolant data we need to restore}
    int: boolean;                      {fixed integer interpolant value flag}
    mode: sys_int_machine_t;           {current interpolation mode}
    end;

var
  light_p: rend_light_p_t;             {points to current RENDlib light source}
  liparm_p: type1_liparm_p_t;          {points to ray tracer lights descriptor block}
  sz: sys_int_adr_t;                   {amount of memory needed}
  save_red,                            {saved interpolant state}
  save_grn,
  save_blu,
  save_alpha:
    iterp_save_t;
  save_z_mode: sys_int_machine_t;      {save Z interpolation mode}
  changed: boolean;                    {TRUE if we changed interpolant modes}
  rend_on: boolean;                    {TRUE if RENDlib ray primitives exist}
  appl_on: boolean;                    {TRUE if application callback routine exists}
  ady: sys_int_machine_t;              {absolute value of DY}
  sign_dy: sys_int_machine_t;          {+1 or -1 sign of DY}
  xlen: sys_int_machine_t;             {number of pixels to draw on curr scan line}
  i, j: sys_int_machine_t;             {loop counters}
  step: rend_iterp_step_k_t;           {Bresenham step type}
  ray: type1_ray_t;                    {ray descriptor}
  octree_origin: vect_3d_t;            {octree most-negative corner point}
  octree_size: vect_3d_t;              {diagonal to octree most-positive corner}
  msg_parm:                            {parameter references for messages}
    array[1..max_msg_parms] of sys_parm_msg_t;
{
*************************************************
*
*   Local subroutine WRITE_PIXEL
*
*   Write the current pixel, if appropriate.  The current integer pixel
*   coordinate is REND_CURR_X, REND_LEAD_EDGE.Y.  The red, green, blue,
*   Z, and alpha interpolant value will be overwritten with the ray values
*   for each pixel.
*
*   The static part of the ray descriptor has already be initialized.
*   These are the BASE and GENERATION fields.  We must fill in all the
*   other fields here.
*
*   To minimize floating point precision problems, the ray start point
*   will be projected to the near Z clipping plane, and the initial ray
*   MIN_DIST set to zero.
}
procedure write_pixel;

var
  cent_2dim: vect_2d_t;                {2DIM space coordinate of pixel center}
  cent_2d: vect_2d_t;                  {2D space coordinate of pixel center}
  color: type1_color_t;                {color returned for ray thru this pixel}
  z_3dw: real;                         {3DW space Z coordinate for ray hit point}
  z_2d: real;                          {2D space warped Z value}
  farz: real;                          {3DW space Z coordinate for ray MAX_DIST}
  m: real;                             {scratch mult factor}
  aval: rend_ray_value_t;              {ray value from application routine}

begin
  cent_2dim.x := rend_curr_x + 0.5;    {pixel center in 2DIM space}
  cent_2dim.y := rend_lead_edge.y + 0.5;
  rend_get.bxfpnt_2d^ (cent_2dim, cent_2d); {find pixel center in 2D space}

  ray.energy := 1.0;                   {this ray fully controls final values}
  ray.min_dist := 0.0;                 {ray point will be as far forward as possible}
{
*   Set the FARZ value.  This is the 3DW space Z coordinate value that will
*   map to the ray at its MAX_DIST value.  This comes from the current pixel
*   Z value if everthing is appropriately enabled, otherwise this comes from
*   the far Z clip plane.
}
  if
      rend_iterps.z.on and             {Z interpolant is ON ?}
      (rend_iterps.z.bitmap_p <> nil)  {there is a Z bitmap ?}
    then begin                         {valid Z value exists in bitmap exists}
      farz :=                          {raw -1.0 to 1.0 Z between Z clip planes}
        ( rend_iterps.z.curr_adr.p16^ - {raw integer value in pixel}
          1.0 -                        {let ray just a little farther than Z dist}
          rend_iterps.z.val_offset     {offset to get into -1.0 to 1.0 space}
          ) / rend_iterps.z.val_scale; {scale factor to get into -1.0 to 1.0 space}
      farz :=                          {to 3DW space from clip range space}
        (farz - rend_view.zadd) / rend_view.zmult;
      if rend_view.perspec_on then begin {perspective transformations active ?}
        farz :=                        {apply inverse perspective}
          rend_view.eyedis * farz / (rend_view.eyedis + farz);
        end;
      end
    else begin                         {no valid Z pixel value, use far Z clip plane}
      farz := rend_view.zclip_far;
      end
    ;
{
*   Fill in the remaining ray fields.  These are POINT, VECT, and MAX_DIST.
}
 if rend_view.perspec_on

    then begin                         {projection is PERSPECTIVE}
      ray.vect.x := cent_2d.x;         {vector from eye point to projection plane}
      ray.vect.y := cent_2d.y;
      ray.vect.z := -rend_view.eyedis;

      m :=                             {project ray point onto near Z clip plane}
        (rend_view.eyedis - rend_view.zclip_near) / rend_view.eyedis;
      ray.point.x := m * ray.vect.x;
      ray.point.y := m * ray.vect.y;
      ray.point.z := rend_view.zclip_near;

      m :=                             {unitize the ray vector}
        1.0 / sqrt(sqr(ray.vect.x) + sqr(ray.vect.y) + sqr(ray.vect.z));
      ray.vect.x := m * ray.vect.x;
      ray.vect.y := m * ray.vect.y;
      ray.vect.z := m * ray.vect.z;

      ray.max_dist :=                  {ray distance to farthest allowed Z value}
        (farz - rend_view.zclip_near) / ray.vect.z;
      end

   else begin                          {projection is ORTHOGRAPHIC}
      ray.vect.x := 0.0;
      ray.vect.y := 0.0;
      ray.vect.z := -1.0;

      ray.point.x := cent_2d.x;
      ray.point.y := cent_2d.y;
      ray.point.z := rend_view.zclip_near;

      ray.max_dist := rend_view.zclip_near - farz;
      end
    ;
{
*   All done setting up this ray.  Now resolve the color value of the ray.
}
  if rend_on then begin                {RENDlib primitives to ray trace ?}
    ray_trace (ray, color);            {get color for this pixel}
    end;
  if appl_on then begin                {application wants to be called each ray ?}
    if rend_ray.callback^ (            {call application routine}
        ray.point,                     {3DW space ray start point}
        ray.vect,                      {unit ray direction vector}
        ray.min_dist, ray.max_dist,    {acceptable distance limits for valid hit}
        aval)                          {returned ray value if found hit}
        then begin                     {application routine found a closer hit}
      ray.max_dist := aval.dist;       {set distance to hit point}
      color.red := aval.red;           {copy resolved ray color}
      color.grn := aval.grn;
      color.blu := aval.blu;
      color.alpha := aval.opac;        {copy resolved ray opacity}
      end;                             {done handling ray hit from application}
    end;                               {done handling application callback on}

  if color.alpha < 0.001 then return;  {assume background and leave pixel alone ?}
{
*   Calculate equivalent RENDlib 3DW space Z coordinate, then check for Z
*   clipping and stuff the Z interpolant.
}
  z_3dw :=                             {calculate 3DW Z coordinate of hit point}
    ray.point.z +                      {Z at ray start}
    (ray.max_dist * ray.vect.z);       {Z distance along ray to hit point}
  if z_3dw < rend_view.zclip_far       {in back of far Z clip plane ?}
    then return;

  if rend_view.perspec_on
    then begin                         {prespective is ON}
      z_2d := rend_view.zadd +
        ((rend_view.eyedis / (rend_view.eyedis - z_3dw)) * {perspective mult factor}
          z_3dw * rend_view.zmult);
      end
    else begin                         {perpsective is OFF}
      z_2d := (z_3dw * rend_view.zmult) + rend_view.zadd;
      end
    ;                                  {Z_2D is all set}

  rend_iterps.z.value.val32 :=         {set final integer Z interpolant value}
    round(65536.0*(
      rend_iterps.z.val_offset + (rend_iterps.z.val_scale * z_2d)
    ));
{
*   Z is all set.  Now set the final integer red, green, blue and alpha values.
}
  color.red := max(0.0, min(0.9999, color.red)); {clip FP colors to useable range}
  color.grn := max(0.0, min(0.9999, color.grn));
  color.blu := max(0.0, min(0.9999, color.blu));
  color.alpha := max(0.0, min(0.9999, color.alpha));

  rend_iterps.red.value.val32 :=
    min(rend_iterps.red.iclamp_max.val32, max(rend_iterps.red.iclamp_min.val32,
    trunc( (color.red * rend_iterps.red.val_scale * 65536.0) +
      rend_iterps.red.val_offset)));
  rend_iterps.grn.value.val32 :=
    min(rend_iterps.grn.iclamp_max.val32, max(rend_iterps.grn.iclamp_min.val32,
    trunc( (color.grn * rend_iterps.grn.val_scale * 65536.0) +
      rend_iterps.grn.val_offset)));
  rend_iterps.blu.value.val32 :=
    min(rend_iterps.blu.iclamp_max.val32, max(rend_iterps.blu.iclamp_min.val32,
    trunc( (color.blu * rend_iterps.blu.val_scale * 65536.0) +
      rend_iterps.blu.val_offset)));
  rend_iterps.alpha.value.val32 :=
    min(rend_iterps.alpha.iclamp_max.val32, max(rend_iterps.alpha.iclamp_min.val32,
    trunc( (color.alpha * rend_iterps.alpha.val_scale * 65536.0) +
      rend_iterps.alpha.val_offset)));
  rend_prim.wpix^;                     {draw the pixel with our RGB colors}
  end;
{
*************************************************
*
*   Start of main routine.
}
begin
  if (idx = 0) or (idy = 0) then return; {no pixels to write ?}

  if not rend_ray.init then begin      {ray tracer never initialized ?}
    rend_message_bomb ('rend', 'rend_ray_not_initialized', nil, 0);
    end;

  rend_on := rend_ray.xmin <= rend_ray.xmax; {TRUE if primitives were saved}
  appl_on := rend_ray.callback <> nil; {TRUE if application routine active}

  if not (rend_on or appl_on)          {nothing to trace ?}
    then return;

  if not rend_ray.traced then begin    {first time tracing this list of primitives ?}
    rend_ray.traced := true;           {primitives list will now be used}
    octree_origin.x := rend_ray.xmin;  {set octree geometry to axis aligned bounds}
    octree_origin.y := rend_ray.ymin;
    octree_origin.z := rend_ray.zmin;
    octree_size.x := rend_ray.xmax - rend_ray.xmin;
    octree_size.y := rend_ray.ymax - rend_ray.ymin;
    octree_size.z := rend_ray.zmax - rend_ray.zmin;
    if rend_on then begin
      type1_octree_geom (              {reset outer bounds of octree}
        octree_origin,
        octree_size,
        rend_ray.top_obj);             {handle to this octree object}
      end;
    end;
{
*   Set up the ray tracer lighting to match the RENDlib lighting environment.
}
  sz := sizeof(liparm_p^) +            {memory needed for ray tracer lights block}
    (sizeof(liparm_p^.light[1]) * (rend_lights.n_on - type1_max_light_sources_k));
  util_mem_grab (                      {allocate mem for ray tracer lights block}
    sz,                                {amount of memory to allocate}
    ray_mem_p^,                        {context to allocate memory under}
    true,                              {we will want to deallocate this memory}
    liparm_p);                         {pointer to new ray tracer lights block}
  rend_ray.top_parms.liparm_p := liparm_p; {set pointer to ray lights block}
  liparm_p^.n_lights := rend_lights.n_on; {set number of ray tracer lights}

  light_p := rend_lights.on_p;         {get pointer to first RENDlib light source}
  i := 1;                              {init index to first ray tracer light source}
  while light_p <> nil do begin        {loop thru the RENDlib light sources}
    with
        liparm_p^.light[i]: light_ray, {LIGHT_RAY is this ray tracer light source}
        light_p^: light_rend           {LIGHT_REND is this RENDlib light source}
        do begin
      case light_rend.ltype of         {what kind of light source is this ?}
rend_ltype_amb_k: begin                {ambient light}
          light_ray.ltype := type1_ltype_ambient_k;
          light_ray.amb_red := light_rend.amb_red;
          light_ray.amb_grn := light_rend.amb_grn;
          light_ray.amb_blu := light_rend.amb_blu;
          end;
rend_ltype_dir_k: begin                {directional light}
          light_ray.ltype := type1_ltype_directional_k;
          light_ray.dir_red := light_rend.dir_red;
          light_ray.dir_grn := light_rend.dir_grn;
          light_ray.dir_blu := light_rend.dir_blu;
          light_ray.dir_uvect.x := light_rend.dir.x;
          light_ray.dir_uvect.y := light_rend.dir.y;
          light_ray.dir_uvect.z := light_rend.dir.z;
          end;
rend_ltype_pnt_k: begin                {point light, no falloff}
          light_ray.ltype := type1_ltype_point_constant_k;
          light_ray.pcon_red := light_rend.pnt_red;
          light_ray.pcon_grn := light_rend.pnt_grn;
          light_ray.pcon_blu := light_rend.pnt_blu;
          light_ray.pcon_coor.x := light_rend.pnt.x;
          light_ray.pcon_coor.y := light_rend.pnt.y;
          light_ray.pcon_coor.z := light_rend.pnt.z;
          end;
rend_ltype_pr2_k: begin                {point light, 1/R**2 falloff}
          light_ray.ltype := type1_ltype_point_r2_k;
          light_ray.pr2_red := light_rend.pr2_red * light_rend.pr2_r2;
          light_ray.pr2_grn := light_rend.pr2_grn * light_rend.pr2_r2;
          light_ray.pr2_blu := light_rend.pr2_blu * light_rend.pr2_r2;
          light_ray.pr2_coor.x := light_rend.pr2_coor.x;
          light_ray.pr2_coor.y := light_rend.pr2_coor.y;
          light_ray.pr2_coor.z := light_rend.pr2_coor.z;
          end;
otherwise
        sys_msg_parm_int (msg_parm[1], ord(light_rend.ltype));
        rend_message_bomb ('rend', 'rend_light_type_unrecognized', msg_parm, 1);
        end;                           {end of RENDlib light source type cases}
      end;                             {done with LIGHT_RAY and LIGHT_REND abbrevs}
    light_p := light_p^.next_on_p;     {advance to next RENDlib light source}
    i := i + 1;                        {advance to next ray tracer light source}
    end;                               {back to process this new light source}
{
*   Set up the static part of the ray descriptor.
}
  ray.base.context_p := addr(rend_ray.context);
  ray.generation := 1;
{
*   Stomp on some of the interpolant state.  We will save it first so that it can
*   be restored when we are done.
}
  save_red.int := rend_iterps.red.int; {save interplant state we will stomp on}
  save_red.mode := rend_iterps.red.mode;
  save_grn.int := rend_iterps.grn.int;
  save_grn.mode := rend_iterps.grn.mode;
  save_blu.int := rend_iterps.blu.int;
  save_blu.mode := rend_iterps.blu.mode;
  save_alpha.int := rend_iterps.alpha.int;
  save_alpha.mode := rend_iterps.alpha.mode;
  save_z_mode := rend_iterps.z.mode;

  rend_iterps.red.int := false;        {stomp on interpolant modes}
  rend_iterps.red.mode := rend_iterp_mode_flat_k;
  rend_iterps.grn.int := false;
  rend_iterps.grn.mode := rend_iterp_mode_flat_k;
  rend_iterps.blu.int := false;
  rend_iterps.blu.mode := rend_iterp_mode_flat_k;
  rend_iterps.alpha.int := false;
  rend_iterps.alpha.mode := rend_iterp_mode_flat_k;
  rend_iterps.z.mode := rend_iterp_mode_flat_k;

  changed :=                           {TRUE if stomping on iterps changed anything}
    (save_red.int <> rend_iterps.red.int) or
    (save_red.mode <> rend_iterps.red.mode) or
    (save_grn.int <> rend_iterps.grn.int) or
    (save_grn.mode <> rend_iterps.grn.mode) or
    (save_blu.int <> rend_iterps.blu.int) or
    (save_blu.mode <> rend_iterps.blu.mode) or
    (save_alpha.int <> rend_iterps.alpha.int) or
    (save_alpha.mode <> rend_iterps.alpha.mode) or
    (save_z_mode <> rend_iterps.z.mode);

  if changed then begin                {some state did get changed ?}
    rend_internal.check_modes^;
    end;
{
*   Set up the Bresnham steppers so the rest of the system knows what we're going
*   to do.
}
  ady := abs(idy);
  if idy >= 0                          {extract sign of DY}
    then sign_dy := 1
    else sign_dy := -1;

  rend_lead_edge.dxa := 0;
  rend_lead_edge.dxb := 0;
  rend_lead_edge.dya := sign_dy;
  rend_lead_edge.dyb := 0;
  rend_lead_edge.err := -1;            {insure we always take A steps}
  rend_lead_edge.dea := 0;
  rend_lead_edge.deb := 0;
  rend_lead_edge.length := ady;        {number of scan lines to draw}

  rend_trail_edge.x := rend_lead_edge.x + idx;
  rend_trail_edge.y := rend_lead_edge.y;
  rend_trail_edge.dxa := 0;
  rend_trail_edge.dxb := 0;
  rend_trail_edge.dya := sign_dy;
  rend_trail_edge.dyb := 0;
  rend_trail_edge.err := -1;           {insure we always take A steps}
  rend_trail_edge.dea := 0;
  rend_trail_edge.deb := 0;
  rend_trail_edge.length := ady;       {number of scan lines to draw}

  if idx >= 0
    then rend_dir_flag := rend_dir_right_k
    else rend_dir_flag := rend_dir_left_k;
  rend_internal.setup_iterps^;         {set up interpolators for new Bresenham}
{
*   Walk every pixel in the trapezoid we just set up.
}
  for i := 1 to min(rend_lead_edge.length, rend_trail_edge.length) do begin
    if rend_dir_flag = rend_dir_right_k {which direction are we scanning}
      then                             {left-to-right}
        xlen := rend_trail_edge.x-rend_lead_edge.x
      else                             {right-to-left}
        xlen := rend_lead_edge.x-rend_trail_edge.x
      ;
    for j := 1 to xlen do begin        {once for each pixel on this scan line}
      write_pixel;                     {draw this pixel, if appropriate}
      if j < xlen then begin           {not last pixel on this scan line ?}
        rend_sw_interpolate (rend_iterp_step_h_k); {do horizontal interpolation step}
        end;
      end;                             {back and do next pixel on this scan line}
    rend_sw_bres_step (rend_trail_edge, step); {go to next scan line on trailing edge}
    rend_sw_bres_step (rend_lead_edge, step); {next scan line on leading edge}
    rend_sw_interpolate (step);        {set up interpolators for new scan line}
    end;                               {back and do new scan line}
{
*   Restore the interpolant state we stomped on.
}
  rend_iterps.red.int := save_red.int; {restore the interpolant state}
  rend_iterps.red.mode := save_red.mode;
  rend_iterps.grn.int := save_grn.int;
  rend_iterps.grn.mode := save_grn.mode;
  rend_iterps.blu.int := save_blu.int;
  rend_iterps.blu.mode := save_blu.mode;
  rend_iterps.alpha.int := save_alpha.int;
  rend_iterps.alpha.mode := save_alpha.mode;
  rend_iterps.z.mode := save_z_mode;

  if changed then begin                {restoring iterps caused state change ?}
    rend_internal.check_modes^;
    end;
  end;
