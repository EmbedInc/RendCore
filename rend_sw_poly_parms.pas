{   Subroutine REND_SW_POLY_PARMS (PARMS)
*
*   Set new current polygon drawing control parameters.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_poly_parms;
define rend_sw_poly_parms;
%include 'rend_sw2.ins.pas';

procedure rend_sw_poly_parms (         {set new parameters to control polygon drawing}
  in      parms: rend_poly_parms_t);   {new polygon drawing parameters}

var
  i: integer32;                        {loop counter}
  p1, p2: ^char;                       {byte pointers for checking for differences}

label
  different;

begin
  if rend_poly_state.saved_poly_2dim <> nil then begin {POLY_2DIM replaced ?}
    rend_prim.poly_2dim :=             {restore original POLY_2DIM pointer}
      univ_ptr(rend_poly_state.saved_poly_2dim);
    rend_poly_state.saved_poly_2dim := nil; {indicate there is nothing to restore}
    end;

  if not parms.subpixel then begin     {user wants integer addressed polygons ?}
    rend_poly_state.saved_poly_2dim := {save pointer to existing POLY_2DIM routine}
      univ_ptr(rend_prim.poly_2dim);
    rend_poly_state.saved_poly_2dim_data_p :=
      rend_prim.poly_2dim_data_p;
    rend_install_prim (rend_sw_nsubpix_poly_2dim_d, rend_prim.poly_2dim);
    end;

  p1 := univ_ptr(addr(rend_poly_parms));
  p2 := univ_ptr(addr(parms));
  for i := 1 to sizeof(rend_poly_parms) do begin {once for each byte in data block}
    if p1^ <> p2^ then goto different; {actually changing something ?}
    end;
  return;

different:                             {something is actually getting changed}
  rend_poly_parms := parms;
  rend_internal.check_modes^;
  end;
