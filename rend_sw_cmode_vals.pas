{   Subroutine REND_SW_CMODE_VALS (VALS)
*
*   Set all the changeable modes from the data structure VALS.  VALS must have been
*   previously set by routine GET.CMODE_VALS.  These two routines are used to
*   save and restore the state of all the changeable modes.  This is necessary to
*   to be able to as "what if" type questions to find out what effect changing one
*   mode may have on the changeable modes.  Note that all the changeable modes are
*   not guaranteed to be restored exactly, because other state may be different than
*   at the time they were saved in VALS.  For example, on hardware that does not do
*   Z buffering, assume that software updates and Z buffering were off at the time
*   VALS was set.  If Z buffering is turned on and then this routine called, the
*   software update flag will still be off, although it was on in VALS.  Any modes
*   that are not restored as in VALS are flagged as having been changed.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_cmode_vals;
define rend_sw_cmode_vals;
%include 'rend_sw2.ins.pas';

procedure rend_sw_cmode_vals (         {set state of all changeable modes}
  in      vals: rend_cmode_vals_t);    {data block with all changeable modes values}

begin
  rend_set.clear_cmodes^;              {init to no mode changed}

  rend_max_buf := vals.max_buf;        {restore modes to raw values in VALS}
  rend_curr_disp_buf := vals.disp_buf;
  rend_curr_draw_buf := vals.draw_buf;
  rend_min_bits_vis := vals.min_bits_vis;
  rend_min_bits_hw := vals.min_bits_hw;
  rend_dith.on := vals.dith_on;

  rend_internal.check_modes^;          {some state may have gotten changed}
  end;
