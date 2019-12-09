{   Subroutine REND_SW_UPDATE_XF2D
*
*   Update the 2D model to image space transform.  This transform is a result of
*   combining the user 2D transform and the current image scale.  This subroutine
*   should be called whenever either is changed.  The user-view 2D transform
*   transforms from 2D model space to a 2D space that has the largest possible
*   +-1.0 square centered in the output image.  The actual 2D transform assumes the
*   output is direct image pixel coordinates.
}
module rend_sw_update_xf2d;
define rend_sw_update_xf2d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_update_xf2d;         {update the internal 2D transform}

var
  xscale: real;                        {X scaling from +-1.0 to image space}
  yscale: real;                        {Y scaling from +-1.0 to image space}
  m: real;                             {scratch mult factor}

begin
  if rend_image.aspect >= 1.0          {check for wider or taller}
    then begin                         {image is wider than tall}
      xscale := 0.5*rend_image.x_size/rend_image.aspect
        - 0.001;
      yscale := -(0.5*rend_image.y_size - 0.001);
      end
    else begin                         {image is taller than wide}
      xscale := 0.5*rend_image.x_size;
      yscale := -(0.5*rend_image.y_size*rend_image.aspect
        - 0.001);
      end
    ;                                  {done handling aspect ratio}
{
*   We now implicitly have the transform from the +-1.0 space to the image space.
*   it is:
*
*   XB = (xscale,0)
*   YB = (0,yscale)
*   ofs = (rend_image.x_size/2.0, rend_image.y_size/2.0)
*
*   The user 2D tranformation matrix is pre-multiplied to the transformation matrix
*   above to yield the overall 2D model space to image space transform.
*
*   The formula for transforming a point thru a 2D matrix is:
*
*   X' = X*XBx + Y*YBx + OFSx
*   Y' = X*XBy + Y*YBy + OFSy
}
  rend_2d.sp.xb.x := rend_2d.uxb.x*xscale; {make concatenated matrix}
  rend_2d.sp.xb.y := rend_2d.uxb.y*yscale;
  rend_2d.sp.yb.x := rend_2d.uyb.x*xscale;
  rend_2d.sp.yb.y := rend_2d.uyb.y*yscale;
  rend_2d.sp.ofs.x := rend_2d.uofs.x*xscale + (rend_image.x_size*0.5);
  rend_2d.sp.ofs.y := rend_2d.uofs.y*yscale + (rend_image.y_size*0.5);
  rend_2d.sp.right :=                  {set right/left handedness flag}
    (rend_2d.sp.xb.x*rend_2d.sp.yb.y - rend_2d.sp.xb.y*rend_2d.sp.yb.x) >= 0.0;
  rend_2d.axis :=                      {set preserve axies flag}
    (rend_2d.sp.xb.y = 0.0) and
    (rend_2d.sp.yb.x = 0.0);
  m := rend_2d.sp.xb.x*rend_2d.sp.yb.y {make cross product}
    - rend_2d.sp.xb.y*rend_2d.sp.yb.x;
  if abs(m) > 1.0E-10                  {compare magnitude to error threshold}
    then begin                         {the matrix is invertable}
      rend_2d.sp.invm := 1.0/m;        {save mult factor for inverse transform}
      rend_2d.sp.inv_ok := true;       {yes, it's OK to do an inverse transform}
      end
    else begin                         {the matrix is not invertable}
      rend_2d.sp.inv_ok := false;      {set flag that matrix has no inverse}
      end
    ;
  rend_image.max_run :=                {max possible iterp run in this image}
    abs(rend_image.x_size) + abs(rend_image.y_size);
  rend_xf3d.vrad_ok := false;          {3D space vector widths are now invalid}
  end;
