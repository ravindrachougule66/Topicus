create or replace package FIAT_VERZAMEL
is

/*------------------------------------------------------------------------------
Package     : FIAT_VERZAMEL
description : code voor de package FIAT_VERZAMEL waarbinnen de volgende procedures
              en functions aanwezig zijn:
              procedure relatie_verzamel
              function  version
------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';

-- procedure relatie_verzamel:
   procedure relatie_verzamel
   (i_relatienummer               in  clienten.cl_nummer%type
   ,i_client_id                   in  clienten.cl_id%type
   ,i_sys_toeslag_optiemarg       in  tabelgegevens.tb_waarde%type
   ,i_rel_toeslag_optiemarg       in  producten.pr_toeslag_percentage%type
   ,i_methode_naked_margin        in  number
   ,i_factor_naked_margin         in  number
   ,i_slot_of_laatste_koers       in  tabelgegevens.tb_symbool%type
   ,i_terminalnr                  in  werkbestand.wk_terminal%type
   ,i_productnummer               in  producten_per_relatie.ppr_productnummer%type
   ,i_productvolgnummer           in  producten_per_relatie.ppr_volgnr_per_product%type
   ,i_overrule_account_blockade   in  number
   ,i_meerdere_producten          in  number
   ,i_te_berekenen_deel           in  varchar2
   ,i_wegings_fac_munt_gebr       in  number
   ,i_relatie_heeft_depots        in  number
   ,i_detail_geg_aanmaken         in  number
   ,i_dagen_administr_feiten_meen in  number
   ,i_bedrijfspaar_product        in  number
   ,i_pr_blokkeren_short_call     in  number
   ,i_pr_blokkeren_short_put      in  number
   ,i_herkomst                    in  number
   ,i_instellingen                in  varchar2
   ,o_extra_spreid_port_waarde    out positie_werkbestand.pwb_port_waarde_rapv%type
   ,o_extra_spreid_port_waarde_vv out positie_werkbestand.pwb_port_waarde_vv%type
   );

-- function version
   function version
   return                      varchar2;

end FIAT_VERZAMEL;
/
create or replace package body FIAT_VERZAMEL
is

/*------------------------------------------------------------------------------
Package body : FIAT_VERZAMEL
description  : code voor de package body FIAT_VERZAMEL waarbinnen de volgende
               procedures en functions aanwezig zijn:
               procedure vullen_doorlopen_rek
               procedure geld_ka_rek
               procedure geld_aktuele_pos
               procedure geld_overige_rekeningen
               procedure niet_doorgeboekte_trans
               procedure positie_aktuele_pos
               procedure positie_berekening
               procedure vullen_as_posities
               procedure vullen_margin_werkb
               function  version
------------------------------------------------------------------------------*/

-- globale variabelen (dus te gebruiken over alle procedures nadat de waarden zijn
-- bepaald in de eerst aanroepend procedure)
   gv_rel_rapp_valuta          relatie_fiattering.rf_rapp_muntsoort%type;
   gv_rel_rapp_reciproke       relatie_fiattering.rf_rapp_reciproke%type;
   gv_rel_rapp_factor          relatie_fiattering.rf_rapp_factor%type;
   gv_rel_rapp_biedkoers       relatie_fiattering.rf_rapp_biedkoers%type;
   gv_rel_rapp_laatkoers       relatie_fiattering.rf_rapp_laatkoers%type;
   gv_rel_rapp_notatie         relatie_fiattering.rf_rapp_notatie%type;
   gv_relatie_pr_id            producten.pr_id%type;
   gv_relatie_ppr_id           producten_per_relatie.ppr_id%type;
   gv_onld_omschrijving        relatie_fiattering.rf_onld_omschrijving%type;
   gv_onld_percentage          relatie_fiattering.rf_onld_percentage%type;
   gv_cl_margin_inst           relatie_fiattering.rf_margin%type;
   gv_debuggen                 relatie_fiattering.rf_debug_j_n%type;
   gv_debug_user               relatie_fiattering.rf_debug_user%type;
   gv_meerdere_producten       number(1);
   gv_detail_geg_aanmaken      number(1);
   gv_bedrijfspaar_product     number(1);
   gv_terminalnummer           werkbestand.wk_terminal%type;
   gv_systspreadcodecategorie  valutaspread_cat_muntsoort.vscm_vsca_id%type;
   gv_bank2mrktqchangedate     muntsoorten.mu_update%type;
   gv_basismuntsoort           relatie_fiattering.rf_bv_muntsoort%type;
   gv_suppressFCDekkwaarde     number(1);

-- procedure vullen_doorlopen_rek
   procedure vullen_doorlopen_rek
   (i_relatienummer              in clienten.cl_nummer%type
   ,i_productnummer              in producten_per_relatie.ppr_productnummer%type
   ,i_productvolgnummer          in producten_per_relatie.ppr_volgnr_per_product%type
   ,i_overrule_account_blockade  in number
   ,i_meerdere_producten         in number
   ,i_te_berekenen_deel          in varchar2
   );

-- procedure geld_ka_rek:
   procedure geld_ka_rek
   (i_relatienr             in clienten.cl_nummer%type
   ,i_wegings_fac_munt_gebr in number
   );

-- procedure geld_aktuele_pos:
   procedure geld_aktuele_pos
   (i_relatienr               in clienten.cl_nummer%type
   ,i_wegings_fac_munt_gebr   in number
   );

-- procedure geld_overige_rekeningen:
   procedure geld_overige_rekeningen
   (i_relatienr             in clienten.cl_nummer%type
   );

-- procedure niet_doorgeboekte_trans:
   procedure niet_doorgeboekt_trans
   (i_relatienr                   in clienten.cl_nummer%type
   ,i_transaktie_volgnummer       in transakties.tr_volgnummer%type
   ,i_wegings_fac_munt_gebr       in number
   );

-- procedure niet_doorgeboekt_trans_loop
   procedure niet_doorgeboekt_trans_loop
   (i_relatienr                   in clienten.cl_nummer%type
   ,i_client_id                   in clienten.cl_id%type
   ,i_boekdatum_vanaf             in transakties.tr_boekdatum%type
   ,i_dagen_administr_feiten_meen in number
   ,i_wegings_fac_munt_gebr       in number
   );

-- procedure positie_aktuele_pos:
   procedure positie_aktuele_pos
   (i_relatienr             in clienten.cl_nummer%type
   ,i_herkomst              number
   );

-- procedure positie_berekening:
   procedure positie_berekening
   (i_relatienummer            in  clienten.cl_nummer%type
   ,i_sys_toeslag_optiemarg    in  tabelgegevens.tb_waarde%type
   ,i_rel_toeslag_optiemarg    in  producten.pr_toeslag_percentage%type
   ,i_methode_naked_margin     in  number
   ,i_factor_naked_margin      in  number
   ,i_slot_of_laatste_koers    in  tabelgegevens.tb_symbool%type
   ,i_terminalnr               in  werkbestand.wk_terminal%type
   ,i_pr_blokkeren_short_call  in  number
   ,i_pr_blokkeren_short_put   in  number
   ,o_optie_fut_in_positie     out number
   );

-- procedure spredingeis_aanpassing
   procedure spreidingeis_aanpassing
   (i_relatienr                in  clienten.cl_nummer%type
   ,o_extra_spr_port_waarde    out positie_werkbestand.pwb_port_waarde_rapv%type
   ,o_extra_spr_port_waarde_vv out positie_werkbestand.pwb_port_waarde_vv%type
   );

-- procedure vullen_as_posities:
   procedure vullen_AS_posities
   (i_relatienr             in clienten.cl_nummer%type
   ,i_terminalnummer        in werkbestand.wk_terminal%type
   );

-- procedure vullen_margin_werkb:
   procedure vullen_margin_werkb
   (i_relatienr             in clienten.cl_nummer%type
   ,i_terminalnummer        in werkbestand.wk_terminal%type
   ,i_rekening_soort        in rekeningen.re_soort%type
   ,i_rekening_nummer       in rekeningen.re_rekening%type
   ,i_ref_symbool           in beleggingsinstrument.be_referentiesymbool%type
   ,i_symbool               in beleggingsinstrument.be_symbool%type
   ,i_optietype             in beleggingsinstrument.be_optietype%type
   ,i_expiratiedatum        in beleggingsinstrument.be_expiratiedatum%type
   ,i_exerciseprijs         in beleggingsinstrument.be_exerciseprijs%type
   ,i_aantal                in temp_ap_werkbest_sessie.tas_saldo_positie%type
   ,i_aantal_prod_geblok    in temp_margin_wb_sessie.tms_prod_geblok_aantal%type
   ,i_hist_wrd_posbe        in temp_ap_werkbest_sessie.tas_hist_wrd_posbe%type
   ,i_bi_type               in beleggingsinstrument.be_bi_nummer%type
   ,i_margin_factor         in positie_werkbestand.pwb_margin_factor%type
   ,i_biedk_refsymbool      in positie_werkbestand.pwb_biedk_refsymb%type
   ,i_biedk_symbool         in positie_werkbestand.pwb_biedk_symbool%type
   ,i_laatk_symbool         in positie_werkbestand.pwb_laatk_symbool%type
   ,i_prijs_factor          in beleggingsinstrument.be_prijs_factor%type
   ,i_waarborgsom_vv        in positie_werkbestand.pwb_waarborgsom_vv%type
   ,i_init_margin_vv        in positie_werkbestand.pwb_init_margin_vv%type
   ,i_fonds_valuta          in positie_werkbestand.pwb_fonds_valuta%type
   ,i_pricing_unit          in beleggingsinstrument.be_pricing_unit%type
   ,i_runnummer             in temp_ap_werkbest_sessie.tas_runnummer%type
   );

-- DE CODE VOOR DE PROCEDURE RELATIE_VERZAMEL:
procedure relatie_verzamel
(i_relatienummer               in  clienten.cl_nummer%type
,i_client_id                   in  clienten.cl_id%type
,i_sys_toeslag_optiemarg       in  tabelgegevens.tb_waarde%type
,i_rel_toeslag_optiemarg       in  producten.pr_toeslag_percentage%type
,i_methode_naked_margin        in  number
,i_factor_naked_margin         in  number
,i_slot_of_laatste_koers       in  tabelgegevens.tb_symbool%type
,i_terminalnr                  in  werkbestand.wk_terminal%type
,i_productnummer               in  producten_per_relatie.ppr_productnummer%type
,i_productvolgnummer           in  producten_per_relatie.ppr_volgnr_per_product%type
,i_overrule_account_blockade   in  number
,i_meerdere_producten          in  number
,i_te_berekenen_deel           in  varchar2
,i_wegings_fac_munt_gebr       in  number
,i_relatie_heeft_depots        in  number
,i_detail_geg_aanmaken         in  number
,i_dagen_administr_feiten_meen in  number
,i_bedrijfspaar_product        in  number
,i_pr_blokkeren_short_call     in  number
,i_pr_blokkeren_short_put      in  number
,i_herkomst                    in  number
,i_instellingen                in  varchar2
,o_extra_spreid_port_waarde    out positie_werkbestand.pwb_port_waarde_rapv%type
,o_extra_spreid_port_waarde_vv out positie_werkbestand.pwb_port_waarde_vv%type
)

is

   v_optie_fut_in_positie        number;
   v_optie_fut_in_lop_ord        number;
   v_trans_boekdatum_vanaf       transakties.tr_boekdatum%type;
   v_extra_spreid_port_waarde    positie_werkbestand.pwb_port_waarde_rapv%type;
   v_extra_spreid_port_waarde_vv positie_werkbestand.pwb_port_waarde_vv%type;
   -- virtuals voor het ophalen van instellingen
   v_op_te_halen_instel                 varchar2(30);
   v_inst_type                          varchar2(1);
   v_instelling                         varchar2(100);


begin
-- als eerste de globale variabelen vullen:
select r.rf_rapp_muntsoort,    r.rf_rapp_biedkoers,   r.rf_rapp_laatkoers,
       r.rf_rapp_factor,       r.rf_rapp_notatie,     r.rf_rapp_reciproke,
       r.rf_onld_omschrijving, r.rf_onld_percentage,  r.rf_margin,
       r.rf_debug_j_n,         r.rf_debug_user,       r.rf_pr_id,
       r.rf_ppr_id,            r.rf_bv_muntsoort
into   gv_rel_rapp_valuta,     gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers,
       gv_rel_rapp_factor,     gv_rel_rapp_notatie,   gv_rel_rapp_reciproke,
       gv_onld_omschrijving,   gv_onld_percentage,    gv_cl_margin_inst,
       gv_debuggen,            gv_debug_user,         gv_relatie_pr_id,
       gv_relatie_ppr_id,      gv_basismuntsoort
from   relatie_fiattering r
where  r.rf_relatie_nummer = i_relatienummer;

gv_meerdere_producten   := i_meerdere_producten;
gv_detail_geg_aanmaken  := i_detail_geg_aanmaken;
gv_bedrijfspaar_product := i_bedrijfspaar_product;
gv_terminalnummer       := i_terminalnr;

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

v_op_te_halen_instel := 'SuppressFCCollateralLoan';
v_inst_type          := 'N';
select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
into   v_instelling
from   dual;
gv_suppressFCDekkwaarde := to_number(rtrim(ltrim(v_instelling)));

-- Als bedrijfspaar product actief is, dan wel details aanmaken ook als vanuit de
-- aanvraag geen details aangemaakt moet worden....
if gv_bedrijfspaar_product = 1
then
   gv_detail_geg_aanmaken := 1;
end if;

v_optie_fut_in_positie        := 0;
v_optie_fut_in_lop_ord        := 0;
o_extra_spreid_port_waarde    := 0;
o_extra_spreid_port_waarde_vv := 0;

-- De algemene verzamelprocessen:

-- uitvoeren van het bepalen welke rekeningen doorlopen moeten worden:
vullen_doorlopen_rek (i_relatienummer, i_productnummer, i_productvolgnummer, i_overrule_account_blockade, i_meerdere_producten, i_te_berekenen_deel);


if i_herkomst <> 4 and i_herkomst <> 5 and i_herkomst <> 7 -- uitsluiten van alleen margin berekening en alleen effectenkrediet berekening
then
   -- uitvoeren van verzamelen van geld van ka_rekening_info (deze voor de aktuele posities)
   geld_ka_rek (i_relatienummer, i_wegings_fac_munt_gebr);

   -- uitvoeren van verzamelen van geld van aktuele posities
   geld_aktuele_pos (i_relatienummer, i_wegings_fac_munt_gebr);

   -- uitvoeren van het toevoegen van rekeningen die geen positie hebben, maar wel kredietlimiet of overige ruimte
   geld_overige_rekeningen (i_relatienummer);
end if;

-- uitvoeren van verzamelen van niet doorgeboekte transacties
-- bepalen vanaf welke boekdatum de niet doorgeboekte transacties meegenomen moeten worden
-- een waarde van 0 voor aantal dagen administratieve feiten meenemen wordt in de procedure
-- niet_doorgeboekte_trans afgevangen.
if i_herkomst <> 7 -- uitsluiten van alleen bepaling ivm vortex
then
   v_trans_boekdatum_vanaf := to_char(sysdate - i_dagen_administr_feiten_meen,'yyyymmdd');
   niet_doorgeboekt_trans_loop (i_relatienummer,               i_client_id,            v_trans_boekdatum_vanaf,
                                i_dagen_administr_feiten_meen, i_wegings_fac_munt_gebr);
end if;

-- de volgende acties alleen als een klant ook een depot heeft:
if i_relatie_heeft_depots = 1
then
   -- uitvoeren van verzamelen van posities van aktuele posities
   positie_aktuele_pos(i_relatienummer, i_herkomst);

   -- uitvoeren van de afsluitende berekeningen op de positie.
   positie_berekening (i_relatienummer, i_sys_toeslag_optiemarg, i_rel_toeslag_optiemarg, i_methode_naked_margin,
                       i_factor_naked_margin, i_slot_of_laatste_koers, i_terminalnr, i_pr_blokkeren_short_call,
                       i_pr_blokkeren_short_put, v_optie_fut_in_positie);

   -- als de klant als kredietbrief "Extra spreidingseis" heeft, dan hier de berekende dekkingswaarden eventueel
   -- herberekenen
   if gv_onld_omschrijving = 'E'
   then
      v_extra_spreid_port_waarde    := 0;
      v_extra_spreid_port_waarde_vv := 0;
      spreidingeis_aanpassing (i_relatienummer, v_extra_spreid_port_waarde, v_extra_spreid_port_waarde_vv);
      o_extra_spreid_port_waarde    := v_extra_spreid_port_waarde;
      o_extra_spreid_port_waarde_vv := v_extra_spreid_port_waarde_vv;
   end if;

if i_herkomst <> 4 and i_herkomst <> 5 and i_herkomst <> 7 -- uitsluiten van alleen margin berekening en alleen effectenkrediet berekening
then

   -- Controle op het bestaan van lopende orders in opties/futures
   begin
      select 1
      into   v_optie_fut_in_lop_ord
      from   relatie_orders r, orders o
      where  r.ord_relatie             = i_relatienummer
      and    o.ord_ordernummer         = r.ord_ordernummer
      and    o.ord_orderregel          = r.ord_orderregel
      and   (o.ord_status              between 2 and 7
             or
             o.ord_status              between 15 and 16)
      and    o.ord_transstatus         <= 1
      and    o.ord_vervaldatum         >= to_char(sysdate,'yyyymmdd')
      and    o.ord_optietype           in ('CALL','PUT','FUT')
      and    rownum                    <= 1;
   exception
      when no_data_found
      then
         v_optie_fut_in_lop_ord := 0;
   end;

   -- Ook nog controle op de onderhanden zijnde order als er nog geen orders met opties/futures zijn gevonden
   if v_optie_fut_in_lop_ord = 0
   then
      begin
         select 1
         into   v_optie_fut_in_lop_ord
         from   kosten_werkbestand k
         where  k.kst_ordernummer       = -1
         and    k.kst_optietype_fnds    in ('CALL','PUT','FUT')
         and    rownum                  <= 1;
      exception
         when no_data_found
         then
            v_optie_fut_in_lop_ord := 0;
      end;
   end if;

end if;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'In procedure FIAT_VERZAMEL.relatie_verzamel');
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'optie/future in positie: '||to_char(v_optie_fut_in_positie));
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'optie/future in orders : '||to_char(v_optie_fut_in_lop_ord));
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
   end if;

   -- als er opties/futures in positie zijn of in de lopende orders dan moet de margin berekend gaan worden
   -- daarvoor de werkbestanden ook vullen.
   if v_optie_fut_in_positie <> 0 or v_optie_fut_in_lop_ord <> 0
   then
      -- de marginwerkbestanden vullen adhv de client margin instelling
      vullen_as_posities (i_relatienummer, i_terminalnr);
   end if;

end if; -- einde alleen als relatie depot(s) heeft

end relatie_verzamel;
-- EINDE VAN DE PROCEDURE RELATIE_VERZAMEL


-- DE CODE VOOR DE PROCEDURE VULLEN_DOORLOPEN_REK
-- In deze procedure wordt een werkbestand gevuld waarin alle
-- rekeningen staan die van belang zijn voor de bepaling van de
-- bestedingsruimte. Dit is vooral van belang bij meerdere producten
-- (het wordt dan nl een beperekende range).
procedure vullen_doorlopen_rek
(i_relatienummer              in clienten.cl_nummer%type
,i_productnummer              in producten_per_relatie.ppr_productnummer%type
,i_productvolgnummer          in producten_per_relatie.ppr_volgnr_per_product%type
,i_overrule_account_blockade  in number
,i_meerdere_producten         in number
,i_te_berekenen_deel          in varchar2
)

is

v_depot_id                  rekeningen.re_id%type;

begin
if gv_debuggen = 1
then
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In FIAT_VERZAMEL.vullen_doorlopen_rek');
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i relatienummer   : '||to_char(i_relatienummer)||' ; i productnummer : '||to_char(i_productnummer));
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i product volgnr  : '||to_char(i_productvolgnummer)||' ; i meerdere producten : '||to_char(i_meerdere_producten));
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'i te bereken deel : '||i_te_berekenen_deel);
   FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
end if;

-- Het te berekenen deel geeft aan voor welk combi product deel berekend moet worden.
-- Als niet voor S of I wordt gevraagd dan wordt Normaal berekend (dus alles voor een combi product) of voor niet-combinatie producten
if (i_te_berekenen_deel not in ('S','I') or i_te_berekenen_deel = ' ' or i_te_berekenen_deel is null)
then
   -- Als er niet meerdere producten zijn --> rekeningen doorlopen en alles overnemen
   if i_meerdere_producten = 0
   then
      insert into te_doorlopen_rek t
             (t.tdr_rekeningnr,        t.tdr_rekeningsoort,          t.tdr_rekeningmunt,
              t.tdr_rekening_blokkade, t.tdr_rekeningsoort_blokkade, t.tdr_re_id)
      select r.re_rekening,           r.re_soort,                   r.re_muntsoort,
             r.re_geblokkeerd,        s.rs_meenemen_in_vbr,         re_id
      from   rekeningen r, rekening_soorten s
      where  r.re_nummer     = i_relatienummer
      and    r.re_soort      = s.rs_soort;

   -- Als er meerdere producten zijn dan --> Alleen rekeningen die gekoppeld zijn aan
   -- product/productvolgnummer overnemen
   elsif i_meerdere_producten = 1
   then
      insert into te_doorlopen_rek t
             (t.tdr_rekeningnr,             t.tdr_rekeningsoort, t.tdr_rekeningmunt,
              t.tdr_produktnr,              t.tdr_produktvolgnr, t.tdr_rekening_blokkade,
              t.tdr_rekeningsoort_blokkade, t.tdr_re_id)
      select p.rpp_rekening_nummer,        p.rpp_rekeningsoort, p.rpp_valuta,
             i_productnummer,              i_productvolgnummer, r.re_geblokkeerd,
             s.rs_meenemen_in_vbr,         r.re_id
      from   rekeningen_per_product p, rekeningen r, rekening_soorten s
      where  p.rpp_productnummer      = i_productnummer
      and    p.rpp_volgnr_per_product = i_productvolgnummer
      and    p.rpp_relatienummer      = i_relatienummer
      and    r.re_nummer              = p.rpp_relatienummer
      and    r.re_rekening            = p.rpp_rekening_nummer
      and    r.re_soort               = p.rpp_rekeningsoort
      and    r.re_muntsoort           = p.rpp_valuta
      and    s.rs_soort               = p.rpp_rekeningsoort;
   end if;
-- De berekening is voor het spaardeel (Savings)
elsif i_te_berekenen_deel = 'S'
then
   -- De geldrekening meenemen als deze niet een gekoppeld securities re id hebben.
   insert into te_doorlopen_rek t
          (t.tdr_rekeningnr,             t.tdr_rekeningsoort, t.tdr_rekeningmunt,
           t.tdr_produktnr,              t.tdr_produktvolgnr, t.tdr_rekening_blokkade,
           t.tdr_rekeningsoort_blokkade, t.tdr_re_id)
   select p.rpp_rekening_nummer,        p.rpp_rekeningsoort, p.rpp_valuta,
          i_productnummer,              i_productvolgnummer, r.re_geblokkeerd,
          s.rs_meenemen_in_vbr,         r.re_id
   from   rekeningen_per_product p, rekeningen r, rekening_soorten s
   where  p.rpp_productnummer      = i_productnummer
   and    p.rpp_volgnr_per_product = i_productvolgnummer
   and    p.rpp_relatienummer      = i_relatienummer
   and    p.rpp_rekeningsoort      >= 1000
   and    r.re_nummer              = p.rpp_relatienummer
   and    r.re_rekening            = p.rpp_rekening_nummer
   and    r.re_soort               = p.rpp_rekeningsoort
   and    r.re_muntsoort           = p.rpp_valuta
   and    s.rs_soort               = p.rpp_rekeningsoort
   and    r.re_securities_re_id    is null;

-- De berekening is voor het beleggendeel (Investments)
elsif i_te_berekenen_deel = 'I'
then
   -- Er is maar 1 depot op een product aanwezig. Daarom is het mogelijk om het id op te halen
   -- Het gevonden depot + alle daaraan gekoppelde geldrekeningen moeten worden gebruikt voor de bestedingsruimte.
   select r.re_id
   into   v_depot_id
   from   rekeningen_per_product p, rekeningen r
   where  p.rpp_productnummer      = i_productnummer
   and    p.rpp_volgnr_per_product = i_productvolgnummer
   and    p.rpp_relatienummer      = i_relatienummer
   and    p.rpp_rekeningsoort      between 100 and 999
   and    p.rpp_relatienummer      = r.re_nummer
   and    p.rpp_rekening_nummer    = r.re_rekening
   and    p.rpp_rekeningsoort      = r.re_soort
   and    p.rpp_valuta             = r.re_muntsoort
   and    rownum                   <= 1;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'depot re id : '||to_char(v_depot_id));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

   insert into te_doorlopen_rek t
          (t.tdr_rekeningnr,             t.tdr_rekeningsoort, t.tdr_rekeningmunt,
           t.tdr_produktnr,              t.tdr_produktvolgnr, t.tdr_rekening_blokkade,
           t.tdr_rekeningsoort_blokkade, t.tdr_re_id)
   select p.rpp_rekening_nummer,        p.rpp_rekeningsoort, p.rpp_valuta,
          i_productnummer,              i_productvolgnummer, r.re_geblokkeerd,
          s.rs_meenemen_in_vbr,         r.re_id
   from   rekeningen_per_product p, rekeningen r, rekening_soorten s
   where  p.rpp_productnummer      = i_productnummer
   and    p.rpp_volgnr_per_product = i_productvolgnummer
   and    p.rpp_relatienummer      = i_relatienummer
   and    r.re_nummer              = p.rpp_relatienummer
   and    r.re_rekening            = p.rpp_rekening_nummer
   and    r.re_soort               = p.rpp_rekeningsoort
   and    r.re_muntsoort           = p.rpp_valuta
   and    s.rs_soort               = p.rpp_rekeningsoort
   and    (r.re_id                 = v_depot_id
           or
           r.re_securities_re_id   = v_depot_id);

end if;
-- Gegevens nog omzetten zodat blokkades die actief zijn met een waarde 1 worden opgeslagen
-- Voor geldrekeningen geldt:
-- tdr_rekeningsoort_blokkade = 1 dan meenemen, dit omzetten naar een waarde 0 en een waarde 0 omzetten naar 1
-- tdr_rekening_blokkade <> 0 dan bepalen of de blokkade moet worden meegenomen. Als blokkade actief is de waarde op 1 zetten

declare
  v_module_prefix          instellingen.inst_appl_prefix%type;
  v_functiecode            instellingen.inst_functiecode%type;
  v_inst_omschrijving      varchar2(31);
  v_inst_type              varchar2(1);
  v_instelling             varchar2(100);
  v_blokkade_rekening      number(1)         := 0;
  v_rekeningsoort_blokkade number(1)         := 0;

  cursor td is
    select t.tdr_rekeningnr,        t.tdr_rekeningsoort,          t.tdr_rekeningmunt,
           t.tdr_rekening_blokkade, t.tdr_rekeningsoort_blokkade, t.tdr_re_id,
           t.rowid
    from   te_doorlopen_rek t
    where  t.tdr_rekeningsoort >= 1000;

begin
   for r_td in td
   loop
      v_blokkade_rekening      := 0;
      v_rekeningsoort_blokkade := 0;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Rekeningnummer : '||r_td.tdr_rekeningnr||' ; Rekeningsoort : '||to_char(r_td.tdr_rekeningsoort));
         FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Rekeningvaluta : '||r_td.tdr_rekeningmunt||' ; rekening id : '||to_char(r_td.tdr_re_id));
         FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Rekeningblokkade voor : '||to_char(r_td.tdr_rekening_blokkade)||
                                                  ' ; Rekeningsoort blokkade : '||to_char(r_td.tdr_rekeningsoort_blokkade));
         FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
     end if;

      -- omzetten rekeningsoort blokkade:
      -- Blokkade actief wordt 1 (was 0)
      -- Blokkade niet actief wordt 0 (was 1)
      if r_td.tdr_rekeningsoort_blokkade = 0
      then
         v_rekeningsoort_blokkade := 1;
      elsif r_td.tdr_rekeningsoort_blokkade = 1
      then
         v_rekeningsoort_blokkade := 0;
      end if;

      if r_td.tdr_rekening_blokkade <> 0 and i_overrule_account_blockade = 0
      then
         -- eerst bepalen of de blokkade soort wel meegenomen mag worden:
         -- LET OP DIT IS NIET TE WIJZIGEN IN DE INSTELLINGEN STRING. DEZE CONSTRUCTIE HIER DUS LATEN STAAN !!!!
         v_module_prefix      := 'oa';
         v_functiecode        := 'FIATVE';
         v_inst_omschrijving  := 'positief_geldsaldo_blok_'||to_char(r_td.tdr_rekening_blokkade);
         v_inst_type          := 'N';
         select FIAT_ALGEMEEN.instell_ophalen(v_module_prefix, v_functiecode, v_inst_omschrijving, v_inst_type, gv_debuggen, gv_debug_user)
         into   v_instelling
         from   dual;
         v_blokkade_rekening := to_number(rtrim(ltrim(v_instelling)));
         -- Als de blokkade instelling actief is dan heeft v_blokkade_rekening de waarde 1 (anders heeft hij de waarde 0).
      else 
         -- Als i_overrule_account_blockade = 1 dan overrule van de account blokkade
         v_blokkade_rekening := 0;  
      end if;
              

      -- Als laatste de gegevens wegschrijven in het bestand
      update te_doorlopen_rek r
      set    r.tdr_rekening_blokkade      = v_blokkade_rekening,
             r.tdr_rekeningsoort_blokkade = v_rekeningsoort_blokkade
      where  r.rowid                      = r_td.rowid;
   end loop;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Einde procedure FIAT_VERZAMEL.vullen_doorlopen_rek');
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
   end if;

end;

end vullen_doorlopen_rek;
-- EINDE VAN DE PROCEDURE VULLEN_DOORLOPEN_REK


-- DE CODE VOOR DE PROCEDURE GELD_KA_REK:
-- In deze procedure worden de externe geldrekeningen doorlopen en de gegevens worden
-- weggeschreven in het geld_werkbestand
-- (vergelijk Magic programma 157 br-calc. geldrekening+kasass, subtaak 2).
procedure geld_ka_rek
(i_relatienr                in clienten.cl_nummer%type
,i_wegings_fac_munt_gebr    in number
)
-- inkomende parameters zijn: i_relatienr    = Relatienummer

is
       v_saldobedrag            geld_werkbestand.gwb_saldo_vv%type;
       v_saldobedrag_bv         geld_werkbestand.gwb_saldo_rapv%type;
       v_saldobedrag_vv_sl      geld_werkbestand.gwb_saldo_vv_sl%type;
       v_intern_extern          varchar2(1);
       v_wegings_factor_long    wegingsfactoren.wg_interne_perc%type;
       v_wegings_factor_short   wegingsfactoren.wg_intern_short_perc%type;
       v_rekening_meenemen      number(1);
       v_dummy_product          producten.pr_productnummer%type;

       v_valuta_biedkoers       muntsoorten.mu_biedkoers%type;
       v_valuta_laatkoers       muntsoorten.mu_laatkoers%type;
       v_valuta_factor          muntsoorten.mu_factor%type;
       v_valuta_reciproke       muntsoorten.mu_reciproke%type;
       v_valuta_notatie         muntsoorten.mu_notatie%type;
       v_dummy_waarde           muntsoorten.mu_middenkoers%type;

cursor kr is

       select k.kri_rekmuntsoort, k.kri_rekeningsoort,    k.kri_rekeningnummer,
              k.kri_saldo_rc,     k.kri_sign_rc,
              w.wg_interne_perc,  w.wg_intern_short_perc, w.wg_nummer
       from   ka_rekening_info k, wegingsfactoren w, muntsoorten m --muntsoorten moet aanwezig blijven voor de wegingsfactor...
       where  k.kri_relatienummer  = i_relatienr
       and    k.kri_saldo_rc       <> 0
       and    m.mu_code            = k.kri_rekmuntsoort
       and    m.mu_wegingsfactornr = w.wg_nummer (+);

begin
    for r_kr in kr
    loop
       -- Resetten van de variabelen
       v_saldobedrag          := 0;
       v_saldobedrag_bv       := 0;
       v_intern_extern        := 'E';
       v_rekening_meenemen    := 1;  -- in eerste instantie er vanuit gaan dat de rekening mee moet worden genomen

       -- bepalen of een rekening moet mee worden genomen:
       begin
          -- Kijken of de ka rekening bestaat binnen de te doorlopen rekeningen:
          select t.tdr_produktnr
          into   v_dummy_product
          from   te_doorlopen_rek t
          where  t.tdr_rekeningnr    = r_kr.kri_rekeningnummer
          and    t.tdr_rekeningsoort = r_kr.kri_rekeningsoort
          and    t.tdr_rekeningmunt  = r_kr.kri_rekmuntsoort;

       exception
          when no_data_found
          then
             v_rekening_meenemen := 0;

       end;

       -- Doorgaan als de rekening meegenomen moet worden:
       if v_rekening_meenemen = 1
       then
          -- ophalen van de valutakoersen en enkele andere valuta gegevens
          FIAT_ALGEMEEN.valutagegevens_bepalen (r_kr.kri_rekmuntsoort,   gv_relatie_pr_id,   gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                                gv_bank2mrktqchangedate, gv_debuggen,        gv_debug_user,     v_valuta_biedkoers,
                                                v_dummy_waarde,          v_valuta_laatkoers, v_valuta_factor,   v_valuta_reciproke,
                                                v_valuta_notatie);

          if r_kr.wg_nummer is null
          then
             v_wegings_factor_long  := 0;
             v_wegings_factor_short := 0;
          else
             v_wegings_factor_long  := r_kr.wg_interne_perc;
             v_wegings_factor_short := r_kr.wg_intern_short_perc;
          end if;

          -- Teken voor het saldobedrag plaatsen
          if r_kr.kri_sign_rc = 'Db'
          then
             v_saldobedrag := r_kr.kri_saldo_rc * -1;
          else
             v_saldobedrag := r_kr.kri_saldo_rc;
          end if;

          v_saldobedrag_vv_sl := v_saldobedrag;

          -- Saldobedrag omrekenen naar de rapportagevaluta.
          if r_kr.kri_rekmuntsoort <> gv_rel_rapp_valuta
          then
             select FIAT_ALGEMEEN.gld_omrekenen_bedrag_vv (v_saldobedrag, v_valuta_reciproke, v_valuta_factor, v_valuta_biedkoers,
                                                           v_valuta_laatkoers, gv_rel_rapp_reciproke, gv_rel_rapp_factor,
                                                           gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
             into   v_saldobedrag_bv
             from   dual;
          else
             v_saldobedrag_bv := v_saldobedrag;
          end if;

          -- wegingsfactor meenemen? Dan berekenen met de wegingsfactor short bij saldo <0 en wegingsfactor long bij saldo > 0
          if i_wegings_fac_munt_gebr = 1
          then
             if v_saldobedrag_bv <0 and v_wegings_factor_short <> 0
             then
                v_saldobedrag_bv    := v_saldobedrag_bv * v_wegings_factor_short/100;
                v_saldobedrag_vv_sl := v_saldobedrag_vv_sl * v_wegings_factor_short/100;
             elsif v_saldobedrag_bv > 0 and v_wegings_factor_long <>0
             then
                v_saldobedrag_bv    := v_saldobedrag_bv * v_wegings_factor_long/100;
                v_saldobedrag_vv_sl := v_saldobedrag_vv_sl * v_wegings_factor_long/100;
             end if;
          end if;

          -- De gegevens wegschrijven in het tijdelijke werkbestand:
          insert into geld_werkbestand
          (gwb_relatie_nummer,      gwb_rekening_nummer,     gwb_rekening_soort,
           gwb_rekening_munt,       gwb_intern_extern,       gwb_saldo_vv,
           gwb_saldo_rapv,          gwb_rek_munt_weegperc_l, gwb_rek_munt_weegperc_s,
           gwb_saldo_vv_sl)
          values
          (i_relatienr,             r_kr.kri_rekeningnummer, r_kr.kri_rekeningsoort,
           r_kr.kri_rekmuntsoort,   v_intern_extern,         v_saldobedrag,
           v_saldobedrag_bv,        v_wegings_factor_long,   v_wegings_factor_short,
           v_saldobedrag_vv_sl);
       end if;
    end loop;

end geld_ka_rek;
-- EINDE CODE VAN DE PROCEDURE GELD_KA_REK


-- DE CODE VOOR DE PROCEDURE GELD_AKTUELE_POS:
-- In deze procedure worden de interne geldrekeningen doorlopen en de gegevens worden
-- weggeschreven in het geld_werkbestand
-- (vergelijk Magic programma 157 br-calc. geldrekening+kasass, subtaak 1).
procedure geld_aktuele_pos
(i_relatienr                in clienten.cl_nummer%type
,i_wegings_fac_munt_gebr    in number
)
-- inkomende parameters zijn: i_relatienr                = Relatienummer
--                            i_wegings_fac_munt_gebr    = Geeft aan of wegingsfactor gebruikt moet worden voor berekeningen

is
  v_saldo_vv               aktuele_posities.ap_saldo_positie%type;
  v_saldo_vv_sl            aktuele_posities.ap_saldo_positie%type;
  v_saldo_bv               aktuele_posities.ap_saldo_positie%type;
  v_krediet_bv             rekeningen.re_credietlimiet%type;
  v_ruimte_bv              rekeningen.re_overige_ruimte%type;
  v_intern_extern          varchar2(1);
  v_wegings_fact_long      wegingsfactoren.wg_interne_perc%type;
  v_wegings_fact_short     wegingsfactoren.wg_intern_short_perc%type;

  v_valuta_biedkoers       muntsoorten.mu_biedkoers%type;
  v_valuta_laatkoers       muntsoorten.mu_laatkoers%type;
  v_valuta_factor          muntsoorten.mu_factor%type;
  v_valuta_reciproke       muntsoorten.mu_reciproke%type;
  v_valuta_notatie         muntsoorten.mu_notatie%type;
  v_dummy_waarde           muntsoorten.mu_middenkoers%type;

cursor ap is

select a.ap_relatienr,     a.ap_rekeningnr,        a.ap_rekening_soort, a.ap_rekening_munts,
       a.ap_saldo_positie,
       r.re_credietlimiet, r.re_overige_ruimte,    r.re_geblokkeerd,
       w.wg_interne_perc,  w.wg_intern_short_perc, w.wg_nummer
from   aktuele_posities a, rekeningen r, muntsoorten m, wegingsfactoren w, -- muntsoorten moeten aanwezig blijven voor de wegingsfactoren
       te_doorlopen_rek t
where  a.ap_relatienr       = i_relatienr
and    a.ap_relatienr       = r.re_nummer
and    a.ap_rekening_soort  = r.re_soort
and    a.ap_rekeningnr      = r.re_rekening
and    a.ap_rekening_munts  = r.re_muntsoort
and    a.ap_rekening_soort    between 1000 and 9999
and    a.ap_rekening_munts  = m.mu_code
and    a.ap_rekeningnr      = t.tdr_rekeningnr                -- inner join!! op te_doorlopen_rek
and    a.ap_rekening_soort  = t.tdr_rekeningsoort             -- om op deze manier af te dwingen dat allen
and    a.ap_rekening_munts  = t.tdr_rekeningmunt              -- door toegestane rekeningen wordt gelopen
and    m.mu_wegingsfactornr = w.wg_nummer (+);

begin
   for r_ap in ap
   loop
      -- Resetten van de variabelen
      v_saldo_bv             := 0;
      v_krediet_bv           := 0;
      v_ruimte_bv            := 0;
      v_intern_extern        := 'I';

      FIAT_ALGEMEEN.valutagegevens_bepalen (r_ap.ap_rekening_munts,  gv_relatie_pr_id,   gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                            gv_bank2mrktqchangedate, gv_debuggen,        gv_debug_user,     v_valuta_biedkoers,
                                            v_dummy_waarde,          v_valuta_laatkoers, v_valuta_factor,   v_valuta_reciproke,
                                            v_valuta_notatie);

      if r_ap.wg_nummer is null
      then
         v_wegings_fact_long  := 0;
         v_wegings_fact_short := 0;
      else
         v_wegings_fact_long  := r_ap.wg_interne_perc;
         v_wegings_fact_short := r_ap.wg_intern_short_perc;
      end if;

      v_saldo_vv    := r_ap.ap_saldo_positie;
      v_saldo_vv_sl := r_ap.ap_saldo_positie;

      -- Omrekenen van het saldobedrag naar de rapportagevaluta
      if gv_rel_rapp_valuta <> r_ap.ap_rekening_munts
      then
         select FIAT_ALGEMEEN.gld_omrekenen_bedrag_vv (v_saldo_vv, v_valuta_reciproke, v_valuta_factor, v_valuta_biedkoers,
                                                       v_valuta_laatkoers, gv_rel_rapp_reciproke, gv_rel_rapp_factor,
                                                       gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
         into   v_saldo_bv
         from   dual;
      else
         v_saldo_bv := r_ap.ap_saldo_positie;
      end if;

      -- wegingsfactor meenemen? Dan berekenen met de wegingsfactor short bij saldo <0 en wegingsfactor long bij saldo > 0
      if i_wegings_fac_munt_gebr = 1
      then
         if v_saldo_bv <0 and v_wegings_fact_short <> 0
         then
            v_saldo_bv    := v_saldo_bv * v_wegings_fact_short/100;
            v_saldo_vv_sl := v_saldo_vv_sl * v_wegings_fact_short/100;
         elsif v_saldo_bv > 0 and v_wegings_fact_long <>0
         then
            v_saldo_bv    := v_saldo_bv * v_wegings_fact_long/100;
            v_saldo_vv_sl := v_saldo_vv_sl * v_wegings_fact_long/100;
         end if;
      end if;

      -- Omrekenen van de kredietlimiet naar de rapportagevaluta
      if gv_rel_rapp_valuta <> r_ap.ap_rekening_munts
      then
         select FIAT_ALGEMEEN.gld_omrekenen_bedrag_vv (r_ap.re_credietlimiet, v_valuta_reciproke, v_valuta_factor, v_valuta_biedkoers,
                                                       v_valuta_laatkoers, gv_rel_rapp_reciproke, gv_rel_rapp_factor,
                                                       gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
         into   v_krediet_bv
         from   dual;
      else
         v_krediet_bv := r_ap.re_credietlimiet;
      end if;

      -- Omrekenen van de overige ruimte naar de rapportagevaluta
      if gv_rel_rapp_valuta <> r_ap.ap_rekening_munts
      then
         select FIAT_ALGEMEEN.gld_omrekenen_bedrag_vv (r_ap.re_overige_ruimte, v_valuta_reciproke, v_valuta_factor, v_valuta_biedkoers,
                                                       v_valuta_laatkoers,  gv_rel_rapp_reciproke, gv_rel_rapp_factor,
                                                       gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
         into   v_ruimte_bv
         from   dual;
      else
         v_ruimte_bv := r_ap.re_overige_ruimte;
      end if;

      -- De gegevens wegschrijven in het tijdelijke werkbestand:
      insert into geld_werkbestand
      (gwb_relatie_nummer,      gwb_rekening_nummer,     gwb_rekening_soort,
       gwb_rekening_munt,       gwb_intern_extern,       gwb_saldo_vv,
       gwb_kredietlimiet_vv,    gwb_overige_ruimte_vv,   gwb_saldo_rapv,
       gwb_kredietlimiet_rapv,  gwb_overige_ruimte_rapv, gwb_rek_munt_weegperc_l,
       gwb_rek_munt_weegperc_s, gwb_saldo_vv_sl)
      values
      (r_ap.ap_relatienr,       r_ap.ap_rekeningnr,      r_ap.ap_rekening_soort,
       r_ap.ap_rekening_munts,  v_intern_extern,         v_saldo_vv,
       r_ap.re_credietlimiet,   r_ap.re_overige_ruimte,  v_saldo_bv,
       v_krediet_bv,            v_ruimte_bv,             v_wegings_fact_long,
       v_wegings_fact_short,    v_saldo_vv_sl);

   end loop;

end geld_aktuele_pos;
-- EINDE CODE VAN DE PROCEDURE GELD_AKTUELE_POS


-- DE CODE VOOR DE PROCEDURE GELD_OVERIGE_REKENINGEN:
-- In deze procedure worden alle rekeningen opgehaald die nog niet zijn geadministreerd
-- in de twee vooraf gaande procedures (dus waar geen positie op geweest is);
-- en aansluitend weggeschreven in het geld_werkbestand als er overige ruimte en/of kredietlimiet
-- van toepassing is
procedure geld_overige_rekeningen
(i_relatienr                in clienten.cl_nummer%type
)
-- inkomende parameters zijn: i_relatienr    = Relatienummer

is
  v_krediet_bv             rekeningen.re_credietlimiet%type;
  v_ruimte_bv              rekeningen.re_overige_ruimte%type;
  v_intern_extern          varchar2(1);
  v_wegings_fact_long      wegingsfactoren.wg_interne_perc%type;
  v_wegings_fact_short     wegingsfactoren.wg_intern_short_perc%type;

  v_valuta_biedkoers       muntsoorten.mu_biedkoers%type;
  v_valuta_laatkoers       muntsoorten.mu_laatkoers%type;
  v_valuta_factor          muntsoorten.mu_factor%type;
  v_valuta_reciproke       muntsoorten.mu_reciproke%type;
  v_valuta_notatie         muntsoorten.mu_notatie%type;
  v_dummy_waarde           muntsoorten.mu_middenkoers%type;

cursor re is
    select r.re_nummer,         r.re_rekening,          r.re_soort,     r.re_muntsoort,
           r.re_overige_ruimte, r.re_credietlimiet,
           w.wg_interne_perc,   w.wg_intern_short_perc, w.wg_nummer
    from   rekeningen r,       muntsoorten m, wegingsfactoren w, -- muntsoorten aanwezig voor bepaling van de wegingsfactoren
           te_doorlopen_rek t
    where  r.re_nummer          = i_relatienr
    and    (r.re_overige_ruimte <> 0
            or
            r.re_credietlimiet  <> 0)
    and    r.re_soort           between 1000 and 1999
    and    r.re_rekening        = t.tdr_rekeningnr           -- inner join!! op te_doorlopen_rek
    and    r.re_soort           = t.tdr_rekeningsoort        -- om op deze manier af te dwingen dat allen
    and    r.re_muntsoort       = t.tdr_rekeningmunt         -- door toegestane rekeningen wordt gelopen
    and    r.re_muntsoort       = m.mu_code
    and    m.mu_wegingsfactornr = w.wg_nummer (+)
    and    not exists  -- DEZE REKENINGEN MOGEN AL NIET VOOR KOMEN IN HET GELD_WERKBESTAND:
          (select 1
           from   geld_werkbestand g
           where  g.gwb_relatie_nummer  = r.re_nummer
           and    g.gwb_rekening_nummer = r.re_rekening
           and    g.gwb_rekening_soort  = r.re_soort
           and    g.gwb_rekening_munt   = r.re_muntsoort);

begin
  for r_re in re
    loop
       -- Resetten van variabelen
       v_krediet_bv    := 0;
       v_ruimte_bv     := 0;
       v_intern_extern := 'I';

       -- weggingsfactoren vastleggen
       if r_re.wg_nummer is null
       then
          v_wegings_fact_long  := 0;
          v_wegings_fact_short := 0;
       else
          v_wegings_fact_long  := r_re.wg_interne_perc;
          v_wegings_fact_short := r_re.wg_intern_short_perc;
       end if;

       -- Omrekenen van de kredietlimiet en de overige ruimte naar de rapportagevaluta
       if gv_rel_rapp_valuta <> r_re.re_muntsoort
       then
          FIAT_ALGEMEEN.valutagegevens_bepalen (r_re.re_muntsoort,       gv_relatie_pr_id,   gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                                gv_bank2mrktqchangedate, gv_debuggen,        gv_debug_user,     v_valuta_biedkoers,
                                                v_dummy_waarde,          v_valuta_laatkoers, v_valuta_factor,   v_valuta_reciproke,
                                                v_valuta_notatie);

          select FIAT_ALGEMEEN.gld_omrekenen_bedrag_vv (r_re.re_credietlimiet, v_valuta_reciproke, v_valuta_factor, v_valuta_biedkoers,
                                                        v_valuta_laatkoers, gv_rel_rapp_reciproke, gv_rel_rapp_factor,
                                                        gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
          into   v_krediet_bv
          from   dual;

          select FIAT_ALGEMEEN.gld_omrekenen_bedrag_vv (r_re.re_overige_ruimte, v_valuta_reciproke, v_valuta_factor, v_valuta_biedkoers,
                                                        v_valuta_laatkoers, gv_rel_rapp_reciproke, gv_rel_rapp_factor,
                                                        gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
          into   v_ruimte_bv
          from   dual;
       else
          v_krediet_bv := r_re.re_credietlimiet;
          v_ruimte_bv  := r_re.re_overige_ruimte;
       end if;

       -- Deze rekeningen staan nog niet in het bestand dus voldoet een insert:
       insert into geld_werkbestand
       (gwb_relatie_nummer,      gwb_rekening_nummer,     gwb_rekening_soort,
        gwb_rekening_munt,       gwb_intern_extern,       gwb_saldo_vv,
        gwb_kredietlimiet_vv,    gwb_overige_ruimte_vv,   gwb_saldo_rapv,
        gwb_kredietlimiet_rapv,  gwb_overige_ruimte_rapv, gwb_rek_munt_weegperc_l,
        gwb_rek_munt_weegperc_s)
       values
       (r_re.re_nummer,          r_re.re_rekening,        r_re.re_soort,
        r_re.re_muntsoort,       v_intern_extern,         0,
        r_re.re_credietlimiet,   r_re.re_overige_ruimte,  0,
        v_krediet_bv,            v_ruimte_bv,             v_wegings_fact_long,
        v_wegings_fact_short);

    end loop;

end geld_overige_rekeningen;
-- EINDE CODE VAN DE PROCEDURE GELD_OVERIGE_REKENINGEN


-- DE CODE VOOR DE PROCEDURE NIET_DOORGEBOEKT_TRANS:
-- In deze procedure worden de niet doorgeboekte transacties voor een relatie verzameld
-- en aan het positie werkbestand toegevoegd. NB er wordt rekening gehouden met eventueel al
-- uitgevoerde deel mutaties (geld of stukken).
procedure niet_doorgeboekt_trans
(i_relatienr                   in clienten.cl_nummer%type
,i_transaktie_volgnummer       in transakties.tr_volgnummer%type
,i_wegings_fac_munt_gebr       in number
)
-- Inkomende parameters zijn: i_relatienr              = Relatienummer
--                            i_transaktie_volgnummer  = Het transaktievolgnummer van een niet volledig doorgeboekte
--                                                       transaktie waar de relatie in voor komt.

is
       v_relatiekant            number(1);
       v_depotnummer            rekeningen.re_rekening%type;
       v_depot_rek_soort        rekeningen.re_soort%type;
       v_rekeningnummer         rekeningen.re_rekening%type;
       v_rekeningsoort          rekeningen.re_soort%type;
       v_rekeningmuntsoort      rekeningen.re_muntsoort%type;
       v_mutatie_bedrag         transakties.tr_notabedrag%type;
       v_mutatie_aantal         transakties.tr_aantal%type;
       v_mutatie_bedrag_rapv    transakties.tr_notabedrag%type;
       v_mutatie_bedrag_vv_sl   transakties.tr_notabedrag%type;
       v_rekening_munt_bkoers   muntsoorten.mu_biedkoers%type;
       v_rekening_munt_lkoers   muntsoorten.mu_laatkoers%type;
       v_rekening_munt_fact     transakties.tr_rel1_munts_fac%type;
       v_rekening_munt_recip    transakties.tr_rel1_munts_rcp%type;
       v_rekening_gevonden      number(1);
       v_mutatie_uitgevoerd     number(1);
       v_wegingsfactor_munt_l   wegingsfactoren.wg_interne_perc%type;
       v_wegingsfactor_munt_s   wegingsfactoren.wg_intern_short_perc%type;
       v_wegingsfactor_nr       wegingsfactoren.wg_nummer%type;
       v_dummy_waarde           muntsoorten.mu_middenkoers%type;

       v_bi_nummer              beleggingsinstrument.be_bi_nummer%type;
       v_exass_factor           beleggingsinstrument.be_exass_factor%type;
       v_referentiesymbool      beleggingsinstrument.be_referentiesymbool%type;
       v_koop_verkoop_ind       transactiesoorten.ts_koop_verkoop_ind%type;

cursor tr is

       select t.tr_rel1,              t.tr_rel1_rek1,         t.tr_rel1_rek1_soort,
              t.tr_rel1_rek2,         t.tr_rel1_rek2_soort,   t.tr_rel1_rek2_munts,
              t.tr_rel1_munts_krs,    t.tr_rel1_munts_fac,    t.tr_rel1_munts_rcp,
              t.tr_notabedrag,        t.tr_rel2,              t.tr_rel2_rek1,
              t.tr_rel2_rek1_soort,   t.tr_rel2_rek2,         t.tr_rel2_rek2_soort,
              t.tr_rel2_rek2_munts,   t.tr_rel2_munts_krs,    t.tr_rel2_munts_fac,
              t.tr_rel2_munts_rcp,    t.tr_brutobedrag,
              t.tr_symbool,           t.tr_optietype,         t.tr_expiratiedatum,
              t.tr_exerciseprijs,     t.tr_aantal,            t.tr_indicatie,
              t.tr_transnummer,       t.tr_invoernummer,      t.tr_terminalnummer,
              tv.trip_tr_status,      t.tr_volgnummer,        t.tr_tpc_actions,
              t.tr_geldblok_ind_rel1, t.tr_geldblok_ind_rel2, t.tr_opdrachtnummer
       from   transakties t, tv_transactions_in_progress tv
       where  t.tr_volgnummer         = i_transaktie_volgnummer
       and    t.tr_volgnummer = tv.trip_tr_volgnummer (+);


begin
    for r_tr in tr
    loop
    -- Resetten van de gebruikte hulpvariabelen
    v_relatiekant          :=   0;
    v_depotnummer          := ' ';
    v_depot_rek_soort      :=   0;
    v_rekeningnummer       := ' ';
    v_rekeningsoort        :=   0;
    v_rekeningmuntsoort    := ' ';
    v_mutatie_aantal       :=   0;
    v_mutatie_bedrag       :=   0;
    v_mutatie_bedrag_rapv  :=   0;
    v_mutatie_bedrag_vv_sl :=   0;
    v_rekening_munt_bkoers :=   0;
    v_rekening_munt_lkoers :=   0;
    v_rekening_munt_fact   :=   0;
    v_rekening_munt_recip  :=   0;
    v_rekening_gevonden    :=   0;
    v_mutatie_uitgevoerd   :=   0;
    v_wegingsfactor_munt_l :=   0;
    v_wegingsfactor_munt_s :=   0;

    if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'In niet doorgeboekte transacties, tr_volgnummer : '||to_char(r_tr.tr_volgnummer));
       FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'transactiesymbool : '||r_tr.tr_symbool||' ; transactieoptietype : '||r_tr.tr_optietype);
       FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'transactieexpiratiedatum : '||r_tr.tr_expiratiedatum||
                                                 ' ; transactieexerciseprijs : '||to_char(r_tr.tr_exerciseprijs));
       FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
    end if;


    -- ophalen van de beleggingsinstrumentgegevens van het transactiesymbool:
    select b.be_bi_nummer, b.be_exass_factor, b.be_referentiesymbool
    into   v_bi_nummer,    v_exass_factor,    v_referentiesymbool
    from   beleggingsinstrument b
    where  b.be_symbool         = r_tr.tr_symbool
    and    b.be_optietype       = r_tr.tr_optietype
    and    b.be_expiratiedatum  = r_tr.tr_expiratiedatum
    and    b.be_exerciseprijs   = r_tr.tr_exerciseprijs;

    -- Ophalen van de koop/verkoop indicatie voor de Tr_Indicatie:
    select s.ts_koop_verkoop_ind
    into   v_koop_verkoop_ind
    from   transactiesoorten s
    where  s.ts_symbool         = r_tr.tr_indicatie;

    -- Het is mogelijk dat zowel relatie 1 als 2 de gevraagde relatie is
    -- bijvoorbeeld bij overboekingen. Dus daarom per relatiekant de gegevens
    -- verwerken en niet genest want dan kun je 1 kant missen.

    -- relatie waarvoor de gegevens verzameld worden is de tr_rel1
    if i_relatienr = r_tr.tr_rel1
    then
       v_relatiekant         := 1;
       v_depotnummer         := r_tr.tr_rel1_rek1;
       v_depot_rek_soort     := r_tr.tr_rel1_rek1_soort;
       v_rekeningnummer      := r_tr.tr_rel1_rek2;
       v_rekeningsoort       := r_tr.tr_rel1_rek2_soort;
       v_rekeningmuntsoort   := r_tr.tr_rel1_rek2_munts;
       v_mutatie_bedrag      := r_tr.tr_notabedrag;
       v_mutatie_aantal      := r_tr.tr_aantal;

       -- controleren of de rekeningen wel voldoen aan de toegestane rekeningen,
       -- allen bij meerdere produkten, anders zijn toch alle rekeningen toegestaan!
       if gv_meerdere_producten = 1
       then
          -- door het v_mutatie_bedrag of mutatie_aantal op 0 te zetten bij het niet toestaan van de
          -- rekeningen zal de transactie niet verder meegenomen worden.
          -- De depotrekening:
          begin
             select decode(t.tdr_rekeningnr, v_depotnummer, 1,0)
             into   v_rekening_gevonden
             from   te_doorlopen_rek t
             where  t.tdr_rekeningnr    = v_depotnummer
             and    t.tdr_rekeningsoort = v_depot_rek_soort;
          exception
             when no_data_found
             then
                -- rekening is niet gevonden dus hier mutatie_aantal op 0 zetten!
                v_mutatie_aantal := 0;
          end;

          -- De geldrekening:
          begin
             select decode (t.tdr_rekeningnr, v_rekeningnummer, 1, 0)
             into   v_rekening_gevonden
             from   te_doorlopen_rek t
             where  t.tdr_rekeningnr    = v_rekeningnummer
             and    t.tdr_rekeningsoort = v_rekeningsoort
             and    t.tdr_rekeningmunt  = v_rekeningmuntsoort;
          exception
             when no_data_found
             then
                -- rekening is niet gevonden dus hier v_mutatie_bedrag op 0 zetten!
                v_mutatie_bedrag := 0;
          end;
       end if;

       -- het notabedrag tegen de huidige koers waarderen!
       if v_mutatie_bedrag <> 0
       then
          select w.wg_interne_perc,      w.wg_intern_short_perc, w.wg_nummer
          into   v_wegingsfactor_munt_l, v_wegingsfactor_munt_s, v_wegingsfactor_nr
          from   muntsoorten m, wegingsfactoren w                -- muntsoorten hier laten staan voor de wegingsfactoren
          where  m.mu_code            = v_rekeningmuntsoort
          and    m.mu_wegingsfactornr = w.wg_nummer (+);

          -- als de wegingsfactor niet goed bepaald is dan de factoren op 0 zetten.
          if v_wegingsfactor_nr is null
          then
             v_wegingsfactor_munt_l := 0;
             v_wegingsfactor_munt_s := 0;
          end if;
       end if;
    end if;

    -- RELATIEKANT 1
    -- als de relatiekant voor relatie 1 is gezet dan uitvoeren:

    -- eerst geld
    -- moet het geld nog uitgevoerd worden, dus nog doorgeboekt worden?
    -- als tr_nummer 0 is dan moet alles nog gedaan worden, anders naar de status kijken.
    if r_tr.tr_transnummer = 0
    then
       v_mutatie_uitgevoerd := 0;
    else
       select FIAT_ALGEMEEN.transstatus (r_tr.trip_tr_status, r_tr.tr_tpc_actions, v_relatiekant, 2)
       into v_mutatie_uitgevoerd
       from dual;
    end if;

    -- uitvoeren als mutatiebedrag <> 0 is en de mutatie nog uitgevoerd moet worden (mutatie_uitgevoerd = 0).
    if v_relatiekant = 1 and v_mutatie_bedrag <> 0 and v_mutatie_uitgevoerd = 0
    then
       -- teken van het bedrag aanpassen aan de transactiesoort:
       if v_koop_verkoop_ind = 1
          or
          v_koop_verkoop_ind = 2
          or
          r_tr.tr_indicatie = 'BYST'
          or
          r_tr.tr_indicatie = 'DP O'  -- nb alleen voor tr_rel1 !!!
          or
          r_tr.tr_indicatie = 'DP M'  -- nb alleen voor tr_rel1 !!!
          or
          r_tr.tr_indicatie = 'O-G1'
       then
          v_mutatie_bedrag := v_mutatie_bedrag * -1;
       end if;

       -- mutatie bedrag alleen berekenen als het geen transactie naar aanleiding van een beleggingsopdracht betreft
       if r_tr.tr_opdrachtnummer = 0
       then
          -- mutatiebedrag omrekenen naar de rapportage valuta:
          if gv_rel_rapp_valuta <> v_rekeningmuntsoort
          then
             FIAT_ALGEMEEN.valutagegevens_bepalen (v_rekeningmuntsoort,     gv_relatie_pr_id,       gv_relatie_ppr_id,    gv_systspreadcodecategorie,
                                                   gv_bank2mrktqchangedate, gv_debuggen,            gv_debug_user,        v_rekening_munt_bkoers,
                                                   v_dummy_waarde,          v_rekening_munt_lkoers, v_rekening_munt_fact, v_rekening_munt_recip,
                                                   v_dummy_waarde);

             select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_mutatie_bedrag, v_rekening_munt_recip, v_rekening_munt_fact, v_rekening_munt_bkoers,
                                                       v_rekening_munt_lkoers, gv_rel_rapp_reciproke, gv_rel_rapp_factor,
                                                       gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
             into   v_mutatie_bedrag_rapv
             from   dual;
          else
             v_mutatie_bedrag_rapv := v_mutatie_bedrag;
          end if;

          v_mutatie_bedrag_vv_sl := v_mutatie_bedrag;

          if i_wegings_fac_munt_gebr = 1
          then
             if v_mutatie_bedrag_rapv < 0 and v_wegingsfactor_munt_s <> 0
             then
                v_mutatie_bedrag_rapv  := v_mutatie_bedrag_rapv * v_wegingsfactor_munt_s/100;
                v_mutatie_bedrag_vv_sl := v_mutatie_bedrag_vv_sl * v_wegingsfactor_munt_s/100;
             elsif v_mutatie_bedrag_rapv > 0 and v_wegingsfactor_munt_l <> 0
             then
                v_mutatie_bedrag_rapv  := v_mutatie_bedrag_rapv * v_wegingsfactor_munt_l/100;
                v_mutatie_bedrag_vv_sl := v_mutatie_bedrag_vv_sl * v_wegingsfactor_munt_l/100;
             end if;
          end if;
       else
          v_mutatie_bedrag_rapv  := 0;
          v_mutatie_bedrag_vv_sl := 0;
       end if;

       -- proberen te updaten van het geldrecord:
       update geld_werkbestand
       set    gwb_trans_mut_vv    = gwb_trans_mut_vv + v_mutatie_bedrag,
              gwb_trans_mut_rapv  = gwb_trans_mut_rapv + v_mutatie_bedrag_rapv,
              gwb_trans_mut_vv_sl = gwb_trans_mut_vv_sl + v_mutatie_bedrag_vv_sl
       where  gwb_relatie_nummer  = i_relatienr
       and    gwb_rekening_nummer = v_rekeningnummer
       and    gwb_rekening_soort  = v_rekeningsoort
       and    gwb_rekening_munt   = v_rekeningmuntsoort
       and    gwb_intern_extern   = 'I';

       -- als de update niet is gelukt, dan bestaat het record nog niet en moet dit dus worden toegevoegd
       if sql%notfound
       then
          insert into geld_werkbestand
          (gwb_relatie_nummer,      gwb_rekening_nummer,     gwb_rekening_soort,
           gwb_rekening_munt,       gwb_intern_extern,       gwb_trans_mut_vv,
           gwb_trans_mut_rapv,      gwb_rek_munt_weegperc_l, gwb_rek_munt_weegperc_s,
           gwb_trans_mut_vv_sl)
          values
          (i_relatienr,             v_rekeningnummer,        v_rekeningsoort,
           v_rekeningmuntsoort,     'I',                     v_mutatie_bedrag,
           v_mutatie_bedrag_rapv,   v_wegingsfactor_munt_l,  v_wegingsfactor_munt_s,
           v_mutatie_bedrag_vv_sl);
       end if;
       -- Wegschrijven van de gebruikte transacties in een werkbestand, alleen indien gewenst:
       if gv_detail_geg_aanmaken = 1
       then
          insert into werkbestand
          (wk_terminal,       wk_soort,        wk_categorie_1,
           wk_categorie_2,
           wk_categorie_3,
           wk_categorie_4,                     wk_waarde_1,
           wk_waarde_2,                        wk_waarde_3,
           wk_waarde_4,                        wk_export)
          values
          (gv_terminalnummer, 'TRGL',          ltrim(to_char(i_relatienr,'999999999')),
           ltrim(v_rekeningmuntsoort || ' ' ||  to_char(v_rekeningsoort,'9999') || ' ' || v_rekeningnummer),
           ltrim(to_char(r_tr.tr_volgnummer,'999999999999999')),
           ltrim(to_char(v_relatiekant,'9')),  v_mutatie_bedrag,
           v_mutatie_bedrag_rapv,              v_relatiekant,
           r_tr.tr_volgnummer,                 r_tr.tr_geldblok_ind_rel1);
       end if;

    -- Einde relatiekant 1 geld
    end if;

    -- Als tweede de positie
    -- mutatie in stukken uitvoeren als het be_bi_nummer van het fonds < 4000 is.
    -- moet de mutatie nog uitgevoerd worden, dus nog doorgeboekt worden?
    -- als tr_nummer 0 is dan moet alles nog gedaan worden, anders naar de status kijken.
    v_mutatie_uitgevoerd := 0;     -- reset van de geldkant
    if r_tr.tr_transnummer = 0
    then
       v_mutatie_uitgevoerd := 0;
    else
       select FIAT_ALGEMEEN.transstatus (r_tr.trip_tr_status, r_tr.tr_tpc_actions, v_relatiekant, 1)
       into v_mutatie_uitgevoerd
       from dual;
    end if;

    -- uitvoeren als mutatie nog uitvoeren, be_bi_nummer < 4000 en mutatie_aantal <> 0, bijstellingen zijn geldboekingen...
    if v_relatiekant = 1 and v_mutatie_aantal <> 0 and v_mutatie_uitgevoerd = 0 and v_bi_nummer < 4000
       and r_tr.tr_indicatie not in ('BYST','TOEK','LOSB')
    then
       -- teken van het aantal aanpassen aan de transactiesoort:
       if r_tr.tr_indicatie in ('EX C','EX P','AS C','AS P')
       then
          if r_tr.tr_indicatie in ('EX C','EX P')
          then
             v_mutatie_aantal := abs(v_mutatie_aantal) * -1;
          else
             v_mutatie_aantal := abs(v_mutatie_aantal);
          end if;
       else
          if v_koop_verkoop_ind = 2 or r_tr.tr_indicatie in ('AFL')
          then
             v_mutatie_aantal := v_mutatie_aantal * -1;
          end if;
       end if;

       -- Niet van alle mutaties het aantal verrekenen (close van futures):
       if r_tr.tr_indicatie not in ('SV F','SK F')
       then
          -- proberen te updaten van het positie record
          update positie_werkbestand
          set    pwb_trans_mut       = pwb_trans_mut + case when r_tr.tr_opdrachtnummer = 0 then v_mutatie_aantal else 0 end,
                 pwb_trans_aanwezig  = 1
          where  pwb_relatie_nummer  = i_relatienr
          and    pwb_rekening_nummer = v_depotnummer
          and    pwb_rekening_soort  = v_depot_rek_soort
          and    pwb_symbool         = r_tr.tr_symbool
          and    pwb_optietype       = r_tr.tr_optietype
          and    pwb_expiratiedatum  = r_tr.tr_expiratiedatum
          and    pwb_exerciseprijs   = r_tr.tr_exerciseprijs;

          -- als de update niet is gelukt, dan bestaat het record nog niet en moet dit dus worden toegevoegd
          if sql%notfound
          then
             insert into positie_werkbestand
             (pwb_relatie_nummer,    pwb_rekening_nummer, pwb_rekening_soort,
              pwb_symbool,           pwb_optietype,       pwb_expiratiedatum,
              pwb_exerciseprijs,     pwb_trans_mut,
              pwb_trans_aanwezig)
             values
             (i_relatienr,           v_depotnummer,       v_depot_rek_soort,
              r_tr.tr_symbool,       r_tr.tr_optietype,   r_tr.tr_expiratiedatum,
              r_tr.tr_exerciseprijs, case when r_tr.tr_opdrachtnummer = 0 then v_mutatie_aantal else 0 end,
              1);
          end if;
       else
          -- het aantal voor deze moet op 0 worden gesteld om te voorkomen dat die meegerekend worden
          -- proberen te updaten van het positie record
          update positie_werkbestand
          set    pwb_trans_mut       = pwb_trans_mut + 0,
                 pwb_trans_aanwezig  = 1
          where  pwb_relatie_nummer  = i_relatienr
          and    pwb_rekening_nummer = v_depotnummer
          and    pwb_rekening_soort  = v_depot_rek_soort
          and    pwb_symbool         = r_tr.tr_symbool
          and    pwb_optietype       = r_tr.tr_optietype
          and    pwb_expiratiedatum  = r_tr.tr_expiratiedatum
          and    pwb_exerciseprijs   = r_tr.tr_exerciseprijs;

          -- als de update niet is gelukt, dan bestaat het record nog niet en moet dit dus worden toegevoegd
          if sql%notfound
          then
             insert into positie_werkbestand
             (pwb_relatie_nummer,    pwb_rekening_nummer, pwb_rekening_soort,
              pwb_symbool,           pwb_optietype,       pwb_expiratiedatum,
              pwb_exerciseprijs,     pwb_trans_mut,       pwb_trans_aanwezig)
             values
             (i_relatienr,           v_depotnummer,       v_depot_rek_soort,
              r_tr.tr_symbool,       r_tr.tr_optietype,   r_tr.tr_expiratiedatum,
              r_tr.tr_exerciseprijs, 0,                   1);
          end if;
       end if;

       -- Voor exercise en assignments ook nog de stukkenkant meenemen (dus geldt niet voor index opties)!
       -- De optiekant is hierboven al gedaan (is nl het symbool).
       if r_tr.tr_indicatie in ('EX C','EX P','AS C','AS P') and v_bi_nummer not between 3000 and 3099
       then
          -- Mutatie aantal is het transactieaantal maal de exercise assignment factor.
          v_mutatie_aantal := r_tr.tr_aantal * v_exass_factor;

          -- teken van het aantal aanpassen aan de transactiesoort:
          if v_koop_verkoop_ind = 2
          then
             v_mutatie_aantal := v_mutatie_aantal * -1;
          end if;

          -- proberen te updaten van het positie record
          update positie_werkbestand
          set    pwb_trans_mut       = pwb_trans_mut + v_mutatie_aantal,
                 pwb_trans_aanwezig  = 1
          where  pwb_relatie_nummer  = i_relatienr
          and    pwb_rekening_nummer = v_depotnummer
          and    pwb_rekening_soort  = v_depot_rek_soort
          and    pwb_symbool         = v_referentiesymbool
          and    pwb_optietype       = ' '
          and    pwb_expiratiedatum  = '00000000'
          and    pwb_exerciseprijs   = 0;

          -- als de update niet is gelukt, dan bestaat het record nog niet en moet dit dus worden toegevoegd
          if sql%notfound
          then
             insert into positie_werkbestand
             (pwb_relatie_nummer,        pwb_rekening_nummer, pwb_rekening_soort,
              pwb_symbool,               pwb_optietype,       pwb_expiratiedatum,
              pwb_exerciseprijs,         pwb_trans_mut,       pwb_trans_aanwezig)
             values
             (i_relatienr,               v_depotnummer,       v_depot_rek_soort,
              v_referentiesymbool,       ' ',                 '00000000',
              0,                         v_mutatie_aantal,    1);
          end if;
       end if;

       -- Wegschrijven van de gebruikte transacties in een werkbestand, alleen indien gewenst:
       if gv_detail_geg_aanmaken = 1
       then
          insert into werkbestand
          (wk_terminal,      wk_soort,               wk_categorie_1,
           wk_categorie_2,
           wk_categorie_3,   wk_categorie_4,         wk_datum_1,
           wk_waarde_1,      wk_waarde_2,
           wk_waarde_3,      wk_waarde_4)
          values
          (gv_terminalnummer, 'TRPO',                ltrim(to_char(i_relatienr,'999999999')),
           ltrim(to_char(r_tr.tr_volgnummer,'999999999999999'))||' '||ltrim(to_char(v_relatiekant,'9')),
           r_tr.tr_symbool,   r_tr.tr_optietype,     r_tr.tr_expiratiedatum,
           v_mutatie_aantal,  r_tr.tr_exerciseprijs,
           v_relatiekant,     r_tr.tr_volgnummer);
       end if;

    -- Einde relatiekant 1 positie
    end if;
    -- EINDE RELATIEKANT 1

    -- RELATIEKANT 2
    -- relatie waarvoor de gegevens verzameld worden is de tr_rel2
    if i_relatienr = r_tr.tr_rel2
    then
       v_relatiekant         := 2;
       v_depotnummer         := r_tr.tr_rel2_rek1;
       v_depot_rek_soort     := r_tr.tr_rel2_rek1_soort;
       v_rekeningnummer      := r_tr.tr_rel2_rek2;
       v_rekeningsoort       := r_tr.tr_rel2_rek2_soort;
       v_rekeningmuntsoort   := r_tr.tr_rel2_rek2_munts;
       v_mutatie_bedrag      := r_tr.tr_brutobedrag;
       v_mutatie_aantal      := r_tr.tr_aantal;

       -- controleren of de rekeningen wel voldoen aan de toegestane rekeningen,
       -- allen bij meerdere produkten, anders zijn toch alle rekeningen toegestaan!
       if gv_meerdere_producten = 1
       then
          -- door het mutatie_bedrag of mutatie_aantal op 0 te zetten bij het niet toestaan van de
          -- rekeningen zal de transactie niet verder meegenomen worden.
          -- De depotrekening:
          begin
             select decode(t.tdr_rekeningnr, v_depotnummer, 1,0)
             into   v_rekening_gevonden
             from   te_doorlopen_rek t
             where  t.tdr_rekeningnr    = v_depotnummer
             and    t.tdr_rekeningsoort = v_depot_rek_soort;
          exception
             when no_data_found
             then
                -- rekening is niet gevonden dus hier mutatie_aantal op 0 zetten!
                v_mutatie_aantal := 0;
          end;

          -- De geldrekening:
          begin
             select decode (t.tdr_rekeningnr, v_rekeningnummer, 1, 0)
             into   v_rekening_gevonden
             from   te_doorlopen_rek t
             where  t.tdr_rekeningnr    = v_rekeningnummer
             and    t.tdr_rekeningsoort = v_rekeningsoort
             and    t.tdr_rekeningmunt  = v_rekeningmuntsoort;
          exception
             when no_data_found
             then
                -- rekening is niet gevonden dus hier mutatie_bedrag op 0 zetten!
                v_mutatie_bedrag := 0;
          end;
       end if;

       if v_mutatie_bedrag <> 0
       then
          -- het brutobedrag tegen de huidige koers waarderen!
          select w.wg_interne_perc,      w.wg_intern_short_perc, w.wg_nummer
          into   v_wegingsfactor_munt_l, v_wegingsfactor_munt_s, v_wegingsfactor_nr
          from   muntsoorten m, wegingsfactoren w                    -- muntsoorten hier laten staan om wegingsfactoren te bepalen
          where  m.mu_code            = v_rekeningmuntsoort
          and    m.mu_wegingsfactornr = w.wg_nummer (+);
          -- als de wegingsfactor niet goed bepaald is dan de factoren op 0 zetten.
          if v_wegingsfactor_nr is null
          then
             v_wegingsfactor_munt_l := 0;
             v_wegingsfactor_munt_s := 0;
          end if;
       end if;
    end if;

    -- als de relatiekant voor relatie 2 is gezet dan uitvoeren:

    -- eerst geld
    -- moet het geld nog uitgevoerd worden, dus nog doorgeboekt worden?
    -- als tr_nummer 0 is dan moet alles nog gedaan worden, anders naar de status kijken.
    if r_tr.tr_transnummer = 0
    then
       v_mutatie_uitgevoerd := 0;
    else
       select FIAT_ALGEMEEN.transstatus (r_tr.trip_tr_status, r_tr.tr_tpc_actions, v_relatiekant, 2)
       into v_mutatie_uitgevoerd
       from dual;
    end if;

    -- uitvoeren als mutatiebedrag <> 0 is en de mutatie nog uitgevoerd moet worden (mutatie_uitgevoerd = 0).
    if v_relatiekant = 2 and v_mutatie_bedrag <> 0 and v_mutatie_uitgevoerd = 0
    then
       -- teken van het bedrag aanpassen aan de transactiesoort hoeft voor zover nu bekend alleen voor BYST.
       if r_tr.tr_indicatie = 'BYST'
       then
          v_mutatie_bedrag := v_mutatie_bedrag * -1;
       end if;

       -- mutatie bedrag alleen berekenen als het geen transactie naar aanleiding van een beleggingsopdracht betreft
       if r_tr.tr_opdrachtnummer = 0
       then
          -- mutatiebedrag omrekenen naar de rapportage valuta:
          if gv_rel_rapp_valuta <> v_rekeningmuntsoort
          then
             FIAT_ALGEMEEN.valutagegevens_bepalen (v_rekeningmuntsoort,     gv_relatie_pr_id,       gv_relatie_ppr_id,    gv_systspreadcodecategorie,
                                                   gv_bank2mrktqchangedate, gv_debuggen,            gv_debug_user,        v_rekening_munt_bkoers,
                                                   v_dummy_waarde,          v_rekening_munt_lkoers, v_rekening_munt_fact, v_rekening_munt_recip,
                                                   v_dummy_waarde);

             select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_mutatie_bedrag, v_rekening_munt_recip, v_rekening_munt_fact, v_rekening_munt_bkoers,
                                                       v_rekening_munt_lkoers, gv_rel_rapp_reciproke, gv_rel_rapp_factor,
                                                       gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
             into   v_mutatie_bedrag_rapv
             from   dual;
          else
             v_mutatie_bedrag_rapv := v_mutatie_bedrag;
          end if;

          v_mutatie_bedrag_vv_sl := v_mutatie_bedrag;

          if i_wegings_fac_munt_gebr = 1
          then
             if v_mutatie_bedrag_rapv < 0 and v_wegingsfactor_munt_s <> 0
             then
                v_mutatie_bedrag_rapv  := v_mutatie_bedrag_rapv * v_wegingsfactor_munt_s/100;
                v_mutatie_bedrag_vv_sl := v_mutatie_bedrag_vv_sl * v_wegingsfactor_munt_s/100;
             elsif v_mutatie_bedrag_rapv > 0 and v_wegingsfactor_munt_l <> 0
             then
                v_mutatie_bedrag_rapv  := v_mutatie_bedrag_rapv * v_wegingsfactor_munt_l/100;
                v_mutatie_bedrag_vv_sl := v_mutatie_bedrag_vv_sl * v_wegingsfactor_munt_l/100;
             end if;
          end if;
       else
          v_mutatie_bedrag_rapv  := 0;
          v_mutatie_bedrag_vv_sl := 0;
       end if;

       -- proberen te updaten van het geldrecord:
       update geld_werkbestand
       set    gwb_trans_mut_vv    = gwb_trans_mut_vv + v_mutatie_bedrag,
              gwb_trans_mut_rapv  = gwb_trans_mut_rapv + v_mutatie_bedrag_rapv,
              gwb_trans_mut_vv_sl = gwb_trans_mut_vv_sl + v_mutatie_bedrag_vv_sl
       where  gwb_relatie_nummer  = i_relatienr
       and    gwb_rekening_nummer = v_rekeningnummer
       and    gwb_rekening_soort  = v_rekeningsoort
       and    gwb_rekening_munt   = v_rekeningmuntsoort
       and    gwb_intern_extern   = 'I';

       -- als de update niet is gelukt, dan bestaat het record nog niet en moet dit dus worden toegevoegd
       if sql%notfound
       then
          insert into geld_werkbestand
          (gwb_relatie_nummer,      gwb_rekening_nummer,     gwb_rekening_soort,
           gwb_rekening_munt,       gwb_intern_extern,       gwb_trans_mut_vv,
           gwb_trans_mut_rapv,      gwb_rek_munt_weegperc_l, gwb_rek_munt_weegperc_s,
           gwb_trans_mut_vv_sl)
          values
          (i_relatienr,             v_rekeningnummer,        v_rekeningsoort,
           v_rekeningmuntsoort,     'I',                     v_mutatie_bedrag,
           v_mutatie_bedrag_rapv,   v_wegingsfactor_munt_l,  v_wegingsfactor_munt_s,
           v_mutatie_bedrag_vv_sl);
       end if;

       -- Wegschrijven van de gebruikte transacties in een werkbestand, alleen indien gewenst:
       if gv_detail_geg_aanmaken = 1
       then
          insert into werkbestand
          (wk_terminal,       wk_soort,              wk_categorie_1,
           wk_categorie_2,
           wk_categorie_3,
           wk_categorie_4,                           wk_waarde_1,
           wk_waarde_2,                              wk_waarde_3,
           wk_waarde_4,                              wk_export)
          values
          (gv_terminalnummer, 'TRGL',                ltrim(to_char(i_relatienr,'999999999')),
           ltrim(v_rekeningmuntsoort || ' ' ||  to_char(v_rekeningsoort,'9999') || ' ' || v_rekeningnummer),
           ltrim(to_char(r_tr.tr_volgnummer,'999999999999999')),
           ltrim(to_char(v_relatiekant,'9')),        v_mutatie_bedrag,
           v_mutatie_bedrag_rapv,                    v_relatiekant,
           r_tr.tr_volgnummer,                       r_tr.tr_geldblok_ind_rel2);
       end if;

    -- Einde relatiekant 2 geld
    end if;

    -- Als tweede de positie
    -- mutatie in stukken uitvoeren als het be_bi_nummer van het fonds < 4000 is.
    -- moet de mutatie nog uitgevoerd worden, dus nog doorgeboekt worden?
    -- als tr_nummer 0 is dan moet alles nog gedaan worden, anders naar de status kijken.
    v_mutatie_uitgevoerd := 0;     -- reset van de geldkant
    if r_tr.tr_transnummer = 0
    then
       v_mutatie_uitgevoerd := 0;
    else
       select FIAT_ALGEMEEN.transstatus (r_tr.trip_tr_status, r_tr.tr_tpc_actions, v_relatiekant, 1)
       into v_mutatie_uitgevoerd
       from dual;
    end if;

    -- uitvoeren als mutatie nog uitvoeren, be_bi_nummer < 4000 en mutatie_aantal <> 0, bijstellingen zijn geldboekingen...
    if v_relatiekant = 2 and v_mutatie_aantal <> 0 and v_mutatie_uitgevoerd = 0 and v_bi_nummer < 4000
       and r_tr.tr_indicatie not in ('BYST','TOEK','LOSB')
    then
       -- teken van het aantal aanpassen aan de transactiesoort:
       if v_koop_verkoop_ind = 1
       then
          v_mutatie_aantal := v_mutatie_aantal * -1;
       end if;

       -- proberen te updaten van het positie record
       update positie_werkbestand
       set    pwb_trans_mut       = pwb_trans_mut + case when r_tr.tr_opdrachtnummer = 0 then v_mutatie_aantal else 0 end,
              pwb_trans_aanwezig  = 1
       where  pwb_relatie_nummer  = i_relatienr
       and    pwb_rekening_nummer = v_depotnummer
       and    pwb_rekening_soort  = v_depot_rek_soort
       and    pwb_symbool         = r_tr.tr_symbool
       and    pwb_optietype       = r_tr.tr_optietype
       and    pwb_expiratiedatum  = r_tr.tr_expiratiedatum
       and    pwb_exerciseprijs   = r_tr.tr_exerciseprijs;

       -- als de update niet is gelukt, dan bestaat het record nog niet en moet dit dus worden toegevoegd
       if sql%notfound
       then
         insert into positie_werkbestand
         (pwb_relatie_nummer,    pwb_rekening_nummer, pwb_rekening_soort,
          pwb_symbool,           pwb_optietype,       pwb_expiratiedatum,
          pwb_exerciseprijs,     pwb_trans_mut,
          pwb_trans_aanwezig)
         values
         (i_relatienr,           v_depotnummer,       v_depot_rek_soort,
          r_tr.tr_symbool,       r_tr.tr_optietype,   r_tr.tr_expiratiedatum,
          r_tr.tr_exerciseprijs, case when r_tr.tr_opdrachtnummer = 0 then v_mutatie_aantal else 0 end,
          1);
       end if;
       -- Wegschrijven van de gebruikte transacties in een werkbestand, alleen indien gewenst:
       if gv_detail_geg_aanmaken = 1
       then
          insert into werkbestand
          (wk_terminal,            wk_soort,          wk_categorie_1,
           wk_categorie_2,
           wk_categorie_3,         wk_categorie_4,
           wk_datum_1,             wk_waarde_1,       wk_waarde_2,
           wk_waarde_3,            wk_waarde_4)
          values
          (gv_terminalnummer,      'TRPO',            ltrim(to_char(i_relatienr,'999999999')),
           ltrim(to_char(r_tr.tr_volgnummer,'999999999999999'))||' '||ltrim(to_char(v_relatiekant,'9')),
           r_tr.tr_symbool,        r_tr.tr_optietype,
           r_tr.tr_expiratiedatum, v_mutatie_aantal,  r_tr.tr_exerciseprijs,
           v_relatiekant,          r_tr.tr_volgnummer);
       end if;

    -- Einde relatiekant 2 positie
    end if;
    -- EINDE RELATIEKANT 2

    end loop;

end niet_doorgeboekt_trans;
-- EINDE CODE VAN DE PROCEDURE NIET_DOOTGEBOEKT_TRANS


-- DE CODE VOOR DE PROCEDURE NIET_DOOTGEBOEKT_TRANS_LOOP
-- procedure niet_doorgeboekt_trans_loop
procedure niet_doorgeboekt_trans_loop
(i_relatienr                   in clienten.cl_nummer%type
,i_client_id                   in clienten.cl_id%type
,i_boekdatum_vanaf             in transakties.tr_boekdatum%type
,i_dagen_administr_feiten_meen in number
,i_wegings_fac_munt_gebr       in number
)

is

  v_trans_bind_BYST        transakties.tr_indicatie%type         := 'BYST';
  v_trans_bind_YTD         transakties.tr_indicatie%type         := 'YTD';
  v_herk_bind_BGND         transakties.tr_herkomst_code_tr%type  := 'BGND';

begin
   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'In de niet doorgeboekte transactiesloop');
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'boekdatum vanaf : '||i_boekdatum_vanaf||
                                                                  ' ; dagen admini. feiten meenemen : '||to_char(i_dagen_administr_feiten_meen));
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
   end if;

   if i_dagen_administr_feiten_meen = 0 -- geen beperking op boekdatum
   then
      declare
         cursor tr is
            select distinct(t.trai_tr_volgnummer)
            from   tv_trip_rel_account_info t, transakties k
            where  t.trai_tr_cl_id        = i_client_id
            and    t.trai_tr_account_code in (1,2,3,4)     -- alleen voor relatie 1 depot en geldrek en relatie 2 depot en geldrek
            and    t.trai_tr_volgnummer   = k.tr_volgnummer
            and    k.tr_herkomst_code_tr  <> v_herk_bind_BGND
            and    k.tr_indicatie         not in (v_trans_bind_BYST, v_trans_bind_YTD);

      begin
         for r_tr in tr
         loop
            niet_doorgeboekt_trans (i_relatienr, r_tr.trai_tr_volgnummer, i_wegings_fac_munt_gebr);
         end loop;
      end;

   else -- wel beperking op boekdatum
      declare
         cursor tr is
            select distinct(t.trai_tr_volgnummer)
            from   tv_trip_rel_account_info t, transakties k
            where  t.trai_tr_cl_id        = i_client_id
            and    t.trai_tr_account_code in (1,2,3,4)     -- alleen voor relatie 1 depot en geldrek en relatie 2 depot en geldrek
            and    t.trai_tr_volgnummer   = k.tr_volgnummer
            and    k.tr_herkomst_code_tr  <> v_herk_bind_BGND
            and    k.tr_indicatie         not in (v_trans_bind_BYST, v_trans_bind_YTD)
            and    k.tr_boekdatum         >= i_boekdatum_vanaf;

      begin
         for r_tr in tr
         loop
            niet_doorgeboekt_trans (i_relatienr, r_tr.trai_tr_volgnummer, i_wegings_fac_munt_gebr);
         end loop;
      end;

   end if;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Einde niet doorgeboekte transactiesloop');
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
   end if;

end niet_doorgeboekt_trans_loop;
-- EINDE CODE VAN DE PROCEDURE NIET_DOOTGEBOEKT_TRANS_LOOP


-- DE CODE VOOR DE PROCEDURE POSITIE_AKTUELE_POS:
-- Procedure voor het vullen van het positie werkbestand met de aktuele positie
-- van de opgegeven relatie.
procedure positie_aktuele_pos
(i_relatienr                in clienten.cl_nummer%type
,i_herkomst                 in number
)
-- inkomende parameters zijn : i_relatienr = Relatienummer

is

-- door de aktuele posities voor de opgegeven relatie.
cursor ap is
         select a.ap_symbool,        a.ap_optietype,      a.ap_expiratiedatum,
                a.ap_exerciseprijs,  a.ap_saldo_positie,  a.ap_sld_losbaar_marg,
                a.ap_hist_wrd_totbe, a.ap_hist_wrd_posbe, a.ap_saldo_totaall_s,
                a.ap_rekening_soort, a.ap_rekeningnr
         from   aktuele_posities a,  te_doorlopen_rek t
         where  a.ap_relatienr      = i_relatienr             -- alle posities worden overgenomen (ook geexpireerde opties/futures
         and    a.ap_saldo_positie  <> 0                      -- als de positie nog bestaat)
         and    a.ap_rekening_soort between 100 and 999
         and    a.ap_rekeningnr     = t.tdr_rekeningnr        -- inner join!! op te_doorlopen_rek
         and    a.ap_rekening_soort = t.tdr_rekeningsoort     -- om op deze manier af te dwingen dat allen
         and    a.ap_rekening_munts = t.tdr_rekeningmunt      -- door toegestane rekeningen wordt gelopen
         and    (i_herkomst         <> 7
                 or
                 a.ap_optietype     = ' ');

begin
  for r_ap in ap
    loop

      -- proberen te updaten van het werkbestand als het record al bestaat
      update positie_werkbestand p
      set    p.pwb_saldo_positie   = p.pwb_saldo_positie + r_ap.ap_saldo_positie,
             p.pwb_sld_losbaar     = p.pwb_sld_losbaar + r_ap.ap_sld_losbaar_marg,
             p.pwb_hist_wrd_totbe  = p.pwb_hist_wrd_totbe + r_ap.ap_hist_wrd_totbe,
             p.pwb_hist_wrd_posbe  = p.pwb_hist_wrd_posbe + r_ap.ap_hist_wrd_posbe,
             p.pwb_saldo_totaall_s = p.pwb_saldo_totaall_s + r_ap.ap_saldo_totaall_s,
             p.pwb_effect_lop_ord  = p.pwb_effect_lop_ord + r_ap.ap_saldo_positie
      where  p.pwb_relatie_nummer  = i_relatienr
      and    p.pwb_rekening_nummer = r_ap.ap_rekeningnr
      and    p.pwb_rekening_soort  = r_ap.ap_rekening_soort
      and    p.pwb_symbool         = r_ap.ap_symbool
      and    p.pwb_optietype       = r_ap.ap_optietype
      and    p.pwb_expiratiedatum  = r_ap.ap_expiratiedatum
      and    p.pwb_exerciseprijs   = r_ap.ap_exerciseprijs;

      -- als dit niet lukt, dan het record inserten in het werkbestand:
      if sql%notfound
      then
          insert into positie_werkbestand
          (pwb_relatie_nummer,     pwb_rekening_nummer,      pwb_rekening_soort,
           pwb_symbool,            pwb_optietype,            pwb_expiratiedatum,
           pwb_exerciseprijs,      pwb_sld_losbaar,          pwb_hist_wrd_totbe,
           pwb_hist_wrd_posbe,     pwb_saldo_totaall_s,      pwb_saldo_positie,
           pwb_effect_lop_ord)
          values
          (i_relatienr,            r_ap.ap_rekeningnr,       r_ap.ap_rekening_soort,
           r_ap.ap_symbool,        r_ap.ap_optietype,        r_ap.ap_expiratiedatum,
           r_ap.ap_exerciseprijs,  r_ap.ap_sld_losbaar_marg, r_ap.ap_hist_wrd_totbe,
           r_ap.ap_hist_wrd_posbe, r_ap.ap_saldo_totaall_s,  r_ap.ap_saldo_positie,
           r_ap.ap_saldo_positie);
      end if;

    end loop;
end positie_aktuele_pos;
-- EINDE CODE VAN DE PROCEDURE POSITIE_AKTUELE_POS


-- DE CODE VOOR DE PROCEDURE POSITIE_BEREKENING:
-- Procedure voor het berekenen van de portefeuiile-, dekkings- en bruto marginwaarden van de
-- positie van een relatie. Ook onder andere het bijstellingsbedrag en de lopende rente worden berekend.
procedure positie_berekening
(i_relatienummer            in  clienten.cl_nummer%type
,i_sys_toeslag_optiemarg    in  tabelgegevens.tb_waarde%type
,i_rel_toeslag_optiemarg    in  producten.pr_toeslag_percentage%type
,i_methode_naked_margin     in  number
,i_factor_naked_margin      in  number
,i_slot_of_laatste_koers    in  tabelgegevens.tb_symbool%type
,i_terminalnr               in  werkbestand.wk_terminal%type
,i_pr_blokkeren_short_call  in  number
,i_pr_blokkeren_short_put   in  number
,o_optie_fut_in_positie     out number
)



-- inkomende parameters zijn : i_relatienummer         = Relatienummer
--                             i_sys_toeslag_optiemarg = Systeem toeslag optiemargin
--                             i_rel_toeslag_optiemarg = Relatie toeslag optiemargin
--                             i_slot_of_laatste_koers = Slot of Laatste koers (S of L)
--                             i_terminalnr            = het terminalnummer waarvoor de gegevens vastgelegd moeten worden
--                             o_optie_fut_in_positie  = variabele die aangeeft of in de positie een optie of
--                                                       future positie aanwezig is

is

  v_fonds_bied_koers            fn_quotes_vw.quot_bied%type;
  v_fonds_laat_koers            fn_quotes_vw.quot_laat%type;
  v_fonds_werk_koers            fn_quotes_vw.quot_bied%type;
  v_fonds_werk_koers_munt       fn_quotes_vw.quot_bied%type;
  v_relatie_werk_koers_munt     muntsoorten.mu_biedkoers%type;
  v_rente_factor                number(14,9);
  v_lopende_rente               positie_werkbestand.pwb_lopende_rente_vv%type;
  v_portefeuille_waarde         positie_werkbestand.pwb_port_waarde_vv%type;
  v_portefeuille_waarde_rapv    positie_werkbestand.pwb_port_waarde_rapv%type;
  v_dekkingswaarde_rapv         positie_werkbestand.pwb_dekk_waarde_rapv%type;
  v_dekkingswaarde_vv_sl        positie_werkbestand.pwb_dekk_waarde_vv_sl%type;
  v_fonds_afloskoers            fn_quotes_vw.quot_bied%type;
  v_dekkingspercentage          number(6,3);
  v_bijstellingskoers           number(17,6);
  v_bijstellingsbedrag          positie_werkbestand.pwb_bijstell_vv%type;
  v_bijstellingsbedrag_rapv     positie_werkbestand.pwb_bijstell_rapv%type;
  v_waarborgsom                 positie_werkbestand.pwb_init_margin_vv%type;
  v_ow_bied_koers               fn_quotes_vw.quot_bied%type;
  v_ow_laat_koers               fn_quotes_vw.quot_laat%type;
  v_margin                      positie_werkbestand.pwb_init_margin_vv%type;
  v_margin_factor               beleggingsinstrument.be_margin_factor%type;
  v_margin_opslag               beleggingsinstrument.be_margin_opslag%type;
  v_ref_symb_volgnummer         beleggingsinstrument.be_volgnummer%type;
  v_ow_is_mandje                number(1);
  v_port_werk_aantal            positie_werkbestand.pwb_werk_aantal_port%type;
  v_margin_werk_aantal          positie_werkbestand.pwb_werk_aantal_marg%type;
  v_aantal_voor_order           positie_werkbestand.pwb_effect_lop_ord%type;
  v_gebr_dekk_percentage        number(6,3);
  v_oorspr_dekk_waarde_rapv     positie_werkbestand.pwb_dekk_waarde_rapv%type;
  v_oorspr_dekk_waarde_vv_sl    positie_werkbestand.pwb_oorsp_dekk_waarde_vv_sl%type;
  v_valuta_biedkoers            muntsoorten.mu_biedkoers%type;
  v_valuta_laatkoers            muntsoorten.mu_laatkoers%type;
  v_valuta_factor               muntsoorten.mu_factor%type;
  v_valuta_reciproke            muntsoorten.mu_reciproke%type;
  v_valuta_notatie              muntsoorten.mu_notatie%type;
  v_dummy_waarde                muntsoorten.mu_middenkoers%type;

cursor pw is
         select p.pwb_symbool,          p.pwb_optietype,        p.pwb_expiratiedatum,
                p.pwb_exerciseprijs,    p.pwb_saldo_positie,    p.pwb_trans_mut,
                p.pwb_lopende_ord_aant, p.pwb_sld_losbaar,      p.pwb_hist_wrd_totbe,
                p.pwb_saldo_totaall_s,  p.pwb_rekening_soort,   p.pwb_rekening_nummer,
                p.pwb_trans_aanwezig,   pwb_effect_lop_ord,
                b.be_bi_nummer,         b.be_muntsoort,         b.be_prijs_factor,
                b.be_oms_1,             b.be_referentiesymbool, b.be_nominaal,
                b.be_pricing_unit,
                w.wg_interne_perc,      w.wg_intern_short_perc
         from   positie_werkbestand p, beleggingsinstrument b, wegingsfactoren w
         where  p.pwb_relatie_nummer = i_relatienummer
         and    p.pwb_symbool        = b.be_symbool        (+)
         and    p.pwb_optietype      = b.be_optietype      (+)
         and    p.pwb_expiratiedatum = b.be_expiratiedatum (+)
         and    p.pwb_exerciseprijs  = b.be_exerciseprijs  (+)
         and    b.be_wg_factor       = w.wg_nummer         (+);

begin
if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug (gv_debug_user,to_char(i_relatienummer)||' '||to_char(i_terminalnr));
       FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
    end if;


     o_optie_fut_in_positie := 0;

     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'In procedure FIAT_VERZAMEL.positie_berekening');
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'parameter o_optie_fut_in_positie : '||to_char(o_optie_fut_in_positie));
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
     end if;

     for r_pw in pw
     loop
         -- Resetten van de gebruikte hulpvariabelen
         v_fonds_bied_koers            := 0;
         v_fonds_laat_koers            := 0;
         v_fonds_werk_koers            := 0;
         v_fonds_werk_koers_munt       := 0;
         v_relatie_werk_koers_munt     := 0;
         v_rente_factor                := 0;
         v_lopende_rente               := 0;
         v_portefeuille_waarde         := 0;
         v_portefeuille_waarde_rapv    := 0;
         v_dekkingswaarde_rapv         := 0;
         v_dekkingswaarde_vv_sl        := 0;
         v_fonds_afloskoers            := 0;
         v_dekkingspercentage          := 0;
         v_bijstellingskoers           := 0;
         v_bijstellingsbedrag          := 0;
         v_bijstellingsbedrag_rapv     := 0;
         v_waarborgsom                 := 0;
         v_ow_bied_koers               := 0;
         v_ow_laat_koers               := 0;
         v_margin                      := 0;
         v_margin_factor               := 0;
         v_margin_opslag               := 0;
         v_ref_symb_volgnummer         := 0;
         v_gebr_dekk_percentage        := 0;
         v_oorspr_dekk_waarde_rapv     := 0;
         v_oorspr_dekk_waarde_vv_sl    := 0;

         -- vaststellen van de werk aantallen:
         v_port_werk_aantal   := r_pw.pwb_saldo_positie + r_pw.pwb_trans_mut + r_pw.pwb_lopende_ord_aant;
         v_margin_werk_aantal := v_port_werk_aantal;
         v_aantal_voor_order  := r_pw.pwb_effect_lop_ord + r_pw.pwb_trans_mut + r_pw.pwb_lopende_ord_aant;

         -- bepalen van de koersen van het fonds via de procedure fondskoersen:
         FIAT_ALGEMEEN.fondskoersen (r_pw.pwb_symbool, r_pw.pwb_optietype, r_pw.pwb_expiratiedatum, r_pw.pwb_exerciseprijs,
                                     i_slot_of_laatste_koers, v_fonds_bied_koers, v_fonds_laat_koers);

         -- bepalen van de valutakoersen en andere valutagegevens:
         FIAT_ALGEMEEN.valutagegevens_bepalen (r_pw.be_muntsoort,       gv_relatie_pr_id,   gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                               gv_bank2mrktqchangedate, gv_debuggen,        gv_debug_user,     v_valuta_biedkoers,
                                               v_dummy_waarde,          v_valuta_laatkoers, v_valuta_factor,   v_valuta_reciproke,
                                               v_valuta_notatie);

         -- werkkoers is afhankelijk van de saldopositie:
         if v_port_werk_aantal > 0
         then
            v_fonds_werk_koers := v_fonds_bied_koers;
         else
            v_fonds_werk_koers := v_fonds_laat_koers;
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Onderhanden zijnd fonds:');
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'symbool          : '||r_pw.pwb_symbool||
                                                     ' ; optietype : '||r_pw.pwb_optietype);
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'expiratie datum  : '||r_pw.pwb_expiratiedatum||
                                                     ' ; exerciseprijs : '||to_char(r_pw.pwb_exerciseprijs));
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'port werk aantal : '||to_char(v_port_werk_aantal)||
                                                     ' ; margin werk aantal : '||to_char(v_margin_werk_aantal));
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'fonds bied koers : '||to_char(v_fonds_bied_koers)||
                                                     ' ; fonds laat koers : '||to_char(v_fonds_laat_koers));
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'fonds werk koers : '||to_char(v_fonds_werk_koers));
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'wegingsfactor short : '||to_char(r_pw.wg_intern_short_perc)||
                                                     ' ; wegingsfactor long : '||to_char(r_pw.wg_interne_perc));
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'prijs factor     : '||to_char(r_pw.be_prijs_factor)||
                                                     ' ; muntsoort fonds : '||r_pw.be_muntsoort);
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'munt bied koers  : '||to_char(v_valuta_biedkoers)||
                                                     '  munt laat koers : '||to_char(v_valuta_laatkoers));
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'munt notatie     : '||to_char(v_valuta_notatie)||
                                                     ' ; munt factor   : '||to_char(v_valuta_factor));
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'munt reciproke   : '||to_char(v_valuta_reciproke)||
                                                     ' fonds omschr 1  : '||r_pw.be_oms_1);
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
         end if;

         -- lopende rente bepalen van de positie, hoeft alleen als het een obligatie is:
         if r_pw.be_bi_nummer between 200 and 299
         then
             select FIAT_ALGEMEEN.rente_factor_berek(r_pw.pwb_symbool, to_char(SYSDATE,'yyyymmdd'),gv_debuggen,gv_debug_user)
             into v_rente_factor
             from dual;

             v_rente_factor := round(v_rente_factor,9);

             v_lopende_rente := v_port_werk_aantal * r_pw.be_prijs_factor * nvl(v_rente_factor,0);
             v_lopende_rente := round (v_lopende_rente,v_valuta_notatie);

             if gv_debuggen = 1
             then
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Bepaling rente');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'rente factor : '||to_char(v_rente_factor)||' ; reken aantal : '||to_char(v_port_werk_aantal));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'prijs factor : '||to_char(r_pw.be_prijs_factor)||' ; lopende rente : '||to_char(v_lopende_rente));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
             end if;
         end if;

         -- afloskoers bepalen onder conditie:
         if r_pw.be_prijs_factor <> 0 and r_pw.pwb_sld_losbaar <> 0
         then
             select FIAT_ALGEMEEN.aflossingskoers(r_pw.pwb_symbool, to_char(SYSDATE,'yyyymmdd'))
             into   v_fonds_afloskoers
             from   dual;
         end if;

         if (v_fonds_afloskoers is null or v_fonds_afloskoers = 0)
         then
             v_fonds_afloskoers := v_fonds_werk_koers;
         end if;

         -- effectief bedrag:
         v_portefeuille_waarde := v_port_werk_aantal * r_pw.be_prijs_factor * v_fonds_werk_koers;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'effectief bedrag (vv) : '||to_char(v_portefeuille_waarde));
         end if;

         -- aflossingswaarde erbij op tellen
         v_portefeuille_waarde := v_portefeuille_waarde + (r_pw.pwb_sld_losbaar *
                                  r_pw.be_prijs_factor * (v_fonds_afloskoers - v_fonds_werk_koers));

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'effectief bedrag + afloswaarde (vv) : '||to_char(v_portefeuille_waarde));
         end if;

         -- lopende rente erbij op tellen
         v_portefeuille_waarde := v_portefeuille_waarde + v_lopende_rente;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'effectief bedrag + lopende rente(vv) : '||to_char(v_portefeuille_waarde));
         end if;

         -- correctie voor historische futurewaarde
         if r_pw.be_bi_nummer between 2900 and 2999 and r_pw.pwb_saldo_totaall_s<>0 and r_pw.pwb_hist_wrd_totbe <> 0
         then
            v_portefeuille_waarde := v_portefeuille_waarde - r_pw.pwb_hist_wrd_totbe/r_pw.pwb_saldo_totaall_s * v_port_werk_aantal;

            if gv_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
               FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Herbereken voor futures, portefeuille waarde : '||to_char(v_portefeuille_waarde));
               FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Hist wrd totbe : '||to_char(r_pw.pwb_hist_wrd_totbe)||' ; saldo totaal ls : '||to_char(r_pw.pwb_saldo_totaall_s));
               FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
            end if;
         end if;

         -- Voor het bepalen van de muntkoers gegevens in geval van futures
         if r_pw.be_bi_nummer between 2900 and 2999
         then
            if r_pw.pwb_saldo_totaall_s <> 0 and
               (v_fonds_werk_koers - r_pw.pwb_hist_wrd_totbe/r_pw.pwb_saldo_totaall_s/r_pw.be_prijs_factor > 0 and v_port_werk_aantal > 0
                or
                v_fonds_werk_koers - r_pw.pwb_hist_wrd_totbe/r_pw.pwb_saldo_totaall_s/r_pw.be_prijs_factor < 0 and v_port_werk_aantal < 0)
            then
               v_fonds_werk_koers_munt   := v_valuta_laatkoers;
               v_relatie_werk_koers_munt := gv_rel_rapp_biedkoers;
            else
               v_fonds_werk_koers_munt   := v_valuta_biedkoers;
               v_relatie_werk_koers_munt := gv_rel_rapp_laatkoers;
            end if;
         -- voor bepalen van de valutakoersen in geval van niet-futures
         else
            if v_port_werk_aantal>0
            then
               v_fonds_werk_koers_munt   := v_valuta_laatkoers;
               v_relatie_werk_koers_munt := gv_rel_rapp_biedkoers;
            else
               v_fonds_werk_koers_munt   := v_valuta_biedkoers;
               v_relatie_werk_koers_munt := gv_rel_rapp_laatkoers;
            end if;
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'fonds werk koers munt : '||to_char(v_fonds_werk_koers_munt)||
                                                     ' ; relatie werk koers munt : '||to_char(v_relatie_werk_koers_munt));
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
         end if;

         -- omrekenen van de portefeuillewaarde naar de gewenste valuta:
         if gv_rel_rapp_valuta <> r_pw.be_muntsoort
         then
            select FIAT_ALGEMEEN.omrekenen_bedrag_vv(v_portefeuille_waarde, v_valuta_reciproke, v_valuta_factor,
                                                     v_fonds_werk_koers_munt, v_fonds_werk_koers_munt, gv_rel_rapp_reciproke ,
                                                     gv_rel_rapp_factor, v_relatie_werk_koers_munt, v_relatie_werk_koers_munt,
                                                     gv_rel_rapp_notatie)
            into   v_portefeuille_waarde_rapv
            from dual;
         else
            v_portefeuille_waarde_rapv := v_portefeuille_waarde;
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'portefeuille waarde in rapv : '||to_char(v_portefeuille_waarde_rapv));
            FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
         end if;
         
         -- als het berekenen van de dekkingswaarde moet worden onderdrukken, dan geldt dat alleen voor fondsen in VV
         if gv_suppressFCDekkwaarde = 0 
            or 
            gv_suppressFCDekkwaarde = 1 and r_pw.be_muntsoort = gv_basismuntsoort
         then
            -- met behulp van de berekende portefeuillewaarde in rapv wordt eerst de oorspronkelijke dekkingswaarde
            -- met de bij het fonds vastgelegde wegingsfactor berekend ten behoeve van de effectenkrediet service:
            if v_portefeuille_waarde_rapv > 0 and r_pw.wg_interne_perc <> 0 and r_pw.wg_interne_perc is not null
            then
               v_gebr_dekk_percentage     := r_pw.wg_interne_perc;
               v_oorspr_dekk_waarde_rapv  := v_portefeuille_waarde_rapv * r_pw.wg_interne_perc/100;
               v_oorspr_dekk_waarde_vv_sl := v_portefeuille_waarde * r_pw.wg_interne_perc/100;
            end if;
            
            if v_portefeuille_waarde_rapv < 0 and r_pw.wg_intern_short_perc<>0 and r_pw.wg_intern_short_perc is not null
            then
               v_gebr_dekk_percentage     := r_pw.wg_intern_short_perc;
               v_oorspr_dekk_waarde_rapv  := v_portefeuille_waarde_rapv * r_pw.wg_intern_short_perc/100;
               v_oorspr_dekk_waarde_vv_sl := v_portefeuille_waarde * r_pw.wg_intern_short_perc/100;
            end if;
            v_oorspr_dekk_waarde_rapv  := round(v_oorspr_dekk_waarde_rapv,gv_rel_rapp_notatie);
            v_oorspr_dekk_waarde_vv_sl := round(v_oorspr_dekk_waarde_vv_sl,v_valuta_notatie);
            
            -- met behulp van de berekende portefeuillewaarde in rapv wordt de dekkingswaarde bepaalt:
            if v_portefeuille_waarde_rapv > 0 and r_pw.wg_interne_perc <> 0 and r_pw.wg_interne_perc is not null
            then
               if rtrim(gv_onld_omschrijving) = 'P'
               then
                  v_dekkingspercentage := gv_onld_percentage/100;
               else
                  v_dekkingspercentage := r_pw.wg_interne_perc/100;
               end if;
               
               v_dekkingswaarde_rapv  := v_portefeuille_waarde_rapv * v_dekkingspercentage;
               v_dekkingswaarde_vv_sl := v_portefeuille_waarde * v_dekkingspercentage;
               
               if gv_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'dekkingspercentage : '||to_char(v_dekkingspercentage)||
                                                           ' ; dekkingswaarde rapv : '||to_char(v_dekkingswaarde_rapv));
                  FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'dekkingswaarde vv sl : '||to_char(v_dekkingswaarde_vv_sl));
               end if;
               
               if rtrim(gv_onld_omschrijving) = 'D' or rtrim(gv_onld_omschrijving) = 'L'
               then
                  v_dekkingswaarde_rapv  := v_dekkingswaarde_rapv * gv_onld_percentage/100;
                  v_dekkingswaarde_vv_sl := v_dekkingswaarde_vv_sl * gv_onld_percentage/100;
               end if;
               
               if gv_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'onld percentage : '||to_char(gv_onld_percentage)||
                                                           ' ; dekkingswaarde rapv : '||to_char(v_dekkingswaarde_rapv));
                  FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'dekkingswaarde vv sl : '||to_char(v_dekkingswaarde_vv_sl));
                  FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
               end if;
            end if;
            
            if v_portefeuille_waarde_rapv < 0 and r_pw.wg_intern_short_perc<>0 and r_pw.wg_intern_short_perc is not null
            then
               if rtrim(gv_onld_omschrijving) = 'P'
               then
                  v_dekkingspercentage := (200 - gv_onld_percentage)/100;
               else
                  v_dekkingspercentage := r_pw.wg_intern_short_perc/100;
               end if;
               
               v_dekkingswaarde_rapv  := v_portefeuille_waarde_rapv * v_dekkingspercentage;
               v_dekkingswaarde_vv_sl := v_portefeuille_waarde * v_dekkingspercentage;
               
               if rtrim(gv_onld_omschrijving) = 'D' or rtrim(gv_onld_omschrijving) = 'L'
               then
                  v_dekkingswaarde_rapv  := v_dekkingswaarde_rapv * (200 - gv_onld_percentage)/100;
                  v_dekkingswaarde_vv_sl := v_dekkingswaarde_vv_sl * (200 - gv_onld_percentage)/100;
               end if;
            end if;
            v_dekkingswaarde_rapv  := round(v_dekkingswaarde_rapv,gv_rel_rapp_notatie);
            v_dekkingswaarde_vv_sl := round(v_dekkingswaarde_vv_sl,v_valuta_notatie);
            
            if v_portefeuille_waarde_rapv = 0
            then
               v_dekkingswaarde_rapv  := 0;
               v_dekkingswaarde_vv_sl := 0;
            end if;
         end if;
         -- Bepalen van de bijstellingswaarde op dit moment voor futures:
         if r_pw.pwb_optietype = 'FUT' and r_pw.pwb_saldo_totaall_s <> 0
         then
            v_bijstellingskoers  := r_pw.pwb_hist_wrd_totbe / r_pw.pwb_saldo_totaall_s / r_pw.be_prijs_factor;
            -- nb hier niet reken_aantal, maar saldo_positie, omdat hiermee de hist_wrd_totbe is berekend en niet met
            -- de werk aantalen!
            v_bijstellingsbedrag := (v_fonds_werk_koers - v_bijstellingskoers) * r_pw.pwb_saldo_positie * r_pw.be_prijs_factor;

            if r_pw.be_muntsoort <> gv_rel_rapp_valuta
            then
               select FIAT_ALGEMEEN.omrekenen_bedrag_vv(v_bijstellingsbedrag, v_valuta_reciproke, v_valuta_factor,
                                                       v_fonds_werk_koers_munt, v_fonds_werk_koers_munt, gv_rel_rapp_reciproke ,
                                                       gv_rel_rapp_factor, v_relatie_werk_koers_munt, v_relatie_werk_koers_munt,
                                                       gv_rel_rapp_notatie)
               into   v_bijstellingsbedrag_rapv
               from   dual;
            else
               v_bijstellingsbedrag_rapv := v_bijstellingsbedrag;
            end if;

            -- v_bijstellingsbedrag wegschrijven in het werkbestand voor later tonen, alleen indien gewenst.
            if gv_detail_geg_aanmaken = 1
            then

               update werkbestand
               set    wk_waarde_1    = wk_waarde_1 + v_bijstellingsbedrag_rapv,
                      wk_waarde_2    = v_fonds_werk_koers,
                      wk_waarde_3    = v_bijstellingskoers,
                      wk_waarde_4    = wk_waarde_4 + r_pw.pwb_saldo_positie
               where  wk_terminal    = i_terminalnr
               and    wk_soort       = 'BIJS'
               and    wk_categorie_1 = substr(r_pw.be_oms_1,1,28)
               and    wk_categorie_2 = r_pw.pwb_optietype
               and    wk_categorie_3 = r_pw.pwb_expiratiedatum
               and    wk_categorie_4 = case when length(r_pw.be_oms_1)<= 28 then ' ' else substr(r_pw.be_oms_1,29,12) end
               and    wk_datum_1     = '00000000';

               if sql%notfound
               then
                  insert into werkbestand
                  (wk_terminal,         wk_soort,                  wk_categorie_1,
                   wk_categorie_2,      wk_categorie_3,            wk_categorie_4,
                   wk_datum_1,          wk_waarde_1,               wk_waarde_2,
                   wk_waarde_3,         wk_waarde_4)
                  values
                  (i_terminalnr,        'BIJS',                    substr(r_pw.be_oms_1,1,28),
                   r_pw.pwb_optietype,  r_pw.pwb_expiratiedatum,   case when length(r_pw.be_oms_1)<= 28 then ' ' else substr(r_pw.be_oms_1,29,12) end,
                   '00000000',          v_bijstellingsbedrag_rapv, v_fonds_werk_koers,
                   v_bijstellingskoers, r_pw.pwb_saldo_positie);
               end if;

            end if;
         end if;
         -- Voor futures nog de v_waarborgsom berekenen
         if r_pw.pwb_optietype = 'FUT'
         then
            v_waarborgsom := ABS(v_port_werk_aantal) * r_pw.be_nominaal;
         end if;

         -- Bepalen van de bruto v_margin voor short opties:
         if r_pw.pwb_optietype in ('CALL','PUT') and v_margin_werk_aantal < 0
         then
            -- stap 1 ophalen van de gegevens bij de onderliggende waarde:
            -- melding 5340-36878 toevoegen van de margin_opslag ipv instelling naked_margin_toeslag.
            begin
               select b.be_margin_factor, b.be_margin_opslag, b.be_volgnummer
               into   v_margin_factor,    v_margin_opslag,    v_ref_symb_volgnummer
               from   beleggingsinstrument b
               where  b.be_symbool        = r_pw.be_referentiesymbool
               and    b.be_optietype      = ' '
               and    b.be_expiratiedatum = '00000000'
               and    b.be_exerciseprijs  = 0;

            exception
               when no_data_found
               then
                  v_margin_factor       := 0;
                  v_margin_opslag       := 0;
                  v_ref_symb_volgnummer := 0;
            end;

            -- Stap 1a. Bekijken of de onderliggende waarde een mandje is
            begin
               select 1
               into   v_ow_is_mandje
               from   mandje_onderliggende_waarde m
               where  m.mnd_volgnummer = v_ref_symb_volgnummer
               and    rownum           <= 1;                   -- 1 record ophalen is al genoeg

            exception
               when no_data_found
               then
                  v_ow_is_mandje := 0;
            end;

            -- stap 2 ophalen van de koers van de onderliggende waarde:
            if v_ow_is_mandje = 1
            then
               FIAT_ALGEMEEN.fondskoers_meerdere_ow (v_ref_symb_volgnummer, r_pw.be_prijs_factor, i_slot_of_laatste_koers, gv_debuggen,
                                                     gv_debug_user, v_ow_bied_koers, v_ow_laat_koers);
            else
               FIAT_ALGEMEEN.fondskoersen (r_pw.be_referentiesymbool,' ', '00000000',0,i_slot_of_laatste_koers,
                                           v_ow_bied_koers,v_ow_laat_koers);
            end if;

            -- stap 3 berekenen van de v_margin:
            FIAT_ALGEMEEN.initial_margin (r_pw.pwb_optietype, r_pw.pwb_exerciseprijs, r_pw.be_pricing_unit, r_pw.be_prijs_factor,
                                          v_fonds_laat_koers, v_margin_factor, v_margin_opslag, v_ow_bied_koers, v_margin_werk_aantal,
                                          i_sys_toeslag_optiemarg, i_rel_toeslag_optiemarg, i_methode_naked_margin, i_factor_naked_margin,
                                          i_pr_blokkeren_short_call, i_pr_blokkeren_short_put, gv_debuggen, gv_debug_user, v_margin);

            if gv_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'in procedure FIAT_VERZAMEL.positie_berekening, na initial v_margin berekening');
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'symbool           : '||r_pw.pwb_symbool||' ; optietype : '||r_pw.pwb_optietype);
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'exp datum         : '||r_pw.pwb_expiratiedatum||' ; exerciseprijs : '||to_char(r_pw.pwb_exerciseprijs));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'referentiesymbool : '||r_pw.be_referentiesymbool||' ; margin factor : '||to_char(v_margin_factor));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'berekende margin  : '||to_char(v_margin));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
            end if;
         end if;

         -- het positie_werkbestand bijwerken met de berekende gegevens:
         -- nb omdat hier het werkbestand als dataleverancier optreedt hoeft niet gecheckt te worden of het record
         -- bestaat --> het bestaat anders was immers niets te berekenen geweest
         update positie_werkbestand
         set    pwb_bi_type                 = r_pw.be_bi_nummer,
                pwb_biedk_symbool           = v_fonds_bied_koers,
                pwb_laatk_symbool           = v_fonds_laat_koers,
                pwb_prijs_factor            = r_pw.be_prijs_factor,
                pwb_ref_symbool             = r_pw.be_referentiesymbool,
                pwb_fonds_valuta            = r_pw.be_muntsoort,
                pwb_pricing_unit            = r_pw.be_pricing_unit,
                pwb_margin_factor           = v_margin_factor,
                pwb_biedk_refsymb           = v_ow_bied_koers,
                pwb_werk_aantal_port        = v_port_werk_aantal,
                pwb_werk_aantal_marg        = v_margin_werk_aantal,
                pwb_effect_lop_ord          = v_aantal_voor_order,
                pwb_port_waarde_vv          = v_portefeuille_waarde,
                pwb_init_margin_vv          = v_margin,
                pwb_lopende_rente_vv        = v_lopende_rente,
                pwb_bijstell_vv             = v_bijstellingsbedrag,
                pwb_waarborgsom_vv          = v_waarborgsom,
                pwb_port_waarde_rapv        = v_portefeuille_waarde_rapv,
                pwb_dekk_waarde_rapv        = v_dekkingswaarde_rapv,
                pwb_bijstell_rapv           = v_bijstellingsbedrag_rapv,
                pwb_gebr_dekk_percentage    = v_gebr_dekk_percentage,
                pwb_oorspr_dekk_waarde_rapv = v_oorspr_dekk_waarde_rapv,
                pwb_dekk_waarde_vv_sl       = v_dekkingswaarde_vv_sl,
                pwb_oorsp_dekk_waarde_vv_sl = v_oorspr_dekk_waarde_vv_sl
         where  pwb_relatie_nummer          = i_relatienummer
         and    pwb_rekening_nummer         = r_pw.pwb_rekening_nummer
         and    pwb_rekening_soort          = r_pw.pwb_rekening_soort
         and    pwb_symbool                 = r_pw.pwb_symbool
         and    pwb_optietype               = r_pw.pwb_optietype
         and    pwb_expiratiedatum          = r_pw.pwb_expiratiedatum
         and    pwb_exerciseprijs           = r_pw.pwb_exerciseprijs;


         -- Economische positie op dit moment aanmaken, alle gegevens zijn nu immers berekend:
         -- proberen te updaten van het werkbestand als het record al bestaat
         update positie_werkbestand p
         set    p.pwb_werk_aantal_port        = p.pwb_werk_aantal_port + v_port_werk_aantal,
                p.pwb_lopende_ord_aant        = p.pwb_lopende_ord_aant + r_pw.pwb_lopende_ord_aant,
                p.pwb_werk_aantal_marg        = p.pwb_werk_aantal_marg + v_margin_werk_aantal,
                p.pwb_port_waarde_vv          = p.pwb_port_waarde_vv + v_portefeuille_waarde,
                p.pwb_port_waarde_rapv        = p.pwb_port_waarde_rapv + v_portefeuille_waarde_rapv,
                p.pwb_dekk_waarde_rapv        = p.pwb_dekk_waarde_rapv + v_dekkingswaarde_rapv,
                p.pwb_lopende_rente_vv        = p.pwb_lopende_rente_vv + v_lopende_rente,
                p.pwb_bi_type                 = r_pw.be_bi_nummer,
                p.pwb_trans_aanwezig          = p.pwb_trans_aanwezig + r_pw.pwb_trans_aanwezig,
                p.pwb_effect_lop_ord          = pwb_effect_lop_ord + v_aantal_voor_order,
                p.pwb_gebr_dekk_percentage    = v_gebr_dekk_percentage,
                p.pwb_oorspr_dekk_waarde_rapv = pwb_oorspr_dekk_waarde_rapv + v_oorspr_dekk_waarde_rapv,
                p.pwb_dekk_waarde_vv_sl       = p.pwb_dekk_waarde_vv_sl + v_dekkingswaarde_vv_sl,
                p.pwb_oorsp_dekk_waarde_vv_sl = p.pwb_oorsp_dekk_waarde_vv_sl + v_oorspr_dekk_waarde_vv_sl
         where  p.pwb_relatie_nummer          = i_relatienummer
         and    p.pwb_rekening_nummer         = ' '
         and    p.pwb_rekening_soort          = 0
         and    p.pwb_symbool                 = r_pw.pwb_symbool
         and    p.pwb_optietype               = r_pw.pwb_optietype
         and    p.pwb_expiratiedatum          = r_pw.pwb_expiratiedatum
         and    p.pwb_exerciseprijs           = r_pw.pwb_exerciseprijs;

         -- als dit niet lukt, dan het record inserten in het werkbestand:
         if sql%notfound
         then
            insert into positie_werkbestand
            (pwb_relatie_nummer,        pwb_rekening_nummer,        pwb_rekening_soort,
             pwb_symbool,               pwb_optietype,              pwb_expiratiedatum,
             pwb_exerciseprijs,         pwb_werk_aantal_port,       pwb_werk_aantal_marg,
             pwb_port_waarde_vv,        pwb_port_waarde_rapv,       pwb_dekk_waarde_rapv,
             pwb_lopende_rente_vv,      pwb_bi_type,                pwb_trans_aanwezig,
             pwb_lopende_ord_aant,      pwb_gebr_dekk_percentage,   pwb_oorspr_dekk_waarde_rapv,
             pwb_fonds_valuta,          pwb_dekk_waarde_vv_sl,      pwb_oorsp_dekk_waarde_vv_sl)
            values
            (i_relatienummer,           ' ',                        0,
             r_pw.pwb_symbool,          r_pw.pwb_optietype,         r_pw.pwb_expiratiedatum,
             r_pw.pwb_exerciseprijs,    v_port_werk_aantal,         v_margin_werk_aantal,
             v_portefeuille_waarde,     v_portefeuille_waarde_rapv, v_dekkingswaarde_rapv,
             v_lopende_rente,           r_pw.be_bi_nummer,          r_pw.pwb_trans_aanwezig,
             r_pw.pwb_lopende_ord_aant, v_gebr_dekk_percentage,     v_oorspr_dekk_waarde_rapv,
             r_pw.be_muntsoort,         v_dekkingswaarde_vv_sl,     v_oorspr_dekk_waarde_vv_sl);
         end if;

         -- als laatste nog vast leggen of de positie een optie of future positie betreft
         if o_optie_fut_in_positie = 0
            and
            (r_pw.pwb_optietype = 'CALL' or r_pw.pwb_optietype = 'PUT' or r_pw.pwb_optietype = 'FUT')
         then
            o_optie_fut_in_positie := 1;
         end if;

     end loop;

     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Einde berekeningen positie');
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
     end if;


end positie_berekening;
-- EINDE CODE VAN DE PROCEDURE POSITIE_BEREKEING


-- DE CODE VOOR DE PROCEDURE SPREIDINGEIS_AANPASSING
procedure spreidingeis_aanpassing
(i_relatienr                in  clienten.cl_nummer%type
,o_extra_spr_port_waarde    out positie_werkbestand.pwb_port_waarde_rapv%type
,o_extra_spr_port_waarde_vv out positie_werkbestand.pwb_port_waarde_vv%type
)

is

  v_totale_port_waarde_bv   positie_werkbestand.pwb_port_waarde_rapv%type;
  v_totale_port_waarde_vv   positie_werkbestand.pwb_port_waarde_vv%type;

begin
  -- Als eerste eenmalig de totale portefeuillewaarde bepalen
  select sum(p.pwb_port_waarde_rapv), sum(p.pwb_port_waarde_vv)
  into   v_totale_port_waarde_bv,     v_totale_port_waarde_vv
  from   positie_werkbestand p
  where  p.pwb_relatie_nummer   = i_relatienr
  and    p.pwb_rekening_soort   between 1 and 999
  and    p.pwb_dekk_waarde_rapv > 0;  -- Alleen fondsen met een positieve dekkingswaarde meetellen !!!

  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Begin spreidingseis aanpassing');
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'totale waarde port van dekk.fondsen: '||to_char(v_totale_port_waarde_bv));
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'totale waarde port van dekk.fondsen vv : '||to_char(v_totale_port_waarde_vv));
  end if;

  -- Nu dit bekend is kan een selectie van de portefeuille regels die voor meer dan
  -- 25% van de totale portefeuillewaarde uitmaken plaats vinden.
  -- Let op dit mag alleen bij portefeuillewaarden die positief zijn!!
  if v_totale_port_waarde_bv > 0
  then
     declare

       v_nieuwe_dekkingswaarde               positie_werkbestand.pwb_dekk_waarde_rapv%type;
       v_nieuwe_dekk_waarde_vv_sl            positie_werkbestand.pwb_dekk_waarde_vv_sl%type;
       v_wegingsfactor_tabel                 beleggingsinstrument.be_wg_factor%type;
       v_wegingsfactor_perc                  wegingsfactoren.wg_interne_perc%type;
       v_positie_portef_perc                 wegingsfactoren.wg_interne_perc%type;


       cursor pd is
           select p.pwb_symbool,           p.pwb_optietype,          p.pwb_expiratiedatum,
                  p.pwb_exerciseprijs,     p.pwb_port_waarde_rapv,   p.pwb_dekk_waarde_rapv,
                  t.bt_grens_waarde,       t.bt_extra_wegingsfactor, p.pwb_port_waarde_vv,
                  p.pwb_dekk_waarde_vv_sl, p.rowid
           from   positie_werkbestand p, type_belegg_instr t
           where  p.pwb_relatie_nummer   = i_relatienr
           and    p.pwb_dekk_waarde_rapv > 0                               -- Ook hier weer aangeven dat alleen positieve dekkingswaarde
           and    p.pwb_port_waarde_rapv >= t.bt_grens_waarde/100 * v_totale_port_waarde_bv  -- de portefeuillewaarde moet gelijk of
           and    p.pwb_rekening_soort   between 1 and 999                  -- meer dan grenswaarde van het totaal zijn
           and    p.pwb_bi_type          = t.bt_type
           and    t.bt_effecten_krediet  = 1;                               -- Alleen de typen waarvoor is aangegeven
                                                                            -- dat extra spredingeisen gelden
     begin
       for r_pd in pd
       loop
          -- reset van de waardes
          v_nieuwe_dekkingswaarde    := 0;
          v_nieuwe_dekk_waarde_vv_sl := 0;
          v_wegingsfactor_tabel      := 0;
          v_wegingsfactor_perc       := 0;
          -- Hoeveel procent is de waarde van het fonds van de hele portefeuille:
		      -- Een overflow dreigt bij een kleine totale portefeuille waarde ten op zichte van een grote  regelwaarde
		      if (r_pd.pwb_port_waarde_rapv/v_totale_port_waarde_bv) * 100 > 100 -- Als het percentage groter dan 100 is dan wordt
          then                                                               -- geld gegeneerd. Dat mag niet.....
			       v_positie_portef_perc   := 100;
	        elsif (r_pd.pwb_port_waarde_rapv/v_totale_port_waarde_bv) *100 < -999.999
          then
			       v_positie_portef_perc   := -999.999;
		      else
			       v_positie_portef_perc   := round((r_pd.pwb_port_waarde_rapv/v_totale_port_waarde_bv)*100,3);
    		  end if;

          select b.be_wg_factor
          into   v_wegingsfactor_tabel
          from   beleggingsinstrument b
          where  b.be_symbool        = r_pd.pwb_symbool
          and    b.be_optietype      = r_pd.pwb_optietype
          and    b.be_expiratiedatum = r_pd.pwb_expiratiedatum
          and    b.be_exerciseprijs  = r_pd.pwb_exerciseprijs;

          select w.wg_interne_perc
          into   v_wegingsfactor_perc
          from   wegingsfactoren w
          where  w.wg_nummer     = v_wegingsfactor_tabel;

          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'fondssymbool : '||r_pd.pwb_symbool||' ; optietype :'||r_pd.pwb_optietype);
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'expiratiedatum : '|| to_char(r_pd.pwb_expiratiedatum)||
                                                      ' ; exerciseprijs : '||to_char(r_pd.pwb_exerciseprijs));
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'grenswaarde : '||to_char(r_pd.bt_grens_waarde)||
                                                      ' ; extra wegingsfactor : '||to_char(r_pd.bt_extra_wegingsfactor));
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'wegingsfac. tabel : '||to_char(v_wegingsfactor_tabel)||
                                                      ' ; interne wegingsfac : '||to_char(v_wegingsfactor_perc));
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'portwaarde pos : '||to_char(r_pd.pwb_port_waarde_rapv)||
                                                      ' ; dekk waarde pos : '||to_char(r_pd.pwb_dekk_waarde_rapv));
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'positie perc van portefeuille : '||to_char(v_positie_portef_perc));
          end if;

          -- Als er een percentage is bepaald dan verder gaan
          if v_wegingsfactor_perc <> 0
          then
             -- bereken van de nieuwe dekkingswaarde
             v_nieuwe_dekkingswaarde    := (r_pd.bt_grens_waarde/v_positie_portef_perc * v_wegingsfactor_perc/100 * r_pd.pwb_port_waarde_rapv) +
                                           ((v_positie_portef_perc - r_pd.bt_grens_waarde)/v_positie_portef_perc * r_pd.bt_extra_wegingsfactor/100 *
                                            v_wegingsfactor_perc/100 * r_pd.pwb_port_waarde_rapv);

             v_nieuwe_dekk_waarde_vv_sl := (r_pd.bt_grens_waarde/v_positie_portef_perc * v_wegingsfactor_perc/100 * r_pd.pwb_port_waarde_vv) +
                                           ((v_positie_portef_perc - r_pd.bt_grens_waarde)/v_positie_portef_perc * r_pd.bt_extra_wegingsfactor/100 *
                                            v_wegingsfactor_perc/100 * r_pd.pwb_port_waarde_vv);


             if gv_debuggen = 1
             then
                FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'nieuwe dekkingswaarde : '||to_char(v_nieuwe_dekkingswaarde));
                FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'nieuwe dekkingswaarde vv : '||to_char(v_nieuwe_dekk_waarde_vv_sl));
             end if;

             v_nieuwe_dekkingswaarde    := round(v_nieuwe_dekkingswaarde,gv_rel_rapp_notatie);
             v_nieuwe_dekk_waarde_vv_sl := round(v_nieuwe_dekk_waarde_vv_sl,gv_rel_rapp_notatie);

             if gv_debuggen = 1
             then
                FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'nieuwe dekkingswaarde afgerond : '||to_char(v_nieuwe_dekkingswaarde));
                FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'nieuwe dekk.waarde vv afgerond : '||to_char(v_nieuwe_dekk_waarde_vv_sl));
                FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
             end if;


             -- als de nieuw berekende dekkingswaarde afwijkt van de oude waarde dan de nieuwe waarde wegschrijven
             if v_nieuwe_dekkingswaarde <> r_pd.pwb_dekk_waarde_rapv
             then
                -- Als eerste de economische positie aanpassen aan de nieuwe dekkingswaarde:
                update positie_werkbestand b
                set    b.pwb_dekk_waarde_rapv  = b.pwb_dekk_waarde_rapv - r_pd.pwb_dekk_waarde_rapv + v_nieuwe_dekkingswaarde,
                       b.pwb_dekk_waarde_vv_sl = b.pwb_dekk_waarde_vv_sl - r_pd.pwb_dekk_waarde_vv_sl + v_nieuwe_dekk_waarde_vv_sl
                where  b.pwb_relatie_nummer    = i_relatienr
                and    b.pwb_rekening_nummer   = ' '
                and    b.pwb_rekening_soort    = 0
                and    b.pwb_symbool           = r_pd.pwb_symbool
                and    b.pwb_optietype         = r_pd.pwb_optietype
                and    b.pwb_expiratiedatum    = r_pd.pwb_expiratiedatum
                and    b.pwb_exerciseprijs     = r_pd.pwb_exerciseprijs;

                -- Daarna de gegevens van de positie zelf bijwerken:
                update positie_werkbestand w
                set    w.pwb_dekk_waarde_rapv  = v_nieuwe_dekkingswaarde,
                       w.pwb_dekk_waarde_vv_sl = v_nieuwe_dekk_waarde_vv_sl
                where  w.rowid                = r_pd.rowid;
             end if;
          end if;
       end loop;
     end;

  o_extra_spr_port_waarde    := v_totale_port_waarde_bv;
  o_extra_spr_port_waarde_vv := v_totale_port_waarde_vv;

  end if; -- Einde portefeuillewaarde groter dan 0

  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Einde spreidingseis aanpassing');
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
  end if;

end spreidingeis_aanpassing;
-- EINDE CODE VAN DE PROCEDURE SPREIDINGEIS_AANPASSING


-- DE CODE VOOR DE PROCEDURE VULLEN_AS_POSITIES:
procedure vullen_AS_posities
(i_relatienr                in clienten.cl_nummer%type
,i_terminalnummer           in werkbestand.wk_terminal%type
)
-- Deze procedure vult de diverse margin werkbestanden (ap_werkbest_sessie en margin_wb_sessie)
-- Inkomende parameters: i_relatienr      = Het relatienummer van de client waarvoor de bestedingsruimte wordt opgevraagd
--                       i_terminalnummer = Het terminalnummer van de sessie

is

  v_runnummer              temp_ap_werkbest_sessie.tas_runnummer%type;

cursor pw is

       select p.pwb_relatie_nummer, p.pwb_rekening_nummer,  p.pwb_rekening_soort,
              p.pwb_symbool,        p.pwb_optietype,        p.pwb_expiratiedatum,
              p.pwb_exerciseprijs,  p.pwb_bi_type,          p.pwb_ref_symbool,
              p.pwb_fonds_valuta,   p.pwb_werk_aantal_marg, p.pwb_hist_wrd_posbe,
              p.pwb_waarborgsom_vv, p.pwb_margin_factor,    p.pwb_biedk_refsymb,
              p.pwb_biedk_symbool,  p.pwb_laatk_symbool,    p.pwb_prijs_factor,
              p.pwb_init_margin_vv, p.pwb_pricing_unit
       from   positie_werkbestand p
       where  p.pwb_relatie_nummer = i_relatienr
       and    p.pwb_rekening_soort between 1 and 999;

begin
     -- Eerst leeg gooien van de werkbestanden:
     delete temp_ap_werkbest_sessie where tas_relatienr = i_terminalnummer;
     delete temp_margin_wb_sessie   where tms_relatienr = i_terminalnummer;

     v_runnummer := 0;

     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'In loop voor wegschrijven naar margin-werkbestand');
     end if;

     for r_pw in pw
     loop

        if gv_debuggen = 1
        then
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Fondssymbool : '||r_pw.pwb_symbool||' ; Optietype : '||r_pw.pwb_optietype);
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Expiratiedatum : '||r_pw.pwb_expiratiedatum||' ;  exerciseprijs : '||to_char(r_pw.pwb_exerciseprijs));
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Ref symbool  : '||r_pw.pwb_ref_symbool||' ; bi-type : '||to_char(r_pw.pwb_bi_type));
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Werk aantal margin  : '||to_char(r_pw.pwb_werk_aantal_marg)||' ; init margin : '||to_char(r_pw.pwb_init_margin_vv));
        end if;


        vullen_margin_werkb (i_relatienr,               i_terminalnummer,          r_pw.pwb_rekening_soort,
                             r_pw.pwb_rekening_nummer,  r_pw.pwb_ref_symbool,      r_pw.pwb_symbool,
                             r_pw.pwb_optietype,        r_pw.pwb_expiratiedatum,   r_pw.pwb_exerciseprijs,
                             r_pw.pwb_werk_aantal_marg, 0,                         r_pw.pwb_hist_wrd_posbe,
                             r_pw.pwb_bi_type,          r_pw.pwb_margin_factor,    r_pw.pwb_biedk_refsymb,
                             r_pw.pwb_biedk_symbool,    r_pw.pwb_laatk_symbool,    r_pw.pwb_prijs_factor,
                             r_pw.pwb_waarborgsom_vv,   r_pw.pwb_init_margin_vv,   r_pw.pwb_fonds_valuta,
                             r_pw.pwb_pricing_unit,     v_runnummer);
     end loop; -- positie gegevens

     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
     end if;

end vullen_AS_posities;
-- EINDE CODE VAN DE PROCEDURE VULLEN_AS_POSITIES


-- DE CODE VOOR DE PROCEDURE VULLEN_MARGIN_WERKB
procedure vullen_margin_werkb
(i_relatienr                in clienten.cl_nummer%type
,i_terminalnummer           in werkbestand.wk_terminal%type
,i_rekening_soort           in rekeningen.re_soort%type
,i_rekening_nummer          in rekeningen.re_rekening%type
,i_ref_symbool              in beleggingsinstrument.be_referentiesymbool%type
,i_symbool                  in beleggingsinstrument.be_symbool%type
,i_optietype                in beleggingsinstrument.be_optietype%type
,i_expiratiedatum           in beleggingsinstrument.be_expiratiedatum%type
,i_exerciseprijs            in beleggingsinstrument.be_exerciseprijs%type
,i_aantal                   in temp_ap_werkbest_sessie.tas_saldo_positie%type
,i_aantal_prod_geblok       in temp_margin_wb_sessie.tms_prod_geblok_aantal%type
,i_hist_wrd_posbe           in temp_ap_werkbest_sessie.tas_hist_wrd_posbe%type
,i_bi_type                  in beleggingsinstrument.be_bi_nummer%type
,i_margin_factor            in positie_werkbestand.pwb_margin_factor%type
,i_biedk_refsymbool         in positie_werkbestand.pwb_biedk_refsymb%type
,i_biedk_symbool            in positie_werkbestand.pwb_biedk_symbool%type
,i_laatk_symbool            in positie_werkbestand.pwb_laatk_symbool%type
,i_prijs_factor             in beleggingsinstrument.be_prijs_factor%type
,i_waarborgsom_vv           in positie_werkbestand.pwb_waarborgsom_vv%type
,i_init_margin_vv           in positie_werkbestand.pwb_init_margin_vv%type
,i_fonds_valuta             in positie_werkbestand.pwb_fonds_valuta%type
,i_pricing_unit             in beleggingsinstrument.be_pricing_unit%type
,i_runnummer                in temp_ap_werkbest_sessie.tas_runnummer%type
)

is

  v_ref_symbool             beleggingsinstrument.be_referentiesymbool%type;

begin
  v_ref_symbool    := i_ref_symbool;
  if (v_ref_symbool = ' ' or v_ref_symbool is null) and i_bi_type between 100 and 299
  then
     v_ref_symbool := i_symbool;
  end if;

  -- Niet futures:
  if i_bi_type not between 2900 and 2999
  then
     -- Gegevens over nemen in het ap_werkbest_sessie:
     insert into temp_ap_werkbest_sessie
     (tas_ref_relatie,           tas_relatienr,           tas_rekening_soort,
      tas_rekeningnr,            tas_ref_symbool,         tas_symbool,
      tas_optietype,             tas_expiratiedatum,      tas_exerciseprijs,
      tas_saldo_positie,         tas_hist_wrd_posbe,      tas_bi_type,
      tas_runnummer)
     values
     (i_relatienr,               i_terminalnummer,        i_rekening_soort,
      i_rekening_nummer,         v_ref_symbool,           i_symbool,
      i_optietype,               i_expiratiedatum,        i_exerciseprijs,
      i_aantal,                  i_hist_wrd_posbe,        i_bi_type,
      i_runnummer);

     -- saldo posities wegschrijven (geen rekeninggegevens):
     -- eerst een update proberen
     update temp_ap_werkbest_sessie
     set    tas_saldo_positie   = tas_saldo_positie  + i_aantal,
            tas_hist_wrd_posbe  = tas_hist_wrd_posbe + i_hist_wrd_posbe
     where  tas_ref_relatie     = i_relatienr
     and    tas_relatienr       = i_terminalnummer
     and    tas_rekening_soort  = 0
     and    tas_rekeningnr      = ' '
     and    tas_ref_symbool     = v_ref_symbool
     and    tas_symbool         = i_symbool
     and    tas_optietype       = i_optietype
     and    tas_expiratiedatum  = i_expiratiedatum
     and    tas_exerciseprijs   = i_exerciseprijs
     and    tas_runnummer       = i_runnummer;

     -- als die niet lukt, dan een insert
     if sql%notfound
     then
        insert into temp_ap_werkbest_sessie
        (tas_ref_relatie,           tas_relatienr,           tas_rekening_soort,
         tas_rekeningnr,            tas_ref_symbool,         tas_symbool,
         tas_optietype,             tas_expiratiedatum,      tas_exerciseprijs,
         tas_saldo_positie,         tas_hist_wrd_posbe,      tas_bi_type,
         tas_runnummer)
        values
        (i_relatienr,               i_terminalnummer,        0,
         ' ',                       v_ref_symbool,           i_symbool,
         i_optietype,               i_expiratiedatum,        i_exerciseprijs,
         i_aantal,                  i_hist_wrd_posbe,        i_bi_type,
         i_runnummer);
     end if;

     -- voor optieposities ook nog margin werkbestand vullen als er margin moet worden berekend
     -- voor de relatie ....
     if i_optietype in ('CALL','PUT') and gv_cl_margin_inst <> 0
     then
        -- eerst proberen te updaten (omdat hier geen rekeninggegevens worden weggeschreven moet je wel
        -- salderen bijdezelfde fondsen):
        update temp_margin_wb_sessie
        set    tms_margin_required      = tms_margin_required + i_init_margin_vv,
               tms_saldo_positie        = tms_saldo_positie + i_aantal,
               tms_prod_geblok_aantal   = tms_prod_geblok_aantal + i_aantal_prod_geblok
        where  tms_relatienr            = i_terminalnummer
        and    tms_runnnummer           = i_runnummer
        and    tms_refsymbool           = v_ref_symbool
        and    tms_soort                = i_optietype
        and    tms_biedkoers            = i_biedk_symbool
        and    tms_exp_datum            = i_expiratiedatum
        and    tms_exerciseprijs        = i_exerciseprijs
        and    tms_symbool              = i_symbool;

        -- als die niet lukt, dan een insert:
        if sql%notfound
        then
           insert into temp_margin_wb_sessie
           (tms_relatienr,             tms_refsymbool,          tms_soort,
            tms_symbool,               tms_exp_datum,           tms_exerciseprijs,
            tms_saldo_positie,         tms_prod_geblok_aantal,  tms_marginfactor,
            tms_slotkoers_voriged,     tms_biedkoers,           tms_laatkoers,
            tms_blocksize,             tms_margin_required,     tms_valuta,
            tms_pricing_unit,          tms_runnnummer)
           values
           (i_terminalnummer,          v_ref_symbool,           i_optietype,
            i_symbool,                 i_expiratiedatum,        i_exerciseprijs,
            i_aantal,                  i_aantal_prod_geblok,    i_margin_factor,
            i_biedk_refsymbool,        i_biedk_symbool,         i_laatk_symbool,
            i_prijs_factor,            i_init_margin_vv,        i_fonds_valuta,
            i_pricing_unit,            i_runnummer);
        end if;
     end if;

  -- Wel futures, hier ook overnemen in ap_werkbest_sessie en daarnaast wegschrijven van de
  -- gegevens in het margin_wb_sessie
  else

     insert into temp_ap_werkbest_sessie
     (tas_ref_relatie,           tas_relatienr,           tas_rekening_soort,
      tas_rekeningnr,            tas_ref_symbool,         tas_symbool,
      tas_optietype,             tas_expiratiedatum,      tas_exerciseprijs,
      tas_positie_future,        tas_hist_wrd_posbe,      tas_bi_type,
      tas_runnummer)
     values
     (i_relatienr,               i_terminalnummer,        i_rekening_soort,
      i_rekening_nummer,         v_ref_symbool,           i_symbool,
      i_optietype,               i_expiratiedatum,        i_exerciseprijs,
      i_aantal,                  i_hist_wrd_posbe,        i_bi_type,
      i_runnummer);

     -- saldo posities wegschrijven:
     -- eerst een update proberen
     update temp_ap_werkbest_sessie
     set    tas_positie_future  = tas_positie_future + i_aantal,
            tas_hist_wrd_posbe  = tas_hist_wrd_posbe + i_hist_wrd_posbe
     where  tas_ref_relatie     = i_relatienr
     and    tas_relatienr       = i_terminalnummer
     and    tas_rekening_soort  = 0
     and    tas_rekeningnr      = ' '
     and    tas_ref_symbool     = v_ref_symbool
     and    tas_symbool         = i_symbool
     and    tas_optietype       = i_optietype
     and    tas_expiratiedatum  = i_expiratiedatum
     and    tas_exerciseprijs   = i_exerciseprijs
     and    tas_runnummer       = i_runnummer;

     -- als die niet lukt, dan een insert
     if sql%notfound
     then
        insert into temp_ap_werkbest_sessie
        (tas_ref_relatie,           tas_relatienr,           tas_rekening_soort,
         tas_rekeningnr,            tas_ref_symbool,         tas_symbool,
         tas_optietype,             tas_expiratiedatum,      tas_exerciseprijs,
         tas_positie_future,        tas_hist_wrd_posbe,      tas_bi_type,
         tas_runnummer)
        values
        (i_relatienr,               i_terminalnummer,        0,
         ' ',                       v_ref_symbool,           i_symbool,
         i_optietype,               i_expiratiedatum,        i_exerciseprijs,
         i_aantal,                  i_hist_wrd_posbe,        i_bi_type,
         i_runnummer);
     end if;

     -- eerst proberen te updaten (omdat hier geen rekeninggegevens worden weggeschreven moet je wel
     -- salderen bijdezelfde fondsen):
     update temp_margin_wb_sessie
     set    tms_margin_required      = tms_margin_required + i_waarborgsom_vv,
            tms_positie_future       = tms_positie_future + i_aantal,
            tms_prod_geblok_aantal   = tms_prod_geblok_aantal + i_aantal_prod_geblok
     where  tms_relatienr            = i_terminalnummer
     and    tms_runnnummer           = i_runnummer
     and    tms_refsymbool           = v_ref_symbool
     and    tms_soort                = i_optietype
     and    tms_biedkoers            = i_biedk_symbool
     and    tms_exp_datum            = i_expiratiedatum
     and    tms_exerciseprijs        = i_exerciseprijs
     and    tms_symbool              = i_symbool;

     -- als die niet lukt, dan een insert:
     if sql%notfound
     then
        insert into temp_margin_wb_sessie
        (tms_relatienr,             tms_refsymbool,          tms_soort,
         tms_symbool,               tms_exp_datum,           tms_exerciseprijs,
         tms_positie_future,        tms_prod_geblok_aantal,  tms_margin_required,
         tms_valuta,                tms_blocksize,           tms_runnnummer,
         tms_biedkoers)
        values
        (i_terminalnummer,          v_ref_symbool,           i_optietype,
         i_symbool,                 i_expiratiedatum,        i_exerciseprijs,
         i_aantal,                  i_aantal_prod_geblok,    i_waarborgsom_vv,
         i_fonds_valuta,            i_prijs_factor,          i_runnummer,
         i_biedk_symbool);
     end if;
  end if;

end vullen_margin_werkb;
-- EINDE CODE VAN DE PROCEDURE VULLEN_MARGIN_WEKB


-- DE CODE VOOR DE FUNCTION VERSION
function Version
return varchar2
is

begin
      return gv_versie;
end version;
-- EINDE CODE FUNCTION VERSION

end FIAT_VERZAMEL;
/
