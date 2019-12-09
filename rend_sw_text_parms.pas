{   Subroutine REND_SW_TEXT_PARMS (PARMS)
*
*   Set all the user-visible parameters that specifically effect the TEXT primitive.
}
module rend_sw_text_parms;
define rend_sw_text_parms;
%include 'rend_sw2.ins.pas';

const
  max_parms = 1;                       {max parameters we can pass to a message}

procedure rend_sw_text_parms (
  in      parms: rend_text_parms_t);   {new values for the modes and switches}

var
  r, r2: real;                         {scratch floating point numbers}
  s, c: real;                          {scratch float numbers for SIN and COS}
  fn: string_treename_t;               {font file name with .font extension}
  tn: string_treename_t;               {full tree name of font file}
  fontlen: sys_int_adr_t;              {length of font data}
  i: sys_int_machine_t;                {loop counter}
  retlen: sys_int_adr_t;               {number of bytes actually read from file}
  conn: file_conn_t;                   {connection handle to font file}
  junk: sys_int_machine_t;             {unused subroutine return arg}
  msg_parm:                            {references parameters for messages}
    array[1..max_parms] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status code}

begin
  fn.max := sizeof(fn.str);            {set max of var strings}
  tn.max := sizeof(tn.str);
{
*   Update the text transform.
}
  s := sin(parms.rot);                 {save SIN/COS of rotation angle}
  c := cos(parms.rot);
  r := parms.size*parms.width;         {width of character cell}
  rend_text_state.sp.xb.x := r*c;      {X character basis vector}
  rend_text_state.sp.xb.y := r*s;
  r := parms.size*parms.height;        {height of character cell}
  r2 := sin(parms.slant)/cos(parms.slant); {horizontal slant factor}
  rend_text_state.sp.yb.x := r*(c*r2 - s); {Y character basis vector}
  rend_text_state.sp.yb.y := r*(s*r2 + c);
  rend_text_state.up.x := -r*s;        {create UP vector one char cell tall}
  rend_text_state.up.y := r*c;
  rend_text_state.sp.right :=          {set right/left handed transform flag}
    (  rend_text_state.sp.xb.x*rend_text_state.sp.yb.y
     - rend_text_state.sp.xb.y*rend_text_state.sp.yb.x) >= 0.0;
{
*   Read in new font file if font name changed.
}
  string_fnam_extend (parms.font, '.font', fn); {make file name with extension}
  string_treename (fn, tn);            {make full font file treename}
  if not string_equal(rend_text_parms.font, tn) then begin {new font file ?}
    file_open_read_bin (tn, '', conn, stat); {open font file for read}
    sys_msg_parm_vstr (msg_parm[1], tn);
    sys_error_abort (stat, 'rend', 'rend_font_file_open', msg_parm, 1);

    file_read_bin (                    {try to read the whole font file}
      conn,                            {connection handle to font file}
      sizeof(rend_text_state.font),    {max amount we have room to hold}
      rend_text_state.font,            {where to put the data}
      retlen,                          {amount of data actually read}
      stat);
    discard (file_eof_partial(stat));  {not filling whole font table is OK}
    sys_error_abort (stat, 'rend', 'rend_font_file_read', msg_parm, 1);

    fontlen := retlen div sizeof(rend_text_state.font[1]);

    file_read_bin (                    {try read one more byte, should hit EOF}
      conn,                            {connection handle to font file}
      1,                               {amount of data to read}
      junk,                            {where to put the data}
      retlen,                          {amount of data actually read}
      stat);
    if not file_eof(stat) then begin   {did not hit EOF as expected ?}
      sys_message_bomb ('rend', 'rend_font_table_overflow', msg_parm, 1);
      end;
    sys_error_abort (stat, 'rend', 'rend_font_file_read', msg_parm, 1);

    file_close (conn);                 {close font file}
{
*   Flip the font data byte order if the CPU's byte order differs from the
*   font file's.  The font file byte order is alwasy FORWARD.  The font data
*   is an array of 4-byte words, so we don't have to interpret anything to
*   flip the word byte order.
}
    if sys_byte_order_k <> sys_byte_order_fwd_k then begin {need to flip font data ?}
      for i := 1 to fontlen do begin   {once for each word in the font data}
        sys_order_flip (rend_text_state.font[i], sizeof(rend_text_state.font[i]));
        end;
      end;                             {done handling flipped font data}
    end;                               {done reading in new font file}
{
*   Switch the TXDRAW space to the right coordinate space.
}
  case parms.coor_level of             {different code for each coordinate space}
rend_space_2dim_k: begin               {2D image coordinate space}
      rend_install_prim (rend_prim.vect_2dim_data_p^, rend_sw_prim.vect_txdraw);
      rend_install_prim (rend_prim.rvect_2dim_data_p^, rend_sw_prim.rvect_txdraw);
      rend_install_prim (rend_prim.poly_2dim_data_p^, rend_sw_prim.poly_txdraw);
      rend_set.cpnt_txdraw := univ_ptr(rend_set.cpnt_2dim);
      rend_set.rcpnt_txdraw := univ_ptr(rend_set.rcpnt_2dim);
      rend_get.cpnt_txdraw := univ_ptr(rend_get.cpnt_2dim);
      end;
rend_space_2dimcl_k: begin             {2D image coordinate space before clipping}
      rend_install_prim (rend_prim.vect_2dimcl_data_p^, rend_sw_prim.vect_txdraw);
      rend_install_prim (rend_prim.rvect_2dimcl_data_p^, rend_sw_prim.rvect_txdraw);
      rend_install_prim (rend_prim.poly_2dimcl_data_p^, rend_sw_prim.poly_txdraw);
      rend_set.cpnt_txdraw := univ_ptr(rend_set.cpnt_2dim);
      rend_set.rcpnt_txdraw := univ_ptr(rend_set.rcpnt_2dim);
      rend_get.cpnt_txdraw := univ_ptr(rend_get.cpnt_2dim);
      end;
rend_space_2d_k: begin                 {2D model coordinate space}
      rend_install_prim (rend_prim.vect_2d_data_p^, rend_sw_prim.vect_txdraw);
      rend_install_prim (rend_prim.rvect_2d_data_p^, rend_sw_prim.rvect_txdraw);
      rend_install_prim (rend_prim.poly_2d_data_p^, rend_sw_prim.poly_txdraw);
      rend_set.cpnt_txdraw := univ_ptr(rend_set.cpnt_2d);
      rend_set.rcpnt_txdraw := univ_ptr(rend_set.rcpnt_2d);
      rend_get.cpnt_txdraw := univ_ptr(rend_get.cpnt_2d);
      end;
rend_space_3dpl_k: begin               {current plane in 3D model space}
      rend_install_prim (rend_prim.vect_3dpl_data_p^, rend_sw_prim.vect_txdraw);
      rend_install_prim (rend_prim.rvect_3dpl_data_p^, rend_sw_prim.rvect_txdraw);
      rend_install_prim (rend_prim.poly_3dpl_data_p^, rend_sw_prim.poly_txdraw);
      rend_set.cpnt_txdraw := univ_ptr(rend_set.cpnt_3dpl);
      rend_set.rcpnt_txdraw := univ_ptr(rend_set.rcpnt_3dpl);
      rend_get.cpnt_txdraw := univ_ptr(rend_get.cpnt_3dpl);
      end;
otherwise
    sys_msg_parm_int (msg_parm[1], ord(parms.coor_level));
    sys_message_bomb ('rend', 'rend_txdraw_space_bad', msg_parm, 1);
    end;                               {done with coordinate space cases}

  rend_text_parms := parms;            {set all new text parameters}
  string_copy (tn, rend_text_parms.font); {save full tree name of font file}
  end;
