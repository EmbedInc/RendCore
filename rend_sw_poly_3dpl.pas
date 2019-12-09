{   Subroutine REND_SW_POLY_3DPL (N,VERTS)
*
*   Draw convex polygon in 3DPL coordinate space.  This is the space defined by
*   a current plane in the 3D model coordinate space.
}
module rend_sw_poly_3dpl;
define rend_sw_poly_3dpl;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_poly_3dpl_d.ins.pas';

procedure rend_sw_poly_3dpl (          {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;

type
  vert_data_t = record                 {max data we store for one vertex}
    coor: vect_3d_fp1_t;               {XYZ coordinate}
    vcache: rend_vcache_t;             {vertex cache}
    end;

var
  v1_p, v2_p, v3_p: rend_vert3d_p_t;   {pnt to descriptors for triangle verticies}
  va_p, vb_p: rend_vert3d_p_t;         {points to leapfrogging second/third verts}
  v1_data, v2_data, v3_data: vert_data_t; {actual data stored for each vertex}
  v: sys_int_machine_t;                {current vertex number}
  p: univ_ptr;                         {scratch pointer}

begin
  if n < 3 then return;                {no enough verticies here ?}
{
*   Allocate and init the data structures for the 3D model space verticies.
*   We will only be using the coordinate field directly, although we will
*   allow use of vertex caches if enabled.
}
  sys_mem_alloc (rend_vert3d_bytes*3, v1_p); {alloc mem for triangle verticies}
  v2_p := univ_ptr(                    {set pointers to non-first vert descriptors}
    sys_int_adr_t(v1_p) + rend_vert3d_bytes);
  v3_p := univ_ptr(
    sys_int_adr_t(v2_p) + rend_vert3d_bytes);

  v1_p^[rend_coor_p_ind].coor_p := addr(v1_data.coor); {set vertex coordinate pntrs}
  v2_p^[rend_coor_p_ind].coor_p := addr(v2_data.coor);
  v3_p^[rend_coor_p_ind].coor_p := addr(v3_data.coor);

  if rend_vcache_p_ind >= 0 then begin {vertex caches ON ?}
    v1_p^[rend_vcache_p_ind].vcache_p := addr(v1_data.vcache); {hook in caches}
    v2_p^[rend_vcache_p_ind].vcache_p := addr(v2_data.vcache);
    v3_p^[rend_vcache_p_ind].vcache_p := addr(v3_data.vcache);
    v1_data.vcache.version := rend_cache_version - 1; {invalidate caches}
    v2_data.vcache.version := v1_data.vcache.version;
    v3_data.vcache.version := v1_data.vcache.version;
    end;

  if rend_norm_p_ind >= 0 then begin   {explicit shading normals enabled ?}
    v1_p^[rend_norm_p_ind].norm_p := nil;
    v2_p^[rend_norm_p_ind].norm_p := nil;
    v3_p^[rend_norm_p_ind].norm_p := nil;
    end;

  if rend_diff_p_ind >= 0 then begin   {explicit diffuse color enabled ?}
    v1_p^[rend_diff_p_ind].diff_p := nil;
    v2_p^[rend_diff_p_ind].diff_p := nil;
    v3_p^[rend_diff_p_ind].diff_p := nil;
    end;

  if rend_tmapi_p_ind >= 0 then begin  {texture mapping indicies enabled ?}
    v1_p^[rend_tmapi_p_ind].tmapi_p := nil;
    v2_p^[rend_tmapi_p_ind].tmapi_p := nil;
    v3_p^[rend_tmapi_p_ind].tmapi_p := nil;
    end;

  if rend_ncache_p_ind >= 0 then begin {normal vector cache enabled ?}
    v1_p^[rend_ncache_p_ind].ncache_p := nil;
    v2_p^[rend_ncache_p_ind].ncache_p := nil;
    v3_p^[rend_ncache_p_ind].ncache_p := nil;
    end;

  if rend_spokes_p_ind >= 0 then begin {spokes list enabled ?}
    v1_p^[rend_spokes_p_ind].spokes_p := nil;
    v2_p^[rend_spokes_p_ind].spokes_p := nil;
    v3_p^[rend_spokes_p_ind].spokes_p := nil;
    end;
{
*   Init for main loop.  This includes setting up the first two verticies,
*   and initializing the second/third vertex leapfrogging.
}
  v1_data.coor.x := rend_3dpl.org.x +
    (verts[1].x * rend_3dpl.xb.x) + (verts[1].y * rend_3dpl.yb.x);
  v1_data.coor.y := rend_3dpl.org.y +
    (verts[1].x * rend_3dpl.xb.y) + (verts[1].y * rend_3dpl.yb.y);
  v1_data.coor.z := rend_3dpl.org.z +
    (verts[1].x * rend_3dpl.xb.z) + (verts[1].y * rend_3dpl.yb.z);

  va_p := v2_p;                        {init leapfrog vertex pointers}
  vb_p := v3_p;

  va_p^[rend_coor_p_ind].coor_p^.x := rend_3dpl.org.x +
    (verts[2].x * rend_3dpl.xb.x) + (verts[2].y * rend_3dpl.yb.x);
  va_p^[rend_coor_p_ind].coor_p^.y := rend_3dpl.org.y +
    (verts[2].x * rend_3dpl.xb.y) + (verts[2].y * rend_3dpl.yb.y);
  va_p^[rend_coor_p_ind].coor_p^.z := rend_3dpl.org.z +
    (verts[2].x * rend_3dpl.xb.z) + (verts[2].y * rend_3dpl.yb.z);
{
*   Main loop.  Once thru here for each triangle in the polygon.
}
  for v := 3 to n do begin             {once for each triangle}
    vb_p^[rend_coor_p_ind].coor_p^.x := rend_3dpl.org.x + {transform this vertex}
      (verts[v].x * rend_3dpl.xb.x) + (verts[v].y * rend_3dpl.yb.x);
    vb_p^[rend_coor_p_ind].coor_p^.y := rend_3dpl.org.y +
      (verts[v].x * rend_3dpl.xb.y) + (verts[v].y * rend_3dpl.yb.y);
    vb_p^[rend_coor_p_ind].coor_p^.z := rend_3dpl.org.z +
      (verts[v].x * rend_3dpl.xb.z) + (verts[v].y * rend_3dpl.yb.z);
    if rend_3dpl.sp.right
      then begin                       {transform is right handed}
        rend_prim.tri_3d^ (v1_p^, va_p^, vb_p^, rend_3dpl.front);
        end
      else begin                       {transform is left handed}
        rend_prim.tri_3d^ (v1_p^, vb_p^, va_p^, rend_3dpl.front);
        end
      ;
    p := vb_p;                         {flip leapfrog second/third vertex pointers}
    vb_p := va_p;
    va_p := p;
    if rend_vcache_p_ind >= 0 then begin {vertex caches ON ?}
      vb_p^[rend_vcache_p_ind].vcache_p^.version := {invalidiate cache of new vert}
        rend_cache_version - 1;
      end;
    end;                               {back to write out next triangle}
{
*   All done drawing polygon.  Now deallocate temporary memory.
}
  sys_mem_dealloc (v1_p);              {deallocate vertex pointers}
  end;
