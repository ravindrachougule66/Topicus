create or replace package EPPLUS_VARIABLES_CTX
is

/*----------------------------------------------------------------------------------------------
file        : EPPLUS_VARIABLES_CTX.pls
description : Specification of EPPLUS_VARIABLES_CTX
author      : Able BV, Gert Nijenhuis
comment     : In order to be able to store a terminal number value for each connection and keep
              it for as long as the connection is present, a package variable must be present
			        for the storage of the unique terminal number associated with this connection.
history     : 28-FEB-2018, GN EP-19053 Initial creation.
              function   version
-----------------------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';

ctx_termnr number := 0;

function get_ctx_termnr
  return VARCHAR2;

function get_ctx_termnr_num
  return number;
  
function version
   return                             varchar2;

END EPPLUS_VARIABLES_CTX;
/
create or replace package body EPPLUS_VARIABLES_CTX
is

function get_ctx_termnr 
return VARCHAR2
is
begin
    return to_char(ctx_termnr);
end;

function get_ctx_termnr_num
  return number
is
begin
    return ctx_termnr;
end;

function Version
return varchar2
is

begin
      return gv_versie;
end version;


end EPPLUS_VARIABLES_CTX;
/
