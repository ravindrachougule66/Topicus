create or replace package FIAT_ORDER_MARGIN_EFFECT
is

/*------------------------------------------------------------------------------
Package     : FIAT_ORDER_MARGIN_EFFECT
description : code voor de package FIAT_ORDER_MARGIN_EFFECT waarbinnen de
              volgende procedures en functions aanwezig zijn:
              procedure  lopende_orders_margin_effect
              function   version
------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';

-- procedure lopende_orders_margin_effect
   procedure lopende_orders_margin_effect
   (i_ordernummer              in  orders.ord_ordernummer%type
   ,i_orderregel               in  orders.ord_orderregel%type
   ,i_orderdetailnr            in  ordersdetaillering.orx_detailnummer%type
   ,i_relatienr                in  clienten.cl_nummer%type
   ,i_slot_last_koers          in  tabelgegevens.tb_symbool%type
   ,i_terminalnummer           in  werkbestand.wk_terminal%type
   ,i_sys_toeslag_optiemarg    in  tabelgegevens.tb_waarde%type
   ,i_rel_toeslag_optiemarg    in  producten.pr_toeslag_percentage%type
   ,i_methode_naked_margin     in  number
   ,i_factor_naked_margin      in  number
   ,i_trekkingswaarde_aktief   in  number
   ,i_pr_blokkeren_short_call  in  producten.pr_blokkeren_short_calls%type
   ,i_pr_blokkeren_short_put   in  producten.pr_blokkeren_short_puts%type
   ,i_pr_blokkeren_long_put    in  producten.pr_blokkeren_long_puts%type
   ,i_instellingen             in  varchar2
   ,o_margin_effect            out kosten_werkbestand.kst_marginbedrag%type
   );

-- function version
   function version
   return                      varchar2;

end FIAT_ORDER_MARGIN_EFFECT;
/
create or replace package body FIAT_ORDER_MARGIN_EFFECT
is

/*------------------------------------------------------------------------------
Package body : FIAT_ORDER_MARGIN_EFFECT
description  : code voor de package body FIAT_ORDER_MARGIN_EFFECT
               waarbinnen de volgende procedures en functions aanwezig zijn:
               procedure  lopende_orders_margin_effect
               procedure  lopende_orders_margin_wb_vul
               procedure  lopende_orders_margin_wb_aanp
               procedure  lopende_orders_margin_wb_wijz
               function   version
------------------------------------------------------------------------------*/

-- globale variabelen (dus te gebruiken over alle procedures nadat de waarden zijn
-- bepaald in de eerst aanroepend procedure)
   gv_rel_margin                   relatie_fiattering.rf_margin%type;
   gv_debuggen                     relatie_fiattering.rf_debug_j_n%type;
   gv_debug_user                   relatie_fiattering.rf_debug_user%type;

-- Declareren van de procedures die niet in de package header staan:

-- procedure lopende_orders_margin_wb_vul:
   procedure lopende_orders_margin_wb_vul
   (i_fondssymbool             in  kosten_werkbestand.kst_fondssymbool%type
   ,i_ref_of_fondssymbool      in  varchar2
   ,i_uitgangs_runnummer       in  temp_ap_werkbest_sessie.tas_runnummer%type
   ,i_controle_uitvoeren       in  number
   );

-- procedure lopende_orders_margin_mandje_wb_vul:
   procedure lopende_ord_marg_mandje_wb_vul
   (i_refsymb_be_volgnummer    in  beleggingsinstrument.be_volgnummer%type
   ,i_ow_is_mandje             in  number
   ,i_uitgangs_runnummer       in  temp_ap_werkbest_sessie.tas_runnummer%type
   ,o_extra_toevoeg_ivm_mandje out number
   );

-- procedure lopende_orders_margin_vul_mw:
   procedure lopende_orders_margin_vul_mw
   (i_relatienr                in  temp_margin_wb_sessie.tms_relatienr%type
   ,i_runnummer                in  temp_margin_wb_sessie.tms_runnnummer%type
   ,i_productnummer            in  temp_margin_wb_sessie.tms_productnummer%type
   ,i_productvolgnummer        in  temp_margin_wb_sessie.tms_product_volgnummer%type
   ,i_rekeningsoort            in  temp_margin_wb_sessie.tms_rekeningsoort%type
   ,i_rekeningnr               in  temp_margin_wb_sessie.tms_rekeningnr%type
   ,i_rekening_munts           in  temp_margin_wb_sessie.tms_rekening_munts%type
   ,i_refsymbool               in  temp_margin_wb_sessie.tms_refsymbool%type
   ,i_soort                    in  temp_margin_wb_sessie.tms_soort%type
   ,i_symbool                  in  temp_margin_wb_sessie.tms_symbool%type
   ,i_exp_datum                in  temp_margin_wb_sessie.tms_exp_datum%type
   ,i_exerciseprijs            in  temp_margin_wb_sessie.tms_exerciseprijs%type
   ,i_saldo_positie            in  temp_margin_wb_sessie.tms_saldo_positie%type
   ,i_positie_future           in  temp_margin_wb_sessie.tms_positie_future%type
   ,i_marginfactor             in  temp_margin_wb_sessie.tms_marginfactor%type
   ,i_slotkoers_voriged        in  temp_margin_wb_sessie.tms_slotkoers_voriged%type
   ,i_biedkoers                in  temp_margin_wb_sessie.tms_biedkoers%type
   ,i_laatkoers                in  temp_margin_wb_sessie.tms_laatkoers%type
   ,i_blocksize                in  temp_margin_wb_sessie.tms_blocksize%type
   ,i_margin_required          in  temp_margin_wb_sessie.tms_margin_required%type
   ,i_gecovered                in  temp_margin_wb_sessie.tms_gecovered%type
   ,i_spread_aantal            in  temp_margin_wb_sessie.tms_spread_aantal%type
   ,i_spread_bedrag            in  temp_margin_wb_sessie.tms_spread_bedrag%type
   ,i_straddle_aantal          in  temp_margin_wb_sessie.tms_straddle_aantal%type
   ,i_straddle_bedrag          in  temp_margin_wb_sessie.tms_straddle_bedrag%type
   ,i_valuta                   in  temp_margin_wb_sessie.tms_valuta%type
   ,i_collateral_bedrag        in  temp_margin_wb_sessie.tms_collateral_bedrag%type
   ,i_pricing_unit             in  temp_margin_wb_sessie.tms_pricing_unit%type
   ,i_cross_aantal             in  temp_margin_wb_sessie.tms_cross_aantal%type
   ,i_cross_bedrag             in  temp_margin_wb_sessie.tms_cross_bedrag%type
   ,i_gecovered_comp           in  temp_margin_wb_sessie.tms_gecovered_comp%type
   ,i_gecovered_comp_bedrag    in  temp_margin_wb_sessie.tms_gecovered_comp_bedrag%type
   ,i_rowid                    in  rowid
   ,i_controle_uitvoeren       in  number
   );
   
-- procedure lopende_orders_margin_vul_ap
   procedure lopende_orders_margin_vul_ap
   (i_ref_relatie              in  temp_ap_werkbest_sessie.tas_ref_relatie%type
   ,i_productnummer            in  temp_ap_werkbest_sessie.tas_productnummer%type
   ,i_product_volgnummer       in  temp_ap_werkbest_sessie.tas_product_volgnummer%type
   ,i_relatienr                in  temp_ap_werkbest_sessie.tas_relatienr%type
   ,i_runnummer                in  temp_ap_werkbest_sessie.tas_runnummer%type
   ,i_rekening_soort           in  temp_ap_werkbest_sessie.tas_rekening_soort%type
   ,i_rekeningnr               in  temp_ap_werkbest_sessie.tas_rekeningnr%type
   ,i_rekening_munts           in  temp_ap_werkbest_sessie.tas_rekening_munts%type
   ,i_ref_symbool              in  temp_ap_werkbest_sessie.tas_ref_symbool%type
   ,i_symbool                  in  temp_ap_werkbest_sessie.tas_symbool%type
   ,i_optietype                in  temp_ap_werkbest_sessie.tas_optietype%type
   ,i_expiratiedatum           in  temp_ap_werkbest_sessie.tas_expiratiedatum%type
   ,i_exerciseprijs            in  temp_ap_werkbest_sessie.tas_exerciseprijs%type
   ,i_saldo_positie            in  temp_ap_werkbest_sessie.tas_saldo_positie%type
   ,i_positie_future           in  temp_ap_werkbest_sessie.tas_positie_future%type
   ,i_hist_wrd_poscl           in  temp_ap_werkbest_sessie.tas_hist_wrd_poscl%type
   ,i_hist_wrd_posbe           in  temp_ap_werkbest_sessie.tas_hist_wrd_posbe%type
   ,i_hist_wrd_totcl           in  temp_ap_werkbest_sessie.tas_hist_wrd_totcl%type
   ,i_hist_wrd_totbe           in  temp_ap_werkbest_sessie.tas_hist_wrd_totbe%type
   ,i_bi_type                  in  temp_ap_werkbest_sessie.tas_bi_type%type
   ,i_sld_losbaar_marg         in  temp_ap_werkbest_sessie.tas_sld_losbaar_marg%type
   ,i_in_cover                 in  temp_ap_werkbest_sessie.tas_in_cover%type
   ,i_in_cover_used            in  temp_ap_werkbest_sessie.tas_in_cover_used%type
   ,i_in_collateral            in  temp_ap_werkbest_sessie.tas_in_collateral%type
   ,i_tegenwaarde_basis        in  temp_ap_werkbest_sessie.tas_tegenwaarde_basis%type
   ,i_export                   in  temp_ap_werkbest_sessie.tas_export%type
   ,i_positie_long             in  temp_ap_werkbest_sessie.tas_positie_long%type
   ,i_positie_short            in  temp_ap_werkbest_sessie.tas_positie_short%type
   ,i_collateral_used          in  temp_ap_werkbest_sessie.tas_collateral_used%type
   ,i_wegingsfactor            in  temp_ap_werkbest_sessie.tas_wegingsfactor%type
   ,i_baisse_margin            in  temp_ap_werkbest_sessie.tas_baisse_margin%type
   ,i_rowid                    in  rowid
   ,i_controle_uitvoeren       in  number
   );
   
-- procedure lopende_orders_margin_wb_aanp:
   procedure lopende_orders_margin_wb_aanp
   (i_relatienummer            in  temp_ap_werkbest_sessie.tas_relatienr%type
   ,i_depot                    in  temp_ap_werkbest_sessie.tas_rekeningnr%type
   ,i_depotreksoort            in  temp_ap_werkbest_sessie.tas_rekening_soort%type
   ,i_refsymbool               in  temp_ap_werkbest_sessie.tas_ref_symbool%type
   ,i_symbool                  in  temp_ap_werkbest_sessie.tas_symbool%type
   ,i_optietype                in  temp_ap_werkbest_sessie.tas_optietype%type
   ,i_expiratiedatum           in  temp_ap_werkbest_sessie.tas_expiratiedatum%type
   ,i_exerciseprijs            in  temp_ap_werkbest_sessie.tas_exerciseprijs%type
   ,i_be_bi_nummer             in  temp_ap_werkbest_sessie.tas_bi_type%type
   ,i_margin_factor            in  temp_margin_wb_sessie.tms_marginfactor%type
   ,i_slot_koers_vorige_dag    in  temp_margin_wb_sessie.tms_slotkoers_voriged%type
   ,i_biedkoers                in  temp_margin_wb_sessie.tms_biedkoers%type
   ,i_laatkoers                in  temp_margin_wb_sessie.tms_laatkoers%type
   ,i_blocksize                in  temp_margin_wb_sessie.tms_blocksize%type
   ,i_valuta                   in  temp_margin_wb_sessie.tms_valuta%type
   ,i_pricing_unit             in  temp_margin_wb_sessie.tms_pricing_unit%type
   ,i_terminalnummer           in  werkbestand.wk_terminal%type
   ,i_order_aantal             in  kosten_werkbestand.kst_trans_aantal%type
   ,i_marginrequirment         in  temp_margin_wb_sessie.tms_margin_required%type
   ,i_aanpassen_runnummer      in  temp_ap_werkbest_sessie.tas_runnummer%type
   );

-- procedure lopende_orders_margin_wb_wijz:
   procedure lopende_orders_margin_wb_wijz
   (i_fondssymbool             in  temp_margin_wb_sessie.tms_symbool%type
   ,i_optietype                in  temp_margin_wb_sessie.tms_soort%type
   ,i_expiratiedatum           in  temp_margin_wb_sessie.tms_exp_datum%type
   ,i_exerciseprijs            in  temp_margin_wb_sessie.tms_exerciseprijs%type
   ,i_aanpassing_op_fonds_niet in  number
   ,i_extra_toevoeg_ivm_mandje in  number
   ,i_transactie_indicatie     in  kosten_werkbestand.kst_trans_indicatie%type
   ,i_is_comb_order            in  number
   );


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_MARGIN_EFFECT
-- In deze procedure wordt voor een lopende order het margin effect van die order op de portefeuille bepaalt.
-- Dit gebeurt in een aantal stappen:
-- 1. Vul temp_margin_wb_sessie en temp_ap_werkbest_sessie met de gegevens van de portefeuille (dat is uit dezelfde bestanden runnummer 8 of 9)
--    Dit hoeft alleen voor de fondsen met het referentiesymbool uit de order en moet 2 keer gedaan worden (runnummer 1 en 2)
-- 2. Voer met runnummer 1 een voor situatie uit (bereken dus de margin mbv de gegevens uit de werkbestanden met runnummer 1)
-- 3. Voer met runnummer 2 een na situatie uit. Pas hiervoor de mutatie uit de order toe op de gegevens uit de werkbestanden met runnummer
--    2 en bereken dan de margin met de gegevens uit de werkbestanden met runnummer 2)
-- 4. Het verschil tussen beide uitkomsten is het effect dat de order heeft op de margin.
-- 5. Verwerk de berekende gegevens in de werkbestanden met runnummer 9.
procedure lopende_orders_margin_effect
(i_ordernummer              in  orders.ord_ordernummer%type
,i_orderregel               in  orders.ord_orderregel%type
,i_orderdetailnr            in  ordersdetaillering.orx_detailnummer%type
,i_relatienr                in  clienten.cl_nummer%type
,i_slot_last_koers          in  tabelgegevens.tb_symbool%type
,i_terminalnummer           in  werkbestand.wk_terminal%type
,i_sys_toeslag_optiemarg    in  tabelgegevens.tb_waarde%type
,i_rel_toeslag_optiemarg    in  producten.pr_toeslag_percentage%type
,i_methode_naked_margin     in  number
,i_factor_naked_margin      in  number
,i_trekkingswaarde_aktief   in  number
,i_pr_blokkeren_short_call  in  producten.pr_blokkeren_short_calls%type
,i_pr_blokkeren_short_put   in  producten.pr_blokkeren_short_puts%type
,i_pr_blokkeren_long_put    in  producten.pr_blokkeren_long_puts%type
,i_instellingen             in  varchar2
,o_margin_effect            out kosten_werkbestand.kst_marginbedrag%type
)

/*------------------------------------------------------------------------------
Procedure   : lopende_orders_margin_effect
description : code voor een procedure waarbij het margin effect van een order
              wordt bepaalt.
author      : Syntel Financial Software, Jan Jans Wolthuis
code        : 5340-36068
history     : 03-MAR-2006, JJW, Initial creation.
              13-MAR-2006, JJW, toevoegen van uitgangs_runnummer + aanpassen code hiervoor
------------------------------------------------------------------------------*/

is
  -- rekenvariabelen
  v_voor_collateral             temp_margin_wb_sessie.tms_collateral_bedrag%type   := 0;
  v_voor_margin_opties          temp_margin_wb_sessie.tms_margin_required%type     := 0;
  v_voor_margin_futures         temp_margin_wb_sessie.tms_margin_required%type     := 0;
  v_voor_margin_totaal          temp_margin_wb_sessie.tms_margin_required%type     := 0;
  v_na_collateral               temp_margin_wb_sessie.tms_collateral_bedrag%type   := 0;
  v_na_margin_opties            temp_margin_wb_sessie.tms_margin_required%type     := 0;
  v_na_margin_futures           temp_margin_wb_sessie.tms_margin_required%type     := 0;
  v_na_margin_totaal            temp_margin_wb_sessie.tms_margin_required%type     := 0;
  -- ordervariabelen
  v_fondssymbool                kosten_werkbestand.kst_fondssymbool%type;
  v_optietype                   kosten_werkbestand.kst_optietype_fnds%type;
  v_expiratiedatum              kosten_werkbestand.kst_expiratiedat_fnds%type;
  v_exerciseprijs               kosten_werkbestand.kst_exercisepr_fnds%type;
  v_ow_is_mandje                number(1);
  v_referentiefonds             kosten_werkbestand.kst_ref_fondssymbool%type;
  v_ref_symbool_volgnummer      beleggingsinstrument.be_volgnummer%type;
  v_refreferentiefonds          beleggingsinstrument.be_referentiesymbool%type;
  v_be_bi_nummer                beleggingsinstrument.be_bi_nummer%type;
  v_prijs_factor_fonds          beleggingsinstrument.be_prijs_factor%type;
  v_ref_bi_nummer               beleggingsinstrument.be_bi_nummer%type;
  v_ref_marginfactor            beleggingsinstrument.be_margin_factor%type;
  v_order_aantal                kosten_werkbestand.kst_trans_aantal%type;
  v_werk_aantal                 kosten_werkbestand.kst_trans_aantal%type;
  v_prod_geblok_aantal          kosten_werkbestand.kst_trans_aantal%type           := 0;
  v_order_indicatie             kosten_werkbestand.kst_trans_indicatie%type;
  v_depot                       kosten_werkbestand.kst_depot%type;
  v_depot_reksoort              kosten_werkbestand.kst_depotreksrt%type;
  v_exerc_ass_factor            kosten_werkbestand.kst_fnds_ex_ass_fac%type;
  v_pricing_unit                temp_margin_wb_sessie.tms_pricing_unit%type;
  v_marginrequirement           kosten_werkbestand.kst_marginbedrag%type;
  v_slotkoers_vorige_dag        fn_quotes_vw.quot_bied%type;
  v_biedkoers                   fn_quotes_vw.quot_bied%type;
  v_laatkoers                   fn_quotes_vw.quot_laat%type;
  v_ref_biedkoers               fn_quotes_vw.quot_bied%type;
  v_ref_laatkoers               fn_quotes_vw.quot_laat%type;
  v_fonds_valuta                beleggingsinstrument.be_muntsoort%type;
  v_ref_fonds_valuta            beleggingsinstrument.be_muntsoort%type;
  -- Gegevens voor combinatie order
  v_fondssymbool_1              kosten_werkbestand.kst_fondssymbool%type;
  v_optietype_1                 kosten_werkbestand.kst_optietype_fnds%type;
  v_expiratiedatum_1            kosten_werkbestand.kst_expiratiedat_fnds%type;
  v_exerciseprijs_1             kosten_werkbestand.kst_exercisepr_fnds%type;
  v_referentiefonds_1           kosten_werkbestand.kst_ref_fondssymbool%type;
  v_refreferentiefonds_1        beleggingsinstrument.be_referentiesymbool%type;
  v_ref_symbool_volgnummer_1    beleggingsinstrument.be_volgnummer%type;
  v_be_bi_nummer_1              beleggingsinstrument.be_bi_nummer%type;
  v_prijs_factor_fonds_1        beleggingsinstrument.be_prijs_factor%type;
  v_ref_bi_nummer_1             beleggingsinstrument.be_bi_nummer%type;
  v_ref_marginfactor_1          beleggingsinstrument.be_margin_factor%type;
  v_ref_fondsomschr_1           beleggingsinstrument.be_oms_1%type;
  v_order_aantal_1              kosten_werkbestand.kst_trans_aantal%type;
  v_werk_aantal_1               kosten_werkbestand.kst_trans_aantal%type;
  v_order_indicatie_1           kosten_werkbestand.kst_trans_indicatie%type;
  v_order_indicatie_w_1         kosten_werkbestand.kst_trans_indicatie_w%type;
  v_depot_1                     kosten_werkbestand.kst_depot%type;
  v_depot_reksoort_1            kosten_werkbestand.kst_depotreksrt%type;
  v_exerc_ass_factor_1          kosten_werkbestand.kst_fnds_ex_ass_fac%type;
  v_pricing_unit_1              temp_margin_wb_sessie.tms_pricing_unit%type;
  v_marginrequirement_1         kosten_werkbestand.kst_marginbedrag%type;
  v_slotkoers_vorige_dag_1      fn_quotes_vw.quot_bied%type;
  v_biedkoers_1                 fn_quotes_vw.quot_bied%type;
  v_laatkoers_1                 fn_quotes_vw.quot_laat%type;
  v_ref_biedkoers_1             fn_quotes_vw.quot_bied%type;
  v_ref_laatkoers_1             fn_quotes_vw.quot_laat%type;
  v_fonds_valuta_1              beleggingsinstrument.be_muntsoort%type;
  v_ref_fonds_valuta_1          beleggingsinstrument.be_muntsoort%type;
  -- berekeningsvariabelen en overige variabelen
  v_runnummer                   temp_ap_werkbest_sessie.tas_runnummer%type;
  v_uitgangs_runnummer          temp_ap_werkbest_sessie.tas_runnummer%type;
  v_dummy_waarde                temp_margin_wb_sessie.tms_margin_required%type;
  v_extra_symbool               kosten_werkbestand.kst_fondssymbool%type;
  v_extra_symbool_1             kosten_werkbestand.kst_fondssymbool%type;
  v_aanpassing_op_fonds_niet    number(1)                                          := 0;
  v_extra_toevoeg_ivm_mandje    number(1)                                          := 0;
  -- In verband met valutakosten
  v_bank2mrktqchangedate        muntsoorten.mu_update%type;
  v_systspreadcodecategorie     valutaspread_cat_muntsoort.vscm_vsca_id%type;
  v_instelling                  varchar2(100);

begin
   -- gegevens van de relatie apart ophalen. NB als er gejoined wordt met het kosten_werkbestand kan de programmatuur
   -- erg traag worden omdat oracle geen statistieken van het kosten_werkbestand bijhoud
   select r.rf_margin,   r.rf_debug_j_n, r.rf_debug_user
   into   gv_rel_margin, gv_debuggen,    gv_debug_user
   from   relatie_fiattering r
   where  r.rf_relatie_nummer  = i_relatienr;
   
   select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, 'Bank2MrktQChangeDate', 'D', gv_debuggen, gv_debug_user)
   into   v_instelling
   from   dual;
   v_bank2mrktqchangedate := rtrim(ltrim(v_instelling));
    
   select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, 'SystSprdCodeCat', 'N', gv_debuggen, gv_debug_user)
   into   v_instelling
   from   dual;
   v_systspreadcodecategorie := to_number(rtrim(ltrim(v_instelling)));
   
   -- gegevens mbt de order ophalen
   select k.kst_fondssymbool,    k.kst_optietype_fnds,    k.kst_expiratiedat_fnds,
          k.kst_exercisepr_fnds, k.kst_ref_fondssymbool,  k.kst_trans_aantal,
          k.kst_trans_indicatie, k.kst_fnds_ex_ass_fac,   k.kst_prijs_factor_fnds,
          k.kst_bi_nummer,       k.kst_ref_fnds_bi_nr,    k.kst_depot,
          k.kst_depotreksrt
   into   v_fondssymbool,        v_optietype,             v_expiratiedatum,
          v_exerciseprijs,       v_referentiefonds,       v_order_aantal,
          v_order_indicatie,     v_exerc_ass_factor,      v_prijs_factor_fonds,
          v_be_bi_nummer,        v_ref_bi_nummer,         v_depot,
          v_depot_reksoort
   from   kosten_werkbestand k
   where  k.kst_ordernummer  = i_ordernummer
   and    k.kst_orderregel   = i_orderregel
   and    k.kst_detailnummer = i_orderdetailnr;

   select b.be_pricing_unit, b.be_muntsoort
   into   v_pricing_unit,      v_fonds_valuta
   from   beleggingsinstrument b
   where  b.be_symbool         = v_fondssymbool
   and    b.be_optietype       = v_optietype
   and    b.be_expiratiedatum  = v_expiratiedatum
   and    b.be_exerciseprijs   = v_exerciseprijs;

   select e.be_referentiesymbool, e.be_margin_factor, e.be_muntsoort,     e.be_volgnummer
   into   v_refreferentiefonds,   v_ref_marginfactor, v_ref_fonds_valuta, v_ref_symbool_volgnummer
   from   beleggingsinstrument e
   where  e.be_symbool         = v_referentiefonds
   and    e.be_optietype       = ' '
   and    e.be_expiratiedatum  = '00000000'
   and    e.be_exerciseprijs   = 0;

   -- bepalen of het referentiefonds een mandje is
   begin
      select 1
      into   v_ow_is_mandje
      from   mandje_onderliggende_waarde m
      where  m.mnd_volgnummer = v_ref_symbool_volgnummer
      and    rownum           <= 1;                        -- Het is voldoende om 1 record op te halen!
   exception
      when no_data_found
      then
         v_ow_is_mandje := 0;
   end;
   
   -- ophalen van koersen voor het fonds en het v_referentiefonds
   if v_ow_is_mandje = 1
   then
      FIAT_ALGEMEEN.fondskoersen(v_fondssymbool, v_optietype, v_expiratiedatum, v_exerciseprijs, i_slot_last_koers, v_biedkoers, v_laatkoers);
      FIAT_ALGEMEEN.fondskoers_meerdere_ow(v_ref_symbool_volgnummer, v_prijs_factor_fonds, 'S', gv_debuggen, gv_debug_user, v_ref_biedkoers, v_ref_laatkoers);
   else
      FIAT_ALGEMEEN.fondskoersen(v_fondssymbool, v_optietype, v_expiratiedatum, v_exerciseprijs, i_slot_last_koers, v_biedkoers, v_laatkoers);
      FIAT_ALGEMEEN.fondskoersen(v_referentiefonds, ' ', '00000000', 0, 'S', v_ref_biedkoers, v_ref_laatkoers);
   end if;
   v_slotkoers_vorige_dag := v_ref_laatkoers;

   -- Bepalen of er crossmargin kan optreden en vast leggen van het dan te gebruiken symbool
   if v_optietype in ('CALL','PUT')
   then
      begin
         select k.cm_future_symbool
         into   v_extra_symbool
         from   koppeltabel_cross_margin k
         where  k.cm_optie_symbool = v_fondssymbool;
      exception
         when no_data_found
         then
            v_extra_symbool := ' ';
      end;

   elsif v_optietype = 'FUT'
   then
      begin
         select k.cm_optie_symbool
         into   v_extra_symbool
         from   koppeltabel_cross_margin k
         where  k.cm_future_symbool = v_fondssymbool;
      exception
         when no_data_found
         then
            v_extra_symbool := ' ';
      end;
   elsif v_optietype = ' '
   then
      v_extra_symbool := ' ';
   end if;
   
   -- als het binnen komende regelnummer 2 is, dan betreft het een combinatieorder en moeten
   -- hier de gegevens voor het eerste leg worden bijgeselecteerd:
   if i_orderregel = 2
   then
      -- gegevens mbt de order ophalen
      select w.kst_fondssymbool,    w.kst_optietype_fnds,    w.kst_expiratiedat_fnds,
             w.kst_exercisepr_fnds, w.kst_ref_fondssymbool,  w.kst_trans_aantal,
             w.kst_trans_indicatie, w.kst_trans_indicatie_w, w.kst_fnds_ex_ass_fac,
             w.kst_bi_nummer,       w.kst_ref_fnds_bi_nr,    w.kst_depot,
             w.kst_depotreksrt
      into   v_fondssymbool_1,      v_optietype_1,           v_expiratiedatum_1,
             v_exerciseprijs_1,     v_referentiefonds_1,     v_order_aantal_1,
             v_order_indicatie_1,   v_order_indicatie_w_1,   v_exerc_ass_factor_1,
             v_be_bi_nummer_1,      v_ref_bi_nummer_1,       v_depot_1,
             v_depot_reksoort_1
      from   kosten_werkbestand w
      where  w.kst_ordernummer  = i_ordernummer
      and    w.kst_orderregel   = 1                          -- hier ophalen eerste leg!
      and    w.kst_detailnummer = i_orderdetailnr;

      select i.be_pricing_unit,     i.be_muntsoort,   i.be_prijs_factor
      into   v_pricing_unit_1,      v_fonds_valuta_1, v_prijs_factor_fonds_1
      from   beleggingsinstrument i
      where  i.be_symbool         = v_fondssymbool_1
      and    i.be_optietype       = v_optietype_1
      and    i.be_expiratiedatum  = v_expiratiedatum_1
      and    i.be_exerciseprijs   = v_exerciseprijs_1;

      select t.be_referentiesymbool, t.be_muntsoort,             t.be_margin_factor,   
             t.be_oms_1,             t.be_volgnummer            
      into   v_refreferentiefonds_1, v_ref_fonds_valuta_1,       v_ref_marginfactor_1, 
             v_ref_fondsomschr_1,    v_ref_symbool_volgnummer_1
      from   beleggingsinstrument t
      where  t.be_symbool         = v_referentiefonds_1
      and    t.be_optietype       = ' '
      and    t.be_expiratiedatum  = '00000000'
      and    t.be_exerciseprijs   = 0;
      
      -- eerst bepalen of er meerdere onderliggende waardes zijn
      begin
      select 1
      into   v_ow_is_mandje
      from   mandje_onderliggende_waarde m
      where  m.mnd_volgnummer  = v_ref_symbool_volgnummer_1
      and    rownum            <= 1 ;  -- maximaal 1 record ophalen !!!

      exception
      when no_data_found
      then
         v_ow_is_mandje := 0;
      end;

      -- ophalen van koersen voor het fonds en het referentiefonds
      if v_ow_is_mandje = 1
      then
         FIAT_ALGEMEEN.fondskoersen(v_fondssymbool_1, v_optietype_1, v_expiratiedatum_1, v_exerciseprijs_1, i_slot_last_koers, v_biedkoers_1, v_laatkoers_1);
         FIAT_ALGEMEEN.fondskoers_meerdere_ow(v_ref_symbool_volgnummer_1, v_prijs_factor_fonds_1, 'S', gv_debuggen, gv_debug_user, v_ref_biedkoers_1, v_ref_laatkoers_1);
      else
         FIAT_ALGEMEEN.fondskoersen(v_fondssymbool_1, v_optietype_1, v_expiratiedatum_1, v_exerciseprijs_1, i_slot_last_koers, v_biedkoers_1, v_laatkoers_1);
         FIAT_ALGEMEEN.fondskoersen(v_referentiefonds_1, ' ', '00000000', 0, 'S', v_ref_biedkoers_1, v_ref_laatkoers_1);
      end if;
      
      v_slotkoers_vorige_dag_1 := v_ref_laatkoers_1;

      -- Bepalen of er crossmargin kan optreden en vast leggen van het dan te gebruiken symbool
      if v_optietype_1 in ('CALL','PUT')
      then
         begin
            select k.cm_future_symbool
            into   v_extra_symbool_1
            from   koppeltabel_cross_margin k
            where  k.cm_optie_symbool = v_fondssymbool_1;
         exception
            when no_data_found
            then
               v_extra_symbool_1 := ' ';
         end;
         
      elsif v_optietype_1 = 'FUT'
      then
         begin
            select k.cm_optie_symbool
            into   v_extra_symbool_1
            from   koppeltabel_cross_margin k
            where  k.cm_future_symbool = v_fondssymbool_1;
         exception
            when no_data_found
            then
               v_extra_symbool_1 := ' ';
         end;
      elsif v_optietype = ' '
      then
         v_extra_symbool_1 := ' ';
      end if;
   end if;
   
   -- Eerst de gegevens met runnummer 1 en 2 verwijderen uit de twee werkbestanden:
   delete temp_margin_wb_sessie tm
   where  (tm.tms_runnnummer = 1
           or
           tm.tms_runnnummer = 2);

   delete temp_ap_werkbest_sessie ta
   where  (ta.tas_runnummer  = 1
           or
           ta.tas_runnummer = 2);

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In procedure FIAT_ORDER_MARGIN_EFFECT.lopende_orders_margin_effect)');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer  : '||to_char(i_ordernummer)||' ; orderregel : '||to_char(i_orderregel));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordersymbool : '||v_fondssymbool||' ; v_optietype : '||v_optietype);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'expdatum     : '||v_expiratiedatum||' ; v_exerciseprijs : '||to_char(v_exerciseprijs));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'orderaantal  : '||to_char(v_order_aantal)||' ; indicatie : '||v_order_indicatie);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margininstel : '||to_char(gv_rel_margin)||' ; extra symbool : '||v_extra_symbool);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'pr blok short call : '||to_char(i_pr_blokkeren_short_call)||' ; pr blok short put : '||to_char(i_pr_blokkeren_short_put));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'pr blok long put   : '||to_char(i_pr_blokkeren_long_put)||' ; ow is mandje : '||to_char(v_ow_is_mandje));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
      if i_orderregel = 2
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In gedeelte voor combinatie orders');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer comb  : '||to_char(i_ordernummer)||' ; orderregel comb : '||'1');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordersymbool comb : '||v_fondssymbool_1||' ; optietype comb : '||v_optietype_1);
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'expdatum comb     : '||v_expiratiedatum_1||' ; exerciseprijs comb : '||to_char(v_exerciseprijs_1));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'orderaantal comb  : '||to_char(v_order_aantal_1)||' ; indicatie comb : '||v_order_indicatie_1);
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
      end if;
   end if;

   -- de verschillende voorbereidingen voor het berekenen van het margineffect:
   -- Eerst de combinatie orders (i_orderregel = 2)
   if i_orderregel = 2
   then
      -- Gedeelte voor combinatieorders die doorrollen (1 sluiting en 1 openingskant). Deze orders worden
      -- zowel bij invoer als als lopende order in dit block behandeld. De wijziging wordt hierbij aan de positie
      -- toegevoegd (aan de nog niet aangepaste positie, uitgangs_runnummer 8).
      -- ook huidige orders (dus bij invoer) met 2 sluitingskopen worden in dit blok behandeld. Als de order lopend
      -- is wordt dit gedeelte overgeslagen....
      -- Voor futures wordt hier geen combinatie orders afgehandeld. (ze komen niet in deze procedure)
      -- In alle andere gevallen het tweede deel van dit statement voor orderregel = 2 uitvoeren:
      if ((substr(v_order_indicatie,1,1)='O' and substr(v_order_indicatie_1,1,1)= 'S')
          or
          (substr(v_order_indicatie,1,1)='S' and substr(v_order_indicatie_1,1,1)= 'O'))
           and
           v_optietype in ('CALL','PUT')
           and
           v_optietype_1 in ('CALL','PUT')
          or
          -- Voor het sluiten van short posities met twee sluitingskopen hier de uitzondering ook meenemen,
          -- (dus beide legs zijn van het type 'SK')
          (v_order_indicatie = 'SK' and v_order_indicatie_1 = 'SK'
           and v_optietype in ('CALL','PUT')
           and v_optietype_1 in ('CALL','PUT'))
          or
          -- Voor orders die een leg heeft met SK en een leg heeft met SV hier
          -- het positieve margin effect berekenen. (sluiten van (diagonal/time) spreads).
          ((v_order_indicatie = 'SK' and v_order_indicatie_1 = 'SV'
          or
          v_order_indicatie = 'SV' and v_order_indicatie_1 = 'SK')
          and v_optietype in ('CALL','PUT')
          and v_optietype_1 in ('CALL','PUT'))
      then
         v_uitgangs_runnummer := 8;
         -- vullen van de gegevens voor de combinatieorder:
         lopende_orders_margin_wb_vul (v_referentiefonds, 'R', v_uitgangs_runnummer, 0);
         -- als beide referentiefondsen van elkaar verschillen dan ook voor het tweede leg de gegevens vullen
         if v_referentiefonds <> v_referentiefonds_1
         then
            lopende_orders_margin_wb_vul (v_referentiefonds_1, 'R', v_uitgangs_runnummer, 0);
         end if;
         -- als het extra fonds gevuld is dan deze ook nog toevoegen:
         if v_extra_symbool <> ' '
         then
            lopende_orders_margin_wb_vul (v_extra_symbool, 'S', v_uitgangs_runnummer, 0);
            if v_extra_symbool <> v_extra_symbool_1 and v_extra_symbool_1 <> ' '
            then
               lopende_orders_margin_wb_vul (v_extra_symbool_1, 'S', v_uitgangs_runnummer, 0);
            end if;
         end if;
         -- Op dit moment is de positie toegevoegd aan de werkbestanden en als uitgangspunt beschikbaar...
         -- De volgende aanpassingen moeten worden gedaan in runnummer 2:
         -- SK          --> positie aanpassen en margin requirment verminderen voor dit order aantal
         -- SV, OK      --> alleen de positie aanpassen
         -- OV          --> positie aanpassen en de margin requirement verhogen voor dit order aantal
         
         -- tweede leg (de gegevens zonder _1):
         if v_order_indicatie in ('SK','OV')
         then
            -- in eerste instantie de margin requirment berekenen:
            FIAT_ORDER_MARGIN.lopende_orders_margin(i_ordernummer, i_orderregel, i_orderdetailnr, i_terminalnummer,
                                                    i_slot_last_koers, i_sys_toeslag_optiemarg, i_rel_toeslag_optiemarg,
                                                    i_methode_naked_margin, i_factor_naked_margin, 0,
                                                    v_prod_geblok_aantal, i_pr_blokkeren_short_call,
                                                    i_pr_blokkeren_short_put, i_pr_blokkeren_long_put, 1, i_instellingen, v_marginrequirement);
            -- voor SK betreft het een afname van de marginrequirement, dus hier maal -1:
            if v_order_indicatie = 'SK'
            then
               v_marginrequirement := -1 * v_marginrequirement;
            end if;
            -- bij de SK wordt een short positie afgebouwd dus het werkaantal moet positief zijn:
            -- voor OV wordt juist een short positie in genomen en moet het werkaantal negatief zijn:
            v_werk_aantal := v_order_aantal;
            if v_order_indicatie ='OV'
            then
               v_werk_aantal := -1 * v_werk_aantal;
            end if;
            -- met behulp van deze berekende gegevens kan de positie worden aangepast:
            lopende_orders_margin_wb_aanp(i_relatienr, v_depot, v_depot_reksoort, v_referentiefonds, v_fondssymbool, v_optietype,
                                          v_expiratiedatum, v_exerciseprijs, v_be_bi_nummer, v_ref_marginfactor, 
                                          v_slotkoers_vorige_dag, v_biedkoers, v_laatkoers, v_exerc_ass_factor, v_fonds_valuta, 
                                          v_pricing_unit, i_terminalnummer, v_werk_aantal, v_marginrequirement, 2);
                                           
         elsif v_order_indicatie in ('SV','OK')
         then
            -- voor deze transactiesoorten hoeft geen marginrequirment berekend te worden en kan dus op 0 worden gesteld:
            v_marginrequirement := 0;
            
            -- voor een SV wordt het aantal van de positie afgetrokken, hier dus negatief maken:
            v_werk_aantal := v_order_aantal;
            if v_order_indicatie = 'SV'
            then
               v_werk_aantal := -1 * v_werk_aantal;
            end if;
            -- met behulp van deze berekende gegevens kan de positie worden aangepast:
            lopende_orders_margin_wb_aanp (i_relatienr, v_depot, v_depot_reksoort, v_referentiefonds, v_fondssymbool, v_optietype,
                                           v_expiratiedatum, v_exerciseprijs, v_be_bi_nummer, v_ref_marginfactor,
                                           v_slotkoers_vorige_dag, v_biedkoers, v_laatkoers, v_exerc_ass_factor, v_fonds_valuta,
                                           v_pricing_unit, i_terminalnummer, v_werk_aantal, v_marginrequirement, 2);
         end if;
         
         -- eerste leg (de gegevens met _1):
         if v_order_indicatie_1 in ('SK','OV')
         then
            -- in eerste instantie de margin requirment berekenen:
            FIAT_ORDER_MARGIN.lopende_orders_margin(i_ordernummer, 1, i_orderdetailnr, i_terminalnummer,
                                                    i_slot_last_koers, i_sys_toeslag_optiemarg, i_rel_toeslag_optiemarg,
                                                    i_methode_naked_margin, i_factor_naked_margin, 0,
                                                    v_prod_geblok_aantal, i_pr_blokkeren_short_call,
                                                    i_pr_blokkeren_short_put, i_pr_blokkeren_long_put, 1, i_instellingen, v_marginrequirement_1);
                                                     
            -- voor SK betreft het een afname van de marginrequirement, dus hier maal -1:
            if v_order_indicatie_1 = 'SK'
            then
               v_marginrequirement_1 := -1 * v_marginrequirement_1;
            end if;
            -- bij de SK wordt een short positie afgebouwd dus het werkaantal moet positief zijn:
            -- voor OV wordt juist een short positie in genomen en moet het werkaantal negatief zijn:
            v_werk_aantal_1 := v_order_aantal_1;
            if v_order_indicatie_1 ='OV'
            then
               v_werk_aantal_1 := -1 * v_werk_aantal_1;
            end if;
            -- met behulp van deze berekende gegevens kan de positie worden aangepast:
            lopende_orders_margin_wb_aanp (i_relatienr, v_depot_1, v_depot_reksoort_1, v_referentiefonds_1, v_fondssymbool_1, 
                                           v_optietype_1, v_expiratiedatum_1, v_exerciseprijs_1, v_be_bi_nummer_1, 
                                           v_ref_marginfactor_1, v_slotkoers_vorige_dag_1, v_biedkoers_1, v_laatkoers_1, 
                                           v_exerc_ass_factor_1, v_fonds_valuta_1, v_pricing_unit_1, i_terminalnummer, 
                                           v_werk_aantal_1, v_marginrequirement_1, 2);
                                           
                                           
         elsif v_order_indicatie_1 in ('SV','OK')
         then
            -- voor deze transactiesoorten hoeft geen marginrequirment berekend te worden en kan dus op 0 worden gesteld:
            v_marginrequirement_1 := 0;
            
            -- voor een SV wordt het aantal van de positie afgetrokken, hier dus negatief maken:
            v_werk_aantal_1 := v_order_aantal_1;
            if v_order_indicatie_1 = 'SV'
            then
               v_werk_aantal_1 := -1 * v_werk_aantal_1;
            end if;
            -- met behulp van deze berekende gegevens kan de positie worden aangepast:
            lopende_orders_margin_wb_aanp (i_relatienr, v_depot_1, v_depot_reksoort_1, v_referentiefonds_1, v_fondssymbool_1, 
                                           v_optietype_1, v_expiratiedatum_1, v_exerciseprijs_1, v_be_bi_nummer_1, 
                                           v_ref_marginfactor_1, v_slotkoers_vorige_dag_1, v_biedkoers_1, v_laatkoers_1, 
                                           v_exerc_ass_factor_1, v_fonds_valuta_1, v_pricing_unit_1, i_terminalnummer, 
                                           v_werk_aantal_1, v_marginrequirement_1, 2);                                           
                                           
         end if;
      -- bestaande lopende combi orders en huidige combi orders zonder sluitingstransacties in dit blok verwerken:
      else
         v_uitgangs_runnummer := 0;
         -- sluitings transacties zijn niet toe te voegen aan het werkbestand.
         -- eerst de gegevens die wel zijn toe te voegen voor leg 2 (de binnengekomen gegevens):
         if v_order_indicatie in ('OV','OK','OV F','OK F')
         then
            v_marginrequirement := 0;
            -- berekenen van de initial margin voor OV of OV F en OK F transacties
            if v_order_indicatie = 'OV'
            then
               FIAT_ORDER_MARGIN.lopende_orders_margin (i_ordernummer, i_orderregel, i_orderdetailnr, i_terminalnummer,
                                                        i_slot_last_koers, i_sys_toeslag_optiemarg, i_rel_toeslag_optiemarg,
                                                        i_methode_naked_margin, i_factor_naked_margin, 0,
                                                        v_prod_geblok_aantal, i_pr_blokkeren_short_call,
                                                        i_pr_blokkeren_short_put, i_pr_blokkeren_long_put, 1, i_instellingen, v_marginrequirement);
                                                        
            elsif v_order_indicatie in ('OV F','OK F')
            then
               FIAT_ORDER_MARGIN.lopende_orders_waarborg (i_ordernummer, i_orderregel, i_orderdetailnr, 
                                                          v_bank2mrktqchangedate, v_systspreadcodecategorie, 1, v_marginrequirement);
            end if;
            -- bepalen van het aantal en de richting van het aantal:
            if v_order_indicatie in ('OK','OK F')
            then
               v_werk_aantal := v_order_aantal;
            else
               v_werk_aantal := -1 * v_order_aantal;
            end if;
            -- de gegevens in de margin werkbestanden plaatsen
            lopende_orders_margin_wb_aanp (i_relatienr, v_depot, v_depot_reksoort, v_referentiefonds, v_fondssymbool, v_optietype,
                                           v_expiratiedatum, v_exerciseprijs, v_be_bi_nummer, v_ref_marginfactor,
                                           v_slotkoers_vorige_dag, v_biedkoers, v_laatkoers, v_exerc_ass_factor, v_fonds_valuta,
                                           v_pricing_unit, i_terminalnummer, v_werk_aantal, v_marginrequirement, 2);
         end if;
         -- aansluitend de gegevens die wel zijn toe te voegen voor leg 1 (de _1 gegevens):
         if v_order_indicatie_1 in ('OV','OK','OV F','OK F')
         then
            v_marginrequirement_1 := 0;
            -- berekenen van de initial margin voor OV of OV F en OK F transacties
            if v_order_indicatie_1 = 'OV'
            then
               FIAT_ORDER_MARGIN.lopende_orders_margin (i_ordernummer, 1, i_orderdetailnr, i_terminalnummer,
                                                        i_slot_last_koers, i_sys_toeslag_optiemarg, i_rel_toeslag_optiemarg,
                                                        i_methode_naked_margin, i_factor_naked_margin, 0,
                                                        v_prod_geblok_aantal, i_pr_blokkeren_short_call,
                                                        i_pr_blokkeren_short_put, i_pr_blokkeren_long_put, 1, i_instellingen, v_marginrequirement_1);
            elsif v_order_indicatie_1 in ('OV F','OK F')
            then
               FIAT_ORDER_MARGIN.lopende_orders_waarborg (i_ordernummer, 1, i_orderdetailnr,  
                                                          v_bank2mrktqchangedate, v_systspreadcodecategorie, 1, v_marginrequirement_1);
            end if;
            -- bepalen van het aantal en de richting van het aantal:
            if v_order_indicatie_1 in ('OK','OK F')
            then
               v_werk_aantal_1 := v_order_aantal_1;
            else
               v_werk_aantal_1 := -1 * v_order_aantal_1;
            end if;
            -- de gegevens in de margin werkbestanden plaatsen
            lopende_orders_margin_wb_aanp (i_relatienr, v_depot_1, v_depot_reksoort_1, v_referentiefonds_1, v_fondssymbool_1, 
                                           v_optietype_1, v_expiratiedatum_1, v_exerciseprijs_1, v_be_bi_nummer_1, 
                                           v_ref_marginfactor_1, v_slotkoers_vorige_dag_1, v_biedkoers_1, v_laatkoers_1, 
                                           v_exerc_ass_factor_1, v_fonds_valuta_1, v_pricing_unit_1, i_terminalnummer, 
                                           v_werk_aantal_1, v_marginrequirement_1, 2);
         end if;
      end if;
      
   -- het betreft een enkelvoudige order
   else
      -- Zijn er blokkades voor demarginverplichting afgegeven:
      if ((i_pr_blokkeren_short_call = 1 and v_optietype = 'CALL' and v_order_indicatie ='OV')
         or
         (i_pr_blokkeren_short_put = 1 and v_optietype = 'PUT' and v_order_indicatie = 'OV'))
      then
         v_prod_geblok_aantal := 0;
         
         if v_optietype = 'CALL'
         then
            FIAT_ORDER_MARGIN.lopende_orders_geblok_w (v_referentiefonds, v_prijs_factor_fonds, v_order_aantal,
                                                       i_terminalnummer, gv_debuggen, gv_debug_user, v_prod_geblok_aantal);
                                                       
            v_order_aantal := v_order_aantal - v_prod_geblok_aantal;
         
         elsif v_optietype = 'PUT'
         then
            FIAT_ORDER_MARGIN.lopende_orders_geblok_w (v_fonds_valuta, (v_prijs_factor_fonds * v_exerciseprijs), v_order_aantal,
                                                       i_terminalnummer, gv_debuggen, gv_debug_user, v_prod_geblok_aantal);
                                                       
            v_order_aantal := v_order_aantal - v_prod_geblok_aantal;
            
         end if;
      end if;
      
      -- alleen verder gaan als er nog een order aantal over is
      if v_order_aantal <= 0
      then
         o_margin_effect := 0;
      -- er is nog een deel over:
      else
         -- Voor het vullen van de werkbestanden zijn er twee uitgangsmogelijkheden:
         -- runnummer 8: Dit is de niet aangepaste uitgangsset
         -- runnummer 9: Dit is de uitgangsset die per order wordt aangepast na het berekenen van het margineffect.
         if v_order_indicatie in ('SV','SV F','EX P')
         then
            v_uitgangs_runnummer := 8;
         else
            v_uitgangs_runnummer := 9;
         end if;
         
         -- Vullen van de werkbestanden in een andere procedure
         lopende_orders_margin_wb_vul (v_referentiefonds, 'R',v_uitgangs_runnummer, 0);
         -- Extra acties met betrekking tot mandjes (altijd uitvoeren: referentiefonds kan ook onderdeel van een mandje zijn):
         lopende_ord_marg_mandje_wb_vul (v_ref_symbool_volgnummer, v_ow_is_mandje, v_uitgangs_runnummer, v_extra_toevoeg_ivm_mandje);
         
         -- Als er crossmargin optreedt dan is het extra fondssymbool gevult, anders niet
         if v_extra_symbool <> ' '
         then
            lopende_orders_margin_wb_vul (v_extra_symbool, 'S',v_uitgangs_runnummer, 0);
         end if;
         
         -- op dit moment zijn de werkbestanden gevuld. Nu de order verwerken in de gegevens van runnummer 2
         -- De volgende situaties treden hierbij op:
         -- V, VN en EX P voor de stukken kant --> alleen de positie aanpassen
         -- OV                                 --> positie aanpassen en de margin requirement ophogen voor dit order aantal
         -- SV, EX C, EX P voor de optie kant  --> alleen de positie aanpassen
         -- SK                                 --> positie aanpassen en margin requirement verminderen voor dit order aantal
         
         -- Voor OV en SK moet eerst de v_marginrequirement bepaalt worden
         if v_order_indicatie in ('OV','SK')
         then
            FIAT_ORDER_MARGIN.lopende_orders_margin(i_ordernummer, i_orderregel, i_orderdetailnr, i_terminalnummer,
                                                    i_slot_last_koers, i_sys_toeslag_optiemarg, i_rel_toeslag_optiemarg,
                                                    i_methode_naked_margin, i_factor_naked_margin, 0,
                                                    v_prod_geblok_aantal, i_pr_blokkeren_short_call,
                                                    i_pr_blokkeren_short_put, i_pr_blokkeren_long_put, 0, i_instellingen, v_marginrequirement);
            -- voor OV geldt dit als een vermeerdering dus als + meenemen. Voor SK geldt dit als een vermindering dus - meenemen!
            if  v_order_indicatie = 'SK'
            then
               v_marginrequirement := -1 * v_marginrequirement;
            end if;
            
            if gv_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'weer in procedure lopende_orders_margin_effect');
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin reequirement voor de order : '||to_char(v_marginrequirement));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
            end if;
            
         else
            v_marginrequirement := 0;
         end if;
         
         -- Nu de wijzigingen doorgeven aan de werkbestanden voor verwerking in runnummer 2
         if v_order_indicatie in ('V','VN','EX P')
         then
            v_werk_aantal   := -1 * v_order_aantal;
            if v_order_indicatie = 'EX P'
            then
               v_werk_aantal := v_werk_aantal * v_exerc_ass_factor;
            end if;
            -- aanpassen van de gegevens
            -- als het een V betreft dan de gegevens uit de order en van het oderfonds .....
            if v_order_indicatie in ('V','VN')
            then
               lopende_orders_margin_wb_aanp(i_relatienr, v_depot, v_depot_reksoort, v_referentiefonds, v_fondssymbool, v_optietype,
                                             v_expiratiedatum, v_exerciseprijs, v_be_bi_nummer, v_ref_marginfactor, 0, 0, 0,
                                             v_exerc_ass_factor, v_fonds_valuta, v_pricing_unit, i_terminalnummer, v_werk_aantal,
                                             v_marginrequirement, 2);
               -- De order moet worden doorgevoerd in de werkbestandgegevens van runnummer 9
               v_aanpassing_op_fonds_niet := 0;
               -- als het een EX P betreft dan de gegevens van het referentiesymbool .....
            elsif v_order_indicatie = 'EX P'
            then
               lopende_orders_margin_wb_aanp(i_relatienr, v_depot, v_depot_reksoort, v_refreferentiefonds, v_referentiefonds, ' ',
                                             '00000000', 0, v_ref_bi_nummer, v_ref_marginfactor, 0, 0, 0,
                                             v_exerc_ass_factor, v_ref_fonds_valuta, v_pricing_unit, i_terminalnummer, v_werk_aantal,
                                             v_marginrequirement, 2);
            end if;
         end if;
         
         if v_order_indicatie = 'OV'
         then
            v_werk_aantal := -1 * v_order_aantal;
            lopende_orders_margin_wb_aanp(i_relatienr, v_depot, v_depot_reksoort, v_referentiefonds, v_fondssymbool, v_optietype,
                                          v_expiratiedatum, v_exerciseprijs, v_be_bi_nummer, v_ref_marginfactor, v_slotkoers_vorige_dag,
                                          v_biedkoers, v_laatkoers, v_exerc_ass_factor, v_fonds_valuta, v_pricing_unit, i_terminalnummer,
                                          v_werk_aantal, v_marginrequirement, 2);
            -- De order moet niet worden doorgevoerd in de werkbestandgegevens van runnummer 9
            v_aanpassing_op_fonds_niet := 1;
         end if;
         
         if v_order_indicatie in ('SV','EX C','EX P', 'SV F')
         then
            v_werk_aantal := -1 * v_order_aantal;
            lopende_orders_margin_wb_aanp(i_relatienr, v_depot, v_depot_reksoort, v_referentiefonds, v_fondssymbool, v_optietype,
                                          v_expiratiedatum, v_exerciseprijs, v_be_bi_nummer, v_ref_marginfactor, v_slotkoers_vorige_dag,
                                          v_biedkoers, v_laatkoers, v_exerc_ass_factor, v_fonds_valuta, v_pricing_unit, i_terminalnummer,
                                          v_werk_aantal, v_marginrequirement, 2);
            -- De order moet worden doorgevoerd in de werkbestandgegevens van runnummer 9
            v_aanpassing_op_fonds_niet := 0;
         end if;
         
         if v_order_indicatie in ('SK','SK F')
         then
            v_werk_aantal := v_order_aantal;
            lopende_orders_margin_wb_aanp(i_relatienr, v_depot, v_depot_reksoort, v_referentiefonds, v_fondssymbool, v_optietype,
                                          v_expiratiedatum, v_exerciseprijs, v_be_bi_nummer, v_ref_marginfactor, v_slotkoers_vorige_dag,
                                          v_biedkoers, v_laatkoers, v_exerc_ass_factor, v_fonds_valuta, v_pricing_unit, i_terminalnummer,
                                          v_werk_aantal, v_marginrequirement, 2);
            -- De order moet worden doorgevoerd in de werkbestandgegevens van runnummer 9
            v_aanpassing_op_fonds_niet := 0;
         end if;
      end if; -- v_order_aantal <> 0
   end if;  -- einde alleen voor enkelvoudige orders
   
   -- Op dit moment zijn de beide runnummers gevuld en kunnen ze één voor één worden aangeboden voor de marginberekening
   v_runnummer := 1;
   FIAT_MARGIN.ma_start_margin_bereken(i_relatienr, gv_rel_margin, i_rel_toeslag_optiemarg, i_terminalnummer, i_slot_last_koers,
                                       i_trekkingswaarde_aktief, 0, 0, v_runnummer, i_pr_blokkeren_short_call,
                                       i_pr_blokkeren_short_put, i_pr_blokkeren_long_put, i_instellingen, v_dummy_waarde, v_voor_collateral,
                                       v_voor_margin_opties, v_voor_margin_futures, v_voor_margin_totaal, v_dummy_waarde);
                                       
   v_runnummer := 2;
   FIAT_MARGIN.ma_start_margin_bereken(i_relatienr, gv_rel_margin, i_rel_toeslag_optiemarg, i_terminalnummer, i_slot_last_koers,
                                       i_trekkingswaarde_aktief, 0, 0, v_runnummer, i_pr_blokkeren_short_call,
                                       i_pr_blokkeren_short_put, i_pr_blokkeren_long_put, i_instellingen, v_dummy_waarde, v_na_collateral,
                                       v_na_margin_opties, v_na_margin_futures, v_na_margin_totaal, v_dummy_waarde);
                                       
   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'weer terug in procedure lopende_orders_margin_effect na runnummer 1 en 2');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'collateral voor    : '||to_char(v_voor_collateral)||' ; margin opties voor : '||to_char(v_voor_margin_opties));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'future margin voor : '||to_char(v_voor_margin_futures)||' ; margin totaal voor : '||to_char(v_voor_margin_totaal));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'collateral na      : '||to_char(v_na_collateral)||' ; margin opties na : '||to_char(v_na_margin_opties));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'future margin na   : '||to_char(v_na_margin_futures)||' ; margin totaal na : '||to_char(v_na_margin_totaal));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
   end if;
   
   -- het verschil tussen beide totaal margin bedragen is het effect van de order op de margin:
   o_margin_effect := v_voor_margin_totaal - v_na_margin_totaal;
   -- het bedrag op 0 stellen als het uitvoeren van de order positief uitvalt voor de marginverplichting;
   -- dus als het margin effect groter als 0 is.
   -- echter dit geldt niet voor:
   -- SK, SV, SK F en SV F, K en KN onderhanden zijnde enkelvoudige orders (--> ordernummer = -1)
   -- combinatie orders
   if o_margin_effect > 0
      and
      not(v_order_indicatie in ('SK','SV','SK F','SV F','K','KN','OK','EMIS') and i_ordernummer = -1 and i_orderregel = 1)
      and
      not(i_orderregel = 2)
   then
      o_margin_effect := 0;
   end if;
   
   -- Als laatste nog de gegevens uit het werkbestand aanpassen zodat bij de volgende
   -- marginruns voor lopende orders hier rekening mee gehouden kan worden
   if v_uitgangs_runnummer = 9
   then
      lopende_orders_margin_wb_wijz (v_fondssymbool, v_optietype, v_expiratiedatum, v_exerciseprijs, v_aanpassing_op_fonds_niet, v_extra_toevoeg_ivm_mandje,
                                     v_order_indicatie, case when i_orderregel = 2 then 1 else 0 end );
   elsif v_uitgangs_runnummer = 8
   then
      if v_order_indicatie in ('V','VN')
      then
         v_werk_aantal   := -1 * v_order_aantal;
         lopende_orders_margin_wb_aanp(i_relatienr, v_depot, v_depot_reksoort, v_referentiefonds, v_fondssymbool, v_optietype,
                                       v_expiratiedatum, v_exerciseprijs, v_be_bi_nummer, v_ref_marginfactor, 0, 0, 0,
                                       v_exerc_ass_factor, v_fonds_valuta, v_pricing_unit, i_terminalnummer, v_werk_aantal,
                                       0, 9);
      elsif v_order_indicatie = 'EX P'
      then
         -- referentiesymbool bij EX P
         v_werk_aantal := -1 * v_order_aantal * v_exerc_ass_factor;
         lopende_orders_margin_wb_aanp(i_relatienr, v_depot, v_depot_reksoort, v_refreferentiefonds, v_referentiefonds, ' ',
                                       '00000000', 0, v_ref_bi_nummer, v_ref_marginfactor, 0, 0, 0,
                                       v_exerc_ass_factor, v_ref_fonds_valuta, v_pricing_unit, i_terminalnummer, v_werk_aantal,
                                       0, 9);
         -- optie bij EX P
         v_werk_aantal := -1 * v_order_aantal;
         lopende_orders_margin_wb_aanp(i_relatienr, v_depot, v_depot_reksoort, v_referentiefonds, v_fondssymbool, v_optietype,
                                       v_expiratiedatum, v_exerciseprijs, v_be_bi_nummer, v_ref_marginfactor, v_slotkoers_vorige_dag,
                                       v_biedkoers, v_laatkoers, v_exerc_ass_factor, v_fonds_valuta, v_pricing_unit, i_terminalnummer,
                                       v_werk_aantal, v_marginrequirement, 9);
      else
         v_werk_aantal := -1 * v_order_aantal;
         lopende_orders_margin_wb_aanp(i_relatienr, v_depot, v_depot_reksoort, v_referentiefonds, v_fondssymbool, v_optietype,
                                       v_expiratiedatum, v_exerciseprijs, v_be_bi_nummer, v_ref_marginfactor, v_slotkoers_vorige_dag,
                                       v_biedkoers, v_laatkoers, v_exerc_ass_factor, v_fonds_valuta, v_pricing_unit, i_terminalnummer,
                                       v_werk_aantal, v_marginrequirement, 9);
      end if;
   end if;
   
end lopende_orders_margin_effect;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_MARGIN_EFFECT


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_MARGIN_WB_VUL
-- In deze procedure worden de gegevens uit de margin werkbestanden gekopieerd naar een set met runnummer 1 en 2.
procedure lopende_orders_margin_wb_vul
(i_fondssymbool             in  kosten_werkbestand.kst_fondssymbool%type
,i_ref_of_fondssymbool      in  varchar2
,i_uitgangs_runnummer       in  temp_ap_werkbest_sessie.tas_runnummer%type
,i_controle_uitvoeren       in  number
)

/*------------------------------------------------------------------------------
Procedure   : lopende_orders_margin_wb_vul
description : code voor een procedure waarbij de gegevens uit de marginwerkbestanden
              worden gekopieerd naar een set met runnummer 1 en 2.
author      : Syntel Financial Software, Jan Jans Wolthuis
code        : 5340-36068
history     : 03-MAR-2006, JJW Initial creation.
	          : 13-MAR-2006, JJW toevoeging van i_uitgangs_runnummer + verwerking in code
------------------------------------------------------------------------------*/


-- Inkomende parameters zijn: i_fondssymbool        = Het (Ref)Symbool waarvan de gegevens moeten worden gekopieerd
--                            i_ref_of_fondssymbool = R of S. Als een R wordt meegestuurd moet door het Refsymbool worden
--                                                    gelopen. Als een S wordt meegestuurd door het (fonds)Symbool.
--                            i_uitgangs_runnummer  = Het runnummer waarvan het subset moet worden gekopieerd.
--                            i_controle_uitvoeren  = Geeft aan of doorgegeven moet worden dat voor toevoegen eerst
--                                                    gecontroleerd moet worden of het record bestaat of niet                             

is

  v_runnummer                 temp_ap_werkbest_sessie.tas_runnummer%type;
  v_omschr_ref_sym            varchar2(20);

begin
  if i_ref_of_fondssymbool = 'R'
  then
     v_omschr_ref_sym      := 'Referentiesymbool';
  elsif i_ref_of_fondssymbool = 'S'
  then
     v_omschr_ref_sym      := 'Fondssymbool';
  else
     v_omschr_ref_sym      := 'Foutieve code';
  end if;
  
  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure FIAT_ORDER_MARGIN_EFFECT.lopende_orders_margin_wb_vul');
  end if;

  -- Hieronder twee loops om de gegevens te kopieren (hiervoor door de gegevens met i_uitgangs_runnummer gaan):
  -- Hier door het temp_margin_wb_sessie werkbestand heen
  declare
     cursor mw is
        select m.tms_relatienr,          m.tms_runnnummer,            m.tms_productnummer,
               m.tms_product_volgnummer, m.tms_rekeningsoort,         m.tms_rekeningnr,
               m.tms_rekening_munts,     m.tms_refsymbool,            m.tms_soort,
               m.tms_symbool,            m.tms_exp_datum,             m.tms_exerciseprijs,
               m.tms_saldo_positie,      m.tms_positie_future,        m.tms_marginfactor,
               m.tms_slotkoers_voriged,  m.tms_biedkoers,             m.tms_laatkoers,
               m.tms_blocksize,          m.tms_margin_required,       m.tms_gecovered,
               m.tms_spread_aantal,      m.tms_spread_bedrag,         m.tms_straddle_aantal,
               m.tms_straddle_bedrag,    m.tms_valuta,                m.tms_collateral_bedrag,
               m.tms_pricing_unit,       m.tms_cross_aantal,          m.tms_cross_bedrag,
               m.tms_gecovered_comp,     m.tms_gecovered_comp_bedrag, m.rowid
        from   temp_margin_wb_sessie m
        where  m.tms_runnnummer      = i_uitgangs_runnummer
        and   (m.tms_refsymbool      = i_fondssymbool 
               and
               i_ref_of_fondssymbool = 'R'
               or
               m.tms_symbool         = i_fondssymbool
               and
               i_ref_of_fondssymbool = 'S'
              );
              
  begin
     for r_mw in mw
     loop
     
        if gv_debuggen = 1
        then
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'vullen temp margin werkbestand (procedure lopende_orders_margin_wb_vul) mbv '||v_omschr_ref_sym);
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'symbool           : '||r_mw.tms_symbool||' ; optietype : '||r_mw.tms_soort);
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'expdat            : '||r_mw.tms_exp_datum||' ;  exerciseprijs : '||to_char(r_mw.tms_exerciseprijs));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'refsymbool        : '||r_mw.tms_refsymbool||' ; marginrequired : '||to_char(r_mw.tms_margin_required));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo pos         : '||to_char(r_mw.tms_saldo_positie)||' ; positie future : '||to_char(r_mw.tms_positie_future));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'spread aantal     : '||to_char(r_mw.tms_spread_aantal)||' ; straddle_aantal : '||to_char(r_mw.tms_straddle_aantal));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'collateral bedrag : '||to_char(r_mw.tms_collateral_bedrag)||' ; cross aantal : '||to_char(r_mw.tms_cross_aantal));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'gecovered         : '||to_char(r_mw.tms_gecovered));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'runnummer         : '||to_char(r_mw.tms_runnnummer)||' ; row id : '||r_mw.rowid);
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
        end if;
        
        -- ieder record twee keer wegschrijven: één maal met runnummer 1 en één maal met runnummer 2
        -- eerst runnummer 1
        v_runnummer := 1;
           
        lopende_orders_margin_vul_mw (r_mw.tms_relatienr,          v_runnummer,                    r_mw.tms_productnummer,
                                      r_mw.tms_product_volgnummer, r_mw.tms_rekeningsoort,         r_mw.tms_rekeningnr,
                                      r_mw.tms_rekening_munts,     r_mw.tms_refsymbool,            r_mw.tms_soort,
                                      r_mw.tms_symbool,            r_mw.tms_exp_datum,             r_mw.tms_exerciseprijs,
                                      r_mw.tms_saldo_positie,      r_mw.tms_positie_future,        r_mw.tms_marginfactor,
                                      r_mw.tms_slotkoers_voriged,  r_mw.tms_biedkoers,             r_mw.tms_laatkoers,
                                      r_mw.tms_blocksize,          r_mw.tms_margin_required,       r_mw.tms_gecovered,
                                      r_mw.tms_spread_aantal,      r_mw.tms_spread_bedrag,         r_mw.tms_straddle_aantal,
                                      r_mw.tms_straddle_bedrag,    r_mw.tms_valuta,                r_mw.tms_collateral_bedrag,
                                      r_mw.tms_pricing_unit,       r_mw.tms_cross_aantal,          r_mw.tms_cross_bedrag,
                                      r_mw.tms_gecovered_comp,     r_mw.tms_gecovered_comp_bedrag, null,
                                      i_controle_uitvoeren);
                                      
        -- nu runnummer 2
        v_runnummer := 2;
        
        lopende_orders_margin_vul_mw (r_mw.tms_relatienr,          v_runnummer,                    r_mw.tms_productnummer,
                                      r_mw.tms_product_volgnummer, r_mw.tms_rekeningsoort,         r_mw.tms_rekeningnr,
                                      r_mw.tms_rekening_munts,     r_mw.tms_refsymbool,            r_mw.tms_soort,
                                      r_mw.tms_symbool,            r_mw.tms_exp_datum,             r_mw.tms_exerciseprijs,
                                      r_mw.tms_saldo_positie,      r_mw.tms_positie_future,        r_mw.tms_marginfactor,
                                      r_mw.tms_slotkoers_voriged,  r_mw.tms_biedkoers,             r_mw.tms_laatkoers,
                                      r_mw.tms_blocksize,          r_mw.tms_margin_required,       r_mw.tms_gecovered,
                                      r_mw.tms_spread_aantal,      r_mw.tms_spread_bedrag,         r_mw.tms_straddle_aantal,
                                      r_mw.tms_straddle_bedrag,    r_mw.tms_valuta,                r_mw.tms_collateral_bedrag,
                                      r_mw.tms_pricing_unit,       r_mw.tms_cross_aantal,          r_mw.tms_cross_bedrag,
                                      r_mw.tms_gecovered_comp,     r_mw.tms_gecovered_comp_bedrag, r_mw.rowid,
                                      i_controle_uitvoeren);
                                      
     end loop;
  end;
  
  -- Door het temp_ap_werkbest_sessie heen
  declare
     cursor ap is
        select t.tas_ref_relatie,       t.tas_productnummer,   t.tas_product_volgnummer,
               t.tas_relatienr,         t.tas_runnummer,       t.tas_rekening_soort,
               t.tas_rekeningnr,        t.tas_rekening_munts,  t.tas_ref_symbool,
               t.tas_symbool,           t.tas_optietype,       t.tas_expiratiedatum,
               t.tas_exerciseprijs,     t.tas_saldo_positie,   t.tas_positie_future,
               t.tas_hist_wrd_poscl,    t.tas_hist_wrd_posbe,  t.tas_hist_wrd_totcl,
               t.tas_hist_wrd_totbe,    t.tas_bi_type,         t.tas_sld_losbaar_marg,
               t.tas_in_cover,          t.tas_in_cover_used,   t.tas_in_collateral,
               t.tas_tegenwaarde_basis, t.tas_export,          t.tas_positie_long,
               t.tas_positie_short,     t.tas_collateral_used, t.tas_wegingsfactor,
               t.tas_baisse_margin,     t.rowid
        from   temp_ap_werkbest_sessie t
        where  t.tas_runnummer        = i_uitgangs_runnummer
        and   (t.tas_ref_symbool      = i_fondssymbool
               and
               i_ref_of_fondssymbool  = 'R'
               or
               t.tas_symbool          = i_fondssymbool
               and
               i_ref_of_fondssymbool  = 'S'
               );
  begin
     for r_ap in ap
     loop
     
        if gv_debuggen = 1
        then
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'vullen temp ap werkbestand (procedure lopende_orders_margin_wb_vul) mbv '||v_omschr_ref_sym);
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'symbool    : '||r_ap.tas_symbool||' ; optietype : '||r_ap.tas_optietype);
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'expdat     : '||r_ap.tas_expiratiedatum||' ;  exerciseprijs : '||to_char(r_ap.tas_exerciseprijs));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'refsymbool : '||r_ap.tas_ref_symbool||' ; saldo pos  : '||to_char(r_ap.tas_saldo_positie));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'depot nr   : '||r_ap.tas_rekeningnr||' ; depot reksoort : '||to_char(r_ap.tas_rekening_soort));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in cover   : '||to_char(r_ap.tas_in_cover)||' ; in cover used : '||to_char(r_ap.tas_in_cover_used));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'runnummer  : '||to_char(r_ap.tas_runnummer)||' ; rowid      : '||r_ap.rowid);
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
        end if;
        
        -- ieder record twee keer wegschrijven: één maal met runnummer 1 en één maal met runnummer 2
        -- eerst runnummer 1
        v_runnummer := 1;
        
        lopende_orders_margin_vul_ap (r_ap.tas_ref_relatie,       r_ap.tas_productnummer,   r_ap.tas_product_volgnummer,
                                      r_ap.tas_relatienr,         v_runnummer,              r_ap.tas_rekening_soort,
                                      r_ap.tas_rekeningnr,        r_ap.tas_rekening_munts,  r_ap.tas_ref_symbool,
                                      r_ap.tas_symbool,           r_ap.tas_optietype,       r_ap.tas_expiratiedatum,
                                      r_ap.tas_exerciseprijs,     r_ap.tas_saldo_positie,   r_ap.tas_positie_future,
                                      r_ap.tas_hist_wrd_poscl,    r_ap.tas_hist_wrd_posbe,  r_ap.tas_hist_wrd_totcl,
                                      r_ap.tas_hist_wrd_totbe,    r_ap.tas_bi_type,         r_ap.tas_sld_losbaar_marg,
                                      r_ap.tas_in_cover,          r_ap.tas_in_cover_used,   r_ap.tas_in_collateral,
                                      r_ap.tas_tegenwaarde_basis, r_ap.tas_export,          r_ap.tas_positie_long,
                                      r_ap.tas_positie_short,     r_ap.tas_collateral_used, r_ap.tas_wegingsfactor,
                                      r_ap.tas_baisse_margin,     null,                     i_controle_uitvoeren);
         
        -- nu runnummer 2
        v_runnummer := 2;

        lopende_orders_margin_vul_ap (r_ap.tas_ref_relatie,       r_ap.tas_productnummer,   r_ap.tas_product_volgnummer,
                                      r_ap.tas_relatienr,         v_runnummer,              r_ap.tas_rekening_soort,
                                      r_ap.tas_rekeningnr,        r_ap.tas_rekening_munts,  r_ap.tas_ref_symbool,
                                      r_ap.tas_symbool,           r_ap.tas_optietype,       r_ap.tas_expiratiedatum,
                                      r_ap.tas_exerciseprijs,     r_ap.tas_saldo_positie,   r_ap.tas_positie_future,
                                      r_ap.tas_hist_wrd_poscl,    r_ap.tas_hist_wrd_posbe,  r_ap.tas_hist_wrd_totcl,
                                      r_ap.tas_hist_wrd_totbe,    r_ap.tas_bi_type,         r_ap.tas_sld_losbaar_marg,
                                      r_ap.tas_in_cover,          r_ap.tas_in_cover_used,   r_ap.tas_in_collateral,
                                      r_ap.tas_tegenwaarde_basis, r_ap.tas_export,          r_ap.tas_positie_long,
                                      r_ap.tas_positie_short,     r_ap.tas_collateral_used, r_ap.tas_wegingsfactor,
                                      r_ap.tas_baisse_margin,     r_ap.rowid,               i_controle_uitvoeren);
       
     end loop;
  end;


end lopende_orders_margin_wb_vul;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_MARGIN_WB_VUL


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_MARGIN_VUL_WM
-- procedure voor het scrhijven van een record in het temp_margin_wb_sessie bestand
procedure lopende_orders_margin_vul_mw
(i_relatienr                in  temp_margin_wb_sessie.tms_relatienr%type
,i_runnummer                in  temp_margin_wb_sessie.tms_runnnummer%type
,i_productnummer            in  temp_margin_wb_sessie.tms_productnummer%type
,i_productvolgnummer        in  temp_margin_wb_sessie.tms_product_volgnummer%type
,i_rekeningsoort            in  temp_margin_wb_sessie.tms_rekeningsoort%type
,i_rekeningnr               in  temp_margin_wb_sessie.tms_rekeningnr%type
,i_rekening_munts           in  temp_margin_wb_sessie.tms_rekening_munts%type
,i_refsymbool               in  temp_margin_wb_sessie.tms_refsymbool%type
,i_soort                    in  temp_margin_wb_sessie.tms_soort%type
,i_symbool                  in  temp_margin_wb_sessie.tms_symbool%type
,i_exp_datum                in  temp_margin_wb_sessie.tms_exp_datum%type
,i_exerciseprijs            in  temp_margin_wb_sessie.tms_exerciseprijs%type
,i_saldo_positie            in  temp_margin_wb_sessie.tms_saldo_positie%type
,i_positie_future           in  temp_margin_wb_sessie.tms_positie_future%type
,i_marginfactor             in  temp_margin_wb_sessie.tms_marginfactor%type
,i_slotkoers_voriged        in  temp_margin_wb_sessie.tms_slotkoers_voriged%type
,i_biedkoers                in  temp_margin_wb_sessie.tms_biedkoers%type
,i_laatkoers                in  temp_margin_wb_sessie.tms_laatkoers%type
,i_blocksize                in  temp_margin_wb_sessie.tms_blocksize%type
,i_margin_required          in  temp_margin_wb_sessie.tms_margin_required%type
,i_gecovered                in  temp_margin_wb_sessie.tms_gecovered%type
,i_spread_aantal            in  temp_margin_wb_sessie.tms_spread_aantal%type
,i_spread_bedrag            in  temp_margin_wb_sessie.tms_spread_bedrag%type
,i_straddle_aantal          in  temp_margin_wb_sessie.tms_straddle_aantal%type
,i_straddle_bedrag          in  temp_margin_wb_sessie.tms_straddle_bedrag%type
,i_valuta                   in  temp_margin_wb_sessie.tms_valuta%type
,i_collateral_bedrag        in  temp_margin_wb_sessie.tms_collateral_bedrag%type
,i_pricing_unit             in  temp_margin_wb_sessie.tms_pricing_unit%type
,i_cross_aantal             in  temp_margin_wb_sessie.tms_cross_aantal%type
,i_cross_bedrag             in  temp_margin_wb_sessie.tms_cross_bedrag%type
,i_gecovered_comp           in  temp_margin_wb_sessie.tms_gecovered_comp%type
,i_gecovered_comp_bedrag    in  temp_margin_wb_sessie.tms_gecovered_comp_bedrag%type
,i_rowid                    in  rowid
,i_controle_uitvoeren       in  number
)

/*------------------------------------------------------------------------------
Procedure   : lopende_orders_margin_wb_vul_mw
description : code voor een procedure waarbij de gegevens uit het temp_margin_wb_sessie
              werkbestand wordt geschreven. Eventueel wordt eerst een controle op het bestaan
              van het te schrijven record uitgevoerd.
------------------------------------------------------------------------------*/

-- Inkomende parameters zijn alle velden uit het werkbestand temp_margin_wb_sessie

is
   v_record_bestaat_niet         number(1);

begin
   v_record_bestaat_niet         := 1;
   
   if i_controle_uitvoeren = 1
   then
      begin
         select 0
         into   v_record_bestaat_niet
         from   temp_margin_wb_sessie m
         where  m.tms_relatienr     = i_relatienr
         and    m.tms_runnnummer    = i_runnummer
         and    m.tms_refsymbool    = i_refsymbool
         and    m.tms_soort         = i_soort
         and    m.tms_biedkoers     = i_biedkoers
         and    m.tms_exp_datum     = i_exp_datum
         and    m.tms_exerciseprijs = i_exerciseprijs
         and    m.tms_symbool       = i_symbool;

      exception
         when no_data_found
         then v_record_bestaat_niet := 1;
      end;
   end if;
   
   if v_record_bestaat_niet = 1
   then
      insert into temp_margin_wb_sessie mA
      (mA.tms_relatienr,            mA.tms_runnnummer,              mA.tms_productnummer,
       mA.tms_product_volgnummer,   mA.tms_rekeningsoort,           mA.tms_rekeningnr,
       mA.tms_rekening_munts,       mA.tms_refsymbool,              mA.tms_soort,
       mA.tms_symbool,              mA.tms_exp_datum,               mA.tms_exerciseprijs,
       mA.tms_saldo_positie,        mA.tms_positie_future,          mA.tms_marginfactor,
       mA.tms_slotkoers_voriged,    mA.tms_biedkoers,               mA.tms_laatkoers,
       mA.tms_blocksize,            mA.tms_margin_required,         mA.tms_gecovered,
       mA.tms_spread_aantal,        mA.tms_spread_bedrag,           mA.tms_straddle_aantal,
       mA.tms_straddle_bedrag,      mA.tms_valuta,                  mA.tms_collateral_bedrag,
       mA.tms_pricing_unit,         mA.tms_cross_aantal,            mA.tms_cross_bedrag,
       mA.tms_gecovered_comp,       mA.tms_gecovered_comp_bedrag,   mA.tms_extern_rowid)
      values
      (i_relatienr,                 i_runnummer,                    i_productnummer,
       i_productvolgnummer,         i_rekeningsoort,                i_rekeningnr,
       i_rekening_munts,            i_refsymbool,                   i_soort,
       i_symbool,                   i_exp_datum,                    i_exerciseprijs,
       i_saldo_positie,             i_positie_future,               i_marginfactor,
       i_slotkoers_voriged,         i_biedkoers,                    i_laatkoers,
       i_blocksize,                 i_margin_required,              i_gecovered,
       i_spread_aantal,             i_spread_bedrag,                i_straddle_aantal,
       i_straddle_bedrag,           i_valuta,                       i_collateral_bedrag,
       i_pricing_unit,              i_cross_aantal,                 i_cross_bedrag,
       i_gecovered_comp,            i_gecovered_comp_bedrag,        i_rowid);
   end if;
            
end lopende_orders_margin_vul_mw;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_MARGIN_VUL_WM


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_MARGIN_VUL_AP
-- procedure voor het scrhijven van een record in het temp_ap_werkbest_sessie bestand
procedure lopende_orders_margin_vul_ap
(i_ref_relatie              in  temp_ap_werkbest_sessie.tas_ref_relatie%type
,i_productnummer            in  temp_ap_werkbest_sessie.tas_productnummer%type
,i_product_volgnummer       in  temp_ap_werkbest_sessie.tas_product_volgnummer%type
,i_relatienr                in  temp_ap_werkbest_sessie.tas_relatienr%type
,i_runnummer                in  temp_ap_werkbest_sessie.tas_runnummer%type
,i_rekening_soort           in  temp_ap_werkbest_sessie.tas_rekening_soort%type
,i_rekeningnr               in  temp_ap_werkbest_sessie.tas_rekeningnr%type
,i_rekening_munts           in  temp_ap_werkbest_sessie.tas_rekening_munts%type
,i_ref_symbool              in  temp_ap_werkbest_sessie.tas_ref_symbool%type
,i_symbool                  in  temp_ap_werkbest_sessie.tas_symbool%type
,i_optietype                in  temp_ap_werkbest_sessie.tas_optietype%type
,i_expiratiedatum           in  temp_ap_werkbest_sessie.tas_expiratiedatum%type
,i_exerciseprijs            in  temp_ap_werkbest_sessie.tas_exerciseprijs%type
,i_saldo_positie            in  temp_ap_werkbest_sessie.tas_saldo_positie%type
,i_positie_future           in  temp_ap_werkbest_sessie.tas_positie_future%type
,i_hist_wrd_poscl           in  temp_ap_werkbest_sessie.tas_hist_wrd_poscl%type
,i_hist_wrd_posbe           in  temp_ap_werkbest_sessie.tas_hist_wrd_posbe%type
,i_hist_wrd_totcl           in  temp_ap_werkbest_sessie.tas_hist_wrd_totcl%type
,i_hist_wrd_totbe           in  temp_ap_werkbest_sessie.tas_hist_wrd_totbe%type
,i_bi_type                  in  temp_ap_werkbest_sessie.tas_bi_type%type
,i_sld_losbaar_marg         in  temp_ap_werkbest_sessie.tas_sld_losbaar_marg%type
,i_in_cover                 in  temp_ap_werkbest_sessie.tas_in_cover%type
,i_in_cover_used            in  temp_ap_werkbest_sessie.tas_in_cover_used%type
,i_in_collateral            in  temp_ap_werkbest_sessie.tas_in_collateral%type
,i_tegenwaarde_basis        in  temp_ap_werkbest_sessie.tas_tegenwaarde_basis%type
,i_export                   in  temp_ap_werkbest_sessie.tas_export%type
,i_positie_long             in  temp_ap_werkbest_sessie.tas_positie_long%type
,i_positie_short            in  temp_ap_werkbest_sessie.tas_positie_short%type
,i_collateral_used          in  temp_ap_werkbest_sessie.tas_collateral_used%type
,i_wegingsfactor            in  temp_ap_werkbest_sessie.tas_wegingsfactor%type
,i_baisse_margin            in  temp_ap_werkbest_sessie.tas_baisse_margin%type
,i_rowid                    in  rowid
,i_controle_uitvoeren       in  number
)

/*------------------------------------------------------------------------------
Procedure   : lopende_orders_margin_wb_vul_ap
description : code voor een procedure waarbij de gegevens uit het temp_ap_werkbest_sessie
              werkbestand wordt geschreven. Eventueel wordt eerst een controle op het bestaan
              van het te schrijven record uitgevoerd.
author      : Syntel Financial Software, Jan Jans Wolthuis
------------------------------------------------------------------------------*/

-- Inkomende parameters zijn alle velden uit het werkbestand temp_ap_werkbest_sessie

is
   v_record_bestaat_niet         number(1);

begin
   v_record_bestaat_niet         := 1;
   
   if i_controle_uitvoeren = 1
   then
      begin
         select 0
         into   v_record_bestaat_niet
         from   temp_ap_werkbest_sessie t
         where  t.tas_relatienr          = i_relatienr
         and    t.tas_runnummer          = i_runnummer
         and    t.tas_rekening_soort     = i_rekening_soort
         and    t.tas_rekening_munts     = i_rekening_munts
         and    t.tas_rekeningnr         = i_rekeningnr
         and    t.tas_symbool            = i_symbool
         and    t.tas_optietype          = i_optietype
         and    t.tas_expiratiedatum     = i_expiratiedatum
         and    t.tas_exerciseprijs      = i_exerciseprijs
         and    t.tas_productnummer      = i_productnummer
         and    t.tas_product_volgnummer = i_product_volgnummer;

      exception
         when no_data_found
         then v_record_bestaat_niet := 1;
      end;
   end if;
   
   if v_record_bestaat_niet = 1
   then
      insert into temp_ap_werkbest_sessie aB
      (aB.tas_ref_relatie,         aB.tas_productnummer,     aB.tas_product_volgnummer,
       aB.tas_relatienr,           aB.tas_runnummer,         aB.tas_rekening_soort,
       aB.tas_rekeningnr,          aB.tas_rekening_munts,    aB.tas_ref_symbool,
       aB.tas_symbool,             aB.tas_optietype,         aB.tas_expiratiedatum,
       aB.tas_exerciseprijs,       aB.tas_saldo_positie,     aB.tas_positie_future,
       aB.tas_hist_wrd_poscl,      aB.tas_hist_wrd_posbe,    aB.tas_hist_wrd_totcl,
       aB.tas_hist_wrd_totbe,      aB.tas_bi_type,           aB.tas_sld_losbaar_marg,
       aB.tas_in_cover,            aB.tas_in_cover_used,     aB.tas_in_collateral,
       aB.tas_tegenwaarde_basis,   aB.tas_export,            aB.tas_positie_long,
       aB.tas_positie_short,       aB.tas_collateral_used,   aB.tas_wegingsfactor,
       aB.tas_baisse_margin,       aB.tas_extern_rowid)
      values
      (i_ref_relatie,              i_productnummer,          i_product_volgnummer,
       i_relatienr,                i_runnummer,              i_rekening_soort,
       i_rekeningnr,               i_rekening_munts,         i_ref_symbool,
       i_symbool,                  i_optietype,              i_expiratiedatum,
       i_exerciseprijs,            i_saldo_positie,          i_positie_future,
       i_hist_wrd_poscl,           i_hist_wrd_posbe,         i_hist_wrd_totcl,
       i_hist_wrd_totbe,           i_bi_type,                i_sld_losbaar_marg,
       i_in_cover,                 i_in_cover_used,          i_in_collateral,
       i_tegenwaarde_basis,        i_export,                 i_positie_long,
       i_positie_short,            i_collateral_used,        i_wegingsfactor,
       i_baisse_margin,            i_rowid);
   end if;
   
end lopende_orders_margin_vul_ap;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_MARGIN_VUL_AP


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORD_MARG_MANDJE_WB_VUL
procedure lopende_ord_marg_mandje_wb_vul
(i_refsymb_be_volgnummer    in  beleggingsinstrument.be_volgnummer%type
,i_ow_is_mandje             in  number
,i_uitgangs_runnummer       in  temp_ap_werkbest_sessie.tas_runnummer%type
,o_extra_toevoeg_ivm_mandje out number
)

/*------------------------------------------------------------------------------
Procedure   : lopende_ord_marg mandje_wb_vul
description : code voor een procedure waarbij door mandjes wordt gelopen om 
              de gegevens mbt de ow van die mandjes op te slaan voor marginberekeningen
author      : Syntel Financial Software, Jan Jans Wolthuis
code        : 8503-53921-0001
history     : 23-MAY-2012, JJW Initial creation.
              18-OKT-2012, JJW, Aanpassing voor referentiefonds in mandje
              07-NOV-2012, JJW, Aanpassing ivm acties als de OW geen mandje is
------------------------------------------------------------------------------*/

is
  
begin
   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In procedure lopende_ord_marg_mandje_wb_vul');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Refsymbool be volgnr : '||to_char(i_refsymb_be_volgnummer)||' ;  ow is mandje : '||to_char(i_ow_is_mandje));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Uitgangs runnummer   : '||to_char(i_uitgangs_runnummer));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;
   
   o_extra_toevoeg_ivm_mandje := 0;
     
   -- Als de onderliggende waarde van de optie die onderhanden is een mandje is,
   -- dan moeten de referentiefondsen worden weggeschreven voor de marginberekening
   if i_ow_is_mandje = 1
   then
      declare
         cursor mo is
         select b.be_symbool
         from   mandje_onderliggende_waarde m, beleggingsinstrument b
         where  m.mnd_volgnummer = i_refsymb_be_volgnummer
         and    m.mnd_ref_volgnr = b.be_volgnummer;
         
      begin
         for r_mo in mo
         loop
            lopende_orders_margin_wb_vul (r_mo.be_symbool, 'S', i_uitgangs_runnummer, 1);
         end loop;
      end;
   else
      -- als de onderliggende waarde van de optie geen mandje is, dan moeten de volgende acties
      -- ondernomen worden:
      -- 1. controleer of de onderliggende waarde als referentiefonds is opgenomen in een mandje
      -- 2. Als dit niet het geval is, dan geen verdere actie
      -- 3. Als dit wel het geval is, controleer dan of de relatie posities heeft in opties waarvan
      --    het gevonden mandje de onderliggende waarde is
      -- 4. Als de relatie geen optiepositie heeft, dan geen verdere actie
      -- 5. Als de relatie wel positie heeft, dan 
      -- 5A. Voeg de opties toe waarvoor het mandje het referentiesymbool is
      -- 5B. Voeg de overige referentie fondsen uit het mandje toe, behalve het referentiefonds uit de
      --     aanroep van deze procedure (die is al toegevoegd in de procedure die deze procedure aanroept)
      
      declare
         v_refsymb_volgnr_in_mandje      number(1);
      begin
         -- 1. controleer of de onderliggende waarde als referentiefonds is toegevoegd aan een mandje
         begin
            select 1
            into   v_refsymb_volgnr_in_mandje
            from   mandje_onderliggende_waarde m
            where  m.mnd_ref_volgnr =  i_refsymb_be_volgnummer
            and    rownum           <= 1;                      -- Er hoeft maar maximaal 1 record opgehaald te worden
         exception
            when no_data_found
            then
               v_refsymb_volgnr_in_mandje := 0;
         end;
         
         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'OW is als referentiefonds in mandje opgenomen : '||to_char(v_refsymb_volgnr_in_mandje));
         end if;
         
         -- 3. Het refsymbool is onderdeel van een mandje
         --    controleer dan of de relatie posities heeft in fondsen waarvan het gevonden mandje de onderliggende waarde is
         if v_refsymb_volgnr_in_mandje = 1
         then
            declare
               v_klant_heeft_optiepositie  number(1);
               
               cursor mo2 is
               select m.mnd_volgnummer, b.be_symbool
               from   mandje_onderliggende_waarde m, beleggingsinstrument b
               where  m.mnd_ref_volgnr = i_refsymb_be_volgnummer
               and    m.mnd_volgnummer = b.be_volgnummer;
            begin
                  
               -- Voor ieder gevonden symbool (het symbool van het mandje) kijken of de relatie optieposities heeft
               for r_mo2 in mo2
               loop
                  v_klant_heeft_optiepositie := 0;
                  
                  begin
                     select 1
                     into   v_klant_heeft_optiepositie
                     from   temp_ap_werkbest_sessie t          -- zoeken naar de optieposities in temp_ap_werkbest_sessie 
                     where  t.tas_ref_symbool =  r_mo2.be_symbool
                     and    rownum            <= 1;            -- Er hoeft maar maximaal 1 record opgehaald te worden
                  exception
                     when no_data_found
                     then
                        v_klant_heeft_optiepositie := 0;
                  end; 
                  
                  if gv_debuggen = 1
                  then
                     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Heeft relatie positie in fonds : '||r_mo2.be_symbool||' ; Ja (1) /Nee (0) : '||to_char(v_klant_heeft_optiepositie));
                  end if;
                  
                  -- De klant heeft wel opties op het mandje in positie
                  if v_klant_heeft_optiepositie = 1
                  then
                     o_extra_toevoeg_ivm_mandje := 1;
                     -- 5A. Voeg de opties toe waarvoor het mandje het referentiesymbool is
                     if gv_debuggen = 1
                     then
                        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Er worden posities toegevoegd met refsymbool :'||r_mo2.be_symbool);
                     end if;
                     lopende_orders_margin_wb_vul (r_mo2.be_symbool, 'R', i_uitgangs_runnummer, 0);
                     
                     -- 5B. Voeg de overige referentie fondsen uit het mandje toe, behalve het referentiefonds uit de
                     --     aanroep van deze procedure
                     declare
                        cursor mo3 is
                        select b.be_symbool
                        from   mandje_onderliggende_waarde m, beleggingsinstrument b
                        where  m.mnd_volgnummer  =  r_mo2.mnd_volgnummer        -- be volgnummer van het mandje
                        and    m.mnd_ref_volgnr  <> i_refsymb_be_volgnummer     -- referentiefonds niet nogmaals toevoegen
                        and    m.mnd_ref_volgnr  =  b.be_volgnummer;
                     begin
                        for r_mo3 in mo3
                        loop
                           if gv_debuggen = 1
                           then
                              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Er worden posities toegevoegd met symbool :'||r_mo3.be_symbool);
                           end if;
                           
                           lopende_orders_margin_wb_vul (r_mo3.be_symbool, 'S', i_uitgangs_runnummer, 1);
                        end loop;
                     end;
                  end if; -- Einde de klant heeft wel opties op het mandje in positie
               end loop; -- Einde voor ieder gevonden symbool kijken of de relatie optieposities heeft
            end; -- Einde controleren of de relatie opties in het mandje heeft
         end if; -- Einde het refsymbool is onderdeel van een mandje
      end;
   
   end if; -- Einde i_ow_is_mandje = 1

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Einde procedure lopende_ord_marg_mandje_wb_vul');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;
end;
-- EINDE CODE LOPENDE_ORD_MARG_MANDJE_WB_VUL


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_MARGIN_WB_AANP
procedure lopende_orders_margin_wb_aanp
(i_relatienummer            in  temp_ap_werkbest_sessie.tas_relatienr%type
,i_depot                    in  temp_ap_werkbest_sessie.tas_rekeningnr%type
,i_depotreksoort            in  temp_ap_werkbest_sessie.tas_rekening_soort%type
,i_refsymbool               in  temp_ap_werkbest_sessie.tas_ref_symbool%type
,i_symbool                  in  temp_ap_werkbest_sessie.tas_symbool%type
,i_optietype                in  temp_ap_werkbest_sessie.tas_optietype%type
,i_expiratiedatum           in  temp_ap_werkbest_sessie.tas_expiratiedatum%type
,i_exerciseprijs            in  temp_ap_werkbest_sessie.tas_exerciseprijs%type
,i_be_bi_nummer             in  temp_ap_werkbest_sessie.tas_bi_type%type
,i_margin_factor            in  temp_margin_wb_sessie.tms_marginfactor%type
,i_slot_koers_vorige_dag    in  temp_margin_wb_sessie.tms_slotkoers_voriged%type
,i_biedkoers                in  temp_margin_wb_sessie.tms_biedkoers%type
,i_laatkoers                in  temp_margin_wb_sessie.tms_laatkoers%type
,i_blocksize                in  temp_margin_wb_sessie.tms_blocksize%type
,i_valuta                   in  temp_margin_wb_sessie.tms_valuta%type
,i_pricing_unit             in  temp_margin_wb_sessie.tms_pricing_unit%type
,i_terminalnummer           in  werkbestand.wk_terminal%type
,i_order_aantal             in  kosten_werkbestand.kst_trans_aantal%type
,i_marginrequirment         in  temp_margin_wb_sessie.tms_margin_required%type
,i_aanpassen_runnummer      in  temp_ap_werkbest_sessie.tas_runnummer%type
)

/*------------------------------------------------------------------------------
Procedure   : lopende_orders_margin_wb_aanp
description : code voor een procedure waarbij de gegevens van een enkelvoudige
              lopende order wordt verwerkt in de marginwerkbestanden met runnummer 2
------------------------------------------------------------------------------*/

is


begin

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'lopende orders margin werkbestand aanpassen');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'(procedure FIAT_ORDER_MARGIN_EFFECT.lopende_orders_margin_wb_aanp)');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'relatie nummer : '||to_char(i_relatienummer)||' ; depot : '||i_depot);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'depotsoort     : '||to_char(i_depotreksoort)||' ; refsymbool : '||i_refsymbool);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'symbool        : '||i_symbool||' ; optietype : '||i_optietype);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'expdatum       : '||i_expiratiedatum||' ; exerciseprijs : '||to_char(i_exerciseprijs));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'be_bi_nummer   : '||to_char(i_be_bi_nummer)||' ; margin factor   : '||to_char(i_margin_factor));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'slot koers     : '||to_char(i_slot_koers_vorige_dag)||' ; biedkoers : '||to_char(i_biedkoers));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'laatkoers      : '||to_char(i_laatkoers)||' ; blocksize : '||to_char(i_blocksize));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'valuta         : '||i_valuta||' ; pricing unit : '||to_char(i_pricing_unit));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'termnummer     : '||to_char(i_terminalnummer)||' ; order aantal : '||to_char(i_order_aantal));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin requir. : '||to_char(i_marginrequirment)||' ; aan te passen runnummer : '||to_char(i_aanpassen_runnummer));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
   end if;

   -- aanpassen van de werkbestand gegevens mbt de order zodat de nieuwe positie ontstaat
   if i_optietype <> 'FUT'
   then
      -- margin werkbestand hoeft alleen voor opties
      if i_optietype in ('CALL','PUT')
      then
         -- voor het werkbestand temp_margin_wb_sessie
         begin
            -- probeer eerst te updaten
            update temp_margin_wb_sessie ma
            set    ma.tms_saldo_positie   = ma.tms_saldo_positie + i_order_aantal,
                   ma.tms_margin_required = ma.tms_margin_required + i_marginrequirment
            where  ma.tms_runnnummer      = i_aanpassen_runnummer
            and    ma.tms_relatienr       = i_terminalnummer
            and    ma.tms_refsymbool      = i_refsymbool
            and    ma.tms_soort           = i_optietype
            and    ma.tms_symbool         = i_symbool
            and    ma.tms_exp_datum       = i_expiratiedatum
            and    ma.tms_exerciseprijs   = i_exerciseprijs;

         -- als dit niet lukt dan een insert
         if sql%notfound
         then
            insert into temp_margin_wb_sessie mb
            (mb.tms_relatienr,       mb.tms_runnnummer,     mb.tms_rekeningsoort,
             mb.tms_rekeningnr,      mb.tms_rekening_munts, mb.tms_refsymbool,
             mb.tms_soort,           mb.tms_symbool,        mb.tms_exp_datum,
             mb.tms_exerciseprijs,   mb.tms_saldo_positie,  mb.tms_positie_future,
             mb.tms_margin_required, mb.tms_marginfactor,   mb.tms_slotkoers_voriged,
             mb.tms_biedkoers,       mb.tms_laatkoers,      mb.tms_blocksize,
             mb.tms_valuta,          mb.tms_pricing_unit)
            values
            (i_terminalnummer,       i_aanpassen_runnummer, 0,
             ' ',                    ' ',                   i_refsymbool,
             i_optietype,            i_symbool,             i_expiratiedatum,
             i_exerciseprijs,        (0 + i_order_aantal),  0,
             i_marginrequirment,     i_margin_factor,       i_slot_koers_vorige_dag,
             i_biedkoers,            i_laatkoers,           i_blocksize,
             i_valuta,               i_pricing_unit);
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'(in procedure lopende_orders_margin_wb_aanp)');
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'voor de optie zit je in de exception!');
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
         end if;

         end;
      end if;

      -- voor het werkbestand temp_ap_werkbest_sess
      -- eerst de positie op het depot
      begin
         -- probeer eest te updaten
         update temp_ap_werkbest_sessie ta
         set    ta.tas_saldo_positie  = ta.tas_saldo_positie + i_order_aantal
         where  ta.tas_runnummer      = i_aanpassen_runnummer
         and    ta.tas_relatienr      = i_terminalnummer
         and    ta.tas_rekeningnr     = i_depot
         and    ta.tas_rekening_soort = i_depotreksoort
         and    ta.tas_symbool        = i_symbool
         and    ta.tas_optietype      = i_optietype
         and    ta.tas_expiratiedatum = i_expiratiedatum
         and    ta.tas_exerciseprijs  = i_exerciseprijs;

         -- als dit niet lukt dan een insert
         if sql%notfound
         then
            insert into temp_ap_werkbest_sessie tb
            (tb.tas_ref_relatie,    tb.tas_relatienr,     tb.tas_runnummer,
             tb.tas_rekening_soort, tb.tas_rekeningnr,    tb.tas_rekening_munts,
             tb.tas_ref_symbool,    tb.tas_symbool,       tb.tas_optietype,
             tb.tas_expiratiedatum, tb.tas_exerciseprijs, tb.tas_saldo_positie,
             tb.tas_bi_type)
            values
            (i_relatienummer,       i_terminalnummer,     i_aanpassen_runnummer,
             i_depotreksoort,       i_depot,              ' ',
             i_refsymbool,          i_symbool,            i_optietype,
             i_expiratiedatum,      i_exerciseprijs,      (0+i_order_aantal),
             i_be_bi_nummer);
         end if;
      end;

      -- Economische positie bijwerken
      begin
         -- probeer eest te updaten
         update temp_ap_werkbest_sessie tc
         set    tc.tas_saldo_positie  = tc.tas_saldo_positie + i_order_aantal
         where  tc.tas_runnummer      = i_aanpassen_runnummer
         and    tc.tas_relatienr      = i_terminalnummer
         and    tc.tas_rekeningnr     = ' '
         and    tc.tas_rekening_soort = 0
         and    tc.tas_symbool        = i_symbool
         and    tc.tas_optietype      = i_optietype
         and    tc.tas_expiratiedatum = i_expiratiedatum
         and    tc.tas_exerciseprijs  = i_exerciseprijs;

         -- als dit niet kukt dan een insert
         if sql%notfound
         then
            insert into temp_ap_werkbest_sessie td
            (td.tas_ref_relatie,    td.tas_relatienr,     td.tas_runnummer,
             td.tas_rekening_soort, td.tas_rekeningnr,    td.tas_rekening_munts,
             td.tas_ref_symbool,    td.tas_symbool,       td.tas_optietype,
             td.tas_expiratiedatum, td.tas_exerciseprijs, td.tas_saldo_positie,
             td.tas_bi_type)
            values
            (i_relatienummer,       i_terminalnummer,     i_aanpassen_runnummer,
             0,                     ' ',                  ' ',
             i_refsymbool,          i_symbool,            i_optietype,
             i_expiratiedatum,      i_exerciseprijs,      (0 + i_order_aantal),
             i_be_bi_nummer);
         end if;
      end;


   elsif i_optietype = 'FUT'
   then
      -- voor het werkbestand temp_margin_wb_sessie
      begin
         -- probeer eerst te updaten
         update temp_margin_wb_sessie mc
         set    mc.tms_positie_future  = mc.tms_positie_future + i_order_aantal,
                mc.tms_margin_required = mc.tms_margin_required + i_marginrequirment
         where  mc.tms_runnnummer      = i_aanpassen_runnummer
         and    mc.tms_relatienr       = i_terminalnummer
         and    mc.tms_refsymbool      = i_refsymbool
         and    mc.tms_soort           = i_optietype
         and    mc.tms_symbool         = i_symbool
         and    mc.tms_exp_datum       = i_expiratiedatum
         and    mc.tms_exerciseprijs   = i_exerciseprijs;

         -- als dit niet lukt dan een insert
         if sql%notfound
         then
            insert into temp_margin_wb_sessie md
            (md.tms_relatienr,       md.tms_runnnummer,     md.tms_rekeningsoort,
             md.tms_rekeningnr,      md.tms_rekening_munts, md.tms_refsymbool,
             md.tms_soort,           md.tms_symbool,        md.tms_exp_datum,
             md.tms_exerciseprijs,   md.tms_saldo_positie,  md.tms_positie_future,
             md.tms_margin_required, md.tms_marginfactor,   md.tms_slotkoers_voriged,
             md.tms_biedkoers,       md.tms_laatkoers,      md.tms_blocksize,
             md.tms_valuta,          md.tms_pricing_unit)
            values
            (i_terminalnummer,       i_aanpassen_runnummer, 0,
             ' ',                    ' ',                   i_refsymbool,
             i_optietype,            i_symbool,             i_expiratiedatum,
             i_exerciseprijs,        0,                     (0 + i_order_aantal),
             i_marginrequirment,     i_margin_factor,       i_slot_koers_vorige_dag,
             i_biedkoers,            i_laatkoers,           i_blocksize,
             i_valuta,               i_pricing_unit);
         end if;
      end;

      -- voor het werkbestand temp_ap_werkbest_sess
      -- eerst de positie op het depot
      begin
         -- probeer eest te updaten
         update temp_ap_werkbest_sessie te
         set    te.tas_positie_future = te.tas_positie_future + i_order_aantal
         where  te.tas_runnummer      = i_aanpassen_runnummer
         and    te.tas_relatienr      = i_terminalnummer
         and    te.tas_rekeningnr     = i_depot
         and    te.tas_rekening_soort = i_depotreksoort
         and    te.tas_symbool        = i_symbool
         and    te.tas_optietype      = i_optietype
         and    te.tas_expiratiedatum = i_expiratiedatum
         and    te.tas_exerciseprijs  = i_exerciseprijs;

         -- als dit niet kukt dan een insert
         if sql%notfound
         then
            insert into temp_ap_werkbest_sessie tf
            (tf.tas_ref_relatie,    tf.tas_relatienr,     tf.tas_runnummer,
             tf.tas_rekening_soort, tf.tas_rekeningnr,    tf.tas_rekening_munts,
             tf.tas_ref_symbool,    tf.tas_symbool,       tf.tas_optietype,
             tf.tas_expiratiedatum, tf.tas_exerciseprijs, tf.tas_positie_future,
             tf.tas_bi_type)
            values
            (i_relatienummer,       i_terminalnummer,     i_aanpassen_runnummer,
             i_depotreksoort,       i_depot,              ' ',
             i_refsymbool,          i_symbool,            i_optietype,
             i_expiratiedatum,      i_exerciseprijs,      (0 + i_order_aantal),
             i_be_bi_nummer);
         end if;
      end;

      -- Economische positie bijwerken
      begin
         -- probeer eest te updaten
         update temp_ap_werkbest_sessie tg
         set    tg.tas_positie_future  = tg.tas_positie_future + i_order_aantal
         where  tg.tas_runnummer      = i_aanpassen_runnummer
         and    tg.tas_relatienr      = i_terminalnummer
         and    tg.tas_rekeningnr     = ' '
         and    tg.tas_rekening_soort = 0
         and    tg.tas_symbool        = i_symbool
         and    tg.tas_optietype      = i_optietype
         and    tg.tas_expiratiedatum = i_expiratiedatum
         and    tg.tas_exerciseprijs  = i_exerciseprijs;

         -- als dit niet kukt dan een insert
         if sql%notfound
         then
            insert into temp_ap_werkbest_sessie th
            (th.tas_ref_relatie,    th.tas_relatienr,     th.tas_runnummer,
             th.tas_rekening_soort, th.tas_rekeningnr,    th.tas_rekening_munts,
             th.tas_ref_symbool,    th.tas_symbool,       th.tas_optietype,
             th.tas_expiratiedatum, th.tas_exerciseprijs, th.tas_positie_future,
             th.tas_bi_type)
            values
            (i_relatienummer,       i_terminalnummer,     i_aanpassen_runnummer,
             0,                     ' ',                  ' ',
             i_refsymbool,          i_symbool,            i_optietype,
             i_expiratiedatum,      i_exerciseprijs,      (0 + i_order_aantal),
             i_be_bi_nummer);
         end if;
      end;

   end if;

end lopende_orders_margin_wb_aanp;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_MARGIN_WB_AANP


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_MARGIN_WB_WIJZ
-- In deze procedure worden de margin werkbestanden voor het margin effect van de orders aangepast aan de nieuwe situaties
-- (aantalen worden aangepast zodat er niet nogmaals cover op gegeven kan worden..)
procedure lopende_orders_margin_wb_wijz
(i_fondssymbool             in  temp_margin_wb_sessie.tms_symbool%type
,i_optietype                in  temp_margin_wb_sessie.tms_soort%type
,i_expiratiedatum           in  temp_margin_wb_sessie.tms_exp_datum%type
,i_exerciseprijs            in  temp_margin_wb_sessie.tms_exerciseprijs%type
,i_aanpassing_op_fonds_niet in  number
,i_extra_toevoeg_ivm_mandje in  number
,i_transactie_indicatie     in  kosten_werkbestand.kst_trans_indicatie%type
,i_is_comb_order            in  number
)

-- inkomende parameters zijn: i_fondssymbool             : Het fondssymbool van het fonds van de lopende order
--                            i_optietype                : Het optietype van het fonds van de lopende order
--                            i_expiratiedatum           : De expiratiedatum van het fonds van de lopende order
--                            i_exerciseprijs            : De exerciseprijs van het fonds van de lopende order
--                            i_aanpassing_op_fonds_niet : Een 0 geeft aan dat de gegvens van het meegstuurde fonds ook
--                                                         moet worden aangepast.
--                                                         Een 1 geeft aan dat het meegestuurde fonds overgeslagen moet worden.

is

   v_saldo_positie     temp_margin_wb_sessie.tms_saldo_positie%type;
   v_positie_future    temp_margin_wb_sessie.tms_positie_future%type;
   v_gecovered         temp_margin_wb_sessie.tms_gecovered%type;
   v_spread_aantal     temp_margin_wb_sessie.tms_spread_aantal%type;
   v_straddle_aantal   temp_margin_wb_sessie.tms_straddle_aantal%type;
   v_cross_aantal      temp_margin_wb_sessie.tms_cross_aantal%type;
   v_margin_required   temp_margin_wb_sessie.tms_margin_required%type;
   
   v_wijziging_doorv   number(1);

begin
   -- eerst het temp_margin_wb_sessie bestand aanpassen
   declare
      cursor mw is
      select m.tms_relatienr,          m.tms_runnnummer,        m.tms_productnummer,
             m.tms_product_volgnummer, m.tms_rekeningsoort,     m.tms_rekeningnr,
             m.tms_rekening_munts,     m.tms_refsymbool,        m.tms_soort,
             m.tms_symbool,            m.tms_exp_datum,         m.tms_exerciseprijs, 
             m.tms_saldo_positie,      m.tms_positie_future,    m.tms_prod_geblok_aantal,
             m.tms_marginfactor,       m.tms_slotkoers_voriged, m.tms_biedkoers,
             m.tms_laatkoers,          m.tms_blocksize,         m.tms_margin_required,
             m.tms_gecovered,          m.tms_spread_aantal,     m.tms_spread_bedrag,
             m.tms_straddle_aantal,    m.tms_straddle_bedrag,   m.tms_valuta,
             m.tms_collateral_bedrag,  m.tms_pricing_unit,      m.tms_cross_aantal,
             m.tms_cross_bedrag,       m.tms_gecovered_comp,    m.tms_gecovered_comp_bedrag,
             m.tms_extern_rowid
      from    temp_margin_wb_sessie m
      where   m.tms_runnnummer   = 2
      and     m.tms_extern_rowid is not null;

   begin
      for r_mw in mw
      loop
         -- Is voor deze order de extra uitgebreide vulling ivm een OW uit het mandje toegepast?
         if i_extra_toevoeg_ivm_mandje = 0
         then   
            -- Geen uitgebreide vulling, dan op de oude manier door
            v_wijziging_doorv := 1;
         else
            -- wel uitgebreide vulling, dan  controleren of het record uit runnummer 1 gelijk is aan dat van runnummer 2
            -- als dat het geval is dan geen wijziging doorvoeren.
            begin
               select 0
               into   v_wijziging_doorv
               from   temp_margin_wb_sessie r1
               where  r1.tms_relatienr             = r_mw.tms_relatienr            
               and    r1.tms_runnnummer            = 1                               -- hier het runnummer 1 record ophalen
               and    r1.tms_productnummer         = r_mw.tms_productnummer        
               and    r1.tms_product_volgnummer    = r_mw.tms_product_volgnummer   
               and    r1.tms_rekeningsoort         = r_mw.tms_rekeningsoort        
               and    r1.tms_rekeningnr            = r_mw.tms_rekeningnr           
               and    r1.tms_rekening_munts        = r_mw.tms_rekening_munts       
               and    r1.tms_refsymbool            = r_mw.tms_refsymbool           
               and    r1.tms_soort                 = r_mw.tms_soort                
               and    r1.tms_symbool               = r_mw.tms_symbool              
               and    r1.tms_exp_datum             = r_mw.tms_exp_datum            
               and    r1.tms_exerciseprijs         = r_mw.tms_exerciseprijs        
               and    r1.tms_saldo_positie         = r_mw.tms_saldo_positie        
               and    r1.tms_positie_future        = r_mw.tms_positie_future       
               and    r1.tms_prod_geblok_aantal    = r_mw.tms_prod_geblok_aantal   
               and    r1.tms_marginfactor          = r_mw.tms_marginfactor         
               and    r1.tms_slotkoers_voriged     = r_mw.tms_slotkoers_voriged    
               and    r1.tms_biedkoers             = r_mw.tms_biedkoers            
               and    r1.tms_laatkoers             = r_mw.tms_laatkoers            
               and    r1.tms_blocksize             = r_mw.tms_blocksize            
               and    r1.tms_margin_required       = r_mw.tms_margin_required      
               and    r1.tms_gecovered             = r_mw.tms_gecovered            
               and    r1.tms_spread_aantal         = r_mw.tms_spread_aantal        
               and    r1.tms_spread_bedrag         = r_mw.tms_spread_bedrag        
               and    r1.tms_straddle_aantal       = r_mw.tms_straddle_aantal      
               and    r1.tms_straddle_bedrag       = r_mw.tms_straddle_bedrag      
               and    r1.tms_valuta                = r_mw.tms_valuta               
               and    r1.tms_collateral_bedrag     = r_mw.tms_collateral_bedrag    
               and    r1.tms_pricing_unit          = r_mw.tms_pricing_unit         
               and    r1.tms_cross_aantal          = r_mw.tms_cross_aantal         
               and    r1.tms_cross_bedrag          = r_mw.tms_cross_bedrag         
               and    r1.tms_gecovered_comp        = r_mw.tms_gecovered_comp       
               and    r1.tms_gecovered_comp_bedrag = r_mw.tms_gecovered_comp_bedrag;
               
            exception
               -- Als het record afwijkend is, dan moet de wijziging weggeschreven gaan worden
               when no_data_found 
               then
                  v_wijziging_doorv := 1;
            end;
            
         end if; 
      
         if ((i_aanpassing_op_fonds_niet = 1
             and
             (r_mw.tms_symbool <> i_fondssymbool
              or
              r_mw.tms_soort <> i_optietype
              or
              r_mw.tms_exp_datum <> i_expiratiedatum
              or
              r_mw.tms_exerciseprijs <> i_exerciseprijs))
            or
            i_aanpassing_op_fonds_niet = 0)
            and 
            v_wijziging_doorv = 1          -- de wijziging moet doorgevoerd worden
         then

            v_saldo_positie     := r_mw.tms_saldo_positie;
            v_positie_future    := r_mw.tms_positie_future;
            v_gecovered         := r_mw.tms_gecovered;
            v_spread_aantal     := r_mw.tms_spread_aantal;
            v_straddle_aantal   := r_mw.tms_straddle_aantal;
            v_cross_aantal      := r_mw.tms_cross_aantal;
            v_margin_required   := r_mw.tms_margin_required;

            -- Wat is er nog over van de saldo positie, geldt alleen voor short opties!
            if v_saldo_positie < 0
            then
               v_saldo_positie := v_saldo_positie + v_gecovered + v_spread_aantal + v_straddle_aantal + v_cross_aantal;
               -- de andere velden op 0 zetten omdat dit nu verwerkt is in de saldo_positie:
               v_gecovered       := 0;
               v_spread_aantal   := 0;
               v_straddle_aantal := 0;
               v_cross_aantal    := 0;
               -- v_margin_required aanpassen de nieuwe situatie:
               -- v_margin_required := saldo_positie/r_mw.tms_saldo_positie*v_margin_required;
            end if;

            -- aanpassen van het oorspronkelijke record
            update temp_margin_wb_sessie tm
            set    tm.tms_saldo_positie   = v_saldo_positie,
                   tm.tms_positie_future  = v_positie_future,
                   tm.tms_gecovered       = v_gecovered,
                   tm.tms_spread_aantal   = v_spread_aantal,
                   tm.tms_straddle_aantal = v_straddle_aantal,
                   tm.tms_cross_aantal    = v_cross_aantal,
                   tm.tms_margin_required = v_margin_required
            where  tm.rowid               = r_mw.tms_extern_rowid;

            if gv_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'wijzigen van de gegevens uit het margin werkbestand ');
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'(procedure FIAT_ORDER_MARGIN_EFFECT.lopende_orders_margin_wb_wijz)');
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'aanpassing op fonds niet : '||to_char(i_aanpassing_op_fonds_niet)||
                                                       ' ; extra aanpassing ivm mandje : '||to_char(i_extra_toevoeg_ivm_mandje));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i symbool      : '||i_fondssymbool||' ; i optietype : '||i_optietype);
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i expiratiedat : '||i_expiratiedatum||' ; exerciseprijs : '||to_char(i_exerciseprijs));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'symbool        : '||r_mw.tms_symbool||' ; optietype : '||r_mw.tms_soort);
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'expiratiedatum : '||r_mw.tms_exp_datum||' ; exerciseprijs : '||to_char(r_mw.tms_exerciseprijs));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie  : '||to_char(v_saldo_positie)||' ; future positie : '||to_char(v_positie_future));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'aantal gevoverd: '||to_char(v_gecovered)||' ; spread aantal : '||to_char(v_spread_aantal));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'straddle aantal: '||to_char(v_straddle_aantal)||' ; cross aantal : '||to_char(v_cross_aantal));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin required: '||to_char(v_margin_required)||' ; row id         : '||r_mw.tms_extern_rowid);
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
            end if;

         end if;
      end loop;
   end;

   -- als tweede het temp_ap_werkbest_sessie bestand aanpassen
   declare
      v_in_cover_used_run_0                  temp_ap_werkbest_sessie.tas_in_cover_used%type;
      v_in_cover_used_for_update             temp_ap_werkbest_sessie.tas_in_cover_used%type;
             
      cursor ap is
      select a.tas_ref_relatie,       a.tas_productnummer,   a.tas_product_volgnummer,
             a.tas_relatienr,         a.tas_runnummer,       a.tas_rekening_soort,
             a.tas_rekeningnr,        a.tas_rekening_munts,  a.tas_ref_symbool,
             a.tas_symbool,           a.tas_optietype,       a.tas_expiratiedatum,
             a.tas_exerciseprijs,     a.tas_saldo_positie,   a.tas_positie_future,
             a.tas_hist_wrd_poscl,    a.tas_hist_wrd_posbe,  a.tas_hist_wrd_totcl,
             a.tas_hist_wrd_totbe,    a.tas_bi_type,         a.tas_sld_losbaar_marg,
             a.tas_in_cover,          a.tas_in_cover_used,   a.tas_in_collateral,
             a.tas_tegenwaarde_basis, a.tas_export,          a.tas_positie_long,
             a.tas_positie_short,     a.tas_collateral_used, a.tas_wegingsfactor,
             a.tas_baisse_margin,     a.tas_extern_rowid
      from   temp_ap_werkbest_sessie a
      where  a.tas_runnummer     =  2
      and    a.tas_extern_rowid is not null;

   begin
      for r_ap in ap
      loop
         v_in_cover_used_for_update    := r_ap.tas_in_cover_used;
         -- Is voor deze order de extra uitgebreide vulling ivm een OW uit het mandje toegepast?
         if i_extra_toevoeg_ivm_mandje = 0
         then   
            -- Geen uitgebreide vulling, dan op de oude manier door
            v_wijziging_doorv := 1;
         else
            -- wel uitgebreide vulling, dan  controleren of het record uit runnummer 1 gelijk is aan dat van runnummer 2
            -- als dat het geval is dan geen wijziging doorvoeren.
            begin
               select 0
               into   v_wijziging_doorv
               from   temp_ap_werkbest_sessie r1
               where  r1.tas_ref_relatie        = r_ap.tas_ref_relatie       
               and    r1.tas_productnummer      = r_ap.tas_productnummer     
               and    r1.tas_product_volgnummer = r_ap.tas_product_volgnummer
               and    r1.tas_relatienr          = r_ap.tas_relatienr         
               and    r1.tas_runnummer          = 1                             -- hier het runnummer 1 record ophalen         
               and    r1.tas_rekening_soort     = r_ap.tas_rekening_soort    
               and    r1.tas_rekeningnr         = r_ap.tas_rekeningnr        
               and    r1.tas_rekening_munts     = r_ap.tas_rekening_munts    
               and    r1.tas_ref_symbool        = r_ap.tas_ref_symbool       
               and    r1.tas_symbool            = r_ap.tas_symbool           
               and    r1.tas_optietype          = r_ap.tas_optietype         
               and    r1.tas_expiratiedatum     = r_ap.tas_expiratiedatum    
               and    r1.tas_exerciseprijs      = r_ap.tas_exerciseprijs     
               and    r1.tas_saldo_positie      = r_ap.tas_saldo_positie     
               and    r1.tas_positie_future     = r_ap.tas_positie_future    
               and    r1.tas_hist_wrd_poscl     = r_ap.tas_hist_wrd_poscl    
               and    r1.tas_hist_wrd_posbe     = r_ap.tas_hist_wrd_posbe    
               and    r1.tas_hist_wrd_totcl     = r_ap.tas_hist_wrd_totcl    
               and    r1.tas_hist_wrd_totbe     = r_ap.tas_hist_wrd_totbe    
               and    r1.tas_bi_type            = r_ap.tas_bi_type           
               and    r1.tas_sld_losbaar_marg   = r_ap.tas_sld_losbaar_marg  
               and    r1.tas_in_cover           = r_ap.tas_in_cover          
               and    r1.tas_in_cover_used      = r_ap.tas_in_cover_used     
               and    r1.tas_in_collateral      = r_ap.tas_in_collateral     
               and    r1.tas_tegenwaarde_basis  = r_ap.tas_tegenwaarde_basis 
               and    r1.tas_export             = r_ap.tas_export            
               and    r1.tas_positie_long       = r_ap.tas_positie_long      
               and    r1.tas_positie_short      = r_ap.tas_positie_short     
               and    r1.tas_collateral_used    = r_ap.tas_collateral_used   
               and    r1.tas_wegingsfactor      = r_ap.tas_wegingsfactor     
               and    r1.tas_baisse_margin      = r_ap.tas_baisse_margin;
               
            exception
               -- Als het record afwijkend is, dan moet de wijziging weggeschreven gaan worden
               when no_data_found 
               then
                  v_wijziging_doorv := 1;
            end;
         end if; 
         
         -- is er voor runlevel 0 (de positie margin bepaling) ook cover berekend, dan hiervoor corrigeren
         if i_transactie_indicatie = 'OV' and i_is_comb_order = 0 and r_ap.tas_optietype = ' ' and r_ap.tas_rekening_soort = 0
         then
            begin
               select t.tas_in_cover_used
               into   v_in_cover_used_run_0
               from   temp_ap_werkbest_sessie t
               where  t.tas_relatienr          = r_ap.tas_relatienr
               and    t.tas_runnummer          = 0                   -- hier zoeken op runnummer = 0
               and    t.tas_rekening_soort     = r_ap.tas_rekening_soort
               and    t.tas_rekening_munts     = r_ap.tas_rekening_munts
               and    t.tas_rekeningnr         = r_ap.tas_rekeningnr
               and    t.tas_symbool            = r_ap.tas_symbool
               and    t.tas_optietype          = r_ap.tas_optietype
               and    t.tas_expiratiedatum     = r_ap.tas_expiratiedatum
               and    t.tas_exerciseprijs      = r_ap.tas_exerciseprijs
               and    t.tas_productnummer      = r_ap.tas_productnummer
               and    t.tas_product_volgnummer = r_ap.tas_product_volgnummer;
            exception
              when no_data_found
              then
                 v_in_cover_used_run_0 := 0;
              end;
              
            if v_in_cover_used_run_0 > 0
               and
               v_in_cover_used_for_update - v_in_cover_used_run_0 >= 0
            then
               v_in_cover_used_for_update := v_in_cover_used_for_update - v_in_cover_used_run_0;
            end if;  
         end if;
         
         if ((i_aanpassing_op_fonds_niet = 1
             and
             (r_ap.tas_symbool <> i_fondssymbool
              or
              r_ap.tas_optietype <> i_optietype
              or
              r_ap.tas_expiratiedatum <> i_expiratiedatum
              or
              r_ap.tas_exerciseprijs <> i_exerciseprijs))
            or
            i_aanpassing_op_fonds_niet = 0)
            and
            v_wijziging_doorv = 1
         then
            -- aanpassen van het oorspronkelijke record
            update temp_ap_werkbest_sessie ta
            set    ta.tas_saldo_positie  = r_ap.tas_saldo_positie,
                   ta.tas_positie_future = r_ap.tas_positie_future,
                   ta.tas_in_cover       = r_ap.tas_in_cover,
                   ta.tas_in_cover_used  = v_in_cover_used_for_update
            where  ta.rowid              = r_ap.tas_extern_rowid;

            if gv_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'wijzigen van de gegevens uit het ap werkbestand');
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'(FIAT_ORDER_MARGIN_EFFECT.procedure lopende_orders_margin_wb_wijz)');
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'aanpassing op fonds niet : '||to_char(i_aanpassing_op_fonds_niet)||
                                                       ' ; extra aanpassing ivm mandje : '||to_char(i_extra_toevoeg_ivm_mandje));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i symbool      : '||i_fondssymbool||' ; i optietype : '||i_optietype);
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i expiratiedat : '||i_expiratiedatum||' ; exerciseprijs : '||to_char(i_exerciseprijs));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'symbool        : '||r_ap.tas_symbool||' ; optietype : '||r_ap.tas_optietype);
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'expiratiedatum : '||r_ap.tas_expiratiedatum||' ; exerciseprijs : '||to_char(r_ap.tas_exerciseprijs));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie  : '||to_char(r_ap.tas_saldo_positie)||' ; future positie : '||to_char(r_ap.tas_positie_future));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in cover       : '||to_char(r_ap.tas_in_cover)||' ; in cover used : '||to_char(r_ap.tas_in_cover_used));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'row id         : '||r_ap.tas_extern_rowid);
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
            end if;
         end if;

      end loop;
   end;

end lopende_orders_margin_wb_wijz;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_MARGIN_WB_WIJZ


-- DE CODE VOOR DE FUNCTION VERSION
function Version
return varchar2
is

begin
      return gv_versie;
end version;
-- EINDE CODE FUNCTION VERSION

end FIAT_ORDER_MARGIN_EFFECT;
/
