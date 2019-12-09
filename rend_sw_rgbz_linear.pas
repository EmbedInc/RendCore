{   Subroutine REND_SW_RGBZ_LINEAR (V1,V2,V3)
*
*   Set linear interpolation values for red, green, blue, and Z.  The call arguments
*   V1, V2, and V3 each contain 6 floating point numbers in the order XYZRGB.
*   These three data points are used to define the linear color/Z surface.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_rgbz_linear;
define rend_sw_rgbz_linear;
%include 'rend_sw2.ins.pas';

procedure rend_sw_rgbz_linear (        {set linear values for RGBZ interpolants}
  in      v1, v2, v3: rend_color3d_t); {XYZ and RGB at three points}

var
  c1, c2, c3: vect_2d_t;               {2d coordinates of three points}

begin
  c1.x := v1.x;
  c1.y := v1.y;
  c2.x := v2.x;
  c2.y := v2.y;
  c3.x := v3.x;
  c3.y := v3.y;
  rend_set.lin_geom_2dim^ (c1, c2, c3); {set geometry anchor points}
  rend_set.lin_vals^ (rend_iterp_red_k, v1.red, v2.red, v3.red);
  rend_set.lin_vals^ (rend_iterp_grn_k, v1.grn, v2.grn, v3.grn);
  rend_set.lin_vals^ (rend_iterp_blu_k, v1.blu, v2.blu, v3.blu);
  rend_set.lin_vals^ (rend_iterp_z_k, v1.z, v2.z, v3.z);
  end;
