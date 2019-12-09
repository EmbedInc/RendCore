{   Subroutine REND_SW_LIGHT_ACCUR (ACCUR)
*
*   Set the new lighting calculation accuracy level.  This allows the application
*   to make tradeoffs between speed and repeatability accross devices.
*   The accuracy choices are values of the form REND_LACCU_xxx_K.  These are
*   defined in REND.INS.PAS.
}
module rend_sw_light_accur;
define rend_sw_light_accur;
%include 'rend_sw2.ins.pas';

procedure rend_sw_light_accur (        {set lighting calculation accuracy level}
  in      accur: rend_laccu_k_t);      {new lighting accuracy mode}
  val_param;

begin
  if rend_lights.accuracy = accur then return; {nothing to do ?}
  rend_lights.accuracy := accur;       {set new accuracy mode}
  rend_lights.changed := true;         {indicate lighting state changed}
  rend_internal.check_modes^;          {notify driver of changed state}
  end;
