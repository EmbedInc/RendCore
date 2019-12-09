{   Subroutine REND_SW_SHNORM_UNITIZED
}
module rend_sw_shnorm_unitized;
define rend_sw_shnorm_unitized;
%include 'rend_sw2.ins.pas';

procedure rend_sw_shnorm_unitized (    {tell whether shading normals will be unitized}
  in      on: boolean);                {future shading norms must be unitized on TRUE}
  val_param;

begin
  if rend_shnorm_unit = on then return; {nothing to do ?}
  rend_shnorm_unit := on;
  rend_internal.check_modes^;
  end;
