create or replace package FIAT_MAGIC
is

/*------------------------------------------------------------------------------
Package     : FIAT_MAGIC
description : code voor de package FIAT_MAGIC waarbinnen de volgende functions en
              procedures aanwezig zijn:
              procedure  relatie_opstart
              procedure  relatie_opruim
              procedure  gegevens_aanwezig
              function   version
              In dit package zitten de procedures (behalve function version) die
              vanuit Magic worden aangeroepen.
------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';


-- procedure relatie_opstart:
   procedure relatie_opstart
   (i_relatienummer              in clienten.cl_nummer%type
   ,i_productnummer              in producten_per_relatie.ppr_productnummer%type
   ,i_productvolgnummer          in producten_per_relatie.ppr_volgnr_per_product%type
   ,i_overrule_account_blockade  in number
   ,i_meerdere_producten         in number
   ,i_te_berekenen_deel          in varchar2
   ,i_detail_geg_aanmaken        in number
   ,i_rapp_val                   in muntsoorten.mu_code%type
   ,i_terminalnr                 in werkbestand.wk_terminal%type
   ,i_onld_omschr                in on_line_dossier.onld_omschrijving_1%type
   ,i_onld_perc                  in on_line_dossier.onld_percentage%type
   ,i_onld_bedrag                in on_line_dossier.onld_bedrag%type
   ,i_sys_opt_marg               in tabelgegevens.tb_waarde%type
   ,i_slot_last_koers            in tabelgegevens.tb_symbool%type
   ,i_ordnr_gewijzigde_order     in orders.ord_ordernummer%type
   ,i_mini_vermogen_eis_bedr     in tabelgegevens.tb_waarde%type
   ,i_user_debug                 in beleggingsadviseurs.ba_magic_user_id%type
   ,i_te_fiatt_belegg_opdr       in beleggingsopdracht_header.boh_opdrachtnummer%type
   ,i_herkomst                   in number
   ,i_instellingen               in varchar2
   ,i_pr_id                      in producten.pr_id%type
   ,i_ppr_id                     in producten_per_relatie.ppr_id%type
   );

-- procedure herbereken_totalen:
   procedure herbereken_totalen
   (i_relatienummer              in clienten.cl_nummer%type
   ,i_terminalnummer             in werkbestand.wk_terminal%type
   ,i_pr_id                      in producten.pr_id%type
   ,i_ppr_id                     in producten_per_relatie.ppr_id%type
   ,i_gewenste_muntsoort         in fiattering_bedragen.fb_valuta%type
   ,i_minim_verm_eis_inst        in number
   ,i_minim_verm_eis_bedr        in tabelgegevens.tb_waarde%type
   ,i_systspreadcodecategorie    in valutaspread_cat_muntsoort.vscm_vsca_id%type
   ,i_bank2mrktqchangedate       in muntsoorten.mu_update%type
   ,i_bedragen_in_vv             in number
   ,i_voorvalutering_bepalen     in number
   ,i_negatieve_rente_bepalen    in number
   ,i_act_balance_exclude_mc     in number
   ,i_coverage_exclude_mc        in number
   ,i_collateral_exclude_mc      in number
   ,i_orders_exclude_mc          in number
   ,i_margin_exclude_mc          in number
   ,i_obligations_exclude_mc     in number
   ,i_neg_interest_exclude_mc    in number
   ,i_invest_orders_exclude_mc   in number
   ,i_value_dat_amn_exclude_mc   in number
   );

-- procedure relatie_opruim:
   procedure relatie_opruim
   (i_term_nummer            in werkbestand.wk_terminal%type
   ,i_alles_verwijderen      in number
   ,i_geen_commit_uitvoeren  in number
   );

-- procedure gegevens_aanwezig
   procedure gegevens_aanwezig
   (i_soort_gegeven      in   clienten.cl_blokkade_soort%type    -- Dit type is gekozen voor zijn picture
   ,i_relatienr          in   clienten.cl_nummer%type
   ,i_termnr             in   werkbestand.wk_terminal%type
   ,o_geg_aanwezig       out  clienten.cl_relatie_type%type      -- Dit type is gekozen voor zijn picture
   );

-- procedure best_comp_historiseren
   procedure best_comp_historiseren
   (i_relatienr_vanaf    in   clienten.cl_nummer%type
   ,i_relatienr_tm       in   clienten.cl_nummer%type
   ,i_productnr_vanaf    in   producten.pr_productnummer%type
   ,i_productnr_tm       in   producten.pr_productnummer%type
   ,i_terminalnr         in   werkbestand.wk_terminal%type
   );


-- procedure best_comp_wegschrijven
   procedure best_comp_wegschrijven
   (i_relatienummer              in   bestedingsruimte_componenten.bc_relatie_nummer%type
   ,i_productnummer              in   bestedingsruimte_componenten.bc_productnummer%type
   ,i_productvolgnummer          in   bestedingsruimte_componenten.bc_product_volgnummer%type
   ,i_terminalnummer             in   werkbestand.wk_terminal%type
   ,i_rapportage_valuta          in   bestedingsruimte_componenten.bc_rapportage_valuta%type
   ,i_bestedingsruimte           in   bestedingsruimte_componenten.bc_bestedingsruimte%type
   ,i_best_ruimte_geblok_tegoed  in   bestedingsruimte_componenten.bc_best_ruimte_geblok_tegoed%type
   ,i_best_ruimte_vrij_tegoed    in   bestedingsruimte_componenten.bc_best_ruimte_vrij_tegoed%type
   ,i_geldsaldo                  in   bestedingsruimte_componenten.bc_geld_saldo%type
   ,i_geldsaldo_geblokkeerd      in   bestedingsruimte_componenten.bc_geld_geblokkeerd%type
   ,i_bedrfspr_geblokk_geld      in   bestedingsruimte_componenten.bc_geld_geblok_bedr_spaar%type
   ,i_overige_geblokk_geld       in   bestedingsruimte_componenten.bc_geld_geblok_overig%type
   ,i_vrij_tegoed                in   bestedingsruimte_componenten.bc_vrij_tegoed%type
   ,i_betalingsopdrachten        in   bestedingsruimte_componenten.bc_betalingsopdr_geblok%type
   ,i_betalopdr_geblok_tegoed    in   bestedingsruimte_componenten.bc_betalingsopdr_bedrspaar%type
   ,i_betalopdr_vrij_tegoed      in   bestedingsruimte_componenten.bc_betalingsopdr_overig%type
   ,i_waarde_effecten            in   bestedingsruimte_componenten.bc_waarde_effecten%type
   ,i_dekkingswaarde_effecten    in   bestedingsruimte_componenten.bc_dekkw_effecten%type
   ,i_dekkingswaarde_geblokkeerd in   bestedingsruimte_componenten.bc_dekkw_geblokkeerd%type
   ,i_ontvangen_zekerheden       in   bestedingsruimte_componenten.bc_ontvangen_garanties%type
   ,i_lopende_orders             in   bestedingsruimte_componenten.bc_lopende_orders%type
   ,i_margin                     in   bestedingsruimte_componenten.bc_margin_totaal%type
   ,i_baisse_margin              in   bestedingsruimte_componenten.bc_baisse_margin%type
   ,i_obligos                    in   bestedingsruimte_componenten.bc_obligo%type
   ,i_negatieve_rente            in   bestedingsruimte_componenten.bc_negatieve_rente%type
   ,i_ruimte_kredietgrp          in   bestedingsruimte_componenten.bc_ruimte_kredietgroep%type
   ,i_kredietlimiet_corr         in   bestedingsruimte_componenten.bc_correctie_kredietlimiet%type
   ,i_lopende_belegg_opdrachten  in   bestedingsruimte_componenten.bc_lopende_belegopdrachten%type
   ,i_oorspr_dekkingswaarde      in   bestedingsruimte_componenten.bc_oorspr_dekkingswaarde%type
   ,i_oorspr_geblokk_dekk_waarde in   bestedingsruimte_componenten.bc_oorspr_gebl_dekkingsw%type
   ,i_oorspr_lopende_orders      in   bestedingsruimte_componenten.bc_oorspr_lopende_orders%type
   ,i_geen_commit_uitvoeren      in   number
   );


-- function version
   function version
   return                      varchar2;

end FIAT_MAGIC;
/
create or replace package body FIAT_MAGIC
is

/*----------------------------------------------------------------------------------------
Package body : FIAT_MAGIC
description  : code voor de package body FIAT_MAGIC waarbinnen de volgende
               functions en procedures aanwezig zijn:
               procedure  relatie_opstart
               procedure  relatie_opruim
               procedure  gegevens_aanwezig
               procedure  best_comp_historiseren
               procedure  best_comp_wegschrijven
               fucntion   version
----------------------------------------------------------------------------------------*/

-- lokale procedures
-- procedure omrekenen_bedrag
   procedure omrekenen_bedrag
   (i_bedrag_van              in  geld_werkbestand.gwb_saldo_vv%type
   ,i_muntsoort_van           in  fiat_muntsoorten.fimu_code%type
   ,i_muntsoort_naar          in  fiat_muntsoorten.fimu_code%type
   ,i_gewenst_van_koerssrt    in  varchar2
   ,i_pr_id                   in  producten.pr_id%type
   ,i_ppr_id                  in  producten_per_relatie.ppr_id%type
   ,i_systspreadcodecategorie in  valutaspread_cat_muntsoort.vscm_vsca_id%type
   ,i_bank2mrktqchangedate    in  muntsoorten.mu_update%type
   ,o_bedrag_naar             out geld_werkbestand.gwb_saldo_vv%type
   );

-- DE CODE VOOR DE PROCEDURE RELATIE_OPSTART:
-- dit is de kapstok procedure die vanuit Magic wordt aangeroepen en waar vandaan de
-- berekeningen voor de bestedingsruimte/fiattering worden opgestart....
procedure relatie_opstart
(i_relatienummer              in clienten.cl_nummer%type
,i_productnummer              in producten_per_relatie.ppr_productnummer%type
,i_productvolgnummer          in producten_per_relatie.ppr_volgnr_per_product%type
,i_overrule_account_blockade  in number
,i_meerdere_producten         in number
,i_te_berekenen_deel          in varchar2
,i_detail_geg_aanmaken        in number
,i_rapp_val                   in muntsoorten.mu_code%type
,i_terminalnr                 in werkbestand.wk_terminal%type
,i_onld_omschr                in on_line_dossier.onld_omschrijving_1%type
,i_onld_perc                  in on_line_dossier.onld_percentage%type
,i_onld_bedrag                in on_line_dossier.onld_bedrag%type
,i_sys_opt_marg               in tabelgegevens.tb_waarde%type
,i_slot_last_koers            in tabelgegevens.tb_symbool%type
,i_ordnr_gewijzigde_order     in orders.ord_ordernummer%type
,i_mini_vermogen_eis_bedr     in tabelgegevens.tb_waarde%type
,i_user_debug                 in beleggingsadviseurs.ba_magic_user_id%type
,i_te_fiatt_belegg_opdr       in beleggingsopdracht_header.boh_opdrachtnummer%type
,i_herkomst                   in number
,i_instellingen               in varchar2
,i_pr_id                      in producten.pr_id%type
,i_ppr_id                     in producten_per_relatie.ppr_id%type
)

-- Inkomende parameters zijn: i_relatienummer             = Relatienummer
--                            i_productnummer             = Het productnummer voor de bepaling
--                            i_productvolgnummer         = Het productvolgnummer voor de bepaling
--                            i_overrule_account_blockade = Vlag die aangeeft of de blokkade op rekeningniveau overruled mag worden
--                            i_meerdere_producten        = Vlag die aangeeft of er meerdere producten voor de relatie zijn
--                            i_detail_geg_aanmaken       = Vlag die aangeeft of detailgegevens weggeschreven moeten worden in
--                                                          werkbestand voor later op scherm tonen
--                            i_rapp_val                  = Rapportagevaluta
--                            i_terminalnr                = Terminalnummer van de user waarop de fiattering is opgestart.
--                            i_onld_omschr               = Online_omschrijving van de relatie --> P of D wordt hiergebruikt
--                            i_onld_perc                 = Online_percentage van de relatie in geval van P
--                            i_onld_bedrag               = Bedrag voor maximering/fixing omgerekend naar rapportage valuta!
--                            i_sys_opt_marg              = Systeem toeslag optiemargin
--                            i_slot_last_koers           = Slot of Laatste koers (S of L)
--                            i_ordnr_gewijzigde_order    = Ordernummer van de gemuteerde order
--                            i_mini_vermogen_eis_bedr    = Bedrag omgerekend in relatie val dat bij margin als minimum
--                                                          vermogenseis geldt
--                            i_user_debug                = Adviseur die aangelogd is.
--                            i_te_fiatt_belegg_opdr      = De te fiatteren beleggingsopdracht.
--                            i_herkomst                  = De herkomst van de aanvraag, op basis hiervan wordt beoordeeld welke componenten worden uitgevoerd
--                            i_instellingen              = Een string met (bijna) alle instellingen die door de packages worden gebruikt
--                            i_pr_id                     = Het Product Id van het product van de klant
--                            i_ppr_id                    = Het Product per relatie Id van het product/productvolgnummer van de klant


is
    v_basis_muntsoort              muntsoorten.mu_code%type;
    v_basis_muntsoort_bkoers       muntsoorten.mu_biedkoers%type;
    v_basis_muntsoort_mkoers       muntsoorten.mu_middenkoers%type;
    v_basis_muntsoort_lkoers       muntsoorten.mu_laatkoers%type;
    v_basis_muntsoort_factor       muntsoorten.mu_factor%type;
    v_basis_muntsoort_reciproke    muntsoorten.mu_reciproke%type;
    v_basis_muntsoort_notatie      muntsoorten.mu_notatie%type;
    v_rapv_rcp                     muntsoorten.mu_reciproke%type;
    v_rapv_factor                  muntsoorten.mu_factor%type;
    v_biedk_rapv                   muntsoorten.mu_biedkoers%type;
    v_middenk_rapv                 muntsoorten.mu_middenkoers%type;
    v_laatk_rapv                   muntsoorten.mu_laatkoers%type;
    v_rapv_notatie                 muntsoorten.mu_notatie%type;

    v_provisie_cat_relatie         clienten.cl_pr_nummer%type;
    v_standaard_prov_cat_gebr      clienten.cl_gebr_stand_prvcat%type;
    v_minimum_prov_relatie_gebr    clienten.cl_min_prov_toepass%type;
    v_relatie_beurs_belasting      clienten.cl_beursbelasting%type;
    v_clientgroep_relatie          clienten.cl_clientgroep%type;
    v_client_margin_inst           clienten.cl_margin%type;
    v_client_margin_toeslag        producten.pr_toeslag_percentage%type;
    v_client_kredietgroep          clienten.cl_kredietgroep%type;
    v_client_id                    clienten.cl_id%type;
    v_client_heeft_depots          number(1);
    v_terugval_basisval            number(4);
    v_provisie_korting_vast        tabelgegevens.tb_waarde%type;
    v_provisie_ex_as_bereken       number(1);
    v_min_max_var_tot              number(1);
    v_max_optie_prov_percentage    relatie_fiattering.rf_max_opt_prov_perc%type;
    v_maximeer_effecten_prov       varchar2(1);
    v_maximeer_opties_prov         varchar2(1);
    v_max_eff_prov_percentage      relatie_fiattering.rf_max_prov_perc%type;
    v_standaard_prov_cat_rel       clienten.cl_pr_nummer%type;
    v_trekkings_waarde_gebruiken   number(1);
   	v_provisie_inst_rekening_gebr  number(1);
    v_mini_vermogens_eis_inst      number(1);
    v_minim_vermogens_eis_bedrag   tabelgegevens.tb_waarde%type;
    v_kooporders_prolongeren       number(1);
    v_methode_naked_margin         number(1);
    v_factor_naked_margin          number(6,3);
    v_wegings_fac_munt_gebr        number(1);
    v_eerst_verkoop_afhandelen     number(1);
    v_dagen_administr_feiten_meen  number(3);
    v_bedrijfspaar_product         number(1)                                        := 0;
    v_belgisch_spaar_product       number(1)                                        := 0;
    v_runnummer                    temp_ap_werkbest_sessie.tas_runnummer%type;
    v_dummy_relatie_nummer         kosten_werkbestand.kst_relatie_nummer%type;
    v_onld_omschr                  on_line_dossier.onld_omschrijving_1%type;
    -- virtuals voor de instellingen die opgehaald worden
    v_inst_type                    varchar2(1);
    v_instelling                   varchar2(100);
    v_op_te_halen_instel           varchar2(30);

    -- virtuals voor het opvangen van berekende waarden
    v_collateral_bedrag            temp_margin_wb_sessie.tms_collateral_bedrag%type;
    v_optie_margin                 temp_margin_wb_sessie.tms_margin_required%type;
    v_future_margin                temp_margin_wb_sessie.tms_margin_required%type;
    v_totaal_margin                temp_margin_wb_sessie.tms_margin_required%type;
    v_baisse_margin                temp_margin_wb_sessie.tms_margin_required%type;
    v_geldsaldo                    aktuele_posities.ap_saldo_positie%type;
    v_geld_geblok                  geblokkeerde_positie.bpos_aantal_nominaal%type;
    v_bedr_spaartegoed_geblok      geblokkeerde_positie.bpos_aantal_nominaal%type;
    v_overige_geld_geblok          geblokkeerde_positie.bpos_aantal_nominaal%type;
    v_totaal_paym_init             payment_initiation.amount%type;
    v_dekk_waarde_rapv             aktuele_posities.ap_saldo_positie%type;
    v_totaal_geblok_dekk           aktuele_posities.ap_saldo_positie%type;
    v_totaal_geblok_stuk           aktuele_posities.ap_saldo_positie%type;
    v_garanties                    on_line_dossier.onld_bedrag%type;
    v_obligo                       on_line_dossier.onld_bedrag%type;
    v_closing_result               obligo_verplichting.obve_obligo_bedrag%type;
    v_bijstellings_bedrag          positiemutaties_geld.pmg_mutatie_aantal%type;
    v_order_lopend_bedrag          kosten_werkbestand.kst_lopend_bedrag%type;
    v_order_dekkingswaarde         kosten_werkbestand.kst_dekkingswaarde%type;
    v_dekkingswaarde_over          kosten_werkbestand.kst_dekkingswaarde%type       := 0;
    v_gebruikte_dekkingsw_ord      kosten_werkbestand.kst_dekkingswaarde%type       := 0;
    v_terug_gegeven_geblok_geld    kosten_werkbestand.kst_marginbedrag%type;
    v_terug_gegeven_twaarde_stuk   kosten_werkbestand.kst_marginbedrag%type;
    v_laatst_berekende_margin      fiattering_bedragen.fb_laatst_ber_margin%type;
    v_voorvalutering               fiattering_bedragen.fb_voorvalutering%type;
    v_lopende_belegg_opdrachten    beleggingsopdracht_header.boh_bedrag%type;
    v_extra_spreid_port_waarde     positie_werkbestand.pwb_port_waarde_rapv%type    := 0;
    v_extra_spreid_port_waarde_vv  positie_werkbestand.pwb_port_waarde_vv%type      := 0;
    v_bank2mrktqchangedate         muntsoorten.mu_update%type;
    v_systspreadcodecategorie      valutaspread_cat_muntsoort.vscm_vsca_id%type;

    -- virtuals voor producten functionaliteit:
    v_pr_blokkeren_short_call      producten.pr_blokkeren_short_calls%type;
    v_pr_blokkeren_short_put       producten.pr_blokkeren_short_puts%type;
    v_pr_blokkeren_long_put        producten.pr_blokkeren_long_puts%type;
    v_pr_margin_berekening         producten.pr_margin_berekening%type;
    v_pr_margin_toeslag            producten.pr_toeslag_percentage%type;
    v_pr_id                        producten.pr_id%type;

    v_sql_err_stack                varchar2(2000);
    v_sql_err_message              varchar2(1000);
    v_debuggen                     number(1)                                  := 0;

begin
    -- de relatie- en de systeemgegevens hoeven maar 1 maal opgehaald te worden:
    select c.cl_beursbelasting,       c.cl_clientgroep,            c.cl_margin,				  c.cl_kredietgroep,         c.cl_id
    into   v_relatie_beurs_belasting, v_clientgroep_relatie,       v_client_margin_inst,	  v_client_kredietgroep, v_client_id
    from   clienten c
    where  c.cl_nummer        = i_relatienummer;

    if i_user_debug = 'PL/SQL'
    then
       v_debuggen  := 1;
    end if;

    if v_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug (i_user_debug, 'Start fiattering voor relatie '||to_char(i_relatienummer)||
                                               ' op '||to_char(SYSDATE,'dd/mm/yyyy-hh24:mi:ss'));
       FIAT_ALGEMEEN.fiat_debug (i_user_debug, 'Doorgegevens Instellingen : '||i_instellingen);
       FIAT_ALGEMEEN.fiat_debug (i_user_debug, ' ');
    end if;

    -- bepalen of een relatie depots heeft (bij geen depots een aantal stappen overslaan)
    begin
       select 1
       into   v_client_heeft_depots
       from   rekeningen_per_product r
       where  r.rpp_productnummer      = i_productnummer
       and    r.rpp_volgnr_per_product = i_productvolgnummer
       and    r.rpp_relatienummer      = i_relatienummer
       and    r.rpp_rekeningsoort      between 1 and 999
       and    i_te_berekenen_deel      <> 'S'
       and    rownum                   <= 1;
    exception
       when no_data_found
       then
          -- als de klant geen depots heeft in het product/productvolgnummer een 0 opslaan
          v_client_heeft_depots := 0;
    end;

	  -- Provisie instellingen ophalen.
    v_op_te_halen_instel := 'PORKActief';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
    into   v_instelling
    from   dual;
    v_provisie_inst_rekening_gebr := to_number(rtrim(ltrim(v_instelling)));

  	if v_provisie_inst_rekening_gebr = 1
	  then
       select p.ppr_provisiecategorie, p.ppr_provcat_standaard,   p.ppr_provcat_minimum
       into   v_provisie_cat_relatie,  v_standaard_prov_cat_gebr, v_minimum_prov_relatie_gebr
       from   producten_per_relatie p
       where  p.ppr_relatienummer      = i_relatienummer
       and    p.ppr_productnummer      = i_productnummer
       and    p.ppr_volgnr_per_product = i_productvolgnummer;
    else
	     select c.cl_pr_nummer,          c.cl_gebr_stand_prvcat,    c.cl_min_prov_toepass
       into   v_provisie_cat_relatie,  v_standaard_prov_cat_gebr, v_minimum_prov_relatie_gebr
       from   clienten c
       where  c.cl_nummer        = i_relatienummer;
	  end if;

    v_op_te_halen_instel := 'Bank2MrktQChangeDate';
    v_inst_type          := 'D';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
    into   v_instelling
    from   dual;
    v_bank2mrktqchangedate := rtrim(ltrim(v_instelling));

    v_op_te_halen_instel := 'SystSprdCodeCat';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
    into   v_instelling
    from   dual;
    v_systspreadcodecategorie := to_number(rtrim(ltrim(v_instelling)));


    FIAT_ALGEMEEN.valutagegevens_bepalen (i_rapp_val,             i_pr_id,      i_ppr_id,      v_systspreadcodecategorie,
                                          v_bank2mrktqchangedate, v_debuggen,   i_user_debug,  v_biedk_rapv,
                                          v_middenk_rapv,         v_laatk_rapv, v_rapv_factor, v_rapv_rcp,
                                          v_rapv_notatie);

    -- Basismuntsoort ophalen
    v_op_te_halen_instel := 'BasisMunt';
    v_inst_type          := 'A';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
    into   v_instelling
    from   dual;
    v_basis_muntsoort := rtrim(ltrim(v_instelling));

    FIAT_ALGEMEEN.valutagegevens_bepalen (v_basis_muntsoort,        i_pr_id,                  i_ppr_id,                 v_systspreadcodecategorie,
                                          v_bank2mrktqchangedate,   v_debuggen,               i_user_debug,             v_basis_muntsoort_bkoers,
                                          v_basis_muntsoort_mkoers, v_basis_muntsoort_lkoers, v_basis_muntsoort_factor, v_basis_muntsoort_reciproke,
                                          v_basis_muntsoort_notatie);

    -- minimale vermogens eis instelling (0 = geen, 1 = per relatie, 2 = per contract)
    v_op_te_halen_instel := 'MinVermEisInst';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
    into   v_instelling
    from   dual;
    v_mini_vermogens_eis_inst := to_number(rtrim(ltrim(v_instelling)));

    if i_herkomst <> 4 and i_herkomst <> 5 and i_herkomst <> 7 -- instellingen binnen dit blok hebben geen betrekking op de margin berekening of de effectenkrediet berekening
    then
       v_op_te_halen_instel := 'StanProvCatRel';
       v_inst_type          := 'N';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
       into   v_instelling
       from   dual;
       v_standaard_prov_cat_rel := to_number(rtrim(ltrim(v_instelling)));

       v_op_te_halen_instel := 'TerugvalBasisval';
       v_inst_type          := 'N';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
       into   v_instelling
       from   dual;
       v_terugval_basisval := to_number(rtrim(ltrim(v_instelling)));

       v_op_te_halen_instel := 'ProvKortVast';
       v_inst_type          := 'N';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
       into   v_instelling
       from   dual;
       v_provisie_korting_vast := to_number(rtrim(ltrim(v_instelling)));

       v_op_te_halen_instel := 'ProvBerekExas';
       v_inst_type          := 'N';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
       into   v_instelling
       from   dual;
       v_provisie_ex_as_bereken := to_number(rtrim(ltrim(v_instelling)));

       v_op_te_halen_instel := 'MinMaxVarTot';
       v_inst_type          := 'N';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
       into   v_instelling
       from   dual;
       v_min_max_var_tot := to_number(rtrim(ltrim(v_instelling)));

       v_op_te_halen_instel := 'MaxEffProvPerc';
       v_inst_type          := 'N';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
       into   v_instelling
       from   dual;
       v_max_eff_prov_percentage := to_number(rtrim(ltrim(v_instelling)))*100; -- deze instelling wordt een factor 100 kleiner opgeslagen vandaar maal 100.

       v_op_te_halen_instel := 'MaxOptProvPerc';
       v_inst_type          := 'N';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
       into   v_instelling
       from   dual;
       v_max_optie_prov_percentage := to_number(rtrim(ltrim(v_instelling)));

       v_op_te_halen_instel := 'MaximeerEffProv';
       v_inst_type          := 'A';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
       into   v_instelling
       from   dual;
       v_maximeer_effecten_prov := rtrim(ltrim(v_instelling));

       v_op_te_halen_instel := 'MaximeerOptProv';
       v_inst_type          := 'A';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
       into   v_instelling
       from   dual;
       v_maximeer_opties_prov := rtrim(ltrim(v_instelling));

       v_op_te_halen_instel := 'KoopOrdProlongeren';
       v_inst_type          := 'N';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
       into   v_instelling
       from   dual;
       v_kooporders_prolongeren := to_number(rtrim(ltrim(v_instelling)));

       v_op_te_halen_instel := 'EerstVerkAfh';
       v_inst_type          := 'N';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
       into   v_instelling
       from   dual;
       v_eerst_verkoop_afhandelen := to_number(rtrim(ltrim(v_instelling)));
    end if;

    if i_herkomst <> 4 and i_herkomst <> 7 -- instellingen binnen dit blok hebben geen betrekking op de margin berekening
    then
    v_op_te_halen_instel := 'DagAdmFeitMeen';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
    into   v_instelling
    from   dual;
    v_dagen_administr_feiten_meen := to_number(rtrim(ltrim(v_instelling)));
    end if;

    v_op_te_halen_instel := 'MethNakedMargin';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
    into   v_instelling
    from   dual;
    v_methode_naked_margin := to_number(rtrim(ltrim(v_instelling)));

    v_op_te_halen_instel := 'FactorNakedMargin';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
    into   v_instelling
    from   dual;
    v_factor_naked_margin := to_number(rtrim(ltrim(v_instelling)));

    -- in de gateway van Magic naar Oracle wordt een ' ' omgezet in een '', hier kan Oracle niets
    -- mee, maar omdat het wel functioneel een waarde is, die hier weer zetten als er geen letter in de i_onld_omsch zit.
    if i_onld_omschr in ('S','D','M','P','F','I','L','E','C')
    then
       v_onld_omschr := i_onld_omschr;
    else
       v_onld_omschr := ' ';
    end if;

    -- gegevens van de trekkingswaarde bepalen.
    v_op_te_halen_instel := 'TRKWActief';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, v_debuggen, i_user_debug)
    into   v_instelling
    from   dual;
    v_trekkings_waarde_gebruiken := to_number(rtrim(ltrim(v_instelling)));

    -- productinformatie ophalen
    select p.pr_blokkeren_long_puts,   p.pr_blokkeren_short_puts,
           p.pr_blokkeren_short_calls, p.pr_margin_berekening,
           p.pr_toeslag_percentage,    p.pr_id
    into   v_pr_blokkeren_long_put,    v_pr_blokkeren_short_put,
           v_pr_blokkeren_short_call,  v_pr_margin_berekening,
           v_pr_margin_toeslag,        v_pr_id
    from   producten p
    where  p.pr_productnummer = i_productnummer;
    
    -- bedrijfspaarproduct en belgischspaarproduct uit de product configurator
    begin 
       select 1 into v_bedrijfspaar_product from product_configurator_temp_vw pc
       where  pc.pr_id = v_pr_id
       and    pc.code = 'IS_BSR_PRODUCT'
       and    pc.year= 0
       and    pc.value= '1';
    exception
       when no_data_found
       then
          v_bedrijfspaar_product := 0;
    end;         
  
    begin
       select 1 into v_belgisch_spaar_product from product_configurator_temp_vw pc
       where  pc.pr_id = v_pr_id
       and    pc.code = 'IS_BPS_PRODUCT'
       and    pc.year= 0
       and    pc.value= '1';
    exception
       when no_data_found
       then
          v_belgisch_spaar_product := 0;
    end;  
  

    -- margin instellingen eventueel aanpassen aan product instelling:
    if v_client_margin_inst = 5
    then
       v_client_margin_inst      := v_pr_margin_berekening;
       v_client_margin_toeslag   := v_pr_margin_toeslag;
    else
       v_client_margin_toeslag   := 0;
       v_pr_blokkeren_long_put   := 0;
       v_pr_blokkeren_short_call := 0;
       v_pr_blokkeren_short_put  := 0;
    end if;
    -- Een aantal instellingen worden na ophalen in een stam werkbestand opgeslagen
    insert into relatie_fiattering r
    (r.rf_relatie_nummer,         r.rf_rapp_muntsoort,        r.rf_rapp_biedkoers,
     r.rf_rapp_laatkoers,         r.rf_rapp_factor,           r.rf_rapp_reciproke,
     r.rf_rapp_notatie,           r.rf_clientgroep,           r.rf_margin,
     r.rf_kredietgroep,           r.rf_pr_nummer,             r.rf_gebr_stand_prvcat,
     r.rf_min_prov_toepass,       r.rf_onld_omschrijving,     r.rf_onld_percentage,
     r.rf_onld_bedrag_rappv,      r.rf_terugval_op_bv,        r.rf_prov_kort_vast,
     r.rf_prov_ex_as_berek,       r.rf_min_max_var_tot,       r.rf_max_opt_prov_perc,
     r.rf_maximeer_eff_prov,      r.rf_maximeer_opt_prov,     r.rf_max_prov_perc,
     r.rf_standaard_cat_rel,      r.rf_bv_muntsoort,          r.rf_bv_biedkoers,
     r.rf_bv_laatkoers,           r.rf_bv_factor,             r.rf_bv_reciproke,
     r.rf_bv_notatie,             r.rf_debug_j_n,              r.rf_debug_user,
     r.rf_rapp_middenkoers,       r.rf_bv_middenkoers,        r.rf_pr_id,
     r.rf_ppr_id)
    values
    (i_relatienummer,             i_rapp_val,                 v_biedk_rapv,
     v_laatk_rapv,                v_rapv_factor,              v_rapv_rcp,
     v_rapv_notatie,              v_clientgroep_relatie,      v_client_margin_inst,
     v_client_kredietgroep,       v_provisie_cat_relatie,     v_standaard_prov_cat_gebr,
     v_minimum_prov_relatie_gebr, v_onld_omschr,              i_onld_perc,
     nvl(i_onld_bedrag,0),        v_terugval_basisval,        v_provisie_korting_vast,
     v_provisie_ex_as_bereken,    v_min_max_var_tot,          v_max_optie_prov_percentage,
     v_maximeer_effecten_prov,    v_maximeer_opties_prov,     v_max_eff_prov_percentage,
     v_standaard_prov_cat_rel,    v_basis_muntsoort,          v_basis_muntsoort_bkoers,
     v_basis_muntsoort_lkoers,    v_basis_muntsoort_factor,   v_basis_muntsoort_reciproke,
     v_basis_muntsoort_notatie,   v_debuggen,                 i_user_debug,
     v_middenk_rapv,              v_basis_muntsoort_mkoers,   i_pr_id,
     i_ppr_id);

    -- hier de inkomende waarde in variabele zetten omdat deze nog aangepast moet worden
    -- (inkomende parameters zijn niet aan te passen).
    v_minim_vermogens_eis_bedrag := i_mini_vermogen_eis_bedr;

    -- verdere variabelen hier zetten
    -- wegings factoren voor munten gebruiken (1 = ja, 0 = nee)
    v_wegings_fac_munt_gebr       := 1;

    -- 1. verzamelproces:
    FIAT_VERZAMEL.relatie_verzamel (i_relatienummer,               v_client_id,                   i_sys_opt_marg,
                                    v_client_margin_toeslag,       v_methode_naked_margin,        v_factor_naked_margin,
                                    i_slot_last_koers,             i_terminalnr,                  i_productnummer,
                                    i_productvolgnummer,           i_overrule_account_blockade,   i_meerdere_producten,
                                    i_te_berekenen_deel,           v_wegings_fac_munt_gebr,       v_client_heeft_depots,
                                    i_detail_geg_aanmaken,         v_dagen_administr_feiten_meen, v_bedrijfspaar_product,
                                    v_pr_blokkeren_short_call,     v_pr_blokkeren_short_put,      i_herkomst,
                                    i_instellingen,                v_extra_spreid_port_waarde,    v_extra_spreid_port_waarde_vv);



    -- 2. de marginberekening uitvoeren
    -- dit hoeft alleen als de klant ook depots heeft
    if v_client_heeft_depots = 1
    then
       v_runnummer := 0;           -- De "echte" marginberekening wordt met runnummer 0 uitgevoerd.
       FIAT_MARGIN.ma_start_margin_bereken (i_relatienummer,              v_client_margin_inst,         v_client_margin_toeslag,
                                            i_terminalnr,                 i_slot_last_koers,            v_trekkings_waarde_gebruiken,
                                            v_mini_vermogens_eis_inst,    v_minim_vermogens_eis_bedrag, v_runnummer,
                                            v_pr_blokkeren_short_call,    v_pr_blokkeren_short_put,     v_pr_blokkeren_long_put,
                                            i_instellingen,
                                            v_minim_vermogens_eis_bedrag, v_collateral_bedrag,          v_optie_margin,
                                            v_future_margin,              v_totaal_margin,              v_baisse_margin);
    end if;


    if i_herkomst <> 4 -- uitsluiten voor alleen margin berekening
    then

    -- 3. De bedragen berekenen aan de hand van de diverse (werk-)bestanden
    FIAT_BEDRAG_BEPALING.relatie_bedrag_bepaling (i_relatienummer,              i_terminalnr,                  v_wegings_fac_munt_gebr,
                                                  v_trekkings_waarde_gebruiken, i_productnummer,               i_productvolgnummer,
                                                  i_te_berekenen_deel,          i_te_fiatt_belegg_opdr,        v_eerst_verkoop_afhandelen,
                                                  v_client_heeft_depots,        i_detail_geg_aanmaken,
                                                  v_bedrijfspaar_product,       i_instellingen,                v_geldsaldo,
                                                  v_geld_geblok,                v_bedr_spaartegoed_geblok,     v_overige_geld_geblok,
                                                  v_totaal_paym_init,           v_dekk_waarde_rapv,            v_totaal_geblok_dekk,
                                                  v_totaal_geblok_stuk,         v_garanties,                   v_obligo,
                                                  v_closing_result,             v_bijstellings_bedrag,         v_laatst_berekende_margin,
                                                  v_voorvalutering,             v_lopende_belegg_opdrachten);

    -- de stappen 4, 5 en 6 hoeven alleen als de relatie depots heeft
    if v_client_heeft_depots = 1
    then
       -- als de klant extra spreidingseis heeft als kredietbrief, dan de portefeuille waarde vastleggen voor verder gebruik bij de ordering
       if i_onld_omschr = 'E'
       then
          insert into werkbestand w
          (w.wk_terminal,                     w.wk_soort,                     w.wk_categorie_1,
           w.wk_waarde_1,                     w.wk_waarde_2,
           w.wk_waarde_3,                     w.wk_waarde_4)
          values
          (i_terminalnr,                      'OREP',                         'Portefeuille waarde',
           nvl(v_extra_spreid_port_waarde,0), nvl(v_extra_spreid_port_waarde,0),
           nvl(v_extra_spreid_port_waarde_vv,0), nvl(v_extra_spreid_port_waarde_vv,0));
       end if;


       if i_herkomst <> 5 and i_herkomst <> 7 -- uitsluiten voor alleen effectenkrediet berekeningen
       then

       -- 4. lopende orders bepalen
       FIAT_ORDERS.lopende_orders_loop (i_relatienummer,              i_slot_last_koers,         i_ordnr_gewijzigde_order,
                                        i_terminalnr,                 v_client_margin_toeslag,
                                        i_productnummer,              i_productvolgnummer,        v_trekkings_waarde_gebruiken,
                                        v_pr_blokkeren_short_call,    v_pr_blokkeren_short_put,   v_pr_blokkeren_long_put,
                                        v_kooporders_prolongeren,     v_methode_naked_margin,     v_factor_naked_margin,
                                        i_te_fiatt_belegg_opdr,       v_eerst_verkoop_afhandelen, i_instellingen,
                                        v_belgisch_spaar_product,     v_dekkingswaarde_over,      v_gebruikte_dekkingsw_ord,
                                        v_lopende_belegg_opdrachten);

       -- 5. de diverse totalen mbt de orders bepalen
       select nvl(sum(k.kst_lopend_bedrag),0), nvl(sum(k.kst_dekkingswaarde),0)
       into   v_order_lopend_bedrag,           v_order_dekkingswaarde
       from   kosten_werkbestand k
       where  k.kst_relatie_nummer = i_relatienummer;

       -- 6 huidige order gegevens berekenen:
       begin
          select k.kst_relatie_nummer
          into   v_dummy_relatie_nummer
          from   kosten_werkbestand k
          where  k.kst_ordernummer = -1
          and    k.kst_orderregel  = 1;
       exception
          when no_data_found
          then
             v_dummy_relatie_nummer := 0;
       end;

       if v_dummy_relatie_nummer <> 0
       then
          FIAT_ORDERS.huidige_order_loop(i_relatienummer,          i_slot_last_koers,       i_terminalnr,                 v_client_margin_toeslag,
                                         i_productnummer,          i_productvolgnummer,     v_trekkings_waarde_gebruiken, v_pr_blokkeren_short_call,
                                         v_pr_blokkeren_short_put, v_pr_blokkeren_long_put, v_kooporders_prolongeren,     v_methode_naked_margin,
                                         v_factor_naked_margin,    v_dekkingswaarde_over,   v_gebruikte_dekkingsw_ord,    i_instellingen,
                                         v_belgisch_spaar_product);
       end if;

       end if;

    end if; -- einde alleen als klant depots heeft


    -- 7. Controleren of er nog geblokkeerd geld en of tegenwaarde van geblokkeerde stukken
    -- is terug gegeven bij combinatieorders.
    -- Het is een optelling van de wk_waarde_2 van de werkbestandsoorten TGBG en TGBS
    -- Geld:
    v_terug_gegeven_geblok_geld := 0;
    begin
       select sum(w.wk_waarde_2)
       into   v_terug_gegeven_geblok_geld
       from   werkbestand w
       where  w.wk_terminal    = i_terminalnr
       and    w.wk_soort       = 'TGBG'
       and    w.wk_categorie_2 = ' ' -- nb geen categorie_1 !!!
       and    w.wk_categorie_3 = ' '
       and    w.wk_categorie_4 = ' '
       and    w.wk_datum_1     = '00000000';
    exception
       when no_data_found
       then
          v_terug_gegeven_geblok_geld := 0;
    end;

    if v_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug (i_user_debug, 'terug gegeven geblokkeerd geld : '||
                                                                             to_char(nvl(v_terug_gegeven_geblok_geld,0)));
       FIAT_ALGEMEEN.fiat_debug (i_user_debug, 'geblokkeerd geld               : '||to_char(v_geld_geblok));
       FIAT_ALGEMEEN.fiat_debug (i_user_debug, ' ');
    end if;

    v_geld_geblok := v_geld_geblok - nvl(v_terug_gegeven_geblok_geld,0);
    if v_geld_geblok <0 and nvl(v_terug_gegeven_geblok_geld,0) <> 0
    then
       v_geld_geblok := 0;
    end if;

    -- tegenwaarde van de teruggegeven stukken:
    v_terug_gegeven_twaarde_stuk := 0;
    begin
       select sum(w.wk_waarde_1)
       into   v_terug_gegeven_twaarde_stuk
       from   werkbestand w
       where  w.wk_terminal    = i_terminalnr
       and    w.wk_soort       = 'TGBS'
       and    w.wk_categorie_2 = ' ' -- nb geen categorie_1 !!!
       and    w.wk_categorie_3 = ' '
       and    w.wk_categorie_4 = ' '
       and    w.wk_datum_1     = '00000000';
    exception
       when no_data_found
       then
          v_terug_gegeven_twaarde_stuk := 0;
    end;

    if v_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug (i_user_debug, 'terug gegeven tegenwaarde stukken : '||
                                                                              to_char(nvl(v_terug_gegeven_twaarde_stuk,0)));
       FIAT_ALGEMEEN.fiat_debug (i_user_debug, 'geblokkeerde stukken               : '||to_char(v_totaal_geblok_stuk));
       FIAT_ALGEMEEN.fiat_debug (i_user_debug, ' ');
    end if;

    v_totaal_geblok_stuk := v_totaal_geblok_stuk - nvl(v_terug_gegeven_twaarde_stuk,0);
    if v_totaal_geblok_stuk <0 and nvl(v_terug_gegeven_twaarde_stuk,0) <> 0
    then
       v_totaal_geblok_stuk := 0;
    end if;

    end if;

    -- 8. Als laatste stap de gegevens wegschrijven zodat ze in magic opgeroepen kunnen worden
    insert into fiattering_bedragen f
    (f.fb_relatie_nummer,              f.fb_datum,                       f.fb_tijd,
     f.fb_geld_saldo,                  f.fb_geld_geblokkeerd,            
     f.fb_dekkw_effecten,              f.fb_dekkw_geblokkeerd,           f.fb_collateral,
     f.fb_margin_totaal,               f.fb_ontvangen_garanties,         f.fb_obligo,
     f.fb_lopende_orders,              f.fb_closing_resultaat,           f.fb_bijstelling,
     f.fb_voorvalutering,              f.fb_laatst_ber_margin,           f.fb_lopende_belegopdrachten,
     f.fb_geld_geblok_bedr_spaar,      f.fb_geld_geblok_overig,          
     f.fb_totaal_paym_init,            f.fb_valuta)
    values
    (i_relatienummer,                  to_char(SYSDATE,'yyyymmdd'),      to_char(SYSDATE,'HH24MISS'),
     nvl(v_geldsaldo,0),               nvl(v_geld_geblok,0),            
     nvl(v_dekk_waarde_rapv,0),        nvl(v_totaal_geblok_stuk,0),      nvl(v_collateral_bedrag,0),
     nvl(v_totaal_margin,0),           nvl(v_garanties,0),               nvl(v_obligo,0),
     nvl(v_order_lopend_bedrag,0),     nvl(v_closing_result,0),          nvl(v_bijstellings_bedrag,0),
     nvl(v_voorvalutering,0),          nvl(v_laatst_berekende_margin,0), nvl(v_lopende_belegg_opdrachten,0),
     nvl(v_bedr_spaartegoed_geblok,0), nvl(v_overige_geld_geblok,0),     
     nvl(v_totaal_paym_init,0),        'ALLES');          -- Bij de eerste berekening wordt ALLES als munt weggeschreven...

    if v_debuggen = 1
    then
       FIAT_ALGEMEEN.version_uitvraag (i_user_debug);
       FIAT_ALGEMEEN.fiat_debug (i_user_debug, 'Einde fiattering voor relatie '||to_char(i_relatienummer)||
                                               ' op '||to_char(SYSDATE,'dd/mm/yyyy-hh24:mi:ss'));
    end if;

exception
   -- Er is een Oracle Error opgetreden. Deze dan hier loggen zodat die in Magic om te zetten is
   when others then
      v_sql_err_stack   := dbms_utility.format_error_backtrace;
      v_sql_err_message := sqlerrm;

      -- De errorgegevens even opslaan in het werkbestand
      insert into werkbestand w
      (w.wk_terminal,                   w.wk_soort,
       w.wk_categorie_1,                w.wk_categorie_2,
       w.wk_categorie_3,                w.wk_categorie_4)
      values
      (i_terminalnr,                    'ERRM',
       '000',                           substr(v_sql_err_message,1,28),
       substr(v_sql_err_message,29,28), substr(v_sql_err_message,57,28));

      insert into werkbestand w
      (w.wk_terminal,                  w.wk_soort,
       w.wk_categorie_1,               w.wk_categorie_2,
       w.wk_categorie_3,               w.wk_categorie_4)
      values
      (i_terminalnr,                   'ERRM',
       '001',                          substr(v_sql_err_stack,1,28),
       substr(v_sql_err_stack,29,28),  substr(v_sql_err_stack,57,28));

      insert into werkbestand w
      (w.wk_terminal,                  w.wk_soort,
       w.wk_categorie_1,               w.wk_categorie_2,
       w.wk_categorie_3,               w.wk_categorie_4)
      values
      (i_terminalnr,                   'ERRM',
       '002',                          substr(v_sql_err_stack,85,28),
       substr(v_sql_err_stack,113,28), substr(v_sql_err_stack,141,28));

      insert into werkbestand w
      (w.wk_terminal,                  w.wk_soort,
       w.wk_categorie_1,               w.wk_categorie_2,
       w.wk_categorie_3,               w.wk_categorie_4)
      values
      (i_terminalnr,                   'ERRM',
       '003',                          substr(v_sql_err_stack,169,28),
       substr(v_sql_err_stack,197,28), substr(v_sql_err_stack,225,28));

      insert into werkbestand w
      (w.wk_terminal,                  w.wk_soort,
       w.wk_categorie_1,               w.wk_categorie_2,
       w.wk_categorie_3,               w.wk_categorie_4)
      values
      (i_terminalnr,                   'ERRM',
       '004',                          substr(v_sql_err_stack,253,28),
       substr(v_sql_err_stack,281,28), substr(v_sql_err_stack,309,28));

      insert into werkbestand w
      (w.wk_terminal,                  w.wk_soort,
       w.wk_categorie_1,               w.wk_categorie_2,
       w.wk_categorie_3,               w.wk_categorie_4)
      values
      (i_terminalnr,                   'ERRM',
       '005',                          substr(v_sql_err_stack,337,28),
       substr(v_sql_err_stack,365,28), substr(v_sql_err_stack,393,28));

         -- De error die Oracle/Magic normaal zou geven hier onderdrukken.
         null;


end relatie_opstart;
-- EINDE CODE PROCEDURE RELATIE_OPSTART


-- DE CODE VOOR DE PROCEDURE HERBEREKEN_TOTALEN
-- procedure die vanuit Magic wordt aangeroepen en die voor een bepaalde muntsoort de totalen berekend
procedure herbereken_totalen
(i_relatienummer              in clienten.cl_nummer%type
,i_terminalnummer             in werkbestand.wk_terminal%type
,i_pr_id                      in producten.pr_id%type
,i_ppr_id                     in producten_per_relatie.ppr_id%type
,i_gewenste_muntsoort         in fiattering_bedragen.fb_valuta%type
,i_minim_verm_eis_inst        in number
,i_minim_verm_eis_bedr        in tabelgegevens.tb_waarde%type
,i_systspreadcodecategorie    in valutaspread_cat_muntsoort.vscm_vsca_id%type
,i_bank2mrktqchangedate       in muntsoorten.mu_update%type
,i_bedragen_in_vv             in number
,i_voorvalutering_bepalen     in number
,i_negatieve_rente_bepalen    in number
,i_act_balance_exclude_mc     in number
,i_coverage_exclude_mc        in number
,i_collateral_exclude_mc      in number
,i_orders_exclude_mc          in number
,i_margin_exclude_mc          in number
,i_obligations_exclude_mc     in number
,i_neg_interest_exclude_mc    in number
,i_invest_orders_exclude_mc   in number
,i_value_dat_amn_exclude_mc   in number
)
is
  -- algemene variabelen
  v_rapp_valuta_notatie              relatie_fiattering.rf_rapp_notatie%type;
  v_relatie_heeft_depots             number(1);
  v_omgerekend_bedrag                geld_werkbestand.gwb_saldo_vv%type;

  -- variabelen om de totaalbedragen in op te slaan om ze daarna weg te kunnen schrijven in het bestand fiattering_bedragen
  v_geldsaldo                        fiattering_bedragen.fb_geld_saldo%type              := 0;
  v_geldsaldo_geblokkeerd            fiattering_bedragen.fb_geld_geblokkeerd%type        := 0;
  v_bedrijfspaar_geld_geblokk        fiattering_bedragen.fb_geld_geblok_bedr_spaar%type  := 0;
  v_overig_geld_geblokk              fiattering_bedragen.fb_geld_geblok_overig%type      := 0;
  v_payment_initiations              fiattering_bedragen.fb_totaal_paym_init%type        := 0;
  v_dekkingswaarde_effecten          fiattering_bedragen.fb_dekkw_effecten%type          := 0;
  v_collateral                       fiattering_bedragen.fb_collateral%type              := 0;
  v_margin_totaal                    fiattering_bedragen.fb_margin_totaal%type           := 0;
  v_dekkingswaarde_geblokk           fiattering_bedragen.fb_dekkw_geblokkeerd%type       := 0;
  v_dekkingswaarde_cov_coll          fiattering_bedragen.fb_dekkw_geblokkeerd%type       := 0;
  v_ontvangen_zekerheden             fiattering_bedragen.fb_ontvangen_garanties%type     := 0;
  v_lopende_orders                   fiattering_bedragen.fb_lopende_orders%type          := 0;
  v_obligo                           fiattering_bedragen.fb_obligo%type                  := 0;
  v_closing_resultaat                fiattering_bedragen.fb_closing_resultaat%type       := 0;
  v_bijstelling                      fiattering_bedragen.fb_bijstelling%type             := 0;
  v_lopende_beleggingsopdr           fiattering_bedragen.fb_lopende_belegopdrachten%type := 0;
  v_negatieve_rente                  fiattering_bedragen.fb_negatieve_rente_bedr%type    := 0;
  v_voorvalutering                   fiattering_bedragen.fb_voorvalutering%type          := 0;
  -- variabelen om de totaalbedragen in vv in op te slaan om ze daarna te kunnen wegschrijven in het bestand fiattering_bedragen
  v_geldsaldo_vv                     fiattering_bedragen.fb_geld_saldo%type              := 0;
  v_geldsaldo_geblokkeerd_vv         fiattering_bedragen.fb_geld_geblokkeerd%type        := 0;
  v_bedrijfspaar_geld_geblokk_vv     fiattering_bedragen.fb_geld_geblok_bedr_spaar%type  := 0;
  v_overig_geld_geblokk_vv           fiattering_bedragen.fb_geld_geblok_overig%type      := 0;
  v_payment_initiations_vv           fiattering_bedragen.fb_totaal_paym_init%type        := 0;
  v_dekkingswaarde_effecten_vv       fiattering_bedragen.fb_dekkw_effecten%type          := 0;
  v_collateral_vv                    fiattering_bedragen.fb_collateral%type              := 0;
  v_margin_totaal_vv                 fiattering_bedragen.fb_margin_totaal%type           := 0;
  v_dekkingswaarde_geblokk_vv        fiattering_bedragen.fb_dekkw_geblokkeerd%type       := 0;
  v_dekkingswaarde_cov_coll_vv       fiattering_bedragen.fb_dekkw_geblokkeerd%type       := 0;
  v_ontvangen_zekerheden_vv          fiattering_bedragen.fb_ontvangen_garanties%type     := 0;
  v_lopende_orders_vv                fiattering_bedragen.fb_lopende_orders%type          := 0;
  v_obligo_vv                        fiattering_bedragen.fb_obligo%type                  := 0;
  v_closing_resultaat_vv             fiattering_bedragen.fb_closing_resultaat%type       := 0;
  v_bijstelling_vv                   fiattering_bedragen.fb_bijstelling%type             := 0;
  v_lopende_beleggingsopdr_vv        fiattering_bedragen.fb_lopende_belegopdrachten%type := 0;
  v_negatieve_rente_vv               fiattering_bedragen.fb_negatieve_rente_bedr%type    := 0;
  v_voorvalutering_vv                fiattering_bedragen.fb_voorvalutering%type          := 0;

  v_aantal_opties_futures            temp_margin_wb_sessie.tms_saldo_positie%type        := 0;

begin
  select r.rf_rapp_notatie
  into   v_rapp_valuta_notatie
  from   relatie_fiattering r
  where  r.rf_relatie_nummer = i_relatienummer;

  begin
     select 1
     into   v_relatie_heeft_depots
     from   te_doorlopen_rek t
     where  t.tdr_rekeningsoort between 100 and 999
     and    rownum              <= 1;
  exception
       when no_data_found
       then
          -- als de klant geen depots heeft in het product/productvolgnummer een 0 opslaan
          v_relatie_heeft_depots := 0;
  end;

  -- bepalen geldsaldo
  if i_bedragen_in_vv = 1
  then
     declare
        cursor gwb is
        select g.gwb_rekening_munt, sum(g.gwb_saldo_vv_sl + g.gwb_trans_mut_vv_sl) as vv_bedrag
        from   geld_werkbestand g
        where  g.gwb_relatie_nummer     = i_relatienummer
        and   (g.gwb_rekening_munt      = i_gewenste_muntsoort
               or
               i_act_balance_exclude_mc = 1)
        group by g.gwb_rekening_munt;

     begin
        for r_gwb in gwb
        loop
           if r_gwb.gwb_rekening_munt = i_gewenste_muntsoort
           then
              v_geldsaldo_vv := v_geldsaldo_vv + r_gwb.vv_bedrag;
           else
              v_omgerekend_bedrag := 0;
              omrekenen_bedrag( r_gwb.vv_bedrag, r_gwb.gwb_rekening_munt,   i_gewenste_muntsoort,
                                case when r_gwb.vv_bedrag>=0 then 'L' else 'B' end,                 i_pr_id,
                                i_ppr_id,        i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);

              v_geldsaldo_vv := v_geldsaldo_vv + v_omgerekend_bedrag;
           end if;
        end loop;
     end;
  else
     select nvl(sum(g.gwb_saldo_rapv + g.gwb_trans_mut_rapv),0)
     into   v_geldsaldo
     from   geld_werkbestand g
     where  g.gwb_relatie_nummer     = i_relatienummer
     and   (g.gwb_rekening_munt      = i_gewenste_muntsoort
            or
            i_act_balance_exclude_mc = 1);
  end if;

  -- Bepalen geblokkeerd geld uit de geldposities
  declare
     cursor fbc is
        select f.account_currency, f.bedrspr_ind, sum(f.amount_repc) as total_amount, sum(f.amount_fc_sl) as total_amount_fc_sl
        from   fiat_blocked_cash f
        where  (f.account_currency       = i_gewenste_muntsoort
                or
                i_act_balance_exclude_mc = 1)
        group by f.account_currency, f.bedrspr_ind;
  begin
     for r_fbc in fbc
     loop
        if i_bedragen_in_vv = 1
        then
           if r_fbc.account_currency = i_gewenste_muntsoort
           then
              v_geldsaldo_geblokkeerd_vv := v_geldsaldo_geblokkeerd_vv + r_fbc.total_amount_fc_sl;

              if r_fbc.bedrspr_ind =1
              then
                 v_bedrijfspaar_geld_geblokk_vv := v_bedrijfspaar_geld_geblokk_vv + r_fbc.total_amount_fc_sl;
              else
                 v_overig_geld_geblokk_vv       := v_overig_geld_geblokk_vv + r_fbc.total_amount_fc_sl;
              end if;
           else
              v_omgerekend_bedrag := 0;
              omrekenen_bedrag( r_fbc.total_amount_fc_sl, r_fbc.account_currency,    i_gewenste_muntsoort,  'B',                i_pr_id,
                                i_ppr_id,                 i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);
              v_geldsaldo_geblokkeerd_vv := v_geldsaldo_geblokkeerd_vv + v_omgerekend_bedrag;

              if r_fbc.bedrspr_ind =1
              then
                 v_bedrijfspaar_geld_geblokk_vv := v_bedrijfspaar_geld_geblokk_vv + v_omgerekend_bedrag;
              else
                 v_overig_geld_geblokk_vv       := v_overig_geld_geblokk_vv + v_omgerekend_bedrag;
              end if;
           end if;
        else
           v_geldsaldo_geblokkeerd := v_geldsaldo_geblokkeerd + r_fbc.total_amount;

           if r_fbc.bedrspr_ind = 1
           then
              v_bedrijfspaar_geld_geblokk := v_bedrijfspaar_geld_geblokk + r_fbc.total_amount;
           else
              v_overig_geld_geblokk       := v_overig_geld_geblokk + r_fbc.total_amount;
           end if;
        end if;
     end loop;
  end;

  -- Totaal van payment initiations
  if i_bedragen_in_vv = 1
  then
     declare
        cursor fp is
        select f.foreign_curr, sum(nvl(f.amount_fc,0)) as vv_amount
        from   fiat_payments f
        where (f.foreign_curr           = i_gewenste_muntsoort
               or
               i_act_balance_exclude_mc = 1)
        group by f.foreign_curr;
     begin
        for r_fp in fp
        loop
           if r_fp.foreign_curr = i_gewenste_muntsoort
           then
              v_payment_initiations_vv := v_payment_initiations_vv + r_fp.vv_amount;
           else
              v_omgerekend_bedrag := 0;
              omrekenen_bedrag( r_fp.vv_amount, r_fp.foreign_curr,         i_gewenste_muntsoort,   'B',                i_pr_id,
                                i_ppr_id,       i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);
              v_payment_initiations_vv := v_payment_initiations_vv + v_omgerekend_bedrag;
           end if;
        end loop;
     end;
  else
     select nvl(sum(f.amount_repc),0)
     into   v_payment_initiations
     from   fiat_payments f
     where (f.foreign_curr           = i_gewenste_muntsoort
            or
            i_act_balance_exclude_mc = 1);

  end if;

  if v_relatie_heeft_depots = 1
  then
     -- totaal van de dekkingswaarde en bijstelling bepalen
     if i_bedragen_in_vv = 1
     then
        declare
           cursor pwb is
           select p.pwb_fonds_valuta, sum(nvl(p.pwb_dekk_waarde_vv_sl,0)) as dekk_waarde_vv, sum(nvl(p.pwb_bijstell_vv,0)) as bijstell_vv
           from   positie_werkbestand p
           where  p.pwb_relatie_nummer  = i_relatienummer
           and    p.pwb_rekening_soort  between 1 and 999
           and   (p.pwb_fonds_valuta    = i_gewenste_muntsoort
                  or
                  i_coverage_exclude_mc = 1)
           group by p.pwb_fonds_valuta;
        begin
           for r_pwb in pwb
           loop
              if r_pwb.pwb_fonds_valuta = i_gewenste_muntsoort
              then
                 v_dekkingswaarde_effecten_vv := v_dekkingswaarde_effecten_vv + r_pwb.dekk_waarde_vv;
                 v_bijstelling_vv             := v_bijstelling_vv + r_pwb.bijstell_vv;
              else
                 v_omgerekend_bedrag := 0;
                 omrekenen_bedrag( r_pwb.dekk_waarde_vv, r_pwb.pwb_fonds_valuta,    i_gewenste_muntsoort,
                                   case when r_pwb.dekk_waarde_vv<=0 then 'B' else 'L' end,                 i_pr_id,
                                   i_ppr_id,             i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);
                 v_dekkingswaarde_effecten_vv := v_dekkingswaarde_effecten_vv + v_omgerekend_bedrag;

                 if r_pwb.bijstell_vv <> 0
                 then
                    v_omgerekend_bedrag := 0;
                    omrekenen_bedrag ( r_pwb.bijstell_vv, r_pwb.pwb_fonds_valuta,    i_gewenste_muntsoort,
                                       case when r_pwb.bijstell_vv<=0 then 'B' else 'L' end,                 i_pr_id,
                                       i_ppr_id,          i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);
                    v_bijstelling_vv := v_bijstelling_vv + v_omgerekend_bedrag;
                 end if;
              end if;
           end loop;
        end;
     else
        select nvl(sum(p.pwb_dekk_waarde_rapv),0),  nvl(sum(p.pwb_bijstell_rapv),0)
        into   v_dekkingswaarde_effecten,           v_bijstelling
        from   positie_werkbestand p
        where  p.pwb_relatie_nummer  = i_relatienummer
        and    p.pwb_rekening_soort  between 1 and 999
        and   (p.pwb_fonds_valuta    = i_gewenste_muntsoort
               or
               i_coverage_exclude_mc = 1);
     end if;

     if i_bedragen_in_vv = 1
     then
     -- geblokkeerde dekkingswaarde ivm cover en collateral gecombineerd met geblokkeerde dekkingswaarde ivm positie blokkade
        declare
           cursor fblv is
           select f.foreign_curr, f.blocked_type, sum(nvl(f.amount_fc_sl,0)) as amount_vv
           from   fiat_blocked_lending_value f
           where (f.foreign_curr        = i_gewenste_muntsoort
                  or
                  i_coverage_exclude_mc = 1)
           and    f.blocked_type        in ('Cover','Collateral','Geblokkeerd')
           group by f.foreign_curr, f.blocked_type;
        begin
           for r_fblv in fblv
           loop
              if r_fblv.foreign_curr = i_gewenste_muntsoort
              then
                 if r_fblv.blocked_type in ('Cover','Collateral')
                 then
                    v_dekkingswaarde_cov_coll_vv := v_dekkingswaarde_cov_coll_vv + r_fblv.amount_vv;
                 else
                    v_dekkingswaarde_geblokk_vv  := v_dekkingswaarde_geblokk_vv + r_fblv.amount_vv;
                 end if;
              else
                 v_omgerekend_bedrag := 0;
                 omrekenen_bedrag( r_fblv.amount_vv, r_fblv.foreign_curr,       i_gewenste_muntsoort,
                                   case when r_fblv.amount_vv<=0 then 'B' else 'L' end,                 i_pr_id,
                                   i_ppr_id,         i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);

                 if r_fblv.blocked_type in ('Cover','Collateral')
                 then
                    v_dekkingswaarde_cov_coll_vv := v_dekkingswaarde_cov_coll_vv + v_omgerekend_bedrag;
                 else
                    v_dekkingswaarde_geblokk_vv  := v_dekkingswaarde_geblokk_vv + v_omgerekend_bedrag;
                 end if;
              end if;
           end loop;
        end;
        -- beide dekkingssoorten bij elkaar optellen (maximeren)
        if v_dekkingswaarde_geblokk_vv + v_dekkingswaarde_cov_coll_vv > v_dekkingswaarde_geblokk_vv
        then
           v_dekkingswaarde_geblokk_vv := v_dekkingswaarde_geblokk_vv + v_dekkingswaarde_cov_coll_vv;
        end if;
     else
        -- geblokkeerde dekkingswaarde ivm cover en collateral
        select nvl(sum(f.amount_repc),0)
        into   v_dekkingswaarde_cov_coll
        from   fiat_blocked_lending_value f
        where (f.foreign_curr        = i_gewenste_muntsoort
               or
               i_coverage_exclude_mc = 1)
        and    f.blocked_type        in ('Cover','Collateral');

        -- geblokkeerde dekkingswaarde ivm positie blokkade
        select nvl(sum(f.amount_repc),0)
        into   v_dekkingswaarde_geblokk
        from   fiat_blocked_lending_value f
        where (f.foreign_curr        = i_gewenste_muntsoort
               or
               i_coverage_exclude_mc = 1)
        and    f.blocked_type        = 'Geblokkeerd';

        -- beide dekkingssoorten bij elkaar optellen (maximeren)
        if v_dekkingswaarde_geblokk + v_dekkingswaarde_cov_coll > v_dekkingswaarde_geblokk
        then
           v_dekkingswaarde_geblokk := v_dekkingswaarde_geblokk + v_dekkingswaarde_cov_coll;
        end if;
     end if;

     -- Berekening van de margin bedragen:
     declare
        cursor tms is
           select m.tms_relatienr,     m.tms_soort,           m.tms_margin_required,   m.tms_gecovered,
                  m.tms_spread_bedrag, m.tms_straddle_bedrag, m.tms_collateral_bedrag, m.tms_valuta,
                  m.tms_cross_bedrag,  m.tms_price_ratio_neg, m.tms_saldo_positie,     m.tms_positie_future
           from   temp_margin_wb_sessie m
           where  m.tms_relatienr     = i_terminalnummer
           and    m.tms_runnnummer    = 0                          -- Hier runnummer 0 omdat het de "normale" margin betreft
           and   (m.tms_valuta        = i_gewenste_muntsoort
                  or
                  i_margin_exclude_mc = 1);

     begin
        for r_tms in tms
        loop
           v_aantal_opties_futures := v_aantal_opties_futures + abs(r_tms.tms_positie_future) +
                                      case when r_tms.tms_saldo_positie < 0 then abs(r_tms.tms_saldo_positie) else 0 end;

           if i_bedragen_in_vv = 1
           then
              if r_tms.tms_valuta = i_gewenste_muntsoort
              then
                 v_margin_totaal_vv := v_margin_totaal_vv + r_tms.tms_margin_required + r_tms.tms_spread_bedrag + r_tms.tms_straddle_bedrag +
                                       r_tms.tms_cross_bedrag;

                 if r_tms.tms_soort = 'FUT'
                 then
                    v_margin_totaal_vv := v_margin_totaal_vv - r_tms.tms_collateral_bedrag;
                 else
                    v_collateral_vv    := v_collateral_vv + r_tms.tms_collateral_bedrag;
                 end if;
              else
                 v_omgerekend_bedrag := 0;
                 omrekenen_bedrag( r_tms.tms_margin_required + r_tms.tms_spread_bedrag + r_tms.tms_straddle_bedrag + r_tms.tms_cross_bedrag,
                                   r_tms.tms_valuta, i_gewenste_muntsoort,      'N',                    i_pr_id,
                                   i_ppr_id,         i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);
                 v_margin_totaal_vv := v_margin_totaal_vv + v_omgerekend_bedrag;

                 if r_tms.tms_collateral_bedrag <> 0
                 then
                    v_omgerekend_bedrag := 0;
                    omrekenen_bedrag( r_tms.tms_collateral_bedrag, r_tms.tms_valuta,          i_gewenste_muntsoort,   'N',                i_pr_id,
                                      i_ppr_id,                    i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);
                    if r_tms.tms_soort = 'FUT'
                    then
                       v_margin_totaal_vv := v_margin_totaal_vv - v_omgerekend_bedrag;
                    else
                       v_collateral_vv    := v_collateral_vv + v_omgerekend_bedrag;
                    end if;
                 end if;
              end if;
           else
              v_margin_totaal := v_margin_totaal + round(r_tms.tms_margin_required   * r_tms.tms_price_ratio_neg,v_rapp_valuta_notatie)
                                                 + round(r_tms.tms_spread_bedrag     * r_tms.tms_price_ratio_neg,v_rapp_valuta_notatie)
                                                 + round(r_tms.tms_straddle_bedrag   * r_tms.tms_price_ratio_neg,v_rapp_valuta_notatie)
                                                 + round(r_tms.tms_cross_bedrag      * r_tms.tms_price_ratio_neg,v_rapp_valuta_notatie);

              if r_tms.tms_soort = 'FUT'
              then
                 v_margin_totaal := v_margin_totaal - round(r_tms.tms_collateral_bedrag * r_tms.tms_price_ratio_neg,v_rapp_valuta_notatie);
              else
                 v_collateral    := v_collateral    + round(r_tms.tms_collateral_bedrag * r_tms.tms_price_ratio_neg,v_rapp_valuta_notatie);
              end if;
           end if;
        end loop;
     end;

     -- afsluitende berekeningen voor de marging
     if i_minim_verm_eis_inst <> 0 and v_aantal_opties_futures <> 0
     then
        if i_bedragen_in_vv = 1
        then
           v_margin_totaal_vv := v_margin_totaal_vv + i_minim_verm_eis_bedr * case when i_minim_verm_eis_inst = 2 then v_aantal_opties_futures else 1 end;
        else
           v_margin_totaal := v_margin_totaal + i_minim_verm_eis_bedr * case when i_minim_verm_eis_inst = 2 then v_aantal_opties_futures else 1 end;
        end if;
     end if;

     -- bepalen closing resultaat futures
     if i_bedragen_in_vv = 1
     then
        declare
           cursor forc is
           select f.foreign_curr, sum(nvl(f.amount_fc,0)) as amount_vv
           from   fiat_obligo_rec_coll f
           where  f.purpose_type           = 'OBGO'
           and    f.class_type             = 400
           and   (f.foreign_curr           = i_gewenste_muntsoort
                  or
                  i_obligations_exclude_mc = 1)
           group by f.foreign_curr;
        begin
           for r_forc in forc
           loop
              if r_forc.foreign_curr = i_gewenste_muntsoort
              then
                 v_closing_resultaat_vv := v_closing_resultaat_vv + r_forc.amount_vv;
              else
                 v_omgerekend_bedrag := 0;
                 omrekenen_bedrag( r_forc.amount_vv, r_forc.foreign_curr,       i_gewenste_muntsoort,   'N',               i_pr_id,
                                   i_ppr_id,         i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);
                 v_closing_resultaat_vv := v_closing_resultaat_vv + v_omgerekend_bedrag;
              end if;
           end loop;
        end;
     else
        select nvl(sum(f.amount_repc),0)
        into   v_closing_resultaat
        from   fiat_obligo_rec_coll f
        where (f.foreign_curr           = i_gewenste_muntsoort
               or
               i_obligations_exclude_mc = 1)
        and    f.purpose_type           = 'OBGO'
        and    f.class_type             = 400;
     end if;

     -- bepalen bedrag lopende orders
     if i_bedragen_in_vv = 1
     then
        declare
           cursor kw is
           select k.kst_rel1_rek2_munts, sum(nvl(k.kst_lopend_bedrag_rekv_sl,0)) as lopend_bedrag_vv
           from   kosten_werkbestand k
           where  k.kst_relatie_nummer  = i_relatienummer
           and    k.kst_ordernummer     > 0                  -- Niet de nieuwe huidige orders
           and   (k.kst_rel1_rek2_munts = i_gewenste_muntsoort
                  or
                  i_orders_exclude_mc   = 1)
           group by k.kst_rel1_rek2_munts;
        begin
           for r_kw in kw
           loop
              if r_kw.kst_rel1_rek2_munts = i_gewenste_muntsoort
              then
                 v_lopende_orders_vv := v_lopende_orders_vv + r_kw.lopend_bedrag_vv;
              else
                 v_omgerekend_bedrag := 0;
                 omrekenen_bedrag( r_kw.lopend_bedrag_vv, r_kw.kst_rel1_rek2_munts,  i_gewenste_muntsoort,   'M',               i_pr_id,
                                   i_ppr_id,              i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);
                 v_lopende_orders_vv := v_lopende_orders_vv + v_omgerekend_bedrag;
              end if;
           end loop;
        end;
     else
        select nvl(sum(k.kst_lopend_bedrag),0)
        into   v_lopende_orders
        from   kosten_werkbestand k
        where  k.kst_relatie_nummer  = i_relatienummer
        and   (k.kst_rel1_rek2_munts = i_gewenste_muntsoort
               or
               i_orders_exclude_mc   = 1)
        and    k.kst_ordernummer     > 0;                    -- Niet de nieuwe huidige orders
     end if;

     -- bepalen lopende beleggingsopdrachten
     if i_bedragen_in_vv = 1
     then
        declare
           cursor fcio is
           select f.foreign_curr, sum(nvl(f.amount_fc,0)) as amount_vv
           from   fiat_current_inv_orders f
           where (f.foreign_curr             = i_gewenste_muntsoort
                  or
                  i_invest_orders_exclude_mc = 1)
           group by f.foreign_curr;
        begin
           for r_fcio in fcio
           loop
              if r_fcio.foreign_curr = i_gewenste_muntsoort
              then
                 v_lopende_beleggingsopdr_vv := v_lopende_beleggingsopdr_vv + r_fcio.amount_vv;
              else
                 v_omgerekend_bedrag := 0;
                 omrekenen_bedrag( r_fcio.amount_vv, r_fcio.foreign_curr,       i_gewenste_muntsoort,   'N',                i_pr_id,
                                   i_ppr_id,         i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);
                 v_lopende_beleggingsopdr_vv := v_lopende_beleggingsopdr_vv + v_omgerekend_bedrag;
              end if;
           end loop;
        end;
     else
        select nvl(sum(f.amount_repc),0)
        into   v_lopende_beleggingsopdr
        from   fiat_current_inv_orders f
        where (f.foreign_curr             = i_gewenste_muntsoort
               or
               i_invest_orders_exclude_mc = 1);
     end if;
  end if;

  -- bepalen garanties en ontvangen zekerheden:
  if i_bedragen_in_vv = 1
  then
     declare
        cursor forc is
        select f.foreign_curr, sum(nvl(f.amount_fc,0)) as amount_vv
        from   fiat_obligo_rec_coll f
        where  f.purpose_type       = 'GARN'
        and   (f.foreign_curr       = i_gewenste_muntsoort
               or
               i_collateral_exclude_mc = 1)
        group by f.foreign_curr;
     begin
        for r_forc in forc
        loop
           if r_forc.foreign_curr = i_gewenste_muntsoort
           then
              v_ontvangen_zekerheden_vv := v_ontvangen_zekerheden_vv + r_forc.amount_vv;
           else
              v_omgerekend_bedrag := 0;
              omrekenen_bedrag( r_forc.amount_vv, r_forc.foreign_curr,       i_gewenste_muntsoort,   'L',               i_pr_id,
                                i_ppr_id,         i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);
              v_ontvangen_zekerheden_vv := v_ontvangen_zekerheden_vv + v_omgerekend_bedrag;
           end if;
        end loop;
     end;
  else
     select nvl(sum(f.amount_repc),0)
     into   v_ontvangen_zekerheden
     from   fiat_obligo_rec_coll f
     where (f.foreign_curr          = i_gewenste_muntsoort
            or
            i_collateral_exclude_mc = 1)
     and    f.purpose_type = 'GARN';
  end if;

  -- bepalen obligo's:
  if i_bedragen_in_vv = 1
  then
     declare
        cursor forc is
        select f.foreign_curr, sum(nvl(f.amount_fc,0)) as amount_vv
        from   fiat_obligo_rec_coll f
        where  f.purpose_type          = 'OBGO'
        and    f.class_type            <> 400
        and   (f.foreign_curr          = i_gewenste_muntsoort
               or
               i_obligations_exclude_mc = 1)
        group by f.foreign_curr;
     begin
        for r_forc in forc
        loop
           if r_forc.foreign_curr = i_gewenste_muntsoort
           then
              v_obligo_vv := v_obligo_vv + r_forc.amount_vv;
           else
              v_omgerekend_bedrag := 0;
              omrekenen_bedrag( r_forc.amount_vv, r_forc.foreign_curr,        i_gewenste_muntsoort,
                                case when r_forc.amount_vv<0 then 'B' else 'L' end,                  i_pr_id,
                                i_ppr_id,         i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);
              v_obligo_vv := v_obligo_vv + v_omgerekend_bedrag;
           end if;
        end loop;
     end;
  else
     select nvl(sum(f.amount_repc),0)
     into   v_obligo
     from   fiat_obligo_rec_coll f
     where (f.foreign_curr           = i_gewenste_muntsoort
            or
            i_obligations_exclude_mc = 1)
     and    f.purpose_type           = 'OBGO'
     and    f.class_type             <> 400;
  end if;

  -- bepalen negatieve rente:
  if i_negatieve_rente_bepalen = 1
  then
     if i_bedragen_in_vv = 1
     then
        declare
           cursor wb is
           select r.tdr_rekeningmunt, sum(nvl(case when w.wk_waarde_1>0 then 0 else w.wk_waarde_1 end,0) +
                                          nvl(case when w.wk_waarde_2<0 then 0 else -1 * w.wk_waarde_2 end,0)) as neg_rente_vv
           from   werkbestand w, te_doorlopen_rek r
           where  w.wk_terminal             = i_terminalnummer
           and    w.wk_soort                = 'NERE'
           and    w.wk_export               <> 1
           and    w.wk_categorie_1          = r.tdr_re_id
           and   (w.wk_waarde_1             < 0
                  or
                  w.wk_waarde_2             > 0)
           and   (r.tdr_rekeningmunt        = i_gewenste_muntsoort
                  or
                  i_neg_interest_exclude_mc = 1)
           group by r.tdr_rekeningmunt;
        begin
           for r_wb in wb
           loop
              if r_wb.tdr_rekeningmunt = i_gewenste_muntsoort
              then
                 v_negatieve_rente_vv := v_negatieve_rente_vv + r_wb.neg_rente_vv;
              else
                 v_omgerekend_bedrag := 0;
                 omrekenen_bedrag( r_wb.neg_rente_vv, r_wb.tdr_rekeningmunt,     i_gewenste_muntsoort,   'N',               i_pr_id,
                                   i_ppr_id,          i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);
                 v_negatieve_rente_vv := v_negatieve_rente_vv + v_omgerekend_bedrag;
              end if;
           end loop;
        end;
     else
       select nvl(sum(w.wk_waarde_3 + w.wk_waarde_4),0)
       into   v_negatieve_rente
       from   werkbestand w, te_doorlopen_rek r
       where  w.wk_terminal             = i_terminalnummer
       and    w.wk_soort                = 'NERE'
       and    w.wk_export               <> 1
       and    r.tdr_re_id               = w.wk_categorie_1
       and   (w.wk_waarde_1             < 0
              or
              w.wk_waarde_2             > 0)
       and   (r.tdr_rekeningmunt        = i_gewenste_muntsoort
              or
              i_neg_interest_exclude_mc = 1);
     end if;
  end if;

  -- bepalen voorvalutering:
  if i_voorvalutering_bepalen = 1
  then
     if i_bedragen_in_vv = 1
     then
        declare
           cursor wb is
           select w.wk_categorie_1, sum(nvl(w.wk_waarde_1,0)) as voorval_vv
           from   werkbestand w
           where  w.wk_terminal              = i_terminalnummer
           and    w.wk_soort                 = 'VRVL'
           and   (w.wk_categorie_1           = i_gewenste_muntsoort
                  or
                  i_value_dat_amn_exclude_mc = 1)
           group by w.wk_categorie_1;
        begin
           for r_wb in wb
           loop
              if r_wb.wk_categorie_1 = i_gewenste_muntsoort
              then
                 v_voorvalutering_vv := v_voorvalutering_vv + r_wb.voorval_vv;
              else
                 v_omgerekend_bedrag := 0;
                 omrekenen_bedrag( r_wb.voorval_vv, r_wb.wk_categorie_1,       i_gewenste_muntsoort,   'N',               i_pr_id,
                                   i_ppr_id,        i_systspreadcodecategorie, i_bank2mrktqchangedate, v_omgerekend_bedrag);
                 v_voorvalutering_vv := v_voorvalutering_vv + v_omgerekend_bedrag;
              end if;
           end loop;
        end;
     else
        select nvl(sum( w.wk_waarde_2),0)
        into   v_voorvalutering
        from   werkbestand w
        where  w.wk_terminal              = i_terminalnummer
        and    w.wk_soort                 = 'VRVL'
        and   (w.wk_categorie_1           = i_gewenste_muntsoort
               or
               i_value_dat_amn_exclude_mc = 1);
     end if;
  end if;

  -- Voorvalutering en de laatst berekende margin hebben geen invloed op de bestedingsruimte
  -- en worden daarom hier ook niet bepaald ongeacht van de bijbehorende instellingen

  -- als laatste de berekende gegevens opslaan
  if i_bedragen_in_vv = 1
  then
     insert into fiattering_bedragen f
     (f.fb_relatie_nummer,            f.fb_datum,                  f.fb_tijd,
      f.fb_geld_saldo,                f.fb_geld_geblokkeerd,       
      f.fb_dekkw_effecten,            f.fb_dekkw_geblokkeerd,      f.fb_collateral,
      f.fb_margin_totaal,             f.fb_ontvangen_garanties,    f.fb_obligo,
      f.fb_lopende_orders,            f.fb_closing_resultaat,      f.fb_bijstelling,
      f.fb_voorvalutering,            f.fb_laatst_ber_margin,      f.fb_lopende_belegopdrachten,
      f.fb_geld_geblok_bedr_spaar,    f.fb_geld_geblok_overig,
      f.fb_negatieve_rente_bedr,      f.fb_totaal_paym_init,
      f.fb_valuta)
     values
     (i_relatienummer,                to_char(sysdate,'yyyymmdd'), to_char(sysdate,'HH24MISS'),
      v_geldsaldo_vv,                 v_geldsaldo_geblokkeerd_vv,  
      v_dekkingswaarde_effecten_vv,   v_dekkingswaarde_geblokk_vv, v_collateral_vv,
      v_margin_totaal_vv,             v_ontvangen_zekerheden_vv,   v_obligo_vv,
      v_lopende_orders_vv,            v_closing_resultaat_vv,      v_bijstelling_vv,
      v_voorvalutering_vv,            0,                           v_lopende_beleggingsopdr_vv,
      v_bedrijfspaar_geld_geblokk_vv, v_overig_geld_geblokk_vv,
      v_negatieve_rente_vv,           v_payment_initiations_vv,
      i_gewenste_muntsoort);
  else
     insert into fiattering_bedragen f
     (f.fb_relatie_nummer,         f.fb_datum,                  f.fb_tijd,
      f.fb_geld_saldo,             f.fb_geld_geblokkeerd,       
      f.fb_dekkw_effecten,         f.fb_dekkw_geblokkeerd,      f.fb_collateral,
      f.fb_margin_totaal,          f.fb_ontvangen_garanties,    f.fb_obligo,
      f.fb_lopende_orders,         f.fb_closing_resultaat,      f.fb_bijstelling,
      f.fb_voorvalutering,         f.fb_laatst_ber_margin,      f.fb_lopende_belegopdrachten,
      f.fb_geld_geblok_bedr_spaar, f.fb_geld_geblok_overig,
      f.fb_negatieve_rente_bedr,   f.fb_totaal_paym_init,
      f.fb_valuta)
     values
     (i_relatienummer,             to_char(sysdate,'yyyymmdd'), to_char(sysdate,'HH24MISS'),
      v_geldsaldo,                 v_geldsaldo_geblokkeerd,     
      v_dekkingswaarde_effecten,   v_dekkingswaarde_geblokk,    v_collateral,
      v_margin_totaal,             v_ontvangen_zekerheden,      v_obligo,
      v_lopende_orders,            v_closing_resultaat,         v_bijstelling,
      v_voorvalutering,            0,                           v_lopende_beleggingsopdr,
      v_bedrijfspaar_geld_geblokk, v_overig_geld_geblokk, 
      v_negatieve_rente,           v_payment_initiations,
      i_gewenste_muntsoort);
  end if;

end herbereken_totalen;
-- EINDE CODE PROCEDURE HERBEREKEN_TOTALEN


-- DE CODE VOOR DE PROCEDURE RELATIE_OPRUIM:
-- procedure die vanuit Magic wordt aangeroepen om gegevens te verwijderen.
procedure relatie_opruim
(i_term_nummer            in werkbestand.wk_terminal%type
,i_alles_verwijderen      in number
,i_geen_commit_uitvoeren  in number
)

-- Inkomende parameters zijn i_term_nummer           = Terminalnummer waarvoor de gegevens zijn verzameld.
--                           i_alles_verwijderen     = Een vlag om te voorkomen dat de orderdetailgegevens
--                                                     verwijderd worden (1 = alles verwijderen,
--                                                     0 = DET1, DET2 en DET3 gegevens laten staan
--                                                     en de toegevoegde huidige order gegevens laten staan).
--                           i_geen_commit_uitvoeren = Waardes 1 en <> 1: 1 = Geen commit uitvoeren
--                                                     <> 1 is commit uitvoeren


is

begin
     delete relatie_fiattering;
     delete fiattering_bedragen;
     delete geld_werkbestand;
     delete positie_werkbestand;

     if i_alles_verwijderen = 0
     then
        delete werkbestand w
        where  w.wk_terminal = i_term_nummer
        and    (w.wk_soort   = 'BIJS' or
                w.wk_soort   = 'BOLW' or
                w.wk_soort   = 'CALI' or
                w.wk_soort   = 'CALW' or
                w.wk_soort   = 'COVR' or   -- hier geen DET1, DET2 en DET3
                w.wk_soort   = 'MARG' or
                w.wk_soort   = 'TGBG' or
                w.wk_soort   = 'TGBS' or
                w.wk_soort   = 'TRGL' or
                w.wk_soort   = 'TRPO' or
                w.wk_soort   = 'BOTA' or
                w.wk_soort   = 'OREP' or
                w.wk_soort   = 'OREF' or
                w.wk_soort   = 'ORDC' or
                w.wk_soort   = 'NERE' or
                w.wk_soort   = 'ERRM' or
                w.wk_soort   = 'VRVL');
      else
        delete werkbestand w
        where  w.wk_terminal = i_term_nummer
        and    (w.wk_soort   = 'BIJS' or
                w.wk_soort   = 'BOLW' or
                w.wk_soort   = 'CALI' or
                w.wk_soort   = 'CALW' or
                w.wk_soort   = 'COVR' or
                w.wk_soort   = 'DET1' or    -- hier wel DET1
                w.wk_soort   = 'DET2' or    -- hier wel DET2
                w.wk_soort   = 'DET3' or    -- hier wel DET3
                w.wk_soort   = 'MARG' or
                w.wk_soort   = 'TGBG' or
                w.wk_soort   = 'TGBS' or
                w.wk_soort   = 'TRGL' or
                w.wk_soort   = 'TRPO' or
                w.wk_soort   = 'BOTA' or
                w.wk_soort   = 'OREP' or
                w.wk_soort   = 'OREF' or
                w.wk_soort   = 'ORDC' or
                w.wk_soort   = 'NERE' or
                w.wk_soort   = 'ERRM' or
                w.wk_soort   = 'VRVL');

     end if;

     if i_alles_verwijderen = 0
     then
        delete kosten_werkbestand k
        where  k.kst_ordernummer <> -1;

        delete fiat_order_costs_det f
        where  f.focd_order_number <> -1;
     else
        delete kosten_werkbestand;
        delete fiat_order_costs_det;
     end if;

     delete temp_margin_wb_sessie m
     where  m.tms_relatienr = i_term_nummer;

     delete temp_ap_werkbest_sessie a
     where  a.tas_relatienr = i_term_nummer;

     delete te_doorlopen_rek;
     delete fiat_muntsoorten;
     delete fiat_tax_register;
     delete fiat_blocked_cash;
     delete fiat_payments;
     delete fiat_obligo_rec_coll;
     delete fiat_current_inv_orders;
     delete fiat_blocked_lending_value;
     delete fiat_reservations;
     delete special_ca_tax_exclusions;

     if i_geen_commit_uitvoeren  <> 1
     then
        commit;
     end if;

end relatie_opruim;
-- EINDE CODE PROCEDURE RELATIE_OPRUIM


-- DE CODE VOOR DE PROCEDURE GEGEVENS_AANWEZIG
procedure gegevens_aanwezig
(i_soort_gegeven      in   clienten.cl_blokkade_soort%type    -- Dit type is gekozen voor zijn picture
,i_relatienr          in   clienten.cl_nummer%type
,i_termnr             in   werkbestand.wk_terminal%type
,o_geg_aanwezig       out  clienten.cl_relatie_type%type      -- Dit type is gekozen voor zijn picture
)

/*------------------------------------------------------------------------------
Procedure   : gegevens_aanwezig
description : Met behulp van deze procedure wordt bepaalt of er gegevens zijn die
              getoont kunnen worden. De oude methode van het controleren of het
              totale bedrag van een onderdeel <> 0 is, is niet sluitend omdat er
              soms toch gegevens zijn maar opgeteld de gegevens 0 opleveren. Door
              echt te checken of data aanwezig is, is dit te voorkomen.
author      : Syntel Financial Software, Jan Jans Wolthuis
code        : 5840-FIATTE
history     : 20-APR-2006, JJW import vanuit epp40binck schema
------------------------------------------------------------------------------*/

-- De inkomende parameters zijn: i_soort_gegeven: een nummer wat aangeeft voor welk onderdeel moet worden bekeken of
--                                                er iets in de tabel staat
--                               i_relatienr:     De relatie waarvoor de bestedingsruimte is opgestart
--                               i_termnr:        Het terminalnummer waarmee de berekeningen zijn uitgevoerd
-- De uitgaande parameters zijn: o_geg_aanwezig:  Een 1 geeft aan dat er gegevens zijn, een 0 geeft aan dat er geen
--                                                gegevens zijn voor het gevraagde soort gegeven

is

   v_dummy_num_result      float;
   v_dummy_varchar_result  varchar2(40);

begin

   -- Voor de zekerheid aangeven dat er gegevens zijn:
   o_geg_aanwezig := 1;

   -- De volgende soort gegevens kunnen gevraagd worden:
   --  1:  Geldrekeningen (gaat via bestand GELD_WERKBESTAND)
   --  2:  Geblokkeerd geld (gaat via bestand GEBLOKKEERDE_POSITIE, onder condities)
   --  3:  Payments/Reservation voor geld (gaat via bestand fiat_payments/gaat via fiat_reservations)
   --  4:  Lopende orders (gaat via bestand KOSTEN_WERKBESTAND)
   --  5:  Dekkingswaarde van stukken (gaat via bestand POSITIE_WERKBESTAND)
   --  6:  Geblokkeerde dekkingswaarde van stukken (gaat via WERKBESTAND, met soort DEKK of GEBL)
   --  7:  Baisseposities (gaat via bestand POSITIE_WERKBESTAND, onder conditie)
   --  8:  Margingegevens (gaat via bestand MARGIN_WB_SESSIE, onder conditie)
   --  9:  Obligogegevens (gaat via bestand WERKBESTAND, met soort OBGO, onder conditie)
   -- 10:  Futuregegevens (gaat via bestand WERKBESTAND, met soort BIJS en OBGO, onder conditie)
   -- 11:  Garanties ontvangen (gaat via bestand WERKBESTAND, met soort GARN)
   -- 12:  Lopende Beleggingsopdrachten/Reservations (gaat via bestand fiat_current_inv_orders/gaat via fiat_reservations)
   -- 13:  Negatieve rente (gaat via bestand WERKBESTAND, met soort NERE)

   if i_soort_gegeven = 1
   then
      begin
         select g.gwb_intern_extern
         into   v_dummy_varchar_result
         from   geld_werkbestand g
         where  g.gwb_relatie_nummer     =  i_relatienr
         and    (g.gwb_saldo_vv          <> 0
                 or
                 g.gwb_kredietlimiet_vv  <> 0
                 or
                 g.gwb_overige_ruimte_vv <> 0
                 or
                 g.gwb_trans_mut_vv      <> 0)
         and    rownum                   <= 1;

      exception
         when no_data_found
         then
            o_geg_aanwezig := 0;

      end;

   elsif i_soort_gegeven = 2
   then
      begin
         select g.bpos_categorie
         into   v_dummy_num_result
         from   geblokkeerde_positie g, te_doorlopen_rek t
         where  g.bpos_categorie      = 1
         and    g.bpos_relatienr      = i_relatienr
         and    g.bpos_blokkeringsrt  <= 4999
         and    g.bpos_rekeningsoort  >= 1000
         and    (g.bpos_vervaldatum   >= to_char(sysdate,'yyyymmdd')
                 or
                 g.bpos_vervaldatum   = '00000000')
         and    g.bpos_rekeningnr     = t.tdr_rekeningnr
         and    g.bpos_rekeningsoort  = t.tdr_rekeningsoort
         and    g.bpos_rekeningmuntsr = t.tdr_rekeningmunt
         and    rownum                <= 1;

      exception
         when no_data_found
         then
            o_geg_aanwezig := 0;

      end;

   elsif i_soort_gegeven in (3,6,9,10,11,12,13)
   then
      begin
         if i_soort_gegeven = 3
         then
            select *
            into   v_dummy_varchar_result
            from   (select f.foreign_curr
                    from   fiat_payments f
                    where  rownum      <= 1
                    union
                    select r.currency
                    from   fiat_reservations r
                    where  r.sl_post   = 3
                    and    rownum      <= 1
                    )
            where rownum <= 1;

         elsif i_soort_gegeven = 6
         then
            select f.foreign_curr
            into   v_dummy_varchar_result
            from   fiat_blocked_lending_value f
            where  rownum        <= 1;

         elsif i_soort_gegeven = 9
         then
            select f.foreign_curr
            into   v_dummy_varchar_result
            from   fiat_obligo_rec_coll f
            where  f.amount_fc   <> 0
            and    (f.class_type = 400
                    or
                    f.class_type between 9001 and 9999)
            and    rownum        <= 1;

         elsif i_soort_gegeven = 10
         then
            select f.foreign_curr
            into   v_dummy_varchar_result
            from   fiat_obligo_rec_coll f
            where  f.class_type   = 400
            and    rownum         <= 1;

         elsif i_soort_gegeven = 11
         then
            select f.foreign_curr
            into   v_dummy_varchar_result
            from   fiat_obligo_rec_coll f
            where  f.purpose_type = 'GARN'
            and    rownum         <= 1;

         elsif i_soort_gegeven = 12
         then
            select *
            into   v_dummy_varchar_result
            from   (select f.foreign_curr
                    from   fiat_current_inv_orders f
                    where  rownum    <= 1
                    union
                    select r.currency
                    from   fiat_reservations r
                    where  r.sl_post = 11
                    and    rownum    <= 1
                   )
            where  rownum <= 1;

         elsif i_soort_gegeven = 13
         then
            select w.wk_soort
            into   v_dummy_varchar_result
            from   werkbestand w
            where  w.wk_terminal = i_termnr
            and    w.wk_soort = 'NERE'
            and    rownum <=1;
         end if;

      exception
         when no_data_found
         then
            o_geg_aanwezig := 0;

      end;

   elsif i_soort_gegeven = 4
   then
      begin
         select k.kst_notabedrag
         into   v_dummy_num_result
         from   kosten_werkbestand k
         where  k.kst_relatie_nummer = i_relatienr
         and    k.kst_ordernummer    >= 1
         and    rownum               <= 1;

      exception
         when no_data_found
         then
            o_geg_aanwezig := 0;

      end;

   elsif i_soort_gegeven in (5,7)
   then
      begin
         if i_soort_gegeven = 5
         then
            select p.pwb_port_waarde_rapv
            into   v_dummy_num_result
            from   positie_werkbestand p
            where  p.pwb_relatie_nummer =  i_relatienr
            and    p.pwb_rekening_soort between 1 and 999
            and    rownum               <= 1;
         else
            select p.pwb_port_waarde_rapv
            into   v_dummy_num_result
            from   positie_werkbestand p
            where  p.pwb_relatie_nummer   =  i_relatienr
            and    p.pwb_rekening_soort   between 100 and 999
            and    p.pwb_optietype        = ' '
            and    p.pwb_expiratiedatum   = '00000000'
            and    p.pwb_exerciseprijs    = 0
            and    p.pwb_werk_aantal_port <= -1
            and    rownum                 <= 1;
         end if;

      exception
         when no_data_found
         then
            o_geg_aanwezig := 0;

      end;

   elsif i_soort_gegeven = 8
   then
      begin
         select m.tms_relatienr
         into   v_dummy_num_result
         from   temp_margin_wb_sessie m
         where  m.tms_relatienr  = i_termnr
         and    m.tms_runnnummer = 0
         and    (m.tms_soort in ('CALL','PUT') and m.tms_saldo_positie <> 0
                 or
                 m.tms_soort = 'FUT' and m.tms_positie_future<>0)
         and    rownum           <= 1;

      exception
         when no_data_found
         then
            o_geg_aanwezig := 0;

      end;

   end if;

end gegevens_aanwezig;
-- EINDE CODE PROCEDURE GEGEVENS_AANWEZIG


-- DE CODE VOOR DE PROCEDURE BEST_COMP_HISTORISEREN
procedure best_comp_historiseren
(i_relatienr_vanaf    in   clienten.cl_nummer%type
,i_relatienr_tm       in   clienten.cl_nummer%type
,i_productnr_vanaf    in   producten.pr_productnummer%type
,i_productnr_tm       in   producten.pr_productnummer%type
,i_terminalnr         in   werkbestand.wk_terminal%type)

/*------------------------------------------------------------------------------
Procedure   : best_comp_historiseren
description : Met behulp van deze procedure worden de gegevens die zijn berekend
              gehistoriseerd of uit de detailbestanden verwijderd.
              Aan de hand van de doorgegeven instellingen en selectiecriteria
              worden in 1 keer de gegevens gekopieerd en uit de diverse
              detailtabellen verwijderd.
author      : Syntel Financial Software, Jan Jans Wolthuis
code        : 5813-53944-0002
history     : 13-OKT-2011, JJW
------------------------------------------------------------------------------*/

is
  -- hier de selectie van de relaties en producten uit de voorselectie
  cursor wk is
  select w.wk_categorie_1, w.wk_categorie_2, w.wk_categorie_3
  from   werkbestand w
  where  w.wk_terminal      = i_terminalnr
  and    w.wk_soort         = 'GBCP'
  and    w.wk_categorie_1   between to_char(i_relatienr_vanaf,'999999999') and to_char(i_relatienr_tm,'999999999')
  and    w.wk_categorie_2   between to_char(i_productnr_vanaf,'9999') and to_char(i_productnr_tm,'9999');


begin

  for r_wk in wk
  loop
     -- Stap 1. kopieren van de vorig berekende gegevens naar de historische tabel:
     insert into best_comp_historisch b
     (b.bch_relatie_nummer,            b.bch_productnummer,           b.bch_product_volgnummer,
      b.bch_rapportage_valuta,         b.bch_datum,                   b.bch_tijd,
      b.bch_geld_saldo,                b.bch_geld_geblokkeerd,        b.bch_betalingsopdr_geblok,
      b.bch_dekkw_effecten,            b.bch_dekkw_geblokkeerd,       b.bch_collateral,
      b.bch_margin_totaal,             b.bch_ontvangen_garanties,     b.bch_obligo,
      b.bch_lopende_orders,            b.bch_closing_resultaat,       b.bch_bijstelling,
      b.bch_lopende_belegopdrachten,   b.bch_ruimte_kredietgroep,     b.bch_correctie_kredietlimiet,
      b.bch_bestedingsruimte,          b.bch_fout_opgetreden,         b.bch_geld_geblok_bedr_spaar,
      b.bch_geld_geblok_overig,        b.bch_betalingsopdr_bedrspaar, b.bch_betalingsopdr_overig,
      b.bch_waarde_effecten,           b.bch_baisse_margin,           b.bch_oorspr_dekkingswaarde,
      b.bch_oorspr_gebl_dekkingsw,     b.bch_oorspr_lopende_orders,   b.bch_vrij_tegoed,
      b.bch_best_ruimte_geblok_tegoed, b.bch_best_ruimte_vrij_tegoed, b.bch_negatieve_rente)
     select
      bc.bc_relatie_nummer,            bc.bc_productnummer,           bc.bc_product_volgnummer,
      bc.bc_rapportage_valuta,         bc.bc_datum,                   bc.bc_tijd,
      bc.bc_geld_saldo,                bc.bc_geld_geblokkeerd,        bc.bc_betalingsopdr_geblok,
      bc.bc_dekkw_effecten,            bc.bc_dekkw_geblokkeerd,       bc.bc_collateral,
      bc.bc_margin_totaal,             bc.bc_ontvangen_garanties,     bc.bc_obligo,
      bc.bc_lopende_orders,            bc.bc_closing_resultaat,       bc.bc_bijstelling,
      bc.bc_lopende_belegopdrachten,   bc.bc_ruimte_kredietgroep,     bc.bc_correctie_kredietlimiet,
      bc.bc_bestedingsruimte,          bc.bc_fout_opgetreden,         bc.bc_geld_geblok_bedr_spaar,
      bc.bc_geld_geblok_overig,        bc.bc_betalingsopdr_bedrspaar, bc.bc_betalingsopdr_overig,
      bc.bc_waarde_effecten,           bc.bc_baisse_margin,           bc.bc_oorspr_dekkingswaarde,
      bc.bc_oorspr_gebl_dekkingsw,     bc.bc_oorspr_lopende_orders,   bc.bc_vrij_tegoed,
      bc.bc_best_ruimte_geblok_tegoed, bc.bc_best_ruimte_vrij_tegoed, bc.bc_negatieve_rente
     from   bestedingsruimte_componenten bc
     where  bc.bc_relatie_nummer     = to_char(r_wk.wk_categorie_1,'999999999')
     and    bc.bc_productnummer      = to_char(r_wk.wk_categorie_2,'9999')
     and    bc.bc_product_volgnummer = to_char(r_wk.wk_categorie_3,'9999');


     -- Stap 2. Verwijderen van de gekopieerde gegevens uit de actuele tabel
     delete from bestedingsruimte_componenten bc
     where  bc.bc_relatie_nummer     = to_char(r_wk.wk_categorie_1,'999999999')
     and    bc.bc_productnummer      = to_char(r_wk.wk_categorie_2,'9999')
     and    bc.bc_product_volgnummer = to_char(r_wk.wk_categorie_3,'9999');


     -- Stap 3. Verwijderen van de gegevens uit de detailtabellen
     delete from bestedingsruimte_geldsaldo b
     where  b.bgld_relatie_nummer     = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bgld_productnummer      = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bgld_product_volgnummer = to_char(r_wk.wk_categorie_3,'9999');

     delete from bestedingsruimte_gebl_geld b
     where  b.bgg_relatie_nummer      = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bgg_productnummer       = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bgg_product_volgnummer  = to_char(r_wk.wk_categorie_3,'9999');

     delete from bestedingsruimte_betalingen b
     where  b.bbt_relatienr           = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bbt_productnummer       = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bbt_product_volgnummer  = to_char(r_wk.wk_categorie_3,'9999');

     delete from bestedingsruimte_dekking b
     where  b.bdek_relatie_nummer     = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bdek_productnummer      = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bdek_product_volgnummer = to_char(r_wk.wk_categorie_3,'9999');

     delete from bestedingsruimte_aktuele_pos b
     where  b.bakp_relatie_nummer     = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bakp_productnummer      = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bakp_product_volgnummer = to_char(r_wk.wk_categorie_3,'9999');

     delete from bestedingsruimte_dekkinggebl b
     where  b.bdgb_relatienr          = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bdgb_productnummer      = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bdgb_product_volgnummer = to_char(r_wk.wk_categorie_3,'9999');

     delete from bestedingsruimte_orders b
     where  b.bord_relatienummer      = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bord_productnummer      = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bord_product_volgnummer = to_char(r_wk.wk_categorie_3,'9999');

     delete from bestedingsruimte_margin b
     where  b.bmar_relatienr          = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bmar_productnummer      = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bmar_product_volgnummer = to_char(r_wk.wk_categorie_3,'9999');

     delete from bestedingsruimte_obligo b
     where  b.bobl_relatienr          = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bobl_productnummer      = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bobl_product_volgnummer = to_char(r_wk.wk_categorie_3,'9999');

     delete from bestedingsruimte_ontvangzekh b
     where  b.bzek_relatienr          = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bzek_productnummer      = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bzek_product_volgnummer = to_char(r_wk.wk_categorie_3,'9999');

     delete from bestedingsruimte_belopdr b
     where  b.bbop_relatienr          = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bbop_productnummer      = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bbop_product_volgnummer = to_char(r_wk.wk_categorie_3,'9999');

     delete from bestedingsruimte_neg_rente b
     where  b.bngr_relatienr          = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bngr_productnummer      = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bngr_product_volgnummer = to_char(r_wk.wk_categorie_3,'9999');

     delete from bestedingsruimte_muntsoorten b
     where  b.bdmu_relatienr          = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bdmu_productnummer      = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bdmu_product_volgnummer = to_char(r_wk.wk_categorie_3,'9999');

     delete from bestedingsruimte_ord_cost_det b
     where  b.bocd_relation_number    = to_char(r_wk.wk_categorie_1,'999999999')
     and    b.bocd_productnumber      = to_char(r_wk.wk_categorie_2,'9999')
     and    b.bocd_product_ser_numb   = to_char(r_wk.wk_categorie_3,'9999');

  end loop;

  commit;

end best_comp_historiseren;
-- EINDE CODE PROCEDURE BEST_COMP_HISTORISEREN


-- DE CODE VOOR PROCEDURE BEST_COMP_WEGSCHRIJVEN
procedure best_comp_wegschrijven
(i_relatienummer              in   bestedingsruimte_componenten.bc_relatie_nummer%type
,i_productnummer              in   bestedingsruimte_componenten.bc_productnummer%type
,i_productvolgnummer          in   bestedingsruimte_componenten.bc_product_volgnummer%type
,i_terminalnummer             in   werkbestand.wk_terminal%type
,i_rapportage_valuta          in   bestedingsruimte_componenten.bc_rapportage_valuta%type
,i_bestedingsruimte           in   bestedingsruimte_componenten.bc_bestedingsruimte%type
,i_best_ruimte_geblok_tegoed  in   bestedingsruimte_componenten.bc_best_ruimte_geblok_tegoed%type
,i_best_ruimte_vrij_tegoed    in   bestedingsruimte_componenten.bc_best_ruimte_vrij_tegoed%type
,i_geldsaldo                  in   bestedingsruimte_componenten.bc_geld_saldo%type
,i_geldsaldo_geblokkeerd      in   bestedingsruimte_componenten.bc_geld_geblokkeerd%type
,i_bedrfspr_geblokk_geld      in   bestedingsruimte_componenten.bc_geld_geblok_bedr_spaar%type
,i_overige_geblokk_geld       in   bestedingsruimte_componenten.bc_geld_geblok_overig%type
,i_vrij_tegoed                in   bestedingsruimte_componenten.bc_vrij_tegoed%type
,i_betalingsopdrachten        in   bestedingsruimte_componenten.bc_betalingsopdr_geblok%type
,i_betalopdr_geblok_tegoed    in   bestedingsruimte_componenten.bc_betalingsopdr_bedrspaar%type
,i_betalopdr_vrij_tegoed      in   bestedingsruimte_componenten.bc_betalingsopdr_overig%type
,i_waarde_effecten            in   bestedingsruimte_componenten.bc_waarde_effecten%type
,i_dekkingswaarde_effecten    in   bestedingsruimte_componenten.bc_dekkw_effecten%type
,i_dekkingswaarde_geblokkeerd in   bestedingsruimte_componenten.bc_dekkw_geblokkeerd%type
,i_ontvangen_zekerheden       in   bestedingsruimte_componenten.bc_ontvangen_garanties%type
,i_lopende_orders             in   bestedingsruimte_componenten.bc_lopende_orders%type
,i_margin                     in   bestedingsruimte_componenten.bc_margin_totaal%type
,i_baisse_margin              in   bestedingsruimte_componenten.bc_baisse_margin%type
,i_obligos                    in   bestedingsruimte_componenten.bc_obligo%type
,i_negatieve_rente            in   bestedingsruimte_componenten.bc_negatieve_rente%type
,i_ruimte_kredietgrp          in   bestedingsruimte_componenten.bc_ruimte_kredietgroep%type
,i_kredietlimiet_corr         in   bestedingsruimte_componenten.bc_correctie_kredietlimiet%type
,i_lopende_belegg_opdrachten  in   bestedingsruimte_componenten.bc_lopende_belegopdrachten%type
,i_oorspr_dekkingswaarde      in   bestedingsruimte_componenten.bc_oorspr_dekkingswaarde%type
,i_oorspr_geblokk_dekk_waarde in   bestedingsruimte_componenten.bc_oorspr_gebl_dekkingsw%type
,i_oorspr_lopende_orders      in   bestedingsruimte_componenten.bc_oorspr_lopende_orders%type
,i_geen_commit_uitvoeren      in   number
)


/*------------------------------------------------------------------------------
Procedure   : best_comp_wegschrijven
description : Met behulp van deze procedure worden de gegevens die zijn berekend
              voor de bestedingsruimte componenten weggeschreven in de diverse
              (detail-)tabellen.
author      : Syntel Financial Software, Jan Jans Wolthuis
code        : 5813-53944-0002
history     : 13-OKT-2011, JJW
------------------------------------------------------------------------------*/

is
  v_weg_te_schrijven_datum     bestedingsruimte_componenten.bc_datum%type;
  v_weg_te_schrijven_tijd      bestedingsruimte_componenten.bc_tijd%type;
  v_fout_opgetreden            bestedingsruimte_componenten.bc_fout_opgetreden%type;

  v_datum_uit_best_ruimte      fiattering_bedragen.fb_datum%type;
  v_tijd_uit_best_ruimte       fiattering_bedragen.fb_tijd%type;

begin

  -- Stap 1. Bepalen of de datum en tijd gevuld is of dat er een fout is geweest
  select f.fb_datum,              f.fb_tijd
  into   v_datum_uit_best_ruimte, v_tijd_uit_best_ruimte
  from   fiattering_bedragen f
  where  f.fb_relatie_nummer = i_relatienummer;

  if nvl(v_datum_uit_best_ruimte,'00000000')='00000000' and nvl(v_tijd_uit_best_ruimte,'000000')='000000'
  then
     v_weg_te_schrijven_datum := to_char(sysdate,'yyyymmdd');
     v_weg_te_schrijven_tijd  := to_char(sysdate,'hhmiss');
     v_fout_opgetreden        := 1;
  else
     v_weg_te_schrijven_datum := v_datum_uit_best_ruimte;
     v_weg_te_schrijven_tijd  := v_tijd_uit_best_ruimte;
     v_fout_opgetreden        := 0;
  end if;

  -- Stap 2. Wegschrijven van de totalen
  -- Deze stap altijd uitvoeren. Er moet gelogd worden dat de berekening voor de rel/prod/prodvlnr is uitgevoerd.
  insert into bestedingsruimte_componenten b
  (b.bc_relatie_nummer,            b.bc_productnummer,            b.bc_product_volgnummer,
   b.bc_rapportage_valuta,         b.bc_datum,                    b.bc_tijd,
   b.bc_geld_saldo,                b.bc_geld_geblokkeerd,         b.bc_betalingsopdr_geblok,
   b.bc_dekkw_effecten,            b.bc_dekkw_geblokkeerd,        b.bc_collateral,
   b.bc_margin_totaal,             b.bc_ontvangen_garanties,      b.bc_obligo,
   b.bc_lopende_orders,            b.bc_closing_resultaat,        b.bc_bijstelling,
   b.bc_lopende_belegopdrachten,   b.bc_ruimte_kredietgroep,      b.bc_correctie_kredietlimiet,
   b.bc_bestedingsruimte,          b.bc_fout_opgetreden,          b.bc_geld_geblok_bedr_spaar,
   b.bc_geld_geblok_overig,        b.bc_betalingsopdr_bedrspaar,  b.bc_betalingsopdr_overig,
   b.bc_waarde_effecten,           b.bc_baisse_margin,            b.bc_oorspr_dekkingswaarde,
   b.bc_oorspr_gebl_dekkingsw,     b.bc_oorspr_lopende_orders,    b.bc_vrij_tegoed,
   b.bc_best_ruimte_geblok_tegoed, b.bc_best_ruimte_vrij_tegoed,  b.bc_negatieve_rente)
  values
  (i_relatienummer,                i_productnummer,               i_productvolgnummer,
   i_rapportage_valuta,            v_weg_te_schrijven_datum,      v_weg_te_schrijven_tijd,
   i_geldsaldo,                    i_geldsaldo_geblokkeerd,       i_betalingsopdrachten,
   i_dekkingswaarde_effecten,      i_dekkingswaarde_geblokkeerd,  0,
   i_margin,                       i_ontvangen_zekerheden,        i_obligos,
   i_lopende_orders,               0,                             0,
   i_lopende_belegg_opdrachten,    i_ruimte_kredietgrp,           i_kredietlimiet_corr,
   i_bestedingsruimte,             v_fout_opgetreden,             i_bedrfspr_geblokk_geld,
   i_overige_geblokk_geld,         i_betalopdr_geblok_tegoed,     i_betalopdr_vrij_tegoed,
   i_waarde_effecten,              i_baisse_margin,               i_oorspr_dekkingswaarde,
   i_oorspr_geblokk_dekk_waarde,   i_oorspr_lopende_orders,       i_vrij_tegoed,
   i_best_ruimte_geblok_tegoed,    i_best_ruimte_vrij_tegoed,     i_negatieve_rente
  );

  -- Stap 3. Overnemen van de detailgegevens
  -- Deze stap alleen uitvoeren als de totalen ongelijk aan 0 zijn. NB dit is niet helemaal sluitend, maar
  -- wel de snelste en makkelijkste manier om het onnodig doorlopen van dit deel te beperken.
  if i_bestedingsruimte          <> 0 or i_best_ruimte_geblok_tegoed  <> 0 or i_best_ruimte_vrij_tegoed    <> 0 or
     i_geldsaldo                 <> 0 or i_geldsaldo_geblokkeerd      <> 0 or i_bedrfspr_geblokk_geld      <> 0 or
     i_overige_geblokk_geld      <> 0 or i_vrij_tegoed                <> 0 or i_betalingsopdrachten        <> 0 or
     i_betalopdr_geblok_tegoed   <> 0 or i_betalopdr_vrij_tegoed      <> 0 or i_waarde_effecten            <> 0 or
     i_dekkingswaarde_effecten   <> 0 or i_dekkingswaarde_geblokkeerd <> 0 or i_ontvangen_zekerheden       <> 0 or
     i_lopende_orders            <> 0 or i_margin                     <> 0 or i_baisse_margin              <> 0 or
     i_obligos                   <> 0 or i_ruimte_kredietgrp          <> 0 or i_kredietlimiet_corr         <> 0 or
     i_lopende_belegg_opdrachten <> 0 or i_oorspr_dekkingswaarde      <> 0 or i_oorspr_geblokk_dekk_waarde <> 0 or
     i_oorspr_lopende_orders     <> 0 or i_negatieve_rente <> 0
  then

     -- Stap 3.1 Vullen van het bestand voor de geldsaldi gegevens
     insert into bestedingsruimte_geldsaldo g
    (g.bgld_relatie_nummer,        g.bgld_productnummer,       g.bgld_product_volgnummer,
     g.bgld_rekening_nummer,       g.bgld_rekening_soort,      g.bgld_rekening_munt,
     g.bgld_intern_extern,         g.bgld_saldo_vv,            g.bgld_kredietlimiet_vv,
     g.bgld_overige_ruimte_vv,     g.bgld_trans_mut_vv,        g.bgld_saldo_rapv,
     g.bgld_kredietlimiet_rapv,    g.bgld_overige_ruimte_rapv, g.bgld_trans_mut_rapv,
     g.bgld_rek_munt_weegperc_l,   g.bgld_rek_munt_weegperc_s, g.bgld_trans_mut_vv_sl,
     g.bgld_saldo_vv_sl)
     select
     gw.gwb_relatie_nummer,        i_productnummer,            i_productvolgnummer,
     gw.gwb_rekening_nummer,       gw.gwb_rekening_soort,      gw.gwb_rekening_munt,
     gw.gwb_intern_extern,         gw.gwb_saldo_vv,            gw.gwb_kredietlimiet_vv,
     gw.gwb_overige_ruimte_vv,     gw.gwb_trans_mut_vv,        gw.gwb_saldo_rapv,
     gw.gwb_kredietlimiet_rapv,    gw.gwb_overige_ruimte_rapv, gw.gwb_trans_mut_rapv,
     gw.gwb_rek_munt_weegperc_l,   gw.gwb_rek_munt_weegperc_s, gw.gwb_trans_mut_vv_sl,
     gw.gwb_saldo_vv_sl
     from  geld_werkbestand gw
     where gw.gwb_relatie_nummer = i_relatienummer;

     -- Stap 3.2 Vullen van het bestand voor de geblokkeerde geldsaldi gegevens
     insert into bestedingsruimte_gebl_geld g
    (g.bgg_relatie_nummer,                           g.bgg_productnummer,
     g.bgg_product_volgnummer,                       g.bgg_rekening_nummer,
     g.bgg_rekening_soort,                           g.bgg_rekening_munt,
     g.bgg_vervaldatum,
     g.bgg_bedrag_vv,                                g.bgg_bedrag_rapv,
     g.bgg_blokkeringsoort,                          g.bgg_amount_fc_sl,
     g.bgg_ingangsdatum)
     select
     i_relatienummer,                                i_productnummer,
     i_productvolgnummer,                            f.account_number,
     f.account_type,                                 f.account_currency,
     decode(f.expiration_date,'01-01-01','00000000', to_char(f.expiration_date,'YYYYMMDD')),
     f.amount_fc,                                    f.amount_repc,
     f.blocking_type,                                f.amount_fc_sl,
     decode(f.starting_date,  '01-01-01','00000000', to_char(f.starting_date,'YYYYMMDD'))
     from fiat_blocked_cash f;

     -- Stap 3.3 Vullen van het bestand voor de payment initiations gegevens
     insert into bestedingsruimte_betalingen b
     (b.bbt_relatienr,     b.bbt_productnummer, b.bbt_product_volgnummer,
      b.bbt_re_id,         b.bbt_datum,         b.bbt_transaction_id,
      b.bbt_muntsoort,     b.bbt_waarde_vv,     b.bbt_waarde_bv)
     select
      i_relatienummer,     i_productnummer,     i_productvolgnummer,
      f.account_id,        p.create_date,       f.transaction_id,
      f.foreign_curr,      f.amount_fc,         f.amount_repc
      from  fiat_payments f, payment_initiation p
      where f.transaction_id = p.transaction_id;

     -- Stap 3.4 Vullen van het bestand voor de positie gegevens
     insert into bestedingsruimte_dekking d
    (d.bdek_relatie_nummer,        d.bdek_productnummer,       d.bdek_product_volgnummer,
     d.bdek_rekening_nummer,       d.bdek_rekening_soort,      d.bdek_rekening_munt,
     d.bdek_symbool,               d.bdek_optietype,           d.bdek_expiratiedatum,
     d.bdek_exerciseprijs,         d.bdek_bi_type,             d.bdek_fonds_valuta,
     d.bdek_pricing_unit,          d.bdek_sld_losbaar,         d.bdek_hist_wrd_totbe,
     d.bdek_hist_wrd_posbe,        d.bdek_saldo_totaall_s,     d.bdek_biedk_symbool,
     d.bdek_laatk_symbool,         d.bdek_prijs_factor,        d.bdek_ref_symbool,
     d.bdek_margin_factor,         d.bdek_biedk_refsymb,       d.bdek_saldo_positie,
     d.bdek_trans_mut,             d.bdek_lopende_ord_aant,    d.bdek_werk_aantal_port,
     d.bdek_werk_aantal_marg,      d.bdek_trans_aanwezig,      d.bdek_effect_lop_ord,
     d.bdek_port_warde_vv,         d.bdek_init_margin_vv,      d.bdek_lopende_rente_vv,
     d.bdek_bjistell_vv,           d.bdek_waarborgsom_vv,      d.bdek_port_waarde_rapv,
     d.bdek_dekk_waarde_rapv,      d.bdek_bijstell_rapv,       d.bdek_dekk_waarde_vv_sl,
     d.bdek_oorsp_dekk_waarde_vv_sl)
     select
     p.pwb_relatie_nummer,         i_productnummer,            i_productvolgnummer,
     p.pwb_rekening_nummer,        p.pwb_rekening_soort,       ' ',
     p.pwb_symbool,                p.pwb_optietype,            p.pwb_expiratiedatum,
     p.pwb_exerciseprijs,          p.pwb_bi_type,              p.pwb_fonds_valuta,
     p.pwb_pricing_unit,           p.pwb_sld_losbaar,          p.pwb_hist_wrd_totbe,
     p.pwb_hist_wrd_posbe,         p.pwb_saldo_totaall_s,      p.pwb_biedk_symbool,
     p.pwb_laatk_symbool,          p.pwb_prijs_factor,         p.pwb_ref_symbool,
     p.pwb_margin_factor,          p.pwb_biedk_refsymb,        p.pwb_saldo_positie,
     p.pwb_trans_mut,              p.pwb_lopende_ord_aant,     p.pwb_werk_aantal_port,
     p.pwb_werk_aantal_marg,       p.pwb_trans_aanwezig,       p.pwb_effect_lop_ord,
     p.pwb_port_waarde_vv,         p.pwb_init_margin_vv,       p.pwb_lopende_rente_vv,
     p.pwb_bijstell_vv,            p.pwb_waarborgsom_vv,       p.pwb_port_waarde_rapv,
     p.pwb_dekk_waarde_rapv,       p.pwb_bijstell_rapv,        p.pwb_dekk_waarde_vv_sl,
     p.pwb_oorsp_dekk_waarde_vv_sl
     from  positie_werkbestand p
     where p.pwb_relatie_nummer = i_relatienummer;

     -- Stap 3.5 Vullen van het bestand voor de gegevens van de aktuele positie voor marginberekening
     insert into bestedingsruimte_aktuele_pos a
    (a.bakp_relatie_nummer,        a.bakp_productnummer,       a.bakp_product_volgnummer,
     a.bakp_terminalnummer,        a.bakp_runnummer,           a.bakp_rekening_soort,
     a.bakp_rekeningnr,            a.bakp_rekening_munts,      a.bakp_ref_symbool,
     a.bakp_symbool,               a.bakp_optietype,           a.bakp_expiratiedatum,
     a.bakp_exerciseprijs,         a.bakp_saldo_positie,       a.bakp_positie_future,
     a.bakp_hist_wrd_poscl,        a.bakp_hist_wrd_posbe,      a.bakp_hist_wrd_totcl,
     a.bakp_hist_wrd_totbe,        a.bakp_bi_type,             a.bakp_sld_losbaar_marg,
     a.bakp_in_cover,              a.bakp_in_cover_used,       a.bakp_in_collateral,
     a.bakp_tegenwaarde_basis,     a.bakp_export,              a.bakp_positie_long,
     a.bakp_positie_short,         a.bakp_collateral_used,     a.bakp_wegingsfactor,
     a.bakp_baisse_margin)
     select
     t.tas_ref_relatie,            i_productnummer,            i_productvolgnummer,
     t.tas_relatienr,              t.tas_runnummer,            t.tas_rekening_soort,
     t.tas_rekeningnr,             t.tas_rekening_munts,       t.tas_ref_symbool,
     t.tas_symbool,                t.tas_optietype,            t.tas_expiratiedatum,
     t.tas_exerciseprijs,          t.tas_saldo_positie,        t.tas_positie_future,
     t.tas_hist_wrd_poscl,         t.tas_hist_wrd_posbe,       t.tas_hist_wrd_totcl,
     t.tas_hist_wrd_totbe,         t.tas_bi_type,              t.tas_sld_losbaar_marg,
     t.tas_in_cover,               t.tas_in_cover_used,        t.tas_in_collateral,
     t.tas_tegenwaarde_basis,      t.tas_export,               t.tas_positie_long,
     t.tas_positie_short,          t.tas_collateral_used,      t.tas_wegingsfactor,
     t.tas_baisse_margin
     from  temp_ap_werkbest_sessie t
     where t.tas_ref_relatie = i_relatienummer;

     -- Stap 3.6 Vullen van het bestand voor de geblokkeerde positie gegevens
     insert into bestedingsruimte_dekkinggebl d
     (d.bdgb_relatienr,            d.bdgb_productnummer,        d.bdgb_product_volgnummer,
      d.bdgb_dekking_bedrag,       d.bdgb_dekking_depot,        d.bdgb_be_volgnummer,
      d.bdgb_dekking_aantal,
      d.bdgb_dekking_soort,        d.bdgb_amount_fc_sl)
     select
      i_relatienummer,             i_productnummer,             i_productvolgnummer,
      f.amount_repc,               f.account_nr,                f.instrument_id,
      case when b.be_aantal_cijfers_display <> 0 then f.quantity * b.be_prijs_factor else f.quantity end,
      f.blocked_type,              f.amount_fc_sl
      from  fiat_blocked_lending_value f, beleggingsinstrument b
      where f.instrument_id = b.be_volgnummer;

     -- Stap 3.7 Vullen van het bestand voor de order gegevens
     insert into bestedingsruimte_orders o
    (o.bord_relatienummer,          o.bord_productnummer,         o.bord_product_volgnummer,
     o.bord_ordernummer,            o.bord_orderregel,            o.bord_detailnummer,
     o.bord_ordertype,              o.bord_depot,                 o.bord_depotreksrt,
     o.bord_pr_nummer,              o.bord_gebr_stand_prvcat,     o.bord_min_prov_toepass,
     o.bord_fondssymbool,
     o.bord_optietype_fnds,         o.bord_expiratiedat_fnds,     o.bord_exercidepr_fnds,
     o.bord_fnds_nominaal,          o.bord_fnds_ex_ass_fac,       o.bord_provisie_cat_fnds,
     o.bord_bi_nummer,              o.bord_prijs_factor_fnds,     o.bord_omw_factor_fnds,
     o.bord_aantal_cijfers_disp,    o.bord_beursnummer,           o.bord_wegingsfactor,
     o.bord_ref_fondssymbool,       o.bord_ref_fnds_bi_nr,        o.bord_ref_fnds_prijs_f,
     o.bord_trans_indicatie,
     o.bord_trans_indicatie_n,      o.bord_trans_indicatie_w,     o.bord_trans_prijs,
     o.bord_trans_aantal,           o.bord_dekk_prijs,            o.bord_ord_notabedrag,
     o.bord_order_soort,            o.bord_limiet_toegestaan,     o.bord_order_limietprijs,
     o.bord_dt_cr_spread,           o.bord_combinatietype,        o.bord_ord_provperceffw,
     o.bord_ord_prov_absoluut,      o.bord_ord_prov_ps_bv,        o.bord_ord_provkort_perc,
     o.bord_ord_mutkosten_btw,      o.bord_ord_settl_kosten,      o.bord_effect_bedrag_bv,
     o.bord_effect_bedrag_rv,       o.bord_courtage_bedrag,       o.bord_trans_kort_bedrag,
     o.bord_trans_muntsrt,
     o.bord_standaard_land,         o.bord_distributiekanaal,     o.bord_gewoon_spoed_bet,
     o.bord_provisie_bedrag,        o.bord_prov_code_tabel,       o.bord_provisie_type,
     o.bord_vaste_kosten,           o.bord_variabele_kosten,      o.bord_kost_corr_doorb,
     o.bord_provisie_korting,       o.bord_mini_prov_t_bedr,      o.bord_max_prov_t_bedr,
     o.bord_prov_korting_perc,      o.bord_corr_naar_min_max,     o.bord_begin_pos_eff,
     o.bord_eind_pos_eff,           o.bord_notabedrag,            o.bord_dekkingswaarde,
     o.bord_marginbedrag,           o.bord_lopend_bedrag,         o.bord_op_te_heffen_eff,
     o.bord_order_keuze,            o.bord_effect_bedrag_rekv_sl, o.bord_notabedrag_rekv_sl,
     o.bord_dekkingswaarde_rekv_sl, o.bord_marginbedrag_rekv_sl,  o.bord_lopend_bedrag_rekv_sl)
     select
     i_relatienummer,               i_productnummer,              i_productvolgnummer,
     k.kst_ordernummer,             k.kst_orderregel,             k.kst_detailnummer,
     k.kst_ordertype,               k.kst_depot,                  k.kst_depotreksrt,
     k.kst_pr_nummer,               k.kst_gebr_stand_prvcat,      k.kst_min_prov_toepass,
     k.kst_fondssymbool,
     k.kst_optietype_fnds,          k.kst_expiratiedat_fnds,      k.kst_exercisepr_fnds,
     k.kst_fnds_nominaal,           k.kst_fnds_ex_ass_fac,        k.kst_provisie_cat_fnds,
     k.kst_bi_nummer,               k.kst_prijs_factor_fnds,      k.kst_omw_factor_fnds,
     k.kst_aantal_cijfers_disp,     k.kst_beursnummer,            k.kst_wegingsfactor,
     k.kst_ref_fondssymbool,        k.kst_ref_fnds_bi_nr,         k.kst_ref_fnds_prijs_f,
     k.kst_trans_indicatie,
     k.kst_trans_indicatie_n,       k.kst_trans_indicatie_w,      k.kst_trans_prijs,
     k.kst_trans_aantal,            k.kst_dekk_prijs,             k.kst_ord_notabedrag,
     k.kst_order_soort,             k.kst_limiet_toegestaan,      k.kst_order_limietprijs,
     k.kst_dt_cr_spread,            k.kst_combinatietype,         k.kst_ord_provperceffw,
     k.kst_ord_prov_absoluut,       k.kst_ord_prov_ps_bv,         k.kst_ord_provkort_perc,
     k.kst_ord_mutkosten_btw,       k.kst_ord_settl_kosten,       k.kst_effect_bedrag_bv,
     k.kst_effect_bedrag_rv,        k.kst_courtage_bedrag,        k.kst_trans_kort_bedrag,
     k.kst_trans_muntsrt,
     k.kst_standaard_land,          k.kst_distributiekanaal,      k.kst_gewoon_spoed_bet,
     k.kst_provisie_bedrag,         k.kst_prov_code_tabel,        k.kst_provisie_type,
     k.kst_vaste_kosten,            k.kst_variabele_kosten,       k.kst_kost_corr_doorb,
     k.kst_provisie_korting,        k.kst_mini_prov_t_bedr,       k.kst_max_prov_t_bedr,
     k.kst_prov_korting_perc,       k.kst_corr_naar_min_max,      k.kst_begin_pos_eff,
     k.kst_eind_pos_eff,            k.kst_notabedrag,             k.kst_dekkingswaarde,
     k.kst_marginbedrag,            k.kst_lopend_bedrag,          k.kst_op_te_heffen_eff,
     k.kst_order_keuze,             k.kst_effect_bedrag_rekv_sl,  k.kst_notabedrag_rekv_sl,
     k.kst_dekkingswaarde_rekv_sl,  k.kst_marginbedrag_rekv_sl,   k.kst_lopend_bedrag_rekv_sl
     from  kosten_werkbestand k
     where k.kst_ordernummer >= 1
     and   k.kst_orderregel  >= 1;

     -- Stap 3.8 Vullen van het bestand voor de marginberekening gegevens
     insert into bestedingsruimte_margin m
    (m.bmar_relatienr,             m.bmar_productnummer,       m.bmar_product_volgnummer,
     m.bmar_runnummer,             m.bmar_rekeningsoort,       m.bmar_rekeningnr,
     m.bmar_rekening_munts,        m.bmar_refsymbool,          m.bmar_symbool,
     m.bmar_soort,                 m.bmar_exp_datum,           m.bmar_exerciseprijs,
     m.bmar_saldo_positie,         m.bmar_positie_future,      m.bmar_prod_geblok_aantal,
     m.bmar_marginfactor,          m.bmar_slotkoers_voriged,   m.bmar_biedkoers,
     m.bmar_laatkoers,             m.bmar_blocksize,           m.bmar_margin_required,
     m.bmar_gecovered,             m.bmar_spread_aantal,       m.bmar_spread_bedrag,
     m.bmar_straddle_aantal,       m.bmar_straddle_bedrag,     m.bmar_valuta,
     m.bmar_collateral_bedrag,     m.bmar_pricing_unit,        m.bmar_cross_aantal,
     m.bmar_cross_bedrag,          m.bmar_gecovered_comp,      m.bmar_gecovered_com_bedrag)
     select
     i_relatienummer,              i_productnummer,            i_productvolgnummer,
     t.tms_runnnummer,             t.tms_rekeningsoort,        t.tms_rekeningnr,
     t.tms_rekening_munts,         t.tms_refsymbool,           t.tms_symbool,
     t.tms_soort,                  t.tms_exp_datum,            t.tms_exerciseprijs,
     t.tms_saldo_positie,          t.tms_positie_future,       t.tms_prod_geblok_aantal,
     t.tms_marginfactor,           t.tms_slotkoers_voriged,    t.tms_biedkoers,
     t.tms_laatkoers,              t.tms_blocksize,            t.tms_margin_required,
     t.tms_gecovered,              t.tms_spread_aantal,        t.tms_spread_bedrag,
     t.tms_straddle_aantal,        t.tms_straddle_bedrag,      t.tms_valuta,
     t.tms_collateral_bedrag,      t.tms_pricing_unit,         t.tms_cross_aantal,
     t.tms_cross_bedrag,           t.tms_gecovered_comp,       t.tms_gecovered_comp_bedrag
     from   temp_margin_wb_sessie t
     where t.tms_relatienr = i_terminalnummer;

     -- Stap 3.9 Vullen van het bestand voor de obligo gegevens
     insert into bestedingsruimte_obligo o
     (o.bobl_relatienr,                                o.bobl_productnummer,
      o.bobl_product_volgnummer,                       o.bobl_klassen,
      o.bobl_valuta,                                   o.bobl_bedrag_vv,
      o.bobl_bedrag_rapv,                              o.bobl_obligo_nummer,
      o.bobl_boek_vervaldatum,
      o.bobl_boektijd)
     select
      i_relatienummer,                                 i_productnummer,
      i_productvolgnummer,                             f.class_type,
      f.foreign_curr,                                  f.amount_fc,
      f.amount_repc,                                   f.internal_id,
      decode (to_char(f.book_date),'01-01-01','00000000',to_char(f.book_date,'YYYYMMDD')),
      decode (to_char(f.book_date),'01-01-01','000000',  to_char(f.book_date,'HH24MISS'))
      from  fiat_obligo_rec_coll f
      where f.purpose_type  = 'OBGO';

     -- Stap 3.10 Vullen van het bestand voor de ontvangen zekerheden gegevens
     insert into bestedingsruimte_ontvangzekh z
     (z.bzek_relatienr,                                  z.bzek_productnummer,
      z.bzek_product_volgnummer,                         z.bzek_klassen,
      z.bzek_valuta,                                     z.bzek_bedrag_vv,
      z.bzek_bedrag_rapv,                                z.bzek_zekerheid_nummer,
      z.bzek_vervaldatum)
     select
      i_relatienummer,                                   i_productnummer,
      i_productvolgnummer,                               f.class_type,
      f.foreign_curr,                                    f.amount_fc,
      f.amount_repc,                                     f.internal_id,
      decode (to_char(f.expiration_date),'01-01-01','00000000',to_char(f.expiration_date,'YYYYMMDD'))
      from  fiat_obligo_rec_coll f
      where f.purpose_type        = 'GARN';

     -- Stap 3.11 Vullen van het bestand voor de lopende beleggingsopdracht gegevens
     insert into bestedingsruimte_belopdr b
     (b.bbop_relatienr,      b.bbop_productnummer,        b.bbop_product_volgnummer,
      b.bbop_opdrachtnummer, b.bbop_opdrachttype,         b.bbop_muntsoort,
      b.bbop_bedrag_vv,      b.bbop_bedrag_rapv,          b.bbop_opdrachtstatus)
     select
      i_relatienummer,       i_productnummer,             i_productvolgnummer,
      f.inv_order_id,        f.inv_order_type,            f.foreign_curr,
      f.amount_fc,           f.amount_repc,               f.inv_order_status
     from  fiat_current_inv_orders f;

     -- Stap 3.12 Vullen van het bestand voor de negatieve rente gegeven
     insert into bestedingsruimte_neg_rente n
    (n.bngr_relatienr,          n.bngr_productnummer,
     n.bngr_product_volgnummer, n.bngr_re_id,
     n.bngr_cr_rente_vv,        n.bngr_db_rente_vv,
     n.bngr_cr_rente_bv,        n.bngr_db_rente_bv,
     n.bngr_bedrag_meetellen)
     select
     i_relatienummer,           i_productnummer,
     i_productvolgnummer,       to_number(w.wk_categorie_1,'999999999999999'),
     w.wk_waarde_1,             w.wk_waarde_2,
     w.wk_waarde_3,             w.wk_waarde_4,
     w.wk_export
     from  werkbestand w
     where w.wk_terminal  = i_terminalnummer
     and   w.wk_soort     = 'NERE';

     -- Stap 3.13 Vullen van het bestand voor de gebruikte muntsoorten
     insert into bestedingsruimte_muntsoorten m
     (m.bdmu_relatienr,        m.bdmu_productnummer,        m.bdmu_product_volgnummer,
      m.bdmu_code,             m.bdmu_notatie,              m.bdmu_factor,
      m.bdmu_reciproke,        m.bdmu_biedkoers,            m.bdmu_middenkoers,
      m.bdmu_laatkoers,        m.bdmu_gebruikt,             m.bdmu_afslag_perc,
      m.bdmu_opslag_perc)
     select
      i_relatienummer,         i_productnummer,             i_productvolgnummer,
      f.fimu_code,             f.fimu_notatie,              f.fimu_factor,
      f.fimu_reciproke,        f.fimu_biedkoers,            f.fimu_middenkoers,
      f.fimu_laatkoers,        f.fimu_gebruikt,             f.fimu_afslag_perc,
      f.fimu_opslag_perc
      from fiat_muntsoorten f;

     -- Stap 3.14 Vullen van het bestand voor de berekende kosten
     insert into bestedingsruimte_ord_cost_det o
     (o.bocd_relation_number, o.bocd_productnumber,     o.bocd_product_ser_numb,
      o.bocd_order_number,    o.bocd_order_line,        o.bocd_order_det_num,
      o.bocd_cfcu_id,         o.bocd_fixed_amt,         o.bocd_variable_amt,
      o.bocd_total_amt,       o.bocd_discount_amt,      o.bocd_discount_perc,
      o.bocd_basevalue_amt,   o.bocd_calculation_type,  o.bocd_classification,
      o.bocd_origin_type,     o.bocd_rule_max_amt,      o.bocd_rule_min_amt,
      o.bocd_rule_fixed_amt,  o.bocd_rule_var_amt_perc, o.bocd_rule_var_amt_amount,
      o.bocd_rule_currency,   o.bocd_tarif_id)
     select
      i_relatienummer,        i_productnummer,          i_productvolgnummer,
      f.focd_order_number,    f.focd_order_line,        f.focd_order_det_num,
      f.focd_cfcu_id,         f.focd_fixed_amt,         f.focd_variable_amt,
      f.focd_total_amt,       f.focd_discount_amt,      f.focd_discount_perc,
      f.focd_basevalue_amt,   f.focd_calculation_type,  f.focd_classification,
      f.focd_origin_type,     f.focd_rule_max_amt,      f.focd_rule_min_amt,
      f.focd_rule_fixed_amt,  f.focd_rule_var_amt_perc, f.focd_rule_var_amt_amount,
      f.focd_rule_currency,   f.focd_tarif_id
      from fiat_order_costs_det f;


  -- Einde van alleen wegschrijven bij bedragen
  end if;

  -- commiten van de weggeschreven gegevens, alleen als dat gevraagd wordt
  if i_geen_commit_uitvoeren  <> 1
  then
     commit;
  end if;


end best_comp_wegschrijven;
-- EINDE CODE PROCEDURE BEST_COMP_WEGSCHRIJVEN


-- DE CODE VOOR DE PROCEDURE OMREKENEN_BEDRAG
procedure omrekenen_bedrag
(i_bedrag_van              in  geld_werkbestand.gwb_saldo_vv%type
,i_muntsoort_van           in  fiat_muntsoorten.fimu_code%type
,i_muntsoort_naar          in  fiat_muntsoorten.fimu_code%type
,i_gewenst_van_koerssrt    in  varchar2                 -- N= normaal, geen sturing, L= Laatkoers, B= Biedkoers, M=Middenkoers
,i_pr_id                   in  producten.pr_id%type
,i_ppr_id                  in  producten_per_relatie.ppr_id%type
,i_systspreadcodecategorie in  valutaspread_cat_muntsoort.vscm_vsca_id%type
,i_bank2mrktqchangedate    in  muntsoorten.mu_update%type
,o_bedrag_naar             out geld_werkbestand.gwb_saldo_vv%type
)
is
  v_dummy                 number(1);

  v_bkoers_van            fiat_muntsoorten.fimu_biedkoers%type;
  v_mkoers_van            fiat_muntsoorten.fimu_middenkoers%type;
  v_lkoers_van            fiat_muntsoorten.fimu_laatkoers%type;
  v_koers_van             fiat_muntsoorten.fimu_middenkoers%type;
  v_factor_van            fiat_muntsoorten.fimu_factor%type;
  v_reciproke_van         fiat_muntsoorten.fimu_reciproke%type;

  v_bkoers_naar           fiat_muntsoorten.fimu_biedkoers%type;
  v_mkoers_naar           fiat_muntsoorten.fimu_middenkoers%type;
  v_lkoers_naar           fiat_muntsoorten.fimu_laatkoers%type;
  v_koers_naar            fiat_muntsoorten.fimu_middenkoers%type;
  v_factor_naar           fiat_muntsoorten.fimu_factor%type;
  v_reciproke_naar        fiat_muntsoorten.fimu_reciproke%type;
  v_notatie_naar          fiat_muntsoorten.fimu_notatie%type;

begin

  FIAT_ALGEMEEN.valutagegevens_bepalen(i_muntsoort_van,        i_pr_id,      i_ppr_id,     i_systspreadcodecategorie,
                                       i_bank2mrktqchangedate, 0,            ' ',          v_bkoers_van,
                                       v_mkoers_van,           v_lkoers_van, v_factor_van, v_reciproke_van,
                                       v_dummy);

  FIAT_ALGEMEEN.valutagegevens_bepalen(i_muntsoort_naar,       i_pr_id,       i_ppr_id,      i_systspreadcodecategorie,
                                       i_bank2mrktqchangedate, 0,             ' ',           v_bkoers_naar,
                                       v_mkoers_naar,          v_lkoers_naar, v_factor_naar, v_reciproke_naar,
                                       v_notatie_naar);

  if i_gewenst_van_koerssrt = 'L'
  then
     v_koers_van  := v_lkoers_van;
     v_koers_naar := v_bkoers_naar;
  elsif i_gewenst_van_koerssrt = 'B'
  then
     v_koers_van  := v_bkoers_van;
     v_koers_naar := v_lkoers_naar;
  elsif i_gewenst_van_koerssrt = 'M'
  then
     v_koers_van  := v_mkoers_van;
     v_koers_naar := v_mkoers_naar;
  end if;

  if i_gewenst_van_koerssrt in ('L','B','M')
  then
     select FIAT_ALGEMEEN.omrekenen_bedrag_vv (i_bedrag_van,  v_reciproke_van,  v_factor_van,  v_koers_van,
                                               v_koers_van,   v_reciproke_naar, v_factor_naar, v_koers_naar,
                                               v_koers_naar,  v_notatie_naar)
     into   o_bedrag_naar
     from   dual;
  else
     select FIAT_ALGEMEEN.omrekenen_bedrag_vv (i_bedrag_van,  v_reciproke_van,  v_factor_van,  v_bkoers_van,
                                               v_lkoers_van,  v_reciproke_naar, v_factor_naar, v_bkoers_naar,
                                               v_lkoers_naar, v_notatie_naar)
     into   o_bedrag_naar
     from   dual;
   end if;

end omrekenen_bedrag;
-- EINDE CODE PROCEDURE OMREKENEN_BEDRAG


-- DE CODE VOOR DE FUNCTION VERSION
function Version
return varchar2
is

begin
      return gv_versie;
end version;
-- EINDE CODE FUNCTION VERSION

end FIAT_MAGIC;
/
