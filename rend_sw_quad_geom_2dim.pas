{   Subroutine REND_SW_QUAD_GEOM_2DIM (P1,P2,P3,P4,P5,P6)
*
*   Declare 6 points to which interpolant values will be anchored later.  This
*   will then be used to set interpolant(s) to quadratic interpolation.
*   This call also implicitly sets up the linear geometric information.
*   It is therefore legal, for example, to call both SET.QUAD_VALS and
*   SET.LIN_VALS after this call.  The first three points (P1-P3) will be used
*   to define the linear surface.  It is therefore important that these three
*   points be linearly independent, in addition to all six points being
*   quadratically independent.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_quad_geom_2dim;
define rend_sw_quad_geom_2dim;
%include 'rend_sw2.ins.pas';

procedure rend_sw_quad_geom_2dim (     {set geometric info to compute quad derivs}
  in      p1, p2, p3, p4, p5, p6: vect_2d_t); {6 points where vals will be specified}

var
  i: integer32;                        {loop counter}

begin
  rend_set.lin_geom_2dim^ (p1, p2, p3); {use first 3 points to set linear geom}
{
*   Later we will need to solve for the derivatives of the colors.  We will use
*   vertex one as the anchor point.  This leaves five simultaneaous equations
*   to describe the color deltas for each remaining vertex from vertex 1.
*   The simultaneous equations have the form:
*
*   d1x[dx] + d1y[dy] + d2xx[dx**2/2] + d2yy[dy**2/2] + d2xy[dx*dy] = [di]
*
*   The values in the brackets are values we have from the color and coordinate
*   information, and are different for each equation.  The values outside the
*   brackets are the derivatives we are trying to solve for.  We have to do
*   this solution once for each interpolant.  Here, stuff in the values that
*   are dependent on just the geometry and not the colors, and init the non-color
*   part of the surface definition.  We start this by filling in the DX and DY
*   terms in each equation.  We then use a loop to compute the other three terms
*   from the DX and DY.
}
  rend_geom.mat[1].dx := p2.x - p1.x;
  rend_geom.mat[1].dy := p2.y - p1.y;
  rend_geom.mat[2].dx := p3.x - p1.x;
  rend_geom.mat[2].dy := p3.y - p1.y;
  rend_geom.mat[3].dx := p4.x - p1.x;
  rend_geom.mat[3].dy := p4.y - p1.y;
  rend_geom.mat[4].dx := p5.x - p1.x;
  rend_geom.mat[4].dy := p5.y - p1.y;
  rend_geom.mat[5].dx := p6.x - p1.x;
  rend_geom.mat[5].dy := p6.y - p1.y;
  for i := 1 to 5 do begin             {once for each equation}
    rend_geom.mat[i].dxx := 0.5 * rend_geom.mat[i].dx * rend_geom.mat[i].dx;
    rend_geom.mat[i].dyy := 0.5 * rend_geom.mat[i].dy * rend_geom.mat[i].dy;
    rend_geom.mat[i].dxy := rend_geom.mat[i].dx * rend_geom.mat[i].dy;
    end;                               {back and fill in next equation in matrix}
  end;
