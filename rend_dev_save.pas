{   Subroutine REND_DEV_SAVE
*
*   Save the current state in the save area for that device.  The save area is
*   created if it does not already exist.
*
*   WARNING:  This routine has the side effect of leaving the current device out
*     of graphics mode, regardless of what state it was on entry.
*
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_dev_save;
define rend_dev_save;
%include 'rend2.ins.pas';

procedure rend_dev_save;

var
  enter_level: sys_int_machine_t;      {ENTER_LEVEL device was at when got here}

begin
  if rend_dev_id <= 0 then return;     {no device currently open ?}
  if rend_device[rend_dev_id].save_area_p = nil then begin {need to make save area ?}
    rend_set.alloc_context^ (          {allocate and initialize save area}
      rend_device[rend_dev_id].save_area_p);
    end;                               {save area now definately exists}
  enter_level := rend_enter_level;     {save device's enter level}
  rend_set.enter_level^ (0);           {bring out of graphics mode before swap out}
  rend_enter_level := enter_level;     {remember level device was at}
  rend_state_to_context (rend_device[rend_dev_id].save_area_p^); {save state}
  rend_enter_level := 0;               {indicate device is now out of graphics mode}
  end;
