module rend_callback;
define rend_callback_cpnt_2dim;
define rend_callback_vect_2dim;
%include 'rend2.ins.pas';
{
********************************************************************************
*
*   Subroutine REND_CALLBACK_CPNT_2DIM (ROUTINE_P, APP_P)
*
*   Cause an application callback whenever SET.CPNT_2DIM is called.  ROUTINE_P
*   points to the app routine to call.  APP_P will be passed to the callback
*   routine.
}
procedure rend_callback_cpnt_2dim (    {set app callback for SET.CPNT_2DIM}
  in      routine_p: rend_cpnt_2dim_call_p_t; {to app routine to call}
  in      app_p: univ_ptr);            {to app private state to pass to callback}
  val_param;

begin
  rend_callback.cpnt_2dim_call_p := routine_p; {save pointer to callback routine}
  rend_callback.cpnt_2dim_state_p := app_p; {save pointer to pass to callback}

  rend_sw_set.cpnt_2dim :=             {install routine that will do the callback}
    addr(rend_sw_cpnt_2dim_cb);
  end;
{
********************************************************************************
*
*   Subroutine REND_CALLBACK_VECT_2DIM (ROUTINE_P, APP_P)
*
*   Cause an application callback whenever PRIM.VECT_2DIM is called.  ROUTINE_P
*   points to the app routine to call.  APP_P will be passed to the callback
*   routine.
}
procedure rend_callback_vect_2dim (    {set app callback for PRIM.VECT_2DIM}
  in      routine_p: rend_vect_2dim_call_p_t; {to app routine to call}
  in      app_p: univ_ptr);            {to app private state to pass to callback}
  val_param;

begin
  rend_callback.cpnt_2dim_call_p := routine_p; {save pointer to callback routine}
  rend_callback.cpnt_2dim_state_p := app_p; {save pointer to pass to callback}

  rend_install_prim (                  {install routine that will do the callback}
    rend_sw_vect_2dim_cb_d, rend_prim.vect_2dim);
  end;
