{   Subroutine REND_SW_GET_SUPROP (SUPROP, ON, VAL)
*
*   Return the current state of a particular surface property.  SUPROP is the
*   ID of the surface property for which to return the state.  ON will be set to
*   TRUE if the surface property is turned on.  VAL will be returned as the current
*   values of the selected surface property.
}
module rend_sw_get_suprop;
define rend_sw_get_suprop;
%include 'rend_sw2.ins.pas';

procedure rend_sw_get_suprop (         {get current state of a surface property}
  in      suprop: rend_suprop_k_t;     {surface property ID, use REND_SUPROP_xxx_K}
  out     on: boolean;                 {TRUE if this surface property turned ON}
  out     val: rend_suprop_val_t);     {current values for this surface property}
  val_param;

var
  p: rend_suprop_p_t;                  {pointer to current surface properties block}

begin
  case rend_curr_face of               {make pointer to curr suprop block}
rend_face_front_k: p := addr(rend_face_front);
rend_face_back_k: p := addr(rend_face_back);
otherwise return;
    end;

  case suprop of                       {different code for each surface property}

rend_suprop_emis_k: begin
      on := p^.emis_on;
      val.emis_red := p^.emis.red;
      val.emis_grn := p^.emis.grn;
      val.emis_blu := p^.emis.blu;
      end;

rend_suprop_diff_k: begin
      on := p^.diff_on;
      val.diff_red := p^.diff.red;
      val.diff_grn := p^.diff.grn;
      val.diff_blu := p^.diff.blu;
      end;

rend_suprop_spec_k: begin
      on := p^.spec_on;
      val.spec_red := p^.spcol.red;
      val.spec_grn := p^.spcol.grn;
      val.spec_blu := p^.spcol.blu;
      val.spec_exp := p^.spexp;
      end;

rend_suprop_trans_k: begin
      on := p^.trans_on;
      val.trans_front := p^.trans_front;
      val.trans_side := p^.trans_side;
      end;

    end;
  end;
