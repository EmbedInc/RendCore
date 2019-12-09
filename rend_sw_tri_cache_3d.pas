{   Subroutine REND_SW_TRI_CACHE_3D (V1, V2, V3, CA1, CA2, CA3, GNORM)
*
*   Internal subroutine to draw a 3D space triangle.  V1-V3 are the descriptors
*   for each vertex.  CA1-CA3 are the vertex caches for each vertex.
*   The vertex cache pointers in V1-V3 should not be used.  GNORM is the
*   geometric normal vector for the triangle.  It points out from the side
*   that is to be considered the "front" face of the polygon.  When the
*   front face is viewed, the verticies appear in a counter-clockwise order
*   from V1 to V2 to V3.
*
*   This internal routine does most of the "work" related to a 3D triangle.
*   It may be called from several different external primitives once
*   appropriate vertex caches have either been found or created.
*
*   This is the default version that handles all cases.
}
module rend_sw_tri_cache_3d;
define rend_sw_tri_cache_3d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_tri_cache_3d_d.ins.pas';

procedure rend_sw_tri_cache_3d (       {3D triangle, explicit caches for each vert}
  in      v1, v2, v3: univ rend_vert3d_t; {descriptor for each vertex}
  in out  ca1, ca2, ca3: rend_vcache_t; {explicit cache for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  val_param;

type
  tri_entry_p_t =                      {pointer to a local TRI array entry, below}
    ^tri_entry_t;

  tri_entry_t = record                 {template for one entry of local TRI array}
    cache_p: rend_vcache_p_t;          {pointer to cache for this vertex}
    v_p: rend_vert3d_p_t;              {pointer to call argument V1-V3}
    lastv_p: tri_entry_p_t;            {pointer to previous vertex (in TRI array)}
    nextv_p: tri_entry_p_t;            {pointer to next vertex (in TRI array)}
    end;

var
  view_front: boolean;                 {TRUE if viewing front side of polygon}
  flip_order: boolean;                 {TRUE if reverse vertex order for final draw}
  clipping_z: boolean;                 {TRUE if doing Z clips instead of XY clips}
  flip_factor: real;                   {-1.0 if flip normals, 1.0 otherwise}
  gnorm3dw: vect_3d_t;                 {geometric normal vector in 3DW space}
  gnorm_mag2: real;                    {gnorm magnitude squared in 3DW space}
  nv, nv2: vect_3d_t;                  {scratch unit normal vectors for lighting}
  nv_p: vect_3d_p_t;
  w: real;                             {scratch scale factor}
  tri:                                 {local copy of some info per vertex}
    array[1..18] of tri_entry_t;
  local_caches:                        {vertex caches for implicit verticies}
    array[4..18] of rend_vcache_t;
  local_verts_p: rend_vert3d_p_t;      {points to first dynamically allocated vertex}
  next_vert_p: rend_vert3d_p_t;        {points to next free vertex descriptor to use}
  local_uvw:                           {UVW buffers for locally created verticies}
    array[4..18] of rend_uvw_t;
  local_col:                           {RGBA values for locally created verticies}
    array[4..18] of rend_rgba_t;
  nextv: sys_int_machine_t;            {next avail vert num in TRI and LOCAL_CACHES}
  sp: rend_suprop_p_t;                 {pointer to applicable surf prop block}
  iv1_p, iv2_p, iv3_p,                 {pointers to verticies for linear interp vals}
  iv4_p, iv5_p, iv6_p:                 {extra pointers for quadratic surface geom}
    tri_entry_p_t;
  poly:                                {final 2DIM space polygon XY coordinates}
    array[1..9] of vect_2d_t;
  nverts: sys_int_machine_t;           {number of verticies in POLY array}
  startv_p: tri_entry_p_t;             {pointer to poly start vertex for looping}
  lastv_p: tri_entry_p_t;              {pointer to last poly vertex for looping}
  pc: tri_entry_p_t;                   {pointer to current vertex being clipped}
  po: tri_entry_p_t;                   {pointer to other vertex being clipped}
  clip_minx: real;                     {coordinates of clip rectangle}
  clip_maxx: real;
  clip_miny: real;
  clip_maxy: real;
  i: sys_int_machine_t;                {scratch integer and loop counter}
  did_lastv: boolean;                  {TRUE if processed last poly vert for clipping}
  made_vert: boolean;                  {TRUE if MAKE_NEW_VERT actually made a vertex}
  flip_shad: boolean;                  {TRUE if flip shading normal vectors}
  gnorm_nready: boolean;               {TRUE if GNORM3DW not yet ready for shading}
  c1, c2, c3, c4, c5, c6: vect_2d_t;   {coordinates of points used for interpolation}

label
  use_gnorm_v1, got_shnorm_v1,
  use_gnorm_v2, got_shnorm_v2,
  use_gnorm_v3, got_shnorm_v3,
  draw_poly, done_rgba_iterps, clipped, no_z_clips, next_z_clip_vertex,
  got_iv2, got_iv3, do_xy_clips, next_clip_minx, next_clip_maxx,
  next_clip_miny, next_clip_maxy, leave;
{
***************************************************************
*
*   Local subroutine INTERPOLATE_VERT (V1, W1, V2, W2, V)
*
*   Interpolate the values of the verticies V1 and V2 into the vertex V.
*   W1 is the fractional contribution from V1, and W2 is the  fractional
*   contribution from V2.  It is assumed that the 3D world space information
*   in the input vertex caches is up to date.  The verticies V1, V2, and V are
*   internal vertex descriptors.  The information will be interpolated in the
*   3D world space, and then used to re-compute the 2DIM space coordinates and color
*   values.
}
procedure interpolate_vert (           {interpolate vertex between two others}
  in      v1: tri_entry_t;             {first input vertex}
  in      w1: real;                    {fractional contribution from first vertex}
  in      v2: tri_entry_t;             {second input vertex}
  in      w2: real;                    {fractional contribution from second vertex}
  in out  v: tri_entry_t);             {output vertex}
  val_param;

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
      w1*v1.v_p^[rend_tmapi_p_ind].tmapi_p^.u +
      w2*v2.v_p^[rend_tmapi_p_ind].tmapi_p^.u;
    end;
  if rend_iterps.v.on then begin
    v.v_p^[rend_tmapi_p_ind].tmapi_p^.v := {make interpolated V coordinate}
      w1*v1.v_p^[rend_tmapi_p_ind].tmapi_p^.v +
      w2*v2.v_p^[rend_tmapi_p_ind].tmapi_p^.v;
    end;
{
*   Interpolate the object diffuse color at this new coordinate.  For each source
*   vertex, the object diffuse color may be given explicitly, or come from the
*   surface properties block.  The resulting diffuse color is set as an explicit
*   color for the new vertex.
}
  if rend_diff_p_ind >= 0 then begin   {diffuse color pointers enabled ?}
    if v1.v_p^[rend_diff_p_ind].diff_p = nil
      then begin                       {diffuse color comes from suprop block}
        red := sp^.diff.red*w1;
        grn := sp^.diff.grn*w1;
        blu := sp^.diff.blu*w1;
        alpha := w1;
        end
      else begin                       {diffuse explicitly given in vertex}
        red := v1.v_p^[rend_diff_p_ind].diff_p^.red*w1;
        grn := v1.v_p^[rend_diff_p_ind].diff_p^.grn*w1;
        blu := v1.v_p^[rend_diff_p_ind].diff_p^.blu*w1;
        alpha := v1.v_p^[rend_diff_p_ind].diff_p^.alpha*w1;
        end
      ;
    if v2.v_p^[rend_diff_p_ind].diff_p = nil
      then begin                       {diffuse color comes from suprop block}
        v.v_p^[rend_diff_p_ind].diff_p^.red := red + sp^.diff.red*w2;
        v.v_p^[rend_diff_p_ind].diff_p^.grn := grn + sp^.diff.grn*w2;
        v.v_p^[rend_diff_p_ind].diff_p^.blu := blu + sp^.diff.blu*w2;
        v.v_p^[rend_diff_p_ind].diff_p^.alpha := alpha + w2;
        end
      else begin                       {diffuse explicitly given in vertex}
        v.v_p^[rend_diff_p_ind].diff_p^.red := red +
          v2.v_p^[rend_diff_p_ind].diff_p^.red*w2;
        v.v_p^[rend_diff_p_ind].diff_p^.grn := grn +
          v2.v_p^[rend_diff_p_ind].diff_p^.grn*w2;
        v.v_p^[rend_diff_p_ind].diff_p^.blu := blu +
          v2.v_p^[rend_diff_p_ind].diff_p^.blu*w2;
        v.v_p^[rend_diff_p_ind].diff_p^.alpha := alpha +
          v2.v_p^[rend_diff_p_ind].diff_p^.alpha*w2;
        end
      ;
    end;
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
***************************************************************
*
*   Local subroutine MAKE_NEW_SHADING_VERT (V1,V2,P)
*
*   Create a new vertex, and fill in by interpolating half way between vertex
*   V1 and V2.  P is the returned pointer to the newly created vertex.  The 3D
*   world space coordinates are interpolated, and then used to find the 2D
*   coordinates and color values.  V1 and V2 are internal vertex descriptors, and
*   P will point to an internal vertex descriptor.
}
procedure make_new_shading_vert (
  in      v1: tri_entry_t;             {first input vertex}
  in      v2: tri_entry_t;             {second input vertex}
  out     p: tri_entry_p_t);           {returned pointer to output vertex}
  val_param;

begin
  p := addr(tri[nextv]);               {make pointer to new vertex}
  p^.cache_p := addr(local_caches[nextv]); {set pointer to cache for this vertex}
  p^.v_p := next_vert_p;               {set pointer to top level vertex descriptor}
  next_vert_p := univ_ptr(             {point to next free local vert}
    sys_int_adr_t(next_vert_p) + rend_vert3d_bytes);
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
***************************************************************
*
*   Local subroutine MAKE_NEW_VERT
*
*   Create a new vertex in the linked list polygon.  PC and PO are pointing to the
*   two verticies between which a new vertex is to be created.  W is set to the
*   fractional contribution of PC to the new vertex.  NEXTV is the number of the
*   next available slot in the TRI, LOCAL_CACHES, and LOCAL_VERTS array.
*   CLIPPING_Z is set to TRUE if the new vertex is a result of clipping to one of
*   the Z clip limits.
}
procedure make_new_vert;

var
  wo: real;                            {contribution of the PO vertex to the new one}
  p: tri_entry_p_t;                    {pointer to new polygon vertex}
  f: real;                             {perspective mult factor}

begin
  made_vert := false;                  {init to no new vertex created here}
  if w < 1.0E-8 then return;           {trying to create a duplicate vertex ?}
  made_vert := true;                   {we will now definately create new vertex}
  p := addr(tri[nextv]);               {make pointer to new vertex}
  p^.cache_p := addr(local_caches[nextv]); {set pointer to cache for this vertex}
  if po = pc^.lastv_p                  {check for which direction PC,PO are linked}
    then begin                         {PO is the vertex before PC}
      p^.lastv_p := po;                {link new vertex into linked list}
      p^.nextv_p := pc;
      po^.nextv_p := p;
      pc^.lastv_p := p;
      end
    else begin                         {PO is the vertex after PC}
      p^.nextv_p := po;                {link new vertex into linked list}
      p^.lastv_p := pc;
      po^.lastv_p := p;
      pc^.nextv_p := p;
      end
    ;                                  {done linking new vertex into linked list}
  wo := 1.0-w;                         {make contribution fraction from PO vertex}
  with
      pc^.cache_p^: cc,                {CC is cache for current vertex}
      po^.cache_p^: co,                {CO is cache for "other" vertex}
      p^.cache_p^: c                   {C is cache for new vertex}
      do begin
  if clipping_z                        {clipping in Z or XY ?}
    then begin                         {new vertex is result of Z clip}
      p^.v_p := next_vert_p;           {set pointer to top level vertex descriptor}
      next_vert_p := univ_ptr(         {point to next free local vert}
        sys_int_adr_t(next_vert_p) + rend_vert3d_bytes);
      if rend_tmapi_p_ind >= 0 then begin
        p^.v_p^[rend_tmapi_p_ind].tmapi_p := {set pointer to texture index coor}
          addr(local_uvw[nextv]);
        end;
      c.clip_mask := 0;
      if rend_shade_geom >= rend_iterp_mode_quad_k
        then begin                     {we are creating geometry for quad shading}
          if rend_diff_p_ind >= 0 then begin
             p^.v_p^[rend_diff_p_ind].diff_p := {set pointer to diffuse colors}
               addr(local_col[nextv]);
             end;
          interpolate_vert (           {fill in new vertex}
            pc^, w,                    {first input vertex and fraction}
            po^, wo,                   {second input vertex and fraction}
            p^);                       {output vertex to fill in}
          end                          {done with creating quad geometry case}
        else begin                     {we are creating geometry for linear shading}
          c.x3dw := w*cc.x3dw + wo*co.x3dw; {interpolate 3DW coordinates}
          c.y3dw := w*cc.y3dw + wo*co.y3dw;
          c.z3dw := w*cc.z3dw + wo*co.z3dw;
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
              w*pc^.v_p^[rend_tmapi_p_ind].tmapi_p^.u + wo*po^.v_p^[rend_tmapi_p_ind].tmapi_p^.u;
            end;
          if rend_iterps.v.on then begin
            p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v := {make interpolated V coordinate}
              w*pc^.v_p^[rend_tmapi_p_ind].tmapi_p^.v + wo*po^.v_p^[rend_tmapi_p_ind].tmapi_p^.v;
            end;
          c.color.red := w*cc.color.red + wo*co.color.red;
          c.color.grn := w*cc.color.grn + wo*co.color.grn;
          c.color.blu := w*cc.color.blu + wo*co.color.blu;
          c.color.alpha := w*cc.color.alpha + wo*co.color.alpha;
          end                          {done with creating linear geometry case}
        ;                              {done handling shade geometry setting}
      end                              {done with new vertex is due to Z clip}
    else begin                         {new vertex is result of X or Y clip}
      c.x := w*cc.x + wo*co.x;         {interpolate X coordinate}
      c.y := w*cc.y + wo*co.y;         {interpolate Y coordinate}
      end
    ;                                  {done checking reason for new vertex}
  end;                                 {done with CC, CO, and C abbreviations}
  nextv := nextv + 1;                  {update index to next set of free entries}
  nverts := nverts + 1;                {log one more vertex in polygon}
  end;
{
***************************************************************
*
*   Local subroutine DELETE_VERTEX
*
*   Remove the current vertex from the linked list of verticies.  If the current
*   vertex is also the one pointed to by STARTV_P, then move STARTV_P to point
*   to the previous vertex.  PC is pointing to the current vertex.
}
procedure delete_vertex;

begin
  pc^.lastv_p^.nextv_p := pc^.nextv_p; {unlink this vertex from linked list}
  pc^.nextv_p^.lastv_p := pc^.lastv_p;
  nverts := nverts-1;                  {one fewer vertex in polygon}
  if startv_p = pc
    then startv_p := pc^.lastv_p;
  end;
{
***************************************************************
*
*   Start main routine.
}
begin
{
*   Transform the geometric normal to the 3D world coordinate space.  It will be
*   used later in the backface determination.  It may also be used as a
*   substitute shading normal vector.
}
  gnorm3dw.x :=                        {transform geometric normal to world space}
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
  gnorm_mag2 := sqr(gnorm3dw.x) + sqr(gnorm3dw.y) + sqr(gnorm3dw.z);
  if gnorm_mag2 < 1.0E-35 then return; {geometric normal unuseably small ?}
{
****************************************
*
*   Make sure the geometric info for each of the caches is up to date.
*   Interpolant values will be calculated later after backface and clip
*   checks are performed.
*
*   Fill in the vertex 1 cache.
*   The backface check will be done part way thru filling in this first
*   cache.
}
  if ca1.version <> rend_cache_version then begin {cache info invalid ?}
    with
        v1[rend_coor_p_ind].coor_p^: mc {MC is abbrev for 3D model space coordinate}
        do begin
      ca1.x3dw :=                      {make 3D world space coor for vertex 1}
        mc.x*rend_xf3d.xb.x +
        mc.y*rend_xf3d.yb.x +
        mc.z*rend_xf3d.zb.x +
        rend_xf3d.ofs.x;
      ca1.y3dw :=
        mc.x*rend_xf3d.xb.y +
        mc.y*rend_xf3d.yb.y +
        mc.z*rend_xf3d.zb.y +
        rend_xf3d.ofs.y;
      ca1.z3dw :=
        mc.x*rend_xf3d.xb.z +
        mc.y*rend_xf3d.yb.z +
        mc.z*rend_xf3d.zb.z +
        rend_xf3d.ofs.z;
      end;                             {done with MC abbreviation}
    end;                               {3D world space coor now definately valid}
{
*   Use the partial information available for vertex 1 to do the backface
*   determination.
}
  if rend_view.perspec_on
    then begin                         {perspective ON, make our own eye vector}
      w :=
        (                   -ca1.x3dw  * gnorm3dw.x) +
        (                   -ca1.y3dw  * gnorm3dw.y) +
        ((rend_view.eyedis - ca1.z3dw) * gnorm3dw.z);
      end
    else begin                         {perspective OFF, eye vector is 0,0,1}
      w := gnorm3dw.z;
      end
    ;                                  {W is now the eye-facing dot product}
  view_front := w >= 0.0;              {TRUE if we are seeing front face of tri}
  case rend_view.backface of           {what kind of backfacing is selected ?}

rend_bface_off_k: begin                {draw polygon "as is"}
      flip_factor := 1.0;              {do not flip shading normals}
      flip_shad := false;              {don't flip shading normals for light eval}
      sp := addr(rend_face_front);     {select suprop block to use}
      end;

rend_bface_front_k: begin              {draw only if front face is showing}
      if not view_front then return;   {front face is not showing ?}
      flip_factor := 1.0;              {do not flip shading normals}
      flip_shad := false;              {don't flip shading normals for light eval}
      sp := addr(rend_face_front);     {select suprop block to use}
      end;

rend_bface_back_k: begin               {draw only if back face showing}
      if view_front then return;
      flip_factor := -1.0;             {flip shading normals before use}
      flip_shad := true;
      if rend_face_back.on             {select suprop block to use}
        then sp := addr(rend_face_back)
        else sp := addr(rend_face_front);
      end;

rend_bface_flip_k: begin               {draw front and back as separate surfaces}
      if view_front
        then begin                     {we are looking at the front face}
          flip_factor := 1.0;          {do not flip shading normals}
          flip_shad := false;          {don't flip shading normals for light eval}
          sp := addr(rend_face_front);
          end
        else begin                     {we are looking at the back face}
          flip_factor := -1.0;         {flip shading normals before use}
          flip_shad := true;
          if rend_face_back.on
            then sp := addr(rend_face_back)
            else sp := addr(rend_face_front);
          end
        ;
      end;

    end;                               {end of backfacing type cases}
{
*   Done doing backfacing rejection.  FLIP_FACTOR, FLIP_SHAD, and SP
*   are all set.  FLIP_SHAD is TRUE if the shading normal vectors must
*   be flipped before the lighting evaluation.  FLIP_FACTOR is either
*   1.0 or -1.0, and can be used as a multiplier for the shading normal
*   vectors.  SP points to the surface properties block to use for the
*   lighting evaluation.
*
*   Continue filling cache for vertex 1.
}
  clip_minx := rend_clip_2dim.xmin;    {make local copy of 2DIM clip rectangle}
  clip_maxx := rend_clip_2dim.xmax;
  clip_miny := rend_clip_2dim.ymin;
  clip_maxy := rend_clip_2dim.ymax;

  if ca1.version <> rend_cache_version then begin {cache info needs updating ?}
    ca1.clip_mask := 0;                {init to inside all clip limits}
    if ca1.z3dw > rend_view.zclip_near {in front of near Z limit ?}
      then ca1.clip_mask := rend_clmask_nz_k;
    if ca1.z3dw < rend_view.zclip_far  {behind far Z limit ?}
      then ca1.clip_mask := rend_clmask_fz_k;
    if ca1.clip_mask = 0 then begin    {OK to transform to 2D space ?}
      if rend_view.perspec_on          {check perspective on/off flag}
        then begin                     {perspective is on}
          w := rend_view.eyedis / (rend_view.eyedis - ca1.z3dw);
          ca1.x :=
            w*(ca1.x3dw*rend_2d.sp.xb.x + ca1.y3dw*rend_2d.sp.yb.x) +
            rend_2d.sp.ofs.x;
          ca1.y :=
            w*(ca1.x3dw*rend_2d.sp.xb.y + ca1.y3dw*rend_2d.sp.yb.y) +
            rend_2d.sp.ofs.y;
          ca1.z :=                     {Z interpolant value at this vertex}
            ca1.z3dw*w*rend_view.zmult + rend_view.zadd;
          end
        else begin                     {perspective is turned off}
          ca1.x :=
            ca1.x3dw*rend_2d.sp.xb.x + ca1.y3dw*rend_2d.sp.yb.x +
            rend_2d.sp.ofs.x;
          ca1.y :=
            ca1.x3dw*rend_2d.sp.xb.y + ca1.y3dw*rend_2d.sp.yb.y +
            rend_2d.sp.ofs.y;
          ca1.z :=                     {Z interpolant value at this vertex}
            ca1.z3dw*rend_view.zmult + rend_view.zadd;
          end
        ;                              {done handling perspective on/off}
      if ca1.y < clip_miny             {find and save 2D clip status}
        then ca1.clip_mask := ca1.clip_mask + rend_clmask_ty_k;
      if ca1.y > clip_maxy
        then ca1.clip_mask := ca1.clip_mask + rend_clmask_by_k;
      if ca1.x < clip_minx
        then ca1.clip_mask := ca1.clip_mask + rend_clmask_lx_k;
      if ca1.x > clip_maxx
        then ca1.clip_mask := ca1.clip_mask + rend_clmask_rx_k;
      end;                             {done transforming to 2DIM space}
    ca1.version := rend_cache_version; {indicate cache now contains valid data}
    ca1.colors_valid := false;         {indicate colors not yet updated}
    end;                               {done with cache version was not valid}
{
*   Fill cache for vertex 2.
}
  if ca2.version <> rend_cache_version then begin {cache info invalid ?}
    with
        v2[rend_coor_p_ind].coor_p^: mc {MC is abbrev for 3D model space coordinate}
        do begin
      ca2.x3dw :=                      {make 3D world space coor for this vertex}
        mc.x*rend_xf3d.xb.x +
        mc.y*rend_xf3d.yb.x +
        mc.z*rend_xf3d.zb.x +
        rend_xf3d.ofs.x;
      ca2.y3dw :=
        mc.x*rend_xf3d.xb.y +
        mc.y*rend_xf3d.yb.y +
        mc.z*rend_xf3d.zb.y +
        rend_xf3d.ofs.y;
      ca2.z3dw :=
        mc.x*rend_xf3d.xb.z +
        mc.y*rend_xf3d.yb.z +
        mc.z*rend_xf3d.zb.z +
        rend_xf3d.ofs.z;
      end;                             {done with MC abbreviation}
    ca2.clip_mask := 0;                {init to inside all clip limits}
    if ca2.z3dw > rend_view.zclip_near {in front of near Z limit ?}
      then ca2.clip_mask := rend_clmask_nz_k;
    if ca2.z3dw < rend_view.zclip_far  {behind far Z limit ?}
      then ca2.clip_mask := rend_clmask_fz_k;
    if ca2.clip_mask = 0 then begin    {OK to transform to 2D space ?}
      if rend_view.perspec_on          {check perspective on/off flag}
        then begin                     {perspective is on}
          w := rend_view.eyedis/(rend_view.eyedis-ca2.z3dw);
          ca2.x :=
            w*(ca2.x3dw*rend_2d.sp.xb.x + ca2.y3dw*rend_2d.sp.yb.x) +
            rend_2d.sp.ofs.x;
          ca2.y :=
            w*(ca2.x3dw*rend_2d.sp.xb.y + ca2.y3dw*rend_2d.sp.yb.y) +
            rend_2d.sp.ofs.y;
          ca2.z :=                     {Z interpolant value at this vertex}
            ca2.z3dw*w*rend_view.zmult + rend_view.zadd;
          end
        else begin                     {perspective is turned off}
          ca2.x :=
            ca2.x3dw*rend_2d.sp.xb.x + ca2.y3dw*rend_2d.sp.yb.x +
            rend_2d.sp.ofs.x;
          ca2.y :=
            ca2.x3dw*rend_2d.sp.xb.y + ca2.y3dw*rend_2d.sp.yb.y +
            rend_2d.sp.ofs.y;
          ca2.z :=                     {Z interpolant value at this vertex}
            ca2.z3dw*rend_view.zmult + rend_view.zadd;
          end
        ;                              {done handling perspective on/off}
      if ca2.y < clip_miny             {find and save 2D clip status}
        then ca2.clip_mask := ca2.clip_mask + rend_clmask_ty_k;
      if ca2.y > clip_maxy
        then ca2.clip_mask := ca2.clip_mask + rend_clmask_by_k;
      if ca2.x < clip_minx
        then ca2.clip_mask := ca2.clip_mask + rend_clmask_lx_k;
      if ca2.x > clip_maxx
        then ca2.clip_mask := ca2.clip_mask + rend_clmask_rx_k;
      end;                             {done transforming to 2DIM space}
    ca2.version := rend_cache_version; {indicate cache now contains valid data}
    ca2.colors_valid := false;         {indicate colors not yet updated}
    end;                               {done with cache version was not valid}
{
*   Fill cache for vertex 3.
}
  if ca3.version <> rend_cache_version then begin {cache info invalid ?}
    with
        v3[rend_coor_p_ind].coor_p^: mc {MC is abbrev for 3D model space coordinate}
        do begin
      ca3.x3dw :=                      {make 3D world space coor for this vertex}
        mc.x*rend_xf3d.xb.x +
        mc.y*rend_xf3d.yb.x +
        mc.z*rend_xf3d.zb.x +
        rend_xf3d.ofs.x;
      ca3.y3dw :=
        mc.x*rend_xf3d.xb.y +
        mc.y*rend_xf3d.yb.y +
        mc.z*rend_xf3d.zb.y +
        rend_xf3d.ofs.y;
      ca3.z3dw :=
        mc.x*rend_xf3d.xb.z +
        mc.y*rend_xf3d.yb.z +
        mc.z*rend_xf3d.zb.z +
        rend_xf3d.ofs.z;
      end;                             {done with MC abbreviation}
    ca3.clip_mask := 0;                {init to inside all clip limits}
    if ca3.z3dw > rend_view.zclip_near {in front of near Z limit ?}
      then ca3.clip_mask := rend_clmask_nz_k;
    if ca3.z3dw < rend_view.zclip_far  {behind far Z limit ?}
      then ca3.clip_mask := rend_clmask_fz_k;
    if ca3.clip_mask = 0 then begin    {OK to transform to 2D space ?}
      if rend_view.perspec_on          {check perspective on/off flag}
        then begin                     {perspective is on}
          w := rend_view.eyedis/(rend_view.eyedis-ca3.z3dw);
          ca3.x :=
            w*(ca3.x3dw*rend_2d.sp.xb.x + ca3.y3dw*rend_2d.sp.yb.x) +
            rend_2d.sp.ofs.x;
          ca3.y :=
            w*(ca3.x3dw*rend_2d.sp.xb.y + ca3.y3dw*rend_2d.sp.yb.y) +
            rend_2d.sp.ofs.y;
          ca3.z :=                     {Z interpolant value at this vertex}
            ca3.z3dw*w*rend_view.zmult + rend_view.zadd;
          end
        else begin                     {perspective is turned off}
          ca3.x :=
            ca3.x3dw*rend_2d.sp.xb.x + ca3.y3dw*rend_2d.sp.yb.x +
            rend_2d.sp.ofs.x;
          ca3.y :=
            ca3.x3dw*rend_2d.sp.xb.y + ca3.y3dw*rend_2d.sp.yb.y +
            rend_2d.sp.ofs.y;
          ca3.z :=                     {Z interpolant value at this vertex}
            ca3.z3dw*rend_view.zmult + rend_view.zadd;
          end
        ;                              {done handling perspective on/off}
      if ca3.y < clip_miny             {find and save 2D clip status}
        then ca3.clip_mask := ca3.clip_mask + rend_clmask_ty_k;
      if ca3.y > clip_maxy
        then ca3.clip_mask := ca3.clip_mask + rend_clmask_by_k;
      if ca3.x < clip_minx
        then ca3.clip_mask := ca3.clip_mask + rend_clmask_lx_k;
      if ca3.x > clip_maxx
        then ca3.clip_mask := ca3.clip_mask + rend_clmask_rx_k;
      end;                             {done transforming to 2DIM space}
    ca3.version := rend_cache_version; {indicate cache now contains valid data}
    ca3.colors_valid := false;         {indicate colors not yet updated}
    end;                               {done with cache version was not valid}
{
*   The geometric information in the cache for each vertex is definately
*   up to date.  This means that the 3DW space coordinate and clip flags
*   are valid.  If the vertex was not clipped out by Z, then the 2DIM space
*   coordinates and clip flags are also valid.
*
*   Now check whether the entire triangle is clipped off.
}
  if                                   {do trivial clip reject test}
    (ca1.clip_mask & ca2.clip_mask & ca3.clip_mask) <> 0
    then return;
{
*   The trivial clip reject test failed.  It is now reasonable to assume that
*   something will be drawn, and it is time to make sure the color and other
*   interpolant information is up to date.
}
  gnorm_nready := true;                {GNORM3DW not yet ready as shading normal}

  nextv := 4;                          {init next vertex number to allocate}
  sys_mem_alloc (rend_vert3d_bytes*15, local_verts_p); {grab mem for temp verts}
  if local_verts_p = nil then begin
    sys_message_bomb ('sys', 'no_mem', nil, 0);
    end;
  next_vert_p := local_verts_p;        {init pointer to next free local vertex}
{
*   Fill in interpolants for vertex 1.
}
  if                                   {need to recompute final colors here ?}
      (not ca1.colors_valid) or        {colors flagged as invalid ?}
      (ca1.flip_shad <> flip_shad)     {normal flipped differently ?}
      then begin
    if  (rend_norm_p_ind >= 0) and then {shading normal explicitly given ?}
        (v1[rend_norm_p_ind].norm_p <> nil)
        then begin
      nv2.x := v1[rend_norm_p_ind].norm_p^.x;
      nv2.y := v1[rend_norm_p_ind].norm_p^.y;
      nv2.z := v1[rend_norm_p_ind].norm_p^.z;
      end
    else if (rend_ncache_p_ind >= 0) and then {try looking in normal vector cache}
        (v1[rend_ncache_p_ind].ncache_p <> nil) and then
        (v1[rend_ncache_p_ind].ncache_p^.flags.version = rend_ncache_flags.version)
        then begin
      nv2.x := v1[rend_ncache_p_ind].ncache_p^.norm.x;
      nv2.y := v1[rend_ncache_p_ind].ncache_p^.norm.y;
      nv2.z := v1[rend_ncache_p_ind].ncache_p^.norm.z;
      end
    else if (rend_spokes_p_ind >= 0) and then {try computing normal from spokes list}
        (v1[rend_spokes_p_ind].spokes_p <> nil)
        then begin
      rend_spokes_to_norm (v1, false, nv2); {make shading normal in NV2}
      end
    else begin                         {no shading normal, use geometric normal}
use_gnorm_v1:                          {using geometric normal for shading}
      if gnorm_nready then begin       {GNORM3DW not ready yet as shading normal ?}
        w := flip_factor / sqrt(gnorm_mag2); {scale factor for unitizing gnorm}
        gnorm3dw.x := gnorm3dw.x * w;
        gnorm3dw.y := gnorm3dw.y * w;
        gnorm3dw.z := gnorm3dw.z * w;
        gnorm_nready := false;         {indicate GNORM3DW now all set}
        end;
      nv_p := addr(gnorm3dw);
      ca1.colors_valid := false;       {colors will not be reusable}
      goto got_shnorm_v1;              {NV_P points to final shading normal}
      end
      ;
    nv.x :=                            {make 3D world space shading normal vector}
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
    w := sqr(nv.x) + sqr(nv.y) + sqr(nv.z); {raw shade normal magnitude squared}
    if w < 1.0E-30
      then begin                       {shading normal unuseable, use geometric norm}
        goto use_gnorm_v1;
        end
      else begin                       {shading normal is big enough to use}
        w := flip_factor / sqrt(w);    {make scale factor for unitizing NV}
        nv.x := w*nv.x;
        nv.y := w*nv.y;
        nv.z := w*nv.z;
        nv_p := addr(nv);              {point to shading normal}
        ca1.colors_valid := true;      {colors will be reusable}
        end
      ;
got_shnorm_v1:                         {NV_P points 3DW space shading unit normal}
    rend_get.light_eval^ (             {evaluate visible color at this vertex}
      v1,                              {vertex to evaluate colors at}
      ca1,                             {cache block for this vertex}
      nv_p^,                           {normal vector at this point}
      sp^);                            {suprop block to use for surface properties}
    ca1.flip_shad := flip_shad;        {save whether used flipped normal or not}
    end;                               {done handling cached colors wern't valid}
{
*   Fill in interpolants for vertex 2.
}
  if                                   {need to recompute final colors here ?}
      (not ca2.colors_valid) or        {colors flagged as invalid ?}
      (ca2.flip_shad <> flip_shad)     {normal flipped differently ?}
      then begin
    if  (rend_norm_p_ind >= 0) and then {shading normal explicitly given ?}
        (v2[rend_norm_p_ind].norm_p <> nil)
        then begin
      nv2.x := v2[rend_norm_p_ind].norm_p^.x;
      nv2.y := v2[rend_norm_p_ind].norm_p^.y;
      nv2.z := v2[rend_norm_p_ind].norm_p^.z;
      end
    else if (rend_ncache_p_ind >= 0) and then {try looking in normal vector cache}
        (v2[rend_ncache_p_ind].ncache_p <> nil) and then
        (v2[rend_ncache_p_ind].ncache_p^.flags.version = rend_ncache_flags.version)
        then begin
      nv2.x := v2[rend_ncache_p_ind].ncache_p^.norm.x;
      nv2.y := v2[rend_ncache_p_ind].ncache_p^.norm.y;
      nv2.z := v2[rend_ncache_p_ind].ncache_p^.norm.z;
      end
    else if (rend_spokes_p_ind >= 0) and then {try computing normal from spokes list}
        (v2[rend_spokes_p_ind].spokes_p <> nil)
        then begin
      rend_spokes_to_norm (v2, false, nv2); {make shading normal in NV2}
      end
    else begin                         {no shading normal, use geometric normal}
use_gnorm_v2:                          {using geometric normal for shading}
      if gnorm_nready then begin       {GNORM3DW not ready yet as shading normal ?}
        w := flip_factor / sqrt(gnorm_mag2); {scale factor for unitizing gnorm}
        gnorm3dw.x := gnorm3dw.x * w;
        gnorm3dw.y := gnorm3dw.y * w;
        gnorm3dw.z := gnorm3dw.z * w;
        gnorm_nready := false;         {indicate GNORM3DW now all set}
        end;
      nv_p := addr(gnorm3dw);
      ca2.colors_valid := false;       {colors will not be reusable}
      goto got_shnorm_v2;              {NV_P points to final shading normal}
      end
      ;
    nv.x :=                            {make 3D world space shading normal vector}
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
    w := sqr(nv.x) + sqr(nv.y) + sqr(nv.z); {raw shade normal magnitude squared}
    if w < 1.0E-30
      then begin                       {shading normal unuseable, use geometric norm}
        goto use_gnorm_v2;
        end
      else begin                       {shading normal is big enough to use}
        w := flip_factor / sqrt(w);    {make scale factor for unitizing NV}
        nv.x := w*nv.x;
        nv.y := w*nv.y;
        nv.z := w*nv.z;
        nv_p := addr(nv);              {point to shading normal}
        ca2.colors_valid := true;      {colors will be reusable}
        end
      ;
got_shnorm_v2:                         {NV_P points 3DW space shading unit normal}
    rend_get.light_eval^ (             {evaluate visible color at this vertex}
      v2,                              {vertex to evaluate colors at}
      ca2,                             {cache block for this vertex}
      nv_p^,                           {normal vector at this point}
      sp^);                            {suprop block to use for surface properties}
    ca2.flip_shad := flip_shad;        {save whether used flipped normal or not}
    end;                               {done handling cached colors wern't valid}
{
*   Fill in interpolants for vertex 3.
}
  if                                   {need to recompute final colors here ?}
      (not ca3.colors_valid) or        {colors flagged as invalid ?}
      (ca3.flip_shad <> flip_shad)     {normal flipped differently ?}
      then begin
    if  (rend_norm_p_ind >= 0) and then {shading normal explicitly given ?}
        (v3[rend_norm_p_ind].norm_p <> nil)
        then begin
      nv2.x := v3[rend_norm_p_ind].norm_p^.x;
      nv2.y := v3[rend_norm_p_ind].norm_p^.y;
      nv2.z := v3[rend_norm_p_ind].norm_p^.z;
      end
    else if (rend_ncache_p_ind >= 0) and then {try looking in normal vector cache}
        (v3[rend_ncache_p_ind].ncache_p <> nil) and then
        (v3[rend_ncache_p_ind].ncache_p^.flags.version = rend_ncache_flags.version)
        then begin
      nv2.x := v3[rend_ncache_p_ind].ncache_p^.norm.x;
      nv2.y := v3[rend_ncache_p_ind].ncache_p^.norm.y;
      nv2.z := v3[rend_ncache_p_ind].ncache_p^.norm.z;
      end
    else if (rend_spokes_p_ind >= 0) and then {try computing normal from spokes list}
        (v3[rend_spokes_p_ind].spokes_p <> nil)
        then begin
      rend_spokes_to_norm (v3, false, nv2); {make shading normal in NV2}
      end
    else begin                         {no shading normal, use geometric normal}
use_gnorm_v3:                          {using geometric normal for shading}
      if gnorm_nready then begin       {GNORM3DW not ready yet as shading normal ?}
        w := flip_factor / sqrt(gnorm_mag2); {scale factor for unitizing gnorm}
        gnorm3dw.x := gnorm3dw.x * w;
        gnorm3dw.y := gnorm3dw.y * w;
        gnorm3dw.z := gnorm3dw.z * w;
        gnorm_nready := false;         {indicate GNORM3DW now all set}
        end;
      nv_p := addr(gnorm3dw);
      ca3.colors_valid := false;       {colors will not be reusable}
      goto got_shnorm_v3;              {NV_P points to final shading normal}
      end
      ;
    nv.x :=                            {make 3D world space shading normal vector}
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
    w := sqr(nv.x) + sqr(nv.y) + sqr(nv.z); {raw shade normal magnitude squared}
    if w < 1.0E-30
      then begin                       {shading normal unuseable, use geometric norm}
        goto use_gnorm_v3;
        end
      else begin                       {shading normal is big enough to use}
        w := flip_factor / sqrt(w);    {make scale factor for unitizing NV}
        nv.x := w*nv.x;
        nv.y := w*nv.y;
        nv.z := w*nv.z;
        nv_p := addr(nv);              {point to shading normal}
        ca3.colors_valid := true;      {colors will be reusable}
        end
      ;
got_shnorm_v3:                         {NV_P points 3DW space shading unit normal}
    rend_get.light_eval^ (             {evaluate visible color at this vertex}
      v3,                              {vertex to evaluate colors at}
      ca3,                             {cache block for this vertex}
      nv_p^,                           {normal vector at this point}
      sp^);                            {suprop block to use for surface properties}
    ca3.flip_shad := flip_shad;        {save whether used flipped normal or not}
    end;                               {done handling cached colors wern't valid}
{
*   The cache data for all three verticies is completely up to date.
*   Now determine which order the triangle will be written to the final 2D image
*   space level.
}
  flip_order := not view_front;        {init to indicate which side we are looking at}
  if rend_2d.sp.right                  {flip if 2D space is right handed}
    then flip_order := not flip_order;
{
*   Fill in the local TRI array entries for the original 3 verticies.
*   This forms a linked list of verticies used for clipping and interpolant
*   setup.  Only the CACHE_P and V_P fields are used unless the triangle is
*   clipped.
}
  tri[1].cache_p := addr(ca1);
  tri[1].v_p := addr(v1);
  tri[2].cache_p := addr(ca2);
  tri[2].v_p := addr(v2);
  tri[3].cache_p := addr(ca3);
  tri[3].v_p := addr(v3);
{
*   Handle clipping.  First check for the easy case where the entire triangle is
*   to be drawn.
}
  nverts := 3;                         {init number of verticies in 2D polygon}

  if                                   {at least one triangle vertex is clipped ?}
      (ca1.clip_mask ! ca2.clip_mask ! ca3.clip_mask) <> 0
      then begin
    goto clipped;                      {go to separate clipping code}
    end;

  if flip_order                        {check which order to write out as polygon}
    then begin                         {reverse order from call argument}
      iv1_p := addr(tri[3]);           {make pointers to interp anchor verticies}
      iv2_p := addr(tri[2]);
      iv3_p := addr(tri[1]);
      poly[1].x := ca3.x;              {fill in coordinates of 2DIM space polygon}
      poly[1].y := ca3.y;
      poly[2].x := ca2.x;
      poly[2].y := ca2.y;
      poly[3].x := ca1.x;
      poly[3].y := ca1.y;
      end
    else begin                         {preserve order from call argument}
      iv1_p := addr(tri[1]);           {make pointers to interp anchor verticies}
      iv2_p := addr(tri[2]);
      iv3_p := addr(tri[3]);
      poly[1].x := ca1.x;              {fill in coordinates of 2DIM space polygon}
      poly[1].y := ca1.y;
      poly[2].x := ca2.x;
      poly[2].y := ca2.y;
      poly[3].x := ca3.x;
      poly[3].y := ca3.y;
      end
    ;
{
*   The final 2D image space polygon coordinates are in the POLY array and NVERTS
*   is set to the number of verticies in the array.  The IV1_P - IV3_P point to our
*   internal verticies that are to be used as anchor points to set up the linear
*   interpolation of the interpolants.
}
draw_poly:                             {jump here when done handling clipping}
{
*   If SHADE_GEOM is set to quadratic, then an additional 3 interpolant anchor points
*   are needed.  These will be found by bisecting the edges of the triangle formed
*   by the verticies pointed to by IV1_P - IV3_P.  The values for the new verticies
*   will be intepolated back in the 3DW space, and then projected into the 2DIM
*   space.  This allows quadratic interpolation to partially correct for
*   non-linearities of the perspective transform.
}
  case rend_shade_geom of
rend_iterp_mode_linear_k: begin        {set up geometry for linear interpolation}
      c1.x := iv1_p^.cache_p^.x;   c1.y := iv1_p^.cache_p^.y;
      c2.x := iv2_p^.cache_p^.x;   c2.y := iv2_p^.cache_p^.y;
      c3.x := iv3_p^.cache_p^.x;   c3.y := iv3_p^.cache_p^.y;
      rend_set.lin_geom_2dim^ (        {set 3 points for linear interpolation}
        c1, c2, c3);
      end;
rend_iterp_mode_quad_k: begin          {set up geom for linear and quadratic interp}
      make_new_shading_vert (iv1_p^, iv2_p^, iv4_p); {create extra 3 shading points}
      make_new_shading_vert (iv2_p^, iv3_p^, iv5_p);
      make_new_shading_vert (iv3_p^, iv1_p^, iv6_p);
      c1.x := iv1_p^.cache_p^.x;   c1.y := iv1_p^.cache_p^.y;
      c2.x := iv2_p^.cache_p^.x;   c2.y := iv2_p^.cache_p^.y;
      c3.x := iv3_p^.cache_p^.x;   c3.y := iv3_p^.cache_p^.y;
      c4.x := iv4_p^.cache_p^.x;   c4.y := iv4_p^.cache_p^.y;
      c5.x := iv5_p^.cache_p^.x;   c5.y := iv5_p^.cache_p^.y;
      c6.x := iv6_p^.cache_p^.x;   c6.y := iv6_p^.cache_p^.y;
      rend_set.quad_geom_2dim^ (       {set 6 points for quadratic interpolation}
        c1, c2, c3, c4, c5, c6);
      end;
    end;                               {done with max shade mode cases}

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
            iv1_p^.cache_p^.color,
            iv2_p^.cache_p^.color,
            iv3_p^.cache_p^.color);
          goto done_rgba_iterps;       {all done with RGB and alpha interpolants}
          end
{
*   Alpha buffering is on but the LIN_VALS_RGBA routine can not be used.  This
*   means that red, green, blue, and alpha are set up separately, although the RGB
*   values must be pre-multiplied by alpha.
}
        else begin

  if rend_iterps.red.on then begin     {red interpolant turned on ?}
    case rend_iterps.red.shmode of
rend_iterp_mode_flat_k: begin          {set red to flat shading}
        w := 0.333333 * (
          iv1_p^.cache_p^.color.red*iv1_p^.cache_p^.color.alpha +
          iv2_p^.cache_p^.color.red*iv2_p^.cache_p^.color.alpha +
          iv3_p^.cache_p^.color.red*iv3_p^.cache_p^.color.alpha);
        rend_set.iterp_flat^ (
          rend_iterp_red_k, w);
        end;
rend_iterp_mode_linear_k: begin        {set red to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_red_k,
          iv1_p^.cache_p^.color.red*iv1_p^.cache_p^.color.alpha,
          iv2_p^.cache_p^.color.red*iv2_p^.cache_p^.color.alpha,
          iv3_p^.cache_p^.color.red*iv3_p^.cache_p^.color.alpha);
        end;
rend_iterp_mode_quad_k: begin          {set red to quadratic interpolation}
        rend_set.quad_vals^ (
          rend_iterp_red_k,
          iv1_p^.cache_p^.color.red*iv1_p^.cache_p^.color.alpha,
          iv2_p^.cache_p^.color.red*iv2_p^.cache_p^.color.alpha,
          iv3_p^.cache_p^.color.red*iv3_p^.cache_p^.color.alpha,
          iv4_p^.cache_p^.color.red*iv4_p^.cache_p^.color.alpha,
          iv5_p^.cache_p^.color.red*iv5_p^.cache_p^.color.alpha,
          iv6_p^.cache_p^.color.red*iv6_p^.cache_p^.color.alpha);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting red interpolant}

  if rend_iterps.grn.on then begin     {green interpolant turned on ?}
    case rend_iterps.grn.shmode of
rend_iterp_mode_flat_k: begin          {set green to flat shading}
        w := 0.333333 * (
          iv1_p^.cache_p^.color.grn*iv1_p^.cache_p^.color.alpha +
          iv2_p^.cache_p^.color.grn*iv2_p^.cache_p^.color.alpha +
          iv3_p^.cache_p^.color.grn*iv3_p^.cache_p^.color.alpha);
        rend_set.iterp_flat^ (
          rend_iterp_grn_k, w);
        end;
rend_iterp_mode_linear_k: begin        {set green to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_grn_k,
          iv1_p^.cache_p^.color.grn*iv1_p^.cache_p^.color.alpha,
          iv2_p^.cache_p^.color.grn*iv2_p^.cache_p^.color.alpha,
          iv3_p^.cache_p^.color.grn*iv3_p^.cache_p^.color.alpha);
        end;
rend_iterp_mode_quad_k: begin          {set green to quadratic interpolation}
        rend_set.quad_vals^ (
          rend_iterp_grn_k,
          iv1_p^.cache_p^.color.grn*iv1_p^.cache_p^.color.alpha,
          iv2_p^.cache_p^.color.grn*iv2_p^.cache_p^.color.alpha,
          iv3_p^.cache_p^.color.grn*iv3_p^.cache_p^.color.alpha,
          iv4_p^.cache_p^.color.grn*iv4_p^.cache_p^.color.alpha,
          iv5_p^.cache_p^.color.grn*iv5_p^.cache_p^.color.alpha,
          iv6_p^.cache_p^.color.grn*iv6_p^.cache_p^.color.alpha);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting green interpolant}

  if rend_iterps.blu.on then begin     {blue interpolant turned on ?}
    case rend_iterps.blu.shmode of
rend_iterp_mode_flat_k: begin          {set blue to flat shading}
        w := 0.333333 * (
          iv1_p^.cache_p^.color.blu*iv1_p^.cache_p^.color.alpha +
          iv2_p^.cache_p^.color.blu*iv2_p^.cache_p^.color.alpha +
          iv3_p^.cache_p^.color.blu*iv3_p^.cache_p^.color.alpha);
        rend_set.iterp_flat^ (
          rend_iterp_blu_k, w);
        end;
rend_iterp_mode_linear_k: begin        {set blue to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_blu_k,
          iv1_p^.cache_p^.color.blu*iv1_p^.cache_p^.color.alpha,
          iv2_p^.cache_p^.color.blu*iv2_p^.cache_p^.color.alpha,
          iv3_p^.cache_p^.color.blu*iv3_p^.cache_p^.color.alpha);
        end;
rend_iterp_mode_quad_k: begin          {set blue to quadratic interpolation}
        rend_set.quad_vals^ (
          rend_iterp_blu_k,
          iv1_p^.cache_p^.color.blu*iv1_p^.cache_p^.color.alpha,
          iv2_p^.cache_p^.color.blu*iv2_p^.cache_p^.color.alpha,
          iv3_p^.cache_p^.color.blu*iv3_p^.cache_p^.color.alpha,
          iv4_p^.cache_p^.color.blu*iv4_p^.cache_p^.color.alpha,
          iv5_p^.cache_p^.color.blu*iv5_p^.cache_p^.color.alpha,
          iv6_p^.cache_p^.color.blu*iv6_p^.cache_p^.color.alpha);
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

      if rend_iterps.red.on then begin {red interpolant turned on ?}
        case rend_iterps.red.shmode of
rend_iterp_mode_flat_k: begin          {set red to flat shading}
            w := 0.333333 * (
              iv1_p^.cache_p^.color.red +
              iv2_p^.cache_p^.color.red +
              iv3_p^.cache_p^.color.red);
            rend_set.iterp_flat^ (
              rend_iterp_red_k, w);
            end;
rend_iterp_mode_linear_k: begin        {set red to linear interpolation}
            rend_set.lin_vals^ (
              rend_iterp_red_k,
              iv1_p^.cache_p^.color.red,
              iv2_p^.cache_p^.color.red,
              iv3_p^.cache_p^.color.red);
            end;
rend_iterp_mode_quad_k: begin          {set red to quadratic interpolation}
            rend_set.quad_vals^ (
              rend_iterp_red_k,
              iv1_p^.cache_p^.color.red,
              iv2_p^.cache_p^.color.red,
              iv3_p^.cache_p^.color.red,
              iv4_p^.cache_p^.color.red,
              iv5_p^.cache_p^.color.red,
              iv6_p^.cache_p^.color.red);
            end;
          end;                         {done with interpolant shade mode cases}
        end;                           {done setting red interpolant}

      if rend_iterps.grn.on then begin {green interpolant turned on ?}
        case rend_iterps.grn.shmode of
rend_iterp_mode_flat_k: begin          {set green to flat shading}
            w := 0.333333 * (
              iv1_p^.cache_p^.color.grn +
              iv2_p^.cache_p^.color.grn +
              iv3_p^.cache_p^.color.grn);
            rend_set.iterp_flat^ (
              rend_iterp_grn_k, w);
            end;
rend_iterp_mode_linear_k: begin        {set green to linear interpolation}
            rend_set.lin_vals^ (
              rend_iterp_grn_k,
              iv1_p^.cache_p^.color.grn,
              iv2_p^.cache_p^.color.grn,
              iv3_p^.cache_p^.color.grn);
            end;
rend_iterp_mode_quad_k: begin          {set green to quadratic interpolation}
            rend_set.quad_vals^ (
              rend_iterp_grn_k,
              iv1_p^.cache_p^.color.grn,
              iv2_p^.cache_p^.color.grn,
              iv3_p^.cache_p^.color.grn,
              iv4_p^.cache_p^.color.grn,
              iv5_p^.cache_p^.color.grn,
              iv6_p^.cache_p^.color.grn);
            end;
          end;                         {done with interpolant shade mode cases}
        end;                           {done setting green interpolant}

      if rend_iterps.blu.on then begin {blue interpolant turned on ?}
        case rend_iterps.blu.shmode of
rend_iterp_mode_flat_k: begin          {set blue to flat shading}
            w := 0.333333 * (
              iv1_p^.cache_p^.color.blu +
              iv2_p^.cache_p^.color.blu +
              iv3_p^.cache_p^.color.blu);
            rend_set.iterp_flat^ (
              rend_iterp_blu_k, w);
            end;
rend_iterp_mode_linear_k: begin        {set blue to linear interpolation}
            rend_set.lin_vals^ (
              rend_iterp_blu_k,
              iv1_p^.cache_p^.color.blu,
              iv2_p^.cache_p^.color.blu,
              iv3_p^.cache_p^.color.blu);
            end;
rend_iterp_mode_quad_k: begin          {set blue to quadratic interpolation}
            rend_set.quad_vals^ (
              rend_iterp_blu_k,
              iv1_p^.cache_p^.color.blu,
              iv2_p^.cache_p^.color.blu,
              iv3_p^.cache_p^.color.blu,
              iv4_p^.cache_p^.color.blu,
              iv5_p^.cache_p^.color.blu,
              iv6_p^.cache_p^.color.blu);
            end;
          end;                         {done with interpolant shade mode cases}
        end;                           {done setting blue interpolant}
      end                              {done with alpha buffering turned off}
    ;                                  {done checking for alpha buffering on/off}
{
*   All done with any possible interactions due to alpha buffering.  The red,
*   green, and blue interpolants have definately been set.  Now set the rest.
}
  if rend_iterps.alpha.on then begin   {alpha interpolant turned on ?}
    case rend_iterps.alpha.shmode of
rend_iterp_mode_flat_k: begin          {set alpha to flat shading}
        w := 0.333333 * (
          iv1_p^.cache_p^.color.alpha +
          iv2_p^.cache_p^.color.alpha +
          iv3_p^.cache_p^.color.alpha);
        rend_set.iterp_flat^ (
          rend_iterp_alpha_k, w);
        end;
rend_iterp_mode_linear_k: begin        {set alpha to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_alpha_k,
          iv1_p^.cache_p^.color.alpha,
          iv2_p^.cache_p^.color.alpha,
          iv3_p^.cache_p^.color.alpha);
        end;
rend_iterp_mode_quad_k: begin          {set alpha to quadratic interpolation}
        rend_set.quad_vals^ (
          rend_iterp_alpha_k,
          iv1_p^.cache_p^.color.alpha,
          iv2_p^.cache_p^.color.alpha,
          iv3_p^.cache_p^.color.alpha,
          iv4_p^.cache_p^.color.alpha,
          iv5_p^.cache_p^.color.alpha,
          iv6_p^.cache_p^.color.alpha);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting alpha interpolant}
done_rgba_iterps:                      {skip to here if RGB/alpha interpolants set}

  if rend_iterps.z.on then begin       {Z interpolant turned on ?}
    case rend_iterps.z.shmode of
rend_iterp_mode_flat_k: begin          {set Z to flat shading}
        w := 0.333333 * (
          iv1_p^.cache_p^.z +
          iv2_p^.cache_p^.z +
          iv3_p^.cache_p^.z);
        rend_set.iterp_flat^ (
          rend_iterp_z_k, w);
        end;
rend_iterp_mode_linear_k: begin        {set Z to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_z_k,
          iv1_p^.cache_p^.z,
          iv2_p^.cache_p^.z,
          iv3_p^.cache_p^.z);
        end;
rend_iterp_mode_quad_k: begin          {set Z to quadratic interpolation}
        rend_set.quad_vals^ (
          rend_iterp_z_k,
          iv1_p^.cache_p^.z,
          iv2_p^.cache_p^.z,
          iv3_p^.cache_p^.z,
          iv4_p^.cache_p^.z,
          iv5_p^.cache_p^.z,
          iv6_p^.cache_p^.z);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting Z interpolant}

  if rend_iterps.u.on then begin       {U interpolant turned on ?}
    case rend_iterps.u.shmode of
rend_iterp_mode_flat_k: begin          {set U to flat shading}
        w := 0.333333 * (
          iv1_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.u +
          iv2_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.u +
          iv3_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.u);
        rend_set.iterp_flat^ (
          rend_iterp_u_k, w);
        end;
rend_iterp_mode_linear_k: begin        {set U to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_u_k,
          iv1_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.u,
          iv2_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.u,
          iv3_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.u);
        end;
rend_iterp_mode_quad_k: begin          {set U to quadratic interpolation}
        rend_set.quad_vals^ (
          rend_iterp_u_k,
          iv1_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.u,
          iv2_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.u,
          iv3_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.u,
          iv4_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.u,
          iv5_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.u,
          iv6_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.u);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting U interpolant}

  if rend_iterps.v.on then begin       {V interpolant turned on ?}
    case rend_iterps.v.shmode of
rend_iterp_mode_flat_k: begin          {set V to flat shading}
        w := 0.333333 * (
          iv1_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v +
          iv2_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v +
          iv3_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v);
        rend_set.iterp_flat^ (
          rend_iterp_v_k, w);
        end;
rend_iterp_mode_linear_k: begin        {set V to linear interpolation}
        rend_set.lin_vals^ (
          rend_iterp_v_k,
          iv1_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v,
          iv2_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v,
          iv3_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v);
        end;
rend_iterp_mode_quad_k: begin          {set V to quadratic interpolation}
        rend_set.quad_vals^ (
          rend_iterp_v_k,
          iv1_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v,
          iv2_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v,
          iv3_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v,
          iv4_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v,
          iv5_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v,
          iv6_p^.v_p^[rend_tmapi_p_ind].tmapi_p^.v);
        end;
      end;                             {done with interpolant shade mode cases}
    end;                               {done setting V interpolant}

  rend_prim.poly_2dim^ (nverts, poly); {finally draw the polygon}
  goto leave;                          {clean up and leave}
{
*   At least some part of the triangle is clipped out, but not such that a
*   trivial reject can be done.  Do the clipping and set the POLY array,
*   NVERTS, and the pointers IV1_P-IV3_P that point to the verticies to be
*   used as reference for the linear interpolation.
*
*   First set up the linked list of verticies based on the whether the vertex order
*   needs to be flipped from the call argument to the final 2DIM space polygon or
*   not.
}
clipped:                               {jump here if trivial clip accept fails}
  if flip_order                        {check for which order to link the verticies}
    then begin                         {link verticies in 3 - 2 - 1 order}
      tri[1].lastv_p := addr(tri[2]);
      tri[1].nextv_p := addr(tri[3]);
      tri[2].lastv_p := addr(tri[3]);
      tri[2].nextv_p := addr(tri[1]);
      tri[3].lastv_p := addr(tri[1]);
      tri[3].nextv_p := addr(tri[2]);
      end
    else begin                         {link verticies in 1 - 2 - 3 order}
      tri[1].lastv_p := addr(tri[3]);
      tri[1].nextv_p := addr(tri[2]);
      tri[2].lastv_p := addr(tri[1]);
      tri[2].nextv_p := addr(tri[3]);
      tri[3].lastv_p := addr(tri[2]);
      tri[3].nextv_p := addr(tri[1]);
      end
    ;                                  {done making linked list of triangle verticies}
  startv_p := addr(tri[1]);            {init vertex pointer to a valid vertex}
  if (                                 {no clipping needed to Z limits ?}
      (rend_clmask_nz_k + rend_clmask_fz_k) & (
      ca1.clip_mask !
      ca2.clip_mask !
      ca3.clip_mask)) = 0 then goto no_z_clips;
{
*   At least one of the triangle verticies exceeded one of the Z clip limits.
*   Create the resulting polygon after clipping to the Z limits.  When creating
*   a new vertex at the Z clip limits, the colors and coordinates must be
*   interpolated from the existing verticies.
}
  clipping_z := true;                  {any new verts will be created due to Z clip}
  pc := startv_p;                      {init pointer to current vertex to process}
  lastv_p := startv_p^.lastv_p;        {save addr of last vertex in to process}
  repeat                               {loop thru all the verticies in the polygon}
    did_lastv := pc = lastv_p;         {set flag if processing last vertex in list}
    if                                 {this vertex clipped out by near Z?}
        (rend_clmask_nz_k & pc^.cache_p^.clip_mask) <> 0 then begin
      po := pc^.lastv_p;               {make pointer to prev adjacent "other" vertex}
      if                               {need intersect between here and last vertex ?}
          (rend_clmask_nz_k & po^.cache_p^.clip_mask) = 0 then begin
        w :=                           {fractional contribution from current vertex}
          (rend_view.zclip_near - po^.cache_p^.z3dw) /
          (pc^.cache_p^.z3dw - po^.cache_p^.z3dw);
        make_new_vert;                 {create new vertex at clip intersect limit}
        end;                           {done clipping edge to previous vertex}
      po := pc^.nextv_p;               {make pointer to next adjacent "other" vertex}
      if                               {need intersect between here and last vertex ?}
          (rend_clmask_nz_k & po^.cache_p^.clip_mask) = 0 then begin
        w :=                           {fractional contribution from current vertex}
          (rend_view.zclip_near - po^.cache_p^.z3dw) /
          (pc^.cache_p^.z3dw - po^.cache_p^.z3dw);
        make_new_vert;                 {create new vertex at clip intersect limit}
        end;                           {done clipping edge to next vertex}
      delete_vertex;                   {this vertex clipped off, unlink it}
      goto next_z_clip_vertex;         {on to next vertex}
      end;                             {done with near Z clip for this vertex}
    if                                 {this vertex clipped out by far Z?}
        (rend_clmask_fz_k & pc^.cache_p^.clip_mask) <> 0 then begin
      po := pc^.lastv_p;               {make pointer to prev adjacent "other" vertex}
      if                               {need intersect between here and last vertex ?}
          (rend_clmask_fz_k & po^.cache_p^.clip_mask) = 0 then begin
        w :=                           {fractional contribution from current vertex}
          (rend_view.zclip_far - po^.cache_p^.z3dw) /
          (pc^.cache_p^.z3dw - po^.cache_p^.z3dw);
        make_new_vert;                 {create new vertex at clip intersect limit}
        end;                           {done clipping edge to previous vertex}
      po := pc^.nextv_p;               {make pointer to next adjacent "other" vertex}
      if                               {need intersect between here and last vertex ?}
          (rend_clmask_fz_k & po^.cache_p^.clip_mask) = 0 then begin
        w :=                           {fractional contribution from current vertex}
          (rend_view.zclip_far - po^.cache_p^.z3dw) /
          (pc^.cache_p^.z3dw - po^.cache_p^.z3dw);
        make_new_vert;                 {create new vertex at clip intersect limit}
        end;                           {done clipping edge to next vertex}
      delete_vertex;                   {this vertex clipped off, unlink it}
      end;                             {done with far Z clip for this vertex}
next_z_clip_vertex:                    {done with this vertex, go on to next}
    pc := pc^.nextv_p;                 {advance curr vert to next vert in chain}
    until did_lastv;                   {back until processed last vertex in list}
{
*   The polygon has been clipped to the Z limits.  Now determine which 3 verticies
*   should be used for determining the linear interpolation coeficients.  The first
*   three verticies that form a triangle of reasonable area will be used.
}
  iv1_p := startv_p;                   {set first vertex of shading triangle}
  iv2_p := iv1_p^.nextv_p;             {init second vertex to next vertex after first}
  repeat                               {look for second vertex far enough from first}
    if (                               {this vertex far enough from first vertex ?}
        abs(iv2_p^.cache_p^.x-iv1_p^.cache_p^.x) +
        abs(iv2_p^.cache_p^.y-iv1_p^.cache_p^.y)) >= 1.0E-4
      then goto got_iv2;
    iv2_p := iv2_p^.nextv_p;           {advance to next vertex in polygon}
    until iv2_p = iv1_p;               {keep trying until back to starting vertex}
  goto leave;                          {polygon too small to bother with}
got_iv2:                               {second vert is now far enough from first vert}
  iv3_p := iv2_p^.nextv_p;             {init third vertex to next after second vert}
  repeat                               {look for third vert far anough from other two}
    if (                               {the three verts form large enough area ?}
        (iv2_p^.cache_p^.y-iv1_p^.cache_p^.y)*(iv3_p^.cache_p^.x-iv1_p^.cache_p^.x) -
        (iv2_p^.cache_p^.x-iv1_p^.cache_p^.x)*(iv3_p^.cache_p^.y-iv1_p^.cache_p^.y))
        >= 1.0E-8
      then goto got_iv3;
    iv3_p := iv3_p^.nextv_p;           {advance to next vertex in polygon}
    until iv3_p = iv1_p;               {keep trying until back to starting vertex}
  goto leave;                          {polygon too small to bother with}
got_iv3:                               {all three verts form tri of big enough area}
{
*   The pointers IV1_P - IV3_P point to three verticies that form a triangle of
*   sufficient area to determine the linear interpolation derivatives from.
*   Now go to the common code with the case where no Z clipping was needed.
}
  goto do_xy_clips;
{
*   The triangle was not clipped by the near or far Z clip limits.  Set up the
*   pointers IV1_P - IV3_P to point to the three verticies to be used to compute
*   the linear interpolation derivatives.  Since none of the points were clipped
*   in Z, the original triangle verticies can be used directly.
}
no_z_clips:
  iv1_p := startv_p;
  iv2_p := iv1_p^.nextv_p;
  iv3_p := iv2_p^.nextv_p;
{
*   Common code to clip to the XY limits.  Different code was run depending on
*   whether or not the triangle needed any clipping in Z.  The pointers IV1_P to
*   IV3_P are all set.  Now clip the polygon to the XY clip limits.  This will be
*   done with a separate loop for each clip limit.
}
do_xy_clips:
  clipping_z := false;                 {now clipping to XY, not Z limits}
{
*   Clip the polygon to the left X clip limit.
}
  pc := startv_p;                      {init pointer to current vertex to process}
  lastv_p := startv_p^.lastv_p;        {save addr of last vertex in to process}
  repeat                               {loop thru all the verticies in the polygon}
    did_lastv := pc = lastv_p;         {set flag if processing last vertex in list}
    if pc^.cache_p^.x >= clip_minx     {this vertex not clipped out ?}
      then goto next_clip_minx;

    po := pc^.lastv_p;                 {set "other" vertex to previous vertex}
    if po^.cache_p^.x >= clip_minx then begin {need to create clip intersect point}
      w :=                             {fractional contribution from current vertex}
        (clip_minx - po^.cache_p^.x) /
        (pc^.cache_p^.x - po^.cache_p^.x);
      make_new_vert;                   {create vertex at clip intersect point}
      end;

    po := pc^.nextv_p;                 {set "other" vertex to next vertex}
    if po^.cache_p^.x >= clip_minx then begin {need to create clip intersect point}
      w :=                             {fractional contribution from current vertex}
        (clip_minx - po^.cache_p^.x) /
        (pc^.cache_p^.x - po^.cache_p^.x);
      make_new_vert;                   {create vertex at clip intersect point}
      delete_vertex;                   {remove current vertex from polygon}
      if made_vert                     {actually created new vertex after current ?}
        then pc := pc^.nextv_p;        {pretend new vert was current vert}
      goto next_clip_minx;             {advance to next vertex after that}
      end;

    delete_vertex;                     {unlink the current vertex}
next_clip_minx:
    pc := pc^.nextv_p;                 {advance curr vert to next vert in chain}
    until did_lastv;                   {back until processed last vertex in list}
{
*   Clip the polygon to the right X clip limit.
}
  pc := startv_p;                      {init pointer to current vertex to process}
  lastv_p := startv_p^.lastv_p;        {save addr of last vertex in to process}
  repeat                               {loop thru all the verticies in the polygon}
    did_lastv := pc = lastv_p;         {set flag if processing last vertex in list}
    if pc^.cache_p^.x <= clip_maxx     {this vertex not clipped out ?}
      then goto next_clip_maxx;

    po := pc^.lastv_p;                 {set "other" vertex to previous vertex}
    if po^.cache_p^.x <= clip_maxx then begin {need to create clip intersect point}
      w :=                             {fractional contribution from current vertex}
        (clip_maxx - po^.cache_p^.x) /
        (pc^.cache_p^.x - po^.cache_p^.x);
      make_new_vert;                   {create vertex at clip intersect point}
      end;

    po := pc^.nextv_p;                 {set "other" vertex to next vertex}
    if po^.cache_p^.x <= clip_maxx then begin {need to create clip intersect point}
      w :=                             {fractional contribution from current vertex}
        (clip_maxx - po^.cache_p^.x) /
        (pc^.cache_p^.x - po^.cache_p^.x);
      make_new_vert;                   {create vertex at clip intersect point}
      delete_vertex;                   {remove current vertex from polygon}
      if made_vert                     {actually created new vertex after current ?}
        then pc := pc^.nextv_p;        {pretend new vert was current vert}
      goto next_clip_maxx;             {advance to next vertex after that}
      end;

    delete_vertex;                     {unlink the current vertex}
next_clip_maxx:
    pc := pc^.nextv_p;                 {advance curr vert to next vert in chain}
    until did_lastv;                   {back until processed last vertex in list}
{
*   Clip the polygon to the top Y clip limit.
}
  pc := startv_p;                      {init pointer to current vertex to process}
  lastv_p := startv_p^.lastv_p;        {save addr of last vertex in to process}
  repeat                               {loop thru all the verticies in the polygon}
    did_lastv := pc = lastv_p;         {set flag if processing last vertex in list}
    if pc^.cache_p^.y >= clip_miny     {this vertex not clipped out ?}
      then goto next_clip_miny;

    po := pc^.lastv_p;                 {set "other" vertex to previous vertex}
    if po^.cache_p^.y >= clip_miny then begin {need to create clip intersect point}
      w :=                             {fractional contribution from current vertex}
        (clip_miny - po^.cache_p^.y) /
        (pc^.cache_p^.y - po^.cache_p^.y);
      make_new_vert;                   {create vertex at clip intersect point}
      end;

    po := pc^.nextv_p;                 {set "other" vertex to next vertex}
    if po^.cache_p^.y >= clip_miny then begin {need to create clip intersect point}
      w :=                             {fractional contribution from current vertex}
        (clip_miny - po^.cache_p^.y) /
        (pc^.cache_p^.y - po^.cache_p^.y);
      make_new_vert;                   {create vertex at clip intersect point}
      delete_vertex;                   {remove current vertex from polygon}
      if made_vert                     {actually created new vertex after current ?}
        then pc := pc^.nextv_p;        {pretend new vert was current vert}
      goto next_clip_miny;             {advance to next vertex after that}
      end;

    delete_vertex;                     {unlink the current vertex}
next_clip_miny:
    pc := pc^.nextv_p;                 {advance curr vert to next vert in chain}
    until did_lastv;                   {back until processed last vertex in list}
{
*   Clip the polygon to the bottom Y clip limit.
}
  pc := startv_p;                      {init pointer to current vertex to process}
  lastv_p := startv_p^.lastv_p;        {save addr of last vertex in to process}
  repeat                               {loop thru all the verticies in the polygon}
    did_lastv := pc = lastv_p;         {set flag if processing last vertex in list}
    if pc^.cache_p^.y <= clip_maxy     {this vertex not clipped out ?}
      then goto next_clip_maxy;

    po := pc^.lastv_p;                 {set "other" vertex to previous vertex}
    if po^.cache_p^.y <= clip_maxy then begin {need to create clip intersect point}
      w :=                             {fractional contribution from current vertex}
        (clip_maxy - po^.cache_p^.y) /
        (pc^.cache_p^.y - po^.cache_p^.y);
      make_new_vert;                   {create vertex at clip intersect point}
      end;

    po := pc^.nextv_p;                 {set "other" vertex to next vertex}
    if po^.cache_p^.y <= clip_maxy then begin {need to create clip intersect point}
      w :=                             {fractional contribution from current vertex}
        (clip_maxy - po^.cache_p^.y) /
        (pc^.cache_p^.y - po^.cache_p^.y);
      make_new_vert;                   {create vertex at clip intersect point}
      delete_vertex;                   {remove current vertex from polygon}
      if made_vert                     {actually created new vertex after current ?}
        then pc := pc^.nextv_p;        {pretend new vert was current vert}
      goto next_clip_maxy;             {advance to next vertex after that}
      end;

    delete_vertex;                     {unlink the current vertex}
next_clip_maxy:
    pc := pc^.nextv_p;                 {advance curr vert to next vert in chain}
    until did_lastv;                   {back until processed last vertex in list}
{
*   The polygon in the linked list is the final polygon to draw.  Now copy it into
*   array POLY so that it can be drawn.
}
  pc := startv_p;                      {init pointer to first vertex}
  for i := 1 to nverts do begin        {once for each vertex}
    poly[i].x := pc^.cache_p^.x;       {copy coordinate into POLY array}
    poly[i].y := pc^.cache_p^.y;
    pc := pc^.nextv_p;                 {point to next vertex in linked list}
    end;                               {back and fill in next vertex}
  goto draw_poly;                      {back to common code with not clipped case}

leave:
  sys_mem_dealloc (local_verts_p);     {deallocate temporary vertex descriptors}
  end;
