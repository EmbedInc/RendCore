{   Subroutine REND_SW_GET_ENTER_LEVEL (LEVEL)
*
*   Return the current ENTER_REND nesting level.  This level is 0 if RENDlib is
*   not in graphics mode.  Positive numbers indicate how many times ENTER_REND
*   was called without a corresponding EXIT_REND.  This is also the number of times
*   EXIT_REND would have to be called to leave graphics mode.  The value is always
*   >= 0, because calling EXIT_REND while not in graphics mode is an error.
}
module rend_sw_get_enter_level;
define rend_sw_get_enter_level;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_enter_level (    {get depth of ENTER_REND nesting level}
  out     level: sys_int_machine_t);   {current nested graphics mode level}

begin
  level := rend_enter_level;           {fetch current value from common block}
  end;
