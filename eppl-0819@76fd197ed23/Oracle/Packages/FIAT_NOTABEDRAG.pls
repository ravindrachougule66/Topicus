create or replace package FIAT_NOTABEDRAG
is

/*------------------------------------------------------------------------------
Package     : FIAT_NOTABEDRAG
description : code voor de package FIAT_NOTABEDRAG waarbinnen de volgende procedures
              en functions aanwezig zijn:
              procedure notabedrag_bereken
              function  version
------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';

-- procedure notabedrag_bereken
   procedure notabedrag_bereken
   (i_ordernummer                 in  orders.ord_ordernummer%type
   ,i_orderregel                  in  orders.ord_orderregel%type
   ,i_orderdetailnr               in  ordersdetaillering.orx_detailnummer%type
   ,i_orx_id                      in  ordersdetaillering.orx_id%type
   ,i_productnummer               in  producten_per_relatie.ppr_productnummer%type
   ,i_product_volgnummer          in  producten_per_relatie.ppr_volgnr_per_product%type
   ,i_slot_of_last_koers          in  varchar2
   ,i_afwijkende_koers_gebruiken  in  number
   ,i_afwijkende_koers            in  fn_quotes_vw.quot_bied%type
   ,i_uitgangspunt_berekening     in  number
   ,i_alleen_eff_bedr_berekenen   in  number
   ,i_fondskoers_comb_order       in  fn_quotes_vw.quot_bied%type
   ,i_instellingen                in  varchar2
   ,i_sys_spread_categorie        in  valutaspread_cat_muntsoort.vscm_vsca_id%type
   ,i_bank2marketchangedate       in  muntsoorten.mu_update%type
   ,i_trans_context               in  contextcalculationrules.cxcr_context%type
   ,i_terminalnummer              in  werkbestand.wk_terminal%type
   ,i_belgisch_spaar_product      in  number
   ,i_richting_omwisseling        in  number
   ,i_capc_id                     in  productconversies.capc_id%type
   ,i_legal_entity_type           in  legalentity_details.lety_id%type
   ,i_eor_kenmerk_id              in  rekeninghouders_details.eor_kenmerk_id%type
   ,i_fundcategory                in  beleggingsinstrument.be_fundcategory%type
   ,o_effectief_bedr_rv           out kosten_werkbestand.kst_effect_bedrag_rv%type
   ,o_nb_verk_als_koop_behandelen out number
   ,o_effectief_bedrag_dekkw_tv   out kosten_werkbestand.kst_effect_bedrag_rv%type
   );

-- procedure
   procedure valuta_kosten_berek_los
   (i_ordernummer                 in  kosten_werkbestand.kst_ordernummer%type
   ,i_orderregel                  in  kosten_werkbestand.kst_orderregel%type
   ,i_orderdetailnummer           in  kosten_werkbestand.kst_detailnummer%type
   ,i_relatienummer               in  relatie_fiattering.rf_relatie_nummer%type
   ,i_sys_spread_categorie        in  valutaspread_cat_muntsoort.vscm_vsca_id%type
   ,i_bank2marketchangedate       in  muntsoorten.mu_update%type
   ,i_netto_bedrag_tv             in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_netto_bedrag_rv             in  kosten_werkbestand.kst_effect_bedrag_rv%type
   ,i_trans_valuta                in  kosten_werkbestand.kst_trans_muntsrt%type
   ,i_order_geldrek_muntsoort     in  kosten_werkbestand.kst_rel1_rek2_munts%type
   ,i_trans_k_v_ind               in  kosten_werkbestand.kst_trans_indicatie_w%type
   );

-- function version
   function version
   return                      varchar2;

end FIAT_NOTABEDRAG;
/
create or replace package body FIAT_NOTABEDRAG
is

/*------------------------------------------------------------------------------
Package body : FIAT_NOTABEDRAG
description  : code voor de package body FIAT_NOTABEDRAG waarbinnen de volgende
               functions en procedures aanwezig zijn:
               procedure  notabedrag_bereken
               procedure  bereken_settl_dat
               procedure  effectief_bedrag_ber
               function   eff_bedrag_berekenen
               procedure  kost_comp_bereken
               procedure  provisie_bereken
               procedure  prov_tabel_bepalen
               functions  version
------------------------------------------------------------------------------*/

-- globale variabelen (dus te gebruiken over alle procedures nadat de waarden zijn
-- bepaald in de eerst aanroepend procedure)
   gv_rel_rapp_valuta             relatie_fiattering.rf_rapp_muntsoort%type;
   gv_rel_rapp_biedkoers          relatie_fiattering.rf_rapp_biedkoers%type;
   gv_rel_rapp_middenkoers        relatie_fiattering.rf_rapp_middenkoers%type;
   gv_rel_rapp_laatkoers          relatie_fiattering.rf_rapp_laatkoers%type;
   gv_rel_rapp_factor             relatie_fiattering.rf_rapp_factor%type;
   gv_rel_rapp_reciproke          relatie_fiattering.rf_rapp_reciproke%type;
   gv_rel_rapp_notatie            relatie_fiattering.rf_rapp_notatie%type;
   gv_pr_id                       relatie_fiattering.rf_pr_id%type;
   gv_ppr_id                      relatie_fiattering.rf_ppr_id%type;
   gv_relatienummer               clienten.cl_nummer%type;
   gv_rel_product_nummer          producten_per_relatie.ppr_productnummer%type;
   gv_rel_product_volgnummer      producten_per_relatie.ppr_volgnr_per_product%type;
   gv_fondssymbool                beleggingsinstrument.be_symbool%type;
   gv_fonds_optietype             beleggingsinstrument.be_optietype%type;
   gv_fonds_expiratiedatum        beleggingsinstrument.be_expiratiedatum%type;
   gv_fonds_exerciseprijs         beleggingsinstrument.be_exerciseprijs%type;
   gv_fonds_id                    beleggingsinstrument.be_volgnummer%type;
   gv_order_orx_id                ordersdetaillering.orx_id%type;
   gv_basis_valuta                relatie_fiattering.rf_bv_muntsoort%type;
   gv_basis_val_biedkoers         relatie_fiattering.rf_bv_biedkoers%type;
   gv_basis_val_middenkoers       relatie_fiattering.rf_bv_middenkoers%type;
   gv_basis_val_laatkoers         relatie_fiattering.rf_bv_laatkoers%type;
   gv_basis_val_factor            relatie_fiattering.rf_bv_factor%type;
   gv_basis_val_reciproke         relatie_fiattering.rf_bv_reciproke%type;
   gv_basis_val_notatie           relatie_fiattering.rf_bv_notatie%type;
   gv_debuggen                    relatie_fiattering.rf_debug_j_n%type;
   gv_debug_user                  relatie_fiattering.rf_debug_user%type;
   gv_minimum_prov_rel_gebr       relatie_fiattering.rf_min_prov_toepass%type;
   gv_maximeer_effecten_prov      relatie_fiattering.rf_maximeer_eff_prov%type;
   gv_maximeer_opties_prov        relatie_fiattering.rf_maximeer_opt_prov%type;
   gv_max_provisie_percentage     relatie_fiattering.rf_max_prov_perc%type;
   gv_max_optie_prov_percentage   relatie_fiattering.rf_max_opt_prov_perc%type;
   gv_provisie_cat_relatie        relatie_fiattering.rf_pr_nummer%type;
   gv_standaard_prov_cat_rel      relatie_fiattering.rf_standaard_cat_rel%type;
   gv_standaard_prov_cat_gebr     relatie_fiattering.rf_gebr_stand_prvcat%type;
   gv_minimum_prov_relatie_gebr   relatie_fiattering.rf_min_prov_toepass%type;
   gv_terugval_basisval           relatie_fiattering.rf_terugval_op_bv%type;
   gv_provisie_korting_vast       relatie_fiattering.rf_prov_kort_vast%type;
   gv_provisie_ex_as_bereken      relatie_fiattering.rf_prov_ex_as_berek%type;
   gv_min_max_var_tot             relatie_fiattering.rf_min_max_var_tot%type;
   gv_slot_of_last_koers          tabelgegevens.tb_symbool%type;
   gv_instellingen                varchar2(1300);
   gv_terminalnummer              werkbestand.wk_terminal%type;
   gv_sys_spread_categorie        valutaspread_cat_muntsoort.vscm_vsca_id%type;
   gv_bank2marketchangedate       muntsoorten.mu_update%type;
   gv_belgisch_spaar_product      number(1);
   gv_bsp_instapfee_aanwezig      number(1);
   gv_instapfee_rule_id           calculationrules.cfcu_id%type := 23;
   gv_context                     contextcalculationrules.cxcr_context%type;
   gv_capc_id                     productconversies.capc_id%type;
   gv_legal_entity_type           legalentity_details.lety_id%type;
   gv_eor_kenmerk_id              rekeninghouders_details.eor_kenmerk_id%type;
   gv_fundcategory                beleggingsinstrument.be_fundcategory%type;

   -- De volgende muntkoersen zijn goed gezet en bevatten de laat of biedkoers en
   -- moeten gebruikt worden bij de omrekeningen
   gv_trans_munt                  relatie_fiattering.rf_rapp_muntsoort%type;
   gv_trans_munt_koers            relatie_fiattering.rf_rapp_biedkoers%type;
   gv_trans_munt_factor           relatie_fiattering.rf_rapp_factor%type;
   gv_trans_munt_reciproke        relatie_fiattering.rf_rapp_reciproke%type;
   gv_trans_munt_notatie          relatie_fiattering.rf_rapp_notatie%type;
   gv_relatie_munt_koers          relatie_fiattering.rf_rapp_biedkoers%type;
   gv_basis_munt_koers            relatie_fiattering.rf_bv_biedkoers%type;

   -- voor de berekening van het notabedrag voor combinatie orders met een limietprijs
   -- worden de volgende variabelen gezet om gebruikt te worden door alle procedures
   -- uit deze package
   gv_db_cr_indicator             kosten_werkbestand.kst_dt_cr_spread%type;
   gv_eff_bedrag_tot_comb_tv      kosten_werkbestand.kst_effect_bedrag_bv%type;
   gv_afwijkende_comb_berekening  number;
   gv_order_type                  orders.ord_ordertype%type;
   gv_order_soort                 orders.ord_ordersoort%type;

-- Declareren van de procedures die niet in de package header staan:

-- function eff_bedrag_berekenen:
   procedure eff_bedrag_berekenen
   (i_aantal                     in  orders.ord_aantal%type
   ,i_prijs                      in  orders.ord_limiet%type
   ,i_trans_indicatie            in  orders.ord_transactiesoort%type
   ,i_tr_fonds_ex_as_factor      in  beleggingsinstrument.be_exass_factor%type
   ,i_tr_fonds_be_bi_nummer      in  beleggingsinstrument.be_bi_nummer%type
   ,i_ow_be_bi_nummer            in  beleggingsinstrument.be_bi_nummer%type
   ,i_tr_fonds_block_size        in  beleggingsinstrument.be_prijs_factor%type
   ,i_tr_fonds_omw_factor        in  beleggingsinstrument.be_aantal_te_ontvangen%type
   ,i_aantal_cijfers_display     in  beleggingsinstrument.be_aantal_cijfers_display%type
   ,i_tr_fonds_prijs_factor      in  beleggingsinstrument.be_prijs_factor%type
   ,i_rentebedrag                in  transakties.tr_rente%type
   ,i_transactie_muntsrt_notatie in  muntsoorten.mu_notatie%type
   ,i_order_keuze                in  orders.ord_keuze%type
   ,o_effectief_bedrag           out transakties.tr_notabedrag%type
   );


-- procedure effectief_bedrag_ber:
   procedure effectief_bedrag_ber
   (i_trans_indicatie            in  transakties.tr_indicatie%type
   ,i_aantal                     in  transakties.tr_aantal%type
   ,i_prijs                      in  transakties.tr_prijs_tr_mntsrt%type
   ,i_beursprijs                 in  transakties.tr_prijs_tr_mntsrt%type
   ,i_rentebedrag                in  transakties.tr_rente%type
   ,i_trans_muntsrt_notatie      in  muntsoorten.mu_notatie%type
   ,i_tr_fonds_be_bi_nummer      in  beleggingsinstrument.be_bi_nummer%type
   ,i_tr_fonds_block_size        in  beleggingsinstrument.be_prijs_factor%type
   ,i_tr_fonds_ex_as_factor      in  beleggingsinstrument.be_exass_factor%type
   ,i_tr_fonds_omw_factor        in  beleggingsinstrument.be_aantal_te_ontvangen%type
   ,i_tr_fonds_prijs_factor      in  beleggingsinstrument.be_prijs_factor%type
   ,i_aantal_cijfers_display     in  beleggingsinstrument.be_aantal_cijfers_display%type
   ,i_ow_be_bi_nummer            in  beleggingsinstrument.be_bi_nummer%type
   ,i_order_keuze                in  orders.ord_keuze%type
   ,o_effectief_bedrag           out transakties.tr_notabedrag%type
   ,o_effectief_bedrag_beurspr   out transakties.tr_notabedrag%type
   );

-- procedure kost_comp_bereken:
   procedure kost_comp_bereken
   (i_ordernummer                in  orders.ord_ordernummer%type
   ,i_orderregel                 in  orders.ord_orderregel%type
   ,i_orderdetailnr              in  ordersdetaillering.orx_detailnummer%type
   ,i_effectief_bv               in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_effectief_vv               in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_trans_prijs                in  kosten_werkbestand.kst_trans_prijs%type
   ,i_fondskoers_comb_order      in  fn_quotes_vw.quot_bied%type
   ,o_bedrag_voor_brutobedrag    out transakties.tr_notabedrag%type
   );

-- procedure prov_tabel_bepalen:
   procedure prov_tabel_bepalen
   (i_provisie_type              in  provtabheader.pr_type%type
   ,i_muntsoort                  in  provtabheader.pr_muntsoort%type
   ,i_prov_be_nummer             in  provtabheader.pr_be_nummer%type
   ,i_prov_cl_nummer             in  provtabheader.pr_cl_nummer%type
   ,i_open_close                 in  provtabheader.pr_open_close%type
   ,i_distributiekanaal          in  provtabheader.pr_distributiekanaal%type
   ,i_standaard_land             in  provtabheader.pr_std_land%type
   ,i_transactiesoort            in  provtabheader.pr_transactiesoort%type
   ,i_premie_eff_bedrag          in  provtabheader.pr_tb_min_premie%type
   ,i_aantal_contracten          in  provtabheader.pr_tb_min_aantal%type
   ,o_tabel_gevonden             out number
   ,o_prov_tab_code              out provtabheader.pr_code%type
   ,o_vaste_kosten               out provtabheader.pr_vaste_kosten%type
   ,o_minimum_provisie           out provtabheader.pr_min_provisie%type
   ,o_maximum_provisie           out provtabheader.pr_max_provisie%type
   );

-- procedure provisie_bereken:
   procedure provisie_bereken
   (i_ordernummer                in  orders.ord_ordernummer%type
   ,i_orderregel                 in  orders.ord_orderregel%type
   ,i_orderdetailnr              in  ordersdetaillering.orx_detailnummer%type
   ,i_effectief_bv               in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_effectief_vv               in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_trans_prijs                in  kosten_werkbestand.kst_trans_prijs%type
   );

-- procedure gehele_provisie_berekenen
   procedure gehele_provisie_berekenen
   (i_ordernummer                  in  kosten_werkbestand.kst_ordernummer%type
   ,i_orderregel                   in  kosten_werkbestand.kst_orderregel%type
   ,i_orderdetail                  in  kosten_werkbestand.kst_detailnummer%type
   ,i_transactie_indicatie         in  kosten_werkbestand.kst_trans_indicatie%type
   ,i_order_aantal                 in  kosten_werkbestand.kst_trans_aantal%type
   ,i_geen_provisie_berekenen      in  kosten_werkbestand.kst_ord_geen_provisie%type
   ,i_order_provisie_perc_eff_wrd  in  kosten_werkbestand.kst_ord_provperceffw%type
   ,i_order_provisie_kort_perc     in  kosten_werkbestand.kst_prov_korting_perc%type
   ,i_effectief_bedrag_bv          in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_effectief_bedrag_tv          in  kosten_werkbestand.kst_effect_bedrag_rv%type
   ,i_klant_prijs                  in  transakties.tr_prijs_tr_mntsrt%type
   ,i_beurs_prijs                  in  transakties.tr_beurs_prijs_trm%type
   ,i_fondskoers_comb_order        in  transakties.tr_prijs_tr_mntsrt%type
   ,i_fonds_prijs_factor           in  beleggingsinstrument.be_prijs_factor%type
   ,o_bedrag_mee_in_brutobedr_bv   out kosten_werkbestand.kst_effect_bedrag_bv%type
   );

-- procedure bepalen_calc_lines
   procedure bepalen_calc_lines
   (i_ordernummer                 in  orders.ord_ordernummer%type
   ,i_orderregel                  in  orders.ord_orderregel%type
   ,i_detailnummer                in  ordersdetaillering.orx_detailnummer%type
   ,i_pr_id                       in  producten.pr_id%type
   ,i_fonds_id                    in  beleggingsinstrument.be_volgnummer%type
   ,i_trans_indicatie             in  kosten_werkbestand.kst_trans_indicatie%type
   ,i_trans_context               in  contextcalculationrules.cxcr_context%type
   ,i_prod_conv_id                in  productconversies.capc_id%type
   ,o_te_doorlopen_amount_type    out varchar2
   ,o_bsp_instapfee_aanwezig      out number
   );

-- procedure admin_external_fees
   procedure admin_external_fees
   (i_ordernummer                 in     orders.ord_ordernummer%type
   ,i_orderregel                  in     orders.ord_orderregel%type
   ,i_detailnummer                in     ordersdetaillering.orx_detailnummer%type
   ,i_trans_indicatie             in     kosten_werkbestand.kst_trans_indicatie%type
   ,o_te_doorlopen_amount_type    in out varchar2
   ,o_bsp_instapfee_aanwezig      in out number
   );

-- procedure calc_lines_schrijven
   procedure calc_lines_schrijven
   (i_rule_id                     in     calculationrules.cfcu_id%type
   ,i_tarif_id                    in     tax_tarif.tt_id%type
   ,i_table                       in     varchar2
   ,i_fixed_amount                in     taxproductrules_vw.tt_fixed_amount%type
   ,i_maximum_amount              in     taxproductrules_vw.tt_maximum_amount%type
   ,i_minimum_amount              in     taxproductrules_vw.tt_minimum_amount%type
   ,i_percentage                  in     fiat_order_costs_det.focd_rule_var_amt_perc%type
   ,i_has_max_amount              in     number
   ,i_has_min_amount              in     number
   ,i_amount_type                 in     calculationrules.cfcu_amount_type%type
   ,i_trans_indicatie             in     kosten_werkbestand.kst_trans_indicatie%type
   ,i_discount_tarif_id           in     prod_dedu_discount.dita_id%type
   ,i_wht_exemption               in     number
   ,o_bsp_instapfee_aanwezig      in out number
   ,o_te_doorlopen_amount_type    in out varchar2
   );

-- procedure order_kosten_berekenen
   procedure order_kosten_berekenen
   (i_ordernummer               in  kosten_werkbestand.kst_ordernummer%type
   ,i_orderregel                in  kosten_werkbestand.kst_orderregel%type
   ,i_orderdetail               in  kosten_werkbestand.kst_detailnummer%type
   ,i_effectief_bedrag_rv       in  kosten_werkbestand.kst_effect_bedrag_rv%type
   ,i_effectief_bedrag_bv       in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_effectief_bedrag_tv       in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_lopende_rente_tv          in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_lopende_rente_bv          in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_lopende_rente_rv          in  kosten_werkbestand.kst_effect_bedrag_rv%type
   ,i_order_aantal              in  kosten_werkbestand.kst_trans_aantal%type
   ,i_klant_prijs               in  transakties.tr_prijs_tr_mntsrt%type
   ,i_beurs_prijs               in  transakties.tr_beurs_prijs_trm%type
   ,i_fondskoers_comb_order     in  transakties.tr_prijs_tr_mntsrt%type
   ,i_te_doorlopen_amount_types in  varchar2
   ,i_transactie_indicatie      in  kosten_werkbestand.kst_trans_indicatie%type
   ,i_trans_k_v_ind             in  kosten_werkbestand.kst_trans_indicatie_w%type
   ,i_prijs_factor_fonds        in  kosten_werkbestand.kst_prijs_factor_fnds%type
   ,i_ex_ass_factor_fonds       in  kosten_werkbestand.kst_fnds_ex_ass_fac%type
   ,i_geen_provisie_berekenen   in  kosten_werkbestand.kst_ord_geen_provisie%type
   ,i_ord_prov_perc_eff_wrd     in  kosten_werkbestand.kst_ord_provperceffw%type
   ,i_ord_prov_kort_perc        in  kosten_werkbestand.kst_prov_korting_perc%type
   ,i_trans_market_koers        in  fiat_muntsoorten.fimu_middenkoers%type
   ,i_order_geldrek_muntsoort   in  kosten_werkbestand.kst_rel1_rek2_munts%type
   ,i_richting_omwisseling      in  number
   ,o_effectief_bedrag_rv       out kosten_werkbestand.kst_effect_bedrag_rv%type
   ,o_effectief_bedrag_bv       out kosten_werkbestand.kst_effect_bedrag_bv%type
   ,o_effectief_bedrag_tv       out kosten_werkbestand.kst_effect_bedrag_bv%type
   );

-- procedure calc_lines_verwerken
   procedure calc_lines_verwerken
   (i_amount_type               in  calculationrules.cfcu_amount_type%type
   ,i_ordernummer               in  kosten_werkbestand.kst_ordernummer%type
   ,i_orderregel                in  kosten_werkbestand.kst_orderregel%type
   ,i_orderdetail               in  kosten_werkbestand.kst_detailnummer%type
   ,i_basis_bedrag_rv           in  kosten_werkbestand.kst_effect_bedrag_rv%type
   ,i_basis_bedrag_bv           in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_basis_bedrag_tv           in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_order_aantal              in  kosten_werkbestand.kst_trans_aantal%type
   ,i_klant_prijs               in  transakties.tr_prijs_tr_mntsrt%type
   ,i_beurs_prijs               in  transakties.tr_beurs_prijs_trm%type
   ,i_fondskoers_comb_ord       in  transakties.tr_prijs_tr_mntsrt%type
   ,i_transactie_indicatie      in  kosten_werkbestand.kst_trans_indicatie%type
   ,i_trans_k_v_ind             in  transactiesoorten.ts_koop_verkoop_ind%type
   ,i_prijs_factor_fonds        in  kosten_werkbestand.kst_prijs_factor_fnds%type
   ,i_ex_ass_factor_fonds       in  kosten_werkbestand.kst_fnds_ex_ass_fac%type
   ,i_geen_prov_berekenen       in  kosten_werkbestand.kst_ord_geen_provisie%type
   ,i_ord_prov_perc_eff_wrd     in  kosten_werkbestand.kst_ord_provperceffw%type
   ,i_ord_prov_kort_perc        in  kosten_werkbestand.kst_prov_korting_perc%type
   ,i_order_geldrek_mnts        in  kosten_werkbestand.kst_rel1_rek2_munts%type
   ,i_trans_market_koers        in  fiat_muntsoorten.fimu_middenkoers%type
   ,i_instapfee_bereken         in  number
   ,i_context                   in  contextcalculationrules.cxcr_context%type
   ,i_richting_omwisseling      in  number                                      
   ,o_correctie_bedrag_rv       out kosten_werkbestand.kst_effect_bedrag_rv%type
   ,o_correctie_bedrag_bv       out kosten_werkbestand.kst_effect_bedrag_bv%type
   ,o_correctie_bedrag_tv       out kosten_werkbestand.kst_effect_bedrag_bv%type
   ,o_berekend_bedrag_rv        out kosten_werkbestand.kst_effect_bedrag_rv%type
   ,o_berekend_bedrag_bv        out kosten_werkbestand.kst_effect_bedrag_bv%type
   ,o_berekend_bedrag_tv        out kosten_werkbestand.kst_effect_bedrag_bv%type
   );

-- procedure cr_notabedrag_bereken
   procedure cr_notabedrag_berekenen
   (i_berekend_bedrag_in_rv     in  kosten_werkbestand.kst_effect_bedrag_rv%type
   ,i_transactie_indicatie      in  kosten_werkbestand.kst_trans_indicatie%type
   ,o_notabedrag_rv             out kosten_werkbestand.kst_notabedrag%type
   );

-- procedure valuta_kosten_berekenen
   procedure valuta_kosten_berekenen
   (i_netto_bedrag              in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_trans_market_koers        in  fiat_muntsoorten.fimu_middenkoers%type
   ,i_order_geldrek_muntsoort   in  kosten_werkbestand.kst_rel1_rek2_munts%type
   ,i_trans_k_v_ind             in  kosten_werkbestand.kst_trans_indicatie_w%type
   ,o_val_kosten_rv             out kosten_werkbestand.kst_effect_bedrag_rv%type
   ,o_val_kosten_tv             out kosten_werkbestand.kst_effect_bedrag_rv%type
   ,o_val_kosten_bv             out kosten_werkbestand.kst_effect_bedrag_bv%type
   ,o_val_spread                out fiat_muntsoorten.fimu_afslag_perc%type
   );

-- procedure omrekenen_tv_bv
   procedure omrekenen_tv_bv
   (i_bedrag_in_tv              in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,o_bedrag_uit_bv             out kosten_werkbestand.kst_effect_bedrag_bv%type
   );

-- procedure omrekenen_tv_rv
   procedure omrekenen_tv_rv
   (i_bedrag_in_tv              in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,o_bedrag_uit_rv             out kosten_werkbestand.kst_effect_bedrag_bv%type
   );

-- procedure omrekenen_bv_tv
   procedure omrekenen_bv_tv
   (i_bedrag_in_bv              in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,o_bedrag_uit_tv             out kosten_werkbestand.kst_effect_bedrag_rv%type
   );

-- procedure omrekenen_bv_rv
   procedure omrekenen_bv_rv
   (i_bedrag_in_bv              in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,o_bedrag_uit_rv             out kosten_werkbestand.kst_effect_bedrag_rv%type
   );

-- procedure optellen_bedragen
   procedure optellen_bedragen
   (i_totaal_bedrag_in_rv       in  kosten_werkbestand.kst_effect_bedrag_rv%type
   ,i_totaal_bedrag_in_bv       in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_totaal_bedrag_in_tv       in  kosten_werkbestand.kst_effect_bedrag_rv%type
   ,i_optel_bedrag_in_rv        in  kosten_werkbestand.kst_effect_bedrag_rv%type
   ,i_optel_bedrag_in_bv        in  kosten_werkbestand.kst_effect_bedrag_bv%type
   ,i_optel_bedrag_in_tv        in  kosten_werkbestand.kst_effect_bedrag_rv%type
   ,i_trans_k_v_ind             in  kosten_werkbestand.kst_trans_indicatie_w%type
   ,o_totaal_bedrag_in_rv       out kosten_werkbestand.kst_effect_bedrag_rv%type
   ,o_totaal_bedrag_in_bv       out kosten_werkbestand.kst_effect_bedrag_bv%type
   ,o_totaal_bedrag_in_tv       out kosten_werkbestand.kst_effect_bedrag_rv%type
   );

-- procedure wht_percentage_bepalen
   procedure wht_percentage_bepalen
   (i_fonds_id                  in  beleggingsinstrument.be_volgnummer%type
   ,i_relatienummer             in  kosten_werkbestand.kst_relatie_nummer%type
   ,o_belasting_percentage      out inkomensverdragperc.iv_percentage%type
   ); 

-- DE CODE VOOR DE PROCEDURE NOTABEDRAG_BEREKEN
-- Procedure voor het berekenen van het geschatte notabedrag voor de opgegeven order
procedure notabedrag_bereken
(i_ordernummer                 in  orders.ord_ordernummer%type
,i_orderregel                  in  orders.ord_orderregel%type
,i_orderdetailnr               in  ordersdetaillering.orx_detailnummer%type
,i_orx_id                      in  ordersdetaillering.orx_id%type
,i_productnummer               in  producten_per_relatie.ppr_productnummer%type
,i_product_volgnummer          in  producten_per_relatie.ppr_volgnr_per_product%type
,i_slot_of_last_koers          in  varchar2
,i_afwijkende_koers_gebruiken  in  number
,i_afwijkende_koers            in  fn_quotes_vw.quot_bied%type
,i_uitgangspunt_berekening     in  number
,i_alleen_eff_bedr_berekenen   in  number
,i_fondskoers_comb_order       in  fn_quotes_vw.quot_bied%type
,i_instellingen                in  varchar2
,i_sys_spread_categorie        in  valutaspread_cat_muntsoort.vscm_vsca_id%type
,i_bank2marketchangedate       in  muntsoorten.mu_update%type
,i_trans_context               in  contextcalculationrules.cxcr_context%type
,i_terminalnummer              in  werkbestand.wk_terminal%type
,i_belgisch_spaar_product      in  number
,i_richting_omwisseling        in  number
,i_capc_id                     in  productconversies.capc_id%type
,i_legal_entity_type           in  legalentity_details.lety_id%type
,i_eor_kenmerk_id              in  rekeninghouders_details.eor_kenmerk_id%type
,i_fundcategory                in  beleggingsinstrument.be_fundcategory%type
,o_effectief_bedr_rv           out kosten_werkbestand.kst_effect_bedrag_rv%type
,o_nb_verk_als_koop_behandelen out number
,o_effectief_bedrag_dekkw_tv   out kosten_werkbestand.kst_effect_bedrag_rv%type
)


is
   -- variabelen uit het kosten_werkbestand
   v_fonds_be_bi_nummer                 beleggingsinstrument.be_bi_nummer%type;
   v_fonds_ex_ass_factor                beleggingsinstrument.be_exass_factor%type;
   v_fonds_prijs_factor                 beleggingsinstrument.be_prijs_factor%type;
   v_fonds_omw_factor                   beleggingsinstrument.be_aantal_te_ontvangen%type;
   v_fonds_aantal_cijfers_display       beleggingsinstrument.be_aantal_cijfers_display%type;
--   fonds_historische_prijs            aktuele_posities.ap_hist_wrd_totbe%type;
   v_fonds_beursnummer                  beurzen.brs_nummer%type;
   v_ref_fondssymbool                   beleggingsinstrument.be_symbool%type;
   v_ref_fonds_be_bi_nummer             beleggingsinstrument.be_bi_nummer%type;
   v_ref_fonds_prijs_factor             beleggingsinstrument.be_prijs_factor%type;
   v_transactie_soort                   transakties.tr_indicatie%type;
   v_transactie_soort_tb_waarde         tabelgegevens.tb_waarde%type;
   v_order_aantal                       transakties.tr_aantal%type;
   v_limiet_toegestaan                  toegelordercontrole.toc_limietprijs%type;
   v_limietprijs                        orders.ord_limiet%type;
   v_order_keuze                        kosten_werkbestand.kst_order_keuze%type;
   v_order_externe_referentie           kosten_werkbestand.kst_externe_referentie%type;
   v_prod_conv_id                       productconversies.capc_id%type;
   v_emissie_inschrijfprijs_hoog        emissies.emi_inschr_hoog%type;
   v_order_effectief_bedrag             kosten_werkbestand.kst_effect_bedrag_bv%type;
   v_order_notabedrag                   kosten_werkbestand.kst_notabedrag%type;
   v_order_geen_provisie                kosten_werkbestand.kst_ord_geen_provisie%type;
   v_order_provisie_perc_eff_wrd        orders.ord_provperceffwrd%type;
   v_order_provisie_perc_abs            orders.ord_provisie_absoluut%type;
   v_order_provisieps_bv                orders.ord_provisieps_bv%type;
   v_order_prov_korting_perc            orders.ord_provkortingperc%type;
   v_order_mutatiekost_btw              orders.ord_mutkosten_btw_bv%type;
   v_order_settl_kost                   orders.ord_settlekosten_bv%type;
   v_order_geldrek_muntsoort            kosten_werkbestand.kst_rel1_rek2_munts%type;
   v_trans_muntsoort                    transakties.tr_trans_munts%type;
   v_trans_munt_bkoers                  muntsoorten.mu_biedkoers%type;
   v_trans_munt_mkoers                  muntsoorten.mu_middenkoers%type;
   v_trans_munt_lkoers                  muntsoorten.mu_laatkoers%type;
   v_trans_munt_factor                  muntsoorten.mu_factor%type;
   v_trans_munt_reciproke               muntsoorten.mu_reciproke%type;
   v_trans_munt_notatie                 muntsoorten.mu_notatie%type;

   -- algemene variabelen
   v_valdat_transdat                    beleggingsinstrument.be_valdat_transdat%type;
   v_rente_factor                       number(14,9);
   v_rente_bedrag_transval              transakties.tr_rente%type;
   v_rente_bedrag_bv                    transakties.tr_rente%type         := 0;
   v_rente_bedrag_rv                    transakties.tr_rente%type         := 0;
   v_werk_fondssymbool                  beleggingsinstrument.be_symbool%type;
   v_werk_fonds_prijs_factor            beleggingsinstrument.be_prijs_factor%type;
   v_rekendatum                         varchar2(8);
   v_klantprijs                         transakties.tr_prijs_tr_mntsrt%type := 0;
   v_beursprijs                         transakties.tr_prijs_tr_mntsrt%type := 0;
   v_dekkingsprijs                      transakties.tr_prijs_tr_mntsrt%type := 0;
   v_provisie_bv                        transakties.tr_provisie%type;
   v_effectief_bedrag_transval          transakties.tr_notabedrag%type;
   v_effectief_bedrag_beursprijs        transakties.tr_notabedrag%type;
   v_effectief_bedrag_dekkingsw         transakties.tr_notabedrag%type;
   v_effectief_bedrag_bv                transakties.tr_notabedrag%type;
   v_effectief_bedrag_rv                transakties.tr_notabedrag%type;
   v_effectief_bedrag_rv_cr_voor        transakties.tr_notabedrag%type;
   v_cr_effect_bedrag_bv                transakties.tr_notabedrag%type;
   v_cr_effect_bedrag_rv                transakties.tr_notabedrag%type;
   v_cr_effect_bedrag_tv                transakties.tr_notabedrag%type;
   v_dummy                              transakties.tr_notabedrag%type;
   v_notabedrag                         transakties.tr_notabedrag%type;
   v_trans_munt_koers                   transakties.tr_trans_munts_krs%type;
   v_relatie_muntsrt_koers              transakties.tr_rel1_rap_krs%type;
   v_basis_munt_koers                   fn_quotes_vw.quot_midden%type;
   v_kosten_relatienr                   kosten_werkbestand.kst_relatie_nummer%type;
   v_fiattering_relatienr               relatie_fiattering.rf_relatie_nummer%type;
   v_te_doorlopen_amount_types          varchar2(250);
   v_bsp_instapfee_aanwezig             number(1);

begin

   -- ophalen van de gegevens die in de procedure gebruikt gaan worden:
   select k.kst_fondssymbool,             k.kst_optietype_fnds,           k.kst_expiratiedat_fnds,
          k.kst_exercisepr_fnds,          k.kst_bi_nummer,                k.kst_fnds_ex_ass_fac,
          k.kst_prijs_factor_fnds,        k.kst_omw_factor_fnds,          k.kst_beursnummer,
          k.kst_ref_fondssymbool,         k.kst_ref_fnds_bi_nr,           k.kst_ref_fnds_prijs_f,
          k.kst_trans_indicatie,          k.kst_trans_indicatie_w,        k.kst_trans_aantal,
          k.kst_order_soort,              k.kst_limiet_toegestaan,        k.kst_order_limietprijs,
          k.kst_ord_provperceffw,         k.kst_ord_prov_absoluut,        k.kst_ord_prov_ps_bv,
          k.kst_ord_provkort_perc,        k.kst_ord_mutkosten_btw,        k.kst_ord_settl_kosten,
          k.kst_trans_muntsrt,            k.kst_relatie_nummer,           k.kst_aantal_cijfers_disp,
          k.kst_pr_nummer,                k.kst_gebr_stand_prvcat,        k.kst_min_prov_toepass,
          k.kst_effect_bedrag_bv,
          k.kst_notabedrag,               k.kst_dt_cr_spread,             k.kst_ordertype,
          k.kst_ord_geen_provisie,        k.kst_order_keuze,              k.kst_externe_referentie,
          k.kst_rel1_rek2_munts,          k.kst_fund_id,
          r.rf_rapp_muntsoort,            r.rf_rapp_biedkoers,            r.rf_rapp_middenkoers,
          r.rf_rapp_laatkoers,            r.rf_rapp_factor,               r.rf_rapp_reciproke,
          r.rf_rapp_notatie,              r.rf_bv_muntsoort,              r.rf_bv_biedkoers,
          r.rf_bv_middenkoers,            r.rf_bv_laatkoers,              r.rf_bv_factor,
          r.rf_bv_reciproke,              r.rf_bv_notatie,                r.rf_relatie_nummer,
          r.rf_min_prov_toepass,          r.rf_maximeer_eff_prov,         r.rf_maximeer_opt_prov,
          r.rf_max_prov_perc,             r.rf_max_opt_prov_perc,         r.rf_standaard_cat_rel,
          r.rf_terugval_op_bv,            r.rf_prov_kort_vast,            r.rf_prov_ex_as_berek,
          r.rf_min_max_var_tot,           r.rf_debug_j_n,                 r.rf_debug_user,
          r.rf_pr_id,                     r.rf_ppr_id
   into   gv_fondssymbool,                gv_fonds_optietype,             gv_fonds_expiratiedatum,
          gv_fonds_exerciseprijs,         v_fonds_be_bi_nummer,           v_fonds_ex_ass_factor,
          v_fonds_prijs_factor,           v_fonds_omw_factor,             v_fonds_beursnummer,
          v_ref_fondssymbool,             v_ref_fonds_be_bi_nummer,       v_ref_fonds_prijs_factor,
          v_transactie_soort,             v_transactie_soort_tb_waarde,   v_order_aantal,
          gv_order_soort,                 v_limiet_toegestaan,            v_limietprijs,
          v_order_provisie_perc_eff_wrd,  v_order_provisie_perc_abs,      v_order_provisieps_bv,
          v_order_prov_korting_perc,      v_order_mutatiekost_btw,        v_order_settl_kost,
          v_trans_muntsoort,              v_kosten_relatienr,             v_fonds_aantal_cijfers_display,
          gv_provisie_cat_relatie,        gv_standaard_prov_cat_gebr,     gv_minimum_prov_relatie_gebr,
          v_order_effectief_bedrag,
          v_order_notabedrag,             gv_db_cr_indicator,             gv_order_type,
          v_order_geen_provisie,          v_order_keuze,                  v_order_externe_referentie,
          v_order_geldrek_muntsoort,      gv_fonds_id,
          gv_rel_rapp_valuta,             gv_rel_rapp_biedkoers,          gv_rel_rapp_middenkoers,
          gv_rel_rapp_laatkoers,          gv_rel_rapp_factor,             gv_rel_rapp_reciproke,
          gv_rel_rapp_notatie,            gv_basis_valuta,                gv_basis_val_biedkoers,
          gv_basis_val_middenkoers,       gv_basis_val_laatkoers,         gv_basis_val_factor,
          gv_basis_val_reciproke,         gv_basis_val_notatie,           v_fiattering_relatienr,
          gv_minimum_prov_rel_gebr,       gv_maximeer_effecten_prov,      gv_maximeer_opties_prov,
          gv_max_provisie_percentage,     gv_max_optie_prov_percentage,   gv_standaard_prov_cat_rel,
          gv_terugval_basisval,           gv_provisie_korting_vast,       gv_provisie_ex_as_bereken,
          gv_min_max_var_tot,             gv_debuggen,                    gv_debug_user,
          gv_pr_id,                       gv_ppr_id
   from   kosten_werkbestand k, relatie_fiattering r
   where  k.kst_ordernummer    = i_ordernummer
   and    k.kst_orderregel     = i_orderregel
   and    k.kst_detailnummer   = i_orderdetailnr
   and    k.kst_relatie_nummer = r.rf_relatie_nummer;

   gv_legal_entity_type := i_legal_entity_type;
   gv_eor_kenmerk_id    := i_eor_kenmerk_id;
   gv_fundcategory      := i_fundcategory;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'begin van notabedrag berekenen FIAT_NOTABEDRAG.notabedrag_bereken');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer in     : '||to_char(i_ordernummer)||' ; orderregel in : '||to_char(i_orderregel));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'orderdetailnr in   : '||to_char(i_orderdetailnr)||' ; order orx id in : '||to_char(i_orx_id));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i relatienummer    : '||to_char(v_fiattering_relatienr)||' ; kosten relatienummer : '||to_char(v_kosten_relatienr));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'gv db cr indicator : '||to_char(gv_db_cr_indicator)||' ; order soort : '||gv_order_soort);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'trans context      : '||i_trans_context);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'   ');
   end if;

   -- muntkoersen bepalen voor de berekeningen
   FIAT_ALGEMEEN.valutagegevens_bepalen (v_trans_muntsoort,       gv_pr_id,            gv_ppr_id,           i_sys_spread_categorie,
                                         i_bank2marketchangedate, gv_debuggen,         gv_debug_user,       v_trans_munt_bkoers,
                                         v_trans_munt_mkoers,     v_trans_munt_lkoers, v_trans_munt_factor, v_trans_munt_reciproke,
                                         v_trans_munt_notatie);

   if v_trans_muntsoort = v_order_geldrek_muntsoort
   then
      v_trans_munt_koers := v_trans_munt_mkoers;
   else
      FIAT_ALGEMEEN.muntkoers_bepalen (v_transactie_soort_tb_waarde, 0,                      v_trans_munt_reciproke, v_trans_munt_bkoers,
                                       v_trans_munt_mkoers,          v_trans_munt_lkoers,    v_trans_munt_koers);
   end if;
   if v_trans_muntsoort = gv_rel_rapp_valuta
   then
      v_relatie_muntsrt_koers := v_trans_munt_koers;
   else
      FIAT_ALGEMEEN.muntkoers_bepalen (v_transactie_soort_tb_waarde, 1,                      gv_rel_rapp_reciproke,  gv_rel_rapp_biedkoers,
                                       gv_rel_rapp_middenkoers,      gv_rel_rapp_laatkoers,  v_relatie_muntsrt_koers);
   end if;
   FIAT_ALGEMEEN.muntkoers_bepalen (v_transactie_soort_tb_waarde, 1,                      gv_basis_val_reciproke, gv_basis_val_biedkoers,
                                    gv_basis_val_middenkoers,     gv_basis_val_laatkoers, v_basis_munt_koers);
   
   -- de bepaalde koersen vast leggen als global variable zodat die door de hele package te gebruiken zijn....
   gv_trans_munt             := v_trans_muntsoort;
   gv_trans_munt_koers       := v_trans_munt_koers;
   gv_trans_munt_factor      := v_trans_munt_factor;
   gv_trans_munt_reciproke   := v_trans_munt_reciproke;
   gv_trans_munt_notatie     := v_trans_munt_notatie;
   gv_relatie_munt_koers     := v_relatie_muntsrt_koers;
   gv_basis_munt_koers       := v_basis_munt_koers;
   gv_slot_of_last_koers     := i_slot_of_last_koers;
   gv_instellingen           := i_instellingen;
   gv_terminalnummer         := i_terminalnummer;
   gv_sys_spread_categorie   := i_sys_spread_categorie;
   gv_bank2marketchangedate  := i_bank2marketchangedate;
   gv_belgisch_spaar_product := i_belgisch_spaar_product;
   gv_order_orx_id           := i_orx_id;
   gv_relatienummer          := v_kosten_relatienr;
   gv_rel_product_nummer     := i_productnummer;
   gv_rel_product_volgnummer := i_product_volgnummer;
   gv_context                := i_trans_context;
   gv_capc_id                := i_capc_id;
   
   o_effectief_bedrag_dekkw_tv := 0;

   -- Voor combinatieorders wordt een afwijkend effectief bedrag berekend om later een notabedrag
   -- mee te bepalen.
   if gv_db_cr_indicator <> 0 and gv_order_type in ('COMB','VZCO') and gv_order_soort = 'L'
   then
      gv_afwijkende_comb_berekening := 1;
      -- met behulp van db_cr_indicator wordt het teken voor het effectief bedrag goed gezet.
      -- nb de limietprijs kan ook 0 zijn....
      -- daarom worden de kosten berekend op de normale manier en wordt pas bij het brutobedrag berekenen hier
      -- gebruik van gemaakt
      gv_eff_bedrag_tot_comb_tv := v_order_aantal * v_fonds_prijs_factor * v_limietprijs * gv_db_cr_indicator;
      -- het bedrag berekend met de limietprijs is voor de gehele combinatie. Dus hier nog door 2 delen voor elk leg
      gv_eff_bedrag_tot_comb_tv := gv_eff_bedrag_tot_comb_tv/2;
   -- het is geen limiet combinatie order
   else
      gv_afwijkende_comb_berekening := 0;
      gv_eff_bedrag_tot_comb_tv     := 0;
   end if;

   -- berekenen van de lopende rente
   if v_fonds_be_bi_nummer between 200 and 299
      or
      v_ref_fonds_be_bi_nummer between 200 and 299 and v_transactie_soort in ('EX C', 'EX P')
   then
      -- bepalen van werkfondssymbool voor de renteberekening:
      if v_fonds_be_bi_nummer between 200 and 299
      then
         v_werk_fondssymbool       := gv_fondssymbool;
         v_werk_fonds_prijs_factor := v_fonds_prijs_factor;
      else
         v_werk_fondssymbool       := v_ref_fondssymbool;
         v_werk_fonds_prijs_factor := v_ref_fonds_prijs_factor;
      end if;

      if v_order_externe_referentie = 0
      then
         -- De rente wordt nu berrekend met de systeemdatum
         select b.be_valdat_transdat
         into   v_valdat_transdat
         from   beleggingsinstrument b
         where  b.be_symbool        = v_werk_fondssymbool
         and    b.be_optietype      = ' '
         and    b.be_expiratiedatum = '00000000'
         and    b.be_exerciseprijs  = 0;

         -- bepalen van de v_rekendatum (dus de datum waarmee de lopende rente berekend moet worden):
         if v_valdat_transdat = 'V'
         then
            -- de valutadatum is gelijk aan de settlementdatum (dus daarom hier settlementdatum bepalen)
            FIAT_ALGEMEEN.bereken_settl_dat(v_fonds_beursnummer, v_transactie_soort_tb_waarde, to_char(SYSDATE,'yyyymmdd'),v_rekendatum);
         else
            v_rekendatum := to_char(SYSDATE,'yyyymmdd');
         end if;
      -- als het wel een productconversie is, dan de actiedatum als rente rekendatum:
      else
         select p.capc_actiedatum
         into   v_rekendatum
         from   productconversies p
         where  p.capc_dossiernummer = v_order_externe_referentie;
      end if;

      -- bepalen van de rente factor
      select FIAT_ALGEMEEN.rente_factor_berek(v_werk_fondssymbool, v_rekendatum, gv_debuggen, gv_debug_user)
      into   v_rente_factor
      from   dual;

      v_rente_factor := nvl(round(v_rente_factor,9),0);

      -- berekenen van het uiteindelijke rentebedrag:
      v_rente_bedrag_transval := round(v_order_aantal * v_rente_factor * v_werk_fonds_prijs_factor, gv_trans_munt_notatie);

      if gv_basis_valuta <> v_trans_muntsoort
      then
         select FIAT_ALGEMEEN.omrekenen_bedrag (v_rente_bedrag_transval, gv_trans_munt_reciproke, gv_trans_munt_factor,
                                                gv_trans_munt_koers, gv_trans_munt_koers, gv_trans_munt_notatie)
         into   v_rente_bedrag_bv
         from   dual;
      else
         v_rente_bedrag_bv := v_rente_bedrag_transval;
      end if;
      if gv_rel_rapp_valuta = gv_basis_valuta
      then
         v_rente_bedrag_rv := v_rente_bedrag_bv;
      else
         if gv_rel_rapp_valuta <> v_trans_muntsoort
         then
            select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_rente_bedrag_transval, gv_trans_munt_reciproke, gv_trans_munt_factor, gv_trans_munt_koers,
                                                      gv_trans_munt_koers,     gv_rel_rapp_reciproke,   gv_rel_rapp_factor,   gv_relatie_munt_koers,
                                                      gv_relatie_munt_koers,   gv_rel_rapp_notatie)
            into   v_rente_bedrag_rv
            from   dual;
         else
            v_rente_bedrag_rv := v_rente_bedrag_transval;
         end if;
      end if;
   end if;
   
   if v_order_externe_referentie <> 0
   then
      select p.capc_id
      into   v_prod_conv_id
      from   productconversies p
      where  p.capc_dossiernummer = v_order_externe_referentie;
   end if;
   
   v_emissie_inschrijfprijs_hoog := 0;
   if v_transactie_soort = 'EMIS'
   then
      select e.emi_inschr_hoog
      into   v_emissie_inschrijfprijs_hoog
      from   emissies e
      where  e.emi_fondssymbool = gv_fondssymbool;
   end if;

   -- bepalen van de v_klantprijs en de v_beursprijs.
   FIAT_ALGEMEEN.fondsprijzen (gv_fondssymbool,              gv_fonds_optietype,         gv_fonds_expiratiedatum,
                               gv_fonds_exerciseprijs,       v_transactie_soort,         v_transactie_soort_tb_waarde,
                               gv_order_soort,               v_limiet_toegestaan,        v_limietprijs,
                               i_afwijkende_koers_gebruiken, i_afwijkende_koers,         v_emissie_inschrijfprijs_hoog,
                               v_order_provisie_perc_abs,    v_order_provisieps_bv,      gv_slot_of_last_koers,
                               gv_debuggen,                  gv_debug_user,              v_klantprijs,
                               v_beursprijs,                 v_dekkingsprijs);

   if i_uitgangspunt_berekening not in (2,3)
   then
      -- Berekenen van effectief bedrag voor het notabedrag, met klant en v_beursprijs
      effectief_bedrag_ber (v_transactie_soort,       v_order_aantal,       v_klantprijs,                v_beursprijs,
                            v_rente_bedrag_transval,  v_trans_munt_notatie, v_fonds_be_bi_nummer,        v_fonds_prijs_factor,
                            v_fonds_ex_ass_factor,    v_fonds_omw_factor,   v_fonds_prijs_factor,        v_fonds_aantal_cijfers_display,
                            v_ref_fonds_be_bi_nummer, v_order_keuze,        v_effectief_bedrag_transval, v_effectief_bedrag_beursprijs);
   else
      v_effectief_bedrag_transval := v_order_effectief_bedrag;
   end if;

   if v_trans_muntsoort = gv_basis_valuta
   then
      v_effectief_bedrag_bv := v_effectief_bedrag_transval;
   else
      select FIAT_ALGEMEEN.omrekenen_bedrag(v_effectief_bedrag_transval, gv_trans_munt_reciproke, gv_trans_munt_factor ,
                                            gv_trans_munt_koers, gv_trans_munt_koers, gv_trans_munt_notatie)
      into   v_effectief_bedrag_bv
      from   dual;
   end if;

   if i_uitgangspunt_berekening not in (2,3)
   then
      -- Berekenen van effectief bedrag voor de dekkingswaarde, dus met de dekkingsprijs
      effectief_bedrag_ber (v_transactie_soort,       v_order_aantal,       v_dekkingsprijs,              v_dekkingsprijs,
                            v_rente_bedrag_transval,  v_trans_munt_notatie, v_fonds_be_bi_nummer,         v_fonds_prijs_factor,
                            v_fonds_ex_ass_factor,    v_fonds_omw_factor,   v_fonds_prijs_factor,         v_fonds_aantal_cijfers_display,
                            v_ref_fonds_be_bi_nummer, v_order_keuze,        v_effectief_bedrag_dekkingsw, v_dummy);
   else
      v_effectief_bedrag_dekkingsw := v_order_effectief_bedrag;
   end if;

   if v_trans_muntsoort = gv_rel_rapp_valuta
   then
      v_effectief_bedrag_rv := v_effectief_bedrag_dekkingsw;
   else
      select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_effectief_bedrag_dekkingsw, gv_trans_munt_reciproke, gv_trans_munt_factor,
                                                gv_trans_munt_koers, gv_trans_munt_koers, gv_rel_rapp_reciproke,
                                                gv_rel_rapp_factor, gv_relatie_munt_koers, gv_relatie_munt_koers,
                                                gv_rel_rapp_notatie)
      into   v_effectief_bedrag_rv
      from   dual;
   end if;

   o_effectief_bedrag_dekkw_tv := v_effectief_bedrag_transval;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag bv : '||to_char(v_effectief_bedrag_bv)||' ; effectief bedrag rv : '||to_char(v_effectief_bedrag_rv));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag comb tv : '||to_char(gv_eff_bedrag_tot_comb_tv)||
                                              ' ; effectief bedrag dekkw tv : '||to_char(o_effectief_bedrag_dekkw_tv));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Geen provisie berekenen  : '||to_char(v_order_geen_provisie)||' ; db cr indicator : '||to_char(gv_db_cr_indicator));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

   -- als alleen het effectief bedrag berekend hoeft te worden, dan hier het berekende bedrag teruggeven
   if i_alleen_eff_bedr_berekenen = 1
   then
      o_effectief_bedr_rv := v_effectief_bedrag_rv;
   -- als het gehele notabedrag berekend moet worden, dan verder gaan met de berekeningen
   else
      -- hier een 0 teruggeven als niet alleen het effectief bedrag berekend hoeft te worden....
      o_effectief_bedr_rv := 0;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In Berekeningen met behulp van de calculation lines');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
      end if;

      v_cr_effect_bedrag_bv    := 0;
      v_cr_effect_bedrag_rv    := 0;
      v_cr_effect_bedrag_tv    := 0;
      v_bsp_instapfee_aanwezig := 0;

      -- Voor Star fund koop (bedrag) hier het effectief als uitgangspunt gelijkstellen aan het notabedrag dat is opgegeven.
      if gv_belgisch_spaar_product = 1 and v_transactie_soort = 'K'
      then
         v_effectief_bedrag_bv       := v_order_notabedrag;
         v_effectief_bedrag_transval := v_order_notabedrag;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In Star fund koop deel');
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'v order notabedrag : '||to_char(v_order_notabedrag));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'v eff bedrag bv : '||to_char(v_effectief_bedrag_bv)||' ; v_eff bedrag tv : '||to_char(v_effectief_bedrag_transval));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
         end if;
      end if;

      -- Hier eerst het effectief bedrag in rv bepalen voor de berekening van het notabedrag. Het berekende v_effectief_bedrag_rv is niet te gebruiken
      -- omdat dat voor de dekkingswaarde berekening wordt gebruikt en met de dekkingsprijs berekend is.
      omrekenen_bv_rv (v_effectief_bedrag_bv, v_effectief_bedrag_rv_cr_voor);

      -- als eerste de calculation lines bepalen voor de doorgegeven combinatie:
      bepalen_calc_lines (i_ordernummer, i_orderregel, i_orderdetailnr, gv_pr_id, 
                          gv_fonds_id, v_transactie_soort, gv_context, v_prod_conv_id, v_te_doorlopen_amount_types, v_bsp_instapfee_aanwezig);

      gv_bsp_instapfee_aanwezig := v_bsp_instapfee_aanwezig;

      -- aansluitend de calculation lines doorlopen als er iets is vastgelegd in de te doorlopen amount types:
      order_kosten_berekenen (i_ordernummer,             i_orderregel,                i_orderdetailnr,           v_effectief_bedrag_rv_cr_voor,
                              v_effectief_bedrag_bv,     v_effectief_bedrag_transval, v_rente_bedrag_transval,   v_rente_bedrag_bv,
                              v_rente_bedrag_rv,         v_order_aantal,              v_klantprijs,              v_beursprijs,
                              i_fondskoers_comb_order,   v_te_doorlopen_amount_types, v_transactie_soort,        v_transactie_soort_tb_waarde,
                              v_fonds_prijs_factor,      v_fonds_ex_ass_factor,       v_order_geen_provisie,     v_order_provisie_perc_eff_wrd,
                              v_order_prov_korting_perc, v_trans_munt_mkoers,         v_order_geldrek_muntsoort, i_richting_omwisseling,
                              v_cr_effect_bedrag_rv,     v_cr_effect_bedrag_bv,       v_cr_effect_bedrag_tv);

      -- teken goed zetten als het voor context CA is met geen "normaal" effectief bedrag (afwijkende koers = 0) en alleen kosten. 
      if i_trans_context = 'CA' and i_afwijkende_koers_gebruiken = 1 and i_afwijkende_koers = 0 and v_transactie_soort = 'D' and v_cr_effect_bedrag_rv > 0
      then
         v_cr_effect_bedrag_rv := v_cr_effect_bedrag_rv * -1;
         v_cr_effect_bedrag_bv := v_cr_effect_bedrag_bv * -1;
         v_cr_effect_bedrag_tv := v_cr_effect_bedrag_tv * -1;
      end if;
      
      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Na berekeningen met calculation lines ; terug ontvangen bedragen');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag rv   : '||to_char(v_cr_effect_bedrag_rv)||' ; effectief bedrag bv : '||to_char(v_cr_effect_bedrag_bv));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag tv   : '||to_char(v_cr_effect_bedrag_tv));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Na berekeningen met calculation lines ; aanwezige effectieve bedragen van voor de berekeningen');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effect bedrag rv voor : '||to_char(v_effectief_bedrag_rv_cr_voor)||' ; effect bedrag bv voor : '||to_char(v_effectief_bedrag_bv));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effect bedrag tv voor : '||to_char(v_effectief_bedrag_transval));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
      end if;

      cr_notabedrag_berekenen (v_cr_effect_bedrag_rv, v_transactie_soort, v_notabedrag);

      -- aantal gegevens weer in variabelen opslaan zodat deze verder gebruikt kunnen worden
      select k.kst_provisie_bedrag
      into   v_provisie_bv
      from   kosten_werkbestand k
      where  k.kst_ordernummer  = i_ordernummer
      and    k.kst_orderregel   = i_orderregel
      and    k.kst_detailnummer = i_orderdetailnr;

      -- Als er instap fee is berekend, dan de effectieve bedragen overnemen om de correcte waarde te kunnen tonen
      if gv_bsp_instapfee_aanwezig = 1
      then
         v_effectief_bedrag_rv := v_cr_effect_bedrag_rv;
         v_effectief_bedrag_bv := v_cr_effect_bedrag_bv;
         v_order_aantal        := trunc((v_cr_effect_bedrag_bv / v_klantprijs / case when v_fonds_aantal_cijfers_display <> 0 then v_fonds_prijs_factor else 1 end),0);

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Zetten van variabelen voor bsp instapfee aanwezig');
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag rv : '||to_char(v_effectief_bedrag_rv)||' ; effectief bedrag bv : '||to_char(v_effectief_bedrag_bv));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order aantal        : '||to_char(v_order_aantal));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
         end if;
      end if;

      -- als is aangegeven dat uitgangspunt van de berekeningen 2 of 4 is dan het aangeleverde notabedrag gebruiken, wel teken goed zetten
      -- het teken wordt bepaald aan de hand van het berekende notabedrag..
      if i_uitgangspunt_berekening in (2,4)
      then
         -- Nog omrekenen in de relatievaluta. Het hier gebruikte notabedrag is namelijk in de fondsvaluta.
         select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_order_notabedrag,  gv_trans_munt_reciproke, gv_trans_munt_factor,
                                                   gv_trans_munt_koers, gv_trans_munt_koers,    gv_rel_rapp_reciproke,
                                                   gv_rel_rapp_factor,  gv_relatie_munt_koers,  gv_relatie_munt_koers,
                                                   gv_rel_rapp_notatie)
         into   v_order_notabedrag
         from   dual;

         if v_notabedrag <=0
         then
            v_notabedrag := -1 * abs(v_order_notabedrag);
         else
            v_notabedrag := abs(v_order_notabedrag);
         end if;
      end if;

      update kosten_werkbestand k
      set    k.kst_notabedrag         = v_notabedrag,
             k.kst_effect_bedrag_bv   = v_effectief_bedrag_bv,
             k.kst_effect_bedrag_rv   = v_effectief_bedrag_rv,
             k.kst_trans_prijs        = v_klantprijs,
             k.kst_dekk_prijs         = v_dekkingsprijs,
             k.kst_provisie_bedrag    = v_provisie_bv,
             k.kst_trans_aantal       = case when gv_bsp_instapfee_aanwezig = 1 then v_order_aantal else k.kst_trans_aantal end
      where  k.kst_ordernummer        = i_ordernummer
      and    k.kst_orderregel         = i_orderregel
      and    k.kst_detailnummer       = i_orderdetailnr;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'notabedrag : '||to_char(v_notabedrag)||' ; effectief bedrag bv : '||to_char(v_effectief_bedrag_bv));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag rv : '||to_char(v_effectief_bedrag_rv)||
                                                 ' ; uitgangspunt berekening : '||to_char(i_uitgangspunt_berekening));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'notabedrag verkoop als koop behandelen : '||to_char(o_nb_verk_als_koop_behandelen));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'einde procedure notabedrag_bereken');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
      end if;

   end if; -- einde van wel notabedrag berekenen en niet alleen effectief bedrag

end notabedrag_bereken;
-- EINDE CODE PROCEDURE NOTABEDRAG_BEREKEN


-- DE CODE VOOR DE PROCEDURE EFF_BEDRAG_BEREKENEN
-- In deze functie wordt het effectieve bedrag berekend aan de hand van de aangeleverde
-- gegevens. Dit wordt gebruikt bij het bepalen van het geschatte notabedrag voor de lopende orders.
procedure eff_bedrag_berekenen
(i_aantal                     in  orders.ord_aantal%type
,i_prijs                      in  orders.ord_limiet%type
,i_trans_indicatie            in  orders.ord_transactiesoort%type
,i_tr_fonds_ex_as_factor      in  beleggingsinstrument.be_exass_factor%type
,i_tr_fonds_be_bi_nummer      in  beleggingsinstrument.be_bi_nummer%type
,i_ow_be_bi_nummer            in  beleggingsinstrument.be_bi_nummer%type
,i_tr_fonds_block_size        in  beleggingsinstrument.be_prijs_factor%type
,i_tr_fonds_omw_factor        in  beleggingsinstrument.be_aantal_te_ontvangen%type
,i_aantal_cijfers_display     in  beleggingsinstrument.be_aantal_cijfers_display%type
,i_tr_fonds_prijs_factor      in  beleggingsinstrument.be_prijs_factor%type
,i_rentebedrag                in  transakties.tr_rente%type
,i_transactie_muntsrt_notatie in  muntsoorten.mu_notatie%type
,i_order_keuze                in  orders.ord_keuze%type
,o_effectief_bedrag           out transakties.tr_notabedrag%type
)

is

 v_effectief_bedrag             transakties.tr_notabedrag%type;

begin
  -- Bepalen van het effectieve bedrag:

  -- aantal * prijs:
  if i_aantal_cijfers_display <> 0
  then
     v_effectief_bedrag := i_aantal * i_tr_fonds_prijs_factor * i_prijs;
  else
     v_effectief_bedrag := i_aantal * i_prijs;
  end if;

  -- Aanpassingen mbt de transactiesoort
  -- exercise en assignment:
  if i_trans_indicatie in ('EX C','EX P','AS C', 'AS P')
  then
     v_effectief_bedrag := v_effectief_bedrag * i_tr_fonds_ex_as_factor;
  end if;

  -- Obligatie: K/V/KN/VN/EMIS en ook D/L/O:
  if ((i_trans_indicatie in ('K','KN','V','VN','EMIS','L','D','O')
       or
       i_trans_indicatie = 'OMWL' and i_order_keuze = 'WISO')
      and i_tr_fonds_be_bi_nummer between 200 and 299)
     or
     (i_trans_indicatie in ('EX C','EX P','AS C', 'AS P','UITK')
      and i_ow_be_bi_nummer between 200 and 299)
     or
     i_trans_indicatie = 'AFL'
  then
     v_effectief_bedrag := v_effectief_bedrag/100;
  end if;

  -- koop, verkoop van opties, futures ook D,L en O bij opties (2000,3999)
  if i_trans_indicatie in ('OK','SK','OV','SV')
     or
     (i_trans_indicatie in ('L','D','O') and i_tr_fonds_be_bi_nummer between 2000 and 3999)
  then
     v_effectief_bedrag := v_effectief_bedrag * i_tr_fonds_block_size;
  end if;

  -- omwisseling
  if i_trans_indicatie = 'OMWL' and i_order_keuze <> 'WISO' or i_trans_indicatie = 'OMWS'
  then
     v_effectief_bedrag := v_effectief_bedrag/i_tr_fonds_omw_factor;
  end if;

  -- afronden
  v_effectief_bedrag := round(v_effectief_bedrag,i_transactie_muntsrt_notatie);

  -- voor obligaties, de lopende rente er bij op tellen:
  if ((i_trans_indicatie in ('K','KN','V','VN','EMIS','L','D','O')
       or
       i_trans_indicatie = 'OMWL' and i_order_keuze = 'WISO')
      and i_tr_fonds_be_bi_nummer between 200 and 299)
     or
     (i_trans_indicatie in ('EX C','EX P','AS C', 'AS P','UITK')
      and i_ow_be_bi_nummer between 200 and 299)
     or
     i_trans_indicatie = 'AFL'
  then
     v_effectief_bedrag := v_effectief_bedrag + i_rentebedrag ;
  end if;

  o_effectief_bedrag := v_effectief_bedrag;

end eff_bedrag_berekenen;
-- EINDE CODE PROCEDURE EFF_BEDRAG_BEREKENEN


-- DE CODE VOOR DE PROCEDURE EFFECTIEF_BEDRAG_BER
-- Deze procedure is een onderdeel van de procedures waarbij het geschatte notabedrag van
-- een order wordt bepaalt.
procedure effectief_bedrag_ber
(i_trans_indicatie            in  transakties.tr_indicatie%type
,i_aantal                     in  transakties.tr_aantal%type
,i_prijs                      in  transakties.tr_prijs_tr_mntsrt%type
,i_beursprijs                 in  transakties.tr_prijs_tr_mntsrt%type
,i_rentebedrag                in  transakties.tr_rente%type
,i_trans_muntsrt_notatie      in  muntsoorten.mu_notatie%type
,i_tr_fonds_be_bi_nummer      in  beleggingsinstrument.be_bi_nummer%type
,i_tr_fonds_block_size        in  beleggingsinstrument.be_prijs_factor%type
,i_tr_fonds_ex_as_factor      in  beleggingsinstrument.be_exass_factor%type
,i_tr_fonds_omw_factor        in  beleggingsinstrument.be_aantal_te_ontvangen%type
,i_tr_fonds_prijs_factor      in  beleggingsinstrument.be_prijs_factor%type
,i_aantal_cijfers_display     in  beleggingsinstrument.be_aantal_cijfers_display%type
,i_ow_be_bi_nummer            in  beleggingsinstrument.be_bi_nummer%type
,i_order_keuze                in  orders.ord_keuze%type
,o_effectief_bedrag           out transakties.tr_notabedrag%type
,o_effectief_bedrag_beurspr   out transakties.tr_notabedrag%type
)

-- inkomende parameters zijn: i_trans_indicatie            = de transactie indicatie in alpha formaat (dus K, V, etc)
--                            i_aantal                     = het aantal waarvoor het effectieve bedrag berekend moet worden
--                            i_prijs                      = de prijs waarmee het effectieve bedrag berekend moet worden
--                            i_beursprijs                 = de beursprijs waarmee het effectieve bedrag berekend moet worden (netto transacties)
--                            i_rentebedrag                = de lopende rente van de transactie/order
--                            i_trans_muntsrt_notatie      = de muntnotatie van de transactie munt
--                            i_tr_fonds_be_bi_nummer      = het be_bi_nummer van het transactie/order fonds
--                            i_tr_fonds_block_size        = de blocksize van het transactie/order fonds
--                            i_tr_fonds_ex_as_factor      = de exercise/assignment factor van het transactie/order fonds
--                            i_tr_fonds_omw_factor        = de omwisselingsfactor van het transactie/order fonds
--                            i_ow_be_bi_nummer            = het be_bi_nummer van de onderliggende waarde van het transactie/order fonds
-- uitgaande parameters zijn: o_effectief_bedrag           = de berekende waarde voor het effectieve bedrag
--                            o_effectief_bedrag_beurspr   = de berekende waarde voor het effectieve bedrag berekend met de beursprijs
--                                                           nb deze kan ook gelijk zijn aan effectief bedrag als prijs = beursprijs geldt.

is

begin

     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure FIAT_NOTABEDRAG.effectief_bedrag_ber');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'trans indicatie        : '||i_trans_indicatie||' ; aantal : '||to_char(i_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'prijs                  : '||to_char(i_prijs)||' ; beursprijs : '||to_char(i_beursprijs));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'rente bedrag           : '||to_char(i_rentebedrag)||' ; trans munt notatie : '||to_char(i_trans_muntsrt_notatie));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fonds be_bi_nummer     : '||to_char(i_tr_fonds_be_bi_nummer)||' ; block size : '||to_char(i_tr_fonds_block_size));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ex as factor           : '||to_char(i_tr_fonds_ex_as_factor)||' ; omw factor : '||to_char(i_tr_fonds_omw_factor));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ow be_bi_nummer        : '||to_char(i_ow_be_bi_nummer)||' ; fonds prijs factor : '||to_char(i_tr_fonds_prijs_factor));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'aantal cijfers display : '||to_char(i_aantal_cijfers_display)||' ; order keuze : '||to_char(i_order_keuze));
     end if;

     -- outgoing bedragen en hulpvariabelen op 0 zetten.
     o_effectief_bedrag         := 0;
     o_effectief_bedrag_beurspr := 0;

     -- Bijstellingen zijn het rentebedrag
     if i_trans_indicatie = 'BYST'
     then
        o_effectief_bedrag := i_rentebedrag;
     end if;

     -- Voor niet futures komt  het onderstaande if statement:
     if i_tr_fonds_be_bi_nummer < 2900 or i_tr_fonds_be_bi_nummer >= 3000
     then
        eff_bedrag_berekenen(i_aantal,                 i_prijs,                 i_trans_indicatie,     i_tr_fonds_ex_as_factor,
                             i_tr_fonds_be_bi_nummer,  i_ow_be_bi_nummer,       i_tr_fonds_block_size, i_tr_fonds_omw_factor,
                             i_aantal_cijfers_display, i_tr_fonds_prijs_factor, i_rentebedrag,         i_trans_muntsrt_notatie,
                             i_order_keuze,            o_effectief_bedrag);

        if i_prijs <> i_beursprijs
        then
           eff_bedrag_berekenen(i_aantal,                 i_beursprijs,                i_trans_indicatie,     i_tr_fonds_ex_as_factor,
                                i_tr_fonds_be_bi_nummer,  i_ow_be_bi_nummer,           i_tr_fonds_block_size, i_tr_fonds_omw_factor,
                                i_aantal_cijfers_display, i_tr_fonds_prijs_factor,     i_rentebedrag,         i_trans_muntsrt_notatie,
                                i_order_keuze,            o_effectief_bedrag_beurspr);
        else
           o_effectief_bedrag_beurspr := o_effectief_bedrag;
        end if;
     end if;

     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure FIAT_NOTABEDRAG.effectief_bedrag_ber');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'o_effectief_bedrag : '||to_char(o_effectief_bedrag)||' ; o_effectief_bedrag_beuspr : '||to_char(o_effectief_bedrag_beurspr));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
     end if;

end effectief_bedrag_ber;
-- EINDE CODE PROCEDURE EFFECTIEF_BEDRAG_BER


-- DE CODE VOOR DE PROCEDURE KOST_COMP_BEREKEN
-- In deze procedure wordt de waarde van de kosten componenten en de provisie berekend voor
-- de opgegeven order.
-- Voor de provisie wordt gebruik gemaakt van een aanroep naar een andere procedure.
-- Vergelijk Magic programma 257 CALC-Kosten, subtaak 2 voor de bepaling van de kostencomponenten bedragen.

   -- LET OP deze procedure is niet te gebruiken voor ALEX:
   -- De orderbehandelkosten zijn niet meegenomen in deze procedure!!!!
procedure kost_comp_bereken
(i_ordernummer               in  orders.ord_ordernummer%type
,i_orderregel                in  orders.ord_orderregel%type
,i_orderdetailnr             in  ordersdetaillering.orx_detailnummer%type
,i_effectief_bv              in  kosten_werkbestand.kst_effect_bedrag_bv%type
,i_effectief_vv              in  kosten_werkbestand.kst_effect_bedrag_bv%type
,i_trans_prijs               in  kosten_werkbestand.kst_trans_prijs%type
,i_fondskoers_comb_order     in  fn_quotes_vw.quot_bied%type
,o_bedrag_voor_brutobedrag   out transakties.tr_notabedrag%type
)

is
   -- variabelen uit en voor het kostenwerkbestand
   v_provisie_bedrag            kosten_werkbestand.kst_provisie_bedrag%type;
   v_provisie_tabel_code        kosten_werkbestand.kst_prov_code_tabel%type;
   v_provisie_vaste_kosten      kosten_werkbestand.kst_vaste_kosten%type;
   v_provisie_variabele_kosten  kosten_werkbestand.kst_variabele_kosten%type;
   v_provisie_korting           kosten_werkbestand.kst_provisie_korting%type;
   v_provisie_type              kosten_werkbestand.kst_provisie_type%type;
   v_trans_kortingbedrag        kosten_werkbestand.kst_trans_kort_bedrag%type;
   v_minimum_prov_tabel_waarde  kosten_werkbestand.kst_mini_prov_t_bedr%type;
   v_maximum_prov_tabel_waarde  kosten_werkbestand.kst_max_prov_t_bedr%type;
   v_corrigeren_naar_min_max    kosten_werkbestand.kst_corr_naar_min_max%type;
   v_maximaal_provisie_perc     relatie_fiattering.rf_max_prov_perc%type;
   v_fondssymbool               beleggingsinstrument.be_symbool%type;
   v_fonds_optie_type           beleggingsinstrument.be_optietype%type;
   v_expiratiedatum             beleggingsinstrument.be_expiratiedatum%type;
   v_exerciseprijs              beleggingsinstrument.be_exerciseprijs%type;
   v_prijs_bv                   fn_quotes_vw.quot_bied%type;
   v_fonds_bi_nummer            beleggingsinstrument.be_bi_nummer%type;
   v_fonds_be_nominaal          beleggingsinstrument.be_nominaal%type;
   v_fonds_exec_ass_factor      beleggingsinstrument.be_exass_factor%type;
   v_courtage_bedrag            transakties.tr_courtage%type;
   v_relatienummer              clienten.cl_nummer%type;
   v_trans_aantal               kosten_werkbestand.kst_trans_aantal%type;
   v_effectief_bedrag_bv        kosten_werkbestand.kst_effect_bedrag_bv%type;
   v_trans_indicatie            kosten_werkbestand.kst_trans_indicatie%type;
   v_trans_indicatie_tb_waarde  kosten_werkbestand.kst_trans_indicatie_w%type;
   v_trans_muntsoort            muntsoorten.mu_code%type;
   v_waarde_kost_corr_comp      kosten_werkbestand.kst_kost_corr_doorb%type;
   v_werk_transactie_aantal     kosten_werkbestand.kst_trans_aantal%type;
   v_werk_muntsoort             muntsoorten.mu_code%type;
   v_werk_muntsrt_koers         muntsoorten.mu_biedkoers%type;
   v_werk_muntsrt_factor        muntsoorten.mu_factor%type;
   v_werk_muntsrt_reciproke     muntsoorten.mu_reciproke%type;
   v_minimum_bedrag_bv          componentformules.cf_minimum_bedrag%type;
   v_component_bied_koers       muntsoorten.mu_biedkoers%type;
   v_component_midden_koers     muntsoorten.mu_middenkoers%type;
   v_component_laat_koers       muntsoorten.mu_laatkoers%type;
   v_component_munt_factor      muntsoorten.mu_factor%type;
   v_component_munt_recip       muntsoorten.mu_reciproke%type;
   v_component_bedrag           kosten_werkbestand.kst_kost_corr_doorb%type;
   v_reken_provisie_bedrag      kosten_werkbestand.kst_provisie_bedrag%type;
   v_service_profiel_print      serviceprf_clientoutput.spc_print%type;
   v_aantal_kopie_dagafschr     number(4);
   v_dummy                      number(1);

begin
   --initialiseren van de gebruikte waarden:

   -- als er geen kostencomponent worden gevonden dan blijft de waarde -1:
   v_waarde_kost_corr_comp     := -1;
   v_reken_provisie_bedrag     := 0;
   o_bedrag_voor_brutobedrag   := 0;

   -- als eerste de provisie berekenen via provisie_bereken
   -- de gegevens van de provisie worden in het kosten_werkbestand weggeschreven.
   provisie_bereken (i_ordernummer, i_orderregel, i_orderdetailnr, i_effectief_bv, i_effectief_vv, i_trans_prijs);

   select k.kst_provisie_bedrag,       k.kst_prov_code_tabel,       k.kst_provisie_type,
          k.kst_mini_prov_t_bedr,      k.kst_max_prov_t_bedr,       k.kst_corr_naar_min_max,
          k.kst_trans_indicatie,       k.kst_trans_indicatie_w,     k.kst_trans_aantal,
          k.kst_bi_nummer,             k.kst_fondssymbool,          k.kst_optietype_fnds,
          k.kst_expiratiedat_fnds,     k.kst_exercisepr_fnds,       k.kst_fnds_nominaal,
          k.kst_fnds_ex_ass_fac,       k.kst_trans_muntsrt,         k.kst_vaste_kosten,
          k.kst_variabele_kosten,      k.kst_provisie_korting,      k.kst_relatie_nummer,
          k.kst_effect_bedrag_bv,      k.kst_trans_kort_bedrag,     k.kst_courtage_bedrag
   into   v_provisie_bedrag,           v_provisie_tabel_code,       v_provisie_type,
          v_minimum_prov_tabel_waarde, v_maximum_prov_tabel_waarde, v_corrigeren_naar_min_max,
          v_trans_indicatie,           v_trans_indicatie_tb_waarde, v_trans_aantal,
          v_fonds_bi_nummer,           v_fondssymbool,              v_fonds_optie_type,
          v_expiratiedatum,            v_exerciseprijs,             v_fonds_be_nominaal,
          v_fonds_exec_ass_factor,     v_trans_muntsoort,           v_provisie_vaste_kosten,
          v_provisie_variabele_kosten, v_provisie_korting,          v_relatienummer,
          v_effectief_bedrag_bv,       v_trans_kortingbedrag,       v_courtage_bedrag
   from   kosten_werkbestand k
   where  k.kst_ordernummer        = i_ordernummer
   and    k.kst_orderregel         = i_orderregel
   and    k.kst_detailnummer       = i_orderdetailnr;

   -- de werk muntsoort eerst op de basisvaluta zetten
   v_werk_muntsoort         := gv_basis_valuta;
   v_werk_muntsrt_koers     := gv_basis_val_biedkoers;
   v_werk_muntsrt_factor    := gv_basis_val_factor;
   v_werk_muntsrt_reciproke := gv_basis_val_reciproke;

   -- Verder gaan als de provisie tabel is gevonden: kostencomponenten doorlopen
   if   v_provisie_tabel_code <> ' '
   then
      -- werk transactie aantal bepalen:
      v_werk_transactie_aantal := v_trans_aantal;

      if v_fonds_bi_nummer between 200 and 299
      then
         v_werk_transactie_aantal := v_trans_aantal/v_fonds_be_nominaal;
      end if;

      if v_trans_indicatie in ('EX C','EX P','AS C','AS P')
      then
         v_werk_transactie_aantal := v_trans_aantal/v_fonds_exec_ass_factor;
      end if;

      -- Door de schalen tabel lopen voor het bepalen van de verschillende kosten componenten
      -- die aan de provisietabel zijn gerelateerd.
      declare
         cursor st is
             select s.st_type,      c.cf_categorie,         c.cf_berekening,
                    c.cf_muntsoort, c.cf_bedrag_percentage, c.cf_minimum_bedrag
             from   schalen_tabel s, componentformules c
             where  s.st_soort   = 'PROVCOMP'
             and    s.st_pr_code = v_provisie_tabel_code
             and    s.st_type    = c.cf_itemnummer
             and    s.st_type    between 2001 and 2003
             order by c.cf_muntsoort;
             -- let op bovenstaand is een inner join (zo laten)!
      begin
         for r_st in st
         loop
            -- de muntkoers en andere muntgegevens per wisseling van de muntsoort bepalen
            if v_werk_muntsoort <> r_st.cf_muntsoort and r_st.cf_muntsoort <> ' '
               or
               v_werk_muntsoort <> gv_basis_valuta and r_st.cf_muntsoort = ' '
            then
               if v_werk_muntsoort <> gv_basis_valuta and (r_st.cf_muntsoort = gv_basis_valuta or r_st.cf_muntsoort = ' ')
               then
                  v_werk_muntsoort         := gv_basis_valuta;
                  v_werk_muntsrt_factor    := gv_basis_val_factor;
                  v_werk_muntsrt_reciproke := gv_basis_val_reciproke;
                  v_werk_muntsrt_koers     := gv_basis_munt_koers;
               end if;

               if v_werk_muntsoort <> v_trans_muntsoort and r_st.cf_muntsoort = v_trans_muntsoort
               then
                  v_werk_muntsoort         := v_trans_muntsoort;
                  v_werk_muntsrt_factor    := gv_trans_munt_factor;
                  v_werk_muntsrt_reciproke := gv_trans_munt_reciproke;
                  v_werk_muntsrt_koers     := gv_trans_munt_koers;
               end if;

               if v_werk_muntsoort <> r_st.cf_muntsoort and r_st.cf_muntsoort not in (v_trans_muntsoort, gv_basis_valuta)
               then
                  FIAT_ALGEMEEN.valutagegevens_bepalen (r_st.cf_muntsoort,        gv_pr_id,               gv_ppr_id,               gv_sys_spread_categorie,
                                                        gv_bank2marketchangedate, gv_debuggen,            gv_debug_user,           v_component_bied_koers,
                                                        v_component_midden_koers, v_component_laat_koers, v_component_munt_factor, v_component_munt_recip,
                                                        v_dummy);

                  v_werk_muntsoort         := r_st.cf_muntsoort;
                  v_werk_muntsrt_factor    := v_component_munt_factor;
                  v_werk_muntsrt_reciproke := v_component_munt_recip;

                  FIAT_ALGEMEEN.muntkoers_bepalen (v_trans_indicatie_tb_waarde, 0,                      v_component_munt_recip, v_component_bied_koers,
                                                   v_component_midden_koers,    v_component_laat_koers, v_werk_muntsrt_koers);
               end if;
            end if;

            -- resetten van het component bedrag
            v_component_bedrag  := 0;
            v_minimum_bedrag_bv := 0; -- voor berekeningtype 7

            -- bepalen van de component bedragen aan de hand van het type berekening:

            -- 1 = vaste kosten,
            -- 2 = variabele kosten,
            -- 3 = provisiekorting.
            -- Deze bedragen zijn al berekend in de provisie berekening, dus de gegevens hier gewoon overnemen.
            if r_st.cf_berekening in (1,2,3)
            then
               select decode(r_st.cf_berekening, 1, v_provisie_vaste_kosten, 2, v_provisie_variabele_kosten, 3, v_provisie_korting, 0)
               into   v_component_bedrag
               from   dual;

               -- teken omdraaien voor 3 provisiekorting:
               if r_st.cf_berekening = 3
               then
                  v_component_bedrag := -1 * v_component_bedrag;
               end if;

               if gv_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'kosten component  : '||to_char(r_st.st_type)||' ; component bedrag : '||to_char(v_component_bedrag));
               end if;
            end if;

            -- 4 = Bedrag per transactie
            if r_st.cf_berekening = 4
            then
               v_component_bedrag := r_st.cf_bedrag_percentage;
               if v_werk_muntsoort <> gv_basis_valuta
               then
                  select FIAT_ALGEMEEN.omrekenen_bedrag (v_component_bedrag, v_werk_muntsrt_reciproke, v_werk_muntsrt_factor,
                                                         v_werk_muntsrt_koers, v_werk_muntsrt_koers, 2)
                  into   v_component_bedrag
                  from   dual;
               end if;
               v_component_bedrag := round(v_component_bedrag, gv_basis_val_notatie);

               if gv_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'kosten component  : '||to_char(r_st.st_type)||' ; component bedrag : '||to_char(v_component_bedrag));
               end if;
            end if;

            -- 5 = Bedrag per Stuk/Nominaal/Contract
            if r_st.cf_berekening = 5
            then
               v_component_bedrag := v_werk_transactie_aantal * r_st.cf_bedrag_percentage;
               if v_werk_muntsoort <> gv_basis_valuta
               then
                  select FIAT_ALGEMEEN.omrekenen_bedrag (v_component_bedrag, v_werk_muntsrt_reciproke, v_werk_muntsrt_factor,
                                                         v_werk_muntsrt_koers, v_werk_muntsrt_koers, 2)
                  into   v_component_bedrag
                  from   dual;
               end if;
               v_component_bedrag := round(v_component_bedrag, gv_basis_val_notatie);

               if gv_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'kosten component  : '||to_char(r_st.st_type)||' ; component bedrag : '||to_char(v_component_bedrag));
               end if;
            end if;

            -- 6 Bedrag per kopie dagafschrift
            if r_st.cf_berekening = 6
            then
               v_aantal_kopie_dagafschr := 0;
               -- bepalen van het aantal kopien dagafschriften
               begin
                   select s.spc_print
                   into   v_service_profiel_print
                   from   serviceprf_clientoutput s
                   where  s.spc_relatie    = v_relatienummer
                   and    s.spc_form_soort = 2;
               exception
                   when no_data_found
                   then
                      v_service_profiel_print := 0;
               end;

               if v_service_profiel_print = 3
               then
                  begin
                      select count(*)
                      into   v_aantal_kopie_dagafschr
                      from   rm_addresses v
                      where  v.adrs_clientnummer = v_relatienummer
                      and    v.adrs_form_soort   = 2
                      and    v.adrs_zendnummer   <>1;
                  exception
                      when no_data_found
                      then
                         v_aantal_kopie_dagafschr := 0;
                  end;
               elsif v_service_profiel_print = 1
               then
                  begin
                      select count(*)
                      into   v_aantal_kopie_dagafschr
                      from   rm_addresses v
                      where  v.adrs_clientnummer = v_relatienummer
                      and    v.adrs_form_soort   = 2;
                  exception
                      when no_data_found
                      then
                         v_aantal_kopie_dagafschr := 0;
                  end;
               end if;

               v_component_bedrag := v_aantal_kopie_dagafschr * r_st.cf_bedrag_percentage;
               if v_werk_muntsoort <> gv_basis_valuta
               then
                  select FIAT_ALGEMEEN.omrekenen_bedrag (v_component_bedrag, v_werk_muntsrt_reciproke, v_werk_muntsrt_factor,
                                                         v_werk_muntsrt_koers, v_werk_muntsrt_koers, 2)
                  into   v_component_bedrag
                  from   dual;
               end if;
               v_component_bedrag := round(v_component_bedrag, gv_basis_val_notatie);

               if gv_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'kosten component  : '||to_char(r_st.st_type)||' ; component bedrag : '||to_char(v_component_bedrag));
               end if;
            end if;

            -- 7 Percentage van het effectief bedrag: Effectief bedrag is al in BV (dus er hoeft niet omgerekend te worden)
            -- Er wordt het maximim genomen van het ingevoerde minimum bedrag en het berekende component bedrag
            if r_st.cf_berekening = 7
            then
                -- Als het een combinatie Limiet order betreft, hier de premie (koers) van de optie gebruiken
                -- om met het juiste premiebedrag de provisie tabel te gaan bepalen. Dit omdat bij combinatie limietorders
                -- juist het verschil in premies (of de optelling van de premies) wordt opgeslagen in kosten_werkbestand.
                if gv_order_type in ('COMB','VZCO') and gv_order_soort = 'L'
                then
                   if v_trans_muntsoort <> gv_basis_valuta
                   then
                      select FIAT_ALGEMEEN.omrekenen_bedrag (i_fondskoers_comb_order, gv_trans_munt_reciproke, gv_trans_munt_factor,
                                                             gv_trans_munt_koers, gv_trans_munt_koers, gv_trans_munt_notatie)
                      into   v_prijs_bv
                      from   dual;
                   else
                      v_prijs_bv := i_fondskoers_comb_order;
                   end if;

                   -- berekenen van het effectief bedrag voor de leg:
                   v_effectief_bedrag_bv := round(v_werk_transactie_aantal * v_prijs_bv * v_fonds_exec_ass_factor,gv_basis_val_notatie);
                end if;

               v_component_bedrag := round(v_effectief_bedrag_bv * (r_st.cf_bedrag_percentage / 100),gv_basis_val_notatie);

               if r_st.cf_muntsoort <> gv_basis_valuta and r_st.cf_minimum_bedrag <> 0
               then
                  select FIAT_ALGEMEEN.omrekenen_bedrag (r_st.cf_minimum_bedrag, v_werk_muntsrt_reciproke, v_werk_muntsrt_factor,
                                                         v_werk_muntsrt_koers,   v_werk_muntsrt_koers,     gv_basis_val_notatie)
                  into   v_minimum_bedrag_bv
                  from   dual;
               elsif r_st.cf_muntsoort = gv_basis_valuta and r_st.cf_minimum_bedrag <> 0
               then
                  v_minimum_bedrag_bv := round(r_st.cf_minimum_bedrag,gv_basis_val_notatie);
               end if;

               if v_minimum_bedrag_bv <> 0 and v_minimum_bedrag_bv > v_component_bedrag
               then
                  v_component_bedrag := v_minimum_bedrag_bv;
               end if;

               if gv_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'kosten component  : '||to_char(r_st.st_type)||' ; component bedrag : '||to_char(v_component_bedrag));
               end if;
            end if;

            -- 8 beurscourtage
            if r_st.cf_berekening = 8
            then
               v_component_bedrag := round(v_courtage_bedrag, gv_basis_val_notatie);

               if gv_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'kosten component  : '||to_char(r_st.st_type)||' ; component bedrag : '||to_char(v_component_bedrag));
               end if;
            end if;

            -- 9 Orderbehandeling (is alleen voor ALEX, dus hier niet verder uitgewerkt).

            -- Verdere verwerking van het component bedrag.
            -- Berekenen totale provisie
            v_reken_provisie_bedrag := v_reken_provisie_bedrag + v_component_bedrag;

            -- Doorberekende kosten correspondent en Stamp Duty:
            if r_st.cf_categorie in ('K','S')
            then
               -- Als er nog geen kosten componenten zijn geweest (waarde = -1) dan hier
               -- de waarde op 0 initialiseren!
               if v_waarde_kost_corr_comp = -1
               then
                  v_waarde_kost_corr_comp := 0;
               end if;
               v_waarde_kost_corr_comp := v_waarde_kost_corr_comp + v_component_bedrag;
            end if;

         -- Einde van de loop door de schalentabel heen
         end loop;
      end;

      v_provisie_bedrag := v_reken_provisie_bedrag;

      -- Nog mogelijke kortingen doorberekenen als het effectief bedrag bv niet 0 is.
      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in FIAT_NOTABEDRAG.kost_comp_bereken voor mogelijke kortingen');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provisie             : '||to_char(v_provisie_bedrag));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag bv  : '||to_char(v_effectief_bedrag_bv)||' ; fonds bi nummer : '||to_char(v_fonds_bi_nummer));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'maximeer opties prov : '||gv_maximeer_opties_prov||' ; maximeer effecten prov : '||gv_maximeer_effecten_prov);
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'maximeer opties perc : '||to_char(gv_max_optie_prov_percentage)||
                                                 ' ; maximeer effecten perc : '||to_char(gv_max_provisie_percentage));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'trans indicatie tb waarde : '||to_char(v_trans_indicatie_tb_waarde));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
      end if;

      if v_effectief_bedrag_bv <> 0 or v_fonds_optie_type = 'FUT'
         or
         v_effectief_bedrag_bv = 0 and gv_order_type in ('COMB','VZCO')
      then
         -- Als in EB ingesteld is dat MIN/MAX provisie over het totale provisiebedrag gelden,
         -- dan hier de componenten corrigeren naar de minimum/maximum provisie (in plaats van in CALC-Provisie).
         if v_corrigeren_naar_min_max = 1
         then
            -- Aanpassen aan Minimum provisie
            if gv_minimum_prov_rel_gebr = 1 and v_provisie_bedrag - (case when v_waarde_kost_corr_comp<0 then 0 else v_waarde_kost_corr_comp end) < v_minimum_prov_tabel_waarde
            then
               v_provisie_bedrag := v_minimum_prov_tabel_waarde + (case when v_waarde_kost_corr_comp<0 then 0 else v_waarde_kost_corr_comp end);
            end if;

            -- Aanpassen aan Maximum provisie
            if v_provisie_bedrag - (case when v_waarde_kost_corr_comp<0 then 0 else v_waarde_kost_corr_comp end) > v_maximum_prov_tabel_waarde
               and v_maximum_prov_tabel_waarde <> 0
            then
               v_provisie_bedrag := v_maximum_prov_tabel_waarde + (case when v_waarde_kost_corr_comp<0 then 0 else v_waarde_kost_corr_comp end);
            end if;
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Na aanpassen aan minimum/maximum provisie; provisie bedrag : '||to_char(v_provisie_bedrag));
         end if;

         -- dit overslaan als het effectief bedrag 0 is
         if v_effectief_bedrag_bv <> 0
         then
            -- Provisie aanpassen aan Maximum Provisiepercentage
            v_maximaal_provisie_perc := 0;
            if v_fonds_bi_nummer between 2000 and 3999 and v_fonds_optie_type <> 'FUT' and
               (gv_maximeer_opties_prov <> 'A' or gv_maximeer_opties_prov = 'A' and v_trans_indicatie_tb_waarde = 2)
            then
               v_maximaal_provisie_perc := gv_max_optie_prov_percentage;
            end if;

            if v_fonds_bi_nummer not between 2000 and 3999 and
               (gv_maximeer_effecten_prov <> 'A' or gv_maximeer_effecten_prov = 'A' and v_trans_indicatie_tb_waarde = 2)
            then
               v_maximaal_provisie_perc := gv_max_provisie_percentage;
            end if;

            if v_provisie_bedrag - (case when v_waarde_kost_corr_comp<0 then 0 else v_waarde_kost_corr_comp end) > v_effectief_bedrag_bv * v_maximaal_provisie_perc/100
               and v_maximaal_provisie_perc <> 0
            then
               v_provisie_bedrag := v_effectief_bedrag_bv * v_maximaal_provisie_perc/100 + (case when v_waarde_kost_corr_comp<0 then 0 else v_waarde_kost_corr_comp end);
            end if;
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Na aanpassen aan maximum provisie percentage; provisie bedrag : '||to_char(v_provisie_bedrag));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
         end if;

         -- Automatiseringkorting
         if v_provisie_bedrag - v_trans_kortingbedrag - (case when v_waarde_kost_corr_comp<0 then 0 else v_waarde_kost_corr_comp end) > 0 and v_trans_kortingbedrag <> 0
         then
            v_provisie_bedrag := v_provisie_bedrag - v_trans_kortingbedrag;
         end if;
      end if;
   end if;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Einde procedure kost_comp_bereken');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Provisie bedrag : '||to_char(v_provisie_bedrag)||' ; kosten correspondent doorbelast : '||to_char(v_waarde_kost_corr_comp));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

   update kosten_werkbestand
   set    kst_provisie_bedrag   = v_provisie_bedrag,
          kst_kost_corr_doorb   = v_waarde_kost_corr_comp
   where  kst_ordernummer       = i_ordernummer
   and    kst_orderregel        = i_orderregel
   and    kst_detailnummer      = i_orderdetailnr;

end kost_comp_bereken;
-- EINDE CODE PROCEDURE KOST_COMP_BEREKENEN


-- DE CODE VOOR DE PROCEDURE PROV_TABEL_BEPALEN
-- procedure voor het bepalen van de provisie tabel. Ook provisietabel gerelateerde gegevens
-- worden verzameld en terug gegeven.
-- Wordt gebruikt voor het bepalen van het geschatte notabedrag bij lopende orders.
procedure prov_tabel_bepalen
(i_provisie_type            in  provtabheader.pr_type%type
,i_muntsoort                in  provtabheader.pr_muntsoort%type
,i_prov_be_nummer           in  provtabheader.pr_be_nummer%type
,i_prov_cl_nummer           in  provtabheader.pr_cl_nummer%type
,i_open_close               in  provtabheader.pr_open_close%type
,i_distributiekanaal        in  provtabheader.pr_distributiekanaal%type
,i_standaard_land           in  provtabheader.pr_std_land%type
,i_transactiesoort          in  provtabheader.pr_transactiesoort%type
,i_premie_eff_bedrag        in  provtabheader.pr_tb_min_premie%type
,i_aantal_contracten        in  provtabheader.pr_tb_min_aantal%type
,o_tabel_gevonden           out number
,o_prov_tab_code            out provtabheader.pr_code%type
,o_vaste_kosten             out provtabheader.pr_vaste_kosten%type
,o_minimum_provisie         out provtabheader.pr_min_provisie%type
,o_maximum_provisie         out provtabheader.pr_max_provisie%type
)

is
  v_tabel_gevonden            number(1);
  v_prov_tab_code             provtabheader.pr_code%type;
  v_vaste_kosten              provtabheader.pr_vaste_kosten%type;
  v_minimum_provisie          provtabheader.pr_min_provisie%type;
  v_maximum_provisie          provtabheader.pr_max_provisie%type;

begin
    v_tabel_gevonden := 1;

    begin
        select p.pr_code,       p.pr_vaste_kosten, p.pr_min_provisie,  p.pr_max_provisie
        into   v_prov_tab_code, v_vaste_kosten,    v_minimum_provisie, v_maximum_provisie
        from   provtabheader p
        where  p.pr_type              = i_provisie_type
        and    p.pr_muntsoort         = i_muntsoort
        and    p.pr_be_nummer         = i_prov_be_nummer
        and    p.pr_cl_nummer         = i_prov_cl_nummer
        and    p.pr_open_close        = i_open_close
        and    p.pr_distributiekanaal = i_distributiekanaal
        and    p.pr_std_land          = i_standaard_land
        and    p.pr_transactiesoort   = i_transactiesoort
        and    p.pr_tb_min_premie     <= i_premie_eff_bedrag
        and    p.pr_tb_max_premie     >= i_premie_eff_bedrag
        and    p.pr_tb_min_aantal     <= i_aantal_contracten
        and    p.pr_tb_max_aantal     >= i_aantal_contracten
        and    p.pr_status            <= 2
        and    rownum                 <= 1
        order by p.pr_type, p.pr_muntsoort, p.pr_be_nummer, p.pr_cl_nummer, p.pr_open_close, p.pr_distributiekanaal,
                 p.pr_code, p.pr_transactiesoort;

    exception
        when no_data_found
        then
           v_tabel_gevonden       := 0;
           v_prov_tab_code        := 0;
           v_vaste_kosten         := 0;
           v_minimum_provisie     := 0;
           v_maximum_provisie     := 0;
    end;

    o_tabel_gevonden       := v_tabel_gevonden;
    o_prov_tab_code        := v_prov_tab_code;
    o_vaste_kosten         := v_vaste_kosten;
    o_minimum_provisie     := v_minimum_provisie;
    o_maximum_provisie     := v_maximum_provisie;

    if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure FIAT_NOTABEDRAG.prov_tabel_bepal');
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i_provisie_type     : '||to_char(i_provisie_type)||' ; i_muntsoort : '||i_muntsoort);
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i_prov_be_nummer    : '||to_char(i_prov_be_nummer)||' ; i_prov_cl_nummer : '||to_char(i_prov_cl_nummer));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i_open_close        : '||to_char(i_open_close)||' ; i_distributiekanaal : '||to_char(i_distributiekanaal));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i_standaard_land    : '||to_char(i_standaard_land)||' ; i_transactiesoort : '||i_transactiesoort);
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i_premie_eff_bedrag : '||to_char(i_premie_eff_bedrag));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'o_tabel_gevonden    : '||o_tabel_gevonden||' ; o_prov_tab_code : '||o_prov_tab_code);
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'o_vaste_kosten      : '||to_char(o_vaste_kosten));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'o_minimum_provisie  : '||to_char(o_minimum_provisie)||' ; o_maximum_provisie : '||to_char(o_maximum_provisie));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'   ');
    end if;

end prov_tabel_bepalen;
-- EINDE CODE PROCEDURE PROV_TABEL_BEPALEN


-- DE CODE VOOR DE PROCEDURE PROVISIE_BEREKEN
-- Procedure voor het berekenen van de provisie voor een bepaalde order (nodig voor het bepalen
-- van het geschatte notabedrag voor die order). (zie Magic programma 197 CALC-Provisie.)
procedure provisie_bereken
(i_ordernummer              in orders.ord_ordernummer%type
,i_orderregel               in orders.ord_orderregel%type
,i_orderdetailnr            in ordersdetaillering.orx_detailnummer%type
,i_effectief_bv             in kosten_werkbestand.kst_effect_bedrag_bv%type
,i_effectief_vv             in kosten_werkbestand.kst_effect_bedrag_bv%type
,i_trans_prijs              in kosten_werkbestand.kst_trans_prijs%type
)

is
    -- variabelen uit en voor het kosten_werkbestand
    v_fondssymbool                 kosten_werkbestand.kst_fondssymbool%type;
    v_optietype                    kosten_werkbestand.kst_optietype_fnds%type;
    v_expiratiedatum               kosten_werkbestand.kst_expiratiedat_fnds%type;
    v_exerciseprijs                kosten_werkbestand.kst_exercisepr_fnds%type;
    v_standaard_land               kosten_werkbestand.kst_standaard_land%type;
    v_distributiekanaal            kosten_werkbestand.kst_distributiekanaal%type;
    v_provisie_cat_fonds           kosten_werkbestand.kst_provisie_cat_fnds%type;
    v_fonds_bi_nummer              kosten_werkbestand.kst_bi_nummer%type;
    v_ref_fonds_bi_nummer          kosten_werkbestand.kst_ref_fnds_bi_nr%type;
    v_relatienummer                clienten.cl_nummer%type;
    v_order_keuze                  kosten_werkbestand.kst_order_keuze%type;
    v_trans_indicatie              kosten_werkbestand.kst_trans_indicatie%type;
    v_trans_indicatie_num          kosten_werkbestand.kst_trans_indicatie_n%type;
    v_trans_indicatie_wrd          kosten_werkbestand.kst_trans_indicatie_w%type;
    v_trans_muntsoort              muntsoorten.mu_code%type;
    v_trans_aantal                 kosten_werkbestand.kst_trans_aantal%type;
    v_gewoon_spoed_betaling        kosten_werkbestand.kst_gewoon_spoed_bet%type;
    v_provisie                     kosten_werkbestand.kst_provisie_bedrag%type;
    v_provisie_tabel_code          kosten_werkbestand.kst_prov_code_tabel%type;
    v_vaste_kosten                 kosten_werkbestand.kst_vaste_kosten%type;
    v_variabele_kosten             kosten_werkbestand.kst_variabele_kosten%type;
    v_provisie_korting             kosten_werkbestand.kst_provisie_korting%type;
    v_minimum_prov_tabel_bedrag    kosten_werkbestand.kst_mini_prov_t_bedr%type;
    v_maximum_prov_tabel_bedrag    kosten_werkbestand.kst_max_prov_t_bedr%type;
    v_prov_korting_perc            kosten_werkbestand.kst_prov_korting_perc%type;
    v_corr_naar_min_max_prov       kosten_werkbestand.kst_corr_naar_min_max%type;
    v_provisie_type                kosten_werkbestand.kst_provisie_type%type;

    -- algemene variabelen voor gebruik in het script
    v_effectief_bedrag_bv         kosten_werkbestand.kst_effect_bedrag_bv%type;
    v_effectief_bedrag_vv         kosten_werkbestand.kst_effect_bedrag_rv%type;
    v_prijs_vv                    kosten_werkbestand.kst_trans_prijs%type;
    v_prijs_bv                    kosten_werkbestand.kst_trans_prijs%type;
    v_fonds_biedkoers             fn_quotes_vw.quot_bied%type;
    v_fonds_laatkoers             fn_quotes_vw.quot_laat%type;
    v_open_close                  number(1);
    v_aantal_contracten           kosten_werkbestand.kst_trans_aantal%type;
    v_schaal_factor               number(3);
    v_prov_tab_muntsoort          varchar2(4);
    v_prov_tab_cat_relatie        number(4);
    v_premie_effectief_bedrag     number(17,6);
    v_prov_tabel_gevonden         number(1);
    v_prov_tabel_code             varchar2(22);
    v_vaste_kost_bedr             kosten_werkbestand.kst_vaste_kosten%type;
    v_minimum_provisie            kosten_werkbestand.kst_mini_prov_t_bedr%type;
    v_maximum_provisie            kosten_werkbestand.kst_max_prov_t_bedr%type;
    v_vorig_schaal_bedrag         schalen_tabel.st_schaal_bedrag%type;
    v_werk_be_bi_nummer           number(4);
    v_korting_perc_gevonden       number(1);
    v_prov_korting_percentage     kosten_werkbestand.kst_prov_korting_perc%type;
    v_prov_korting_bedrag         clientprovkorting.pk_effectief_bedrag%type;
    v_werk_bedrag                 kosten_werkbestand.kst_variabele_kosten%type;

    -- virtuals voor de instellingen die opgehaald worden
    v_op_te_halen_instel                varchar2(30);
    v_instelling                        varchar2(100);
    v_inst_type                         varchar2(1);
    v_prov_kort_afl                     number (1);
    v_prov_kort_uitk                    number (1);


begin
    -- ophalen van de gegevens uit het kosten_werkbestand
    select k.kst_relatie_nummer,    k.kst_provisie_cat_fnds,   k.kst_bi_nummer,
           k.kst_trans_indicatie,   k.kst_trans_indicatie_n,   k.kst_trans_indicatie_w,
           k.kst_trans_aantal,      k.kst_trans_muntsrt,       k.kst_standaard_land,      k.kst_distributiekanaal,
           k.kst_gewoon_spoed_bet,  k.kst_ref_fnds_bi_nr,      k.kst_fondssymbool,
           k.kst_optietype_fnds,    k.kst_expiratiedat_fnds,   k.kst_exercisepr_fnds,
           k.kst_order_keuze
    into   v_relatienummer,         v_provisie_cat_fonds,      v_fonds_bi_nummer,
           v_trans_indicatie,       v_trans_indicatie_num,     v_trans_indicatie_wrd,
           v_trans_aantal,          v_trans_muntsoort,         v_standaard_land,          v_distributiekanaal,
           v_gewoon_spoed_betaling, v_ref_fonds_bi_nummer,     v_fondssymbool,
           v_optietype,             v_expiratiedatum,          v_exerciseprijs,
           v_order_keuze
    from   kosten_werkbestand k
    where  k.kst_ordernummer    = i_ordernummer
    and    k.kst_orderregel     = i_orderregel
    and    k.kst_detailnummer   = i_orderdetailnr;

    -- initialiseren van de (weg te schrijven) variabelen:
    v_provisie                   := 0;
    v_provisie_tabel_code        := ' ';
    v_vaste_kosten               := 0;
    v_variabele_kosten           := 0;
    v_provisie_korting           := 0;
    v_minimum_prov_tabel_bedrag  := 0;
    v_maximum_prov_tabel_bedrag  := 0;
    v_prov_korting_perc          := 0;
    v_corr_naar_min_max_prov     := 0;
    v_prov_tabel_gevonden        := 0;
    v_vorig_schaal_bedrag        := 0;
    v_korting_perc_gevonden      := 0;
    v_effectief_bedrag_bv        := abs(i_effectief_bv);
    v_prijs_bv                   := 0;

    v_effectief_bedrag_vv := i_effectief_vv;
    v_prijs_vv            := i_trans_prijs;

    if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure FIAT_NOTABEDRAG.provisie_bereken');
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order type : '||gv_order_type||' ; order soort : '||gv_order_soort);
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'binnenkomende prijs : '||to_char(i_trans_prijs)||' ; slot of last koers : '||gv_slot_of_last_koers);
    end if;

    -- Als het een combinatie Limiet order betreft, hier de premie (koers) van de optie bepalen
    -- om met het juiste premiebedrag de provisie tabel te gaan bepalen. Dit omdat bij combinatie limietorders
    -- juist het verschil in premies (of de optelling van de premies) wordt opgeslage in kosten_werkbestand.
    if gv_order_type in ('COMB','VZCO') and gv_order_soort = 'L'
    then
       FIAT_ALGEMEEN.fondskoersen (v_fondssymbool,        v_optietype,       v_expiratiedatum,  v_exerciseprijs,
                                   gv_slot_of_last_koers, v_fonds_biedkoers, v_fonds_laatkoers);

       if v_trans_indicatie_wrd = 1
       then
          v_prijs_vv := v_fonds_laatkoers;
       elsif v_trans_indicatie_wrd = 2
       then
          v_prijs_vv := v_fonds_biedkoers;
       end if;
    end if;

    select FIAT_ALGEMEEN.omrekenen_bedrag (v_prijs_vv, gv_trans_munt_reciproke, gv_trans_munt_factor,
                                           gv_trans_munt_koers, gv_trans_munt_koers, gv_trans_munt_notatie)
    into   v_prijs_bv
    from   dual;

    if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure FIAT_NOTABEDRAG na om rekenen prijs');
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag in bv : ' || to_char(i_effectief_bv)||' ; prijs in bv : '|| to_char(v_prijs_bv));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag in vv : ' || to_char(v_effectief_bedrag_vv)||' ; prijs in vv : '||to_char(v_prijs_vv));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fonds biedkoers        : ' || to_char(v_fonds_biedkoers)||'  ; fonds laatkoers : '||to_char(v_fonds_laatkoers));
    end if;

    -- aanpassen van de v_trans_indicatie indien het om KN, VN of EMIS gaat:
    if v_trans_indicatie in ('KN','VN','EMIS')
    then
       if v_trans_indicatie = 'VN'
       then
          v_trans_indicatie := 'V';
       else
          v_trans_indicatie := 'K';
       end if;
    end if;

    -- bepalen met welke be_bi_nummer er gewerkt moet worden:
    if gv_provisie_ex_as_bereken = 2
    then
       if v_trans_indicatie in ('EX C','EX P') and (v_fonds_bi_nummer < 3000 or v_fonds_bi_nummer >=3100)
       then
          v_fonds_bi_nummer := v_ref_fonds_bi_nummer;
       end if;
    end if;


    -- 1. BEPALEN PROVISIE TYPE:
    v_provisie_type              := 9;

    -- provisieberekening op basis van stukken
    if gv_provisie_ex_as_bereken = 2
    then
       if v_trans_indicatie in ('OK','OV','SK','SV','OK F','OV F','SV F','SK F','BYST')
          or
          (v_trans_indicatie in ('EX C','EX P','AS C','AS P') and v_fonds_bi_nummer between 3000 and 3099)
       then
          v_provisie_type := 1;
       elsif v_trans_indicatie in ('K','V','UITK','OMWL','OMWS','AFL','D','L','O')
             or
            (v_trans_indicatie in ('EX C','EX P','AS C','AS P') and v_fonds_bi_nummer not between 3000 and 3099)
       then
          v_provisie_type := 2;
       end if;
    end if;

    -- provisieberekening op basis van opties
    if gv_provisie_ex_as_bereken = 1
    then
       if v_trans_indicatie in ('OK','OV','SK','SV','OK F','OV F','SV F','SK F','BYST','EX C','EX P','AS C','AS P')
       then
          v_provisie_type := 1;
       elsif v_trans_indicatie in ('K','V','UITK','OMWL','OMWS','AFL','D','L','O')
       then
          v_provisie_type := 2;
       end if;
    end if;

    -- provisieberekening voor geld
    if v_trans_indicatie in ('O-G','S-G','T-G')
    then
       v_provisie_type := 3;
    end if;

    -- ZETTEN VAN VIRS VOOR BEPALEN PROVISIETABEL.
    if v_provisie_type = 2
    then
       v_open_close := 0;
    elsif v_trans_indicatie in ('OK','OK F','OV','OV F')
    then
       v_open_close := 1;
    elsif v_trans_indicatie in ('SK','SK F','SV','SV F','AS C','AS P','EX C','EX P','BYST')
    then
       v_open_close := 2;
    end if;

    if gv_debuggen = 1
    then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provisie type : ' || to_char(v_provisie_type)||' ; transactie soort : '|| v_trans_indicatie );
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'open en close : ' || to_char(v_open_close));
    end if;

    if v_provisie_type = 3
    then
       v_open_close := v_gewoon_spoed_betaling;
    end if;

    if v_provisie_type in (2,3)
    then
       v_aantal_contracten := 0;
       v_schaal_factor     := 100;
    else
       v_aantal_contracten := v_trans_aantal;
       v_schaal_factor     := 1;
    end if;

     -- voor WISO omwisselingen moet niet het distributiekanaal van de order gebruikt worden, maar het default distributiekanaal
    if v_order_keuze = 'WISO' and v_trans_indicatie = 'OMWL'
    then
       v_op_te_halen_instel := 'DefaultDistrKan';
       v_inst_type          := 'N';
       select FIAT_ALGEMEEN.instell_bepalen(gv_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
       into   v_instelling
       from   dual;
       v_distributiekanaal := to_number(rtrim(ltrim(v_instelling)));
    end if;

    -- DOORGAAN MET BEREKENEN ALS WORDT VOLDAAN AAN DE VOLGENDE VOORWAARDEN:
    if v_provisie_type in (1,2) and gv_provisie_cat_relatie <> 0 and v_provisie_cat_fonds <> 0
       or
       v_provisie_type = 3 and gv_provisie_cat_relatie <> 0
    then

       if gv_debuggen = 1
       then
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'doorgaan met berekenen');
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provisietype             : '||to_char(v_provisie_type));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provisie cat fonds       : '||to_char(v_provisie_cat_fonds)||' ;  provisie cat relatie : '||to_char(gv_provisie_cat_relatie));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'terugval basisval        : '||to_char(gv_terugval_basisval)||' ; trans muntsoort : '||v_trans_muntsoort);
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'basisvaluta              : '||gv_basis_valuta||' ; standaard prov cat rel : '||to_char(gv_standaard_prov_cat_rel));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'standaard prov cat gebr  : '||to_char(gv_standaard_prov_cat_gebr));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'   ');
       end if;

       -- 2.  BEPALEN VAN DE TE GEBRUIKEN PROVISIETABEL
       -- 2.1 INITIELE PROVISIETABEL
       v_prov_tab_muntsoort      := v_trans_muntsoort;
       v_prov_tab_cat_relatie    := gv_provisie_cat_relatie;

       if v_provisie_type in (2,3)
       then
          v_premie_effectief_bedrag := v_effectief_bedrag_vv;
       else
          v_premie_effectief_bedrag := v_prijs_vv;
       end if;
       -- eerst proberen te bepalen met transactiesoort gevuld
       prov_tabel_bepalen(v_provisie_type, v_prov_tab_muntsoort, v_provisie_cat_fonds, v_prov_tab_cat_relatie, v_open_close,
                          v_distributiekanaal, v_standaard_land, v_trans_indicatie_num, v_premie_effectief_bedrag, v_aantal_contracten,
                          v_prov_tabel_gevonden, v_prov_tabel_code, v_vaste_kost_bedr, v_minimum_provisie, v_maximum_provisie);
       -- als de tabel niet is gevonden, dan proberen te vinden zonder transactiesoort (dus op 0 stellen)
       if   v_prov_tabel_gevonden = 0
       then
          prov_tabel_bepalen(v_provisie_type, v_prov_tab_muntsoort, v_provisie_cat_fonds, v_prov_tab_cat_relatie, v_open_close,
                             v_distributiekanaal, v_standaard_land, 0, v_premie_effectief_bedrag, v_aantal_contracten,
                             v_prov_tabel_gevonden, v_prov_tabel_code, v_vaste_kost_bedr, v_minimum_provisie, v_maximum_provisie);
       end if;

       -- 2.2 INITIELE PROV.TABEL BESTAAT NIET ---> BASISMUNTSOORT
       if v_prov_tabel_gevonden = 0 and gv_terugval_basisval = 1 and v_trans_muntsoort <> gv_basis_valuta
       then
          v_prov_tab_muntsoort      := gv_basis_valuta;
          v_prov_tab_cat_relatie    := gv_provisie_cat_relatie;

          if v_provisie_type in (2,3)
          then
             v_premie_effectief_bedrag := v_effectief_bedrag_bv;
          else
             v_premie_effectief_bedrag := v_prijs_bv;
          end if;
          -- eerst proberen te bepalen met transactiesoort gevuld
          prov_tabel_bepalen(v_provisie_type, v_prov_tab_muntsoort, v_provisie_cat_fonds, v_prov_tab_cat_relatie, v_open_close,
                             v_distributiekanaal, v_standaard_land, v_trans_indicatie_num, v_premie_effectief_bedrag, v_aantal_contracten,
                             v_prov_tabel_gevonden, v_prov_tabel_code, v_vaste_kost_bedr, v_minimum_provisie, v_maximum_provisie);
          -- als de tabel niet is gevonden, dan proberen te vinden zonder transactiesoort (dus op 0 stellen)
          if   v_prov_tabel_gevonden = 0
          then
             prov_tabel_bepalen(v_provisie_type, v_prov_tab_muntsoort, v_provisie_cat_fonds, v_prov_tab_cat_relatie, v_open_close,
                                v_distributiekanaal, v_standaard_land, 0, v_premie_effectief_bedrag, v_aantal_contracten,
                                v_prov_tabel_gevonden, v_prov_tabel_code, v_vaste_kost_bedr, v_minimum_provisie, v_maximum_provisie);
          end if;
       end if;

       -- 2.3 PROV.TABEL IN BASISMUNTSOORT BESTAAT NIET ---> STD.PROV.CAT.REL.
       if v_prov_tabel_gevonden = 0 and gv_standaard_prov_cat_rel <> 0 and gv_standaard_prov_cat_gebr <> 0
       then
          v_prov_tab_muntsoort      := v_trans_muntsoort;
          v_prov_tab_cat_relatie    := gv_standaard_prov_cat_rel;

          if v_provisie_type in (2,3)
          then
             v_premie_effectief_bedrag := v_effectief_bedrag_vv;
          else
             v_premie_effectief_bedrag := v_prijs_vv;
          end if;
          -- eerst proberen te bepalen met transactiesoort gevuld
          prov_tabel_bepalen(v_provisie_type, v_prov_tab_muntsoort, v_provisie_cat_fonds, v_prov_tab_cat_relatie, v_open_close,
                             v_distributiekanaal, v_standaard_land, v_trans_indicatie_num, v_premie_effectief_bedrag, v_aantal_contracten,
                             v_prov_tabel_gevonden, v_prov_tabel_code, v_vaste_kost_bedr, v_minimum_provisie, v_maximum_provisie);
          -- als de tabel niet is gevonden, dan proberen te vinden zonder transactiesoort (dus op 0 stellen)
          if   v_prov_tabel_gevonden = 0
          then
             prov_tabel_bepalen(v_provisie_type, v_prov_tab_muntsoort, v_provisie_cat_fonds, v_prov_tab_cat_relatie, v_open_close,
                                v_distributiekanaal, v_standaard_land, 0, v_premie_effectief_bedrag, v_aantal_contracten,
                                v_prov_tabel_gevonden, v_prov_tabel_code, v_vaste_kost_bedr, v_minimum_provisie, v_maximum_provisie);
          end if;
       end if;

       -- 2.4 PROV.TABEL IN STD.PROV.CAT.REL. BESTAAT NIET ---> STD.PROV.CAT.REL en BASISMUNTSOORT
       if v_prov_tabel_gevonden = 0 and gv_standaard_prov_cat_rel <> 0 and gv_standaard_prov_cat_gebr <> 0
          and gv_terugval_basisval = 1 and v_trans_muntsoort <> gv_basis_valuta
       then
          v_prov_tab_muntsoort      := gv_basis_valuta;
          v_prov_tab_cat_relatie    := gv_standaard_prov_cat_rel;

          if v_provisie_type in (2,3)
          then
             v_premie_effectief_bedrag := v_effectief_bedrag_bv;
          else
             v_premie_effectief_bedrag := v_prijs_bv;
          end if;
          -- eerst proberen te bepalen met transactiesoort gevuld
          prov_tabel_bepalen(v_provisie_type, v_prov_tab_muntsoort, v_provisie_cat_fonds, v_prov_tab_cat_relatie, v_open_close,
                             v_distributiekanaal, v_standaard_land, v_trans_indicatie_num, v_premie_effectief_bedrag, v_aantal_contracten,
                             v_prov_tabel_gevonden, v_prov_tabel_code, v_vaste_kost_bedr, v_minimum_provisie, v_maximum_provisie);
          -- als de tabel niet is gevonden, dan proberen te vinden zonder transactiesoort (dus op 0 stellen)
          if   v_prov_tabel_gevonden = 0
          then
             prov_tabel_bepalen(v_provisie_type, v_prov_tab_muntsoort, v_provisie_cat_fonds, v_prov_tab_cat_relatie, v_open_close,
                                v_distributiekanaal, v_standaard_land, 0, v_premie_effectief_bedrag, v_aantal_contracten,
                                v_prov_tabel_gevonden, v_prov_tabel_code, v_vaste_kost_bedr, v_minimum_provisie, v_maximum_provisie);
          end if;
       end if;

       -- verder gaan als een provisietabel gevonden is...
       if v_prov_tabel_gevonden = 1
       then
          -- 3. BEREKEN SCHAALBEDRAG
          -- ALS PROVISIETYPE = 1 DAN AANTAL, ANDERS EFFECTIEF BEDRAG VV
          -- OF EFFECTIEF BEDRAG BV ALS MUNTSOORT PROV. TABEL <> BASISMUNTSOORT
          if v_provisie_type = 1
          then
             v_premie_effectief_bedrag := v_trans_aantal;
          end if;

          if v_provisie_type in (2,3)
          then
             if v_prov_tab_muntsoort = gv_basis_valuta
             then
                v_premie_effectief_bedrag := v_effectief_bedrag_bv;
             else
                v_premie_effectief_bedrag := v_effectief_bedrag_vv;
             end if;
          end if;

          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'premie/effectief bedrag : ' || to_char(v_premie_effectief_bedrag));
          end if;

          declare
             cursor st is
                 select s.st_schaal_bedrag, s.st_schaal_perc
                 from   schalen_tabel s
                 where  s.st_soort   = 'PROV'
                 and    s.st_pr_code = v_prov_tabel_code
                 order by s.st_schaal_bedrag;

          begin
             for r_st in st
             loop

             if gv_debuggen = 1
             then
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'schaal bedrag : ' || to_char(r_st.st_schaal_bedrag) || ' ; schaal percentage : '|| to_char(r_st.st_schaal_perc));
             end if;

                if v_vorig_schaal_bedrag < v_premie_effectief_bedrag
                then
                   if v_premie_effectief_bedrag >= r_st.st_schaal_bedrag
                   then
                      v_provisie         := round(v_provisie + (r_st.st_schaal_bedrag - v_vorig_schaal_bedrag) *
                                                  r_st.st_schaal_perc / v_schaal_factor,gv_trans_munt_notatie);
                      v_variabele_kosten := round(v_variabele_kosten + (r_st.st_schaal_bedrag - v_vorig_schaal_bedrag) *
                                                  r_st.st_schaal_perc / v_schaal_factor,gv_trans_munt_notatie);

                      if gv_debuggen = 1
                      then
                         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'premie_effectief_bedrag >= schaal_bedrag');
                         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provisie bedrag : '||to_char(v_provisie)||' ; variabele kosten : '||to_char(v_variabele_kosten));
                      end if;
                   else
                      v_provisie         := round(v_provisie + (v_premie_effectief_bedrag - v_vorig_schaal_bedrag) *
                                                  r_st.st_schaal_perc / v_schaal_factor,gv_trans_munt_notatie);
                      v_variabele_kosten := round(v_variabele_kosten + (v_premie_effectief_bedrag - v_vorig_schaal_bedrag) *
                                                  r_st.st_schaal_perc / v_schaal_factor,gv_trans_munt_notatie);
                      if gv_debuggen = 1
                      then
                         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'premie_effectief_bedrag < schaal_bedrag');
                         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provisie bedrag : '||to_char(v_provisie)||' ; variabele kosten : '||to_char(v_variabele_kosten));
                      end if;
                   end if;

                   v_vorig_schaal_bedrag := r_st.st_schaal_bedrag;
                end if;
             end loop;
          end;

          -- 4. KORTINGSBEREKENING

          -- Ophalen instellingen om te bepalen of kortingen voor AFL en UITK transacties moeten worden meegenomen
           v_op_te_halen_instel := 'ProvKortAfl';
           v_inst_type          := 'N';
           select FIAT_ALGEMEEN.instell_bepalen(gv_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
           into   v_instelling
           from   dual;
           v_prov_kort_afl := to_number(rtrim(ltrim(v_instelling)));

           v_op_te_halen_instel := 'ProvKortUitk';
           v_inst_type          := 'N';
           select FIAT_ALGEMEEN.instell_bepalen(gv_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
           into   v_instelling
           from   dual;
           v_prov_kort_uitk := to_number(rtrim(ltrim(v_instelling)));

           if (v_trans_indicatie <> 'UITK' and v_trans_indicatie <> 'AFL') or
              (v_trans_indicatie = 'UITK' and v_prov_kort_uitk = 1) or
              (v_trans_indicatie = 'AFL' and v_prov_kort_afl = 1)
           then
              if v_trans_indicatie <> 'UITK'
              then
                 v_werk_be_bi_nummer := v_fonds_bi_nummer;
              else
                 -- aanpassen aan dividend (be_bi_nummer 300) en coupon (be_bi_nummer 400) bij uitkering
                 if v_fonds_bi_nummer between 100 and 199
                 then
                    v_werk_be_bi_nummer := 300;
                 else
                    v_werk_be_bi_nummer := 400;
                 end if;
              end if;

          begin
              v_korting_perc_gevonden := 1;

              select c.pk_prov_korting
              into   v_prov_korting_perc
              from   clientprovkorting c
              where  c.pk_relatienummer = v_relatienummer
              and    c.pk_prov_type     = 0
              and    c.pk_bi_nummer     = v_werk_be_bi_nummer;

          exception
              when no_data_found
              then
                 v_prov_korting_perc   := 0;
                 v_korting_perc_gevonden := 0;
          end;

          if v_korting_perc_gevonden = 0
          then
             begin
                 v_korting_perc_gevonden := 1;

                 select c.pk_prov_korting,         c.pk_effectief_bedrag
                 into   v_prov_korting_percentage, v_prov_korting_bedrag
                 from   clientprovkorting c
                 where  c.pk_relatienummer = v_relatienummer
                 and    c.pk_prov_type     = v_provisie_type;

             exception
                 when no_data_found
                 then
                    v_prov_korting_perc   := 0;
                    v_korting_perc_gevonden := 0;
             end;

             if v_korting_perc_gevonden = 1 and v_effectief_bedrag_bv >= v_prov_korting_bedrag * 1000
             then
                v_prov_korting_perc := v_prov_korting_percentage;
             end if;
          end if;

          v_provisie_korting := v_prov_korting_perc / 100 * v_provisie;

          if v_prov_korting_perc <> 0
          then
             v_provisie:= v_provisie* (100 - v_prov_korting_perc)/100;
          end if;

          v_vaste_kosten := v_vaste_kost_bedr;

          if v_prov_korting_perc <> 0 and gv_provisie_korting_vast = 1
          then
             v_vaste_kosten := v_vaste_kosten * (100 - v_prov_korting_perc)/100;
          end if;

          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provisie korting : '||to_char(v_provisie_korting)||' ; provisie kortingspercentage : '||to_char(v_prov_korting_perc));
          end if;

    end if;

          -- 5. TOETSEN AAN MIN. PROVISIE EN MAX. PROVISIE UIT PROVISIETABEL
          -- ALLEEN HIER UITVOEREN ALS DE INSTELLING (min_max_var_tot) OP 'VARIABELE TOESLAG EN KORTING' STAAT.

          if gv_min_max_var_tot <> 2
          then
             v_werk_bedrag := v_variabele_kosten - v_provisie_korting;

             if v_provisie < v_minimum_provisie and gv_minimum_prov_relatie_gebr = 1
             then
                v_provisie := v_minimum_provisie;
             end if;

             if v_provisie > v_maximum_provisie and v_maximum_provisie <> 0
             then
                v_provisie := v_maximum_provisie;
             end if;

             -- 5.1 AANPASSEN VARIABELE TOESLAG EN KORTING AAN MAXIMUM PROVISIE
             -- Variabele toeslag en korting worden als aparte componenten opgeslagen.
             -- De verhouding tussen deze beide componenten moet echter wel in tact
             -- blijven. Dus bij aanpassing van de provisie, beide componenten naar
             -- verhouding aanpassen.

             if v_werk_bedrag > v_maximum_provisie and v_maximum_provisie <> 0
             then
                v_variabele_kosten := v_maximum_provisie / v_werk_bedrag * v_variabele_kosten;
                v_provisie_korting := v_maximum_provisie / v_werk_bedrag * v_provisie_korting;
             end if;

             -- 5.2 AANPASSEN VARIABELE TOESLAG EN KORTING AAN MINIMUM PROVISIE
             -- Variabele toeslag en korting worden als aparte componenten opgeslagen.
             -- De verhouding tussen deze beide componenten moet echter wel in tact
             -- blijven. Dus bij aanpassing van de provisie, beide componenten naar
             -- verhouding aanpassen.

             -- Tot nu toe berekende provisie (= v_werk_bedrag <>0)

             if v_werk_bedrag <> 0 and v_werk_bedrag < v_minimum_provisie and gv_minimum_prov_relatie_gebr = 1
             then
                v_variabele_kosten := v_minimum_provisie / v_werk_bedrag * v_variabele_kosten;
                v_provisie_korting := v_minimum_provisie / v_werk_bedrag * v_provisie_korting;
             end if;

             -- Tot nu toe berekende provisie (= v_werk_bedrag = 0)
             if v_werk_bedrag = 0 and v_werk_bedrag < v_minimum_provisie and gv_minimum_prov_relatie_gebr = 1
             then
                -- Variabele kosten naar verhouding vergroten
                v_variabele_kosten := v_minimum_provisie /((100 - v_prov_korting_perc)/100);
                -- Provisiekorting naar verhouding vergroten
                v_provisie_korting := v_variabele_kosten * (v_prov_korting_perc/100);
             end if;
          end if;

          -- 6. OPTELLEN: PROVISIE + VASTE KOSTEN
          v_provisie := v_provisie + v_vaste_kosten;

          -- 7. GEBRUIKTE PROVISIE TABEL TERUGGEGEVEN
          v_provisie_tabel_code := v_prov_tabel_code;

       end if;
    end if;

    -- 8. zetten van de output parameters

    v_minimum_prov_tabel_bedrag := v_minimum_provisie;
    v_maximum_prov_tabel_bedrag := v_maximum_provisie;

    if gv_min_max_var_tot = 2
    then
       v_corr_naar_min_max_prov := 1;
    else
       v_corr_naar_min_max_prov := 0;
    end if;

    -- 8.1 Omrekenen naar basisvaluta en afronden van de bedragen.

    if v_prov_tab_muntsoort <> gv_basis_valuta
    then
        select FIAT_ALGEMEEN.omrekenen_bedrag (v_vaste_kosten, gv_trans_munt_reciproke, gv_trans_munt_factor, gv_trans_munt_koers,
                                               gv_trans_munt_koers, gv_trans_munt_notatie)
        into   v_vaste_kosten
        from   dual;

        select FIAT_ALGEMEEN.omrekenen_bedrag (v_variabele_kosten, gv_trans_munt_reciproke, gv_trans_munt_factor, gv_trans_munt_koers,
                                               gv_trans_munt_koers, gv_trans_munt_notatie)
        into   v_variabele_kosten
        from   dual;

        select FIAT_ALGEMEEN.omrekenen_bedrag (v_provisie_korting, gv_trans_munt_reciproke, gv_trans_munt_factor, gv_trans_munt_koers,
                                               gv_trans_munt_koers, gv_trans_munt_notatie)
        into   v_provisie_korting
        from   dual;

        select FIAT_ALGEMEEN.omrekenen_bedrag (v_provisie, gv_trans_munt_reciproke, gv_trans_munt_factor, gv_trans_munt_koers,
                                               gv_trans_munt_koers, gv_trans_munt_notatie)
        into   v_provisie
        from   dual;

        select FIAT_ALGEMEEN.omrekenen_bedrag (v_minimum_prov_tabel_bedrag, gv_trans_munt_reciproke, gv_trans_munt_factor, gv_trans_munt_koers,
                                               gv_trans_munt_koers, gv_trans_munt_notatie)
        into   v_minimum_prov_tabel_bedrag
        from   dual;

        select FIAT_ALGEMEEN.omrekenen_bedrag (v_maximum_prov_tabel_bedrag, gv_trans_munt_reciproke, gv_trans_munt_factor, gv_trans_munt_koers,
                                               gv_trans_munt_koers, gv_trans_munt_notatie)
        into   v_maximum_prov_tabel_bedrag
        from   dual;
    end if;

    if v_provisie_type = 9
    then
       v_provisie                   := 0;
       v_provisie_tabel_code        := ' ';
       v_vaste_kosten               := 0;
       v_variabele_kosten           := 0;
       v_provisie_korting           := 0;
       v_minimum_prov_tabel_bedrag  := 0;
       v_maximum_prov_tabel_bedrag  := 0;
       v_prov_korting_perc          := 0;
       v_corr_naar_min_max_prov     := 0;
    end if;

    update kosten_werkbestand k
    set    k.kst_effect_bedrag_bv  = i_effectief_bv,
           k.kst_provisie_bedrag   = round(v_provisie, gv_basis_val_notatie),
           k.kst_prov_code_tabel   = v_provisie_tabel_code,
           k.kst_provisie_type     = v_provisie_type,
           k.kst_vaste_kosten      = round(v_vaste_kosten, gv_basis_val_notatie),
           k.kst_variabele_kosten  = round(v_variabele_kosten, gv_basis_val_notatie),
           k.kst_provisie_korting  = round(v_provisie_korting, gv_basis_val_notatie),
           k.kst_mini_prov_t_bedr  = round(v_minimum_prov_tabel_bedrag, gv_basis_val_notatie),
           k.kst_max_prov_t_bedr   = round(v_maximum_prov_tabel_bedrag, gv_basis_val_notatie),
           k.kst_prov_korting_perc = v_prov_korting_perc,
           k.kst_corr_naar_min_max = v_corr_naar_min_max_prov
    where  k.kst_ordernummer       = i_ordernummer
    and    k.kst_orderregel        = i_orderregel
    and    k.kst_detailnummer      = i_orderdetailnr;


end provisie_bereken;
-- EINDE CODE PROCEDURE PROVISIE_BEREKEN


-- DE CODE VOOR DE PROCEDURE GEHELE_PROVISIE_BEREKENEN
procedure gehele_provisie_berekenen
(i_ordernummer                  in  kosten_werkbestand.kst_ordernummer%type
,i_orderregel                   in  kosten_werkbestand.kst_orderregel%type
,i_orderdetail                  in  kosten_werkbestand.kst_detailnummer%type
,i_transactie_indicatie         in  kosten_werkbestand.kst_trans_indicatie%type
,i_order_aantal                 in  kosten_werkbestand.kst_trans_aantal%type
,i_geen_provisie_berekenen      in  kosten_werkbestand.kst_ord_geen_provisie%type
,i_order_provisie_perc_eff_wrd  in  kosten_werkbestand.kst_ord_provperceffw%type
,i_order_provisie_kort_perc     in  kosten_werkbestand.kst_prov_korting_perc%type
,i_effectief_bedrag_bv          in  kosten_werkbestand.kst_effect_bedrag_bv%type
,i_effectief_bedrag_tv          in  kosten_werkbestand.kst_effect_bedrag_rv%type
,i_klant_prijs                  in  transakties.tr_prijs_tr_mntsrt%type
,i_beurs_prijs                  in  transakties.tr_beurs_prijs_trm%type
,i_fondskoers_comb_order        in  transakties.tr_prijs_tr_mntsrt%type
,i_fonds_prijs_factor           in  beleggingsinstrument.be_prijs_factor%type
,o_bedrag_mee_in_brutobedr_bv   out kosten_werkbestand.kst_effect_bedrag_bv%type
)
is

    v_provisie_bv              kosten_werkbestand.kst_provisie_bedrag%type;
    v_kosten_corresp_doorb     kosten_werkbestand.kst_kost_corr_doorb%type;


begin

    if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In procedure gehele_provisie_berekenen voor:');
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Ordernummer : '||to_char(i_ordernummer)||' ; orderregel : '||to_char(i_orderregel));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Orderdetail : '||to_char(i_orderdetail));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
    end if;

    -- er kan op de order zijn aangegeven dat er geen provisie berekend moet worden
    if i_geen_provisie_berekenen = 1
    then
       v_provisie_bv := 0;
    -- er moet gewoon provisie berekend worden
    else
       -- externe provisie, KN/VN/EMIS -> afhankelijk van de relatiegegevens
       if i_order_provisie_perc_eff_wrd = 0
       -- provisie wordt bepaald aan de hand van de effectieve waarde (via normale kosten componentberekeningen)
       then
          -- aanroepen van de procedure kosten componenten berekenen (kost_comp_bereken)
          kost_comp_bereken (i_ordernummer, i_orderregel,            i_orderdetail,               i_effectief_bedrag_bv,    i_effectief_bedrag_tv,
                             i_klant_prijs, i_fondskoers_comb_order, o_bedrag_mee_in_brutobedr_bv);

          -- de berekende provisie en de doorberekende kosten correspondent weer ophalen
          select k.kst_provisie_bedrag, k.kst_kost_corr_doorb
          into   v_provisie_bv,         v_kosten_corresp_doorb
          from   kosten_werkbestand k
          where  k.kst_ordernummer     = i_ordernummer
          and    k.kst_orderregel      = i_orderregel
          and    k.kst_detailnummer    = i_orderdetail;

          -- doorberekende kosten correspondent uit de provisie behalen
          if v_kosten_corresp_doorb >= 0
          then
             v_provisie_bv := v_provisie_bv - v_kosten_corresp_doorb;
          else
             -- als de kosten correspondent -1 is, dan hier op 0 zetten om te voorkomen dat er met die -1
             -- gerekend wordt in de verdere berekeningen
             v_kosten_corresp_doorb := 0;
          end if;

          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'provisie in bv : '||to_char(v_provisie_bv)||' ; kosten correspondent doorb : '||to_char(v_kosten_corresp_doorb));
          end if;
       else
          -- provisie is een percentage van effectief bedrag ...
          v_provisie_bv                := i_effectief_bedrag_bv * i_order_provisie_perc_eff_wrd/100;
          o_bedrag_mee_in_brutobedr_bv := 0;
       end if;

       -- er is handmatig bij orderinvoer een kortingspercentage voor de provisie opgegeven:
       if i_order_provisie_kort_perc <> 0
       then
          v_provisie_bv  := v_provisie_bv * (100 - i_order_provisie_kort_perc)/100;
       end if;

       -- netto koop en verkoop nog de provisie bepalen
       if i_transactie_indicatie in ('KN','VN')
       then
          select FIAT_ALGEMEEN.omrekenen_bedrag(i_order_aantal*i_fonds_prijs_factor*(i_klant_prijs - i_beurs_prijs), gv_trans_munt_reciproke,
                                                gv_trans_munt_factor , gv_trans_munt_koers, gv_trans_munt_koers, gv_trans_munt_notatie)
          into v_provisie_bv
          from dual;

          v_provisie_bv := v_provisie_bv * case when i_transactie_indicatie = 'VN' then -(1) else 1 end;
       end if;

    end if;

    -- als laatste de berekende gegevens hier nog tussentijds wegschrijven in het werkbestand
    update kosten_werkbestand w
    set    w.kst_provisie_bedrag = nvl(v_provisie_bv,0),
           w.kst_kost_corr_doorb = nvl(v_kosten_corresp_doorb,0)
    where  w.kst_ordernummer     = i_ordernummer
    and    w.kst_orderregel      = i_orderregel
    and    w.kst_detailnummer    = i_orderdetail;

    if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Einde procedure gehele_provisie_berekenen voor:');
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Ordernummer : '||to_char(i_ordernummer)||' ; orderregel : '||to_char(i_orderregel));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Orderdetail : '||to_char(i_orderdetail)||' ; Berekende gegevens : ');
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Provisie    : '||to_char(v_provisie_bv)||' ; kosten correspondent : '||to_char(v_kosten_corresp_doorb));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
    end if;
end gehele_provisie_berekenen;
-- EINDE CODE GEHELE_PROVISIE_BEREKENEN


-- DE CODE VOOR DE PROCEDURE BEPALEN_CALC_LINES
procedure bepalen_calc_lines
(i_ordernummer                 in  orders.ord_ordernummer%type
,i_orderregel                  in  orders.ord_orderregel%type
,i_detailnummer                in  ordersdetaillering.orx_detailnummer%type
,i_pr_id                       in  producten.pr_id%type
,i_fonds_id                    in  beleggingsinstrument.be_volgnummer%type
,i_trans_indicatie             in  kosten_werkbestand.kst_trans_indicatie%type
,i_trans_context               in  contextcalculationrules.cxcr_context%type
,i_prod_conv_id                in  productconversies.capc_id%type
,o_te_doorlopen_amount_type    out varchar2
,o_bsp_instapfee_aanwezig      out number
)
is

  v_tarif_id                  tax_tarif.tt_id%type;
  v_fixed_amount              taxproductrules_vw.tt_fixed_amount%type;
  v_maximum_amount            taxproductrules_vw.tt_maximum_amount%type;
  v_minimum_amount            taxproductrules_vw.tt_minimum_amount%type;
  v_percentage                fiat_order_costs_det.focd_rule_var_amt_perc%type;  -- Percentage voor indirecte kosten bevat meer decimalen
  v_has_max_amount            number(1);
  v_max_amount_allowed        number(1);
  v_has_min_amount            number(1);
  v_min_amount_allowed        number(1);
  v_has_exemption             number(1);
  v_discount_tarif_id         prod_dedu_discount.dita_id%type;
  v_table                     varchar2(15);
  v_bsp_instapfee_aanwezig    number(1) := 0;

  v_tax_prod_gevonden         number(1);
  v_exclusion_aanwezig        number(1);
  v_exclusion_level_ca        number(1);
  v_wht_exemption             number(1);
  v_initiele_belast_bepaald   number(1);
  v_aant_holders_met_exemp    number(8);
  v_aant_holders_zonder_exemp number(8);
  v_calc_rule_toepassen       number(1);

cursor cr is
       select c.cxcr_cfcu_id, c.cxcr_table, c.cxcr_dedu_id, r.cfcu_amount_type, r.cfcu_type, r.cfcu_method, r.cfcu_pay_off_type
       from   contextcalculationrules_vw c, calculationrules r
       where  c.cxcr_context   = i_trans_context
       and    c.cxcr_indicatie = i_trans_indicatie
       and    c.cxcr_cfcu_id   = r.cfcu_id
       and    r.cfcu_type      <> 'REGISTER'     -- Registerregels zijn geen berekeningen, hier dus overslaan
       and    r.cfcu_book_type in ('PTY','ALL')  -- Hier al aangeven dat het alleen om klant gerelateerde regels gaat !
       order by c.cxcr_cfcu_id;

begin

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'start bepalen calc rules; doorlopen van context calculations ');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'product id : '||to_char(i_pr_id)||' ; fonds id : '||to_char(i_fonds_id));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'trans indicatie : '||i_trans_indicatie||' ;  trans context : '||i_trans_context);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'prod conv id : '||to_char(i_prod_conv_id));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

   o_te_doorlopen_amount_type := ' ';
   v_initiele_belast_bepaald  := 0;

   -- Hier eerst de al doorgegeven kosten doorlopen om deze te administreren en amount type vast te stellen (niet voor context CA)
   if i_trans_context <> 'CA'
   then
      admin_external_fees (i_ordernummer, i_orderregel, i_detailnummer, i_trans_indicatie, o_te_doorlopen_amount_type, v_bsp_instapfee_aanwezig);
   
   -- Hier de deductions bepalen als het wel een CA betreft. 
   -- Dit kan in 1 keer voor alle calculation rules. Hiervoor wordt de bestaande tabel special_ca_tax_exclusions gebruikt
   else 
      insert into special_ca_tax_exclusions (party_id, dedu_id)
      select d.party_id, d.deduction_id 
      from   deduction_exemptions_vw d 
      inner join (select c.cfcu_dedu_id, p.exclusion_country_nr, p.exclusion_party_type 
                  from   pcvn_tax_exclusions p 
                  inner join calculationrules c on c.cfcu_id = p.ptex_cfcu_id
                  where p.ptex_capc_id    = i_prod_conv_id 
                  and   p.exclusion_level = 1 ) t 
                  on    d.deduction_id = t.cfcu_dedu_id
      where d.country_code = coalesce(t.exclusion_country_nr, d.country_code)
      and   (t.exclusion_party_type is null
             or
             t.exclusion_party_type = 'N' and exists (select 'true' from rekeninghouders_details r where r.eor_partij_id = d.party_id and r.eor_rechtsvorm = 0)
             or
             t.exclusion_party_type = 'L' and exists (select 'true' from rekeninghouders_details r where r.eor_partij_id = d.party_id and r.eor_rechtsvorm <> 0)
            )
      and   d.party_id in 
                       (select h.hpp_holdernummer
                        from   holders_per_product h
                        where  h.hpp_relatienummer  = gv_relatienummer
                        and    h.hpp_product        = gv_rel_product_nummer
                        and    h.hpp_product_volgnr = gv_rel_product_volgnummer
                        and    h.hpp_type_holder    in (1,2))
      and   d.party_id     <>0 
      and   d.deduction_id is not null;
   end if;
   
   for r_cr in cr
   loop

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'CALC RULE ID : '||to_char(r_cr.cxcr_cfcu_id)||' ; calc rule tabel : '||r_cr.cxcr_table);
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'amount type  : '||r_cr.cfcu_amount_type||' ; type : '||r_cr.cfcu_type);
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'method       : '||r_cr.cfcu_method||' ; deduction id : '||to_char(nvl(r_cr.cxcr_dedu_id,99999999999999999)));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
      end if;

      -- resetten van de gegevens die bepaald kunnen worden
      v_tarif_id            := 0;
      v_fixed_amount        := 0;
      v_maximum_amount      := 0;
      v_minimum_amount      := 0;
      v_percentage          := 0;
      v_has_max_amount      := 0;
      v_has_min_amount      := 0;
      v_tax_prod_gevonden   := 0;
      v_exclusion_aanwezig  := 0;
      v_exclusion_level_ca  := 0;
      v_wht_exemption       := 0;
      v_calc_rule_toepassen := 1;     -- er vanuit gaan dat de calc rule toegepast moet worden. Eventuele vrijstellingen kunnen dit wijzigen.

      -- controle op exclusion
      if gv_order_orx_id > 0
      then
         begin
            select 1
            into   v_exclusion_aanwezig
            from   ord_tax_exclusions o
            where  o.otex_orx_id  = gv_order_orx_id
            and    o.otex_cfcu_id = r_cr.cxcr_cfcu_id;
         exception
            when no_data_found
            then
               v_exclusion_aanwezig := 0;
         end;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'exclusion aanwezig (ord_tax_exclusions) : '||to_char(v_exclusion_aanwezig));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
         end if;
      end if;
      
      -- controle op uitsluiting (exclusion) bij ca
      if v_exclusion_aanwezig = 0 and i_trans_context = 'CA'
      then
         begin 
            select 9,                    p.exclusion_level
            into   v_exclusion_aanwezig, v_exclusion_level_ca
            from   pcvn_tax_exclusions p
            where  p.ptex_capc_id      = i_prod_conv_id
            and    p.ptex_be_id        = i_fonds_id
            and    p.ptex_cfcu_id      = r_cr.cxcr_cfcu_id
            and    p.ptex_fund_role    = case when i_trans_indicatie = 'D' then 2 else 1 end; -- of 2 als van of naar fonds betreft, te bekijken a.d.h.v. trans indicatie
         exception
            when no_data_found
            then
               v_exclusion_aanwezig := 0;
         end;
         -- Als er een exclusion record is, hoeft dat nog niet te betekenen dat de tax niet meegenomen hoeft te worden. Dit is nu afhankelijk van het level
         if v_exclusion_aanwezig = 9
         then
            if v_exclusion_level_ca = 0
            then
               v_exclusion_aanwezig := 1;
            else
               v_exclusion_aanwezig := 0;
            end if;
         end if;
         
         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'uitsluiting calcrule vanuit prod conv : '||to_char(v_exclusion_aanwezig));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'prod conv id : '||to_char(i_prod_conv_id)||' '||' ; fonds id : '||to_char(i_fonds_id));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'cfcu id      : '||to_char(r_cr.cxcr_cfcu_id)||' '||' ; fonds role   : '||to_char(case when i_trans_indicatie = 'D' then 2 else 1 end));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'exclusion level ca : '||to_char(v_exclusion_level_ca));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
         end if;
      end if;
      
      -- Er is geen exclusion of uitsluiting bij ca dan doorgaan met de calc rule
      if v_exclusion_aanwezig = 0
      then

         -- is er een deduction aangegeven op de context calculation rule?
         -- De conditie dat het alleen voor relatie type 1 is wordt hier niet gebruikt omdat de fiattering voor relaties is en niet voor andere relatietypen.
         if r_cr.cxcr_dedu_id is not null and r_cr.cxcr_dedu_id <> 0
         then
            if v_initiele_belast_bepaald = 0
            then
               v_aant_holders_met_exemp  := 0;

               select count(*)
               into   v_aant_holders_met_exemp
               from   holders_per_product h
               where  h.hpp_relatienummer  = gv_relatienummer
               and    h.hpp_product        = gv_rel_product_nummer
               and    h.hpp_product_volgnr = gv_rel_product_volgnummer
               and    h.hpp_type_holder    in (1, 2)
               and    (exists
                       (select 1
                        from   RM_PARTIJ_TAX_CHARACTERISTICS rtc
                        inner join country_deductions cd
                              on    cd.country_id              = rtc.ptch_land_nummer
                              and   rtc.ptch_belastingplichtig = 'J'
                              and   cd.has_exemption           = 1
                              where h.hpp_holdernummer = rtc.ptch_eor_partij_id)
                      or exists
                      (select 1
                       from   party_deductions pd
                       where  pd.party_id = h.hpp_holdernummer
                       and    pd.has_exemption = 1
                      )
                      or exists
                      (select 1
                       from   special_ca_tax_exclusions s
                       where  s.party_id   = h.hpp_holdernummer));

               v_initiele_belast_bepaald := 1;

               if gv_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in onderdeel bepalen aantal holders met vrijstelling (exemptions)');
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'aantal holders met vrijstelling : '||to_char(v_aant_holders_met_exemp));
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
               end if;
            end if;
            -- Als er holders zijn met vrijstelling, hebben dan alle holders de vrijstelling voor deze deduction?
            if v_aant_holders_met_exemp > 0
            then
               v_aant_holders_zonder_exemp := 99999999;

               select count(*)
               into   v_aant_holders_zonder_exemp
               from   holders_per_product h
               where  h.hpp_relatienummer  = gv_relatienummer
               and    h.hpp_product        = gv_rel_product_nummer
               and    h.hpp_product_volgnr = gv_rel_product_volgnummer
               and    h.hpp_type_holder in (1, 2)
               and not (exists
                        (select 1
                         from   RM_PARTIJ_TAX_CHARACTERISTICS rtc
                         inner join country_deductions cd
                               on    cd.country_id              = rtc.ptch_land_nummer
                               and   rtc.ptch_belastingplichtig = 'J'
                               and   cd.has_exemption           = 1
                               and   cd.deduction_id            = r_cr.cxcr_dedu_id
                               where h.hpp_holdernummer = rtc.ptch_eor_partij_id)
                        or exists
                        (select 1
                         from party_deductions pd
                         where pd.party_id    = h.hpp_holdernummer
                         and pd.has_exemption = 1
                         and pd.deduction_id  = r_cr.cxcr_dedu_id)
                        or exists
                        (select 1
                         from   special_ca_tax_exclusions s
                         where  s.party_id    = h.hpp_holdernummer
                         and    s.dedu_id     = r_cr.cxcr_dedu_id)
                       );

                if v_aant_holders_zonder_exemp = 0 -- als alle holders de vrijstelling hebben, dan moet de calc rule niet toegepast worden.
                then
                   v_calc_rule_toepassen := 0;
                   -- Als er wel vrijstelling is voor alle holders, maar het betreft bepaalde WHT dan moet wel de waarde bepaald worden om eventueel de grondslag voor RV mee te corrigeren.
                   if r_cr.cxcr_cfcu_id in (77, 106, 107, 108, 109, 110)
                   then
                      v_calc_rule_toepassen := 1;   -- Calc rule wel aanlaten om in ieder geval te gaan berekenen
                      v_wht_exemption       := 1;   -- Hiermee aangeven dat voor WHT wel een vrijstelling geldt, maar de berekening toch gedaan moet worden. 
                end if;
                end if;

                if gv_debuggen = 1
                then
                   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in onderdeel bepalen aantal holders zonder vrijstelling (exemptions)');
                   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'aantal holders zonder vrijstelling : '||to_char(v_aant_holders_zonder_exemp)||
                                                           ' ; calc rule toepassen : '||to_char(v_calc_rule_toepassen));
                   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'wht exemption van toepassing : '||to_char(v_wht_exemption));
                   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                end if;
            end if;
            
            -- Nog kijken of er een exemption is voor de combinatie deduction, legal entity en fundcatogory
            begin
               select f.has_exemption
               into   v_has_exemption
               from   fundcategory_deductions f
               where  f.fuca_id         = gv_fundcategory
               and    f.lety_id         = gv_legal_entity_type
               and    f.dedu_id         = r_cr.cxcr_dedu_id;
            exception
               when no_data_found
               then
                  v_has_exemption  := 0;
            end;                     
            
            if gv_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in onderdeel voor bepalen examption voor combinatie legal entity en fundcategory');
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fundcategory : '||to_char(gv_fundcategory)||' ; legal entity type : '||to_char(gv_legal_entity_type));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'deduction id : '||to_char(r_cr.cxcr_dedu_id)||' ; has examption : '||to_char(v_has_exemption));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
         end if;
         end if;

      -- er zijn geen exclusions of vrijstellingen, de calc rule moet worden uitgevoerd
      if v_calc_rule_toepassen = 1
      then
         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In deel met calc rule toepassen');
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
         end if;

      -- table is hier al samen te stellen....
      if r_cr.cfcu_type = 'COMMISSION'
      then
         v_table        := 'COMMISSION';
      elsif r_cr.cfcu_type = 'INDIRECT'
      then
         if r_cr.cfcu_method = 'FXC'
         then
            v_table   := 'FX_SPREAD';
         else
            v_table   := 'IC_COSTS';
         end if;
      elsif r_cr.cfcu_type = 'TAX' and r_cr.cfcu_method <> 'WHT'
      then
         v_table := 'TARIFFS';
      else
         v_table := ' ';
      end if;
      
      -- Kijken of minimum en maximum bedrag toegestaan zijn
      begin
         select 1
         into   v_max_amount_allowed
         from   calculationparams c
         where  c.cfcp_cfcu_id = r_cr.cxcr_cfcu_id
         and    c.cfcp_type    = 'MAX';
      exception
         when no_data_found
         then
            v_max_amount_allowed := 0;
      end;
      
      begin
         select 1
         into   v_min_amount_allowed 
         from   calculationparams c
         where  c.cfcp_cfcu_id = r_cr.cxcr_cfcu_id
         and    c.cfcp_type    = 'MIN';
      exception
         when no_data_found
         then
            v_min_amount_allowed := 0;
      end;
      
      -- Doorgaan voor PROD en SECU calc rules
      if r_cr.cxcr_table = 'PROD' or r_cr.cxcr_table = 'SECU'
      then
         -- Eerst voor soort PROD kijken of er iets is
         declare
            cursor tpr is

            select t.prcr_tt_id,        t.tt_fixed_amount, t.tt_minimum_amount,
                   t.tt_maximum_amount, t.ts_percentage
            from   taxproductrules_vw t
            where  t.prcr_pr_id      = i_pr_id
            and    t.prcr_cfcu_id    = r_cr.cxcr_cfcu_id;

         begin
            v_tax_prod_gevonden := 0;

            for r_tpr in tpr
            loop
               -- Gegevens vast houden als het een PROD tabel betreft
               if r_cr.cxcr_table = 'PROD'
               then
                  v_tarif_id       := nvl(r_tpr.prcr_tt_id,0);
                  v_fixed_amount   := nvl(r_tpr.tt_fixed_amount,0);
                  v_minimum_amount := nvl(r_tpr.tt_minimum_amount,0);
                  v_maximum_amount := nvl(r_tpr.tt_maximum_amount,0);
                  v_percentage     := nvl(r_tpr.ts_percentage,0);

                  if (r_tpr.tt_minimum_amount not in (null,0) and r_cr.cfcu_method in ('HYBRID','CC')) or v_min_amount_allowed = 1
                  then
                     v_has_min_amount := 1;
                     if r_cr.cfcu_pay_off_type = 'TRANS'
                     then
                        omrekenen_bv_tv(v_minimum_amount, v_minimum_amount);
                     end if;
                  else
                     v_has_min_amount := 0;
                  end if;

                  if (r_tpr.tt_maximum_amount not in (null,0) and r_cr.cfcu_method in ('HYBRID','CC')) or v_max_amount_allowed = 1
                  then
                     v_has_max_amount := 1;
                     if r_cr.cfcu_pay_off_type = 'TRANS'
                     then
                        omrekenen_bv_tv(v_maximum_amount, v_maximum_amount);
                     end if;
                  else
                     v_has_max_amount := 0;
                  end if;
                  
                  if r_cr.cfcu_pay_off_type = 'TRANS'
                  then
                     omrekenen_bv_tv(v_fixed_amount, v_fixed_amount);
                  end if;
               end if;

                     -- Is er een deduction tarif aanwezig?
                     begin
                        select p.dita_id
                        into   v_discount_tarif_id
                        from   prod_dedu_discount p
                        where  p.pr_id          = gv_pr_id
                        and    p.dedu_id        = r_cr.cxcr_dedu_id
                        and    p.pach_id        = gv_eor_kenmerk_id; 
                     exception
                        when no_data_found
                        then
                           v_discount_tarif_id := 0;
                     end;
                     
               v_tax_prod_gevonden := 1;

               if gv_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In loop r_tpr'||' ; tax prod gevonden : '||to_char(v_tax_prod_gevonden));
                        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
               end if;
            end loop;
            -- Wegschrijven als het een PROD tabel betreft.
            if v_tax_prod_gevonden = 1 and r_cr.cxcr_table = 'PROD'
            then
                     calc_lines_schrijven (r_cr.cxcr_cfcu_id, v_tarif_id,                  v_table,           v_fixed_amount,
                                           v_maximum_amount,  v_minimum_amount,            v_percentage,      v_has_max_amount,
                                           v_has_min_amount,  trim(r_cr.cfcu_amount_type), i_trans_indicatie, v_discount_tarif_id,
                                           v_wht_exemption,   v_bsp_instapfee_aanwezig,    o_te_doorlopen_amount_type);
            end if;
         end;
         -- Aansluitend door gaan met SECU controle als de PROD controle gelukt is
         if v_tax_prod_gevonden = 1
         then
            -- De indirecte kosten hier overslaan
            if r_cr.cfcu_type <> 'INDIRECT'
            then
               declare
                  cursor stt is
                  select t.tt_id, t.tt_fixed_amount, t.tt_minimum_amount, t.tt_maximum_amount
                  from   security_tax_tariff s, tax_tarif t
                  where  s.sctt_be_id = i_fonds_id
                  and    t.tt_id      = s.sctt_tt_id
                  and    t.tt_cfcu_id = r_cr.cxcr_cfcu_id;

               begin
                  for r_stt in stt
                  loop
                     begin
                        select s.ts_percentage
                        into   v_percentage
                        from   tax_tarif_scales s
                        where  s.ts_tt_id = r_stt.tt_id;
                     exception
                        when no_data_found
                        then
                           v_percentage := 0;
                     end;

                     v_tarif_id       := nvl(r_stt.tt_id,0);
                     v_fixed_amount   := nvl(r_stt.tt_fixed_amount,0);
                     v_minimum_amount := nvl(r_stt.tt_minimum_amount,0);
                     v_maximum_amount := nvl(r_stt.tt_maximum_amount,0);

                     if (r_stt.tt_minimum_amount not in (null,0) and r_cr.cfcu_method in ('HYBRID','CC')) or v_min_amount_allowed = 1
                     then
                        v_has_min_amount := 1;
                        if r_cr.cfcu_pay_off_type = 'TRANS'
                        then
                           omrekenen_bv_tv(v_minimum_amount, v_minimum_amount);
                        end if;
                     else
                        v_has_min_amount := 0;
                     end if;

                     if (r_stt.tt_maximum_amount not in (null,0) and r_cr.cfcu_method in ('HYBRID','CC')) or v_max_amount_allowed = 1
                     then
                        v_has_max_amount := 1;
                        if r_cr.cfcu_pay_off_type = 'TRANS'
                        then
                           omrekenen_bv_tv(v_maximum_amount, v_maximum_amount);
                        end if;
                     else
                        v_has_max_amount := 0;
                     end if;
                     
                     if r_cr.cfcu_pay_off_type = 'TRANS'
                     then
                        omrekenen_bv_tv(v_fixed_amount, v_fixed_amount);
                     end if;
                           -- Als er een uitzondering is (legal entity, fund category en deducion id), dan 100 % discount --> Tarif id = 400
                           if v_has_exemption = 1 
                              or 
                              v_wht_exemption = 1
                           then
                              v_discount_tarif_id := 400;
                           end if;
                     
                           calc_lines_schrijven (r_cr.cxcr_cfcu_id, v_tarif_id,                  v_table,           v_fixed_amount,
                                                 v_maximum_amount,  v_minimum_amount,            v_percentage,      v_has_max_amount,
                                                 v_has_min_amount,  trim(r_cr.cfcu_amount_type), i_trans_indicatie, v_discount_tarif_id, 
                                                 v_wht_exemption,   v_bsp_instapfee_aanwezig,    o_te_doorlopen_amount_type);

                  end loop;
               end;
            -- De indirecte kosten hier uitvoeren
            else
               declare
                  cursor ic is
                  select i.icf_amount, i.icf_percentage
                  from   indirect_costs_per_fund_vw i
                           where  i.icf_be_id      = i_fonds_id
                           and    i.icf_cfcu_id    = r_cr.cxcr_cfcu_id
                  and    i.icf_date_since <= sysdate
                  and    (i.icf_date_till is null
                          or
                          i.icf_date_till >= sysdate);
               begin
                  for r_ic in ic
                  loop
                           v_tarif_id          := 0;
                           v_fixed_amount      := nvl(r_ic.icf_amount,0);
                           v_minimum_amount    := 0;
                           v_maximum_amount    := 0;
                           v_percentage        := nvl(r_ic.icf_percentage,0);
                           v_has_max_amount    := 0;
                           v_has_min_amount    := 0;
                           v_discount_tarif_id := 0;
                      
                      if r_cr.cfcu_pay_off_type = 'TRANS'
                      then
                         omrekenen_bv_tv(v_fixed_amount, v_fixed_amount);
                      end if;
                      
                           calc_lines_schrijven (r_cr.cxcr_cfcu_id, v_tarif_id,                      v_table,           v_fixed_amount,
                                                 v_maximum_amount,  v_minimum_amount,                v_percentage,      v_has_max_amount,
                                                 v_has_min_amount,  trim(r_cr.cfcu_amount_type),     i_trans_indicatie, v_discount_tarif_id,
                                                 0,                 v_bsp_instapfee_aanwezig,        o_te_doorlopen_amount_type);
                  end loop;
               end;
            end if;
         end if;

      else
         -- geen PROD of SECU, dan opnemen om door te lopen voor berekeningen
         calc_lines_schrijven (r_cr.cxcr_cfcu_id, 0, v_table, 0, 0, 0, 0, 0, 0, trim(r_cr.cfcu_amount_type), 
                                     i_trans_indicatie, 0, 0, v_bsp_instapfee_aanwezig, o_te_doorlopen_amount_type);
      end if;

      end if; -- calc rule gebruiken
      end if; -- einde geen exclusion aanwezig.
   end loop;

   o_bsp_instapfee_aanwezig := v_bsp_instapfee_aanwezig;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'BSP instapfee aanwezig : '||to_char(o_bsp_instapfee_aanwezig));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'einde bepalen calc rules ');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
   end if;
end bepalen_calc_lines;
-- EINDE CODE PROCEDURE BEPALEN_CALC_LINES


-- DE CODE VOOR DE PROCEDURE ADMIN_EXTERNAL_FEES
procedure admin_external_fees
(i_ordernummer                 in     orders.ord_ordernummer%type
,i_orderregel                  in     orders.ord_orderregel%type
,i_detailnummer                in     ordersdetaillering.orx_detailnummer%type
,i_trans_indicatie             in     kosten_werkbestand.kst_trans_indicatie%type
,o_te_doorlopen_amount_type    in out varchar2
,o_bsp_instapfee_aanwezig      in out number
)
is

  v_table                  varchar2(15);

  cursor ef is
     select f.focd_cfcu_id, c.cfcu_type, c.cfcu_method, c.cfcu_amount_type
     from   fiat_order_costs_det f, calculationrules c
     where  f.focd_order_number  = i_ordernummer
     and    f.focd_order_line    = i_orderregel
     and    f.focd_order_det_num = i_detailnummer
     and    f.focd_cfcu_id       = c.cfcu_id;
begin
  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in admin_external_fees');
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
  end if;

  for r_ef in ef
  loop

     if r_ef.cfcu_type = 'COMMISSION'
     then
        v_table        := 'COMMISSION';
     elsif r_ef.cfcu_type = 'INDIRECT'
     then
        if r_ef.cfcu_method = 'FXC'
        then
           v_table   := 'FX_SPREAD';
        else
           v_table   := 'IC_COSTS';
        end if;
     elsif r_ef.cfcu_type = 'TAX' and r_ef.cfcu_method <> 'WHT'
     then
        v_table := 'TARIFFS';
     else
        v_table := ' ';
     end if;

     calc_lines_schrijven(r_ef.focd_cfcu_id,0,v_table,0,0,0,0,0,0,r_ef.cfcu_amount_type, i_trans_indicatie,0,0, o_bsp_instapfee_aanwezig, o_te_doorlopen_amount_type);

  end loop;

  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'einde admin_external_fees');
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'te doorlopen amount types : '||o_te_doorlopen_amount_type);
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
  end if;

end admin_external_fees;
-- EINDE CODE PROCEDURE ADMIN_EXTERNAL_FEES


-- DE CODE VOOR DE PROCEDURE CALC_LINES_SCHRIJVEN
procedure calc_lines_schrijven
(i_rule_id                  in     calculationrules.cfcu_id%type
,i_tarif_id                 in     tax_tarif.tt_id%type
,i_table                    in     varchar2
,i_fixed_amount             in     taxproductrules_vw.tt_fixed_amount%type
,i_maximum_amount           in     taxproductrules_vw.tt_maximum_amount%type
,i_minimum_amount           in     taxproductrules_vw.tt_minimum_amount%type
,i_percentage               in     fiat_order_costs_det.focd_rule_var_amt_perc%type  -- Percentage voor indirecte kosten bevat meer decimalen
,i_has_max_amount           in     number
,i_has_min_amount           in     number
,i_amount_type              in     calculationrules.cfcu_amount_type%type
,i_trans_indicatie          in     kosten_werkbestand.kst_trans_indicatie%type
,i_discount_tarif_id        in     prod_dedu_discount.dita_id%type
,i_wht_exemption            in     number
,o_bsp_instapfee_aanwezig   in out number
,o_te_doorlopen_amount_type in out varchar2
)

is
  
   v_amount_type           calculationrules.cfcu_amount_type%type;
  
begin
   -- Bepaalde WHT-soorten moeten eerder berekend worden voor bepaalde RV-soorten. Daarom die WHT-soorten een eigen amounttype geven die eerder verwerkt kan worden.
   if i_rule_id in (77,106,107,108,109,110)
   then
      if i_amount_type = 'EFFAMT'
      then
         v_amount_type := 'CAEFFA';
      elsif i_amount_type = 'EFFNUL'
      then
         v_amount_type := 'CAEFFN';
      end if;
   else
      v_amount_type := i_amount_type;
   end if;
   -- voor nu de calculationlines wegschrijven in het werkbestand
   update werkbestand w
   set    w.wk_categorie_3 = to_char(i_tarif_id,'9999')||' '||trim(i_table),
          w.wk_categorie_4 = trim(to_char(i_has_max_amount,'9'))||' '||trim(to_char(i_has_min_amount,'9'))||' '||trim(to_char(i_discount_tarif_id,'999999999999999')),
          w.wk_waarde_1    = i_fixed_amount,
          w.wk_waarde_2    = i_maximum_amount,
          w.wk_waarde_3    = i_minimum_amount,
          w.wk_waarde_4    = i_percentage * 10000,
          w.wk_export      = i_wht_exemption
   where  w.wk_terminal    = gv_terminalnummer
   and    w.wk_soort       = 'CALI'
   and    w.wk_categorie_1 = trim(v_amount_type)
   and    w.wk_categorie_2 = to_char(i_rule_id,'9999')||' '||i_trans_indicatie||' '||to_char(gv_fonds_id,'999999999999999');

   if sql%notfound
   then
      insert into werkbestand
      (wk_terminal,                                    wk_soort,
       wk_categorie_1,                                 wk_categorie_2,
       wk_categorie_3,                                 wk_categorie_4,
       wk_waarde_1,                                    wk_waarde_2,
       wk_waarde_3,                                    wk_waarde_4,
       wk_export)
      values
      (gv_terminalnummer,                              'CALI',
       trim(v_amount_type),                            to_char(i_rule_id,'9999')||' '||i_trans_indicatie||' '||to_char(gv_fonds_id,'999999999999999'),
       to_char(i_tarif_id,'9999')||' '||trim(i_table), ltrim(to_char(i_has_max_amount,'9'))||' '||ltrim(to_char(i_has_min_amount,'9'))||' '||trim(to_char(i_discount_tarif_id,'999999999999999')),
       i_fixed_amount,                                 i_maximum_amount,
       i_minimum_amount,                               i_percentage * 10000,
       i_wht_exemption);
   end if;

   if gv_belgisch_spaar_product = 1 and i_rule_id = gv_instapfee_rule_id -- Als er instap fee voor Star fund is, dan dit even vast houden om
   then                                                                  -- later rekening mee te kunnen houden.
      o_bsp_instapfee_aanwezig := 1;
   end if;
   
   -- methode vastleggen om later door te doorlopen
   if instr(o_te_doorlopen_amount_type,trim(v_amount_type)) = 0
   then
      o_te_doorlopen_amount_type := trim(o_te_doorlopen_amount_type)||'<'||trim(v_amount_type)||'>';
   end if;
   
   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'wegschrijven calc line');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'calc rule id    : '||to_char(i_rule_id)||' ; tax tarif : '||to_char(i_tarif_id));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fixed amount    : '||to_char(i_fixed_amount)||' ; percentage : '||to_char(i_percentage));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'minimum amount  : '||to_char(i_minimum_amount)||' ;  has minimum amount : '||to_char(i_has_min_amount));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'maximum amount  : '||to_char(i_maximum_amount)||' ;  has maximum amount : '||to_char(i_has_max_amount));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'amount type     : '||v_amount_type||' ; table : '||i_table||' ; i amount type : '||i_amount_type);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'trans indicatie : '||i_trans_indicatie||' ; fonds id : '||to_char(gv_fonds_id));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'bsp instapfee aanwezig : '||to_char(o_bsp_instapfee_aanwezig)||' ; has exemption : '||to_char(i_discount_tarif_id));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'wht exemption   : '||to_char(i_wht_exemption));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

end calc_lines_schrijven;
-- EINDE CODE CALC_LINES_SCHRIJVEN


-- DE CODE VOOR DE PROCEDURE ORDER_KOSTEN_BEREKENEN
procedure order_kosten_berekenen
(i_ordernummer               in  kosten_werkbestand.kst_ordernummer%type
,i_orderregel                in  kosten_werkbestand.kst_orderregel%type
,i_orderdetail               in  kosten_werkbestand.kst_detailnummer%type
,i_effectief_bedrag_rv       in  kosten_werkbestand.kst_effect_bedrag_rv%type
,i_effectief_bedrag_bv       in  kosten_werkbestand.kst_effect_bedrag_bv%type
,i_effectief_bedrag_tv       in  kosten_werkbestand.kst_effect_bedrag_bv%type
,i_lopende_rente_tv          in  kosten_werkbestand.kst_effect_bedrag_bv%type
,i_lopende_rente_bv          in  kosten_werkbestand.kst_effect_bedrag_bv%type
,i_lopende_rente_rv          in  kosten_werkbestand.kst_effect_bedrag_rv%type
,i_order_aantal              in  kosten_werkbestand.kst_trans_aantal%type
,i_klant_prijs               in  transakties.tr_prijs_tr_mntsrt%type
,i_beurs_prijs               in  transakties.tr_beurs_prijs_trm%type
,i_fondskoers_comb_order     in  transakties.tr_prijs_tr_mntsrt%type
,i_te_doorlopen_amount_types in  varchar2
,i_transactie_indicatie      in  kosten_werkbestand.kst_trans_indicatie%type
,i_trans_k_v_ind             in  kosten_werkbestand.kst_trans_indicatie_w%type
,i_prijs_factor_fonds        in  kosten_werkbestand.kst_prijs_factor_fnds%type
,i_ex_ass_factor_fonds       in  kosten_werkbestand.kst_fnds_ex_ass_fac%type
,i_geen_provisie_berekenen   in  kosten_werkbestand.kst_ord_geen_provisie%type
,i_ord_prov_perc_eff_wrd     in  kosten_werkbestand.kst_ord_provperceffw%type
,i_ord_prov_kort_perc        in  kosten_werkbestand.kst_prov_korting_perc%type
,i_trans_market_koers        in  fiat_muntsoorten.fimu_middenkoers%type
,i_order_geldrek_muntsoort   in  kosten_werkbestand.kst_rel1_rek2_munts%type
,i_richting_omwisseling      in  number                                      -- 1 is van, 2 is naar, alleen van toepassing als context = 'CA'
,o_effectief_bedrag_rv       out kosten_werkbestand.kst_effect_bedrag_rv%type
,o_effectief_bedrag_bv       out kosten_werkbestand.kst_effect_bedrag_bv%type
,o_effectief_bedrag_tv       out kosten_werkbestand.kst_effect_bedrag_bv%type
)

is
  v_reken_eff_bedrag_rv          kosten_werkbestand.kst_effect_bedrag_rv%type := 0;
  v_reken_eff_bedrag_bv          kosten_werkbestand.kst_effect_bedrag_bv%type := 0;
  v_reken_eff_bedrag_tv          kosten_werkbestand.kst_effect_bedrag_bv%type := 0;

  v_reken_bedrag_rv              kosten_werkbestand.kst_effect_bedrag_rv%type := 0;
  v_reken_bedrag_bv              kosten_werkbestand.kst_effect_bedrag_bv%type := 0;
  v_reken_bedrag_tv              kosten_werkbestand.kst_effect_bedrag_bv%type := 0;

  v_correctie_bedrag_rv          kosten_werkbestand.kst_effect_bedrag_rv%type := 0;
  v_correctie_bedrag_bv          kosten_werkbestand.kst_effect_bedrag_bv%type := 0;
  v_correctie_bedrag_tv          kosten_werkbestand.kst_effect_bedrag_bv%type := 0;

  v_provisie_bedrag_rv           kosten_werkbestand.kst_provisie_bedrag%type := 0;
  v_provisie_bedrag_bv           kosten_werkbestand.kst_provisie_bedrag%type := 0;
  v_provisie_bedrag_tv           kosten_werkbestand.kst_provisie_bedrag%type := 0;

  v_amount_type                  calculationrules.cfcu_amount_type%type;

  v_dummy_num                    kosten_werkbestand.kst_effect_bedrag_bv%type;
  v_instapfee_apart              number(1);


begin
  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure order_kosten_bereken ');
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i effectief bedrag rv   : '||to_char(i_effectief_bedrag_rv)||' ; i effectief bedrag bv : '||to_char(i_effectief_bedrag_bv));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i effectief bedrag tv   : '||to_char(i_effectief_bedrag_tv));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i te doorlopen amount types : '||trim(i_te_doorlopen_amount_types));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
  end if;

  -- de aangeleverde effectieve bedragen overnemen in de rekenvariabelen:
  v_reken_eff_bedrag_rv := i_effectief_bedrag_rv;
  v_reken_eff_bedrag_bv := i_effectief_bedrag_bv;
  v_reken_eff_bedrag_tv := i_effectief_bedrag_tv;

  -- Als bepaald is dat bps instapfee aanwezig is, dan die eerst berekenen en het effectief bedrag daarop aanpassen.
  if gv_bsp_instapfee_aanwezig = 1
  then
     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in onderdeel bsp instapfee aanwezig');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
     end if;
     v_instapfee_apart := 1;
     v_amount_type := 'EFFAMT';

     if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
     then
        calc_lines_verwerken (v_amount_type,           i_ordernummer,         i_orderregel,              i_orderdetail,
                              v_reken_eff_bedrag_rv,   v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv,     i_order_aantal,
                              i_klant_prijs,           i_beurs_prijs,         i_fondskoers_comb_order,   i_transactie_indicatie,
                              i_trans_k_v_ind,         i_prijs_factor_fonds,  i_ex_ass_factor_fonds,     i_geen_provisie_berekenen,
                              i_ord_prov_perc_eff_wrd, i_ord_prov_kort_perc,  i_order_geldrek_muntsoort, i_trans_market_koers,
                              v_instapfee_apart,       gv_context,            i_richting_omwisseling,
                              v_dummy_num,             v_dummy_num,           v_dummy_num,               v_reken_bedrag_rv,         
                              v_reken_bedrag_bv,       v_reken_bedrag_tv);

        -- Het effectief bedrag aanpassen met het berekende reken bedrag om het correcte effectieve bedrag te verkrijgen:
        v_reken_eff_bedrag_bv := v_reken_eff_bedrag_bv - v_reken_bedrag_bv;
        v_reken_eff_bedrag_rv := v_reken_eff_bedrag_rv - v_reken_bedrag_rv;
        v_reken_eff_bedrag_tv := v_reken_eff_bedrag_tv - v_reken_bedrag_tv;

        if gv_debuggen = 1
        then
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'reken eff bedrag bv : '||to_char(v_reken_eff_bedrag_bv)||' ; reken bedrag bv : '||to_char(v_reken_bedrag_bv));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'reken eff bedrag rv : '||to_char(v_reken_eff_bedrag_rv)||' ; reken bedrag rv : '||to_char(v_reken_bedrag_rv));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'reken eff bedrag tv : '||to_char(v_reken_eff_bedrag_tv)||' ; reken bedrag tv : '||to_char(v_reken_bedrag_tv));
        end if;

/*        optellen_bedragen (v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv, v_reken_bedrag_rv,     v_reken_bedrag_bv,
                           v_reken_bedrag_tv,     i_trans_k_v_ind,       v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv);
*/
        if gv_debuggen = 1
        then
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Einde onderdeel bsp instapfee aanwezig');
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
        end if;
     end if;

     -- Als laatste aangeven dat de instapfee al berekend is, dus niet weer opnieuw meenemen in het doorlopen van de calcrules
     v_instapfee_apart := 2;
  else
     v_instapfee_apart := 0;
  end if;
  -- De methodes op vastgestelde volgorde doorlopen
  -- In verband met WHT voor CA moet die eerst worden berekend (hiermee afwijkend van de ep/ta programmatuur, waar een gecorrigeerde prijs wordt gebruikt)
  -- Dit zijn de amount typen CAEFFN en CAEFFA
  v_amount_type := 'CAEFFN';
  -- een methode alleen uitvoeren als deze is vastgelegd in de calc lines  
  if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
  then
     calc_lines_verwerken (v_amount_type,           i_ordernummer,         i_orderregel,              i_orderdetail,
                           v_reken_eff_bedrag_rv,   v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv,     i_order_aantal,
                           i_klant_prijs,           i_beurs_prijs,         i_fondskoers_comb_order,   i_transactie_indicatie,
                           i_trans_k_v_ind,         i_prijs_factor_fonds,  i_ex_ass_factor_fonds,     i_geen_provisie_berekenen,
                           i_ord_prov_perc_eff_wrd, i_ord_prov_kort_perc,  i_order_geldrek_muntsoort, i_trans_market_koers,
                           v_instapfee_apart,       gv_context,            i_richting_omwisseling,    
                           v_dummy_num,             v_dummy_num,           v_dummy_num,               v_reken_bedrag_rv,         
                           v_reken_bedrag_bv,       v_reken_bedrag_tv);

     optellen_bedragen (v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv, v_reken_bedrag_rv,     v_reken_bedrag_bv,
                        v_reken_bedrag_tv,     i_trans_k_v_ind,       v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv);  
  end if;
  
  v_amount_type := 'CAEFFA';
  if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
  then
     calc_lines_verwerken (v_amount_type,           i_ordernummer,         i_orderregel,              i_orderdetail,
                           v_reken_eff_bedrag_rv,   v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv,     i_order_aantal,
                           i_klant_prijs,           i_beurs_prijs,         i_fondskoers_comb_order,   i_transactie_indicatie,
                           i_trans_k_v_ind,         i_prijs_factor_fonds,  i_ex_ass_factor_fonds,     i_geen_provisie_berekenen,
                           i_ord_prov_perc_eff_wrd, i_ord_prov_kort_perc,  i_order_geldrek_muntsoort, i_trans_market_koers,
                           v_instapfee_apart,       gv_context,            i_richting_omwisseling,    
                           v_dummy_num,             v_dummy_num,           v_dummy_num,               v_reken_bedrag_rv,         
                           v_reken_bedrag_bv,       v_reken_bedrag_tv);

     optellen_bedragen (v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv, v_reken_bedrag_rv,     v_reken_bedrag_bv,
                        v_reken_bedrag_tv,     i_trans_k_v_ind,       v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv);  
  end if;
  
  -- Vanaf hier de volgorde die door de programmatuur in de ta wordt aangehouden
  v_amount_type := 'TAXBAS';
  if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
  then
     calc_lines_verwerken (v_amount_type,           i_ordernummer,         i_orderregel,              i_orderdetail,
                           0,                       0,                     0,                         i_order_aantal,
                           i_klant_prijs,           i_beurs_prijs,         i_fondskoers_comb_order,   i_transactie_indicatie,
                           i_trans_k_v_ind,         i_prijs_factor_fonds,  i_ex_ass_factor_fonds,     i_geen_provisie_berekenen,
                           i_ord_prov_perc_eff_wrd, i_ord_prov_kort_perc,  i_order_geldrek_muntsoort, i_trans_market_koers,
                           0,                       gv_context,            i_richting_omwisseling,    
                           v_correctie_bedrag_rv,   v_correctie_bedrag_bv, v_correctie_bedrag_tv,     v_dummy_num,               
                           v_dummy_num,             v_dummy_num);
  end if;
  
  v_amount_type := 'EFFNUL';
  if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
  then
     calc_lines_verwerken (v_amount_type,           i_ordernummer,         i_orderregel,              i_orderdetail,
                           v_reken_eff_bedrag_rv,   v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv,     i_order_aantal,
                           i_klant_prijs,           i_beurs_prijs,         i_fondskoers_comb_order,   i_transactie_indicatie,
                           i_trans_k_v_ind,         i_prijs_factor_fonds,  i_ex_ass_factor_fonds,     i_geen_provisie_berekenen,
                           i_ord_prov_perc_eff_wrd, i_ord_prov_kort_perc,  i_order_geldrek_muntsoort, i_trans_market_koers,
                           v_instapfee_apart,       gv_context,            i_richting_omwisseling,    
                           v_dummy_num,             v_dummy_num,           v_dummy_num,               v_reken_bedrag_rv,         
                           v_reken_bedrag_bv,       v_reken_bedrag_tv);
     
     optellen_bedragen (v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv, v_reken_bedrag_rv,     v_reken_bedrag_bv,
                        v_reken_bedrag_tv,     i_trans_k_v_ind,       v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv);  
  end if;
  
  v_amount_type := 'EFFAMT';
  if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
  then
     calc_lines_verwerken (v_amount_type,           i_ordernummer,         i_orderregel,              i_orderdetail,
                           v_reken_eff_bedrag_rv,   v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv,     i_order_aantal,
                           i_klant_prijs,           i_beurs_prijs,         i_fondskoers_comb_order,   i_transactie_indicatie,
                           i_trans_k_v_ind,         i_prijs_factor_fonds,  i_ex_ass_factor_fonds,     i_geen_provisie_berekenen,
                           i_ord_prov_perc_eff_wrd, i_ord_prov_kort_perc,  i_order_geldrek_muntsoort, i_trans_market_koers,
                           v_instapfee_apart,       gv_context,            i_richting_omwisseling,    
                           v_dummy_num,             v_dummy_num,           v_dummy_num,               v_reken_bedrag_rv,         
                           v_reken_bedrag_bv,       v_reken_bedrag_tv);

     optellen_bedragen (v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv, v_reken_bedrag_rv,     v_reken_bedrag_bv,
                        v_reken_bedrag_tv,     i_trans_k_v_ind,       v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv);
  end if;

  v_amount_type := 'EFFCOR';
  -- het effectief bedrag corrigeren voor de berekende bedragen bij TAXBAS
  optellen_bedragen (v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv, v_correctie_bedrag_rv, v_correctie_bedrag_bv,
                     v_correctie_bedrag_tv, i_trans_k_v_ind,       v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv);
  if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
  then
     calc_lines_verwerken (v_amount_type,           i_ordernummer,         i_orderregel,              i_orderdetail,
                           v_reken_eff_bedrag_rv,   v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv,     i_order_aantal,
                           i_klant_prijs,           i_beurs_prijs,         i_fondskoers_comb_order,   i_transactie_indicatie,
                           i_trans_k_v_ind,         i_prijs_factor_fonds,  i_ex_ass_factor_fonds,     i_geen_provisie_berekenen,
                           i_ord_prov_perc_eff_wrd, i_ord_prov_kort_perc,  i_order_geldrek_muntsoort, i_trans_market_koers,
                           0,                       gv_context,            i_richting_omwisseling,    
                           v_dummy_num,             v_dummy_num,           v_dummy_num,               v_reken_bedrag_rv,         
                           v_reken_bedrag_bv,       v_reken_bedrag_tv);

     optellen_bedragen (v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv, v_reken_bedrag_rv,     v_reken_bedrag_bv,
                        v_reken_bedrag_tv,     i_trans_k_v_ind,       v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv);
  end if;

  v_amount_type := 'INTRST';
  if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
  then
     calc_lines_verwerken (v_amount_type,           i_ordernummer,        i_orderregel,              i_orderdetail,
                           i_lopende_rente_rv,      i_lopende_rente_bv,   i_lopende_rente_tv,        i_order_aantal,
                           i_klant_prijs,           i_beurs_prijs,        i_fondskoers_comb_order,   i_transactie_indicatie,
                           i_trans_k_v_ind,         i_prijs_factor_fonds, i_ex_ass_factor_fonds,     i_geen_provisie_berekenen,
                           i_ord_prov_perc_eff_wrd, i_ord_prov_kort_perc, i_order_geldrek_muntsoort, i_trans_market_koers,
                           0,                       gv_context,           i_richting_omwisseling,    
                           v_dummy_num,             v_dummy_num,          v_dummy_num,               v_reken_bedrag_rv,         
                           v_reken_bedrag_bv,       v_reken_bedrag_tv);

     optellen_bedragen (v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv, v_reken_bedrag_rv,     v_reken_bedrag_bv,
                        v_reken_bedrag_tv,     i_trans_k_v_ind,       v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv);
  end if;

  v_amount_type := 'NETAMT';
  if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
  then
     calc_lines_verwerken (v_amount_type,           i_ordernummer,         i_orderregel,              i_orderdetail,
                           v_reken_eff_bedrag_rv,   v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv,     i_order_aantal,
                           i_klant_prijs,           i_beurs_prijs,         i_fondskoers_comb_order,   i_transactie_indicatie,
                           i_trans_k_v_ind,         i_prijs_factor_fonds,  i_ex_ass_factor_fonds,     i_geen_provisie_berekenen,
                           i_ord_prov_perc_eff_wrd, i_ord_prov_kort_perc,  i_order_geldrek_muntsoort, i_trans_market_koers,
                           0,                       gv_context,            i_richting_omwisseling,    
                           v_dummy_num,             v_dummy_num,           v_dummy_num,               v_reken_bedrag_rv,         
                           v_reken_bedrag_bv,       v_reken_bedrag_tv);

     optellen_bedragen (v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv, v_reken_bedrag_rv,     v_reken_bedrag_bv,
                        v_reken_bedrag_tv,     i_trans_k_v_ind,       v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv);
  end if;

  v_amount_type := 'SYSTEM';
  if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
  then
     calc_lines_verwerken (v_amount_type,           i_ordernummer,         i_orderregel,              i_orderdetail,
                           i_effectief_bedrag_rv,   i_effectief_bedrag_bv, i_effectief_bedrag_tv,     i_order_aantal,
                           i_klant_prijs,           i_beurs_prijs,         i_fondskoers_comb_order,   i_transactie_indicatie,
                           i_trans_k_v_ind,         i_prijs_factor_fonds,  i_ex_ass_factor_fonds,     i_geen_provisie_berekenen,
                           i_ord_prov_perc_eff_wrd, i_ord_prov_kort_perc,  i_order_geldrek_muntsoort, i_trans_market_koers,
                           0,                       gv_context,            i_richting_omwisseling,    
                           v_dummy_num,             v_dummy_num,           v_dummy_num,               v_reken_bedrag_rv,         
                           v_reken_bedrag_bv,       v_reken_bedrag_tv);

     optellen_bedragen (v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv, v_reken_bedrag_rv,     v_reken_bedrag_bv,
                        v_reken_bedrag_tv,     i_trans_k_v_ind,       v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv);

  end if;
  v_amount_type := 'COMMIS';
  if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
  then
     calc_lines_verwerken (v_amount_type,           i_ordernummer,         i_orderregel,              i_orderdetail,
                           v_provisie_bedrag_rv,    v_provisie_bedrag_bv,  v_provisie_bedrag_tv,      i_order_aantal,
                           i_klant_prijs,           i_beurs_prijs,         i_fondskoers_comb_order,   i_transactie_indicatie,
                           i_trans_k_v_ind,         i_prijs_factor_fonds,  i_ex_ass_factor_fonds,     i_geen_provisie_berekenen,
                           i_ord_prov_perc_eff_wrd, i_ord_prov_kort_perc,  i_order_geldrek_muntsoort, i_trans_market_koers,
                           0,                       gv_context,            i_richting_omwisseling,    
                           v_dummy_num,             v_dummy_num,           v_dummy_num,               v_reken_bedrag_rv,         
                           v_reken_bedrag_bv,       v_reken_bedrag_tv);

     optellen_bedragen (v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv, v_reken_bedrag_rv,     v_reken_bedrag_bv,
                        v_reken_bedrag_tv,     i_trans_k_v_ind,       v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv);
  end if;


  v_amount_type := 'ECOSTS';
  if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
  then
     null;
  end if;
  -- Indirecte kosten worden voor eerst overgeslagen
/*  v_amount_type := 'ICOSTS';
  if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
  then
     null;
  end if; */
  v_amount_type := 'NOTAMT';
  if instr(i_te_doorlopen_amount_types,'<'||trim(v_amount_type)||'>')<>0
  then
     calc_lines_verwerken (v_amount_type,           i_ordernummer,        i_orderregel,              i_orderdetail,
                           0,                       0,                    0,                         i_order_aantal,
                           i_klant_prijs,           i_beurs_prijs,        i_fondskoers_comb_order,   i_transactie_indicatie,
                           i_trans_k_v_ind,         i_prijs_factor_fonds, i_ex_ass_factor_fonds,     i_geen_provisie_berekenen,
                           i_ord_prov_perc_eff_wrd, i_ord_prov_kort_perc, i_order_geldrek_muntsoort, i_trans_market_koers,
                           0,                       gv_context,           i_richting_omwisseling,    
                           v_dummy_num,             v_dummy_num,          v_dummy_num,               v_reken_bedrag_rv,         
                           v_reken_bedrag_bv,       v_reken_bedrag_tv);

     optellen_bedragen (v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv, v_reken_bedrag_rv,     v_reken_bedrag_bv,
                        v_reken_bedrag_tv,     i_trans_k_v_ind,       v_reken_eff_bedrag_rv, v_reken_eff_bedrag_bv, v_reken_eff_bedrag_tv);
  end if;

  -- teruggeven van de berekende gegevens (voor eerst, misschien opslaan in kosten_werkbestand...)
  o_effectief_bedrag_rv := v_reken_eff_bedrag_rv;
  o_effectief_bedrag_bv := v_reken_eff_bedrag_bv;
  o_effectief_bedrag_tv := v_reken_eff_bedrag_tv;

end order_kosten_berekenen;
-- EINDE CODE ORDER_KOSTEN_BEREKENEN


-- DE CODE VOOR CALC_LINES_VERWERKEN
procedure calc_lines_verwerken
(i_amount_type           in  calculationrules.cfcu_amount_type%type
,i_ordernummer           in  kosten_werkbestand.kst_ordernummer%type
,i_orderregel            in  kosten_werkbestand.kst_orderregel%type
,i_orderdetail           in  kosten_werkbestand.kst_detailnummer%type
,i_basis_bedrag_rv       in  kosten_werkbestand.kst_effect_bedrag_rv%type
,i_basis_bedrag_bv       in  kosten_werkbestand.kst_effect_bedrag_bv%type
,i_basis_bedrag_tv       in  kosten_werkbestand.kst_effect_bedrag_bv%type
,i_order_aantal          in  kosten_werkbestand.kst_trans_aantal%type
,i_klant_prijs           in  transakties.tr_prijs_tr_mntsrt%type
,i_beurs_prijs           in  transakties.tr_beurs_prijs_trm%type
,i_fondskoers_comb_ord   in  transakties.tr_prijs_tr_mntsrt%type
,i_transactie_indicatie  in  kosten_werkbestand.kst_trans_indicatie%type
,i_trans_k_v_ind         in  transactiesoorten.ts_koop_verkoop_ind%type
,i_prijs_factor_fonds    in  kosten_werkbestand.kst_prijs_factor_fnds%type
,i_ex_ass_factor_fonds   in  kosten_werkbestand.kst_fnds_ex_ass_fac%type
,i_geen_prov_berekenen   in  kosten_werkbestand.kst_ord_geen_provisie%type
,i_ord_prov_perc_eff_wrd in  kosten_werkbestand.kst_ord_provperceffw%type
,i_ord_prov_kort_perc    in  kosten_werkbestand.kst_prov_korting_perc%type
,i_order_geldrek_mnts    in  kosten_werkbestand.kst_rel1_rek2_munts%type
,i_trans_market_koers    in  fiat_muntsoorten.fimu_middenkoers%type
,i_instapfee_bereken     in  number
,i_context               in  contextcalculationrules.cxcr_context%type
,i_richting_omwisseling  in  number                                      -- 1 is van, 2 is naar, alleen van toepassing als context = 'CA'
,o_correctie_bedrag_rv   out kosten_werkbestand.kst_effect_bedrag_rv%type
,o_correctie_bedrag_bv   out kosten_werkbestand.kst_effect_bedrag_bv%type
,o_correctie_bedrag_tv   out kosten_werkbestand.kst_effect_bedrag_bv%type
,o_berekend_bedrag_rv    out kosten_werkbestand.kst_effect_bedrag_rv%type
,o_berekend_bedrag_bv    out kosten_werkbestand.kst_effect_bedrag_bv%type
,o_berekend_bedrag_tv    out kosten_werkbestand.kst_effect_bedrag_bv%type
)

is
  v_basis_bedrag_rv         kosten_werkbestand.kst_effect_bedrag_rv%type;
  v_basis_bedrag_bv         kosten_werkbestand.kst_effect_bedrag_bv%type;
  v_basis_bedrag_tv         kosten_werkbestand.kst_effect_bedrag_bv%type;

  v_rule_id                 calculationrules.cfcu_id%type;
  v_tarif_id                tax_tarif.tt_id%type;
  v_table                   varchar2(15);
  v_fixed_amount            taxproductrules_vw.tt_fixed_amount%type;
  v_minimum_amount          taxproductrules_vw.tt_minimum_amount%type;
  v_maximum_amount          taxproductrules_vw.tt_maximum_amount%type;
  v_percentage              fiat_order_costs_det.focd_rule_var_amt_perc%type;  -- In verband met indirecte kosten het groot decimaal percentage gebruiken
  v_has_min_amount          number(1);
  v_has_max_amount          number(1);
  v_kosten_bestaan_al       number(1);
  v_wht_exemption           werkbestand.wk_export%type;
  v_fonds_id_uit_wk         kosten_werkbestand.kst_fund_id%type;
  v_tr_ind_uit_wk           kosten_werkbestand.kst_trans_indicatie%type;
  v_discount_tarif_id       prod_dedu_discount.dita_id%type;

  v_calc_rule_type          calculationrules.cfcu_type%type;
  v_calc_rule_method        calculationrules.cfcu_method%type;
  v_calc_rule_pay_off_type  calculationrules.cfcu_pay_off_type%type;
  v_calc_rule_book_type     calculationrules.cfcu_book_type%type;

  v_reken_basis_bedrag      kosten_werkbestand.kst_effect_bedrag_rv%type;
  v_reken_bedrag            kosten_werkbestand.kst_effect_bedrag_rv%type;
  v_kost_corresp_doorb      kosten_werkbestand.kst_kost_corr_doorb%type;
  v_berekend_WHT_voor_ca    fiat_order_costs_det.focd_total_amt%type;
  v_berekend_bedrag_wht     kosten_werkbestand.kst_effect_bedrag_rv%type;
  v_dummy_num               kosten_werkbestand.kst_effect_bedrag_bv%type;

  v_berekend_bedrag_rv      kosten_werkbestand.kst_effect_bedrag_rv%type;
  v_berekend_bedrag_bv      kosten_werkbestand.kst_effect_bedrag_bv%type;
  v_berekend_bedrag_tv      kosten_werkbestand.kst_effect_bedrag_rv%type;

  v_provisie_tabel          kosten_werkbestand.kst_prov_code_tabel%type;
  v_provisie_type           kosten_werkbestand.kst_provisie_type%type;
  v_ord_provperceffw        kosten_werkbestand.kst_ord_provperceffw%type;
  v_prov_vaste_kosten       kosten_werkbestand.kst_vaste_kosten%type;
  v_prov_vari_kosten        kosten_werkbestand.kst_variabele_kosten%type;
  v_prov_korting            kosten_werkbestand.kst_provisie_korting%type;
  v_prov_korting_perc       kosten_werkbestand.kst_prov_korting_perc%type;
  v_prov_schaal_optie       schalen_tabel.st_schaal_perc%type;
  
  v_ca_base_amount_from     tax_base_amount.tba_base_amount_from%type;
  v_ca_base_amount_to       tax_base_amount.tba_base_amount_to%type;
  v_ca_base_amount          tax_base_amount.tba_base_amount_from%type;
  v_ca_gebr_afw_b_amount    number(1);
  v_ca_hold_basis_bedrag_tv kosten_werkbestand.kst_effect_bedrag_bv%type;
  v_ca_hold_basis_bedrag_rv kosten_werkbestand.kst_effect_bedrag_rv%type;    
  
  -- variabelen voor het vastleggen in het costs-bestand
  v_fix_amount              fiat_order_costs_det.focd_fixed_amt%type;
  v_variable_amount         fiat_order_costs_det.focd_variable_amt%type;
  v_discount_amount         fiat_order_costs_det.focd_discount_amt%type;
  v_discount_amount_tv      fiat_order_costs_det.focd_discount_amt%type;
  v_discount_amount_bv      fiat_order_costs_det.focd_discount_amt%type;
  v_discount_amount_rv      fiat_order_costs_det.focd_discount_amt%type;
  v_total_amount            fiat_order_costs_det.focd_total_amt%type;
  v_discount_perc           fiat_order_costs_det.focd_discount_perc%type;
  v_discount_methode        discount_tariffs.method%type;   
  v_discount_fixed_amount   discount_tariffs.fixed_amount%type;
  v_discount_base_amount    fiat_order_costs_det.focd_basevalue_amt%type;
  v_basevalue_amount        fiat_order_costs_det.focd_basevalue_amt%type;
  v_calculation_type        fiat_order_costs_det.focd_calculation_type%type;
  v_classification          fiat_order_costs_det.focd_classification%type;
  v_origin_type             fiat_order_costs_det.focd_origin_type%type;
  v_rule_max_amount         fiat_order_costs_det.focd_rule_max_amt%type;
  v_rule_min_amount         fiat_order_costs_det.focd_rule_min_amt%type;
  v_rule_fixed_amount       fiat_order_costs_det.focd_rule_fixed_amt%type;
  v_rule_var_amt_perc       fiat_order_costs_det.focd_rule_var_amt_perc%type;
  v_rule_var_amt_amount     fiat_order_costs_det.focd_rule_var_amt_amount%type;
  v_rule_currency           fiat_order_costs_det.focd_rule_currency%type;
  v_rule_method             fiat_order_costs_det.focd_method%type;

  cursor wk is
  select w.wk_categorie_2, w.wk_categorie_3, w.wk_categorie_4,    w.wk_waarde_1,
         w.wk_waarde_2,    w.wk_waarde_3,    w.wk_waarde_4,       w.wk_export
  from   werkbestand w
  where  w.wk_terminal    = gv_terminalnummer
  and    w.wk_soort       = 'CALI'
  and    w.wk_categorie_1 = i_amount_type
  and    (i_instapfee_bereken = 0                                                               -- Alles doorlopen
          or
          i_instapfee_bereken = 1 and to_number(substr(w.wk_categorie_2,1,5)) = gv_instapfee_rule_id  -- Alleen rule id instap fee doorlopen
          or
          i_instapfee_bereken = 2 and to_number(substr(w.wk_categorie_2,1,5)) <> gv_instapfee_rule_id -- Alles behalve rule id instap fee doorlopen
         );

begin
  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In de procedure calc_lines_verwerken; berekening met de volgende parameters :');
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'amount type      : '||i_amount_type||' ; basis bedrag rv : '||to_char(i_basis_bedrag_rv));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'basis bedrag bv  : '||to_char(i_basis_bedrag_bv)||' ; basis bedrag tv : '||to_char(i_basis_bedrag_tv));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'klant prijs      : '||to_char(i_klant_prijs)||' ; beurs prijs      : '||to_char(i_beurs_prijs));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fondskoers comb  : '||to_char(i_fondskoers_comb_ord)||' ; order aantal : '||to_char(i_order_aantal));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'trans indicatie  : '||i_transactie_indicatie||' ;  koop verk indicatie : '||to_char(i_trans_k_v_ind));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'prijs fact fonds : '||to_char(i_prijs_factor_fonds)||' ; ex ass factor : '||to_char(i_ex_ass_factor_fonds));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'geen prov berek  : '||to_char(i_geen_prov_berekenen)||' ; prov perc eff wrd : '||to_char(i_ord_prov_perc_eff_wrd));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'prov kort perc   : '||to_char(i_ord_prov_kort_perc)||' ; instapfee berekenen : '||to_char(i_instapfee_bereken));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
  end if;

  -- eerst de basisbedragen uit de parameters overnemen in de werk variabelen
  v_basis_bedrag_rv         := i_basis_bedrag_rv;
  v_basis_bedrag_bv         := i_basis_bedrag_bv;
  v_basis_bedrag_tv         := i_basis_bedrag_tv;

  o_correctie_bedrag_bv     := 0;
  o_correctie_bedrag_rv     := 0;
  o_correctie_bedrag_tv     := 0;
  o_berekend_bedrag_bv      := 0;
  o_berekend_bedrag_rv      := 0;
  o_berekend_bedrag_tv      := 0;

  for r_wk in wk
  loop
     -- gegevens uit de opgeslagen calc lines omzetten zodat deze gemakkelijk te gebruiken zijn:
     v_rule_id              := to_number(substr(r_wk.wk_categorie_2,1,5));
     v_tarif_id             := to_number(substr(r_wk.wk_categorie_3,1,5));
     v_table                := trim(substr(r_wk.wk_categorie_3,6,22));
     v_fixed_amount         := r_wk.wk_waarde_1;
     v_minimum_amount       := r_wk.wk_waarde_3;
     v_maximum_amount       := r_wk.wk_waarde_2;
     v_percentage           := r_wk.wk_waarde_4 / 10000; -- Hier weer corrigeren voor het opslaan in maar vier decimalen....
     v_has_min_amount       := to_number(substr(trim(r_wk.wk_categorie_4),3,1));
     v_has_max_amount       := to_number(substr(trim(r_wk.wk_categorie_4),1,1));
     v_discount_tarif_id    := to_number(substr(trim(r_wk.wk_categorie_4),5,15));
     v_fonds_id_uit_wk      := to_number(substr(r_wk.wk_categorie_2,11,17));
     v_tr_ind_uit_wk        := trim(substr(r_wk.wk_categorie_2,6,5));
     v_wht_exemption        := r_wk.wk_export;
     
     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user,'Fondsid uit werkbestand : '||to_char(v_fonds_id_uit_wk)||' ; fondsid uit order : '||to_char(gv_fonds_id));
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user,'Tr.ind. uit werkbestand : '||v_tr_ind_uit_wk||' ; tr.ind. uit parameter : '||i_transactie_indicatie);
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user,' ');
     end if;
     
     -- doorgaan als het fonds en de transactiesoort overeenkomen:
     if v_fonds_id_uit_wk = gv_fonds_id and v_tr_ind_uit_wk = i_transactie_indicatie
     then
        
        v_fix_amount            := 0;
        v_variable_amount       := 0;
        v_total_amount          := 0;
        v_discount_amount       := 0;
        v_discount_perc         := 0;
        v_discount_methode      := ' ';
        v_discount_fixed_amount := 0;
        v_discount_base_amount  := 0;
        v_basevalue_amount      := 0;
        v_calculation_type      := ' ';
        v_classification        := ' ';
        v_origin_type           := ' ';
        v_rule_max_amount       := 0;
        v_rule_min_amount       := 0;
        v_rule_fixed_amount     := 0;
        v_rule_var_amt_perc     := 0;
        v_rule_var_amt_amount   := 0;
        v_rule_currency         := ' ';
        v_rule_method           := ' ';
        v_kosten_bestaan_al     := 0;
        v_ca_gebr_afw_b_amount  := 0;
        
        v_berekend_bedrag_rv    := 0;
        v_berekend_bedrag_bv    := 0;
        v_berekend_bedrag_tv    := 0;
        v_berekend_bedrag_wht   := 0;
        
        -- bekijken of de kosten al zijn aangeleverd, geldt niet voor context CA en calc rule type TAX
        if not (i_context = 'CA' and v_calc_rule_type = 'TAX')
        then 
           begin
              select f.focd_variable_amt, f.focd_total_amt, 1
              into   v_variable_amount,   v_total_amount,   v_kosten_bestaan_al
              from   fiat_order_costs_det f
              where  f.focd_order_number  = i_ordernummer
              and    f.focd_order_line    = i_orderregel
              and    f.focd_order_det_num = i_orderdetail
              and    f.focd_cfcu_id       = v_rule_id;
           exception
              when no_data_found
              then
                 v_kosten_bestaan_al := 0;
           end;
        else
           v_kosten_bestaan_al := 0;
        end if;
        
        select c.cfcu_type,      c.cfcu_method,      c.cfcu_pay_off_type,      c.cfcu_book_type
        into   v_calc_rule_type, v_calc_rule_method, v_calc_rule_pay_off_type, v_calc_rule_book_type
        from   calculationrules c
        where  c.cfcu_id = v_rule_id;
        
        -- als er een discount tarif aanwezig is, dan de tarif gegevens ophalen
        if v_discount_tarif_id <> 0
        then
           begin
              select d.method,           d.fixed_amount,          d.percentage
              into   v_discount_methode, v_discount_fixed_amount, v_discount_perc
              from   discount_tariffs d
              where  d.id     = v_discount_tarif_id;
           exception
              when no_data_found
              then
                 v_discount_methode      := ' ';
                 v_discount_fixed_amount := 0;
                 v_discount_perc         := 0;
           end;
           if v_discount_fixed_amount <> 0 and v_discount_fixed_amount is not null and v_calc_rule_pay_off_type = 'TRANS'
           then
              omrekenen_bv_tv(v_discount_fixed_amount, v_discount_fixed_amount);
           end if;
        end if;
        
        -- voor context ca ook nog kijken of de TAX-calc rule een eigen grondslag (en dus een eigen eff.bedrag heeft)
        if i_context = 'CA' and v_calc_rule_type = 'TAX'
        then
           begin
              select 1,                      t.tba_base_amount_from, t.tba_base_amount_to
              into   v_ca_gebr_afw_b_amount, v_ca_base_amount_from,  v_ca_base_amount_to
              from   tax_base_amount t
              where  t.tba_capc_id    = gv_capc_id
              and    t.tba_be_id      = gv_fonds_id
              and    t.tba_cfcu_id    = v_rule_id;
           exception
              when no_data_found
              then
                 v_ca_gebr_afw_b_amount := 0;
                 v_ca_base_amount       := 0;
           end;
           -- als er een record is gevonden en het bijbehorend grondslagbedrag is ongelijk 0, dan een nieuw effectief bedrag berekenen voor deze calc rule
           if v_ca_gebr_afw_b_amount = 1 
              and 
              (i_richting_omwisseling = 1 and v_ca_base_amount_from <> 0
               or
               i_richting_omwisseling = 2 and v_ca_base_amount_to <> 0)
           then  
              v_ca_base_amount := case when i_richting_omwisseling = 1 then v_ca_base_amount_from else v_ca_base_amount_to end;
              
              v_ca_hold_basis_bedrag_tv := v_basis_bedrag_tv;
              v_ca_hold_basis_bedrag_rv := v_basis_bedrag_rv;
              v_basis_bedrag_tv         := i_order_aantal * i_prijs_factor_fonds * v_ca_base_amount; -- het nieuwe effectief bedrag is in tv
              omrekenen_tv_rv (v_basis_bedrag_tv, v_basis_bedrag_rv);
           else
              -- Als geen afwijkende grondslag is, dan de doorgegeven prijs gebruiken (de verrekenprijs)
              v_ca_base_amount          := i_klant_prijs;
              v_ca_hold_basis_bedrag_tv := v_basis_bedrag_tv;
              v_ca_hold_basis_bedrag_rv := v_basis_bedrag_rv;
              v_basis_bedrag_tv         := i_order_aantal * i_prijs_factor_fonds * v_ca_base_amount; -- het nieuwe effectief bedrag is in tv
              omrekenen_tv_rv (v_basis_bedrag_tv, v_basis_bedrag_rv);
              
              v_ca_gebr_afw_b_amount := 1; -- weer aanzetten om met de net bepaalde gegevens te gaan rekenen en door te geven...
           end if;
           
           -- Ook nog bekijken of voor specifieke RV-soorten WHT is berekend. Dan het basis bedrag daarop aanpassen.
           if v_rule_id in (78,95,112)
           then 
              -- bepalen of er al WHT is berekend:
              v_berekend_WHT_voor_ca := 0;
              
              select sum(w.wk_waarde_1)
              into   v_berekend_WHT_voor_ca
              from   werkbestand w
              where  w.wk_terminal                      = gv_terminalnummer
              and    w.wk_soort                         = 'CALW';
                      
              v_basis_bedrag_tv := v_basis_bedrag_tv - nvl(v_berekend_WHT_voor_ca,0);
              omrekenen_tv_rv   (v_basis_bedrag_tv, v_basis_bedrag_rv);
           end if;
        end if;
        
        if gv_debuggen = 1
        then
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'rule id           : '||to_char(v_rule_id)||' ; tarif id    : '||to_char(v_tarif_id));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fixed amount      : '||to_char(v_fixed_amount)||' ; percentage : '||to_char(v_percentage));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'minimum amount    : '||to_char(v_minimum_amount)||' ; has minimum amount : '||to_char(v_has_min_amount));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'maximum amount    : '||to_char(v_maximum_amount)||' ; has maximum amount : '||to_char(v_has_max_amount));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'discount tarif id : '||to_char(v_discount_tarif_id)||' ; wht exemption : '||to_char(v_wht_exemption));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'calc rule type    : '||v_calc_rule_type||' ; calc rule method : '||v_calc_rule_method);
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'cr pay off type   : '||v_calc_rule_pay_off_type||' ; calc rule book type : '||v_calc_rule_book_type);
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'kosten bestaan al : '||to_char(v_kosten_bestaan_al)||' ; total amount : '||to_char(v_total_amount));
           if i_context = 'CA' and v_calc_rule_type = 'TAX'
           then
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'capc id        : '||to_char(gv_capc_id)||' ; fonds id : '||to_char(gv_fonds_id));
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'richting omwis : '||to_char(i_richting_omwisseling)||' ; ca gebr afwijkend base amount : '||to_char(v_ca_gebr_afw_b_amount));
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'bepaald base am: '||to_char(v_ca_base_amount)||' ; nieuw basis bedrag tv : '||to_char(v_basis_bedrag_tv));
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'oud basis bedrag tv : '||to_char(v_ca_hold_basis_bedrag_tv)||' ; berekend WHT : '||to_char(v_berekend_WHT_voor_ca));
           end if;
           if v_discount_tarif_id <> 0
           then
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'discount tarif id : '||to_char(v_discount_tarif_id)||' ; discount methode : '||v_discount_methode);
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'discount percent  : '||to_char(v_discount_perc)||' ; discount fixed amount : '||to_char(v_discount_fixed_amount));
           end if;
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
        end if;
        
        if v_kosten_bestaan_al = 0 -- de kosten zijn niet aangeleverd  
        then
           v_reken_bedrag := 0;
           case when v_calc_rule_pay_off_type = 'TRANS' then v_reken_basis_bedrag := v_basis_bedrag_tv;
                when v_calc_rule_pay_off_type = 'SYST'  then v_reken_basis_bedrag := v_basis_bedrag_bv;
                else                                         v_reken_basis_bedrag := v_basis_bedrag_rv;
           end case;
           
           -- tbv afhandeling method HYBRID vastleggen welke mthode is gebruikt.
           v_rule_method := v_calc_rule_method;
           -- Hier onder de verschillende methoden afhandelen:
           -- Methode is percentage of Hybrid en het percentage is <> 0
           if trim(v_calc_rule_method) = 'PERCENT' or trim(v_calc_rule_method) = 'HYBRID' and v_percentage <> 0
           then
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In calc rule methode PERCENT');
              end if;
              v_rule_method := 'PERCENT';
              v_reken_bedrag := v_reken_basis_bedrag*v_percentage/100;
              v_fixed_amount := null;  -- Als er een percentage is, dan het vaste bedrag gaan onderdrukken.
              v_rule_var_amt_perc := v_percentage;
              -- Controleren naar maximum en minimum als dat van toepassing is
              if v_has_max_amount = 1 or v_has_min_amount = 1
              then
                 if v_has_max_amount = 1 and v_reken_bedrag > v_maximum_amount and v_maximum_amount <> 0
                 then
                    v_reken_bedrag := v_maximum_amount;
                 end if;
                 if v_has_min_amount = 1 and v_reken_bedrag < v_minimum_amount and v_minimum_amount <> 0
                 then
                    v_reken_bedrag := v_minimum_amount;
                 end if;
              end if;
              -- teken goed zetten voor koopachtigen bij amount type 'INTRST'
              if i_trans_k_v_ind = 1 and i_amount_type = 'INTRST'
              then
                 v_reken_bedrag := v_reken_bedrag * -(1);
              end if;
              
           elsif trim(v_calc_rule_method) = 'PERC_GROSS'
           then
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In calc rule methode PERC_GROSS');
              end if;
              v_reken_bedrag := (v_reken_basis_bedrag/(100-v_percentage)) * v_percentage;
                            
           elsif trim(v_calc_rule_method) = 'FIXED'
           then
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In calc rule methode FIXED');
              end if;
              
              v_reken_bedrag := v_fixed_amount;
              
            -- Methode is STQ of Hybrid en het percentage is 0
           elsif trim(v_calc_rule_method) = 'STQ' or trim(v_calc_rule_method) = 'HYBRID' and v_percentage = 0
           then
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In calc rule methode STQ/HYBRID');
              end if;
              
              v_rule_method := 'STQ';
              v_rule_var_amt_amount := v_fixed_amount;
              v_reken_bedrag := i_order_aantal * v_fixed_amount * i_prijs_factor_fonds;
              v_fixed_amount := null;    -- We hebben het inmiddels opgeslagen in v_rule_var_amount
              v_percentage   := null;    -- Als er een vastbedrag is, dan het percentage gaan onderdrukken.
              if substr(i_transactie_indicatie,1,2)='EX' or substr(i_transactie_indicatie,1,2)='AS'
              then
                 v_reken_bedrag := v_reken_bedrag * i_ex_ass_factor_fonds;
              end if;
              
            -- Reynders tax is voor nu overgeslagen omdat daar een extra berekening bij hoort waarvoor nu geen tijd is gerekend
           elsif substr(trim(v_calc_rule_method),1,2) = 'RT'
           then
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In calc rule methode RT');
              end if;
              
              FIAT_NOTABEDR_KOSTEN.reynderstax_berekenen (i_ordernummer,                         i_orderregel,            i_orderdetail, 
                                                          gv_fonds_id,                           gv_fondssymbool,         gv_fonds_optietype, 
                                                          gv_fonds_expiratiedatum,               gv_fonds_exerciseprijs,  gv_ppr_id,
                                                          i_order_aantal * i_prijs_factor_fonds, i_klant_prijs,           v_percentage,
                                                          case when trim(v_calc_rule_method) = 'RT' then 1 else 0 end,    gv_trans_munt_notatie,  
                                                          gv_debuggen,                           gv_debug_user,           v_reken_bedrag);
              
              -- Anticipated sale bedrag wordt vanuit order create doorgegeven en wordt hier niet herberekend, maar overgenomen
              -- uit de aan de order (details) toegevoegde kosten regels. Daarom  hier geen code
              -- elsif trim(v_calc_rule_method) = 'AS'
              
              -- Real brokerage cost is voor de tegenpartij en wordt hier dus niet meegenomen voor de relatie
              -- elsif trim(v_calc_rule_method) = 'CB'
              
           elsif trim(v_calc_rule_method) = 'CC'
           then
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In calc rule methode CC');
              end if;
              
              gehele_provisie_berekenen (i_ordernummer,         i_orderregel,            i_orderdetail,         i_transactie_indicatie,  i_order_aantal,
                                         i_geen_prov_berekenen, i_ord_prov_perc_eff_wrd, i_ord_prov_kort_perc,  i_basis_bedrag_bv,       i_basis_bedrag_tv,
                                         i_klant_prijs,         i_beurs_prijs,           i_fondskoers_comb_ord, i_prijs_factor_fonds,    v_dummy_num);
                                      
              -- de provisie en kosten correspondent zijn opgeslagen in het kosten_werkbestand. Hier overnemen in het reken bedrag:
              select k.kst_provisie_bedrag,  k.kst_kost_corr_doorb,  k.kst_prov_code_tabel,   k.kst_vaste_kosten,
                     k.kst_variabele_kosten, k.kst_provisie_korting, k.kst_prov_korting_perc, k.kst_provisie_type,
                     k.kst_ord_provperceffw
              into   v_reken_bedrag,         v_kost_corresp_doorb,   v_provisie_tabel,        v_prov_vaste_kosten,
                     v_prov_vari_kosten,     v_prov_korting,         v_prov_korting_perc,     v_provisie_type,
                     v_ord_provperceffw
              from   kosten_werkbestand k
              where  k.kst_ordernummer  = i_ordernummer
              and    k.kst_orderregel   = i_orderregel
              and    k.kst_detailnummer = i_orderdetail;
              
              -- voor het berekenen kosten correspondent nu even bij de provisie (reken bedrag) optellen
              v_reken_bedrag := v_reken_bedrag + v_kost_corresp_doorb;
              -- provisie uit deze procedure is genoteerd in de systeem valuta. Mocht nu de instelling voor calc rule pay off type niet op SYST staan,
              -- dan deze hier even omzetten zodat de omrekeningen correct gaan
              v_calc_rule_pay_off_type := 'SYST';
              -- als er een percentage is opgegeven door een adviseur, dan hier de rule om zetten
              if v_ord_provperceffw <> 0 and v_ord_provperceffw is not null
              then
                 v_calc_rule_method := 'PERCENT';
                 v_percentage       := v_ord_provperceffw;
                 v_provisie_tabel   := ' ';
              end if;
              
           -- Byst, bewaarloon, Rekening courant rente en service fee zijn geen onderdeel van de ordering. Hier overslaan.
           -- elsif substr(trim(v_calc_rule_method),1,2) = 'CQ'
           
           -- Btw over kosten via transactiesoort O-G en O-G1 zijn geen onderdeel van de ordering. Hier overslaan.
           -- elsif substr(trim(v_calc_rule_method),1,2) = 'CT'
           
           elsif trim(v_calc_rule_method) = 'FXC'
           then
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In calc rule methode FXC');
              end if;
              if i_basis_bedrag_tv <> 0
              then
                 valuta_kosten_berekenen (i_basis_bedrag_tv,    i_trans_market_koers, i_order_geldrek_mnts, i_trans_k_v_ind,
                                          v_berekend_bedrag_rv, v_berekend_bedrag_tv, v_berekend_bedrag_bv, v_rule_var_amt_perc);
                 -- om de logging van de berekende bedragen af te dwingen hier ook reken bedrag vullen
                 v_reken_bedrag := v_berekend_bedrag_rv;
              else
                 v_reken_bedrag := 0;
              end if;
           
           -- WHT kan ingericht en gebruikt worden in de productconversies.
           elsif trim(v_calc_rule_method) = 'WHT'
           then
              -- het percentage dat aan de calculation rule hangt is voor WHT niet correct. Er moet een percentage worden bepaald.
              wht_percentage_bepalen (gv_fonds_id, gv_relatienummer, v_percentage);
              
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug (gv_debug_user,'In calc rule methode WHT');
                 FIAT_ALGEMEEN.fiat_debug (gv_debug_user,'Bepaald percentage : '||to_char(v_percentage));
              end if;

              v_rule_method := 'PERCENT';
              v_reken_bedrag := v_reken_basis_bedrag*v_percentage/100;
              v_fixed_amount := null;  -- Als er een percentage is, dan het vaste bedrag gaan onderdrukken.
              v_rule_var_amt_perc := v_percentage;
                      
           -- Registertaken zijn geen onderdeel van de bestedingsruimte bepaling. Hier overslaan.
           -- elsif trim(v_calc_rule_method) = 'REG'
           end if;
           
           -- Discount bedrag berekenen als er een tarif is
           if v_discount_tarif_id<>0  
           then
              v_discount_base_amount := v_reken_bedrag;
              if v_discount_methode = 'FIXED'
              then
                 v_discount_amount := -1 * v_discount_fixed_amount;
              elsif v_discount_methode = 'PERCENT'
              then
                 v_discount_amount := -1 * (v_discount_base_amount * v_discount_perc/100);
                 case when v_calc_rule_pay_off_type = 'TRANS' then v_discount_amount := round(v_discount_amount,gv_trans_munt_notatie);
                      when v_calc_rule_pay_off_type = 'SYST'  then v_discount_amount := round(v_discount_amount,gv_basis_val_notatie);
                      else                                         v_discount_amount := round(v_discount_amount,gv_rel_rapp_notatie);
                 end case;
              else
                 v_discount_amount := 0;
              end if;
              if v_discount_amount <> 0
              then
                 if v_calc_rule_pay_off_type = 'TRANS'
                 then
                    v_discount_amount_tv := v_discount_amount;
                    omrekenen_tv_bv (v_discount_amount_tv, v_discount_amount_bv);
                    omrekenen_tv_rv (v_discount_amount_tv, v_discount_amount_rv);
                 elsif v_calc_rule_pay_off_type = 'SYST'
                 then
                    v_discount_amount_bv := v_discount_amount;
                    omrekenen_bv_rv (v_discount_amount_bv, v_discount_amount_rv);
                    omrekenen_bv_tv (v_discount_amount_bv, v_discount_amount_tv);
                 end if;
              else
                 v_discount_amount_bv := 0;
                 v_discount_amount_rv := 0;
                 v_discount_amount_tv := 0;
              end if;
           else
              v_discount_amount_bv := 0;
              v_discount_amount_rv := 0;
              v_discount_amount_tv := 0; 
           end if;
        
        -- einde kosten bestaan al = 0 (dus bestaan niet)
        else -- --> kosten bestaan al = 1 (dus bestaan, dan overnemen)
           v_reken_bedrag := v_total_amount;
        end if; -- einde kosten bestaan al
        
        -- verder gaan als er wat berekend is
        if v_reken_bedrag <> 0 or v_calc_rule_type = 'INDIRECT'
        then
           -- Uit de FXC stap komen al de correct berekende bedragen terug, die dus niet meer omrekenen
           if trim(v_calc_rule_method) <> 'FXC'
           then
              -- omrekening van het berekende bedrag zodat deze correct opgeteld kan worden
              case when v_calc_rule_pay_off_type = 'TRANS' then v_berekend_bedrag_tv := round(v_reken_bedrag,gv_trans_munt_notatie);
                   when v_calc_rule_pay_off_type = 'SYST'  then v_berekend_bedrag_bv := round(v_reken_bedrag,gv_basis_val_notatie);
                   else                                         v_berekend_bedrag_rv := round(v_reken_bedrag,gv_rel_rapp_notatie);
              end case;
              
              if v_calc_rule_pay_off_type = 'TRANS'
              then
                 omrekenen_tv_bv (v_berekend_bedrag_tv, v_berekend_bedrag_bv);
                 omrekenen_tv_rv (v_berekend_bedrag_tv, v_berekend_bedrag_rv);
              elsif v_calc_rule_pay_off_type = 'SYST'
              then
                 omrekenen_bv_rv (v_berekend_bedrag_bv, v_berekend_bedrag_rv);
                 omrekenen_bv_tv (v_berekend_bedrag_bv, v_berekend_bedrag_tv);
              end if;
           end if;
           
           if gv_debuggen = 1
           then
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'berekende bedragen : ');
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'bedrag in rv : '||to_char(v_berekend_bedrag_rv)||' ; berekend in bv : '||to_char(v_berekend_bedrag_bv));
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'bedrag in tv : '||to_char(v_berekend_bedrag_tv));
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
           end if;
           
           -- het berekende basis bedrag voor de wht vasthouden (zonder discount) om het later weer te kunnen gebruiken
           if v_rule_id in (77,106,107,108,109,110)
           then
              v_berekend_bedrag_wht := v_berekend_bedrag_tv;
           end if;
           
           -- Als er een discount is berekend, dan hier corrigeren voor die discount:
           if v_discount_amount <> 0
           then
              -- voor nu het berekende bedrag eerst vast leggen in het variable amount zodat dit in ieder geval nog ergens vast ligt...
              v_variable_amount := v_berekend_bedrag_rv;

              -- Dan het discount bedrag verrekenen.             
              v_berekend_bedrag_rv := v_berekend_bedrag_rv + v_discount_amount_rv;
              v_berekend_bedrag_tv := v_berekend_bedrag_tv + v_discount_amount_tv;
              v_berekend_bedrag_bv := v_berekend_bedrag_bv + v_discount_amount_bv;
              
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'berekendende bedragen incl discount : ');
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'discount amt rv : '||to_char(v_discount_amount_rv)||' ; v_berekend in rv : '||to_char(v_berekend_bedrag_rv));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'discount amt tv : '||to_char(v_discount_amount_tv)||' ; v_berekend in tv : '||to_char(v_berekend_bedrag_tv));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'discount amt bv : '||to_char(v_discount_amount_bv)||' ; v_berekend in bv : '||to_char(v_berekend_bedrag_bv));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
           end if;
           end if;
           
           -- vastleggen van de berekende gegevens
           if (v_calc_rule_pay_off_type = 'TRANS' and (v_berekend_bedrag_tv <> 0 or v_discount_amount_tv <> 0)
               or
               v_calc_rule_pay_off_type = 'SYST'  and (v_berekend_bedrag_bv <> 0 or v_discount_amount_bv <> 0)
               or
               v_calc_rule_type = 'INDIRECT'      and v_rule_id <> 101
               or
               v_rule_id = 101                    and v_berekend_bedrag_rv <> 0  -- alleen valutakosten vastleggen als die <> 0 zijn....
              )
              and
              v_kosten_bestaan_al = 0 -- alleen als de kosten niet zijn aangeleverd
           then
              v_total_amount      := v_berekend_bedrag_rv;
              v_basevalue_amount  := case when trim(v_calc_rule_method) = 'PERC_GROSS' then v_basis_bedrag_rv + v_berekend_bedrag_rv else v_basis_bedrag_rv end;
              v_calculation_type  := v_calc_rule_type;
              
              -- bepalen van basisgegevens voor de kosten detaillering:
              if v_table = 'COMMISSION' and v_provisie_tabel <> ' ' and v_provisie_tabel is not null
              then
                 select p.pr_vaste_kosten,   p.pr_min_provisie, p.pr_max_provisie
                 into   v_rule_fixed_amount, v_rule_min_amount, v_rule_max_amount
                 from   provtabheader p
                 where  p.pr_code = v_provisie_tabel;
                 
                 begin
                    select nvl(s.st_schaal_perc,0)
                    into   v_prov_schaal_optie
                    from   schalen_tabel s
                    where  s.st_soort = 'PROV'
                    and    s.st_pr_code = v_provisie_tabel
                    and    rownum       <= 1
                    order by s.st_schaal_bedrag;
                 exception
                    when no_data_found
                    then
                       v_prov_schaal_optie := 0;
                 end;
                 
                 if v_provisie_type = 1  -- opties --> dan het schaal bedrag (wordt opgeslagen in percentage)
                 then
                    v_rule_var_amt_amount := v_prov_schaal_optie;
                    v_rule_var_amt_perc   := null;
                 elsif v_provisie_type = 2 -- niet opties --> dan percentage berekenen
                 then
                    v_rule_var_amt_amount := null;
                    v_rule_var_amt_perc   := round(v_prov_vari_kosten/i_basis_bedrag_bv * 100,3);
                 else
                    v_rule_var_amt_amount := null;
                    v_rule_var_amt_perc   := null;
                 end if;
                 
                 -- bedragen van de bestedingsruimte berekening voor provisie zijn in BV, nog omzetten naar rv om te tonen
                 omrekenen_bv_rv (v_prov_vaste_kosten, v_fix_amount);
                 omrekenen_bv_rv (v_prov_vari_kosten, v_variable_amount);
                 omrekenen_bv_rv (v_prov_korting, v_discount_amount);
                 
              elsif v_table = 'COMMISSION' and v_calc_rule_method = 'PERCENT'
              then
                 v_rule_var_amt_perc   := v_percentage;
                 v_rule_var_amt_amount := 0;
              else
                 v_discount_amount := v_discount_amount_rv;
              end if;
              
              if v_table = 'TARIFFS'
              then
                 select t.tt_fixed_amount,   t.tt_minimum_amount, t.tt_maximum_amount
                 into   v_rule_fixed_amount, v_rule_min_amount,   v_rule_max_amount
                 from   tax_tarif t
                 where  t.tt_id      = v_tarif_id
                 and    t.tt_cfcu_id = v_rule_id;
                 
                 select s.ts_percentage
                 into   v_rule_var_amt_perc
                 from   tax_tarif_scales s
                 where  s.ts_id      = v_tarif_id
                 and    rownum       <= 1
                 order by s.ts_id, s.ts_limit_amount;
              end if;
              
              begin
                 select c.crc_mifid_type, c.crc_origin_type
                 into   v_classification, v_origin_type
                 from   calculationrules_codings c
                 where  c.crc_cfcu_id = v_rule_id;
              exception
                 when no_data_found
                 then
                    v_classification := 'N/A';
                    v_origin_type    := 'N/A';
              end;
              
              omrekenen_bv_rv(v_rule_fixed_amount, v_rule_fixed_amount);
              omrekenen_bv_rv(v_rule_min_amount, v_rule_min_amount);
              omrekenen_bv_rv(v_rule_max_amount, v_rule_max_amount);
              omrekenen_bv_rv(v_rule_var_amt_amount,v_rule_var_amt_amount);
              
              -- Bij type 67 [MarketSpread] het variabele bedrag vullen met het berekende bedrag.
              if v_rule_id = 67
              then
                 v_variable_amount := v_total_amount;
              end if;
              -- Als de context = CA, dan kunnen dezelfde calcrule meerdere keren voorkomen, dan merge uitvoeren, anders gewoon een insert uitvoeren
              if i_context = 'CA'
              then
                 merge into fiat_order_costs_det f
                 using (select i_ordernummer       order_number,   i_orderregel        order_line,        i_orderdetail         order_det_num,
                               v_rule_id           cfcu_id,        v_fix_amount        fixed_amt,         v_variable_amount     variable_amt,
                               v_total_amount      total_amt,      v_discount_amount   discount_amt,      v_discount_perc       discount_perc,
                               v_basevalue_amount  basevalue_amt,  v_calculation_type  calculation_type,  v_classification      classification,
                               v_origin_type       origin_type,    v_rule_max_amount   rule_max_amt,      v_rule_min_amount     rule_min_amt,
                               v_rule_fixed_amount rule_fixed_amt, v_rule_var_amt_perc rule_var_amt_perc, v_rule_var_amt_amount rule_var_amt_amount,
                               gv_rel_rapp_valuta  rule_currency,  v_tarif_id          tarif_id,          v_rule_method         rule_method
                        from dual) u
                    on (f.focd_order_number  = u.order_number  and
                        f.focd_order_line    = u.order_line    and
                        f.focd_order_det_num = u.order_det_num and
                        f.focd_cfcu_id       = u.cfcu_id       and
                        f.focd_tarif_id      = u.tarif_id)
                 when matched then
                    update set f.focd_fixed_amt     = f.focd_fixed_amt + u.fixed_amt,
                               f.focd_variable_amt  = f.focd_variable_amt + u.variable_amt,
                               f.focd_total_amt     = f.focd_total_amt + u.total_amt,
                               f.focd_discount_amt  = f.focd_discount_amt + u.discount_amt, 
                               f.focd_basevalue_amt = f.focd_basevalue_amt + u.basevalue_amt
                 when not matched then
                    insert (f.focd_order_number,   f.focd_order_line,        f.focd_order_det_num,
                            f.focd_cfcu_id,        f.focd_fixed_amt,         f.focd_variable_amt,
                            f.focd_total_amt,      f.focd_discount_amt,      f.focd_discount_perc,
                            f.focd_basevalue_amt,  f.focd_calculation_type,  f.focd_classification,
                            f.focd_origin_type,    f.focd_rule_max_amt,      f.focd_rule_min_amt,
                            f.focd_rule_fixed_amt, f.focd_rule_var_amt_perc, f.focd_rule_var_amt_amount,
                            f.focd_rule_currency,  f.focd_tarif_id,          f.focd_method)
                    values (u.order_number,        u.order_line,             u.order_det_num,
                            u.cfcu_id,             u.fixed_amt,              u.variable_amt,
                            u.total_amt,           u.discount_amt,           u.discount_perc,
                            u.basevalue_amt,       u.calculation_type,       u.classification,
                            u.origin_type,         u.rule_max_amt,           u.rule_min_amt,
                            u.rule_fixed_amt,      u.rule_var_amt_perc,      u.rule_var_amt_amount,
                            u.rule_currency,       u.tarif_id,               u.rule_method);
                 
                 -- De berekende WHT-gegevens nog per fonds/transactieindicatie opslaan om deze later te kunnen gebruiken
                 if v_rule_id in (77,106,107,108,109,110)
                 then
                    insert into werkbestand w
                    (w.wk_terminal,          w.wk_soort,                w.wk_categorie_1,
                     w.wk_categorie_2,       w.wk_categorie_3,          w.wk_waarde_1)
                    values                                                           
                    (gv_terminalnummer,      'CALW',                    to_char(gv_fonds_id,'999999999999999'),
                     i_transactie_indicatie, to_char(v_rule_id,'9999'), v_berekend_bedrag_wht);
                 end if;
              else          
                 insert into fiat_order_costs_det f
                 (f.focd_order_number,   f.focd_order_line,        f.focd_order_det_num,
                  f.focd_cfcu_id,        f.focd_fixed_amt,         f.focd_variable_amt,
                  f.focd_total_amt,      f.focd_discount_amt,      f.focd_discount_perc,
                  f.focd_basevalue_amt,  f.focd_calculation_type,  f.focd_classification,
                  f.focd_origin_type,    f.focd_rule_max_amt,      f.focd_rule_min_amt,
                  f.focd_rule_fixed_amt, f.focd_rule_var_amt_perc, f.focd_rule_var_amt_amount,
                  f.focd_rule_currency,  f.focd_tarif_id,          f.focd_method)
                 values
                 (i_ordernummer,         i_orderregel,             i_orderdetail,
                  v_rule_id,             v_fix_amount,             v_variable_amount,
                  v_total_amount,        v_discount_amount,        v_discount_perc,
                  v_basevalue_amount,    v_calculation_type,       v_classification,
                  v_origin_type,         v_rule_max_amount,        v_rule_min_amount,
                  v_rule_fixed_amount,   v_rule_var_amt_perc,      v_rule_var_amt_amount,
                  gv_rel_rapp_valuta,    v_tarif_id,               v_rule_method); 
              end if;
           end if;
           -- output parameters zetten, niet voor indirecte kosten en niet voor wht exemption
           if v_calc_rule_type <> 'INDIRECT' and v_wht_exemption <> 1
           then
              if i_amount_type = 'TAXBAS' and (v_calc_rule_book_type = 'ALL' or v_calc_rule_book_type = 'PTY')
              then
                 o_correctie_bedrag_bv := o_correctie_bedrag_bv + v_berekend_bedrag_bv;
                 o_correctie_bedrag_tv := o_correctie_bedrag_tv + v_berekend_bedrag_tv;
                 o_correctie_bedrag_rv := o_correctie_bedrag_rv + v_berekend_bedrag_rv;
              else
                 o_berekend_bedrag_bv  := o_berekend_bedrag_bv + v_berekend_bedrag_bv;
                 o_berekend_bedrag_tv  := o_berekend_bedrag_tv + v_berekend_bedrag_tv;
                 o_berekend_bedrag_rv  := o_berekend_bedrag_rv + v_berekend_bedrag_rv;
              end if;
           end if;
           
        end if;
         
        -- terug zetten van de rv en tv-basisbedragen op de waarde die het had voordat de afwijkende basisbedragen zijn berekend
        if v_ca_gebr_afw_b_amount = 1
        then
           v_basis_bedrag_rv := v_ca_hold_basis_bedrag_rv;
           v_basis_bedrag_tv := v_ca_hold_basis_bedrag_tv;
        end if;
        
     end if; -- Einde het fonds uit werkbestand is fonds uit gv en transactie indicatie is transactie indicatie uit parameter
  end loop;

end calc_lines_verwerken;
-- EINDE CODE VOOR CALC_LINES_VERWERKEN


-- DE CODE VOOR PROCEDURE CR_NOTABEDRAG_BEREKENEN
procedure cr_notabedrag_berekenen
(i_berekend_bedrag_in_rv       in  kosten_werkbestand.kst_effect_bedrag_rv%type
,i_transactie_indicatie        in  kosten_werkbestand.kst_trans_indicatie%type
,o_notabedrag_rv               out kosten_werkbestand.kst_notabedrag%type
)
is

v_afl_omwl_neg_bedrag          number(1) := 0;
v_afl_omws_pos_bedrag          number(1) := 0;
v_verk_met_pos_bedrag          number(1) := 0;

v_reken_bedrag_in_rv           kosten_werkbestand.kst_effect_bedrag_rv%type;

begin
   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'In procedure cr_notabedrag_berekenen ; binnen gekomen gegevens :');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'berekend bedrag in rv : '||to_char(i_berekend_bedrag_in_rv)||' ; trans indicatie : '||i_transactie_indicatie);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
   end if;

   if i_transactie_indicatie in ('AFL','OMWL') and i_berekend_bedrag_in_rv <= 0
   then
      v_afl_omwl_neg_bedrag  := 1;
   end if;

   if i_transactie_indicatie in ('AFL','OMWS') and i_berekend_bedrag_in_rv > 0
   then
      v_afl_omws_pos_bedrag  := 1;
   end if;

   if i_transactie_indicatie in ('V','VN','OV','SV') and i_berekend_bedrag_in_rv > 0
   then
      v_verk_met_pos_bedrag  := 1;
   end if;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'AFL of OMWL met negatief bedrag : '||to_char(v_afl_omwl_neg_bedrag)
                                               ||' ; AFL of OMWS met positief bedrag : '||to_char(v_afl_omws_pos_bedrag));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'Verkopen met positief bedrag : '||to_char(v_verk_met_pos_bedrag));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
   end if;

   -- voor de berekeningen eerst het bedrag dat binnen is gekomen overnemen in de reken variabele
   v_reken_bedrag_in_rv := i_berekend_bedrag_in_rv;

   if i_transactie_indicatie not in ('EX C','EX P','AS C','AS P','D','L')
   then
      v_reken_bedrag_in_rv := abs(v_reken_bedrag_in_rv);
   end if;

   if v_afl_omwl_neg_bedrag = 1 or i_transactie_indicatie in ('V','VN','OV','SV') or i_transactie_indicatie = 'OMWS' and v_afl_omws_pos_bedrag = 0
   then
      o_notabedrag_rv  := v_reken_bedrag_in_rv;
   end if;

   if v_afl_omws_pos_bedrag = 1 or v_verk_met_pos_bedrag = 1 or
      i_transactie_indicatie in ('K','KN','OK','SK','OK F','OV F','SK F','SV F','AS P','EX C','AS C','EX P','EMIS','D','L') or
      i_transactie_indicatie = 'OMWL' and v_afl_omwl_neg_bedrag = 0
   then
      o_notabedrag_rv  := v_reken_bedrag_in_rv * -(1);
   end if;

   -- als laatste het teken nogmaals omzetten
   o_notabedrag_rv := o_notabedrag_rv *-(1);

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'Einde procedure cr_notabedrag_berekenen ; berekende gegevens :');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'nota bedrag in rv : '||to_char(o_notabedrag_rv));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
   end if;

end cr_notabedrag_berekenen;
-- EINDE CODE VOOR CR_NOTABEDRAG_BEREKENEN


-- DE CODE VOOR PROCEDURE VALUTA_KOSTEN_BEREKENEN
procedure valuta_kosten_berekenen
(i_netto_bedrag            in  kosten_werkbestand.kst_effect_bedrag_bv%type
,i_trans_market_koers      in  fiat_muntsoorten.fimu_middenkoers%type
,i_order_geldrek_muntsoort in  kosten_werkbestand.kst_rel1_rek2_munts%type
,i_trans_k_v_ind           in  kosten_werkbestand.kst_trans_indicatie_w%type
,o_val_kosten_rv           out kosten_werkbestand.kst_effect_bedrag_rv%type
,o_val_kosten_tv           out kosten_werkbestand.kst_effect_bedrag_rv%type
,o_val_kosten_bv           out kosten_werkbestand.kst_effect_bedrag_bv%type
,o_val_spread              out fiat_muntsoorten.fimu_afslag_perc%type
)
is
  v_grek_munt_biedkoers    fiat_muntsoorten.fimu_biedkoers%type;
  v_grek_munt_middenkoers  fiat_muntsoorten.fimu_middenkoers%type;
  v_grek_munt_laatkoers    fiat_muntsoorten.fimu_laatkoers%type;
  v_grek_munt_reciproke    fiat_muntsoorten.fimu_reciproke%type;
  v_grek_munt_factor       fiat_muntsoorten.fimu_factor%type;
  v_grek_munt_notatie      fiat_muntsoorten.fimu_notatie%type;
  -- bepalen van de transactie muntsoort koersen zonder aanpassing aan klant instellingen
  v_trans_munt_biedkoers   fiat_muntsoorten.fimu_biedkoers%type;
  v_trans_munt_middenkoers fiat_muntsoorten.fimu_middenkoers%type;
  v_trans_munt_laatkoers   fiat_muntsoorten.fimu_laatkoers%type;

  -- te gebruiken muntsoort voor de berekeningen:
  v_grek_b_munt_koers      fiat_muntsoorten.fimu_middenkoers%type;
  v_grek_m_munt_koers      fiat_muntsoorten.fimu_middenkoers%type;
  v_trans_m_munt_koers     fiat_muntsoorten.fimu_middenkoers%type;

  v_opslag_perc            fiat_muntsoorten.fimu_opslag_perc%type;
  v_afslag_perc            fiat_muntsoorten.fimu_afslag_perc%type;

  v_bedrag_in_bankkoers    kosten_werkbestand.kst_effect_bedrag_bv%type    := 0;
  v_bedrag_in_marktkoers   kosten_werkbestand.kst_effect_bedrag_bv%type    := 0;
  v_valutakosten_in_rekval kosten_werkbestand.kst_effect_bedrag_bv%type    := 0;

begin
  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'In procedure valuta_kosten_berekenen');
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'Netto bedrag in     : '||to_char(i_netto_bedrag));
     FIAT_ALGEMEEn.fiat_debug( gv_debug_user, 'Order geldrek munts : '||i_order_geldrek_muntsoort||' ; trans k/v indicatie : '||to_char(i_trans_k_v_ind));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
  end if;

  -- Als de geldrekening muntsoort gelijk is aan de trans muntsoort, dan zijn er geen valuta kosten:
  if i_order_geldrek_muntsoort = gv_trans_munt
  then
     o_val_kosten_tv := 0;
     o_val_kosten_rv := 0;
     o_val_kosten_bv := 0;
     o_val_spread    := 0;

     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'geldrek muntsoort is gelijk aan transmuntsoort --> geen valutakosten berekening');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
     end if;
  else
     -- de "normale" koersgegevens van de transactiemuntsoort bepalen:
     if gv_trans_munt = gv_basis_valuta
     then
        v_trans_munt_biedkoers   := gv_basis_val_biedkoers;
        v_trans_munt_middenkoers := gv_basis_val_middenkoers;
        v_trans_munt_laatkoers   := gv_basis_val_laatkoers;
     else
        select m.mu_biedkoers,         m.mu_middenkoers,         m.mu_laatkoers
        into   v_trans_munt_biedkoers, v_trans_munt_middenkoers, v_trans_munt_laatkoers
        from   muntsoorten m
        where  m.mu_code = gv_trans_munt;
     end if;

     -- aansluitend bepalen welke van de transactiemuntsoort koers er daadwerkelijk gebruikt moet worden:
     FIAT_ALGEMEEN.muntkoers_bepalen (i_trans_k_v_ind,          0,                      gv_trans_munt_reciproke, v_trans_munt_biedkoers,
                                      v_trans_munt_middenkoers, v_trans_munt_laatkoers, v_trans_m_munt_koers);

     -- de koers gegevens van de rekeningmuntsoort zijn nog niet bekend
     -- de "normale" koersgegevens van de rekeningmuntsoort bepalen:
     if i_order_geldrek_muntsoort = gv_basis_valuta
     then
        v_grek_munt_biedkoers   := gv_basis_val_biedkoers;
        v_grek_munt_middenkoers := gv_basis_val_middenkoers;
        v_grek_munt_laatkoers   := gv_basis_val_laatkoers;
     else
        select m.mu_biedkoers,        m.mu_middenkoers,        m.mu_laatkoers,        m.mu_reciproke
        into   v_grek_munt_biedkoers, v_grek_munt_middenkoers, v_grek_munt_laatkoers, v_grek_munt_reciproke
        from   muntsoorten m
        where  m.mu_code = i_order_geldrek_muntsoort;
     end if;

     -- aansluitend bepalen welke van de koers er daadwerkelijk gebruikt moet worden aan de hand van de transactie
     FIAT_ALGEMEEN.muntkoers_bepalen (i_trans_k_v_ind,         1,                     v_grek_munt_reciproke, v_grek_munt_biedkoers,
                                      v_grek_munt_middenkoers, v_grek_munt_laatkoers, v_grek_m_munt_koers);

     -- aansluitend de klant (bank) koers:
     FIAT_ALGEMEEN.valutagegevens_bepalen (i_order_geldrek_muntsoort, gv_pr_id,              gv_ppr_id,          gv_sys_spread_categorie,
                                           gv_bank2marketchangedate,  gv_debuggen,           gv_debug_user,      v_grek_munt_biedkoers,
                                           v_grek_munt_middenkoers,   v_grek_munt_laatkoers, v_grek_munt_factor, v_grek_munt_reciproke,
                                           v_grek_munt_notatie);

     -- aansluitend bepalen welk van de koers er daadwerkelijk gebruikt moet worden aan de hand van de transactie
     FIAT_ALGEMEEN.muntkoers_bepalen (i_trans_k_v_ind,         1,                     v_grek_munt_reciproke, v_grek_munt_biedkoers,
                                      v_grek_munt_middenkoers, v_grek_munt_laatkoers, v_grek_b_munt_koers);

     -- als eerste stap de omrekening van het effectieve bedrag met behulp met de klant (bank) koersen:
     select FIAT_ALGEMEEN.omrekenen_bedrag_vv (i_netto_bedrag,      gv_trans_munt_reciproke, gv_trans_munt_factor, gv_trans_munt_koers,
                                               gv_trans_munt_koers, v_grek_munt_reciproke,   v_grek_munt_factor,   v_grek_b_munt_koers,
                                               v_grek_b_munt_koers, 4)                       -- let op hier hardcode notatie op 4 !
     into   v_bedrag_in_bankkoers
     from   dual;

     -- Als tweede stap de omrekening van het effectieve bedrag met behulp van de market koersen:
     select FIAT_ALGEMEEN.omrekenen_bedrag_vv (i_netto_bedrag,       gv_trans_munt_reciproke, gv_trans_munt_factor, v_trans_m_munt_koers,
                                               v_trans_m_munt_koers, v_grek_munt_reciproke,   v_grek_munt_factor,   v_grek_m_munt_koers,
                                               v_grek_m_munt_koers,  4)                       -- let op hier hardcoded notatie op 4 !
     into   v_bedrag_in_marktkoers
     from   dual;

     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug ( gv_debug_user, 'gebruikte klant (bank) transm koers : '||to_char(gv_trans_munt_koers)||
                                 ' ; gebruikte transm market koers : '||to_char(v_trans_m_munt_koers));
        FIAT_ALGEMEEN.fiat_debug ( gv_debug_user, 'gebruikte klant (bank) rekm koers : '||to_char(v_grek_b_munt_koers)||
                                 ' ; gebruikte klant (market) rekm koers : '||to_char(v_grek_m_munt_koers));
        FIAT_ALGEMEEN.fiat_debug ( gv_debug_user, ' ');
     end if;

     -- De uiteindelijke valutakosten. Deze zijn in de rekening valuta
     v_valutakosten_in_rekval := round((v_bedrag_in_bankkoers - v_bedrag_in_marktkoers) * case when i_trans_k_v_ind = 2 then -1 else 1 end, v_grek_munt_notatie);

     -- Voor de berekening moet dit bedrag als een bedrag in rv, tv en bv worden teruggegeven.
     select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_valutakosten_in_rekval, v_grek_munt_reciproke, v_grek_munt_factor, v_grek_m_munt_koers,
                                               v_grek_m_munt_koers,      gv_rel_rapp_reciproke, gv_rel_rapp_factor, gv_rel_rapp_middenkoers,
                                               gv_rel_rapp_middenkoers,  gv_rel_rapp_notatie)
     into   o_val_kosten_rv
     from   dual;

     select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_valutakosten_in_rekval, v_grek_munt_reciproke,   v_grek_munt_factor,   v_grek_m_munt_koers,
                                               v_grek_m_munt_koers,      gv_trans_munt_reciproke, gv_trans_munt_factor, i_trans_market_koers,
                                               i_trans_market_koers,     gv_trans_munt_notatie)
     into   o_val_kosten_tv
     from   dual;

     select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_valutakosten_in_rekval, v_grek_munt_reciproke,  v_grek_munt_factor,  v_grek_m_munt_koers,
                                               v_grek_m_munt_koers,      gv_basis_val_reciproke, gv_basis_val_factor, gv_basis_val_middenkoers,
                                               gv_basis_val_middenkoers, gv_basis_val_notatie)
     into   o_val_kosten_bv
     from   dual;

     select f.fimu_opslag_perc, f.fimu_afslag_perc
     into   v_opslag_perc,      v_afslag_perc
     from   fiat_muntsoorten f
     where  f.fimu_code = gv_trans_munt;
     -- spread van de transactiemuntsoort...
     o_val_spread := case when (v_bedrag_in_marktkoers - v_bedrag_in_bankkoers)/v_bedrag_in_marktkoers*100 <0 then v_afslag_perc else v_opslag_perc end;
  end if;

  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'Einde procedure valuta_kosten_berekenen');
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'Bedrag in marktkoers   : '||to_char(v_bedrag_in_marktkoers)||' ; Bedrag in bankkoers : '||to_char(v_bedrag_in_bankkoers));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'valutakosten in rekval : '||to_char(v_valutakosten_in_rekval));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'o val kosten rv        : '||to_char(o_val_kosten_rv)||' ; o val kosten tv : '||to_char(o_val_kosten_tv));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'o val kosten bv        : '||to_char(o_val_kosten_bv)||' ; o val spread    : '||to_char(o_val_spread));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
  end if;

end valuta_kosten_berekenen;
-- EINDE CODE VOOR PROCEDURE VALUTA_KOSTEN_BEREKENEN


-- DE CODE VOOR PROCEDURE VALUTA_KOSTEN_BEREK_LOS
-- Deze procedure kan gebruikt worden om van buiten FIAT_NOTABEDRAG met een aantal aan te leveren gegevens
-- toch valutakosten voor een bepaald effectief bedrag te berekenen
procedure valuta_kosten_berek_los
(i_ordernummer             in  kosten_werkbestand.kst_ordernummer%type
,i_orderregel              in  kosten_werkbestand.kst_orderregel%type
,i_orderdetailnummer       in  kosten_werkbestand.kst_detailnummer%type
,i_relatienummer           in  relatie_fiattering.rf_relatie_nummer%type
,i_sys_spread_categorie    in  valutaspread_cat_muntsoort.vscm_vsca_id%type
,i_bank2marketchangedate   in  muntsoorten.mu_update%type
,i_netto_bedrag_tv         in  kosten_werkbestand.kst_effect_bedrag_bv%type
,i_netto_bedrag_rv         in  kosten_werkbestand.kst_effect_bedrag_rv%type
,i_trans_valuta            in  kosten_werkbestand.kst_trans_muntsrt%type
,i_order_geldrek_muntsoort in  kosten_werkbestand.kst_rel1_rek2_munts%type
,i_trans_k_v_ind           in  kosten_werkbestand.kst_trans_indicatie_w%type
)
is

  v_trans_munt_biedkoers       fiat_muntsoorten.fimu_biedkoers%type;
  v_trans_munt_middenkoers     fiat_muntsoorten.fimu_middenkoers%type;
  v_trans_munt_laatkoers       fiat_muntsoorten.fimu_laatkoers%type;

  v_valuta_kosten_rv           kosten_werkbestand.kst_effect_bedrag_rv%type;
  v_valuta_kosten_tv           kosten_werkbestand.kst_effect_bedrag_rv%type;
  v_valuta_kosten_bv           kosten_werkbestand.kst_effect_bedrag_rv%type;
  v_valuta_spread              fiat_muntsoorten.fimu_afslag_perc%type;

  v_classification             fiat_order_costs_det.focd_classification%type;
  v_origin_type                fiat_order_costs_det.focd_origin_type%type;

begin
   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In procedure valuta kosten berekenen los');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Netto bedrag in tv : '||to_char(i_netto_bedrag_tv)||' ; transactie valuta : '||i_trans_valuta);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;
   
   -- Dit heeft alleen nut als het netto bedrag in tv ongelijk aan 0 is
   if i_netto_bedrag_tv <> 0
   then  
      -- eerst bepalen van een aantal gegevens die in de global variabelen moet worden gezet
      select r.rf_rapp_muntsoort,      r.rf_rapp_biedkoers,    r.rf_rapp_middenkoers,    r.rf_rapp_laatkoers,
             r.rf_rapp_reciproke,      r.rf_rapp_notatie,      r.rf_rapp_factor,
             r.rf_bv_muntsoort,        r.rf_bv_biedkoers,      r.rf_bv_middenkoers,      r.rf_bv_laatkoers,
             r.rf_bv_reciproke,        r.rf_bv_notatie,        r.rf_bv_factor,
             r.rf_pr_id,               r.rf_ppr_id,            r.rf_debug_j_n,           r.rf_debug_user
      into   gv_rel_rapp_valuta,       gv_rel_rapp_biedkoers,  gv_rel_rapp_middenkoers,  gv_rel_rapp_laatkoers,
             gv_rel_rapp_reciproke,    gv_rel_rapp_notatie,    gv_rel_rapp_factor,
             gv_basis_valuta,          gv_basis_val_biedkoers, gv_basis_val_middenkoers, gv_basis_val_laatkoers,
             gv_basis_val_reciproke,   gv_basis_val_notatie,   gv_basis_val_factor,
             gv_pr_id,                 gv_ppr_id,              gv_debuggen,             gv_debug_user
      from   relatie_fiattering r
      where  r.rf_relatie_nummer = i_relatienummer;
      
      gv_sys_spread_categorie    := i_sys_spread_categorie;
      gv_bank2marketchangedate   := i_bank2marketchangedate;
      
      gv_trans_munt              := i_trans_valuta;
      
      FIAT_ALGEMEEN.valutagegevens_bepalen (gv_trans_munt,            gv_pr_id,               gv_ppr_id,            gv_sys_spread_categorie,
                                            gv_bank2marketchangedate, gv_debuggen,            gv_debug_user,        v_trans_munt_biedkoers,
                                            v_trans_munt_middenkoers, v_trans_munt_laatkoers, gv_trans_munt_factor, gv_trans_munt_reciproke,
                                            gv_trans_munt_notatie);
      
      if gv_trans_munt = i_order_geldrek_muntsoort
      then
         gv_trans_munt_koers := v_trans_munt_middenkoers;
      else
         FIAT_ALGEMEEN.muntkoers_bepalen (i_trans_k_v_ind,          0,                      gv_trans_munt_reciproke, v_trans_munt_biedkoers,
                                          v_trans_munt_middenkoers, v_trans_munt_laatkoers, gv_trans_munt_koers);
      end if;
      
      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Trans market koers : '||to_char(v_trans_munt_middenkoers)||' ; order geldrek muntsoort : '||i_order_geldrek_muntsoort);
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Koop/Verkoop indic.: '||to_char(i_trans_k_v_ind));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
      end if;
      
      valuta_kosten_berekenen (abs(i_netto_bedrag_tv),  v_trans_munt_middenkoers, i_order_geldrek_muntsoort, i_trans_k_v_ind,
                               v_valuta_kosten_rv,      v_valuta_kosten_tv,       v_valuta_kosten_bv,        v_valuta_spread);
      
      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Na uitvoeren procedure valuta kosten berekenen');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Valuta kosten in rv : '||to_char(v_valuta_kosten_rv)||' ; valuta kosten in tv : '||to_char(v_valuta_kosten_tv));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Valuta kosten in bv : '||to_char(v_valuta_kosten_bv)||' ; valuta spread : '||to_char(v_valuta_spread));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
      end if;
      
      -- Als laatste de bedragen wegschrijven in het bedrag in rv <> 0 is
      if v_valuta_kosten_rv <> 0
      then
         -- Bij omwisselingen kunnen meer dan 1 fondsen met valutakosten zijn. Hier de bedragen bij elkaar op tellen...
         update fiat_order_costs_det f
         set    f.focd_total_amt     = f.focd_total_amt + v_valuta_kosten_rv,
                f.focd_basevalue_amt = f.focd_basevalue_amt + abs(i_netto_bedrag_rv)
         where  f.focd_order_number  = i_ordernummer
         and    f.focd_order_line    = i_orderregel
         and    f.focd_order_det_num = i_orderdetailnummer
         and    f.focd_cfcu_id       = 101;                 -- 101 is de calc rule voor de valutakosten van de relatie.
         
         if sql%notfound
         then
            begin
               select c.crc_mifid_type, c.crc_origin_type
               into   v_classification, v_origin_type
               from   calculationrules_codings c
               where  c.crc_cfcu_id = 101;
            exception
               when no_data_found
               then
                  v_classification := 'N/A';
                  v_origin_type    := 'N/A';
            end;
         
            insert into fiat_order_costs_det f
            (f.focd_order_number,    f.focd_order_line,        f.focd_order_det_num,
             f.focd_cfcu_id,         f.focd_fixed_amt,         f.focd_variable_amt,
             f.focd_total_amt,       f.focd_discount_amt,      f.focd_discount_perc,
             f.focd_basevalue_amt,   f.focd_calculation_type,  f.focd_classification,
             f.focd_origin_type,     f.focd_rule_max_amt,      f.focd_rule_min_amt,
             f.focd_rule_fixed_amt,  f.focd_rule_var_amt_perc, f.focd_rule_var_amt_amount,
             f.focd_rule_currency,   f.focd_tarif_id)
            values
            (i_ordernummer,          i_orderregel,             i_orderdetailnummer,
             101,                    null,                     null,
             v_valuta_kosten_rv,     null,                     null,
             abs(i_netto_bedrag_rv), 'INDIRECT',               v_classification,
             v_origin_type,          null,                     null,
             null,                   null,                     null,
             gv_rel_rapp_valuta,     0);
         end if;
      end if;
   end if; -- netto bedrag tv <> 0
end valuta_kosten_berek_los;


-- DE CODE VOOR PROCEDURE OMREKENEN_TV_BV
procedure omrekenen_tv_bv
(i_bedrag_in_tv       in   kosten_werkbestand.kst_effect_bedrag_bv%type
,o_bedrag_uit_bv      out  kosten_werkbestand.kst_effect_bedrag_bv%type
)

is
begin
   if gv_trans_munt = gv_basis_valuta
   then
      o_bedrag_uit_bv := i_bedrag_in_tv;
   else
      select FIAT_ALGEMEEN.omrekenen_bedrag(i_bedrag_in_tv,gv_trans_munt_reciproke,gv_trans_munt_factor,
                                            gv_trans_munt_koers,gv_trans_munt_koers,gv_basis_val_notatie)
      into   o_bedrag_uit_bv
      from   dual;
   end if;
end omrekenen_tv_bv;
-- EINDE CODE VOOR OMREKENEN_TV_BV


-- DE CODE VOOR PROCEDURE OMREKENEN_TV_RV
procedure omrekenen_tv_rv
(i_bedrag_in_tv        in  kosten_werkbestand.kst_effect_bedrag_bv%type
,o_bedrag_uit_rv       out kosten_werkbestand.kst_effect_bedrag_bv%type
)

is
begin
   if gv_trans_munt = gv_rel_rapp_valuta
   then
      o_bedrag_uit_rv := i_bedrag_in_tv;
   else
      select FIAT_ALGEMEEN.omrekenen_bedrag_vv(i_bedrag_in_tv,gv_trans_munt_reciproke,gv_trans_munt_factor,
                                               gv_trans_munt_koers,gv_trans_munt_koers,gv_rel_rapp_reciproke,gv_rel_rapp_factor,
                                               gv_relatie_munt_koers,gv_relatie_munt_koers,gv_rel_rapp_notatie)
      into   o_bedrag_uit_rv
      from   dual;
   end if;
end omrekenen_tv_rv;
-- EINDE CODE VOOR OMREKENEN_TV_RV


-- DE CODE VOOR PROCEDURE OMREKENEN_BV_TV
procedure omrekenen_bv_tv
(i_bedrag_in_bv        in  kosten_werkbestand.kst_effect_bedrag_bv%type
,o_bedrag_uit_tv       out kosten_werkbestand.kst_effect_bedrag_rv%type
)

is
begin
   if gv_basis_valuta = gv_trans_munt
   then
      o_bedrag_uit_tv := i_bedrag_in_bv;
   else
      select FIAT_ALGEMEEN.omrekenen_bedrag_vv(i_bedrag_in_bv,gv_basis_val_reciproke,gv_basis_val_factor,
                                               gv_basis_munt_koers,gv_basis_munt_koers,gv_trans_munt_reciproke,gv_trans_munt_factor,
                                               gv_trans_munt_koers,gv_trans_munt_koers,gv_trans_munt_notatie)
      into   o_bedrag_uit_tv
      from   dual;
   end if;
end omrekenen_bv_tv;
-- EINDE CODE VOOR OMREKENEN_BV_TV


-- DE CODE VOOR PROCEDURE OMREKENEN_BV_RV
procedure omrekenen_bv_rv
(i_bedrag_in_bv        in  kosten_werkbestand.kst_effect_bedrag_bv%type
,o_bedrag_uit_rv       out kosten_werkbestand.kst_effect_bedrag_rv%type
)

is
begin
   if gv_basis_valuta = gv_rel_rapp_valuta
   then
      o_bedrag_uit_rv := i_bedrag_in_bv;
   else
      select FIAT_ALGEMEEN.omrekenen_bedrag_vv(i_bedrag_in_bv,gv_basis_val_reciproke,gv_basis_val_factor,
                                               gv_basis_munt_koers,gv_basis_munt_koers,gv_rel_rapp_reciproke,gv_rel_rapp_factor,
                                               gv_relatie_munt_koers,gv_relatie_munt_koers,gv_rel_rapp_notatie)
      into   o_bedrag_uit_rv
      from   dual;
   end if;
end omrekenen_bv_rv;
-- EINDE CODE VOOR OMREKENEN_BV_RV


-- DE CODE VOOR PROCEDURE OPTELLEN_BEDRAGEN
procedure optellen_bedragen
(i_totaal_bedrag_in_rv           in  kosten_werkbestand.kst_effect_bedrag_rv%type
,i_totaal_bedrag_in_bv           in  kosten_werkbestand.kst_effect_bedrag_bv%type
,i_totaal_bedrag_in_tv           in  kosten_werkbestand.kst_effect_bedrag_rv%type
,i_optel_bedrag_in_rv            in  kosten_werkbestand.kst_effect_bedrag_rv%type
,i_optel_bedrag_in_bv            in  kosten_werkbestand.kst_effect_bedrag_bv%type
,i_optel_bedrag_in_tv            in  kosten_werkbestand.kst_effect_bedrag_rv%type
,i_trans_k_v_ind                 in  kosten_werkbestand.kst_trans_indicatie_w%type
,o_totaal_bedrag_in_rv           out kosten_werkbestand.kst_effect_bedrag_rv%type
,o_totaal_bedrag_in_bv           out kosten_werkbestand.kst_effect_bedrag_bv%type
,o_totaal_bedrag_in_tv           out kosten_werkbestand.kst_effect_bedrag_rv%type
)
is
begin

o_totaal_bedrag_in_rv := i_totaal_bedrag_in_rv + i_optel_bedrag_in_rv * case when i_trans_k_v_ind = 2 then -(1) else 1 end;
o_totaal_bedrag_in_bv := i_totaal_bedrag_in_bv + i_optel_bedrag_in_bv * case when i_trans_k_v_ind = 2 then -(1) else 1 end;
o_totaal_bedrag_in_tv := i_totaal_bedrag_in_tv + i_optel_bedrag_in_tv * case when i_trans_k_v_ind = 2 then -(1) else 1 end;

end optellen_bedragen;
-- EINDE CODE VOOR OPTELLEN_BEDRAGEN


-- DE CODE VOOR PROCEDURE WHT_PERCENTAGE_BEPALEN
procedure wht_percentage_bepalen
(i_fonds_id                  in  beleggingsinstrument.be_volgnummer%type
,i_relatienummer             in  kosten_werkbestand.kst_relatie_nummer%type
,o_belasting_percentage      out inkomensverdragperc.iv_percentage%type
)
is

  v_fonds_belastingverdrag       beleggingsinstrument.be_belastingverdrag%type;
  v_fonds_landcode               beleggingsinstrument.be_landcode%type;     
  v_fonds_instrumenttype         beleggingsinstrument.be_bi_nummer%type;
  
  v_verdrag_groepcode            relatieverdrag.rv_vg_verdraggrpcode%type;
  v_relatieverdrag_gevonden      number(1);

begin
  -- resetten van het belasting percentage
  o_belasting_percentage         := 0;
  v_relatieverdrag_gevonden      := 1;  -- er van uit gaan dat het relatieverdrag is gevonden
  
  select b.be_belastingverdrag,    b.be_landcode,    b.be_bi_nummer
  into   v_fonds_belastingverdrag, v_fonds_landcode, v_fonds_instrumenttype
  from   beleggingsinstrument b
  where  b.be_volgnummer = i_fonds_id;

  begin
     select r.rv_vg_verdraggrpcode
     into   v_verdrag_groepcode
     from   relatieverdrag r
     where  r.rv_cl_relatienummer = i_relatienummer
     and    r.rv_bv_belastingverdr = v_fonds_belastingverdrag
     and    r.rv_status            <= 2;
  exception
     when no_data_found
     then
        v_verdrag_groepcode       := 0;
        v_relatieverdrag_gevonden := 0;
  end;  
  
  -- Als er een relatie verdrag is gevonden, dan daarmee zoeken naar het bijbehorende percentage
  if v_relatieverdrag_gevonden = 1
  then
     begin
        select i.iv_percentage
        into   o_belasting_percentage
        from   inkomensverdragperc i    
        where  i.iv_belastingsverdrag  = v_fonds_belastingverdrag
        and    i.iv_verdraggroepcode   = v_verdrag_groepcode
        and    i.iv_inkomenssoort      = case when v_fonds_instrumenttype between 200 and 299 
                                              then 6 
                                              else 5 
                                              end
        and    i.iv_status             <= 2;
     exception
        when no_data_found
        then
           o_belasting_percentage := 0;
     end;
     
  -- Er is geen relatie verdrag gevonden. Dan via de landen tabel een percentage bepalen.
  else 
     select l.land_bronbelasting
     into   o_belasting_percentage
     from   landen l
     where  l.land_nummer = v_fonds_landcode;
  end if;

end wht_percentage_bepalen;
-- EINDE CODE VOOR WHT_PERCENTAGE_BEPALEN


-- DE CODE VOOR DE FUNCTION VERSION
function Version
return varchar2
is

begin
      return gv_versie;
end version;
-- EINDE CODE FUNCTION VERSION

end FIAT_NOTABEDRAG;
/
