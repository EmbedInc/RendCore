{   Subroutine REND_SW_GET_COMMENT_LIST (LIST_P)
*
*   Return a pointer to the handle to the image comments list.  The application
*   can then edit the comments list using the STRING_LIST_xxx routines.
*
*   The comments are written to an image file if the image file format supports
*   comments.  The call REND_SET.IMAGE_WRITE^ writes a rectangle from the current
*   bitmap to an image file.
}
module rend_sw_get_comments_list;
define rend_sw_get_comments_list;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_comments_list (  {get handle to current comments list}
  out     list_p: string_list_p_t);    {string list handle, use STRING calls to edit}

begin
  list_p := addr(rend_image.comm);
  end;
