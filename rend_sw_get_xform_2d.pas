{   Subroutine REND_SW_GET_XFORM_2D (XB,YB,OFS)
*
*   Return the current user-view 2D transform.  This is the transform that converts
*   from 2D model space to the +-1.0 image space.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_get_xform_2d;
define rend_sw_get_xform_2d;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_xform_2d (       {read back current 2D transform}
  out     xb: vect_2d_t;               {X basis vector}
  out     yb: vect_2d_t;               {Y basis vector}
  out     ofs: vect_2d_t);             {offset vector}

begin
  xb.x := rend_2d.uxb.x;
  xb.y := rend_2d.uxb.y;
  yb.x := rend_2d.uyb.x;
  yb.y := rend_2d.uyb.y;
  ofs.x := rend_2d.uofs.x;
  ofs.y := rend_2d.uofs.y;
  end;
