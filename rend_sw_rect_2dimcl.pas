{   Subroutine REND_SW_RECT_2DIMCL (DX,DY)
*
*   Draw an axis aligned rectangle.  The current point is at one corner, and
*   DX,DY is the displacement to the other corner.
}
module rend_sw_rect_2dimcl;
define rend_sw_rect_2dimcl;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_rect_2dimcl_d.ins.pas';

procedure rend_sw_rect_2dimcl (        {axis aligned rectangle at current point}
  in      dx, dy: real);               {displacement from curr pnt to opposite corner}
  val_param;

var
  in_v: rend_2dverts_t;                {verticies of the polygon}
  cl_n: sys_int_machine_t;             {number of verticies in clipped polygon}
  cl_poly: rend_2dverts_t;             {verticies of clipped polygon}
  state: rend_clip_state_k_t;          {clipping internal state}
  i: sys_int_machine_t;                {loop counter}
  j: sys_int_machine_t;                {scratch vertex ID}

label
  loop, poly, next_clipped;

begin
{
*   Write the verticies of the rectangle into a polygon descriptor so that it can
*   be passed thru the clip check.
}
  if dx >= 0.0                         {check horizontal rectangle direction}
    then begin                         {rectangle extends to the right}
      in_v[2].x := rend_2d.curr_x2dim;
      in_v[3].x := rend_2d.curr_x2dim;
      in_v[1].x := rend_2d.curr_x2dim + dx;
      in_v[4].x := in_v[1].x;
      end
    else begin                         {rectangle extends to the left}
      in_v[1].x := rend_2d.curr_x2dim;
      in_v[4].x := rend_2d.curr_x2dim;
      in_v[2].x := rend_2d.curr_x2dim + dx;
      in_v[3].x := in_v[2].x;
      end
    ;
  if dy < 0.0                          {check vertical rectangle direction}
    then begin                         {rectangle extends upwards}
      in_v[3].y := rend_2d.curr_y2dim;
      in_v[4].y := rend_2d.curr_y2dim;
      in_v[1].y := rend_2d.curr_y2dim+dy;
      in_v[2].y := in_v[1].y;
      end
    else begin                         {rectangle extends downwards}
      in_v[1].y := rend_2d.curr_y2dim;
      in_v[2].y := rend_2d.curr_y2dim;
      in_v[3].y := rend_2d.curr_y2dim+dy;
      in_v[4].y := in_v[3].y;
      end
    ;
{
*   The array IN_V contains the verticies of the rectangle expressed as a polygon.
*   Vertex 1 is the top right rectangle corner.  The other verticies proceed
*   counter-clockwise.
}
  state := rend_clip_state_start_k;    {init internal clipping state}

loop:                                  {back here for each clipped polygon fragment}
  rend_get.clip_poly_2dimcl^ (         {get next clipped polygon fragment}
    state,                             {internal clipping state}
    4,                                 {number of verticies in unlipped polygon}
    in_v,                              {verticies of the unclipped polygon}
    cl_n,                              {number of verticies in this clipped fragement}
    cl_poly);                          {verticies of the clipped polygon fragment}
  if state = rend_clip_state_end_k then return; {no more output polygon fragements ?}
{
*   The current clipped polygon fragment verticies are in CL_POLY, and the number
*   of verticies are in CL_N.
}
  if cl_n <> 4 then goto poly;         {no longer a rectangle ?}
  for i := 1 to 4 do begin             {check each vertex for being current point}
    if cl_poly[i].x <> rend_2d.curr_x2dim {not at current point X coor ?}
      then next;
    if cl_poly[i].y <> rend_2d.curr_y2dim {not at current point Y coor ?}
      then next;
    j := i + 2;                        {make index for opposite corner}
    if j > 4 then j:=j-4;              {handle wrap around}
    rend_prim.rect_2dim^ (             {pass on rectangle to 2DIM space}
      cl_poly[j].x - cl_poly[i].x,     {X size}
      cl_poly[j].y - cl_poly[i].y);    {Y size}
    goto next_clipped;                 {done with this clip fragment}
    end;                               {back and test next vertex for being curr pnt}
{
*   The current point is not at any of the rectangle corners.
}
  rend_set.cpnt_2dim^ (cl_poly[1].x, cl_poly[1].y); {set current point to first corner}
  rend_prim.rect_2dim^ (               {draw rectangle}
    cl_poly[3].x-cl_poly[1].x,         {X size}
    cl_poly[3].y-cl_poly[1].y);        {y size}
  goto next_clipped;                   {done with this rectangle fragment}
{
*   The clipped fragment is not an axis aligned rectangle.
}
poly:                                  {jump here if handle as arbitrary polygon}
  if cl_n >= 3 then begin              {this polygon fragement exists ?}
    rend_prim.poly_2dim^ (cl_n, cl_poly); {draw this clipped polygon fragment}
    end;
next_clipped:
  if state <> rend_clip_state_last_k then goto loop; {back for the next fragment ?}
  end;
