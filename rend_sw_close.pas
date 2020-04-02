{   Subroutine REND_SW_CLOSE
*
*   Close out this use of the software bitmap device.
}
module rend_sw_close;
define rend_sw_close;
%include 'rend_sw2.ins.pas';

procedure rend_sw_close;

var
  stat: sys_err_t;                     {completion status code}

begin
  if rend_image.fnam_auto.len > 0 then begin {automatically write image file ?}
    rend_image.ftype.len := 0;         {default image file type from FNAM_AUTO}
    rend_set.image_write^ (            {write image file from final bitmap}
      rend_image.fnam_auto,            {name of image file to write}
      0, 0,                            {coordinate of top left pixel}
      rend_image.x_size, rend_image.y_size, {image size in pixels}
      stat);
    rend_image.fnam_auto.len := 0;     {prevent recursive calls on error}
    rend_error_abort (stat, 'rend', 'rend_write_image', nil, 0);
    end;

  util_mem_context_del (               {release all dynamic memory for this device}
    rend_device[rend_dev_id].mem_p);
  rend_device[rend_dev_id].open := false; {device descriptor is now unused}
  rend_dev_id := 0;                    {indicate there is no current device}
  rend_reset_call_tables;              {make all call table calls illegal}
  end;
