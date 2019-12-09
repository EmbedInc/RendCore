{   Subroutine REND_SW_ITERP_WMASK (ITERP,WMASK)
*
*   Set the write mask for the given interpolant.
}
module rend_sw_iterp_wmask;
define rend_sw_iterp_wmask;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_wmask (        {set write mask for this interpolant}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      wmask: sys_int_machine_t);   {right justified write mask, 1=write}
  val_param;

begin
  if rend_iterps.iterp[iterp].wmask = wmask then return; {nothing to do ?}
  rend_iterps.iterp[iterp].wmask := wmask;
  rend_internal.check_modes^;          {update routine pointers if necessary}
  end;
