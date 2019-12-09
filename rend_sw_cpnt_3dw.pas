{   Subroutine REND_SW_CPNT_3DW (X,Y,Z)
*
*   Set the current point from the 3D world coordinate space.
}
module rend_sw_cpnt_3dw;
define rend_sw_cpnt_3dw;
%include 'rend_sw2.ins.pas';

procedure rend_sw_cpnt_3dw (           {set new current point from 3D world space}
  in      x, y, z: real);              {coordinates of new current point}
  val_param;

var
  w: real;                             {perspective scale factor}

begin
  rend_view.cpnt.x := x;               {save 3DW space current point}
  rend_view.cpnt.y := y;
  rend_view.cpnt.z := z;
  rend_view.cpnt_clipped :=            {set flag to indicate whether curr pnt clipped}
    (z > rend_view.zclip_near) or (z < rend_view.zclip_far);
  if rend_view.perspec_on              {check for perspective on/off}
    then begin                         {perspective is turned on}
      if rend_view.cpnt_clipped then return; {punt if outside Z clip limits}
      w :=                             {make perspective mult factor}
        rend_view.eyedis/(rend_view.eyedis-z);
      rend_set.cpnt_2d^ (x*w, y*w);    {set current point in 2D model space}
      end
    else begin                         {perspective is turned off}
      rend_set.cpnt_2d^ (x, y);        {no transformation needed on current point}
      end
    ;
  end;
