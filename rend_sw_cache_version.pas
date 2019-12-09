{   Subroutine REND_SW_CACHE_VERSION (VERSION)
*
*   Set new version ID that must match the version ID in any cached data for that
*   cached data to be considered valid.  This is used by the mechanism that saves
*   the final 2D coordinates and interpolant values for 3D polygon verticies.
*   If the version saved in the cache matches the current version set here, then
*   the cached information is used.  If not, then new information is calculated,
*   used, saved in the cache, and the cache version is set to the new current
*   version.
}
module rend_sw_cache_version;
define rend_sw_cache_version;
%include 'rend_sw2.ins.pas';

procedure rend_sw_cache_version (      {set version ID tag for valid cache entry}
  in      version: sys_int_machine_t); {new ID for recognizing valid cache data}
  val_param;

begin
  rend_cache_version := version;       {save new current version ID}
  end;
