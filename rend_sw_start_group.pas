{   Subroutine REND_SW_START_GROUP
*
*   Indicate to RENDlib that the application will now only call one PRIM repeatedly,
*   with no intervening SET or GET calls, until SET.END_GROUP is called.  In cases
*   where the placement or geometry of the primitive depends on the current point
*   value, SET.CPNT_xxx calls are allowed if xxx is the same coordinate space as
*   the one primitive type called.
*
*   SET.START_GROUP is intended to allow RENDlib to make use of device efficiencies
*   that may be available when drawing a large block of the same type of primitive.
*   It is quite possible there may be a time penalty for starting and ending a group,
*   in return for higher execution speed for each member of the group.  It is
*   therefore suggested that start/end group only be done for a "large" number of
*   primitives.  Any specifics depend on the particular target devices and drivers.
*
*   There are no primitives that benefit from being grouped in the software (SW)
*   device.
}
module rend_sw_start_group;
define rend_sw_start_group;
%include 'rend_sw2.ins.pas';

procedure rend_sw_start_group;

begin
  end;
