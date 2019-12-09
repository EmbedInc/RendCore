{   Subroutine REND_SW_POLY_2DIM (N,VERTS)
*
*   Draw a polygon in 2D image coordinate space.  N is the number of verticies in
*   the polygon.  N must not be less than 3.  VERTS contains the list of verticies
*   in counter-clockwise order when viewed in the final image.  No clipping is done,
*   and the polygon must be convex.
}
module rend_sw_poly_2dim;
define rend_sw_poly_2dim;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_poly_2dim_d.ins.pas';

procedure rend_sw_poly_2dim (          {convex polygon}
  in      n: sys_int_machine_t;        {number of verticies in VERTS}
  in      verts: univ rend_2dverts_t); {verticies in counter-clockwise order}
  val_param;

var
  i: sys_int_machine_t;                {loop counter}
  lowy: real;                          {lowest Y coordinate of any vertex}
  lowyv: sys_int_machine_t;            {vertex number with lowest Y}
  highy: real;                         {highest Y coordinate of any vertex}
  highyv: sys_int_machine_t;           {vertex number with highest Y}
  lefte, righte: sys_int_machine_t;    {number of edges on left and right sides}
  leftvt, leftvb: sys_int_machine_t;   {top and bottom vertex numbers for left edge}
  rightvt, rightvb: sys_int_machine_t; {top and bottom vertex numbers for right edge}
  done_left, done_right: boolean;      {TRUE if done with curr left or right edge}
  left_to_right: boolean;              {trapezoid scan direction flag}
  tri:                                 {triangle for recursive call}
    array[1..3] of vect_2d_t;
  mid1, mid2, mid3: vect_2d_t;         {midpoints of triangle for recursive triangles}
  ofs_left_l, ofs_left_t: real;        {X offsets for left leading and trailing edges}
  ofs_right_l, ofs_right_t: real;      {X offsets for right leading and trailing edges}

label
  too_big, size_ok, loop;

begin
  lowy := verts[1].y;                  {init min and max Y range}
  highy := lowy;
  lowyv := 1;                          {init min and max Y vertex numbers}
  highyv := 1;
  for i := 2 to n do begin             {once for each remaining vertex}
    if verts[i].y < lowy then begin    {found new lowest Y coordinate ?}
      lowy := verts[i].y;
      lowyv := i;
      end;
    if verts[i].y > highy then begin   {found new highest Y coordinate ?}
      highy := verts[i].y;
      highyv := i;
      end;
    end;                               {back and check next vertex for min/max}
{
*   Check whether this polygon needs to be broken up into smaller pieces to
*   stay within the interpolator accuracy limits.  If the input polygon is a
*   triangle and it is too big, then it is broken into 4 triangles and this routine
*   is called recursively.  For polygons that may be too big and have more than
*   3 verticies, the polygon is broken into triangles and this routine called
*   recursively.
}
  if not rend_check_run_size           {no need to check polygon size ?}
    then goto size_ok;
  for i := 2 to n do begin             {once for each vertex except leading edge top}
    if i = lowyv then next;            {don't compare to reference vertex}
    if trunc(abs(verts[i].x-verts[lowyv].x) + abs(verts[i].y-verts[lowyv].y))
        > rend_max_allowed_run         {this vertex too far from top vertex ?}
      then goto too_big;               {this polygon needs to be broken up}
    end;                               {back and check next vertex}
  goto size_ok;                        {this polygon definately within size limit}

too_big:                               {this polygon must be broken up}
  if n = 3 then begin                  {this polygon is a triangle ?}
    mid1.x := 0.5 * (verts[1].x + verts[2].x); {make edge mid points of big triangle}
    mid1.y := 0.5 * (verts[1].y + verts[2].y);
    mid2.x := 0.5 * (verts[2].x + verts[3].x);
    mid2.y := 0.5 * (verts[2].y + verts[3].y);
    mid3.x := 0.5 * (verts[3].x + verts[1].x);
    mid3.y := 0.5 * (verts[3].y + verts[1].y);
    tri[1] := mid1;                    {recursively call with 4 smaller triangles}
    tri[2] := verts[2];
    tri[3] := mid2;
    rend_prim.poly_2dim^ (3, tri);
    tri[2] := mid2;
    tri[3] := mid3;
    rend_prim.poly_2dim^ (3, tri);
    tri[2] := mid3;
    tri[3] := verts[1];
    rend_prim.poly_2dim^ (3, tri);
    tri[1] := verts[3];
    tri[3] := mid2;
    rend_prim.poly_2dim^ (3, tri);
    return;                            {done with top level polygon}
    end;

  tri[1] := verts[1];                  {init first vertex of each triangle}
  for i := 2 to n-1 do begin           {once for each triangle to break off}
    tri[2] := verts[i];
    tri[3] := verts[i+1];
    rend_prim.poly_2dim^ (3, tri);     {draw this triangle recursively}
    end;                               {back and break off next triangular piece}
  return;                              {everything has been drawn recursively}

size_ok:                               {polygon is definately within size limit}
  lefte := highyv - lowyv;             {init number of edges on left side of polygon}
  if lefte < 0 then lefte := lefte+n;  {compensate for wrap around}
  righte := lowyv - highyv;            {init number of edges on right side of polygon}
  if righte < 0 then righte := righte + n; {compensate for wrap around}
  left_to_right := lefte <= righte;    {set scan dir to minimize leading edges}
  if left_to_right                     {set direction flag in common block}
    then rend_dir_flag := rend_dir_right_k
    else rend_dir_flag := rend_dir_left_k;
  leftvb := lowyv;                     {init bottom of previous left edge}
  rightvb := lowyv;                    {init bottom of previous right edge}
  done_left := true;                   {init to current edges exhausted}
  done_right := true;
  if rend_poly_parms.subpixel
    then begin                         {subpixel addressing is ON}
      ofs_left_l := 0.5;
      ofs_left_t := -0.5;
      ofs_right_l := -0.5;
      ofs_right_t := 0.5;
      end
    else begin                         {subpixel addressing is OFF}
      ofs_left_l := 0.0;
      ofs_left_t := -1.0;
      ofs_right_l := 0.0;
      ofs_right_t := 1.0;
      end
    ;

loop:                                  {back here to do next trapezoid down}
  if done_left then begin              {left edge has been exhausted ?}
    leftvt := leftvb;                  {old edge bottom is new edge top}
    leftvb := leftvt+1;                {bottom is counter-clockwise one vertex}
    if leftvb > n then leftvb := 1;    {compensate for wrap around}
    if (leftvb = rightvb) and done_right then return; {edges "crossed" at bottom ?}
    if left_to_right

      then begin                       {this new left edge is a leading edge}
        rend_internal.bres_fp^ (       {set up new leading left edge}
          rend_lead_edge,              {Bresenham stepper data structure}
          verts[leftvt].x+ofs_left_l,  {X coor of top point}
          verts[leftvt].y,             {Y coor of top point}
          verts[leftvb].x+ofs_left_l,  {X coor of bottom point}
          verts[leftvb].y,             {Y coor of bottom point}
          false);                      {Y is major axis}
        if rend_lead_edge.length > 0 then begin {actually something to draw here ?}
          rend_set.cpnt_2dimi^ (       {set starting pixel as current point}
            rend_lead_edge.x, rend_lead_edge.y);
          rend_internal.setup_iterps^; {set up interpolators for new leading edge}
          end;
        end                            {done with new leading left edge}

      else begin                       {this new left edge is a trailing edge}
        rend_internal.bres_fp^ (       {set up new trailing left edge}
          rend_trail_edge,             {Bresenham stepper data structure}
          verts[leftvt].x+ofs_left_t,  {X coor of top point}
          verts[leftvt].y,             {Y coor of top point}
          verts[leftvb].x+ofs_left_t,  {X coor of bottom point}
          verts[leftvb].y,             {Y coor of bottom point}
          false);                      {Y is major axis}
        end                            {done with new trailing left edge}
      ;
    end;                               {done handling new left edge}

  if done_right then begin             {right edge has been exhausted ?}
    rightvt := rightvb;                {old edge bottom is new edge top}
    rightvb := rightvt-1;              {bottom is clockwise one vertex}
    if rightvb <= 0 then rightvb := n; {compensate for wrap around}
    if left_to_right

      then begin                       {this new right edge is a trailing edge}
        rend_internal.bres_fp^ (       {set up new trailing right edge}
          rend_trail_edge,             {Bresenham stepper data structure}
          verts[rightvt].x+ofs_right_t, {X coor of top point}
          verts[rightvt].y,            {Y coor of top point}
          verts[rightvb].x+ofs_right_t, {X coor of bottom point}
          verts[rightvb].y,            {Y coor of bottom point}
          false);                      {Y is major axis}
        end                            {done with new trailing right edge}

      else begin                       {this new right edge is a leading edge}
        rend_internal.bres_fp^ (       {set up new leading right edge}
          rend_lead_edge,              {Bresenham stepper data structure}
          verts[rightvt].x+ofs_right_l, {X coor of top point}
          verts[rightvt].y,            {Y coor of top point}
          verts[rightvb].x+ofs_right_l, {X coor of bottom point}
          verts[rightvb].y,            {Y coor of bottom point}
          false);                      {Y is major axis}
        if rend_lead_edge.length > 0 then begin {actually something to draw here ?}
          rend_set.cpnt_2dimi^ (       {set starting pixel as current point}
            rend_lead_edge.x, rend_lead_edge.y);
          rend_internal.setup_iterps^; {set up interpolators for new leading edge}
          end;
        end                            {done with new leading right edge}
      ;
    end;                               {done handling new right edge}

  rend_internal.tzoid^;                {draw this trapezoid}
  if leftvb = rightvb then return;     {left and right edges met ?}
  if left_to_right                     {check which side leading/trailing edges on}
    then begin                         {leading on left, trailing on right}
      done_left := rend_lead_edge.length <= 0;
      done_right := rend_trail_edge.length <= 0;
      end
    else begin                         {leading on right, trailing on left}
      done_left := rend_trail_edge.length <= 0;
      done_right := rend_lead_edge.length <= 0;
      end
    ;
  goto loop;                           {back and process with new edge}
  end;
