create or replace package FIAT_ORDER_MARGIN
is

/*------------------------------------------------------------------------------
Package     : FIAT_ORDER_MARGIN
description : code voor de package FIAT_ORDER_MARGIN waarbinnen de volgende
              functions en procedures aanwezig zijn:
              procedure  lopende_orders_margin
              procedure  lopende_orders_waarborg
              function   version
------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';

-- procedure lopende_orders_margin:
   procedure lopende_orders_margin
   (i_ordernummer                in  orders.ord_ordernummer%type
   ,i_orderregel                 in  orders.ord_orderregel%type
   ,i_orderdetailnr              in  ordersdetaillering.orx_detailnummer%type
   ,i_terminalnummer             in  werkbestand.wk_terminal%type
   ,i_slot_of_last               in  varchar2
   ,i_sys_toeslag_optiemarg      in  tabelgegevens.tb_waarde%type
   ,i_rel_toeslag_optiemarg      in  producten.pr_toeslag_percentage%type
   ,i_methode_naked_margin       in  number
   ,i_factor_naked_margin        in  number
   ,i_omrekenen_naar_relv        in  number
   ,i_prod_geblok_aantal         in  kosten_werkbestand.kst_trans_aantal%type
   ,i_pr_blokkeren_short_call    in  producten.pr_blokkeren_short_calls%type
   ,i_pr_blokkeren_short_put     in  producten.pr_blokkeren_short_puts%type
   ,i_pr_blokkeren_long_put      in  producten.pr_blokkeren_long_puts%type
   ,i_bij_comb_apart_houden      in  number
   ,i_instellingen               in  varchar2
   ,o_margin_bedrag              out kosten_werkbestand.kst_marginbedrag%type
   );

-- procedure lopende_orders_waarborg:
   procedure lopende_orders_waarborg
   (i_ordernummer                in  orders.ord_ordernummer%type
   ,i_orderregel                 in  orders.ord_orderregel%type
   ,i_orderdetailnummer          in  ordersdetaillering.orx_detailnummer%type
   ,i_bank2mrktqchangedate       in  muntsoorten.mu_update%type
   ,i_systspreadcodecategorie    in  valutaspread_cat_muntsoort.vscm_vsca_id%type
   ,i_bij_comb_apart_houden      in  number
   ,o_waarborgsom                out positie_werkbestand.pwb_waarborgsom_vv%type
   );

-- procedure lopende_orders_gp_geblok
   procedure lopende_orders_gp_geblok
   (i_fonds_valuta   in       werkbestand.wk_categorie_1%type
   ,i_actie          in       varchar2
   ,i_terminalnr     in       werkbestand.wk_terminal%type
   ,io_waarde        in out   werkbestand.wk_waarde_1%type
   );

-- procedure lopende_orders_geblok_w
   procedure lopende_orders_geblok_w
   (i_fonds_valuta   in        werkbestand.wk_categorie_1%type
   ,i_factor         in        number
   ,i_te_dekken_aant in        kosten_werkbestand.kst_trans_aantal%type
   ,i_terminalnr     in        werkbestand.wk_terminal%type
   ,i_debuggen       in        relatie_fiattering.rf_debug_j_n%type
   ,i_debug_user     in        relatie_fiattering.rf_debug_user%type
   ,o_gedekt_aant    out       kosten_werkbestand.kst_trans_aantal%type
   );

-- function version
   function version
   return                      varchar2;

end FIAT_ORDER_MARGIN;
/
create or replace package body FIAT_ORDER_MARGIN
is

/*------------------------------------------------------------------------------
Package body : FIAT_ORDER_MARGIN
description  : code voor de package body FIAT_ORDER_MARGIN waarbinnen de volgende
               functions en procedures aanwezig zijn:
               procedure  lopende_order_margin
               procedure  lopende_orders_gp_geblok
               procedure  lopende_orders_geblok_w
               procedure  teruggave_prod_geld
               procedure  teruggave_prod_stukken
               procedure  positie_prod_afgedekt
               procedure  spread_margin
               procedure  straddle_margin
               procedure  lopende_orders_waarborg
               function   version
-----------------------------------------------------------------------------*/

-- globale variabelen (dus te gebruiken over alle procedures nadat de waarden zijn
-- bepaald in de eerst aanroepend procedure)
   gv_rel_rapp_valuta                relatie_fiattering.rf_rapp_muntsoort%type;
   gv_rel_rapp_laatkoers             relatie_fiattering.rf_rapp_laatkoers%type;
   gv_rel_rapp_biedkoers             relatie_fiattering.rf_rapp_biedkoers%type;
   gv_rel_rapp_factor                relatie_fiattering.rf_rapp_factor%type;
   gv_rel_rapp_reciproke             relatie_fiattering.rf_rapp_reciproke%type;
   gv_rel_rapp_notatie               relatie_fiattering.rf_rapp_notatie%type;
   gv_pr_blokkeren_short_call        number(1);
   gv_pr_blokkeren_short_put         number(1);
   gv_instellingen                   varchar2(1300);
   gv_debuggen                       relatie_fiattering.rf_debug_j_n%type;
   gv_debug_user                     relatie_fiattering.rf_debug_user%type;
   gv_pr_id                          producten.pr_id%type;
   gv_ppr_id                         producten_per_relatie.ppr_id%type;
   gv_systspreadcodecategorie        valutaspread_cat_muntsoort.vscm_vsca_id%type;
   gv_bank2mrktqchangedate           muntsoorten.mu_update%type;

-- Declareren van de procedures die niet in de package header staan:

-- procedure spread_margin:
   procedure spread_margin
   (i_symbool_short              in  beleggingsinstrument.be_symbool%type
   ,i_optietype_short            in  beleggingsinstrument.be_optietype%type
   ,i_expiratiedatum_short       in  beleggingsinstrument.be_expiratiedatum%type
   ,i_exerciseprijs_short        in  beleggingsinstrument.be_exerciseprijs%type
   ,i_factor_short               in  beleggingsinstrument.be_prijs_factor%type
   ,i_pricing_unit_short         in  beleggingsinstrument.be_pricing_unit%type
   ,i_symbool_long               in  beleggingsinstrument.be_symbool%type
   ,i_optietype_long             in  beleggingsinstrument.be_optietype%type
   ,i_expiratiedatum_long        in  beleggingsinstrument.be_expiratiedatum%type
   ,i_exerciseprijs_long         in  beleggingsinstrument.be_exerciseprijs%type
   ,i_factor_long                in  beleggingsinstrument.be_prijs_factor%type
   ,i_pricing_unit_long          in  beleggingsinstrument.be_pricing_unit%type
   ,i_aantal                     in  orders.ord_aantal%type
   ,i_index_opties               in  number
   ,i_slot_of_last               in  varchar2
   ,i_sys_toeslag_optiemarg      in  tabelgegevens.tb_waarde%type
   ,o_margin_spread              out temp_margin_wb_sessie.tms_spread_bedrag%type
   ,o_niet_gedekt_aantal         out orders.ord_aantal%type
   );

-- procedure straddle_margin:
   procedure straddle_margin
   (i_exerciseprijs_call         in  beleggingsinstrument.be_exerciseprijs%type
   ,i_expiratiedatum_call        in  beleggingsinstrument.be_expiratiedatum%type
   ,i_premie_call                in  fn_quotes_vw.quot_laat%type
   ,i_factor_call                in  beleggingsinstrument.be_prijs_factor%type
   ,i_pricing_unit_call          in  beleggingsinstrument.be_pricing_unit%type
   ,i_exerciseprijs_put          in  beleggingsinstrument.be_exerciseprijs%type
   ,i_expiratiedatum_put         in  beleggingsinstrument.be_expiratiedatum%type
   ,i_premie_put                 in  fn_quotes_vw.quot_laat%type
   ,i_factor_put                 in  beleggingsinstrument.be_prijs_factor%type
   ,i_pricing_unit_put           in  beleggingsinstrument.be_pricing_unit%type
   ,i_biedkoers_ow               in  fn_quotes_vw.quot_bied%type
   ,i_margin_factor              in  beleggingsinstrument.be_margin_factor%type
   ,i_sys_toeslag_optiemarg      in  tabelgegevens.tb_waarde%type
   ,i_aantal                     in  orders.ord_aantal%type
   ,o_ongedekt_aantal_call       out orders.ord_aantal%type
   ,o_ongedekt_aantal_put        out orders.ord_aantal%type
   ,o_margin_straddle            out temp_margin_wb_sessie.tms_straddle_bedrag%type
   );

-- procedure positie_prod_afgedekt
   procedure positie_prod_afgedekt
   (i_fondssymbool               in  beleggingsinstrument.be_symbool%type
   ,i_optietype                  in  beleggingsinstrument.be_optietype%type
   ,i_expiratiedatum             in  beleggingsinstrument.be_expiratiedatum%type
   ,i_exerciseprijs              in  beleggingsinstrument.be_exerciseprijs%type
   ,i_ref_symbool                in  beleggingsinstrument.be_referentiesymbool%type
   ,i_terminalnummer             in  werkbestand.wk_terminal%type
   ,o_aantal_prod_afgedekt       out temp_margin_wb_sessie.tms_prod_geblok_aantal%type
   );

-- procedure teruggave_prod_geld
   procedure teruggave_prod_geld
   (i_valuta                     in  muntsoorten.mu_code%type
   ,i_biedkoers                  in  muntsoorten.mu_biedkoers%type
   ,i_factor                     in  muntsoorten.mu_factor%type
   ,i_reciproke                  in  muntsoorten.mu_reciproke%type
   ,i_bedrag                     in  kosten_werkbestand.kst_marginbedrag%type
   ,i_terminalnr                 in  werkbestand.wk_terminal%type
   );

-- procedure teruggave_prod_stukken
   procedure teruggave_prod_stukken
   (i_reffonds_symbool           in  beleggingsinstrument.be_referentiesymbool%type
   ,i_reffonds_id                in  beleggingsinstrument.be_volgnummer%type
   ,i_aantal                     in  kosten_werkbestand.kst_trans_aantal%type
   ,i_terminalnr                 in  werkbestand.wk_terminal%type
   ,i_debuggen                   in  relatie_fiattering.rf_debug_j_n%type
   ,i_debug_user                 in  relatie_fiattering.rf_debug_user%type
   );

-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_MARGIN
-- In deze procedure wordt voor een opgegeven ordernummer de margin verplichting berekend
-- Vergelijk onderdelen van Magic programma 158 br-calc. marginbedrag.
procedure lopende_orders_margin
(i_ordernummer                in  orders.ord_ordernummer%type
,i_orderregel                 in  orders.ord_orderregel%type
,i_orderdetailnr              in  ordersdetaillering.orx_detailnummer%type
,i_terminalnummer             in  werkbestand.wk_terminal%type
,i_slot_of_last               in  varchar2
,i_sys_toeslag_optiemarg      in  tabelgegevens.tb_waarde%type
,i_rel_toeslag_optiemarg      in  producten.pr_toeslag_percentage%type
,i_methode_naked_margin       in  number
,i_factor_naked_margin        in  number
,i_omrekenen_naar_relv        in  number
,i_prod_geblok_aantal         in  kosten_werkbestand.kst_trans_aantal%type
,i_pr_blokkeren_short_call    in  producten.pr_blokkeren_short_calls%type
,i_pr_blokkeren_short_put     in  producten.pr_blokkeren_short_puts%type
,i_pr_blokkeren_long_put      in  producten.pr_blokkeren_long_puts%type
,i_bij_comb_apart_houden      in  number
,i_instellingen               in  varchar2
,o_margin_bedrag              out kosten_werkbestand.kst_marginbedrag%type
)

is
   v_symbool                 beleggingsinstrument.be_symbool%type;
   v_optietype               beleggingsinstrument.be_optietype%type;
   v_expiratiedatum          beleggingsinstrument.be_expiratiedatum%type;
   v_exerciseprijs           beleggingsinstrument.be_exerciseprijs%type;
   v_laatkoers_optie         fn_quotes_vw.quot_laat%type;
   v_prijs_factor            beleggingsinstrument.be_prijs_factor%type;
   v_pricing_unit            beleggingsinstrument.be_pricing_unit%type;
   v_bi_nummer               beleggingsinstrument.be_bi_nummer%type;
   v_ow_is_mandje            number(1);
   v_ref_symbool_volgnummer  beleggingsinstrument.be_volgnummer%type;
   v_reffonds                beleggingsinstrument.be_referentiesymbool%type;
   v_biedkoers_reffonds      fn_quotes_vw.quot_bied%type;
   v_margin_factor           beleggingsinstrument.be_margin_factor%type;
   v_margin_opslag           beleggingsinstrument.be_margin_opslag%type;
   v_trans_indicatie         orders.ord_transactiesoort%type;
   v_aantal                  orders.ord_aantal%type;
   v_fonds_muntsoort         beleggingsinstrument.be_muntsoort%type;
   v_fonds_mntsrt_lkoers     muntsoorten.mu_laatkoers%type;
   v_fonds_mntsrt_bkoers     muntsoorten.mu_biedkoers%type;
   v_fonds_mntsrt_fact       muntsoorten.mu_factor%type;
   v_fonds_mntsrt_recip      muntsoorten.mu_reciproke%type;
   v_fonds_prijs_factor      kosten_werkbestand.kst_prijs_factor_fnds%type;
   v_init_margin             kosten_werkbestand.kst_marginbedrag%type;
   v_totaal_margin           kosten_werkbestand.kst_marginbedrag%type;
   v_margin_spread           temp_margin_wb_sessie.tms_spread_bedrag%type;
   v_margin_straddle         temp_margin_wb_sessie.tms_straddle_bedrag%type;
   v_margin_ongedekt         kosten_werkbestand.kst_marginbedrag%type;
   v_index_optie             number(1);

   -- gegevens voor het tweede leg (eigenlijk eerste leg)
   v_symbool_1               beleggingsinstrument.be_symbool%type;
   v_optietype_1             beleggingsinstrument.be_optietype%type;
   v_expiratiedatum_1        beleggingsinstrument.be_expiratiedatum%type;
   v_exerciseprijs_1         beleggingsinstrument.be_exerciseprijs%type;
   v_laatkoers_optie_1       fn_quotes_vw.quot_laat%type;
   v_prijs_factor_1          beleggingsinstrument.be_prijs_factor%type;
   v_pricing_unit_1          beleggingsinstrument.be_pricing_unit%type;
   v_bi_nummer_1             beleggingsinstrument.be_bi_nummer%type;
   v_ow_is_mandje_1          number(1);
   v_ref_symb_volgnummer_1   beleggingsinstrument.be_volgnummer%type;
   v_reffonds_1              beleggingsinstrument.be_referentiesymbool%type;
   v_biedkoers_reffonds_1    fn_quotes_vw.quot_bied%type;
   v_margin_factor_1         beleggingsinstrument.be_margin_factor%type;
   v_margin_opslag_1         beleggingsinstrument.be_margin_opslag%type;
   v_trans_indicatie_1       orders.ord_transactiesoort%type;
   v_aantal_1                orders.ord_aantal%type;
   v_fonds_muntsoort_1       beleggingsinstrument.be_muntsoort%type;
   v_fonds_mntsrt_lkoers_1   muntsoorten.mu_laatkoers%type;
   v_fonds_mntsrt_bkoers_1   muntsoorten.mu_biedkoers%type;
   v_fonds_mntsrt_fact_1     muntsoorten.mu_factor%type;
   v_fonds_mntsrt_recip_1    muntsoorten.mu_reciproke%type;
   v_fonds_prijs_factor_1    kosten_werkbestand.kst_prijs_factor_fnds%type;
   v_init_margin_1           kosten_werkbestand.kst_marginbedrag%type;
   v_combinatietype          orders.ord_combinatietype%type;
   -- algemene variabelen
   v_dummy_koers             fn_quotes_vw.quot_bied%type;
   v_aantal_ongedekt         orders.ord_aantal%type;
   v_aantal_ongedekt_1       orders.ord_aantal%type;
   v_instelling              varchar2(100);
   
   -- variabelen voor de produkten checks:
   v_comb_berek_uitvoeren    number(1);
   v_prod_aantal_gedekt      kosten_werkbestand.kst_trans_aantal%type;
   v_prod_aantal_gedekt_1    kosten_werkbestand.kst_trans_aantal%type;


begin
   -- als orderregel = 2 dan is het een combinatieorder en moeten de gegevens voor
   -- het eerste leg ook nog apart opgehaald worden.

   -- eerst de gegevens van de meegestuurde parameters:
   select k.kst_fondssymbool,      k.kst_optietype_fnds,    k.kst_expiratiedat_fnds,
          k.kst_exercisepr_fnds,   k.kst_trans_indicatie,   k.kst_trans_aantal,
          k.kst_ref_fondssymbool,  k.kst_prijs_factor_fnds,
          k.kst_trans_muntsrt,     k.kst_prijs_factor_fnds,
          r.rf_rapp_muntsoort,     r.rf_rapp_laatkoers,     r.rf_rapp_biedkoers,
          r.rf_rapp_factor,        r.rf_rapp_reciproke,     r.rf_rapp_notatie,
          r.rf_pr_id,              r.rf_ppr_id,
          r.rf_debug_j_n,          r.rf_debug_user,
          b.be_pricing_unit,       b.be_bi_nummer
   into   v_symbool,               v_optietype,             v_expiratiedatum,
          v_exerciseprijs,         v_trans_indicatie,       v_aantal,
          v_reffonds,              v_prijs_factor,
          v_fonds_muntsoort,       v_fonds_prijs_factor,
          gv_rel_rapp_valuta,      gv_rel_rapp_laatkoers,   gv_rel_rapp_biedkoers,
          gv_rel_rapp_factor,      gv_rel_rapp_reciproke,   gv_rel_rapp_notatie,
          gv_pr_id,                gv_ppr_id,
          gv_debuggen,             gv_debug_user,
          v_pricing_unit,          v_bi_nummer
   from   kosten_werkbestand k, beleggingsinstrument b, relatie_fiattering r
   where  k.kst_ordernummer   = i_ordernummer
   and    k.kst_orderregel    = i_orderregel
   and    k.kst_detailnummer  = i_orderdetailnr
   and    b.be_symbool        = k.kst_fondssymbool
   and    b.be_optietype      = k.kst_optietype_fnds
   and    b.be_expiratiedatum = k.kst_expiratiedat_fnds
   and    b.be_exerciseprijs  = k.kst_exercisepr_fnds;
   
   select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, 'Bank2MrktQChangeDate', 'D', gv_debuggen, gv_debug_user)
   into   v_instelling
   from   dual;
   gv_bank2mrktqchangedate := rtrim(ltrim(v_instelling));
    
   select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, 'SystSprdCodeCat', 'N', gv_debuggen, gv_debug_user)
   into   v_instelling
   from   dual;
   gv_systspreadcodecategorie := to_number(rtrim(ltrim(v_instelling)));
   
   FIAT_ALGEMEEN.valutagegevens_bepalen (v_fonds_muntsoort,       gv_pr_id,              gv_ppr_id,           gv_systspreadcodecategorie,
                                         gv_bank2mrktqchangedate, gv_debuggen,           gv_debug_user,       v_fonds_mntsrt_bkoers,
                                         v_dummy_koers,           v_fonds_mntsrt_lkoers, v_fonds_mntsrt_fact, v_fonds_mntsrt_recip,
                                         v_dummy_koers);
   
   select b.be_margin_factor, b.be_margin_opslag, b.be_volgnummer
   into   v_margin_factor,    v_margin_opslag,    v_ref_symbool_volgnummer
   from   beleggingsinstrument b
   where  b.be_symbool        = v_reffonds
   and    b.be_optietype      = ' '
   and    b.be_expiratiedatum = '00000000'
   and    b.be_exerciseprijs  = 0;

   gv_pr_blokkeren_short_call := i_pr_blokkeren_short_call;
   gv_pr_blokkeren_short_put  := i_pr_blokkeren_short_put;   
   gv_instellingen            := i_instellingen;
   
   v_init_margin   := 0;
   v_totaal_margin := 0;

   -- ophalen koersen:
   -- eerst die van de optie:
   FIAT_ALGEMEEN.fondskoersen(v_symbool, v_optietype, v_expiratiedatum, v_exerciseprijs, i_slot_of_last, v_dummy_koers, v_laatkoers_optie);
   -- dan die van de onderliggende waarde:
   begin
       select 1
       into   v_ow_is_mandje
       from   mandje_onderliggende_waarde m
       where  m.mnd_volgnummer = v_ref_symbool_volgnummer
       and    rownum           <= 1;                      -- Er hoeft maar 1 record opgehaald te worden !
   exception
       when no_data_found
       then
          v_ow_is_mandje := 0;
   end;
   if v_ow_is_mandje = 1
   then
      FIAT_ALGEMEEN.fondskoers_meerdere_ow (v_ref_symbool_volgnummer, v_prijs_factor, i_slot_of_last, gv_debuggen, gv_debug_user, v_biedkoers_reffonds, v_dummy_koers);
   else
      FIAT_ALGEMEEN.fondskoersen(v_reffonds, ' ', '00000000', 0, i_slot_of_last, v_biedkoers_reffonds, v_dummy_koers);
   end if;

   -- ophalen gegevens andere leg (leg 1 hardcoded!)
   if i_orderregel = 2
   then
      select k.kst_fondssymbool,      k.kst_optietype_fnds,    k.kst_expiratiedat_fnds,
             k.kst_exercisepr_fnds,   k.kst_trans_indicatie,   k.kst_trans_aantal,
             k.kst_ref_fondssymbool,  k.kst_prijs_factor_fnds,
             k.kst_trans_muntsrt,     k.kst_combinatietype,    k.kst_prijs_factor_fnds,
             b.be_pricing_unit,       b.be_bi_nummer
      into   v_symbool_1,             v_optietype_1,           v_expiratiedatum_1,
             v_exerciseprijs_1,       v_trans_indicatie_1,     v_aantal_1,
             v_reffonds_1,            v_prijs_factor_1,
             v_fonds_muntsoort_1,     v_combinatietype,        v_fonds_prijs_factor_1,
             v_pricing_unit_1,        v_bi_nummer_1
      from   kosten_werkbestand k, beleggingsinstrument b
      where  k.kst_ordernummer   = i_ordernummer
      and    k.kst_orderregel    = 1
      and    k.kst_detailnummer  = i_orderdetailnr
      and    b.be_symbool        = k.kst_fondssymbool
      and    b.be_optietype      = k.kst_optietype_fnds
      and    b.be_expiratiedatum = k.kst_expiratiedat_fnds
      and    b.be_exerciseprijs  = k.kst_exercisepr_fnds;

      FIAT_ALGEMEEN.valutagegevens_bepalen (v_fonds_muntsoort_1,     gv_pr_id,                gv_ppr_id,             gv_systspreadcodecategorie,
                                            gv_bank2mrktqchangedate, gv_debuggen,             gv_debug_user,         v_fonds_mntsrt_bkoers_1,
                                            v_dummy_koers,           v_fonds_mntsrt_lkoers_1, v_fonds_mntsrt_fact_1, v_fonds_mntsrt_recip_1,
                                            v_dummy_koers);
      
      select b.be_margin_factor, b.be_margin_opslag, b.be_volgnummer
      into   v_margin_factor_1,  v_margin_opslag_1,  v_ref_symb_volgnummer_1
      from   beleggingsinstrument b
      where  b.be_symbool        = v_reffonds_1
      and    b.be_optietype      = ' '
      and    b.be_expiratiedatum = '00000000'
      and    b.be_exerciseprijs  = 0;

      v_init_margin_1 := 0;

      -- ophalen koersen:
      -- eerst die van de optie:
      FIAT_ALGEMEEN.fondskoersen(v_symbool_1, v_optietype_1, v_expiratiedatum_1, v_exerciseprijs_1, i_slot_of_last, v_dummy_koers, v_laatkoers_optie_1);
      -- dan die van de onderliggende waarde:
      begin
         select 1
         into   v_ow_is_mandje_1
         from   mandje_onderliggende_waarde m
         where  m.mnd_volgnummer = v_ref_symb_volgnummer_1
         and    rownum           <= 1;                      -- Er hoeft maar 1 record opgehaald te worden !
      exception
         when no_data_found
         then
            v_ow_is_mandje_1 := 0;
      end;
      
      if v_ow_is_mandje_1 = 1
      then
         FIAT_ALGEMEEN.fondskoers_meerdere_ow (v_ref_symb_volgnummer_1, v_prijs_factor_1, i_slot_of_last, gv_debuggen, gv_debug_user, v_biedkoers_reffonds_1, v_dummy_koers);
      else
         FIAT_ALGEMEEN.fondskoersen(v_reffonds_1, ' ', '00000000', 0, i_slot_of_last, v_biedkoers_reffonds_1, v_dummy_koers);
      end if;
   end if;

   -- als de orderregel 1 is, is het geen combinatie order --> berekenen van de marginverplichting
   -- of bij comb apart houden = 1 (dus van de afzonderlijke legs wordt de initial margin berekend)
   if i_orderregel = 1 or i_bij_comb_apart_houden = 1
   then
      FIAT_ALGEMEEN.initial_margin (v_optietype, v_exerciseprijs, v_pricing_unit, v_prijs_factor, v_laatkoers_optie,
                                    v_margin_factor, v_margin_opslag, v_biedkoers_reffonds, (v_aantal - i_prod_geblok_aantal),
                                    i_sys_toeslag_optiemarg, i_rel_toeslag_optiemarg, i_methode_naked_margin, i_factor_naked_margin,
                                    gv_pr_blokkeren_short_call, gv_pr_blokkeren_short_put, gv_debuggen, gv_debug_user, v_init_margin);
      -- omrekenen als de muntsoorten van elkaar verschillen
      if v_fonds_muntsoort <> gv_rel_rapp_valuta and i_omrekenen_naar_relv = 1
      then
         select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_init_margin, v_fonds_mntsrt_recip, v_fonds_mntsrt_fact, v_fonds_mntsrt_bkoers,
                                                   v_fonds_mntsrt_lkoers, gv_rel_rapp_reciproke, gv_rel_rapp_factor, gv_rel_rapp_biedkoers,
                                                   gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
         into   v_totaal_margin
         from   dual;
      else
         v_totaal_margin := v_init_margin;
      end if;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure FIAT_ORDER_MARGIN.lopende_orders_margin');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'berekende margin order : '||to_char(v_totaal_margin)||
                                                 ' ; bij combinatie order apart houden : '||to_char(i_bij_comb_apart_houden));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
      end if;

   -- als de orderregel 2 is, is het een combinatie order --> berekenen van de spread/straddle/strangle/overige marginverplichting
   else
       -- Er vanuit gaan dat de marginverplichting berekend moet worden, hier de switch op 1 zetten, bij de producten
       -- functionaliteit kan hij eventueel op 0 worden gezet en wordt er geen berekening uitgevoerd..
       v_comb_berek_uitvoeren := 1;

      -- Bij producten is het mogelijk om al de verwachte posities af te dekken met geld en stukken
      -- Voor komen van dubbele margin projectcode 8340-36725 voor Robein.

      -- Het betreft een combinatie met call opties:
      if v_optietype ='CALL' and v_optietype_1 = 'CALL' and i_pr_blokkeren_short_call = 1
         and v_bi_nummer not between 3000 and 3099
         and v_reffonds = v_reffonds_1
      then
         -- er hoeft alleen maar wat gedaan te worden als het een SK en OV of een OV en OV combinatie betreft
         -- het betreft een SK en OV combinatie order:
         if (v_trans_indicatie = 'SK' and v_trans_indicatie_1 = 'OV')
             or
            (v_trans_indicatie = 'OV' and v_trans_indicatie_1 = 'SK')
         then
            -- als eerste bepalen of er al is geblokkeerd voor de nu short positie (de positie die nu met SK wordt gesloten):
            if v_trans_indicatie = 'SK'
            then
               positie_prod_afgedekt(v_symbool, v_optietype, v_expiratiedatum, v_exerciseprijs, v_reffonds,
                                     i_terminalnummer, v_prod_aantal_gedekt);
               -- als het prod aantal gedekt groter of gelijk is aan het order aantal hoeft er niets meer gedaan te worden:
               if v_prod_aantal_gedekt >= v_aantal
               then
                  v_comb_berek_uitvoeren := 0;
               else
                  -- doorgaan voor het nog niet afgedekte gedeelte
                   v_aantal   := v_aantal - v_prod_aantal_gedekt;
                   v_aantal_1 := v_aantal;
               end if;
            elsif v_trans_indicatie_1 = 'SK'
            then
               positie_prod_afgedekt(v_symbool_1, v_optietype_1, v_expiratiedatum_1, v_exerciseprijs_1, v_reffonds_1,
                                     i_terminalnummer, v_prod_aantal_gedekt_1);
               -- als het prod aantal gedekt groter of gelijk is aan het order aantal hoeft er niets meer gedaan te worden:
               if v_prod_aantal_gedekt_1 >= v_aantal_1
               then
                  v_comb_berek_uitvoeren := 0;
               else
                  -- doorgaan voor het nog niet afgedekte gedeelte
                  v_aantal_1 := v_aantal_1 - v_prod_aantal_gedekt_1;
                  v_aantal   := v_aantal_1;
               end if;
            end if;
         end if;  -- Einde Call en SK en OV
         -- het betreft een OV en OV combinatie order:
         if v_trans_indicatie = 'OV' and v_trans_indicatie_1 = 'OV'
         then
            -- eerst leg 1 controleren:
            lopende_orders_geblok_w (v_reffonds, v_fonds_prijs_factor, v_aantal, i_terminalnummer, gv_debuggen,
                                     gv_debug_user, v_prod_aantal_gedekt);

            -- tweede leg controleren:
            lopende_orders_geblok_w (v_reffonds_1, v_fonds_prijs_factor_1, v_aantal_1, i_terminalnummer, gv_debuggen,
                                     gv_debug_user, v_prod_aantal_gedekt_1);

            -- als de afgedekte aantalen gelijk zijn aan het order aantal dan hoeft er niets te gebeuren, anders de aantalen
            -- aanpassen aan het grootste order aantal dat nog afgedekt moet worden:
            if v_aantal <> v_prod_aantal_gedekt or v_aantal_1 <> v_prod_aantal_gedekt_1
            then
               if v_aantal - v_prod_aantal_gedekt <= v_aantal_1 - v_prod_aantal_gedekt_1
               then
                  v_aantal   := v_aantal_1 - v_prod_aantal_gedekt_1;
                  v_aantal_1 := v_aantal;
               else
                  v_aantal   := v_aantal - v_prod_aantal_gedekt;
                  v_aantal_1 := v_aantal;
               end if;
            else
               v_comb_berek_uitvoeren := 0;
            end if;
         end if; -- einde CALL en OV en OV.

         -- Er hoeft niets gedaan te worden als het de volgende combinaties betreft:
         -- SV en OK
         -- OK en OK
         -- SV en SV
         -- SK en SK
      end if; -- einde v_optietype = Call en v_optietype_1 = Call en pr_blokkerren_short_call = 1

      -- het betreft een combinatie met put opties:
      if v_optietype = 'PUT' and v_optietype_1 = 'PUT'
         and (i_pr_blokkeren_short_put = 1 or i_pr_blokkeren_long_put = 1)
         and v_bi_nummer not between 3000 and 3099
         and v_reffonds = v_reffonds_1
      then
         -- Er hoeft alleen maar iets gedaan te worden voor SK-OV en OV-OV combinaties:
         -- het betreft een SK en OV combinatie order:
         if ((v_trans_indicatie = 'SK' and v_trans_indicatie_1 = 'OV')
              or
             (v_trans_indicatie = 'OV' and v_trans_indicatie_1 = 'SK'))
              and i_pr_blokkeren_short_put = 1
         then
            -- als eerste bepalen of er al is geblokkeerd voor de nu short positie (de positie die nu met SK wordt gesloten):
            if v_trans_indicatie = 'SK'
            then
               positie_prod_afgedekt(v_symbool, v_optietype, v_expiratiedatum, v_exerciseprijs, v_reffonds,
                                     i_terminalnummer, v_prod_aantal_gedekt);
               -- als het prod aantal gedekt groter of gelijk is aan het order aantal moet er geld teruggegeven
               -- gaan worden (er wordt nl ook al voor deze order geld geblokkeerd). Altijd het laagste geblokkeerde
               -- geld bedrag van beide opties terug geven (houdt in kleinste exerciseprijs gebruiken):
               if v_prod_aantal_gedekt >= v_aantal
               then
                  v_comb_berek_uitvoeren := 0;
                  if v_exerciseprijs <= v_exerciseprijs_1
                  then
                     -- geld teruggeven ter groote van v_exercisprijs * v_fonds_prijs_factor * v_aantal
                     teruggave_prod_geld (v_fonds_muntsoort, v_fonds_mntsrt_bkoers, v_fonds_mntsrt_fact,
                                          v_fonds_mntsrt_recip, (v_exerciseprijs * v_fonds_prijs_factor * v_aantal),
                                          i_terminalnummer);
                  else
                     -- geld teruggeven ter grootte van v_exercisprijs_1 * v_fonds_prijs_factor_1 * v_aantal_1
                     teruggave_prod_geld (v_fonds_muntsoort_1, v_fonds_mntsrt_bkoers_1, v_fonds_mntsrt_fact_1,
                                          v_fonds_mntsrt_recip_1,
                                          (v_exerciseprijs_1 * v_fonds_prijs_factor_1 * v_aantal_1), i_terminalnummer);

                  end if;
               else
                  -- doorgaan voor het nog niet afgedekte gedeelte
                  v_aantal   := v_aantal - v_prod_aantal_gedekt;
                  v_aantal_1 := v_aantal;
                  -- Voor het wel al afgedekte gedeelte geld teruggeven (ook hier weer de kleinste exerciseprijs gebruiken):
                  if v_prod_aantal_gedekt <> 0
                  then
                     if v_exerciseprijs <= v_exerciseprijs_1
                     then
                        -- geld teruggeven ter groote van v_exercisprijs * v_fonds_prijs_factor * v_aantal
                        teruggave_prod_geld (v_fonds_muntsoort, v_fonds_mntsrt_bkoers, v_fonds_mntsrt_fact,
                                             v_fonds_mntsrt_recip, (v_exerciseprijs * v_fonds_prijs_factor * v_prod_aantal_gedekt),
                                             i_terminalnummer);
                     else
                        -- geld teruggeven ter grootte van v_exercisprijs_1 * v_fonds_prijs_factor_1 * v_aantal_1
                        teruggave_prod_geld (v_fonds_muntsoort_1, v_fonds_mntsrt_bkoers_1, v_fonds_mntsrt_fact_1,
                                             v_fonds_mntsrt_recip_1,
                                             (v_exerciseprijs_1 * v_fonds_prijs_factor_1 * v_prod_aantal_gedekt), i_terminalnummer);
                     end if;
                  end if;
               end if;
            -- als eerste bepalen of er al is geblokkeerd voor de nu short positie (de positie die nu met SK wordt gesloten):
            elsif v_trans_indicatie_1 = 'SK'
            then
               positie_prod_afgedekt(v_symbool_1, v_optietype_1, v_expiratiedatum_1, v_exerciseprijs_1, v_reffonds_1,
                                     i_terminalnummer, v_prod_aantal_gedekt_1);
               -- als het prod aantal gedekt groter of gelijk is aan het order aantal moet er geld teruggegeven
               -- gaan worden (er wordt nl ook al voor deze order geld geblokkeerd). Altijd het laagste geblokkeerde
               -- geld bedrag van beide opties terug geven (houdt in kleinste exerciseprijs gebruiken):
               if v_prod_aantal_gedekt_1 >= v_aantal_1
               then
                  v_comb_berek_uitvoeren := 0;
                  if v_exerciseprijs <= v_exerciseprijs_1
                  then
                     -- geld teruggeven ter groote van v_exercisprijs * v_fonds_prijs_factor * v_aantal
                     teruggave_prod_geld (v_fonds_muntsoort, v_fonds_mntsrt_bkoers, v_fonds_mntsrt_fact,
                                          v_fonds_mntsrt_recip, (v_exerciseprijs * v_fonds_prijs_factor * v_aantal),
                                          i_terminalnummer);
                  else
                     -- geld teruggeven ter grootte van v_exercisprijs_1 * v_fonds_prijs_factor_1 * v_aantal_1
                     teruggave_prod_geld (v_fonds_muntsoort_1, v_fonds_mntsrt_bkoers_1, v_fonds_mntsrt_fact_1,
                                          v_fonds_mntsrt_recip_1,
                                          (v_exerciseprijs_1 * v_fonds_prijs_factor_1 * v_aantal_1), i_terminalnummer);

                  end if;
               else
                  -- doorgaan voor het nog niet afgedekte gedeelte
                  v_aantal_1 := v_aantal_1 - v_prod_aantal_gedekt_1;
                  v_aantal   := v_aantal_1;
                  -- Voor het wel al afgedekte gedeelte geld teruggeven (ook hier weer de kleinste exerciseprijs gebruiken):
                  if v_prod_aantal_gedekt <> 0
                  then
                     if v_exerciseprijs <= v_exerciseprijs_1
                     then
                        -- geld teruggeven ter groote van v_exercisprijs * v_fonds_prijs_factor * v_aantal
                        teruggave_prod_geld (v_fonds_muntsoort, v_fonds_mntsrt_bkoers, v_fonds_mntsrt_fact,
                                             v_fonds_mntsrt_recip, (v_exerciseprijs * v_fonds_prijs_factor * v_prod_aantal_gedekt),
                                             i_terminalnummer);
                     else
                        -- geld teruggeven ter grootte van v_exercisprijs_1 * v_fonds_prijs_factor_1 * v_aantal_1
                        teruggave_prod_geld (v_fonds_muntsoort_1, v_fonds_mntsrt_bkoers_1, v_fonds_mntsrt_fact_1,
                                             v_fonds_mntsrt_recip_1,
                                             (v_exerciseprijs_1 * v_fonds_prijs_factor_1 * v_prod_aantal_gedekt), i_terminalnummer);
                     end if;
                  end if;
               end if;
            end if;
         end if;  -- einde SK en OV en i_pr_blokkeren_short_put = 1

         -- het betreft een OV en OV combinatie order:
         if v_trans_indicatie = 'OV' and v_trans_indicatie_1 = 'OV' and i_pr_blokkeren_short_call = 1
         then
            -- eerste leg controleren:
            lopende_orders_geblok_w (v_fonds_muntsoort, (v_exerciseprijs * v_fonds_prijs_factor), v_aantal, i_terminalnummer,
                                     gv_debuggen, gv_debug_user, v_prod_aantal_gedekt);

            -- tweede leg controleren:
            lopende_orders_geblok_w (v_fonds_muntsoort_1, (v_exerciseprijs_1 * v_fonds_prijs_factor_1), v_aantal_1,
                                     i_terminalnummer, gv_debuggen, gv_debug_user, v_prod_aantal_gedekt_1);

            -- als de afgedekte aantalen gelijk zijn aan het order aantal dan hoeft er niets te gebeuren, anders de aantalen
            -- aanpassen aan het grootste order aantal dat nog afgedekt moet worden (marginverplichting treedt dus op):
            if v_aantal <> v_prod_aantal_gedekt or v_aantal_1 <> v_prod_aantal_gedekt_1
            then
               if v_aantal - v_prod_aantal_gedekt <= v_aantal_1 - v_prod_aantal_gedekt_1
               then
                  v_aantal   := v_aantal_1 - v_prod_aantal_gedekt_1;
                  v_aantal_1 := v_aantal;
               else
                  v_aantal   := v_aantal - v_prod_aantal_gedekt;
                  v_aantal_1 := v_aantal;
               end if;
            else
               v_comb_berek_uitvoeren := 0;
            end if;

         end if; -- einde OV en OV en i_pr_blokkeren_short_put = 1

         -- Er hoef niets gedaan te worden als het de volgende combinaties betreft:
         -- SV en OK Voor de OK is in de Magic programmatuur geen stukken geblokkeerd (er wordt nl al vanuit gegaan dat
         --          de positie die nu met SV wordt opgeheven al stukken geblokkeerd heeft. Verder levert deze combinatie
         --          geen marginverplichting op dus hoef hier verder niets gedaan te worden.....
         -- SK en SK
         -- OK en OK Voor de OK moeten wel stukken worden geblokkeerd, maar als dat niet is gedaan dan is daar verder
         --          hier niets voor te doen; deze combinatie levert verder geen marginverplichting op .....
         -- SV en SV
      end if; -- einde optietype = 'PUT' en optietype_1 = 'PUT' en i_pr_blokkeren_short_put en i_pr_blokkeren_long_put = 1

      -- Straddle/Strangle constructies (een aantal specifieke komen voor teruggave van stukken in aanmerking):
      if ((v_optietype = 'CALL' and v_trans_indicatie = 'OV' and v_optietype_1 = 'PUT' and v_trans_indicatie_1 = 'SV')
           or
          (v_optietype = 'CALL' and v_trans_indicatie = 'SK' and v_optietype_1 = 'PUT' and v_trans_indicatie_1 = 'OK')
           or
          (v_optietype_1 = 'CALL' and v_trans_indicatie_1 = 'OV' and v_optietype = 'PUT' and v_trans_indicatie = 'SV')
           or
          (v_optietype_1 = 'CALL' and v_trans_indicatie_1 = 'SK' and v_optietype = 'PUT' and v_trans_indicatie = 'OK'))
          and v_reffonds = v_reffonds_1
         and v_bi_nummer not between 3000 and 3099
         and i_pr_blokkeren_short_call = 1 and i_pr_blokkeren_long_put = 1
      then
         -- controleren of voor beide legs stukken zijn geblokkeerd of nog kunnen worden geblokkeerd...

         -- Voor de SK en SV kant waren de stukken al in dekking gezet (dit zijn immers de sluittransacties).....
         -- dus de stukken zijn al toegekend in de "normale" margin berekening!
         -- Voor de OV en OK kant zijn de stukken voor deze order in dekking gezet (dit zijn immers de opentransacties)...
         -- dus de stukken zijn nog niet toegekend en zullen dat hier moeten...
         if v_trans_indicatie = 'SK'
         then
            -- leg 1 is de SK en is dus al in de normale margin meegelopen:
            positie_prod_afgedekt (v_symbool, v_optietype, v_expiratiedatum, v_exerciseprijs, v_reffonds,i_terminalnummer,
                                   v_prod_aantal_gedekt);
            -- leg 2 is de OK en het geblokeerde aantal moet hier dus worden geregistreerd:
            lopende_orders_geblok_w (v_reffonds_1, v_fonds_prijs_factor_1, v_aantal_1, i_terminalnummer, gv_debuggen,
                                     gv_debug_user, v_prod_aantal_gedekt_1);
         elsif v_trans_indicatie_1 = 'SK'
         then
            -- leg 2 is de SK en is dus al in de normale margin meegelopen:
            positie_prod_afgedekt (v_symbool_1, v_optietype_1, v_expiratiedatum_1, v_exerciseprijs_1, v_reffonds_1,
                                   i_terminalnummer, v_prod_aantal_gedekt_1);
            -- leg 1 is de OK en het geblokeerde aantal moet hier dus worden geregistreerd:
            lopende_orders_geblok_w (v_reffonds, v_fonds_prijs_factor, v_aantal, i_terminalnummer, gv_debuggen,
                                     gv_debug_user, v_prod_aantal_gedekt);
         elsif v_trans_indicatie = 'OV'
         then
            -- Leg 1 is de OV en het geblokkeerde aantal moet hier dus worden geregistreerd:
            lopende_orders_geblok_w (v_reffonds, v_fonds_prijs_factor, v_aantal, i_terminalnummer, gv_debuggen,
                                     gv_debug_user, v_prod_aantal_gedekt);
            -- Leg 2 is de SV en is dus al in de normale margin meegelopen:
            positie_prod_afgedekt (v_symbool_1, v_optietype_1, v_expiratiedatum_1, v_exerciseprijs_1, v_reffonds_1,
                                   i_terminalnummer, v_prod_aantal_gedekt_1);
         elsif v_trans_indicatie_1 = 'OV'
         then
            -- leg 2 is de OV en het geblokeerde aantal moet hier dus worden geregistreerd:
            lopende_orders_geblok_w (v_reffonds_1, v_fonds_prijs_factor_1, v_aantal_1, i_terminalnummer, gv_debuggen,
                                     gv_debug_user, v_prod_aantal_gedekt_1);
            -- leg 1 is de SV en is dus al in de normale margin meegelopen:
            positie_prod_afgedekt (v_symbool, v_optietype, v_expiratiedatum, v_exerciseprijs, v_reffonds,i_terminalnummer,
                                   v_prod_aantal_gedekt);
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'in FIAT_ORDER_MARGIN.lopende_orders_margin straddle/strangle teruggeven blokkade');
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'aantal   : '||to_char(v_aantal)  ||' ;  prod aantal gedekt   : '||to_char(v_prod_aantal_gedekt));
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'aantal 1 : '||to_char(v_aantal_1)||' ;  prod aantal gedekt 1 : '||to_char(v_prod_aantal_gedekt_1));
         end if;

         -- Beide legs zijn volledig afgedekt middels geblokkeerde posities:
         if v_aantal - v_prod_aantal_gedekt = 0 and v_aantal_1 - v_prod_aantal_gedekt_1 = 0
         then
            -- verdere verwerking is niet nodig
            v_comb_berek_uitvoeren := 0;
            -- teruggeven van de geblokkeerde stukken van één van de legs:
            teruggave_prod_stukken (v_reffonds, v_ref_symbool_volgnummer, (v_aantal * v_fonds_prijs_factor) , i_terminalnummer,
                                    gv_debuggen, gv_debug_user);

         -- één of beide legs zijn niet volledig afgedekt. Het aantal aanpassen aan het nog grootste aantal dat nog
         -- niet is afgedekt:
         else
            if v_prod_aantal_gedekt < v_prod_aantal_gedekt_1
            then
               v_aantal   := v_aantal - v_prod_aantal_gedekt;
               v_aantal_1 := v_aantal;
               -- de tegenwaarde van het minimale aantal dat wel is afgedekt teruggeven:
               teruggave_prod_stukken (v_reffonds, v_ref_symbool_volgnummer, (v_prod_aantal_gedekt * v_fonds_prijs_factor), i_terminalnummer,
                                       gv_debuggen, gv_debug_user);
            else
               v_aantal_1 := v_aantal_1 - v_prod_aantal_gedekt_1;
               v_aantal   := v_aantal_1;
               -- de tegenwaarde van het minimale aantal dat wel is afgedekt teruggeven:
               teruggave_prod_stukken (v_reffonds_1, v_ref_symbool_volgnummer, (v_prod_aantal_gedekt_1 * v_fonds_prijs_factor_1), i_terminalnummer,
                                       gv_debuggen, gv_debug_user);
            end if;
         end if;
      end if; -- einde Call OV - Put SV of Call SK - Put OK (straddle/strangle)

      -- Er is geen (of niet voldoende) dekking voor de combinatie gevonden:
      if v_comb_berek_uitvoeren = 1
      then

         if v_trans_indicatie ='OV'
         then
            FIAT_ALGEMEEN.initial_margin (v_optietype, v_exerciseprijs, v_pricing_unit, v_prijs_factor, v_laatkoers_optie,
                                          v_margin_factor, v_margin_opslag, v_biedkoers_reffonds, v_aantal, i_sys_toeslag_optiemarg,
                                          i_rel_toeslag_optiemarg, i_methode_naked_margin, i_factor_naked_margin, 
                                          gv_pr_blokkeren_short_call, gv_pr_blokkeren_short_put, gv_debuggen, gv_debug_user, v_init_margin);
         end if;

         if v_trans_indicatie_1 = 'OV'
         then
            FIAT_ALGEMEEN.initial_margin (v_optietype_1, v_exerciseprijs_1, v_pricing_unit_1, v_prijs_factor_1, v_laatkoers_optie_1,
                                          v_margin_factor_1, v_margin_opslag_1, v_biedkoers_reffonds_1, v_aantal_1, i_sys_toeslag_optiemarg,
                                          i_rel_toeslag_optiemarg, i_methode_naked_margin, i_factor_naked_margin, 
                                          gv_pr_blokkeren_short_call, gv_pr_blokkeren_short_put, gv_debuggen, gv_debug_user, v_init_margin_1);
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure FIAT_ORDER_MARGIN.lopende_orders_margin');
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in het combinatie order gedeelte ');
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'berekende init margin leg 1 : '||to_char(v_init_margin)||' ; berekende init margin leg 2 : '||to_char(v_init_margin_1));
         end if;

         -- combinatietypes afhandelen:
         -- A. overige combinatietypes:
         if v_combinatietype < 2 or v_combinatietype > 4 and v_combinatietype < 6 or v_combinatietype > 9
            or (v_combinatietype in (3,4) and (v_trans_indicatie <> 'OV' or v_trans_indicatie_1 <> 'OV'))
         then
            v_totaal_margin := v_init_margin + v_init_margin_1;
         else
            -- B. spread combinaties:
            if v_combinatietype = 2 or v_combinatietype between 6 and 9
            then
               v_margin_spread := 0;

               if v_bi_nummer between 3000 and 3099
               then
                  v_index_optie := 1;
               else
                  v_index_optie := 0;
               end if;

               if v_trans_indicatie = 'OV'
               then
                  spread_margin (v_symbool, v_optietype, v_expiratiedatum, v_exerciseprijs, v_prijs_factor, v_pricing_unit,
                                 v_symbool_1, v_optietype_1, v_expiratiedatum_1, v_exerciseprijs_1, v_prijs_factor_1, v_pricing_unit_1,
                                 v_aantal, v_index_optie, i_slot_of_last, i_sys_toeslag_optiemarg, v_margin_spread, v_aantal_ongedekt);
                  -- niet gedekt v_aantal apart berekenen:
                  if v_aantal_ongedekt <> 0
                  then
                     FIAT_ALGEMEEN.initial_margin (v_optietype, v_exerciseprijs, v_pricing_unit, v_prijs_factor, v_laatkoers_optie,
                                                   v_margin_factor, v_margin_opslag, v_biedkoers_reffonds, v_aantal_ongedekt, i_sys_toeslag_optiemarg,
                                                   i_rel_toeslag_optiemarg, i_methode_naked_margin, i_factor_naked_margin, 
                                                   gv_pr_blokkeren_short_call, gv_pr_blokkeren_short_put, gv_debuggen, gv_debug_user, v_margin_ongedekt);
                  else
                     v_margin_ongedekt := 0;
                  end if;
                  v_totaal_margin := v_margin_spread + v_margin_ongedekt;
               end if;

               if v_trans_indicatie <> 'OV'
               then
                  spread_margin (v_symbool_1, v_optietype_1, v_expiratiedatum_1, v_exerciseprijs_1, v_prijs_factor_1, v_pricing_unit_1,
                                 v_symbool, v_optietype, v_expiratiedatum, v_exerciseprijs, v_prijs_factor, v_pricing_unit,
                                 v_aantal, v_index_optie, i_slot_of_last, i_sys_toeslag_optiemarg, v_margin_spread, v_aantal_ongedekt_1);

                  -- niet gedekt v_aantal apart berekenen:
                  if v_aantal_ongedekt_1 <> 0
                  then
                     FIAT_ALGEMEEN.initial_margin (v_optietype_1, v_exerciseprijs_1, v_pricing_unit_1, v_prijs_factor_1, v_laatkoers_optie_1,
                                                   v_margin_factor_1, v_margin_opslag_1, v_biedkoers_reffonds_1, v_aantal_ongedekt_1, i_sys_toeslag_optiemarg,
                                                   i_rel_toeslag_optiemarg, i_methode_naked_margin, i_factor_naked_margin, 
                                                   gv_pr_blokkeren_short_call, gv_pr_blokkeren_short_put, gv_debuggen, gv_debug_user, v_margin_ongedekt);
                  else
                     v_margin_ongedekt := 0;
                  end if;
                  v_totaal_margin := v_margin_spread + v_margin_ongedekt;
               end if;

               if gv_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Einde van het spread gedeelte');
               end if;
            end if;

            -- C. straddle/strangle combinaties (alleen beide OV)
            if v_combinatietype in (3,4) and v_trans_indicatie = 'OV' and v_trans_indicatie_1 = 'OV'
            then
               if v_optietype = 'CALL'
               then
                  straddle_margin(v_exerciseprijs, v_expiratiedatum, v_laatkoers_optie, v_prijs_factor, v_pricing_unit,
                                  v_exerciseprijs_1, v_expiratiedatum_1, v_laatkoers_optie_1, v_prijs_factor_1, v_pricing_unit_1,
                                  v_biedkoers_reffonds, v_margin_factor, i_sys_toeslag_optiemarg, v_aantal, v_aantal_ongedekt,
                                  v_aantal_ongedekt_1, v_margin_straddle);
               else
                  straddle_margin(v_exerciseprijs_1, v_expiratiedatum_1, v_laatkoers_optie_1, v_prijs_factor_1, v_pricing_unit_1,
                                  v_exerciseprijs, v_expiratiedatum, v_laatkoers_optie, v_prijs_factor, v_pricing_unit,
                                  v_biedkoers_reffonds_1, v_margin_factor_1, i_sys_toeslag_optiemarg, v_aantal, v_aantal_ongedekt_1,
                                  v_aantal_ongedekt, v_margin_straddle);
               end if;

               if v_aantal_ongedekt <> 0
               then
                  FIAT_ALGEMEEN.initial_margin (v_optietype, v_exerciseprijs, v_pricing_unit, v_prijs_factor, v_laatkoers_optie,
                                                v_margin_factor, v_margin_opslag, v_biedkoers_reffonds, v_aantal_ongedekt, i_sys_toeslag_optiemarg,
                                                i_rel_toeslag_optiemarg, i_methode_naked_margin, i_factor_naked_margin, 
                                                gv_pr_blokkeren_short_call, gv_pr_blokkeren_short_put, gv_debuggen, gv_debug_user, v_margin_ongedekt);

                  v_margin_straddle := v_margin_straddle + v_margin_ongedekt;
               end if;

               if v_aantal_ongedekt_1 <> 0
               then
                  v_margin_ongedekt := 0;

                  FIAT_ALGEMEEN.initial_margin (v_optietype_1, v_exerciseprijs_1, v_pricing_unit_1, v_prijs_factor_1, v_laatkoers_optie_1,
                                                v_margin_factor_1, v_margin_opslag_1, v_biedkoers_reffonds_1, v_aantal_ongedekt_1, i_sys_toeslag_optiemarg,
                                                i_rel_toeslag_optiemarg, i_methode_naked_margin, i_factor_naked_margin, 
                                                gv_pr_blokkeren_short_call, gv_pr_blokkeren_short_put, gv_debuggen, gv_debug_user, v_margin_ongedekt);

                  v_margin_straddle := v_margin_straddle + v_margin_ongedekt;
               end if;

               v_totaal_margin := v_margin_straddle;

               if gv_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in het straddle gedeelte');
               end if;
            end if;
         end if;

         -- controleren of de totaal berekende margin niet groter is dan de optelling van de initiele margin van de beide legs:
         if v_totaal_margin > v_init_margin + v_init_margin_1
         then
            v_totaal_margin := v_init_margin + v_init_margin_1;
         end if;

         select FIAT_ALGEMEEN.omrekenen_bedrag_vv(v_totaal_margin, v_fonds_mntsrt_recip, v_fonds_mntsrt_fact, v_fonds_mntsrt_bkoers,
                                                  v_fonds_mntsrt_lkoers, gv_rel_rapp_reciproke, gv_rel_rapp_factor, gv_rel_rapp_biedkoers,
                                                  gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
         into   v_totaal_margin
         from   dual;

      end if; -- einde van v_comb_berek_uitvoeren = 1
   end if;

   -- doorgeven van het berekende marginbedrag aan de parameter o_margin_bedrag:
   o_margin_bedrag := v_totaal_margin;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'berekende margin : '||to_char(o_margin_bedrag));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;
end lopende_orders_margin;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_MARGIN


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_GP_GEBLOK
procedure lopende_orders_gp_geblok
(i_fonds_valuta   in       werkbestand.wk_categorie_1%type
,i_actie          in       varchar2
,i_terminalnr     in       werkbestand.wk_terminal%type
,io_waarde        in out   werkbestand.wk_waarde_1%type
)

is

  v_totaal_geblokkeerd         werkbestand.wk_waarde_1%type;
  v_al_uitgegeven_geblokkeerd  werkbestand.wk_waarde_2%type;


begin
   -- Ophaal (Get) actie
   if i_actie = 'G'
   then
      begin
         select w.wk_waarde_1,        w.wk_waarde_2
         into   v_totaal_geblokkeerd, v_al_uitgegeven_geblokkeerd
         from   werkbestand w
         where  w.wk_terminal = i_terminalnr
         and    w.wk_soort    = 'BOLW'
         and    w.wk_categorie_1 = i_fonds_valuta
         and    w.wk_categorie_2 = ' '
         and    w.wk_categorie_3 = ' '
         and    w.wk_categorie_4 = ' ';

         io_waarde := v_totaal_geblokkeerd - v_al_uitgegeven_geblokkeerd;
      exception
         when no_data_found
         then
           io_waarde := 0;
      end;
   -- Wegschrijf (Put) actie
   elsif i_actie = 'P'
   then
      update werkbestand w
      set    w.wk_waarde_2 = w.wk_waarde_2 + io_waarde
      where  w.wk_terminal = i_terminalnr
      and    w.wk_soort    = 'BOLW'
      and    w.wk_categorie_1 = i_fonds_valuta
      and    w.wk_categorie_2 = ' '
      and    w.wk_categorie_3 = ' '
      and    w.wk_categorie_4 = ' ';
   end if;


end lopende_orders_gp_geblok;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_GP_GEBLOK


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_GEBLOK_W
-- procedure lopende_orders_geblok_w
procedure lopende_orders_geblok_w
(i_fonds_valuta   in        werkbestand.wk_categorie_1%type
,i_factor         in        number
,i_te_dekken_aant in        kosten_werkbestand.kst_trans_aantal%type
,i_terminalnr     in        werkbestand.wk_terminal%type
,i_debuggen       in        relatie_fiattering.rf_debug_j_n%type
,i_debug_user     in        relatie_fiattering.rf_debug_user%type
,o_gedekt_aant    out       kosten_werkbestand.kst_trans_aantal%type
)

is

  v_gevonden_aantal         werkbestand.wk_waarde_1%type;
  v_totaal_geblok           werkbestand.wk_waarde_1%type;
  v_al_uitgegeven_aantal    werkbestand.wk_waarde_2%type;
  
  v_volgnummer_refer_ow     beleggingsinstrument.be_volgnummer%type;
  v_ow_is_mandje            number(1);
  v_gedekt_aantal           werkbestand.wk_waarde_1%type;

begin
  o_gedekt_aant  := 0;
  
  -- Eerst bepalen of dit soms een mandje betreft....
  select b.be_volgnummer
  into   v_volgnummer_refer_ow
  from   beleggingsinstrument b
  where  b.be_symbool         = i_fonds_valuta
  and    b.be_optietype       = ' '
  and    b.be_expiratiedatum  = '00000000'
  and    b.be_exerciseprijs   = 0;
  
  begin
     select 1
     into   v_ow_is_mandje
     from   mandje_onderliggende_waarde m
     where  m.mnd_volgnummer = v_volgnummer_refer_ow
     and    rownum           <= 1;
  exception
     when no_data_found
     then
        v_ow_is_mandje := 0;
  end;
  
  if i_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'in FIAT_ORDER_MARGIN.lopende_orders_geblok_w');
     FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'fonds of valuta   : '||i_fonds_valuta||' ; factor : '||to_char(i_factor));
     FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'te dekken aantal  : '||to_char(i_te_dekken_aant)||' ; terminalnummer : '||to_char(i_terminalnr));
     FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'volgnummer ow     : '||to_char(v_volgnummer_refer_ow)||' ;  mandje is ow  : '||to_char(v_ow_is_mandje));
  end if;
  
  -- Het betreft geen mandje
  if v_ow_is_mandje = 0
  then
     begin
        select w.wk_waarde_1,   w.wk_waarde_2
        into   v_totaal_geblok, v_al_uitgegeven_aantal
        from   werkbestand w
        where  w.wk_terminal = i_terminalnr
        and    w.wk_soort    = 'BOLW'
        and    w.wk_categorie_1 = i_fonds_valuta
        and    w.wk_categorie_2 = ' '
        and    w.wk_categorie_3 = ' '
        and    w.wk_categorie_4 = ' '
        and    w.wk_datum_1     = '00000000';
        
        v_gevonden_aantal := trunc(((v_totaal_geblok - v_al_uitgegeven_aantal)/i_factor),0);
     exception
        when no_data_found
        then
           v_gevonden_aantal := 0;
     end;
     
     if i_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'De OW is geen mandje .... ');
        FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'totaal geblokkerd : '||to_char(v_totaal_geblok)||' ; al uitgegeven aantal : '||to_char(v_al_uitgegeven_aantal));
        FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'gevonden aantal   : '||to_char(v_gevonden_aantal));
        FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
     end if;
     
     -- als het gevonden aantal groter of gelijk is aan het te dekken aantal dan
     -- is het in z'n geheel afgedekt
     if v_gevonden_aantal >= i_te_dekken_aant
     then
        o_gedekt_aant := i_te_dekken_aant;
        
        update werkbestand b
        set    b.wk_waarde_2 = b.wk_waarde_2 + (i_te_dekken_aant * i_factor)
        where  b.wk_terminal    = i_terminalnr
        and    b.wk_soort       = 'BOLW'
        and    b.wk_categorie_1 = i_fonds_valuta
        and    b.wk_categorie_2 = ' '
        and    b.wk_categorie_3 = ' '
        and    b.wk_categorie_4 = ' '
        and    b.wk_datum_1     = '00000000';
        
     else
        o_gedekt_aant := v_gevonden_aantal;
        
        update werkbestand b
        set    b.wk_waarde_2 = b.wk_waarde_2 + (v_gevonden_aantal * i_factor)
        where  b.wk_terminal    = i_terminalnr
        and    b.wk_soort       = 'BOLW'
        and    b.wk_categorie_1 = i_fonds_valuta
        and    b.wk_categorie_2 = ' '
        and    b.wk_categorie_3 = ' '
        and    b.wk_categorie_4 = ' '
        and    b.wk_datum_1     = '00000000';
        
     end if;
     
  -- Referentiefonds is wel een mandje....
  else
     -- In twee stappen de handelingen afhandelen:
     -- Stap 1 Als eerste bepalen of alle OW uit het mandje wel voldoende geblokkeerde posities hebben.
     --        en hoeveel opties daadwerkelijk afgedekt kunnen worden
     declare
        v_maximaal_te_dekken     werkbestand.wk_waarde_1%type;
        v_beschikbaar_aantal     werkbestand.wk_waarde_1%type;
        v_gedekt_aantal_mnd      werkbestand.wk_waarde_1%type;
                
        cursor mn is
           select m.mnd_factor,    b.be_symbool
           from   mandje_onderliggende_waarde m, beleggingsinstrument b
           where  m.mnd_volgnummer     = v_volgnummer_refer_ow
           and    m.mnd_ref_volgnr     = b.be_volgnummer;
               
     begin
        -- reset van het gedekte aantal
        v_gedekt_aantal := -1;
        
        for r_mn in mn
        loop
           v_beschikbaar_aantal  := 0;
           
           -- per referentiesymbool van de ow bepalen wat de beschikbare geblokkeerde positie is
           lopende_orders_gp_geblok (r_mn.be_symbool, 'G', i_terminalnr, v_beschikbaar_aantal);
           
           if i_debuggen = 1
           then
              FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'huidig refsymbool in mandje :'||r_mn.be_symbool||
                                                       ' ; beschikbaar geblok stuk : '||to_char(v_beschikbaar_aantal));
              FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
           end if;
           
           -- met behulp van het beschikbaar aantal is het volgende aantal opties te dekken:
           v_maximaal_te_dekken := trunc(v_beschikbaar_aantal/(r_mn.mnd_factor * i_factor),0);
           v_gedekt_aantal_mnd  := least(i_te_dekken_aant, v_maximaal_te_dekken);
           
           if v_gedekt_aantal = -1
           then
              v_gedekt_aantal := v_gedekt_aantal_mnd;
           else
              v_gedekt_aantal := least (v_gedekt_aantal_mnd, v_gedekt_aantal);
           end if;
           
           if i_debuggen = 1
           then
              FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Met de OW uit het mandje  :'||r_mn.be_symbool||
                                                       ' ; gedekt aantal : '||to_char(v_gedekt_aantal));
              FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
           end if;
        end loop;
     end;
     
     -- Stap 2. Het in stap 1 bepaald aantal gebruiken om de stukken registeren en om de gegevens van de optie
     --         aan te passen. 
     -- Alleen uitvoeren als het gedekt aantal groter dan 0 is...
     if v_gedekt_aantal > 0
     then
        declare
           v_te_blokkeren_aantal        werkbestand.wk_waarde_1%type;
           
           cursor mo is
              select m.mnd_factor,        b.be_symbool
              from   mandje_onderliggende_waarde m, beleggingsinstrument b
              where  m.mnd_volgnummer = v_volgnummer_refer_ow 
              and    m.mnd_ref_volgnr = b.be_volgnummer;
              
        begin
        
           if i_debuggen = 1
           then
              FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'In deel 2 van afhandeling van het mandje  ');
              FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Het gedekt aantal : '||to_char(v_gedekt_aantal));
              FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
           end if;
           
           for r_mo in mo
           loop
               -- Vermenigvuldigen met de factor voor het fonds uit het mandje
               v_te_blokkeren_aantal    := v_gedekt_aantal * r_mo.mnd_factor * i_factor;
               lopende_orders_gp_geblok (r_mo.be_symbool, 'P', i_terminalnr, v_te_blokkeren_aantal );
                                      
               if i_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Fonds uit mandje :  '||r_mo.be_symbool||' ; factor in mandje : '||to_char(r_mo.mnd_factor));
                  FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Gebruikte geblokkeerde stukken  : '||to_char(v_te_blokkeren_aantal));
                  FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
               end if;
                       
           end loop;
        
        -- als laatste nog doorgeven hoeveel gedekt is:
        o_gedekt_aant := v_gedekt_aantal;
        end;
     else
        o_gedekt_aant := 0;
     end if; -- Einde gedekt aantal > 0
     
     
  end if;  -- Einde referentiefonds is mandje
  if i_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'gedekt aantal   : '||to_char(o_gedekt_aant));
     FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Einde FIAT_ORDER_MARGIN.lopende_orders_geblok_w');
     FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
  end if;


end lopende_orders_geblok_w;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_GEBLOK_W


-- DE CODE VOOR DE PROCEDURE TERUGGAVE_PROD_GELD
procedure teruggave_prod_geld
(i_valuta                     in  muntsoorten.mu_code%type
,i_biedkoers                  in  muntsoorten.mu_biedkoers%type
,i_factor                     in  muntsoorten.mu_factor%type
,i_reciproke                  in  muntsoorten.mu_reciproke%type
,i_bedrag                     in  kosten_werkbestand.kst_marginbedrag%type
,i_terminalnr                 in  werkbestand.wk_terminal%type
)
is

   v_bedrag_rapv              kosten_werkbestand.kst_marginbedrag%type;

begin
   if i_valuta = gv_rel_rapp_valuta
   then
      v_bedrag_rapv   := i_bedrag;
   else
      select FIAT_ALGEMEEN.omrekenen_bedrag_vv (i_bedrag , i_reciproke, i_factor, i_biedkoers, i_biedkoers,
                                                gv_rel_rapp_reciproke, gv_rel_rapp_factor, gv_rel_rapp_laatkoers,
                                                gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
      into   v_bedrag_rapv
      from   dual;
   end if;

   -- Eerst proberen te updaten (TGBG = Terug Gegeven geBlokkeerd Geld):
   update werkbestand w
   set    w.wk_waarde_1 = w.wk_waarde_1 + i_bedrag,
          w.wk_waarde_2 = w.wk_waarde_2 + v_bedrag_rapv
   where  w.wk_terminal    = i_terminalnr
   and    w.wk_soort       = 'TGBG'
   and    w.wk_categorie_1 = i_valuta
   and    w.wk_categorie_2 = ' '
   and    w.wk_categorie_3 = ' '
   and    w.wk_categorie_4 = ' '
   and    w.wk_datum_1     = '00000000';

   -- als dat niet lukt dan een insert:
   if sql%notfound
   then
      insert into werkbestand w
      (w.wk_terminal,    w.wk_soort,       w.wk_categorie_1,
       w.wk_categorie_2, w.wk_categorie_3, w.wk_categorie_4,
       w.wk_datum_1,     w.wk_waarde_1,    w.wk_waarde_2)
      values
      (i_terminalnr,     'TGBG',           i_valuta,
       ' ',              ' ',              ' ',
       '00000000',       i_bedrag,         v_bedrag_rapv);
   end if;

end teruggave_prod_geld;
-- EINDE CODE PROCEDURE TERUGGAVE_PROD_GELD


-- DE CODE VOOR DE PROCEDURE TERUGGAVE_PROD_STUKKEN
procedure teruggave_prod_stukken
(i_reffonds_symbool           in  beleggingsinstrument.be_referentiesymbool%type
,i_reffonds_id                in  beleggingsinstrument.be_volgnummer%type
,i_aantal                     in  kosten_werkbestand.kst_trans_aantal%type
,i_terminalnr                 in  werkbestand.wk_terminal%type
,i_debuggen                   in  relatie_fiattering.rf_debug_j_n%type
,i_debug_user                 in  relatie_fiattering.rf_debug_user%type
)

is

  v_totaal_tegenwrd_geblok    werkbestand.wk_waarde_1%type;
  v_totaal_geblokkeerd        werkbestand.wk_waarde_2%type;
  v_terug_gegeven_waarde      werkbestand.wk_waarde_1%type;

begin
   v_totaal_tegenwrd_geblok := 0;
   v_totaal_geblokkeerd     := 0;
   v_terug_gegeven_waarde   := 0;

   -- Eerst bepalen hoeveel er nu is geblokkeerd en wat de waarde daarvan is
   begin
      select f.amount_repc,            f.quantity
      into   v_totaal_tegenwrd_geblok, v_totaal_geblokkeerd
      from   fiat_blocked_lending_value f
      where  f.instrument_id      = i_reffonds_id
      and    f.blocked_type       = 'Geblokkeerd';
   exception
      when no_data_found
      then
         v_totaal_tegenwrd_geblok := 0;
         v_totaal_geblokkeerd     := 0;
   end;

   if i_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'in procedure FIAT_ORDER_MARGIN.teruggave_prod_stukken');
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'ref fonds symbool    : '||i_reffonds_symbool||' ; aantal : '||to_char(i_aantal));
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'totaal tegenw geblok : '||to_char(v_totaal_tegenwrd_geblok));
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'totaal geblokkeerd   : '||to_char(v_totaal_geblokkeerd));
   end if;

   if v_totaal_tegenwrd_geblok <> 0 and v_totaal_geblokkeerd<> 0
   then
      v_terug_gegeven_waarde := (v_totaal_tegenwrd_geblok * i_aantal)/v_totaal_geblokkeerd;
   end if;

   if i_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'terug te geven waarde : '||to_char(v_terug_gegeven_waarde));
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
   end if;

   -- Eerst proberen te updaten (TGBS = Terug Gegeven geBlokkeerde Stukken):
   update werkbestand w
   set    w.wk_waarde_1 = w.wk_waarde_1 + v_terug_gegeven_waarde,
          w.wk_waarde_2 = w.wk_waarde_2 + i_aantal
   where  w.wk_terminal    = i_terminalnr
   and    w.wk_soort       = 'TGBS'
   and    w.wk_categorie_1 = i_reffonds_symbool
   and    w.wk_categorie_2 = ' '
   and    w.wk_categorie_3 = ' '
   and    w.wk_categorie_4 = ' '
   and    w.wk_datum_1     = '00000000';

   -- als dat niet lukt dan een insert:
   if sql%notfound
   then
      insert into werkbestand w
      (w.wk_terminal,    w.wk_soort,             w.wk_categorie_1,
       w.wk_categorie_2, w.wk_categorie_3,       w.wk_categorie_4,
       w.wk_datum_1,     w.wk_waarde_1,          w.wk_waarde_2)
      values
      (i_terminalnr,     'TGBS',                 i_reffonds_symbool,
       ' ',              ' ',                    ' ',
       '00000000',       v_terug_gegeven_waarde, i_aantal);
   end if;

end teruggave_prod_stukken;
-- EINDE CODE PROCEDURE TERUGGAVE_PROD_STUKKEN


-- DE CODE VOOR DE PROCEDURE POSITIE_PROD_AFGEDEKT
procedure positie_prod_afgedekt
(i_fondssymbool                in  beleggingsinstrument.be_symbool%type
,i_optietype                  in  beleggingsinstrument.be_optietype%type
,i_expiratiedatum             in  beleggingsinstrument.be_expiratiedatum%type
,i_exerciseprijs              in  beleggingsinstrument.be_exerciseprijs%type
,i_ref_symbool                in  beleggingsinstrument.be_referentiesymbool%type
,i_terminalnummer             in  werkbestand.wk_terminal%type
,o_aantal_prod_afgedekt       out temp_margin_wb_sessie.tms_prod_geblok_aantal%type
)

is

begin
   select t.tms_prod_geblok_aantal
   into   o_aantal_prod_afgedekt
   from   temp_margin_wb_sessie t
   where  tms_relatienr            = i_terminalnummer
   and    tms_runnnummer           = 0
   and    tms_refsymbool           = i_ref_symbool
   and    tms_soort                = i_optietype
   and    tms_exp_datum            = i_expiratiedatum
   and    tms_exerciseprijs        = i_exerciseprijs
   and    tms_symbool              = i_fondssymbool;

exception
   when no_data_found
   then
      o_aantal_prod_afgedekt := 0;


end positie_prod_afgedekt;
-- HET EINDE CODE PROCEDURE POSITIE_PROD_AFGEDEKT


-- DE CODE VOOR DE PROCEDURE SPREAD_MARGIN
-- In deze procedure wordt de spread margin berekend voor lopende orders
procedure spread_margin
(i_symbool_short              in  beleggingsinstrument.be_symbool%type
,i_optietype_short            in  beleggingsinstrument.be_optietype%type
,i_expiratiedatum_short       in  beleggingsinstrument.be_expiratiedatum%type
,i_exerciseprijs_short        in  beleggingsinstrument.be_exerciseprijs%type
,i_factor_short               in  beleggingsinstrument.be_prijs_factor%type
,i_pricing_unit_short         in  beleggingsinstrument.be_pricing_unit%type
,i_symbool_long               in  beleggingsinstrument.be_symbool%type
,i_optietype_long             in  beleggingsinstrument.be_optietype%type
,i_expiratiedatum_long        in  beleggingsinstrument.be_expiratiedatum%type
,i_exerciseprijs_long         in  beleggingsinstrument.be_exerciseprijs%type
,i_factor_long                in  beleggingsinstrument.be_prijs_factor%type
,i_pricing_unit_long          in  beleggingsinstrument.be_pricing_unit%type
,i_aantal                     in  orders.ord_aantal%type
,i_index_opties               in  number
,i_slot_of_last               in  varchar2
,i_sys_toeslag_optiemarg      in  tabelgegevens.tb_waarde%type
,o_margin_spread              out temp_margin_wb_sessie.tms_spread_bedrag%type
,o_niet_gedekt_aantal         out orders.ord_aantal%type
)

is
  v_gedekt_aantal                 orders.ord_aantal%type;
  v_laat_koers_short              fn_quotes_vw.quot_laat%type;
  v_bied_koers_long               fn_quotes_vw.quot_bied%type;
  v_dummy_koers                   fn_quotes_vw.quot_midden%type;
  v_toeslag_time_spread           tabelgegevens.tb_waarde%type;
  v_minimum_spread_bedrag         tabelgegevens.tb_waarde%type;
  -- virtuals voor het bepalen van instellingen
  v_op_te_halen_instel            varchar2(30);
  v_inst_type                     varchar2(1);
  v_instelling                    varchar2(100);
    

begin
    -- initialiseren van de gegevens
    o_margin_spread      := 0;
    o_niet_gedekt_aantal := i_aantal;

    -- expiratiedatum van long optie positie is gelijk of later dan de expiratiedatum van de short optie positie.
    if   to_date(i_expiratiedatum_long,'yyyymmdd') >= to_date(i_expiratiedatum_short,'yyyymmdd')
    then
       -- bepalen hoeveel opties er zijn afgedekt middels deze combinatie:
       v_gedekt_aantal        := trunc(i_aantal * (i_factor_short * i_pricing_unit_short)/(i_factor_long * i_pricing_unit_long),0);
       o_niet_gedekt_aantal := i_aantal - v_gedekt_aantal;

       if i_optietype_short = 'CALL'
       then
          if i_exerciseprijs_short/i_pricing_unit_short < i_exerciseprijs_long/i_pricing_unit_long
          then
             o_margin_spread := (i_exerciseprijs_long/i_pricing_unit_long - i_exerciseprijs_short/i_pricing_unit_short) *
                                i_pricing_unit_short * i_factor_short * v_gedekt_aantal;
          else
             o_margin_spread := 0;
          end if;
       end if;

       if i_optietype_short = 'PUT'
       then
          if i_exerciseprijs_short/i_pricing_unit_short > i_exerciseprijs_long/i_pricing_unit_long
          then
             o_margin_spread := (i_exerciseprijs_short/i_pricing_unit_short - i_exerciseprijs_long/i_pricing_unit_long) *
                                i_pricing_unit_short * i_factor_short * v_gedekt_aantal;
          else
             o_margin_spread := 0;
          end if;
       end if;

       if gv_debuggen = 1
       then
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure FIAT_ORDER_MARGIN.spread_margin');
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'berekende marginbedrag spread (tussenwaarde): '||to_char(o_margin_spread));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'expiratiedatum short : '||i_expiratiedatum_short||' ;  expiratiedatum long : '||i_expiratiedatum_long);
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'index opties?        : '||to_char(i_index_opties));
       end if;

       --Time spread (index opties)
       if i_expiratiedatum_short <> i_expiratiedatum_long and i_index_opties = 1
       then
          -- ophalen van de specifieke bied en laat koersen:
          FIAT_ALGEMEEN.fondskoersen(i_symbool_short, i_optietype_short, i_expiratiedatum_short, i_exerciseprijs_short,
                                     i_slot_of_last, v_dummy_koers, v_laat_koers_short);
          FIAT_ALGEMEEN.fondskoersen(i_symbool_long,  i_optietype_long,  i_expiratiedatum_long,  i_exerciseprijs_long,
                                     i_slot_of_last, v_bied_koers_long, v_dummy_koers);
          -- berekende margin nooit lager dan verschil tussen de premies:
          if o_margin_spread < (v_laat_koers_short/i_pricing_unit_short - v_bied_koers_long/i_pricing_unit_long) *
                               i_pricing_unit_short * i_factor_short * v_gedekt_aantal
          then
             o_margin_spread := (v_laat_koers_short/i_pricing_unit_short - v_bied_koers_long/i_pricing_unit_long) *
                                i_pricing_unit_short * i_factor_short * v_gedekt_aantal;
          end if;
          
          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in het Time spread gedeelte');
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'laat koers short : '||to_char(v_laat_koers_short)||' ;  v_biedkoers long : '||to_char(v_bied_koers_long));
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin spread    : '||to_char(o_margin_spread)||' ; gedekt aantal : '||to_char(v_gedekt_aantal));
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
          end if;
          
          -- minimum spread bedrag
          v_op_te_halen_instel := 'MinSpreadBedr';
          v_inst_type          := 'N';
          select FIAT_ALGEMEEN.instell_bepalen(gv_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
          into   v_instelling
          from   dual;
          v_minimum_spread_bedrag := to_number(rtrim(ltrim(v_instelling)));

          if o_margin_spread < v_minimum_spread_bedrag * v_gedekt_aantal
          then
             o_margin_spread := v_minimum_spread_bedrag * v_gedekt_aantal;
          end if;

          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,',minimum spread bedrag');
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'minimum bedrag : '||to_char(v_minimum_spread_bedrag)||' ; margin spread : '||to_char(o_margin_spread));
          end if;

          if i_exerciseprijs_long = i_exerciseprijs_short
          then          
             -- margintoeslag time spread
             v_op_te_halen_instel := 'TimeSpreadToesl';
             v_inst_type          := 'N';
             select FIAT_ALGEMEEN.instell_bepalen(gv_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
             into   v_instelling
             from   dual;
             v_toeslag_time_spread := to_number(rtrim(ltrim(v_instelling)));

             o_margin_spread := o_margin_spread + v_gedekt_aantal * v_toeslag_time_spread;
             
             if gv_debuggen = 1
             then
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,',margintoeslag time spread');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'toeslag bedrag : '||to_char(v_toeslag_time_spread)||' ; margin spread : '||to_char(o_margin_spread));
             end if;
          end if;

       end if;

    -- toeslag optiemargin
    o_margin_spread := (1 + (i_sys_toeslag_optiemarg/100)) * o_margin_spread;

    if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'spreadmargin incl toeslag optiemargin');
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'marginbedrag (spread) : '||to_char(o_margin_spread)||' ; sys toeslag optiemargin : '||to_char(i_sys_toeslag_optiemarg));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
    end if;

    end if;
end spread_margin;
-- EINDE CODE PROCEDURE SPREAD_MARGIN


-- DE CODE VOOR DE PROCEDURE STRADDLE_MARGIN
-- In deze procedure wordt de straddle/strangle margin berekend voor lopende orders.
procedure straddle_margin
(i_exerciseprijs_call         in  beleggingsinstrument.be_exerciseprijs%type
,i_expiratiedatum_call        in  beleggingsinstrument.be_expiratiedatum%type
,i_premie_call                in  fn_quotes_vw.quot_laat%type
,i_factor_call                in  beleggingsinstrument.be_prijs_factor%type
,i_pricing_unit_call          in  beleggingsinstrument.be_pricing_unit%type
,i_exerciseprijs_put          in  beleggingsinstrument.be_exerciseprijs%type
,i_expiratiedatum_put         in  beleggingsinstrument.be_expiratiedatum%type
,i_premie_put                 in  fn_quotes_vw.quot_laat%type
,i_factor_put                 in  beleggingsinstrument.be_prijs_factor%type
,i_pricing_unit_put           in  beleggingsinstrument.be_pricing_unit%type
,i_biedkoers_ow               in  fn_quotes_vw.quot_bied%type
,i_margin_factor              in  beleggingsinstrument.be_margin_factor%type
,i_sys_toeslag_optiemarg      in  tabelgegevens.tb_waarde%type
,i_aantal                     in  orders.ord_aantal%type
,o_ongedekt_aantal_call       out orders.ord_aantal%type
,o_ongedekt_aantal_put        out orders.ord_aantal%type
,o_margin_straddle            out temp_margin_wb_sessie.tms_straddle_bedrag%type
)

is
  v_gedekt_aantal_put         orders.ord_aantal%type;
  v_gedekt_aantal_call        orders.ord_aantal%type;

begin
  -- initialiseren van de uitgaande parameters:
  o_ongedekt_aantal_call := i_aantal;
  o_ongedekt_aantal_put  := i_aantal;
  o_margin_straddle      := 0;

  -- Van beide opties is de expiratiedatum gelijk maar de exerciseprijs
  -- van de CALL optie is groter dan exerciseprijs van de PUT optie.
  if i_expiratiedatum_call = i_expiratiedatum_put and i_exerciseprijs_call>= i_exerciseprijs_put
  then
     -- Vanwege verschillende pricing units hoeft bij een gelijk aantal nog niet alles gedekt te zijn
     v_gedekt_aantal_call     := trunc(i_aantal * ((i_factor_put * i_pricing_unit_put) / (i_factor_call * i_pricing_unit_call)),0);
     o_ongedekt_aantal_call   := i_aantal - v_gedekt_aantal_call;
     v_gedekt_aantal_put      := trunc(i_aantal * ((i_factor_call * i_pricing_unit_call) / (i_factor_put * i_pricing_unit_put)),0);
     o_ongedekt_aantal_put    := i_aantal - v_gedekt_aantal_put;

     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure FIAT_ORDER_MARGIN.straddle_margin');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'o ongedekt aantal call : '||to_char(o_ongedekt_aantal_call)||' ; o ongedekt aantal put : '||to_char(o_ongedekt_aantal_put));
     end if;

     -- koers put > koers call:
     if i_premie_put/i_pricing_unit_put > i_premie_call/i_pricing_unit_call
     then
        o_margin_straddle := (2 * (i_exerciseprijs_put/i_pricing_unit_put) - i_biedkoers_ow);
     else
     -- koers put <= koers call:
        o_margin_straddle := (2 * i_biedkoers_ow - (i_exerciseprijs_call/i_pricing_unit_call));
     end if;

     if o_margin_straddle <0
     then
        o_margin_straddle := 0;
     end if;

     o_margin_straddle := o_margin_straddle * i_margin_factor / 100;

     if i_premie_put/i_pricing_unit_put > i_premie_call/i_pricing_unit_call
     then
        o_margin_straddle := (o_margin_straddle + i_premie_put) * i_factor_put * v_gedekt_aantal_put;
     else
        o_margin_straddle := (o_margin_straddle + i_premie_call) * i_factor_call * v_gedekt_aantal_call;
     end if;

     -- Berekende margin nooit lager dan de som van de premies
     if o_margin_straddle < (i_premie_call * i_factor_call * v_gedekt_aantal_call + i_premie_put * i_factor_put * v_gedekt_aantal_put)
     then
        o_margin_straddle :=(i_premie_call * i_factor_call * v_gedekt_aantal_call + i_premie_put * i_factor_put * v_gedekt_aantal_put);
     end if;

     -- toeslag optiemargin
     o_margin_straddle := (1 + (i_sys_toeslag_optiemarg/100)) * o_margin_straddle;

     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'straddle margin : '||to_char(o_margin_straddle));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
     end if;
  end if;
end;
-- EINDE CODE PROCEDURE STRADDLE_MARGIN


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_WAARBORG
-- In deze procedure wordt de waarborgsom voor de gehele opgegeven order berekend
-- (dus ook voor een combinatie order)
procedure lopende_orders_waarborg
(i_ordernummer                in  orders.ord_ordernummer%type
,i_orderregel                 in  orders.ord_orderregel%type
,i_orderdetailnummer          in  ordersdetaillering.orx_detailnummer%type
,i_bank2mrktqchangedate       in  muntsoorten.mu_update%type
,i_systspreadcodecategorie    in  valutaspread_cat_muntsoort.vscm_vsca_id%type
,i_bij_comb_apart_houden      in  number
,o_waarborgsom                out positie_werkbestand.pwb_waarborgsom_vv%type
)

is
  v_nominaal                  beleggingsinstrument.be_nominaal%type;
  v_transactiesoort           orders.ord_transactiesoort%type;
  v_aantal                    orders.ord_aantal%type;
  v_fonds_muntsoort           beleggingsinstrument.be_muntsoort%type;
  v_fonds_munt_bkoers         muntsoorten.mu_biedkoers%type;
  v_fonds_munt_fac            muntsoorten.mu_factor%type;
  v_fonds_munt_recp           muntsoorten.mu_reciproke%type;
  v_nominaal_1                beleggingsinstrument.be_nominaal%type;
  v_transactiesoort_1         orders.ord_transactiesoort%type;
  v_aantal_1                  orders.ord_aantal%type;
  v_fonds_muntsoort_1         beleggingsinstrument.be_muntsoort%type;
  v_fonds_munt_bkoers_1       muntsoorten.mu_biedkoers%type;
  v_fonds_munt_fac_1          muntsoorten.mu_factor%type;
  v_fonds_munt_recp_1         muntsoorten.mu_reciproke%type;
  v_nominaal_fnds_rel         beleggingsinstrument.be_nominaal%type;
  v_nominaal_fnds_rel_1       beleggingsinstrument.be_nominaal%type;
  v_dummy_waarde              number(1);

begin
  -- ophalen van de gegevens voor de doorgestuurde ordergegevens.
  select k.kst_trans_indicatie, k.kst_trans_aantal,
         k.kst_trans_muntsrt,   
         r.rf_rapp_muntsoort,   r.rf_rapp_biedkoers,     r.rf_rapp_laatkoers,
         r.rf_rapp_factor,      r.rf_rapp_reciproke,     r.rf_rapp_notatie,
         r.rf_pr_id,            r.rf_ppr_id,
         r.rf_debug_j_n,        r.rf_debug_user,
         b.be_nominaal
  into   v_transactiesoort,     v_aantal,
         v_fonds_muntsoort,     
         gv_rel_rapp_valuta,    gv_rel_rapp_biedkoers,   gv_rel_rapp_laatkoers,
         gv_rel_rapp_factor,    gv_rel_rapp_reciproke,   gv_rel_rapp_notatie,
         gv_pr_id,              gv_ppr_id,
         gv_debuggen,           gv_debug_user,
         v_nominaal
  from   kosten_werkbestand k, beleggingsinstrument b, relatie_fiattering r
  where  k.kst_ordernummer       = i_ordernummer
  and    k.kst_orderregel        = i_orderregel
  and    k.kst_detailnummer      = i_orderdetailnummer
  and    k.kst_fondssymbool      = b.be_symbool
  and    k.kst_optietype_fnds    = b.be_optietype
  and    k.kst_expiratiedat_fnds = b.be_expiratiedatum
  and    k.kst_exercisepr_fnds   = b.be_exerciseprijs;

  -- hier alvast de nominale waarde van fonds naar relatie valuta omrekenen:
  if v_fonds_muntsoort <> gv_rel_rapp_valuta
  then
     FIAT_ALGEMEEN.valutagegevens_bepalen (v_fonds_muntsoort,      gv_pr_id,       gv_ppr_id,        i_systspreadcodecategorie,
                                           i_bank2mrktqchangedate, gv_debuggen,    gv_debug_user,    v_fonds_munt_bkoers,
                                           v_dummy_waarde,         v_dummy_waarde, v_fonds_munt_fac, v_fonds_munt_recp,
                                           v_dummy_waarde);
          
     select FIAT_ALGEMEEN.omrekenen_bedrag_vv(v_nominaal, v_fonds_munt_recp, v_fonds_munt_fac, v_fonds_munt_bkoers,
                                              v_fonds_munt_bkoers, gv_rel_rapp_reciproke, gv_rel_rapp_factor, gv_rel_rapp_laatkoers,
                                              gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
     into   v_nominaal_fnds_rel
     from   dual;
     
  else
     v_nominaal_fnds_rel := v_nominaal;
  end if;

  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure FIAT_ORDER_MARGIN.lopende_orders_waarborg');
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'nominaal in relmuntsoort : '||to_char(v_nominaal_fnds_rel));
  end if;

  -- als de doorgegeven orderregel 2 is, is het een combinatieorder, hier de gegevens van het
  -- eerste leg hardcoded ophalen (het tweede leg wordt nl doorgegeven als parameter)
  if i_orderregel = 2
  then
     select k.kst_trans_indicatie, k.kst_trans_aantal,
            k.kst_trans_muntsrt,   
            b.be_nominaal
     into   v_transactiesoort_1,   v_aantal_1,
            v_fonds_muntsoort_1,   
            v_nominaal_1
     from   kosten_werkbestand k, beleggingsinstrument b
     where  k.kst_ordernummer       = i_ordernummer
     and    k.kst_orderregel        = 1
     and    k.kst_detailnummer      = i_orderdetailnummer
     and    k.kst_fondssymbool      = b.be_symbool
     and    k.kst_optietype_fnds    = b.be_optietype
     and    k.kst_expiratiedat_fnds = b.be_expiratiedatum
     and    k.kst_exercisepr_fnds   = b.be_exerciseprijs;

     -- hier alvast de nominale waarde omrekenen naar de relatievaluta
     if v_fonds_muntsoort_1 <> gv_rel_rapp_valuta
     then
        FIAT_ALGEMEEN.valutagegevens_bepalen (v_fonds_muntsoort_1,    gv_pr_id,       gv_ppr_id,          i_systspreadcodecategorie,
                                              i_bank2mrktqchangedate, gv_debuggen,    gv_debug_user,      v_fonds_munt_bkoers_1,
                                              v_dummy_waarde,         v_dummy_waarde, v_fonds_munt_fac_1, v_fonds_munt_recp_1,
                                              v_dummy_waarde);
        
        select FIAT_ALGEMEEN.omrekenen_bedrag_vv(v_nominaal_1, v_fonds_munt_recp_1, v_fonds_munt_fac_1, v_fonds_munt_bkoers_1,
                                                 v_fonds_munt_bkoers_1, gv_rel_rapp_reciproke, gv_rel_rapp_factor,
                                                 gv_rel_rapp_laatkoers, gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
        into   v_nominaal_fnds_rel_1
        from   dual;
     else
        v_nominaal_fnds_rel_1 := v_nominaal_1;
     end if;
     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'nominaal leg 2 in relmuntsoort : '||to_char(v_nominaal_fnds_rel_1));
     end if;
  end if;

  -- Combinatie order:
  if i_orderregel = 2 and i_bij_comb_apart_houden <> 1
  then
     -- doorrollen van een future (verschil in waarborgsommen meenemen)
     if substr(v_transactiesoort,1,1)='O' and substr(v_transactiesoort_1,1,1)='S'
     then
        if v_nominaal_fnds_rel - v_nominaal_fnds_rel_1>0
        then
           o_waarborgsom := abs(v_aantal) * (v_nominaal_fnds_rel - v_nominaal_fnds_rel_1);
        else
           o_waarborgsom := 0;
        end if;
     -- doorrollen van een future (verschil in waarborgsommen meenemen)
     elsif substr(v_transactiesoort,1,1)='S' and substr(v_transactiesoort_1,1,1)='O'
     then
        if v_nominaal_fnds_rel_1 - v_nominaal_fnds_rel > 0
        then
           o_waarborgsom := abs(v_aantal_1) * (v_nominaal_fnds_rel_1 - v_nominaal_fnds_rel);
        else
           o_waarborgsom := 0;
        end if;
     -- twee openingen: dan voor ieder v_aantal de waarborgsom berekenen
     elsif substr(v_transactiesoort,1,1)='O' and substr(v_transactiesoort_1,1,1)='O'
     then
        o_waarborgsom := abs(v_aantal) * v_nominaal_fnds_rel + abs(v_aantal_1)* v_nominaal_fnds_rel_1;
     else
        o_waarborgsom := 0;
     end if;
  else
     -- geen combinatie order:
     o_waarborgsom := abs(v_aantal) * v_nominaal_fnds_rel;
  end if;

  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'waarborgsom uit : '||to_char(o_waarborgsom));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
  end if;
end lopende_orders_waarborg;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_WAARBORG


-- DE CODE VOOR DE FUNCTION VERSION
function Version
return varchar2
is

begin
      return gv_versie;
end version;
-- EINDE CODE FUNCTION VERSION

end FIAT_ORDER_MARGIN;
/
