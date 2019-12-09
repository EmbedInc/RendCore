{   Subroutine REND_SW_NSUBPIX_POLY_2DIM (N,VERTS)
*
*   Convert a subpixel addressed polygon to one that has the verticies snapped
*   to pixel centers.  This routine snaps the verticies and then calls the subroutine
*   pointed to by REND_POLY_STATE.SAVED_POLY_2DIM.
*
*   PRIM_DATA prim_data_p rend_poly_state.saved_poly_2dim_data_p
}
module rend_sw_nsubpix_poly_2dim;
define rend_sw_nsubpix_poly_2dim;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_nsubpix_poly_2dim_d.ins.pas';

procedure rend_sw_nsubpix_poly_2dim (  {convert subpixel to integer polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;

var
  v: rend_2dverts_t;                   {coordinates of snapped verticies}
  i: sys_int_machine_t;                {loop counter}
  max_y, min_y: real;                  {polygon top and bottom}

begin
  min_y := 1.0E35;
  max_y := -1.0E35;
  for i := 1 to n do begin             {once for each vertex}
    v[i].x :=
      min(trunc(verts[i].x), rend_clip_2dim.ixmax) + 0.5;
    v[i].y :=
      min(trunc(verts[i].y), rend_clip_2dim.iymax) + 0.5;
    min_y := min(min_y, v[i].y);
    max_y := max(max_y, v[i].y);
    end;                               {back for next vertex in polygon}
  for i := 1 to n do begin             {once for each vertex}
    if v[i].y = min_y
      then v[i].y := v[i].y - 0.001;
    if v[i].y = max_y
      then v[i].y := v[i].y + 0.001;
    end;
  rend_poly_state.saved_poly_2dim^ (n, v); {call normal subpixel polygon routine}
  end;
