{   Subroutine REND_SW_LINE2_3D (V1,V2,GNORM)
*
*   This is a special case implementation of the LINE_3D primitive.  See header
*   comments in REND_SW_LINE_3D.PAS for details of what this primitive is supposed
*   to do.
*
*   This version of LINE_3D is installed when wide vectors have been enabled
*   in any of the 2D coordinate spaces below the 3D model coordinate space.
*   In this implementation, the width in the 3D space necessary to achieve the
*   desired width in the space where vectors are thickened is found.  This is
*   used to create polygons in 3D space to model the wide vector.
}
module rend_sw_line2_3d;
define rend_sw_line2_3d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_line2_3d_d.ins.pas';

procedure rend_sw_line2_3d (           {takes into account vector thickening}
  in      v1, v2: univ rend_vert3d_t;  {descriptors for each line segment endpoint}
  in      gnorm: vect_3d_t);           {geometric normal for Z slope and backface}

type
  rend_vert3d_p_t =
    ^rend_vert3d_t;

var
  l1, l2: vect_3d_t;                   {longitudinal vectors at V1 and V2}
  r1, r2: vect_3d_t;                   {radial vectors at V1 and V2}
  w1, w2: real;                        {1.0 / perspective factors at V1 and V2}
  p1, p2: vect_3d_t;                   {line segment ends clipped to near Z}
  z1_3dw, z2_3dw: real;                {3D world space line segment ends Z values}
  p: vect_3d_t;                        {scratch 3D coordinate}
  clip_p1, clip_p2: boolean;           {TRUE if P1 or P2 past near Z clip limit}
  m1, m2: real;                        {mult factors for clipping}
  size: sys_int_adr_t;                 {amount of memory needed for verticies}
  v3_p, v4_p, v5_p, v6_p: rend_vert3d_p_t; {pnt to wide line corner verticies}
  coor3, coor4, coor5, coor6: vect_3d_fp1_t; {wide line corner coordinates}
  cache3, cache4, cache5, cache6:      {vertex caches for corner verticies}
    rend_vcache_t;
  i: sys_int_machine_t;                {loop counter}
  j: sys_int_machine_t;                {scratch integer}

begin
  p1.x := v1[rend_coor_p_ind].coor_p^.x; {init clipped line ends to unclipped values}
  p1.y := v1[rend_coor_p_ind].coor_p^.y;
  p1.z := v1[rend_coor_p_ind].coor_p^.z;

  p2.x := v2[rend_coor_p_ind].coor_p^.x;
  p2.y := v2[rend_coor_p_ind].coor_p^.y;
  p2.z := v2[rend_coor_p_ind].coor_p^.z;

  z1_3dw :=                            {make 3D world space Z values for clip check}
    (rend_xf3d.xb.z * p1.x) +
    (rend_xf3d.yb.z * p1.y) +
    (rend_xf3d.zb.z * p1.z) +
    rend_xf3d.ofs.z;
  z2_3dw :=
    (rend_xf3d.xb.z * p2.x) +
    (rend_xf3d.yb.z * p2.y) +
    (rend_xf3d.zb.z * p2.z) +
    rend_xf3d.ofs.z;
{
*   Clip P1 and P2 to the near Z clip limit.  This is necessary because perspective
*   factors will be computed for P1 and P2.  At most only one of the points will
*   actually be clipped.  A trivial reject is done if both points are past the
*   near Z clip limit.
}
  clip_p1 := z1_3dw > rend_view.zclip_near;
  clip_p2 := z2_3dw > rend_view.zclip_near;
  if clip_p1 and clip_p2 then return;  {trivial reject ?}

  if clip_p1 then begin                {P1 is in front of near Z clip limit ?}
    m1 := (rend_view.zclip_near - z2_3dw) / (z1_3dw - z2_3dw);
    m2 := 1.0 - m1;
    p1.x := (m1 * p1.x) + (m2 * p2.x);
    p1.y := (m1 * p1.y) + (m2 * p2.y);
    p1.z := (m1 * p1.z) + (m2 * p2.z);
    z1_3dw := (m1 * z1_3dw) + (m2 * z2_3dw);
    end;

  if clip_p2 then begin                {P2 is in front of near Z clip limit ?}
    m2 := (rend_view.zclip_near - z1_3dw) / (z2_3dw - z1_3dw);
    m1 := 1.0 - m2;
    p2.x := (m1 * p1.x) + (m2 * p2.x);
    p2.y := (m1 * p1.y) + (m2 * p2.y);
    p2.z := (m1 * p1.z) + (m2 * p2.z);
    z2_3dw := (m1 * z1_3dw) + (m2 * z2_3dw);
    end;

  if not rend_xf3d.vrad_ok             {precomputed 3D vector width not ready ?}
    then rend_make_xf3d_vrad;          {ensure the VRAD fields are correct}
{
*   Create the longitudinal and radial vectors at each end of the line segment.
*   These form a 2D coordinate space at each end of the line segment.  The
*   longitudinal vectors are paralell to the line segment.  The radial vectors
*   are perpendicular to both the line segment and its geometric normal.
*   The magnitude of these vectors will be adjusted so that they will map to
*   the line segment's thickness radius in the 2D space where wide lines are
*   enabled.
*
*   Find the raw longitudinal and radial directions.  The magnitudes will be
*   adjusted later.
}
  l2.x := p2.x - p1.x;                 {raw longitudinal direction}
  l2.y := p2.y - p1.y;
  l2.z := p2.z - p1.z;

  r2.x := (gnorm.y * l2.z) - (gnorm.z * l2.y); {raw radial direction}
  r2.y := (gnorm.z * l2.x) - (gnorm.x * l2.z);
  r2.z := (gnorm.x * l2.y) - (gnorm.y * l2.x);
{
*   Calculate the perspective factors for each line segment end point.  These will
*   really be stored as their reciprocals in W1 and W2.
}
  if rend_view.perspec_on
    then begin                         {perspective is ON}
      w1 := (rend_view.eyedis - z1_3dw) / rend_view.eyedis;
      w2 := (rend_view.eyedis - z2_3dw) / rend_view.eyedis;
      end
    else begin                         {perspective is OFF}
      w1 := 1.0;
      w2 := 1.0;
      end
    ;
{
*   Adjust the longitudinal and radial vectors to their final magnitudes.
}
  m1 := sqrt(                          {denom of the L2 magnitude adjust factor}
    sqr(l2.x * rend_xf3d.vradx.x) +
    sqr(l2.y * rend_xf3d.vradx.y) +
    sqr(l2.z * rend_xf3d.vradx.z) +
    sqr(l2.x * rend_xf3d.vrady.x) +
    sqr(l2.y * rend_xf3d.vrady.y) +
    sqr(l2.z * rend_xf3d.vrady.z) +
    sqr(l2.x * rend_xf3d.vradz.x) +
    sqr(l2.y * rend_xf3d.vradz.y) +
    sqr(l2.z * rend_xf3d.vradz.z) );
  if m1 < 1.0e-30 then return;         {line has no length - nothing to draw}
  m1 := w2 / m1;                       {L2 magnitude adjust factor}
  l2.x := m1 * l2.x;                   {make final L2}
  l2.y := m1 * l2.y;
  l2.z := m1 * l2.z;

  m1 := -w1 / w2;                      {L1 magnitude adjust factor from L2}
  l1.x := m1 * l2.x;                   {make final L1}
  l1.y := m1 * l2.y;
  l1.z := m1 * l2.z;

  m1 := w2 / sqrt(                     {R2 magnitude adjust factor}
    sqr(r2.x * rend_xf3d.vradx.x) +
    sqr(r2.y * rend_xf3d.vradx.y) +
    sqr(r2.z * rend_xf3d.vradx.z) +
    sqr(r2.x * rend_xf3d.vrady.x) +
    sqr(r2.y * rend_xf3d.vrady.y) +
    sqr(r2.z * rend_xf3d.vrady.z) +
    sqr(r2.x * rend_xf3d.vradz.x) +
    sqr(r2.y * rend_xf3d.vradz.y) +
    sqr(r2.z * rend_xf3d.vradz.z) );
  r2.x := m1 * r2.x;
  r2.y := m1 * r2.y;
  r2.z := m1 * r2.z;

  m1 := -w1 / w2;                      {R1 magnitude adjust factor from R2}
  r1.x := m1 * r2.x;
  r1.y := m1 * r2.y;
  r1.z := m1 * r2.z;
{
*   The longitudinal and radial vectors are all set.
*   Now create vertex descriptors for the corners of the wide line rectangle.
}
  size := rend_vert3d_bytes * 4;       {amount mem needed for vertex descriptors}
  sys_mem_alloc (size, v3_p);          {grab mem for vertex descriptors}
  if v3_p = nil then begin
    writeln ('Unable to grab dynamic memory in REND_SW_LINE2_3D.');
    writeln ('The disk is probably full.');
    sys_bomb;
    end;
  v4_p := univ_ptr(                    {make pointers to all other vertex descriptors}
    sys_int_adr_t(v3_p) + rend_vert3d_bytes);
  v5_p := univ_ptr(
    sys_int_adr_t(v4_p) + rend_vert3d_bytes);
  v6_p := univ_ptr(
    sys_int_adr_t(v5_p) + rend_vert3d_bytes);

  for i := 0 to rend_vert3d_last_list_ent do begin {once for each ON 3D vertex field}
    j := rend_vert3d_on_list[i];       {get index value for this field type}
    v3_p^[j].coor_p := v2[j].coor_p;   {init corner verticies from segment ends}
    v6_p^[j].coor_p := v2[j].coor_p;
    v4_p^[j].coor_p := v1[j].coor_p;
    v5_p^[j].coor_p := v1[j].coor_p;
    end;

  if rend_vcache_p_ind >= 0 then begin {vertex caches turned ON ?}
    v3_p^[rend_vcache_p_ind].vcache_p := addr(cache3);
    v4_p^[rend_vcache_p_ind].vcache_p := addr(cache4);
    v5_p^[rend_vcache_p_ind].vcache_p := addr(cache5);
    v6_p^[rend_vcache_p_ind].vcache_p := addr(cache6);
    cache3.version := rend_cache_version - 1; {init caches to invalid}
    cache4.version := rend_cache_version - 1;
    cache5.version := rend_cache_version - 1;
    cache6.version := rend_cache_version - 1;
    end;

  v3_p^[rend_coor_p_ind].coor_p := addr(coor3); {set vertex coordinate pointers}
  v4_p^[rend_coor_p_ind].coor_p := addr(coor4);
  v5_p^[rend_coor_p_ind].coor_p := addr(coor5);
  v6_p^[rend_coor_p_ind].coor_p := addr(coor6);
{
*   The vertex pointers for the rectangle corners are all set.  Now make the
*   XYZ coordinates for each corner.  This will be done by first finding the
*   middle of each end, and then adding and subtracting the radial vector to
*   find the corner points.
}
  p.x := p2.x + l2.x;                  {middle of V2 end of rectangle}
  p.y := p2.y + l2.y;
  p.z := p2.z + l2.z;
  coor3.x := p.x + r2.x;
  coor3.y := p.y + r2.y;
  coor3.z := p.z + r2.z;
  coor6.x := p.x - r2.x;
  coor6.y := p.y - r2.y;
  coor6.z := p.z - r2.z;

  p.x := p1.x + l1.x;                  {middle of V1 end of rectangle}
  p.y := p1.y + l1.y;
  p.z := p1.z + l1.z;
  coor5.x := p.x + r1.x;
  coor5.y := p.y + r1.y;
  coor5.z := p.z + r1.z;
  coor4.x := p.x - r1.x;
  coor4.y := p.y - r1.y;
  coor4.z := p.z - r1.z;
{
*   All rectangle corner points completely set.  Now write out the rectangle
*   using two TRI_3D primitives.
}
  rend_prim.tri_3d^ (v3_p^, v4_p^, v5_p^, gnorm);
  rend_prim.tri_3d^ (v3_p^, v5_p^, v6_p^, gnorm);

  sys_mem_dealloc (v3_p);              {deallocate vertex descriptor memory}
  end;
