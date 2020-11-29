{   Routines to show events state, for debugging.
}
module rend_event_show;
define rend_event_show;
%include 'rend2.ins.pas';
{
********************************************************************************
*
*   Subroutine REND_EVENT_SHOW (EV)
*
*   Show a description of the event EV on standard output.
}
procedure rend_event_show (            {show event on standard output}
  in      ev: rend_event_t);           {the event to show}
  val_param;

begin
  write ('RENDlib event ');
  case ev.ev_type of                   {which event is this ?}
rend_ev_none_k: begin                  {no event occurred}
      writeln ('NONE');
      end;
rend_ev_close_k: begin                 {draw device closed, RENDlib still open}
      writeln ('CLOSE');
      end;
rend_ev_resize_k: begin                {drawing area changed size}
      writeln ('RESIZE, ', rend_image.x_size, ',', rend_image.y_size);
      end;
rend_ev_wiped_rect_k: begin            {rect of pixels wiped out, now redrawable}
      writeln ('WIPED_RECT');
      end;
rend_ev_wiped_resize_k: begin          {all pixels wiped out, now redrawable}
      writeln ('WIPED_RESIZE');
      end;
rend_ev_key_k: begin                   {a user-pressable key changed state}
      writeln ('KEY');
      end;
rend_ev_scrollv_k: begin
      writeln ('SCROLLV');
      end;
rend_ev_pnt_enter_k: begin             {pointer entered draw area}
      writeln ('PNT_ENTER');
      end;
rend_ev_pnt_exit_k: begin              {pointer left draw area}
      writeln ('PNT_EXIT');
      end;
rend_ev_pnt_move_k: begin              {pointer location changed}
      writeln ('PNT_MOVE');
      end;
rend_ev_close_user_k: begin            {user requested close of graphics device}
      writeln ('CLOSE_USER');
      end;
rend_ev_stdin_line_k: begin            {text line available from REND_GET_STDIN_LINE}
      writeln ('STDIN_LINE');
      end;
rend_ev_xf3d_k: begin                  {3D transformation event}
      writeln ('XF3D');
      end;
rend_ev_app_k: begin                   {application event}
      writeln ('APP');
      end;
rend_ev_call_k: begin                  {callback event}
      writeln ('CALL');
      end;
otherwise
    writeln ('ID ', ord(ev.ev_type));
    end;                               {end of event type cases}
  end;
