{   Subroutine REND_SW_CLIP_2DIM_ON (HANDLE, ON)
*
*   Turn the indicated 2D image space clipping window on or off.
}
module rend_sw_clip_2dim_on;
define rend_sw_clip_2dim_on;
%include 'rend_sw2.ins.pas';

procedure rend_sw_clip_2dim_on (       {turn 2D image space clip window on/off}
  in      handle: rend_clip_2dim_handle_t; {handle to this clip window}
  in      on: boolean);                {TRUE for on, FALSE for off}
  val_param;

var
  i: sys_int_machine_t;                {loop counter}

label
  done_onoff;

begin
  rend_clips_2dim.clip[handle].on := on; {set flag to turn window ON/OFF}
{
*   Check for this window previously ON.
}
  for i := 1 to rend_clips_2dim.n_on do begin {once for each previously ON window}
    if rend_clips_2dim.list_on[i] <> handle then next;
    if on                              {are we turning window ON or OFF ?}
      then begin                       {turning window ON}
        goto done_onoff;               {window already in ON list, nothing to do}
        end
      else begin                       {turning window OFF}
        rend_clips_2dim.list_on[i] :=  {put last entry in list into this slot}
          rend_clips_2dim.list_on[rend_clips_2dim.n_on];
        rend_clips_2dim.n_on := rend_clips_2dim.n_on-1; {one less window in ON list}
        goto done_onoff;
        end
      ;
    end;                               {back and check next entry in ON list}
{
*   This clip window was not previously ON.
}
  if on then begin                     {need to turn it ON ?}
    rend_clips_2dim.n_on := rend_clips_2dim.n_on+1; {one more ON clip window}
    rend_clips_2dim.list_on[rend_clips_2dim.n_on] := {put this window in ON list}
      handle;
    end;
done_onoff:                            {jump here if ON/OFF state correct}
{
*   If the current clipping state resolves to just one rectangle, then cache it
*   in REND_CLIP_2DIM.
}
  rend_cache_clip_2dim;
  end;
