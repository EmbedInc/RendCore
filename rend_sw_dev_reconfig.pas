{   Subroutine REND_SW_DEV_RECONFIG
*
*   Look at any relevant device modes/configurations again and set any internal
*   state based on the device modes.
*
*   This is not relevant to the all-software device.
}
module rend_sw_dev_reconfig;
define rend_sw_dev_reconfig;
%include 'rend_sw2.ins.pas';

procedure rend_sw_dev_reconfig;

begin
  rend_set.dev_restore^;               {SW device does nothing special for RECONFIG}
  end;
