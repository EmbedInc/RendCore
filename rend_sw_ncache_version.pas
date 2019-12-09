{   Subroutine REND_SW_NCACHE_VERSION (VERSION)
*
*   Set the new current version ID for all normal vector caches.  The version ID
*   stored in the cache must equal the current version ID for the cache to be
*   considered valid.
}
module rend_sw_ncache_version;
define rend_sw_ncache_version;
%include 'rend_sw2.ins.pas';

procedure rend_sw_ncache_version (     {set new valid version ID for norm vect cache}
  in      version: sys_int_machine_t);
  val_param;

begin
  rend_ncache_flags.version := version;
  end;
