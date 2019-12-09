{   Subroutine REND_SW_GET_Z_CLIP (NEAR,FAR)
*
*   Return the current coordinates of the 3D world space Z clipping planes.
*
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_get_z_clip;
define rend_sw_get_z_clip;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_z_clip (         {get current 3DW space Z clipping limits}
  out     near, far: real);            {Z limits, normally NEAR > FAR}

begin
  near := rend_view.zclip_near;
  far := rend_view.zclip_far;
  end;
