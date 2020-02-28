{   Subroutine REND_SW_GET_Z_2D (Z)
*
*   Return the effective Z "coordinate" as it would exist if transformed from the
*   3DW into the 2D space.  Note that this has nothing to do with the current
*   Z interpolant value.
}
module rend_sw_get_z_2d;
define rend_sw_get_z_2d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_z_2d (           {return Z coor after transform from 3DW to 2D}
  out     z: real);                    {effective Z coordinate in 2D space}

var
  z_3dw: real;                         {clipped 3DW space source Z coordinate used}

begin
  z_3dw := rend_view.cpnt.z;           {init to use raw 3DW current point Z coor}
  if (z_3dw > rend_view.zclip_near)    {clip Z value to near clip limit}
    then z_3dw := rend_view.zclip_near;
  if (z_3dw < rend_view.zclip_far)     {clip Z value to far clip limit}
    then z_3dw := rend_view.zclip_far;

  if rend_view.perspec_on              {check for perspective on/off}
    then begin                         {perspective is turned on}
      z :=
        z_3dw*rend_view.zmult*rend_view.eyedis/(rend_view.eyedis-z_3dw) +
        rend_view.zadd;
      end
    else begin                         {perspective is turned off}
      z :=                             {pass back 3DW space Z coordinate}
        z_3dw*rend_view.zmult + rend_view.zadd;
      end
    ;
  end;
