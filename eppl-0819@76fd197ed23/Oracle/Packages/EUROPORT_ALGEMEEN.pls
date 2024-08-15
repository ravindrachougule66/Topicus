create or replace package EUROPORT_ALGEMEEN
is

/*------------------------------------------------------------------------------
Package     : EUROPROT_ALGEMEEN
description : code voor de package EUROPORT_ALGEMEEN waarbinnen de volgende functions
              en procedures:
              procedure te_verwerken_bericht
              procedure controle_lock_order
              function  version
------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';

-- procedure te_verwerken_bericht
   procedure te_verwerken_bericht
   (i_proces_id          in  hr_header.hr_x_procesid%type
   ,o_x_msgtype          out hr_header.hr_x_msgtype%type
   ,o_x_ep_in_out        out hr_header.hr_x_ep_in_out%type
   ,o_x_epmsgseqnum      out hr_header.hr_x_epmsgseqnum%type
   );

-- procedure controle_lock_order
   procedure controle_lock_order
   (i_ordernummer        in  orders.ord_ordernummer%type
   ,i_orderregel         in  orders.ord_orderregel%type
   ,o_ordernummer        out orders.ord_ordernummer%type
   ,o_orderregel         out orders.ord_orderregel%type
   );
   
-- procedure collect_orders
   procedure collect_orders
   (i_depot              in  orders.ord_depot%type
   ,i_use_bulk           in  varchar2
   ,i_WM_orin_id         in  order_initiation.orin_id%type
   );
   
-- function version
   function version
   return                      varchar2;

end EUROPORT_ALGEMEEN;
/
create or replace package body EUROPORT_ALGEMEEN
is

/*----------------------------------------------------------------------------------------
Package body : EUROPORT_ALGEMEEN
description  : code voor de package body EUROPORT_ALGEMEEN waarbinnen de volgende
               functions en procedures aanwezig zijn:
               procedure te_verwerken_bericht
               procedure controle_lock_order
               procedure collect_orders
               function  version
----------------------------------------------------------------------------------------*/

-- DE CODE VOOR DE PROCEDURE TE_VERWERKEN_BERICHTEN
-- Met behulp van deze procedure wordt bepaald wat het eerst volgende bericht is
-- dat verwerkt moet worden in multi verwerken ooutbound.
procedure te_verwerken_bericht
(i_proces_id         in  hr_header.hr_x_procesid%type
,o_x_msgtype         out hr_header.hr_x_msgtype%type
,o_x_ep_in_out       out hr_header.hr_x_ep_in_out%type
,o_x_epmsgseqnum     out hr_header.hr_x_epmsgseqnum%type
)

is
  v_msgtype              hr_header.hr_x_msgtype%type;
  v_ep_in_out            hr_header.hr_x_ep_in_out%type;
  v_epmsgseqnum          hr_header.hr_x_epmsgseqnum%type;

  v_record_gevonden      number(1);
  v_update_gelukt        number(1);

  v_header_gelocked      exception;
  pragma exception_init  (v_header_gelocked, -00054);

  cursor hr is
  select /*+ index (t IF_HR_UK01) */ t.hr_x_msgtype, t.hr_x_ep_in_out, t.hr_x_epmsgseqnum, rowid
  from  hr_header t
  where t.hr_x_procesid = i_proces_id   -- Hier het meegestuurde proces_id gebruiken om de splitsing tussen Verzamel en niet verzamel te maken
  and   t.hr_x_berichtverwerkt = 0
  and   t.hr_x_ep_in_out = 'I'
  and   (t.hr_x_datetimetoproc = ' '
         or
         t.hr_x_datetimetoproc <> ' '
         and
         t.hr_x_datetimetoproc <= to_char(SYSDATE, 'YYYYMMDD-HH24:MI:SS'))
  order by t.hr_x_procesid,   t.hr_x_berichtverwerkt, t.hr_x_ep_in_out, t.hr_x_priority,
           t.hr_x_datetimein, t.hr_x_epmsgseqnum;

begin
  -- net zo lang door gaan tot er een bericht is geselecteerd of als er geen bericht
  -- meer is om te verwerken.
  for r_hr in hr
  loop
     -- Ga er vanuit dat er iets wordt gevonden:
     v_record_gevonden  := 1;
     -- Er vanuit gaan dat de update niet gaat lukken, je blijft dan in de loop...
     v_update_gelukt    := 0;
     -- Het zetten van de output variabelen naar nul en leeg.
     o_x_msgtype        := 0;
     o_x_ep_in_out      := ' ';
     o_x_epmsgseqnum    := 0;

     begin
        select t.hr_x_msgtype, t.hr_x_ep_in_out, t.hr_x_epmsgseqnum
        into   v_msgtype,      v_ep_in_out,      v_epmsgseqnum
        from   hr_header t
        where  t.rowid = r_hr.rowid
        for update nowait; -- proberen te locken van het record uit de loop

     exception
        when v_header_gelocked -- het locken is niet gelukt
        then
           v_record_gevonden := 0;

     end;


     -- Afhandeling van de gevonden gegevens
     if v_record_gevonden = 1
     then
        -- hier het record van status wijzigen zodat het verwerkt kan worden,
        -- echter alleen als het veld bericht verwerkt op 0 staat
        begin
           -- Ga er vanuit dat de update lukt
           v_update_gelukt := 1;

           update hr_header d
           set    d.hr_x_berichtverwerkt = 9
           where  d.rowid = r_hr.rowid
           and    d.hr_x_berichtverwerkt = 0;

           if sql%notfound
           then
              v_update_gelukt := 0;
           end if;
           commit;
        exception
           when others
           then
              v_update_gelukt := 0;
        end;

       if v_update_gelukt = 1
       then
          o_x_msgtype     := v_msgtype;
          o_x_ep_in_out   := v_ep_in_out;
          o_x_epmsgseqnum := v_epmsgseqnum;

       end if;
    end if;

    -- Als de lock niet lukt doorgaan met het volgende record uit de loop...

    -- De loop verlaten als er een bericht is gevonden (v_record_gevonden = 1 and v_update_gelukt = 1)
    exit
    when v_record_gevonden = 1 and v_update_gelukt = 1;

  end loop;
end te_verwerken_bericht;
-- EINDE CODE PROCEDURE TE_VERWERKEN_BERICHT


-- DE CODE VOOR DE PROCEDURE CONTROLE_LOCK_ORDER
procedure controle_lock_order
(i_ordernummer       in   orders.ord_ordernummer%type
,i_orderregel        in   orders.ord_orderregel%type
,o_ordernummer       out  orders.ord_ordernummer%type
,o_orderregel        out  orders.ord_orderregel%type
)

is

  v_ordernummer           orders.ord_ordernummer%type;
  v_orderregel            orders.ord_orderregel%type;
  v_order_gelocked        exception;
  pragma exception_init   (v_order_gelocked, -00054);

begin

   begin
      select o.ord_ordernummer, o.ord_orderregel
      into   v_ordernummer,     v_orderregel
      from   orders o
      where  o.ord_ordernummer = i_ordernummer
      and    o.ord_orderregel  = i_orderregel
      for update nowait;     -- proberen te locken van de gevraagde order

   exception
      when v_order_gelocked     -- het locken is niet gelukt
      then
         v_ordernummer := 0;
         v_orderregel  := 0;
   end;
   -- Als de lock lukt, het record weer vrij geven met behulp van een commit
   commit;
   -- parameters zetten
   o_ordernummer := v_ordernummer;
   o_orderregel  := v_orderregel;

end controle_lock_order;
-- EINDE CODE PROCEDURE CONTROLE_LOCK_ORDER


-- DE CODE VOOR DE PROCEDURE COLLECT_ORDERS
procedure collect_orders
(i_depot              in  orders.ord_depot%type
,i_use_bulk           in  varchar2
,i_WM_orin_id         in  order_initiation.orin_id%type
)

is

begin
  
if i_WM_orin_id = 0 and i_depot <> ' '
then
   -- Als use_bulk = 'Y', dan de de temporairy table vullen met gegevens uit (hist) orders en (hist) orderdetailling
   if i_use_bulk = 'Y'
   then
     insert into od_orders_account_tt 
     ("ORDERTYPE",        "ORDERNUMMER",     "ORDERREGEL",      "ADVISEUR",        "RELATIE",   "DEPOT",    "GELDREKVALUTA",       "GELDREKENING",            "VIARELATIE", "VIADEPOT", 
      "VIAGELDREKVALUTA", "VIAGELDREKENING", "FONDSSYMBOOL",    "OPTIETYPE",       "EXPIRATIE", "EXERCISE", "TRANSACTIESOORT",     "ORDERSOORT",              "ORDERKEUZE", "LIMIET",           
      "AANTAL",           "DISTRIB_KANAAL",  "STATUS",          "UITVSTATUS",      "BEURS",     "STOPPX",   "TOT_AANT_UITGEVOERD", "TOT_EFF_BEDR_UITGEVOERD", "VERVALDATUM", 
      "INGANGSDATUM",     "ORDERTRAJECT",    "GELDIGHEIDSDUUR", "EFFECTIEFBEDRAG", "NOTABEDRAG", 
      "PRIJS_FACTOR", 
      "AANTAL_CIJFERS_DISPLAY", 
      "OMS",                 
      "ORIGIN",            "PENDING",         "ORINID",         "WM_ORINID")
     select 
      "ORDERTYPE",        "ORDERNUMMER",     "ORDERREGEL",      "ADVISEUR",        "RELATIE",   "DEPOT",    "GELDREKVALUTA",       "GELDREKENING",            "VIARELATIE", "VIADEPOT",
      "VIAGELDREKVALUTA", "VIAGELDREKENING", "FONDSSYMBOOL",    "OPTIETYPE",       "EXPIRATIE", "EXERCISE", "TRANSACTIESOORT",     "ORDERSOORT",              "ORDERKEUZE", "LIMIET",
      "AANTAL",           "DISTRIB_KANAAL",  "STATUS",          "UITVSTATUS",      "BEURS",     "STOPPX",   "TOT_AANT_UITGEVOERD", "TOT_EFF_BEDR_UITGEVOERD", "VERVALDATUM",
      "INGANGSDATUM",     "ORDERTRAJECT",    "GELDIGHEIDSDUUR", "EFFECTIEFBEDRAG", "NOTABEDRAG",
      nvl(b.be_prijs_factor,0)                  as prijs_factor,
      nvl(b.be_aantal_cijfers_display,0)        as aantal_cijfers_display,
      nvl(b.be_oms_1,' ')                       as oms,
      "ORIGIN",           "PENDING",          "ORINID",         "WM_ORINID"
        from (select ord.ord_ordertype                  as ordertype,
                     ord.ord_ordernummer                as ordernummer,
                     ord.ord_orderregel                 as orderregel,
                     ord.ord_adviseur                   as adviseur,
                     ord.ord_relatie                    as relatie,
                     ord.ord_depot                      as depot,
                     ord.ord_geldrekvaluta              as geldrekvaluta,
                     ord.ord_geldrekening               as geldrekening,
                     ord.ord_viarelatie                 as viarelatie,
                     ord.ord_viadepot                   as viadepot,
                     ord.ord_viageldrekvaluta           as viageldrekvaluta,
                     ord.ord_viageldrekening            as viageldrekening,
                     ord.ord_fondssymbool               as fondssymbool,
                     ord.ord_optietype                  as optietype,
                     ord.ord_expiratie                  as expiratie,
                     ord.ord_exercise                   as exercise,
                     ord.ord_transactiesoort            as transactiesoort,
                     ord.ord_ordersoort                 as ordersoort,
                     ord.ord_keuze                      as orderkeuze,
                     ord.ord_limiet                     as limiet,
                     ord.ord_aantal                     as aantal,
                     ord.ord_distrib_kanaal             as distrib_kanaal,
                     ord.ord_status                     as status,
                     ord.ord_uitvstatus                 as uitvstatus,
                     ord.ord_beurs                      as beurs,
                     ord.ord_stoppx                     as stoppx,
                     ord.ord_tot_aant_uitgevoerd        as tot_aant_uitgevoerd,
                     ord.ord_tot_eff_bedr_uitgevoerd    as tot_eff_bedr_uitgevoerd,
                     ord.ord_vervaldatum                as vervaldatum,
                     ord.ord_ingangsdatum               as ingangsdatum,
                     ord.ord_ordertrajekt               as ordertraject,
                     ord.ord_geldigheidsduur            as geldigheidsduur,
                     ord.ord_effectiefbedrag            as effectiefbedrag,
                     ord.ord_notabedrag                 as notabedrag,
                     'O'                                as origin,
                     case
                        when ord.ord_status in (1,2,3,4,5,6,7,15,16)
                        then
                           case
                              when ord.ord_uitvstatus in (0,1) then 1
                              else 0
                              end
                        else 0
                     end                                as pending,
                     nvl(ord.ord_orin_id,0)             as orinid,
                     0                                  as wm_orinid
              from  ORDERS ord
              where ord.ord_depot      = i_depot
        union 
              select hord.hord_ordertype,
                     hord.hord_ordernummer,
                     hord.hord_orderregel,
                     hord.hord_adviseur,
                     hord.hord_relatie,
                     hord.hord_depot,
                     hord.hord_geldrekvaluta,
                     hord.hord_geldrekening,
                     hord.hord_viarelatie,
                     hord.hord_viadepot,
                     hord.hord_viageldrekval,
                     hord.hord_viageldrekening,
                     hord.hord_fondssymbool,
                     hord.hord_optietype,
                     hord.hord_expiratie,
                     hord.hord_exercise,
                     hord.hord_transactiesoort,
                     hord.hord_ordersoort,
                     hord.hord_keuze,
                     hord.hord_limiet,
                     hord.hord_aantal,
                     hord.hord_distrib_kanaal,
                     hord.hord_status,
                     hord.hord_uitvstatus,
                     hord.hord_beurs,
                     hord.hord_stoppx,
                     hord.hord_tot_aant_uitgevoerd,
                     hord.hord_tot_eff_bedr_uitgevoerd,
                     hord.hord_vervaldatum,
                     hord.hord_ingangsdatum,
                     hord.hord_ordertrajekt,
                     hord.hord_geldigheidsduur,
                     hord.hord_effectiefbedrag,
                     hord.hord_notabedrag,
                     'HO',
                     0,
                     nvl(hord.hord_orin_id,0),
                     0
              from  ORDHISORDERS HORD
              where hord.hord_depot      = i_depot
        union 
              select ordvrz.ord_ordertype,
                     ordvrz.ord_ordernummer,
                     ordvrz.ord_orderregel,
                     ordvrz.ord_adviseur,
                     orx.orx_relatie,
                     orx.orx_depot,
                     orx.orx_geldrekvaluta,
                     orx.orx_geldrekening,
                     ordvrz.ord_viarelatie,
                     ordvrz.ord_viadepot,
                     ordvrz.ord_viageldrekvaluta,
                     ordvrz.ord_viageldrekening,
                     ordvrz.ord_fondssymbool,
                     ordvrz.ord_optietype,
                     ordvrz.ord_expiratie,
                     ordvrz.ord_exercise,
                     ordvrz.ord_transactiesoort,
                     ordvrz.ord_ordersoort,
                     ordvrz.ord_keuze,
                     orx.orx_limiet,
                     orx.orx_aantal,
                     ordvrz.ord_distrib_kanaal,
                     ordvrz.ord_status,
                     ordvrz.ord_uitvstatus,
                     ordvrz.ord_beurs,
                     ordvrz.ord_stoppx,
                     ordvrz.ord_tot_aant_uitgevoerd,
                     ordvrz.ord_tot_eff_bedr_uitgevoerd,
                     ordvrz.ord_vervaldatum,
                     ordvrz.ord_ingangsdatum,
                     ordvrz.ord_ordertrajekt,
                     ordvrz.ord_geldigheidsduur,
                     orx.orx_effectiefbedrag,
                     orx.orx_notabedrag,
                     'VO',
                     case
                        when ordvrz.ord_status in (1,2,3,4,5,6,7,15,16)
                        then
                           case
                              when ordvrz.ord_uitvstatus in (0, 1) then 1
                              else 0
                           end
                        else 0
                     end,
                     nvl(orx.orx_orin_id,0),
                     0
              from ORDERS ordvrz
              inner join ORDERSDETAILLERING orx
                     on  orx.orx_ordernummer = ordvrz.ord_ordernummer
                     and orx.orx_orderregel = ordvrz.ord_orderregel
                     and  orx.orx_depot            = i_depot
                     and (ordvrz.ord_orderherkomst <> 'BGSO'
                          and orx.orx_orin_id is null
                          and orx.orx_opdrachtnummer = 0
                          or
                          ordvrz.ord_orderherkomst = 'BGSO')
              where ordvrz.ord_ordertype  in ('FVRZ','VBDR','VSW1')
        union
              select hordvrz.hord_ordertype,
                     hordvrz.hord_ordernummer,
                     hordvrz.hord_orderregel,
                     hordvrz.hord_adviseur,
                     horx.horx_relatie,
                     horx.horx_depot,
                     horx.horx_geldrekvaluta,
                     horx.horx_geldrekening,
                     hordvrz.hord_viarelatie,
                     hordvrz.hord_viadepot,
                     hordvrz.hord_viageldrekval,
                     hordvrz.hord_viageldrekening,
                     hordvrz.hord_fondssymbool,
                     hordvrz.hord_optietype,
                     hordvrz.hord_expiratie,
                     hordvrz.hord_exercise,
                     hordvrz.hord_transactiesoort,
                     hordvrz.hord_ordersoort,
                     hordvrz.hord_keuze,
                     horx.horx_limiet,
                     horx.horx_aantal,
                     hordvrz.hord_distrib_kanaal,
                     hordvrz.hord_status,
                     hordvrz.hord_uitvstatus,
                     hordvrz.hord_beurs,
                     hordvrz.hord_stoppx,
                     hordvrz.hord_tot_aant_uitgevoerd,
                     hordvrz.hord_tot_eff_bedr_uitgevoerd,
                     hordvrz.hord_vervaldatum,
                     hordvrz.hord_ingangsdatum,
                     hordvrz.hord_ordertrajekt,
                     hordvrz.hord_geldigheidsduur,
                     horx.horx_effectiefbedrag,
                     horx.horx_notabedrag,
                     'HVO',
                     0,
                     nvl(horx.horx_orin_id,0),
                     0
              from ORDHISORDERS HORDVRZ
              inner join ORDHISDETAILLERING horx
                     on  horx.horx_ordernummer = hordvrz.hord_ordernummer
                     and horx.horx_orderregel  = hordvrz.hord_orderregel
                     and horx.horx_depot       = i_depot
                     and (hordvrz.hord_orderherkomst <> 'BGSO'
                          and horx.horx_opdrachtnummer = 0
                          and horx.horx_orin_id is null
                          or
                          hordvrz.hord_orderherkomst = 'BGSO')
              where hordvrz.hord_ordertype  in ('FVRZ','VBDR','VSW1')
             )
             left outer join BELEGGINGSINSTRUMENT b
                         on  b.be_symbool = fondssymbool
                        and  b.be_optietype = optietype
                        and  b.be_expiratiedatum = expiratie
                        and  b.be_exerciseprijs = exercise;
                        
   elsif i_use_bulk = 'N'
   then
     insert into od_orders_account_tt 
     ("ORDERTYPE",        "ORDERNUMMER",     "ORDERREGEL",      "ADVISEUR",        "RELATIE",   "DEPOT",    "GELDREKVALUTA",       "GELDREKENING",            "VIARELATIE", "VIADEPOT", 
      "VIAGELDREKVALUTA", "VIAGELDREKENING", "FONDSSYMBOOL",    "OPTIETYPE",       "EXPIRATIE", "EXERCISE", "TRANSACTIESOORT",     "ORDERSOORT",              "ORDERKEUZE", "LIMIET",           
      "AANTAL",           "DISTRIB_KANAAL",  "STATUS",          "UITVSTATUS",      "BEURS",     "STOPPX",   "TOT_AANT_UITGEVOERD", "TOT_EFF_BEDR_UITGEVOERD", "VERVALDATUM", 
      "INGANGSDATUM",     "ORDERTRAJECT",    "GELDIGHEIDSDUUR", "EFFECTIEFBEDRAG", "NOTABEDRAG", 
      "PRIJS_FACTOR", 
      "AANTAL_CIJFERS_DISPLAY", 
      "OMS",                 
      "ORIGIN",            "PENDING",        "ORINID",          "WM_ORINID")
     select 
      "ORDERTYPE",        "ORDERNUMMER",     "ORDERREGEL",      "ADVISEUR",        "RELATIE",   "DEPOT",    "GELDREKVALUTA",       "GELDREKENING",            "VIARELATIE", "VIADEPOT",
      "VIAGELDREKVALUTA", "VIAGELDREKENING", "FONDSSYMBOOL",    "OPTIETYPE",       "EXPIRATIE", "EXERCISE", "TRANSACTIESOORT",     "ORDERSOORT",              "ORDERKEUZE", "LIMIET",
      "AANTAL",           "DISTRIB_KANAAL",  "STATUS",          "UITVSTATUS",      "BEURS",     "STOPPX",   "TOT_AANT_UITGEVOERD", "TOT_EFF_BEDR_UITGEVOERD", "VERVALDATUM",
      "INGANGSDATUM",     "ORDERTRAJECT",    "GELDIGHEIDSDUUR", "EFFECTIEFBEDRAG", "NOTABEDRAG",
      nvl(b.be_prijs_factor,0)                  as prijs_factor,
      nvl(b.be_aantal_cijfers_display,0)        as aantal_cijfers_display,
      nvl(b.be_oms_1,' ')                       as oms,
      "ORIGIN",           "PENDING",         "ORINID",          "WM_ORINID"
     from (select ord.ord_ordertype                  as ordertype,
                  ord.ord_ordernummer                as ordernummer,
                  ord.ord_orderregel                 as orderregel,
                  ord.ord_adviseur                   as adviseur,
                  ord.ord_relatie                    as relatie,
                  ord.ord_depot                      as depot,
                  ord.ord_geldrekvaluta              as geldrekvaluta,
                  ord.ord_geldrekening               as geldrekening,
                  ord.ord_viarelatie                 as viarelatie,
                  ord.ord_viadepot                   as viadepot,
                  ord.ord_viageldrekvaluta           as viageldrekvaluta,
                  ord.ord_viageldrekening            as viageldrekening,
                  ord.ord_fondssymbool               as fondssymbool,
                  ord.ord_optietype                  as optietype,
                  ord.ord_expiratie                  as expiratie,
                  ord.ord_exercise                   as exercise,
                  ord.ord_transactiesoort            as transactiesoort,
                  ord.ord_ordersoort                 as ordersoort,
                  ord.ord_keuze                      as orderkeuze,
                  ord.ord_limiet                     as limiet,
                  ord.ord_aantal                     as aantal,
                  ord.ord_distrib_kanaal             as distrib_kanaal,
                  ord.ord_status                     as status,
                  ord.ord_uitvstatus                 as uitvstatus,
                  ord.ord_beurs                      as beurs,
                  ord.ord_stoppx                     as stoppx,
                  ord.ord_tot_aant_uitgevoerd        as tot_aant_uitgevoerd,
                  ord.ord_tot_eff_bedr_uitgevoerd    as tot_eff_bedr_uitgevoerd,
                  ord.ord_vervaldatum                as vervaldatum,
                  ord.ord_ingangsdatum               as ingangsdatum,
                  ord.ord_ordertrajekt               as ordertraject,
                  ord.ord_geldigheidsduur            as geldigheidsduur,
                  ord.ord_effectiefbedrag            as effectiefbedrag,
                  ord.ord_notabedrag                 as notabedrag,
                  'O'                                as origin,
                  case
                     when ord.ord_status in (1,2,3,4,5,6,7,15,16)
                     then
                        case
                           when ord.ord_uitvstatus in (0, 1) then 1
                           else 0
                        end
                     else 0
                  end                                as pending,
                  nvl(ord.ord_orin_id,0)             as orinid,
                  0                                  as wm_orinid
           from ORDERS ord
           where ord.ord_depot      = i_depot
         union
           select hord.hord_ordertype,
                  hord.hord_ordernummer,
                  hord.hord_orderregel,
                  hord.hord_adviseur,
                  hord.hord_relatie,
                  hord.hord_depot,
                  hord.hord_geldrekvaluta,
                  hord.hord_geldrekening,
                  hord.hord_viarelatie,
                  hord.hord_viadepot,
                  hord.hord_viageldrekval,
                  hord.hord_viageldrekening,
                  hord.hord_fondssymbool,
                  hord.hord_optietype,
                  hord.hord_expiratie,
                  hord.hord_exercise,
                  hord.hord_transactiesoort,
                  hord.hord_ordersoort,
                  hord.hord_keuze,
                  hord.hord_limiet,
                  hord.hord_aantal,
                  hord.hord_distrib_kanaal,
                  hord.hord_status,
                  hord.hord_uitvstatus,
                  hord.hord_beurs,
                  hord.hord_stoppx,
                  hord.hord_tot_aant_uitgevoerd,
                  hord.hord_tot_eff_bedr_uitgevoerd,
                  hord.hord_vervaldatum,
                  hord.hord_ingangsdatum,
                  hord.hord_ordertrajekt,
                  hord.hord_geldigheidsduur,
                  hord.hord_effectiefbedrag,
                  hord.hord_notabedrag,
                  'HO',
                  0,
                  nvl(hord.hord_orin_id,0),
                  0
           from ORDHISORDERS HORD
           where hord.hord_depot      = i_depot)
           left outer join BELEGGINGSINSTRUMENT b
                       on  b.be_symbool = fondssymbool
                       and b.be_optietype = optietype
                       and b.be_expiratiedatum = expiratie
                       and b.be_exerciseprijs = exercise;
                       
   end if;


-- For the WM_Orinid processing
else 

     insert into od_orders_account_tt 
     ("ORDERTYPE",        "ORDERNUMMER",     "ORDERREGEL",      "ADVISEUR",        "RELATIE",   "DEPOT",    "GELDREKVALUTA",       "GELDREKENING",            "VIARELATIE", "VIADEPOT", 
      "VIAGELDREKVALUTA", "VIAGELDREKENING", "FONDSSYMBOOL",    "OPTIETYPE",       "EXPIRATIE", "EXERCISE", "TRANSACTIESOORT",     "ORDERSOORT",              "ORDERKEUZE", "LIMIET",           
      "AANTAL",           "DISTRIB_KANAAL",  "STATUS",          "UITVSTATUS",      "BEURS",     "STOPPX",   "TOT_AANT_UITGEVOERD", "TOT_EFF_BEDR_UITGEVOERD", "VERVALDATUM", 
      "INGANGSDATUM",     "ORDERTRAJECT",    "GELDIGHEIDSDUUR", "EFFECTIEFBEDRAG", "NOTABEDRAG", 
      "PRIJS_FACTOR", 
      "AANTAL_CIJFERS_DISPLAY", 
      "OMS",                 
      "ORIGIN",            "PENDING",         "ORINID",         "WM_ORINID")
     select 
      "ORDERTYPE",        "ORDERNUMMER",     "ORDERREGEL",      "ADVISEUR",        "RELATIE",   "DEPOT",    "GELDREKVALUTA",       "GELDREKENING",            "VIARELATIE", "VIADEPOT",
      "VIAGELDREKVALUTA", "VIAGELDREKENING", "FONDSSYMBOOL",    "OPTIETYPE",       "EXPIRATIE", "EXERCISE", "TRANSACTIESOORT",     "ORDERSOORT",              "ORDERKEUZE", "LIMIET",
      "AANTAL",           "DISTRIB_KANAAL",  "STATUS",          "UITVSTATUS",      "BEURS",     "STOPPX",   "TOT_AANT_UITGEVOERD", "TOT_EFF_BEDR_UITGEVOERD", "VERVALDATUM",
      "INGANGSDATUM",     "ORDERTRAJECT",    "GELDIGHEIDSDUUR", "EFFECTIEFBEDRAG", "NOTABEDRAG",
      nvl(b.be_prijs_factor,0)                  as prijs_factor,
      nvl(b.be_aantal_cijfers_display,0)        as aantal_cijfers_display,
      nvl(b.be_oms_1,' ')                       as oms,
      "ORIGIN",           "PENDING",          "ORINID",         "WM_ORINID"
        from (select ord.ord_ordertype                  as ordertype,
                     ord.ord_ordernummer                as ordernummer,
                     ord.ord_orderregel                 as orderregel,
                     ord.ord_adviseur                   as adviseur,
                     ord.ord_relatie                    as relatie,
                     ord.ord_depot                      as depot,
                     ord.ord_geldrekvaluta              as geldrekvaluta,
                     ord.ord_geldrekening               as geldrekening,
                     ord.ord_viarelatie                 as viarelatie,
                     ord.ord_viadepot                   as viadepot,
                     ord.ord_viageldrekvaluta           as viageldrekvaluta,
                     ord.ord_viageldrekening            as viageldrekening,
                     ord.ord_fondssymbool               as fondssymbool,
                     ord.ord_optietype                  as optietype,
                     ord.ord_expiratie                  as expiratie,
                     ord.ord_exercise                   as exercise,
                     ord.ord_transactiesoort            as transactiesoort,
                     ord.ord_ordersoort                 as ordersoort,
                     ord.ord_keuze                      as orderkeuze,
                     ord.ord_limiet                     as limiet,
                     ord.ord_aantal                     as aantal,
                     ord.ord_distrib_kanaal             as distrib_kanaal,
                     ord.ord_status                     as status,
                     ord.ord_uitvstatus                 as uitvstatus,
                     ord.ord_beurs                      as beurs,
                     ord.ord_stoppx                     as stoppx,
                     ord.ord_tot_aant_uitgevoerd        as tot_aant_uitgevoerd,
                     ord.ord_tot_eff_bedr_uitgevoerd    as tot_eff_bedr_uitgevoerd,
                     ord.ord_vervaldatum                as vervaldatum,
                     ord.ord_ingangsdatum               as ingangsdatum,
                     ord.ord_ordertrajekt               as ordertraject,
                     ord.ord_geldigheidsduur            as geldigheidsduur,
                     ord.ord_effectiefbedrag            as effectiefbedrag,
                     ord.ord_notabedrag                 as notabedrag,
                     'O'                                as origin,
                     case
                        when ord.ord_status in (1,2,3,4,5,6,7,15,16)
                        then
                           case
                              when ord.ord_uitvstatus in (0,1) then 1
                              else 0
                              end
                        else 0
                     end                                as pending,
                     nvl(ord.ord_orin_id,0)             as orinid,
                     nvl(t.order_orin_id,0)             as WM_orinid
              from  ORDERS ord
              inner join transorin_orderorin_vw t
                     on  t.transaction_orin_id = ord.ord_orin_id
              where t.order_orin_id    = i_WM_orin_id
        union 
              select hord.hord_ordertype,
                     hord.hord_ordernummer,
                     hord.hord_orderregel,
                     hord.hord_adviseur,
                     hord.hord_relatie,
                     hord.hord_depot,
                     hord.hord_geldrekvaluta,
                     hord.hord_geldrekening,
                     hord.hord_viarelatie,
                     hord.hord_viadepot,
                     hord.hord_viageldrekval,
                     hord.hord_viageldrekening,
                     hord.hord_fondssymbool,
                     hord.hord_optietype,
                     hord.hord_expiratie,
                     hord.hord_exercise,
                     hord.hord_transactiesoort,
                     hord.hord_ordersoort,
                     hord.hord_keuze,
                     hord.hord_limiet,
                     hord.hord_aantal,
                     hord.hord_distrib_kanaal,
                     hord.hord_status,
                     hord.hord_uitvstatus,
                     hord.hord_beurs,
                     hord.hord_stoppx,
                     hord.hord_tot_aant_uitgevoerd,
                     hord.hord_tot_eff_bedr_uitgevoerd,
                     hord.hord_vervaldatum,
                     hord.hord_ingangsdatum,
                     hord.hord_ordertrajekt,
                     hord.hord_geldigheidsduur,
                     hord.hord_effectiefbedrag,
                     hord.hord_notabedrag,
                     'HO',
                     0,
                     nvl(hord.hord_orin_id,0),
                     nvl(t.order_orin_id,0)
              from  ORDHISORDERS HORD
              inner join transorin_orderorin_vw t
                     on  t.transaction_orin_id = hord.hord_orin_id
              where t.order_orin_id      = i_WM_orin_id
        union 
              select ordvrz.ord_ordertype,
                     ordvrz.ord_ordernummer,
                     ordvrz.ord_orderregel,
                     ordvrz.ord_adviseur,
                     orx.orx_relatie,
                     orx.orx_depot,
                     orx.orx_geldrekvaluta,
                     orx.orx_geldrekening,
                     ordvrz.ord_viarelatie,
                     ordvrz.ord_viadepot,
                     ordvrz.ord_viageldrekvaluta,
                     ordvrz.ord_viageldrekening,
                     ordvrz.ord_fondssymbool,
                     ordvrz.ord_optietype,
                     ordvrz.ord_expiratie,
                     ordvrz.ord_exercise,
                     ordvrz.ord_transactiesoort,
                     ordvrz.ord_ordersoort,
                     ordvrz.ord_keuze,
                     orx.orx_limiet,
                     orx.orx_aantal,
                     ordvrz.ord_distrib_kanaal,
                     ordvrz.ord_status,
                     ordvrz.ord_uitvstatus,
                     ordvrz.ord_beurs,
                     ordvrz.ord_stoppx,
                     ordvrz.ord_tot_aant_uitgevoerd,
                     ordvrz.ord_tot_eff_bedr_uitgevoerd,
                     ordvrz.ord_vervaldatum,
                     ordvrz.ord_ingangsdatum,
                     ordvrz.ord_ordertrajekt,
                     ordvrz.ord_geldigheidsduur,
                     orx.orx_effectiefbedrag,
                     orx.orx_notabedrag,
                     'VO',
                     case
                        when ordvrz.ord_status in (1,2,3,4,5,6,7,15,16)
                        then
                           case
                              when ordvrz.ord_uitvstatus in (0, 1) then 1
                              else 0
                           end
                        else 0
                     end,
                     nvl(orx.orx_orin_id,0),
                     nvl(t.order_orin_id,0)
              from ORDERS ordvrz
              inner join ORDERSDETAILLERING orx
                     on  orx.orx_ordernummer = ordvrz.ord_ordernummer
                     and orx.orx_orderregel = ordvrz.ord_orderregel
              inner join transorin_orderorin_vw t
                     on  t.transaction_orin_id = orx.orx_orin_id
              where ordvrz.ord_ordertype  in ('FVRZ','VBDR','VSW1')
              and   t.order_orin_id       = i_WM_orin_id
        union
              select hordvrz.hord_ordertype,
                     hordvrz.hord_ordernummer,
                     hordvrz.hord_orderregel,
                     hordvrz.hord_adviseur,
                     horx.horx_relatie,
                     horx.horx_depot,
                     horx.horx_geldrekvaluta,
                     horx.horx_geldrekening,
                     hordvrz.hord_viarelatie,
                     hordvrz.hord_viadepot,
                     hordvrz.hord_viageldrekval,
                     hordvrz.hord_viageldrekening,
                     hordvrz.hord_fondssymbool,
                     hordvrz.hord_optietype,
                     hordvrz.hord_expiratie,
                     hordvrz.hord_exercise,
                     hordvrz.hord_transactiesoort,
                     hordvrz.hord_ordersoort,
                     hordvrz.hord_keuze,
                     horx.horx_limiet,
                     horx.horx_aantal,
                     hordvrz.hord_distrib_kanaal,
                     hordvrz.hord_status,
                     hordvrz.hord_uitvstatus,
                     hordvrz.hord_beurs,
                     hordvrz.hord_stoppx,
                     hordvrz.hord_tot_aant_uitgevoerd,
                     hordvrz.hord_tot_eff_bedr_uitgevoerd,
                     hordvrz.hord_vervaldatum,
                     hordvrz.hord_ingangsdatum,
                     hordvrz.hord_ordertrajekt,
                     hordvrz.hord_geldigheidsduur,
                     horx.horx_effectiefbedrag,
                     horx.horx_notabedrag,
                     'HVO',
                     0,
                     nvl(horx.horx_orin_id,0),
                     nvl(t.order_orin_id,0)
              from ORDHISORDERS HORDVRZ
              inner join ORDHISDETAILLERING horx
                     on  horx.horx_ordernummer = hordvrz.hord_ordernummer
                     and horx.horx_orderregel  = hordvrz.hord_orderregel
              inner join transorin_orderorin_vw t
                     on  t.transaction_orin_id = horx.horx_orin_id
              where hordvrz.hord_ordertype  in ('FVRZ','VBDR','VSW1')
              and   t.order_orin_id         = i_WM_orin_id
             )
             left outer join BELEGGINGSINSTRUMENT b
                         on  b.be_symbool = fondssymbool
                        and  b.be_optietype = optietype
                        and  b.be_expiratiedatum = expiratie
                        and  b.be_exerciseprijs = exercise;
end if;
end collect_orders;
-- EINDE CODE PROCEDURE COLLECT_ORDERS


-- DE CODE VOOR DE FUNCTION VERSION
function Version
return varchar2
is

begin
   return gv_versie;
end version;
-- EINDE CODE FUNCTION VERSION

end EUROPORT_ALGEMEEN;
/
