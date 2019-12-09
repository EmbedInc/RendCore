{   Subroutine REND_SW_POLY_2DIMCL (N,VERTS)
*
*   Draw a polygon in 2D image space, but clip first.  N is the number of vertices
*   in the polygon.  VERTS is an array containing one XY pair for each
*   vertex.  The vertices must be in counter clockwise order when viewed
*   in the final image, and the polygon must be convex.
}
module rend_sw_poly_2dimcl;
define rend_sw_poly_2dimcl;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_poly_2dimcl_d.ins.pas';

procedure rend_sw_poly_2dimcl (        {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;

var
  cl_n: sys_int_machine_t;             {number of verticies in clipped polygon}
  cl_poly: rend_2dverts_t;             {verticies of clipped polygon}
  state: rend_clip_state_k_t;          {clipping internal state}

label
  loop;

begin
  state := rend_clip_state_start_k;    {init internal clipping state}

loop:                                  {back here for each clipped polygon fragment}
  rend_get.clip_poly_2dimcl^ (         {get next clipped polygon fragment}
    state,                             {internal clipping state}
    n,                                 {number of verticies in unlipped polygon}
    verts,                             {verticies of the unclipped polygon}
    cl_n,                              {number of verticies in this clipped fragement}
    cl_poly);                          {verticies of the clipped polygon fragment}
  if state = rend_clip_state_end_k then return; {no more output polygon fragements ?}
  if cl_n >= 3 then begin              {this polygon fragement exists ?}
    rend_prim.poly_2dim^ (cl_n, cl_poly); {draw this clipped polygon fragment}
    end;
  if state <> rend_clip_state_last_k then goto loop; {back for the next fragment ?}
  end;
