create or replace package FIAT_ORDERS
is

/*------------------------------------------------------------------------------
Package     : FIAT_ORDERS
description : code voor de package FIAT_ORDERS waarbinnen de volgende procedures
              en functions aanwezig zijn:
              procedure  lopende_orders_loop
              procedure  huidige_order_loop
              funcction  version
------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';

-- procedure lopende_orders_loop:
   procedure lopende_orders_loop
   (i_relatienummer              in  clienten.cl_nummer%type
   ,i_slot_of_laatste_koers      in  varchar2
   ,i_ordnr_gewijzigde_order     in  orders.ord_ordernummer%type
   ,i_terminalnummer             in  werkbestand.wk_terminal%type
   ,i_rel_toeslag_optiemarg      in  producten.pr_toeslag_percentage%type
   ,i_rel_productnummer          in  producten_per_relatie.ppr_productnummer%type
   ,i_rel_product_volgnummer     in  producten_per_relatie.ppr_volgnr_per_product%type
   ,i_trekkingswaarde_aktief     in  number
   ,i_pr_blokkeren_short_call    in  producten.pr_blokkeren_short_calls%type
   ,i_pr_blokkeren_short_put     in  producten.pr_blokkeren_short_puts%type
   ,i_pr_blokkeren_long_put      in  producten.pr_blokkeren_long_puts%type
   ,i_kooporders_prolongeren     in  number
   ,i_methode_naked_margin       in  number
   ,i_factor_naked_margin        in  number
   ,i_te_fiatt_belegg_opdr       in  beleggingsopdracht_header.boh_opdrachtnummer%type
   ,i_eerst_verkoop_afhandelen   in  number
   ,i_instellingen               in  varchar2
   ,i_belgisch_spaar_product     in  number
   ,o_dekkingswaarde_over        out kosten_werkbestand.kst_dekkingswaarde%type
   ,o_gebruikte_dekkingsw_ord    out positie_werkbestand.pwb_port_waarde_rapv%type
   ,o_tot_lopende_opdrachten     out beleggingsopdracht_header.boh_bedrag%type
   );

-- procedure huidige_orders_loop:
   procedure huidige_order_loop
   (i_relatienummer              in  clienten.cl_nummer%type
   ,i_slot_of_laatste_koers      in  varchar2
   ,i_terminalnummer             in  werkbestand.wk_terminal%type
   ,i_rel_toeslag_optiemarg      in  producten.pr_toeslag_percentage%type
   ,i_rel_productnummer          in  producten_per_relatie.ppr_productnummer%type
   ,i_rel_product_volgnummer     in  producten_per_relatie.ppr_volgnr_per_product%type
   ,i_trekkingswaarde_aktief     in  number
   ,i_pr_blokkeren_short_call    in  producten.pr_blokkeren_short_calls%type
   ,i_pr_blokkeren_short_put     in  producten.pr_blokkeren_short_puts%type
   ,i_pr_blokkeren_long_put      in  producten.pr_blokkeren_long_puts%type
   ,i_kooporders_prolongeren     in  number
   ,i_methode_naked_margin       in  number
   ,i_factor_naked_margin        in  number
   ,i_dekkingswaarde_over        in  kosten_werkbestand.kst_dekkingswaarde%type
   ,i_gebruikte_dekkingsw_ord    in  positie_werkbestand.pwb_port_waarde_rapv%type
   ,i_instellingen               in  varchar2
   ,i_belgisch_spaar_product     in  number
   );

-- function version
   function version
   return                      varchar2;

end FIAT_ORDERS;
/
create or replace package body FIAT_ORDERS
is

/*------------------------------------------------------------------------------
Package body : FIAT_ORDERS
description  : code voor de package body FIAT_ORDERS waarbinnen de volgende
               functions en procedures aanwezig zijn:
               procedure  lopende_orders_loop
               procedure  huidige_order_loop
               procedure  lopende_orders_aantal
               procedure  lopende_orders_bereken
               procedure  lopende_orders_dekw
               procedure  uitgangspunt_bepalen
               function   version
------------------------------------------------------------------------------*/

-- globale variabelen (dus te gebruiken over alle procedures nadat de waarden zijn
-- bepaald in de eerst aanroepend procedure)
   gv_relatie_onld_omsch                       relatie_fiattering.rf_onld_omschrijving%type;
   gv_relatie_onld_perc                        relatie_fiattering.rf_onld_percentage%type;
   gv_relatie_onld_bedrag                      relatie_fiattering.rf_onld_bedrag_rappv%type;
   gv_debuggen                                 relatie_fiattering.rf_debug_j_n%type;
   gv_debug_user                               relatie_fiattering.rf_debug_user%type;
   gv_relatienummer                            clienten.cl_nummer%type;
   gv_rel_productnummer                        producten_per_relatie.ppr_productnummer%type;
   gv_rel_product_volgnr                       producten_per_relatie.ppr_volgnr_per_product%type;
   gv_rel_rapp_valuta                          relatie_fiattering.rf_rapp_muntsoort%type;
   gv_rel_rapp_biedkoers                       relatie_fiattering.rf_rapp_biedkoers%type;
   gv_rel_rapp_middenkoers                     relatie_fiattering.rf_rapp_middenkoers%type;
   gv_rel_rapp_laatkoers                       relatie_fiattering.rf_rapp_laatkoers%type;
   gv_rel_rapp_factor                          relatie_fiattering.rf_rapp_factor%type;
   gv_rel_rapp_reciproke                       relatie_fiattering.rf_rapp_reciproke%type;
   gv_rel_rapp_notatie                         relatie_fiattering.rf_rapp_notatie%type;
   gv_rek_valuta                               relatie_fiattering.rf_rapp_muntsoort%type;
   gv_rek_val_biedkoers                        relatie_fiattering.rf_rapp_biedkoers%type;
   gv_rek_val_middenkoers                      relatie_fiattering.rf_rapp_middenkoers%type;
   gv_rek_val_laatkoers                        relatie_fiattering.rf_rapp_laatkoers%type;
   gv_rek_val_factor                           relatie_fiattering.rf_rapp_factor%type;
   gv_rek_val_reciproke                        relatie_fiattering.rf_rapp_reciproke%type;
   gv_rek_val_notatie                          relatie_fiattering.rf_rapp_notatie%type;
   gv_relatie_pr_id                            producten.pr_id%type;
   gv_relatie_ppr_id                           producten_per_relatie.ppr_id%type;
   gv_basis_valuta                             relatie_fiattering.rf_bv_muntsoort%type;
   gv_basis_val_biedkoers                      relatie_fiattering.rf_bv_biedkoers%type;
   gv_basis_val_laatkoers                      relatie_fiattering.rf_bv_laatkoers%type;
   gv_basis_val_factor                         relatie_fiattering.rf_bv_factor%type;
   gv_basis_val_reciproke                      relatie_fiattering.rf_bv_reciproke%type;
   gv_basis_val_notatie                        relatie_fiattering.rf_bv_notatie%type;
   gv_rel_toeslag_optiemarg                    producten.pr_toeslag_percentage%type;
   gv_legal_entity_type                        legalentity_details.lety_id%type;
   gv_eor_kenmerk_id                           rekeninghouders_details.eor_kenmerk_id%type;
   gv_trekkingswaarde_aktief                   number(1);
   gv_pr_blokkeren_short_call                  producten.pr_blokkeren_short_calls%type;
   gv_pr_blokkeren_short_put                   producten.pr_blokkeren_short_puts%type;
   gv_pr_blokkeren_long_put                    producten.pr_blokkeren_long_puts%type;
   gv_kooporders_prolongeren                   number(1);
   gv_methode_naked_margin                     number(1);
   gv_factor_naked_margin                      number(6,3);
   gv_terminalnummer                           werkbestand.wk_terminal%type;
   gv_slot_of_laatste_koers                    tabelgegevens.tb_symbool%type;
   gv_order_nummer                             kosten_werkbestand.kst_ordernummer%type;
   gv_order_regel                              kosten_werkbestand.kst_orderregel%type;
   gv_order_detailregel                        kosten_werkbestand.kst_detailnummer%type;
   gv_order_orx_id                             ordersdetaillering.orx_id%type;
   gv_instellingen                             varchar2(1300);
   gv_systspreadcodecategorie                  valutaspread_cat_muntsoort.vscm_vsca_id%type;
   gv_bank2mrktqchangedate                     muntsoorten.mu_update%type;
   gv_belgisch_spaar_product                   number(1);
   gv_calculate_in_fc                          number(1);
   gv_suppressFCDekkwaarde                     number(1);

-- Declareren van de procedures die niet in de package header staan:

-- procedure lopende_orders_aantal:
   procedure lopende_orders_aantal
   (i_order_nummer                     in      orders.ord_ordernummer%type
   ,i_order_regel                      in      orders.ord_orderregel%type
   ,i_order_detailnummer               in      ordersdetaillering.orx_detailnummer%type
   ,i_order_status                     in      orders.ord_status%type
   ,i_order_type                       in      orders.ord_ordertype%type
   ,i_order_keuze                      in      orders.ord_keuze%type
   ,i_order_uitvoerstatus              in      orders.ord_uitvstatus%type
   ,i_order_transstatus                in      orders.ord_transstatus%type
   ,i_order_aantal                     in      orders.ord_aantal%type
   ,i_order_effectiefbedrag            in      orders.ord_effectiefbedrag%type
   ,i_order_notabedrag                 in      orders.ord_notabedrag%type
   ,i_order_depot                      in      orders.ord_depot%type
   ,i_order_depot_reksrt               in      orders.ord_depotreksrt%type
   ,i_order_geldrek_muntsoort          in      orders.ord_geldrekvaluta%type
   ,i_relatienummer                    in      clienten.cl_nummer%type
   ,i_order_relatie                    in      orders.ord_relatie%type
   ,i_belegg_opdr_herkomstcode         in      beleggingsopdracht_header.boh_herkomst%type
   ,i_order_herkomstcode               in      orders.ord_orderherkomst%type
   ,i_transactiesoort                  in      orders.ord_transactiesoort%type
   ,i_fonds_muntsoort                  in      beleggingsinstrument.be_muntsoort%type
   ,i_fonds_muntsrt_biedkoers          in      muntsoorten.mu_biedkoers%type
   ,i_fonds_muntsrt_laatkoers          in      muntsoorten.mu_laatkoers%type
   ,i_fonds_muntsrt_factor             in      muntsoorten.mu_factor%type
   ,i_fonds_muntsrt_reciproke          in      muntsoorten.mu_reciproke%type
   ,i_fonds_muntsrt_notatie            in      muntsoorten.mu_notatie%type
   ,i_orin_id_order                    in      orders.ord_orin_id%type
   ,i_order_in_reservation             in      orders.ord_in_reservation%type
   ,o_reken_aantal                     out     orders.ord_aantal%type
   ,o_order_depot                      out     orders.ord_depot%type
   ,o_order_depot_reksrt               out     orders.ord_depotreksrt%type
   ,o_order_geldrek_muntsoort          out     orders.ord_geldrekvaluta%type
   ,o_order_effectiefbedrag            out     orders.ord_effectiefbedrag%type
   ,o_order_notabedrag                 out     orders.ord_notabedrag%type
   ,o_transactiesoort                  out     orders.ord_transactiesoort%type
   ,o_m_aantal                         out     ordermodificaties.orm_aantal%type
   ,o_m_order_soort                    out     ordermodificaties.orm_ordersoort%type
   ,o_m_limiet                         out     ordermodificaties.orm_limiet%type
   ,o_m_provperceffwrd                 out     ordermodificaties.orm_provperceffwrd%type
   ,o_m_provkortingbv                  out     ordermodificaties.orm_provkortingbv%type
   ,o_m_provkortingperc                out     ordermodificaties.orm_provkortingperc%type
   ,o_m_provisieps_bv                  out     ordermodificaties.orm_provisieps_bv%type
   ,o_m_mutkosten_btw_bv               out     ordermodificaties.orm_mutkosten_btw_bv%type
   ,o_m_settlekosten_bv                out     ordermodificaties.orm_settlekosten_bv%type
   ,o_mutatie_gevonden                 out     number
   ,o_bgs_opdracht_nummer              out     beleggingsopdracht_header.boh_opdrachtnummer%type
   ,o_aantal_ord_bedrag_bgs            out     number
   ,o_bedrag_ord_aantal_bgs            out     number
   ,o_order_id                         out     ordersdetaillering.orx_id%type
   ,o_orx_distributiekanaal            out     ordersdetaillering.orx_distrib_kanaal%type
   );

-- procedure lopende_orders_bereken:
   procedure lopende_orders_bereken
   (i_ordernummer                      in      kosten_werkbestand.kst_ordernummer%type
   ,i_orderregel                       in      kosten_werkbestand.kst_orderregel%type
   ,i_orderdetailnummer                in      kosten_werkbestand.kst_detailnummer%type
   ,i_uitgangspunt_berekeningen        in      number
   ,i_symbool_comb                     in      kosten_werkbestand.kst_fondssymbool%type
   ,i_optietype_comb                   in      kosten_werkbestand.kst_optietype_fnds%type
   ,i_expiratiedatum_comb              in      kosten_werkbestand.kst_expiratiedat_fnds%type
   ,i_exerciseprijs_comb               in      kosten_werkbestand.kst_exercisepr_fnds%type
   ,i_fonds_muntsrt_comb               in      beleggingsinstrument.be_muntsoort%type
   ,i_trans_tb_waarde_comb             in      kosten_werkbestand.kst_trans_indicatie_w%type
   ,i_ordersoort_comb                  in      kosten_werkbestand.kst_order_soort%type
   ,i_transactie_soort_comb            in      kosten_werkbestand.kst_trans_indicatie%type
   ,i_limietprijs_comb                 in      kosten_werkbestand.kst_trans_prijs%type
   ,i_db_cr_indicatie                  in      orders.ord_dt_cr_spread%type
   ,i_slot_of_laatste_koers            in      varchar2
   ,i_terminalnummer                   in      werkbestand.wk_terminal%type
   ,i_sys_toeslag_optiemarg            in      tabelgegevens.tb_waarde%type
   ,i_wegings_perc_long                in      wegingsfactoren.wg_interne_perc%type
   ,i_wegings_perc_short               in      wegingsfactoren.wg_intern_short_perc%type
   ,i_fundcategory                     in      beleggingsinstrument.be_fundcategory%type
   ,i_berekenen_afgeleide_effecten     in      order_enkel_transtype.oet_afgeleide_effecten%type
   ,i_exas_berek_afgeleide_effect      in      order_enkel_transtype.oet_afgeleide_effecten%type
   ,i_berekenen_bruto_margin           in      order_enkel_transtype.oet_bruto_margin%type
   ,i_berekenen_bedrag_huidige_ord     in      order_enkel_transtype.oet_bedrag_huidige_o%type
   ,i_bgs_koop_order_op_0_zetten       in      number
   ,i_trans_context                    in      contextcalculationrules.cxcr_context%type
   ,io_gebruikte_dekkingsw_ord         in out  positie_werkbestand.pwb_port_waarde_rapv%type
   ,io_dekkingswaarde_over             in out  positie_werkbestand.pwb_port_waarde_rapv%type
   );

-- procedure lopende_orders_dekw:
   procedure lopende_orders_dekw
   (i_relatie_onld_omsch               in      on_line_dossier.onld_omschrijving_1%type
   ,i_relatie_onld_perc                in      on_line_dossier.onld_percentage%type
   ,i_fonds_symbool                    in      beleggingsinstrument.be_symbool%type
   ,i_optietype                        in      beleggingsinstrument.be_optietype%type
   ,i_expiratiedatum                   in      beleggingsinstrument.be_expiratiedatum%type
   ,i_exerciseprijs                    in      beleggingsinstrument.be_exerciseprijs%type
   ,i_fonds_muntsoort                  in      beleggingsinstrument.be_muntsoort%type
   ,i_trans_soort_tb_waarde            in      tabelgegevens.tb_waarde%type
   ,i_order_soort                      in      kosten_werkbestand.kst_order_soort%type
   ,i_wegingsperc_long                 in      wegingsfactoren.wg_interne_perc%type
   ,i_wegingsperc_short                in      wegingsfactoren.wg_intern_short_perc%type
   ,i_fundcategory                     in      beleggingsinstrument.be_fundcategory%type
   ,i_effectief_bedrag_tv              in      kosten_werkbestand.kst_notabedrag%type
   ,i_reken_aantal                     in      kosten_werkbestand.kst_trans_aantal%type
   ,i_begin_positie_order              in      kosten_werkbestand.kst_begin_pos_eff%type
   ,i_eind_positie_order               in      kosten_werkbestand.kst_eind_pos_eff%type
   ,i_fonds_be_bi_nummer               in      beleggingsinstrument.be_bi_nummer%type
   ,i_trans_context                    in      contextcalculationrules.cxcr_context%type
   ,o_dekkingswaarde                   out     kosten_werkbestand.kst_dekkingswaarde%type
   ,o_gebr_wegingsperc                 out     kosten_werkbestand.kst_wegingsfactor%type
   );

-- procedure lopende_orders_dekw_fnds_berek
   procedure lopende_orders_dekw_fnds_berek
   (i_relatienummer                    in      kosten_werkbestand.kst_relatie_nummer%type
   ,i_order_depot                      in      kosten_werkbestand.kst_depot%type
   ,i_order_depot_reksoort             in      kosten_werkbestand.kst_depotreksrt%type
   ,i_ex_as_factor_optie               in      beleggingsinstrument.be_exass_factor%type
   ,i_referentiesymbool                in      beleggingsinstrument.be_referentiesymbool%type
   ,i_fondssymbool                     in      beleggingsinstrument.be_symbool%type
   ,i_transactiesoort                  in      orders.ord_transactiesoort%type
   ,i_transactie_soort_tb_waarde       in      transactiesoorten.ts_koop_verkoop_ind%type
   ,i_rekenaantal                      in      kosten_werkbestand.kst_trans_aantal%type
   ,i_mandjes_factor                   in      mandje_onderliggende_waarde.mnd_factor%type
   ,i_order_externe_referentie         in      orders.ord_externe_referentie%type
   ,o_wegingsfactor_long               out     wegingsfactoren.wg_interne_perc%type
   ,o_wegingsfactor_short              out     wegingsfactoren.wg_eff_short_perc%type
   ,o_begin_positie_order              out     kosten_werkbestand.kst_begin_pos_eff%type
   ,o_eind_positie_order               out     kosten_werkbestand.kst_eind_pos_eff%type
   ,o_aantal_ow                        out     kosten_werkbestand.kst_trans_aantal%type
   ,o_effectiefbedrag_rv               out     kosten_werkbestand.kst_effect_bedrag_rv%type
   ,o_effectiefbedrag_tv               out     kosten_werkbestand.kst_effect_bedrag_rv%type
   );

-- procedure lopende_orders_dekwaarde_loop:
   procedure lopende_orders_dekwrde_loop
   (i_relatienummer                    in      kosten_werkbestand.kst_relatie_nummer%type
   ,i_order_depot                      in      kosten_werkbestand.kst_depot%type
   ,i_order_depot_reksoort             in      kosten_werkbestand.kst_depotreksrt%type
   ,i_ex_as_factor                     in      beleggingsinstrument.be_exass_factor%type
   ,i_referentiesymbool                in      beleggingsinstrument.be_referentiesymbool%type
   ,i_transactiesoort                  in      orders.ord_transactiesoort%type
   ,i_transactiesoort_tb_waarde        in      kosten_werkbestand.kst_trans_indicatie_w%type
   ,i_order_soort                      in      kosten_werkbestand.kst_order_soort%type
   ,i_rekenaantal                      in      kosten_werkbestand.kst_trans_aantal%type
   ,i_trans_context                    in      contextcalculationrules.cxcr_context%type
   ,i_fundcategory                     in      beleggingsinstrument.be_fundcategory%type
   ,o_dekkingswaarde                   out     kosten_werkbestand.kst_dekkingswaarde%type
   ,o_gebr_wegingsperc                 out     kosten_werkbestand.kst_wegingsfactor%type
   );

-- procedure uitgangspunt_bepalen
   procedure uitgangspunt_bepalen
   (i_order_keuze                      in      orders.ord_keuze%type
   ,i_order_type                       in      orders.ord_ordertype%type
   ,i_order_trans_status               in      orders.ord_transstatus%type
   ,i_order_notabedrag                 in      orders.ord_notabedrag%type
   ,i_order_effectiefbedrag            in      orders.ord_effectiefbedrag%type
   ,i_aantal_order_bedrag_bgs          in      number
   ,i_bedrag_order_aantal_bgs          in      number
   ,o_uitgangspunt_berekeningen        out     number
   );

-- procedure geboekt_in_trans_bepalen
   procedure geboekt_in_trans_bepalen
   (i_order_nummer                     in      orders.ord_ordernummer%type
   ,i_order_regel                      in      orders.ord_orderregel%type
   ,i_relatie_nummer                   in      orders.ord_relatie%type
   ,i_depot                            in      orders.ord_depot%type
   ,i_depot_reksoort                   in      orders.ord_depotreksrt%type
   ,i_orin_id                          in      orders.ord_orin_id%type
   ,o_geboekt_aantal                   out     orders.ord_aantal%type
   ,o_geboekt_notabedrag               out     orders.ord_notabedrag%type
   ,o_geboekt_effectiefbedrag          out     orders.ord_effectiefbedrag%type
   ,o_totaal_uitgevoerd                out     ordersuitvoeringen.uit_aantal%type
   ,o_tot_uitgevoerd_voor_trans        out     ordersuitvoeringen.uit_aantal%type
   );

-- procedure omrek_geboekt_notabedrag
   procedure omrek_geboekt_notabedrag
   (i_order_nummer                     in      orders.ord_ordernummer%type
   ,i_order_regel                      in      orders.ord_orderregel%type
   ,i_relatie_nummer                   in      orders.ord_relatie%type
   ,i_depot                            in      orders.ord_depot%type
   ,i_depot_reksoort                   in      orders.ord_depotreksrt%type
   ,i_fonds_muntsoort                  in      muntsoorten.mu_code%type
   ,i_fonds_muntsrt_reciproke          in      muntsoorten.mu_reciproke%type
   ,i_fonds_muntsrt_factor             in      muntsoorten.mu_factor%type
   ,i_fonds_muntsrt_biedkoers          in      muntsoorten.mu_biedkoers%type
   ,i_fonds_muntsrt_laatkoers          in      muntsoorten.mu_laatkoers%type
   ,i_fonds_muntsrt_notatie            in      muntsoorten.mu_notatie%type
   ,i_geboekt_notabedrag               in      orders.ord_notabedrag%type
   ,o_geboekt_notabedrag               out     orders.ord_notabedrag%type
   );

-- procedure lopende_beleg_opdr_herber
   procedure lopende_beleg_opdr_herber
   (o_tot_lopende_opdrachten out beleggingsopdracht_header.boh_bedrag%type
   );

-- procedure kosten_overnemen
   procedure kosten_overnemen
   (i_order_id               in  ordersdetaillering.orx_id%type
   ,i_ordernummer            in  ordersdetaillering.orx_ordernummer%type
   ,i_orderregel             in  ordersdetaillering.orx_orderregel%type
   ,i_order_detailnummer     in  ordersdetaillering.orx_detailnummer%type
   );

-- procedure omrekenen_rv_rekv
   procedure omrekenen_rv_rekv
   (i_bedrag_in_rv           in  kosten_werkbestand.kst_lopend_bedrag%type
   ,i_fonds_valuta           in  beleggingsinstrument.be_muntsoort%type
   ,o_bedrag_in_rekv         out kosten_werkbestand.kst_lopend_bedrag_rekv_sl%type
   );

-- procedure lopendbedrag_comb_bereken
   procedure lopendbedrag_comb_bereken
   (i_notabedrag_comb            in  kosten_werkbestand.kst_notabedrag%type
   ,i_notabedrag                 in  kosten_werkbestand.kst_notabedrag%type
   ,i_marginbedrag_comb          in  kosten_werkbestand.kst_marginbedrag%type
   ,i_marginbedrag               in  kosten_werkbestand.kst_marginbedrag%type
   ,i_ordernummer                in  kosten_werkbestand.kst_ordernummer%type
   ,i_bgs_koop_order_op_0_zetten in  number
   ,o_lopendbedrag_comb          out kosten_werkbestand.kst_lopend_bedrag%type
   ,o_lopendbedrag               out kosten_werkbestand.kst_lopend_bedrag%type
   );

-- procedure lopend
   procedure lopendbedrag_bereken
   (i_notabedrag                   in  kosten_werkbestand.kst_notabedrag%type
   ,i_dekkingswaarde               in  kosten_werkbestand.kst_dekkingswaarde%type
   ,i_marginbedrag                 in  kosten_werkbestand.kst_marginbedrag%type
   ,i_margin_effect_bedrag         in  kosten_werkbestand.kst_marginbedrag%type
   ,i_transactie_soort             in  kosten_werkbestand.kst_trans_indicatie%type
   ,i_bereken_bedrag_huidige_ord   in  number
   ,i_berekenen_afgeleide_effecten in  number
   ,i_exas_berek_afgeleide_effect  in  number
   ,i_bgs_koop_order_op_0_zetten   in  number
   ,i_ordernummer                  in  kosten_werkbestand.kst_ordernummer%type
   ,o_lopendbedrag                 out kosten_werkbestand.kst_lopend_bedrag%type
   ,o_marginbedrag                 out kosten_werkbestand.kst_marginbedrag%type
   );

-- procedure set_afwijkende_ordergegevens
   procedure set_afwijkende_ordergegevens
   (i_transactiesoort              in  transactiesoorten.ts_symbool%type
   ,i_ordernummer                  in  kosten_werkbestand.kst_ordernummer%type
   ,i_orderregel                   in  kosten_werkbestand.kst_orderregel%type
   ,i_detailnummer                 in  kosten_werkbestand.kst_detailnummer%type
   ,i_fondssymbool                 in  kosten_werkbestand.kst_fondssymbool%type
   ,i_fonds_optietype              in  kosten_werkbestand.kst_optietype_fnds%type
   ,i_fonds_expiratiedatum         in  kosten_werkbestand.kst_expiratiedat_fnds%type
   ,i_fonds_exercise_prijs         in  kosten_werkbestand.kst_exercisepr_fnds%type
   ,i_fonds_bi_nummer              in  kosten_werkbestand.kst_bi_nummer%type
   ,i_fonds_ex_ass_fac             in  kosten_werkbestand.kst_fnds_ex_ass_fac%type
   ,i_fonds_prijs_factor           in  kosten_werkbestand.kst_prijs_factor_fnds%type
   ,i_fonds_omw_factor             in  kosten_werkbestand.kst_omw_factor_fnds%type
   ,i_fonds_beurs_nummer           in  kosten_werkbestand.kst_beursnummer%type
   ,i_fonds_aantal_cijfers_disp    in  kosten_werkbestand.kst_aantal_cijfers_disp%type
   ,i_fonds_volgnummer             in  kosten_werkbestand.kst_fund_id%type
   ,i_fonds_muntsoort              in  kosten_werkbestand.kst_trans_muntsrt%type
   ,i_ref_fondssymbool             in  kosten_werkbestand.kst_ref_fondssymbool%type
   ,i_ref_fonds_bi_nummer          in  kosten_werkbestand.kst_ref_fnds_bi_nr%type
   ,i_ref_fonds_prijs_factor       in  kosten_werkbestand.kst_ref_fnds_prijs_f%type
   ,i_order_aantal                 in  kosten_werkbestand.kst_trans_aantal%type
   ,i_order_geen_provisie          in  kosten_werkbestand.kst_ord_geen_provisie%type
   ,i_wissel_tr_tb_waarde          in  number
   ,o_transsoort_tb_waarde         out transactiesoorten.ts_koop_verkoop_ind%type
   );

-- procedure bepaal_holder_kenmerken
   procedure bepaal_holder_kenmerken
   (i_ppr_id                       in  producten_per_relatie.ppr_id%type
   ,o_legal_entity_type            out legalentity_details.lety_id%type
   ,o_eor_kenmerk_id               out rekeninghouders_details.eor_kenmerk_id%type
   );

-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_LOOP:
-- In deze procedure wordt voor de opgegeven relatie de lopende orders bepaalt en worden
-- er al een aantal berekeneningen voor deze lopende orders uitgevoerd. De gegevens
-- worden weggeschreven in het kosten_werkbestand.
procedure lopende_orders_loop
(i_relatienummer              in  clienten.cl_nummer%type
,i_slot_of_laatste_koers      in  varchar2
,i_ordnr_gewijzigde_order     in  orders.ord_ordernummer%type
,i_terminalnummer             in  werkbestand.wk_terminal%type
,i_rel_toeslag_optiemarg      in  producten.pr_toeslag_percentage%type
,i_rel_productnummer          in  producten_per_relatie.ppr_productnummer%type
,i_rel_product_volgnummer     in  producten_per_relatie.ppr_volgnr_per_product%type
,i_trekkingswaarde_aktief     in  number
,i_pr_blokkeren_short_call    in  producten.pr_blokkeren_short_calls%type
,i_pr_blokkeren_short_put     in  producten.pr_blokkeren_short_puts%type
,i_pr_blokkeren_long_put      in  producten.pr_blokkeren_long_puts%type
,i_kooporders_prolongeren     in  number
,i_methode_naked_margin       in  number
,i_factor_naked_margin        in  number
,i_te_fiatt_belegg_opdr       in  beleggingsopdracht_header.boh_opdrachtnummer%type
,i_eerst_verkoop_afhandelen   in  number
,i_instellingen               in  varchar2
,i_belgisch_spaar_product     in  number
,o_dekkingswaarde_over        out kosten_werkbestand.kst_dekkingswaarde%type
,o_gebruikte_dekkingsw_ord    out positie_werkbestand.pwb_port_waarde_rapv%type
,o_tot_lopende_opdrachten     out beleggingsopdracht_header.boh_bedrag%type
)

is
   -- order fonds gerelateerde gegevens
   v_referentie_symbool                 beleggingsinstrument.be_referentiesymbool%type;
   v_ref_fonds_be_bi_nummer             beleggingsinstrument.be_bi_nummer%type;
   v_ref_fonds_prijs_factor             beleggingsinstrument.be_prijs_factor%type;
   v_ref_fonds_beurs_nummer             beleggingsinstrument.be_bv_beurs%type;
   v_ref_fonds_wegings_fac              beleggingsinstrument.be_wg_factor%type;
   v_ref_fonds_provisie_tabel           beleggingsinstrument.be_pr_nummer%type;
   v_fonds_provisie_tabel               beleggingsinstrument.be_pr_nummer%type;
   v_wegings_perc_long                  wegingsfactoren.wg_interne_perc%type;
   v_wegings_perc_short                 wegingsfactoren.wg_eff_short_perc%type;
   v_omwisselings_factor                beleggingsinstrument.be_aantal_te_ontvangen%type;
   -- order gerelateerde gegevens
   v_order_transsoort                   orders.ord_transactiesoort%type;
   v_trans_indicatie_num                tabelgegevens.tb_nummer%type;
   v_transactie_soort_tb_waarde         tabelgegevens.tb_waarde%type;
   v_order_soort                        orders.ord_ordersoort%type;
   v_limiet_toegestaan                  toegelordercontrole.toc_limietprijs%type;
   v_limietprijs                        orders.ord_limiet%type;
   v_emissie_inschrijfprijs_hoog        emissies.emi_inschr_hoog%type;
   v_emissie_betreft_ipo                emissies.emi_betreft_ipo%type;
   v_klantprijs                         fn_quotes_vw.quot_bied%type;
   v_dummy_prijs                        fn_quotes_vw.quot_bied%type;
   v_order_effectiefbedrag              orders.ord_effectiefbedrag%type;
   v_order_notabedrag                   orders.ord_notabedrag%type;
   v_uitgangspunt_berekeningen          number(1);
   v_order_provisie_perc_eff_wrd        orders.ord_provperceffwrd%type;
   v_order_provisieps_bv                orders.ord_provisieps_bv%type;
   v_order_prov_korting_perc            orders.ord_provkortingperc%type;
   v_order_mutatiekost_btw              orders.ord_mutkosten_btw_bv%type;
   v_order_settl_kost                   orders.ord_settlekosten_bv%type;
   v_standaard_land                     number(1);
   v_markt_model                        toegelordercontrole.toc_marktmodel%type;
   v_berek_bedrag_huidige_order         order_enkel_transtype.oet_bedrag_huidige_o%type;
   v_berekenen_bruto_margin             order_enkel_transtype.oet_bruto_margin%type;
   v_berekenen_afgeleide_effecten       order_enkel_transtype.oet_afgeleide_effecten%type;
   v_exas_berek_afgeleide_effect        order_enkel_transtype.oet_afgeleide_effecten%type;
   v_gebruikte_dekkingswaarde_ord       kosten_werkbestand.kst_dekkingswaarde%type;
   v_dekkingswaarde_over                kosten_werkbestand.kst_dekkingswaarde%type;
   v_positie_in_fonds                   positie_werkbestand.pwb_saldo_positie%type;
   v_begin_positie_order                kosten_werkbestand.kst_begin_pos_eff%type;
   v_eind_positie_order                 kosten_werkbestand.kst_eind_pos_eff%type;
   v_effect_lopende_orders_aant         positie_werkbestand.pwb_effect_lop_ord%type;
   v_port_waarde_positie_fonds          positie_werkbestand.pwb_port_waarde_rapv%type;
   v_dekk_waarde_positie_fonds          positie_werkbestand.pwb_dekk_waarde_rapv%type;
   v_positie_rowid                      rowid;
   v_OREF_record_gevonden               number(1);
   v_valuta_biedkoers                   muntsoorten.mu_biedkoers%type;
   v_valuta_laatkoers                   muntsoorten.mu_laatkoers%type;
   v_valuta_factor                      muntsoorten.mu_factor%type;
   v_valuta_reciproke                   muntsoorten.mu_reciproke%type;
   v_valuta_notatie                     muntsoorten.mu_notatie%type;
   v_dummy_waarde                       muntsoorten.mu_middenkoers%type;
   v_calculation_context                contextcalculationrules.cxcr_context%type;
   v_order_id                           ordersdetaillering.orx_id%type;
   v_orx_distributiekanaal              ordersdetaillering.orx_distrib_kanaal%type;
   -- relatie gerelateerde gegevens
   v_order_depot                        orders.ord_depot%type;
   v_order_depot_reksoort               orders.ord_depotreksrt%type;
   v_order_geldrek_muntsoort            orders.ord_geldrekvaluta%type;
   v_sys_toeslag_optiemarg              tabelgegevens.tb_waarde%type;
   -- variabelen voor het bepalen van reken/werk aantal
   v_reken_aantal                       orders.ord_aantal%type;
   --variabelen voor mutatie gegevens:
   v_mutatie_gevonden                   number(1);
   v_m_aantal                           orders.ord_aantal%type;
   v_m_order_soort                      orders.ord_ordersoort%type;
   v_m_limiet                           orders.ord_limiet%type;
   v_m_provperceffwrd                   orders.ord_provperceffwrd%type;
   v_m_provkortingbv                    orders.ord_provkorting_bv%type;
   v_m_provkortingperc                  orders.ord_provkortingperc%type;
   v_m_provisieps_bv                    orders.ord_provisieps_bv%type;
   v_m_mutkosten_btw_bv                 orders.ord_mutkosten_btw_bv%type;
   v_m_settlekosten_bv                  orders.ord_settlekosten_bv%type;
   --variabelen voor combinatieorder gegevens:
   v_symbool_comb                       beleggingsinstrument.be_symbool%type;
   v_optietype_comb                     beleggingsinstrument.be_optietype%type;
   v_expiratiedatum_comb                beleggingsinstrument.be_expiratiedatum%type;
   v_exerciseprijs_comb                 beleggingsinstrument.be_exerciseprijs%type;
   v_fonds_muntsrt_comb                 beleggingsinstrument.be_muntsoort%type;
   v_transactie_soort_comb              orders.ord_transactiesoort%type;
   v_trans_tb_waarde_comb               tabelgegevens.tb_waarde%type;
   v_limietprijs_comb                   orders.ord_limiet%type;
   v_ordersoort_comb                    orders.ord_ordersoort%type;
   v_db_cr_indicatie                    orders.ord_dt_cr_spread%type;
   -- virtuals voor het opvangen van niet gebruikte alpha waarden
   v_dummy_tb_alpha                     tabelgegevens.tb_nummer_oms%type;
   -- virtuals voor het ophalen van instellingen
   v_op_te_halen_instel                 varchar2(30);
   v_inst_type                          varchar2(1);
   v_instelling                         varchar2(100);
   -- virtuals voor het provisie op rekening gedeelte
   v_prov_op_rek_aktief                 number(1);
   v_cl_pr_nummer                       relatie_fiattering.rf_pr_nummer%type;
   v_cl_gebr_stand_prvcat               relatie_fiattering.rf_gebr_stand_prvcat%type;
   v_cl_min_prov_toepass                relatie_fiattering.rf_min_prov_toepass%type;
   v_pr_nummer                          kosten_werkbestand.kst_pr_nummer%type;
   v_gebr_stand_prvcat                  kosten_werkbestand.kst_gebr_stand_prvcat%type;
   v_min_prov_toepass                   kosten_werkbestand.kst_min_prov_toepass%type;
   -- overige virtuals
   v_belegg_opdracht_herkomstcode       beleggingsopdracht_header.boh_herkomst%type;
   v_bgs_koop_order_op_0_zetten         number(1);
   v_bgs_opdracht_nummer                beleggingsopdracht_header.boh_opdrachtnummer%type;
   v_bgs_opdracht_type                  beleggingsopdracht_header.boh_opdrachttype%type;
   v_aantal_ord_bedrag_bgs              number(1);
   v_bedrag_ord_aantal_bgs              number(1);
   v_maximeren_verkoopaantall           number(1);

cursor od is
       -- de tabel relatie_orders is een view waarin alle orders staan waarin de relatie deelneemt.
       select r.ord_ordernummer,         r.ord_orderregel,            r.ord_detailnummer,
              r.ord_orx_id,
              o.ord_ordertype,           o.ord_relatie,               o.ord_depot,
              o.ord_depotreksrt,         o.ord_fondssymbool,          o.ord_optietype,
              o.ord_expiratie,           o.ord_exercise,              o.ord_transactiesoort,
              o.ord_aantal,              o.ord_status,                o.ord_uitvstatus,
              o.ord_transstatus,         o.ord_beurs,                 o.ord_ordersoort,
              o.ord_limiet,              o.ord_provperceffwrd,        o.ord_provisie_absoluut,
              o.ord_provisieps_bv,       o.ord_provkortingperc,       o.ord_mutkosten_btw_bv,
              o.ord_settlekosten_bv,     o.ord_provkorting_bv,        o.ord_distrib_kanaal,
              o.ord_ordertrajekt,        o.ord_geldigheidsduur,       o.ord_keuze,
              o.ord_dt_cr_spread,        o.ord_combinatietype,        o.ord_notabedrag,
              o.ord_effectiefbedrag,     o.ord_orderherkomst,         o.ord_geen_provisie,
              o.ord_externe_referentie,  o.ord_geldrekvaluta,         o.ord_orin_id,
              o.ord_in_reservation,
              b.be_bi_nummer,            b.be_exass_factor,           b.be_prijs_factor,
              b.be_aantal_in_te_leveren, b.be_pr_nummer,              b.be_referentiesymbool,
              b.be_muntsoort,            b.be_landcode,               b.be_wg_factor,
              b.be_nominaal,             b.be_aantal_cijfers_display, b.be_aantal_te_ontvangen,
              b.be_volgnummer,           b.be_fundcategory
       from   relatie_orders r, orders o, beleggingsinstrument b
       where  r.ord_relatie             = i_relatienummer
       and    r.ord_ordernummer         <> i_ordnr_gewijzigde_order
       and    o.ord_ordernummer         = r.ord_ordernummer
       and    o.ord_orderregel          = r.ord_orderregel
       and    (o.ord_status             between 2 and 7
               or
               o.ord_status             between 15 and 16)
       and    o.ord_vervaldatum         >= to_char(sysdate,'yyyymmdd')
       and    o.ord_fondssymbool        = b.be_symbool
       and    o.ord_optietype           = b.be_optietype
       and    o.ord_expiratie           = b.be_expiratiedatum
       and    o.ord_exercise            = b.be_exerciseprijs
       order by r.ord_ordernummer, r.ord_orderregel, r.ord_detailnummer;


-- Door de lopende orders van de relatie heen
begin
    -- de relatie- en de systeemgegevens hoeven maar 1 maal opgehaald te worden:
    select r.rf_onld_omschrijving, r.rf_onld_percentage,   r.rf_onld_bedrag_rappv,
           r.rf_pr_nummer,         r.rf_gebr_stand_prvcat, r.rf_min_prov_toepass,
           r.rf_debug_j_n,         r.rf_debug_user,
           r.rf_rapp_muntsoort,    r.rf_rapp_biedkoers,    r.rf_rapp_laatkoers,
           r.rf_rapp_factor,       r.rf_rapp_reciproke,    r.rf_rapp_notatie,
           r.rf_bv_muntsoort,      r.rf_bv_biedkoers,      r.rf_bv_laatkoers,
           r.rf_bv_factor,         r.rf_bv_reciproke,      r.rf_bv_notatie,
           r.rf_pr_id,             r.rf_ppr_id,            r.rf_rapp_middenkoers
    into   gv_relatie_onld_omsch,  gv_relatie_onld_perc,   gv_relatie_onld_bedrag,
           v_cl_pr_nummer,         v_cl_gebr_stand_prvcat, v_cl_min_prov_toepass,
           gv_debuggen,            gv_debug_user,
           gv_rel_rapp_valuta,     gv_rel_rapp_biedkoers,  gv_rel_rapp_laatkoers,
           gv_rel_rapp_factor,     gv_rel_rapp_reciproke,  gv_rel_rapp_notatie,
           gv_basis_valuta,        gv_basis_val_biedkoers, gv_basis_val_laatkoers,
           gv_basis_val_factor,    gv_basis_val_reciproke, gv_basis_val_notatie,
           gv_relatie_pr_id,       gv_relatie_ppr_id,      gv_rel_rapp_middenkoers
    from   relatie_fiattering r
    where  r.rf_relatie_nummer = i_relatienummer;
    
    gv_rel_toeslag_optiemarg   := i_rel_toeslag_optiemarg;
    gv_relatienummer           := i_relatienummer;
    gv_rel_productnummer       := i_rel_productnummer;
    gv_rel_product_volgnr      := i_rel_product_volgnummer;
    gv_trekkingswaarde_aktief  := i_trekkingswaarde_aktief;
    gv_pr_blokkeren_short_call := i_pr_blokkeren_short_call;
    gv_pr_blokkeren_short_put  := i_pr_blokkeren_short_put;
    gv_pr_blokkeren_long_put   := i_pr_blokkeren_long_put;
    gv_kooporders_prolongeren  := i_kooporders_prolongeren;
    gv_methode_naked_margin    := i_methode_naked_margin;
    gv_factor_naked_margin     := i_factor_naked_margin;
    gv_terminalnummer          := i_terminalnummer;
    gv_slot_of_laatste_koers   := i_slot_of_laatste_koers;
    gv_instellingen            := i_instellingen;
    gv_belgisch_spaar_product  := i_belgisch_spaar_product;
    
    bepaal_holder_kenmerken (gv_relatie_ppr_id, gv_legal_entity_type, gv_eor_kenmerk_id);
    
    v_op_te_halen_instel := 'OptieMarginToesl';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    v_sys_toeslag_optiemarg := to_number(rtrim(ltrim(v_instelling)));

    -- gegevens van de provisie op rekeningen bepalen (Robein melding 8340-36740).
    v_op_te_halen_instel := 'PORKActief';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    v_prov_op_rek_aktief := to_number(rtrim(ltrim(v_instelling)));

    v_op_te_halen_instel := 'MaxVerkAant';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    v_maximeren_verkoopaantall := to_number(rtrim(ltrim(v_instelling)));

    v_op_te_halen_instel := 'Bank2MrktQChangeDate';
    v_inst_type          := 'D';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    gv_bank2mrktqchangedate := rtrim(ltrim(v_instelling));

    v_op_te_halen_instel := 'SystSprdCodeCat';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    gv_systspreadcodecategorie := to_number(rtrim(ltrim(v_instelling)));

    v_op_te_halen_instel := 'CalculateInFc';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    gv_calculate_in_fc   := to_number(rtrim(ltrim(v_instelling)));
    
    v_op_te_halen_instel := 'SuppressFCCollateralLoan';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    gv_suppressFCDekkwaarde := to_number(rtrim(ltrim(v_instelling)));

    
    if i_te_fiatt_belegg_opdr <> 0
    then
       select b.boh_herkomst
       into   v_belegg_opdracht_herkomstcode
       from   beleggingsopdracht_header b
       where  b.boh_opdrachtnummer = i_te_fiatt_belegg_opdr;
    else
       v_belegg_opdracht_herkomstcode := ' ';
    end if;
    -- Einde van  het ophalen van de vaste instellingen...

    -- Deze variabelen maar 1 keer zetten
    v_gebruikte_dekkingswaarde_ord := 0;
    v_dekkingswaarde_over          := 0;

    -- VANAF HIER DE LOOP DOOR DE ORDERS --
    for r_od in od
    loop

       if gv_debuggen = 1
       then
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in de procedure FIAT_ORDERS.lopende_orders_loop');
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer  : '||to_char(r_od.ord_ordernummer)||' ; orderregel : '||to_char(r_od.ord_orderregel));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'detailnummer : '||to_char(r_od.ord_detailnummer)||' ; inkomend ordernummer : '||to_char(i_ordnr_gewijzigde_order));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'   ');
       end if;

       gv_order_nummer      := r_od.ord_ordernummer;
       gv_order_regel       := r_od.ord_orderregel;
       gv_order_detailregel := r_od.ord_detailnummer;
       gv_order_orx_id      := r_od.ord_orx_id;

       if r_od.be_referentiesymbool = ' '
       then
          v_referentie_symbool := r_od.ord_fondssymbool;
       else
          v_referentie_symbool := r_od.be_referentiesymbool;
       end if;

       v_bgs_koop_order_op_0_zetten := 0; -- resetten naar default waarde (0 = niet op 0 zetten).
       v_bgs_opdracht_nummer        := 0;

       -- ophalen van extra gegevens voor de order (dus per order!)
       select b.be_bi_nummer,           b.be_prijs_factor,         b.be_bv_beurs,
              b.be_wg_factor,           b.be_pr_nummer
       into   v_ref_fonds_be_bi_nummer, v_ref_fonds_prijs_factor,  v_ref_fonds_beurs_nummer,
              v_ref_fonds_wegings_fac,  v_ref_fonds_provisie_tabel
       from   beleggingsinstrument b
       where  b.be_symbool        = v_referentie_symbool
       and    b.be_optietype      = ' '
       and    b.be_expiratiedatum = '00000000'
       and    b.be_exerciseprijs  = 0;

       FIAT_ALGEMEEN.valutagegevens_bepalen (r_od.be_muntsoort,       gv_relatie_pr_id,   gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                             gv_bank2mrktqchangedate, gv_debuggen,        gv_debug_user,     v_valuta_biedkoers,
                                             v_dummy_waarde,          v_valuta_laatkoers, v_valuta_factor,   v_valuta_reciproke,
                                             v_valuta_notatie);

       -- bepalen van het marktmodel
       if r_od.ord_keuze in ('O','VO')
       then
          if r_od.ord_optietype in ('CALL','PUT')
          then
             v_markt_model := 'OPT';
          else
             v_markt_model := 'FUT';
          end if;
       elsif r_od.ord_keuze in ('C','VC')
       then
          if r_od.ord_optietype in ('CALL','PUT')
          then
             v_markt_model := 'OPTC';
          else
             v_markt_model := 'FUTC';
          end if;
       else
          v_markt_model := 'EFF';
       end if;

       begin
          select c.toc_limietprijs
          into   v_limiet_toegestaan
          from   toegelordercontrole c
          where  c.toc_ordertraject = r_od.ord_ordertrajekt
          and    c.toc_ordertype    = r_od.ord_ordersoort
          and    c.toc_geldigheid   = r_od.ord_geldigheidsduur
          and    c.toc_marktmodel   = v_markt_model;

       exception
          when no_data_found
          then
             v_limiet_toegestaan := 0;
       end;

       begin
          select l.land_std_provisie
          into   v_standaard_land
          from   landen l
          where  l.land_nummer = r_od.be_landcode;

       exception
          when no_data_found
          then
             v_standaard_land := 0;
       end;

       -- bepalen van het rekenaantal (aantal dat nog loopt en niet in transacties is verwerkt)
       v_reken_aantal       := 0;
       v_mutatie_gevonden   := 0;
       v_m_aantal           := 0;
       v_m_order_soort      := ' ';
       v_m_limiet           := 0;
       v_m_provperceffwrd   := 0;
       v_m_provkortingbv    := 0;
       v_m_provkortingperc  := 0;
       v_m_provisieps_bv    := 0;
       v_m_mutkosten_btw_bv := 0;
       v_m_settlekosten_bv  := 0;

       if r_od.be_aantal_te_ontvangen = 0
       then
          v_omwisselings_factor := 0;
       else
          v_omwisselings_factor := round(r_od.be_aantal_in_te_leveren/r_od.be_aantal_te_ontvangen,6);
       end if;

       -- Bij verzamelorders worden de aantalen, bedragen en transactiesoort niet alleen uit de order gehaald maar
       -- bij afwijking uit de details
       -- bepalen van het nog lopend aantal van de order. Eventueel ook modificatie gegevens worden opgehaald
       lopende_orders_aantal(r_od.ord_ordernummer,     r_od.ord_orderregel,            r_od.ord_detailnummer,
                             r_od.ord_status,          r_od.ord_ordertype,             r_od.ord_keuze,
                             r_od.ord_uitvstatus,      r_od.ord_transstatus,           r_od.ord_aantal,
                             r_od.ord_effectiefbedrag, r_od.ord_notabedrag,            r_od.ord_depot,
                             r_od.ord_depotreksrt,     r_od.ord_geldrekvaluta,         i_relatienummer,
                             r_od.ord_relatie,         v_belegg_opdracht_herkomstcode, r_od.ord_orderherkomst,
                             r_od.ord_transactiesoort, r_od.be_muntsoort,              v_valuta_biedkoers,
                             v_valuta_laatkoers,       v_valuta_factor,                v_valuta_reciproke,
                             v_valuta_notatie,         r_od.ord_orin_id,               r_od.ord_in_reservation,
                             v_reken_aantal,           v_order_depot,
                             v_order_depot_reksoort,   v_order_geldrek_muntsoort,      v_order_effectiefbedrag,
                             v_order_notabedrag,       v_order_transsoort,             v_m_aantal,
                             v_m_order_soort,          v_m_limiet,                     v_m_provperceffwrd,
                             v_m_provkortingbv,        v_m_provkortingperc,            v_m_provisieps_bv,
                             v_m_mutkosten_btw_bv,     v_m_settlekosten_bv,            v_mutatie_gevonden,
                             v_bgs_opdracht_nummer,    v_aantal_ord_bedrag_bgs,        v_bedrag_ord_aantal_bgs,
                             v_order_id,               v_orx_distributiekanaal);

       -- hier checken of het depot wel in de mee te nemen depots voorkomt:
       begin
          select t.tdr_rekeningnr
          into   v_dummy_tb_alpha
          from   te_doorlopen_rek t
          where  t.tdr_rekeningnr    = v_order_depot
          and    t.tdr_rekeningsoort = v_order_depot_reksoort
          and    t.tdr_rekeningmunt  = ' ';
       exception
          when no_data_found
          then
             -- Als de rekening niet voorkomt in de te_doorlopen_rek dan het aantal op 0 stellen
             -- zodat de rest van de behandelingen niet worden uitgevoerd.
             v_reken_aantal          := 0;
             v_order_notabedrag      := 0;
             v_order_effectiefbedrag := 0;
       end;

       -- verder gaan als het als er nog een lopend deel is (aantal, notabedrag of effectiefbedrag <> 0)
       if   v_reken_aantal <> 0 or v_order_notabedrag <> 0 or v_order_effectiefbedrag <> 0
       then
          -- calculation lines zijn per order. Eerst werkbestand hiervoor leeg maken
          delete werkbestand w
          where  w.wk_terminal = gv_terminalnummer
          and    w.wk_soort    in ('CALI','CALW');

          -- Als een EP+ implementatie gebruik maakt van provisie op rek dan hier de provisiegegevens
          -- goed zetten. NB vanaf release 0516/0517 is het provisiegegevens op productniveau
          if v_prov_op_rek_aktief = 1
          then
             select p.ppr_provisiecategorie, p.ppr_provcat_standaard, p.ppr_provcat_minimum
             into   v_pr_nummer,             v_gebr_stand_prvcat,     v_min_prov_toepass
             from   producten_per_relatie p
             where  p.ppr_relatienummer      = i_relatienummer
             and    p.ppr_productnummer      = i_rel_productnummer
             and    p.ppr_volgnr_per_product = i_rel_product_volgnummer;
          else
             v_pr_nummer         := v_cl_pr_nummer;
             v_gebr_stand_prvcat := v_cl_gebr_stand_prvcat;
             v_min_prov_toepass  := v_cl_min_prov_toepass;
          end if;

          -- Op dit momement is de juiste transactie indicatie bekend. Hier de transactiesoort gerelateerde
          -- gegevens verder ophalen.
          select t.ts_indicatie_nummer, t.ts_koop_verkoop_ind
          into   v_trans_indicatie_num, v_transactie_soort_tb_waarde
          from   transactiesoorten t
          where  t.ts_symbool = v_order_transsoort;

          if v_order_transsoort not in ('EX C','EX P')
          then
             select o.oet_bedrag_huidige_o,        o.oet_bruto_margin,
                    o.oet_afgeleide_effecten
             into   v_berek_bedrag_huidige_order,  v_berekenen_bruto_margin,
                    v_berekenen_afgeleide_effecten
             from   order_enkel_transtype o
             where  o.oet_trans_ind_nummer = v_trans_indicatie_num;

             -- Als het geen exercise is, dan de weging van het fonds
             begin
                select w.wg_interne_perc,   w.wg_intern_short_perc
                into   v_wegings_perc_long, v_wegings_perc_short
                from   wegingsfactoren w
                where  w.wg_nummer = r_od.be_wg_factor;
             exception
                when no_data_found
                then
                   v_wegings_perc_long  := 0;
                   v_wegings_perc_short := 0;
             end;
             v_fonds_provisie_tabel      := r_od.be_pr_nummer;

             v_emissie_inschrijfprijs_hoog := 0;
             v_emissie_betreft_ipo         := 0;
             if v_order_transsoort = 'EMIS'
             then
                select e.emi_provisiecat,      e.emi_inschr_hoog,             e.emi_betreft_ipo 
                into   v_fonds_provisie_tabel, v_emissie_inschrijfprijs_hoog, v_emissie_betreft_ipo
                from   emissies e
                where  e.emi_fondssymbool = r_od.ord_fondssymbool;
             end if;

          else
             select o.oet_bedrag_huidige_o,       o.oet_bruto_margin,
                    o.oet_afgeleide_effecten
             into   v_berek_bedrag_huidige_order, v_berekenen_bruto_margin,
                    v_berekenen_afgeleide_effecten
             from   order_enkel_transtype o
             where  o.oet_trans_ind_nummer = v_trans_indicatie_num
             and    o.oet_onderdeel        = 'St';

             select o.oet_afgeleide_effecten
             into   v_exas_berek_afgeleide_effect
             from   order_enkel_transtype o
             where  o.oet_trans_ind_nummer = v_trans_indicatie_num
             and    o.oet_onderdeel        = 'Op';

             -- als het een exercise is, dan de weging van de onderliggende waarde
             begin
                select w.wg_interne_perc,   w.wg_intern_short_perc
                into   v_wegings_perc_long, v_wegings_perc_short
                from   wegingsfactoren w
                where  w.wg_nummer = v_ref_fonds_wegings_fac;
             exception
                when no_data_found
                then
                   v_wegings_perc_long  := 0;
                   v_wegings_perc_short := 0;
             end;
             v_fonds_provisie_tabel      := v_ref_fonds_provisie_tabel;

          end if;

          -- zetten van de variabelen waarmee verder gewerkt wordt (afgezien van de hierboven gevulde gegevens):
          -- als er mutatie gegevens zijn gevonden dan die gebruiken:
          if v_mutatie_gevonden = 1
          then
             v_order_soort                  := v_m_order_soort;
             v_limietprijs                  := v_m_limiet;
             v_order_provisie_perc_eff_wrd  := v_m_provperceffwrd;
             v_order_provisieps_bv          := v_m_provisieps_bv;
             v_order_prov_korting_perc      := v_m_provkortingperc;
             v_order_mutatiekost_btw        := v_m_mutkosten_btw_bv;
             v_order_settl_kost             := v_m_settlekosten_bv;
          else
             v_order_soort                  := r_od.ord_ordersoort;
             v_limietprijs                  := r_od.ord_limiet;
             v_order_provisie_perc_eff_wrd  := r_od.ord_provperceffwrd;
             v_order_provisieps_bv          := r_od.ord_provisieps_bv;
             v_order_prov_korting_perc      := r_od.ord_provkortingperc;
             v_order_mutatiekost_btw        := r_od.ord_mutkosten_btw_bv;
             v_order_settl_kost             := r_od.ord_settlekosten_bv;
          end if;

          -- voor combinatie orders voor het tweede leg de volgende gegevens van het eerste leg gebruiken:
          if r_od.ord_ordertype in ('COMB','VZCO') and r_od.ord_orderregel = 2
          then
             v_order_soort := v_ordersoort_comb;
             v_limietprijs := v_limietprijs_comb;
          end if;

          -- voor bgs orders moet nog gecontroleerd worden of het effect van de koop orders op 0 moet worden
          -- gezet. Hiervoor eerst het opdrachttype bepalen:
          if v_bgs_opdracht_nummer <> 0
          then
             begin
                select b.boh_opdrachttype
                into   v_bgs_opdracht_type
                from   beleggingsopdracht_header b
                where  b.boh_opdrachtnummer  = v_bgs_opdracht_nummer;
             exception
             when no_data_found
             then
                -- als de query niet lukt, dan in de historische bestanden kijken
                begin
                   select h.hboh_opdrachttype
                   into   v_bgs_opdracht_type
                   from   hist_beleggingsopdr_header h
                   where  h.hboh_opdrachtnummer  = v_bgs_opdracht_nummer;
                exception
                when no_data_found
                then
                   v_bgs_opdracht_type := ' ';
                end;
             end;

             -- bepalen of het lopend bedrag op 0 gezet moet worden
             if i_eerst_verkoop_afhandelen = 0             -- de instelling eerst verkoop afhandelen moet op 0 staan
                and
                v_bgs_opdracht_type in ('REBA','SWTC')     -- het moet een rebalance of switch betreffen
                and
                v_transactie_soort_tb_waarde = 1           -- het betreft alleen koop achtigen
             then
                v_bgs_koop_order_op_0_zetten := 1;
             end if;
          else -- het is geen bgs opdracht, dan de koop orders op de normale manier behandelen
             v_bgs_koop_order_op_0_zetten  := 0;
          end if;


          -- Nog bepalen wat het uitgangspunt is van de berekeningen van het nota/effectief bedrag
          -- De uitgangspunten zijn: 1 = aantal, 2 = notabedrag en effectiefbedrag, 3 = alleen effectiefbedrag
          -- 4 = alleen notabedrag en 0 = geen berekeningen meer uitvoeren
          uitgangspunt_bepalen (r_od.ord_keuze,          r_od.ord_ordertype,          r_od.ord_transstatus,
                                v_order_notabedrag,      v_order_effectiefbedrag,     v_aantal_ord_bedrag_bgs,
                                v_bedrag_ord_aantal_bgs, v_uitgangspunt_berekeningen);

          -- Als uitgangspunt van de berekeningen 1 is dan het notabedrag en effectiefbedrag op 0 zetten
          -- voor de zekerheid.
          if v_uitgangspunt_berekeningen = 1
          then
             v_order_notabedrag          := 0;
             v_order_effectiefbedrag     := 0;
          end if;

          -- voor de uitgangspunten 2 en 3 is het mogelijk om met behulp van het effectief bedrag een geschat aantal
          -- te bepalen. Dit zal een correcter aantal opleveren als koersen zijn gewijzigd tussen de invoer en nu bepalen van de VBR
          if v_uitgangspunt_berekeningen = 2 or v_uitgangspunt_berekeningen = 3
          then
             -- eerst de koersen bepalen die nu van toepassing zijn:
             FIAT_ALGEMEEN.fondsprijzen (r_od.ord_fondssymbool,      r_od.ord_optietype,    r_od.ord_expiratie,
                                         r_od.ord_exercise,          v_order_transsoort,    v_transactie_soort_tb_waarde,
                                         v_order_soort,              v_limiet_toegestaan,   v_limietprijs,
                                         0,                          0,                     v_emissie_inschrijfprijs_hoog,
                                         r_od.ord_provisie_absoluut, v_order_provisieps_bv, i_slot_of_laatste_koers,
                                         gv_debuggen,                gv_debug_user,         v_klantprijs,
                                         v_dummy_prijs,              v_dummy_prijs);

             if v_klantprijs <> 0
             then
                -- Op dit moment is het effectiefbedrag nog in de fondsvaluta (delen door de koers kan dus zondermeer)
                v_reken_aantal := trunc(v_order_effectiefbedrag /v_klantprijs / r_od.be_prijs_factor,0);
             end if;
          end if;

          -- eventueel nog aanpassen van het uitgangspunt als er geen openstaand aantal meer is:
          -- NB de uitgangspunten voor de bedragen zijn bepaald met behulp van de nog openstaande bedragen. Deze bedragen zijn er dus.
          if v_uitgangspunt_berekeningen = 1 and v_reken_aantal = 0
          then
             -- als er geen reken aantal meer is, dan is de aantal order geheel afgehandeld. Uitgangspunt dan naar 0 zetten.
             v_uitgangspunt_berekeningen := 0;

             if gv_debuggen = 1
             then
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in de procedure FIAT_ORDERS.lopende_orders_loop');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'uitganspunt berekeningen is naar 0 gezet, berekeningen voor de order '||to_char(r_od.ord_ordernummer)||' stoppen hier');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'   ');
             end if;
          end if;

          -- bepalen van het effect van de lopende orders tot nu toe op deze order...
          if v_berekenen_afgeleide_effecten = 1 and v_transactie_soort_tb_waarde = 2 and
             r_od.ord_ordertype not in ('COMB','VZCO') and r_od.ord_orderregel = 1
             or
             gv_relatie_onld_omsch = 'E' and v_wegings_perc_long <> 0
          then
             -- bepalen van het uitgangspunt voor deze order adv de positie
             begin
                select p.pwb_effect_lop_ord,         p.pwb_port_waarde_rapv,      p.pwb_dekk_waarde_rapv,
                       p.pwb_saldo_positie,          p.rowid
                into   v_effect_lopende_orders_aant, v_port_waarde_positie_fonds, v_dekk_waarde_positie_fonds,
                       v_positie_in_fonds,           v_positie_rowid
                from   positie_werkbestand p
                where  p.pwb_relatie_nummer  = i_relatienummer
                and    p.pwb_rekening_nummer = v_order_depot
                and    p.pwb_rekening_soort  = v_order_depot_reksoort
                and    p.pwb_symbool         = r_od.ord_fondssymbool
                and    p.pwb_optietype       = r_od.ord_optietype
                and    p.pwb_expiratiedatum  = r_od.ord_expiratie
                and    p.pwb_exerciseprijs   = r_od.ord_exercise;

             exception
               when no_data_found
               then
                  v_positie_in_fonds           := 0;
                  v_effect_lopende_orders_aant := 0;
                  v_port_waarde_positie_fonds  := 0;
                  v_dekk_waarde_positie_fonds  := 0;
                  v_positie_rowid              := ' ';
               end;

             if gv_relatie_onld_omsch = 'E' and v_wegings_perc_long <> 0
             then
                -- voor E moeten we altijd de positie verwerken. Dit omdat anders bij uitvoering van een order opeens kan blijken dat
                -- de dekkingswaarde kleiner (en dus het effect negatiever) blijkt te zijn. Hierdoor kunnen klanten een negatieve best.ruimte krijgen.
                begin
                   v_OREF_record_gevonden := 1;

                   select w.wk_waarde_3,         w.wk_waarde_4
                   into   v_begin_positie_order, v_eind_positie_order
                   from   werkbestand w
                   where  w.wk_terminal    = gv_terminalnummer
                   and    w.wk_soort       = 'OREF'
                   and    w.wk_categorie_1 = r_od.ord_fondssymbool
                   and    w.wk_categorie_2 = r_od.ord_optietype
                   and    w.wk_categorie_3 = to_char(r_od.ord_exercise)
                   and    w.wk_datum_1     = r_od.ord_expiratie;
                exception
                   when no_data_found
                   then
                      v_OREF_record_gevonden := 0;
                end;
                -- voor deze order is het eindpunt van de vorige order het beginpunt
                if v_OREF_record_gevonden = 0
                then
                   v_begin_positie_order        := nvl(v_effect_lopende_orders_aant,0);
                else
                   v_begin_positie_order        := nvl(v_eind_positie_order,0);
                end if;
                v_effect_lopende_orders_aant := v_begin_positie_order + ABS(v_reken_aantal) * (case when v_transactie_soort_tb_waarde = 2 or r_od.ord_transactiesoort = 'OMWL'
                                                                                                    then -1
                                                                                                    else 1
                                                                                                    end);
                v_eind_positie_order         := v_effect_lopende_orders_aant;

                if v_OREF_record_gevonden = 0
                then
                   -- Bij een insert de dekkingswaarde en fondswaarde opslaan, bij een update niet meer !!
                   insert into werkbestand w
                   (w.wk_terminal,                    w.wk_soort,          w.wk_categorie_1,            w.wk_categorie_2,
                    w.wk_categorie_3,                 w.wk_datum_1,        w.wk_waarde_1,               w.wk_waarde_2,
                    w.wk_waarde_3,                    w.wk_waarde_4)
                   values
                   (gv_terminalnummer,                'OREF',              r_od.ord_fondssymbool,       r_od.ord_optietype,
                    to_char(r_od.ord_exercise),       r_od.ord_expiratie,  v_port_waarde_positie_fonds, v_dekk_waarde_positie_fonds,
                    v_begin_positie_order,            v_eind_positie_order);
                elsif v_OREF_record_gevonden = 1
                then
                   update werkbestand w
                   set    w.wk_waarde_3    = v_begin_positie_order,
                          w.wk_waarde_4    = v_eind_positie_order
                   where  w.wk_terminal    = gv_terminalnummer
                   and    w.wk_soort       = 'OREF'
                   and    w.wk_categorie_1 = r_od.ord_fondssymbool
                   and    w.wk_categorie_2 = r_od.ord_optietype
                   and    w.wk_categorie_3 = to_char(r_od.ord_exercise)
                   and    w.wk_datum_1     = r_od.ord_expiratie;
                end if;

             elsif v_berekenen_afgeleide_effecten = 1 and v_transactie_soort_tb_waarde = 2 and
                   r_od.ord_ordertype not in ('COMB','VZCO') and r_od.ord_orderregel = 1
             then
                v_begin_positie_order        := v_effect_lopende_orders_aant;
                v_effect_lopende_orders_aant := v_effect_lopende_orders_aant - ABS(v_reken_aantal);
                v_eind_positie_order         := v_begin_positie_order - ABS(v_reken_aantal);

                -- Eventueel nog aanpassen van het eind aantal en het effect om te voorkomen dat baisse margin berekend kan gaan worden
                -- Dit geldt alleen voor bedragorders vanuit de BGSO !
                if v_maximeren_verkoopaantall = 1 and v_uitgangspunt_berekeningen <> 1 and r_od.ord_orderherkomst = 'BGSO'
                then
                   if v_effect_lopende_orders_aant < 0 and v_begin_positie_order > 0
                   then
                      v_effect_lopende_orders_aant := 0;
                    end if;

                    if v_eind_positie_order < 0 and v_begin_positie_order > 0
                    then
                       v_eind_positie_order := 0;
                    end if;
                end if;

                if v_positie_rowid <> ' '
                then
                   update positie_werkbestand pw
                   set    pw.pwb_effect_lop_ord = v_effect_lopende_orders_aant
                   where  pw.rowid              = v_positie_rowid;
                end if;
             elsif gv_relatie_onld_omsch = 'E' and v_transactie_soort_tb_waarde = 1
             then
                v_begin_positie_order        := v_positie_in_fonds;
                v_effect_lopende_orders_aant := v_positie_in_fonds + ABS(v_reken_aantal);
                v_eind_positie_order         := v_begin_positie_order + ABS(v_reken_aantal);
             else
                v_begin_positie_order        := 0;
                v_effect_lopende_orders_aant := 0;
                v_eind_positie_order         := 0;
             end if;
          else
             v_effect_lopende_orders_aant := 0;
             v_begin_positie_order        := 0;
             v_eind_positie_order         := 0;
             v_port_waarde_positie_fonds  := 0;
             v_dekk_waarde_positie_fonds  := 0;
          end if;

          -- De db cr indicator moet ook voor het 2e leg weggeschreven worden, daarom hier voor het eerste leg
          -- ook al in de virtual opslaan en de virtual wegschrijven ipv het veld uit het orderbestand
          if r_od.ord_ordertype in ('COMB','VZCO') and r_od.ord_orderregel = 1
          then
             v_db_cr_indicatie := r_od.ord_dt_cr_spread;
          end if;

          -- Doorgaan als een berekeningsuitgangspunt is (m.a.w. er is een aantal, eff./notabedrag en de bedrag order is nog lopend)
          if v_uitgangspunt_berekeningen <> 0
          then
             -- wegschrijven in het kosten werkbestand:
             insert into kosten_werkbestand k
             (k.kst_ordernummer,              k.kst_orderregel,            k.kst_detailnummer,
              k.kst_fondssymbool,             k.kst_optietype_fnds,        k.kst_expiratiedat_fnds,
              k.kst_exercisepr_fnds,          k.kst_bi_nummer,             k.kst_fnds_ex_ass_fac,
              k.kst_prijs_factor_fnds,        k.kst_omw_factor_fnds,       k.kst_provisie_cat_fnds,
              k.kst_aantal_cijfers_disp,      k.kst_beursnummer,           k.kst_fnds_nominaal,
              k.kst_ref_fondssymbool,         k.kst_ref_fnds_bi_nr,        k.kst_ref_fnds_prijs_f,
              k.kst_trans_indicatie,          k.kst_trans_indicatie_n,
              k.kst_trans_indicatie_w,        k.kst_trans_aantal,          k.kst_order_soort,
              k.kst_limiet_toegestaan,        k.kst_order_limietprijs,     k.kst_ord_provperceffw,
              k.kst_ord_prov_absoluut,        k.kst_ord_prov_ps_bv,        k.kst_ord_provkort_perc,
              k.kst_ord_mutkosten_btw,        k.kst_ord_settl_kosten,      k.kst_trans_kort_bedrag,
              k.kst_courtage_bedrag,          k.kst_trans_muntsrt,         k.kst_relatie_nummer,
              k.kst_depot,                    k.kst_rel1_rek2_munts,
              k.kst_depotreksrt,              k.kst_standaard_land,        k.kst_distributiekanaal,
              k.kst_begin_pos_eff,            k.kst_eind_pos_eff,          k.kst_gewoon_spoed_bet,
              k.kst_ordertype,                k.kst_dt_cr_spread,          k.kst_combinatietype,
              k.kst_pr_nummer,                k.kst_gebr_stand_prvcat,     k.kst_min_prov_toepass,
              k.kst_effect_bedrag_bv,
              k.kst_notabedrag,               k.kst_ord_notabedrag,        k.kst_order_keuze,
              k.kst_ord_geen_provisie,        k.kst_externe_referentie,    k.kst_opdrachtnummer,
              k.kst_fund_id)
             values
             (r_od.ord_ordernummer,           r_od.ord_orderregel,         r_od.ord_detailnummer,
              r_od.ord_fondssymbool,          r_od.ord_optietype,          r_od.ord_expiratie,
              r_od.ord_exercise,              r_od.be_bi_nummer,           r_od.be_exass_factor,
              r_od.be_prijs_factor,           v_omwisselings_factor,       v_fonds_provisie_tabel,
              r_od.be_aantal_cijfers_display, r_od.ord_beurs,              r_od.be_nominaal,
              v_referentie_symbool,           v_ref_fonds_be_bi_nummer,    v_ref_fonds_prijs_factor,
              v_order_transsoort,             v_trans_indicatie_num,
              v_transactie_soort_tb_waarde,   v_reken_aantal,              v_order_soort,
              v_limiet_toegestaan,            v_limietprijs,               v_order_provisie_perc_eff_wrd,
              r_od.ord_provisie_absoluut,     v_order_provisieps_bv,       v_order_prov_korting_perc,
              v_order_mutatiekost_btw,        v_order_settl_kost,          r_od.ord_provkorting_bv,
              0,                              r_od.be_muntsoort,           i_relatienummer,
              v_order_depot,                  v_order_geldrek_muntsoort,
              v_order_depot_reksoort,         v_standaard_land,            case when v_orx_distributiekanaal<>0 then v_orx_distributiekanaal else r_od.ord_distrib_kanaal end,
              v_begin_positie_order,          v_eind_positie_order,        0,
              r_od.ord_ordertype,             v_db_cr_indicatie,           r_od.ord_combinatietype,
              v_pr_nummer,                    v_gebr_stand_prvcat,         v_min_prov_toepass,
              v_order_effectiefbedrag,
              v_order_notabedrag,             r_od.ord_notabedrag,         r_od.ord_keuze,
              r_od.ord_geen_provisie,         r_od.ord_externe_referentie, v_bgs_opdracht_nummer,
              r_od.be_volgnummer);

             if v_order_transsoort = 'OMWL' and r_od.ord_keuze = 'WISO'
             then
                v_calculation_context := 'CA';                 -- voor omwisselingen context CA gebruiken !
             elsif
                v_order_transsoort = 'EMIS' and v_emissie_betreft_ipo = 1  
             then
                v_calculation_context := 'CUSTODY';            -- voor emissies en IPO = Ja context CUSTODY gebruiken ! 
             else      
                v_calculation_context := 'MARKETTRADE';        -- voor de overige orders context MARKETTRADE gebruiken !
             end if;

             -- als er op de order (nu alleen voor verzamelorders) al kosten zijn geadministreerd dan deze overnemen
             if v_order_id <> 0
             then
                kosten_overnemen(v_order_id, r_od.ord_ordernummer, r_od.ord_orderregel, r_od.ord_detailnummer);
             end if;

             -- Op deze plek de berekeningen aanroepen.....
             lopende_orders_bereken(r_od.ord_ordernummer,           r_od.ord_orderregel,      r_od.ord_detailnummer,
                                    v_uitgangspunt_berekeningen,    v_symbool_comb,           v_optietype_comb,
                                    v_expiratiedatum_comb,          v_exerciseprijs_comb,     v_fonds_muntsrt_comb,
                                    v_trans_tb_waarde_comb,         v_ordersoort_comb,        v_transactie_soort_comb,
                                    v_limietprijs_comb,             v_db_cr_indicatie,        i_slot_of_laatste_koers,
                                    gv_terminalnummer,              v_sys_toeslag_optiemarg,  v_wegings_perc_long,
                                    v_wegings_perc_short,           r_od.be_fundcategory,     v_berekenen_afgeleide_effecten, 
                                    v_exas_berek_afgeleide_effect,  v_berekenen_bruto_margin, v_berek_bedrag_huidige_order,   
                                    v_bgs_koop_order_op_0_zetten,   v_calculation_context,    v_gebruikte_dekkingswaarde_ord, 
                                    v_dekkingswaarde_over);

             -- reseten van de te berekenen waarden of vast houden van de gegevens van het eerste leg van een combinatie order
             if r_od.ord_ordertype in ('COMB','VZCO') and r_od.ord_orderregel = 1
             then
                v_limietprijs_comb      := v_limietprijs;
                v_ordersoort_comb       := v_order_soort;
                v_symbool_comb          := r_od.ord_fondssymbool;
                v_optietype_comb        := r_od.ord_optietype;
                v_expiratiedatum_comb   := r_od.ord_expiratie;
                v_exerciseprijs_comb    := r_od.ord_exercise;
                v_fonds_muntsrt_comb    := r_od.be_muntsoort;
                v_transactie_soort_comb := v_order_transsoort;
                v_trans_tb_waarde_comb  := v_transactie_soort_tb_waarde;
                v_db_cr_indicatie       := r_od.ord_dt_cr_spread;
             else
                v_limietprijs_comb      := 0;
                v_ordersoort_comb       := ' ';
                v_symbool_comb          := ' ';
                v_optietype_comb        := ' ';
                v_expiratiedatum_comb   := '00000000';
                v_exerciseprijs_comb    := 0;
                v_fonds_muntsrt_comb    := ' ';
                v_transactie_soort_comb := ' ';
                v_trans_tb_waarde_comb  := 0;
                v_db_cr_indicatie       := 0;
             end if;
          -- onderstaande end if is van v_uitgangspunt_berekening <> 0
          end if;
       -- onderstaande end if is van v_reken_aantal <> 0
       end if;
    end loop;
    o_dekkingswaarde_over       := v_dekkingswaarde_over;
    o_gebruikte_dekkingsw_ord   := v_gebruikte_dekkingswaarde_ord;

    -- nu nog de beleggingsopdracht gegevens aanpassen
    lopende_beleg_opdr_herber(o_tot_lopende_opdrachten);

end lopende_orders_loop;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_LOOP


-- DE CODE VOOR DE PROCEDURE HUIDIGE_ORDER_LOOP:
-- In deze procedure wordt voor de opgegeven relatie de huidige orders bepaalt en worden
-- er al een aantal berekeneningen voor deze huidige orders uitgevoerd. De gegevens
-- zijn en worden weggeschreven in het kosten_werkbestand.
procedure huidige_order_loop
(i_relatienummer              in  clienten.cl_nummer%type
,i_slot_of_laatste_koers      in  varchar2
,i_terminalnummer             in  werkbestand.wk_terminal%type
,i_rel_toeslag_optiemarg      in  producten.pr_toeslag_percentage%type
,i_rel_productnummer          in  producten_per_relatie.ppr_productnummer%type
,i_rel_product_volgnummer     in  producten_per_relatie.ppr_volgnr_per_product%type
,i_trekkingswaarde_aktief     in  number
,i_pr_blokkeren_short_call    in  producten.pr_blokkeren_short_calls%type
,i_pr_blokkeren_short_put     in  producten.pr_blokkeren_short_puts%type
,i_pr_blokkeren_long_put      in  producten.pr_blokkeren_long_puts%type
,i_kooporders_prolongeren     in  number
,i_methode_naked_margin       in  number
,i_factor_naked_margin        in  number
,i_dekkingswaarde_over        in  kosten_werkbestand.kst_dekkingswaarde%type
,i_gebruikte_dekkingsw_ord    in  positie_werkbestand.pwb_port_waarde_rapv%type
,i_instellingen               in  varchar2
,i_belgisch_spaar_product     in  number
)

is
   -- order fonds gerelateerde gegevens
   v_referentie_symbool                 beleggingsinstrument.be_referentiesymbool%type;
   v_ref_fonds_be_bi_nummer             beleggingsinstrument.be_bi_nummer%type;
   v_ref_fonds_prijs_factor             beleggingsinstrument.be_prijs_factor%type;
   v_ref_fonds_beurs_nummer             beleggingsinstrument.be_bv_beurs%type;
   v_ref_fonds_wegings_fac              beleggingsinstrument.be_wg_factor%type;
   v_ref_fonds_provisie_tabel           beleggingsinstrument.be_pr_nummer%type;
   v_fonds_provisie_tabel               beleggingsinstrument.be_pr_nummer%type;
   v_wegings_perc_long                  wegingsfactoren.wg_interne_perc%type;
   v_wegings_perc_short                 wegingsfactoren.wg_eff_short_perc%type;
   v_omwisselings_factor                beleggingsinstrument.be_aantal_te_ontvangen%type;
   -- order gerelateerde gegevens
   v_trans_indicatie_num                tabelgegevens.tb_nummer%type;
   v_transactie_soort_tb_waarde         tabelgegevens.tb_waarde%type;
   v_order_soort                        orders.ord_ordersoort%type;
   v_limietprijs                        orders.ord_limiet%type;
   v_limiet_toegestaan                  kosten_werkbestand.kst_limiet_toegestaan%type;
   v_emissie_inschrijfprijs_hoog        emissies.emi_inschr_hoog%type;
   v_emissie_betreft_ipo                emissies.emi_betreft_ipo%type;
   v_reken_aantal                       kosten_werkbestand.kst_trans_aantal%type;
   v_order_effectiefbedrag              kosten_werkbestand.kst_effect_bedrag_bv%type;
   v_order_notabedrag                   kosten_werkbestand.kst_notabedrag%type;
   v_uitgangspunt_berekeningen          number(1);
   v_standaard_land                     number(1);
   v_berek_bedrag_huidige_order         order_enkel_transtype.oet_bedrag_huidige_o%type;
   v_berekenen_bruto_margin             order_enkel_transtype.oet_bruto_margin%type;
   v_berekenen_afgeleide_effecten       order_enkel_transtype.oet_afgeleide_effecten%type;
   v_exas_berek_afgeleide_effect        order_enkel_transtype.oet_afgeleide_effecten%type;
   v_gebruikte_dekkingswaarde_ord       kosten_werkbestand.kst_dekkingswaarde%type;
   v_dekkingswaarde_over                kosten_werkbestand.kst_dekkingswaarde%type;
   v_begin_positie_order                kosten_werkbestand.kst_begin_pos_eff%type;
   v_eind_positie_order                 kosten_werkbestand.kst_eind_pos_eff%type;
   v_effect_lopende_orders_aant         positie_werkbestand.pwb_effect_lop_ord%type;
   v_klantprijs                         kosten_werkbestand.kst_trans_prijs%type;
   v_dummy_prijs                        kosten_werkbestand.kst_trans_prijs%type;
   v_positie_in_fonds                   positie_werkbestand.pwb_saldo_positie%type;
   v_port_waarde_positie_fonds          positie_werkbestand.pwb_port_waarde_rapv%type;
   v_dekk_waarde_positie_fonds          positie_werkbestand.pwb_dekk_waarde_rapv%type;
   v_positie_rowid                      rowid;
   v_OREF_record_gevonden               number(1);
   v_valuta_biedkoers                   muntsoorten.mu_biedkoers%type;
   v_valuta_laatkoers                   muntsoorten.mu_laatkoers%type;
   v_valuta_factor                      muntsoorten.mu_factor%type;
   v_valuta_reciproke                   muntsoorten.mu_reciproke%type;
   v_valuta_notatie                     muntsoorten.mu_notatie%type;
   v_calculation_context                contextcalculationrules.cxcr_context%type;
   v_dummy_waarde                       muntsoorten.mu_middenkoers%type;
   -- relatie gerelateerde gegevens
   v_sys_toeslag_optiemarg              tabelgegevens.tb_waarde%type;
   --variabelen voor combinatieorder gegevens:
   v_symbool_comb                       beleggingsinstrument.be_symbool%type;
   v_optietype_comb                     beleggingsinstrument.be_optietype%type;
   v_expiratiedatum_comb                beleggingsinstrument.be_expiratiedatum%type;
   v_exerciseprijs_comb                 beleggingsinstrument.be_exerciseprijs%type;
   v_fonds_muntsrt_comb                 beleggingsinstrument.be_muntsoort%type;
   v_transactie_soort_comb              orders.ord_transactiesoort%type;
   v_trans_tb_waarde_comb               tabelgegevens.tb_waarde%type;
   v_limietprijs_comb                   orders.ord_limiet%type;
   v_limiettoegestaan_comb              kosten_werkbestand.kst_limiet_toegestaan%type;
   v_ordersoort_comb                    orders.ord_ordersoort%type;
   v_db_cr_indicatie_comb               orders.ord_dt_cr_spread%type;
   -- virtuals voor het ophalen van de instellingen
   v_op_te_halen_instel                 varchar2(30);
   v_inst_type                          varchar2(1);
   v_instelling                         varchar2(100);

cursor od is
       select k.kst_ordernummer,        k.kst_orderregel,            k.kst_detailnummer,
              k.kst_ordertype,          k.kst_relatie_nummer,        k.kst_depot,
              k.kst_depotreksrt,        k.kst_fondssymbool,          k.kst_optietype_fnds,
              k.kst_expiratiedat_fnds,  k.kst_exercisepr_fnds,       k.kst_beursnummer,
              k.kst_trans_indicatie,    k.kst_trans_aantal,          k.kst_order_soort,
              k.kst_limiet_toegestaan,  k.kst_order_limietprijs,     k.kst_dt_cr_spread,
              k.kst_combinatietype,     k.kst_distributiekanaal,     k.kst_effect_bedrag_bv,
              k.kst_notabedrag,         k.kst_order_keuze,           k.kst_ord_prov_absoluut,
              k.kst_ord_prov_ps_bv,
              b.be_bi_nummer,           b.be_exass_factor,           b.be_prijs_factor,
              b.be_pr_nummer,           b.be_referentiesymbool,      b.be_aantal_te_ontvangen,
              b.be_muntsoort,           b.be_landcode,               b.be_wg_factor,
              b.be_nominaal,            b.be_aantal_cijfers_display, b.be_aantal_in_te_leveren,
              b.be_volgnummer,          b.be_fundcategory
       from   kosten_werkbestand k, beleggingsinstrument b
       where  k.kst_ordernummer       = -1
       and    k.kst_fondssymbool      = b.be_symbool
       and    k.kst_optietype_fnds    = b.be_optietype
       and    k.kst_expiratiedat_fnds = b.be_expiratiedatum
       and    k.kst_exercisepr_fnds   = b.be_exerciseprijs
       order by k.kst_ordernummer, k.kst_orderregel, k.kst_detailnummer;


-- Door de huidige order van de relatie heen
begin
    -- de relatie- en de systeemgegevens hoeven maar 1 maal opgehaald te worden:
    select r.rf_onld_omschrijving, r.rf_onld_percentage,  r.rf_onld_bedrag_rappv,
           r.rf_rapp_muntsoort,    r.rf_rapp_biedkoers,   r.rf_rapp_laatkoers,
           r.rf_rapp_factor,       r.rf_rapp_reciproke,   r.rf_rapp_notatie,
           r.rf_debug_j_n,         r.rf_debug_user,
           r.rf_pr_id,             r.rf_ppr_id,           r.rf_rapp_middenkoers
    into   gv_relatie_onld_omsch,  gv_relatie_onld_perc,  gv_relatie_onld_bedrag,
           gv_rel_rapp_valuta,     gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers,
           gv_rel_rapp_factor,     gv_rel_rapp_reciproke, gv_rel_rapp_notatie,
           gv_debuggen,            gv_debug_user,
           gv_relatie_pr_id,       gv_relatie_ppr_id,     gv_rel_rapp_middenkoers
    from   relatie_fiattering r
    where  r.rf_relatie_nummer = i_relatienummer;

    gv_rel_toeslag_optiemarg   := i_rel_toeslag_optiemarg;
    gv_trekkingswaarde_aktief  := i_trekkingswaarde_aktief;
    gv_pr_blokkeren_short_call := i_pr_blokkeren_short_call;
    gv_pr_blokkeren_short_put  := i_pr_blokkeren_short_put;
    gv_pr_blokkeren_long_put   := i_pr_blokkeren_long_put;
    gv_kooporders_prolongeren  := i_kooporders_prolongeren;
    gv_methode_naked_margin    := i_methode_naked_margin;
    gv_factor_naked_margin     := i_factor_naked_margin;
    gv_terminalnummer          := i_terminalnummer;
    gv_slot_of_laatste_koers   := i_slot_of_laatste_koers;
    gv_instellingen            := i_instellingen;
    gv_relatienummer           := i_relatienummer;
    gv_rel_productnummer       := i_rel_productnummer;
    gv_rel_product_volgnr      := i_rel_product_volgnummer;
    gv_belgisch_spaar_product  := i_belgisch_spaar_product;
    
    bepaal_holder_kenmerken (gv_relatie_ppr_id, gv_legal_entity_type, gv_eor_kenmerk_id);
    
    v_op_te_halen_instel := 'OptieMarginToesl';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    v_sys_toeslag_optiemarg := to_number(rtrim(ltrim(v_instelling)));

    v_op_te_halen_instel := 'Bank2MrktQChangeDate';
    v_inst_type          := 'D';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    gv_bank2mrktqchangedate := rtrim(ltrim(v_instelling));

    v_op_te_halen_instel := 'SystSprdCodeCat';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    gv_systspreadcodecategorie := to_number(rtrim(ltrim(v_instelling)));

    v_op_te_halen_instel := 'CalculateInFc';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    gv_calculate_in_fc   := to_number(rtrim(ltrim(v_instelling)));
    
    v_op_te_halen_instel := 'SuppressFCCollateralLoan';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    gv_suppressFCDekkwaarde := to_number(rtrim(ltrim(v_instelling)));
    -- Einde van  het ophalen van de vaste instellingen...

    -- Deze variabelen maar 1 keer zetten
    v_gebruikte_dekkingswaarde_ord := i_gebruikte_dekkingsw_ord;
    v_dekkingswaarde_over          := i_dekkingswaarde_over;

    if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure FIAT_ORDERS.huidige_order_loop (dus onderhanden zijnde order');
    end if;

    -- HIER BEGINT DE LOOP DOOR DE NIEUWE ORDERS --
    for r_od in od
    loop

       if gv_debuggen = 1
       then
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer  : '||to_char(r_od.kst_ordernummer)||' ; orderregel : '||to_char(r_od.kst_orderregel));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'detailnummer : '||to_char(r_od.kst_detailnummer));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'   ');
       end if;

       gv_order_nummer      := r_od.kst_ordernummer;
       gv_order_regel       := r_od.kst_orderregel;
       gv_order_detailregel := r_od.kst_detailnummer;
       gv_order_orx_id      := -1 * r_od.kst_orderregel;        -- Dit nummer bestaat nog niet, dus hier op -(regelnummer) gezet...

       if r_od.be_referentiesymbool = ' '
       then
          v_referentie_symbool := r_od.kst_fondssymbool;
       else
          v_referentie_symbool := r_od.be_referentiesymbool;
       end if;

       -- ophalen van extra gegevens voor de order (dus per poot!)
       select b.be_bi_nummer,           b.be_prijs_factor,         b.be_bv_beurs,
              b.be_wg_factor,           b.be_pr_nummer
       into   v_ref_fonds_be_bi_nummer, v_ref_fonds_prijs_factor,  v_ref_fonds_beurs_nummer,
              v_ref_fonds_wegings_fac,  v_ref_fonds_provisie_tabel
       from   beleggingsinstrument b
       where  b.be_symbool        = v_referentie_symbool
       and    b.be_optietype      = ' '
       and    b.be_expiratiedatum = '00000000'
       and    b.be_exerciseprijs  = 0;

       FIAT_ALGEMEEN.valutagegevens_bepalen (r_od.be_muntsoort,       gv_relatie_pr_id,   gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                             gv_bank2mrktqchangedate, gv_debuggen,        gv_debug_user,     v_valuta_biedkoers,
                                             v_dummy_waarde,          v_valuta_laatkoers, v_valuta_factor,   v_valuta_reciproke,
                                             v_valuta_notatie);


       select t.ts_indicatie_nummer, t.ts_koop_verkoop_ind
       into   v_trans_indicatie_num, v_transactie_soort_tb_waarde
       from   transactiesoorten t
       where  t.ts_symbool = r_od.kst_trans_indicatie;

       if r_od.kst_trans_indicatie not in ('EX C','EX P')
       then
          select o.oet_bedrag_huidige_o,       o.oet_bruto_margin,
                 o.oet_afgeleide_effecten
          into   v_berek_bedrag_huidige_order, v_berekenen_bruto_margin,
                 v_berekenen_afgeleide_effecten
          from   order_enkel_transtype o
          where  o.oet_trans_ind_nummer = v_trans_indicatie_num;

          -- Als het geen exercise is, dan de weging van het fonds
          begin
             select w.wg_interne_perc,   w.wg_intern_short_perc
             into   v_wegings_perc_long, v_wegings_perc_short
             from   wegingsfactoren w
             where  w.wg_nummer = r_od.be_wg_factor;
          exception
             when no_data_found
             then
                v_wegings_perc_long  := 0;
                v_wegings_perc_short := 0;
          end;
          v_fonds_provisie_tabel      := r_od.be_pr_nummer;

          v_emissie_inschrijfprijs_hoog := 0;
          v_emissie_betreft_ipo         := 0;
          if r_od.kst_trans_indicatie = 'EMIS'
          then
             select e.emi_provisiecat,      e.emi_inschr_hoog,             e.emi_betreft_ipo
             into   v_fonds_provisie_tabel, v_emissie_inschrijfprijs_hoog, v_emissie_betreft_ipo
             from   emissies e
             where  e.emi_fondssymbool = r_od.kst_fondssymbool;
          end if;

       else
          select o.oet_bedrag_huidige_o,       o.oet_bruto_margin,
                 o.oet_afgeleide_effecten
          into   v_berek_bedrag_huidige_order, v_berekenen_bruto_margin,
                 v_berekenen_afgeleide_effecten
          from   order_enkel_transtype o
          where  o.oet_trans_ind_nummer = v_trans_indicatie_num
          and    o.oet_onderdeel        = 'St';

          select o.oet_afgeleide_effecten
          into   v_exas_berek_afgeleide_effect
          from   order_enkel_transtype o
          where  o.oet_trans_ind_nummer = v_trans_indicatie_num
          and    o.oet_onderdeel        = 'Op';

          -- als het een exercise is, dan de weging van de onderliggende waarde
          begin
             select w.wg_interne_perc,   w.wg_intern_short_perc
             into   v_wegings_perc_long, v_wegings_perc_short
             from   wegingsfactoren w
             where  w.wg_nummer = v_ref_fonds_wegings_fac;
          exception
             when no_data_found
             then
                v_wegings_perc_long  := 0;
                v_wegings_perc_short := 0;
          end;
          v_fonds_provisie_tabel      := v_ref_fonds_provisie_tabel;

       end if;

       begin
          select l.land_std_provisie
          into   v_standaard_land
          from   landen l
          where  l.land_nummer = r_od.be_landcode;

       exception
          when no_data_found
          then
             v_standaard_land := 0;
       end;

       -- verder gaan als het orderaantal <> 0 is
       if   r_od.kst_trans_aantal <> 0 or r_od.kst_notabedrag <> 0
       then
          -- calculation lines zijn per order. Eerst werkbestand hiervoor leeg maken
          delete werkbestand w
          where  w.wk_terminal = gv_terminalnummer
          and    w.wk_soort    in ('CALI','CALW');

          -- zetten van de variabelen waarmee verder gewerkt wordt (afgezien van de hierboven gevulde gegevens):
          v_order_soort           := r_od.kst_order_soort;
          v_limietprijs           := r_od.kst_order_limietprijs;
          v_limiet_toegestaan     := r_od.kst_limiet_toegestaan;
          v_order_effectiefbedrag := r_od.kst_effect_bedrag_bv;
          v_order_notabedrag      := r_od.kst_notabedrag;
          v_reken_aantal          := r_od.kst_trans_aantal;

          if r_od.be_aantal_te_ontvangen = 0
          then
             v_omwisselings_factor := 0;
          else
             v_omwisselings_factor := round(r_od.be_aantal_in_te_leveren/r_od.be_aantal_te_ontvangen,6);
          end if;

          -- voor combinatie orders voor het tweede leg de volgende gegevens van het eerste leg gebruiken:
          if r_od.kst_ordertype in ('COMB','VZCO') and r_od.kst_orderregel = 2
          then
             v_order_soort       := v_ordersoort_comb;
             v_limietprijs       := v_limietprijs_comb;
             v_limiet_toegestaan := v_limiettoegestaan_comb;
          end if;

          -- Nog bepalen wat het uitgangspunt is van de berekeningen van het nota/effectief bedrag
          -- De uitgangspunten zijn: 1 = aantal, 2 = notabedrag en effectiefbedrag, 3 = alleen effectiefbedrag
          -- 4 = alleen notabedrag en 0 = geen berekeningen meer uitvoeren
          uitgangspunt_bepalen (r_od.kst_order_keuze,       r_od.kst_ordertype,          0,
                                v_order_notabedrag,         v_order_effectiefbedrag,     0,
                                0,                          v_uitgangspunt_berekeningen);

          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'na het bepalen uitgangspunt van de berekeningen');
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order keuze  : '||r_od.kst_order_keuze||' ; order type : '||r_od.kst_ordertype);
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order notabedrag : '||to_char(v_order_notabedrag)||
                                                     ' ; order effectiefbedrag : '||to_char(v_order_effectiefbedrag));
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'reken aantal : '||to_char(v_reken_aantal)||
                                                     ' ; uitgangspunt berekeningen : '||to_char(v_uitgangspunt_berekeningen));
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'   ');
          end if;

          if v_uitgangspunt_berekeningen = 1
          then
             v_order_notabedrag      := 0;
             v_order_effectiefbedrag := 0;

          -- voor de uitgangspunten 2 en 3 is het mogelijk om met behulp van het effectief bedrag een geschat aantal
          -- te bepalen. Dit zal een correcter aantal opleveren als koersen zijn gewijzigd tussen de invoer en nu bepalen van de VBR
          elsif v_uitgangspunt_berekeningen = 2 or v_uitgangspunt_berekeningen = 3
          then
             -- eerst de koersen bepalen die nu van toepassing zijn:
             FIAT_ALGEMEEN.fondsprijzen (r_od.kst_fondssymbool,      r_od.kst_optietype_fnds,  r_od.kst_expiratiedat_fnds,
                                         r_od.kst_exercisepr_fnds,   r_od.kst_trans_indicatie, v_transactie_soort_tb_waarde,
                                         r_od.kst_order_soort,       v_limiet_toegestaan,      v_limietprijs,
                                         0,                          0,                        v_emissie_inschrijfprijs_hoog,
                                         r_od.kst_ord_prov_absoluut, r_od.kst_ord_prov_ps_bv,  i_slot_of_laatste_koers,
                                         gv_debuggen,                gv_debug_user,            v_klantprijs,
                                         v_dummy_prijs,              v_dummy_prijs);

             if v_klantprijs <> 0
             then
                -- Op dit moment is het effectiefbedrag nog in de fondsvaluta (delen door de koers kan dus zondermeer)
                v_reken_aantal := trunc(v_order_effectiefbedrag /v_klantprijs / r_od.be_prijs_factor,0);
             end if;
          end if;

          -- Doorgaan als een berekeningsuitgangspunt is (m.a.w. er is een aantal, eff./notabedrag en de bedrag order is nog lopend)
          if v_uitgangspunt_berekeningen <> 0
          then
             -- bepalen van het effect van de lopende orders tot nu toe op deze order...
             if v_berekenen_afgeleide_effecten = 1 and v_transactie_soort_tb_waarde = 2 and
                r_od.kst_ordertype not in ('COMB','VZCO') and r_od.kst_orderregel = 1
                or
                gv_relatie_onld_omsch = 'E' and v_wegings_perc_long <> 0
             then
                -- bepalen van het uitgangspunt voor deze order adv de positie
                begin
                   select p.pwb_effect_lop_ord,         p.pwb_port_waarde_rapv,      p.pwb_dekk_waarde_rapv,
                          p.pwb_saldo_positie,          p.rowid
                   into   v_effect_lopende_orders_aant, v_port_waarde_positie_fonds, v_dekk_waarde_positie_fonds,
                          v_positie_in_fonds,           v_positie_rowid
                   from   positie_werkbestand p
                   where  p.pwb_relatie_nummer  = i_relatienummer
                   and    p.pwb_rekening_nummer = r_od.kst_depot
                   and    p.pwb_rekening_soort  = r_od.kst_depotreksrt
                   and    p.pwb_symbool         = r_od.kst_fondssymbool
                   and    p.pwb_optietype       = r_od.kst_optietype_fnds
                   and    p.pwb_expiratiedatum  = r_od.kst_expiratiedat_fnds
                   and    p.pwb_exerciseprijs   = r_od.kst_exercisepr_fnds;

                exception
                   when no_data_found
                   then
                      v_positie_in_fonds           := 0;
                      v_effect_lopende_orders_aant := 0;
                      v_port_waarde_positie_fonds  := 0;
                      v_dekk_waarde_positie_fonds  := 0;
                      v_positie_rowid              := ' ';
                end;

                if gv_relatie_onld_omsch = 'E' and v_wegings_perc_long <> 0
                then
                   -- voor E moeten we altijd de positie verwerken. Dit omdat anders bij uitvoering van een order opeens kan blijken dat
                   -- de dekkingswaarde kleiner (en dus het effect negatiever) blijkt te zijn. Hierdoor kunnen klanten een negatieve best.ruimte krijgen.
                   begin
                      v_OREF_record_gevonden := 1;

                      select w.wk_waarde_3,         w.wk_waarde_4
                      into   v_begin_positie_order, v_eind_positie_order
                      from   werkbestand w
                      where  w.wk_terminal    = gv_terminalnummer
                      and    w.wk_soort       = 'OREF'
                      and    w.wk_categorie_1 = r_od.kst_fondssymbool
                      and    w.wk_categorie_2 = r_od.kst_optietype_fnds
                      and    w.wk_categorie_3 = to_char(r_od.kst_exercisepr_fnds)
                      and    w.wk_datum_1     = r_od.kst_expiratiedat_fnds;
                   exception
                      when no_data_found
                      then
                         v_OREF_record_gevonden := 0;
                   end;
                   -- voor deze order is het eindpunt van de vorige order het beginpunt
                   if v_OREF_record_gevonden = 0
                   then
                      v_begin_positie_order        := nvl(v_effect_lopende_orders_aant,0);
                   else
                      v_begin_positie_order        := nvl(v_eind_positie_order,0);
                   end if;

                   v_effect_lopende_orders_aant := v_begin_positie_order + ABS(v_reken_aantal) * (case when v_transactie_soort_tb_waarde = 2 or r_od.kst_trans_indicatie = 'OMWL'
                                                                                                       then -1
                                                                                                       else 1
                                                                                                       end);
                   v_eind_positie_order         := v_effect_lopende_orders_aant;

                   if v_OREF_record_gevonden = 0
                   then
                      -- Bij een insert de dekkingswaarde en fondswaarde opslaan, bij een update niet meer !!
                      insert into werkbestand w
                      (w.wk_terminal,                     w.wk_soort,                  w.wk_categorie_1,            w.wk_categorie_2,
                       w.wk_categorie_3,                  w.wk_datum_1,                w.wk_waarde_1,               w.wk_waarde_2,
                       w.wk_waarde_3,                     w.wk_waarde_4)
                      values
                      (gv_terminalnummer,                 'OREF',                      r_od.kst_fondssymbool,       r_od.kst_optietype_fnds,
                       to_char(r_od.kst_exercisepr_fnds), r_od.kst_expiratiedat_fnds,  v_port_waarde_positie_fonds, v_dekk_waarde_positie_fonds,
                       v_begin_positie_order,             v_eind_positie_order);
                   elsif v_OREF_record_gevonden = 1
                   then
                      update werkbestand w
                      set    w.wk_waarde_3    = v_begin_positie_order,
                             w.wk_waarde_4    = v_eind_positie_order
                      where  w.wk_terminal    = gv_terminalnummer
                      and    w.wk_soort       = 'OREF'
                      and    w.wk_categorie_1 = r_od.kst_fondssymbool
                      and    w.wk_categorie_2 = r_od.kst_optietype_fnds
                      and    w.wk_categorie_3 = to_char(r_od.kst_exercisepr_fnds)
                      and    w.wk_datum_1     = r_od.kst_expiratiedat_fnds;
                   end if;

                elsif v_berekenen_afgeleide_effecten = 1 and v_transactie_soort_tb_waarde = 2 and
                r_od.kst_ordertype not in ('COMB','VZCO') and r_od.kst_orderregel = 1
                then
                   v_begin_positie_order        := v_effect_lopende_orders_aant;
                   v_effect_lopende_orders_aant := v_effect_lopende_orders_aant - ABS(v_reken_aantal);
                   v_eind_positie_order         := v_begin_positie_order - ABS(v_reken_aantal);

                   if v_positie_rowid <> ' '
                   then
                      update positie_werkbestand pw
                      set    pw.pwb_effect_lop_ord = v_effect_lopende_orders_aant
                      where  pw.rowid              = v_positie_rowid;
                   end if;
                else
                   v_begin_positie_order        := 0;
                   v_effect_lopende_orders_aant := 0;
                   v_eind_positie_order         := 0;
                end if;
             else
                v_effect_lopende_orders_aant := 0;
                v_begin_positie_order        := 0;
                v_port_waarde_positie_fonds  := 0;
                v_dekk_waarde_positie_fonds  := 0;
                v_eind_positie_order         := 0;
             end if;

             -- De db cr indicator moet ook voor het 2e leg weggeschreven worden, daarom hier voor het eerste leg
             -- ook al in de virtual opslaan en de virtual wegschrijven ipv het veld uit het orderbestand
             if r_od.kst_ordertype in ('COMB','VZCO') and r_od.kst_orderregel = 1
             then
                v_db_cr_indicatie_comb := r_od.kst_dt_cr_spread;
             end if;

             -- wegschrijven in het kosten werkbestand:
             update kosten_werkbestand k
             set    k.kst_bi_nummer           = r_od.be_bi_nummer,
                    k.kst_fnds_ex_ass_fac     = r_od.be_exass_factor,
                    k.kst_prijs_factor_fnds   = r_od.be_prijs_factor,
                    k.kst_omw_factor_fnds     = v_omwisselings_factor,
                    k.kst_provisie_cat_fnds   = v_fonds_provisie_tabel,
                    k.kst_aantal_cijfers_disp = r_od.be_aantal_cijfers_display,
                    k.kst_fnds_nominaal       = r_od.be_nominaal,
                    k.kst_ref_fondssymbool    = v_referentie_symbool,
                    k.kst_ref_fnds_bi_nr      = v_ref_fonds_be_bi_nummer,
                    k.kst_ref_fnds_prijs_f    = v_ref_fonds_prijs_factor,
                    k.kst_trans_indicatie_n   = v_trans_indicatie_num,
                    k.kst_trans_indicatie_w   = v_transactie_soort_tb_waarde,
                    k.kst_order_soort         = v_order_soort,
                    k.kst_effect_bedrag_bv    = v_order_effectiefbedrag,
                    k.kst_notabedrag          = v_order_notabedrag,
                    k.kst_trans_aantal        = v_reken_aantal,
                    k.kst_courtage_bedrag     = 0,
                    k.kst_order_limietprijs   = v_limietprijs,
                    k.kst_limiet_toegestaan   = v_limiet_toegestaan,
                    k.kst_trans_muntsrt       = r_od.be_muntsoort,
                    k.kst_standaard_land      = v_standaard_land,
                    k.kst_begin_pos_eff       = v_begin_positie_order,
                    k.kst_eind_pos_eff        = v_eind_positie_order,
                    k.kst_gewoon_spoed_bet    = 0,
                    k.kst_dt_cr_spread        = v_db_cr_indicatie_comb,
                    k.kst_fund_id             = r_od.be_volgnummer
             where  k.kst_ordernummer         = r_od.kst_ordernummer
             and    k.kst_orderregel          = r_od.kst_orderregel
             and    k.kst_detailnummer        = r_od.kst_detailnummer;

             if r_od.kst_trans_indicatie = 'OMWL' and r_od.kst_order_keuze = 'WISO'
             then
                v_calculation_context := 'CA';                 -- voor omwisselingen context CA gebruiken !
             elsif
                r_od.kst_trans_indicatie = 'EMIS' and v_emissie_betreft_ipo = 1
             then
                v_calculation_context := 'CUSTODY_CALC';       -- voor emissies en IPO = Ja context CUSTODY_CALC gebruiken ! 
             else       
                v_calculation_context := 'CALCULATION';        -- voor de overige orders context CALCULATION gebruiken !
             end if;

             -- Op deze plek de berekeningen aanroepen
             lopende_orders_bereken(r_od.kst_ordernummer,           r_od.kst_orderregel,      r_od.kst_detailnummer,
                                    v_uitgangspunt_berekeningen,    v_symbool_comb,           v_optietype_comb,
                                    v_expiratiedatum_comb,          v_exerciseprijs_comb,     v_fonds_muntsrt_comb,
                                    v_trans_tb_waarde_comb,         v_ordersoort_comb,        v_transactie_soort_comb,
                                    v_limietprijs_comb,             v_db_cr_indicatie_comb,   i_slot_of_laatste_koers,
                                    gv_terminalnummer,              v_sys_toeslag_optiemarg,  v_wegings_perc_long,
                                    v_wegings_perc_short,           r_od.be_fundcategory,     v_berekenen_afgeleide_effecten, 
                                    v_exas_berek_afgeleide_effect,  v_berekenen_bruto_margin, v_berek_bedrag_huidige_order,   
                                    0,                              v_calculation_context,    v_gebruikte_dekkingswaarde_ord, 
                                    v_dekkingswaarde_over);

             -- reseten van de te berekenen waarden of vast houden van de gegevens van het eerste leg van een combinatie order
             if r_od.kst_ordertype in ('COMB','VZCO') and r_od.kst_orderregel = 1
             then
                v_limietprijs_comb      := v_limietprijs;
                v_limiettoegestaan_comb := v_limiet_toegestaan;
                v_ordersoort_comb       := v_order_soort;
                v_symbool_comb          := r_od.kst_fondssymbool;
                v_optietype_comb        := r_od.kst_optietype_fnds;
                v_expiratiedatum_comb   := r_od.kst_expiratiedat_fnds;
                v_exerciseprijs_comb    := r_od.kst_exercisepr_fnds;
                v_fonds_muntsrt_comb    := r_od.be_muntsoort;
                v_transactie_soort_comb := r_od.kst_trans_indicatie;
                v_trans_tb_waarde_comb  := v_transactie_soort_tb_waarde;
                v_db_cr_indicatie_comb  := r_od.kst_dt_cr_spread;
             else
                v_limietprijs_comb      := 0;
                v_limiettoegestaan_comb := 0;
                v_ordersoort_comb       := ' ';
                v_symbool_comb          := ' ';
                v_optietype_comb        := ' ';
                v_expiratiedatum_comb   := '00000000';
                v_exerciseprijs_comb    := 0;
                v_fonds_muntsrt_comb    := ' ';
                v_transactie_soort_comb := ' ';
                v_trans_tb_waarde_comb  := 0;
                v_db_cr_indicatie_comb  := 0;
             end if;

          -- onderstaande end if is van de v_uitgangspunt_berekeningen <> 0
          end if;
       -- onderstaande end if is van v_reken_aantal <> 0
       end if;
    end loop;

end huidige_order_loop;
-- EINDE CODE PROCEDURE HUIDIGE_ORDER_LOOP


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_AANTAL:
-- bepalen van het aantal dat nog loopt voor een order.
-- als de order is gemuteerd dan worden ook enkele andere gegevens
-- mee teruggegeven.
procedure lopende_orders_aantal
(i_order_nummer               in  orders.ord_ordernummer%type
,i_order_regel                in  orders.ord_orderregel%type
,i_order_detailnummer         in  ordersdetaillering.orx_detailnummer%type
,i_order_status               in  orders.ord_status%type
,i_order_type                 in  orders.ord_ordertype%type
,i_order_keuze                in  orders.ord_keuze%type
,i_order_uitvoerstatus        in  orders.ord_uitvstatus%type
,i_order_transstatus          in  orders.ord_transstatus%type
,i_order_aantal               in  orders.ord_aantal%type
,i_order_effectiefbedrag      in  orders.ord_effectiefbedrag%type
,i_order_notabedrag           in  orders.ord_notabedrag%type
,i_order_depot                in  orders.ord_depot%type
,i_order_depot_reksrt         in  orders.ord_depotreksrt%type
,i_order_geldrek_muntsoort    in  orders.ord_geldrekvaluta%type
,i_relatienummer              in  clienten.cl_nummer%type  -- Dit is het relatienummer van de relatie waarvoor de VBR berekend wordt
,i_order_relatie              in  orders.ord_relatie%type  -- In verzamelorders is dit de verzamelrelatie
,i_belegg_opdr_herkomstcode   in  beleggingsopdracht_header.boh_herkomst%type
,i_order_herkomstcode         in  orders.ord_orderherkomst%type
,i_transactiesoort            in  orders.ord_transactiesoort%type
,i_fonds_muntsoort            in  beleggingsinstrument.be_muntsoort%type
,i_fonds_muntsrt_biedkoers    in  muntsoorten.mu_biedkoers%type
,i_fonds_muntsrt_laatkoers    in  muntsoorten.mu_laatkoers%type
,i_fonds_muntsrt_factor       in  muntsoorten.mu_factor%type
,i_fonds_muntsrt_reciproke    in  muntsoorten.mu_reciproke%type
,i_fonds_muntsrt_notatie      in  muntsoorten.mu_notatie%type
,i_orin_id_order              in  orders.ord_orin_id%type
,i_order_in_reservation       in  orders.ord_in_reservation%type
,o_reken_aantal               out orders.ord_aantal%type
,o_order_depot                out orders.ord_depot%type
,o_order_depot_reksrt         out orders.ord_depotreksrt%type
,o_order_geldrek_muntsoort    out orders.ord_geldrekvaluta%type
,o_order_effectiefbedrag      out orders.ord_effectiefbedrag%type
,o_order_notabedrag           out orders.ord_notabedrag%type
,o_transactiesoort            out orders.ord_transactiesoort%type
,o_m_aantal                   out ordermodificaties.orm_aantal%type
,o_m_order_soort              out ordermodificaties.orm_ordersoort%type
,o_m_limiet                   out ordermodificaties.orm_limiet%type
,o_m_provperceffwrd           out ordermodificaties.orm_provperceffwrd%type
,o_m_provkortingbv            out ordermodificaties.orm_provkortingbv%type
,o_m_provkortingperc          out ordermodificaties.orm_provkortingperc%type
,o_m_provisieps_bv            out ordermodificaties.orm_provisieps_bv%type
,o_m_mutkosten_btw_bv         out ordermodificaties.orm_mutkosten_btw_bv%type
,o_m_settlekosten_bv          out ordermodificaties.orm_settlekosten_bv%type
,o_mutatie_gevonden           out number
,o_bgs_opdracht_nummer        out beleggingsopdracht_header.boh_opdrachtnummer%type
,o_aantal_ord_bedrag_bgs      out number
,o_bedrag_ord_aantal_bgs      out number
,o_order_id                   out ordersdetaillering.orx_id%type
,o_orx_distributiekanaal      out ordersdetaillering.orx_distrib_kanaal%type
)

is

   v_transsoort_detl            ordersdetaillering.orx_transactiesoort%type      := ' ';
   v_geboekt_aantal             orders.ord_aantal%type                           := 0;
   v_aantal_transgemkt_detl     ordersdetaillering.orx_aantaltransgemkt%type     := 0;
   v_geboekt_effectiefbedrag    transakties.tr_notabedrag%type                   := 0;
   v_geboekt_notabedrag         transakties.tr_notabedrag%type                   := 0;
   v_orx_aantal_of_bedrag       ordersdetaillering.orx_aantal_of_bedrag%type     := ' ';
   v_orx_bedrag_soort           ordersdetaillering.orx_bedrag_soort%type         := ' ';
   v_rev_aantal_of_bedrag       revisie_detail.rvd_aantal_of_bedrag%type         := ' ';
   v_orin_id                    ordersdetaillering.orx_orin_id%type              := 0;
   v_orx_distrib_kanaal         ordersdetaillering.orx_distrib_kanaal%type       := 0;
   v_orx_in_reservation         ordersdetaillering.orx_in_reservation%type       := 0;
   v_m_order_depot              orderdetailmodificaties.orxm_depot%type          := ' ';
   v_m_order_depot_reksrt       orderdetailmodificaties.orxm_depotreksoort%type  := 0;
   v_m_order_geldrek_muntsoort  orderdetailmodificaties.orxm_geldrekvaluta%type  := ' ';
   v_processing_completed       ordersdetaillering.orx_processing_completed%type;
   v_totaal_uitgevoerd          ordersuitvoeringen.uit_aantal%type               := 0;
   v_tot_uitgevoerd_voor_trans  ordersuitvoeringen.uit_aantal%type               := 0;


begin
       if gv_debuggen = 1
       then
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure FIAT_ORDERS.lopende_orders_aantal');
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ontvangen gegevens   :');
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'relatienummer        : '||to_char(i_relatienummer)||' ; order relatie : '||to_char(i_order_relatie));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order depot          : '||i_order_depot||' ; order depot rekeningsoort : '||to_char(i_order_depot_reksrt));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer          : '||to_char(i_order_nummer)||' ; orderregel      : '||to_char(i_order_regel));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'orderdetailnummer    : '||to_char(i_order_detailnummer)||' ; order status : '||to_char(i_order_status));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order type           : '||i_order_type||' ; order keuze : ' ||i_order_keuze);
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'uitvoer status       : '||to_char(i_order_uitvoerstatus)||' ; trans status : '||to_char(i_order_transstatus));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order aantal         : '||to_char(i_order_aantal)||' ; transactiesoort : '||i_transactiesoort);
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag     : '||to_char(i_order_effectiefbedrag)||' ; notabedrag : '||to_char(i_order_notabedrag));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'beleg.opdr.herkomstc : '||i_belegg_opdr_herkomstcode||' ; order herkomstcode : '||i_order_herkomstcode);
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fonds muntsoort      : '||i_fonds_muntsoort||' ; fonds muntsoort notatie : '||to_char(i_fonds_muntsrt_notatie));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fonds munt biedkoers : '||to_char(i_fonds_muntsrt_biedkoers)||' ; fonds munt laatkoers : '||to_char(i_fonds_muntsrt_laatkoers));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fonds munt factor    : '||to_char(i_fonds_muntsrt_factor)||' ; fonds munt reciproke : '||to_char(i_fonds_muntsrt_reciproke));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'geldrek muntsoort    : '||i_order_geldrek_muntsoort);
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
       end if;

       -- In eerste instantie aannemen dat de transactie indicatie niet wijzigt
       o_transactiesoort       := i_transactiesoort;
       -- Er vanuit gaan dat het geen bgs order is
       o_bgs_opdracht_nummer   := 0;
       o_aantal_ord_bedrag_bgs := 0;
       o_bedrag_ord_aantal_bgs := 0;
       -- Verder zetten van enkele vlaggen:
       o_mutatie_gevonden      := 0;

       -- Er vanuit gaan dat de order geheel is uitgevoerd en alle transacties zijn aangemaakt als de transstatus 2 of 3 is
       -- De order hoeft dan ook niet verder in de bestedingsruimte mee te lopen.
       -- Output gegevens dan ook op 0 zetten of leeg maken..
       if i_order_transstatus in (2,3)
       then
          o_reken_aantal            := 0;
          o_order_depot             := ' ';
          o_order_depot_reksrt      := 0;
          o_order_geldrek_muntsoort := ' ';
          o_order_effectiefbedrag   := 0;
          o_order_notabedrag        := 0;
          o_transactiesoort         := ' ';
          o_m_aantal                := 0;
          o_m_order_soort           := ' ';
          o_m_limiet                := 0;
          o_m_provperceffwrd        := 0;
          o_m_provkortingbv         := 0;
          o_m_provkortingperc       := 0;
          o_m_provisieps_bv         := 0;
          o_m_mutkosten_btw_bv      := 0;
          o_m_settlekosten_bv       := 0;
          o_bgs_opdracht_nummer     := 0;
          o_aantal_ord_bedrag_bgs   := 0;
          o_bedrag_ord_aantal_bgs   := 0;

          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in het deel order_transstatus in (2,3): Output gegevens gereset');
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer : '||to_char(i_order_nummer)||' ; orderregel : '||to_char(i_order_regel));
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order aantal : '||to_char(i_order_aantal)||' ; reken aantal : '||to_char(o_reken_aantal));
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order notabedrag : '||to_char(o_order_notabedrag)||' ; order notabedrag in : '||to_char(i_order_notabedrag));
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effec. bedrag    : '||to_char(o_order_effectiefbedrag)||' ; effec. bedrag in : '||to_char(i_order_effectiefbedrag));
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
          end if;

       -- Voor de order moet bekeken worden of er nog een openstaand deel is  en zo ja hoeveel dan....
       else
          -- enkelvoudige en combinatie orders
          if i_order_type in ('BEDR','COMB','ENKL')
          then
             if gv_debuggen = 1
             then
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in het deel van de BEDR, COMB en ENKL order');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
             end if;

             -- Als de order al in de reserveringen is opgenomen, dan hier niets meer berekenen. Dus alls op 0 stellen
             if i_order_in_reservation = 1
             then
                o_reken_aantal          := 0;
                o_order_effectiefbedrag := 0;
                o_order_notabedrag      := 0;
             else
                -- Kijken of de order gemuteerd is, dan moeten namelijk extra gegevens worden bepaald waar ook later mee gerekend moet worden
                if i_order_status in (5,16) and i_order_type in ('COMB','ENKL') and i_order_keuze <> 'BEDR'
                then
                   -- er op voorhand vanuit gaan dat de mutatie gevonden wordt:
                   o_mutatie_gevonden     := 1;

                   begin
                      select m.orm_aantal,         m.orm_ordersoort,       m.orm_limiet,
                             m.orm_provperceffwrd, m.orm_provkortingbv,    m.orm_provkortingperc,
                             m.orm_provisieps_bv,  m.orm_mutkosten_btw_bv, m.orm_settlekosten_bv
                      into   o_m_aantal,           o_m_order_soort,        o_m_limiet,
                             o_m_provperceffwrd,   o_m_provkortingbv,      o_m_provkortingperc,
                             o_m_provisieps_bv,    o_m_mutkosten_btw_bv,   o_m_settlekosten_bv
                      from   ordermodificaties m
                      where  m.orm_ordernummer = i_order_nummer
                      and    m.orm_orderregel  = decode (i_order_type,'COMB',1,i_order_regel) ---> kan worden decode (i_order_type,'COMB',1,i_order_regel)
                      and    m.orm_aktief_jn   = 1;
                   exception
                      when no_data_found
                      then
                         o_mutatie_gevonden    := 0; -- mutatie is niet gevonden, dan de vlag ook weer uitzetten.
                   end;

                   if gv_debuggen = 1
                   then
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in het deel enkelvoudige gemuteerde orders');
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer         : '||to_char(i_order_nummer)||' ; orderregel : '||to_char(i_order_regel));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'mutatie gevonden    : '||to_char(o_mutatie_gevonden));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'gemuteerde gegevens : ');
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'aantal              : '||to_char(o_m_aantal)||' ; order soort : '||to_char(o_m_order_soort));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'limiet              : '||to_char(o_m_limiet)||' ; provisie perc. effect.waarde  : '||to_char(o_m_provperceffwrd));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provisie korting bv : '||to_char(o_m_provkortingbv)||' ; prov korting perc : '||to_char(o_m_provkortingperc));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provisie ps bv      : '||to_char(o_m_provisieps_bv)||' ; mutkosten btw bv  : '||to_char(o_m_mutkosten_btw_bv));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'settlementkosten bv : '||to_char(o_m_settlekosten_bv));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                   end if;
                end if;

                o_order_depot              := i_order_depot;
                o_order_depot_reksrt       := i_order_depot_reksrt;
                o_order_geldrek_muntsoort  := i_order_geldrek_muntsoort;

                -- Als de order is uitgevoerd, dan bepalen voor welk deel van de orderuitvoeringen daadwerkelijk transacties zijn aangemaakt
                if i_order_uitvoerstatus > 0
                then
                   geboekt_in_trans_bepalen (i_order_nummer,   i_order_regel,        i_relatienummer,           o_order_depot,       o_order_depot_reksrt,
                                             case when i_orin_id_order is null then 0 else i_orin_id_order end,
                                             v_geboekt_aantal, v_geboekt_notabedrag, v_geboekt_effectiefbedrag, v_totaal_uitgevoerd, v_tot_uitgevoerd_voor_trans);
                end if;

                -- het bepaalde uitgevoerde notabedrag staat in de muntsoort van de geldrekening.
                -- Deze muntsoort kan afwijken van de muntsoort van het fonds. Als deze afwijken dan deze eerst omrekenen
                if (i_order_keuze = 'BEDR' or i_order_type = 'BEDR') and v_geboekt_notabedrag <> 0 and v_geboekt_notabedrag is not null
                then
                   omrek_geboekt_notabedrag (i_order_nummer,            i_order_regel,           i_relatienummer,
                                             o_order_depot,             o_order_depot_reksrt,    i_fonds_muntsoort,
                                             i_fonds_muntsrt_reciproke, i_fonds_muntsrt_factor,  i_fonds_muntsrt_biedkoers,
                                             i_fonds_muntsrt_laatkoers, i_fonds_muntsrt_notatie, v_geboekt_notabedrag,
                                             v_geboekt_notabedrag);
                end if;

                -- de berekende gegevens teruggeven in de parameters:
                if i_order_status in (5,16) and o_mutatie_gevonden = 1
                then
                   o_reken_aantal          := o_m_aantal - nvl(v_geboekt_aantal,0);
                else
                   o_reken_aantal          := i_order_aantal - nvl(v_geboekt_aantal,0);
                end if;

                if o_reken_aantal < 0
                then
                   o_reken_aantal          := 0;
                end if;

                o_order_effectiefbedrag    := abs(i_order_effectiefbedrag) - abs(round(nvl(v_geboekt_effectiefbedrag,0),i_fonds_muntsrt_notatie));
                if o_order_effectiefbedrag < 0 or o_order_effectiefbedrag is null
                then
                   o_order_effectiefbedrag := 0;
                end if;

                o_order_notabedrag         := abs(i_order_notabedrag) - abs(round(nvl(v_geboekt_notabedrag,0),i_fonds_muntsrt_notatie));
                if o_order_notabedrag < 0
                then
                   o_order_notabedrag      := 0;
                end if;

                -- correctie voor bedrag orders als de uitvoerstatus >= 2 is en aantal uitgevoerd gelijk is aan aantal geboekt in de transactie
                if (i_order_keuze = 'BEDR' or i_order_type = 'BEDR') and i_order_uitvoerstatus >= 2
                    and v_geboekt_aantal = v_tot_uitgevoerd_voor_trans
                    and v_tot_uitgevoerd_voor_trans = v_totaal_uitgevoerd
                then
                   o_reken_aantal          := 0;
                   o_order_effectiefbedrag := 0;
                   o_order_notabedrag      := 0;
                end if;

                o_bgs_opdracht_nummer      := 0;     -- enkelvoudige orders komen niet uit de BGS
             end if;

             if gv_debuggen = 1
             then
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'tonen berekende gegevens enkl, comb en enkelvoudige bedr orders');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer           : '||to_char(i_order_nummer)||' ; orderregel : '||to_char(i_order_regel));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'teruggegeven gegevens : ');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'reken aantal          : '||to_char(o_reken_aantal)||' ; order geldrek muntsoort : '||o_order_geldrek_muntsoort);
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order dept            : '||o_order_depot||' ; order depot reksrt  : '||to_char(o_order_depot_reksrt));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'notabedrag            : '||to_char(o_order_notabedrag)||' ; effectief bedrag : '||to_char(o_order_effectiefbedrag));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'bgs opdracht nummer   : '||to_char(o_bgs_opdracht_nummer)||' ; in reservation : '||to_char(i_order_in_reservation));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
             end if;

          -- Bij verzamelorders zijn de aantallen en bedragen uit de order voor alle relaties uit de verzamelorder, dus niet alleen voor de gevraagde relatie
          -- relatie onderhanden moet ongelijk zijn aan de verzamelrelatie
          elsif i_order_type in ('FVRZ','VZCO','VBDR') and i_order_relatie <> i_relatienummer
          then
             if gv_debuggen = 1
             then
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in het deel van de FVRZ en VZCO order');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
             end if;

             begin
                -- bepalen van het aantal, depot en aantal uitgevoerd voor de relatie in de "normale" detaillering:
                select d.orx_aantal,              d.orx_depot,                d.orx_depotreksoort,
                       d.orx_notabedrag,          d.orx_effectiefbedrag,      d.orx_opdrachtnummer,
                       d.orx_transactiesoort,     d.orx_aantaltransgemkt,     d.orx_processing_completed,
                       d.orx_geldrekvaluta,       d.orx_aantal_of_bedrag,     d.orx_bedrag_soort,
                       d.orx_id,                  d.orx_orin_id,              nvl(d.orx_distrib_kanaal,0),
                       d.orx_in_reservation
                into   o_reken_aantal,            o_order_depot,              o_order_depot_reksrt,
                       o_order_notabedrag,        o_order_effectiefbedrag,    o_bgs_opdracht_nummer,
                       v_transsoort_detl,         v_aantal_transgemkt_detl,   v_processing_completed,
                       o_order_geldrek_muntsoort, v_orx_aantal_of_bedrag,     v_orx_bedrag_soort,
                       o_order_id,                v_orin_id,                  v_orx_distrib_kanaal,
                       v_orx_in_reservation
                from   ordersdetaillering d
                where  d.orx_ordernummer   = i_order_nummer
                and    d.orx_orderregel    = i_order_regel
                and    d.orx_detailnummer  = i_order_detailnummer;
             exception
                -- als de relatie in een mutatie is toegevoegd, dan zal bovenstaande selectie niets vinden en in de exception schieten
                when no_data_found
                then
                   o_reken_aantal            := 0;
                   o_order_depot             := ' ';
                   o_order_depot_reksrt      := 0;
                   o_order_geldrek_muntsoort := ' ';
                   o_order_notabedrag        := 0;
                   o_order_effectiefbedrag   := 0;
                   o_bgs_opdracht_nummer     := 0;
                   v_transsoort_detl         := ' ';
                   v_aantal_transgemkt_detl  := 0;
                   o_orx_distributiekanaal   := 0;
             end;

             -- Als het detail in reservering staat, dan hier niet mee tellen
             if v_orx_in_reservation = 1
             then
                o_reken_aantal          := 0;
                o_order_effectiefbedrag := 0;
                o_order_notabedrag      := 0;
             else

                -- Als de order gemuteerd is (status 5 of 16), dan hieronder de gegevens bepalen
                if i_order_status in (5,16) and i_order_keuze not in ('BEDR','VBDR')
                then
                   -- bekijken of de mutatie nog wel actief is
                   begin
                      select 1,                    o.orm_ordersoort,       o.orm_limiet,
                             o.orm_provperceffwrd, o.orm_provkortingbv,    o.orm_provkortingperc,
                             o.orm_provisieps_bv,  o.orm_mutkosten_btw_bv, o.orm_settlekosten_bv
                      into   o_mutatie_gevonden,   o_m_order_soort,        o_m_limiet,
                             o_m_provperceffwrd,   o_m_provkortingbv,      o_m_provkortingperc,
                             o_m_provisieps_bv,    o_m_mutkosten_btw_bv,   o_m_settlekosten_bv
                      from   ordermodificaties o
                      where  o.orm_ordernummer   = i_order_nummer
                      and    o.orm_orderregel    = i_order_regel
                      and    o.orm_aktief_jn     = 1;
                   exception
                   when no_data_found
                   then
                      o_m_order_soort       := ' ';
                      o_m_limiet            := 0;
                      o_m_provperceffwrd    := 0;
                      o_m_provkortingbv     := 0;
                      o_m_provkortingperc   := 0;
                      o_m_provisieps_bv     := 0;
                      o_m_mutkosten_btw_bv  := 0;
                      o_m_settlekosten_bv   := 0;
                      o_mutatie_gevonden    := 0; -- mutatie is niet gevonden, dan de vlag ook weer uitzetten.
                   end;

                   -- alleen de gegevens uit de mutatiedetaillering meenemen als de mutatie nog actief is
                   if o_mutatie_gevonden = 1
                   then
                      -- bepalen van het aantal, depot en depotrekeningsoort voor de relatie
                      select m.orxm_aantal, m.orxm_depot,    m.orxm_depotreksoort,   m.orxm_geldrekvaluta
                      into   o_m_aantal,    v_m_order_depot, v_m_order_depot_reksrt, v_m_order_geldrek_muntsoort
                      from   orderdetailmodificaties m
                      where  m.orxm_ordernummer      = i_order_nummer
                      and    m.orxm_orderregel       = i_order_regel
                      and    m.orxm_detailnummer     = i_order_detailnummer;
                      -- als het mutatierecords is gevonden, dan die gegevens gebruiken
                      if sql%found
                      then
                         o_reken_aantal             := o_m_aantal;
                         o_order_depot              := v_m_order_depot;
                         o_order_depot_reksrt       := v_m_order_depot_reksrt;
                         o_order_geldrek_muntsoort  := v_m_order_geldrek_muntsoort;
                      end if;
                   end if;

                   if gv_debuggen = 1
                   then
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in het deel gemuteerde verzamelorder');
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer         : '||to_char(i_order_nummer)||' ; orderregel : '||to_char(i_order_regel));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'mutatie gevonden    : '||to_char(o_mutatie_gevonden));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'gemuteerde gegevens : ');
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'aantal              : '||to_char(o_m_aantal)||' ; order soort : '||to_char(o_m_order_soort));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'limiet              : '||to_char(o_m_limiet)||' ; provisie perc. effect.waarde  : '||to_char(o_m_provperceffwrd));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provisie korting bv : '||to_char(o_m_provkortingbv)||' ; prov korting perc : '||to_char(o_m_provkortingperc));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provisie ps bv      : '||to_char(o_m_provisieps_bv)||' ; mutkosten btw bv  : '||to_char(o_m_mutkosten_btw_bv));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'settlementkosten bv : '||to_char(o_m_settlekosten_bv));
                      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                   end if;
                end if;  -- einde order is gemuteerd

                -- als de order (gedeeltelijk) is uitgevoerd kijken hoeveel voor de relatie al in transacties is opgenomen
                -- het aantaltransgemaakt uit de detaillering is niet meer voldoende nu de transacties in meerdere stappen gecreëerd worden.
                if i_order_uitvoerstatus > 0
                then
                   geboekt_in_trans_bepalen (i_order_nummer,   i_order_regel,        i_relatienummer,           o_order_depot,       o_order_depot_reksrt,
                                             case when v_orin_id is null then 0 else v_orin_id end,
                                             v_geboekt_aantal, v_geboekt_notabedrag, v_geboekt_effectiefbedrag, v_totaal_uitgevoerd, v_tot_uitgevoerd_voor_trans);
                end if;

                -- Bepalen of de onderliggende beleggingsopdracht of WM-opdracht een bedrag-opdracht is, die in een aantal order is weggeschreven
                -- Als dat zo is, dan moet toch het bedrag leidend zijn.
                if i_order_herkomstcode = 'BGSO'
                then
                   o_aantal_ord_bedrag_bgs := 0;
                   o_bedrag_ord_aantal_bgs := 0;

                   if v_orin_id <> 0
                   then
                      -- gegevens zijn vanuit de nieuwe createOrder service aangemaakt (WM/StarFund).
                      -- Als op het detail is aangegeven dat het een bedrag is, maar de verzamelorder is een aantal order:
                      if v_orx_aantal_of_bedrag = 'B' and i_order_keuze <> 'VBDR'
                      then
                         o_aantal_ord_bedrag_bgs := 1;
                         -- op deze plek ook nota of effectief bedrag goed zetten (op 0 zetten wat het niet is). Dit zorgt er ook voor
                         -- dat het uitgangspunt correct wordt bepaald (zie procedure uitgangspunt bepalen)
                         if v_orx_bedrag_soort = 'N'
                         then
                            o_order_effectiefbedrag := 0;
                         elsif v_orx_bedrag_soort = 'E'
                         then
                            o_order_notabedrag := 0;
                         end if;
                      -- Als op het detail is aangegeven dat het een aantal order is, maar de verzamelorder is een bedrag order
                      elsif v_orx_aantal_of_bedrag = 'A' and i_order_keuze = 'VBDR'
                      then
                         o_bedrag_ord_aantal_bgs := 1;
                      end if;

                      if gv_debuggen = 1
                      then
                         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In het deel van bepalen aantal of bedrag voor WM/StarFund opdrachten');
                         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                      end if;

                   -- Hier het deel voor BGS-opdrachten (met behulp van revisie details de gegevens achterhalen)
                   else
                      -- eerst bepalen of de het een aantal order met een aantal detail is of een bedrag order met een bedrag detail
                      -- dan geen verschil in werkwijze, anders wel gegevens omdraaien
                      begin
                         select r.rvd_aantal_of_bedrag
                         into   v_rev_aantal_of_bedrag
                         from   revisie_detail r, revisie_header h
                         where  r.rvd_relatienummer      = i_relatienummer
                         and    r.rvd_productnummer      = gv_rel_productnummer
                         and    r.rvd_volgnr_per_product = gv_rel_product_volgnr
                         and    r.rvd_ordernummer        = i_order_nummer
                         and    r.rvd_voorstelnummer     = h.rvh_voorstelnummer
                         and    h.rvh_opdrachtnummer     = o_bgs_opdracht_nummer;
                      exception
                         when no_data_found
                         then
                            begin
                               -- als bovenstaande select niets oplevert dan hier onder in de historische bestanden zoeken
                               select r.hrvd_aantal_of_bedrag
                               into   v_rev_aantal_of_bedrag
                               from   hist_revisie_detail r, hist_revisie_header h
                               where  r.hrvd_relatienummer      = i_relatienummer
                               and    r.hrvd_productnummer      = gv_rel_productnummer
                               and    r.hrvd_volgnr_per_product = gv_rel_product_volgnr
                               and    r.hrvd_ordernummer        = i_order_nummer
                               and    r.hrvd_voorstelnummer     = h.hrvh_voorstelnummer
                               and    h.hrvh_opdrachtnummer     = o_bgs_opdracht_nummer;
                               -- als ook deze zoekactie niets oplevert dan het veld leegmaken.
                            exception
                               when no_data_found
                               then
                               v_rev_aantal_of_bedrag := ' ';
                            end;
                      end;

                      -- Als in het revisie detail staat dat het om een bedrag detail gaat, maar de order is geen
                      -- bedrag verzamelorder, dan hier aangeven dat de aantal order toch als bedrag order behandeld moet worden.
                      if v_rev_aantal_of_bedrag = 'B' and i_order_keuze <> 'VBDR'
                      then
                         o_aantal_ord_bedrag_bgs := 1;
                      -- Als in het revisie detail staat dat het om een aantal detail gaat, maar de order is geen
                      -- aantal verzamelorder, dan hier aangeven dat de bedrag order toch als aantal order behandeld moet worden.
                      elsif v_rev_aantal_of_bedrag = 'A' and i_order_keuze = 'VBDR'
                      then
                         o_bedrag_ord_aantal_bgs := 1;
                      end if;

                      if gv_debuggen = 1
                      then
                         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In het deel van bepalen aantal of bedrag voor BGS-opdrachten');
                         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                      end if;
                   end if;
                end if;

                -- het bepaalde uitgevoerde notabedrag staat in de muntsoort van de geldrekening.
                -- Deze muntsoort kan afwijken van de muntsoort van het fonds. Als deze afwijken dan deze eerst omrekenen
                if (i_order_keuze = 'VBDR' or o_aantal_ord_bedrag_bgs = 1) and v_geboekt_notabedrag <> 0 and v_geboekt_notabedrag is not null
                then
                   omrek_geboekt_notabedrag (i_order_nummer,            i_order_regel,           i_relatienummer,
                                             o_order_depot,             o_order_depot_reksrt,    i_fonds_muntsoort,
                                             i_fonds_muntsrt_reciproke, i_fonds_muntsrt_factor,  i_fonds_muntsrt_biedkoers,
                                             i_fonds_muntsrt_laatkoers, i_fonds_muntsrt_notatie, v_geboekt_notabedrag,
                                             v_geboekt_notabedrag);
                end if;

                -- zetten van de output parameters
                -- eerst bepalen of er nog een lopend aantal over is door te kijken of een order uitgevoerd is en wat er dan als totaal uitgevoerd en
                -- geboekt is gevonden in de transacties
                if v_processing_completed = 1 and i_order_uitvoerstatus >= 1
                   and (v_aantal_transgemkt_detl = v_geboekt_aantal or v_orin_id <> 0 and v_geboekt_aantal <> 0)
                then
                   o_reken_aantal          := 0;
                   o_order_notabedrag      := 0;
                   o_order_effectiefbedrag := 0;
                -- de order is nog niet volledig uitgevoerd
                else
                   o_reken_aantal := o_reken_aantal - v_geboekt_aantal;

                   if o_reken_aantal < 0
                   then
                      o_reken_aantal := 0;
                   end if;

                   o_order_effectiefbedrag := abs(nvl(o_order_effectiefbedrag,0)) - abs(round(nvl(v_geboekt_effectiefbedrag,0),i_fonds_muntsrt_notatie));
                   if o_order_effectiefbedrag < 0
                   then
                      o_order_effectiefbedrag := 0;
                   end if;

                   o_order_notabedrag := abs(nvl(o_order_notabedrag,0)) - abs(round(nvl(v_geboekt_notabedrag,0),i_fonds_muntsrt_notatie));
                   if o_order_notabedrag < 0
                   then
                      o_order_notabedrag := 0;
                   end if;

                   -- Als het geen bedrag order is of als het een aantal detail is bij een bedrag order, dan hier het effectief bedrag en notabedrag op 0 zetten
                   if i_order_keuze not in ('BEDR','VBDR') and i_order_type <> 'BEDR'
                      and
                      o_aantal_ord_bedrag_bgs <> 1  -- het is een aantal order en volgens de details is het ook een aantal
                      or
                      o_bedrag_ord_aantal_bgs = 1   -- het is wel een bedrag order, maar volgens de details een toch een aantal
                   then
                      o_order_effectiefbedrag := 0;
                      o_order_notabedrag      := 0;
                   end if;
                end if;

                if v_transsoort_detl <> ' '
                then
                   o_transactiesoort := v_transsoort_detl;
                end if;

                if v_orx_distrib_kanaal <> 0 and v_orx_distrib_kanaal is not null
                then
                   o_orx_distributiekanaal := v_orx_distrib_kanaal;
                else
                   o_orx_distributiekanaal := 0;
                end if;

             end if;

             if gv_debuggen = 1
             then
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'tonen berekende gegevens verzamel orders');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer           : '||to_char(i_order_nummer)||' ; orderregel : '||to_char(i_order_regel));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'teruggegeven gegevens : ');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'reken aantal          : '||to_char(o_reken_aantal)||' ; order geldrek valuta : '||o_order_geldrek_muntsoort);
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order dept            : '||o_order_depot||' ; order depot reksrt  : '||to_char(o_order_depot_reksrt));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'notabedrag            : '||to_char(o_order_notabedrag)||' ; effectief bedrag : '||to_char(o_order_effectiefbedrag));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'bgs opdracht nummer   : '||to_char(o_bgs_opdracht_nummer)||' ; in reservation : '||to_char(v_orx_in_reservation));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
             end if;

          end if;  -- Einde enkelvoudige / verzamelorder
       end if; -- Einde order transstatus in (2,3) / nog transacties aan te maken

end lopende_orders_aantal;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_AANTAL


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_BEREKEN:
-- in deze procedure worden de diverse onderdelen berekend:
-- geschat notabedrag, marginbedrag, dekkingswaarde, lopend orderbedrag
procedure lopende_orders_bereken
(i_ordernummer                      in      kosten_werkbestand.kst_ordernummer%type
,i_orderregel                       in      kosten_werkbestand.kst_orderregel%type
,i_orderdetailnummer                in      kosten_werkbestand.kst_detailnummer%type
,i_uitgangspunt_berekeningen        in      number
,i_symbool_comb                     in      kosten_werkbestand.kst_fondssymbool%type
,i_optietype_comb                   in      kosten_werkbestand.kst_optietype_fnds%type
,i_expiratiedatum_comb              in      kosten_werkbestand.kst_expiratiedat_fnds%type
,i_exerciseprijs_comb               in      kosten_werkbestand.kst_exercisepr_fnds%type
,i_fonds_muntsrt_comb               in      beleggingsinstrument.be_muntsoort%type
,i_trans_tb_waarde_comb             in      kosten_werkbestand.kst_trans_indicatie_w%type
,i_ordersoort_comb                  in      kosten_werkbestand.kst_order_soort%type
,i_transactie_soort_comb            in      kosten_werkbestand.kst_trans_indicatie%type
,i_limietprijs_comb                 in      kosten_werkbestand.kst_trans_prijs%type
,i_db_cr_indicatie                  in      orders.ord_dt_cr_spread%type
,i_slot_of_laatste_koers            in      varchar2
,i_terminalnummer                   in      werkbestand.wk_terminal%type
,i_sys_toeslag_optiemarg            in      tabelgegevens.tb_waarde%type
,i_wegings_perc_long                in      wegingsfactoren.wg_interne_perc%type
,i_wegings_perc_short               in      wegingsfactoren.wg_intern_short_perc%type
,i_fundcategory                     in      beleggingsinstrument.be_fundcategory%type
,i_berekenen_afgeleide_effecten     in      order_enkel_transtype.oet_afgeleide_effecten%type
,i_exas_berek_afgeleide_effect      in      order_enkel_transtype.oet_afgeleide_effecten%type
,i_berekenen_bruto_margin           in      order_enkel_transtype.oet_bruto_margin%type
,i_berekenen_bedrag_huidige_ord     in      order_enkel_transtype.oet_bedrag_huidige_o%type
,i_bgs_koop_order_op_0_zetten       in      number
,i_trans_context                    in      contextcalculationrules.cxcr_context%type
,io_gebruikte_dekkingsw_ord         in out  positie_werkbestand.pwb_port_waarde_rapv%type
,io_dekkingswaarde_over             in out  positie_werkbestand.pwb_port_waarde_rapv%type
)

is

   v_relatienummer                    kosten_werkbestand.kst_relatie_nummer%type;
   v_order_depot                      kosten_werkbestand.kst_depot%type;
   v_order_depot_reksoort             kosten_werkbestand.kst_depotreksrt%type;

   v_notabedrag                       kosten_werkbestand.kst_notabedrag%type;
   v_dekkingswaarde                   kosten_werkbestand.kst_dekkingswaarde%type;
   v_lopend_bedrag                    kosten_werkbestand.kst_lopend_bedrag%type;
   v_margin_bedrag                    kosten_werkbestand.kst_marginbedrag%type;
   v_margin_effect_bedrag             kosten_werkbestand.kst_marginbedrag%type;
   v_effectief_bedrag_relatieval      kosten_werkbestand.kst_effect_bedrag_rv%type;
   v_effectief_bedrag_transval        kosten_werkbestand.kst_effect_bedrag_rv%type;
   v_provisie                         kosten_werkbestand.kst_provisie_bedrag%type;
   v_kost_corr                        kosten_werkbestand.kst_kost_corr_doorb%type;
   v_effectief_bedrag_bv              kosten_werkbestand.kst_effect_bedrag_bv%type;
   v_lopend_bedrag_rekv               kosten_werkbestand.kst_lopend_bedrag_rekv_sl%type;
   v_effectief_bedrag_rekv            kosten_werkbestand.kst_effect_bedrag_rekv_sl%type;
   v_notabedrag_rekv                  kosten_werkbestand.kst_notabedrag_rekv_sl%type;
   v_dekkingswaarde_rekv              kosten_werkbestand.kst_dekkingswaarde_rekv_sl%type;
   v_marginbedrag_rekv                kosten_werkbestand.kst_marginbedrag_rekv_sl%type;
   v_margin_effect_bedrag_rekv        kosten_werkbestand.kst_marginbedrag_rekv_sl%type;

   v_notabedrag_comb                  kosten_werkbestand.kst_notabedrag%type;
   v_dekkingswaarde_comb              kosten_werkbestand.kst_dekkingswaarde%type;
   v_margin_comb                      kosten_werkbestand.kst_marginbedrag%type;
   v_lopend_bedrag_comb               kosten_werkbestand.kst_lopend_bedrag%type;
   v_provisie_comb                    kosten_werkbestand.kst_provisie_bedrag%type;
   v_kost_corr_comb                   kosten_werkbestand.kst_kost_corr_doorb%type;
   v_effectief_bedrag_relval_comb     kosten_werkbestand.kst_effect_bedrag_rv%type;
   v_effectief_bedrag_bv_comb         kosten_werkbestand.kst_effect_bedrag_bv%type;
   v_lopend_bedrag_rekv_comb          kosten_werkbestand.kst_lopend_bedrag_rekv_sl%type;
   v_effectief_bedrag_rekv_comb       kosten_werkbestand.kst_effect_bedrag_rekv_sl%type;
   v_notabedrag_rekv_comb             kosten_werkbestand.kst_notabedrag_rekv_sl%type;
   v_dekkingswaarde_rekv_comb         kosten_werkbestand.kst_dekkingswaarde_rekv_sl%type;
   v_marginbedrag_rekv_comb           kosten_werkbestand.kst_marginbedrag_rekv_sl%type;

   v_fondssymbool                     kosten_werkbestand.kst_fondssymbool%type;
   v_optietype                        kosten_werkbestand.kst_optietype_fnds%type;
   v_expiratiedatum                   kosten_werkbestand.kst_expiratiedat_fnds%type;
   v_exerciseprijs                    kosten_werkbestand.kst_exercisepr_fnds%type;
   v_fonds_muntsoort                  kosten_werkbestand.kst_trans_muntsrt%type;
   v_fonds_nominale_waarde            kosten_werkbestand.kst_fnds_nominaal%type;
   v_fonds_ex_as_factor               kosten_werkbestand.kst_fnds_ex_ass_fac%type;
   v_fonds_be_bi_nummer               kosten_werkbestand.kst_bi_nummer%type;
   v_fonds_prijs_factor               kosten_werkbestand.kst_prijs_factor_fnds%type;
   v_fonds_aantal_cijfers_display     kosten_werkbestand.kst_aantal_cijfers_disp%type;
   v_fonds_volgnummer                 kosten_werkbestand.kst_fund_id%type;
   v_fonds_omw_factor                 kosten_werkbestand.kst_omw_factor_fnds%type;
   v_fonds_beursnummer                kosten_werkbestand.kst_beursnummer%type;
   v_reffondssymbool                  kosten_werkbestand.kst_ref_fondssymbool%type;
   v_ref_fonds_be_bi_nummer           kosten_werkbestand.kst_ref_fnds_bi_nr%type;
   v_ref_fonds_prijs_factor           kosten_werkbestand.kst_ref_fnds_prijs_f%type;
   v_transactie_soort                 kosten_werkbestand.kst_trans_indicatie%type;
   v_transactie_soort_tb_waarde       kosten_werkbestand.kst_trans_indicatie_w%type;
   v_eind_positie_order               kosten_werkbestand.kst_eind_pos_eff%type             := 0;
   v_begin_positie_order              kosten_werkbestand.kst_begin_pos_eff%type            := 0;
   v_reken_aantal                     kosten_werkbestand.kst_trans_aantal%type             := 0;
   v_prod_geblok_aantal               kosten_werkbestand.kst_trans_aantal%type             := 0;
   v_munt_notatie                     muntsoorten.mu_notatie%type;
   v_ordertype                        kosten_werkbestand.kst_ordertype%type;
   v_order_soort                      kosten_werkbestand.kst_order_soort%type;
   v_order_keuze                      kosten_werkbestand.kst_order_keuze%type;
   v_order_ext_refentie               orders.ord_externe_referentie%type;
   v_rekening_muntsoort               kosten_werkbestand.kst_rel1_rek2_munts%type;

   v_ca_fondssymbool                  productconversies.capc_fondssymbool%type;
   v_ca_actiedatum                    productconversies.capc_actiedatum%type;
   v_ca_conversiesoort                productconversies.capc_conversiesoort%type;
   v_ca_id                            productconversies.capc_id%type;
   v_ca_aantal                        productconversies.capc_aantal%type;
   v_ca_toewijzingspercentage         productconversies.capc_toewijzingspercentage%type;
   v_ca_verrekenbedrag                productconversies.capc_verrekenbedrag%type;
   v_ca_verrekenbedrag_mntsrt         productconversies.capc_verrekenbedrag_muntsoort%type;
   v_ca_verrkbedrag_mntsrt_factor     muntsoorten.mu_factor%type;
   v_ca_verrkbedrag_mntsrt_bkoers     muntsoorten.mu_biedkoers%type;
   v_ca_verrkbedrag_mntsrt_mkoers     muntsoorten.mu_middenkoers%type;
   v_ca_verrkbedrag_mntsrt_lkoers     muntsoorten.mu_laatkoers%type;
   v_ca_verrkbedrag_mntsrt_recipr     muntsoorten.mu_reciproke%type;
   v_ca_verrkbed_mntsrt_notatie       muntsoorten.mu_notatie%type;
   v_ca_transactiesoort               productconversiesoorten.cacs_transactiesoort%type;
   v_ca_provisie_onderdrukken         productconversiesoorten.cacs_provisie_onderdrukken%type;
   v_ca_grondslag_aanwezig            number(2);
   v_ca_effectief_bedrag              kosten_werkbestand.kst_effect_bedrag_rv%type;
   v_ca_notabedrag_relval             kosten_werkbestand.kst_notabedrag%type;
   v_ca_effectief_bedrag_bv           kosten_werkbestand.kst_effect_bedrag_bv%type;
   v_ca_dekkingswaarde_relval         kosten_werkbestand.kst_dekkingswaarde%type;

   v_gebruikte_dekkingswaarde_pos     positie_werkbestand.pwb_dekk_waarde_rapv%type;
   v_wegings_factor_gebruikt          wegingsfactoren.wg_interne_perc%type;
   v_bied_koers_fonds                 fn_quotes_vw.quot_bied%type;
   v_laat_koers_fonds                 fn_quotes_vw.quot_laat%type;
   v_koers_fonds                      fn_quotes_vw.quot_bied%type;
   v_afwijkende_koers_gebruiken       number(1);
   v_te_gebruiken_koers_fonds         fn_quotes_vw.quot_bied%type;
   v_correctie_limietprijs            number(1)                                           := 0;
   v_wegingsfactor_long               wegingsfactoren.wg_interne_perc%type;
   v_wegingsfactor_short              wegingsfactoren.wg_intern_short_perc%type;

   v_bied_koers_comb                  fn_quotes_vw.quot_bied%type;
   v_laat_koers_comb                  fn_quotes_vw.quot_laat%type;
   v_koers_comb                       fn_quotes_vw.quot_bied%type;
   v_te_gebruiken_koers_comb          fn_quotes_vw.quot_bied%type;

   v_dummy_num                        kosten_werkbestand.kst_notabedrag%type;
   v_nb_verk_als_koop_behandelen      number(1)                                            := 0;


begin
   select k.kst_relatie_nummer,    k.kst_depot,                    k.kst_depotreksrt,
          k.kst_fondssymbool,      k.kst_optietype_fnds,           k.kst_expiratiedat_fnds,
          k.kst_exercisepr_fnds,   k.kst_trans_indicatie,          k.kst_trans_indicatie_w,
          k.kst_eind_pos_eff,      k.kst_begin_pos_eff,            k.kst_fnds_ex_ass_fac,
          k.kst_trans_aantal,      k.kst_ordertype,                k.kst_trans_muntsrt,
          k.kst_ref_fondssymbool,  k.kst_prijs_factor_fnds,        k.kst_order_soort,
          k.kst_bi_nummer,         k.kst_order_keuze,              k.kst_externe_referentie,
          k.kst_fnds_nominaal,     k.kst_aantal_cijfers_disp,      k.kst_fund_id,
          k.kst_rel1_rek2_munts,   k.kst_omw_factor_fnds,          k.kst_beursnummer,
          f.fimu_notatie
   into   v_relatienummer,         v_order_depot,                  v_order_depot_reksoort,
          v_fondssymbool,          v_optietype,                    v_expiratiedatum,
          v_exerciseprijs,         v_transactie_soort,             v_transactie_soort_tb_waarde,
          v_eind_positie_order,    v_begin_positie_order,          v_fonds_ex_as_factor,
          v_reken_aantal,          v_ordertype,                    v_fonds_muntsoort,
          v_reffondssymbool,       v_fonds_prijs_factor,           v_order_soort,
          v_fonds_be_bi_nummer,    v_order_keuze,                  v_order_ext_refentie,
          v_fonds_nominale_waarde, v_fonds_aantal_cijfers_display, v_fonds_volgnummer,
          v_rekening_muntsoort,    v_fonds_omw_factor,             v_fonds_beursnummer,
          v_munt_notatie
   from   kosten_werkbestand k, fiat_muntsoorten f
   where  k.kst_ordernummer   = i_ordernummer
   and    k.kst_orderregel    = i_orderregel
   and    k.kst_detailnummer  = i_orderdetailnummer
   and    k.kst_trans_muntsrt = f.fimu_code;

   v_notabedrag                       := 0;
   v_ca_notabedrag_relval             := 0;
   v_dekkingswaarde                   := 0;
   v_margin_bedrag                    := 0;
   v_lopend_bedrag                    := 0;
   v_notabedrag_comb                  := 0;
   v_dekkingswaarde_comb              := 0;
   v_margin_comb                      := 0;
   v_lopend_bedrag_comb               := 0;
   v_provisie_comb                    := 0;
   v_kost_corr_comb                   := 0;
   v_effectief_bedrag_bv_comb         := 0;
   v_effectief_bedrag_relval_comb     := 0;

   v_gebruikte_dekkingswaarde_pos := 0;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in de procedure FIAT_ORDERS.lopende_orders_bereken');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer           : '||to_char(i_ordernummer)||' ; orderregel : '||to_char(i_orderregel));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order detailnummer    : '||to_char(i_orderdetailnummer)||' ; ordertype : '||v_ordertype);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fondssymbool          : '||v_fondssymbool||' ; optietype : '||v_optietype);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'expiratiedatum        : '||v_expiratiedatum||' ; exerciseprijs : '||to_char(v_exerciseprijs));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'transsoort tb waarde  : '||to_char(v_transactie_soort_tb_waarde)||' ; relatienummer : '||to_char(v_relatienummer));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'eind pos order        : '||to_char(v_eind_positie_order)||' ; begin positie order : '||to_char(v_begin_positie_order));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'munt notatie          : '||to_char(v_munt_notatie)||' ; transactiesoort : '||v_transactie_soort);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'rekenaantal           : '||to_char(v_reken_aantal)||' ; bgs koop order op 0 zetten : '||to_char(i_bgs_koop_order_op_0_zetten));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'transactie context    : '||i_trans_context);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

   -- Verwisselingsorders wijken erg af van de "normale" manier van berekenen
   -- Deze worden dus apart afgehandeld
   if v_transactie_soort = 'OMWL' and v_order_keuze = 'WISO'
   then
      -- Voor het fonds uit de order geldt:
      -- Dit fonds verdwijnt uit de positie
      -- Eventueel is geld bij betrokken (verkrijgen/betalen)
      -- Als transactiesoort in de order is OMWL opgenomen. De transactiesoort die uiteindelijk in de transactie komt is V of L
      -- Als er een verrekenbedrag is, dan is dat koers voor het effectiefbedrag. De koers voor de dekkingswaarde is wel de beurskoers

      -- Met behulp van het CA dossiernummer zijn een aantal productconversiegegevens op te halen
      select p.capc_fondssymbool,             p.capc_actiedatum,            p.capc_conversiesoort,
             p.capc_aantal,                   p.capc_toewijzingspercentage, p.capc_verrekenbedrag,
             p.capc_verrekenbedrag_muntsoort, p.capc_id,
             s.cacs_transactiesoort,          s.cacs_provisie_onderdrukken
      into   v_ca_fondssymbool,               v_ca_actiedatum,              v_ca_conversiesoort,
             v_ca_aantal,                     v_ca_toewijzingspercentage,   v_ca_verrekenbedrag,
             v_ca_verrekenbedrag_mntsrt,      v_ca_id,
             v_ca_transactiesoort,            v_ca_provisie_onderdrukken
      from   productconversies p, productconversiesoorten s
      where  p.capc_dossiernummer  = v_order_ext_refentie
      and    p.capc_conversiesoort = s.cacs_conversiesoort;

      -- aanpassen van het rekenaantal aan het toewijzingsprecentage:
      v_reken_aantal := v_reken_aantal * (case when v_ca_toewijzingspercentage = 0 then 1 else v_ca_toewijzingspercentage/100 end);
      -- fixen naar gehelen:
      v_reken_aantal := trunc(v_reken_aantal,0);

      -- Kijken of voor het fonds binnen de productconversie ook grondslagen aanwezig zijn:
      begin
          select 1
          into   v_ca_grondslag_aanwezig
          from   tax_base_amount t
          where  t.tba_capc_id          = v_ca_id
          and    t.tba_be_id            = v_fonds_volgnummer
          and    t.tba_base_amount_from <> 0
          and    rownum                 <= 1;
      exception
         when no_data_found
         then
            v_ca_grondslag_aanwezig := 0;
      end;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In het productconversie verwisselingsorder deel...');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ca fondssymbool : '||v_ca_fondssymbool||' ; ca actiedatum : '||v_ca_actiedatum);
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ca conversiesoort : '||to_char(v_ca_conversiesoort)||' ; ca aantal : '||to_char(v_ca_aantal));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ca toewijzingspercentage : '||to_char(v_ca_toewijzingspercentage)||' ; ca verrekenbedrag : '||to_char(v_ca_verrekenbedrag));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ca verrekenbedrag muntsoort : '||v_ca_verrekenbedrag_mntsrt||' ; ca transactiesoort : '||to_char(v_ca_transactiesoort));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ca provisie onderdrukken : '||to_char(v_ca_provisie_onderdrukken)||' ; reken aantal : '||to_char(v_reken_aantal));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ca grondslag aanwezig : '||to_char(v_ca_grondslag_aanwezig));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
      end if;

      -- Er valt alleen een notabedrag te berekenen als:
      -- A. het verrekenbedrag <> 0 is (dit kan zowel positief als negatief zijn: - --> klant betaald; + --> klant ontvangt)
      -- of
      -- B. er zijn bij belastingen afwijkende grondslagen opgegeven (en dan kun je daarmee een "effectief bedrag" berekenen om de bijbehorende belasting te berekenen

      if v_ca_verrekenbedrag <> 0 or v_ca_grondslag_aanwezig <> 0
      then
         -- bepalen van de valutagegevens voor de verrekenbedrag muntsoort
         FIAT_ALGEMEEN.valutagegevens_bepalen (v_ca_verrekenbedrag_mntsrt,     gv_relatie_pr_id,               gv_relatie_ppr_id,              gv_systspreadcodecategorie,
                                               gv_bank2mrktqchangedate,        gv_debuggen,                    gv_debug_user,                  v_ca_verrkbedrag_mntsrt_bkoers,
                                               v_ca_verrkbedrag_mntsrt_mkoers, v_ca_verrkbedrag_mntsrt_lkoers, v_ca_verrkbedrag_mntsrt_factor, v_ca_verrkbedrag_mntsrt_recipr,
                                               v_ca_verrkbed_mntsrt_notatie);

        -- het notabedrag berekenen met behulp van het verrekenbedrag of doorgeven dat er tax berekend moet worden
        -- omdat de berekeningen niet plaats vinden met behulp van transactiesoort OMWL wordt eerst het transactiesoort omgezet en vastgelegd.
        if v_ca_transactiesoort = 2
        then
           v_transactie_soort := 'V';
        else
           v_transactie_soort := 'L';
        end if;

        set_afwijkende_ordergegevens (v_transactie_soort,         i_ordernummer,                  i_orderregel,             i_orderdetailnummer,
                                      v_fondssymbool,             v_optietype,                    v_expiratiedatum,         v_exerciseprijs,
                                      v_fonds_be_bi_nummer,       v_fonds_ex_as_factor,           v_fonds_prijs_factor,     v_fonds_omw_factor,
                                      v_fonds_beursnummer,        v_fonds_aantal_cijfers_display, v_fonds_volgnummer,       v_fonds_muntsoort,
                                      v_reffondssymbool,          v_ref_fonds_be_bi_nummer,       v_ref_fonds_prijs_factor, v_reken_aantal,
                                      v_ca_provisie_onderdrukken, case when v_ca_verrekenbedrag < 0 then 1 else 0 end,      v_transactie_soort_tb_waarde);

        FIAT_NOTABEDRAG.notabedrag_bereken( i_ordernummer,             i_orderregel,                i_orderdetailnummer,      gv_order_orx_id,
                                            gv_rel_productnummer,      gv_rel_product_volgnr,       i_slot_of_laatste_koers,  1,
                                            abs(v_ca_verrekenbedrag),  i_uitgangspunt_berekeningen, 0,                        0,
                                            gv_instellingen,           gv_systspreadcodecategorie,  gv_bank2mrktqchangedate,
                                            i_trans_context,           i_terminalnummer,            gv_belgisch_spaar_product,
                                            1,                         v_ca_id,                     gv_legal_entity_type,     gv_eor_kenmerk_id,
                                            i_fundcategory,            v_dummy_num,                 v_dummy_num,              v_dummy_num);

        -- Op dit punt zijn een aantal gegevens berekend. Deze ophalen om te kunnen gebruiken in totaaltellingen:
        select k.kst_effect_bedrag_bv,   k.kst_effect_bedrag_rv, k.kst_notabedrag
        into   v_ca_effectief_bedrag_bv, v_ca_effectief_bedrag,  v_ca_notabedrag_relval
        from   kosten_werkbestand k
        where  k.kst_ordernummer  = i_ordernummer
        and    k.kst_orderregel   = i_orderregel
        and    k.kst_detailnummer = i_orderdetailnummer;
        
        -- Teken goed zetten als het berekende notabedrag het verkeede teken heeft (alleen bij negatief verrekenbedrag (= te betalen))
        if v_ca_verrekenbedrag < 0 and v_ca_notabedrag_relval > 0
        then 
           v_ca_notabedrag_relval := -1 * v_ca_notabedrag_relval;
        end if;
      else
         -- Als er geen rekenbedrag of tax is, dan bedragen op 0 zetten.
         v_ca_effectief_bedrag    := 0;
         v_ca_effectief_bedrag_bv := 0;
         v_ca_notabedrag_relval   := 0;
      end if;

      -- Aansluitend het dekkingswaarde effect berekenen voor het fonds dat uit positie gaat.
      -- Maar alleen als de berekening voor VV-fondsen niet moet worden onderdrukt.
      -- Beginnen met de start situatie bepalen
      if gv_relatie_onld_omsch <> ' '
         and
         (gv_suppressFCDekkwaarde = 0 or gv_basis_valuta = v_fonds_muntsoort)
      then
         lopende_orders_dekw_fnds_berek (v_relatienummer,               v_order_depot,              v_order_depot_reksoort,   1,
                                         ' ',                           v_fondssymbool,             v_transactie_soort,       v_transactie_soort_tb_waarde,
                                         v_reken_aantal,                1,                          v_order_ext_refentie,     v_wegingsfactor_long,
                                         v_wegingsfactor_short,         v_begin_positie_order,      v_eind_positie_order,     v_reken_aantal,
                                         v_effectief_bedrag_relatieval, v_effectief_bedrag_transval);

         lopende_orders_dekw (gv_relatie_onld_omsch,       gv_relatie_onld_perc, v_fondssymbool,             v_optietype,
                              v_expiratiedatum,            v_exerciseprijs,      v_fonds_muntsoort,          v_transactie_soort_tb_waarde,
                              v_order_soort,               v_wegingsfactor_long, v_wegingsfactor_short,      i_fundcategory, 
                              v_effectief_bedrag_transval, v_reken_aantal,       v_begin_positie_order,      v_eind_positie_order,      
                              v_fonds_be_bi_nummer,        i_trans_context,      v_ca_dekkingswaarde_relval, v_wegings_factor_gebruikt);

      else
         v_ca_dekkingswaarde_relval := 0;
         v_wegings_factor_gebruikt  := 0;
      end if;

      -- ter debug de gegevens van dit fonds wegschrijven in het werkbestand
      insert into werkbestand w
      (w.wk_terminal,         w.wk_soort,             w.wk_categorie_1,
       w.wk_categorie_2,      w.wk_categorie_3,       w.wk_waarde_1,
       w.wk_waarde_2,         w.wk_waarde_3,          w.wk_waarde_4)
      values
      (gv_terminalnummer,     'ORDC',                 to_char(i_ordernummer,'99999999')||' '||to_char(i_orderregel,'9999'),
       'Hoofdfonds',          v_fondssymbool,         v_reken_aantal,
       v_ca_effectief_bedrag, v_ca_notabedrag_relval, v_ca_dekkingswaarde_relval);

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Na de berekeningen voor het OMWL-fonds dat uit positie gaat');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ca effectief bedrag : '||to_char(v_ca_effectief_bedrag)||' '||' ; notabedrag : '||to_char(v_ca_notabedrag_relval));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effect bedrag relval : ' ||to_char(v_effectief_bedrag_relatieval)||' '||
                                                 ' ; effectief bedrag transval :'||to_char(v_effectief_bedrag_transval));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ca dekkingswaarde relval : '||to_char(v_ca_dekkingswaarde_relval)||' '||
                                                 ' ; wegingsfactor gebruikt : '||to_char(v_wegings_factor_gebruikt));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
      end if;

      -- Bij een omwisseling via D/L wordt middels Deponeringen nieuwe fondsen in positie verkregen. Hiervoor door de te verkrijgen fondsen lopen
      declare
         v_caTo_reken_aantal             kosten_werkbestand.kst_trans_aantal%type;
         v_caTo_effectief_bedrag_relval  kosten_werkbestand.kst_effect_bedrag_rv%type;   -- variabele voor dekkingswaarde berekening
         v_caTo_effectief_bedrag_trval   kosten_werkbestand.kst_effect_bedrag_rv%type;   -- variabele voor dekkingswaarde berekening
         v_caTo_effectief_bedrag_rv      kosten_werkbestand.kst_effect_bedrag_rv%type;   -- variabele afgeleidt uit de notabedrag berekening
         v_caTo_effectief_bedrag_bv      kosten_werkbestand.kst_effect_bedrag_bv%type;   -- variabele afgeleidt uit de notabedrag berekening
         v_caTo_notabedrag_relval        kosten_werkbestand.kst_notabedrag%type;

         v_caTo_dekkingswaarde_relval    kosten_werkbestand.kst_dekkingswaarde%type;
         v_caTo_wegingsfactor_gebruikt   wegingsfactoren.wg_interne_perc%type;
         v_caTo_wegingsfactor_long       wegingsfactoren.wg_interne_perc%type;
         v_caTo_wegingsfactor_short      wegingsfactoren.wg_intern_short_perc%type;
         v_caTo_begin_positie            kosten_werkbestand.kst_begin_pos_eff%type;
         v_caTo_eind_positie             kosten_werkbestand.kst_eind_pos_eff%type;

         cursor pc is
            select p.cavp_nieuw_fondssymbool,       p.cavp_aantal_nieuwe_fonds,  p.cavp_verrekenbedrag,
                   p.cavp_verrekenbedrag_muntsoort, b.be_prijs_factor,           b.be_bi_nummer,
                   b.be_nominaal,                   b.be_aantal_cijfers_display, b.be_muntsoort,
                   b.be_volgnummer,                 b.be_exass_factor,           b.be_bv_beurs,
                   b.be_aantal_te_ontvangen,        b.be_aantal_in_te_leveren,   b.be_referentiesymbool,
                   r.be_bi_nummer as ref_bi_nummer, r.be_prijs_factor as ref_prijs_factor
            from   productconversie_ontvangsten p, beleggingsinstrument b, beleggingsinstrument r
            where  p.cavp_fondssymbool          = v_ca_fondssymbool
            and    p.cavp_actiedatum            = v_ca_actiedatum
            and    b.be_symbool                 = p.cavp_nieuw_fondssymbool
            and    b.be_optietype               = ' '
            and    b.be_expiratiedatum          = '00000000'
            and    b.be_exerciseprijs           = 0
            and    r.be_symbool                 = b.be_symbool
            and    r.be_optietype               = ' '
            and    r.be_expiratiedatum          = '00000000'
            and    r.be_exerciseprijs           = 0;


      begin
         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'OMWL Voor de loop van de te verkrijgen fondsen...');
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
         end if;

         -- NB er hoeven geen te verkrijgen fondsen te zijn, dan is het hoofdfonds het enige fonds in de productconversie. Dan zullen er geen verdere acties plaatsvinden hier.
         for r_pc in pc
         loop
            -- resetten van de gebruikte variabelen (per fonds):
            v_caTo_effectief_bedrag_relval  := 0;
            v_caTo_effectief_bedrag_trval   := 0;
            v_caTo_effectief_bedrag_rv      := 0;
            v_caTo_effectief_bedrag_bv      := 0;
            v_caTo_dekkingswaarde_relval    := 0;
            v_caTo_notabedrag_relval        := 0;
            v_ca_grondslag_aanwezig         := 0;

            -- eerst berekenen wat het nieuwe aantal wordt in het nieuwe fonds:
            v_caTo_reken_aantal := trunc((v_reken_aantal * (case when v_fonds_aantal_cijfers_display <> 0 then v_fonds_prijs_factor else 1 end) /
                                          v_ca_aantal * r_pc.cavp_aantal_nieuwe_fonds) / (case when r_pc.be_aantal_cijfers_display <> 0 then r_pc.be_prijs_factor else 1 end), 0);

            -- Kijken of voor het fonds binnen de productconversie ook grondslagen aanwezig zijn:
            begin
               select 1
               into   v_ca_grondslag_aanwezig
               from   tax_base_amount t
               where  t.tba_capc_id        = v_ca_id
               and    t.tba_be_id          = r_pc.be_volgnummer
               and    t.tba_base_amount_to <> 0
               and    rownum               <= 1;
            exception
               when no_data_found
               then
                  v_ca_grondslag_aanwezig := 0;
            end;

            if gv_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Nieuw fondssymbool : '||r_pc.cavp_nieuw_fondssymbool||' '||' ; aantal nieuw fonds : '||to_char(r_pc.cavp_aantal_nieuwe_fonds));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Verrekenbedrag     : '||to_char(r_pc.cavp_verrekenbedrag)||' '||' ; verreken muntsoort : '||r_pc.cavp_verrekenbedrag_muntsoort);
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Prijs factor fonds : '||to_char(r_pc.be_prijs_factor)||' '||' ; aantal cijfers display : '||to_char(r_pc.be_aantal_cijfers_display));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'To reken aantal    : '||to_char(v_caTo_reken_aantal)||' '||' ; grondslag aanwezig : '||to_char(v_ca_grondslag_aanwezig));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
            end if;

            -- Er valt alleen een notabedrag te berekenen als:
            -- A. het verrekenbedrag <> 0 is (dit kan zowel positief als negatief zijn: - --> De klant betaald; + --> de klant ontvangt)
            -- of
            -- B. er zijn bij belastingen afwijkende grondslagen opgegeven (en dan kun je daarmee een "effectief bedrag" berekenen om de bijbehorende belasting te berekenen

            if r_pc.cavp_verrekenbedrag <> 0 or v_ca_grondslag_aanwezig = 1
            then
               -- het notabedrag berekenen met behulp van het verrekenbedrag of doorgeven dat er tax berekend moet worden
               -- omdat de berekeningen niet plaats vinden met behulp van transactiesoort OMWL wordt eerst het transactiesoort omgezet en vastgelegd:
               v_transactie_soort := 'D';
               set_afwijkende_ordergegevens (v_transactie_soort,           i_ordernummer,                  i_orderregel,             i_orderdetailnummer,
                                             r_pc.cavp_nieuw_fondssymbool, ' ',                            '00000000',               0,
                                             r_pc.be_bi_nummer,            r_pc.be_exass_factor,           r_pc.be_prijs_factor,
                                             case when r_pc.be_aantal_te_ontvangen= 0 then 0 else round(r_pc.be_aantal_in_te_leveren/r_pc.be_aantal_te_ontvangen,6) end,
                                             r_pc.be_bv_beurs,             r_pc.be_aantal_cijfers_display, r_pc.be_volgnummer,       r_pc.be_muntsoort,
                                             r_pc.be_referentiesymbool,    r_pc.ref_bi_nummer,             r_pc.ref_prijs_factor,    v_caTo_reken_aantal,
                                             v_ca_provisie_onderdrukken,   case when r_pc.cavp_verrekenbedrag > 0 then 1 else 0 end, v_transactie_soort_tb_waarde);

               FIAT_NOTABEDRAG.notabedrag_bereken( i_ordernummer,                 i_orderregel,                i_orderdetailnummer,      gv_order_orx_id,
                                                   gv_rel_productnummer,          gv_rel_product_volgnr,       i_slot_of_laatste_koers,  1,
                                                   abs(r_pc.cavp_verrekenbedrag), i_uitgangspunt_berekeningen, 0,                        0,
                                                   gv_instellingen,               gv_systspreadcodecategorie,  gv_bank2mrktqchangedate,
                                                   i_trans_context,               i_terminalnummer,            gv_belgisch_spaar_product,
                                                   2,                             v_ca_id,                     gv_legal_entity_type,     gv_eor_kenmerk_id,
                                                   i_fundcategory,                v_dummy_num,                 v_dummy_num,              v_dummy_num);

               -- op dit punt zijn een aantal gegevens berekend. Deze ophalen om te gebruiken in de totaaltellingen:
               select k.kst_effect_bedrag_bv,     k.kst_effect_bedrag_rv,     k.kst_notabedrag
               into   v_caTo_effectief_bedrag_bv, v_caTo_effectief_bedrag_rv, v_caTo_notabedrag_relval
               from   kosten_werkbestand k
               where  k.kst_ordernummer  = i_ordernummer
               and    k.kst_orderregel   = i_orderregel
               and    k.kst_detailnummer = i_orderdetailnummer;
               
               -- Teken goed zetten als het berekende notabedrag het verkeede teken heeft (alleen bij negatief verrekenbedrag (= te betalen))
               if r_pc.cavp_verrekenbedrag < 0 and v_caTo_notabedrag_relval > 0
               then
                  v_caTo_notabedrag_relval := -1 * v_caTo_notabedrag_relval;
               end if;
            else
               -- Als er geen verrekenbedrag of tax is, dan bedragen op 0 zetten
               v_caTo_effectief_bedrag_bv := 0;
               v_caTo_effectief_bedrag_rv := 0;
               v_caTo_notabedrag_relval   := 0;
            end if;

            -- Aansluitend het dekkingswaarde effect berekenen voor het fonds dat in positie komt.
            -- Maar alleen als de berekening voor VV-fondsen niet moet worden onderdrukt.
            if gv_relatie_onld_omsch <> ' '
               and
               (gv_suppressFCDekkwaarde = 0 or gv_basis_valuta = r_pc.be_muntsoort)
            then
               lopende_orders_dekw_fnds_berek (v_relatienummer,                v_order_depot,                v_order_depot_reksoort, 1,
                                               ' ',                            r_pc.cavp_nieuw_fondssymbool, v_transactie_soort,     v_transactie_soort_tb_waarde,
                                               v_reken_aantal,                 1,                            v_order_ext_refentie,   v_caTo_wegingsfactor_long,
                                               v_caTo_wegingsfactor_short,     v_caTo_begin_positie,         v_caTo_eind_positie,    v_reken_aantal,
                                               v_caTo_effectief_bedrag_relval, v_caTo_effectief_bedrag_trval);

               lopende_orders_dekw (gv_relatie_onld_omsch,         gv_relatie_onld_perc,      r_pc.cavp_nieuw_fondssymbool,  ' ',
                                    '00000000',                    0,                         r_pc.be_muntsoort,             v_transactie_soort_tb_waarde,
                                    v_order_soort,                 v_caTo_wegingsfactor_long, v_caTo_wegingsfactor_short,    i_fundcategory,
                                    v_caTo_effectief_bedrag_trval, v_caTo_reken_aantal,       v_caTo_begin_positie,          v_caTo_eind_positie,           
                                    r_pc.be_bi_nummer,             i_trans_context,           v_caTo_dekkingswaarde_relval,  v_caTo_wegingsfactor_gebruikt);

            else
               v_caTo_dekkingswaarde_relval  := 0;
               v_caTo_wegingsfactor_gebruikt := 0;
            end if;

            -- de berekende gegevens wegschrijven in het werkbestand voor debug doeleinden:
            insert into werkbestand w
            (w.wk_terminal,                  w.wk_soort,                   w.wk_categorie_1,
             w.wk_categorie_2,               w.wk_categorie_3,             w.wk_waarde_1,
             w.wk_waarde_2,                  w.wk_waarde_3,                w.wk_waarde_4)
            values
            (i_terminalnummer,               'ORDC',                       to_char(i_ordernummer,'99999999')||' '||to_char(i_orderregel,'9999'),
             'Subfonds',                     r_pc.cavp_nieuw_fondssymbool, v_caTo_reken_aantal,
             v_caTo_effectief_bedrag_relval, v_caTo_notabedrag_relval,     v_caTo_dekkingswaarde_relval);

            if gv_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'OMWL na het berekeen van de gegevens van het nieuwe fonds');
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'nieuw aantal            : '||to_char(v_caTo_reken_aantal)||' ; notabedrag : '||to_char(v_caTo_notabedrag_relval));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag relval : '||to_char(v_caTo_effectief_bedrag_relval)||' ; dekkingswaarde : '||to_char(v_caTo_dekkingswaarde_relval));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
            end if;

            -- De bedragen meetellen in de totalen van het hoofdfonds:
            v_ca_notabedrag_relval     := v_ca_notabedrag_relval + v_caTo_notabedrag_relval;
            v_ca_dekkingswaarde_relval := v_ca_dekkingswaarde_relval + v_caTo_dekkingswaarde_relval;
            v_ca_effectief_bedrag      := v_ca_effectief_bedrag + v_caTo_effectief_bedrag_relval;
            v_ca_effectief_bedrag_bv   := v_ca_effectief_bedrag_bv + v_caTo_effectief_bedrag_bv;
         end loop;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'OMWL Na de loop door de te verkrijgen fondsen');
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
         end if;
      end;

      -- overnemen van de berekende totaal bedragen in variabelen die verder gebruikt gaan worden in de berekeningen:
      v_notabedrag                  := v_ca_notabedrag_relval;
      v_dekkingswaarde              := v_ca_dekkingswaarde_relval;
      v_effectief_bedrag_relatieval := v_ca_effectief_bedrag;
      v_effectief_bedrag_bv         := v_ca_effectief_bedrag_bv;

      -- Als laatste de ordergegevens weer terugzetten zodat daarmee weer verder wordt gegaan met de originele gegevens uit de order:
      set_afwijkende_ordergegevens ('OMWL',                     i_ordernummer,                  i_orderregel,                i_orderdetailnummer,
                                    v_fondssymbool,             v_optietype,                    v_expiratiedatum,            v_exerciseprijs,
                                    v_fonds_be_bi_nummer,       v_fonds_ex_as_factor,           v_fonds_prijs_factor,        v_fonds_omw_factor,
                                    v_fonds_beursnummer,        v_fonds_aantal_cijfers_display, v_fonds_volgnummer,          v_fonds_muntsoort,
                                    v_reffondssymbool,          v_ref_fonds_be_bi_nummer,       v_ref_fonds_prijs_factor,    v_reken_aantal,
                                    v_ca_provisie_onderdrukken, 0,                              v_transactie_soort_tb_waarde);
      v_transactie_soort := 'OMWL';

   -- berekenen voor iedere ENKELVOUDIGE order de volgende dingen (behalve OMWL volgens WISO):
   -- --> het nota bedrag (voor alle orders)
   -- --> dekkingswaarde (voor alle orders)
   -- --> margineffect (voor orders met de instelling afgeleide effecten)
   elsif v_ordertype not in ('COMB','VZCO') and i_orderregel = 1
   then
      -- berekenen van het notabedrag:
      FIAT_NOTABEDRAG.notabedrag_bereken (i_ordernummer,        i_orderregel,                  i_orderdetailnummer,           gv_order_orx_id,
                                          gv_rel_productnummer, gv_rel_product_volgnr,         i_slot_of_laatste_koers,       0,
                                          0,                    i_uitgangspunt_berekeningen,   0,                             0,
                                          gv_instellingen,      gv_systspreadcodecategorie,    gv_bank2mrktqchangedate,
                                          i_trans_context,      gv_terminalnummer,             gv_belgisch_spaar_product,
                                          0,                    0,                             gv_legal_entity_type,          gv_eor_kenmerk_id,
                                          i_fundcategory,       v_dummy_num,                   v_nb_verk_als_koop_behandelen, v_effectief_bedrag_transval);

      -- berekenen van de dekkingswaarde voor de stukken (dit gebeurt adhv bij notabedrag bepaalde gegevens)
      select k.kst_notabedrag, k.kst_effect_bedrag_bv,  k.kst_effect_bedrag_rv,        k.kst_provisie_bedrag,  k.kst_kost_corr_doorb
      into   v_notabedrag,     v_effectief_bedrag_bv,   v_effectief_bedrag_relatieval, v_provisie,             v_kost_corr
      from   kosten_werkbestand k
      where  k.kst_ordernummer        = i_ordernummer
      and    k.kst_orderregel         = i_orderregel
      and    k.kst_detailnummer       = i_orderdetailnummer;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectiefbedrag in transval   : '||to_char(v_effectief_bedrag_transval)||' ; v_notabedrag : '||to_char(v_notabedrag));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'voor het berekenen van de dekkingswaarde van de order');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i wegings perc long  : '||to_char(i_wegings_perc_long)||' ; i wegingsperc short : '||to_char(i_wegings_perc_short));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'relatie onld omsch   : '||gv_relatie_onld_omsch||' ; trans soort tb waarde: '||to_char(v_transactie_soort_tb_waarde));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'eind positie order   : '||to_char(v_eind_positie_order)||' ; begin positie order : '||to_char(v_begin_positie_order));
         if gv_relatie_onld_omsch = ' '
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'de relatie onld omschrijving is inderdaad leeg ( )');
         end if;
      end if;

      if (((i_wegings_perc_long <> 0  and (v_transactie_soort_tb_waarde = 1 or v_transactie_soort_tb_waarde= 2 and v_eind_positie_order >=0)
            or
            i_wegings_perc_short <> 0 and v_transactie_soort_tb_waarde = 2 and v_eind_positie_order < 0
            or
            v_transactie_soort in ('EX C','EX P'))
            and
            gv_relatie_onld_omsch <> ' '
          )
          or
          (i_wegings_perc_short <> 0 and v_transactie_soort_tb_waarde = 2 and v_eind_positie_order < 0
           and gv_relatie_onld_omsch = ' ')  -- baisse margin altijd berekenen bij geen kredietbrief!!!
          )
          and 
           -- Maar alleen als de berekening voor VV-fondsen niet moet worden onderdrukt.
          (gv_suppressFCDekkwaarde = 0 or gv_basis_valuta = v_fonds_muntsoort)
      then
         -- bepalen van de dekkingswaarde die bij de positie is opgebruikt (dus de sum)
         select sum(p.pwb_dekk_waarde_rapv)
         into   v_gebruikte_dekkingswaarde_pos
         from   positie_werkbestand p
         where  p.pwb_rekening_soort = 0;

         if gv_relatie_onld_omsch in ('M','F','L','C','E')
         then
            io_dekkingswaarde_over := gv_relatie_onld_bedrag - nvl(v_gebruikte_dekkingswaarde_pos,0) - nvl(io_gebruikte_dekkingsw_ord,0);
            -- Als de dekkingswaarde die over is kleiner dan 0 is, dan is er geen dekkingswaarde meer over.
            if io_dekkingswaarde_over < 0
            then
               io_dekkingswaarde_over := 0;
            end if;
         end if;

         -- Voor koop orders (K, KN, EMIS en EX C) geldt ook nog dat de koop orders moeten prolongeren, in de andere gevallen
         -- wel altijd berekenen:
         if ((v_transactie_soort in ('K','KN','EMIS','EX C') and gv_kooporders_prolongeren = 1)
            or
            v_transactie_soort not in ('K','KN','EMIS','EX C'))
         then
            -- Berekening voor dekkingswaarde voor exercises
            if v_transactie_soort in ('EX C','EX P')
            then
               lopende_orders_dekwrde_loop (v_relatienummer,   v_order_depot,      v_order_depot_reksoort,       v_fonds_ex_as_factor,
                                            v_reffondssymbool, v_transactie_soort, v_transactie_soort_tb_waarde, v_order_soort,
                                            v_reken_aantal,    i_trans_context,    i_fundcategory,               v_dekkingswaarde,             
                                            v_wegings_factor_gebruikt);

            -- overige gevallen berekenen
            else
               lopende_orders_dekw (gv_relatie_onld_omsch,       gv_relatie_onld_perc,  v_fondssymbool,        v_optietype,
                                    v_expiratiedatum,            v_exerciseprijs,       v_fonds_muntsoort,     v_transactie_soort_tb_waarde,
                                    v_order_soort,               i_wegings_perc_long,   i_wegings_perc_short,  i_fundcategory,
                                    v_effectief_bedrag_transval, v_reken_aantal,        v_begin_positie_order, v_eind_positie_order,      
                                    v_fonds_be_bi_nummer,        i_trans_context,       v_dekkingswaarde,      v_wegings_factor_gebruikt);

            end if;
         end if;

         -- Bij verkopen de dekkingswaarde negatief nemen (je raakt immers de stukken kwijt, dus ook dekkingswaarde kwijt)
         if v_transactie_soort_tb_waarde = 2
         then
            v_dekkingswaarde := -1 * v_dekkingswaarde;
         end if;

         -- Kijken hoe de berekende dekkingswaarde zich verhoudt tot de dekkingswaarde over
         -- nb baisse margin moet altijd meegenomen worden, dus hier uitsluiten van het controleren
         if gv_relatie_onld_omsch in ('M','F','L','C','E') and v_dekkingswaarde > 0
         then
            if io_dekkingswaarde_over = 0
            then
               v_dekkingswaarde := 0;
            else
               io_dekkingswaarde_over := io_dekkingswaarde_over - v_dekkingswaarde;
               if io_dekkingswaarde_over < 0
               then
                  -- dekkingswaarde aftoppen op het maximale dat er mag worden uitgegeven
                  -- nb de io_dekkingswaarde_over is hier negatief dus een + (anders - - wordt +)
                  v_dekkingswaarde      := v_dekkingswaarde + io_dekkingswaarde_over;
                  io_dekkingswaarde_over := 0;
               end if;
            end if;
            -- bijhouden hoeveel dekkingswaarde er in de orders al is opgebruikt:
            io_gebruikte_dekkingsw_ord := io_gebruikte_dekkingsw_ord + v_dekkingswaarde;
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'na het berekenen van de dekkingswaarde van de order');
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'relatie onld bedrag     : '||to_char(gv_relatie_onld_bedrag)||' ; berekende dekkingswaarde port : '||to_char(v_gebruikte_dekkingswaarde_pos));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'io dekkingswaarde over  : '||to_char(io_dekkingswaarde_over)||' ; io gebruikte dekkingsw ord : '||to_char(io_gebruikte_dekkingsw_ord));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'dekkingswaarde berekend : '||to_char(v_dekkingswaarde));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'wegingsfactor gebruikt  : '||to_char(v_wegings_factor_gebruikt));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
         end if;
      else
         v_dekkingswaarde := 0;
      end if;

      -- aanpassen teken van het notabedrag aan de klantsituatie (koop is betalen --> -, verkoop is krijgen --> +)
      -- voor futures wordt alleen provisie berekend, dit zijn kosten dus moeten ook
      -- negatief zijn voor de relatie, dus daarvoor zorgen als dat nog niet het geval is.
      -- Uitzondering is als verkoop door laag effectief bedrag en hoge kosten als koop (kost dus geld) behandeld moet worden
      if v_notabedrag > 0
      then
         if v_transactie_soort_tb_waarde = 1 or v_optietype = 'FUT' or v_nb_verk_als_koop_behandelen = 1
         then
            v_notabedrag := -1 * v_notabedrag;
         end if;
      else
         if v_transactie_soort_tb_waarde = 2
         then
            v_notabedrag := -1 * v_notabedrag;
         end if;
      end if;

      -- bepalen van het margin effect. Alleen voor de orders waarvoor geldt dat afgeleide effecten aanstaat
      if (v_transactie_soort in ('EX C','EX P') and (i_berekenen_afgeleide_effecten = 1 or i_exas_berek_afgeleide_effect = 1)
          or
          v_transactie_soort not in ('EX C','EX P') and i_berekenen_afgeleide_effecten = 1)
      then
         FIAT_ORDER_MARGIN_EFFECT.lopende_orders_margin_effect (i_ordernummer, i_orderregel, i_orderdetailnummer,
                                                                v_relatienummer, i_slot_of_laatste_koers, i_terminalnummer,
                                                                i_sys_toeslag_optiemarg, gv_rel_toeslag_optiemarg,
                                                                gv_methode_naked_margin, gv_factor_naked_margin,
                                                                gv_trekkingswaarde_aktief, gv_pr_blokkeren_short_call,
                                                                gv_pr_blokkeren_short_put, gv_pr_blokkeren_long_put, gv_instellingen,
                                                                v_margin_effect_bedrag);
      elsif gv_pr_blokkeren_long_put = 1 and v_optietype = 'PUT' and v_transactie_soort = 'OK' and i_berekenen_afgeleide_effecten <> 1
      then
         -- voor long put in ieder geval de verbruikte dekking registreren zodat die niet te gebruiken is door hierna
         -- volgende orders.
         FIAT_ORDER_MARGIN.lopende_orders_geblok_w (v_reffondssymbool, v_fonds_prijs_factor, v_reken_aantal,
                                                    i_terminalnummer, gv_debuggen, gv_debug_user, v_prod_geblok_aantal);
      end if;

   -- Berekenen van de notabedragen voor de COMBINATIEorders
   elsif v_ordertype in ('COMB','VZCO') and i_orderregel = 2
   then
      -- Bepalen van de te gebruiken koersen voor het berekenen van de notabedragen:
      -- Als eerste voor beide legs de fondskoersen bepalen:
      FIAT_ALGEMEEN.fondskoersen(i_symbool_comb, i_optietype_comb, i_expiratiedatum_comb, i_exerciseprijs_comb, i_slot_of_laatste_koers,
                                 v_bied_koers_comb, v_laat_koers_comb);
      FIAT_ALGEMEEN.fondskoersen(v_fondssymbool, v_optietype, v_expiratiedatum, v_exerciseprijs, i_slot_of_laatste_koers,
                                 v_bied_koers_fonds, v_laat_koers_fonds);

      if i_trans_tb_waarde_comb = 1
      then
         v_koers_comb := v_laat_koers_comb;
      else
         v_koers_comb := v_bied_koers_comb;
      end if;

      if v_transactie_soort_tb_waarde = 1
      then
         v_koers_fonds := v_laat_koers_fonds;
      else
         v_koers_fonds := v_bied_koers_fonds;
      end if;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in het combinatie order gedeelte');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'koers comb : '||to_char(v_koers_comb)||' ; koers fonds : '||to_char(v_koers_fonds));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'substr transsoort comb  : '||substr(i_transactie_soort_comb,-1));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'substr transsoort fonds : '||substr(v_transactie_soort,-1));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'db cr indicatie : '||to_char(i_db_cr_indicatie));
      end if;

      if i_ordersoort_comb in ('L','SLI')
      then
         -- Als gebruik wordt gemaakt van de calc rules, dan gaan we de koersen van de beide legs bepalen met behulp van de bepaalde koersen en
         -- de transactie indicaties en de debet-credit indicator

         -- Als beide transactiesoorten koop of verkoop-achtigen zijn
         if substr(v_transactie_soort,-1)=substr(i_transactie_soort_comb,-1)
         then
            -- wat is de leg met de kleinste fondskoers? Die wordt nl altijd gebruikt als uitgangspunt
            if v_koers_comb <= v_koers_fonds
            then
               v_te_gebruiken_koers_comb  := v_koers_comb;
               v_te_gebruiken_koers_fonds := i_limietprijs_comb - v_te_gebruiken_koers_comb;
            else
               v_te_gebruiken_koers_fonds := v_koers_fonds;
               v_te_gebruiken_koers_comb  := i_limietprijs_comb - v_te_gebruiken_koers_fonds;
            end if;
            -- als een van de koersen onder of gelijk 0 is gekomen dan is blijkbaar een limiet opgevoerd kleiner/gelijk dan de kleinste koers, dan terugvallen op limiet/2
            if v_te_gebruiken_koers_comb <= 0 or v_te_gebruiken_koers_fonds <= 0
            then
               v_te_gebruiken_koers_comb  := i_limietprijs_comb/2;
               v_te_gebruiken_koers_fonds := i_limietprijs_comb - v_te_gebruiken_koers_comb;
               v_correctie_limietprijs    := 1;
            end if;
         else
            -- wat is de instelling voor db/cr indicator?
            if i_db_cr_indicatie = 1 and  substr(v_transactie_soort,-1)='K'  -- Credit indicator, zoek naar de koop (debet) kant om als uitgangspunt te dienen
               or
               i_db_cr_indicatie = -1 and substr(v_transactie_soort,-1)='V'  -- Debet indicator, zoek naar de verkoop (credit) kant om als uitgangspunt te dienen
            then
               v_te_gebruiken_koers_fonds := v_koers_fonds;
               v_te_gebruiken_koers_comb  := v_te_gebruiken_koers_fonds + i_limietprijs_comb;
            else
               v_te_gebruiken_koers_comb  := v_koers_comb;
               v_te_gebruiken_koers_fonds := v_te_gebruiken_koers_comb + i_limietprijs_comb;
            end if;
         end if;

      else
         -- Voor niet L en SLI orders moet het effectief bedrag berekend worden met de koersen van de fondsen.
         v_te_gebruiken_koers_comb  := v_koers_comb;
         v_te_gebruiken_koers_fonds := v_koers_fonds;
      end if;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'te gebruiken koers comb : '||to_char(v_te_gebruiken_koers_comb)||' ; te gebruiken koers fonds : '||to_char(v_te_gebruiken_koers_fonds));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'koers comb              : '||to_char(v_koers_comb)||' ;  koers fonds : '||to_char(v_koers_fonds));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
      end if;

      -- Geen afwijkende koersen gebruiken als één van beide koersen <> 0 zijn.
      if v_te_gebruiken_koers_comb = 0 and v_te_gebruiken_koers_fonds = 0
      then
         v_afwijkende_koers_gebruiken := 0;
      else
         v_afwijkende_koers_gebruiken := 1;
      end if;

      -- Eerst het notabedrag berekenen van het eerste leg:
      FIAT_NOTABEDRAG.notabedrag_bereken(i_ordernummer,             1,                             i_orderdetailnummer,           gv_order_orx_id,
                                         gv_rel_productnummer,      gv_rel_product_volgnr,         i_slot_of_laatste_koers,       v_afwijkende_koers_gebruiken,
                                         v_te_gebruiken_koers_comb, i_uitgangspunt_berekeningen,   0,                             v_koers_comb,
                                         gv_instellingen,           gv_systspreadcodecategorie,    gv_bank2mrktqchangedate,       
                                         i_trans_context,           gv_terminalnummer,             gv_belgisch_spaar_product,     
                                         0,                         0,                             gv_legal_entity_type,          gv_eor_kenmerk_id, 
                                         i_fundcategory,            v_dummy_num,                   v_nb_verk_als_koop_behandelen, v_dummy_num);

      select k.kst_notabedrag, k.kst_provisie_bedrag,
            (case when k.kst_trans_indicatie_w=1 and k.kst_order_soort not in ('L','SLI')
                  then k.kst_effect_bedrag_bv*-1
                       else k.kst_effect_bedrag_bv end),
            (case when k.kst_trans_indicatie_w=1 and k.kst_order_soort not in ('L','SLI')
                  then k.kst_effect_bedrag_rv*-1
                       else k.kst_effect_bedrag_rv end),
             k.kst_kost_corr_doorb
      into   v_notabedrag_comb, v_provisie_comb, v_effectief_bedrag_bv_comb, v_effectief_bedrag_relval_comb, v_kost_corr_comb
      from   kosten_werkbestand k
      where  k.kst_ordernummer  = i_ordernummer
      and    k.kst_orderregel   = 1
      and    k.kst_detailnummer = i_orderdetailnummer;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'terug uit berekenen notabedrag voor leg 1');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'berekend notabedrag comb : '||to_char(v_notabedrag_comb));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'db cr indicatie          : '||to_char(i_db_cr_indicatie)||' ; order soort : '||v_order_soort);
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'trans tb waarde comb     : '||to_char(i_trans_tb_waarde_comb)||' ; te gebruiken koers comb : '||to_char(v_te_gebruiken_koers_comb));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'optietype comb           : '||i_optietype_comb||' ; Afwijkende koers gebruiken : '||to_char(v_afwijkende_koers_gebruiken));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'notabedrag verkoop als koop behandelen : '||to_char(v_nb_verk_als_koop_behandelen));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
      end if;

      -- aanpassen teken van het notabedrag aan de klantsituatie (koop is betalen --> -, verkoop is krijgen --> +)
      -- voor futures en bij koers = 0 wordt alleen provisie berekend, dit zijn kosten dus moeten ook
      -- negatief zijn voor de relatie, dus daarvoor zorgen als dat nog niet het geval is.
      -- De correctie hoeft alleen uitgevoerd te worden het geen limiet order is met db/cr indicatie
      -- Uitzondering is ook als effectief bedrag zo laag is en de kosten zo hoog dat het notabedrag betaald moet worden bij verkopen
      -- Bij gebruik calc rules wel corrigeren omdat hier het daadwerkelijke notabedrag gebruikt wordt
      if v_notabedrag_comb > 0
      then
         if i_trans_tb_waarde_comb = 1 or i_optietype_comb = 'FUT' or v_te_gebruiken_koers_comb = 0 or v_nb_verk_als_koop_behandelen = 1
         then
            v_notabedrag_comb := -1 * v_notabedrag_comb;
         end if;
      else
         if i_trans_tb_waarde_comb = 2
         then
            v_notabedrag_comb := -1 * v_notabedrag_comb;
         end if;
      end if;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'na goed zetten teken notabedrag voor leg 1');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'berekend notabedrag comb : '||to_char(v_notabedrag_comb));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
      end if;

      -- Als tweede het notabedrag berekenen van het tweede leg:
      FIAT_NOTABEDRAG.notabedrag_bereken(i_ordernummer,              2,                           i_orderdetailnummer,           gv_order_orx_id,
                                         gv_rel_productnummer,       gv_rel_product_volgnr,       i_slot_of_laatste_koers,       v_afwijkende_koers_gebruiken,
                                         v_te_gebruiken_koers_fonds, i_uitgangspunt_berekeningen, 0,                             v_koers_fonds,
                                         gv_instellingen,            gv_systspreadcodecategorie,  gv_bank2mrktqchangedate,       
                                         i_trans_context,            gv_terminalnummer,           gv_belgisch_spaar_product,     
                                         0,                          0,                           gv_legal_entity_type,          gv_eor_kenmerk_id,
                                         i_fundcategory,             v_dummy_num,                 v_nb_verk_als_koop_behandelen, v_dummy_num);

      select k.kst_notabedrag, k.kst_provisie_bedrag,
             (case when k.kst_trans_indicatie_w=1 and k.kst_order_soort not in ('L','SLI')
                   then k.kst_effect_bedrag_bv*-1
                        else k.kst_effect_bedrag_bv end),
             (case when k.kst_trans_indicatie_w=1 and k.kst_order_soort not in ('L','SLI')
                   then k.kst_effect_bedrag_rv*-1
                        else k.kst_effect_bedrag_rv end),
             k.kst_kost_corr_doorb
      into   v_notabedrag, v_provisie, v_effectief_bedrag_bv, v_effectief_bedrag_relatieval, v_kost_corr
      from   kosten_werkbestand k
      where  k.kst_ordernummer  = i_ordernummer
      and    k.kst_orderregel   = 2
      and    k.kst_detailnummer = i_orderdetailnummer;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'terug uit berekenen notabedrag voor leg 2');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'berekend notabedrag comb : '||to_char(v_notabedrag));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'db cr indicatie          : '||to_char(i_db_cr_indicatie)||' ; order soort : '||v_order_soort);
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'trans tb waarde          : '||to_char(v_transactie_soort_tb_waarde)||' ; te gebruiken koers comb : '||to_char(v_te_gebruiken_koers_comb));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'optietype comb           : '||v_optietype);
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'notabedrag verkoop als koop behandelen : '||to_char(v_nb_verk_als_koop_behandelen));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
      end if;

      -- aanpassen teken van het notabedrag aan de klantsituatie (koop is betalen --> -, verkoop is krijgen --> +)
      -- voor futures en bij koers = 0 wordt alleen provisie berekend, dit zijn kosten dus moeten ook
      -- negatief zijn voor de relatie, dus daarvoor zorgen als dat nog niet het geval is.
      -- De correctie hoeft alleen uitgevoerd te worden als het geen limiet order is met db/cr indicatie
      -- Uitzondering is ook als effectief bedrag zo laag is en de kosten zo hoog dat het notabedrag betaald moet worden bij verkopen
      -- Bij gebruik calc rules wel corrigeren omdat hier het daadwerkelijke notabedrag gebruikt wordt
      if v_notabedrag > 0
      then
         if v_transactie_soort_tb_waarde = 1 or v_optietype = 'FUT' or v_te_gebruiken_koers_fonds = 0 or v_nb_verk_als_koop_behandelen = 1
         then
            v_notabedrag := -1 * v_notabedrag;
         end if;
      else
         if v_transactie_soort_tb_waarde = 2
         then
            v_notabedrag := -1 * v_notabedrag;
         end if;
      end if;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'na goed zetten teken notabedrag voor leg 2');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'berekend notabedrag : '||to_char(v_notabedrag));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
      end if;

      -- combinatie orders hebben geen dekkingswaarde dus die hier op 0 zetten:
      v_dekkingswaarde_comb := 0;
      v_dekkingswaarde      := 0;
   end if; --einde berekenen van de notabedragen voor combinatie orders.

   -- berekenen van de margin verplichting indien nodig:
   --  i_berekenen_bruto_margin = 1 en i_berekenen_afgeleide_effecten = 0
   --  of
   --  het betreft een combinatie order (opties)
   -- Voor futures moet altijd de waarborg meegenomen worden zie verder hier beneden (volgende block)
   if v_reken_aantal <> 0 and v_optietype <> 'FUT'
   then
      -- enkelvoudige orders
      if i_berekenen_bruto_margin = 1 and v_ordertype not in ('COMB','VZCO') and i_orderregel = 1 and i_berekenen_afgeleide_effecten = 0
      then
         FIAT_ORDER_MARGIN.lopende_orders_margin(i_ordernummer, i_orderregel, i_orderdetailnummer, i_terminalnummer,
                                                 i_slot_of_laatste_koers, i_sys_toeslag_optiemarg, gv_rel_toeslag_optiemarg,
                                                 gv_methode_naked_margin, gv_factor_naked_margin,
                                                 1, 0, gv_pr_blokkeren_short_call, gv_pr_blokkeren_short_put,
                                                 gv_pr_blokkeren_long_put, 0, gv_instellingen, v_margin_bedrag);
         -- het margin berdrag is een kosten bedrag, dus hier het teken omdraaien:
         v_margin_bedrag := -1 * v_margin_bedrag;
      end if;
      -- combinatie orders:
      if v_ordertype in ('COMB', 'VZCO') and i_orderregel = 2
      then
         FIAT_ORDER_MARGIN_EFFECT.lopende_orders_margin_effect (i_ordernummer, i_orderregel, i_orderdetailnummer,
                                                                v_relatienummer, i_slot_of_laatste_koers, i_terminalnummer,
                                                                i_sys_toeslag_optiemarg, gv_rel_toeslag_optiemarg,
                                                                gv_methode_naked_margin, gv_factor_naked_margin,
                                                                gv_trekkingswaarde_aktief, gv_pr_blokkeren_short_call,
                                                                gv_pr_blokkeren_short_put, gv_pr_blokkeren_long_put, gv_instellingen, v_margin_bedrag);
         -- NB Het marginbedrag uit deze procedure is al negatief of nul.
      end if;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'berekenen van margin voor de order');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'berekende margin : '||to_char(v_margin_bedrag)||' berekend margin effect : '||to_char(v_margin_effect_bedrag));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordertype        : '||v_ordertype||' ; orderregel : '||to_char(i_orderregel));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'transactie_soort : '||v_transactie_soort||' ; rekenaantal : '||to_char(v_reken_aantal));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'optietype        : '||v_optietype);
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
      end if;
   end if;

   -- berekenen van de waarborgsom voor futures:
   -- voor alle openings-orders en openining/sluitings-combinatie orders:
   -- dus hier zowel enkelvoudige als combinatie orders. Dit omdat het combinatiegedeelte voor future afwijkt van
   -- de normale berekeningen (alvast teruggeven van waarborgsommen bij clossingen etc).
   if (v_ordertype in ('COMB','VZCO') and i_orderregel = 2
       or
       v_ordertype not in ('COMB','VZCO') and i_orderregel = 1 and substr(v_transactie_soort,1,1)='O')
       and v_reken_aantal <> 0
       and v_optietype = 'FUT'
   then
      FIAT_ORDER_MARGIN.lopende_orders_waarborg(i_ordernummer,i_orderregel, i_orderdetailnummer, gv_bank2mrktqchangedate, gv_systspreadcodecategorie, 0, v_margin_bedrag);
      -- het waarborg bedrag is een kosten bedrag, dus hier het teken omdraaien:
      v_margin_bedrag := -1 * v_margin_bedrag;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in het gedeelte voor de waarborg');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin bedrag (waarborg) : '||to_char(v_margin_bedrag));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
      end if;
   end if;

   -- alle gegevens (notabedrag, dekkingswaarde, margin/waarborgsom) zijn nu voorhanden;
   -- dus vanaf hier de gegevens berekenen en wegschrijven.

   -- Voor combinatie orders zijn de gegevens van het eerste leg al opgehaald
   -- en kan hier gebruikt worden om de gegevens te berkenen.
   if v_ordertype in ('COMB','VZCO') and i_orderregel = 2
   then
      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in het gedeelte verdelen bedragen voor combinatie orders');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin bedrag (totaal) : '||to_char(v_margin_bedrag));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'notabedrag comb : '||to_char(v_notabedrag_comb)||' ; notabedrag : '||to_char(v_notabedrag));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provisie comb   : '||to_char(v_provisie_comb)||' ; provisie : '||to_char(v_provisie));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'kost. corresp comb : '||to_char(v_kost_corr_comb)||' ; kost. corresp : '||to_char(v_kost_corr));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag bv comb : '||to_char(v_effectief_bedrag_bv_comb)||' ; effectief bedrag bv : '||to_char(v_effectief_bedrag_bv));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag rv comb : '||to_char(v_effectief_bedrag_relval_comb)||' ; effectief bedrag rv : '||to_char(v_effectief_bedrag_relatieval));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
      end if;

      -- als het een combinatie order is, dan de berekende margin verdelen over beide legs.
      v_margin_comb                      := round(v_margin_bedrag/2, v_munt_notatie);
      v_margin_bedrag                    := round((v_margin_bedrag - v_margin_comb), v_munt_notatie);

      -- Als gebruik wordt gemaakt van de calc rules, dan de daadwerkelijke notabedragen gebruiken en dus niet verdelen
      -- effectieve bedragen nog van het correcte teken voorzien:
      -- de limietprijs is evenredig over beide legs verdeelt, dan kijken naar de db/cr-indicator om het teken goed te zetten
      if v_correctie_limietprijs = 1
      then
         v_effectief_bedrag_bv_comb      := round(abs(v_effectief_bedrag_bv_comb) * i_db_cr_indicatie, v_munt_notatie);
         v_effectief_bedrag_bv           := round(abs(v_effectief_bedrag_bv) * i_db_cr_indicatie, v_munt_notatie);
         v_effectief_bedrag_relval_comb  := round(abs(v_effectief_bedrag_relval_comb) * i_db_cr_indicatie, v_munt_notatie);
         v_effectief_bedrag_relatieval   := round(abs(v_effectief_bedrag_relatieval) * i_db_cr_indicatie, v_munt_notatie);
      else
         v_effectief_bedrag_bv_comb      := round(abs(v_effectief_bedrag_bv_comb) * case when i_trans_tb_waarde_comb = 2
                                                                                         then 1 else -1 end, v_munt_notatie);
         v_effectief_bedrag_bv           := round(abs(v_effectief_bedrag_bv) * case when v_transactie_soort_tb_waarde = 2
                                                                                    then 1 else -1 end, v_munt_notatie);
         v_effectief_bedrag_relval_comb  := round(abs(v_effectief_bedrag_relval_comb) * case when i_trans_tb_waarde_comb = 2
                                                                                             then 1 else -1 end, v_munt_notatie);
         v_effectief_bedrag_relatieval   := round(abs(v_effectief_bedrag_relatieval) * case when v_transactie_soort_tb_waarde = 2
                                                                                            then 1 else -1 end, v_munt_notatie);
      end if;

      -- Bepalen van het geschatte lopend order bedrag
      lopendbedrag_comb_bereken (v_notabedrag_comb, v_notabedrag,                 v_margin_comb,        v_margin_bedrag,
                                 i_ordernummer,     i_bgs_koop_order_op_0_zetten, v_lopend_bedrag_comb, v_lopend_bedrag);

   end if; -- einde berekeningen voor combinatie orders

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'voor het bepalen lopend bedrag enkelvoudige orders');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'transactie soort : '||v_transactie_soort||' ; i berekenen bedrag huidige order : '||to_char(i_berekenen_bedrag_huidige_ord));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i berekenen afgeleide effecten : '||to_char(i_berekenen_afgeleide_effecten));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i exas bereken afgeleide effecten : '||to_char(i_exas_berek_afgeleide_effect));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

   -- Berekenen van het lopend order bedrag voor enkelvoudige orders
   if v_ordertype not in ('COMB','VZCO') and i_orderregel = 1
   then
     lopendbedrag_bereken (v_notabedrag,                   v_dekkingswaarde,              v_margin_bedrag,
                           v_margin_effect_bedrag,         v_transactie_soort,            i_berekenen_bedrag_huidige_ord,
                           i_berekenen_afgeleide_effecten, i_exas_berek_afgeleide_effect, i_bgs_koop_order_op_0_zetten,
                           i_ordernummer,                  v_lopend_bedrag,               v_margin_bedrag);
   end if;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'vlak voor het wegschrijven naar kosten werkbestanden');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer         : '||to_char(i_ordernummer)||' ; orderregel : '||to_char(i_orderregel));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag bv : '||to_char(v_effectief_bedrag_bv)||' ; effectief bedrag rv : '||to_char(v_effectief_bedrag_relatieval));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'dekkingswaarde      : '||to_char(v_dekkingswaarde)||' ; notabedrag : '||to_char(v_notabedrag));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'lopend bedrag       : '||to_char(v_lopend_bedrag)||' ; margin bedrag : '||to_char(v_margin_bedrag));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provisie bedrag     : '||to_char(v_provisie)||' ; kosten corresp bedrag : '||to_char(v_kost_corr));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'wegingsfactor gebruikt : '||to_char(v_wegings_factor_gebruikt));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
   end if;

   if gv_calculate_in_fc = 1
   then
      gv_rek_valuta           := v_rekening_muntsoort;
      FIAT_ALGEMEEN.valutagegevens_bepalen (gv_rek_valuta,           gv_relatie_pr_id,     gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                            gv_bank2mrktqchangedate, gv_debuggen,          gv_debug_user,     gv_rek_val_biedkoers,
                                            gv_rek_val_middenkoers,  gv_rek_val_laatkoers, gv_rek_val_factor, gv_rek_val_reciproke,
                                            gv_rek_val_notatie);

      omrekenen_rv_rekv (v_notabedrag,                  v_fonds_muntsoort, v_notabedrag_rekv);
      omrekenen_rv_rekv (v_dekkingswaarde,              v_fonds_muntsoort, v_dekkingswaarde_rekv);
      omrekenen_rv_rekv (v_margin_bedrag,               v_fonds_muntsoort, v_marginbedrag_rekv);
      omrekenen_rv_rekv (v_margin_effect_bedrag,        v_fonds_muntsoort, v_margin_effect_bedrag_rekv);
      omrekenen_rv_rekv (v_effectief_bedrag_relatieval, v_fonds_muntsoort, v_effectief_bedrag_rekv);

      -- Berekenen van het lopend order bedrag in rekening valuta
      lopendbedrag_bereken (v_notabedrag_rekv,              v_dekkingswaarde_rekv,         v_marginbedrag_rekv,
                            v_margin_effect_bedrag_rekv,    v_transactie_soort,            i_berekenen_bedrag_huidige_ord,
                            i_berekenen_afgeleide_effecten, i_exas_berek_afgeleide_effect, i_bgs_koop_order_op_0_zetten,
                            i_ordernummer,                  v_lopend_bedrag_rekv,          v_marginbedrag_rekv);

   else
      v_notabedrag_rekv       := 0;
      v_dekkingswaarde_rekv   := 0;
      v_marginbedrag_rekv     := 0;
      v_lopend_bedrag_rekv    := 0;
      v_effectief_bedrag_rekv := 0;
   end if;

   -- als het een combinatie order is (--> orderregel = 2), dan op dit punt de nieuw berekende gegevens
   -- wegschrijven in het eerste leg (deze is al geweest nl zie order by!)
   if v_ordertype in ('COMB','VZCO') and i_orderregel = 2
   then
      if gv_calculate_in_fc = 1
      then
         omrekenen_rv_rekv (v_notabedrag_comb,              i_fonds_muntsrt_comb, v_notabedrag_rekv_comb);
         omrekenen_rv_rekv (v_dekkingswaarde_comb,          i_fonds_muntsrt_comb, v_dekkingswaarde_rekv_comb);
         omrekenen_rv_rekv (v_margin_comb,                  i_fonds_muntsrt_comb, v_marginbedrag_rekv_comb);
         omrekenen_rv_rekv (v_effectief_bedrag_relval_comb, i_fonds_muntsrt_comb, v_effectief_bedrag_rekv_comb);
         -- lopend bedrag berekenen aan de hand van de losse bedragen voor notabedrag en margin
         lopendbedrag_comb_bereken (v_notabedrag_rekv_comb, v_notabedrag_rekv,            v_marginbedrag_rekv_comb,  v_marginbedrag_rekv,
                                    i_ordernummer,          i_bgs_koop_order_op_0_zetten, v_lopend_bedrag_rekv_comb, v_lopend_bedrag_rekv);
      else
         v_notabedrag_rekv_comb       := 0;
         v_dekkingswaarde_rekv_comb   := 0;
         v_marginbedrag_rekv_comb     := 0;
         v_lopend_bedrag_rekv_comb    := 0;
         v_effectief_bedrag_rekv_comb := 0;
      end if;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer         : '||to_char(i_ordernummer)||' ; orderregel : 1');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectief bedrag bv : '||to_char(v_effectief_bedrag_bv_comb)||' ; effectief bedrag rv : '||to_char(v_effectief_bedrag_relval_comb));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'dekkingswaarde      : '||to_char(v_dekkingswaarde_comb)||' ; notabedrag : '||to_char(v_notabedrag_comb));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'lopend bedrag       : '||to_char(v_lopend_bedrag_comb)||' ; margin bedrag : '||to_char(v_margin_comb));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'provise bedrag      : '||to_char(v_provisie_comb)||' ; kosten corresp bedrag : '||to_char(v_kost_corr_comb));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
     end if;

      update kosten_werkbestand k
      set    k.kst_notabedrag             = v_notabedrag_comb,
             k.kst_dekkingswaarde         = v_dekkingswaarde_comb,
             k.kst_marginbedrag           = v_margin_comb,
             k.kst_lopend_bedrag          = v_lopend_bedrag_comb,
             k.kst_provisie_bedrag        = v_provisie_comb,
             k.kst_effect_bedrag_bv       = v_effectief_bedrag_bv_comb,
             k.kst_effect_bedrag_rv       = v_effectief_bedrag_relval_comb,
             k.kst_kost_corr_doorb        = v_kost_corr_comb,
             k.kst_effect_bedrag_rekv_sl  = v_effectief_bedrag_rekv_comb,
             k.kst_notabedrag_rekv_sl     = v_notabedrag_rekv_comb,
             k.kst_dekkingswaarde_rekv_sl = v_dekkingswaarde_rekv_comb,
             k.kst_marginbedrag_rekv_sl   = v_marginbedrag_rekv_comb,
             k.kst_lopend_bedrag_rekv_sl  = v_lopend_bedrag_rekv_comb
      where  k.kst_ordernummer            = i_ordernummer
      and    k.kst_orderregel             = 1
      and    k.kst_detailnummer           = i_orderdetailnummer;
   end if;

   update kosten_werkbestand w
   set    w.kst_dekkingswaarde         = v_dekkingswaarde,
          w.kst_notabedrag             = v_notabedrag,
          w.kst_lopend_bedrag          = v_lopend_bedrag,
          w.kst_marginbedrag           = v_margin_bedrag,
          w.kst_wegingsfactor          = v_wegings_factor_gebruikt,
          w.kst_provisie_bedrag        = v_provisie,
          w.kst_effect_bedrag_bv       = v_effectief_bedrag_bv,
          w.kst_effect_bedrag_rv       = v_effectief_bedrag_relatieval,
          w.kst_kost_corr_doorb        = v_kost_corr,
          w.kst_effect_bedrag_rekv_sl  = v_effectief_bedrag_rekv,
          w.kst_notabedrag_rekv_sl     = v_notabedrag_rekv,
          w.kst_dekkingswaarde_rekv_sl = v_dekkingswaarde_rekv,
          w.kst_marginbedrag_rekv_sl   = v_marginbedrag_rekv,
          w.kst_lopend_bedrag_rekv_sl  = v_lopend_bedrag_rekv
   where  w.kst_ordernummer            = i_ordernummer
   and    w.kst_orderregel             = i_orderregel
   and    w.kst_detailnummer           = i_orderdetailnummer;

end lopende_orders_bereken;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_BEREKEN


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_DEKW:
-- bepalen van de dekkingswaarde voor orders. Dit gebeurt op de volgende manier:
-- Volgens de normale methodes en
-- volgens de extra spreidingseis-methode. Deze is afhankelijk van een aantal extra instellingen.
procedure lopende_orders_dekw
(i_relatie_onld_omsch       in  on_line_dossier.onld_omschrijving_1%type
,i_relatie_onld_perc        in  on_line_dossier.onld_percentage%type
,i_fonds_symbool            in  beleggingsinstrument.be_symbool%type
,i_optietype                in  beleggingsinstrument.be_optietype%type
,i_expiratiedatum           in  beleggingsinstrument.be_expiratiedatum%type
,i_exerciseprijs            in  beleggingsinstrument.be_exerciseprijs%type
,i_fonds_muntsoort          in  beleggingsinstrument.be_muntsoort%type
,i_trans_soort_tb_waarde    in  tabelgegevens.tb_waarde%type
,i_order_soort              in  kosten_werkbestand.kst_order_soort%type
,i_wegingsperc_long         in  wegingsfactoren.wg_interne_perc%type
,i_wegingsperc_short        in  wegingsfactoren.wg_intern_short_perc%type
,i_fundcategory             in  beleggingsinstrument.be_fundcategory%type
,i_effectief_bedrag_tv      in  kosten_werkbestand.kst_notabedrag%type
,i_reken_aantal             in  kosten_werkbestand.kst_trans_aantal%type
,i_begin_positie_order      in  kosten_werkbestand.kst_begin_pos_eff%type
,i_eind_positie_order       in  kosten_werkbestand.kst_eind_pos_eff%type
,i_fonds_be_bi_nummer       in  beleggingsinstrument.be_bi_nummer%type
,i_trans_context            in  contextcalculationrules.cxcr_context%type
,o_dekkingswaarde           out kosten_werkbestand.kst_dekkingswaarde%type
,o_gebr_wegingsperc         out kosten_werkbestand.kst_wegingsfactor%type
)

-- inkomende parameters zijn: i_relatie_onld_omsch       = De kredietinstelling van de klant (on line dossier instelling)
--                            i_relatie_onld_perc        = Het dekkingswaarde percentage als de klant instelling P of D heeft
--                            i_fonds_symbool            = Het fondssymbool van de order waarvoor de dekkingswaarde berekend moet worden
--                            i_optietype                = Het optietype het fonds van de order waarvoor de dekkingswaarde berekend moet worden
--                            i_expiratiedatum           = De expiratiedatum van het fonds van de order waarvoor de dekkingswaarde berekend moet worden
--                            i_exerciseprijs            = De exercisprijs van het fonds van de order waarvoor de dekkingswaarde berekend moet worden
--                            i_trans_soort_tb_waarde    = De tb_waarde van de transactiesoort van de order (1 = koop, 2 = verkoop)
--                            i_order_soort              = De order soort (B, L, SLI, etc) van de order
--                            i_wegingsperc_long         = Het long wegingspercentage dat bij het fonds hoort
--                            i_wegingsperc_short        = Het short wegingspercentage dat bij het fondshoort
--                            i_effectief_bedrag         = Het effectieve bedrag dat voor de berekening van de dekkingswaarde
--                                                         gebruikt moet worden. Dit bedrag is in de fonds (transactie) valuta!
--                            i_reken_aantal             = Het nog lopende orderaantal
--                            i_begin_positie_order      = Van belang voor verkooporders. Is de positie voordat het orderaantal is verrekend
--                            i_eind_positie_order       = Van belang voor verkooporders. Is de positie nadat het orderaantal is verrekend
--                            i_fonds_be_bi_nummer       = Het beleggingsinstrumenttype van het fonds waarin de order wordt ingelegd. Ook
--                                                         voor gebruik in de extra spreidingseis.
-- uitgaande parameters zijn: o_dekkingswaarde           = De berekende dekkingswaarde (in rapportage valuta !)
--                            o_gebr_wegingsperc         = Het wegingspercentage dat (als laatste) is gebruikt bij de berekening.

is

   v_dekkingswaarde_long         kosten_werkbestand.kst_dekkingswaarde%type       := 0;
   v_dekkingswaarde_short        kosten_werkbestand.kst_dekkingswaarde%type       := 0;
   v_effectiefbedrag_long        kosten_werkbestand.kst_notabedrag%type           := 0;
   v_effectiefbedrag_short       kosten_werkbestand.kst_notabedrag%type           := 0;

   v_grens_percentage            type_belegg_instr.bt_grens_waarde%type           := 0;
   v_extra_wegingsfactor         type_belegg_instr.bt_extra_wegingsfactor%type    := 0;
   v_positie_portef_perc         wegingsfactoren.wg_interne_perc%type             := 0;

   v_order_waarde                kosten_werkbestand.kst_effect_bedrag_rv%type     := 0;
   v_port_waarde_voor_order      positie_werkbestand.pwb_port_waarde_rapv%type    := 0;
   v_port_waarde_na_order        positie_werkbestand.pwb_port_waarde_rapv%type    := 0;
   v_fonds_portwaarde_voor_order positie_werkbestand.pwb_port_waarde_rapv%type    := 0;
   v_fonds_portwaarde_na_order   positie_werkbestand.pwb_port_waarde_rapv%type    := 0;
   v_fonds_dekkwaarde_voor_order positie_werkbestand.pwb_dekk_waarde_rapv%type    := 0;
   v_nieuwe_dekkingswaarde       kosten_werkbestand.kst_dekkingswaarde%type       := 0;
   v_extra_dekkw_berekening      number(1)                                        := 0;

   v_fonds_biedkoers             fn_quotes_vw.quot_bied%type                      := 0;
   v_dummy_num                   fn_quotes_vw.quot_laat%type                      := 0;

   v_fonds_munt_biedkoers        muntsoorten.mu_biedkoers%type                    := 0;
   v_fonds_munt_middenkoers      muntsoorten.mu_middenkoers%type                  := 0;
   v_fonds_munt_laatkoers        muntsoorten.mu_laatkoers%type                    := 0;
   v_fonds_munt_reciproke        muntsoorten.mu_reciproke%type                    := 0;
   v_fonds_munt_factor           muntsoorten.mu_factor%type                       := 0;
   v_fonds_muntkoers_gebruik     muntsoorten.mu_middenkoers%type                  := 0;
   v_rapp_muntkoers_gebruik      muntsoorten.mu_middenkoers%type                  := 0;


begin
   -- bepalen van de te gebruiken effectieve bedragen. Dit is met name van belang voor de verkopen en kopen
   -- waarbij door het nulpunt wordt gegaan (laatste 2 elsif)....
   if i_begin_positie_order >= 0 and  i_eind_positie_order >= 0
   then
      v_effectiefbedrag_long := i_effectief_bedrag_tv;
   elsif i_begin_positie_order < 0 and i_eind_positie_order <= 0
   then
      v_effectiefbedrag_short := i_effectief_bedrag_tv;
   elsif i_begin_positie_order >= 0 and i_eind_positie_order < 0
   then
      v_effectiefbedrag_short := i_effectief_bedrag_tv * abs((0-i_eind_positie_order)/i_reken_aantal);
      v_effectiefbedrag_long  := i_effectief_bedrag_tv * (i_begin_positie_order / i_reken_aantal);
   elsif i_begin_positie_order < 0 and i_eind_positie_order > 0
   then
      v_effectiefbedrag_short := i_effectief_bedrag_tv * (abs(i_begin_positie_order)/i_reken_aantal);
      v_effectiefbedrag_long  := i_effectief_bedrag_tv * (i_eind_positie_order / i_reken_aantal);
   end if;

   -- bepalen van de fondsmuntsoort gegevens als deze afwijkt van de relatie rapp valuta:
   if i_fonds_muntsoort <> gv_rel_rapp_valuta
   then
      FIAT_ALGEMEEN.valutagegevens_bepalen (i_fonds_muntsoort,        gv_relatie_pr_id,       gv_relatie_ppr_id,   gv_systspreadcodecategorie,
                                            gv_bank2mrktqchangedate,  gv_debuggen,            gv_debug_user,       v_fonds_munt_biedkoers,
                                            v_fonds_munt_middenkoers, v_fonds_munt_laatkoers, v_fonds_munt_factor, v_fonds_munt_reciproke,
                                            v_dummy_num);
   end if;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in de procedure FIAT_ORDERS.lopende_orders_dekw');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectiefbedrag short    : '||to_char(v_effectiefbedrag_short)||' ; effectiefbedrag long : '||to_char(v_effectiefbedrag_long));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'begin positie order      : '||to_char(i_begin_positie_order)||' ; eind positie order : '||to_char(i_eind_positie_order));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'wegingsfactor short      : '||to_char(i_wegingsperc_short)||' ; wegingsfactor long : '||to_char(i_wegingsperc_long));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'kredietbrief relatie     : '||gv_relatie_onld_omsch||' ; transactie context ; '||i_trans_context);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
   end if;

   -- Er is een long gedeelte om te berekenen...
   if v_effectiefbedrag_long <> 0
   then
      if i_relatie_onld_omsch = 'P'
      then
         v_dekkingswaarde_long := i_relatie_onld_perc / 100;
         o_gebr_wegingsperc    := v_dekkingswaarde_long;
      else
         v_dekkingswaarde_long := i_wegingsperc_long / 100;
         o_gebr_wegingsperc    := v_dekkingswaarde_long;
      end if;

      v_dekkingswaarde_long := v_dekkingswaarde_long * v_effectiefbedrag_long;

      if i_relatie_onld_omsch = 'D' or i_relatie_onld_omsch = 'L'
      then
         v_dekkingswaarde_long := v_dekkingswaarde_long * i_relatie_onld_perc / 100;
      end if;
      -- als laatste stap moet nog omgerekend worden naar relatie valuta als de valuta's afwijken
      if i_fonds_muntsoort <> gv_rel_rapp_valuta
      then
         select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_dekkingswaarde_long,  v_fonds_munt_reciproke, v_fonds_munt_factor, v_fonds_munt_laatkoers,
                                                   v_fonds_munt_laatkoers, gv_rel_rapp_reciproke,  gv_rel_rapp_factor,  gv_rel_rapp_biedkoers,
                                                   gv_rel_rapp_biedkoers,  gv_rel_rapp_notatie)
         into   v_dekkingswaarde_long
         from   dual;
      end if;
   end if;

   -- Er is een short gedeelte om te berekenen...
   if v_effectiefbedrag_short <> 0
   then
      if i_relatie_onld_omsch = 'P'
      then
         v_dekkingswaarde_short := (200 - i_relatie_onld_perc)/100;
         o_gebr_wegingsperc     := v_dekkingswaarde_short;
      else
         v_dekkingswaarde_short := i_wegingsperc_short / 100;
         o_gebr_wegingsperc     := v_dekkingswaarde_short;
      end if;

      v_dekkingswaarde_short := v_dekkingswaarde_short * v_effectiefbedrag_short;

      if i_relatie_onld_omsch = 'D' or i_relatie_onld_omsch = 'L'
      then
         v_dekkingswaarde_short := v_dekkingswaarde_short * (200 - i_relatie_onld_perc)/100;
      end if;
      -- als laatste stap moet nog omgerekend worden naar relatie valuta als de valuta's afwijken
      if i_fonds_muntsoort <> gv_rel_rapp_valuta
      then
         select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_dekkingswaarde_short, v_fonds_munt_reciproke, v_fonds_munt_factor, v_fonds_munt_biedkoers,
                                                   v_fonds_munt_biedkoers, gv_rel_rapp_reciproke,  gv_rel_rapp_factor,  gv_rel_rapp_laatkoers,
                                                   gv_rel_rapp_laatkoers,  gv_rel_rapp_notatie)
         into   v_dekkingswaarde_short
         from   dual;
      end if;
   end if;

o_dekkingswaarde := v_dekkingswaarde_long + v_dekkingswaarde_short;

if gv_debuggen = 1
then
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Einde berekenen "normale dekkingswaarde"');
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'dekkingswaarde long    : '||to_char(v_dekkingswaarde_long)||' ; dekkingswaarde short : '||to_char(v_dekkingswaarde_short));
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'dekkingswaarde totaal  : '||to_char(o_dekkingswaarde)||' dit is dus voordat "E" dekkingswaarde wordt berekend ');
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
end if;

-- Eventueel corrigeren voor de Extraspreidingseis
-- Alleen als klant als kredietbrief "Extra spreidingseis" en als het wegingspercentage ongelijk 0 is
if i_relatie_onld_omsch = 'E' and i_wegingsperc_long <> 0
then

   -- Eerst een aantal instellingen op beleggingsinstrumenttype niveau bepalen
   select t.bt_grens_waarde,  t.bt_extra_wegingsfactor
   into   v_grens_percentage, v_extra_wegingsfactor
   from   type_belegg_instr t
   where  t.bt_type = i_fonds_be_bi_nummer;

   -- wat is de totale portefeuille waarde bij aanvang van de berekening?
   select w.wk_waarde_1
   into   v_port_waarde_voor_order
   from   werkbestand w
   where  w.wk_terminal = gv_terminalnummer
   and    w.wk_soort    = 'OREP';

   -- wat zijn de diverse fondsgerelateerde gegevens?
   select w.wk_waarde_1,                 w.wk_waarde_2
   into   v_fonds_portwaarde_voor_order, v_fonds_dekkwaarde_voor_order
   from   werkbestand w
   where  w.wk_terminal    = gv_terminalnummer
   and    w.wk_soort       = 'OREF'
   and    w.wk_categorie_1 = i_fonds_symbool
   and    w.wk_categorie_2 = i_optietype
   and    w.wk_categorie_3 = to_char(i_exerciseprijs)
   and    w.wk_datum_1     = i_expiratiedatum;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In order Extra spreidingseis');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Grens percentage : '||to_char(v_grens_percentage)||' ;  extra wegingsfactor : '||to_char(v_extra_wegingsfactor));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'port waarde voor order : '||to_char(v_port_waarde_voor_order)||' ;  portwaarde fonds voor order : '||to_char(v_fonds_portwaarde_voor_order));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'dekkingswaarde fonds voor order : '||to_char(v_fonds_dekkwaarde_voor_order));
   end if;

   -- Eerst de bedragen bepalen zoals ze zouden zijn na uitvoering van de order
   -- De bedragen waarmee gerekend moet worden zijn in de rapp valuta, ze worden echter in transactie valuta aangeleverd. Dus nog omrekenen.
   if i_trans_soort_tb_waarde = 1
   then
      v_order_waarde := i_effectief_bedrag_tv;
   elsif i_trans_soort_tb_waarde = 2 and i_order_soort not in ('L','SLI')
   then
      v_order_waarde := -1 * i_effectief_bedrag_tv;
   -- Voor limiet en stop limit verkoop orders moet het effectief bedrag opnieuw worden berekend, maar nu met behulp van koers van het fonds om
   -- te grote afwijkingen tussen limietprijs en daadwerkelijke koers te voorkomen.
   elsif i_trans_soort_tb_waarde = 2 and i_order_soort in ('L','SLI')
   then
      -- Als eerste de biedfondskoers bepalen om af te dwingen dat deze gebruikt gaat worden
      FIAT_ALGEMEEN.fondskoersen (i_fonds_symbool, i_optietype, i_expiratiedatum, i_exerciseprijs, gv_slot_of_laatste_koers, v_fonds_biedkoers, v_dummy_num);

      FIAT_NOTABEDRAG.notabedrag_bereken (gv_order_nummer,      gv_order_regel,             gv_order_detailregel,      gv_order_orx_id,
                                          gv_rel_productnummer, gv_rel_product_volgnr,      gv_slot_of_laatste_koers,  1,
                                          v_fonds_biedkoers,    1,                          1,                         0,
                                          gv_instellingen,      gv_systspreadcodecategorie, gv_bank2mrktqchangedate,   
                                          i_trans_context,      gv_terminalnummer,          gv_belgisch_spaar_product, 
                                          0,                    0,                          gv_legal_entity_type,      gv_eor_kenmerk_id,
                                          i_fundcategory,       v_dummy_num,                v_dummy_num,               v_order_waarde);

      if v_order_waarde >= 0
      then
         v_order_waarde := -1 * v_order_waarde;
      end if;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In order Extra spreidingseis, in het onderdeel Limiet/Stop Limit verkoop orders voor herberekenen effectieve waarde');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Fonds biedkoers : '||to_char(v_fonds_biedkoers)||' ;  effectieve waarde in tv : '||to_char(v_order_waarde));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
      end if;
   end if;

   -- als er omgerekend moet worden, dan hier de koersen bepalen zodat er netjes omgerekend kan worden
   if i_fonds_muntsoort <> gv_rel_rapp_valuta
   then
      FIAT_ALGEMEEN.muntkoers_bepalen (i_trans_soort_tb_waarde,  0,                      v_fonds_munt_reciproke,   v_fonds_munt_biedkoers,
                                       v_fonds_munt_middenkoers, v_fonds_munt_laatkoers, v_fonds_muntkoers_gebruik);
      FIAT_ALGEMEEN.muntkoers_bepalen (i_trans_soort_tb_waarde,  1,                      gv_rel_rapp_reciproke,    gv_rel_rapp_biedkoers,
                                       gv_rel_rapp_middenkoers,  gv_rel_rapp_laatkoers,  v_rapp_muntkoers_gebruik);

      select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_order_waarde, v_fonds_munt_reciproke, v_fonds_munt_factor, v_fonds_muntkoers_gebruik,
                                                v_fonds_muntkoers_gebruik, gv_rel_rapp_reciproke, gv_rel_rapp_factor, v_rapp_muntkoers_gebruik,
                                                v_rapp_muntkoers_gebruik, gv_rel_rapp_notatie)
      into   v_order_waarde
      from   dual;
   end if;

   v_fonds_portwaarde_na_order := v_fonds_portwaarde_voor_order + v_order_waarde;

   -- Bij een negatieve begin positie, alleen het deel boven nul meenemen voor de berekening van de port waarde na order
   if i_begin_positie_order < 0 and i_eind_positie_order > 0
   then
      v_port_waarde_na_order      := v_port_waarde_voor_order + v_fonds_portwaarde_na_order;
   -- Bij een positieve begin positie en een negatieve eind positie de portefeuille waarde aanpassen naar het nul punt
   elsif i_begin_positie_order > 0 and i_eind_positie_order < 0
   then
      v_port_waarde_na_order      := v_port_waarde_voor_order - v_fonds_portwaarde_voor_order;
   -- Als begin en eind posities onder nul zijn, dan is de portefeuille waarde na gelijk aan de portefeuille waarde voor de order
   elsif i_begin_positie_order <= 0 and i_eind_positie_order < 0
   then
      v_port_waarde_na_order      := v_port_waarde_voor_order;
   else
      v_port_waarde_na_order      := v_port_waarde_voor_order + v_order_waarde;
   end if;

   -- koersverschillen (limietprijs en fondskoersen) bij een eindpositie van 0 in ieder geval voorkomen:
   if i_eind_positie_order = 0
   then
      v_fonds_portwaarde_na_order := 0;
   end if;

   -- Als de eind positie kleiner is dan 0 en de begin positie groter, dan het deel van de bestaande dekkingswaarde op tellen bij de berekende short dekkingswaarde
   if v_grens_percentage <> 0 and i_eind_positie_order < 0 and i_begin_positie_order > 0
   then
      o_dekkingswaarde := v_fonds_dekkwaarde_voor_order + v_dekkingswaarde_short;

   -- Doorgaan als het grens percentage ongelijk 0 is en als de eindpositie groter gelijk aan 0 is
   elsif v_grens_percentage <> 0 and i_eind_positie_order >= 0
   then
      -- Als de order waarde 0 is (omdat bijvoorbeeld een 0-koers is), dan is geen dekkingswaarde te berekenen en wordt de dekkingswaarde dus 0:
      if v_order_waarde = 0
      then
         o_dekkingswaarde := 0;
      else
         -- bepalen van het positie portefeuille percentage
         if v_fonds_portwaarde_na_order <> 0
         then
            if (v_fonds_portwaarde_na_order/v_port_waarde_na_order) * 100 > 100  -- Als het percentage meer dan 100 wordt
            then                                                                 -- dan maximaal 100 berekenen, anders wordt
               v_positie_portef_perc := 100;                                     -- in dit geval geld gegenereerd !!!
            elsif (v_fonds_portwaarde_na_order/v_port_waarde_na_order) * 100 < -999.999
            then
               v_positie_portef_perc := -999.999;
            else
               v_positie_portef_perc := round((v_fonds_portwaarde_na_order/v_port_waarde_na_order)*100,3);
            end if;
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fonds muntkoers te gebruiken    : '||to_char(v_fonds_muntkoers_gebruik)||' ; rapp muntkoers te gebruiken : '||to_char(v_rapp_muntkoers_gebruik));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'port waarde na order : '||to_char(v_port_waarde_na_order)||' ;  fonds portwaarde na order : '||to_char(v_fonds_portwaarde_na_order));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'waarde van de order : '||to_char(v_order_waarde)||'  ; positie portefeuille percentage : '||to_char(v_positie_portef_perc));
         end if;

         -- Er zijn een vijftal mogelijkheden voor de berekeningen:
         -- 1. Orderfonds blijft voor en na de order onder het grenspercentage
         -- 2. Orderfonds is voor de order boven het grenspercentage en het aantal in positie wordt door de order 0
         -- 3. Orderfonds is voor de order onder de grenswaarde en na de order boven het grenspercentage
         -- 4. Orderfonds is voor en na de order boven het grenspercentage en er blijft positie in het orderfonds
         -- 5. Orderfonds is voor de order boven het grenspercentage en na de order komt het onder het grenspercentage en er blijft positie in het orderfonds

         -- Situatie 1. Orderfonds blijft voor en na de order onder het grenspercentage
         -- Deze situatie is in het eerste deel van de procedure al uitgerekend daarvoor hoeft dus niets gedaan te worden.
         -- Hier wordt niet actief opgechekct. De overige situaties worden niet uitgevoerd en daardoor wordt niets opnieuw berekend....

         -- Situatie 2. Orderfonds is voor de order boven het grenspercentage en het aantal in positie wordt door de order 0
         if v_fonds_portwaarde_voor_order >= v_grens_percentage/100 * v_port_waarde_voor_order
            and
            v_port_waarde_voor_order <> 0    -- Als v_port_waarde_voor_order 0 is dan is er geen positief bevoorschotbaar fonds in positie
            and                              -- en is het orderfonds voor de order dus niet in positie.
            i_eind_positie_order = 0
         then
            -- Het positie-portefeuille-percentage moet berekend worden met de waardes voor order
            if (v_fonds_portwaarde_voor_order/v_port_waarde_voor_order) * 100 > 100
            then
               v_positie_portef_perc := 100;
            elsif (v_fonds_portwaarde_voor_order/v_port_waarde_voor_order) * 100 < -999.999
            then
               v_positie_portef_perc := -999.999;
            else
               v_positie_portef_perc := round((v_fonds_portwaarde_voor_order/v_port_waarde_voor_order)*100,3);
            end if;

            v_nieuwe_dekkingswaarde := (v_grens_percentage/v_positie_portef_perc * i_wegingsperc_long/100 * abs(v_order_waarde) +
                                       ((v_positie_portef_perc - v_grens_percentage)/v_positie_portef_perc * v_extra_wegingsfactor/100 *
                                       i_wegingsperc_long/100 * abs(v_order_waarde)));

            o_dekkingswaarde := -1 * v_nieuwe_dekkingswaarde;  --Deze situatie kan alleen bij een verkoop optreden
            o_gebr_wegingsperc := round((v_grens_percentage/v_positie_portef_perc * i_wegingsperc_long/100) + ((v_positie_portef_perc - v_grens_percentage)/v_positie_portef_perc
                                       * v_extra_wegingsfactor/100 * i_wegingsperc_long/100),3);

            -- omdat de portefeuille waarde van het fonds naar 0 gaat, gaat ook de nieuwe dekkingswaarde naar 0. Omdat correct vast te leggen moet dat nog wel
            -- worden gezet (nb NIET voor het zetten van o_dekkingswaarde !!!, want daar moet het bedrag wel in worden vastgelegd !!)
            v_nieuwe_dekkingswaarde := 0;

            -- aangeven dat een berekening is uitgevoerd:
            v_extra_dekkw_berekening := 1;

            if gv_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In situatie 2 Orderfonds voor de order boven het grensperc en aantal in pos wordt 0 door order');
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'positie portefeuille percentage : '||to_char(v_positie_portef_perc));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'nieuwe dekkingswaarde : '||to_char(o_dekkingswaarde)||'  ; gebruikt wegingsperc : '||to_char(o_gebr_wegingsperc));
            end if;

         -- Situaties 3 en 4 worden op dezelfde manier afgehandeld en kunnen dus worden samengenomen.
         -- Situatie 3. Orderfonds is voor de order onder de grenswaarde en na de order boven het grenspercentage
         -- Situatie 4. Orderfonds is voor en na de order boven het grenspercentage en er blijft positie in het orderfonds
         elsif (v_fonds_portwaarde_voor_order < v_grens_percentage/100 * v_port_waarde_voor_order
                and
                v_fonds_portwaarde_na_order >= v_grens_percentage/100 * v_port_waarde_na_order)
               or
               (v_fonds_portwaarde_voor_order >= v_grens_percentage/100 * v_port_waarde_voor_order
                and
                v_fonds_portwaarde_na_order >= v_grens_percentage/100 * v_port_waarde_na_order
                and
                i_eind_positie_order <> 0)
         then
            -- Dekkingswaarde nieuwe positie is:
            v_nieuwe_dekkingswaarde := (v_grens_percentage/v_positie_portef_perc * i_wegingsperc_long/100 * v_fonds_portwaarde_na_order) +
                                       ((v_positie_portef_perc - v_grens_percentage)/v_positie_portef_perc * v_extra_wegingsfactor/100 *
                                        i_wegingsperc_long/100 * v_fonds_portwaarde_na_order);

            -- Het dekkingswaarde effect berekenen voor de order (dekkingswaarde nieuw - oud)
            o_dekkingswaarde   := v_nieuwe_dekkingswaarde - v_fonds_dekkwaarde_voor_order;
            o_gebr_wegingsperc := round((v_grens_percentage/v_positie_portef_perc * i_wegingsperc_long/100) + ((v_positie_portef_perc - v_grens_percentage)/v_positie_portef_perc
                                        * v_extra_wegingsfactor/100 * i_wegingsperc_long/100),3);

            -- aangeven dat een berekening is uitgevoerd:
            v_extra_dekkw_berekening := 1;

            if gv_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In situaties 3 en 4 Orderfonds komt of blijft boven het grensperc');
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'nieuwe dekkingswaarde : '||to_char(v_nieuwe_dekkingswaarde)||' ; dekkingswaarde voor order : '||
                                                        to_char(v_fonds_dekkwaarde_voor_order));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'positie portefeuille percentage : '||to_char(v_positie_portef_perc));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'nieuwe dekkingswaarde : '||to_char(o_dekkingswaarde)||'  ; gebruikt wegingsperc : '||to_char(o_gebr_wegingsperc));
            end if;

         -- Situatie 5. Orderfonds is voor de order boven het grenspercentage en na de order komt het onder het grenspercentage en er blijft positie in het orderfonds
         elsif v_fonds_portwaarde_voor_order >= v_grens_percentage/100 * v_port_waarde_voor_order
               and
               v_fonds_portwaarde_na_order < v_grens_percentage/100 * v_port_waarde_na_order
               and
               i_eind_positie_order <> 0
         then
            -- De dekkingswaarde van de eindpositie moet berekend worden met de standaard wegingsfactor
            v_nieuwe_dekkingswaarde := v_fonds_portwaarde_na_order * i_wegingsperc_long / 100;

            -- Het dekkingswaarde effect berekenen voor de order (dekkingswaarde nieuw - oud)
            o_dekkingswaarde   := v_nieuwe_dekkingswaarde - v_fonds_dekkwaarde_voor_order;
            o_gebr_wegingsperc := i_wegingsperc_long / 100;

            -- aangeven dat een berekening is uitgevoerd:
            v_extra_dekkw_berekening := 1;

            if gv_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In situatie 5 Orderfonds van de order begint boven het grensperc eindigt er onder, maar blijft in positie');
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'positie portefeuille percentage : '||to_char(v_positie_portef_perc));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'nieuwe dekkingswaarde : '||to_char(o_dekkingswaarde)||'  ; gebruikt wegingsperc : '||to_char(o_gebr_wegingsperc));
            end if;

         -- om het wegschrijven van de gegevens toch goed te laten gebeuren moet hier voor situatie 1 toch nieuwe dekkingswaarde worden gezet
         else
            v_nieuwe_dekkingswaarde := v_fonds_dekkwaarde_voor_order + o_dekkingswaarde * (case when i_trans_soort_tb_waarde = 2 then -1 else 1 end);
         end if;

         -- voor verkopen hier het teken omdraaien zodat in de aanroepende procedure met het goede teken wordt gewerkt
         if i_trans_soort_tb_waarde = 2 and v_extra_dekkw_berekening = 1
         then
            o_dekkingswaarde := -1 * o_dekkingswaarde;
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In het deel van onld omschrijving E');
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Dekkingswaarde fonds positie : '||to_char(v_fonds_dekkwaarde_voor_order)
                                                     ||' ; nieuwe dekkingswaarde : '||to_char(v_nieuwe_dekkingswaarde));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'dekkingswaarde uit : '||to_char(o_dekkingswaarde));
         end if;

      end if; -- einde van v_waarde_order = 0
   end if;

   -- De totale portefeuille waarde aanpassen
   -- Maar als de portefeuille waarde na de order negatief is, deze op 0 zetten:
   if v_port_waarde_na_order <0
   then
      v_port_waarde_na_order := 0;
   end if;

   update werkbestand w
   set    w.wk_waarde_1 = v_port_waarde_na_order
   where  w.wk_terminal = gv_terminalnummer
   and    w.wk_soort    = 'OREP';

   update werkbestand w
   set    w.wk_waarde_1    = v_fonds_portwaarde_na_order,
          w.wk_waarde_2    = v_nieuwe_dekkingswaarde
   where  w.wk_terminal    = gv_terminalnummer
   and    w.wk_soort       = 'OREF'
   and    w.wk_categorie_1 = i_fonds_symbool
   and    w.wk_categorie_2 = i_optietype
   and    w.wk_categorie_3 = to_char(i_exerciseprijs)
   and    w.wk_datum_1     = i_expiratiedatum;

end if;

o_dekkingswaarde := round(o_dekkingswaarde,gv_basis_val_notatie);

if gv_debuggen = 1
then
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'totale dekkingswaarde : '||to_char(o_dekkingswaarde));
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
end if;

end lopende_orders_dekw;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_DEKW


-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_DEKW_FNDS_BEREK
-- Procedure voor het berekenen/bepalen van een aantal waarden die nodig zijn voor
-- de berekening van de dekkingswaarde vanuit de dekkingswaarde_loop procedure
procedure lopende_orders_dekw_fnds_berek
(i_relatienummer                    in      kosten_werkbestand.kst_relatie_nummer%type
,i_order_depot                      in      kosten_werkbestand.kst_depot%type
,i_order_depot_reksoort             in      kosten_werkbestand.kst_depotreksrt%type
,i_ex_as_factor_optie               in      beleggingsinstrument.be_exass_factor%type
,i_referentiesymbool                in      beleggingsinstrument.be_referentiesymbool%type
,i_fondssymbool                     in      beleggingsinstrument.be_symbool%type
,i_transactiesoort                  in      orders.ord_transactiesoort%type
,i_transactie_soort_tb_waarde       in      transactiesoorten.ts_koop_verkoop_ind%type
,i_rekenaantal                      in      kosten_werkbestand.kst_trans_aantal%type
,i_mandjes_factor                   in      mandje_onderliggende_waarde.mnd_factor%type
,i_order_externe_referentie         in      orders.ord_externe_referentie%type
,o_wegingsfactor_long               out     wegingsfactoren.wg_interne_perc%type
,o_wegingsfactor_short              out     wegingsfactoren.wg_eff_short_perc%type
,o_begin_positie_order              out     kosten_werkbestand.kst_begin_pos_eff%type
,o_eind_positie_order               out     kosten_werkbestand.kst_eind_pos_eff%type
,o_aantal_ow                        out     kosten_werkbestand.kst_trans_aantal%type
,o_effectiefbedrag_rv               out     kosten_werkbestand.kst_effect_bedrag_rv%type
,o_effectiefbedrag_tv               out     kosten_werkbestand.kst_effect_bedrag_rv%type
)

-- Inkomende parameters zijn: i_relatienummer        = het nummer van de relatie uit de order
--                            i_order_depot          = Het depot uit de order
--                            i_order_depot_reksoort = Het depot rekeningsoort uit de order
--                            i_ex_as_factor_optie   = De exercise/assignment factor van een optie
--                            i_referentiesymbool    = Het referentiesymbool van een optie
--                            i_transactiesoort      = Het transactiesoort van de order
--                            i_rekenaantal          = Het nog lopende order aantal
-- Uitgaande parameters zijn  o_wegingsfactor_long   = De long wegingsfactor van de ow van de optie
--                            o_wegingsfactor_short  = De short wegingsfactor van de ow van de optie
--                            o_begin_positie_order  = De beginpositie in het referentiefonds van de optie
--                            o_eind_positie_order   = De eindpositie in het referentiefonds van de optie

is

  v_te_gebruiken_fonds            beleggingsinstrument.be_symbool%type;
  v_aantal_cijfers_display        beleggingsinstrument.be_aantal_cijfers_display%type;
  v_be_bi_nummer                  beleggingsinstrument.be_bi_nummer%type;
  v_valdat_transdat               beleggingsinstrument.be_valdat_transdat%type;
  v_fonds_beursnummer             beleggingsinstrument.be_br_nummer%type;
  v_rente_factor                  number(14,9);
  v_rekendatum                    varchar2(8);
  v_rente_bedrag_transval         transakties.tr_rente%type;
  v_symbool_prijs_factor          beleggingsinstrument.be_prijs_factor%type;
  v_ref_symbool_wegings_fac       beleggingsinstrument.be_wg_factor%type;
  v_wegingsperc_long              wegingsfactoren.wg_interne_perc%type;
  v_wegingsperc_short             wegingsfactoren.wg_intern_short_perc%type;

  v_be_muntsoort                  beleggingsinstrument.be_muntsoort%type;
  v_be_munt_notatie               muntsoorten.mu_notatie%type;
  v_be_munt_factor                muntsoorten.mu_factor%type;
  v_be_munt_biedkoers             muntsoorten.mu_biedkoers%type;
  v_be_munt_laatkoers             muntsoorten.mu_laatkoers%type;
  v_be_munt_reciproke             muntsoorten.mu_reciproke%type;
  v_fonds_biedkoers               fn_quotes_vw.quot_bied%type;
  v_fonds_laatkoers               fn_quotes_vw.quot_laat%type;
  v_dummy_waarde                  muntsoorten.mu_middenkoers%type;

  v_bedrag_aantal_teken           number(1);

  v_aantal_ow                     kosten_werkbestand.kst_trans_aantal%type;
  v_effectief_bedrag_rv           kosten_werkbestand.kst_effect_bedrag_rv%type;
  v_effectief_bedrag_tv           kosten_werkbestand.kst_effect_bedrag_rv%type;

  v_begin_positie_order           kosten_werkbestand.kst_begin_pos_eff%type;
  v_eind_positie_order            kosten_werkbestand.kst_eind_pos_eff%type;
  v_positie_in_fonds              positie_werkbestand.pwb_saldo_positie%type;
  v_effect_lopende_orders_aant    positie_werkbestand.pwb_effect_lop_ord%type;
  v_port_waarde_positie_fonds     positie_werkbestand.pwb_port_waarde_rapv%type;
  v_dekk_waarde_positie_fonds     positie_werkbestand.pwb_dekk_waarde_rapv%type;
  v_positie_rowid                 rowid;
  v_OREF_record_gevonden          number(1);


begin

-- Fonds gegevens bepalen
if i_transactiesoort in ('EX P','EX C')
then
   v_te_gebruiken_fonds := i_referentiesymbool;
else
   v_te_gebruiken_fonds := i_fondssymbool;
end if;

-- Stap 1. Bekijk of de OW/Fonds een mandje is
select b.be_prijs_factor,           b.be_wg_factor,            b.be_muntsoort,
       b.be_aantal_cijfers_display, b.be_bi_nummer,            b.be_valdat_transdat,
       b.be_bv_beurs
into   v_symbool_prijs_factor,      v_ref_symbool_wegings_fac, v_be_muntsoort,
       v_aantal_cijfers_display,    v_be_bi_nummer,            v_valdat_transdat,
       v_fonds_beursnummer
from   beleggingsinstrument b
where  b.be_symbool        = v_te_gebruiken_fonds
and    b.be_optietype      = ' '
and    b.be_expiratiedatum = '00000000'
and    b.be_exerciseprijs  = 0;

-- het bedrag_aantal_teken geeft een 1 of -1 aan en wordt gebruikt voor een aantal bepalingen
if i_transactiesoort in ('EX P','V','L')
then
   v_bedrag_aantal_teken := -1;
else
   v_bedrag_aantal_teken := 1;
end if;

-- Bereken eerst de effectieve waarde voor de aandeelpositie
FIAT_ALGEMEEN.fondskoersen (v_te_gebruiken_fonds, ' ', '00000000',0, gv_slot_of_laatste_koers, v_fonds_biedkoers, v_fonds_laatkoers);

if i_transactiesoort in ('EX C','EX P')
then
   v_aantal_ow           := i_rekenaantal * i_ex_as_factor_optie * i_mandjes_factor;
   v_effectief_bedrag_tv := v_aantal_ow * v_symbool_prijs_factor * case when v_bedrag_aantal_teken = -1 then v_fonds_laatkoers else v_fonds_biedkoers end
                            * v_bedrag_aantal_teken;
else
   v_aantal_ow           := i_rekenaantal;
   v_effectief_bedrag_tv := v_aantal_ow * (case when v_aantal_cijfers_display <> 0 then v_symbool_prijs_factor else 1 end) *
                            (case when v_be_bi_nummer between 200 and 299 then v_symbool_prijs_factor else 1 end) *
                            (case when v_bedrag_aantal_teken = -1 then v_fonds_laatkoers else v_fonds_biedkoers end) * v_bedrag_aantal_teken;
   -- lopende rente nog berekenen voor de obligaties. Deze moet ook mee.
   if v_be_bi_nummer between 200 and 299
   then
      v_rente_factor          := 0;

      if i_order_externe_referentie = 0
      then
         -- bepalen van de v_rekendatum (dus de datum waarmee de lopende rente berekend moet worden):
         if v_valdat_transdat = 'V'
         then
            -- de valutadatum is gelijk aan de settlementdatum (dus daarom hier settlementdatum bepalen)
            FIAT_ALGEMEEN.bereken_settl_dat(v_fonds_beursnummer, i_transactie_soort_tb_waarde, to_char(SYSDATE,'yyyymmdd'),v_rekendatum);
         else
            v_rekendatum := to_char(SYSDATE,'yyyymmdd');
         end if;
      -- als het wel een productconversie is, dan de actiedatum als rente rekendatum:
      else
         select p.capc_actiedatum
         into   v_rekendatum
         from   productconversies p
         where  p.capc_dossiernummer = i_order_externe_referentie;
      end if;

      -- bepalen van de rente factor
      select FIAT_ALGEMEEN.rente_factor_berek(v_te_gebruiken_fonds, v_rekendatum, gv_debuggen, gv_debug_user)
      into   v_rente_factor
      from   dual;

      v_rente_factor := nvl(round(v_rente_factor,9),0);

      -- berekenen van het uiteindelijke rentebedrag:
      v_rente_bedrag_transval := i_rekenaantal * v_rente_factor * v_symbool_prijs_factor;

      v_effectief_bedrag_tv := v_effectief_bedrag_tv + v_rente_bedrag_transval * v_bedrag_aantal_teken;
   end if;
end if;



if gv_debuggen = 1
then
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In procedure lopende orders dekkingswaarde fonds berekenen ');
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'te gebruiken fonds  : '||v_te_gebruiken_fonds||' ; aantal  : '||to_char(v_aantal_ow));
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'wegingsfactor fonds : '||to_char(v_ref_symbool_wegings_fac)||' ; aantal cijfers display : '||to_char(v_aantal_cijfers_display));
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fonds biedkoers     : '||to_char(v_fonds_biedkoers)||' ; fonds laatkoers : '||to_char(v_fonds_laatkoers));
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'bedrag aantal teken : '||to_char(v_bedrag_aantal_teken)||' ; effectief bedrag tv : '||to_char(v_effectief_bedrag_tv));
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'lopende rente       : '||to_char(v_rente_bedrag_transval)||' ; rente factor : '||to_char(v_rente_factor));
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
end if;

-- omrekenen naar relatie valuta:
if v_be_muntsoort <> gv_rel_rapp_valuta
then
   FIAT_ALGEMEEN.valutagegevens_bepalen (v_be_muntsoort,          gv_relatie_pr_id,    gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                         gv_bank2mrktqchangedate, gv_debuggen,         gv_debug_user,     v_be_munt_biedkoers,
                                         v_dummy_waarde,          v_be_munt_laatkoers, v_be_munt_factor,  v_be_munt_reciproke,
                                         v_be_munt_notatie);

   select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_effectief_bedrag_tv, v_be_munt_reciproke,   v_be_munt_factor,   v_be_munt_biedkoers,
                                             v_be_munt_laatkoers,   gv_rel_rapp_reciproke, gv_rel_rapp_factor, gv_rel_rapp_biedkoers,
                                             gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
   into   v_effectief_bedrag_rv
   from   dual;
else
   v_effectief_bedrag_rv := v_effectief_bedrag_tv;
end if;

-- Wat zijn de long wegingspercentages van het referentiesymbool?
begin
    select w.wg_interne_perc,  w.wg_eff_short_perc
    into   v_wegingsperc_long, v_wegingsperc_short
    from   wegingsfactoren w
    where  w.wg_nummer = v_ref_symbool_wegings_fac;
exception
    when no_data_found
    then
       v_wegingsperc_long  := 0;
       v_wegingsperc_short := 0;
end;

-- Bepalen van het effect van de lopende orders op deze exercise ...
-- Bepalen van het uitgangspunt voor deze order aan de hand van de positie
begin
   select p.pwb_effect_lop_ord,         p.pwb_port_waarde_rapv,      p.pwb_dekk_waarde_rapv,
          p.pwb_saldo_positie,          p.rowid
   into   v_effect_lopende_orders_aant, v_port_waarde_positie_fonds, v_dekk_waarde_positie_fonds,
          v_positie_in_fonds,           v_positie_rowid
   from   positie_werkbestand p
   where  p.pwb_relatie_nummer  = i_relatienummer
   and    p.pwb_rekening_nummer = i_order_depot
   and    p.pwb_rekening_soort  = i_order_depot_reksoort
   and    p.pwb_symbool         = v_te_gebruiken_fonds
   and    p.pwb_optietype       = ' '
   and    p.pwb_expiratiedatum  = '00000000'
   and    p.pwb_exerciseprijs   = 0;

exception
   when no_data_found
   then
      v_positie_in_fonds           := 0;
      v_effect_lopende_orders_aant := 0;
      v_port_waarde_positie_fonds  := 0;
      v_dekk_waarde_positie_fonds  := 0;
      v_positie_rowid              := ' ';
end;

if gv_relatie_onld_omsch = 'E' and v_wegingsperc_long <> 0
then
   -- voor E moeten we altijd de positie verwerken. Dit omdat anders bij uitvoering van een order opeens kan blijken dat
   -- de dekkingswaarde kleiner (en dus het effect negatiever) blijkt te zijn. Hierdoor kunnen klanten een negatieve best.ruimte krijgen.
   begin
       v_OREF_record_gevonden := 1;

       select w.wk_waarde_3,         w.wk_waarde_4
       into   v_begin_positie_order, v_eind_positie_order
       from   werkbestand w
       where  w.wk_terminal    = gv_terminalnummer
       and    w.wk_soort       = 'OREF'
       and    w.wk_categorie_1 = v_te_gebruiken_fonds
       and    w.wk_categorie_2 = ' '
       and    w.wk_categorie_3 = '0'
       and    w.wk_datum_1     = '00000000';
   exception
       when no_data_found
       then
          v_OREF_record_gevonden := 0;
   end;

   -- voor deze order is het eindpunt van de vorige order het beginpunt
   if v_OREF_record_gevonden = 0
   then
      v_begin_positie_order     := nvl(v_effect_lopende_orders_aant,0);
   else
      v_begin_positie_order     := nvl(v_eind_positie_order,0);
   end if;
   v_effect_lopende_orders_aant := v_begin_positie_order + ABS(v_aantal_ow) * v_bedrag_aantal_teken;
   v_eind_positie_order         := v_effect_lopende_orders_aant;

   if v_OREF_record_gevonden = 0
   then
      -- Bij een insert de dekkingswaarde en fondswaarde opslaan, bij een update niet meer !!
      insert into werkbestand w
      (w.wk_terminal,                    w.wk_soort,          w.wk_categorie_1,            w.wk_categorie_2,
       w.wk_categorie_3,                 w.wk_datum_1,        w.wk_waarde_1,               w.wk_waarde_2,
       w.wk_waarde_3,                    w.wk_waarde_4)
      values
      (gv_terminalnummer,                'OREF',               v_te_gebruiken_fonds,        ' ',
       '0',                              '00000000',           v_port_waarde_positie_fonds, v_dekk_waarde_positie_fonds,
        v_begin_positie_order,            v_eind_positie_order);
   elsif v_OREF_record_gevonden = 1
   then
      update werkbestand w
      set    w.wk_waarde_3    = v_begin_positie_order,
             w.wk_waarde_4    = v_eind_positie_order
      where  w.wk_terminal    = gv_terminalnummer
      and    w.wk_soort       = 'OREF'
      and    w.wk_categorie_1 = v_te_gebruiken_fonds
      and    w.wk_categorie_2 = ' '
      and    w.wk_categorie_3 = '0'
      and    w.wk_datum_1     = '00000000';
   end if;

elsif gv_relatie_onld_omsch = 'E' and v_wegingsperc_long = 0
then
   v_begin_positie_order        := v_positie_in_fonds;
   v_eind_positie_order         := v_begin_positie_order + v_bedrag_aantal_teken * ABS(v_aantal_ow);
elsif i_transactiesoort in ('EX P', 'V','L')
then
   v_begin_positie_order        := v_effect_lopende_orders_aant;
   v_effect_lopende_orders_aant := v_effect_lopende_orders_aant + v_bedrag_aantal_teken * ABS(v_aantal_ow);
   v_eind_positie_order         := v_begin_positie_order + v_bedrag_aantal_teken * ABS(v_aantal_ow);

   if v_positie_rowid <> ' '
   then
      update positie_werkbestand pw
      set    pw.pwb_effect_lop_ord  = v_effect_lopende_orders_aant
      where  pw.rowid               = v_positie_rowid;
   end if;
else
   v_begin_positie_order        := 0;
   v_eind_positie_order         := 0;
end if;


o_wegingsfactor_long  := v_wegingsperc_long;
o_wegingsfactor_short := v_wegingsperc_short;
o_begin_positie_order := v_begin_positie_order;
o_eind_positie_order  := v_eind_positie_order;
o_aantal_ow           := v_aantal_ow;
o_effectiefbedrag_rv  := v_effectief_bedrag_rv;
o_effectiefbedrag_tv  := v_effectief_bedrag_tv;

end lopende_orders_dekw_fnds_berek;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_DEKW_FNDS_BEREK



-- DE CODE VOOR DE PROCEDURE LOPENDE_ORDERS_DEKWRDE_LOOP
-- procedure voor het berekenen dekkingswaarde voor transactiesoorten waarbij in 1 order
-- meerdere fondsen gekocht of verkocht worden.
procedure lopende_orders_dekwrde_loop
(i_relatienummer                    in      kosten_werkbestand.kst_relatie_nummer%type
,i_order_depot                      in      kosten_werkbestand.kst_depot%type
,i_order_depot_reksoort             in      kosten_werkbestand.kst_depotreksrt%type
,i_ex_as_factor                     in      beleggingsinstrument.be_exass_factor%type
,i_referentiesymbool                in      beleggingsinstrument.be_referentiesymbool%type
,i_transactiesoort                  in      orders.ord_transactiesoort%type
,i_transactiesoort_tb_waarde        in      kosten_werkbestand.kst_trans_indicatie_w%type
,i_order_soort                      in      kosten_werkbestand.kst_order_soort%type
,i_rekenaantal                      in      kosten_werkbestand.kst_trans_aantal%type
,i_trans_context                    in      contextcalculationrules.cxcr_context%type
,i_fundcategory                     in      beleggingsinstrument.be_fundcategory%type
,o_dekkingswaarde                   out     kosten_werkbestand.kst_dekkingswaarde%type
,o_gebr_wegingsperc                 out     kosten_werkbestand.kst_wegingsfactor%type
)

-- Inkomende parameters zijn: i_relatienummer     = Het relatienummer van de relatie uit de order
--                            i_order_depot       = Het depotnummer van de order
--                            i_order_depot_reksoort = Het rekeningsoort van het depot van de order
--                            i_ex_as_factor      = De exercise/assignment factor van een optie
--                            i_referentiesymbool = Het referentiesymbool van een optie
--                            i_transactiesoort   = Het transactiesoort van de order
--                            i_order_soort       = De ordersoort van order
--                            i_rekenaantal       = Het nog lopende order aantal
--                            o_dekkingswaarde    = De berekende dekkingswaarde
--                            o_gebr_wegingsperc  = het wegingsfactorpercentage dat is gebruikt voor 1 fonds

is

  v_referentiesymbool_volgnummer  beleggingsinstrument.be_volgnummer%type;
  v_ref_symbool_bi_nummer         beleggingsinstrument.be_bi_nummer%type;
  v_ref_symbool_muntsoort         beleggingsinstrument.be_muntsoort%type;
  v_wegingsperc_long              wegingsfactoren.wg_interne_perc%type;
  v_wegingsperc_short             wegingsfactoren.wg_intern_short_perc%type;
  v_ow_is_mandje                  number(1);

  v_aantal_ow                     kosten_werkbestand.kst_trans_aantal%type;
  v_effectief_bedrag_tv           kosten_werkbestand.kst_effect_bedrag_rv%type;

  v_begin_positie_order           kosten_werkbestand.kst_begin_pos_eff%type;
  v_eind_positie_order            kosten_werkbestand.kst_eind_pos_eff%type;
  v_dummy_num                     kosten_werkbestand.kst_effect_bedrag_rv%type;

begin

o_dekkingswaarde   := 0;
o_gebr_wegingsperc := 0;

-- berekenen van het dekkingswaarde effect voor Exercise orders
if i_transactiesoort in ('EX C','EX P')
then
   -- Stap 1. Bekijk of de OW een mandje is
   select b.be_volgnummer,                b.be_bi_nummer,          b.be_muntsoort
   into   v_referentiesymbool_volgnummer, v_ref_symbool_bi_nummer, v_ref_symbool_muntsoort
   from   beleggingsinstrument b
   where  b.be_symbool        = i_referentiesymbool
   and    b.be_optietype      = ' '
   and    b.be_expiratiedatum = '00000000'
   and    b.be_exerciseprijs  = 0;

   begin
      select 1
      into   v_ow_is_mandje
      from   mandje_onderliggende_waarde m
      where  m.mnd_volgnummer = v_referentiesymbool_volgnummer
      and    rownum           <= 1;                            -- 1 record ophalen is genoeg
  exception
      when no_data_found
      then
         v_ow_is_mandje := 0;
  end;

  -- De onderliggende waarde is geen mandje
  if v_ow_is_mandje = 0
  then
     lopende_orders_dekw_fnds_berek (i_relatienummer,       i_order_depot,         i_order_depot_reksoort, i_ex_as_factor,
                                     i_referentiesymbool,   ' ',                   i_transactiesoort,      i_transactiesoort_tb_waarde,
                                     i_rekenaantal,         1,                     0,                      v_wegingsperc_long,
                                     v_wegingsperc_short,   v_begin_positie_order, v_eind_positie_order,   v_aantal_ow,
                                     v_dummy_num,           v_effectief_bedrag_tv);

     lopende_orders_dekw (gv_relatie_onld_omsch,      gv_relatie_onld_perc,  i_referentiesymbool,     ' ',
                          '00000000',                 0,                     v_ref_symbool_muntsoort, case when i_transactiesoort = 'EX P' then 2 else 1 end,
                          i_order_soort,              v_wegingsperc_long,    v_wegingsperc_short,     i_fundcategory,
                          abs(v_effectief_bedrag_tv), abs(v_aantal_ow),      v_begin_positie_order,   v_eind_positie_order,    
                          v_ref_symbool_bi_nummer,    i_trans_context,       o_dekkingswaarde,        o_gebr_wegingsperc);

  -- De onderliggende waarde is wel een mandje
  else
     -- Door de fondsen heenlopen die in het mandje zitten. Per fonds moet dan de dekkingswaarde worden berekend.
     -- Het totaal van deze dekkingswaarden is dan het effect dat de exercise heeft.
     declare
        v_dekwrde_ow_uit_mandje             kosten_werkbestand.kst_dekkingswaarde%type;

        cursor mo is
           select m.mnd_factor,        b.be_symbool,        b.be_optietype,
                  b.be_expiratiedatum, b.be_exerciseprijs,  b.be_bi_nummer,
                  b.be_muntsoort
           from   mandje_onderliggende_waarde m, beleggingsinstrument b
           where  m.mnd_volgnummer  = v_referentiesymbool_volgnummer
           and    m.mnd_ref_volgnr  = b.be_volgnummer;
     begin
        for r_mo in mo
        loop
           lopende_orders_dekw_fnds_berek (i_relatienummer,        i_order_depot,         i_order_depot_reksoort, i_ex_as_factor,
                                           r_mo.be_symbool,        ' ',                   i_transactiesoort,      i_transactiesoort_tb_waarde,
                                           i_rekenaantal,         r_mo.mnd_factor,       0,                      v_wegingsperc_long,
                                           v_wegingsperc_short,   v_begin_positie_order, v_eind_positie_order,   v_aantal_ow,
                                           v_dummy_num,           v_effectief_bedrag_tv);

           v_dekwrde_ow_uit_mandje := 0;

           lopende_orders_dekw (gv_relatie_onld_omsch,      gv_relatie_onld_perc,  r_mo.be_symbool,         r_mo.be_optietype,
                                r_mo.be_expiratiedatum,     r_mo.be_exerciseprijs, r_mo.be_muntsoort,       case when i_transactiesoort = 'EX P' then 2 else 1 end,
                                i_order_soort,              v_wegingsperc_long,    v_wegingsperc_short,     i_fundcategory, 
                                abs(v_effectief_bedrag_tv), abs(v_aantal_ow),      v_begin_positie_order,   v_eind_positie_order, 
                                r_mo.be_bi_nummer,          i_trans_context,       v_dekwrde_ow_uit_mandje, o_gebr_wegingsperc);

           if gv_debuggen = 1
           then
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'Berekende dekkingswaarde : '||to_char(v_dekwrde_ow_uit_mandje)||' ; gebruikt wegingspercentage : '||to_char(o_gebr_wegingsperc));
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
           end if;

           o_dekkingswaarde := o_dekkingswaarde + v_dekwrde_ow_uit_mandje;
        end loop;

        if gv_debuggen = 1
        then
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'Totaal samengestelde dekkingswaarde : '||to_char(o_dekkingswaarde));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
        end if;

     end;
  end if;


end if;


end lopende_orders_dekwrde_loop;
-- EINDE CODE PROCEDURE LOPENDE_ORDERS_DEKWRDE_LOOP


-- DE CODE VAN PROCEDURE UITGANGSPUNT_BEPALEN
procedure uitgangspunt_bepalen
(i_order_keuze                in   orders.ord_keuze%type
,i_order_type                 in   orders.ord_ordertype%type
,i_order_trans_status         in   orders.ord_transstatus%type
,i_order_notabedrag           in   orders.ord_notabedrag%type
,i_order_effectiefbedrag      in   orders.ord_effectiefbedrag%type
,i_aantal_order_bedrag_bgs    in   number        -- 1 = order is aantalorder, maar detail is bedrag--> bedrag, <> 1 = volgens order behandelen
,i_bedrag_order_aantal_bgs    in   number        -- 1 = order is bedragorder, maar detail is aantal--> aantal, <> 1 = volgens order behandelen
,o_uitgangspunt_berekeningen  out  number
)
is
begin
    if i_order_trans_status in (2,3)
    then
       o_uitgangspunt_berekeningen := 0;
    else
       if i_order_keuze not in ('BEDR','VBDR') and i_order_type <> 'BEDR'
          and
          i_aantal_order_bedrag_bgs <> 1 -- het is een aantal order en volgens de details is het ook een aantal
          or
          i_bedrag_order_aantal_bgs = 1  -- het is dan wel een bedrag order, maar volgens de details toch een aantal (dan heeft deze parameter de waarde 1)
       then
          -- aantal orders hebben als uitgangspunt 1 (aantal)
          o_uitgangspunt_berekeningen := 1;

       -- Bedrag orders
       else
          -- als zowel nota- als effectiefbedrag aanwezig (moet) zijn dan uitgangspunt 2
          if i_order_notabedrag <> 0 and i_order_effectiefbedrag <> 0
          then
             o_uitgangspunt_berekeningen := 2;

          -- als alleen effectiefbedrag bekend is, dan uitgangspunt 3
          elsif i_order_notabedrag = 0 and i_order_effectiefbedrag <> 0
          then
             o_uitgangspunt_berekeningen := 3;

          -- als alleen notabedrag bekend is, dan uitgangspunt 4
          elsif i_order_notabedrag <> 0 and i_order_effectiefbedrag = 0
          then
             o_uitgangspunt_berekeningen := 4;

          -- als geen van de bedragen gevuld zijn, dan uitgangspunt 0 (geen actie meer ondernemen)
          elsif i_order_notabedrag = 0 and i_order_effectiefbedrag = 0
          then
             o_uitgangspunt_berekeningen := 0;
          end if;
       end if;
    end if;

    if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in de procedure FIAT_ORDERS.uitgangspunt_bepalen');
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order keuze             : '||i_order_keuze||' ; order type : '||i_order_type);
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'order transctiestatus   : '||to_char(i_order_trans_status));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'notabedrag              : '||to_char(i_order_notabedrag)||' ; effectief bedrag  : '||to_char(i_order_effectiefbedrag));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'aantal order bedrag bgs : '||to_char(i_aantal_order_bedrag_bgs)||' ; bedrag order aantal bgs : '||to_char(i_bedrag_order_aantal_bgs));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'uitgangspunt berekeningen : '||to_char(o_uitgangspunt_berekeningen));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
    end if;
end uitgangspunt_bepalen;
-- EINDE CODE PROCEDURE UITGANGSPUNT_BEPALEN


-- DE CODE VOOR DE PROCEDURE GEBOEKT_IN_TRANS_BEPALEN
procedure geboekt_in_trans_bepalen
(i_order_nummer                     in      orders.ord_ordernummer%type
,i_order_regel                      in      orders.ord_orderregel%type
,i_relatie_nummer                   in      orders.ord_relatie%type
,i_depot                            in      orders.ord_depot%type
,i_depot_reksoort                   in      orders.ord_depotreksrt%type
,i_orin_id                          in      orders.ord_orin_id%type
,o_geboekt_aantal                   out     orders.ord_aantal%type
,o_geboekt_notabedrag               out     orders.ord_notabedrag%type
,o_geboekt_effectiefbedrag          out     orders.ord_effectiefbedrag%type
,o_totaal_uitgevoerd                out     ordersuitvoeringen.uit_aantal%type
,o_tot_uitgevoerd_voor_trans        out     ordersuitvoeringen.uit_aantal%type
)
is

  v_vorig_uitvoernrintr      ordersuitvoeringen.uit_uitvoernrintr%type;
  v_trans_gevonden           number(1);
  v_geb_notabedrag           transakties.tr_notabedrag%type;
  v_geb_eff_bedrag           transakties.tr_notabedrag%type;
  v_geboekt_tr_aantal        transakties.tr_aantal%type;

  cursor uit is
     select u.uit_uitvoernrintr, u.uit_aantal
     from   ordersuitvoeringen u
     where  u.uit_ordernummer  = i_order_nummer
     and    u.uit_orderregel   = i_order_regel
     and    u.uit_uitvoernrintr <> 0
     order by u.uit_uitvoernrintr asc, u.uit_uitvoernummer asc;

begin

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure geboekt_in_trans_bepalen');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer        : '||to_char(i_order_nummer)||' ; orderregel : '||to_char(i_order_regel));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'relatie nummer     : '||to_char(i_relatie_nummer));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'depot              : '||i_depot||' ; depot rekeningsoort : '||to_char(i_depot_reksoort));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'berekende gegevens : ');
   end if;

   v_trans_gevonden            := 0;
   v_vorig_uitvoernrintr       := 0;
   v_geboekt_tr_aantal         := 0;
   v_geb_notabedrag            := 0;
   v_geb_eff_bedrag            := 0;
   o_geboekt_aantal            := 0;
   o_geboekt_notabedrag        := 0;
   o_geboekt_effectiefbedrag   := 0;
   o_totaal_uitgevoerd         := 0;
   o_tot_uitgevoerd_voor_trans := 0;

   -- eerst bepalen hoeveel in totaal is uitgevoerd voor de order
   select sum(o.uit_aantal)
   into   o_totaal_uitgevoerd
   from   ordersuitvoeringen o
   where  o.uit_ordernummer  = i_order_nummer
   and    o.uit_orderregel   = i_order_regel;

   for r_uit in uit
   loop
      v_trans_gevonden := 1;

      o_tot_uitgevoerd_voor_trans := o_tot_uitgevoerd_voor_trans + r_uit.uit_aantal;

      if v_vorig_uitvoernrintr <> r_uit.uit_uitvoernrintr
      then
         begin
            select trans_aantal,        notabedrag,       effectief_bedrag
            into   v_geboekt_tr_aantal, v_geb_notabedrag, v_geb_eff_bedrag
            from   (select t.tr_aantal as trans_aantal, t.tr_notabedrag as notabedrag, t.tr_effective_amount as effectief_bedrag
                    from   transakties t
                    where  t.tr_ordernr_ordsubnr = (1000 * i_order_nummer) + i_order_regel
                    and    t.tr_orderuitvoernr   = r_uit.uit_uitvoernrintr
                    and    t.tr_rel1             = i_relatie_nummer
                    and    t.tr_rel1_rek1        = i_depot
                    and    t.tr_rel1_rek1_soort  = i_depot_reksoort
                    and    t.tr_mut_gemaakt      <> 's'
                    and    nvl(t.tr_orin_id,0)   = i_orin_id
                    order by t.tr_volgnummer asc
                   )
            where  rownum  <= 1;
         exception
               when no_data_found
               then
                  v_trans_gevonden    := 0;
                  v_geboekt_tr_aantal := 0;
                  v_geb_notabedrag    := 0;
                  v_geb_eff_bedrag    := 0;
         end;

         -- vastleggen van het laatst gebruikte uitvoernr in de transactie
         v_vorig_uitvoernrintr := r_uit.uit_uitvoernrintr;

         if v_trans_gevonden = 1
         then
            o_geboekt_aantal          := o_geboekt_aantal + v_geboekt_tr_aantal;
            o_geboekt_notabedrag      := o_geboekt_notabedrag + v_geb_notabedrag;
            o_geboekt_effectiefbedrag := o_geboekt_effectiefbedrag + v_geb_eff_bedrag;
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'gegevens van gevonden transactie : '||' transactie gevonden : '||to_char(v_trans_gevonden));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'uitvoernrintr      : '||to_char(r_uit.uit_uitvoernrintr)||' ; geboekt aantal     : '||to_char(v_geboekt_tr_aantal));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'geboekt notabedrag : '||to_char(v_geb_notabedrag)||' ; geboekt effec bedrag : '||to_char(v_geb_eff_bedrag));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
         end if;
      end if;
   end loop;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'einde procedure geboekt_in_trans_bepalen');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ordernummer               : '||to_char(i_order_nummer)||' ; orderregel : '||to_char(i_order_regel));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'totaal berekende gegevens : ');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'geboekt aantal            : '||to_char(o_geboekt_aantal));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'geboekt notabedrag        : '||to_char(o_geboekt_notabedrag)||' ; geboekt effec bedrag : '||to_char(o_geboekt_effectiefbedrag));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'totaal uitgevoerd aantal  : '||to_char(o_totaal_uitgevoerd)||' ; uitvoering in trans aantal : '||to_char(o_tot_uitgevoerd_voor_trans));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

end geboekt_in_trans_bepalen;
-- EINDE CODE PROCEDURE GEBOEKT_IN_TRANS_BEPALEN


-- CODE VAN DE PROCEDURE OMREK_GEBOEKT_NOTABEDRAG
procedure omrek_geboekt_notabedrag
(i_order_nummer                     in      orders.ord_ordernummer%type
,i_order_regel                      in      orders.ord_orderregel%type
,i_relatie_nummer                   in      orders.ord_relatie%type
,i_depot                            in      orders.ord_depot%type
,i_depot_reksoort                   in      orders.ord_depotreksrt%type
,i_fonds_muntsoort                  in      muntsoorten.mu_code%type
,i_fonds_muntsrt_reciproke          in      muntsoorten.mu_reciproke%type
,i_fonds_muntsrt_factor             in      muntsoorten.mu_factor%type
,i_fonds_muntsrt_biedkoers          in      muntsoorten.mu_biedkoers%type
,i_fonds_muntsrt_laatkoers          in      muntsoorten.mu_laatkoers%type
,i_fonds_muntsrt_notatie            in      muntsoorten.mu_notatie%type
,i_geboekt_notabedrag               in      orders.ord_notabedrag%type
,o_geboekt_notabedrag               out     orders.ord_notabedrag%type
)
is

  v_muntsoort_geldrekening          muntsoorten.mu_code %type;
  v_geldrek_munt_biedkoers          muntsoorten.mu_biedkoers%type;
  v_geldrek_munt_laatkoers          muntsoorten.mu_laatkoers%type;
  v_geldrek_munt_factor             muntsoorten.mu_factor%type;
  v_geldrek_munt_reciproke          muntsoorten.mu_reciproke%type;
  v_dummy_waarde                    muntsoorten.mu_middenkoers%type;

begin
   -- het notabedrag is geboekt op de geldrekening van de relatie.
   -- deze hier ophalen om daarna te bepalen of er moet worden omgerekend
   begin
      select t.tr_rel1_rek2_munts
      into   v_muntsoort_geldrekening
      from   transakties t, ordersuitvoeringen u
      where  u.uit_ordernummer      = i_order_nummer
      and    u.uit_orderregel       = i_order_regel
      and    t.tr_ordernr_ordsubnr  = (1000 * i_order_nummer + i_order_regel)
      and    t.tr_orderuitvoernr    = u.uit_uitvoernrintr
      and    t.tr_rel1              = i_relatie_nummer
      and    t.tr_rel1_rek1         = i_depot
      and    t.tr_rel1_rek1_soort   = i_depot_reksoort
      and    rownum                 <= 1;

   exception
   when no_data_found
   then
      v_muntsoort_geldrekening := ' ';
   end;

   if v_muntsoort_geldrekening <> i_fonds_muntsoort and v_muntsoort_geldrekening <> ' ' and v_muntsoort_geldrekening is not null
   then
      -- Ophalen van de koersgegevens van de muntsoort van de rekening:
      if v_muntsoort_geldrekening = gv_rel_rapp_valuta
      then
         v_geldrek_munt_biedkoers := gv_rel_rapp_biedkoers;
         v_geldrek_munt_laatkoers := gv_rel_rapp_laatkoers;
         v_geldrek_munt_factor    := gv_rel_rapp_factor;
         v_geldrek_munt_reciproke := gv_rel_rapp_reciproke;
      elsif v_muntsoort_geldrekening = gv_basis_valuta
      then
         v_geldrek_munt_biedkoers := gv_basis_val_biedkoers;
         v_geldrek_munt_laatkoers := gv_basis_val_laatkoers;
         v_geldrek_munt_factor    := gv_basis_val_factor;
         v_geldrek_munt_reciproke := gv_basis_val_reciproke;
      else
         FIAT_ALGEMEEN.valutagegevens_bepalen (v_muntsoort_geldrekening, gv_relatie_pr_id,         gv_relatie_ppr_id,     gv_systspreadcodecategorie,
                                               gv_bank2mrktqchangedate,  gv_debuggen,              gv_debug_user,         v_geldrek_munt_biedkoers,
                                               v_dummy_waarde,           v_geldrek_munt_laatkoers, v_geldrek_munt_factor, v_geldrek_munt_reciproke,
                                               v_dummy_waarde);
      end if;

      -- aansluitend omrekenen naar de muntsoort van het beleggingsinstrument
      select FIAT_ALGEMEEN.omrekenen_bedrag_vv (i_geboekt_notabedrag, v_geldrek_munt_reciproke, v_geldrek_munt_factor,
                                                v_geldrek_munt_biedkoers , v_geldrek_munt_laatkoers , i_fonds_muntsrt_reciproke,
                                                i_fonds_muntsrt_factor, i_fonds_muntsrt_biedkoers, i_fonds_muntsrt_laatkoers,
                                                i_fonds_muntsrt_notatie)
      into   o_geboekt_notabedrag
      from   dual;
   else
      -- muntsoort rekening is gelijk aan muntsoort fonds; notabedrag in overnemen in notabedrag uit:
      o_geboekt_notabedrag := i_geboekt_notabedrag;
   end if;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure omrek_geboekt_notabedrag');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'bepaald rekening muntsoort : '||v_muntsoort_geldrekening||' ; muntsoort fonds : '||i_fonds_muntsoort);
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'geboekt notabedrag in      : '||to_char(i_geboekt_notabedrag)||' ; geboekt notabedrag uit : '||to_char(o_geboekt_notabedrag));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

end omrek_geboekt_notabedrag;
-- EINDE PROCEDURE OMREK_GEBOEKT_NOTABEDRAG


-- DE CODE VOOR DE PROCEDURE LOPENDE_BELEG_OPDR_HERBER
procedure lopende_beleg_opdr_herber
(o_tot_lopende_opdrachten out beleggingsopdracht_header.boh_bedrag%type
)
is

  v_order_notabedrag_rv  orders.ord_notabedrag%type;
  v_order_notabedrag_vv  orders.ord_notabedrag%type;
  v_valuta_biedkoers     muntsoorten.mu_biedkoers%type;
  v_valuta_laatkoers     muntsoorten.mu_laatkoers%type;
  v_valuta_factor        muntsoorten.mu_factor%type;
  v_valuta_reciproke     muntsoorten.mu_reciproke%type;
  v_valuta_notatie       muntsoorten.mu_notatie%type;
  v_dummy_waarde         number(1);

begin

   declare
   cursor lod is

   -- kst_lopende_bedrag is in de muntsoort van de rapportagevaluta
   select k.kst_lopend_bedrag, k.kst_opdrachtnummer, h.boh_geldrekening_munt
   from   kosten_werkbestand k, beleggingsopdracht_header h
   where  k.kst_opdrachtnummer    <> 0
   and    h.boh_opdrachtnummer    = k.kst_opdrachtnummer;

   begin

   if gv_debuggen = 1
   then
      -- Wat is het bedrag voor de lopende beleggingsopdrachten bij het begin van de procedure? Dit voor de debug info ophalen
      select sum(f.amount_repc)
      into   o_tot_lopende_opdrachten
      from   fiat_current_inv_orders f;

      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure lopende beleggingsopdrachten herberekenen');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Bedrag lopende beleggingsopdrachten aan begin : '||to_char(o_tot_lopende_opdrachten));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

   for r_lod in lod
   loop

           v_order_notabedrag_rv := r_lod.kst_lopend_bedrag;

           if r_lod.boh_geldrekening_munt = gv_rel_rapp_valuta
           then
              v_order_notabedrag_vv := r_lod.kst_lopend_bedrag;
           else
              FIAT_ALGEMEEN.valutagegevens_bepalen (r_lod.boh_geldrekening_munt, gv_relatie_pr_id,   gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                                    gv_bank2mrktqchangedate,     gv_debuggen,        gv_debug_user,     v_valuta_biedkoers,
                                                    v_dummy_waarde,              v_valuta_laatkoers, v_valuta_factor,   v_valuta_reciproke,
                                                    v_valuta_notatie);

              select FIAT_ALGEMEEN.omrekenen_bedrag_vv (r_lod.kst_lopend_bedrag, gv_rel_rapp_reciproke, gv_rel_rapp_factor,gv_rel_rapp_biedkoers,
                                                        gv_rel_rapp_laatkoers, v_valuta_reciproke, v_valuta_factor,
                                                        v_valuta_biedkoers, v_valuta_laatkoers, v_valuta_notatie)
              into   v_order_notabedrag_vv
              from   dual;
           end if;

           -- amount_fc is in de muntsoort van de beleggingsopdracht (geldrekening)
           -- amount_repc is in de muntsoort van de rapportagevaluta
           update fiat_current_inv_orders f
           set    f.amount_fc      = case when f.amount_fc - v_order_notabedrag_vv > 0 then
                                     0 else f.amount_fc - v_order_notabedrag_vv end,
                  f.amount_repc    = case when f.amount_repc - v_order_notabedrag_rv > 0 then
                                     0 else f.amount_repc - v_order_notabedrag_rv end
           where  f.inv_order_id   = r_lod.kst_opdrachtnummer;

           if gv_debuggen = 1
           then
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Corrigeren voor opdrachtnummer : '||to_char(r_lod.kst_opdrachtnummer));
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Order notabedrag in vv : '||to_char(v_order_notabedrag_vv)||
                                                      ' ; Order notabedrag in rv : '||to_char(v_order_notabedrag_rv));
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
           end if;
       end loop;

   end;

   -- als laatste het totaal teruggeven
   select sum(f.amount_repc)
   into   o_tot_lopende_opdrachten
   from   fiat_current_inv_orders f;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Einde procedure lopende beleggingsopdrachten herberekenen');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Totaal bedrag lopende beleggingsopdrachten : '||to_char(o_tot_lopende_opdrachten));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

end lopende_beleg_opdr_herber;
-- EINDE CODE PROCEDURE LOPENDE_BELEG_OPDR_HERBER


-- DE CODE VOOR DE PROCEDURE KOSTEN_OVERNEMEN
procedure kosten_overnemen
(i_order_id               in  ordersdetaillering.orx_id%type
,i_ordernummer            in  ordersdetaillering.orx_ordernummer%type
,i_orderregel             in  ordersdetaillering.orx_orderregel%type
,i_order_detailnummer     in  ordersdetaillering.orx_detailnummer%type
)
is
  cursor oc is
  select o.ooef_cfcu_id,        o.ooef_amount,         o.ooef_base_amount,   o.ooef_currency,
         o.ooef_minimum_amount, o.ooef_maximum_amount, o.ooef_percentage
  from   od_orddet_external_fees o
  where  o.ooef_orx_id = i_order_id;
begin
  for r_oc in oc
  loop
     insert into fiat_order_costs_det f
     (f.focd_order_number,       f.focd_order_line,       f.focd_order_det_num,   f.focd_cfcu_id,
      f.focd_total_amt,          f.focd_basevalue_amt,    f.focd_rule_currency,   f.focd_rule_min_amt,
      f.focd_rule_fixed_amt,     f.focd_rule_var_amt_perc)
     values
      (i_ordernummer,            i_orderregel,            i_order_detailnummer,   r_oc.ooef_cfcu_id,
       r_oc.ooef_amount,         r_oc.ooef_base_amount,   r_oc.ooef_currency,     r_oc.ooef_minimum_amount,
       r_oc.ooef_maximum_amount, r_oc.ooef_percentage);
  end loop;
end kosten_overnemen;
-- EINDE CODE PROCEDURE KOSTEN_OVERNEMEN


-- DE CODE VOOR PROCEDURE OMREKENEN_RV_REKV
procedure omrekenen_rv_rekv
(i_bedrag_in_rv           in  kosten_werkbestand.kst_lopend_bedrag%type
,i_fonds_valuta           in  beleggingsinstrument.be_muntsoort%type
,o_bedrag_in_rekv         out kosten_werkbestand.kst_lopend_bedrag_rekv_sl%type
)

is

  v_te_gebr_rappv_koers    fiat_muntsoorten.fimu_biedkoers%type;
  v_te_gebr_rekv_koers     fiat_muntsoorten.fimu_biedkoers%type;
  v_om_te_rekenen_bedrag   kosten_werkbestand.kst_lopend_bedrag%type;

begin
   v_om_te_rekenen_bedrag  := nvl(i_bedrag_in_rv,0);

   -- als muntsoorten gelijk zijn, dan zijn de bedragen ook gelijk
   if gv_rel_rapp_valuta = gv_rek_valuta
   then
      o_bedrag_in_rekv  := v_om_te_rekenen_bedrag;
   else

      -- bepalen van de gebruiken koersen:
      if i_fonds_valuta = gv_rel_rapp_valuta
      then
         v_te_gebr_rappv_koers  := gv_rel_rapp_middenkoers;
      else
         if v_om_te_rekenen_bedrag < 0
         then
            v_te_gebr_rappv_koers := gv_rel_rapp_biedkoers;
         else
            v_te_gebr_rappv_koers := gv_rel_rapp_laatkoers;
         end if;
      end if;

      if i_fonds_valuta = gv_rek_valuta
      then
         v_te_gebr_rekv_koers := gv_rek_val_middenkoers;
      else
         if v_om_te_rekenen_bedrag < 0
         then
            v_te_gebr_rekv_koers := gv_rek_val_laatkoers;
         else
            v_te_gebr_rekv_koers := gv_rek_val_biedkoers;
         end if;
      end if;

      select FIAT_ALGEMEEN.omrekenen_bedrag_vv(v_om_te_rekenen_bedrag, gv_rel_rapp_reciproke, gv_rel_rapp_factor,
                                               v_te_gebr_rappv_koers,  v_te_gebr_rappv_koers, gv_rek_val_reciproke,
                                               gv_rek_val_factor,      v_te_gebr_rekv_koers,  v_te_gebr_rekv_koers,
                                               gv_rek_val_notatie)
      into   o_bedrag_in_rekv
      from   dual;
   end if;

end omrekenen_rv_rekv;
-- EINDE CODE VOOR PROCEDURE OMREKENEN_RV_REKV


-- DE CODE VOOR DE PROCEDURE LOPENDBEDRAG_COMB_BEREKEN
procedure lopendbedrag_comb_bereken
(i_notabedrag_comb            in  kosten_werkbestand.kst_notabedrag%type
,i_notabedrag                 in  kosten_werkbestand.kst_notabedrag%type
,i_marginbedrag_comb          in  kosten_werkbestand.kst_marginbedrag%type
,i_marginbedrag               in  kosten_werkbestand.kst_marginbedrag%type
,i_ordernummer                in  kosten_werkbestand.kst_ordernummer%type
,i_bgs_koop_order_op_0_zetten in  number
,o_lopendbedrag_comb          out kosten_werkbestand.kst_lopend_bedrag%type
,o_lopendbedrag               out kosten_werkbestand.kst_lopend_bedrag%type
)
is
begin

      -- Bepalen van het geschatte lopend order bedrag
      o_lopendbedrag_comb  := round(i_notabedrag_comb + i_marginbedrag_comb, gv_rel_rapp_notatie);
      o_lopendbedrag       := round(i_notabedrag + i_marginbedrag, gv_rel_rapp_notatie);

      -- het totaal van de beide poten (niet bij invoer) is positief, dan beide op 0 zetten
      -- er mag immers geen geld gegenereerd worden...
      if o_lopendbedrag_comb + o_lopendbedrag > 0 and i_ordernummer > 0
         or
         -- Afhankelijk van de doorgegeven setting het lopend bedrag op 0 zetten
         i_bgs_koop_order_op_0_zetten = 1
      then
         o_lopendbedrag      := 0;
         o_lopendbedrag_comb := 0;
      end if;

end lopendbedrag_comb_bereken;
-- EINDE CODE VOOR PROCEDURE LOPENDBEDRAG_COMB_BEREKEN


-- DE CODE VOOR DE PROCEDURE LOPENDBEDRAG_BEREKEN
procedure lopendbedrag_bereken
(i_notabedrag                   in  kosten_werkbestand.kst_notabedrag%type
,i_dekkingswaarde               in  kosten_werkbestand.kst_dekkingswaarde%type
,i_marginbedrag                 in  kosten_werkbestand.kst_marginbedrag%type
,i_margin_effect_bedrag         in  kosten_werkbestand.kst_marginbedrag%type
,i_transactie_soort             in  kosten_werkbestand.kst_trans_indicatie%type
,i_bereken_bedrag_huidige_ord   in  number
,i_berekenen_afgeleide_effecten in  number
,i_exas_berek_afgeleide_effect  in  number
,i_bgs_koop_order_op_0_zetten   in  number
,i_ordernummer                  in  kosten_werkbestand.kst_ordernummer%type
,o_lopendbedrag                 out kosten_werkbestand.kst_lopend_bedrag%type
,o_marginbedrag                 out kosten_werkbestand.kst_marginbedrag%type
)
is
  v_marginbedrag               kosten_werkbestand.kst_marginbedrag%type;
begin
   -- Initialiseren
   o_lopendbedrag   := 0;
   v_marginbedrag   := i_marginbedrag;

   -- Als berekenen bedrag huidige order aanstaat de opbrengst en kosten bij elkaar op tellen
   if i_bereken_bedrag_huidige_ord = 1 and i_transactie_soort not in ('EX C','EX P')
   then
      o_lopendbedrag := round(i_notabedrag,gv_rel_rapp_notatie) + round(i_dekkingswaarde,gv_rel_rapp_notatie) + round(v_marginbedrag,gv_rel_rapp_notatie);
   else
      if (i_transactie_soort in ('EX C','EX P') and (i_berekenen_afgeleide_effecten = 1 or i_exas_berek_afgeleide_effect = 1)
          or
          i_transactie_soort not in ('EX C','EX P') and i_berekenen_afgeleide_effecten = 1)
      then
         v_marginbedrag  := i_margin_effect_bedrag;

         if i_transactie_soort not in ('SV F','SK F')
         then
            o_lopendbedrag := round(i_notabedrag,gv_rel_rapp_notatie) + round(i_dekkingswaarde,gv_rel_rapp_notatie) +
                              round(v_marginbedrag,gv_rel_rapp_notatie);
         else
            o_lopendbedrag := round(i_notabedrag,gv_rel_rapp_notatie) + round(v_marginbedrag,gv_rel_rapp_notatie);
         end if;
      else
         -- Anders alleen de margin meenemen
         o_lopendbedrag := round(v_marginbedrag,gv_rel_rapp_notatie);
      end if;
   end if;

   o_marginbedrag := v_marginbedrag;

   -- Afhankelijk van de doorgegeven setting het lopend bedrag op 0 zetten
   -- of als er toch geld wordt gegenereerd bij lopende orders
   if i_bgs_koop_order_op_0_zetten = 1
      or
      o_lopendbedrag > 0 and i_ordernummer > 0
   then
      o_lopendbedrag := 0;
   end if;

end lopendbedrag_bereken;
-- EINDE CODE VOOR PROCEDURE LOPENDBEDRAG_BEREKEN


-- DE CODE VOOR DE PROCEDURE SET_AFWIJKEND_TRANSSOORT
procedure set_afwijkende_ordergegevens
(i_transactiesoort              in  transactiesoorten.ts_symbool%type
,i_ordernummer                  in  kosten_werkbestand.kst_ordernummer%type
,i_orderregel                   in  kosten_werkbestand.kst_orderregel%type
,i_detailnummer                 in  kosten_werkbestand.kst_detailnummer%type
,i_fondssymbool                 in  kosten_werkbestand.kst_fondssymbool%type
,i_fonds_optietype              in  kosten_werkbestand.kst_optietype_fnds%type
,i_fonds_expiratiedatum         in  kosten_werkbestand.kst_expiratiedat_fnds%type
,i_fonds_exercise_prijs         in  kosten_werkbestand.kst_exercisepr_fnds%type
,i_fonds_bi_nummer              in  kosten_werkbestand.kst_bi_nummer%type
,i_fonds_ex_ass_fac             in  kosten_werkbestand.kst_fnds_ex_ass_fac%type
,i_fonds_prijs_factor           in  kosten_werkbestand.kst_prijs_factor_fnds%type
,i_fonds_omw_factor             in  kosten_werkbestand.kst_omw_factor_fnds%type
,i_fonds_beurs_nummer           in  kosten_werkbestand.kst_beursnummer%type
,i_fonds_aantal_cijfers_disp    in  kosten_werkbestand.kst_aantal_cijfers_disp%type
,i_fonds_volgnummer             in  kosten_werkbestand.kst_fund_id%type
,i_fonds_muntsoort              in  kosten_werkbestand.kst_trans_muntsrt%type
,i_ref_fondssymbool             in  kosten_werkbestand.kst_ref_fondssymbool%type
,i_ref_fonds_bi_nummer          in  kosten_werkbestand.kst_ref_fnds_bi_nr%type
,i_ref_fonds_prijs_factor       in  kosten_werkbestand.kst_ref_fnds_prijs_f%type
,i_order_aantal                 in  kosten_werkbestand.kst_trans_aantal%type
,i_order_geen_provisie          in  kosten_werkbestand.kst_ord_geen_provisie%type
,i_wissel_tr_tb_waarde          in  number
,o_transsoort_tb_waarde         out transactiesoorten.ts_koop_verkoop_ind%type
)
is

  v_transsoort_tb_waarde        kosten_werkbestand.kst_trans_indicatie_w%type;
  v_transsoort_num_waarde       kosten_werkbestand.kst_trans_indicatie_n%type;

begin
  -- bepalen van de transactiesoort-gegevens voor de doorgegeven transactiesoort
  select t.ts_indicatie_nummer,   t.ts_koop_verkoop_ind
  into   v_transsoort_num_waarde, v_transsoort_tb_waarde
  from   transactiesoorten t
  where  t.ts_symbool = i_transactiesoort;

  -- Als het verrekenbedrag tegengesteld is aan de transactierichting (positief bij deponering, negatief bij lichting/verkoop)
  -- dan hier de tb-waarde omkeren zodat de correct muntkoersen en optellingen gaan plaats vinden bij het bereken van het notabedrag
  if i_wissel_tr_tb_waarde = 1
  then
     v_transsoort_tb_waarde := case when v_transsoort_tb_waarde = 2 then 1 else 2 end;
  end if;

  update kosten_werkbestand k
  set    k.kst_fondssymbool        = i_fondssymbool,
         k.kst_optietype_fnds      = i_fonds_optietype,
         k.kst_expiratiedat_fnds   = i_fonds_expiratiedatum,
         k.kst_exercisepr_fnds     = i_fonds_exercise_prijs,
         k.kst_bi_nummer           = i_fonds_bi_nummer,
         k.kst_fnds_ex_ass_fac     = i_fonds_ex_ass_fac,
         k.kst_prijs_factor_fnds   = i_fonds_prijs_factor,
         k.kst_omw_factor_fnds     = i_fonds_omw_factor,
         k.kst_beursnummer         = i_fonds_beurs_nummer,
         k.kst_aantal_cijfers_disp = i_fonds_aantal_cijfers_disp,
         k.kst_fund_id             = i_fonds_volgnummer,
         k.kst_ref_fondssymbool    = i_ref_fondssymbool,
         k.kst_ref_fnds_bi_nr      = i_ref_fonds_bi_nummer,
         k.kst_ref_fnds_prijs_f    = i_ref_fonds_prijs_factor,
         k.kst_trans_muntsrt       = i_fonds_muntsoort,
         k.kst_trans_aantal        = i_order_aantal,
         k.kst_ord_geen_provisie   = i_order_geen_provisie,
         k.kst_trans_indicatie     = i_transactiesoort,
         k.kst_trans_indicatie_n   = v_transsoort_num_waarde,
         k.kst_trans_indicatie_w   = v_transsoort_tb_waarde
  where  k.kst_ordernummer         = i_ordernummer
  and    k.kst_orderregel          = i_orderregel
  and    k.kst_detailnummer        = i_detailnummer;

  o_transsoort_tb_waarde := v_transsoort_tb_waarde;

end set_afwijkende_ordergegevens;
-- EINDE CODE VOOR PROCEDURE SET_AFWIJKEND_TRANSSOORT


-- DE CODE VOOR DE PROCEDURE BEPAAL_HOLDER_KENMERKEN
procedure bepaal_holder_kenmerken
(i_ppr_id                       in  producten_per_relatie.ppr_id%type
,o_legal_entity_type            out legalentity_details.lety_id%type
,o_eor_kenmerk_id               out rekeninghouders_details.eor_kenmerk_id%type
)
is

       v_eerste_verwerkt         number(1);

cursor hk is 
         select r.eor_kenmerk_id, l.lety_id
         from   producten_per_relatie p
         left outer join holders_per_product h 
                    on   h.hpp_relatienummer    = p.ppr_relatienummer
                    and  h.hpp_product          = p.ppr_productnummer
                    and  h.hpp_product_volgnr   = p.ppr_volgnr_per_product
                    and  h.hpp_type_holder      = 1
         left outer join rekeninghouders_details r
                    on   r.eor_partij_id        = h.hpp_holdernummer
         left outer join legalentity_details l
                    on   l.party_id             = h.hpp_holdernummer
         where p.ppr_id = i_ppr_id;

begin
   -- Altijd de gegevens van de eerste holder vast houden, de overige overslaan (in Magic is het een yes-after constructie) 
   v_eerste_verwerkt := 0;

   for r_hk in hk
   loop 
      if v_eerste_verwerkt = 0
      then
         o_legal_entity_type := r_hk.lety_id;
         o_eor_kenmerk_id    := nvl(r_hk.eor_kenmerk_id,0);
         
         v_eerste_verwerkt   := 1;
      end if;
   end loop;
end bepaal_holder_kenmerken;
-- EINDE CODE VOOR PROCEDURE BEPAAL_HOLDER_KENMERKEN


-- DE CODE VOOR DE FUNCTION VERSION
function Version
return varchar2
is

begin
      return gv_versie;
end version;
-- EINDE CODE FUNCTION VERSION

end FIAT_ORDERS;
/
