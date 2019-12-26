{   Subroutine REND_SW_TRI_RAY_3D (V1, V2, V3, CA1, CA2, CA3, GNORM)
*
*   Draw triangle in 3D space.  V1-V3 are the descriptors for each vertex.
*   CA1-CA3 are the vertex caches for each vertex.  The vertex cache pointers in
*   V1-V3 should not be used.  GNORM is the geometric normal vector for the
*   triangle.  It points out from the side that is to be considered the "front"
*   face of the polygon.  When the front face is viewed, the verticies appear in
*   a counter-clockwise order from V1 to V2 to V3.
*
*   This version of the REND_INTERNAL.TRI_CACHE_3D primitive will save the
*   triangle for future ray tracing.
*
*   PRIM_DATA prim_call rend_sw_ray_trace_2dimi
}
module rend_sw_tri_cache_ray_3d;
define rend_sw_tri_cache_ray_3d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_tri_cache_ray_3d_d.ins.pas';

procedure rend_sw_tri_cache_ray_3d (   {3D triangle, explicit caches for each vert}
  in      v1, v2, v3: univ rend_vert3d_t; {descriptor for each vertex}
  in out  ca1, ca2, ca3: rend_vcache_t; {explicit cache for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  val_param;

var
  tri: type1_tri_crea_data_t;          {creation data for ray TRI object}
  nv2, nv: vect_3d_t;                  {scratch shading normal vector}
  w: real;                             {scale factor for unitizing shading normal}
  obj_p: ray_object_p_t;               {pointer to new ray tracer triangle object}
  stat: sys_err_t;

label
  no_shnorm1, no_shnorm2, no_shnorm3;

begin
  if rend_ray.traced then begin        {traced some pixels with this octree ?}
    rend_message_bomb ('rend', 'rend_ray_already_traced', nil, 0);
    end;
{
*   Make sure the current visual properties block is up to date.
}
  if rend_ray.visprop_old then begin   {current visprop block is out of date}
    rend_sw_ray_visprop_new;           {create an up to date visprop block}
    end;
  rend_ray.visprop_used := true;       {we will be using this visprop block}
{
*   Init all the TRI object data indicating no optional data is being sent, but
*   fill in the optional data with the default values anyway.  This is because
*   we may later discover that some verticies have optional data and some don't.
*   This way we can just fill in the optional data if found.
}
  tri.flags := [];                     {init to no optional data given}
  tri.visprop_p := rend_ray.visprop_p; {set pnt to visual properties for this tri}
{
*   Now transform the verticies into 3D world space and stuff into TRI.
}
  tri.p1.x :=                          {fill in 3DW space coordinates for vertex 1}
    v1[rend_coor_p_ind].coor_p^.x*rend_xf3d.xb.x +
    v1[rend_coor_p_ind].coor_p^.y*rend_xf3d.yb.x +
    v1[rend_coor_p_ind].coor_p^.z*rend_xf3d.zb.x +
    rend_xf3d.ofs.x;
  tri.p1.y :=
    v1[rend_coor_p_ind].coor_p^.x*rend_xf3d.xb.y +
    v1[rend_coor_p_ind].coor_p^.y*rend_xf3d.yb.y +
    v1[rend_coor_p_ind].coor_p^.z*rend_xf3d.zb.y +
    rend_xf3d.ofs.y;
  tri.p1.z :=
    v1[rend_coor_p_ind].coor_p^.x*rend_xf3d.xb.z +
    v1[rend_coor_p_ind].coor_p^.y*rend_xf3d.yb.z +
    v1[rend_coor_p_ind].coor_p^.z*rend_xf3d.zb.z +
    rend_xf3d.ofs.z;
  tri.p2.x :=                          {fill in 3DW space coordinates for vertex 2}
    v2[rend_coor_p_ind].coor_p^.x*rend_xf3d.xb.x +
    v2[rend_coor_p_ind].coor_p^.y*rend_xf3d.yb.x +
    v2[rend_coor_p_ind].coor_p^.z*rend_xf3d.zb.x +
    rend_xf3d.ofs.x;
  tri.p2.y :=
    v2[rend_coor_p_ind].coor_p^.x*rend_xf3d.xb.y +
    v2[rend_coor_p_ind].coor_p^.y*rend_xf3d.yb.y +
    v2[rend_coor_p_ind].coor_p^.z*rend_xf3d.zb.y +
    rend_xf3d.ofs.y;
  tri.p2.z :=
    v2[rend_coor_p_ind].coor_p^.x*rend_xf3d.xb.z +
    v2[rend_coor_p_ind].coor_p^.y*rend_xf3d.yb.z +
    v2[rend_coor_p_ind].coor_p^.z*rend_xf3d.zb.z +
    rend_xf3d.ofs.z;
  tri.p3.x :=                          {fill in 3DW space coordinates for vertex 3}
    v3[rend_coor_p_ind].coor_p^.x*rend_xf3d.xb.x +
    v3[rend_coor_p_ind].coor_p^.y*rend_xf3d.yb.x +
    v3[rend_coor_p_ind].coor_p^.z*rend_xf3d.zb.x +
    rend_xf3d.ofs.x;
  tri.p3.y :=
    v3[rend_coor_p_ind].coor_p^.x*rend_xf3d.xb.y +
    v3[rend_coor_p_ind].coor_p^.y*rend_xf3d.yb.y +
    v3[rend_coor_p_ind].coor_p^.z*rend_xf3d.zb.y +
    rend_xf3d.ofs.y;
  tri.p3.z :=
    v3[rend_coor_p_ind].coor_p^.x*rend_xf3d.xb.z +
    v3[rend_coor_p_ind].coor_p^.y*rend_xf3d.yb.z +
    v3[rend_coor_p_ind].coor_p^.z*rend_xf3d.zb.z +
    rend_xf3d.ofs.z;
{
*   Update the 3DW space bounding box to include this primitive.
}
  rend_ray.xmin := min(rend_ray.xmin, tri.p1.x);
  rend_ray.xmax := max(rend_ray.xmax, tri.p1.x);
  rend_ray.ymin := min(rend_ray.ymin, tri.p1.y);
  rend_ray.ymax := max(rend_ray.ymax, tri.p1.y);
  rend_ray.zmin := min(rend_ray.zmin, tri.p1.z);
  rend_ray.zmax := max(rend_ray.zmax, tri.p1.z);

  rend_ray.xmin := min(rend_ray.xmin, tri.p2.x);
  rend_ray.xmax := max(rend_ray.xmax, tri.p2.x);
  rend_ray.ymin := min(rend_ray.ymin, tri.p2.y);
  rend_ray.ymax := max(rend_ray.ymax, tri.p2.y);
  rend_ray.zmin := min(rend_ray.zmin, tri.p2.z);
  rend_ray.zmax := max(rend_ray.zmax, tri.p2.z);

  rend_ray.xmin := min(rend_ray.xmin, tri.p3.x);
  rend_ray.xmax := max(rend_ray.xmax, tri.p3.x);
  rend_ray.ymin := min(rend_ray.ymin, tri.p3.y);
  rend_ray.ymax := max(rend_ray.ymax, tri.p3.y);
  rend_ray.zmin := min(rend_ray.zmin, tri.p3.z);
  rend_ray.zmax := max(rend_ray.zmax, tri.p3.z);
{
*   Transform the geometric normal into the 3DW space and set it as the default
*   shading normals.
}
  nv.x :=
    gnorm.x*rend_xf3d.vxb.x +
    gnorm.y*rend_xf3d.vyb.x +
    gnorm.z*rend_xf3d.vzb.x;
  nv.y :=
    gnorm.x*rend_xf3d.vxb.y +
    gnorm.y*rend_xf3d.vyb.y +
    gnorm.z*rend_xf3d.vzb.y;
  nv.z :=
    gnorm.x*rend_xf3d.vxb.z +
    gnorm.y*rend_xf3d.vyb.z +
    gnorm.z*rend_xf3d.vzb.z;
  w := 1.0 / sqrt (sqr(nv.x) + sqr(nv.y) + sqr(nv.z)); {unitizing factor}
  tri.v1.shnorm.x := nv.x * w;         {stuff vertex 1 value}
  tri.v1.shnorm.y := nv.y * w;
  tri.v1.shnorm.z := nv.z * w;
  tri.v2.shnorm := tri.v1.shnorm;      {copy into other verticies}
  tri.v3.shnorm := tri.v1.shnorm;
{
*   Copy the current diffuse color as the default explicit colors for each
*   vertex.
}
  tri.v1.red := rend_ray.visprop_p^.diff_red; {stuff diff color into vertex 1}
  tri.v1.grn := rend_ray.visprop_p^.diff_grn;
  tri.v1.blu := rend_ray.visprop_p^.diff_blu;
  tri.v2.red := tri.v1.red;            {copy into vertex 2}
  tri.v2.grn := tri.v1.grn;
  tri.v2.blu := tri.v1.blu;
  tri.v3.red := tri.v1.red;            {copy into vertex 3}
  tri.v3.grn := tri.v1.grn;
  tri.v3.blu := tri.v1.blu;
{
*   Init the explicit alpha value for each vertex with the current FRONT opacity
*   fraction.  Artifacts will result if front and side opacities differ, and an
*   explicit opacity is supplied for some verticies, but not all.
}
  tri.v1.alpha := rend_ray.visprop_p^.opac_front;
  tri.v2.alpha := rend_ray.visprop_p^.opac_front;
  tri.v3.alpha := rend_ray.visprop_p^.opac_front;
{
*   Set explicit vertex diffuse colors and opacity fractions, if present.
}
  if rend_diff_p_ind >= 0 then begin   {diffuse colors per vertex enabled ?}
    if v1[rend_diff_p_ind].diff_p <> nil then begin {vertex 1 has explicit colors ?}
      tri.v1.red := v1[rend_diff_p_ind].diff_p^.red;
      tri.v1.grn := v1[rend_diff_p_ind].diff_p^.grn;
      tri.v1.blu := v1[rend_diff_p_ind].diff_p^.blu;
      tri.v1.alpha := v1[rend_diff_p_ind].diff_p^.alpha;
      tri.flags := tri.flags + [type1_tri_flag_rgb_k, type1_tri_flag_alpha_k]
      end;
    if v2[rend_diff_p_ind].diff_p <> nil then begin {vertex 2 has explicit colors ?}
      tri.v2.red := v2[rend_diff_p_ind].diff_p^.red;
      tri.v2.grn := v2[rend_diff_p_ind].diff_p^.grn;
      tri.v2.blu := v2[rend_diff_p_ind].diff_p^.blu;
      tri.v2.alpha := v2[rend_diff_p_ind].diff_p^.alpha;
      tri.flags := tri.flags + [type1_tri_flag_rgb_k, type1_tri_flag_alpha_k]
      end;
    if v3[rend_diff_p_ind].diff_p <> nil then begin {vertex 3 has explicit colors ?}
      tri.v3.red := v3[rend_diff_p_ind].diff_p^.red;
      tri.v3.grn := v3[rend_diff_p_ind].diff_p^.grn;
      tri.v3.blu := v3[rend_diff_p_ind].diff_p^.blu;
      tri.v3.alpha := v3[rend_diff_p_ind].diff_p^.alpha;
      tri.flags := tri.flags + [type1_tri_flag_rgb_k, type1_tri_flag_alpha_k]
      end;
    end;
{
*   Set explicit vertex shading normals, if present.
}
  with                                 {process vertex 1}
      v1: v,                           {V is call argument for this vertex}
      tri.v1: tv                       {TV is TRI optional vertex data for this vert}
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
    else begin                         {no explicit shading normal for this vertex}
      goto no_shnorm1;
      end;                             {NV_P is pointing to shading normal}
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
    w := sqr(nv.x) + sqr(nv.y) + sqr(nv.z);
    if w < 1.0E-35 then goto no_shnorm1; {shnorm too small, use geometric normal ?}
    w := 1.0 / sqrt(w);                {make mult factor for unitizing shading norm}
    tv.shnorm.x := nv.x * w;           {stuff explicit unit shading normal into TRI}
    tv.shnorm.y := nv.y * w;
    tv.shnorm.z := nv.z * w;
    tri.flags := tri.flags + [type1_tri_flag_shnorm_k];
no_shnorm1:
    end;                               {done with shading normal for vertex 1}

  with                                 {process vertex 2}
      v2: v,                           {V is call argument for this vertex}
      tri.v2: tv                       {TV is TRI optional vertex data for this vert}
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
    else begin                         {no explicit shading normal for this vertex}
      goto no_shnorm2;
      end;                             {NV_P is pointing to shading normal}
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
    w := sqr(nv.x) + sqr(nv.y) + sqr(nv.z);
    if w < 1.0E-35 then goto no_shnorm2; {shnorm too small, use geometric normal ?}
    w := 1.0 / sqrt(w);                {make mult factor for unitizing shading norm}
    tv.shnorm.x := nv.x * w;           {stuff explicit unit shading normal into TRI}
    tv.shnorm.y := nv.y * w;
    tv.shnorm.z := nv.z * w;
    tri.flags := tri.flags + [type1_tri_flag_shnorm_k];
no_shnorm2:
    end;                               {done with shading normal for vertex 2}

  with                                 {process vertex 3}
      v3: v,                           {V is call argument for this vertex}
      tri.v3: tv                       {TV is TRI optional vertex data for this vert}
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
    else begin                         {no explicit shading normal for this vertex}
      goto no_shnorm3;
      end;                             {NV_P is pointing to shading normal}
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
    w := sqr(nv.x) + sqr(nv.y) + sqr(nv.z);
    if w < 1.0E-35 then goto no_shnorm3; {shnorm too small, use geometric normal ?}
    w := 1.0 / sqrt(w);                {make mult factor for unitizing shading norm}
    tv.shnorm.x := nv.x * w;           {stuff explicit unit shading normal into TRI}
    tv.shnorm.y := nv.y * w;
    tv.shnorm.z := nv.z * w;
    tri.flags := tri.flags + [type1_tri_flag_shnorm_k];
no_shnorm3:
    end;                               {done with shading normal for vertex 3}
{
*   All the state has been set up.  Now create the actual triangle object.
}
  obj_p :=                             {alloc mem for the new triangle object}
    ray_mem_alloc_perm (sizeof(obj_p^));
  obj_p^.class_p := addr(rend_ray.class_tri); {set pointer to obj routines}

  rend_ray.class_tri.create^ (         {create triangle object}
    obj_p^,                            {object to create}
    addr(tri),                         {user data about the object to create}
    stat);
  sys_error_abort (stat, 'ray', 'object_create', nil, 0);

  if obj_p^.data_p <> nil then begin   {triangle not punted by TRI create routines ?}
    rend_ray.top_obj.class_p^.add_child^ ( {add new triangle as child to top object}
      rend_ray.top_obj,                {aggregate object to add triangle to}
      obj_p^);                         {object to be added}
    end;
  end;
