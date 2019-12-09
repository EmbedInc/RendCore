{   Subroutine REND_SW_ITERP_RUN_OFS (ITERP,OFS)
*
*   Declare where to find the data for interpolant ITERP within a run
*   descriptor.  OFS if the machine address offset of where the data for this
*   interpolant lives from the start of a run descriptor.  This information is
*   used by the RUN primitives.
}
module rend_sw_iterp_run_ofs;
define rend_sw_iterp_run_ofs;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_run_ofs (      {set pixel offset for RUN primitives}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      ofs: sys_int_adr_t);         {machine addresses into pixel for this iterp}
  val_param;

begin
  if rend_iterps.iterp[iterp].run_offset = ofs {nothing to do ?}
    then return;

  rend_iterps.iterp[iterp].run_offset := ofs; {set new offset}
  rend_internal.check_modes^;
  end;
