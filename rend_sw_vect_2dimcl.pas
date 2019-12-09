{   Subroutine REND_SW_VECT_2DIMCL (X,Y)
*
*   Draw a vector in the 2D image coordinate space, but clip it first.
}
module rend_sw_vect_2dimcl;
define rend_sw_vect_2dimcl;
%include 'rend_sw2.ins.pas';
%include 'rend_sw_vect_2dimcl_d.ins.pas';

procedure rend_sw_vect_2dimcl (        {vector from curr pnt to new absolute point}
  in      x, y: real);                 {coor of end point and new current point}
  val_param;

var
  v_2dim: rend_2dvect_t;               {vector in 2D image space}
  clv: rend_2dvect_t;                  {clipped result fragment of this vector}
  state: rend_clip_state_k_t;          {clipping internal state}

label
  loop, done_frags;

begin
  v_2dim.p1.x := rend_2d.curr_x2dim;   {fill in start and end verticies of vector}
  v_2dim.p1.y := rend_2d.curr_y2dim;
  v_2dim.p2.x := x;
  v_2dim.p2.y := y;

  state := rend_clip_state_start_k;    {init internal clipping state}

loop:                                  {back here for each new vector fragment}
  rend_get.clip_vect_2dimcl^ (         {get next clipped vector fragment}
    state,                             {internal clipping state}
    v_2dim,                            {the unclipped vector}
    clv);                              {the clipped output vector fragment}
  if state = rend_clip_state_end_k     {no more output vector fragments ?}
    then goto done_frags;
  if (clv.p1.x <> rend_2d.curr_x2dim)  {this fragment not start at current point ?}
      or (clv.p1.y <> rend_2d.curr_y2dim) then begin
    rend_set.cpnt_2dim^ (clv.p1.x, clv.p1.y); {set current point to this vector start}
    end;
  rend_prim.vect_2dim^ (clv.p2.x, clv.p2.y); {draw this vector fragment}
  if state <> rend_clip_state_last_k then goto loop; {back for the next fragment ?}

done_frags:                            {all done drawing vector fragments}
  rend_2d.curr_x2dim := x;             {update 2DIM space current point}
  rend_2d.curr_y2dim := y;
  if (rend_2d.curr_x2dim <> v_2dim.p2.x) {2DIM current point needs to be updated ?}
      or (rend_2d.curr_y2dim <> v_2dim.p2.y) then begin
    rend_set.cpnt_2dim^ (v_2dim.p2.x, v_2dim.p2.y); {set 2DIM current point}
    end;
  end;
