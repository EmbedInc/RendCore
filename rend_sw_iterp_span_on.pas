{   Subroutine REND_SW_ITERP_SPAN_ON (ITERP,ON)
*
*   Enable/disable the interpolant ITERP to participate in SPAN and RUN primitives.
*   All ON interpolants (enabled with REND_SET.ITERP_ON) will do something during
*   a SPAN or RUN primitive.  However, a primitive must be enabled with this call
*   to recieve any color information from the span or run.  Enterpolants that are
*   ON, but not enabled for span/run will interpolate colors and write normally,
*   just as with any other primitive, such as rectangle.  Enabled interpolants for
*   span/run will follow all the same rules, except that their final interpolator
*   output colors will be replaced by the value from the span or run.  Their
*   interpolators will still advance, and their values and derivatives will not
*   be corrupted.  Therefore, if you have no intention of using the interpolator
*   value after the SPAN or RUN primitive, set the interpolation mode to flat.
*   This avoids computation to interpolate values that will never be used.
*
*   ON should be set TRUE to enable the interpolant ITERP to have its
*   interpolator value superceeded by the span/run data.  A value of FALSE
*   prevents this.
}
module rend_sw_iterp_span_on;
define rend_sw_iterp_span_on;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_span_on (      {iterp participates in SPAN, RUNS ON/OFF}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {TRUE if interpolant does participate}
  val_param;

begin
  if rend_iterps.iterp[iterp].span_run = on {nothing to do ?}
    then return;

  rend_iterps.iterp[iterp].span_run := on; {set new value}
  rend_internal.check_modes^;
  end;
