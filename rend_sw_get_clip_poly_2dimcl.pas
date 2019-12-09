{   Subroutine REND_SW_GET_CLIP_POLY_2DIMCL (STATE, IN_N, IN_POLY, OUT_N, OUT_POLY)
*
*   Clip the 2D input polygon to produce the 2D output polygon.
*   The STATE variable is handled in the same way as for the
*   CLIP_VECT routines. OUT_N is also set to zero if there is no
*   output polygon.
}
module rend_sw_get_clip_poly_2dimcl;
define rend_sw_get_clip_poly_2dimcl;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_clip_poly_2dimcl ( {run polygon thru 2DIMCL clipping}
  in out  state: rend_clip_state_k_t;  {for remembering multiple output fragments}
  in      in_n: sys_int_machine_t;     {number of verticies in input polygon}
  in      in_poly: rend_2dverts_t;     {verticies of input polygon}
  out     out_n: sys_int_machine_t;    {number of verts in this output fragment}
  out     out_poly: rend_2dverts_t);   {verticies in this output fragment}
  val_param;

var
  sply: rend_2dverts_t;                {scratch poly arrays for clipping}
  poly: rend_2dverts_t;
  sverts: sys_int_machine_t;           {number of vertices in SPLY}
  nverts: sys_int_machine_t;           {number of vertices in POLY}
  prev_v: sys_int_machine_t;           {number of previous vertex}
  v: sys_int_machine_t;                {current vertex number}
  m: real;                             {for finding intersection}
  clip_minx: real;                     {coordinates of clip rectangle}
  clip_maxx: real;
  clip_miny: real;
  clip_maxy: real;
  prev_in: boolean;                    {previous vertex was clipped in}
  this_in: boolean;                    {this vertex is clipped in}

label
  clipped, next_v1, next_v2, next_v3, next_v4, none_out;

begin
  if (not rend_clip_2dim.exists) or (not rend_clip_2dim.draw_inside) then begin
    rend_message_bomb ('rend', 'rend_clip_complicated_cpoly', nil, 0);
    end;

  if state <> rend_clip_state_start_k then begin {no more polygons left ?}
none_out:                              {jump here to return no polygon}
    state := rend_clip_state_end_k;
    out_n := 0;                        {indicate empty polygon being returned}
    return;
    end;

  clip_minx := rend_clip_2dim.xmin;    {make local copy of clip rectangle}
  clip_maxx := rend_clip_2dim.xmax;
  clip_miny := rend_clip_2dim.ymin;
  clip_maxy := rend_clip_2dim.ymax;
{
*   Do a quick test to see if the polygon is not clipped at all.
}
  for v := 1 to in_n do begin          {once for each vertex}
    if in_poly[v].x < clip_minx then goto clipped;
    if in_poly[v].x > clip_maxx then goto clipped;
    if in_poly[v].y < clip_miny then goto clipped;
    if in_poly[v].y > clip_maxy then goto clipped;
    out_poly[v] := in_poly[v];
    end;
  out_n := in_n;
  state := rend_clip_state_last_k;
  return;
{
*   Clip the polygon in IN_POLY by the left edge and put the new polygon into
*   SPLY.
}
clipped:                               {jump here if the polygon needs clipping}
  sverts := 0;                         {init number of output vertices}
  prev_in := in_poly[in_n].x >= clip_minx; {init previous vert clipped in flag}
  prev_v := in_n;                      {init previous vertex to last vertex}
  for v := 1 to in_n do begin          {once for each vertex in input polygon}
    this_in := in_poly[v].x >= clip_minx; {set this vertex clipped in flag}
    if not (this_in or prev_in)        {both clipped out ?}
      then goto next_v1;               {on to next vertex}
    if sverts < rend_max_verts         {still room for another output vertex ?}
      then sverts := sverts+1;         {one more output vertex}
    if this_in and prev_in then begin  {no problem, everything clipped in ?}
      sply[sverts] := in_poly[v];      {copy vertex to output polygon}
      goto next_v1;                    {on to next input vertex}
      end;
    m :=                               {fraction along edge}
      (clip_minx-in_poly[prev_v].x)/(in_poly[v].x-in_poly[prev_v].x);
    sply[sverts].x := clip_minx;       {add intersect vertex to output poly}
    sply[sverts].y := (1.0-m)*in_poly[prev_v].y+m*in_poly[v].y;
    if this_in then begin              {this point needs to be added too ?}
      if sverts < rend_max_verts then sverts:=sverts+1; {room for one more vertex ?}
      sply[sverts] := in_poly[v];      {copy vertex to output polygon}
      end;
next_v1:                               {jump here to advance to next input vertex}
    prev_in := this_in;                {this vertex becomes previous vertex}
    prev_v := v;
    end;                               {back and do next input vertex}
{
*   Clip the polygon in SPLY by the right edge and put the new polygon into
*   POLY.
}
  if sverts < 3 then goto none_out;    {not a valid polygon ?}
  nverts := 0;                         {init number of output vertices}
  prev_in := sply[sverts].x <= clip_maxx; {init previous vert clipped in flag}
  prev_v := sverts;                    {init previous vertex to last vertex}
  for v := 1 to sverts do begin        {once for each vertex in input polygon}
    this_in := sply[v].x <= clip_maxx; {set this vertex clipped in flag}
    if not (this_in or prev_in)        {both clipped out ?}
      then goto next_v2;               {on to next vertex}
    if nverts < rend_max_verts         {still room for another output vertex ?}
      then nverts := nverts+1;         {one more output vertex}
    if this_in and prev_in then begin  {no problem, everything clipped in ?}
      poly[nverts] := sply[v];         {copy vertex to output polygon}
      goto next_v2;                    {on to next input vertex}
      end;
    m := (clip_maxx-sply[prev_v].x)/(sply[v].x-sply[prev_v].x); {fract along edge}
    poly[nverts].x := clip_maxx;       {add intersect vertex to output poly}
    poly[nverts].y := (1.0-m)*sply[prev_v].y+m*sply[v].y;
    if this_in then begin              {this point needs to be added too ?}
      if nverts < rend_max_verts then nverts:=nverts+1; {room for one more vertex ?}
      poly[nverts] := sply[v];         {copy vertex to output polygon}
      end;
next_v2:                               {jump here to advance to next input vertex}
    prev_in := this_in;                {this vertex becomes previous vertex}
    prev_v := v;
    end;                               {back and do next input vertex}
{
*   Clip the polygon in POLY by the bottom edge and put the new polygon into
*   SPLY.
}
  if nverts < 3 then goto none_out;    {not a valid polygon ?}
  sverts := 0;                         {init number of output vertices}
  prev_in := poly[nverts].y >= clip_miny; {init previous vert clipped in flag}
  prev_v := nverts;                    {init previous vertex to last vertex}
  for v := 1 to nverts do begin        {once for each vertex in input polygon}
    this_in := poly[v].y >= clip_miny; {set this vertex clipped in flag}
    if not (this_in or prev_in)        {both clipped out ?}
      then goto next_v3;               {on to next vertex}
    if sverts < rend_max_verts         {still room for another output vertex ?}
      then sverts := sverts+1;         {one more output vertex}
    if this_in and prev_in then begin  {no problem, everything clipped in ?}
      sply[sverts] := poly[v];         {copy vertex to output polygon}
      goto next_v3;                    {on to next input vertex}
      end;
    m := (clip_miny-poly[prev_v].y)/(poly[v].y-poly[prev_v].y); {fract along edge}
    sply[sverts].y := clip_miny;       {add intersect vertex to output poly}
    sply[sverts].x := (1.0-m)*poly[prev_v].x+m*poly[v].x;
    if this_in then begin              {this point needs to be added too ?}
      if sverts < rend_max_verts then sverts:=sverts+1; {room for one more vertex ?}
      sply[sverts] := poly[v];         {copy vertex to output polygon}
      end;
next_v3:                               {jump here to advance to next input vertex}
    prev_in := this_in;                {this vertex becomes previous vertex}
    prev_v := v;
    end;                               {back and do next input vertex}
{
*   Clip the polygon in SPLY by the top edge and put the new polygon into OUT_POLY.
}
  if sverts < 3 then goto none_out;    {not a valid polygon ?}
  out_n := 0;                          {init number of output vertices}
  prev_in := sply[sverts].y <= clip_maxy; {init previous vert clipped in flag}
  prev_v := sverts;                    {init previous vertex to last vertex}
  for v := 1 to sverts do begin        {once for each vertex in input polygon}
    this_in := sply[v].y <= clip_maxy; {set this vertex clipped in flag}
    if not (this_in or prev_in)        {both clipped out ?}
      then goto next_v4;               {on to next vertex}
    if out_n < rend_max_verts          {still room for another output vertex ?}
      then out_n := out_n+1;           {one more output vertex}
    if this_in and prev_in then begin  {no problem, everything clipped in ?}
      out_poly[out_n] := sply[v];      {copy vertex to output polygon}
      goto next_v4;                    {on to next input vertex}
      end;
    m := (clip_maxy-sply[prev_v].y)/(sply[v].y-sply[prev_v].y); {fract along edge}
    out_poly[out_n].y := clip_maxy;    {add intersect vertex to output poly}
    out_poly[out_n].x := (1.0-m)*sply[prev_v].x+m*sply[v].x;
    if this_in then begin              {this point needs to be added too ?}
      if out_n < rend_max_verts then out_n:=out_n+1; {room for one more vertex ?}
      out_poly[out_n] := sply[v];      {copy vertex to output polygon}
      end;
next_v4:                               {jump here to advance to next input vertex}
    prev_in := this_in;                {this vertex becomes previous vertex}
    prev_v := v;
    end;                               {back and do next input vertex}
  if out_n < 3 then goto none_out;     {not enough left to display ?}
  state := rend_clip_state_last_k;     {yes we have a polygon, but this is last one}
  end;
