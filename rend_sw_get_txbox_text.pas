{   Subroutine REND_SW_GET_TXLEN_TEXT (S, SLEN, BV, UP, LL)
*
*   Find the box around all the character cells in string S.  SLEN is the number
*   of characters in the string.  BV is the baseline vector along the bottom
*   of the character cells in the direction of the characters at the end of the
*   string.  UP is in the direction of one character cell up.  LL lower left
*   coordinate of the character cell for the first character.
}
module rend_sw_get_txbox_text;
define rend_sw_get_txbox_text;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_txbox_text (     {get box around text string}
  in      s: univ string;              {text string}
  in      slen: string_index_t;        {number of characters in string}
  out     bv: vect_2d_t;               {baseline vector, along base of char cells}
  out     up: vect_2d_t;               {character cell UP direction and size}
  out     ll: vect_2d_t);              {lower left corner of text string box}
  val_param;

var
  x, y: rend_font_ar_entry_t;          {coordinate from font array}
  ind: sys_int_machine_t;              {font array index}
  i: sys_int_machine_t;                {character loop counter}
  cnum: sys_int_machine_t;             {font array number of current character}

begin
{
*   Calculate baseline vector BV.
}
  bv.x := 0.0;                         {init to no displacment}
  bv.y := 0.0;

  for i := 1 to slen do begin          {once for each character in string}
    cnum := ord(s[i]) & 127;           {make char code of this character}
    ind := rend_text_state.font[cnum].i; {get initial font array index}
    if ind <= 0 then next;             {no character here ?}

    while rend_text_state.font[ind].i <> -1 do begin {not hit end of char def ?}
      x.i := rend_text_state.font[ind].i & (~1); {fetch X coordinate}
      ind := ind + 1;
      y := rend_text_state.font[ind];  {fetch Y coordinate}
      ind := ind + 1;                  {on to next coordinate}
      end;

    bv.x := bv.x + x.f;                {add on displacement for this character}
    bv.y := bv.y + y.f;
    end;                               {back and process next character}
{
*   Character cell up vector UP.
}
  up.x := 0.0;
  up.y := 1.0;
{
*   Find lower left text string corner in LL.
}
  rend_get.cpnt_txdraw^ (              {set TEXT space origin to TXDRAW curr point}
    rend_text_state.sp.ofs.x,
    rend_text_state.sp.ofs.y);
  case rend_text_parms.start_org of    {where is string anchored to current point ?}
rend_torg_ul_k: begin                  {upper left}
      ll.x := 0.0;
      ll.y := -1.0;
      end;
rend_torg_um_k: begin                  {upper middle}
      ll.x := -0.5 * bv.x;
      ll.y := -1.0;
      end;
rend_torg_ur_k: begin                  {upper right}
      ll.x := -bv.x;
      ll.y := -1.0;
      end;
rend_torg_ml_k: begin                  {middle left}
      ll.x := 0.0;
      ll.y := -0.5;
      end;
rend_torg_mid_k: begin                 {middle}
      ll.x := -0.5 * bv.x;
      ll.y := -0.5;
      end;
rend_torg_mr_k: begin                  {middle right}
      ll.x := -bv.x;
      ll.y := -0.5;
      end;
rend_torg_ll_k: begin                  {lower left}
      ll.x := 0.0;
      ll.y := 0.0;
      end;
rend_torg_lm_k: begin                  {lower middle}
      ll.x := -0.5 * bv.x;
      ll.y := 0.0;
      end;
rend_torg_lr_k: begin                  {lower right}
      ll.x := -bv.x;
      ll.y := 0.0;
      end;
otherwise
    writeln ('Bad value of text parameter START_ORG found.');
    sys_bomb;
    end;                               {done with START_ORG cases}
  end;
