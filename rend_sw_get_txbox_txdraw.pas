{   Subroutine REND_SW_GET_TXLEN_TXDRAW (S, SLEN, BV, UP, LL)
*
*   Find the box around all the character cells in string S.  SLEN is the number
*   of characters in the string.  BV is the baseline vector along the bottom
*   of the character cells in the direction of the characters at the end of the
*   string.  UP is in the direction of one character cell up.  LL lower left
*   coordinate of the character cell for the first character.
}
module rend_sw_get_txbox_txdraw;
define rend_sw_get_txbox_txdraw;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_txbox_txdraw (   {get box around text string}
  in      s: univ string;              {text string}
  in      slen: string_index_t;        {number of characters in string}
  out     bv: vect_2d_t;               {baseline vector, along base of char cells}
  out     up: vect_2d_t;               {character cell UP direction and size}
  out     ll: vect_2d_t);              {lower left corner of text string box}
  val_param;

begin
  rend_get.txbox_text^ (s, slen, bv, up, ll); {get info in TEXT space}
  rend_get.xfvect_text^ (bv, bv);      {transform to TXDRAW space}
  rend_get.xfvect_text^ (up, up);
  rend_get.xfpnt_text^ (ll, ll);
  end;
