{   Subroutine REND_SW_VIDEO_SYNC_INT_CLR
*
*   Clears the video sync interrupt flag.
}
{
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*   ::        CONFIDENTIAL AND PROPRIETARY INFORMATION OF        ::
*   ::                    COGNIVISION, INC.                      ::
*   ::           PROTECTED BY THE COPYRIGHT LAW AS AN            ::
*   ::                    UNPUBLISHED WORK                       ::
*   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
}
module rend_sw_video_sync_int_clr;
define rend_sw_video_sync_int_clr;
%include 'rend_sw2.ins.pas';

procedure rend_sw_video_sync_int_clr;  {clear flag that video sync has been interrupted}

begin
  rend_video_sync_int := false;
  end;
