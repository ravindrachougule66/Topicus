create or replace package EUROPORT_VARIABLES
is

/*------------------------------------------------------------------------------
Package     : EUROPORT_VARIABLES
description : code voor de package EUROPORT_VARIABLES waarbinnen de volgende functions
              en procedures:
              function  version
------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';

protect_termnr	 number := 0;
error_termnr		 number := 0;
hc_array_filled	 number := 0;
type hc_array		 is table of number index by pls_integer;
hc_array_list		 hc_array;

-- function version
   function version
   return                      varchar2;
   
end EUROPORT_VARIABLES;
/
create or replace package body EUROPORT_VARIABLES
is
/*------------------------------------------------------------------------------
Package body : EUROPORT_VARIABLES
description  : function  version
------------------------------------------------------------------------------*/

-- Function: Version
   function version return varchar2 is
   begin
      return gv_versie;
   end version;

end EUROPORT_VARIABLES;
/
