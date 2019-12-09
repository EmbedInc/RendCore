{   Subroutine REND_SW_LINE_3D (V1, V2, GNORM)
*
*   Draw a line segment from 3D model coordinate space.  V1 and V2 are standard
*   RENDlib vertex descriptors for each line segment endpoint.  GNORM is the
*   geometric normal vector for this line.  Only its direction is relevant, and
*   therefore must not be of zero length.  The geometric normal is used in
*   backface determination, and for setting the proper slope of the Z interpolant
*   in the direction perpendicular to the line segment.
}
module rend_sw_line_3d;
define rend_sw_line_3d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_line_3d_d.ins.pas';

procedure rend_sw_line_3d (            {draw 3D model space line, curr pnt trashed}
  in      v1, v2: univ rend_vert3d_t;  {descriptors for each line segment endpoint}
  in      gnorm: vect_3d_t);           {geometric normal for Z slope and backface}
  val_param;

type
  lv_entry_t = record                  {template for one entry of local V array}
    cache_p: rend_vcache_p_t;          {pointer to cache for this vertex}
    v_p: rend_vert3d_p_t;              {pointer to original vertex descriptor}
    end;

  lv_entry_p_t =                       {pointer to a local V array entry}
    ^lv_entry_t;

var
  flip_factor: real;                   {-1.0 if flip normals, 1.0 otherwise}
  gnorm3dw: vect_3d_t;                 {geometric normal vector in 3DW space}
  nv, nv2: vect_3d_t;                  {scratch shading normal and other vectors}
  nv_p: vect_3d_p_t;                   {pointer to current shading normal vector}
  w: real;                             {scratch scale factor}
  lv:                                  {local copy of some info per vertex}
    array[1..8] of lv_entry_t;
  local_caches:                        {vertex cache info if none available from user}
    array[1..8] of rend_vcache_t;
  local_verts_p: rend_vert3d_p_t;      {points to first dynamically allocated vertex}
  next_vert_p: rend_vert3d_p_t;        {points to next free vertex descriptor to use}
  local_uvw:                           {UVW buffers for locally created verticies}
    array[3..8] of rend_uvw_t;
  local_col:                           {RGBA values for locally created verticies}
    array[3..8] of rend_rgba_t;
  nextv: integer32;                    {next avail vert num in LV and LOCAL_CACHES}
  sp: rend_suprop_p_t;                 {pointer to applicable surf prop block}
  iv1_p, iv2_p,                        {pointers to verticies for linear interp vals}
  iv3_p:                               {extra pointer for quadratic surface geom}
    lv_entry_p_t;
  perp: vect_3d_t;                     {perpendicular to GNORM3DW and line segment}
  p4, p5, p6: vect_2d_t;               {iterp anchor points, 2DIM space}
  p4z: real;                           {Z value of iterp anchor point}
  v1_p, v2_p:                          {pointers to verticies at line segment ends}
    lv_entry_p_t;
  col1, col2, col3: real;              {color values used to set up interpolators}
  clip_minx, clip_maxx, clip_miny, clip_maxy: {2DIM space clipping coordinates}
    real;
  flip_shad: boolean;                  {TRUE if flip shading normal vectors}
  view_front: boolean;                 {TRUE if viewing front side of polygon}
  gnorm3dw_unit: boolean;              {TRUE if GNORM3DW has been unitized}
  clipping_z: boolean;                 {TRUE if doing Z clips instead of XY clips}
  c1, c2, c3: vect_2d_t;               {misc coordinates used for interpolation}

label
  got_shnorm_v1, got_shnorm_v2, draw_line,
  done_rgba_iterps, clipped, done_z_clips, leave;
{
**************************************************************************************
*
*   Local subroutine INTERPOLATE_VERT (V1,W1,V2,W2,V)
*
*   Interpolate the values of the verticies V1 and V2 into the vertex V.
*   W1 is the fractional contribution from V1, and W2 is the  fractional
*   contribution from V2.  It is assumed that the 3D world space information
*   in the input vertex caches is up to date.  The verticies V1, V2, and V are
*   internal vertex descriptors.  The information will be interpolated in the
*   3D world space, and then used to re-compute the 2DIM space coordinates and color
*   values.
}
procedure interpolate_vert (
  in      v1: lv_entry_t;              {first input vertex}
  in      w1: real;                    {fractional contribution from first vertex}
  in      v2: lv_entry_t;              {second input vertex}
  in      w2: real;                    {fractional contribution from second vertex}
  in out  v: lv_entry_t);              {output vertex}

var
  m: real;                             {scratch mult factor}
  red, grn, blu, alpha: real;          {scratch color values}
  norm: vect_3d_t;                     {scratch normal vector}

begin
{
*   Fill the geometry information in the new vertex cache.  The 3D world space
*   coordinates will be interpolated from the two input verticies.  The 2D
*   coordinates will be computed from the interpolated 3D coordinates.
}
  with
      v1.cache_p^: ca1,                {CA1 is vertex 1 cache}
      v2.cache_p^: ca2,                {CA2 is vertex 2 cache}
      v.cache_p^: ca                   {CA is output vertex cache}
    do begin
  ca.x3dw := w1*ca1.x3dw + w2*ca2.x3dw; {interpolate 3D world space coordinate}
  ca.y3dw := w1*ca1.y3dw + w2*ca2.y3dw;
  ca.z3dw := w1*ca1.z3dw + w2*ca2.z3dw;
  m := rend_view.eyedis/(rend_view.eyedis-ca.z3dw); {perspective mult factor}
  ca.x :=
    m*(ca.x3dw*rend_2d.sp.xb.x + ca.y3dw*rend_2d.sp.yb.x) +
    rend_2d.sp.ofs.x;
  ca.y :=
    m*(ca.y3dw*rend_2d.sp.xb.y + ca.y3dw*rend_2d.sp.yb.y) +
    rend_2d.sp.ofs.y;
  ca.z :=
    m*ca.z3dw*rend_view.zmult + rend_view.zadd;
{
*   Geometry all set.  Now interpolate the texture index coordinates, if appropriate.
}
  if rend_iterps.u.on then begin
    v.v_p^[rend_tmapi_p_ind].tmapi_p^.u := {make interpolated U coordinate}
      w1*v1.v_p^[rend_tmapi_p_ind].tmapi_p^.u + w2*v2.v_p^[rend_tmapi_p_ind].tmapi_p^.u;
    end;
  if rend_iterps.v.on then begin
    v.v_p^[rend_tmapi_p_ind].tmapi_p^.v := {make interpolated V coordinate}
      w1*v1.v_p^[rend_tmapi_p_ind].tmapi_p^.v + w2*v2.v_p^[rend_tmapi_p_ind].tmapi_p^.v;
    end;
{
*   Interpolate the object diffuse color at this new coordinate.  For each source
*   vertex, the object diffuse color may be given explicitly, or come from the
*   surface properties block.  The resulting diffuse color is set as an explicit
*   color for the new vertex.
}
  if (rend_diff_p_ind < 0) or else (v1.v_p^[rend_diff_p_ind].diff_p = nil)
    then begin                         {diffuse color comes from suprop block}
      red := sp^.diff.red*w1;
      grn := sp^.diff.grn*w1;
      blu := sp^.diff.blu*w1;
      alpha := w;
      end
    else begin                         {diffuse explicitly given in vertex}
      red := v1.v_p^[rend_diff_p_ind].diff_p^.red*w1;
      grn := v1.v_p^[rend_diff_p_ind].diff_p^.grn*w1;
      blu := v1.v_p^[rend_diff_p_ind].diff_p^.blu*w1;
      alpha := v1.v_p^[rend_diff_p_ind].diff_p^.alpha*w1;
      end
    ;
  if (rend_diff_p_ind < 0) or else (v2.v_p^[rend_diff_p_ind].diff_p = nil)
    then begin                         {diffuse color comes from suprop block}
      v.v_p^[rend_diff_p_ind].diff_p^.red := red + sp^.diff.red*w2;
      v.v_p^[rend_diff_p_ind].diff_p^.grn := grn + sp^.diff.grn*w2;
      v.v_p^[rend_diff_p_ind].diff_p^.blu := blu + sp^.diff.blu*w2;
      v.v_p^[rend_diff_p_ind].diff_p^.alpha := alpha + w2;
      end
    else begin                         {diffuse explicitly given in vertex}
      v.v_p^[rend_diff_p_ind].diff_p^.red := red + v2.v_p^[rend_diff_p_ind].diff_p^.red*w2;
      v.v_p^[rend_diff_p_ind].diff_p^.grn := grn + v2.v_p^[rend_diff_p_ind].diff_p^.grn*w2;
      v.v_p^[rend_diff_p_ind].diff_p^.blu := blu + v2.v_p^[rend_diff_p_ind].diff_p^.blu*w2;
      v.v_p^[rend_diff_p_ind].diff_p^.alpha := alpha + v2.v_p^[rend_diff_p_ind].diff_p^.alpha*w2;
      end
    ;
{
*   Calculate the final visible colors at the new vertex.  This is done by
*   interpolating the shading normal vector used for each of the source verticies,
*   re-unitizing it, and using it as the shading normal for the new vertex.
*   This yields a better approximation than just simply interpolating the visible
*   colors from the source verticies.
}
  norm.x := w1*ca1.shnorm.x + w2*ca2.shnorm.x;
  norm.y := w1*ca1.shnorm.y + w2*ca2.shnorm.y;
  norm.z := w1*ca1.shnorm.z + w2*ca2.shnorm.z;
  m := sqr(norm.x) + sqr(norm.y) + sqr(norm.z);
  if m < 1.0E-10
    then begin                         {interpolated unit shading normal is too small}
      if not gnorm3dw_unit then begin  {GNORM3DW not already shading vector ?}
        m := flip_factor/sqrt(         {scale factor to unitize geometric normal}
          sqr(gnorm3dw.x) + sqr(gnorm3dw.y) + sqr(gnorm3dw.z));
        gnorm3dw.x := m*gnorm3dw.x;    {scale geometric normal to unit length}
        gnorm3dw.y := m*gnorm3dw.y;
        gnorm3dw.z := m*gnorm3dw.z;
        gnorm3dw_unit := true;         {GNORM3DW has now been unitized}
        end;                           {done making GNORM3DW into shading norm vect}
      rend_get.light_eval^ (           {evaluate visible colors here}
        v.v_p^,                        {REND lib vertex to evaluate colors at}
        ca,                            {cache block to use for this vertex}
        gnorm3dw,                      {unit normal vector to use for shading}
        sp^);                          {surface properties block to use}
      end                              {done with use geometric norm for shading}
    else begin                         {use interpolated normal for shading}
      m := 1.0/sqrt(m);                {mult factor to unitize interpolated normal}
      norm.x := norm.x * m;            {make unit shading normal for this vertex}
      norm.y := norm.y * m;
      norm.z := norm.z * m;
      rend_get.light_eval^ (           {evaluate visible colors here}
        v.v_p^,                        {REND lib vertex to evaluate colors at}
        ca,                            {cache block to use for this vertex}
        norm,                          {unit normal vector to use for shading}
        sp^);                          {surface properties block to use}
      end                              {done with use geometric norm for shading}
    ;                                  {done evaluating final colors}

    end;                               {done with CA1, CA2, and CA abbreviations}
  end;
{
**************************************************************************************
*
*   Local subroutine MAKE_NEW_SHADING_VERT (V1, V2, P)
*
*   Create a new vertex, and fill in by interpolating half way between vertex
*   V1 and V2.  P is the returned pointer to the newly created vertex.  The 3D
*   world space coordinates are interpolated, and then used to find the 2D
*   coordinates and color values.  V1 and V2 are internal vertex descriptors, and
*   P will point to an internal vertex descriptor.
}
procedure make_new_shading_vert (
  in      v1: lv_entry_t;              {first input vertex}
  in      v2: lv_entry_t;              {second input vertex}
  out     p: lv_entry_p_t);            {returned pointer to output vertex}

begin
  p := addr(lv[nextv]);                {make pointer to new vertex}
  p^.cache_p := addr(local_caches[nextv]); {set pointer to cache for this vertex}
  p^.v_p := next_vert_p;               {set pointer to top level vertex descriptor}
  next_vert_p := univ_ptr(             {point to next free local vert}
    integer32(next_vert_p) + rend_vert3d_bytes);
  if rend_tmapi_p_ind >= 0 then begin
    p^.v_p^[rend_tmapi_p_ind].tmapi_p := {set pointer to texture index coor}
      addr(local_uvw[nextv]);
    end;
  if rend_diff_p_ind >= 0 then begin
    p^.v_p^[rend_diff_p_ind].diff_p := {set pointer to diffuse colors}
      addr(local_col[nextv]);
    end;
  interpolate_vert (                   {fill in value into new vertex}
    v1, 0.5,                           {first source vertex and weighting factor}
    v2, 0.5,                           {seoncd source vertex and weighting factor}
    p^);                               {output vertex to fill in}
  nextv := nextv+1;                    {update index to next set of free entries}
  end;
{
**************************************************************************************
*
*   Local subroutine CLIP_VERT (V1, W1, V2, P)
*
*   Create new vertex as a result of clipping off vertex V1 from the line segment
*   V1 to V2.  P is returned pointing to the replacement for vertex V1.
*   W1 is the fractional contribution of V1 to the new vertex.  NEXTV is the number
*   of the next available slot in the LV and LOCAL_CACHES array.  CLIPPING_Z
*   must be set to TRUE if the new vertex is a result of clipping to one of
*   the Z clip limits.
}
procedure clip_vert (
  in      v1: lv_entry_t;              {vertex to clip off}
  in      w1: real;                    {fractional contribution of V1 to new vert}
  in      v2: lv_entry_t;              {"other" vertex to clip towards}
  out     p: lv_entry_p_t);            {returned pointing to V1 replacement}

var
  w2: real;                            {contribution of the V1 vertex to the new one}
  f: real;                             {perspective mult factor}

begin
  p := addr(v1);                       {init to not create any new vertex}
  w2 := 1.0-w1;                        {make contribution fraction from V2}
  if w2 < 1.0E-8 then return;          {trying to duplicate V1 ?}
  p := addr(lv[nextv]);                {point to new vertex descriptor}
  p^.cache_p := addr(local_caches[nextv]); {set pointer to cache for this vertex}
  with
      v1.cache_p^: cc,                 {CC is cache for current vertex}
      v2.cache_p^: co,                 {CO is cache for "other" vertex}
      p^.cache_p^: c                   {C is cache for new vertex}
      do begin
  if clipping_z                        {clipping in Z or XY ?}
    then begin                         {new vertex is result of Z clip}
      p^.v_p := next_vert_p;           {set pointer to top level vertex descriptor}
      next_vert_p := univ_ptr(         {point to next free local vert}
        integer32(next_vert_p) + rend_vert3d_bytes);
      if rend_tmapi_p_ind >= 0 then begin
        p^.v_p^[rend_tmapi_p_ind].tmapi_p := {set pointer to texture index coor}
          addr(local_uvw[nextv]);
        end;
      if rend_shade_geom >= rend_iterp_mode_quad_k
        then begin                     {we are creating geometry for quad shading}
          if rend_diff_p_ind >= 0 then begin
             p^.v_p^[rend_diff_p_ind].diff_p := {set pointer to diffuse colors}
               addr(local_col[nextv]);
             end;
          interpolate_vert (           {fill in new vertex}
            v1, w1,                    {first input vertex and fraction}
            v2, w2,                    {second input vertex and fraction}
            p^);                       {output vertex to fill in}
          end                          {done with creating quad geometry case}
        else begin                     {we are creating geometry for linear shading}
          c.x3dw := w1*cc.x3dw + w2*co.x3dw; {interpolate 3DW coordinates}
          c.y3dw := w1*cc.y3dw + w2*co.y3dw;
          c.z3dw := w1*cc.z3dw + w2*co.z3dw;
          f := rend_view.eyedis/(rend_view.eyedis-c.z3dw); {perspective mult factor}
          c.x :=
            f*(c.x3dw*rend_2d.sp.xb.x + c.y3dw*rend_2d.sp.yb.x) +
            rend_2d.sp.ofs.x;
          c.y :=
            f*(c.x3dw*rend_2d.sp.xb.y + c.y3dw*rend_2d.sp.yb.y) +
            rend_2d.sp.ofs.y;
          c.z :=                       {Z interpolant value at this vertex}
            f*c.z3dw*rend_view.zmult + rend_view.zadd;
          if rend_iterps.u.on then begin
            p^.v_p^[rend_tmapi_p_ind].tmapi_p^.u := {make interpolated U coordinate}
              w1*v1.v_p^[rend_tmapi_p_ind].tmapi_p^.u +
              w2*v2.v_p^[rend_tmapi_p_ind].tmapi_p^.u;
            end;
          if rend_iterps.v.on then begin
            p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v := {make interpolated V coordinate}
              w1*v1.v_p^[rend_tmapi_p_ind].tmapi_p^.v +
              w2*v2.v_p^[rend_tmapi_p_ind].tmapi_p^.v;
            end;
          c.color.red := w1*cc.color.red + w2*co.color.red;
          c.color.grn := w1*cc.color.grn + w2*co.color.grn;
          c.color.blu := w1*cc.color.blu + w2*co.color.blu;
          c.color.alpha := w1*cc.color.alpha + w2*co.color.alpha;
          end                          {done with creating linear geometry case}
        ;                              {done handling shade geometry setting}
      end                              {done with new vertex is due to Z clip}
    else begin                         {new vertex is result of X or Y clip}
      c.x := w1*cc.x + w2*co.x;        {interpolate X coordinate}
      c.y := w1*cc.y + w2*co.y;        {interpolate Y coordinate}
      end
    ;                                  {done checking reason for new vertex}
  c.clip_mask := 0;
  end;                                 {done with CC, CO, and C abbreviations}
  nextv := nextv+1;                    {update index to next set of free entries}
  end;
{
**************************************************************************************
*
*   Start main routine.
}
begin
{
*   Transform the geometric normal to the 3D world coordinate space.  It will be
*   used later in the backface determination.
}
  gnorm3dw.x :=
    gnorm.x*rend_xf3d.vxb.x +
    gnorm.y*rend_xf3d.vyb.x +
    gnorm.z*rend_xf3d.vzb.x;
  gnorm3dw.y :=
    gnorm.x*rend_xf3d.vxb.y +
    gnorm.y*rend_xf3d.vyb.y +
    gnorm.z*rend_xf3d.vzb.y;
  gnorm3dw.z :=
    gnorm.x*rend_xf3d.vxb.z +
    gnorm.y*rend_xf3d.vyb.z +
    gnorm.z*rend_xf3d.vzb.z;
{
*   The CACHE_P and V_P entries will now be filled in array TRI.  This will be done
*   one vertex at a time explicitly.  If the original vertex from the caller did
*   not contain a cache pointer, a temporary cache area will be created for this
*   vertex so that its existance can be assumed later.  In this pass, the geometric
*   information will be updated in the cache, if necessary.  The interpolant values
*   will be calculated later if the whole triangle is not clipped off.
*
*   Fill in vertex 1.  The backface determination will also be done together with
*   filling in this vertex.
}
  if (rend_vcache_p_ind < 0) or else (v1[rend_vcache_p_ind].vcache_p = nil)
    then begin                         {no user supplied cache, create our own}
      lv[1].cache_p := addr(local_caches[1]); {get pointer to local cache memory}
      lv[1].cache_p^.version :=        {flag new cache as invalid}
        rend_cache_version_invalid;
      end
    else begin                         {user cache exists, just copy pointer}
      lv[1].cache_p := v1[rend_vcache_p_ind].vcache_p; {copy user's cache pointer}
      end
    ;                                  {cache block now exists for this vertex}
  lv[1].v_p := addr(v1);               {save pointer to caller's vertex data}
  with
      lv[1].cache_p^: ca,              {CA is abbrev for cache block}
      v1[rend_coor_p_ind].coor_p^: mc  {MC is abbrev for 3D model space coordinate}
      do begin
    if ca.version <> rend_cache_version then begin {cache info invalid ?}
      ca.x3dw :=                       {make 3D world space coor for vertex 1}
        mc.x*rend_xf3d.xb.x +
        mc.y*rend_xf3d.yb.x +
        mc.z*rend_xf3d.zb.x +
        rend_xf3d.ofs.x;
      ca.y3dw :=
        mc.x*rend_xf3d.xb.y +
        mc.y*rend_xf3d.yb.y +
        mc.z*rend_xf3d.zb.y +
        rend_xf3d.ofs.y;
      ca.z3dw :=
        mc.x*rend_xf3d.xb.z +
        mc.y*rend_xf3d.yb.z +
        mc.z*rend_xf3d.zb.z +
        rend_xf3d.ofs.z;
      end;                             {3D world space coor now definately valid}
{
*   Use the partial information available for vertex 1 to do the backface
*   determination.
}
    if rend_view.perspec_on
      then begin                       {perspective is turned on}
        view_front :=                  {true if viewing front face of polygon}
          (-ca.x3dw*gnorm3dw.x - ca.y3dw*gnorm3dw.y +
          (rend_view.eyedis-ca.z3dw)*gnorm3dw.z)
          >= 0.0;
        end
      else begin                       {perspective is turned off}
        view_front := gnorm3dw.z >= 0.0;
        end
      ;
    case rend_view.backface of

rend_bface_off_k: begin                {draw polygon "as is"}
        flip_factor := 1.0;            {do not flip shading normals}
        flip_shad := false;            {don't flip shading normals for light eval}
        sp := addr(rend_face_front);   {select suprop block to use}
        end;

rend_bface_front_k: begin              {draw only if front face is showing}
        if not view_front then return; {front face is not showing ?}
        flip_factor := 1.0;            {do not flip shading normals}
        flip_shad := false;            {don't flip shading normals for light eval}
        sp := addr(rend_face_front);   {select suprop block to use}
        end;

rend_bface_back_k: begin               {draw only if back face showing}
        if view_front then return;
        flip_factor := -1.0;           {flip shading normals before use}
        flip_shad := true;
        if rend_face_back.on
          then sp := addr(rend_face_back)
          else sp := addr(rend_face_front);
        end;

rend_bface_flip_k: begin               {draw front and back as separate surfaces}
        if view_front
          then begin                   {we are looking at the front face}
            flip_factor := 1.0;        {do not flip shading normals}
            flip_shad := false;        {don't flip shading normals for light eval}
            sp := addr(rend_face_front);
            end
          else begin                   {we are looking at the back face}
            flip_factor := -1.0;       {flip shading normals before use}
            flip_shad := true;
            if rend_face_back.on
              then sp := addr(rend_face_back)
              else sp := addr(rend_face_front);
            end
          ;
        end;

      end;                             {done with backfacing flag cases}
{
*   FLIP_FACTOR, FLIP_SHAD, and the pointer SP are all set.  Any backface
*   elimination has also been done.  FLIP_FACTOR is -1.0 if the shading normals
*   need to be flipped around before the shading calculation is done.
*   SP points to the suprop block to use for color determination.
*
*   Continue filling cache for vertex 1.
}
    if not rend_clip_2dim.exists then begin
      writeln ('Complicated clipping environment not supported in REND_SW_LINE_3D.');
      sys_bomb;
      end;
    clip_minx := rend_clip_2dim.xmin;
    clip_maxx := rend_clip_2dim.xmax;
    clip_miny := rend_clip_2dim.ymin;
    clip_maxy := rend_clip_2dim.ymax;

    if ca.version <> rend_cache_version then begin {cache info needs updating ?}
      ca.clip_mask := 0;               {init to inside all clip limits}
      if ca.z3dw > rend_view.zclip_near {in front of near Z limit ?}
        then ca.clip_mask := rend_clmask_nz_k;
      if ca.z3dw < rend_view.zclip_far {behind far Z limit ?}
        then ca.clip_mask := rend_clmask_fz_k;
      if ca.clip_mask = 0 then begin   {OK to transform to 2D space ?}
        if rend_view.perspec_on        {check perspective on/off flag}
          then begin                   {perspective is on}
            w := rend_view.eyedis/(rend_view.eyedis-ca.z3dw);
            ca.x :=
              w*(ca.x3dw*rend_2d.sp.xb.x + ca.y3dw*rend_2d.sp.yb.x) +
              rend_2d.sp.ofs.x;
            ca.y :=
              w*(ca.x3dw*rend_2d.sp.xb.y + ca.y3dw*rend_2d.sp.yb.y) +
              rend_2d.sp.ofs.y;
            ca.z :=                    {Z interpolant value at this vertex}
              ca.z3dw*w*rend_view.zmult + rend_view.zadd;
            end
          else begin                   {perspective is turned off}
            ca.x :=
              ca.x3dw*rend_2d.sp.xb.x + ca.y3dw*rend_2d.sp.yb.x +
              rend_2d.sp.ofs.x;
            ca.y :=
              ca.x3dw*rend_2d.sp.xb.y + ca.y3dw*rend_2d.sp.yb.y +
              rend_2d.sp.ofs.y;
            ca.z :=                    {Z interpolant value at this vertex}
              ca.z3dw*rend_view.zmult + rend_view.zadd;
            end
          ;                            {done handling perspective on/off}
        if ca.y < clip_miny            {find and save 2D clip status}
          then ca.clip_mask := ca.clip_mask + rend_clmask_ty_k;
        if ca.y > clip_maxy
          then ca.clip_mask := ca.clip_mask + rend_clmask_by_k;
        if ca.x < clip_minx
          then ca.clip_mask := ca.clip_mask + rend_clmask_lx_k;
        if ca.x > clip_maxx
          then ca.clip_mask := ca.clip_mask + rend_clmask_rx_k;
        end;                           {done transforming to 2DIM space}
      ca.version := rend_cache_version; {indicate cache now contains valid data}
      ca.colors_valid := false;        {indicate colors not yet updated}
      end;                             {done with cache version was not valid}
    end;                               {done with CA and MC abbreviations}
{
*   Fill cache for vertex 2.
}
  if (rend_vcache_p_ind < 0) or else (v2[rend_vcache_p_ind].vcache_p = nil)
    then begin                         {no user supplied cache, create our own}
      lv[2].cache_p := addr(local_caches[2]); {get pointer to local cache memory}
      lv[2].cache_p^.version :=        {flag new cache as invalid}
        rend_cache_version_invalid;
      end
    else begin                         {user cache exists, just copy pointer}
      lv[2].cache_p := v2[rend_vcache_p_ind].vcache_p; {copy user's cache pointer}
      end
    ;                                  {cache block now exists for this vertex}
  lv[2].v_p := addr(v2);               {save pointer to caller's vertex data}
  with
      lv[2].cache_p^: ca,              {CA is abbrev for cache block}
      v2[rend_coor_p_ind].coor_p^: mc  {MC is abbrev for 3D model space coordinate}
      do begin
    if ca.version <> rend_cache_version then begin {cache info invalid ?}
      ca.x3dw :=                       {make 3D world space coor for this vertex}
        mc.x*rend_xf3d.xb.x +
        mc.y*rend_xf3d.yb.x +
        mc.z*rend_xf3d.zb.x +
        rend_xf3d.ofs.x;
      ca.y3dw :=
        mc.x*rend_xf3d.xb.y +
        mc.y*rend_xf3d.yb.y +
        mc.z*rend_xf3d.zb.y +
        rend_xf3d.ofs.y;
      ca.z3dw :=
        mc.x*rend_xf3d.xb.z +
        mc.y*rend_xf3d.yb.z +
        mc.z*rend_xf3d.zb.z +
        rend_xf3d.ofs.z;
      end;                             {3D world space coor now definately valid}
    if ca.version <> rend_cache_version then begin {cache info needs updating ?}
      ca.clip_mask := 0;               {init to inside all clip limits}
      if ca.z3dw > rend_view.zclip_near {in front of near Z limit ?}
        then ca.clip_mask := rend_clmask_nz_k;
      if ca.z3dw < rend_view.zclip_far {behind far Z limit ?}
        then ca.clip_mask := rend_clmask_fz_k;
      if ca.clip_mask = 0 then begin   {OK to transform to 2D space ?}
        if rend_view.perspec_on        {check perspective on/off flag}
          then begin                   {perspective is on}
            w := rend_view.eyedis/(rend_view.eyedis-ca.z3dw);
            ca.x :=
              w*(ca.x3dw*rend_2d.sp.xb.x + ca.y3dw*rend_2d.sp.yb.x) +
              rend_2d.sp.ofs.x;
            ca.y :=
              w*(ca.x3dw*rend_2d.sp.xb.y + ca.y3dw*rend_2d.sp.yb.y) +
              rend_2d.sp.ofs.y;
            ca.z :=                    {Z interpolant value at this vertex}
              ca.z3dw*w*rend_view.zmult + rend_view.zadd;
            end
          else begin                   {perspective is turned off}
            ca.x :=
              ca.x3dw*rend_2d.sp.xb.x + ca.y3dw*rend_2d.sp.yb.x +
              rend_2d.sp.ofs.x;
            ca.y :=
              ca.x3dw*rend_2d.sp.xb.y + ca.y3dw*rend_2d.sp.yb.y +
              rend_2d.sp.ofs.y;
            ca.z :=                    {Z interpolant value at this vertex}
              ca.z3dw*rend_view.zmult + rend_view.zadd;
            end
          ;                            {done handling perspective on/off}
        if ca.y < clip_miny            {find and save 2D clip status}
          then ca.clip_mask := ca.clip_mask + rend_clmask_ty_k;
        if ca.y > clip_maxy
          then ca.clip_mask := ca.clip_mask + rend_clmask_by_k;
        if ca.x < clip_minx
          then ca.clip_mask := ca.clip_mask + rend_clmask_lx_k;
        if ca.x > clip_maxx
          then ca.clip_mask := ca.clip_mask + rend_clmask_rx_k;
        end;                           {done transforming to 2DIM space}
      ca.version := rend_cache_version; {indicate cache now contains valid data}
      ca.colors_valid := false;        {indicate colors not yet updated}
      end;                             {done with cache version was not valid}
    end;                               {done with CA and MC abbreviations}
{
*   The geometric information in the cache for each vertex is definately up to date.
*   This means that the 3DW space coordinate and clip flag are valid.  If the vertex
*   was not clipped out by Z, then the 2DIM space coordinates and clip flags are
*   also valid.
*
*   Now check whether the entire triangle is clipped off.
}
  if (                                 {do trivial clip reject test}
      lv[1].cache_p^.clip_mask &
      lv[2].cache_p^.clip_mask) <> 0 then return;
{
*   The trivial clip reject test failed.  It is now reasonable to assume that
*   something will be drawn, and it is time to make sure the color and other
*   interpolant information is up to date.
}
  nextv := 3;                          {init next vertex number to allocate}
  sys_mem_alloc (rend_vert3d_bytes*6, local_verts_p); {grab mem for temp verts}
  if local_verts_p = nil then begin
    writeln ('Unable to allocate dynamic memory in REND_SW_LINE_3D.');
    writeln ('The disk is probably full.');
    sys_bomb;
    end;
  next_vert_p := local_verts_p;        {init pointer to next free local vertex}
  gnorm3dw_unit := false;              {init to GNORM3DW has not been unitized yet}
{
*   Fill in interpolants for vertex 1.
}
  if (not lv[1].cache_p^.colors_valid) or
      (lv[1].cache_p^.flip_shad <> flip_shad)
      then begin                       {need to find colors here ?}
    with
        lv[1].cache_p^: ca,            {CA is abbrev for cache block for this vertex}
        v1: v                          {V is the call arg for this vertex}
        do begin
      if  (rend_norm_p_ind >= 0) and then {shading normal explicitly given ?}
          (v[rend_norm_p_ind].norm_p <> nil)
          then begin
        nv2.x := v[rend_norm_p_ind].norm_p^.x;
        nv2.y := v[rend_norm_p_ind].norm_p^.y;
        nv2.z := v[rend_norm_p_ind].norm_p^.z;
        end
      else if (rend_ncache_p_ind >= 0) and then {try looking in normal vector cache}
          (v[rend_ncache_p_ind].ncache_p <> nil) and then
          (v[rend_ncache_p_ind].ncache_p^.flags.version = rend_ncache_flags.version)
          then begin
        nv2.x := v[rend_ncache_p_ind].ncache_p^.norm.x;
        nv2.y := v[rend_ncache_p_ind].ncache_p^.norm.y;
        nv2.z := v[rend_ncache_p_ind].ncache_p^.norm.z;
        end
      else if (rend_spokes_p_ind >= 0) and then {try computing normal from spokes list}
          (v[rend_spokes_p_ind].spokes_p <> nil)
          then begin
        rend_spokes_to_norm (v, false, nv2); {make shading normal in NV2}
        end
      else begin                       {no shading normal, use geometric normal}
        w := flip_factor/sqrt(         {scale factor to unitize geometric normal}
          sqr(gnorm3dw.x) + sqr(gnorm3dw.y) + sqr(gnorm3dw.z));
        gnorm3dw.x := w*gnorm3dw.x;    {scale geometric normal to unit length}
        gnorm3dw.y := w*gnorm3dw.y;
        gnorm3dw.z := w*gnorm3dw.z;
        gnorm3dw_unit := true;         {GNORM3DW has now been unitized}
        nv_p := addr(gnorm3dw);
        ca.colors_valid := false;      {colors will not be reusable}
        goto got_shnorm_v1;            {NV_P points to final shading normal}
        end
        ;
      nv.x :=                          {make 3D world space shading normal vector}
        nv2.x*rend_xf3d.vxb.x +
        nv2.y*rend_xf3d.vyb.x +
        nv2.z*rend_xf3d.vzb.x;
      nv.y :=
        nv2.x*rend_xf3d.vxb.y +
        nv2.y*rend_xf3d.vyb.y +
        nv2.z*rend_xf3d.vzb.y;
      nv.z :=
        nv2.x*rend_xf3d.vxb.z +
        nv2.y*rend_xf3d.vyb.z +
        nv2.z*rend_xf3d.vzb.z;
      w := flip_factor/sqrt(           {make scale factor for unitizing NV}
        sqr(nv.x) + sqr(nv.y) + sqr(nv.z));
      nv.x := w*nv.x;
      nv.y := w*nv.y;
      nv.z := w*nv.z;
      nv_p := addr(nv);                {point to shading normal}
      ca.colors_valid := true;         {colors will be reusable}
got_shnorm_v1:                         {NV_P points 3DW space shading unit normal}
      rend_get.light_eval^ (           {evaluate visible color at this vertex}
        v,                             {vertex to evaluate colors at}
        ca,                            {cache block for this vertex}
        nv_p^,                         {normal vector at this point}
        sp^);                          {suprop block to use for surface properties}
      ca.flip_shad := flip_shad;       {save whether used flipped normal or not}
      end;                             {done with CA and V abbreviations}
    end;                               {done handling cached colors wern't valid}
{
*   Fill in interpolants for vertex 2.
}
  if (not lv[2].cache_p^.colors_valid) or
      (lv[2].cache_p^.flip_shad <> flip_shad)
      then begin                       {need to find colors here ?}
    with
        lv[2].cache_p^: ca,            {CA is abbrev for cache block for this vertex}
        v2: v                          {V is the call arg for this vertex}
        do begin
      if  (rend_norm_p_ind >= 0) and then {shading normal explicitly given ?}
          (v[rend_norm_p_ind].norm_p <> nil)
          then begin
        nv2.x := v[rend_norm_p_ind].norm_p^.x;
        nv2.y := v[rend_norm_p_ind].norm_p^.y;
        nv2.z := v[rend_norm_p_ind].norm_p^.z;
        end
      else if (rend_ncache_p_ind >= 0) and then {try looking in normal vector cache}
          (v[rend_ncache_p_ind].ncache_p <> nil) and then
          (v[rend_ncache_p_ind].ncache_p^.flags.version = rend_ncache_flags.version)
          then begin
        nv2.x := v[rend_ncache_p_ind].ncache_p^.norm.x;
        nv2.y := v[rend_ncache_p_ind].ncache_p^.norm.y;
        nv2.z := v[rend_ncache_p_ind].ncache_p^.norm.z;
        end
      else if (rend_spokes_p_ind >= 0) and then {try computing normal from spokes list}
          (v[rend_spokes_p_ind].spokes_p <> nil)
          then begin
        rend_spokes_to_norm (v, false, nv2); {make shading normal in NV2}
        end
      else begin                       {no shading normal, use geometric normal}
        if not gnorm3dw_unit then begin {GNORM3DW not already shading vector ?}
          w := flip_factor/sqrt(       {scale factor to unitize geometric normal}
            sqr(gnorm3dw.x) + sqr(gnorm3dw.y) + sqr(gnorm3dw.z));
          gnorm3dw.x := w*gnorm3dw.x;  {scale geometric normal to unit length}
          gnorm3dw.y := w*gnorm3dw.y;
          gnorm3dw.z := w*gnorm3dw.z;
          gnorm3dw_unit := true;       {GNORM3DW has now been unitized}
          end;                         {done making GNORM3DW into shading norm vect}
        nv_p := addr(gnorm3dw);
        ca.colors_valid := false;      {colors will not be reusable}
        goto got_shnorm_v2;            {NV_P points to final shading normal}
        end
        ;
      nv.x :=                          {make 3D world space shading normal vector}
        nv2.x*rend_xf3d.vxb.x +
        nv2.y*rend_xf3d.vyb.x +
        nv2.z*rend_xf3d.vzb.x;
      nv.y :=
        nv2.x*rend_xf3d.vxb.y +
        nv2.y*rend_xf3d.vyb.y +
        nv2.z*rend_xf3d.vzb.y;
      nv.z :=
        nv2.x*rend_xf3d.vxb.z +
        nv2.y*rend_xf3d.vyb.z +
        nv2.z*rend_xf3d.vzb.z;
      w := flip_factor/sqrt(           {make scale factor for unitizing NV}
        sqr(nv.x) + sqr(nv.y) + sqr(nv.z));
      nv.x := w*nv.x;
      nv.y := w*nv.y;
      nv.z := w*nv.z;
      nv_p := addr(nv);                {point to shading normal}
      ca.colors_valid := true;         {colors will be reusable}
got_shnorm_v2:                         {NV_P points 3DW space shading unit normal}
      rend_get.light_eval^ (           {evaluate visible color at this vertex}
        v,                             {vertex to evaluate colors at}
        ca,                            {cache block for this vertex}
        nv_p^,                         {normal vector at this point}
        sp^);                          {suprop block to use for surface properties}
      ca.flip_shad := flip_shad;       {save whether used flipped normal or not}
      end;                             {done with CA and V abbreviations}
    end;                               {done handling cached colors wern't valid}
{
*   The cache data for both verticies is completely up to date.
*
*   Handle clipping.  First check for the easy case where the whole line segment
*   is to be drawn.
}
  iv1_p := addr(lv[1]);                {init pointers to interpolation anchor points}
  iv2_p := addr(lv[2]);

  if (                                 {jump elsewhere if clipping needed}
      lv[1].cache_p^.clip_mask !
      lv[2].cache_p^.clip_mask) <> 0
    then goto clipped;

  v1_p := iv1_p;                       {pointers to line segment end points}
  v2_p := iv2_p;
draw_line:                             {jump back here after done clipping}
{
*   IV1_P and IV2_P point to the two anchor points that are to be used for setting
*   up all the interpolants.  V1_P and V2_P point to the two vertex descriptors
*   that represent the final line segment endpoints.  IV1_P and IV2_P are
*   guaranteed to point to coordinates that are within the Z clip limits, but not
*   necessarily within the XY clip limits.
*
*   If SHADE_GEOM is set to quadratic, then a total of six coordinates are needed
*   to compute the quadratic profile.  A new vertex will be created in the center
*   of the line segment before perspective.  This will allow the quadratic
*   interpolation to partially correct for non-linearities of the perspective
*   transform.  The remaining three coordinates will come from the three verticies
*   translated perpendicular to the line segment.  The two endpoints will
*   be translated in one direction and the center point in the other.  This
*   provides 6 linearly independent points for the simultaneous equation solver.
*   P4 will correspond to vertex at IV1_P^, P6 to IV2_p^, and P5 to the new
*   vertex created in the center.
}
  iv3_p := iv2_p;                      {avoid NIL dereference in later WITH statement}
  with
    iv1_p^.cache_p^: v1c,              {V1C is cache for vertex 1}
    iv2_p^.cache_p^: v2c               {V2C is cache for vertex 2}
    do begin

  if rend_shade_geom >= rend_iterp_mode_linear_k then begin {need some extra points ?}
    if not gnorm3dw_unit then begin    {GNORM3DW not already unit vector ?}
      w := flip_factor/sqrt(           {scale factor to unitize geometric normal}
        sqr(gnorm3dw.x) + sqr(gnorm3dw.y) + sqr(gnorm3dw.z));
      gnorm3dw.x := w*gnorm3dw.x;      {scale geometric normal to unit length}
      gnorm3dw.y := w*gnorm3dw.y;
      gnorm3dw.z := w*gnorm3dw.z;
      gnorm3dw_unit := true;           {GNORM3DW has now been unitized}
      end;                             {done unitizing GNORM3DW}
    nv.x := v2c.x3dw - v1c.x3dw;       {from vertex 1 to vertex 2 in 3D world space}
    nv.y := v2c.y3dw - v1c.y3dw;
    nv.z := v2c.z3dw - v1c.z3dw;
    perp.x := (gnorm3dw.y * nv.z) - (gnorm3dw.z * nv.y); {vector perp to line segment}
    perp.y := (gnorm3dw.z * nv.x) - (gnorm3dw.x * nv.z);
    perp.z := (gnorm3dw.x * nv.y) - (gnorm3dw.y * nv.x);
    nv.x := v1c.x3dw + perp.x;         {perpendicular point at vertex 1, 3DW space}
    nv.y := v1c.y3dw + perp.y;
    nv.z := v1c.z3dw + perp.z;
    if rend_view.perspec_on            {check perspective ON/OFF flag}
      then begin                       {perspective is ON}
        w := rend_view.eyedis/(rend_view.eyedis-nv.z);
        p4.x :=                        {transform to 2DIM space}
          w * (nv.x*rend_2d.sp.xb.x + nv.y*rend_2d.sp.yb.x) +
          rend_2d.sp.ofs.x;
        p4.y :=
          w * (nv.x*rend_2d.sp.xb.y + nv.y*rend_2d.sp.yb.y) +
          rend_2d.sp.ofs.y;
        p4z :=
          w * nv.z * rend_view.zmult + rend_view.zadd;
        end
      else begin                       {perspective is OFF}
        p4.x :=                        {transform to 2DIM space}
          nv.x*rend_2d.sp.xb.x + nv.y*rend_2d.sp.yb.x +
          rend_2d.sp.ofs.x;
        p4.y :=
          nv.x*rend_2d.sp.xb.y + nv.y*rend_2d.sp.yb.y +
          rend_2d.sp.ofs.y;
        p4z :=
          nv.z * rend_view.zmult + rend_view.zadd;
        end
      ;                                {done handling perspective ON/OFF}
    end;                               {done making extra point P4}
{
*   If the shading geometry is at least linear, then P4 has been set, and PERP
*   is a vector in 3D world space that is perpendicular to both the line segment
*   and the geometric normal.
}
  case rend_shade_geom of
rend_iterp_mode_linear_k: begin        {set up geometry for linear interpolation}
      c1.x := v1c.x;  c1.y := v1c.y;
      c2.x := v2c.x;  c2.y := v2c.y;
      rend_set.lin_geom_2dim^ (        {set 3 points for linear interpolation}
        p4, c1, c2);
      end;
rend_iterp_mode_quad_k: begin          {set up geom for linear and quadratic interp}
      make_new_shading_vert (iv1_p^, iv2_p^, iv3_p); {create extra shading point}
      nv.x := v2c.x + perp.x;          {perpendicular point at vertex 2, 3DW space}
      nv.y := v2c.y + perp.y;
      nv.z := v2c.z + perp.z;
      nv2.x := iv3_p^.cache_p^.x - perp.x; {perpendicular point at vertex 3, 3DW space}
      nv2.y := iv3_p^.cache_p^.y - perp.y;
      nv2.z := iv3_p^.cache_p^.z - perp.z;
      if rend_view.perspec_on          {check perspective ON/OFF flag}
        then begin                     {perspective is ON}
          w := rend_view.eyedis/(rend_view.eyedis-nv.z);
          p6.x :=                      {transform to 2DIM space}
            w * (nv.x*rend_2d.sp.xb.x + nv.y*rend_2d.sp.yb.x) +
            rend_2d.sp.ofs.x;
          p6.y :=
            w * (nv.x*rend_2d.sp.xb.y + nv.y*rend_2d.sp.yb.y) +
            rend_2d.sp.ofs.y;

          w := rend_view.eyedis/(rend_view.eyedis-nv2.z);
          p5.x :=                      {transform to 2DIM space}
            w * (nv2.x*rend_2d.sp.xb.x + nv2.y*rend_2d.sp.yb.x) +
            rend_2d.sp.ofs.x;
          p5.y :=
            w * (nv2.x*rend_2d.sp.xb.y + nv2.y*rend_2d.sp.yb.y) +
            rend_2d.sp.ofs.y;
          end
        else begin                     {perspective is OFF}
          p6.x :=                      {transform to 2DIM space}
            nv.x*rend_2d.sp.xb.x + nv.y*rend_2d.sp.yb.x +
            rend_2d.sp.ofs.x;
          p6.y :=
            nv.x*rend_2d.sp.xb.y + nv.y*rend_2d.sp.yb.y +
            rend_2d.sp.ofs.y;

          p5.x :=                      {transform to 2DIM space}
            nv2.x*rend_2d.sp.xb.x + nv2.y*rend_2d.sp.yb.x +
            rend_2d.sp.ofs.x;
          p5.y :=
            nv2.x*rend_2d.sp.xb.y + nv2.y*rend_2d.sp.yb.y +
            rend_2d.sp.ofs.y;
          end
        ;                              {done handling perspective ON/OFF}
      c1.x := v1c.x;               c1.y := v1c.y;
      c2.x := v2c.x;               c2.y := v2c.y;
      c3.x := iv3_p^.cache_p^.x;   c3.y := iv3_p^.cache_p^.y;
      rend_set.quad_geom_2dim^ (       {set 6 points for quadratic interpolation}
        p4,
        c1,
        c2,
        p6,
        c3,
        p5);
      end;                             {done with quadratic shade geom case}
    end;                               {done with max shade geom cases}

  if rend_alpha_on                     {alpha buffering turned on ?}
{
*   Alpha buffering is turned on.  This means that red, green, and blue must be
*   pre-multiplied by alpha before being used to set up the interpolants.  It also
*   makes is possible for RGB to be interpolated quadratically with just a linear
*   SHADE_GEOM mode.
}
    then begin
      if                               {can we use LIN_VALS_RGBA call ?}
          (rend_shade_geom = rend_iterp_mode_linear_k) and
          (rend_iterps.red.shmode = rend_iterp_mode_quad_k) and
          (rend_iterps.grn.shmode = rend_iterp_mode_quad_k) and
          (rend_iterps.blu.shmode = rend_iterp_mode_quad_k) and
          (rend_iterps.alpha.shmode = rend_iterp_mode_linear_k)
        then begin
{
*   Alpha buffering is on, SHADE_GEOM is set to linear, RGB shade mode is set to
*   quadratic, and alpha shade mode is set to linear.  This means that the quadratic
*   color values will be inferred by the product of the linear alpha and the linear
*   color, yielding a quadratic result.
}
          rend_set.lin_vals_rgba^ (    {set linear alpha, quadratic RGB}
            v1c.color,
            v1c.color,
            v2c.color);
          goto done_rgba_iterps;       {all done with RGB and alpha interpolants}
          end
{
*   Alpha buffering is on but the LIN_VALS_RGBA routine can not be used.  This
*   means that red, green, blue, and alpha are set up separately, although the RGB
*   values must be pre-multiplied by alpha.
}
        else begin

  if rend_iterps.red.on then begin     {red interpolant turned on ?}
    col1 := v1c.color.red * v1c.color.alpha; {value at vertex 1}
    col2 := v2c.color.red * v2c.color.alpha; {value at vertex 2}
    case rend_iterps.red.shmode of
rend_iterp_mode_flat_k: begin          {set red to flat shading}
        rend_set.iterp_flat^ (
          rend_iterp_red_k, (col1 + col2)*0.5);
        end;
rend_iterp_mode_linear_k: begin        {set red to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_red_k, col1, col1, col2);
        end;
rend_iterp_mode_quad_k: begin          {set red to quadratic interpolation}
        col3 := iv3_p^.cache_p^.color.red * iv3_p^.cache_p^.color.alpha;
        rend_set.quad_vals^ (
          rend_iterp_red_k,
          col1, col1, col2, col2, col3, col3);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting red interpolant}

  if rend_iterps.grn.on then begin     {green interpolant turned on ?}
    col1 := v1c.color.grn * v1c.color.alpha; {value at vertex 1}
    col2 := v2c.color.grn * v2c.color.alpha; {value at vertex 2}
    case rend_iterps.grn.shmode of
rend_iterp_mode_flat_k: begin          {set green to flat shading}
        rend_set.iterp_flat^ (
          rend_iterp_grn_k, (col1 + col2)*0.5);
        end;
rend_iterp_mode_linear_k: begin        {set green to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_grn_k, col1, col1, col2);
        end;
rend_iterp_mode_quad_k: begin          {set green to quadratic interpolation}
        col3 := iv3_p^.cache_p^.color.grn * iv3_p^.cache_p^.color.alpha;
        rend_set.quad_vals^ (
          rend_iterp_grn_k,
          col1, col1, col2, col2, col3, col3);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting green interpolant}

  if rend_iterps.blu.on then begin     {blue interpolant turned on ?}
    col1 := v1c.color.blu * v1c.color.alpha; {value at vertex 1}
    col2 := v2c.color.blu * v2c.color.alpha; {value at vertex 2}
    case rend_iterps.blu.shmode of
rend_iterp_mode_flat_k: begin          {set blue to flat shading}
        rend_set.iterp_flat^ (
          rend_iterp_blu_k, (col1 + col2)*0.5);
        end;
rend_iterp_mode_linear_k: begin        {set blue to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_blu_k, col1, col1, col2);
        end;
rend_iterp_mode_quad_k: begin          {set blue to quadratic interpolation}
        col3 := iv3_p^.cache_p^.color.blu * iv3_p^.cache_p^.color.alpha;
        rend_set.quad_vals^ (
          rend_iterp_blu_k,
          col1, col1, col2, col2, col3, col3);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting blue interpolant}

          end                          {done with separate RGB/alpha case}
        ;                              {done picking how to set RGB/alpha}
      end                              {done with alpha buffering turned on}
{
*   Alpha buffering is turned off.  Red, green, and blue are not pre-multiplied by
*   alpha.
}
    else begin

  if rend_iterps.red.on then begin     {red interpolant turned on ?}
    case rend_iterps.red.shmode of
rend_iterp_mode_flat_k: begin          {set red to flat shading}
        rend_set.iterp_flat^ (
          rend_iterp_red_k, (v1c.color.red + v2c.color.red)*0.5);
        end;
rend_iterp_mode_linear_k: begin        {set red to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_red_k, v1c.color.red, v1c.color.red, v2c.color.red);
        end;
rend_iterp_mode_quad_k: begin          {set red to quadratic interpolation}
        rend_set.quad_vals^ (
          rend_iterp_red_k,
          v1c.color.red, v1c.color.red, v2c.color.red,
          v2c.color.red, iv3_p^.cache_p^.color.red, iv3_p^.cache_p^.color.red);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting red interpolant}

  if rend_iterps.grn.on then begin     {green interpolant turned on ?}
    case rend_iterps.grn.shmode of
rend_iterp_mode_flat_k: begin          {set green to flat shading}
        rend_set.iterp_flat^ (
          rend_iterp_grn_k, (v1c.color.grn + v2c.color.grn)*0.5);
        end;
rend_iterp_mode_linear_k: begin        {set green to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_grn_k, v1c.color.grn, v1c.color.grn, v2c.color.grn);
        end;
rend_iterp_mode_quad_k: begin          {set green to quadratic interpolation}
        rend_set.quad_vals^ (
          rend_iterp_grn_k,
          v1c.color.grn, v1c.color.grn, v2c.color.grn,
          v2c.color.grn, iv3_p^.cache_p^.color.grn, iv3_p^.cache_p^.color.grn);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting green interpolant}

  if rend_iterps.blu.on then begin     {blue interpolant turned on ?}
    case rend_iterps.blu.shmode of
rend_iterp_mode_flat_k: begin          {set blue to flat shading}
        rend_set.iterp_flat^ (
          rend_iterp_blu_k, (v1c.color.blu + v2c.color.blu)*0.5);
        end;
rend_iterp_mode_linear_k: begin        {set blue to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_blu_k, v1c.color.blu, v1c.color.blu, v2c.color.blu);
        end;
rend_iterp_mode_quad_k: begin          {set blue to quadratic interpolation}
        rend_set.quad_vals^ (
          rend_iterp_blu_k,
          v1c.color.blu, v1c.color.blu, v2c.color.blu,
          v2c.color.blu, iv3_p^.cache_p^.color.blu, iv3_p^.cache_p^.color.blu);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting blue interpolant}

      end                              {done with alpha buffering turned off}
    ;                                  {done checking for alpha buffering on/off}
{
*   All done with any possible interactions due to alpha buffering.  The red,
*   green, and blue interpolants have definately been set.  Now set the rest.
}
  if rend_iterps.alpha.on then begin   {alpha interpolant turned on ?}
    case rend_iterps.alpha.shmode of
rend_iterp_mode_flat_k: begin          {set alpha to flat shading}
        rend_set.iterp_flat^ (
          rend_iterp_alpha_k, (v1c.color.alpha + v2c.color.alpha)*0.5);
        end;
rend_iterp_mode_linear_k: begin        {set alpha to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_alpha_k, v1c.color.alpha, v1c.color.alpha, v2c.color.alpha);
        end;
rend_iterp_mode_quad_k: begin          {set alpha to quadratic interpolation}
        rend_set.quad_vals^ (
          rend_iterp_alpha_k,
          v1c.color.alpha, v1c.color.alpha, v2c.color.alpha,
          v2c.color.alpha, iv3_p^.cache_p^.color.alpha, iv3_p^.cache_p^.color.alpha);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting alpha interpolant}
done_rgba_iterps:                      {skip to here if RGB/alpha interpolants set}

  if rend_tmapi_p_ind >= 0 then begin  {UVW vertex field pointer turned on ?}
    with
        iv1_p^.v_p^[rend_tmapi_p_ind].tmapi_p^: uvw1, {UVW for vertex 1}
        iv2_p^.v_p^[rend_tmapi_p_ind].tmapi_p^: uvw2, {UVW for vertex 2}
        iv3_p^.v_p^[rend_tmapi_p_ind].tmapi_p^: uvw3 {UVW for vertex 3}
        do begin

  if rend_iterps.u.on then begin       {U interpolant turned on ?}
    case rend_iterps.u.shmode of
rend_iterp_mode_flat_k: begin          {set U to flat shading}
        rend_set.iterp_flat^ (
          rend_iterp_u_k, (uvw1.u + uvw2.u)*0.5);
        end;
rend_iterp_mode_linear_k: begin        {set U to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_u_k, uvw1.u, uvw1.u, uvw2.u);
        end;
rend_iterp_mode_quad_k: begin          {set U to quadratic interpolation}
        rend_set.quad_vals^ (
          rend_iterp_u_k,
          uvw1.u, uvw1.u, uvw2.u,
          uvw2.u, uvw3.u, uvw3.u);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting U interpolant}

  if rend_iterps.v.on then begin       {V interpolant turned on ?}
    case rend_iterps.v.shmode of
rend_iterp_mode_flat_k: begin          {set V to flat shading}
        rend_set.iterp_flat^ (
          rend_iterp_v_k, (uvw1.v + uvw2.v)*0.5);
        end;
rend_iterp_mode_linear_k: begin        {set V to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_v_k, uvw1.v, uvw1.v, uvw2.v);
        end;
rend_iterp_mode_quad_k: begin          {set V to quadratic interpolation}
        rend_set.quad_vals^ (
          rend_iterp_v_k,
          uvw1.v, uvw1.v, uvw2.v,
          uvw2.v, uvw3.v, uvw3.v);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting V interpolant}

      end;                             {done with UVW1, UVW2, and UVW3 abbreviations}
    end;                               {done with TMAPI_P field turned on}

  if rend_iterps.z.on then begin       {Z interpolant turned on ?}
    case rend_iterps.z.shmode of
rend_iterp_mode_flat_k: begin          {set Z to flat shading}
        rend_set.iterp_flat^ (
          rend_iterp_z_k, (v1c.z + v2c.z)*0.5);
        end;
rend_iterp_mode_linear_k,              {set Z to linear interpolation}
rend_iterp_mode_quad_k: begin
        rend_set.lin_vals^ (
          rend_iterp_z_k,
          p4z, v1c.z, v2c.z);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting Z interpolant}
    end;                               {done with V1C and V2C abbreviations}

  rend_set.cpnt_2dim^ (                {set current point to first vertex}
    v1_p^.cache_p^.x, v1_p^.cache_p^.y);
  rend_prim.vect_2dim^ (               {draw vector to second vertex}
    v2_p^.cache_p^.x, v2_p^.cache_p^.y);

  goto leave;                          {clean up and leave}
{
*   At least some part of the line segment is clipped out, but not such that a
*   trivial reject can be done.  Do the clipping and set the IV1 and IV2 pointers
*   to point to the verticies to be used as reference for the linear interpolation
*   and as the final 2DIM space vector endpoints.
}
clipped:                               {jump here if trivial clip accept fails}
  if (                                 {no clipping needed to Z limits ?}
      (rend_clmask_nz_k + rend_clmask_fz_k) & (
      lv[1].cache_p^.clip_mask !
      lv[2].cache_p^.clip_mask)) = 0 then goto done_z_clips;
{
*   At least one of the end points exceeded one of the Z clip limits.
*   Create the resulting line segment after clipping to the Z limits.  When creating
*   a new vertex at the Z clip limits, the colors and coordinates must be
*   interpolated from the existing verticies.
}
  clipping_z := true;                  {any new verts will be created due to Z clip}
{
*   Clip V1 to near Z.
}
  if (iv1_p^.cache_p^.clip_mask & rend_clmask_nz_k) <> 0 then begin
    w :=                               {weighting factor for vertex 1}
      (rend_view.zclip_near - iv2_p^.cache_p^.z3dw) /
      (iv1_p^.cache_p^.z3dw - iv2_p^.cache_p^.z3dw);
    clip_vert (iv1_p^, w, iv2_p^, iv1_p); {make replacement vertex 1}
    end;
{
*   Clip V1 to far Z.
}
  if (iv1_p^.cache_p^.clip_mask & rend_clmask_fz_k) <> 0 then begin
    w :=                               {weighting factor for vertex 1}
      (rend_view.zclip_far - iv2_p^.cache_p^.z3dw) /
      (iv1_p^.cache_p^.z3dw - iv2_p^.cache_p^.z3dw);
    clip_vert (iv1_p^, w, iv2_p^, iv1_p); {make replacement vertex 1}
    end;
{
*   Clip V2 to near Z.
}
  if (iv2_p^.cache_p^.clip_mask & rend_clmask_nz_k) <> 0 then begin
    w :=                               {weighting factor for vertex 2}
      (rend_view.zclip_near - iv1_p^.cache_p^.z3dw) /
      (iv2_p^.cache_p^.z3dw - iv1_p^.cache_p^.z3dw);
    clip_vert (iv2_p^, w, iv1_p^, iv2_p); {make replacement vertex 2}
    end;
{
*   Clip V2 to far Z.
}
  if (iv2_p^.cache_p^.clip_mask & rend_clmask_fz_k) <> 0 then begin
    w :=                               {weighting factor for vertex 2}
      (rend_view.zclip_far - iv1_p^.cache_p^.z3dw) /
      (iv2_p^.cache_p^.z3dw - iv1_p^.cache_p^.z3dw);
    clip_vert (iv2_p^, w, iv1_p^, iv2_p); {make replacement vertex 2}
    end;
done_z_clips:                          {jump here if IV1_P and IV2_P all set}
{
*   IV1_P and IV2_P point to the verticies that are to be used for calculating
*   the interpolant values later.  These pointers will no longer be touched,
*   even if the corresponding verticies are clipped off by X and Y.
}
  v1_p := iv1_p;                       {init line segment endpoint vertex pointers}
  v2_p := iv2_p;
  clipping_z := false;                 {now clipping to XY, not Z limits}
{
*   Clip to the 2DIM X limits.
}
  with
      v1_p^.cache_p^: c1,              {C1 is cache for vertex 1}
      v2_p^.cache_p^: c2               {C2 is cache for vertex 2}
      do begin
    if c1.x < clip_minx
      then c1.clip_mask := c1.clip_mask ! rend_clmask_lx_k;
    if c1.x > clip_maxx
      then c1.clip_mask := c1.clip_mask ! rend_clmask_rx_k;
    if c2.x < clip_minx
      then c2.clip_mask := c2.clip_mask ! rend_clmask_lx_k;
    if c2.x > clip_maxx
      then c2.clip_mask := c2.clip_mask ! rend_clmask_rx_k;
    if (c1.clip_mask & c2.clip_mask) <> 0 {trivial reject of whole line segment ?}
      then goto leave;
    end;                               {done with C1 and C2 abbreviations}
{
*   Clip V1 to X limits.
}
  if (v1_p^.cache_p^.clip_mask & rend_clmask_lx_k) <> 0 then begin
    w :=                               {weighting factor for this vertex}
      (clip_minx - v2_p^.cache_p^.x) /
      (v1_p^.cache_p^.x - v2_p^.cache_p^.x);
    clip_vert (v1_p^, w, v2_p^, v1_p);
    end;
  if (v1_p^.cache_p^.clip_mask & rend_clmask_rx_k) <> 0 then begin
    w :=                               {weighting factor for this vertex}
      (clip_maxx - v2_p^.cache_p^.x) /
      (v1_p^.cache_p^.x - v2_p^.cache_p^.x);
    clip_vert (v1_p^, w, v2_p^, v1_p);
    end;
{
*   Clip V2 to X limits.
}
  if (v2_p^.cache_p^.clip_mask & rend_clmask_lx_k) <> 0 then begin
    w :=                               {weighting factor for this vertex}
      (clip_minx - v1_p^.cache_p^.x) /
      (v2_p^.cache_p^.x - v1_p^.cache_p^.x);
    clip_vert (v2_p^, w, v1_p^, v2_p);
    end;
  if (v2_p^.cache_p^.clip_mask & rend_clmask_rx_k) <> 0 then begin
    w :=                               {weighting factor for this vertex}
      (clip_maxx - v1_p^.cache_p^.x) /
      (v2_p^.cache_p^.x - v1_p^.cache_p^.x);
    clip_vert (v2_p^, w, v1_p^, v2_p);
    end;
{
*   Clip to the 2DIM Y limits.
}
  with
      v1_p^.cache_p^: c1,              {C1 is cache for vertex 1}
      v2_p^.cache_p^: c2               {C2 is cache for vertex 2}
      do begin
    if c1.y < clip_miny
      then c1.clip_mask := c1.clip_mask ! rend_clmask_ty_k;
    if c1.y > clip_maxy
      then c1.clip_mask := c1.clip_mask ! rend_clmask_by_k;
    if c2.y < clip_miny
      then c2.clip_mask := c2.clip_mask ! rend_clmask_ty_k;
    if c2.y > clip_maxy
      then c2.clip_mask := c2.clip_mask ! rend_clmask_by_k;
    if (c1.clip_mask & c2.clip_mask) <> 0 {trivial reject of whole line segment ?}
      then goto leave;
    end;                               {done with C1 and C2 abbreviations}
{
*   Clip V1 to Y limits.
}
  if (v1_p^.cache_p^.clip_mask & rend_clmask_ty_k) <> 0 then begin
    w :=                               {weighting factor for this vertex}
      (clip_miny - v2_p^.cache_p^.y) /
      (v1_p^.cache_p^.y - v2_p^.cache_p^.y);
    clip_vert (v1_p^, w, v2_p^, v1_p);
    end;
  if (v1_p^.cache_p^.clip_mask & rend_clmask_by_k) <> 0 then begin
    w :=                               {weighting factor for this vertex}
      (clip_maxy - v2_p^.cache_p^.y) /
      (v1_p^.cache_p^.y - v2_p^.cache_p^.y);
    clip_vert (v1_p^, w, v2_p^, v1_p);
    end;
{
*   Clip V2 to Y limits.
}
  if (v2_p^.cache_p^.clip_mask & rend_clmask_ty_k) <> 0 then begin
    w :=                               {weighting factor for this vertex}
      (clip_miny - v1_p^.cache_p^.y) /
      (v2_p^.cache_p^.y - v1_p^.cache_p^.y);
    clip_vert (v2_p^, w, v1_p^, v2_p);
    end;
  if (v2_p^.cache_p^.clip_mask & rend_clmask_by_k) <> 0 then begin
    w :=                               {weighting factor for this vertex}
      (clip_maxy - v1_p^.cache_p^.y) /
      (v2_p^.cache_p^.y - v1_p^.cache_p^.y);
    clip_vert (v2_p^, w, v1_p^, v2_p);
    end;
{
*   IV1_P, IV2_P, V1_P, and V2_P all set.  Now jump back to common code with
*   no-clip case.
}
  goto draw_line;

leave:
  sys_mem_dealloc (local_verts_p);     {deallocate temporary vertex descriptors}
  end;
