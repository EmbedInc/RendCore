{   Subroutine REND_SW_VECT_POLY (X,Y)
*
*   Convert a vector to a polygon and send it on down the pipe.
*   The entry point address for this routine is usually used to replace an existing
*   2D vector primitive in the rendering pipe.  The resulting polygon will be passed
*   to a 2D polygon routine.  The address of the REND_PRIM entry for the 2D polygon
*   routine is in REND_VECT_STATE.POLY_PROC.
*
*   PRIM_DATA prim_data_p rend_vect_state.poly_proc_data_p
}
module rend_sw_vect_poly;
define rend_sw_vect_poly;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_vect_poly_d.ins.pas';

procedure rend_sw_vect_poly (          {convert vector to a polygon}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;

var
  xbx, xby: real;                      {X basis vector for end cap transform}
  ybx, yby: real;                      {Y basis vector for end cap transform}
  ofsx, ofsy: real;                    {offset vector for end cap transform}
  m: real;                             {vector magnitude mult factor}
  poly: rend_2dverts_t;                {vertex list of resulting polygon}
  nv: sys_int_machine_t;               {number of verticies in POLY}
{
************************************************
*
*   Internal subroutine ADD_CAP (CAP)
*
*   Add the vertex list for this end cap to the polygon vertex list in POLY.
*   CAP is the descriptor for this end cap.
}
procedure add_cap (
  in      cap: rend_vectcap_t);        {descriptor for this end cap}

var
  i: sys_int_machine_t;                {loop counter}

begin
  for i := 1 to cap.n do begin         {once for each vertex in this cap}
    nv := nv+1;                        {one more vertex in POLY array}
    poly[nv].x :=                      {X coordinate of this vertex}
      cap.vert[i].x*xbx + cap.vert[i].y*ybx + ofsx;
    poly[nv].y :=                      {Y coordinate of this vertex}
      cap.vert[i].x*xby + cap.vert[i].y*yby + ofsy;
    end;                               {back for next vertex in this end cap}
  end;
{
************************************************
*
*   Code for main routine.
}
begin
  if (rend_vect_state.start_cap.n+rend_vect_state.end_cap.n) > rend_max_verts
      then begin
    writeln ('Polygon created by this vector has too many verticies in subroutine');
    writeln ('REND_SW_VECT_POLY.');
    sys_bomb;
    end;
  nv := 0;                             {init number of verticies in POLY array}
{
*   Set up an internal 2D transform to go from the vector's space to the
*   polygon's space.  The XB vector is always pointing in the direction
*   of the vector and has a length equal to the width radius of the vector.
*   The YB vector is perpendicular to XB so as to form a right handed
*   coordinate system.  The start and end caps have been defined for a
*   vector going in the +X direction and a width radius of 1.0.  Therefore,
*   assuming semi-circular end caps, the coordinates in the start and end
*   caps would form a unit circle about the origin.  The start cap would
*   contain points counter-clockwise from PI/2 to -PI/2.  The end cap
*   would contain counter-clockwise points from -PI/2 to PI/2.  The start
*   and end cap would each contain the same coordinate at PI/2 and -PI/2.
*   The long sides of the vector polygon go between these when each end
*   cap is displaced to its respective end point.
}
  xbx := x-rend_vect_state.cpnt_p^.x;  {init direction of XB}
  xby := y-rend_vect_state.cpnt_p^.y;
  m := sqr(xbx)+sqr(xby);              {current XB magnitude squared}
  if m < 1.0e-30                       {check input vector length}
    then begin                         {input vector start and end point are the same}
      xbx := 0.5*rend_vect_parms.width; {pick an easy set of orthagonal vectors}
      xby := 0.0;
      ybx := 0.0;
      yby := xbx;
      end
    else begin                         {input vector had recognizable length}
      m := (0.5*rend_vect_parms.width)/sqrt(m); {mult factor for XB, YB magnitude}
      xbx := xbx*m;                    {adjust XB to magnitude of width radius}
      xby := xby*m;
      ybx := -xby;                     {make right angle vector for right handed coor}
      yby := xbx;
      end
    ;                                  {XB and YB all set for vector start cap}
  if (rend_vect_parms.poly_level = rend_space_2dim_k)
      or (rend_vect_parms.poly_level = rend_space_2dimcl_k)
      then begin                       {left handed coordinate space ?}
    ybx := -ybx;                       {flip the handedness of the local transform}
    yby := -yby;
    end;
  ofsx := rend_vect_state.cpnt_p^.x;   {set offset vector to start point}
  ofsy := rend_vect_state.cpnt_p^.y;
  add_cap (rend_vect_state.start_cap); {add start cap to polygon vertex list}

  ofsx := x;                           {move displacement to vector end point}
  ofsy := y;
  add_cap (rend_vect_state.end_cap);   {add end cap to polygon vertex list}
{
*   The complete polygon is sitting in POLY.  Now pass this polygon on down the pipe.
}
  rend_vect_state.poly_proc_p^^ (      {call polygon draw procedure}
    nv,                                {number of verticies in polygon}
    poly);                             {counter-clockwise polygon vertex list}
  rend_vect_state.cpnt_proc_p^^ (x, y); {leave current point at vector end point}
  end;
