{   Module of SW driver routines that deal with the CIRRES parameters.
}
module rend_sw_cirres;
define rend_sw_cirres;
define rend_sw_cirres_n;
define rend_sw_get_cirres;
%include 'rend_sw2.ins.pas';
{
***************************************************************
*
*   Subroutine REND_SW_CIRRES (CIRRES)
*
*   Set all the CIRRES parameters to the same value.
}
procedure rend_sw_cirres (             {set all CIRRES values simultaneously}
  in      cirres: sys_int_machine_t);  {new value for all CIRRES parameters}
  val_param;

var
  i: sys_int_machine_t;
  c: sys_int_machine_t;                {sanitized CIRRES value}
  changed: boolean;                    {TRUE if a value actually got changed}

begin
  c := max(3, cirres);                 {clip to minimum allowable value}

  changed := false;                    {init to nothing got changed}
  for i := 1 to rend_last_cirres_k do begin
    if rend_cirres[i] = c then next;   {this parameter already set as desired ?}
    rend_cirres[i] := c;               {set to new value}
    changed := true;
    end;

  if changed then rend_internal.check_modes^; {update to new state if got changed}
  end;
{
***************************************************************
*
*   Subroutine REND_SW_CIRRES_N (N, CIRRES)
*
*   Set a particular CIRRES parameter.  N is the 1-N CIRRES parameter number.
*   This routine does nothing if N is out of the legal range 1 to
*   REND_LAST_CIRRES_K.
}
procedure rend_sw_cirres_n (           {set one specific CIRRES parameter}
  in      n: sys_int_machine_t;        {1-N CIRRES value to set, outrange ignored}
  in      cirres: sys_int_machine_t);  {new val for the particular CIRRES parameter}
  val_param;

var
  c: sys_int_machine_t;                {sanitized CIRRES value}

begin
  if (n < 1) or (n > rend_last_cirres_k) {no such CIRRES parameter exists ?}
    then return;

  c := max(3, cirres);                 {clip to minimum allowable value}
  if rend_cirres[n] = c then return;   {already set as desired ?}
  rend_cirres[n] := c;                 {set to new value}
  rend_internal.check_modes^;          {update to new state}
  end;
{
***************************************************************
*
*   Function REND_SW_GET_CIRRES (N)
*
*   Return the value of the selected CIRRES parameter.  The nearest legal
*   value of N will be used if it is out of range.
}
function rend_sw_get_cirres (          {get value of particular CIRRES parameter}
  in      n: sys_int_machine_t)        {1 - REND_LAST_CIRRES_K, clipped to range}
  :sys_int_machine_t;                  {value of selected CIRRES parameter}
  val_param;

var
  i: sys_int_machine_t;

begin
  i := max(1, min(rend_last_cirres_k, n)); {make nearest legal CIRRES parm number}
  rend_sw_get_cirres := rend_cirres[i]; {return the value}
  end;
