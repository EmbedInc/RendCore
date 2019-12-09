{   Subroutine REND_SW_ENTER_LEVEL (LEVEL)
*
*   Set the ENTER_REND nesting level.  A level of 0 indicates that RENDlib is not
*   in graphics mode.  Positive levels indicate the number of times that REND_EXIT
*   must be called to leave graphics mode.  Negative values are not allowed.
*   Note that calling this routine with a value of 0 forces exiting of graphics
*   mode.
}
module rend_sw_enter_level;
define rend_sw_enter_level;
%include 'rend_sw2.ins.pas';

procedure rend_sw_enter_level (        {set depth of ENTER_REND nesting level}
  in      level: sys_int_machine_t);   {desired level, 0 = not in graphics mode}
  val_param;

var
  n: sys_int_machine_t;                {difference to new ENTER_REND level}
  i: sys_int_machine_t;                {loop counter}

begin
  if level < 0 then begin
    rend_message_bomb ('rend', 'rend_enter_level_negative', nil, 0);
    end;
  n := level - rend_enter_level;       {make how much to increase the level}
  if n >= 0                            {check for increasing or decreasing level}
    then begin                         {user wants higher ENTER_REND level}
      for i := 1 to n do begin
        rend_set.enter_rend^;
        end;
      end
    else begin                         {user wants lower ENTER_REND level}
      for i := 1 to -n do begin
        rend_set.exit_rend^;
        end;
      end
    ;
  end;
