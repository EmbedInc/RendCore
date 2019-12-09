{   Subroutine REND_MAKE_XF3D_VRAD
*
*   Update the fields VRADX, VRADY, VRADZ, and VRAD_OK in REND_XF3D.  It is already
*   assumed that vector thickening is enabled in some 2D space below the 3D space.
*   VRADX-VRADZ are three
*   vectors that can be used to adjust the magnitude of a 3D space vector to
*   map to the line thickness radius in the space where lines are being thickened.
*   The sum of the squares of the dot products with the 3D space vector is the
*   square of the "radius" in the 2D space.
}
module rend_make_xf3d_vrad;
define rend_make_xf3d_vrad;
%include 'rend2.ins.pas';

procedure rend_make_xf3d_vrad;

var
  vx, vy, vz: vect_3d_t;               {3D unit vectors in 2D thickening space}
  m: real;                             {scratch mult factor}
  rr: real;                            {thickening space 1/( vector width radius)}

begin
{
*   Transform the unit axis vectors from the 3D model space to the 2D space
*   where the vectors are being thickned.  Note that the 3D unit axis vectors
*   transformed to the 2D model space are exactly the 3D transform basis vectors.
*
*   The transformed vectors will be VX, VY, and VZ.
}
  case rend_vect_parms.poly_level of

rend_space_2d_k,
rend_space_2dcl_k: begin               {all the 2D model coordinate spaces}
      vx := rend_xf3d.xb;
      vy := rend_xf3d.yb;
      vz := rend_xf3d.zb;
      end;

rend_space_2dimi_k,                    {all the 2D pixel coordinate spaces}
rend_space_2dim_k,
rend_space_2dimcl_k: begin
      m := sqrt(0.5 * (                {find RMS "average" 2D scale factor}
        sqr(rend_2d.sp.xb.x) + sqr(rend_2d.sp.xb.y) +
        sqr(rend_2d.sp.yb.x) + sqr(rend_2d.sp.yb.y) ));

      vx.x :=
        (rend_2d.sp.xb.x * rend_xf3d.xb.x) +
        (rend_2d.sp.yb.x * rend_xf3d.xb.y);
      vx.y :=
        (rend_2d.sp.xb.y * rend_xf3d.xb.x) +
        (rend_2d.sp.yb.y * rend_xf3d.xb.y);
      vx.z := m * rend_xf3d.xb.z;

      vy.x :=
        (rend_2d.sp.xb.x * rend_xf3d.yb.x) +
        (rend_2d.sp.yb.x * rend_xf3d.yb.y);
      vy.y :=
        (rend_2d.sp.xb.y * rend_xf3d.yb.x) +
        (rend_2d.sp.yb.y * rend_xf3d.yb.y);
      vy.z := m * rend_xf3d.yb.z;

      vz.x :=
        (rend_2d.sp.xb.x * rend_xf3d.zb.x) +
        (rend_2d.sp.yb.x * rend_xf3d.zb.y);
      vz.y :=
        (rend_2d.sp.xb.y * rend_xf3d.zb.x) +
        (rend_2d.sp.yb.y * rend_xf3d.zb.y);
      vz.z := m * rend_xf3d.zb.z;
      end;

otherwise
    writeln ('Wide vectors not ON in any relevant coordinate space. (REND_MAKE_XF3D_VRAD).');
    sys_bomb;
    end;                               {done with wide vect coordinate space choices}
{
*   VX, VY, and VZ are the 3D model space unit axis vectors transformed to the
*   2D space where vectors are being thickened.  Now compare their magnitudes to
*   the desired vector thickness radius.  The VRAD vectors will be in the direction
*   of the 3D space axis, but will be adjusted in magnitude based on how the
*   unit vectors compared to the vector thickness radius.  When an arbitrary
*   3D vector is dotted with the VRAD vectors, the result indicates the
*   arbitrary vector's length in radii.
}
  rr := 2.0 / rend_vect_parms.width;   {reciprocal of vector width radius}

  rend_xf3d.vradx.x :=
    rr * sqrt(sqr(vx.x) + sqr(vx.y) + sqr(vx.z));
  rend_xf3d.vradx.y := 0.0;
  rend_xf3d.vradx.z := 0.0;

  rend_xf3d.vrady.x := 0.0;
  rend_xf3d.vrady.y :=
    rr * sqrt(sqr(vy.x) + sqr(vy.y) + sqr(vy.z));
  rend_xf3d.vrady.z := 0.0;

  rend_xf3d.vradz.x := 0.0;
  rend_xf3d.vradz.y := 0.0;
  rend_xf3d.vradz.z :=
    rr * sqrt(sqr(vz.x) + sqr(vz.y) + sqr(vz.z));

  rend_xf3d.vrad_ok := true;           {indicate VRAD fields all properly set now}
  end;
