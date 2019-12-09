{   Subroutine REND_SW_TRI_3D (V1, V2, V3, GNORM)
*
*   Draw a triangle from 3D model coordinate space.  V1-V3 contain
*   information about each vertex.  Each V argument is a list of pointers
*   to various pieces of information that may be supplied with the vertex.  A NIL
*   pointer indicates that the associated information is not present.
*   For the detailed format of a V argument, see the data type REND_VERT3D_T in
*   file rend.ins.pas.  GNORM is the geometric normal vector for the triangle.
*   It points out from the side that is to be considered the "front" face of the
*   polygon.  When the front face is viewed, the verticies appear in a
*   counter-clockwise order from V1 to V2 to V3.
*
*   PRIM_DATA PRIM_DATA_P rend_internal.tri_cache_3d_data_p
}
module rend_sw_tri_3d;
define rend_sw_tri_3d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_tri_3d_d.ins.pas';

procedure rend_sw_tri_3d (             {draw 3D model space triangle}
  in      v1, v2, v3: univ rend_vert3d_t; {pointer info for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}

var
  ca1_p, ca2_p, ca3_p: rend_vcache_p_t; {pointers to caches for each vertex}
  ca1, ca2, ca3: rend_vcache_t;        {scratch cashes for each vertex}

begin
  ca1.version := rend_cache_version + 1; {make invalid cache version number}
{
*   Determine where the vertex caches will come from.  Vertex caches will
*   be used directly from the vertex, if supplied.  Otherwise we will use
*   a temporary cache, initialized to invalid.
}
  if rend_vcache_p_ind >= 0
    then begin                         {vertex caches are globally enabled}
      if v1[rend_vcache_p_ind].vcache_p = nil
        then begin                     {no cache supplied for V1}
          ca1_p := addr(ca1);
          end
        else begin                     {V1 already has a cache}
          ca1_p := v1[rend_vcache_p_ind].vcache_p;
          end
        ;
      if v2[rend_vcache_p_ind].vcache_p = nil
        then begin                     {no cache supplied for V2}
          ca2_p := addr(ca2);
          ca2.version := ca1.version;
          end
        else begin                     {V2 already has a cache}
          ca2_p := v2[rend_vcache_p_ind].vcache_p;
          end
        ;
      if v3[rend_vcache_p_ind].vcache_p = nil
        then begin                     {no cache supplied for V3}
          ca3_p := addr(ca3);
          ca3.version := ca1.version;
          end
        else begin                     {V3 already has a cache}
          ca3_p := v3[rend_vcache_p_ind].vcache_p;
          end
        ;
      end
    else begin                         {vertex caches are globally disabled}
      ca1_p := addr(ca1);
      ca2_p := addr(ca2);
      ca2.version := ca1.version;
      ca3_p := addr(ca3);
      ca3.version := ca1.version;
      end
    ;
{
*   CA1_P - CA3_P are all set.
}
  rend_internal.tri_cache_3d^ (        {pass on triangle with definate caches}
    v1, v2, v3, ca1_p^, ca2_p^, ca3_p^, gnorm);
  end;
