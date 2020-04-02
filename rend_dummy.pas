{   Module of routines that just return.  These routines may be installed
*   into the call tables to disable particular functions.  They are usually
*   installed in response to the REND_BENCH flags.
}
module rend_dummy;
define rend_dummy_poly_2d;
define rend_dummy_quad_3d;
define rend_dummy_tri_3d;
define rend_dummy_tri_cache_3d;
define rend_dummy_tstrip_3d;
%include 'rend2.ins.pas';

define
  rend_dummy_poly_2d_d := [
    call_adr := addr(rend_dummy_poly_2d),
    name := [
      str := 'rend_dummy_poly_2d',
      len := 18,
      max := sizeof(rend_dummy_poly_2d_d.name.str)
      ],
    self_p := addr(rend_dummy_poly_2d_d),
    sw_read := rend_access_no_k,
    sw_write := rend_access_no_k,
    n_prims := 0,
    called_prims := [
      nil,
      nil,
      nil,
      nil
      ]
    ];

define
  rend_dummy_quad_3d_d := [
    call_adr := addr(rend_dummy_quad_3d),
    name := [
      str := 'rend_dummy_quad_3d',
      len := 18,
      max := sizeof(rend_dummy_quad_3d_d.name.str)
      ],
    self_p := addr(rend_dummy_quad_3d_d),
    sw_read := rend_access_no_k,
    sw_write := rend_access_no_k,
    n_prims := 0,
    called_prims := [
      nil,
      nil,
      nil,
      nil
      ]
    ];

define
  rend_dummy_tri_3d_d := [
    call_adr := addr(rend_dummy_tri_3d),
    name := [
      str := 'rend_dummy_tri_3d',
      len := 17,
      max := sizeof(rend_dummy_tri_3d_d.name.str)
      ],
    self_p := addr(rend_dummy_tri_3d_d),
    sw_read := rend_access_no_k,
    sw_write := rend_access_no_k,
    n_prims := 0,
    called_prims := [
      nil,
      nil,
      nil,
      nil
      ]
    ];

define
  rend_dummy_tri_cache_3d_d := [
    call_adr := addr(rend_dummy_tri_cache_3d),
    name := [
      str := 'rend_dummy_tri_cache_3d',
      len := 23,
      max := sizeof(rend_dummy_tri_cache_3d_d.name.str)
      ],
    self_p := addr(rend_dummy_tri_cache_3d_d),
    sw_read := rend_access_no_k,
    sw_write := rend_access_no_k,
    n_prims := 0,
    called_prims := [
      nil,
      nil,
      nil,
      nil
      ]
    ];

define
  rend_dummy_tstrip_3d_d := [
    call_adr := addr(rend_dummy_tstrip_3d),
    name := [
      str := 'rend_dummy_tstrip_3d',
      len := 20,
      max := sizeof(rend_dummy_tstrip_3d_d.name.str)
      ],
    self_p := addr(rend_dummy_tstrip_3d_d),
    sw_read := rend_access_no_k,
    sw_write := rend_access_no_k,
    n_prims := 0,
    called_prims := [
      nil,
      nil,
      nil,
      nil
      ]
    ];
{
************************************************
}
procedure rend_dummy_poly_2d (         {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;

begin
  end;
{
************************************************
}
procedure rend_dummy_quad_3d (         {draw 3D model space quadrilateral}
  in      v1, v2, v3, v4: univ rend_vert3d_t); {pointer info for each vertex}
  val_param;

begin
  end;
{
************************************************
}
procedure rend_dummy_tri_3d (          {draw 3D model space triangle}
  in      v1, v2, v3: univ rend_vert3d_t; {pointer info for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}

begin
  end;
{
************************************************
}
procedure rend_dummy_tri_cache_3d (    {3D triangle explicit caches for each vert}
  in      v1, v2, v3: univ rend_vert3d_t; {descriptor for each vertex}
  in out  ca1, ca2, ca3: rend_vcache_t; {explicit cache for each vertex}
  in      gnorm: vect_3d_t);           {geometric unit normal vector}
  val_param;

begin
  end;
{
************************************************
}
procedure rend_dummy_tstrip_3d (       {draw connected strip of triangles}
  in      vlist: univ rend_vert3d_p_list_t; {list of pointers to vertex descriptors}
  in      nverts: sys_int_machine_t);  {number of verticies in VLIST}
  val_param;

begin
  end;
