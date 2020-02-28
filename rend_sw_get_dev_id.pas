{   Subroutine REND_SW_GET_DEV_ID
*
*   Return the device ID of the current RENDlib device.  This is the same ID that
*   was originally returned by REND_OPEN.
}
module rend_sw_get_dev_id;
define rend_sw_get_dev_id;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_dev_id (         {find out what device is current}
  out     dev_id: rend_dev_id_t);      {current RENDlib device ID}

begin
  dev_id := rend_dev_id;
  end;
