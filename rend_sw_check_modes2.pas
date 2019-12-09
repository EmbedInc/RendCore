{   Subroutine REND_SW_CHECK_MODES2
*
*   Common part of CHECK_MODES that needs to be run after any routine pointers have
*   been altered.  This subroutine is normally called by REND_SW_CHECK_MODES,
*   but this can be inhibited by a device CHECK_MODES routine by setting
*   REND_INHIBIT_CHECK_MODES2 to TRUE.  This flag is automatically reset every time
*   REND_SW_CHECK_MODES is run.  Normally, a device CHECK_MODES routine would
*   do the following:
*
*   1)  Set REND_INHIBIT_CHECK_MODES2 to TRUE.
*
*   2)  Call REND_SW_INTERNAL.CHECK_MODES^.  This will now NOT call CHECK_MODES2,
*       but will reset the inhibit flag.
*
*   3)  Do operations specific to the device.
*
*   4)  Call REND_INTERNAL.CHECK_MODES2^.
}
module rend_sw_check_modes2;
define rend_sw_check_modes2;
%include 'rend_sw2.ins.pas';

procedure rend_sw_check_modes2;

var
  prim_data_pp: rend_prim_data_pp_t;   {scratch pointer to prim data block pointer}
  iterp_n: sys_int_machine_t;          {current interpolant number}

label
  sw_read_yes, done_sw_read;

begin
{
*   Reset the various flags that indicate state got changed since the last
*   CHECK_MODES call.
}
  rend_suprop.changed := false;
  rend_lights.changed := false;
{
*   Make sure the data block pointer for the primitive called by the vector to
*   polygon conversion routine is correct.
}
  if rend_vect_state.poly_proc_p <> nil then begin
    prim_data_pp := univ_ptr(          {adr of call table prim data block pointer}
      sys_int_adr_t(rend_vect_state.poly_proc_p) + sizeof(univ_ptr));
    rend_vect_state.poly_proc_data_p := prim_data_pp^;
    end;
{
*   Make sure the SW_READ flag for REND_SW_WPIX is set properly.
}
  if  rend_zon and                     {reading SW due to Z buffering ?}
      (rend_iterps.z.bitmap_p <> nil)
    then goto sw_read_yes;
  if rend_alpha_on                     {RGB going to be doing read/modify/write}
    then goto sw_read_yes;
  for iterp_n := 1 to rend_iterps.n_on do begin {once for each enabled interpolant}
    with rend_iterps.list_on[iterp_n]^:iterp do begin {set up ITERP abbreviation}
      if  (iterp.wmask <> 0) and       {this interpolant require SW reads ?}
          (iterp.bitmap_p <> nil) and
          (iterp.pixfun <> rend_pixfun_insert_k)
        then goto sw_read_yes;
      end;                             {done with ITERP abbreviation}
    end;                               {back and check next interpolant}
  rend_sw_wpix_d.sw_read := rend_access_no_k; {no SW bitmap reads required}
  goto done_sw_read;
sw_read_yes:                           {jump here if definately reading from SW}
  rend_sw_wpix_d.sw_read := rend_access_yes_k;
done_sw_read:                          {all done setting WPIX SW_READ flag}
  end;
