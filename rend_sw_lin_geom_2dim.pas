{   Subroutine REND_SW_LIN_GEOM_2DIM (P1, P2, P3)
*
*   Specify 3 points at which an interpolant value will be specified later.
*   The interpolant can then be set up for linear interpolation.
}
module rend_sw_lin_geom_2dim;
define rend_sw_lin_geom_2dim;
%include 'rend_sw2.ins.pas';

procedure rend_sw_lin_geom_2dim (      {set geometric info to compute linear derivs}
  in      p1, p2, p3: vect_2d_t);      {3 points where vals will be specified}
  val_param;

var
  d: real;                             {determinant used for computing derivatives}

begin
  rend_geom.p2.dx := p2.x - p1.x;      {compute geometric deltas from vertex 1}
  rend_geom.p2.dy := p2.y - p1.y;
  rend_geom.p3.dx := p3.x - p1.x;
  rend_geom.p3.dy := p3.y - p1.y;
  d :=                                 {twice area of triangle}
    (rend_geom.p3.dx * rend_geom.p2.dy) -
    (rend_geom.p2.dx * rend_geom.p3.dy);
  if abs(d) < 1.0E-10 then begin       {not enough area to define linear surface ?}
    rend_geom.valid := false;          {indicate geom data no good}
    return;                            {nothing more can be done}
    end;
  d := 1.0/d;                          {mult factor for derivatives}
  rend_geom.p2.dx := rend_geom.p2.dx * d; {pre-multiply so not needed later}
  rend_geom.p3.dx := rend_geom.p3.dx * d;
  rend_geom.p2.dy := rend_geom.p2.dy * d;
  rend_geom.p3.dy := rend_geom.p3.dy * d;
  rend_geom.p1.coor := p1;             {save coordinates of anchor point}
  rend_geom.valid := true;             {geom data is OK to use}
  end;
