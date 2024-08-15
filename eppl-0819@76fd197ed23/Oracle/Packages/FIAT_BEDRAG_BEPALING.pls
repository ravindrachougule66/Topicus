create or replace package FIAT_BEDRAG_BEPALING
is

/*------------------------------------------------------------------------------
Package     : FIAT_BEDRAG_BEPALING
description : code voor de package FIAT_BEDRAG_BEPALING waarbinnen de volgende
              procedures en functions aanwezig zijn:
              procedure relatie_bedrag_bepaling
              function  version
------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';

-- procedure relatie_bedrag_bepaling:
   procedure relatie_bedrag_bepaling
   (i_relatienummer               in  clienten.cl_nummer%type
   ,i_terminalnr                  in  werkbestand.wk_terminal%type
   ,i_wegings_fac_munt_gebr       in  number
   ,i_trekkings_waarde_gebruiken  in  number
   ,i_productnummer               in  producten_per_relatie.ppr_productnummer%type
   ,i_productvolgnummer           in  producten_per_relatie.ppr_volgnr_per_product%type
   ,i_te_berekenen_deel           in  varchar2
   ,i_te_fiatt_beleg_opdracht     in  beleggingsopdracht_header.boh_opdrachtnummer%type
   ,i_eerst_verkoop_afhandelen    in  number
   ,i_relatie_heeft_depots        in  number
   ,i_detail_geg_aanmaken         in  number
   ,i_bedrijfspaar_product        in  number
   ,i_instellingen                in  varchar2
   ,o_geldsaldo                   out aktuele_posities.ap_saldo_positie%type
   ,o_geld_geblok                 out geblokkeerde_positie.bpos_aantal_nominaal%type
   ,o_bedr_spaar_geblokkeerd      out geblokkeerde_positie.bpos_aantal_nominaal%type
   ,o_overige_geld_geblokkeerd    out geblokkeerde_positie.bpos_aantal_nominaal%type
   ,o_totaal_paym_init            out payment_initiation.amount%type
   ,o_dekk_waarde_rapv            out positie_werkbestand.pwb_dekk_waarde_rapv%type
   ,o_totaal_geblok_dekk          out aktuele_posities.ap_saldo_positie%type
   ,o_totaal_geblok_stuk          out aktuele_posities.ap_saldo_positie%type
   ,o_garanties                   out on_line_dossier.onld_bedrag%type
   ,o_obligo                      out on_line_dossier.onld_bedrag%type
   ,o_closing_result              out obligo_verplichting.obve_obligo_bedrag%type
   ,o_bijstellings_bedrag         out positie_werkbestand.pwb_bijstell_rapv%type
   ,o_laatst_berekende_margin     out fiattering_bedragen.fb_laatst_ber_margin%type
   ,o_voorvalutering              out fiattering_bedragen.fb_voorvalutering%type
   ,o_lopende_beleg_opdrachten    out beleggingsopdracht_header.boh_bedrag%type
   );


-- function version
   function version
   return                      varchar2;

end FIAT_BEDRAG_BEPALING;
/
create or replace package body FIAT_BEDRAG_BEPALING
is

/*------------------------------------------------------------------------------
Package body : FIAT_BEDRAG_BEPALING
description  : code voor de package body FIAT_BEDRAG_BEPALING waarbinnen de
               volgende procedures aanwezig zijn:
               procedure relatie_bedrag_bepaling
               procedure tot_geld_saldo
               procedure geld_geblokkeerd
               procedure dekking_geblokkeerd
               procedure geblokkeerde_stukken
               procedure on_line_dossier_berekening
               procedure laatst_berekende_margin
               procedure voorvalutering
               function  version
------------------------------------------------------------------------------*/

-- globale variabelen (dus te gebruiken over alle procedures nadat de waarden zijn
-- bepaald in de eerst aanroepend procedure)
   gv_relatie_nummer              relatie_fiattering.rf_relatie_nummer%type;
   gv_relatie_pr_id               producten.pr_id%type;
   gv_relatie_ppr_id              producten_per_relatie.ppr_id%type;        
   gv_rel_rapp_valuta             relatie_fiattering.rf_rapp_muntsoort%type;
   gv_rel_rapp_biedkoers          relatie_fiattering.rf_rapp_biedkoers%type;
   gv_rel_rapp_middenkoers        relatie_fiattering.rf_rapp_middenkoers%type;
   gv_rel_rapp_laatkoers          relatie_fiattering.rf_rapp_laatkoers%type;
   gv_rel_rapp_factor             relatie_fiattering.rf_rapp_factor%type;
   gv_rel_rapp_reciproke          relatie_fiattering.rf_rapp_reciproke%type;
   gv_rel_rapp_notatie            relatie_fiattering.rf_rapp_notatie%type;
   gv_basis_valuta                relatie_fiattering.rf_bv_muntsoort%type;
   gv_rel_onld_omschrijving       relatie_fiattering.rf_onld_omschrijving%type;
   gv_rel_onld_percentage         relatie_fiattering.rf_onld_percentage%type;
   gv_productnummer               producten_per_relatie.ppr_productnummer%type;
   gv_productvolgnummer           producten_per_relatie.ppr_volgnr_per_product%type;
   gv_bedrijfspaar_product        number(1);
   gv_debuggen                    relatie_fiattering.rf_debug_j_n%type;
   gv_debug_user                  relatie_fiattering.rf_debug_user%type;
   gv_detail_geg_aanmaken         number(1);
   gv_multi_valuta_spl            number(1);
   gv_bank2mrktqchangedate        muntsoorten.mu_update%type;
   gv_systspreadcodecategorie     valutaspread_cat_muntsoort.vscm_vsca_id%type;

-- procedure geld_geblokkeerd:
   procedure geld_geblokkeerd
   (i_relatienr                in  clienten.cl_nummer%type
   ,i_munt_weging_gebruiken    in  number
   ,i_bloksoort_bedr_sparen    in  tabelgegevens.tb_nummer%type
   );

-- procedure bereken_payment_init
   procedure bereken_payment_init
   ;
   
-- procedure totaliseren_geld_saldi
   procedure totaliseren_geld_saldi
   (i_relatienummer               in  clienten.cl_nummer%type
   ,o_geld_saldo                  out aktuele_posities.ap_saldo_positie%type
   ,o_totaal_geblokkeerd          out geblokkeerde_positie.bpos_aantal_nominaal%type
   ,o_bedrf_spaar_geblokkeerd     out geblokkeerde_positie.bpos_aantal_nominaal%type
   ,o_overige_geblokkeerd         out geblokkeerde_positie.bpos_aantal_nominaal%type
   ,o_totaal_paym_init            out payment_initiation.amount%type
   );

-- procedure dekking_geblokkeerd:
   procedure dekking_geblokkeerd
   (i_terminalnummer             in  werkbestand.wk_terminal%type
   ,i_TRKW_aktief                in  number
   ,o_totaal_geblokkeerd         out aktuele_posities.ap_saldo_positie%type
   );

-- procedure geblokkeerde_stukken:
   procedure geblokkeerde_stukken
   (i_relatienr                  in  clienten.cl_nummer%type
   ,o_dekkings_waarde            out aktuele_posities.ap_saldo_positie%type
   );

-- procedure on_line_dossier_berekening:
   procedure on_line_dossier_berekening
   (i_relatienr                  in  clienten.cl_nummer%type
   ,i_te_berekenen_deel          in  varchar2
   ,o_garanties                  out on_line_dossier.onld_bedrag%type
   ,o_obligo                     out on_line_dossier.onld_bedrag%type
   ,o_closing_result             out obligo_verplichting.obve_obligo_bedrag%type
   );

-- procedure laatst_berekende_margin
   procedure laatst_berekende_margin
   (i_relatienummer              in  clienten.cl_nummer%type
   ,o_laatst_berek_marging       out historisch_obligo.ho_optie%type
   );

-- procedure voorvalutering
   procedure voorvalutering
   (i_relatienummer              in  clienten.cl_nummer%type
   ,i_terminalnummer             in  werkbestand.wk_terminal%type
   ,o_voorvalutering             out fiattering_bedragen.fb_voorvalutering%type
   );

-- procedure lopende_beleggingsopdrachten
   procedure lopende_beleggingsopdrachten
   (i_relatienummer              in  clienten.cl_nummer%type
   ,i_terminalnummer             in  werkbestand.wk_terminal%type
   ,i_te_fiatteren_belegopdracht in  beleggingsopdracht_header.boh_opdrachtnummer%type
   ,i_eerst_verkoop_afhandelen   in  number
   ,o_tot_lopende_opdrachten_rv  out beleggingsopdracht_header.boh_bedrag%type
   );


-- HIERONDER VOLGEN DE UITGESCHREVEN PROCEDURES:

-- DE CODE VOOR DE PROCEDURE RELATIE_BEDRAG_BEPALING:
procedure relatie_bedrag_bepaling
(i_relatienummer               in  clienten.cl_nummer%type
,i_terminalnr                  in  werkbestand.wk_terminal%type
,i_wegings_fac_munt_gebr       in  number
,i_trekkings_waarde_gebruiken  in  number
,i_productnummer               in  producten_per_relatie.ppr_productnummer%type
,i_productvolgnummer           in  producten_per_relatie.ppr_volgnr_per_product%type
,i_te_berekenen_deel           in  varchar2
,i_te_fiatt_beleg_opdracht     in  beleggingsopdracht_header.boh_opdrachtnummer%type
,i_eerst_verkoop_afhandelen    in  number
,i_relatie_heeft_depots        in  number
,i_detail_geg_aanmaken         in  number
,i_bedrijfspaar_product        in  number
,i_instellingen                in  varchar2
,o_geldsaldo                   out aktuele_posities.ap_saldo_positie%type
,o_geld_geblok                 out geblokkeerde_positie.bpos_aantal_nominaal%type
,o_bedr_spaar_geblokkeerd      out geblokkeerde_positie.bpos_aantal_nominaal%type
,o_overige_geld_geblokkeerd    out geblokkeerde_positie.bpos_aantal_nominaal%type
,o_totaal_paym_init            out payment_initiation.amount%type
,o_dekk_waarde_rapv            out positie_werkbestand.pwb_dekk_waarde_rapv%type
,o_totaal_geblok_dekk          out aktuele_posities.ap_saldo_positie%type
,o_totaal_geblok_stuk          out aktuele_posities.ap_saldo_positie%type
,o_garanties                   out on_line_dossier.onld_bedrag%type
,o_obligo                      out on_line_dossier.onld_bedrag%type
,o_closing_result              out obligo_verplichting.obve_obligo_bedrag%type
,o_bijstellings_bedrag         out positie_werkbestand.pwb_bijstell_rapv%type
,o_laatst_berekende_margin     out fiattering_bedragen.fb_laatst_ber_margin%type
,o_voorvalutering              out fiattering_bedragen.fb_voorvalutering%type
,o_lopende_beleg_opdrachten    out beleggingsopdracht_header.boh_bedrag%type
)

is

   v_laatst_berek_margin_bepalen     number(1);
   v_voorvalutering_bepalen          number(1);
   v_herkomstcode_belegg_opdr        beleggingsopdracht_header.boh_herkomst%type;
   v_lopende_belegg_opdr_in_fiatt    number(1);
   -- virtuals voor de instellingen die opgehaald worden
   v_op_te_halen_instel              varchar2(30);
   v_inst_type                       varchar2(1);
   v_instelling                      varchar2(100);
   v_blokkade_soort_bedr_sparen      tabelgegevens.tb_nummer%type   := 0;

begin
    -- de globale variabelen vullen om deze over de gehele package te kunen gebruiken
    select r.rf_rapp_muntsoort,  r.rf_rapp_biedkoers,      r.rf_rapp_laatkoers,
           r.rf_rapp_factor,     r.rf_rapp_reciproke,      r.rf_rapp_notatie,
           r.rf_bv_muntsoort,    r.rf_onld_omschrijving,   r.rf_onld_percentage,
           r.rf_relatie_nummer,  r.rf_debug_j_n,           r.rf_debug_user,
           r.rf_pr_id,           r.rf_ppr_id,              r.rf_rapp_middenkoers
    into   gv_rel_rapp_valuta,   gv_rel_rapp_biedkoers,    gv_rel_rapp_laatkoers,
           gv_rel_rapp_factor,   gv_rel_rapp_reciproke,    gv_rel_rapp_notatie,
           gv_basis_valuta,      gv_rel_onld_omschrijving, gv_rel_onld_percentage,
           gv_relatie_nummer,    gv_debuggen,              gv_debug_user,
           gv_relatie_pr_id,     gv_relatie_ppr_id,        gv_rel_rapp_middenkoers
    from   relatie_fiattering r
    where  r.rf_relatie_nummer = i_relatienummer;

    gv_productnummer        := i_productnummer;
    gv_productvolgnummer    := i_productvolgnummer;
    gv_bedrijfspaar_product := i_bedrijfspaar_product;
    gv_detail_geg_aanmaken  := i_detail_geg_aanmaken;
    
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
        
    if gv_bedrijfspaar_product = 1
    then
       v_op_te_halen_instel := 'BlokSoortBedrSpr';
       v_inst_type          := 'N';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
       into   v_instelling
       from   dual;
       v_blokkade_soort_bedr_sparen := to_number(rtrim(ltrim(v_instelling)));
    end if;
    
    v_op_te_halen_instel := 'UseMultiCurrencySP';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    gv_multi_valuta_spl := to_number(rtrim(ltrim(v_instelling)));
        
    -- Geblokkeerd geld bepalen
    geld_geblokkeerd (i_relatienummer, i_wegings_fac_munt_gebr,  v_blokkade_soort_bedr_sparen);

    -- aanroepen van berekenen van de payment initiations bedragen
    bereken_payment_init;
    
    -- De geld totalen bepalen:
    totaliseren_geld_saldi (i_relatienummer,          o_geldsaldo,                o_geld_geblok,
                            o_bedr_spaar_geblokkeerd, o_overige_geld_geblokkeerd, o_totaal_paym_init);

    -- de onderstaande stappen hoeven alleen uitgevoerd te worden als de relatie een depot heeft
    if i_relatie_heeft_depots = 1
    then
       -- totaal van de dekkingswaarde bepalen
       select sum(p.pwb_dekk_waarde_rapv)
       into   o_dekk_waarde_rapv
       from   positie_werkbestand p
       where  p.pwb_relatie_nummer = i_relatienummer
       and    p.pwb_rekening_soort between 1 and 999;

       -- Totaal van de geblokkeerde dekking bepalen
       dekking_geblokkeerd (i_terminalnr, i_trekkings_waarde_gebruiken, o_totaal_geblok_dekk);

       -- Totaal dekking van de geblokkeerde stukken bepalen
       geblokkeerde_stukken (i_relatienummer, o_totaal_geblok_stuk );

       -- Beide dekkingssoorten bij elkaar optellen (maximeren)
       if o_totaal_geblok_stuk + o_totaal_geblok_dekk > o_totaal_geblok_stuk
       then
          o_totaal_geblok_stuk := o_totaal_geblok_stuk + o_totaal_geblok_dekk;
       else
          o_totaal_geblok_stuk := o_totaal_geblok_stuk;
       end if;
    else
       o_dekk_waarde_rapv   := 0;
       o_totaal_geblok_dekk := 0;
       o_totaal_geblok_stuk := 0;
    end if;

    -- Online dossier kan ook als de klant geen depots heeft !!!!
    -- Garanties en obligo verplichtingen bepalen:
    on_line_dossier_berekening (i_relatienummer, i_te_berekenen_deel, o_garanties, o_obligo, o_closing_result);

    -- de onderstaande stappen hoeven alleen uitgevoerd te worden als de relatie een depot heeft
    if i_relatie_heeft_depots = 1
    then
       -- Totaal van de bijstellingsbedragen bepalen
       select nvl(sum(p.pwb_bijstell_rapv),0)
       into   o_bijstellings_bedrag
       from   positie_werkbestand p
       where  p.pwb_relatie_nummer = i_relatienummer;

       -- Laatst berekende margin bepalen:
       v_op_te_halen_instel := 'LaatstBerMargin';
       v_inst_type          := 'N';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
       into   v_instelling
       from   dual;
       v_laatst_berek_margin_bepalen := to_number(rtrim(ltrim(v_instelling)));

       if v_laatst_berek_margin_bepalen = 1
       then
          laatst_berekende_margin (i_relatienummer, o_laatst_berekende_margin);
       end if;
    else
       o_bijstellings_bedrag     := 0;
       o_laatst_berekende_margin := 0;
    end if;

    -- Bedrag van de voorvalutering bepalen
    v_op_te_halen_instel := 'Voorvalutering';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    v_voorvalutering_bepalen := to_number(rtrim(ltrim(v_instelling)));

    if v_voorvalutering_bepalen = 1
    then
       voorvalutering (i_relatienummer, i_terminalnr, o_voorvalutering);
    end if;

    -- de onderstaande stappen hoeven alleen uitgevoerd te worden als de relatie een depot heeft
    if i_relatie_heeft_depots = 1
    then
       -- lopende beleggingsopdrachten, alleen als de instelling dat aangeeft
       v_op_te_halen_instel := 'BeleggOpdrInFiatt';
       v_inst_type          := 'N';
       select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
       into   v_instelling
       from   dual;
       v_lopende_belegg_opdr_in_fiatt := to_number(rtrim(ltrim(v_instelling)));

       -- de herkomstcode van de beleggingsopdracht achterhalen.
       if i_te_fiatt_beleg_opdracht <> 0
       then
          select b.boh_herkomst
          into   v_herkomstcode_belegg_opdr
          from   beleggingsopdracht_header b
          where  b.boh_opdrachtnummer = i_te_fiatt_beleg_opdracht;
       else
          v_herkomstcode_belegg_opdr := ' ';
       end if;

       -- lopende beleggingsopdrachten alleen fiatteren als dat volgens de instelling moet en als
       -- het geen historische beleggingsopdracht betreft.
       if v_lopende_belegg_opdr_in_fiatt = 1 and v_herkomstcode_belegg_opdr <> 'BHAH'
       then
          lopende_beleggingsopdrachten (i_relatienummer, i_terminalnr, i_te_fiatt_beleg_opdracht, i_eerst_verkoop_afhandelen, o_lopende_beleg_opdrachten);
       end if;
    else
       o_lopende_beleg_opdrachten := 0;
    end if;

end relatie_bedrag_bepaling;
-- EINDE VAN DE PROCEDURE RELATIE_BEDRAG_BEPALING


-- DE CODE VOOR DE PROCEDURE GELD_GEBLOKKEERD:
-- In deze procedure wordt het totaal saldo bepaald van geblokkeerd geld
-- uit de file geblokkeerde_positie.
procedure geld_geblokkeerd
(i_relatienr                in  clienten.cl_nummer%type
,i_munt_weging_gebruiken    in  number
,i_bloksoort_bedr_sparen    in  tabelgegevens.tb_nummer%type
)

-- Inkomende parameters zijn: i_relatienr             = het relatienummer van de client waarvoor
--                                                      de bepaling wordt uitgevoerd.
--                            i_wegings_fac_gebruiken = 1 houdt in wegingsfactoren gebruiken,
--                                                      <> 1 houdt in geen weging
-- Uitgaande parameters zijn: o_geld_saldo            = het totale geldsaldo dat bepaald is

is
   v_blokk_biedk              muntsoorten.mu_laatkoers%type;
   v_blokk_factor             muntsoorten.mu_factor%type;
   v_blokk_recip              muntsoorten.mu_reciproke%type;
   v_wegingsfactor_short      wegingsfactoren.wg_intern_short_perc%type;
   v_saldo_gewogen            geblokkeerde_positie.bpos_aantal_nominaal%type;
   v_saldo_gewogen_bv         geblokkeerde_positie.bpos_aantal_nominaal%type;
   v_saldo_gewogen_vv_sl      geblokkeerde_positie.bpos_aantal_nominaal%type;
   v_dummy_num                number(1);

cursor bp is

   select g.bpos_blokkeringsrt,  g.bpos_aantal_nominaal,
          g.bpos_rekeningnr,     g.bpos_rekeningsoort, g.bpos_rekeningmuntsr,
          g.bpos_vervaldatum,    g.bpos_ingangsdatum
   from   geblokkeerde_positie g, te_doorlopen_rek t
   where  g.bpos_relatienr         =  i_relatienr
   and    g.bpos_categorie         =  1
   and    g.bpos_fondssymbool      =  ' '
   and    g.bpos_rekeningsoort     between 1000 and 9999
   and    g.bpos_blokkeringsrt     <= 4999
   and    g.bpos_rekeningnr        = t.tdr_rekeningnr                  -- inner join!! op te_doorlopen_rek
   and    g.bpos_rekeningsoort     = t.tdr_rekeningsoort               -- om op deze manier af te dwingen dat allen
   and    g.bpos_rekeningmuntsr    = t.tdr_rekeningmunt                -- door toegestane rekeningen wordt gelopen
   and   (g.bpos_vervaldatum       =  '00000000'
          or
          g.bpos_vervaldatum >  to_char(SYSDATE,'yyyymmdd'));

begin
   for r_bp in bp
   loop
      -- Ophalen van aanvullende gegevens:
      select w.wg_intern_short_perc
      into   v_wegingsfactor_short
      from   muntsoorten m, wegingsfactoren w
      where  m.mu_code            = r_bp.bpos_rekeningmuntsr
      and    m.mu_wegingsfactornr = w.wg_nummer (+);
      
      FIAT_ALGEMEEN.valutagegevens_bepalen (r_bp.bpos_rekeningmuntsr, gv_relatie_pr_id, gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                            gv_bank2mrktqchangedate,  gv_debuggen,      gv_debug_user,     v_blokk_biedk,
                                            v_dummy_num,              v_dummy_num,      v_blokk_factor,    v_blokk_recip,
                                            v_dummy_num);
      
      if (v_wegingsfactor_short = 0 or v_wegingsfactor_short is null)
      then
         v_wegingsfactor_short := 100;
      end if;

      -- wegingsfactor meenemen als dat is aangegeven
      if i_munt_weging_gebruiken = 1
      then
         v_saldo_gewogen       := r_bp.bpos_aantal_nominaal * v_wegingsfactor_short/100;
         v_saldo_gewogen_vv_sl := r_bp.bpos_aantal_nominaal * v_wegingsfactor_short/100;
      else
         v_saldo_gewogen       := r_bp.bpos_aantal_nominaal;
         v_saldo_gewogen_vv_sl := r_bp.bpos_aantal_nominaal;
      end if;

      -- het bedrag omrekenen als de rekeningmuntsoort afwijkt van de rapportage muntsoort
      -- omdat het om een negatieve factor gaat is het van laat naar biedkoers omrekenen
      if r_bp.bpos_rekeningmuntsr <> gv_rel_rapp_valuta
      then
         select FIAT_ALGEMEEN.gld_omrekenen_bedrag_vv(v_saldo_gewogen, v_blokk_recip, v_blokk_factor, v_blokk_biedk,
                                                      v_blokk_biedk, gv_rel_rapp_reciproke, gv_rel_rapp_factor,
                                                      gv_rel_rapp_laatkoers, gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
         into   v_saldo_gewogen_bv
         from   dual;
      else
         v_saldo_gewogen_bv := v_saldo_gewogen;
      end if;

      -- Vast leggen welke bedragen zijn berekend voor dit blokkade record:  
      insert into fiat_blocked_cash f
      (f.account_number,          f.account_type,  
       f.account_currency,        f.blocking_type,       
       f.starting_date, 
       f.expiration_date,
       f.weighting_fac_short, 
       f.bedrspr_ind,   
       f.amount_fc,               f.amount_repc,
       f.amount_fc_sl)
      values 
      (r_bp.bpos_rekeningnr,      r_bp.bpos_rekeningsoort, 
       r_bp.bpos_rekeningmuntsr,  r_bp.bpos_blokkeringsrt,
       case when r_bp.bpos_ingangsdatum = '00000000' then to_date('1-1-0001','DD-MM-YYYY') else to_date(r_bp.bpos_ingangsdatum,'YYYYMMDD') end, 
       case when r_bp.bpos_vervaldatum  = '00000000' then to_date('1-1-0001','DD-MM-YYYY') else to_date(r_bp.bpos_vervaldatum,'YYYYMMDD') end,
       decode(i_munt_weging_gebruiken,1,v_wegingsfactor_short,0), 
       decode(r_bp.bpos_blokkeringsrt,i_bloksoort_bedr_sparen,1,0),   
       r_bp.bpos_aantal_nominaal, v_saldo_gewogen_bv,
       v_saldo_gewogen_vv_sl);
   end loop;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Einde Fiat_bedrag_bepaing.Geld_Geblokkeerd');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

end geld_geblokkeerd;
-- EINDE VAN DE PROCEDURE GELD_GEBLOKKEERD


-- DE CODE VOOR DE PROCEDURE BEREKEN_PAYMENT_INIT
-- in deze procedure worden de bedragen vanuit payment initiations bepaald
-- hierbij wordt alleen gekeken naar de debet kant....
procedure bereken_payment_init

is
  v_bet_valuta_koers        muntsoorten.mu_biedkoers%type;
  v_bet_valuta_factor       muntsoorten.mu_factor%type;
  v_bet_valuta_reciproke    muntsoorten.mu_reciproke%type;
  
  v_bedrag_in_rapp_val      payment_initiation.amount%type;
 
  v_dummy_num               number(1);

cursor pyi is
   select i.debt_re_id, i.transaction_id,  i.currency,
          i.amount,     i.create_date
   from   payment_initiation i, paym_init_status s, te_doorlopen_rek r
   where  i.debt_re_id       = r.tdr_re_id
   and    i.amount           <> 0
   and    i.in_reservation   = 0 
   and    i.status           <> 8
   and    i.status           = s.id
   and    s.status_type      = 1;

begin

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user,'Begin procedure FIAT_BEDRAG_BEPALING.bereken_paym_int');
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user,'');
   end if;

for r_pyi in pyi
loop
   -- eerst gegevens resetten:
   v_bedrag_in_rapp_val := 0;


   if r_pyi.currency = gv_rel_rapp_valuta
   then
      v_bedrag_in_rapp_val := r_pyi.amount;
   else
      -- het bedrag gaan omrekenen naar de rapportage valuta
      FIAT_ALGEMEEN.valutagegevens_bepalen (r_pyi.currency,          gv_relatie_pr_id, gv_relatie_ppr_id,   gv_systspreadcodecategorie,
                                            gv_bank2mrktqchangedate, gv_debuggen,      gv_debug_user,       v_bet_valuta_koers,
                                            v_dummy_num,             v_dummy_num,      v_bet_valuta_factor, v_bet_valuta_reciproke,
                                            v_dummy_num);
      
      select FIAT_ALGEMEEN.omrekenen_bedrag_vv (r_pyi.amount,       v_bet_valuta_reciproke, v_bet_valuta_factor, 
                                                v_bet_valuta_koers, v_bet_valuta_koers,     gv_rel_rapp_reciproke,
                                                gv_rel_rapp_factor, gv_rel_rapp_laatkoers,  gv_rel_rapp_laatkoers,
                                                gv_rel_rapp_notatie) 
      into   v_bedrag_in_rapp_val
      from   dual;
   end if;
   
   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user,'Rekening id : '||to_char(r_pyi.debt_re_id)||' ; muntsoort : '||r_pyi.currency);
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user,'bedrag vv : '||to_char(r_pyi.amount)||' ; bedrag rapp val : '||to_char(v_bedrag_in_rapp_val));
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user,'create date : '||r_pyi.create_date||' ; transaction id : '||r_pyi.transaction_id);
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user,' ');
   end if;
      
   -- wegschrijven van de gegevens in het werk bestand om de totaal berekening mee te kunnen doen en te rapporteren
   insert into fiat_payments f
   (f.account_id,      f.relation_ind,       f.transaction_id,
    f.foreign_curr,    f.amount_fc,          f.amount_repc,                               
    f.free_blocked)
   values
   (r_pyi.debt_re_id,  1,                    r_pyi.transaction_id,
    r_pyi.currency,    abs(r_pyi.amount)*-1, abs(v_bedrag_in_rapp_val)*-1,                
    0);
    
end loop;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user,'Einde procedure FIAT_BEDRAG_BEPALING.bereken_paym_int');
      FIAT_ALGEMEEN.fiat_debug (gv_debug_user,'');
   end if;

end bereken_payment_init;
-- EINDE VAN DE PROCEDURE BEREKEN_PAYMENT_INIT


-- DE CODE VOOR DE PROCEDURE TOTALISEREN_GELD_SALDI
-- in deze procedure worden de totaalbedragen van de geldrekening,
-- gebblokkeerd geld en payment initiations bepaald.
procedure totaliseren_geld_saldi
(i_relatienummer               in  clienten.cl_nummer%type
,o_geld_saldo                  out aktuele_posities.ap_saldo_positie%type
,o_totaal_geblokkeerd          out geblokkeerde_positie.bpos_aantal_nominaal%type
,o_bedrf_spaar_geblokkeerd     out geblokkeerde_positie.bpos_aantal_nominaal%type
,o_overige_geblokkeerd         out geblokkeerde_positie.bpos_aantal_nominaal%type
,o_totaal_paym_init            out payment_initiation.amount%type
)

is

begin
   -- Eerst de uitgaande parameters resetten
   o_geld_saldo                  := 0;
   o_totaal_geblokkeerd          := 0;
   o_bedrf_spaar_geblokkeerd     := 0;
   o_overige_geblokkeerd         := 0;
   o_totaal_paym_init            := 0;

   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Begin FIAT_BEDRAG_BEPALING.totaliseren_geld_saldi');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

   -- Er worden een aantal stappen uitgevoerd in deze procedure:
   -- 1. Bedragen resetten als de rekening is geblokkeerd (op rekeningniveau of op rekeningsoortniveau)
   -- 2. Bedragen totaliseren en parameters zetten.

   -- Stap 1 Bedragen resetten:
   -- Stap 1A. Bepalen of de bedragen voor een rekening gereset moeten worden.
   declare
      v_bedragen_resetten          number(1);
      v_totaal_geldsaldo           geld_werkbestand.gwb_saldo_rapv%type;
      v_totaal_paym_init           payment_initiation.amount%type;
      v_totaal_payments            fiat_payments.amount_repc%type;
      v_totaal_niet_geb_saldo      geld_werkbestand.gwb_trans_mut_rapv%type;
      v_totaal_geblokkeerd_saldo   geblokkeerde_positie.bpos_aantal_nominaal%type;

      cursor td is
         select t.tdr_rekeningnr,        t.tdr_rekeningsoort,          t.tdr_rekeningmunt,
                t.tdr_rekening_blokkade, t.tdr_rekeningsoort_blokkade, t.tdr_re_id
         from   te_doorlopen_rek t
         where  (t.tdr_rekening_blokkade = 1
                 or
                 t.tdr_rekeningsoort_blokkade = 1);
   begin
      for r_td in td
      loop
         -- er vanuit gaan dat de bedragen niet gereset hoeven te worden:
         v_bedragen_resetten        := 0;
         v_totaal_geldsaldo         := 0;
         v_totaal_niet_geb_saldo    := 0;
         v_totaal_geblokkeerd_saldo := 0;

         -- Als op rekeningsoort een blokkade is ingesteld, dan altijd resetten
         if r_td.tdr_rekeningsoort_blokkade = 1
         then
            v_bedragen_resetten := 1;
         end if;

         -- Als op rekeningsoort geen blokkade is in gesteld, dan is die op rekening niveau ingesteld
         -- Dan bepalen of de totaal telling van geldsaldo, nietdoorgeboekte geldboekingen, geblokkeerd geld en payment initiation
         -- groter dan 0 is. Dan resetten, anders niets doen.
         if r_td.tdr_rekeningsoort_blokkade = 0
         then
            select sum(g.gwb_saldo_rapv), sum(g.gwb_trans_mut_rapv)
            into   v_totaal_geldsaldo,    v_totaal_niet_geb_saldo
            from   geld_werkbestand g
            where  g.gwb_relatie_nummer  = i_relatienummer
            and    g.gwb_rekening_nummer = r_td.tdr_rekeningnr
            and    g.gwb_rekening_soort  = r_td.tdr_rekeningsoort
            and    g.gwb_rekening_munt   = r_td.tdr_rekeningmunt;
            
            select sum(f.amount_repc)
            into   v_totaal_geblokkeerd_saldo
            from   fiat_blocked_cash f
            where  f.account_number = r_td.tdr_rekeningnr
            and    f.account_type   = r_td.tdr_rekeningsoort
            and    f.account_currency = r_td.tdr_rekeningmunt;

            v_totaal_geblokkeerd_saldo := v_totaal_geblokkeerd_saldo * -1;

            select sum(f.amount_repc)
            into   v_totaal_payments
            from   fiat_payments f
            where  f.account_id     = r_td.tdr_re_id;    -- alle gegevens voor de re_id moeten opgeteld worden.

            -- bedragen bij elkaar op tellen en bedragen resetten als dit bedrag groter dan 0 is:
            if nvl(v_totaal_geldsaldo,0) + nvl(v_totaal_niet_geb_saldo,0) + nvl(v_totaal_geblokkeerd_saldo,0) + nvl(v_totaal_payments,0) > 0
            then
               v_bedragen_resetten := 1;
            end if;
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Rekeningnummer     : '||r_td.tdr_rekeningnr||' ; Rekeningsoort : '||to_char(r_td.tdr_rekeningsoort));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Rekeningmuntsoort  : '||r_td.tdr_rekeningmunt);
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Rekeningblokkade   : '||to_char(r_td.tdr_rekening_blokkade)||
                                                    ' ; Rekeningsoort blokkade : '||to_char(r_td.tdr_rekeningsoort_blokkade));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Totaal geldsaldo   : '||to_char(v_totaal_geldsaldo)||
                                                    ' ; Totaal niet geboekt saldo : '||to_char(v_totaal_niet_geb_saldo));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Totaal geblokkeerd : '||to_char(v_totaal_geblokkeerd_saldo)||
                                                    ' ; Totaal payments : '||to_char(v_totaal_payments));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Totaal payment initations  : '||to_char(v_totaal_paym_init));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Bedragen resetten  : '||to_char(v_bedragen_resetten));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
         end if;

         -- De bedragen moeten gereset worden:
         if v_bedragen_resetten = 1
         then
            -- Eerst de bedragen in het geld_werkbestand:
            update geld_werkbestand g
            set    g.gwb_saldo_rapv          = 0,
                   g.gwb_kredietlimiet_rapv  = 0,
                   g.gwb_overige_ruimte_rapv = 0,
                   g.gwb_trans_mut_rapv      = 0,
                   g.gwb_trans_mut_vv_sl     = 0,
                   g.gwb_saldo_vv_sl         = 0
            where  g.gwb_relatie_nummer      = i_relatienummer
            and    g.gwb_rekening_nummer     = r_td.tdr_rekeningnr
            and    g.gwb_rekening_soort      = r_td.tdr_rekeningsoort
            and    g.gwb_rekening_munt       = r_td.tdr_rekeningmunt;

            -- Dan de bedragen van de geblokkeerde geldposities:
            update fiat_blocked_cash f
            set    f.amount_repc             = 0,
                   f.amount_fc_sl            = 0
            where  f.account_number          = r_td.tdr_rekeningnr
            and    f.account_type            = r_td.tdr_rekeningsoort
            and    f.account_currency        = r_td.tdr_rekeningmunt;

            -- Daarna de regels van de payment initiations:
            update fiat_payments f
            set    f.amount_repc             = 0
            where  f.account_id              = r_td.tdr_re_id;
         end if;
      end loop;
   end;

   -- 2. Bedragen totaliseren in parameters zetten.
   -- De bedragen hebben nu de correcte waarde en kunnen gebruikt worden voor het totaliseren

   -- Totaal van geldsaldo + niet doorgeboekte transacties:
   select sum(g.gwb_saldo_rapv + g.gwb_trans_mut_rapv)
   into   o_geld_saldo
   from   geld_werkbestand g
   where  g.gwb_relatie_nummer  = i_relatienummer;

   -- bepalen totalen van de geblokkeerde geldposities
   declare
      cursor fbc is
         select sum(f.amount_repc) as total_amount, f.bedrspr_ind
         from   fiat_blocked_cash f
         group by f.bedrspr_ind;
   begin
      for r_fbc in fbc
      loop
         o_totaal_geblokkeerd := o_totaal_geblokkeerd + r_fbc.total_amount;
         
         if r_fbc.bedrspr_ind = 1
         then
            o_bedrf_spaar_geblokkeerd := o_bedrf_spaar_geblokkeerd + r_fbc.total_amount;
         else
            o_overige_geblokkeerd     := o_overige_geblokkeerd + r_fbc.total_amount;
         end if;
      end loop;
   end;

   -- Totaal van payment initiations
   select sum(f.amount_repc)
   into   o_totaal_paym_init
   from   fiat_payments f;
   
   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Totaal geldsaldo   : '||to_char(o_geld_saldo));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Totaal geblokkeerd : '||to_char(o_totaal_geblokkeerd)||
                                              ' ; Totaal Bedijfsspaar geblokkeerd : '||to_char(o_bedrf_spaar_geblokkeerd));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Totaal geblokkeerd overige : '||to_char(o_overige_geblokkeerd));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Totaal payment initations  : '||to_char(o_totaal_paym_init));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Einde FIAT_BEDRAG_BEPALING.totaliseren_geld_saldi');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

end totaliseren_geld_saldi;
-- EINDE VAN DE PROCEDURE TOTALISEREN_GELD_SALDI


-- DE CODE VOOR DE PROCEDURE DEKKING_GEBLOKKEERD:
-- in deze procedure wordt de dekkingswaarde van de voor cover/collateral
-- geblokkeerde stukken berekend. Als de TRKW aktief is, dan wordt daar een
-- correctie voor uitgevoerd.
procedure dekking_geblokkeerd
(i_terminalnummer           in  werkbestand.wk_terminal%type
,i_TRKW_aktief              in  number
,o_totaal_geblokkeerd       out aktuele_posities.ap_saldo_positie%type
)

is
   -- de gebruikte variabelen
   v_tegen_waarde_cover       werkbestand.wk_waarde_1%type;
   v_tegen_waarde_cover_vv    werkbestand.wk_waarde_2%type;
   v_cover_in_rapp_val        aktuele_posities.ap_saldo_positie%type;
   v_cover_in_vv_sl           aktuele_posities.ap_saldo_positie%type;
   v_collateral_in_rapp_val   aktuele_posities.ap_saldo_positie%type;
   v_collateral_in_vv_sl      aktuele_posities.ap_saldo_positie%type;

   v_fondsomschrijving        beleggingsinstrument.be_oms_1%type;
   v_fonds_id                 beleggingsinstrument.be_volgnummer%type;   
   v_fonds_munt_notatie       muntsoorten.mu_notatie%type;

   cursor ts is
   select t.tas_symbool,          t.tas_optietype,        t.tas_expiratiedatum,
          t.tas_exerciseprijs,    t.tas_collateral_used,  t.tas_in_cover_used,
          t.tas_bi_type,
          p.pwb_werk_aantal_port, p.pwb_dekk_waarde_rapv, p.pwb_fonds_valuta,
          p.pwb_dekk_waarde_vv_sl
   from   temp_ap_werkbest_sessie t, positie_werkbestand p
   where  t.tas_relatienr        =   i_terminalnummer
   and    t.tas_rekening_soort   =   0
   and    t.tas_optietype        =   ' '
   and    t.tas_expiratiedatum   =   '00000000'
   and    t.tas_exerciseprijs    =   0
   and    t.tas_bi_type          between 100 and 299
   and    t.tas_saldo_positie    >=  1
   and    t.tas_runnummer        =   0
   and    (t.tas_collateral_used > 0
           or
           t.tas_in_cover_used   >   0)
   and    p.pwb_relatie_nummer   = gv_relatie_nummer
   and    p.pwb_rekening_soort   = t.tas_rekening_soort
   and    p.pwb_rekening_nummer  = t.tas_rekeningnr
   and    p.pwb_symbool          = t.tas_symbool
   and    p.pwb_optietype        = t.tas_optietype
   and    p.pwb_expiratiedatum   = t.tas_expiratiedatum
   and    p.pwb_exerciseprijs    = t.tas_exerciseprijs
   and    p.pwb_dekk_waarde_rapv > 0;        -- alleen als voor het fonds ook daadwerkelijk dekkingswaarde is berekend !

begin
   -- zetten van de variabelen die maar 1 keer gedaan hoeven te worden
   o_totaal_geblokkeerd     := 0;

   -- door de stukken loopen om de geblokkeerde waarde te berekenen...
   for r_ts in ts
   loop
      -- resetten van de variabelen die in de loop gebruikt worden
      v_tegen_waarde_cover       := 0;
      v_tegen_waarde_cover_vv    := 0;
      v_cover_in_rapp_val        := 0;
      v_cover_in_vv_sl           := 0;
      v_collateral_in_rapp_val   := 0;
      v_collateral_in_vv_sl      := 0;

      v_fondsomschrijving        := ' ';
      v_fonds_munt_notatie       := 0;

      -- per gevonden record de volgende gegevens er bij zoeken.
      -- nb niet in de main select toevoegen! het bij selecteren van beleggingsinstrumenten "cost" te veel
      select b.be_oms_1,             b.be_volgnummer, m.mu_notatie
      into   v_fondsomschrijving,    v_fonds_id,      v_fonds_munt_notatie
      from   beleggingsinstrument b, muntsoorten m
      where  b.be_symbool         = r_ts.tas_symbool
      and    b.be_optietype       = r_ts.tas_optietype
      and    b.be_expiratiedatum  = r_ts.tas_expiratiedatum
      and    b.be_exerciseprijs   = r_ts.tas_exerciseprijs
      and    b.be_muntsoort       = m.mu_code;


      if r_ts.tas_in_cover_used > 0
      then
         -- berekenen van de dekkingswaarde van de in cover gezette stukken
         v_cover_in_rapp_val := round(r_ts.tas_in_cover_used / r_ts.pwb_werk_aantal_port * r_ts.pwb_dekk_waarde_rapv, gv_rel_rapp_notatie);
         v_cover_in_vv_sl    := round(r_ts.tas_in_cover_used / r_ts.pwb_werk_aantal_port * r_ts.pwb_dekk_waarde_vv_sl, v_fonds_munt_notatie);

         if i_TRKW_aktief = 1
         then
            select w.wk_waarde_1,        w.wk_waarde_2
            into   v_tegen_waarde_cover, v_tegen_waarde_cover_vv
            from   werkbestand w
            where  w.wk_terminal    = i_terminalnummer
            and    w.wk_soort       = 'COVR'
            and    w.wk_categorie_1 = ' '
            and    w.wk_categorie_2 = 'Cover'
            and    w.wk_categorie_3 = substr(r_ts.tas_symbool,1,28)
            and    w.wk_categorie_4 = substr(v_fondsomschrijving,1,26)
            and    w.wk_datum_1     = '00000000';

            -- tegen_waarde_cover is negatief, dus door hier gewoon op te tellen
            -- ontstaat de juiste cover waarde!
            v_cover_in_rapp_val := v_cover_in_rapp_val + nvl(v_tegen_waarde_cover,0);
            v_cover_in_vv_sl    := v_cover_in_vv_sl    + nvl(v_tegen_waarde_cover_vv,0);
         end if;

         -- het berekende wegschrijven in het werkbestand, alleen als dat gewenst is of multi valuta van toepassing is
         if gv_detail_geg_aanmaken = 1 or gv_multi_valuta_spl = 1
         then
            merge into fiat_blocked_lending_value f
            using (select v_fonds_id                       instrument_id, 'Cover'                blocked_type,
                          r_ts.pwb_fonds_valuta            foreign_curr,  ' '                    account_nr,
                          to_date('1-1-0001','DD-MM-YYYY') starting_date, r_ts.tas_in_cover_used quantity,
                          v_cover_in_rapp_val              amount_repc,   v_cover_in_vv_sl       amount_fc_sl
                   from dual) u
                on (f.instrument_id  = u.instrument_id and
                    f.blocked_type   = u.blocked_type  and
                    f.foreign_curr   = u.foreign_curr  and
                    f.account_nr     = u.account_nr)
            when matched then
               update set f.quantity     = f.quantity + u.quantity,
                          f.amount_repc  = f.amount_repc + u.amount_repc,
                          f.amount_fc_sl = f.amount_fc_sl + u.amount_fc_sl
            when not matched then
               insert (f.instrument_id, f.blocked_type, f.foreign_curr, f.account_nr,
                       f.starting_date, f.quantity,     f.amount_repc,  f.amount_fc_sl)
               values (u.instrument_id, u.blocked_type, u.foreign_curr, u.account_nr,
                       u.starting_date, u.quantity,     u.amount_repc,  u.amount_fc_sl);
         
         end if;
      end if; -- einde in_cover_used > 0

      -- er zijn stukken in collateral gezet:
      if r_ts.tas_collateral_used > 0
      then
         v_collateral_in_rapp_val := round(r_ts.tas_collateral_used / r_ts.pwb_werk_aantal_port * r_ts.pwb_dekk_waarde_rapv, gv_rel_rapp_notatie);
         v_collateral_in_vv_sl    := round(r_ts.tas_collateral_used / r_ts.pwb_werk_aantal_port * r_ts.pwb_dekk_waarde_vv_sl, v_fonds_munt_notatie);

         -- het berekende wegschrijven in het werkbestand, alleen als dat gewenst is of als het multi valuta is
         if gv_detail_geg_aanmaken = 1 or gv_multi_valuta_spl = 1
         then
            merge into fiat_blocked_lending_value f
            using (select v_fonds_id                       instrument_id, 'Collateral'             blocked_type,
                          r_ts.pwb_fonds_valuta            foreign_curr,  ' '                      account_nr,
                          to_date('1-1-0001','DD-MM-YYYY') starting_date, r_ts.tas_collateral_used quantity,
                          v_collateral_in_rapp_val         amount_repc,   v_collateral_in_vv_sl    amount_fc_sl
                   from dual) u
               on (f.instrument_id  = u.instrument_id and
                   f.blocked_type   = u.blocked_type  and
                   f.foreign_curr   = u.foreign_curr  and
                   f.account_nr     = u.account_nr)
            when matched then
               update set f.quantity     = f.quantity + u.quantity,
                          f.amount_repc  = f.amount_repc + u.amount_repc,
                          f.amount_fc_sl = f.amount_fc_sl + u.amount_fc_sl
            when not matched then
               insert (f.instrument_id, f.blocked_type, f.foreign_curr, f.account_nr,
                       f.starting_date, f.quantity,     f.amount_repc,  f.amount_fc_sl)
               values (u.instrument_id, u.blocked_type, u.foreign_curr, u.account_nr,
                       u.starting_date, u.quantity,     u.amount_repc,  u.amount_fc_sl);
         end if;
      end if; -- einde collateral_used > 0

      -- totaal bijwerken:
      o_totaal_geblokkeerd := o_totaal_geblokkeerd + v_cover_in_rapp_val + v_collateral_in_rapp_val;
   end loop;
end dekking_geblokkeerd;
-- EINDE VAN DE PROCEDURE DEKKING_GEBLOKKEERD


-- DE CODE VOOR DE PROCEDURE GEBLOKKEERDE_STUKKEN:
-- in deze procedure wordt de totale dekkingswaarde bepaald van
-- alle geblokkeerde stukken voor de opgegeven relatie.
-- de waarde wordt omgerekend naar de rapportage valuta.
procedure geblokkeerde_stukken
(i_relatienr                in  clienten.cl_nummer%type
,o_dekkings_waarde          out aktuele_posities.ap_saldo_positie%type
)

is
   v_dekkings_wrde_fonds_rappv     positie_werkbestand.pwb_dekk_waarde_rapv%type;
   v_dekkings_wrde_fonds_vv        positie_werkbestand.pwb_dekk_waarde_vv_sl%type;

cursor bp is
   select g.bpos_fondssymbool,    g.bpos_aantal_nominaal, g.bpos_ingangsdatum,
          g.bpos_rekeningnr,
          b.be_oms_1,             b.be_muntsoort,         b.be_volgnummer,
          m.mu_notatie,
          p.pwb_werk_aantal_port, p.pwb_dekk_waarde_rapv, p.pwb_dekk_waarde_vv_sl
   from   geblokkeerde_positie g, beleggingsinstrument b, tabelgegevens t,
          muntsoorten m,          te_doorlopen_rek d,     positie_werkbestand p
   where  g.bpos_categorie      =  1
   and    g.bpos_relatienr      =  i_relatienr
   and    g.bpos_rekeningsoort  <= 999
   and    g.bpos_blokkeringsrt  <= 4999
   and    g.bpos_rekeningnr     = d.tdr_rekeningnr                         -- inner join!! op te_doorlopen_rek
   and    g.bpos_rekeningsoort  = d.tdr_rekeningsoort                      -- om op deze manier af te dwingen dat allen
   and    g.bpos_rekeningmuntsr = d.tdr_rekeningmunt                       -- door toegestane rekeningen wordt gelopen
   and    (g.bpos_vervaldatum   = '00000000'
           or
           g.bpos_vervaldatum   > to_char(sysdate,'yyyymmdd'))
   and    b.be_symbool          = g.bpos_fondssymbool
   and    b.be_optietype        = ' '
   and    b.be_expiratiedatum   = '00000000'
   and    b.be_exerciseprijs    = 0
   and    b.be_muntsoort        = m.mu_code
   and    t.tb_soort            = 'BGED'
   and    t.tb_nummer           = g.bpos_blokkeringsrt
   and    t.tb_waarde           < 10
   and    p.pwb_relatie_nummer  = g.bpos_relatienr
   and    p.pwb_rekening_nummer = ' '
   and    p.pwb_rekening_soort  = 0
   and    p.pwb_symbool         = g.bpos_fondssymbool
   and    p.pwb_optietype       = ' '
   and    p.pwb_expiratiedatum  = '00000000'
   and    p.pwb_exerciseprijs   = 0;


begin

   o_dekkings_waarde := 0;

   for r_bp in bp
   loop
      -- hier door de geblokkeerde fondsen heen
      -- berekenen van de dekkingswaarde voor de geblokkeerde positie.
      if r_bp.pwb_werk_aantal_port <> 0
      then
         v_dekkings_wrde_fonds_rappv := round(r_bp.bpos_aantal_nominaal / r_bp.pwb_werk_aantal_port * r_bp.pwb_dekk_waarde_rapv, gv_rel_rapp_notatie);
         v_dekkings_wrde_fonds_vv    := round(r_bp.bpos_aantal_nominaal / r_bp.pwb_werk_aantal_port * r_bp.pwb_dekk_waarde_vv_sl, r_bp.mu_notatie);
      else
         v_dekkings_wrde_fonds_rappv := 0;
         v_dekkings_wrde_fonds_vv    := 0;
      end if;

      -- gevens wegschrijven voor detailgegevens op het scherm:
      merge into fiat_blocked_lending_value f                       
      using (select r_bp.be_volgnummer               instrument_id, 'Geblokkeerd'             blocked_type,
                    r_bp.be_muntsoort                foreign_curr,  r_bp.bpos_rekeningnr      account_nr,
                    to_date('1-1-0001','DD-MM-YYYY') starting_date, r_bp.bpos_aantal_nominaal quantity,
                    v_dekkings_wrde_fonds_rappv      amount_repc,   v_dekkings_wrde_fonds_vv  amount_fc_sl
             from dual) u
         on (f.instrument_id  = u.instrument_id and
             f.blocked_type   = u.blocked_type  and
             f.foreign_curr   = u.foreign_curr  and
             f.account_nr     = u.account_nr)
      when matched then
         update set f.quantity     = f.quantity + u.quantity,
                    f.amount_repc  = f.amount_repc + u.amount_repc,
                    f.amount_fc_sl = f.amount_fc_sl + u.amount_fc_sl
      when not matched then
         insert (f.instrument_id, f.blocked_type, f.foreign_curr, f.account_nr,
                 f.starting_date, f.quantity,     f.amount_repc,  f.amount_fc_sl)
         values (u.instrument_id, u.blocked_type, u.foreign_curr, u.account_nr,
                 u.starting_date, u.quantity,     u.amount_repc,  u.amount_fc_sl); 
      
      o_dekkings_waarde := o_dekkings_waarde + v_dekkings_wrde_fonds_rappv;
   end loop;

end geblokkeerde_stukken;
-- EINDE VAN DE PROCEDURE GEBLOKKEERDE_STUKKEN


-- DE CODE VOOR DE PROCEDURE ON_LINE_DOSSIER_BEREKENING:
-- Procedure voor het bepalen van de waarde van de garanties en obligo voor de opgegeven relatie.
procedure on_line_dossier_berekening
(i_relatienr               in   clienten.cl_nummer%type
,i_te_berekenen_deel       in   varchar2
,o_garanties               out  on_line_dossier.onld_bedrag%type
,o_obligo                  out  on_line_dossier.onld_bedrag%type
,o_closing_result          out  obligo_verplichting.obve_obligo_bedrag%type
)


-- inkomende parameters zijn: i_relatienr    = Relatienummer
--                            i_rapp_valuta  = Rapportagevaluta
--                            i_rapp_recip   = Reciproke van de rapportagevaluta
--                            i_rapp_factor  = Factor van de rapportagevaluta
--                            i_rapp_biedk   = Biedkoers van de rapportagevaluta
--                            i_rapp_laatk   = Laatkoers van de rapportagevaluta
--                            i_rapp_notatie = Notatie van de rapportagevaluta
-- uitgaande parameters zijn: o_garanties    = Een optelling (omgerekend) van alle klasse 47 en 54 bedragen
--                            o_obligo       = Een optelling (omgerekend) van alle klasse 42, 44, 46, 52 en 56 bedragen

is
   v_bedrag_omgerekend     on_line_dossier.onld_bedrag%type            default 0;
   v_obligo_bedrag         obligo_verplichting.obve_obligo_bedrag%type default 0;
   v_obligo_reken          on_line_dossier.onld_bedrag%type            default 0;
   v_garanties_reken       on_line_dossier.onld_bedrag%type            default 0;
   v_closing_reken         obligo_verplichting.obve_obligo_bedrag%type default 0;
   v_numerieke_tijd        number(8)                                   default 0;
   
   v_valuta_biedkoers      muntsoorten.mu_biedkoers%type;
   v_valuta_middenkoers    muntsoorten.mu_middenkoers%type;
   v_valuta_laatkoers      muntsoorten.mu_laatkoers%type;
   v_valuta_notatie        muntsoorten.mu_notatie%type;
   v_valuta_factor         muntsoorten.mu_factor%type;
   v_valuta_reciproke      muntsoorten.mu_reciproke%type;

begin

   -- Het on line dossier gedeelte:
   declare

   cursor ol is
      select   decode(o.onld_valuta,' ',gv_basis_valuta,o.onld_valuta) muntsoort_onld,
               o.onld_vervaldatum, o.onld_ontvangstdatum, o.onld_bedrag,
               o.onld_klasse,      o.onld_id_nummer
      from     on_line_dossier o
      where    o.onld_relatienummer      = i_relatienr
      and      o.onld_klasse             in (42,44,46,47,52,54,56)
      and      o.onld_ontvangstdatum     between '00010101' and to_char(SYSDATE,'yyyymmdd')
      and      (o.onld_vervaldatum       = '00000000' or o.onld_vervaldatum >= to_char(SYSDATE,'yyyymmdd'))
      and      o.onld_productnummer      = gv_productnummer
      and      o.onld_product_volgnummer = gv_productvolgnummer
      order by muntsoort_onld;

   begin

       for r_ol in ol
       loop
          -- bepalen te gebruiken muntkoersen en andere gegevens
          FIAT_ALGEMEEN.valutagegevens_bepalen (r_ol.muntsoort_onld,     gv_relatie_pr_id,   gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                                gv_bank2mrktqchangedate, gv_debuggen,        gv_debug_user,     v_valuta_biedkoers,
                                                v_valuta_middenkoers,    v_valuta_laatkoers, v_valuta_factor,   v_valuta_reciproke,
                                                v_valuta_notatie);

          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'in package FIAT_BEDRAG_BEPALING, on_line_dossier klasse 54, etc:');
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'vervaldatum : '||r_ol.onld_vervaldatum);
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'ontvangstdatum : '||r_ol.onld_ontvangstdatum||' ; bedrag : '||to_char(r_ol.onld_bedrag));
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'valuta :         '||r_ol.muntsoort_onld||' ; biedkoers : '||to_char(v_valuta_biedkoers));
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'middenkoers :    '||to_char(v_valuta_middenkoers)||' ; laatkoers : '||to_char(v_valuta_laatkoers));
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'muntnotatie :    '||to_char(v_valuta_notatie)||' ; muntfactor : '||to_char(v_valuta_factor));
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'reciproke :      '||to_char(v_valuta_reciproke));
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'  ');
          end if;
          
          -- teken van het bedrag goed zetten om ook goed te kunnen omrekenen naar de rapportage valuta mocht dat moeten
          if r_ol.onld_klasse in (47,54)
          then
             v_obligo_bedrag := r_ol.onld_bedrag;
          else
             v_obligo_bedrag := -1 * r_ol.onld_bedrag;
          end if;

          v_bedrag_omgerekend := 0;

          if r_ol.muntsoort_onld = gv_rel_rapp_valuta
          then
                v_bedrag_omgerekend := v_obligo_bedrag;
          else
                select FIAT_ALGEMEEN.gld_omrekenen_bedrag_vv(v_obligo_bedrag,       v_valuta_reciproke,    v_valuta_factor,    v_valuta_biedkoers,
                                                             v_valuta_laatkoers,    gv_rel_rapp_reciproke, gv_rel_rapp_factor , gv_rel_rapp_biedkoers,
                                                             gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
                into   v_bedrag_omgerekend
                from   dual;
          end if;

          -- Optellen bij de juiste variabelen en bijhouden van de gegevens in het werkbestand
          if r_ol.onld_klasse in (47,54)
          then
             -- hypotheken en garanties ontvangen
             v_garanties_reken := v_garanties_reken + v_bedrag_omgerekend;
             
             -- Opslaan als dat gewenst is of als het multi currency betreft..
             if gv_detail_geg_aanmaken = 1 or gv_multi_valuta_spl = 1
             then
                insert into fiat_obligo_rec_coll f
                (f.purpose_type,  f.class_type,        f.foreign_curr,      f.internal_id,
                 f.book_date,     
                 f.expiration_date,                      
                 f.amount_fc,     f.amount_repc)
                values
                ('GARN',          r_ol.onld_klasse,    r_ol.muntsoort_onld, r_ol.onld_id_nummer,
                 to_date('1-1-0001','DD-MM-YYYY'),
                 case when r_ol.onld_vervaldatum = '00000000' then to_date('1-1-0001','DD-MM-YYYY') else to_date(r_ol.onld_vervaldatum,'YYYYMMDD') end,
                 v_obligo_bedrag, v_bedrag_omgerekend);
             end if;
          else
             -- overige gegevens.
             v_obligo_reken   := v_obligo_reken + v_bedrag_omgerekend;

             insert into fiat_obligo_rec_coll f 
             (f.purpose_type,  f.class_type,          f.foreign_curr,      f.internal_id,
              f.book_date,     
              f.expiration_date,                         
              f.amount_fc,     f.amount_repc)
             values
             ('OBGO',          r_ol.onld_klasse,      r_ol.muntsoort_onld, r_ol.onld_id_nummer,
              to_date('1-1-0001','DD-MM-YYYY'),      
              case when r_ol.onld_vervaldatum = '00000000' then to_date('1-1-0001','DD-MM-YYYY') else to_date(r_ol.onld_vervaldatum,'YYYYMMDD') end, 
              v_obligo_bedrag, v_bedrag_omgerekend);
          end if;

       end loop;   -- end loop van online dossier
   end;

   -- het obligo gedeelte:
   declare

   cursor og is
       select o.obve_obligo_soort, o.obve_obligo_bedrag, o.obve_valuta,  o.obve_boekdatum,
              o.obve_boektijd
       from   obligo_verplichting o
       where  o.obve_relatienr          = i_relatienr
       and   (o.obve_obligo_soort     = 400 and i_te_berekenen_deel <> 'S'                
              or
              o.obve_obligo_soort     between 9001 and 9999) 
       and    o.obve_productnummer      = gv_productnummer
       and    o.obve_product_volgnummer = gv_productvolgnummer
       and    o.obve_obligo_bedrag      <> 0;

   begin
       for r_og in og
       loop
          -- bepalen te gebruiken muntkoersen en andere gegevens
          FIAT_ALGEMEEN.valutagegevens_bepalen (r_og.obve_valuta,        gv_relatie_pr_id,   gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                                gv_bank2mrktqchangedate, gv_debuggen,        gv_debug_user,     v_valuta_biedkoers,
                                                v_valuta_middenkoers,    v_valuta_laatkoers, v_valuta_factor,   v_valuta_reciproke,
                                                v_valuta_notatie);
           
          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'in package FIAT_BEDRAG_BEPALING, procedure onbligo verplichting gedeelte');
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'klasse :         '||to_char(r_og.obve_obligo_soort));
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'bedrag :         '||to_char(r_og.obve_obligo_bedrag));
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'valuta :         '||r_og.obve_valuta||' ; biedkoers : '||to_char(v_valuta_biedkoers));
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'middenkoers :    '||to_char(v_valuta_middenkoers)||' ; laatkoers : '||to_char(v_valuta_laatkoers));
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'muntnotatie :    '||to_char(v_valuta_notatie)||' ; muntfactor : '||to_char(v_valuta_factor));
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'reciproke :      '||to_char(v_valuta_reciproke));
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'boekdatum :      '||r_og.obve_boekdatum||' ; boektijd : '||r_og.obve_boektijd);
             FIAT_ALGEMEEN.fiat_debug(gv_debug_user,'  ');
          end if;

          v_numerieke_tijd    := to_number(to_char(to_date(r_og.obve_boektijd,'HH24MISS'),'SSSSS'));

          -- teken van het bedrag goed zetten om ook goed te kunnen omrekenen naar de rapportage valuta mocht dat moeten
          if r_og.obve_obligo_soort = 400
          then
             v_obligo_bedrag := r_og.obve_obligo_bedrag;
          else
             v_obligo_bedrag := -1 * r_og.obve_obligo_bedrag;
          end if;


          if r_og.obve_valuta  = gv_rel_rapp_valuta
          then
             v_bedrag_omgerekend := v_obligo_bedrag;
          else
             select FIAT_ALGEMEEN.gld_omrekenen_bedrag_vv(v_obligo_bedrag,   v_valuta_reciproke,    v_valuta_factor,    v_valuta_biedkoers,
                                                      v_valuta_laatkoers,    gv_rel_rapp_reciproke, gv_rel_rapp_factor, gv_rel_rapp_biedkoers,
                                                      gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
             into   v_bedrag_omgerekend
             from   dual;
          end if;

          -- wegschrijven in het werkbestand om later te kunnen tonen:
          merge into fiat_obligo_rec_coll f
          using (select 'OBGO'           purpose_type, r_og.obve_obligo_soort  class_type,
                        r_og.obve_valuta foreign_curr, 0                       internal_id,
                        case when r_og.obve_boekdatum = '00000000' 
                             then to_date('1-1-0001','DD-MM-YYYY') 
                             else to_date(r_og.obve_boekdatum||r_og.obve_boektijd,'YYYYMMDDHH24MISS') 
                        end                                                     book_date,
                        to_date('1-1-0001','DD-MM-YYYY')                        expiration_date,
                        v_obligo_bedrag   amount_fc,    v_bedrag_omgerekend     amount_repc
                from dual) u
             on (f.purpose_type           = u.purpose_type and
                 f.class_type             = u.class_type   and
                 f.foreign_curr           = u.foreign_curr and
                 f.book_date              = u.book_date)
          when matched then
             update set f.amount_fc       = u.amount_fc,
                        f.amount_repc     = u.amount_repc
          when not matched then
              insert (f.purpose_type, f.class_type,      f.foreign_curr, f.internal_id,
                      f.book_date,    f.expiration_date, f.amount_fc,    f.amount_repc)
              values (u.purpose_type, u.class_type,      u.foreign_curr, u.internal_id,
                      u.book_date,    u.expiration_date, u.amount_fc,    u.amount_repc);
                 
          -- Optellen bij de juiste variabelen
          if r_og.obve_obligo_soort <> 400
          then
             v_obligo_reken := v_obligo_reken + v_bedrag_omgerekend;
          else
             v_closing_reken := v_closing_reken + v_bedrag_omgerekend;
          end if;

       end loop;  -- end loop van de obligo gegevens
   end;

    o_garanties      := v_garanties_reken;
    o_obligo         := v_obligo_reken;
    o_closing_result := v_closing_reken;

end on_line_dossier_berekening;
-- EINDE VAN DE PROCEDURE ON_LINE_DOSSIER_BEREKENING


-- DE CODE VAN DE PROCEDURE LAATST_BEREKENDE_MARGIN
procedure laatst_berekende_margin
(i_relatienummer              in  clienten.cl_nummer%type
,o_laatst_berek_marging       out historisch_obligo.ho_optie%type
)

is
  v_hist_optie                historisch_obligo.ho_optie%type;
  v_hist_baisse               historisch_obligo.ho_baisse%type;
  v_hist_future               historisch_obligo.ho_future%type;
  v_hist_collateralused       historisch_obligo.ho_collateralused%type;

begin
  begin
     select h.ho_optie,           h.ho_baisse,    h.ho_future,
            h.ho_collateralused
     into   v_hist_optie,         v_hist_baisse,  v_hist_future,
            v_hist_collateralused
     from   historisch_obligo h
     where  h.ho_relatienr          = i_relatienummer
     and    h.ho_datum              = to_char(SYSDATE,'yyyymmdd')
     and    h.ho_herkomst           = 0
     and    h.ho_productnummer      = gv_productnummer
     and    h.ho_product_volgnummer = gv_productvolgnummer;
  exception
     when no_data_found
     then
        v_hist_optie          := 0;
        v_hist_baisse         := 0;
        v_hist_future         := 0;
        v_hist_collateralused := 0;
  end;

  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'In FIAT_ALGEMEEN.laatst_berekende_margin');
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'ho optie  : '||to_char(v_hist_optie)||' ;  ho baisse : '||to_char(v_hist_baisse));
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'ho future : '||to_char(v_hist_future)||
                                                                    ' ; ho collateralused : '||to_char(v_hist_collateralused));
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
  end if;
  
  o_laatst_berek_marging := v_hist_optie + v_hist_baisse + v_hist_future + v_hist_collateralused;
end laatst_berekende_margin;
-- EINDE VAN DE PROCEDURE LAATST_BEREKENDE_MARGIN


-- DE CODE VOOR DE PROCEDURE VOORVALUTERING
procedure voorvalutering
(i_relatienummer        in  clienten.cl_nummer%type
,i_terminalnummer       in  werkbestand.wk_terminal%type
,o_voorvalutering       out fiattering_bedragen.fb_voorvalutering%type
)
is

  v_voorvalutering          fiattering_bedragen.fb_voorvalutering%type;

begin
  -- Hier de totaalrekenvariabele die in de procedure op 0 zetten
  v_voorvalutering := 0;

  -- de voorvalutering valt in twee delen uit een:
  -- Een FX poot
  -- Een niet doorgeboekte poot

  declare
    cursor fx is
       select f.fx_rel1_a_term_mntst, f.fx_rel1_v_term_mntst, f.fx_indicatie,
              f.fx_bedrag,            f.fx_bedrag_vv2,        f.fx_contractnummer
       from   fx_contracten f, te_doorlopen_rek t
       where  f.fx_rel1              = i_relatienummer
       and    f.fx_rel1_a_trm_rek    = t.tdr_rekeningnr
       and    f.fx_rel1_a_trm_reksrt = t.tdr_rekeningsoort
       and    f.fx_rel1_a_term_mntst = t.tdr_rekeningmunt
       and    f.fx_actueel           <= 2
       and    f.fx_einddatum         >= to_char(SYSDATE,'yyyymmdd')
       and    f.fx_spot              <> 1;   -- fx-spot contracten niet meenemen

    v_aankoop_biedkoers    muntsoorten.mu_biedkoers%type;
    v_aankoop_laatkoers    muntsoorten.mu_laatkoers%type;
    v_aankoop_factor       muntsoorten.mu_factor%type;
    v_aankoop_reciproke    muntsoorten.mu_reciproke%type;

    v_verkoop_biedkoers    muntsoorten.mu_biedkoers%type;
    v_verkoop_laatkoers    muntsoorten.mu_laatkoers%type;
    v_verkoop_factor       muntsoorten.mu_factor%type;
    v_verkoop_reciproke    muntsoorten.mu_reciproke%type;

    v_bedrag_fx            fx_contracten.fx_bedrag%type              := 0;
    v_contracten_meenemen  number(1);
    v_dummy_nummer         number(1);

  begin
    for r_fx in fx
    loop
       -- eerst achterhalen of er een transactie bestaat en of die al is doorgeboekt
       -- iets andere constructie dan uit prog 160.11.1
       v_contracten_meenemen := 0;
       declare
          cursor tr is
             select t.tr_transnummer
             from   transakties t
             where  t.tr_fx_dep_contractnr = r_fx.fx_contractnummer
             and    t.tr_herkomst_code_tr  between 'FXCO' and 'FXCS';
       begin
          -- voor ieder gevonden transactie moet nagegaan worden of de transacties doorgeboekt zijn:
          for r_tr in tr
          loop
            if r_tr.tr_transnummer <> 0
            then
               v_contracten_meenemen := 1;
            end if;
          end loop;
       end;

       if gv_debuggen = 1
       then
          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'In FIAT_BEDRAG_BEPALING.voorvalutering:');
          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Fx contractnummer : '||to_char(r_fx.fx_contractnummer)||' ; Fx badrag : '||to_char(r_fx.fx_bedrag));
          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Fx bedrag vv2     : '||to_char(r_fx.fx_bedrag_vv2)||' ; Fx indicatie : '||r_fx.fx_indicatie);
          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'contracten meenemen : '||to_char(v_contracten_meenemen));
       end if;

       -- Pas doorgaan als de contracten meegenomen moeten worden:
       if v_contracten_meenemen = 1
       then
          -- Aankoop valuta:
          if r_fx.fx_indicatie = 'TV V'
          then
             v_bedrag_fx := r_fx.fx_bedrag * -1;
          else
             v_bedrag_fx := r_fx.fx_bedrag;
          end if;
          -- eventueel nog omerekenen naar de relatierapportage muntsoort
          if gv_rel_rapp_valuta <> r_fx.fx_rel1_a_term_mntst
          then
             FIAT_ALGEMEEN.valutagegevens_bepalen (r_fx.fx_rel1_a_term_mntst, gv_relatie_pr_id,    gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                                   gv_bank2mrktqchangedate,   gv_debuggen,         gv_debug_user,     v_aankoop_biedkoers,
                                                   v_dummy_nummer,            v_aankoop_laatkoers, v_aankoop_factor,  v_aankoop_reciproke,
                                                   v_dummy_nummer);
             
             select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_bedrag_fx, v_aankoop_reciproke, v_aankoop_factor,
                                                       v_aankoop_biedkoers, v_aankoop_laatkoers, gv_rel_rapp_reciproke,
                                                       gv_rel_rapp_factor, gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers,
                                                       gv_rel_rapp_notatie)
             into   v_bedrag_fx
             from   dual;
          end if;

          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'voor aankoop valuta');
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'omgerekend fx bedrag : '||to_char(v_bedrag_fx));
          end if;

          -- bedrag van de aankoopvaluta optellen bij de variabele
          v_voorvalutering := v_voorvalutering + v_bedrag_fx;
          
          if gv_multi_valuta_spl = 1
          then
             insert into werkbestand w
             (w.wk_terminal,    w.wk_soort,     w.wk_categorie_1,          w.wk_categorie_2,
              w.wk_categorie_3, w.wk_waarde_1,  w.wk_waarde_2)
             values
             (i_terminalnummer, 'VRVL',         r_fx.fx_rel1_a_term_mntst, to_char(r_fx.fx_contractnummer,'999999999'), 
              'aankoop',        r_fx.fx_bedrag, v_bedrag_fx);
          end if;
          
          -- Verkoop valuta:
          if r_fx.fx_indicatie = 'TV V'
          then
             v_bedrag_fx := r_fx.fx_bedrag_vv2 * -1;
          else
             v_bedrag_fx := r_fx.fx_bedrag_vv2;
          end if;
          -- eventueel nog omerekenen naar de relatierapportage muntsoort
          if gv_rel_rapp_valuta <> r_fx.fx_rel1_v_term_mntst
          then
             FIAT_ALGEMEEN.valutagegevens_bepalen (r_fx.fx_rel1_v_term_mntst, gv_relatie_pr_id,    gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                                   gv_bank2mrktqchangedate,   gv_debuggen,         gv_debug_user,     v_verkoop_biedkoers,
                                                   v_dummy_nummer,            v_verkoop_laatkoers, v_verkoop_factor,  v_verkoop_reciproke,
                                                   v_dummy_nummer);
             
             select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_bedrag_fx, v_verkoop_reciproke, v_verkoop_factor,
                                                       v_verkoop_biedkoers, v_verkoop_laatkoers, gv_rel_rapp_reciproke,
                                                       gv_rel_rapp_factor, gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers,
                                                       gv_rel_rapp_notatie)
             into   v_bedrag_fx
             from   dual;
          end if;

          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'voor verkoop valuta');
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'omgerekend fx bedrag : '||to_char(v_bedrag_fx));
          end if;

          -- bedrag van de verkoopvaluta aftrekken van de variabele:
          v_voorvalutering := v_voorvalutering - v_bedrag_fx;

          if gv_multi_valuta_spl = 1
          then
             insert into werkbestand w
             (w.wk_terminal,    w.wk_soort,          w.wk_categorie_1,          w.wk_categorie_2,
              w.wk_categorie_3, w.wk_waarde_1,       w.wk_waarde_2)
             values
             (i_terminalnummer, 'VRVL',              r_fx.fx_rel1_v_term_mntst, to_char(r_fx.fx_contractnummer,'999999999'), 
              'verkoop',        -1 * r_fx.fx_bedrag, -1 * v_bedrag_fx);
          end if;


       end if; -- einde v_transactienummer = 0
    end loop;  -- einde loop van fx-contracten
  end; -- FX contracten gedeelte


  -- Postiemutatie gedeelte
  declare
    cursor pg is
       select p.pmg_relatienr,        p.pmg_rekeningnr,       p.pmg_rekening_soort,
              p.pmg_rekening_munts,   p.pmg_mutatie_aantal,   t.tr_transnummer,
              t.tr_rel1,              t.tr_rel1_rek2,         t.tr_rel1_rek2_soort,
              t.tr_rel1_rek2_munts,   t.tr_rel1_munts_krs,    t.tr_rel1_munts_fac,
              t.tr_rel1_munts_rcp,
              t.tr_rel2,              t.tr_rel2_rek2,         t.tr_rel2_rek2_soort,
              t.tr_rel2_rek2_munts,   t.tr_rel2_munts_krs,    t.tr_rel2_munts_fac,
              t.tr_rel2_munts_rcp,
              t.tr_vruchtrelatie,     t.tr_vruchtrek_nr,      t.tr_vruchtrek_soort,
              t.tr_vruchtrek_muntsrt, t.tr_vruchtrek_mnt_krs, t.tr_vruchtrek_mnt_fac,
              t.tr_vruchtrek_mnt_rcp
       from   positiemutaties_geld p, transakties t, te_doorlopen_rek r
       where  p.pmg_relatienr      = i_relatienummer
       and    p.pmg_rekeningnr     = r.tdr_rekeningnr       -- innerjoin op deze manier
       and    p.pmg_rekening_soort = r.tdr_rekeningsoort    -- zodat alleen te doorlopen rekeningen
       and    p.pmg_rekening_munts = r.tdr_rekeningmunt     -- worden meegenomen
       and    p.pmg_rekening_soort between 1000 and 9999
       and    p.pmg_valutadatum    > to_char(SYSDATE,'yyyymmdd')
       and    p.pmg_transactienr   = t.tr_transnummer
       and    t.tr_invoernummer    = 0
       and    t.tr_terminalnummer  = 0;

       v_mutatie_bedrag      positiemutaties_geld.pmg_mutatie_aantal%type := 0;

  begin
    for r_pg in pg
    loop
       if gv_debuggen = 1
       then
          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'in FIAT_BEDRAG_BEPALING.voorvalutering positiemutatie gedeelte');
          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'relatienummer : '||to_char(r_pg.pmg_relatienr)||
                                                                                         ' ; rekeningnr : '||r_pg.pmg_rekeningnr);
          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'rekeningsoort : '||to_char(r_pg.pmg_rekening_soort)||
                                                                                 ' ; rekening munts : '||r_pg.pmg_rekening_munts);
          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'mutatieaantal : '||to_char(r_pg.pmg_mutatie_aantal));
       end if;

       -- als relatie 1:
       if     r_pg.pmg_relatienr      = r_pg.tr_rel1
          and r_pg.pmg_rekeningnr     = r_pg.tr_rel1_rek2
          and r_pg.pmg_rekening_soort = r_pg.tr_rel1_rek2_soort
          and r_pg.pmg_rekening_munts = r_pg.tr_rel1_rek2_munts
       then
          v_mutatie_bedrag := r_pg.pmg_mutatie_aantal;
          -- als de rekeningmuntsoort ongelijk is aan de rapportage valuta dan omrekenen naar rapportage valuta
          if r_pg.pmg_rekening_munts <> gv_rel_rapp_valuta
          then
             select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_mutatie_bedrag, r_pg.tr_rel1_munts_rcp , r_pg.tr_rel1_munts_fac ,
                                                       r_pg.tr_rel1_munts_krs, r_pg.tr_rel1_munts_krs, gv_rel_rapp_reciproke,
                                                       gv_rel_rapp_factor, gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers,
                                                       gv_rel_rapp_notatie)
             into   v_mutatie_bedrag
             from   dual;
          end if;
          -- als laatste bedrag optellen bij v_voorvalutering:
          v_voorvalutering := v_voorvalutering + v_mutatie_bedrag;

          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'als relatie 1:');
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'mutatiebedrag : '||to_char(v_mutatie_bedrag)||
                                                      ' ; voorvalutering : '||to_char(v_voorvalutering));
          end if;

          if gv_multi_valuta_spl = 1
          then
             insert into werkbestand w
             (w.wk_terminal,    w.wk_soort,              w.wk_categorie_1,        w.wk_categorie_2, 
             w.wk_categorie_3,  w.wk_waarde_1,           w.wk_waarde_2)
             values
             (i_terminalnummer, 'VRVL',                  r_pg.pmg_rekening_munts, to_char(r_pg.tr_transnummer,'999999999'), 
              'relatie 1',      r_pg.pmg_mutatie_aantal, v_mutatie_bedrag);
          end if;
       end if;

       -- als relatie 2:
       if     r_pg.pmg_relatienr      = r_pg.tr_rel2
          and r_pg.pmg_rekeningnr     = r_pg.tr_rel2_rek2
          and r_pg.pmg_rekening_soort = r_pg.tr_rel2_rek2_soort
          and r_pg.pmg_rekening_munts = r_pg.tr_rel2_rek2_munts
       then
          v_mutatie_bedrag := r_pg.pmg_mutatie_aantal;
          -- als de rekeningmuntsoort ongelijk is aan de rapportage valuta dan omrekenen naar rapportage valuta
          if r_pg.pmg_rekening_munts <> gv_rel_rapp_valuta
          then
             select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_mutatie_bedrag, r_pg.tr_rel2_munts_rcp , r_pg.tr_rel2_munts_fac ,
                                                       r_pg.tr_rel2_munts_krs, r_pg.tr_rel2_munts_krs, gv_rel_rapp_reciproke,
                                                       gv_rel_rapp_factor, gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers,
                                                       gv_rel_rapp_notatie)
             into   v_mutatie_bedrag
             from   dual;
          end if;
          -- als laatste bedrag optellen bij v_voorvalutering:
          v_voorvalutering := v_voorvalutering + v_mutatie_bedrag;

          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'als relatie 2:');
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'mutatiebedrag : '||to_char(v_mutatie_bedrag)||
                                                      ' ; voorvalutering : '||to_char(v_voorvalutering));
          end if;

          if gv_multi_valuta_spl = 1
          then
             insert into werkbestand w
             (w.wk_terminal,    w.wk_soort,              w.wk_categorie_1,        w.wk_categorie_2, 
             w.wk_categorie_3,  w.wk_waarde_1,           w.wk_waarde_2)
             values
             (i_terminalnummer, 'VRVL',                  r_pg.pmg_rekening_munts, to_char(r_pg.tr_transnummer,'999999999'), 
              'relatie 2',      r_pg.pmg_mutatie_aantal, v_mutatie_bedrag);
          end if;
       end if;

       -- als vruchtrelatie:
       if     r_pg.pmg_relatienr      = r_pg.tr_vruchtrelatie
          and r_pg.pmg_rekeningnr     = r_pg.tr_vruchtrek_nr
          and r_pg.pmg_rekening_soort = r_pg.tr_vruchtrek_soort
          and r_pg.pmg_rekening_munts = r_pg.tr_vruchtrek_muntsrt
       then
          v_mutatie_bedrag := r_pg.pmg_mutatie_aantal;
          -- als de rekeningmuntsoort ongelijk is aan de rapportage valuta dan omrekenen naar rapportage valuta
          if r_pg.pmg_rekening_munts <> gv_rel_rapp_valuta
          then
             select FIAT_ALGEMEEN.omrekenen_bedrag_vv (v_mutatie_bedrag, r_pg.tr_vruchtrek_mnt_rcp ,
                                                       r_pg.tr_vruchtrek_mnt_fac, r_pg.tr_vruchtrek_mnt_krs,
                                                       r_pg.tr_vruchtrek_mnt_krs, gv_rel_rapp_reciproke,
                                                       gv_rel_rapp_factor, gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers,
                                                       gv_rel_rapp_notatie)
             into   v_mutatie_bedrag
             from   dual;
          end if;
          -- als laatste bedrag optellen bij v_voorvalutering:
          v_voorvalutering := v_voorvalutering + v_mutatie_bedrag;

          if gv_debuggen = 1
          then
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'als vruchtrelatie:');
             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'mutatiebedrag : '||to_char(v_mutatie_bedrag)||
                                                      ' ; voorvalutering : '||to_char(v_voorvalutering));
          end if;
          
          if gv_multi_valuta_spl = 1
          then
             insert into werkbestand w
             (w.wk_terminal,    w.wk_soort,              w.wk_categorie_1,        w.wk_categorie_2, 
             w.wk_categorie_3,  w.wk_waarde_1,           w.wk_waarde_2)
             values
             (i_terminalnummer, 'VRVL',                  r_pg.pmg_rekening_munts, to_char(r_pg.tr_transnummer,'999999999'), 
              'vruchtrelatie',  r_pg.pmg_mutatie_aantal, v_mutatie_bedrag);
          end if;

       end if;

    end loop; -- einde positie mutatie loop
  end;


  o_voorvalutering := v_voorvalutering;

  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'einde voorvalutering:');
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'totaal bedrag voorvalutering : '||to_char(v_voorvalutering));
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
  end if;

end voorvalutering;
-- EINDE VAN DE PROCEDURE VOORVALUTERING


-- DE CODE VOOR DE PROCEDURE LOPENDE_BELEGGINGSOPDRACHTEN
-- Deze procedure berekent de invloed van de volgende lopende beleggingsopdrachten op de bestedingsruimte
-- t.b.v. de fiattering van andere beleggingsopdrachten, orders of payment initiations.
-- Het betreft de volgende opdrachten:
-- Investeringen die wel gefiatteerd zijn, maar waarvan nog geen orders zijn gemaakt (status 15,40,42).
-- Het geld staat op de rekeneing, maar is nodig voor het uitvoeren van de beleggingsopdracht.
--
-- Onttrekkingen met externe overboekingen die al volledig zijn uitgevoerd (status=90),
-- maar waarvan het geld nog niet is overgeboekt. Het geld staat op de rekening,
-- maar moet nog worden overgeboekt naar de externe rekening.
--
-- Switch en Rebalance opdrachten waarvan alleen de verkoop tak is uitgevoerd
-- en de opbrengst daarvan nog op de rekening staat (status=60).
-- De opbrengst van de verkopen staat op de rekening, maar moet nog gebruikt worden voor de aankopen.
-- Historische beleggingsopdrachten (herkomst = BHAH) worden niet doorlopen
procedure lopende_beleggingsopdrachten
(i_relatienummer              in  clienten.cl_nummer%type
,i_terminalnummer             in  werkbestand.wk_terminal%type
,i_te_fiatteren_belegopdracht in  beleggingsopdracht_header.boh_opdrachtnummer%type
,i_eerst_verkoop_afhandelen   in  number
,o_tot_lopende_opdrachten_rv  out beleggingsopdracht_header.boh_bedrag%type
)
is

   v_waarde_lopende_opdracht_rv   beleggingsopdracht_header.boh_bedrag%type;
   v_waarde_tot_opdracht_vv       transakties.tr_notabedrag%type;
   v_waarde_tot_opdracht_rv       transakties.tr_notabedrag%type;
   v_kooporder_aanwezig           number(1);
   v_revisie_voorstelnummer       revisie_header.rvh_voorstelnummer%type;
   
   v_valuta_biedkoers             muntsoorten.mu_biedkoers%type;
   v_valuta_middenkoers           muntsoorten.mu_middenkoers%type;
   v_valuta_laatkoers             muntsoorten.mu_laatkoers%type;
   v_valuta_factor                muntsoorten.mu_factor%type;
   v_valuta_reciproke             muntsoorten.mu_reciproke%type;
   v_dummy_nummer                 number(1);

cursor bo is
   select h.boh_opdrachtnummer,    h.boh_bedrag,        h.boh_status,
          h.boh_geldbatchsoort,    h.boh_geldbatchcode, h.boh_aantal_of_bedrag,
          h.boh_geldrekening_munt, h.boh_opdrachttype,  h.boh_methode
   from   beleggingsopdracht_header h
   where  h.boh_relatie               =  i_relatienummer
   and    h.boh_product               =  gv_productnummer
   and    h.boh_product_volgnr        =  gv_productvolgnummer
   and    h.boh_opdrachtnummer        <> i_te_fiatteren_belegopdracht
   and    h.boh_opdrachtnummer        >= 1
   and    ((h.boh_opdrachttype        = 'INV'
            and
            h.boh_status              in (15,40,42))
           or
           (h.boh_opdrachttype        = 'REBA'
            and
            h.boh_methode             = 11
            and
            (h.boh_status              in (15,40,42,45)
             and
             i_eerst_verkoop_afhandelen <> 0       -- eerst verkoop afhandelen <> Nee
             or
             h.boh_status               < 90
             and
             i_eerst_verkoop_afhandelen = 0))      -- eerst verkoop afhandelen = Nee
           or
           (h.boh_opdrachttype         in ('SWTC','REBA')
            and
            h.boh_status               in (50,54,60))
          )
   and    h.boh_herkomst               <> 'BHAH';

cursor ta (p_opdrachtnummer number) is
   select t.tr_notabedrag,     t.tr_rel1_rek2_munts, t.tr_rel1_munts_krs,
          t.tr_rel1_munts_fac, t.tr_rel1_munts_rcp,  t.tr_volgnummer
   from   transakties t
   where  t.tr_opdrachtnummer = p_opdrachtnummer
   and    t.tr_indicatie      = 'V'
   and    t.tr_mut_gemaakt    = 'J'
   and    t.tr_transnummer    <> 0
   and    not exists (select 1 from tv_transactions_in_progress tv
                      where t.tr_volgnummer = tv.trip_tr_volgnummer);

cursor tap (p_opdrachtnummer number) is
   select t.tr_notabedrag,     t.tr_rel1_rek2_munts, t.tr_rel1_munts_krs,
          t.tr_rel1_munts_fac, t.tr_rel1_munts_rcp,  t.tr_volgnummer
   from   transakties t
   where  t.tr_opdrachtnummer = p_opdrachtnummer
   and    t.tr_indicatie      = 'K';


begin
  o_tot_lopende_opdrachten_rv := 0;

  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'begin lopende beleggingsopdrachten:');
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
  end if;

  for r_bo in bo
  loop
     
     v_waarde_lopende_opdracht_rv := 0;
     v_waarde_tot_opdracht_vv     := 0;
     v_waarde_tot_opdracht_rv     := 0;
     v_kooporder_aanwezig         := 0;
     
     -- Ophalen van de muntsoortkoersen en een aantal overige muntsoortgegevens
     FIAT_ALGEMEEN.valutagegevens_bepalen (r_bo.boh_geldrekening_munt, gv_relatie_pr_id,   gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                           gv_bank2mrktqchangedate,    gv_debuggen,        gv_debug_user,     v_valuta_biedkoers,
                                           v_valuta_middenkoers,       v_valuta_laatkoers, v_valuta_factor,   v_valuta_reciproke,
                                           v_dummy_nummer);
     
     -- Controle op het aanwezig zijn van kooporders
     if r_bo.boh_opdrachttype = 'REBA' and r_bo.boh_methode = 11 and r_bo.boh_status between 45 and 60 and i_eerst_verkoop_afhandelen <> 0
     then
        select r.rvh_voorstelnummer
        into   v_revisie_voorstelnummer
        from   revisie_header r
        where  r.rvh_opdrachtnummer = r_bo.boh_opdrachtnummer;

        begin
           select 1
           into   v_kooporder_aanwezig
           from   revisie_detail r
           where  r.rvd_relatienummer      = i_relatienummer
           and    r.rvd_productnummer      = gv_productnummer
           and    r.rvd_volgnr_per_product = gv_productvolgnummer
           and    r.rvd_voorstelnummer     = v_revisie_voorstelnummer
           and    r.rvd_transactiesoort    = 'K'
           and    r.rvd_status             = 60
           and    rownum                   <=1;
        exception
           when no_data_found
           then
              v_kooporder_aanwezig := 0;
        end;
     end if;

     -- Voor Investeringen of Onttrekkingen van bedrag:
     if r_bo.boh_opdrachttype = 'INV'
        or
        r_bo.boh_opdrachttype = 'REBA' and r_bo.boh_methode = 11 and v_kooporder_aanwezig = 0 and i_eerst_verkoop_afhandelen <> 0
        or
        r_bo.boh_opdrachttype = 'REBA' and r_bo.boh_methode = 11  and i_eerst_verkoop_afhandelen = 0
     then

        if r_bo.boh_geldrekening_munt = gv_rel_rapp_valuta
        then
           v_waarde_lopende_opdracht_rv := r_bo.boh_bedrag;
        else
           select FIAT_ALGEMEEN.omrekenen_bedrag_vv (r_bo.boh_bedrag, v_valuta_reciproke, v_valuta_factor, v_valuta_biedkoers,
                                                     v_valuta_laatkoers, gv_rel_rapp_reciproke, gv_rel_rapp_factor,
                                                     gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers, gv_rel_rapp_notatie)
           into   v_waarde_lopende_opdracht_rv
           from   dual;
        end if;

        o_tot_lopende_opdrachten_rv := o_tot_lopende_opdrachten_rv - v_waarde_lopende_opdracht_rv;
        -- vast houden voor het vastleggen in het werkbestand
        v_waarde_tot_opdracht_vv    := -1 * r_bo.boh_bedrag;
        v_waarde_tot_opdracht_rv    := -1 * v_waarde_lopende_opdracht_rv;
     
        if gv_debuggen = 1
        then
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Voor Investeringen of Onttrekkingen van bedrag');
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Beleggingsopdracht : '||to_char(r_bo.boh_opdrachtnummer)||' Bedrag opdracht : '||to_char(r_bo.boh_bedrag));
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Waarde lopende opdracht rv : '||to_char(v_waarde_lopende_opdracht_rv));
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Totaal waarde lopende opdrachten : '||to_char(o_tot_lopende_opdrachten_rv));
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
        end if;
     end if;

     -- Voor Onttrekkingen van aantallen, Switch of Rebalance: Opbrengsten van verkopen optellen:
     if r_bo.boh_opdrachttype in ('REBA','SWTC') and r_bo.boh_status not in (15,40,42)
        and
        not (r_bo.boh_opdrachttype = 'REBA' and r_bo.boh_methode = 11  and i_eerst_verkoop_afhandelen = 0)
     then
        for r_ta in ta (r_bo.boh_opdrachtnummer)
        loop
           if r_ta.tr_rel1_rek2_munts = gv_rel_rapp_valuta
           then
              v_waarde_lopende_opdracht_rv := r_ta.tr_notabedrag;
           else
              select FIAT_ALGEMEEN.omrekenen_bedrag_vv (r_ta.tr_notabedrag, r_ta.tr_rel1_munts_rcp, r_ta.tr_rel1_munts_fac,
                                                        r_ta.tr_rel1_munts_krs, r_ta.tr_rel1_munts_krs, gv_rel_rapp_reciproke,
                                                        gv_rel_rapp_factor, gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers,
                                                        gv_rel_rapp_notatie)
              into   v_waarde_lopende_opdracht_rv
              from   dual;
           end if;
           o_tot_lopende_opdrachten_rv := o_tot_lopende_opdrachten_rv + v_waarde_lopende_opdracht_rv;

           -- vast houden voor het vastleggen in het werkbestand per beleggingsopdracht
           v_waarde_tot_opdracht_vv    := v_waarde_tot_opdracht_vv + r_ta.tr_notabedrag;
           v_waarde_tot_opdracht_rv    := v_waarde_tot_opdracht_rv + v_waarde_lopende_opdracht_rv;

           -- wegschrijven in het werkbestand per transactie, alleen indien gewenst
           if gv_detail_geg_aanmaken = 1
           then
              insert into werkbestand w
              (w.wk_terminal,                               w.wk_soort,
               w.wk_categorie_1,                            w.wk_categorie_2,
               w.wk_categorie_3,                            w.wk_waarde_1,
               w.wk_waarde_2)
              values
              (i_terminalnummer,                            'BOTA',
               to_char(r_bo.boh_opdrachtnummer,'999999999'), to_char(r_ta.tr_volgnummer,'9999999999999999'),
               r_ta.tr_rel1_rek2_munts,                      r_ta.tr_notabedrag,
               v_waarde_lopende_opdracht_rv);
           end if;

           if gv_debuggen = 1
           then
              FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Voor Onttrekkingen van aantallen, Switch of Rebalance Opbrengsten van verkopen optellen');
              FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Beleggingsopdracht : '||to_char(r_bo.boh_opdrachtnummer)||' Bedrag opdracht : '||to_char(r_bo.boh_bedrag));
              FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Waarde lopende opdracht rv : '||to_char(v_waarde_lopende_opdracht_rv));
              FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Totaal waarde lopende opdrachten : '||to_char(o_tot_lopende_opdrachten_rv));
              FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
           end if;
        end loop;
     end if;

     -- Controleren of er al kooptransacties zijn. Dan daarvoor het openstaande bedrag corrigeren.
     if r_bo.boh_bedrag <> 0
     then
        for r_tap in tap (r_bo.boh_opdrachtnummer)
        loop
           if r_tap.tr_rel1_rek2_munts = gv_rel_rapp_valuta
           then
              v_waarde_lopende_opdracht_rv := r_tap.tr_notabedrag;
           else
              select FIAT_ALGEMEEN.omrekenen_bedrag_vv (r_tap.tr_notabedrag, r_tap.tr_rel1_munts_rcp, r_tap.tr_rel1_munts_fac,
                                                        r_tap.tr_rel1_munts_krs, r_tap.tr_rel1_munts_krs, gv_rel_rapp_reciproke,
                                                        gv_rel_rapp_factor, gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers,
                                                        gv_rel_rapp_notatie)
              into   v_waarde_lopende_opdracht_rv
              from   dual;
           end if;
           -- bedrag voor lopende opdracht aanpassen
           o_tot_lopende_opdrachten_rv := o_tot_lopende_opdrachten_rv + v_waarde_lopende_opdracht_rv;
           
           -- vasthouden voor het vastleggen in het werkbestand per beleggingsopdracht
           v_waarde_tot_opdracht_vv    := v_waarde_tot_opdracht_vv + r_tap.tr_notabedrag;
           v_waarde_tot_opdracht_rv    := v_waarde_tot_opdracht_rv + v_waarde_lopende_opdracht_rv;
                   
           -- wegschrijven in het werkbestand per transactie, alleen indien gewenst
           if gv_detail_geg_aanmaken = 1
           then
              insert into werkbestand w
              (w.wk_terminal,                               w.wk_soort,
               w.wk_categorie_1,                            w.wk_categorie_2,
               w.wk_categorie_3,                            w.wk_waarde_1,
               w.wk_waarde_2)
              values
              (i_terminalnummer,                            'BOTA',
               to_char(r_bo.boh_opdrachtnummer,'999999999'), to_char(r_tap.tr_volgnummer,'9999999999999999'),
               r_tap.tr_rel1_rek2_munts,                     r_tap.tr_notabedrag,
               v_waarde_lopende_opdracht_rv);
           end if;
           
           if gv_debuggen = 1
           then
              FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Controleren of er al kooptransacties zijn. Dan daarvoor het opstaande bedrag corrigeren');
              FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Beleggingsopdracht : '||to_char(r_bo.boh_opdrachtnummer)||' Bedrag opdracht : '||to_char(r_bo.boh_bedrag));
              FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Waarde koop transactie : '||to_char(v_waarde_lopende_opdracht_rv));
              FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Totaal waarde lopende opdrachten : '||to_char(o_tot_lopende_opdrachten_rv));
              FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
           end if;
        end loop;
     end if;
     
     -- als laatste de beleggingsopdracht wegschrijven in het werkbestand
     insert into fiat_current_inv_orders f  
     (f.inv_order_id,          f.inv_order_type,         f.foreign_curr,             f.quantity_or_amount,
      f.inv_order_status,      f.amount_fc,              f.amount_repc)
     values
     (r_bo.boh_opdrachtnummer, r_bo.boh_opdrachttype,    r_bo.boh_geldrekening_munt, r_bo.boh_aantal_of_bedrag,
      r_bo.boh_status,         v_waarde_tot_opdracht_vv, v_waarde_tot_opdracht_rv);
  end loop;

  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Einde lopende beleggingsopdrachten:');
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Bedrag lopende beleggingsopdracht : '||to_char(o_tot_lopende_opdrachten_rv));
     FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
  end if;


end lopende_beleggingsopdrachten;
-- EINDE VAN DE PROCEDURE LOPENDE_BELEGGINGSOPDRACHTEN


-- DE CODE VOOR DE FUNCTION VERSION
function Version
return varchar2
is

begin
      return gv_versie;
end version;
-- EINDE CODE FUNCTION VERSION

end FIAT_BEDRAG_BEPALING;
/
