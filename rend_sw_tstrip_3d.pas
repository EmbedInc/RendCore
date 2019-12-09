{   Subroutine REND_SW_TSTRIP_3D (VLIST, NVERTS)
*
*   Draw triangle strip in 3D space.  A triangle strip is a list of triangles
*   with subsequent common sides in a specific order.  Such a strip can
*   result from triangulating one "row" of quadralaterals of a quad mesh.
*
*   The first three verticies in the list specify the first triangle.
*   After that, each additional vertex specifies a new triangle, since
*   each new triangle shares an edge with the previous triangle.
*   The first vertex must be the one vertex of the first triangle that
*   is not shared by the second triangle.  Triangle 1 is formed by
*   verticies 1-2-3, triangle 2 by 3-2-4, triangle 3 by 3-4-5, triangle
*   4 by 5-4-6, etc.
*
*   The "front" side of the first triangle is the side from with the verticies
*   1-2-3 appear around the triangle in counter-clockwise order.  This
*   implicitly defines the front face of the remaining triangles because
*   of the consecutive shared edges.
*
*   NVERTS is the number of verticies in the entire list.  Therefore,
*   NVERTS-2 triangles will be drawn.
*
*   PRIM_DATA PRIM_DATA_P rend_internal.tri_cache_3d_data_p
}
module rend_sw_tstrip_3d;
define rend_sw_tstrip_3d;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_tstrip_3d_d.ins.pas';

procedure rend_sw_tstrip_3d (          {draw connected strip of triangles}
  in      vlist: univ rend_vert3d_p_list_t; {list of pointers to vertex descriptors}
  in      nverts: sys_int_machine_t);  {number of verticies in VLIST}
  val_param;

var
  v1_p, v2_p, v3_p: rend_vert3d_p_t;   {pointers to current triangle verticies}
  c1_p, c2_p, c3_p: rend_vcache_p_t;   {pointers to caches for current verticies}
  ca:                                  {supply of temporary vertex caches}
    array[0..3] of rend_vcache_t;      {low two bits index for easy "round robin"}
  v: sys_int_machine_t;                {last vertex number of current triangle}
  version_invalid: sys_int_machine_t;  {cache version guaranteed to be invalid}
  e1, e2: vect_3d_t;                   {edge vectors used to find geometric normal}
  gnorm: vect_3d_t;                    {geometric normal vector for current triangle}
  phase: boolean;                      {identifies which side next triangle shares}

begin
  if nverts < 3 then return;           {not enough to draw even one triangle ?}

  version_invalid := rend_cache_version + 1; {make arbitrary invalid cache version}
{
*   Init the vertex pointers as if the triangle before the first one
*   had just been drawn.  This allows us to jump into a regular loop without
*   a large amount of duplicate for the first triangle.
}
  phase := true;                       {start with A-x-B becomres A-B-C}

  v1_p := vlist[1];                    {set pointers to verticies to be re-used}
  v3_p := vlist[2];

  if rend_vcache_p_ind >= 0            {vertex caches globally ON or OFF ?}
{
*********************************
*
*   Handle case where vertex caches are globally enabled, and my be present
*   in each vertex.
}
    then begin                         {vertex caches are globally enabled}
      if v1_p^[rend_vcache_p_ind].vcache_p = nil
        then begin                     {no cache supplied with vertex}
          c1_p := addr(ca[1]);
          c1_p^.version := version_invalid;
          end
        else begin                     {a cache was supplied with the vertex}
          c1_p := v1_p^[rend_vcache_p_ind].vcache_p;
          end
        ;
      if v3_p^[rend_vcache_p_ind].vcache_p = nil
        then begin                     {no cache supplied with vertex}
          c3_p := addr(ca[2]);
          c3_p^.version := version_invalid;
          end
        else begin                     {a cache was supplied with the vertex}
          c3_p := v3_p^[rend_vcache_p_ind].vcache_p;
          end
        ;

      for v := 3 to nverts do begin    {once for each triangle in strip}
        if phase                       {which way new triangle connected to old ?}
          then begin                   {A-x-B becomes A-B-C}
            v2_p := v3_p;              {old vertex 3 becomes new vertex 2}
            c2_p := c3_p;
            phase := false;
            end
          else begin                   {x-A-B becomes B-A-C}
            v1_p := v3_p;              {old vertex 3 becomes new vertex 1}
            c1_p := c3_p;
            phase := true;
            end
          ;
        v3_p := vlist[v];              {get pointer to new vertex descriptor}
        if v3_p^[rend_vcache_p_ind].vcache_p = nil
          then begin                   {no cache supplied with vertex}
            c3_p := addr(ca[v & 3]);
            c3_p^.version := version_invalid;
            end
          else begin                   {a cache was supplied with the vertex}
            c3_p := v3_p^[rend_vcache_p_ind].vcache_p;
            end
          ;
{
*   All the per-vertex info is all set up for this triangle.
}
        e1.x :=                        {make edge vector from vetex 1 to 2}
          v2_p^[rend_coor_p_ind].coor_p^.x - v1_p^[rend_coor_p_ind].coor_p^.x;
        e1.y :=
          v2_p^[rend_coor_p_ind].coor_p^.y - v1_p^[rend_coor_p_ind].coor_p^.y;
        e1.z :=
          v2_p^[rend_coor_p_ind].coor_p^.z - v1_p^[rend_coor_p_ind].coor_p^.z;

        e2.x :=                        {make edge vector from vetex 1 to 3}
          v3_p^[rend_coor_p_ind].coor_p^.x - v1_p^[rend_coor_p_ind].coor_p^.x;
        e2.y :=
          v3_p^[rend_coor_p_ind].coor_p^.y - v1_p^[rend_coor_p_ind].coor_p^.y;
        e2.z :=
          v3_p^[rend_coor_p_ind].coor_p^.z - v1_p^[rend_coor_p_ind].coor_p^.z;

        gnorm.x := (e1.y * e2.z) - (e1.z * e2.y); {E1 x E2 is geometric normal}
        gnorm.y := (e1.z * e2.x) - (e1.x * e2.z);
        gnorm.z := (e1.x * e2.y) - (e1.y * e2.x);
        rend_internal.tri_cache_3d^ (  {draw this triangle}
          v1_p^, v2_p^, v3_p^, c1_p^, c2_p^, c3_p^, gnorm);
        end;                           {back for next triangle in strip}
      end                              {end of vertex caches globally enabled case}
{
*********************************
*
*   Handle case where vertex caches are globally disabled.
}
    else begin                         {vertex caches are globally disabled}
      c1_p := addr(ca[1]);
      c1_p^.version := version_invalid;
      c3_p := addr(ca[2]);
      c3_p^.version := version_invalid;

      for v := 3 to nverts do begin    {once for each triangle in strip}
        if phase                       {which way new triangle connected to old ?}
          then begin                   {A-x-B becomes A-B-C}
            v2_p := v3_p;              {old vertex 3 becomes new vertex 2}
            c2_p := c3_p;
            phase := false;
            end
          else begin                   {x-A-B becomes B-A-C}
            v1_p := v3_p;              {old vertex 3 becomes new vertex 1}
            c1_p := c3_p;
            phase := true;
            end
          ;
        v3_p := vlist[v];              {get pointer to new vertex descriptor}
        c3_p := addr(ca[v & 3]);       {use new spare vertex cache}
        c3_p^.version := version_invalid;
{
*   All the per-vertex info is all set up for this triangle.
}
        e1.x :=                        {make edge vector from vetex 1 to 2}
          v2_p^[rend_coor_p_ind].coor_p^.x - v1_p^[rend_coor_p_ind].coor_p^.x;
        e1.y :=
          v2_p^[rend_coor_p_ind].coor_p^.y - v1_p^[rend_coor_p_ind].coor_p^.y;
        e1.z :=
          v2_p^[rend_coor_p_ind].coor_p^.z - v1_p^[rend_coor_p_ind].coor_p^.z;

        e2.x :=                        {make edge vector from vetex 1 to 3}
          v3_p^[rend_coor_p_ind].coor_p^.x - v1_p^[rend_coor_p_ind].coor_p^.x;
        e2.y :=
          v3_p^[rend_coor_p_ind].coor_p^.y - v1_p^[rend_coor_p_ind].coor_p^.y;
        e2.z :=
          v3_p^[rend_coor_p_ind].coor_p^.z - v1_p^[rend_coor_p_ind].coor_p^.z;

        gnorm.x := (e1.y * e2.z) - (e1.z * e2.y); {E1 x E2 is geometric normal}
        gnorm.y := (e1.z * e2.x) - (e1.x * e2.z);
        gnorm.z := (e1.x * e2.y) - (e1.y * e2.x);
        rend_internal.tri_cache_3d^ (  {draw this triangle}
          v1_p^, v2_p^, v3_p^, c1_p^, c2_p^, c3_p^, gnorm);
        end;                           {back for next triangle in strip}
      end                              {end of vertex caches globally disabled case}
    ;
  end;
