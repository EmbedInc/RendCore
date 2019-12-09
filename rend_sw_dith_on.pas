{   Subroutine REND_SW_DITH_ON (ON)
*
*   Turn dithering on/off.  A value of TRUE turns dithering on.
}
module rend_sw_dith_on;
define rend_sw_dith_on;
%include 'rend_sw2.ins.pas';

procedure rend_sw_dith_on (            {turn dithering on/off}
  in      on: boolean);                {TRUE for dithering on}
  val_param;

begin
  rend_cmode[rend_cmode_dithon_k] := false; {reset to this mode not changed}
  if on = rend_dith.on then return;    {nothing to do ?}

  rend_prim.flush_all^;                {write pending pixels with old dither mode}

  rend_dith.on := on;                  {turn on dithering}

  if rend_dith.on then begin           {mode needs to be changed ?}
    rend_dith.on := false;             {SW device doesn't do dithering}
    rend_cmode[rend_cmode_dithon_k] := true; {indicate mode got changed}
    end;

  rend_internal.check_modes^;          {update routine pointers and device modes}
  end;
