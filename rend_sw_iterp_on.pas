{   Subroutine REND_SW_ITERP_ON (ITERP,ON)
*
*   Turn an interpolant on/off.  If an interpolant is off, it does not participate
*   in any operations.
}
module rend_sw_iterp_on;
define rend_sw_iterp_on;
%include 'rend_sw2.ins.pas';

procedure rend_sw_iterp_on (           {turn interpolant on/off}
  in      iterp: rend_iterp_k_t;       {interpolant identifier}
  in      on: boolean);                {as if interpolant does not exist when FALSE}
  val_param;

var
  i: sys_int_machine_t;                {loop counter}
  adr: rend_iterp_pix_p_t;             {pointer to this interpolant}

label
  done_on;

begin
  adr := addr(rend_iterps.iterp[iterp]); {make address of this interpolant block}
  if adr^.on = on then return;         {nothing to do ?}

  rend_prim.flush_all^;                {finish any pending drawing before change}

  adr^.on := on;
  if on
    then begin                         {this interpolant is being turned on}
      rend_iterps.mask_on :=           {update mask of ON interpolants}
        rend_iterps.mask_on + [iterp];
      for i := 1 to rend_iterps.n_on do begin {look thru interpolant ON list}
        if rend_iterps.list_on[i] = adr {this interpolant already in list ?}
          then goto done_on;           {done turning interpolant on}
        end;                           {back and check next list entry}
      rend_iterps.n_on := rend_iterps.n_on+1; {one more interpolant switched on}
      rend_iterps.list_on[rend_iterps.n_on] := {put ON interpolant into list}
        adr;
done_on:                               {jump to here if done turning interpolant on}
      end
    else begin                         {this interpolant is being turned off}
      rend_iterps.mask_on :=           {update mask of ON interpolants}
        rend_iterps.mask_on - [iterp];
      for i := 1 to rend_iterps.n_on do begin {look thru interpolant ON list}
        if rend_iterps.list_on[i] = adr then begin {found index to this iterp ?}
          rend_iterps.list_on[i] :=    {replace with last entry in ON list}
            rend_iterps.list_on[rend_iterps.n_on];
          rend_iterps.n_on := rend_iterps.n_on-1; {one less ON interpolant}
          exit;                        {found iterp, don't look further}
          end;                         {done with found list index for this iterp}
        end;                           {back and check next list entry}

      adr^.x := 0.0;                   {emulate always being black}
      adr^.y := 0.0;
      adr^.aval := 0.0;
      adr^.adx := 0.0;
      adr^.ady := 0.0;
      adr^.adxx := 0.0;
      adr^.adyy := 0.0;
      adr^.adxy := 0.0;
      end                              {done turning interpolant off}
    ;
  rend_internal.check_modes^;          {update routine pointers and device modes}
  end;
