{   Subroutine REND_DEV_SET (DEV_ID)
*
*   Set a new RENDlib device as current.  The state of the old device will be saved
*   before the new one is loaded in.  The state after this call will be exactly that
*   at the time when this device was last swapped out.
}
module rend_dev_set;
define rend_dev_set;
%include 'rend2.ins.pas';

procedure rend_dev_set (               {swap in new device}
  in      dev_id: sys_int_machine_t);  {RENDlib device ID from REND_OPEN}
  val_param;

begin
  if rend_dev_id = dev_id then return; {this device already swapped in ?}
  rend_dev_save;                       {save state of old device}
  rend_context_to_state (              {load state of new device}
    rend_device[dev_id].save_area_p^);
  rend_enter_level := 0;               {enter level we are really at}
  rend_set.dev_restore^;               {reset device from new state}
  end;
