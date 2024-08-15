create or replace package FIAT_MARGIN
is

/*------------------------------------------------------------------------------
Package     : FIAT_MARGIN
description : code voor de package FIAT_MARGIN waarbinnen de volgende procedures
              en functions aanwezig zijn:
              procedure  ma_start_margin_bereken
              function   version
------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';


-- procedure ma_start_margin_bereken
   procedure ma_start_margin_bereken
   (i_relatienr                  in     clienten.cl_nummer%type
   ,i_cl_margin                  in     clienten.cl_margin%type
   ,i_cl_margin_toeslag          in     producten.pr_toeslag_percentage%type
   ,i_terminalnummer             in     werkbestand.wk_terminal%type
   ,i_slot_of_laatste_koers      in     varchar2
   ,i_trekkingswaarde_actief     in     number
   ,i_minim_vermogens_eis_inst   in     number
   ,i_minim_vermogens_eis_bedr   in     tabelgegevens.tb_waarde%type
   ,i_runnummer                  in     temp_ap_werkbest_sessie.tas_runnummer%type
   ,i_pr_blokkeren_short_call    in     producten.pr_blokkeren_short_calls%type
   ,i_pr_blokkeren_short_put     in     producten.pr_blokkeren_short_puts%type
   ,i_pr_blokkeren_long_put      in     producten.pr_blokkeren_long_puts%type
   ,i_instellingen               in     varchar2
   ,o_minim_vermogens_eis_bedr   out    tabelgegevens.tb_waarde%type
   ,o_collateral                 out    temp_margin_wb_sessie.tms_collateral_bedrag%type
   ,o_margin_opties              out    temp_margin_wb_sessie.tms_margin_required%type
   ,o_margin_futures             out    temp_margin_wb_sessie.tms_margin_required%type
   ,o_margin_totaal              out    temp_margin_wb_sessie.tms_margin_required%type
   ,o_margin_baisse              out    positie_werkbestand.pwb_dekk_waarde_rapv%type
   );


-- function version
   function version
   return                      varchar2;

end FIAT_MARGIN;
/
create or replace package body FIAT_MARGIN
is

/*------------------------------------------------------------------------------
Package body : FIAT_MARGIN
description  : code voor de package body FIAT_MARGIN waarbinnen procedures
               en functions aanwezig zijn:
               procedure  ma_start_margin_bereken
               procedure  ma_margin_bereken
               procedure  ma_get_put_geblokkeerd
               procedure  ma_geblok_stuk_geld
               procedure  ma_kopieren_bestanden
               procedure  ma_call_margin
               procedure  ma_geblok_stuk_geld
               procedure  ma_put_margin
               procedure  ma_straddle_strangle
               procedure  ma_collateral
               procedure  ma_collateral_fonds_loop
               procedure  ma_registratie
               procedure  ma_tot_future_margin
               function   version
------------------------------------------------------------------------------*/

-- globale variabelen (dus te gebruiken over alle procedures nadat de waarden zijn
-- bepaald in de eerst aanroepend procedure)
   gv_rel_rapp_valuta             relatie_fiattering.rf_rapp_muntsoort%type;
   gv_rel_rapp_biedkoers          relatie_fiattering.rf_rapp_biedkoers%type;
   gv_rel_rapp_laatkoers          relatie_fiattering.rf_rapp_laatkoers%type;
   gv_rel_rapp_factor             relatie_fiattering.rf_rapp_factor%type;
   gv_rel_rapp_reciproke          relatie_fiattering.rf_rapp_reciproke%type;
   gv_rel_rapp_notatie            relatie_fiattering.rf_rapp_notatie%type;
   gv_rel_onld_omschrijving       relatie_fiattering.rf_onld_omschrijving%type;
   gv_rel_onld_percentage         relatie_fiattering.rf_onld_percentage%type;
   gv_debuggen                    relatie_fiattering.rf_debug_j_n%type;
   gv_debug_user                  relatie_fiattering.rf_debug_user%type;

   gv_relatienummer               clienten.cl_nummer%type;
   gv_relatie_pr_id               producten.pr_id%type;
   gv_relatie_ppr_id              producten_per_relatie.ppr_id%type;
   gv_terminalnummer              werkbestand.wk_terminal%type;
   gv_runnummer                   temp_ap_werkbest_sessie.tas_runnummer%type;
   gv_debug_runnummer             temp_ap_werkbest_sessie.tas_runnummer%type;
   gv_cl_margin                   clienten.cl_margin%type;
   gv_cl_margin_toeslag           producten.pr_toeslag_percentage%type;
   gv_pr_blokkeren_short_call     producten.pr_blokkeren_short_calls%type;
   gv_pr_blokkeren_short_put      producten.pr_blokkeren_short_puts%type;
   gv_pr_blokkeren_long_put       producten.pr_blokkeren_long_puts%type;

   gv_bank2mrktqchangedate        muntsoorten.mu_update%type;
   gv_systspreadcodecategorie     valutaspread_cat_muntsoort.vscm_vsca_id%type;
   
   gv_dummy                       werkbestand.wk_waarde_1%type;

-- Declareren van de procedures die niet in de package header staan:

-- procedure ma_margin_bereken:
   procedure ma_margin_bereken
   (i_slot_of_laatste_koers      in     varchar2
   ,i_trekkingswaarde_actief     in     number
   ,i_instellingen               in     varchar2
   ,o_collateral                 out    temp_margin_wb_sessie.tms_collateral_bedrag%type
   ,o_margin_opties              out    temp_margin_wb_sessie.tms_margin_required%type
   ,o_margin_futures             out    temp_margin_wb_sessie.tms_margin_required%type
   );


-- procedure ma_get_put_geblokkeerd
   procedure ma_get_put_geblokkeerd
   (i_fonds_valuta               in    werkbestand.wk_categorie_1%type
   ,i_actie                      in    varchar2
   ,i_te_blokkeren_waarde        in    werkbestand.wk_waarde_1%type
   ,o_tot_geblokkeerd            out   werkbestand.wk_waarde_1%type
   ,o_vrij_om_te_blokkeren       out   werkbestand.wk_waarde_1%type
   );

-- procedure geblok_stuk_geld:
   procedure ma_geblok_stuk_geld
   (i_blokk_srt_margin           in     geblokkeerde_positie.bpos_blokkeringsrt%type
   );

-- procedure ma_kopieren_bestanden
   procedure ma_kopieren_bestanden;

-- procedure ma_call_margin:
   procedure ma_call_margin
   (i_minimum_spread_bedrag      in     tabelgegevens.tb_waarde%type
   ,i_toeslag_time_spread        in     tabelgegevens.tb_waarde%type
   ,i_optiemargin_toeslag        in     tabelgegevens.tb_waarde%type
   );

-- procedure ma_put_margin:
   procedure ma_put_margin
   (i_minimum_spread_bedrag      in     tabelgegevens.tb_waarde%type
   ,i_toeslag_time_spread        in     tabelgegevens.tb_waarde%type
   ,i_optiemargin_toeslag        in     tabelgegevens.tb_waarde%type
   );

-- procedure ma_straddle_strangle:
   procedure ma_straddle_strangle
   (i_optiemargin_toeslag        in     tabelgegevens.tb_waarde%type
   );

-- procedure ma_cross_margin
   procedure ma_cross_margin
   (i_optiemargin_toeslag        in     tabelgegevens.tb_waarde%type
   );

-- procedure ma_collateral:
   procedure ma_collateral;

-- procedure ma_collateral_fonds_loop:
   procedure ma_collateral_fonds_loop
   (i_be_bi_nummer_vanaf         in     beleggingsinstrument.be_bi_nummer%type
   ,i_be_bi_nummer_tm            in     beleggingsinstrument.be_bi_nummer%type
   ,i_ms_valuta                  in     temp_margin_wb_sessie.tms_valuta%type
   ,i_margin_bedrag              in     temp_margin_wb_sessie.tms_margin_required%type
   ,io_collateral_bedrag         in out temp_margin_wb_sessie.tms_collateral_bedrag%type
   );

-- procedure ma_registratie:
   procedure ma_registratie
   (i_slot_of_laatste_koers      in     varchar2
   ,i_trekkingswaarde_actief     in     number
   ,o_optie_margin               out    temp_margin_wb_sessie.tms_margin_required%type
   ,o_collateral_bedrag          out    temp_margin_wb_sessie.tms_collateral_bedrag%type
   ,o_future_margin              out    temp_margin_wb_sessie.tms_margin_required%type
   );

-- procedure ma_tot_future_margin:
   procedure ma_tot_future_margin
   (o_future_margin              out    temp_margin_wb_sessie.tms_margin_required%type
   );


-- DE CODE VOOR DE PROCEDURE MA_START_MARGIN_BEREKEEN
-- Deze procedure is het beginpunt van de margin berekening voor de opgegeven relatie.
-- Vergelijk Magic programma 173 MarginBerekening(Sessie) als start programma.
procedure ma_start_margin_bereken
(i_relatienr                     in     clienten.cl_nummer%type
,i_cl_margin                     in     clienten.cl_margin%type
,i_cl_margin_toeslag             in     producten.pr_toeslag_percentage%type
,i_terminalnummer                in     werkbestand.wk_terminal%type
,i_slot_of_laatste_koers         in     varchar2
,i_trekkingswaarde_actief        in     number
,i_minim_vermogens_eis_inst      in     number
,i_minim_vermogens_eis_bedr      in     tabelgegevens.tb_waarde%type
,i_runnummer                     in     temp_ap_werkbest_sessie.tas_runnummer%type
,i_pr_blokkeren_short_call       in     producten.pr_blokkeren_short_calls%type
,i_pr_blokkeren_short_put        in     producten.pr_blokkeren_short_puts%type
,i_pr_blokkeren_long_put         in     producten.pr_blokkeren_long_puts%type
,i_instellingen                  in     varchar2
,o_minim_vermogens_eis_bedr      out    tabelgegevens.tb_waarde%type
,o_collateral                    out    temp_margin_wb_sessie.tms_collateral_bedrag%type
,o_margin_opties                 out    temp_margin_wb_sessie.tms_margin_required%type
,o_margin_futures                out    temp_margin_wb_sessie.tms_margin_required%type
,o_margin_totaal                 out    temp_margin_wb_sessie.tms_margin_required%type
,o_margin_baisse                 out    positie_werkbestand.pwb_dekk_waarde_rapv%type
)

is

    v_optie_margin                      temp_margin_wb_sessie.tms_margin_required%type     := 0;
    v_future_margin                     temp_margin_wb_sessie.tms_margin_required%type     := 0;
    v_aantal_positie_fut                temp_margin_wb_sessie.tms_positie_future%type      := 0;
    v_aantal_positie_opt                temp_margin_wb_sessie.tms_saldo_positie%type       := 0;
    v_aantal_posities_opt_fut           temp_margin_wb_sessie.tms_saldo_positie%type       := 0;
    -- virtuals voor de instellingen die opgehaald worden
    v_op_te_halen_instel                varchar2(30);
    v_inst_type                         varchar2(1);
    v_instelling                        varchar2(100);

begin
    select r.rf_rapp_muntsoort,      r.rf_rapp_biedkoers,    r.rf_rapp_laatkoers,
           r.rf_rapp_factor,         r.rf_rapp_reciproke,    r.rf_rapp_notatie,
           r.rf_onld_omschrijving,   r.rf_onld_percentage,   r.rf_debug_j_n,
           r.rf_debug_user,          r.rf_pr_id,             r.rf_ppr_id
    into   gv_rel_rapp_valuta,       gv_rel_rapp_biedkoers,  gv_rel_rapp_laatkoers,
           gv_rel_rapp_factor,       gv_rel_rapp_reciproke,  gv_rel_rapp_notatie,
           gv_rel_onld_omschrijving, gv_rel_onld_percentage, gv_debuggen,
           gv_debug_user,            gv_relatie_pr_id,       gv_relatie_ppr_id
    from   relatie_fiattering r
    where  r.rf_relatie_nummer = i_relatienr;


    o_collateral              := 0;
    o_margin_opties           := 0;
    o_margin_futures          := 0;
    o_margin_totaal           := 0;
    o_margin_baisse           := 0;
    v_optie_margin            := 0;
    v_future_margin           := 0;
    v_aantal_posities_opt_fut := 0;

    gv_relatienummer           := i_relatienr;
    
    gv_terminalnummer          := i_terminalnummer;
    gv_runnummer               := i_runnummer;
    gv_cl_margin               := i_cl_margin;
    gv_cl_margin_toeslag       := i_cl_margin_toeslag;
    gv_pr_blokkeren_short_call := i_pr_blokkeren_short_call;
    gv_pr_blokkeren_short_put  := i_pr_blokkeren_short_put;
    gv_pr_blokkeren_long_put   := i_pr_blokkeren_long_put;
    
    if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug ( gv_debug_user,'Begin margin berekening FIAT_MARGIN.ma_start_margin_berekening');
       FIAT_ALGEMEEN.fiat_debug ( gv_debug_user,'gevraagd runnummer : '||i_runnummer);
       FIAT_ALGEMEEN.fiat_debug ( gv_debug_user,' ');
    end if;

    v_op_te_halen_instel := 'DebugRunnummers';
    v_inst_type          := 'N';
    select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
    into   v_instelling
    from   dual;
    gv_debug_runnummer := to_number(rtrim(ltrim(v_instelling)));
    
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
    
    -- omnummeren van het het debugrunnummer.
    -- Volgens het instellingenscherm (EuroPort+ beheer zijn de volgende keuzes mogelijk:
    -- 1 = Standaard marginberekening                   --> runnummer 0
    -- 2 = Margin effect berekeningen                   --> runnummer 1 of 2
    -- 9 = Geen margindebugging                         --> runnummer <> 0, 1 of 2

    if gv_debug_runnummer = 1
    then
       gv_debug_runnummer := 0;
    elsif gv_debug_runnummer = 2
    then
       if i_runnummer = 1 or i_runnummer = 2
       then
          gv_debug_runnummer := i_runnummer;
       end if;
    elsif gv_debug_runnummer = 9
    then
       gv_debug_runnummer := gv_debug_runnummer;
    end if;

    if i_cl_margin > 0
    then
       -- als voor de klant is aangegeven dat er margin moet worden berekend dan dat hier doen
       ma_margin_bereken(i_slot_of_laatste_koers, i_trekkingswaarde_actief, i_instellingen, o_collateral, v_optie_margin, v_future_margin);
    else
       -- als voor de klant NIET is aangegeven dat er margin moet worden berekend, dan in ieder
       -- geval de initiele margin van futures bepalen (optellen)
       ma_tot_future_margin(v_future_margin);
    end if;

    -- Afrondende bepalingen:
    -- alleen voor runnummer 0 (is de gewonen margin berekening, overige runnummers zijn voor de bepaling van
    -- een effect op de positie/margin)
    if gv_runnummer = 0
    then
       -- bepalen van het v_aantal_posities_opt_fut voor de minimale vermogenseis:
       if  i_minim_vermogens_eis_inst = 0
       then
          v_aantal_posities_opt_fut     := 0;
          o_minim_vermogens_eis_bedr  := 0;
       else
          select sum(abs(t.tms_positie_future)), sum(abs(t.tms_saldo_positie))
          into   v_aantal_positie_fut,           v_aantal_positie_opt
          from   temp_margin_wb_sessie t
          where  t.tms_relatienr      = i_terminalnummer
          and    t.tms_runnnummer     = 0
          and    (t.tms_saldo_positie < 0 and t.tms_soort in ('CALL','PUT')
                  or
                  t.tms_positie_future <> 0 and t.tms_soort = 'FUT');
          
          v_aantal_posities_opt_fut := v_aantal_positie_fut + v_aantal_positie_opt;
       end if;
       -- Bij een instelling van 1, dan maximaal maar 1 contract in rekening brengen
       if i_minim_vermogens_eis_inst = 1 and v_aantal_posities_opt_fut > 1
       then
          v_aantal_posities_opt_fut := 1;
       end if;

       o_margin_opties  := v_optie_margin;
       o_margin_futures := v_future_margin;
       o_margin_totaal  := v_optie_margin + v_future_margin + v_aantal_posities_opt_fut * i_minim_vermogens_eis_bedr;

       -- pas hier kun je bepalen wat de nieuwe waarde voor o_minim_vermogens_eis_bedr wordt
       -- (na het berekenen van o_margin_totaal).
       if  i_minim_vermogens_eis_inst = 0 or i_minim_vermogens_eis_inst = 1 and v_aantal_posities_opt_fut = 1
       then
          o_minim_vermogens_eis_bedr := 0;
       end if;

       -- nog bepalen van het totaal van de baisse margin:
       select sum(p.pwb_dekk_waarde_rapv)
       into   o_margin_baisse
       from   positie_werkbestand p
       where  p.pwb_relatie_nummer   = i_relatienr
       and    p.pwb_rekening_soort   between 100 and 999
       and    p.pwb_optietype        = ' '
       and    p.pwb_expiratiedatum   = '00000000'
       and    p.pwb_exerciseprijs    = 0
       and    p.pwb_werk_aantal_port < 0;

    -- voor overige runnummers wel de totalen terugsturen:
    else
       o_margin_opties  := v_optie_margin;
       o_margin_futures := v_future_margin;
       o_margin_totaal  := v_optie_margin + v_future_margin;
    end if;
end ma_start_margin_bereken;
-- EINDE CODE PROCEDURE MA_START_MARGIN_BEREKEN


-- DE CODE VOOR DE PROCEDURE MA_MARGIN_BEREKEN
-- In deze procedure staan de verschillende aanroepen naar de verschillende onderdelen
-- waarin een marginberekening kan uit een vallen.
-- Verglijk programma 173 br-Opt Fut posities(Sessie) hoofdtaak.
procedure ma_margin_bereken
(i_slot_of_laatste_koers         in     varchar2
,i_trekkingswaarde_actief        in     number
,i_instellingen                  in     varchar2
,o_collateral                    out    temp_margin_wb_sessie.tms_collateral_bedrag%type
,o_margin_opties                 out    temp_margin_wb_sessie.tms_margin_required%type
,o_margin_futures                out    temp_margin_wb_sessie.tms_margin_required%type
)

is

   v_minim_spread_bedrag                tabelgegevens.tb_waarde%type                 := 0;
   v_time_spread_toeslag                tabelgegevens.tb_waarde%type                 := 0;
   v_optiemargin_toeslag                tabelgegevens.tb_waarde%type                 := 0;
   v_blokkeringssrt_margin              geblokkeerde_positie.bpos_blokkeringsrt%type := 0;
   -- virtuals voor de instellingen die opgehaald worden
   v_op_te_halen_instel                 varchar2(30);
   v_inst_type                          varchar2(1);
   v_instelling                         varchar2(100);

begin

   -- bepalen van een aantal constanten:
   v_op_te_halen_instel := 'MinSpreadBedr';
   v_inst_type          := 'N';
   select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
   into   v_instelling
   from   dual;
   v_minim_spread_bedrag := to_number(rtrim(ltrim(v_instelling)));

   v_op_te_halen_instel := 'OptieMarginToesl';
   v_inst_type          := 'N';
   select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
   into   v_instelling
   from   dual;
   v_optiemargin_toeslag := to_number(rtrim(ltrim(v_instelling)));

   v_op_te_halen_instel := 'TimeSpreadToesl';
   v_inst_type          := 'N';
   select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
   into   v_instelling
   from   dual;
   v_time_spread_toeslag := to_number(rtrim(ltrim(v_instelling)));

   v_op_te_halen_instel := 'BlokkSoortMargin';
   v_inst_type          := 'N';
   select FIAT_ALGEMEEN.instell_bepalen(i_instellingen, v_op_te_halen_instel, v_inst_type, gv_debuggen, gv_debug_user)
   into   v_instelling
   from   dual;
   v_blokkeringssrt_margin := to_number(rtrim(ltrim(v_instelling)));

   -- Als eerste de geblokkeerde stukken en geld, productfunctionaliteit die alleen bij runnummer 0
   -- uitgevoerd hoeft te worden
   if gv_runnummer = 0
   then
      if (gv_pr_blokkeren_long_put = 1 or gv_pr_blokkeren_short_call = 1 or gv_pr_blokkeren_short_put = 1)
      then
         ma_geblok_stuk_geld (v_blokkeringssrt_margin);
      end if;
      -- kopieren van de margingwerkbestanden naar runnummer 8 en 9. Dit nu pas doen zodat eventueel geblokkeerde posities
      -- ook meegekopieerd worden.
      ma_kopieren_bestanden;
   end if;

   -- Het CALL margin gedeelte:
   ma_call_margin(v_minim_spread_bedrag, v_time_spread_toeslag, v_optiemargin_toeslag);

   -- Het PUT margin gedeelte:
   ma_put_margin (v_minim_spread_bedrag, v_time_spread_toeslag, v_optiemargin_toeslag);

   -- Het STRADDLE/STRANGLE gedeelte:
   ma_straddle_strangle(v_optiemargin_toeslag);

   -- Het cross margin Call/Put gedeelte:
   ma_cross_margin(v_optiemargin_toeslag);

   -- Het COLLATERAL gedeelte, alleen als client instelling 3 of 4 is:
   if gv_cl_margin in (3,4)
   then
      ma_collateral;
   end if;

   -- Het registeren van de totalen:
   ma_registratie(i_slot_of_laatste_koers, i_trekkingswaarde_actief,
                  o_margin_opties, o_collateral, o_margin_futures);

end ma_margin_bereken;
-- EINDE CODE PROCEDURE MA_MARGIN_BEREKEN


-- DE CODE VOOR DE PROCEDURE MA_GET_PUT_GEBLOKKEERD
procedure ma_get_put_geblokkeerd
(i_fonds_valuta         in   werkbestand.wk_categorie_1%type
,i_actie                in   varchar2
,i_te_blokkeren_waarde  in   werkbestand.wk_waarde_1%type
,o_tot_geblokkeerd      out  werkbestand.wk_waarde_1%type
,o_vrij_om_te_blokkeren out  werkbestand.wk_waarde_1%type
)

is
  v_reeds_verbruikt        werkbestand.wk_waarde_2%type;
  v_aantal_geblokkeerd     werkbestand.wk_waarde_1%type;
  v_aantal_vrij_te_blok    werkbestand.wk_waarde_2%type;
begin
   -- Ophaal (Get) actie
   if i_actie = 'G'
   then
      begin
         select w.wk_waarde_1,        w.wk_waarde_2
         into   v_aantal_geblokkeerd, v_reeds_verbruikt
         from   werkbestand w
         where  w.wk_terminal = gv_terminalnummer
         and    w.wk_soort    = 'BOLW'
         and    w.wk_categorie_1 = i_fonds_valuta
         and    w.wk_categorie_2 = ' '
         and    w.wk_categorie_3 = ' '
         and    w.wk_categorie_4 = ' ';
      exception
         when no_data_found
         then
           v_aantal_geblokkeerd := 0;
           v_reeds_verbruikt    := 0;
      end;
      
      if v_aantal_geblokkeerd - v_reeds_verbruikt <= 0
      then
         v_aantal_vrij_te_blok := 0;
      else
         v_aantal_vrij_te_blok := v_aantal_geblokkeerd - v_reeds_verbruikt;
      end if;  

      -- eerst doorgeven hoeveel daadwerkelijk geblokkeerd is
      o_tot_geblokkeerd      := v_aantal_geblokkeerd;
      -- dan doorgeven hoeveel hiervan nog te gebruiken is voor blokkades
      o_vrij_om_te_blokkeren := v_aantal_vrij_te_blok;
      
   -- Wegschrijf (Put) actie
   elsif i_actie = 'P'
   then
      update werkbestand w
      set    w.wk_waarde_2 = w.wk_waarde_2 + i_te_blokkeren_waarde
      where  w.wk_terminal = gv_terminalnummer
      and    w.wk_soort    = 'BOLW'
      and    w.wk_categorie_1 = i_fonds_valuta
      and    w.wk_categorie_2 = ' '
      and    w.wk_categorie_3 = ' '
      and    w.wk_categorie_4 = ' ';
   end if;

end ma_get_put_geblokkeerd;

-- EINDE CODE PROCEDURE MA_GET_PUT_GEBLOKKEERD


-- DE CODE VOOR DE PROCEDURE GEBLOK_STUK_GELD
-- in deze procedure worden de geblokkeerde stukken en geld ivm marginverplichting bepaalt
-- en weggeschreven in werkbestanden
-- Vergelijk subtaak 2 van programma 173 br-Opt Fut posities(Sessie) in de standaard omgeving
procedure ma_geblok_stuk_geld
(i_blokk_srt_margin       in  geblokkeerde_positie.bpos_blokkeringsrt%type
)

is

begin
  -- eerste stap in het proces: Vullen van de initiele gegevens (wk_soort: BOLW) aan de hand van
  -- de geblokkeerde posities
  declare
    -- variabelen:
    v_symbool_of_munt       werkbestand.wk_categorie_1%type;

    -- Door de geblokkeerde stukken en geld heen. Door gebruik te maken van
    -- te_doorlopen_rek worden altijd de goede posities opgehaald.
    cursor bp is
       select g.bpos_fondssymbool,  g.bpos_aantal_nominaal, g.bpos_rekeningsoort,
              g.bpos_rekeningmuntsr
       from   geblokkeerde_positie g, te_doorlopen_rek t
       where  g.bpos_categorie      = 1
       and    g.bpos_relatienr      = gv_relatienummer
       and    g.bpos_rekeningsoort  >= 1
       and    g.bpos_blokkeringsrt  = i_blokk_srt_margin
       and    g.bpos_rekeningnr     = t.tdr_rekeningnr           -- inner join!! op te_doorlopen_rek
       and    g.bpos_rekeningsoort  = t.tdr_rekeningsoort        -- om op deze manier af te dwingen dat allen
       and    g.bpos_rekeningmuntsr = t.tdr_rekeningmunt         -- door toegestane rekeningen wordt gelopen
       order by g.bpos_rekeningmuntsr, g.bpos_fondssymbool;

  begin

    if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'In de eerste stap van procedure geblok_stuk_geld');
    end if;

    for r_bp in bp
    loop
      -- voor het makkelijk kunnen wegschrijven in het werkbestand de variabele zetten:
      if r_bp.bpos_rekeningsoort <1000
      then
         v_symbool_of_munt := r_bp.bpos_fondssymbool;
      else
         v_symbool_of_munt := r_bp.bpos_rekeningmuntsr;
      end if;

      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'symbool of munt : '||v_symbool_of_munt||' ; aantal of nominaal : '
                                                  ||to_char(r_bp.bpos_aantal_nominaal));
      end if;

      -- eerst proberen te updaten
      update werkbestand w
      set    w.wk_waarde_1    = w.wk_waarde_1 + r_bp.bpos_aantal_nominaal
      where  w.wk_terminal    = gv_terminalnummer
      and    w.wk_soort       = 'BOLW'
      and    w.wk_categorie_1 = v_symbool_of_munt
      and    w.wk_categorie_2 = ' '
      and    w.wk_categorie_3 = ' '
      and    w.wk_categorie_4 = ' ';
      -- Als de update niet lukt, dan een insert
      if sql%notfound
      then
         insert into werkbestand w
         (w.wk_terminal,              w.wk_soort,       w.wk_categorie_1,
          w.wk_categorie_2,           w.wk_categorie_3, w.wk_categorie_4,
          w.wk_waarde_1)
         values
         (gv_terminalnummer,          'BOLW',           v_symbool_of_munt,
          ' ',                        ' ',              ' ',
          r_bp.bpos_aantal_nominaal);
      end if;
    end loop;
  end;

  -- tweede stap: Het bepalen van de afname in margin verplichting door de geblokkeerde posities tegen de
  -- call en put posities aan te houden:
  declare
    v_beschikbare_geblok_stuk        werkbestand.wk_waarde_1%type                     := 0;
    v_beschikbare_geblok_geld        werkbestand.wk_waarde_1%type                     := 0;
    v_gebruikte_geblok_stuk          werkbestand.wk_waarde_1%type                     := 0;
    v_gebruikte_geblok_geld          werkbestand.wk_waarde_1%type                     := 0;
    v_te_dekken_aantal               werkbestand.wk_waarde_1%type                     := 0;
    v_beschikbaar_dek_aantal         werkbestand.wk_waarde_1%type                     := 0;
    v_gedekt_aantal                  werkbestand.wk_waarde_1%type                     := 0;
    v_nieuw_required_margin          temp_margin_wb_sessie.tms_margin_required%type   := 0;

    v_huidige_valuta                 muntsoorten.mu_code%type                         := ' ';
    v_huidig_refsymbool              beleggingsinstrument.be_referentiesymbool%type   := ' ';
        
    v_ow_is_mandje                   number(1);
    v_mandje_symb_volgnummer         beleggingsinstrument.be_volgnummer%type;
        
    
    cursor ms is
    select  t.tms_refsymbool,   t.tms_soort,                  t.tms_symbool,
            t.tms_exp_datum,    t.tms_exerciseprijs,          t.tms_saldo_positie,
            t.tms_blocksize,    t.tms_margin_required,        t.tms_valuta,
            t.tms_pricing_unit, t.rowid as onderhanden_rowid, b.be_bi_nummer
    from    temp_margin_wb_sessie t, beleggingsinstrument b
    where   t.tms_relatienr     = gv_terminalnummer
    and     t.tms_soort         in ('CALL','PUT')
    and     t.tms_runnnummer    = 0
    and     t.tms_symbool       = b.be_symbool
    and     t.tms_soort         = b.be_optietype
    and     t.tms_exp_datum     = b.be_expiratiedatum
    and     t.tms_exerciseprijs = b.be_exerciseprijs
    order by t.tms_valuta, t.tms_refsymbool, t.tms_soort;

  begin
     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'In de tweede stap van procedure geblok_stuk_geld');
     end if;

     for r_ms in ms
     loop
        if gv_debuggen = 1
        then
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Betreft optie:');
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Symbool        : '||r_ms.tms_symbool||' ; optietype    : '||r_ms.tms_soort);
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Expiratiedatum : '||r_ms.tms_exp_datum||' ; exerciseprijs : '||to_char(r_ms.tms_exerciseprijs));
           FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
        end if;
                
        -- Voor Long Call posities is het niet mogelijk om posities te blokkeren dus die hier overslaan
        if not(r_ms.tms_soort = 'CALL' and r_ms.tms_saldo_positie >= 0)
        then
           -- Bij wisseling van de valuta
           if v_huidige_valuta = ' ' or v_huidige_valuta <> r_ms.tms_valuta
           then
              -- als eerste de berekende gegevens wegschrijven
              if v_huidige_valuta <> ' ' and v_gebruikte_geblok_geld <> 0
              then
                 ma_get_put_geblokkeerd (v_huidige_valuta, 'P', v_gebruikte_geblok_geld, gv_dummy, gv_dummy);
              end if;
              -- als tweede nieuwe gegevens ophalen voor deze munt:
              v_huidige_valuta        := r_ms.tms_valuta;
              v_gebruikte_geblok_geld := 0;
              ma_get_put_geblokkeerd (v_huidige_valuta, 'G', gv_dummy, gv_dummy, v_beschikbare_geblok_geld);
              
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'huidige valuta :'||v_huidige_valuta||
                                                          ' ; beschikbaar geblok geld : '||to_char(v_beschikbare_geblok_geld));
                 FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
              end if;
           end if;
           
           -- Eerst bepalen of het referentiesymbool van de optie een mandje is
           select b.be_volgnummer
           into   v_mandje_symb_volgnummer
           from   beleggingsinstrument b
           where  b.be_symbool         = r_ms.tms_refsymbool
           and    b.be_optietype       = ' '
           and    b.be_expiratiedatum  = '00000000'
           and    b.be_exerciseprijs   = 0;                    
           
           begin
              select 1
              into   v_ow_is_mandje
              from   mandje_onderliggende_waarde m
              where  m.mnd_volgnummer = v_mandje_symb_volgnummer
              and    rownum           <= 1;                        -- Er hoeft maar maximaal 1 record opgehaald te worden
           exception
              when no_data_found
              then
                 v_ow_is_mandje := 0;
           end;
           
           -- Dit deel uitvoeren als de ow van de optie geen mandje is of als het een short put betreft
           if v_ow_is_mandje = 0  
              or
              r_ms.tms_soort = 'PUT' and r_ms.tms_saldo_positie < 0 and v_beschikbare_geblok_geld > 0 and gv_pr_blokkeren_short_put = 1
           then 
                      
              -- bij wisseling van het refsymbool:
              if v_huidig_refsymbool = ' ' or v_huidig_refsymbool <> r_ms.tms_refsymbool
              then
                 -- als eerste de berekende gegevens wegschrijven:
                 if v_huidig_refsymbool <> ' ' and v_gebruikte_geblok_stuk <> 0
                 then
                    ma_get_put_geblokkeerd (v_huidig_refsymbool, 'P', v_gebruikte_geblok_stuk, gv_dummy, gv_dummy);
                 end if;
                 -- als tweede nieuwe gegevens ophalen voor dit reffonds:
                 v_huidig_refsymbool     := r_ms.tms_refsymbool;
                 v_gebruikte_geblok_stuk := 0;
                 ma_get_put_geblokkeerd (v_huidig_refsymbool, 'G', gv_dummy, gv_dummy, v_beschikbare_geblok_stuk);
                 
                 if gv_debuggen = 1
                 then
                    FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'huidig refsymbool bij ow is geen mandje of optie is long put :'||v_huidig_refsymbool||
                                                             ' ; beschikbaar geblok stuk : '||to_char(v_beschikbare_geblok_stuk));
                    FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
                 end if;
              end if;
              
              -- per fonds resetten en setten van een aantal gegevens:
              v_gedekt_aantal         := 0;
              v_nieuw_required_margin := 0;
              
              if v_beschikbare_geblok_stuk > 0
              then
              -- blokkeren short call:
              if r_ms.tms_soort = 'CALL' and r_ms.tms_saldo_positie < 0 and
                 gv_pr_blokkeren_short_call = 1 and r_ms.be_bi_nummer not between 3000 and 3099
              then
                 v_te_dekken_aantal       := abs(r_ms.tms_saldo_positie);
                 v_beschikbaar_dek_aantal := trunc((v_beschikbare_geblok_stuk - v_gebruikte_geblok_stuk)/
                                                  (r_ms.tms_blocksize * r_ms.tms_pricing_unit),0);
                 v_gedekt_aantal          := least(v_beschikbaar_dek_aantal, v_te_dekken_aantal);
                 v_gebruikte_geblok_stuk  := v_gebruikte_geblok_stuk +
                                             v_gedekt_aantal * r_ms.tms_blocksize * r_ms.tms_pricing_unit;
                 v_nieuw_required_margin  := (v_te_dekken_aantal - v_gedekt_aantal)/
                                             v_te_dekken_aantal * r_ms.tms_margin_required;
                 -- aanpassen van het temp_margin_wb_sessie record met de nieuwe gegevens:
                 update temp_margin_wb_sessie t
                 set    t.tms_prod_geblok_aantal = v_gedekt_aantal,
                        t.tms_margin_required    = v_nieuw_required_margin
                 where  t.rowid                  = r_ms.onderhanden_rowid;
                 
                 if gv_debuggen = 1
                 then
                    FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'in blokkeren short call');
                    FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'te dekken aantal : '||to_char(v_te_dekken_aantal)||
                                                             ' ; beschikbaar dek aantak : '||to_char(v_beschikbaar_dek_aantal));
                    FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'gedekt aantal : '|| to_char(v_gedekt_aantal)||
                                                             ' ; gebruikt geblok stuk : '||to_char(v_gebruikte_geblok_stuk));
                    FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'nieuw required margin : '||to_char(v_nieuw_required_margin));
                    FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
                 end if;
              end if;
              
              -- blokkeren long put:
              if r_ms.tms_soort = 'PUT' and r_ms.tms_saldo_positie > 0
                 and gv_pr_blokkeren_long_put = 1 and r_ms.be_bi_nummer not between 3000 and 3099
              then
                 v_te_dekken_aantal       := abs(r_ms.tms_saldo_positie);
                 v_beschikbaar_dek_aantal := trunc((v_beschikbare_geblok_stuk - v_gebruikte_geblok_stuk)/
                                                  (r_ms.tms_blocksize * r_ms.tms_pricing_unit),0);
                 v_gedekt_aantal          := least(v_beschikbaar_dek_aantal, v_te_dekken_aantal);
                 v_gebruikte_geblok_stuk  := v_gebruikte_geblok_stuk +
                                             v_gedekt_aantal * r_ms.tms_blocksize * r_ms.tms_pricing_unit;
                 -- voor een long positie is er geen margin requirement.....
                 -- aanpassen van het temp_margin_wb_sessie record met de nieuwe gegevens:
                 update temp_margin_wb_sessie t
                 set    t.tms_prod_geblok_aantal = v_gedekt_aantal
                 where  t.rowid                  = r_ms.onderhanden_rowid;
                 
                 if gv_debuggen = 1
                 then
                    FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'in blokkeren long put');
                    FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'te dekken aantal : '||to_char(v_te_dekken_aantal)||
                                                             ' ; beschikbaar dek aantak : '||to_char(v_beschikbaar_dek_aantal));
                    FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'gedekt aantal : '|| to_char(v_gedekt_aantal)||
                                                             ' ; gebruikt geblok stuk : '||to_char(v_gebruikte_geblok_stuk));
                    FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
                 end if;
              end if;
           end if;
           
           -- benodigd geblokkeerd geld:
           if r_ms.tms_soort = 'PUT' and r_ms.tms_saldo_positie < 0 and v_beschikbare_geblok_geld > 0
              and gv_pr_blokkeren_short_put = 1
           then
              v_te_dekken_aantal       := abs(r_ms.tms_saldo_positie);
              v_beschikbaar_dek_aantal := trunc((v_beschikbare_geblok_geld - v_gebruikte_geblok_geld)/
                                               (r_ms.tms_blocksize * r_ms.tms_exerciseprijs),0);
              v_gedekt_aantal          := least (v_beschikbaar_dek_aantal, v_te_dekken_aantal);
              v_gebruikte_geblok_geld  := v_gebruikte_geblok_geld +
                                          v_gedekt_aantal * r_ms.tms_blocksize * r_ms.tms_exerciseprijs;
              v_nieuw_required_margin  := (v_te_dekken_aantal - v_gedekt_aantal) /
                                           v_te_dekken_aantal * r_ms.tms_margin_required;
              -- aanpassen van het temp_margin_wb_sessie record met de nieuwe gegevens:
              update temp_margin_wb_sessie t
              set    t.tms_prod_geblok_aantal = v_gedekt_aantal,
                     t.tms_margin_required    = v_nieuw_required_margin
              where  t.rowid                  = r_ms.onderhanden_rowid;
              
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'in blokkeren short put');
                 FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'te dekken aantal : '||to_char(v_te_dekken_aantal)||
                                                          ' ; beschikbaar dek aantak : '||to_char(v_beschikbaar_dek_aantal));
                 FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'gedekt aantal : '|| to_char(v_gedekt_aantal)||
                                                          ' ; gebruikt geblok stuk : '||to_char(v_gebruikte_geblok_stuk));
                 FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'nieuw required margin : '||to_char(v_nieuw_required_margin));
                 FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
              end if;
           end if;


           -- Dit deel uitvoeren als de ow van de optie wel een mandje is (alleen short call en long put, short put is in eerste deel al gedaan)
           else  
              
              -- Dit alleen uitvoeren voor blokkeren short call of long put
              if r_ms.tms_soort = 'CALL' and r_ms.tms_saldo_positie < 0 and gv_pr_blokkeren_short_call = 1 and r_ms.be_bi_nummer not between 3000 and 3099
                 or
                 r_ms.tms_soort = 'PUT' and r_ms.tms_saldo_positie > 0 and gv_pr_blokkeren_long_put = 1 and r_ms.be_bi_nummer not between 3000 and 3099
              then
                 
                 -- Het aantal dat te dekken is:
                 v_te_dekken_aantal := abs(r_ms.tms_saldo_positie);
                 
                 -- eerst resetten van een aantal variabelen (hier op -1 zetten om een eerste itteratie te kunnen afvangen)
                 v_gedekt_aantal := -1;
                               
                 -- Stap 1. Als eerst bepalen of alle ow uit het mandje wel voldoende geblokkeerde posities hebben 
                 --         en hoeveel opties daadwerkelijk afgedekt kunnen worden
                 declare
                    v_maximaal_te_dekken          werkbestand.wk_waarde_1%type;
                    v_beschikbaar_aantal_mn1      werkbestand.wk_waarde_1%type;
                    v_gedekt_aantal_mn1           werkbestand.wk_waarde_1%type;
                    
                    cursor mn is
                       select m.mnd_factor,        b.be_symbool
                       from   mandje_onderliggende_waarde m, beleggingsinstrument b
                       where  m.mnd_volgnummer = v_mandje_symb_volgnummer 
                       and    m.mnd_ref_volgnr = b.be_volgnummer;
                               
                 begin
                    for r_mn in mn
                    loop
                       v_beschikbaar_aantal_mn1 := 0;                    
                       
                       -- per referentiesymbool van de ow bepalen wat de beschikbare geblokkeerde positie is   
                       ma_get_put_geblokkeerd (r_mn.be_symbool, 'G', gv_dummy, gv_dummy, v_beschikbaar_aantal_mn1);
                       
                       if gv_debuggen = 1
                       then
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'huidig refsymbool in mandje :'||r_mn.be_symbool||
                                                                   ' ; beschikbaar geblok stuk : '||to_char(v_beschikbaar_aantal_mn1));
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
                       end if;
                       
                       -- met behulp van het beschikbaar aantal is het volgende aantal opties te dekken:
                       v_maximaal_te_dekken := trunc(v_beschikbaar_aantal_mn1/(r_mn.mnd_factor * r_ms.tms_blocksize * r_ms.tms_pricing_unit),0);
                       v_gedekt_aantal_mn1  := least(v_te_dekken_aantal, v_maximaal_te_dekken);
                        
                       -- Vast houden hoeveel er nu daadwerkelijk gedekt kunnen worden met behulp van de ow uit het mandje 
                       -- Dit aantal wordt hierna gebruikt om daadwerkelijk te dekken en te registeren
                       if v_gedekt_aantal = -1  
                       then
                          v_gedekt_aantal := v_gedekt_aantal_mn1;
                       else
                          v_gedekt_aantal := least (v_gedekt_aantal, v_gedekt_aantal_mn1);
                       end if;
                       
                       if gv_debuggen = 1
                       then
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Met de OW uit het mandje  :'||r_mn.be_symbool||
                                                                 ' ; gedekt aantal : '||to_char(v_gedekt_aantal));
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
                       end if;
                    end loop;
                 end;
                 
                 -- Stap 2. Het in stap 1 bepaald aantal gebruiken om de stukken registeren en om de gegevens van de optie
                 --         aan te passen. 
                 -- Alleen uitvoeren als het gedekt aantal groter dan 0 is...
                 if v_gedekt_aantal > 0
                 then
                    declare 
                       v_gebruikte_gebl_stukken_mn2        werkbestand.wk_waarde_1%type;
                       
                       cursor mo is
                          select m.mnd_factor,        b.be_symbool
                          from   mandje_onderliggende_waarde m, beleggingsinstrument b
                          where  m.mnd_volgnummer = v_mandje_symb_volgnummer 
                          and    m.mnd_ref_volgnr = b.be_volgnummer;
                       
                    begin

                       if gv_debuggen = 1
                       then
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'In deel 2 van afhandeling van het mandje  ');
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Het gedekt aantal : '||to_char(v_gedekt_aantal));
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
                       end if;
                      
                       for r_mo in mo
                       loop
                          -- Vermenigvuldigen met de factor voor het fonds uit het mandje
                          v_gebruikte_gebl_stukken_mn2       := v_gedekt_aantal * r_mo.mnd_factor * r_ms.tms_blocksize * r_ms.tms_pricing_unit;
                          ma_get_put_geblokkeerd (r_mo.be_symbool, 'P', v_gebruikte_gebl_stukken_mn2, gv_dummy, gv_dummy);
                       
                          if gv_debuggen = 1
                          then
                             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Fonds uit mandje :  '||r_mo.be_symbool||' ; factor in mandje : '||to_char(r_mo.mnd_factor));
                             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Gebruikte geblokkeerde stukken  : '||to_char(v_gebruikte_gebl_stukken_mn2));
                             FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
                          end if;
                       
                       
                       end loop;
                    end;
                    
                    -- Ook nog de gegevens van de optie aanpassen ! Verschil tussen Call en Put
                    if r_ms.tms_soort = 'CALL'
                    then
                       v_nieuw_required_margin  := (v_te_dekken_aantal - v_gedekt_aantal)/
                                                    v_te_dekken_aantal * r_ms.tms_margin_required;
                       -- aanpassen van het temp_margin_wb_sessie record met de nieuwe gegevens:
                       update temp_margin_wb_sessie t
                       set    t.tms_prod_geblok_aantal = v_gedekt_aantal,
                              t.tms_margin_required    = v_nieuw_required_margin
                       where  t.rowid                  = r_ms.onderhanden_rowid;

                       if gv_debuggen = 1
                       then
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Afronden van Call optie met mandje ');
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Nieuwe margin bedrag : '||to_char(v_nieuw_required_margin)||' ; Gedekt aantal : '||to_char(v_gedekt_aantal));
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Onderhanden rowid : '||r_ms.onderhanden_rowid);
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
                       end if;
                    
                    else
                       -- voor een long positie is er geen margin requirement.....
                       -- aanpassen van het temp_margin_wb_sessie record met de nieuwe gegevens:
                       update temp_margin_wb_sessie t
                       set    t.tms_prod_geblok_aantal = v_gedekt_aantal
                       where  t.rowid                  = r_ms.onderhanden_rowid;

                       if gv_debuggen = 1
                       then
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Afronden van Put optie met mandje ');
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'Gedekt aantal : '||to_char(v_gedekt_aantal));
                          FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
                       end if;
                    end if;
                                                 
                 end if; -- Einde gedekt aantal > 0
              end if;    -- Einde alleen uitvoeren voor short Call of long Put
           end if;       -- Einde verchil tussen wel of geen mandje als ow van de optie
        end if;          -- Het betreft geen long call positie 
     
     end loop;

     -- na het uit de loop gaan nog de laatste waarden wegschrijven voor refsymbool en valuta:
     if v_gebruikte_geblok_stuk <> 0
     then
        ma_get_put_geblokkeerd (v_huidig_refsymbool, 'P', v_gebruikte_geblok_stuk, gv_dummy, gv_dummy);
     end if;

     if v_gebruikte_geblok_geld <> 0
     then
        ma_get_put_geblokkeerd (v_huidige_valuta, 'P', v_gebruikte_geblok_geld, gv_dummy, gv_dummy);
     end if;

     if gv_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'laatste stap in procedure ma_geblok_stuk_geld');
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'huidig refsymbool : '||v_huidig_refsymbool||
                                                 ' ; gebruikte geblok stuk : '||to_char(v_gebruikte_geblok_stuk));
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user, 'huidige valuta : '|| v_huidige_valuta||
                                                 ' ; gebruikt geblok geld : '||to_char(v_gebruikte_geblok_geld));
        FIAT_ALGEMEEN.fiat_debug (gv_debug_user, ' ');
     end if;
  end;

end ma_geblok_stuk_geld;
-- EINDE CODE PROCEDURE GEBLOK_STUK_GELD


-- DE CODE VOOR DE PROCEDURE MA_KOPIEREN_BESTANDEN
-- Met behulp van het runnummer worden nu twee sets aangemaakt van dezelfde data.
-- Runnummer 0 wordt gebruikt voor de marginberekening van de portefeuille
-- Runnummer 8 wordt gebruikt als uitgangspunt voor de marginberekeningen van de invloed van orders,
-- hierbij worden de gegevens van runnummer 8 gekopieerd maar niet aangepast.
-- Runnummer 9 wordt gebruikt als uitgangspunt voor de marginberekeningen van de invloed van orders
-- hierbij wordt bij het onderdeel lopende_orders iedere keer een subset genomen van deze records van runnummer 9.
-- De gegevens van runnummer 9 worden per lopende order aangepast.
procedure ma_kopieren_bestanden
is
   v_teller                    number(1);
   v_runnummer                 number(1);
begin
   -- kopieren van temp_margin_wb_sessie van runnummer 0 naar runnummer 8 en 9
   declare
      cursor tm is
          select t.tms_relatienr,         t.tms_productnummer,        t.tms_product_volgnummer,
                 t.tms_rekeningsoort,     t.tms_rekeningnr,           t.tms_rekening_munts,
                 t.tms_refsymbool,        t.tms_soort,                t.tms_symbool,
                 t.tms_exp_datum,         t.tms_exerciseprijs,        t.tms_saldo_positie,
                 t.tms_positie_future,    t.tms_prod_geblok_aantal,   t.tms_marginfactor,
                 t.tms_slotkoers_voriged, t.tms_biedkoers,            t.tms_laatkoers,
                 t.tms_blocksize,         t.tms_margin_required,      t.tms_gecovered,
                 t.tms_spread_aantal,     t.tms_spread_bedrag,        t.tms_straddle_aantal,
                 t.tms_straddle_bedrag,   t.tms_valuta,               t.tms_collateral_bedrag,
                 t.tms_pricing_unit,      t.tms_cross_aantal,         t.tms_cross_bedrag,
                 t.tms_gecovered_comp,    t.tms_gecovered_comp_bedrag
          from   temp_margin_wb_sessie t
          where  t.tms_runnnummer = 0;
   begin
      for r_tm in tm
      loop
         v_teller    := 0;
         v_runnummer := 8;

         while v_teller < 2
         loop
            insert into temp_margin_wb_sessie
            values
            (r_tm.tms_relatienr,          v_runnummer,                   r_tm.tms_productnummer,
             r_tm.tms_product_volgnummer, r_tm.tms_rekeningsoort,        r_tm.tms_rekeningnr,
             r_tm.tms_rekening_munts,     r_tm.tms_refsymbool,           r_tm.tms_soort,
             r_tm.tms_symbool,            r_tm.tms_exp_datum,            r_tm.tms_exerciseprijs,
             r_tm.tms_saldo_positie,      r_tm.tms_positie_future,       r_tm.tms_prod_geblok_aantal,
             r_tm.tms_marginfactor,       r_tm.tms_slotkoers_voriged,    r_tm.tms_biedkoers,
             r_tm.tms_laatkoers,          r_tm.tms_blocksize,            r_tm.tms_margin_required,
             r_tm.tms_gecovered,          r_tm.tms_spread_aantal,        r_tm.tms_spread_bedrag,
             r_tm.tms_straddle_aantal,    r_tm.tms_straddle_bedrag,      r_tm.tms_valuta,
             r_tm.tms_collateral_bedrag,  r_tm.tms_pricing_unit,         r_tm.tms_cross_aantal,
             r_tm.tms_cross_bedrag,       r_tm.tms_gecovered_comp,       r_tm.tms_gecovered_comp_bedrag,
             null,                        null,                          null);

            v_teller    := v_teller + 1;
            v_runnummer := 9;
         end loop; -- einde teller loop
      end loop; -- einde bestands loop cursor tm
   end;

   -- kopieren van temp_ap_werkbest_sessie van runnummer 0 naar 8 en 9
   declare
      cursor ta is
          select a.tas_ref_relatie,     a.tas_productnummer,    a.tas_product_volgnummer,
                 a.tas_relatienr,       a.tas_rekening_soort,   a.tas_rekeningnr,
                 a.tas_rekening_munts,  a.tas_ref_symbool,      a.tas_symbool,
                 a.tas_optietype,       a.tas_expiratiedatum,   a.tas_exerciseprijs,
                 a.tas_saldo_positie,   a.tas_positie_future,   a.tas_hist_wrd_poscl,
                 a.tas_hist_wrd_posbe,  a.tas_hist_wrd_totcl,   a.tas_hist_wrd_totbe,
                 a.tas_bi_type,         a.tas_sld_losbaar_marg, a.tas_in_cover,
                 a.tas_in_cover_used,   a.tas_in_collateral,    a.tas_tegenwaarde_basis,
                 a.tas_export,          a.tas_positie_long,     a.tas_positie_short,
                 a.tas_collateral_used, a.tas_wegingsfactor,    a.tas_baisse_margin
          from   temp_ap_werkbest_sessie a
          where  a.tas_runnummer = 0;
   begin
      for r_ta in ta
      loop
         v_teller    := 0;
         v_runnummer := 8;

         while v_teller < 2
         loop
            insert into temp_ap_werkbest_sessie
            values
            (r_ta.tas_ref_relatie,       r_ta.tas_productnummer,    r_ta.tas_product_volgnummer,
             r_ta.tas_relatienr,         v_runnummer,               r_ta.tas_rekening_soort,
             r_ta.tas_rekeningnr,        r_ta.tas_rekening_munts,   r_ta.tas_ref_symbool,
             r_ta.tas_symbool,           r_ta.tas_optietype,        r_ta.tas_expiratiedatum,
             r_ta.tas_exerciseprijs,     r_ta.tas_saldo_positie,    r_ta.tas_positie_future,
             r_ta.tas_hist_wrd_poscl,    r_ta.tas_hist_wrd_posbe,   r_ta.tas_hist_wrd_totcl,
             r_ta.tas_hist_wrd_totbe,    r_ta.tas_bi_type,          r_ta.tas_sld_losbaar_marg,
             r_ta.tas_in_cover,          r_ta.tas_in_cover_used,    r_ta.tas_in_collateral,
             r_ta.tas_tegenwaarde_basis, r_ta.tas_export,           r_ta.tas_positie_long,
             r_ta.tas_positie_short,     r_ta.tas_collateral_used,  r_ta.tas_wegingsfactor,
             r_ta.tas_baisse_margin,     null);

            v_teller    := v_teller + 1;
            v_runnummer := 9;
         end loop;
      end loop;
   end;

end ma_kopieren_bestanden;
-- EINDE CODE PROCEDURE MA_KOPIEREN_BESTANDEN


-- DE CODE VOOR DE PROCEDURE MA_CALL_MARGIN
-- in deze procedure wordt het call-optie gedeelte afgehandeld van de margin berekening
-- vergelijk subtaak 3 van programma 173 br-Opt Fut posities(Sessie)
procedure ma_call_margin
(i_minimum_spread_bedrag in  tabelgegevens.tb_waarde%type
,i_toeslag_time_spread   in  tabelgegevens.tb_waarde%type
,i_optiemargin_toeslag   in  tabelgegevens.tb_waarde%type
)

is

   v_saldo_positie            temp_margin_wb_sessie.tms_saldo_positie%type            := 0;
   v_prod_geblok_aantal       temp_margin_wb_sessie.tms_prod_geblok_aantal%type       := 0;
   v_spread_bedrag            temp_margin_wb_sessie.tms_spread_bedrag%type            := 0;
   v_spread_aantal            temp_margin_wb_sessie.tms_spread_aantal%type            := 0;
   v_gecovered_aantal         temp_margin_wb_sessie.tms_gecovered%type                := 0;
   v_margin_required          temp_margin_wb_sessie.tms_margin_required%type          := 0;
   v_ow_is_mandje             number(1)                                               := 0;
   v_ref_symb_volgnummer      beleggingsinstrument.be_volgnummer%type                 := 0;
   v_maximaal_te_coveren      temp_ap_werkbest_sessie.tas_in_cover%type;                          

cursor ms is

select   m.tms_relatienr,     m.tms_refsymbool,         m.tms_soort,         m.tms_symbool,
         m.tms_exerciseprijs, m.tms_exp_datum,          m.tms_saldo_positie, m.tms_laatkoers,
         m.tms_blocksize,     m.tms_margin_required,    m.tms_gecovered,     m.tms_spread_aantal,
         m.tms_spread_bedrag, m.tms_straddle_aantal,    m.tms_pricing_unit,  m.tms_prod_geblok_aantal,
         m.rowid
from     temp_margin_wb_sessie m
where    m.tms_relatienr     =  gv_terminalnummer
and      m.tms_soort         =  'CALL'
and      m.tms_saldo_positie <= -1
and      m.tms_runnnummer    =  gv_runnummer
order by m.tms_refsymbool asc, m.tms_laatkoers desc, m.tms_exerciseprijs asc, m.tms_exp_datum desc;

begin
     for r_ms in ms
     loop
     
     -- eerste bepalen of de onderliggende waarde een mandje betreft:
     select b.be_volgnummer
     into   v_ref_symb_volgnummer
     from   beleggingsinstrument b
     where  b.be_symbool         = r_ms.tms_refsymbool
     and    b.be_optietype       = ' '
     and    b.be_expiratiedatum  = '00000000'
     and    b.be_exerciseprijs   = 0;
     
     begin
        select 1
        into   v_ow_is_mandje
        from   mandje_onderliggende_waarde m
        where  m.mnd_volgnummer = v_ref_symb_volgnummer
        and    rownum           <= 1;             -- Er hoeft maar maximaal 1 record opgehaald te worden!
     
     exception
        when no_data_found
        then
           v_ow_is_mandje := 0;
     end;
     
     v_maximaal_te_coveren   := 0;
     
     -- Variabelen die gebruikt moeten worden voor het updaten van het record uit de loop.
     -- Vullen met de gegevens uit het record, zodat deze aangepast kunnen worden.
     v_saldo_positie      := r_ms.tms_saldo_positie;
     v_prod_geblok_aantal := r_ms.tms_prod_geblok_aantal;
     v_spread_bedrag      := r_ms.tms_spread_bedrag;
     v_spread_aantal      := r_ms.tms_spread_aantal;
     v_gecovered_aantal   := r_ms.tms_gecovered;
     v_margin_required    := r_ms.tms_margin_required;

     if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer and v_saldo_positie <= 0
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' in package FIAT_MARGIN, procedure ma_call_margin');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'De gegevens van de short optie:');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ref symbool     : '||r_ms.tms_refsymbool||
                                                ' ; symbool : '||r_ms.tms_symbool);
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'soort           : '||r_ms.tms_soort     ||
                                                ' ; exp datum : '||r_ms.tms_exp_datum);
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'exerciseprijs   : '||to_char(r_ms.tms_exerciseprijs)||
                                                ' ; margin instelling client : '||to_char(gv_cl_margin));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie   : '||to_char(v_saldo_positie)||
                                                ' ; gecovered aantal : '||to_char(v_gecovered_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'spread bedrag   : '||to_char(v_spread_bedrag)||
                                                ' ; spread aantal : '||to_char(v_spread_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin required : '||to_char(v_margin_required)||
                                                ' ; runnummer : '||to_char(gv_runnummer));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'prod geblok aant: '||to_char(v_prod_geblok_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
     end if;

     -- Deel 1: Zoek bijbehorende long call af (subtaak 173.3.1)
     if v_saldo_positie + v_prod_geblok_aantal + v_spread_aantal < 0
     then
        declare
          lc_nog_over_short           temp_margin_wb_sessie.tms_saldo_positie%type      := 0;
          lc_nog_over_long            temp_margin_wb_sessie.tms_saldo_positie%type      := 0;
          lc_aantal_spread            temp_margin_wb_sessie.tms_saldo_positie%type      := 0;
          lc_init_margin_spread       temp_margin_wb_sessie.tms_spread_bedrag%type      := 0;
          lc_spread_margin            temp_margin_wb_sessie.tms_spread_bedrag%type      := 0;
          lc_in_cover_used            temp_ap_werkbest_sessie.tas_in_cover_used%type    := 0;
          lc_as_rowid                 rowid;
          lc_as_bi_nummer             beleggingsinstrument.be_bi_nummer%type            := 0;

          cursor msA is

          select   mA.tms_relatienr,     mA.tms_refsymbool,   mA.tms_soort,         mA.tms_symbool,
                   mA.tms_exerciseprijs, mA.tms_exp_datum,    mA.tms_saldo_positie, mA.tms_blocksize,
                   mA.tms_spread_aantal, mA.tms_pricing_unit, mA.tms_biedkoers,     mA.rowid
          from     temp_margin_wb_sessie mA
          where    mA.tms_relatienr     =  gv_terminalnummer
          and      mA.tms_refsymbool    =  r_ms.tms_refsymbool
          and      mA.tms_soort         =  'CALL'
          and      mA.tms_exp_datum     >= r_ms.tms_exp_datum
          and      mA.tms_exerciseprijs <= r_ms.tms_exerciseprijs
          and      mA.tms_saldo_positie >= 1
          and      mA.tms_runnnummer    =  gv_runnummer
          order by mA.tms_exp_datum asc, mA.tms_exerciseprijs desc;

        begin

          for r_msA in msA
          loop

             if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
             then
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Is er iets gevonden in Deel 1 van de call berekeningen?');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Gegevens van de long optie');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'refsymbool    : '||r_msA.tms_refsymbool||
                                                        ' ; symbool : '||r_msA.tms_symbool);
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'soort         : '||r_msA.tms_soort     ||
                                                        ' ; exp datum : '||r_msA.tms_exp_datum);
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'exerciseprijs : '||to_char(r_msA.tms_exerciseprijs));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie : '||to_char(r_msA.tms_saldo_positie)||
                                                       ' ; spread aantal : '||to_char(r_msA.tms_spread_aantal));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Gegevens van de short optie op dit moment');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie : '||to_char(v_saldo_positie)||
                                                        ' ; spread aantal : '||to_char(v_spread_aantal));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
             end if;

            lc_aantal_spread      := 0;
            lc_spread_margin      := 0;
            lc_in_cover_used      := 0;
            lc_as_bi_nummer       := 0;

            -- ophalen van de aktuele in_cover_used van de long call
            select a.tas_in_cover_used, a.tas_bi_type,   a.rowid
            into   lc_in_cover_used,    lc_as_bi_nummer, lc_as_rowid
            from   temp_ap_werkbest_sessie a
            where  a.tas_relatienr      = gv_terminalnummer
            and    a.tas_rekening_soort = 0
            and    a.tas_rekening_munts = ' '
            and    a.tas_rekeningnr     = ' '
            and    a.tas_symbool        = r_msA.tms_symbool
            and    a.tas_optietype      = r_msA.tms_soort
            and    a.tas_expiratiedatum = r_msA.tms_exp_datum
            and    a.tas_exerciseprijs  = r_msA.tms_exerciseprijs
            and    a.tas_runnummer      = gv_runnummer;

            lc_nog_over_short := ABS(v_saldo_positie + v_prod_geblok_aantal + v_spread_aantal);
            lc_nog_over_long  := r_msA.tms_saldo_positie - r_msA.tms_spread_aantal;

            if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'nog over short : '||to_char(lc_nog_over_short)||
                                                       ' ; nog over long : '||to_char(lc_nog_over_long));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
            end if;

            -- Bij verschillende blocksizes: long omrekenen naar blocksize short pos. (afrondend naar beneden)
            lc_nog_over_long  := trunc(lc_nog_over_long * (r_msA.tms_blocksize*r_msA.tms_pricing_unit)/
                                                           (r_ms.tms_blocksize*r_ms.tms_pricing_unit),0);
            -- Bepalen welk aantal te gebruiken voor de berekening:
            if lc_nog_over_short <= lc_nog_over_long
            then
               lc_aantal_spread := lc_nog_over_short;
            else
               lc_aantal_spread := lc_nog_over_long;
            end if;

            if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'aantal spread : '||to_char(lc_aantal_spread));
            end if;

            -- Aanpassen van de initial margin aan de nieuwe spread situatie:
            if lc_aantal_spread = 0
            then
               lc_init_margin_spread := 0;
            else
               lc_init_margin_spread := v_margin_required / lc_nog_over_short * lc_aantal_spread;
            end if;

            if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'init margin spread : '||to_char(lc_init_margin_spread));
            end if;

            -- Berekenen van het spread bedrag:
            if r_msA.tms_exerciseprijs > r_ms.tms_exerciseprijs
            then
               lc_spread_margin := (r_msA.tms_exerciseprijs/r_msA.tms_pricing_unit -
                                    r_ms.tms_exerciseprijs/r_ms.tms_pricing_unit)*
                                                           r_ms.tms_blocksize*r_ms.tms_pricing_unit*lc_aantal_spread;
            else
               lc_spread_margin := 0;
            end if;

            if gv_debuggen = 1  and gv_runnummer = gv_debug_runnummer
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'spread margin : '||to_char(lc_spread_margin));
            end if;

            --Time spread
            if r_msA.tms_exp_datum <> r_ms.tms_exp_datum
            then
               -- Berekende margin nooit lager dan verschil tussen de premies
               if lc_spread_margin < ABS(lc_aantal_spread*r_ms.tms_blocksize*r_ms.tms_laatkoers)-
                                     ABS(lc_aantal_spread*r_ms.tms_pricing_unit*r_msA.tms_blocksize*
                                         r_msA.tms_biedkoers/r_msA.tms_pricing_unit)
               then
                  lc_spread_margin := ABS(lc_aantal_spread*r_ms.tms_blocksize*r_ms.tms_laatkoers)-
                                      ABS(lc_aantal_spread*r_ms.tms_pricing_unit*r_msA.tms_blocksize*
                                          r_msA.tms_biedkoers/r_msA.tms_pricing_unit);
               end if;

               -- Voor index opties:
               if lc_as_bi_nummer between 3000 and 3899
               then
                  -- Minimum spread bedrag
                  if lc_spread_margin < i_minimum_spread_bedrag * lc_aantal_spread
                  then
                     lc_spread_margin := i_minimum_spread_bedrag * lc_aantal_spread;
                  end if;
                  -- Margintoeslag time spreads
                  if r_ms.tms_exerciseprijs = r_msA.tms_exerciseprijs
                  then
                     lc_spread_margin := lc_spread_margin + i_toeslag_time_spread * lc_aantal_spread;
                  end if;
               end if;
            end if;

            -- Toeslag optiemargin
            lc_spread_margin := (1 + (i_optiemargin_toeslag/100)) * lc_spread_margin;
            lc_spread_margin := (1 + (gv_cl_margin_toeslag/100)) * lc_spread_margin;

            -- Bijwerken van de totalen:
            if lc_spread_margin < lc_init_margin_spread
            then
               -- Bijwerken van de gegevens van de short optie
               v_spread_bedrag   := v_spread_bedrag + lc_spread_margin;
               v_margin_required := v_margin_required - lc_init_margin_spread;
               v_spread_aantal   := v_spread_aantal + lc_aantal_spread;

               -- aanpassing van het berekende lc_aantal_spread om naar boven af te ronden:
               if (lc_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/(r_msA.tms_blocksize*r_msA.tms_pricing_unit))-
                   trunc(lc_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                                              (r_msA.tms_blocksize*r_msA.tms_pricing_unit)),0))>0
               then
                  lc_aantal_spread := trunc(lc_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                                              (r_msA.tms_blocksize*r_msA.tms_pricing_unit)),0)+1;
               else
                  lc_aantal_spread := trunc(lc_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                                              (r_msA.tms_blocksize*r_msA.tms_pricing_unit)),0);
               end if;

               -- Bijwerken van de gegevens van de long posities
               update temp_margin_wb_sessie
               set    tms_spread_aantal = tms_spread_aantal + lc_aantal_spread
               where  rowid = r_msA.rowid;

               update temp_ap_werkbest_sessie
               set    tas_in_cover_used = tas_in_cover_used + lc_aantal_spread
               where  rowid = lc_as_rowid;
            end if;
          end loop; -- einde van loop r_msA
        end;
     -- Einde Deel 1: Zoek bijbehorende long call af (subtaak 173.3.1)
     end if;

     if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'tussen 1 en 2');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie   : '||to_char(v_saldo_positie)||
                                                ' ; gecovered aantal : '||to_char(v_gecovered_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'spread bedrag   : '||to_char(v_spread_bedrag)||
                                                ' ; spread aantal : '||to_char(v_spread_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin required : '||to_char(v_margin_required)||
                                                ' ; prod geblok aant: '||to_char(v_prod_geblok_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
     end if;

     -- Deel 2a: In cover berekenen (subtaak 173.3.2 / 173.3.2.1) voor opties met geen mandje als ow
     if v_saldo_positie + v_prod_geblok_aantal + v_spread_aantal < 0 and (gv_cl_margin = 2 or gv_cl_margin = 4) and v_ow_is_mandje = 0
     then
        declare
          cb_geblokkeerd_stuk         temp_margin_wb_sessie.tms_prod_geblok_aantal%type := 0;
          cb_beschikbare_cover        temp_ap_werkbest_sessie.tas_in_cover%type         := 0;
          cb_benodigde_cover          temp_ap_werkbest_sessie.tas_in_cover%type         := 0;
          cb_gebruikte_cover          temp_ap_werkbest_sessie.tas_in_cover%type         := 0;
          cb_opties_gecovered         temp_ap_werkbest_sessie.tas_in_cover%type         := 0;
          cb_as_in_cover_used         temp_ap_werkbest_sessie.tas_in_cover%type         := 0;
          cb_as_rowid                 rowid;

          cursor asA is

          select a.tas_relatienr,     a.tas_rekening_soort, a.tas_rekening_munts, a.tas_rekeningnr,
                 a.tas_symbool,       a.tas_optietype,      a.tas_expiratiedatum, a.tas_exerciseprijs,
                 a.tas_saldo_positie, a.tas_in_cover,       a.tas_in_cover_used,  a.tas_export,
                 a.rowid
          from   temp_ap_werkbest_sessie a
          where  a.tas_relatienr      = gv_terminalnummer
          and    a.tas_rekening_soort = 0
          and    a.tas_rekeningnr     = ' '
          and    a.tas_symbool        = r_ms.tms_refsymbool
          and    a.tas_optietype      = ' '
          and    a.tas_expiratiedatum = '00000000'
          and    a.tas_exerciseprijs  = 0
          and    a.tas_runnummer      = gv_runnummer
          order by a.tas_relatienr, a.tas_rekening_soort, a.tas_rekening_munts, a.tas_rekeningnr, a.tas_symbool,
                   a.tas_optietype, a.tas_expiratiedatum, a.tas_exerciseprijs, a.tas_productnummer, a.tas_product_volgnummer;

        begin
          if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in Deel 2 van de call berekeningen');
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
          end if;

          for r_asA in asA
          loop
             cb_geblokkeerd_stuk := 0;

             if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
             then
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Is er iets gevonden in Deel 2a van de call berekeningen?');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
             end if;

            -- ophalen actuele positie in de optieserie
            begin
               select w.tas_in_cover_used,  w.rowid
               into   cb_as_in_cover_used, cb_as_rowid
               from   temp_ap_werkbest_sessie w
               where  w.tas_relatienr      = gv_terminalnummer
               and    w.tas_rekening_soort = r_asA.tas_rekening_soort
               and    w.tas_rekening_munts = r_asA.tas_rekening_munts
               and    w.tas_rekeningnr     = r_asA.tas_rekeningnr
               and    w.tas_symbool        = r_ms.tms_refsymbool
               and    w.tas_optietype      = r_ms.tms_soort
               and    w.tas_expiratiedatum = r_ms.tms_exp_datum
               and    w.tas_exerciseprijs  = r_ms.tms_exerciseprijs
               and    w.tas_runnummer      = gv_runnummer;
            exception
               when no_data_found
               then
                  cb_as_in_cover_used     := 0;
                  cb_as_rowid             := ' ';
            end;

            cb_benodigde_cover := ABS(v_saldo_positie + v_prod_geblok_aantal + v_spread_aantal)*
                                                      r_ms.tms_blocksize*r_ms.tms_pricing_unit;

            -- Bepalen hoeveel stukken er in cover gezet kan worden
            cb_beschikbare_cover := trunc((r_asA.tas_in_cover - r_asA.tas_in_cover_used)/
                                          (r_ms.tms_blocksize*r_ms.tms_pricing_unit),0)*
                                          (r_ms.tms_blocksize*r_ms.tms_pricing_unit);

            -- Cover automatisch?
            if gv_cl_margin = 2 or gv_cl_margin = 4
            then
               cb_geblokkeerd_stuk := 0;
               -- Kijken hoeveel stukken er van deze positie al is geblokkeerd voor producten functionaliteit
               ma_get_put_geblokkeerd (r_asA.tas_symbool, 'G', gv_dummy, cb_geblokkeerd_stuk, gv_dummy);

               cb_beschikbare_cover := trunc((r_asA.tas_saldo_positie - cb_geblokkeerd_stuk - r_asA.tas_in_cover_used)/
                                             (r_ms.tms_blocksize*r_ms.tms_pricing_unit),0)*
                                             (r_ms.tms_blocksize*r_ms.tms_pricing_unit);

               if cb_beschikbare_cover <0
               then
                  cb_beschikbare_cover := 0;
               end if;
            end if;
            -- Bepalen van de gebruikte cover
            if cb_beschikbare_cover >= cb_benodigde_cover
            then
               cb_gebruikte_cover := cb_benodigde_cover;
            else
               cb_gebruikte_cover := cb_beschikbare_cover;
            end if;
            -- Bepalen hoeveel opties hiermee is gecovered
            cb_opties_gecovered := trunc(cb_gebruikte_cover/(r_ms.tms_blocksize*r_ms.tms_pricing_unit),0);

            -- Bijwerken van de gegevens
            if cb_opties_gecovered > 0
            then
               if gv_cl_margin =2 or gv_cl_margin = 4
               then
                  update temp_ap_werkbest_sessie
                  set    tas_in_cover_used  = tas_in_cover_used + cb_gebruikte_cover,
                         tas_in_cover       = tas_in_cover_used + cb_gebruikte_cover,
                         tas_export         = 1
                  where  rowid              = r_asA.rowid;

                  if cb_as_rowid <> ' '
                  then
                     update temp_ap_werkbest_sessie
                     set    tas_in_cover_used  = tas_in_cover_used + cb_gebruikte_cover
                     where  rowid              = cb_as_rowid;
                  end if;

                  v_margin_required  := v_margin_required/(cb_benodigde_cover/(r_ms.tms_blocksize*r_ms.tms_pricing_unit))*
                                      (cb_benodigde_cover/(r_ms.tms_blocksize*r_ms.tms_pricing_unit)-cb_opties_gecovered);
                  v_gecovered_aantal := v_gecovered_aantal + cb_opties_gecovered;
                  cb_benodigde_cover := cb_benodigde_cover - cb_gebruikte_cover;
               else
                  update temp_ap_werkbest_sessie
                  set    tas_in_cover_used  = tas_in_cover_used + cb_gebruikte_cover,
                         tas_export         = 1
                  where  rowid              = r_asA.rowid;

                  if cb_as_rowid <> ' '
                  then
                     update temp_ap_werkbest_sessie
                     set    tas_in_cover_used  = tas_in_cover_used + cb_gebruikte_cover
                     where  rowid              = cb_as_rowid;
                  end if;

                  v_margin_required  := v_margin_required/(cb_benodigde_cover/(r_ms.tms_blocksize*r_ms.tms_pricing_unit))*
                                      (cb_benodigde_cover/(r_ms.tms_blocksize*r_ms.tms_pricing_unit)-cb_opties_gecovered);
                  v_gecovered_aantal := v_gecovered_aantal + cb_opties_gecovered;
                  cb_benodigde_cover := cb_benodigde_cover - cb_gebruikte_cover;
               end if;

               if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
               then
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Einde onderdeel 2a cover berekening voor opties geen mandje als ow');
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin required : '||to_char(v_margin_required)||
                                                          ' ; gecovered aantal : '||to_char(v_gecovered_aantal));
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'benodigde cover : '||to_char(cb_benodigde_cover));
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
               end if;
            end if;
          end loop; -- einde van loop r_asA
        end;
     -- Einde Deel 2a: In cover berekenen voor opties met geen mandje als ow.
     end if;


     -- Deel 2b: In cover berekenen (subtaak 173.3.2 / 173.3.2.1) voor opties met een mandje als ow
     if v_saldo_positie + v_prod_geblok_aantal + v_spread_aantal < 0 and (gv_cl_margin = 2 or gv_cl_margin = 4) and v_ow_is_mandje = 1
     then
        declare
          cm_geblokkeerd_stuk           temp_margin_wb_sessie.tms_prod_geblok_aantal%type := 0;
          cm_beschikbare_cover          temp_ap_werkbest_sessie.tas_in_cover%type         := 0;
          cm_benodigde_cover            temp_ap_werkbest_sessie.tas_in_cover%type         := 0;
          cm_gebruikte_cover            temp_ap_werkbest_sessie.tas_in_cover%type         := 0;
          cm_opties_gecovered           temp_ap_werkbest_sessie.tas_in_cover%type         := 0;
          cm_maximaal_te_coveren        temp_ap_werkbest_sessie.tas_in_cover%type         := -1;
          
          cm_fonds_uit_mandje_aanwezig  number(1);

          cursor om is
          select m.mnd_factor,        b.be_symbool,      b.be_optietype, 
                 b.be_expiratiedatum, b.be_exerciseprijs
          from   mandje_onderliggende_waarde m, beleggingsinstrument b
          where  m.mnd_volgnummer   = v_ref_symb_volgnummer
          and    m.mnd_ref_volgnr   = b.be_volgnummer;
          
        begin

           if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
           then
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in Deel 2b van de call berekeningen (cover met mandje als ow)');
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
           end if;
           
           for r_om in om
           loop
              
              -- Zet per fonds de indicatie uit dat het fonds aanwezig is. Pas als het daadwerkelijk gevonden is mag het aangezet worden
              cm_fonds_uit_mandje_aanwezig := 0;
              
              declare
                cursor asA is
                 
                select a.tas_relatienr,     a.tas_rekening_soort, a.tas_rekening_munts, a.tas_rekeningnr,
                       a.tas_symbool,       a.tas_optietype,      a.tas_expiratiedatum, a.tas_exerciseprijs,
                       a.tas_saldo_positie, a.tas_in_cover,       a.tas_in_cover_used,  a.tas_export,
                       a.rowid
                from   temp_ap_werkbest_sessie a
                where  a.tas_relatienr      = gv_terminalnummer
                and    a.tas_rekening_soort = 0
                and    a.tas_rekeningnr     = ' '
                and    a.tas_symbool        = r_om.be_symbool
                and    a.tas_optietype      = r_om.be_optietype
                and    a.tas_expiratiedatum = r_om.be_expiratiedatum
                and    a.tas_exerciseprijs  = r_om.be_exerciseprijs
                and    a.tas_runnummer      = gv_runnummer
                order by a.tas_relatienr, a.tas_rekening_soort, a.tas_rekening_munts, a.tas_rekeningnr, a.tas_symbool,
                         a.tas_optietype, a.tas_expiratiedatum, a.tas_exerciseprijs, a.tas_productnummer, a.tas_product_volgnummer;
                         
              begin
                 
                 for r_asA in asA
                 loop
                    -- het fonds is daadwerkelijk in positie aanwezig:
                    cm_fonds_uit_mandje_aanwezig := 1;
                    
                    cm_geblokkeerd_stuk := 0;
                    
                    if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
                    then
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Eén van de OW uit het mandje is gevonden : '||r_asA.tas_symbool);
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Bij behorende factor : '||to_char(r_om.mnd_factor));
                    end if;
                    
                 -- Hier berekenen wat het voor het fonds uit het mandje inhoud ! (dus met factor)
                 cm_benodigde_cover := ABS(v_saldo_positie + v_prod_geblok_aantal + v_spread_aantal)* r_om.mnd_factor * r_ms.tms_blocksize * r_ms.tms_pricing_unit;
                 
                 -- Bepalen hoeveel stukken er in cover gezet kan worden
                 cm_beschikbare_cover := trunc((r_asA.tas_in_cover - r_asA.tas_in_cover_used)/
                                               (r_om.mnd_factor*r_ms.tms_pricing_unit),0)*
                                               (r_om.mnd_factor*r_ms.tms_pricing_unit);
                 
                 if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
                 then
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Benodigde cover : '||to_char(cm_benodigde_cover)||' ; beschikbare cover : '||to_char(cm_beschikbare_cover));
                 end if;
                 
                 -- Cover automatisch?
                 if gv_cl_margin = 2 or gv_cl_margin = 4
                 then
                    cm_geblokkeerd_stuk := 0;
                    -- Kijken hoeveel stukken er van deze positie al is geblokkeerd voor producten functionaliteit
                    ma_get_put_geblokkeerd (r_asA.tas_symbool, 'G', gv_dummy, cm_geblokkeerd_stuk, gv_dummy);
                    
                    cm_beschikbare_cover := trunc((r_asA.tas_saldo_positie - cm_geblokkeerd_stuk - r_asA.tas_in_cover_used)/
                                                  (r_om.mnd_factor*r_ms.tms_pricing_unit),0)*
                                                  (r_om.mnd_factor*r_ms.tms_pricing_unit);
                                                                      
                    if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
                    then
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'geblokkeerde stukken : '||to_char(cm_geblokkeerd_stuk)||' ; beschikbare cover : '||to_char(cm_beschikbare_cover));
                    end if;
                    
                    if cm_beschikbare_cover <0
                    then
                       cm_beschikbare_cover := 0;
                    end if;
                    
                    if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
                    then
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'beschikbare cover : '||to_char(cm_beschikbare_cover));
                    end if;
                    
                 end if;
                 -- Bepalen van de gebruikte cover
                 if cm_beschikbare_cover >= cm_benodigde_cover
                 then
                    cm_gebruikte_cover := cm_benodigde_cover;
                 else
                    cm_gebruikte_cover := cm_beschikbare_cover;
                 end if;
                 
                 if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
                 then
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'beschikbare cover : '||to_char(cm_beschikbare_cover)||' ; gebruikte cover : '||to_char(cm_gebruikte_cover) );
                 end if;

                 -- Bepalen hoeveel opties hiermee is gecovered  (hier weer met factor uit het mandje !)
                 cm_opties_gecovered := trunc(cm_gebruikte_cover/(r_om.mnd_factor*r_ms.tms_blocksize*r_ms.tms_pricing_unit),0);
                 
                 if cm_opties_gecovered < cm_maximaal_te_coveren or cm_maximaal_te_coveren = -1
                 then
                    cm_maximaal_te_coveren := cm_opties_gecovered;
                 end if;
            
                 if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
                 then
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'opties gecovered : '||to_char(cm_opties_gecovered)||' ; maximaal te coveren : '||to_char(cm_maximaal_te_coveren) );
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                 end if;
                 
                 end loop; -- einde van loop r_asA
              end;
              -- als het fonds niet aanwezig was in positie, dan is cm_fonds_uit_mandje_aanwezig nu nog steeds 0.
              -- als dat zo is, dan mist 1 van de opties uit het mandje en is er geen cover mogelijk
              if cm_fonds_uit_mandje_aanwezig = 0
              then
                 cm_maximaal_te_coveren := 0;
              end if;
              
              -- vast houden wat het maximaal te coveren aantal is geweest voor deze optie
              v_maximaal_te_coveren := cm_maximaal_te_coveren;
            
            end loop;  -- einde van loop r_om
        end;
        
        -- Nu de gegevens herberekenen zodat de correcte aantallen worden opgeslagen.
        if v_maximaal_te_coveren > 0
        then
           declare
              cm2_as_rowid             rowid;
              cm2_benodigde_cover      temp_ap_werkbest_sessie.tas_in_cover%type     := 0;
              cm2_gebruikte_cover      temp_ap_werkbest_sessie.tas_in_cover%type     := 0;
              
              cursor om2 is
                 select m.mnd_factor,        b.be_symbool,       b.be_optietype,
                        b.be_expiratiedatum, b.be_exerciseprijs
                 from   mandje_onderliggende_waarde m, beleggingsinstrument b
                 where  m.mnd_volgnummer = v_ref_symb_volgnummer
                 and    m.mnd_ref_volgnr = b.be_volgnummer;
           begin
              for r_om2 in om2
              loop
                 declare
                    cursor asA is
                    
                    select a.tas_relatienr,     a.tas_rekening_soort, a.tas_rekening_munts, a.tas_rekeningnr,
                           a.tas_symbool,       a.tas_optietype,      a.tas_expiratiedatum, a.tas_exerciseprijs,
                           a.tas_saldo_positie, a.tas_in_cover,       a.tas_in_cover_used,  a.tas_export,
                           a.rowid
                    from   temp_ap_werkbest_sessie a
                    where  a.tas_relatienr      = gv_terminalnummer
                    and    a.tas_rekening_soort = 0
                    and    a.tas_rekeningnr     = ' '
                    and    a.tas_symbool        = r_om2.be_symbool
                    and    a.tas_optietype      = r_om2.be_optietype
                    and    a.tas_expiratiedatum = r_om2.be_expiratiedatum
                    and    a.tas_exerciseprijs  = r_om2.be_exerciseprijs
                    and    a.tas_runnummer      = gv_runnummer
                    order by a.tas_relatienr, a.tas_rekening_soort, a.tas_rekening_munts, a.tas_rekeningnr, a.tas_symbool,
                             a.tas_optietype, a.tas_expiratiedatum, a.tas_exerciseprijs, a.tas_productnummer, a.tas_product_volgnummer;
                         
                 begin
                 
                    for r_asA in asA
                    loop
                    
                       if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
                       then
                          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Is er iets gevonden in Deel 2b van de call berekeningen? (onderdeel herberekenen gegevens)');
                          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                       end if;
                        
                       -- Bepalen wat het rowid van de positie is
                       begin
                          select w.rowid
                          into   cm2_as_rowid
                          from   temp_ap_werkbest_sessie w
                          where  w.tas_relatienr      = gv_terminalnummer
                          and    w.tas_rekening_soort = r_asA.tas_rekening_soort
                          and    w.tas_rekening_munts = r_asA.tas_rekening_munts
                          and    w.tas_rekeningnr     = r_asA.tas_rekeningnr
                          and    w.tas_symbool        = r_ms.tms_refsymbool
                          and    w.tas_optietype      = r_ms.tms_soort
                          and    w.tas_expiratiedatum = r_ms.tms_exp_datum
                          and    w.tas_exerciseprijs  = r_ms.tms_exerciseprijs
                          and    w.tas_runnummer      = gv_runnummer;
                       exception
                          when no_data_found
                          then
                             cm2_as_rowid             := ' ';
                       end;
                       
                       cm2_gebruikte_cover := v_maximaal_te_coveren * r_om2.mnd_factor * r_ms.tms_blocksize * r_ms.tms_pricing_unit;
                       
                       if gv_cl_margin = 2 or gv_cl_margin = 4
                       then
                          update temp_ap_werkbest_sessie
                          set    tas_in_cover_used = tas_in_cover_used + cm2_gebruikte_cover,
                                 tas_in_cover      = tas_in_cover + cm2_gebruikte_cover,
                                 tas_export        = 1
                          where  rowid             = r_asA.rowid;
                       else
                          update temp_ap_werkbest_sessie
                          set    tas_in_cover_used = tas_in_cover_used + cm2_gebruikte_cover,
                                 tas_export        = 1
                          where  rowid             = r_asA.rowid;
                       end if;
                    end loop;  -- einde van loop r_asA
                 end;
              end loop; -- einde van loop r_om2
              
              if cm2_as_rowid <> ' '
              then
                 update temp_ap_werkbest_sessie
                 set    tas_in_cover_used    = tas_in_cover_used + cm2_gebruikte_cover
                 where  rowid                = cm2_as_rowid;
              end if;
              
              cm2_benodigde_cover := ABS(v_saldo_positie + v_prod_geblok_aantal + v_spread_aantal) * r_ms.tms_blocksize*r_ms.tms_pricing_unit;
              
              v_margin_required  := v_margin_required/(cm2_benodigde_cover/(r_ms.tms_blocksize*r_ms.tms_pricing_unit))*
                                      (cm2_benodigde_cover/(r_ms.tms_blocksize*r_ms.tms_pricing_unit)-v_maximaal_te_coveren);
              v_gecovered_aantal := v_gecovered_aantal + v_maximaal_te_coveren;
                            
           end;
        end if;  -- Einde herberekenen van de gegevens
     -- Einde Deel 2b: In cover berekenen met mandje als ow.
     end if;

     if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'tussen 2 en 3');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie   : '||to_char(v_saldo_positie)||
                                                ' ; gecovered aantal : '||to_char(v_gecovered_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'spread bedrag   : '||to_char(v_spread_bedrag)||
                                                ' ; spread aantal : '||to_char(v_spread_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin required : '||to_char(v_margin_required)||
                                                ' ; prod geblok aant: '||to_char(v_prod_geblok_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
     end if;

     -- Deel 3: Zoek long call op (subtaak 173.3.3)
     if   v_saldo_positie + v_prod_geblok_aantal + v_spread_aantal + v_gecovered_aantal < 0
     then
        declare
          bs_nog_over_short       temp_margin_wb_sessie.tms_saldo_positie%type    := 0;
          bs_nog_over_long        temp_margin_wb_sessie.tms_saldo_positie%type    := 0;
          bs_aantal_spread        temp_margin_wb_sessie.tms_spread_aantal%type    := 0;
          bs_init_margin_spread   temp_margin_wb_sessie.tms_spread_bedrag%type    := 0;
          bs_spread_margin        temp_margin_wb_sessie.tms_spread_bedrag%type    := 0;
          bs_in_cover_used        temp_ap_werkbest_sessie.tas_in_cover_used%type  := 0;
          bs_as_bi_nummer         beleggingsinstrument.be_bi_nummer%type          := 0;
          bs_as_rowid             rowid;

          cursor msB is

          select   mB.tms_relatienr,     mB.tms_refsymbool,   mB.tms_soort,         mB.tms_symbool,
                   mB.tms_exerciseprijs, mB.tms_exp_datum,    mB.tms_saldo_positie, mB.tms_blocksize,
                   mB.tms_spread_aantal, mB.tms_pricing_unit, mB.tms_biedkoers,     mB.rowid
          from     temp_margin_wb_sessie mB
          where    mB.tms_relatienr     =  gv_terminalnummer
          and      mB.tms_refsymbool    =  r_ms.tms_refsymbool
          and      mB.tms_soort         =  'CALL'
          and      mB.tms_exp_datum     >= r_ms.tms_exp_datum
          and      mB.tms_exerciseprijs >= r_ms.tms_exerciseprijs
          and      mB.tms_saldo_positie >= 1
          and      mB.tms_runnnummer    =  gv_runnummer
          order by mB.tms_relatienr, mB.tms_refsymbool, mB.tms_soort, mB.tms_exerciseprijs, mB.tms_exp_datum;

        begin

          for r_msB in msB
          loop

             if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
             then
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Is er iets gevonden in Deel 3 zoeken long call op?');
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'refsymbool    : '||r_msB.tms_refsymbool||
                                                        ' ; soort : '||r_msB.tms_soort);
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'symbool       : '||r_msB.tms_symbool   ||
                                                        ' ; exerciseprijs : '||to_char(r_msB.tms_exerciseprijs));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'exp datum     : '||r_msB.tms_exp_datum);
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie : '||to_char(r_msB.tms_saldo_positie)||
                                                        ' ; spread aantal : '||to_char(r_msB.tms_spread_aantal));
                FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
             end if;

            bs_aantal_spread        := 0;
            bs_spread_margin        := 0;
            bs_in_cover_used        := 0;
            bs_as_bi_nummer         := 0;

            -- ophalen van de aktuele in_cover_used van de long call
            select a.tas_in_cover_used, a.tas_bi_type,   a.rowid
            into   bs_in_cover_used,    bs_as_bi_nummer, bs_as_rowid
            from   temp_ap_werkbest_sessie a
            where  a.tas_relatienr      = gv_terminalnummer
            and    a.tas_rekening_soort = 0
            and    a.tas_rekening_munts = ' '
            and    a.tas_rekeningnr     = ' '
            and    a.tas_symbool        = r_msB.tms_symbool
            and    a.tas_optietype      = r_msB.tms_soort
            and    a.tas_expiratiedatum = r_msB.tms_exp_datum
            and    a.tas_exerciseprijs  = r_msB.tms_exerciseprijs
            and    a.tas_runnummer      = gv_runnummer;

            -- Uitgangssituatie bepalen
            bs_nog_over_short := abs(v_saldo_positie + v_prod_geblok_aantal + v_spread_aantal + v_gecovered_aantal);
            bs_nog_over_long  := r_msB.tms_saldo_positie - r_msB.tms_spread_aantal;

            -- Bij verschillende blocksizes: long omrekenen naar blocksize short pos. (afrondend naar beneden)
            bs_nog_over_long := trunc(bs_nog_over_long*(r_msB.tms_blocksize*r_msB.tms_pricing_unit)/
                                                       (r_ms.tms_blocksize*r_ms.tms_pricing_unit),0);
            -- Bepalen welk aantal te gebruiken bij de berekening
            if bs_nog_over_long < bs_nog_over_short
            then
               bs_aantal_spread := bs_nog_over_long;
            else
               bs_aantal_spread := bs_nog_over_short;
            end if;
            -- Aanpassen van de initial margin aan de nieuwe spread situatie
            if bs_aantal_spread = 0
            then
               bs_init_margin_spread := 0;
            else
               bs_init_margin_spread := v_margin_required / bs_nog_over_short * bs_aantal_spread;
            end if;
            -- Berekenen van het spread bedrag:
            if r_msB.tms_exerciseprijs > r_ms.tms_exerciseprijs
            then
               bs_spread_margin := (r_msB.tms_exerciseprijs/r_msB.tms_pricing_unit-
                                    r_ms.tms_exerciseprijs/r_ms.tms_pricing_unit)*
                                    r_ms.tms_blocksize*r_ms.tms_pricing_unit*bs_aantal_spread;
            else
               bs_spread_margin := 0;
            end if;

            -- Time spread
            if r_msB.tms_exp_datum <> r_ms.tms_exp_datum
            then
               -- Berekende margin nooit lager dan verschil tussen de premies
               if bs_spread_margin < ABS(bs_aantal_spread*r_ms.tms_blocksize*r_ms.tms_laatkoers) -
                                     ABS(bs_aantal_spread*r_ms.tms_pricing_unit*r_msB.tms_blocksize*
                                                          r_msB.tms_biedkoers/r_msB.tms_pricing_unit)
               then
                  bs_spread_margin := ABS(bs_aantal_spread*r_ms.tms_blocksize*r_ms.tms_laatkoers) -
                                      ABS(bs_aantal_spread*r_ms.tms_pricing_unit*r_msB.tms_blocksize*
                                                          r_msB.tms_biedkoers/r_msB.tms_pricing_unit);
               end if;
               -- index opties
               if bs_as_bi_nummer between 3000 and 3899
               then
                  -- Minimum spread bedrag
                  if bs_spread_margin < i_minimum_spread_bedrag * bs_aantal_spread
                  then
                     bs_spread_margin := i_minimum_spread_bedrag * bs_aantal_spread;
                  end if;
                  -- Margintoeslag time spreads
                  if r_msB.tms_exerciseprijs = r_ms.tms_exerciseprijs
                  then
                     bs_spread_margin := bs_spread_margin + i_toeslag_time_spread*bs_aantal_spread;
                  end if;
               end if;
            end if;

            -- Toeslag optiemargin
            bs_spread_margin := (1 + (i_optiemargin_toeslag/100)) * bs_spread_margin;
            bs_spread_margin := (1 + (gv_cl_margin_toeslag/100)) * bs_spread_margin;

            -- Bijwerken van de totalen:
            if bs_spread_margin < bs_init_margin_spread
            then
               -- Bijwerken van de gegevens van de short optie
               v_spread_bedrag   := v_spread_bedrag + bs_spread_margin;
               v_margin_required := v_margin_required - bs_init_margin_spread;
               v_spread_aantal   := v_spread_aantal + bs_aantal_spread;

               -- aanpassen van de berekende bs_aantal_spread om naar boven af te ronden
               if (bs_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/(r_msB.tms_blocksize*r_msB.tms_pricing_unit)))-
                   trunc(bs_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                        (r_msB.tms_blocksize*r_msB.tms_pricing_unit)),0)>0
               then
                  bs_aantal_spread := trunc(bs_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                            (r_msB.tms_blocksize*r_msB.tms_pricing_unit)),0)+1;
               else
                  bs_aantal_spread := trunc(bs_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                            (r_msB.tms_blocksize*r_msB.tms_pricing_unit)),0);
               end if;

               -- Bijwerken van de gegevens van de long posities
               update temp_margin_wb_sessie
               set    tms_spread_aantal = tms_spread_aantal + bs_aantal_spread
               where  rowid = r_msB.rowid;

               update temp_ap_werkbest_sessie
               set    tas_in_cover_used = tas_in_cover_used + bs_aantal_spread
               where  rowid = bs_as_rowid;
            end if;
          end loop; -- einde van loop r_msB
        end;
     -- Einde Deel 3: Zoek long call op
     end if;

     if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'na 3');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie   : '||to_char(v_saldo_positie)||
                                                ' ; gecovered aantal : '||to_char(v_gecovered_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'spread bedrag   : '||to_char(v_spread_bedrag)||
                                                ' ; spread aantal : '||to_char(v_spread_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin required : '||to_char(v_margin_required)||
                                                ' ; prod geblok aant: '||to_char(v_prod_geblok_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
     end if;

     -- Als laatste de short optie bij werken met de aangepaste gegevens
     -- Omdat alle wijzigingen in de variabelen zijn bijgehouden kunnen deze gebruikt worden
     -- om het record te updaten
     update temp_margin_wb_sessie
     set    tms_spread_bedrag   = v_spread_bedrag,
            tms_spread_aantal   = v_spread_aantal,
            tms_margin_required = v_margin_required,
            tms_gecovered       = v_gecovered_aantal
     where  rowid = r_ms.rowid;

     end loop;  -- einde van loop r_ms

end ma_call_margin;
-- EINDE CODE PROCEDURE MA_CALL_MARGIN


-- DE CODE VOOR DE PROCEDURE MA_PUT_MARGIN
-- in deze procedure wordt het put-optie gedeelte afgehandeld van de margin berekening
-- vergelijk subtaak 5 van programma 173 br-Opt Fut posities(Sessie)
procedure ma_put_margin
(i_minimum_spread_bedrag  in tabelgegevens.tb_waarde%type
,i_toeslag_time_spread    in tabelgegevens.tb_waarde%type
,i_optiemargin_toeslag    in tabelgegevens.tb_waarde%type
)

is

  v_saldo_positie            temp_margin_wb_sessie.tms_saldo_positie%type          := 0;
  v_prod_geblok_aantal       temp_margin_wb_sessie.tms_prod_geblok_aantal%type     := 0;
  v_spread_bedrag            temp_margin_wb_sessie.tms_spread_bedrag%type          := 0;
  v_spread_aantal            temp_margin_wb_sessie.tms_spread_aantal%type          := 0;
  v_margin_required          temp_margin_wb_sessie.tms_margin_required%type        := 0;

cursor ms is

select   m.tms_relatienr,       m.tms_refsymbool,         m.tms_soort,         m.tms_symbool,
         m.tms_exerciseprijs,   m.tms_exp_datum,          m.tms_saldo_positie, m.tms_laatkoers,
         m.tms_blocksize,       m.tms_margin_required,    m.tms_spread_aantal, m.tms_spread_bedrag,
         m.tms_straddle_aantal, m.tms_pricing_unit,       m.tms_runnnummer,    m.tms_prod_geblok_aantal,
         m.rowid
from     temp_margin_wb_sessie m
where    m.tms_relatienr     =  gv_terminalnummer
and      m.tms_soort         =  'PUT'
and      m.tms_saldo_positie <= -1
and      m.tms_runnnummer    =  gv_runnummer
order by m.tms_refsymbool asc, m.tms_exerciseprijs desc, m.tms_laatkoers desc, m.tms_exp_datum desc;

begin
     for r_ms in ms
     loop

     -- Variabelen die gebruikt worden voor het updaten van het record uit de loop.
     -- Vullen met de waarden uit het record, zodat deze aangepast kunnen worden.
     v_saldo_positie      := r_ms.tms_saldo_positie;
     v_prod_geblok_aantal := r_ms.tms_prod_geblok_aantal;
     v_spread_bedrag      := r_ms.tms_spread_bedrag;
     v_spread_aantal      := r_ms.tms_spread_aantal;
     v_margin_required    := r_ms.tms_margin_required;

     if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In procedure FIAT_MARGIN.ma_put_margin');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'onderhanden zijnde put optie');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ref symbool     : '||r_ms.tms_refsymbool||
                                                ' ; soort : '||r_ms.tms_soort);
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'symbool         : '||r_ms.tms_symbool||
                                                ' ; exerciseprijs : '||to_char(r_ms.tms_exerciseprijs));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'expiratiedatum  : '||r_ms.tms_exp_datum);
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie   : '||to_char(v_saldo_positie)||
                                                ' ; spread bedrag : '||to_char(v_spread_bedrag));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'spread aantal   : '||to_char(v_spread_aantal)||
                                                ' ; margin required : '||to_char(v_margin_required));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'prod geblok aant: '||to_char(v_prod_geblok_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
     end if;

     -- Deel 1: Zoek bijbehorende long put op (subtaak 173.4.1)
     if v_saldo_positie + v_prod_geblok_aantal + v_spread_aantal < 0
     then
        declare
          lp_nog_over_short           temp_margin_wb_sessie.tms_saldo_positie%type        := 0;
          lp_nog_over_long            temp_margin_wb_sessie.tms_saldo_positie%type        := 0;
          lp_aantal_spread            temp_margin_wb_sessie.tms_spread_aantal%type        := 0;
          lp_init_margin_spread       temp_margin_wb_sessie.tms_spread_bedrag%type        := 0;
          lp_spread_margin            temp_margin_wb_sessie.tms_spread_bedrag%type        := 0;
          lp_as_bi_nummer             temp_ap_werkbest_sessie.tas_bi_type%type            := 0;
          lp_as_in_cover_used         temp_ap_werkbest_sessie.tas_in_cover_used%type      := 0;
          lp_as_rowid                 rowid;

          cursor msA is

          select   mA.tms_relatienr,     mA.tms_refsymbool,   mA.tms_soort,         mA.tms_symbool,
                   mA.tms_exerciseprijs, mA.tms_exp_datum,    mA.tms_saldo_positie, mA.tms_blocksize,
                   mA.tms_spread_aantal, mA.tms_pricing_unit, mA.tms_biedkoers,     rowid
          from     temp_margin_wb_sessie mA
          where    mA.tms_relatienr     =  gv_terminalnummer
          and      mA.tms_refsymbool    =  r_ms.tms_refsymbool
          and      mA.tms_soort         =  'PUT'
          and      mA.tms_exerciseprijs >= r_ms.tms_exerciseprijs
          and      mA.tms_exp_datum     >= r_ms.tms_exp_datum
          and      mA.tms_saldo_positie >= 1
          and      mA.tms_runnnummer    =  gv_runnummer
          order by mA.Tms_exp_datum asc, mA.tms_exerciseprijs asc;

        begin

          for r_msA in msA
          loop
            if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In deel 1 zoek bijbehorende long put op');
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'ref symbool : '||r_msA.tms_refsymbool||
                                                       ' ; soort : '||r_msA.tms_soort);
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'symbool     : '||r_msA.tms_symbool||
                                                       ' ; exerciseprijs : '||to_char(r_msA.tms_exerciseprijs));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'epiratiedatum : '||r_msA.tms_exp_datum);
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie : '||to_char(r_msA.tms_saldo_positie)||
                                                       ' ; spread aantal : '||to_char(r_msA.tms_spread_aantal));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
            end if;

            lp_aantal_spread            := 0;
            lp_spread_margin            := 0;
            lp_as_bi_nummer             := 0;
            lp_as_in_cover_used         := 0;

            -- Ophalen van de aktuele in cover used en bi type van de optie
            select a.tas_in_cover_used, a.tas_bi_type,   a.rowid
            into   lp_as_in_cover_used, lp_as_bi_nummer, lp_as_rowid
            from   temp_ap_werkbest_sessie a
            where  a.tas_relatienr      = gv_terminalnummer
            and    a.tas_rekening_soort = 0
            and    a.tas_rekening_munts = ' '
            and    a.tas_rekeningnr     = ' '
            and    a.tas_symbool        = r_msA.tms_symbool
            and    a.tas_optietype      = r_msA.tms_soort
            and    a.tas_expiratiedatum = r_msA.tms_exp_datum
            and    a.tas_exerciseprijs  = r_msA.tms_exerciseprijs
            and    a.tas_runnummer      = gv_runnummer;

            lp_nog_over_short := ABS(v_saldo_positie + v_prod_geblok_aantal + v_spread_aantal);
            lp_nog_over_long  := r_msA.tms_saldo_positie - r_msA.tms_spread_aantal;

            -- Bij verschillende blocksizes: long omrekenen naar blocksize short pos. (afrondend naar beneden)
            lp_nog_over_long  := trunc(lp_nog_over_long*(r_msA.tms_blocksize*r_msA.tms_pricing_unit)/
                                                        (r_ms.tms_blocksize*r_ms.tms_pricing_unit),0);
            -- Bepalen welk aantal te gebruiken voor de berekening:
            if lp_nog_over_long <= lp_nog_over_short
            then
               lp_aantal_spread := lp_nog_over_long;
            else
               lp_aantal_spread := lp_nog_over_short;
            end if;
            -- Aanpassen van de initial margin aan de nieuwe spread situatie:
            if lp_aantal_spread = 0
            then
               lp_init_margin_spread := 0;
            else
               lp_init_margin_spread := v_margin_required/lp_nog_over_short*lp_aantal_spread;
            end if;
            -- Berekenen van de spread margin
            if r_ms.tms_exerciseprijs > r_msA.tms_exerciseprijs
            then
               lp_spread_margin := (r_ms.tms_exerciseprijs/r_ms.tms_pricing_unit -
                                    r_msA.tms_exerciseprijs/r_msA.tms_pricing_unit)*
                                    r_ms.tms_blocksize*r_ms.tms_pricing_unit*lp_aantal_spread;
            else
               lp_spread_margin := 0;
            end if;

            -- Time spread
            if r_ms.tms_exp_datum <> r_msA.tms_exp_datum
            then
               -- Berekende margin nooit lager dan verschil tussen de premies
               if lp_spread_margin < ABS(lp_aantal_spread*r_ms.tms_blocksize*r_ms.tms_laatkoers)-
                                     ABS(lp_aantal_spread*r_ms.tms_pricing_unit*r_msA.tms_blocksize*
                                                                             r_msA.tms_biedkoers/r_msA.tms_pricing_unit)
               then
                  lp_spread_margin := ABS(lp_aantal_spread*r_ms.tms_blocksize*r_ms.tms_laatkoers)-
                                      ABS(lp_aantal_spread*r_ms.tms_pricing_unit*r_msA.tms_blocksize*
                                                                              r_msA.tms_biedkoers/r_msA.tms_pricing_unit);
               end if;
               -- index opties
               if lp_as_bi_nummer between 3000 and 3899
               then
                  -- Minimum spread bedrag
                  if lp_spread_margin < i_minimum_spread_bedrag * lp_aantal_spread
                  then
                     lp_spread_margin := i_minimum_spread_bedrag * lp_aantal_spread;
                  end if;
                  -- Margintoeslag time spreads
                  if r_ms.tms_exerciseprijs = r_msA.tms_exerciseprijs
                  then
                     lp_spread_margin := lp_spread_margin + i_toeslag_time_spread*lp_aantal_spread;
                  end if;
               end if;
            end if;

            -- Toeslag optiemargin
            lp_spread_margin := (1 + (i_optiemargin_toeslag/100)) * lp_spread_margin;
            lp_spread_margin := (1 + (gv_cl_margin_toeslag/100)) * lp_spread_margin;

            -- Bijwerken van de totalen:
            if lp_spread_margin < lp_init_margin_spread
            then
               -- Bijwerken van de gegevens van de short optie
               v_spread_bedrag   := v_spread_bedrag + lp_spread_margin;
               v_margin_required := v_margin_required - lp_init_margin_spread;
               v_spread_aantal   := v_spread_aantal + lp_aantal_spread;

               -- aanpassen van het berekende lc_aantal_spread om naar boven af te ronden
               if (lp_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/(r_msA.tms_blocksize*r_msA.tms_pricing_unit)))-
                   trunc(lp_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                        (r_msA.tms_blocksize*r_msA.tms_pricing_unit)),0)>0
               then
                  lp_aantal_spread := trunc(lp_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                            (r_msA.tms_blocksize*r_msA.tms_pricing_unit)),0)+1;
               else
                  lp_aantal_spread := trunc(lp_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                            (r_msA.tms_blocksize*r_msA.tms_pricing_unit)),0);
               end if;

               -- Bijwerken van de gegevens van de long posities:
               update temp_margin_wb_sessie
               set    tms_spread_aantal = tms_spread_aantal + lp_aantal_spread
               where  rowid             = r_msA.rowid;

               update temp_ap_werkbest_sessie
               set    tas_in_cover_used = tas_in_cover_used + lp_aantal_spread
               where  rowid             = lp_as_rowid;
            end if;
          end loop;  -- einde loop r_msA
        end;
     -- Einde Deel 1: Zoek bijbehorende long put op
     end if;

     if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'tussen 1 en 2');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie   : '||to_char(v_saldo_positie));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'spread bedrag   : '||to_char(v_spread_bedrag)||
                                                ' ; spread aantal : '||to_char(v_spread_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin required : '||to_char(v_margin_required)||
                                                ' ; prod geblok aant: '||to_char(v_prod_geblok_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
     end if;

     -- Deel 2 Zoek bijbehorende long put af (subtaak 173.4.2)
     if  v_saldo_positie + v_prod_geblok_aantal + v_spread_aantal < 0
     then
        declare
          bs_nog_over_short            temp_margin_wb_sessie.tms_saldo_positie%type   := 0;
          bs_nog_over_long             temp_margin_wb_sessie.tms_saldo_positie%type   := 0;
          bs_aantal_spread             temp_margin_wb_sessie.tms_spread_aantal%type   := 0;
          bs_init_margin_spread        temp_margin_wb_sessie.tms_spread_bedrag%type   := 0;
          bs_spread_margin             temp_margin_wb_sessie.tms_spread_bedrag%type   := 0;
          bs_be_bi_nummer              beleggingsinstrument.be_bi_nummer%type         := 0;
          bs_as_in_cover_used          temp_ap_werkbest_sessie.tas_in_cover_used%type := 0;
          bs_as_rowid                  rowid;

          cursor msB is

          select   mB.tms_relatienr,     mB.tms_refsymbool,   mB.tms_soort,         mB.tms_symbool,
                   mB.tms_exerciseprijs, mB.tms_exp_datum,    mB.tms_saldo_positie, mB.tms_blocksize,
                   mB.tms_spread_aantal, mB.tms_pricing_unit, mB.tms_biedkoers,     mB.rowid
          from     temp_margin_wb_sessie mB
          where    mB.tms_relatienr     =  gv_terminalnummer
          and      mB.tms_refsymbool    =  r_ms.tms_refsymbool
          and      mB.tms_soort         =  'PUT'
          and      mB.tms_exerciseprijs <= r_ms.tms_exerciseprijs
          and      mB.tms_exp_datum     >= r_ms.tms_exp_datum
          and      mB.tms_saldo_positie >= 1
          and      mB.tms_runnnummer    =  gv_runnummer
          order by mB.tms_relatienr, mB.tms_refsymbool, mB.tms_soort, mB.tms_exerciseprijs desc, mB.tms_exp_datum;

          begin

            for r_msB in msB
            loop
              if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'deel 2 zoek bijbehorende long put af');
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'refsymbool : '||r_msB.tms_refsymbool||
                                                         ' ; soort : '||r_msB.tms_soort);
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'symbool    : '||r_msB.tms_symbool   ||
                                                         ' ; exerciseprijs : '||to_char(r_msB.tms_exerciseprijs));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'expiratiedatum : '||r_msB.tms_exp_datum);
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
              end if;

              bs_aantal_spread             := 0;
              bs_spread_margin             := 0;
              bs_be_bi_nummer              := 0;
              bs_as_in_cover_used          := 0;

              -- ophalen van de aktuele positie en bi-type van de long put
              select a.tas_in_cover_used,  a.tas_bi_type,   a.rowid
              into   bs_as_in_cover_used,  bs_be_bi_nummer, bs_as_rowid
              from   temp_ap_werkbest_sessie a
              where  a.tas_relatienr       = gv_terminalnummer
              and    a.tas_rekening_soort  = 0
              and    a.tas_rekening_munts  = ' '
              and    a.tas_rekeningnr      = ' '
              and    a.tas_symbool         = r_msB.tms_symbool
              and    a.tas_optietype       = r_msB.tms_soort
              and    a.tas_expiratiedatum  = r_msB.tms_exp_datum
              and    a.tas_exerciseprijs   = r_msB.tms_exerciseprijs
              and    a.tas_runnummer       = gv_runnummer;

              -- Uitgangssituatie bepalen
              bs_nog_over_short := ABS(v_saldo_positie + v_prod_geblok_aantal + v_spread_aantal);
              bs_nog_over_long  := r_msB.tms_saldo_positie - r_msB.tms_spread_aantal;

              -- Bij verschillende blocksizes: long omrekenen naar blocksize short pos. (afrondend naar beneden)
              bs_nog_over_long := trunc(bs_nog_over_long*(r_msB.tms_blocksize*r_msB.tms_pricing_unit)/
                                                                    (r_ms.tms_blocksize*r_ms.tms_pricing_unit),0);

              if bs_nog_over_long < bs_nog_over_short
              then
                 bs_aantal_spread := bs_nog_over_long;
              else
                 bs_aantal_spread := bs_nog_over_short;
              end if;

              -- Aanpassen vsn de initial margin aan de nieuwe spread situatie
              if bs_aantal_spread = 0
              then
                 bs_init_margin_spread := 0;
              else
                 bs_init_margin_spread := v_margin_required/bs_nog_over_short*bs_aantal_spread;
              end if;
              -- Berekenen van het spread bedrag
              if r_ms.tms_exerciseprijs > r_msB.tms_exerciseprijs
              then
                 bs_spread_margin := (r_ms.tms_exerciseprijs/r_ms.tms_pricing_unit -
                                      r_msB.tms_exerciseprijs/r_msB.tms_pricing_unit) *
                                      r_ms.tms_blocksize * r_ms.tms_pricing_unit * bs_aantal_spread;
              else
                 bs_spread_margin := 0;
              end if;

              -- Time spread
              if r_msB.tms_exp_datum <> r_ms.tms_exp_datum
              then
                 -- Berekende margin nooit lager dan verschil tussen de premies
                 if bs_spread_margin < ABS(bs_aantal_spread*r_ms.tms_blocksize*r_ms.tms_laatkoers)-
                                       ABS(bs_aantal_spread*r_ms.tms_pricing_unit*
                                                     r_msB.tms_blocksize*r_msB.tms_biedkoers/r_msB.tms_pricing_unit)
                 then
                    bs_spread_margin := ABS(bs_aantal_spread*r_ms.tms_blocksize*r_ms.tms_laatkoers)-
                                        ABS(bs_aantal_spread*r_ms.tms_pricing_unit*
                                                      r_msB.tms_blocksize*r_msB.tms_biedkoers/r_msB.tms_pricing_unit);
                 end if;
                 -- index opties
                 if bs_be_bi_nummer between 3000 and 3899
                 then
                    -- Minimum spread bedrag
                    if bs_spread_margin < i_minimum_spread_bedrag*bs_aantal_spread
                    then
                       bs_spread_margin := i_minimum_spread_bedrag*bs_aantal_spread;
                    end if;
                    -- Margintoeslag time spreads
                    if r_ms.tms_exerciseprijs <> r_msB.tms_exerciseprijs
                    then
                       bs_spread_margin := bs_spread_margin + i_toeslag_time_spread*bs_aantal_spread;
                    end if;
                 end if;
              end if;

              -- Toeslag optiemargin
              bs_spread_margin := (1 + (i_optiemargin_toeslag/100)) * bs_spread_margin;
              bs_spread_margin := (1 + (gv_cl_margin_toeslag/100)) * bs_spread_margin;

              -- Bijwerken van de totalen:
              if bs_spread_margin < bs_init_margin_spread
              then
                 -- Bijwerken van de short positie
                 v_spread_bedrag   := v_spread_bedrag + bs_spread_margin;
                 v_margin_required := v_margin_required - bs_init_margin_spread;
                 v_spread_aantal   := v_spread_aantal + bs_aantal_spread;

                 -- Aanpassen van de berekende bs_aantal_spread om naar boven af te ronden
                 if (bs_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/(r_msB.tms_blocksize*r_msB.tms_pricing_unit)))-
                     trunc(bs_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                                               (r_msB.tms_blocksize*r_msB.tms_pricing_unit)),0)>0
                 then
                    bs_aantal_spread := trunc(bs_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                              (r_msB.tms_blocksize*r_msB.tms_pricing_unit)),0)+1;
                 else
                    bs_aantal_spread := trunc(bs_aantal_spread*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                              (r_msB.tms_blocksize*r_msB.tms_pricing_unit)),0);
                 end if;

                 -- Bijwerken van de gegevens van de long posities
                 update temp_margin_wb_sessie
                 set    tms_spread_aantal = tms_spread_aantal + bs_aantal_spread
                 where  rowid             = r_msB.rowid;

                 if bs_as_rowid <> ' ' and bs_as_rowid is not null
                 then
                    update temp_ap_werkbest_sessie
                    set    tas_in_cover_used = tas_in_cover_used + bs_aantal_spread
                    where  rowid             = bs_as_rowid;
                 end if;
              end if;

            end loop;  -- einde van loop r_msB
          end;
     -- Einde Deel 2: Zoek bijbehorende long put af
     end if;

     if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'na 2');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie   : '||to_char(v_saldo_positie));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'spread bedrag   : '||to_char(v_spread_bedrag)||
                                                ' ; spread aantal : '||to_char(v_spread_aantal));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin required : '||to_char(v_margin_required));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
     end if;

     -- Als laatste de short optie bijwerken met de aangepaste gegevens
     -- omdat alle wijzigingen in de variabelen zijn bijgehouden kunnen deze gebruikt worden
     -- om het record te updaten.
     update temp_margin_wb_sessie
     set    tms_spread_bedrag   = v_spread_bedrag,
            tms_spread_aantal   = v_spread_aantal,
            tms_margin_required = v_margin_required
     where  rowid               = r_ms.rowid;

     end loop;  -- Einde van de r_ms loop

end ma_put_margin;
-- EINDE CODE PROCEDURE MA_PUT_MARGIN


-- DE CODE VOOR DE PROCEDURE MA_STRADDLE_STRANGLE
-- In deze procedure wordt het straddle en strangle gedeelte afgehandeld van de margin berekening
-- vergelijk subtaak 5 van programma 173 br-Opt Fut posities(Sessie)
procedure ma_straddle_strangle
(i_optiemargin_toeslag           in     tabelgegevens.tb_waarde%type
)

is

  v_margin_required     temp_margin_wb_sessie.tms_margin_required%type     := 0;
  v_straddle_aantal     temp_margin_wb_sessie.tms_straddle_aantal%type     := 0;
  v_straddle_bedrag     temp_margin_wb_sessie.tms_straddle_bedrag%type     := 0;

cursor ms is

select   m.tms_relatienr,          m.tms_refsymbool,         m.tms_soort,           m.tms_symbool,
         m.tms_exp_datum,          m.tms_exerciseprijs,      m.tms_saldo_positie,   m.tms_slotkoers_voriged,
         m.tms_laatkoers,          m.tms_blocksize,          m.tms_margin_required, m.tms_gecovered,
         m.tms_spread_aantal,      m.tms_straddle_aantal,    m.tms_straddle_bedrag, m.tms_pricing_unit,
         m.tms_prod_geblok_aantal, m.rowid
from     temp_margin_wb_sessie m
where    m.tms_relatienr  = gv_terminalnummer
and      m.tms_soort      = 'CALL'
and      m.tms_runnnummer = gv_runnummer
and      (m.tms_saldo_positie + m.tms_prod_geblok_aantal + m.tms_spread_aantal + m.tms_gecovered) < 0
order by m.tms_relatienr,     m.tms_refsymbool, m.tms_soort, m.tms_biedkoers desc, m.tms_exp_datum,
         m.tms_exerciseprijs, m.tms_symbool;

begin
  for r_ms in ms
  loop

  -- variabelen die gebruikt worden voor het updaten van het record uit de loop hun initiele waarde geven
  v_margin_required := r_ms.tms_margin_required;
  v_straddle_aantal := r_ms.tms_straddle_aantal;
  v_straddle_bedrag := r_ms.tms_straddle_bedrag;

  if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'onderdeel straddle_strangle :');
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'gegevens van de onderhanden zijnde call optie:');
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'refsymbool      : '||r_ms.tms_refsymbool||
                                             ' ; soort : '||r_ms.tms_soort);
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'symbool         : '||r_ms.tms_symbool   ||
                                             ' ; expiratie datum : '||r_ms.tms_exp_datum);
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'exercprijs      : '||to_char(r_ms.tms_exerciseprijs)||
                                             ' ; saldo positie : '||to_char(r_ms.tms_saldo_positie));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'spread aantal   : '||to_char(r_ms.tms_spread_aantal)||
                                             ' ; straddle aantal : '||to_char(r_ms.tms_straddle_aantal));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'gecovered       : '||to_char(r_ms.tms_gecovered));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin required : '||to_char(v_margin_required)||
                                             ' ; straddle aantal : '||to_char(v_straddle_aantal));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'straddle bedrag : '||to_char(v_straddle_bedrag)||
                                             ' ; prod geblok aant : '||to_char(r_ms.tms_prod_geblok_aantal));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
  end if;

  -- Zoeken naar de short put
  -- de conditie zit al in het select statement
  declare
    st_aantal_over_call          temp_margin_wb_sessie.tms_saldo_positie%type    := 0;
    st_aantal_over_put           temp_margin_wb_sessie.tms_saldo_positie%type    := 0;
    st_aantal_straddle           temp_margin_wb_sessie.tms_straddle_aantal%type  := 0;
    st_hoogste_premie            temp_margin_wb_sessie.tms_biedkoers%type        := 0;
    st_rekenveld                 number(15,9)                                    := 0;
    st_straddle_margin           temp_margin_wb_sessie.tms_straddle_bedrag%type  := 0;

    cursor msA is

    select   ma.tms_relatienr,         ma.tms_refsymbool,         ma.tms_soort,              ma.tms_symbool,
             ma.tms_exp_datum,         ma.tms_exerciseprijs,      ma.tms_saldo_positie,      ma.tms_marginfactor,
             ma.tms_slotkoers_voriged, ma.tms_laatkoers,          ma.tms_blocksize,          ma.tms_margin_required,
             ma.tms_gecovered,         ma.tms_spread_aantal,      ma.tms_straddle_aantal,    ma.tms_straddle_bedrag,
             ma.tms_pricing_unit,      ma.tms_prod_geblok_aantal, ma.rowid
    from     temp_margin_wb_sessie ma
    where    ma.tms_relatienr       =  gv_terminalnummer
    and      ma.tms_refsymbool      =  r_ms.tms_refsymbool
    and      ma.tms_soort           =  'PUT'
    and      ma.tms_symbool         =  r_ms.tms_symbool
    and      ma.tms_exp_datum       =  r_ms.tms_exp_datum
    and      ma.tms_exerciseprijs   <= r_ms.tms_exerciseprijs
    and      ma.tms_saldo_positie   <= -1
    and      ma.tms_runnnummer      =  gv_runnummer
    order by ma.tms_relatienr, ma.tms_refsymbool,    ma.tms_soort,   ma.tms_biedkoers desc,
             ma.tms_exp_datum, ma.tms_exerciseprijs, ma.tms_symbool;

  begin

    for r_msA in msA
    loop
       -- resetten van de hulpvelden:
       st_aantal_straddle    := 0;
       st_hoogste_premie     := 0;
       st_rekenveld          := 0;
       st_straddle_margin    := 0;

       if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
       then
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'de gegevens van de onderhanden zijnde put optie');
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'refsymbool    : '||r_msA.tms_refsymbool||
                                                  ' ; soort : '||r_msA.tms_soort);
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'symbool       : '||r_msA.tms_symbool   ||
                                                  ' ; expiratie datum : '||r_msA.tms_exp_datum);
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'exercprijs    : '||to_char(r_msA.tms_exerciseprijs)||
                                                  ' ; saldo positie : '||to_char(r_msA.tms_saldo_positie));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'spread aantal : '||to_char(r_msA.tms_spread_aantal)||
                                                  ' ; straddle aantal : '||to_char(r_msA.tms_straddle_aantal));
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
       end if;


       -- Bepalen van het beschikbare aantal:
       st_aantal_over_call := ABS(r_ms.tms_saldo_positie + r_ms.tms_prod_geblok_aantal + r_ms.tms_spread_aantal +
                                  r_ms.tms_gecovered + v_straddle_aantal);
       st_aantal_over_put  := ABS(r_msA.tms_saldo_positie + r_msA.tms_prod_geblok_aantal + r_msA.tms_spread_aantal +
                                  r_msA.tms_gecovered + r_msA.tms_straddle_aantal);

       if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
       then
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'aantal over call : '||st_aantal_over_call||
                                                  ' ; aantal over put : '||st_aantal_over_put);
       end if;

       -- Bij verschillende blocksizes: put omrekenen naar blocksize call pos. (naar beneden afronden)
       st_aantal_over_put  := trunc((st_aantal_over_put*(r_msA.tms_blocksize*r_msA.tms_pricing_unit)/
                                    (r_ms.tms_blocksize*r_ms.tms_pricing_unit)),0);
       -- Bepalen welk aantal te gebruiken voor de berekening:
       if st_aantal_over_put < st_aantal_over_call
       then
          st_aantal_straddle := st_aantal_over_put;
       else
          st_aantal_straddle := st_aantal_over_call;
       end if;

       if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
       then
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'aantal straddle : '||st_aantal_straddle);
       end if;

       -- Verder gaan als het aantal straddle groter is dan 0
       if st_aantal_straddle > 0
       then
          -- Bepalen van de hoogste premie/Pricing unit
          if r_ms.tms_laatkoers/r_ms.tms_pricing_unit > r_msA.tms_laatkoers/r_msA.tms_pricing_unit
          then
             st_hoogste_premie := r_ms.tms_laatkoers/r_ms.tms_pricing_unit;
          else
             st_hoogste_premie := r_msA.tms_laatkoers/r_msA.tms_pricing_unit;
          end if;

          if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'hoogste premie : '||st_hoogste_premie);
          end if;

          -- Berekenen van het straddle bedrag
          if r_msA.tms_laatkoers > r_ms.tms_laatkoers
          then
             -- Koers Put > Koers Call
             st_rekenveld := 2*(r_msA.tms_exerciseprijs/r_msA.tms_pricing_unit)-r_msA.tms_slotkoers_voriged;
          else
             -- Koers Put <= Koers Call
             st_rekenveld := 2*r_ms.tms_slotkoers_voriged - (r_ms.tms_exerciseprijs/r_ms.tms_pricing_unit);
          end if;

          if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' Stap 1 rekenveld : '||st_rekenveld);
          end if;

          -- als het rekenveld kleiner dan 0 is dan moet deze op 0 worden gezet:
          st_rekenveld := GREATEST(st_rekenveld, 0);

          if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Stap 2 rekenveld : '||st_rekenveld);
          end if;

          if st_rekenveld <> 0
          then
             st_rekenveld := r_msA.tms_marginfactor/100 * st_rekenveld;
          end if;

          if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Stap 3 rekenveld : '||st_rekenveld);
          end if;

          -- De (hoogste) premie moet minimaal worden berekend
          st_rekenveld := st_rekenveld + st_hoogste_premie;

          if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Stap 4 rekenveld : '||st_rekenveld);
          end if;

          -- Het straddle bedrag berekenen
          st_straddle_margin := st_rekenveld*r_msA.tms_blocksize*r_msA.tms_pricing_unit*st_aantal_straddle;

          if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Stap 1 straddle margin : '||st_straddle_margin);
          end if;

          -- De berekende margin mag nooit lager dan som van de premies zijn:
          if st_straddle_margin < ABS(st_aantal_straddle*r_ms.tms_blocksize*r_ms.tms_laatkoers)+
                                  ABS(st_aantal_straddle*r_ms.tms_pricing_unit*r_msA.tms_blocksize*
                                      r_msA.tms_laatkoers/r_msA.tms_pricing_unit)
          then
             st_straddle_margin := ABS(st_aantal_straddle*r_ms.tms_blocksize*r_ms.tms_laatkoers)+
                                   ABS(st_aantal_straddle*r_ms.tms_pricing_unit*r_msA.tms_blocksize*
                                       r_msA.tms_laatkoers/r_msA.tms_pricing_unit);
          end if;

          if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Stap 2 straddle margin : '||st_straddle_margin);
          end if;

          -- Toeslag optiemargin uitvoeren
          st_straddle_margin := (1 + (i_optiemargin_toeslag/100)) * st_straddle_margin;
          st_straddle_margin := (1 + (gv_cl_margin_toeslag/100)) * st_straddle_margin;

          if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
          then
             FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Stap 3 straddle margin : '||st_straddle_margin);
          end if;

          -- Bijwerken van de gegevens
          -- Herberekenen van het de initial margin:
          -- Call optie:
          v_margin_required := v_margin_required/st_aantal_over_call*(st_aantal_over_call-st_aantal_straddle);
          v_straddle_aantal := v_straddle_aantal + st_aantal_straddle;
          v_straddle_bedrag := v_straddle_bedrag + st_straddle_margin / 2;

          -- aanpassen van het berekende st_aantal_straddle om het naar boven af te ronden voor de put optie:
          if (st_aantal_straddle*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/(r_msA.tms_blocksize*r_msA.tms_pricing_unit)))-
              trunc(st_aantal_straddle*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                    (r_msA.tms_blocksize*r_msA.tms_pricing_unit)),0)>0
          then
             st_aantal_straddle := trunc(st_aantal_straddle*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                         (r_msA.tms_blocksize*r_msA.tms_pricing_unit)),0) + 1;
          else
             st_aantal_straddle := trunc(st_aantal_straddle*(r_ms.tms_blocksize*r_ms.tms_pricing_unit/
                                         (r_msA.tms_blocksize*r_msA.tms_pricing_unit)),0);
          end if;

          -- Put optie
          update temp_margin_wb_sessie
          set    tms_margin_required = tms_margin_required/st_aantal_over_put*(st_aantal_over_put-st_aantal_straddle),
                 tms_straddle_aantal = tms_straddle_aantal + st_aantal_straddle,
                 tms_straddle_bedrag = tms_straddle_bedrag + st_straddle_margin / 2
          where  rowid = r_msA.rowid;

       end if;
    end loop;  -- einde van loop r_msA
  end;

  -- Bijwerken van de gegevens van de short optie:
  update temp_margin_wb_sessie
  set    tms_margin_required   = v_margin_required,
         tms_straddle_aantal   = v_straddle_aantal,
         tms_straddle_bedrag   = v_straddle_bedrag
  where  rowid  = r_ms.rowid;

  end loop;  -- einde van loop r_ms

end ma_straddle_strangle;
-- EINDE CODE PROCEDURE MA_STRADDLE_STRANGLE


-- DE CODE VOOR DE PROCEDURE MA_CROSS_MARGIN
procedure ma_cross_margin
(i_optiemargin_toeslag      in   tabelgegevens.tb_waarde%type
)

is

  v_margin_required         temp_margin_wb_sessie.tms_margin_required%type     := 0;
  v_cross_aantal            temp_margin_wb_sessie.tms_cross_aantal%type        := 0;
  v_cross_bedrag            temp_margin_wb_sessie.tms_cross_bedrag%type        := 0;

  cursor ms is

  select m.tms_refsymbool,      m.tms_soort,         m.tms_symbool,       m.tms_exp_datum,
         m.tms_exerciseprijs,   m.tms_saldo_positie, m.tms_laatkoers,     m.tms_blocksize,
         m.tms_margin_required, m.tms_gecovered,     m.tms_spread_aantal, m.tms_straddle_aantal,
         m.tms_pricing_unit,    m.tms_cross_aantal,  m.tms_cross_bedrag,  m.tms_prod_geblok_aantal,
         m.rowid
  from   temp_margin_wb_sessie m
  where  m.tms_relatienr       = gv_terminalnummer
  and    m.tms_soort           in ('CALL','PUT')
  and    m.tms_runnnummer      = gv_runnummer
  and    m.tms_saldo_positie + m.tms_gecovered + m.tms_spread_aantal + m.tms_straddle_aantal + m.tms_prod_geblok_aantal < 0
  and    exists (select 1                                            -- bepalen of er een future gekoppeld is aan
                 from  koppeltabel_cross_margin k                    -- de optie in de koppeltabel
                 where k.cm_optie_symbool    = m.tms_symbool)
  order by m.tms_relatienr, m.tms_refsymbool, m.tms_soort, m.tms_biedkoers desc, m.tms_exp_datum,
           m.tms_exerciseprijs, m.tms_symbool;

begin
  for r_ms in ms
  loop
     if gv_debuggen = 1 and gv_debug_runnummer = gv_runnummer
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'In onderdeel voor cross margin (FIAT_MARGIN.ma_cross_margin)');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
     end if;

     -- variabelen die gebruikt worden voor het updaten van het record uit de loop hun initiele waarde geven
     v_margin_required := r_ms.tms_margin_required;
     v_cross_aantal    := r_ms.tms_cross_aantal;
     v_cross_bedrag    := r_ms.tms_cross_bedrag;

     -- Het betreft een call optie (zie subtaak 173.6.2):
     if r_ms.tms_soort = 'CALL'
     then
        declare
           cf_aantal_over_optie         temp_margin_wb_sessie.tms_saldo_positie%type     := 0;
           cf_aantal_over_future        temp_margin_wb_sessie.tms_saldo_positie%type     := 0;
           cf_verhouding_future_optie   number(4)                                        := 0;
           cf_aantal_cross              temp_margin_wb_sessie.tms_cross_aantal%type      := 0;
           cf_bedrag_cross              temp_margin_wb_sessie.tms_cross_bedrag%type      := 0;

          cursor mcF is

              select mF.tms_relatienr,     mF.tms_soort,           mF.tms_symbool,
                     mF.tms_exp_datum,     mF.tms_positie_future,  mF.tms_blocksize,
                     mF.tms_spread_aantal, mF.tms_straddle_aantal, mF.tms_cross_aantal,
                     mF.rowid
              from   temp_margin_wb_sessie mF, koppeltabel_cross_margin kC
              where  mF.tms_relatienr      =  gv_terminalnummer
              and    mF.tms_soort          =  'FUT'
              and    mF.tms_exp_datum      >= r_ms.tms_exp_datum
              and    mF.tms_positie_future >= 1
              and    mF.tms_runnnummer     =  gv_runnummer
              and    kC.cm_optie_symbool   =  r_ms.tms_symbool   -- hier inner join op
              and    kC.cm_future_symbool  =  mF.tms_symbool     -- koppeltabel_cross_margin !!!
              order by mF.tms_relatienr, mF.tms_refsymbool, mF.tms_soort, mF.tms_biedkoers desc,
                       mF.tms_exp_datum, mF.tms_exerciseprijs, mF.tms_symbool;
        begin
           for r_mcF in mcF
           loop

              if gv_debuggen = 1 and gv_debug_runnummer = gv_runnummer
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'in het call optie/future gedeelte');
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie symbool        : '||r_ms.tms_symbool||
                                                          ' ; optie type    : '||r_ms.tms_soort);
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie expdatum       : '||r_ms.tms_exp_datum||
                                                          ' ; optie exerciseprijs : '||to_char(r_ms.tms_exerciseprijs));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie positie        : '||to_char(r_ms.tms_saldo_positie)||
                                                          ' ; optie blocksize : '||to_char(r_ms.tms_blocksize));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie marginrequired : '||to_char(r_ms.tms_margin_required)||
                                                          ' ; optie gecovered   : '||to_char(r_ms.tms_gecovered));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie spread aantal  : '||to_char(r_ms.tms_spread_aantal)||
                                                          ' ;  optie straddle aantal : '||to_char(r_ms.tms_straddle_aantal));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie cross aantal   : '||to_char(v_cross_aantal)||
                                                          ' optie cross bedrag : '||to_char(v_cross_bedrag));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie pricing unit   : '||to_char(r_ms.tms_pricing_unit));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'future symbool       : '||r_mcF.tms_symbool||
                                                          ' ; future expdatum   : '||r_mcF.tms_exp_datum);
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'future positie       : '||to_char(r_mcF.tms_positie_future)||
                                                          ' ; future blocksize : '||to_char(r_mcF.tms_blocksize));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'future cross aantal  : '||to_char(r_mcF.tms_cross_aantal)||
                                                          ' ; future spread aantal : '||to_char(r_mcF.tms_spread_aantal));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'future straddle aant : '||to_char(r_mcF.tms_straddle_aantal));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
              end if;

              -- Rekening houden met verhouding van blocksizes van opties en futures !!
              -- Dus normaliter worden opties per 2 afgedekt door 1 future
              cf_verhouding_future_optie := r_mcF.tms_blocksize/(r_ms.tms_blocksize*r_ms.tms_pricing_unit);

              -- beschikbaar aantal short optie:
              cf_aantal_over_optie  := ABS (r_ms.tms_saldo_positie + r_ms.tms_spread_aantal + r_ms.tms_straddle_aantal +
                                            r_ms.tms_gecovered + r_ms.tms_prod_geblok_aantal + v_cross_aantal);
              -- beschikbaar aantal long future:
              -- let op tms_positie_future is een positief getal, dus alleen aftrekken!!
              cf_aantal_over_future := ABS (r_mcF.tms_positie_future - r_mcF.tms_spread_aantal - r_mcF.tms_straddle_aantal -
                                            (r_mcF.tms_cross_aantal/cf_verhouding_future_optie));
              -- aantal cross berekenen:
              cf_aantal_cross := ABS (LEAST (cf_aantal_over_optie / cf_verhouding_future_optie * cf_verhouding_future_optie,
                                             cf_aantal_over_future * cf_verhouding_future_optie));
              -- Cross margin = Initial margin future + premie van de optie
              -- Initial future margin wordt niet aangepast, dus hier alleen maar de premie van de optie uitrekenen
              cf_bedrag_cross := r_ms.tms_laatkoers * r_ms.tms_blocksize * r_ms.tms_pricing_unit * cf_aantal_cross;
              -- toeslag optiemargin:
              cf_bedrag_cross := (1 + i_optiemargin_toeslag/100) * cf_bedrag_cross;
              cf_bedrag_cross := (1 + gv_cl_margin_toeslag/100) * cf_bedrag_cross;

              if gv_debuggen = 1 and gv_debug_runnummer = gv_runnummer
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'berekende gegevens : ');
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'verhouding future optie : '||to_char(cf_verhouding_future_optie));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'aantal over optie       : '||to_char(cf_aantal_over_optie)||
                                                          ' ; aantal over future : '||to_char(cf_aantal_over_future));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'aantal cross            : '||to_char(cf_aantal_cross)||
                                                          'bedrag cross            : '||to_char(cf_bedrag_cross));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
              end if;

              -- Bijwerken van de gegevens van de optie:
              v_cross_aantal    := v_cross_aantal + cf_aantal_cross;
              v_cross_bedrag    := v_cross_bedrag + cf_bedrag_cross;
              -- ter voorkoming van het delen door 0:
              if cf_aantal_over_optie <> 0 and cf_aantal_cross <> 0
              then
                 v_margin_required := v_margin_required - (v_margin_required / cf_aantal_over_optie * cf_aantal_cross);
              end if;
              -- Bijwerken van de future (direct in het bestand)
              update temp_margin_wb_sessie
              set    tms_cross_aantal = tms_cross_aantal + cf_aantal_cross
              where  rowid            = r_mcF.rowid;

           end loop;  --eimde loop r_mcF (future voor call opties)
        end;
     end if; -- einde call optie

     -- Het beteft een put optie (zie subtaak 173.6.2):
     if r_ms.tms_soort = 'PUT'
     then
        declare
           pf_aantal_over_optie         temp_margin_wb_sessie.tms_saldo_positie%type     := 0;
           pf_aantal_over_future        temp_margin_wb_sessie.tms_positie_future%type    := 0;
           pf_verhouding_future_optie   number(4)                                        := 0;
           pf_aantal_cross              temp_margin_wb_sessie.tms_cross_aantal%type      := 0;
           pf_bedrag_cross              temp_margin_wb_sessie.tms_cross_bedrag%type      := 0;

           cursor mpF is

              select mF.tms_relatienr,     mF.tms_soort,           mF.tms_symbool,
                     mF.tms_exp_datum,     mF.tms_positie_future,  mF.tms_blocksize,
                     mF.tms_spread_aantal, mF.tms_straddle_aantal, mF.tms_cross_aantal,
                     mF.rowid
              from   temp_margin_wb_sessie mF, koppeltabel_cross_margin kP
              where  mF.tms_relatienr      =  gv_terminalnummer
              and    mF.tms_soort          =  'FUT'
              and    mF.tms_positie_future <= -1
              and    mF.tms_exp_datum      >= r_ms.tms_exp_datum
              and    mF.tms_runnnummer     =  gv_runnummer
              and    kP.cm_optie_symbool   =  r_ms.tms_symbool   -- hier inner join op
              and    kP.cm_future_symbool  =  mF.tms_symbool     -- koppeltabel_cross_margin !!!
              order by mF.tms_relatienr, mF.tms_refsymbool, mF.tms_soort, mF.tms_biedkoers desc,
                       mF.tms_exp_datum, mF.tms_exerciseprijs, mF.tms_symbool;
        begin
           for r_mpF in mpF
           loop

              if gv_debuggen = 1 and gv_debug_runnummer = gv_runnummer
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'in het call optie/future gedeelte');
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie symbool        : '||r_ms.tms_symbool||
                                                          ' ; optie type    : '||r_ms.tms_soort);
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie expdatum       : '||r_ms.tms_exp_datum||
                                                          ' ; optie exerciseprijs : '||to_char(r_ms.tms_exerciseprijs));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie positie        : '||to_char(r_ms.tms_saldo_positie)||
                                                          ' ; optie blocksize : '||to_char(r_ms.tms_blocksize));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie marginrequired : '||to_char(r_ms.tms_margin_required)||
                                                          ' ; optie gecovered   : '||to_char(r_ms.tms_gecovered));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie spread aantal  : '||to_char(r_ms.tms_spread_aantal)||
                                                          ' ;  optie straddle aantal : '||to_char(r_ms.tms_straddle_aantal));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie cross aantal   : '||to_char(v_cross_aantal)||
                                                          ' optie cross bedrag : '||to_char(v_cross_bedrag));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'optie pricing unit   : '||to_char(r_ms.tms_pricing_unit));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'future symbool       : '||r_mpF.tms_symbool||
                                                          ' ; future expdatum   : '||r_mpF.tms_exp_datum);
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'future positie       : '||to_char(r_mpF.tms_positie_future)||
                                                          ' ; future blocksize : '||to_char(r_mpF.tms_blocksize));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'future cross aantal  : '||to_char(r_mpF.tms_cross_aantal)||
                                                          ' ; future spread aantal : '||to_char(r_mpF.tms_spread_aantal));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'future straddle aant : '||to_char(r_mpF.tms_straddle_aantal));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
              end if;

              -- Rekening houden met verhouding van blocksizes van opties en futures !!
              -- Dus normaliter worden opties per 2 afgedekt door 1 future
              pf_verhouding_future_optie := r_mpF.tms_blocksize/(r_ms.tms_blocksize*r_ms.tms_pricing_unit);

              -- beschikbaar aantal short optie:
              pf_aantal_over_optie  := ABS (r_ms.tms_saldo_positie + r_ms.tms_spread_aantal + r_ms.tms_straddle_aantal +
                                            r_ms.tms_gecovered + r_ms.tms_prod_geblok_aantal + v_cross_aantal);
              -- beschikbaar aantal long future:
              -- let op tms_positie_future is een negatief getal, dus alleen optellen!!
              pf_aantal_over_future := ABS (r_mpF.tms_positie_future + r_mpF.tms_spread_aantal + r_mpF.tms_straddle_aantal +
                                            (r_mpF.tms_cross_aantal/pf_verhouding_future_optie));
              -- aantal cross berekenen:
              pf_aantal_cross := ABS (LEAST (pf_aantal_over_optie / pf_verhouding_future_optie * pf_verhouding_future_optie,
                                             pf_aantal_over_future * pf_verhouding_future_optie));
              -- Cross margin = Initial margin future + premie van de optie
              -- Initial future margin wordt niet aangepast, dus hier alleen maar de premie van de optie uitrekenen
              pf_bedrag_cross := r_ms.tms_laatkoers * r_ms.tms_blocksize * r_ms.tms_pricing_unit * pf_aantal_cross;
              -- toeslag optiemargin:
              pf_bedrag_cross := (1 + i_optiemargin_toeslag/100) * pf_bedrag_cross;
              pf_bedrag_cross := (1 + gv_cl_margin_toeslag/100) * pf_bedrag_cross;

              if gv_debuggen = 1 and gv_debug_runnummer = gv_runnummer
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'berekende gegevens : ');
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'verhouding future optie : '||to_char(pf_verhouding_future_optie));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'aantal over optie       : '||to_char(pf_aantal_over_optie)||
                                                          ' ; aantal over future : '||to_char(pf_aantal_over_future));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'aantal cross            : '||to_char(pf_aantal_cross)||
                                                          'bedrag cross            : '||to_char(pf_bedrag_cross));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
              end if;

              -- Bijwerken van de gegevens van de optie:
              v_cross_aantal    := v_cross_aantal + pf_aantal_cross;
              v_cross_bedrag    := v_cross_bedrag + pf_bedrag_cross;
              -- Ter voorkoming van het delen door 0:
              if pf_aantal_over_optie <> 0 and pf_aantal_cross <> 0
              then
                 v_margin_required := v_margin_required - (v_margin_required / pf_aantal_over_optie * pf_aantal_cross);
              end if;
              -- Bijwerken van de future (direct in het bestand)
              update temp_margin_wb_sessie
              set    tms_cross_aantal = tms_cross_aantal + pf_aantal_cross
              where  rowid            = r_mpF.rowid;

           end loop; -- einde van de loop r_mpF (de future loop voor put opties).
        end;
     end if;  -- einde put optie

     -- wegschrijven van de berekende gegevens voor de optie als er iets is gewijzigd:
     if (v_margin_required <> r_ms.tms_margin_required
         or
         v_cross_aantal    <> r_ms.tms_cross_aantal
         or
         v_cross_bedrag    <> r_ms.tms_cross_bedrag)
     then
        update temp_margin_wb_sessie t
        set    t.tms_margin_required = v_margin_required,
               t.tms_cross_aantal    = v_cross_aantal,
               t.tms_cross_bedrag    = v_cross_bedrag
        where  t.rowid               = r_ms.rowid;
     end if;
  end loop;  -- einde loop r_ms (de hoofdloop op opties)

  if gv_debuggen = 1 and gv_debug_runnummer = gv_runnummer
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'Einde onderdeel cross margin (FIAT_MARGIN.ma_cross_margin)');
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
  end if;

end ma_cross_margin;
-- EINDE CODE PROCEDURE MA_CROSS_MARGIN


-- DE CODE VOOR DE PROCEDURE MA_COLLATERAL
-- In deze procedure wordt het collateral gedeelte van de margin berekening afgehandeld
-- vergelijk subtaak 7 van programma 173 br-Opt Fut posities(Sessie)
procedure ma_collateral
is

  v_collateral_bedrag      temp_margin_wb_sessie.tms_collateral_bedrag%type   := 0;
  v_be_bi_nummer_vanaf     beleggingsinstrument.be_bi_nummer%type             := 0;
  v_be_bi_nummer_tm        beleggingsinstrument.be_bi_nummer%type             := 0;
  v_margin_totaal_bedrag   temp_margin_wb_sessie.tms_margin_required%type     := 0;
  v_dummy_symbool          beleggingsinstrument.be_symbool%type               := ' ';

  v_obligaties_aanwezig    number(1)    := 1;  -- hier aangeven dat obligaties aanwezig zijn
                                               -- als ze er niet zijn dan wordt dit wel weer uitgezet
  v_aandelen_aanwezig      number(1)    := 1;  -- hier aangeven dat aandelen aanwezig zijn
                                               -- als ze er niet zijn dan wordt dit wel weer uitgezet

cursor ms is

select   m.tms_relatienr,       m.tms_refsymbool,    m.tms_soort,           m.tms_biedkoers,
         m.tms_exp_datum,       m.tms_exerciseprijs, m.tms_symbool,         m.tms_saldo_positie,
         m.tms_margin_required, m.tms_spread_bedrag, m.tms_straddle_bedrag, m.tms_collateral_bedrag,
         m.tms_valuta,          m.tms_cross_bedrag,  m.rowid
from     temp_margin_wb_sessie m
where    m.tms_relatienr     =  gv_terminalnummer
and      m.tms_soort         in ('CALL','PUT')
and      m.tms_saldo_positie <= -1
and      m.tms_runnnummer    =  gv_runnummer
and      (m.tms_margin_required + m.tms_spread_bedrag + m.tms_straddle_bedrag +
          m.tms_cross_bedrag - m.tms_collateral_bedrag) > 0
order by m.tms_relatienr, m.tms_refsymbool, m.tms_soort, m.tms_biedkoers desc, m.tms_exp_datum,
         m.tms_exerciseprijs, m.tms_symbool;

begin
     -- Voordat de loop in gaat eenmalig kijken of er überhaupt aandelen en obligaties aanwezig zijn:
     -- aandelen:
     begin
       select a.tas_symbool
       into   v_dummy_symbool
       from   temp_ap_werkbest_sessie a
       where  a.tas_relatienr          = gv_terminalnummer
       and    a.tas_rekening_soort     = 0
       and    a.tas_rekeningnr         = ' '
       and    a.tas_rekening_munts     = ' '
       and    a.tas_bi_type            between 100 and 199
       and    a.tas_saldo_positie      >= 1
       and    a.tas_runnummer          = gv_runnummer
       and    rownum                   <= 1;

     exception
       when no_data_found
       then
          v_aandelen_aanwezig := 0;
     end;

     -- obligaties
     begin
       select a.tas_symbool
       into   v_dummy_symbool
       from   temp_ap_werkbest_sessie a
       where  a.tas_relatienr          = gv_terminalnummer
       and    a.tas_rekening_soort     = 0
       and    a.tas_rekeningnr         = ' '
       and    a.tas_rekening_munts     = ' '
       and    a.tas_bi_type            between 200 and 299
       and    a.tas_saldo_positie      >= 1
       and    a.tas_runnummer          =  gv_runnummer
       and    rownum                   <= 1;

     exception
       when no_data_found
       then
          v_obligaties_aanwezig := 0;
     end;

     for r_ms in ms
     loop
        -- vastleggen van de uitgangswaarde van het collateral bedrag:
        v_collateral_bedrag    := r_ms.tms_collateral_bedrag;
        v_margin_totaal_bedrag := r_ms.tms_margin_required + r_ms.tms_spread_bedrag +
                                  r_ms.tms_straddle_bedrag + r_ms.tms_cross_bedrag;

        if gv_debuggen = 1 and gv_debug_runnummer = gv_runnummer
        then
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'in procedure ma_collateral');
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'symbool             : '||r_ms.tms_symbool||
                                                    ' ; optietype : '||r_ms.tms_soort);
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'expiratiedatum      : '||r_ms.tms_exp_datum||
                                                    ' ; exerciseprijs : '||to_char(r_ms.tms_exerciseprijs));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'collateral bedrag   : '||to_char(v_collateral_bedrag)||
                                                    ' ; margin totaal bedrag : '||to_char(v_margin_totaal_bedrag));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'obligaties aanwezig : '||to_char(v_obligaties_aanwezig)||
                                                    ' ; aandelen aanwezig : '||to_char(v_aandelen_aanwezig));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
        end if;

        -- Doorgaan als er nog een bedrag is dat afgedekt kan worden
        if (r_ms.tms_margin_required + r_ms.tms_spread_bedrag + r_ms.tms_straddle_bedrag +
            r_ms.tms_cross_bedrag - v_collateral_bedrag) > 0
            and
            v_obligaties_aanwezig = 1
        then
           -- Afdekken van de verplichtingen eerst met obligaties:
           v_be_bi_nummer_vanaf := 200;
           v_be_bi_nummer_tm    := 299;

           ma_collateral_fonds_loop(v_be_bi_nummer_vanaf, v_be_bi_nummer_tm, r_ms.tms_valuta,
                                    v_margin_totaal_bedrag, v_collateral_bedrag);
        end if;

        if gv_debuggen = 1 and gv_debug_runnummer = gv_runnummer
        then
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'in procedure ma_collateral tussen obligaties en aandelen');
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'margin totaal bedrag : '||to_char(v_margin_totaal_bedrag)||
                                                    ' ; collateral bedrag : '||to_char(v_collateral_bedrag));
        end if;

        -- Als bovenstaand gedeelte is afgerond kijken of er nog steeds over is om af te dekken,
        -- dan met aandelen afdekken
        if (r_ms.tms_margin_required + r_ms.tms_spread_bedrag + r_ms.tms_straddle_bedrag +
            r_ms.tms_cross_bedrag - v_collateral_bedrag) > 0
            and
            v_aandelen_aanwezig = 1
        then
           -- Afdekken van de verplichtingen eerst met obligaties:
           v_be_bi_nummer_vanaf := 100;
           v_be_bi_nummer_tm    := 199;

           ma_collateral_fonds_loop(v_be_bi_nummer_vanaf, v_be_bi_nummer_tm, r_ms.tms_valuta,
                                    v_margin_totaal_bedrag, v_collateral_bedrag);
        end if;

        if gv_debuggen = 1 and gv_debug_runnummer = gv_runnummer
        then
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'in procedure ma_collateral na aandelen');
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user, 'margin totaal bedrag : '||to_char(v_margin_totaal_bedrag)||
                                                    ' ; collateral bedrag : '||to_char(v_collateral_bedrag));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user, ' ');
        end if;

        -- Bijwerken van het margin_wb_sessie bestand.
        -- alleen als er een wijziging is geweest in het v_collateral_bedrag
        if r_ms.tms_collateral_bedrag <> v_collateral_bedrag
        then
           update temp_margin_wb_sessie
           set    tms_collateral_bedrag = v_collateral_bedrag
           where  rowid                 = r_ms.rowid;
        end if;
     end loop;  -- einde van loop r_ms

end ma_collateral;
-- EINDE CODE PROCEDURE MA_COLLATERAL


-- DE CODE VOOR DE PROCEDURE MA_COLLATERAL_FONDS_LOOP
-- In deze procedure wordt de fondsenloop uitgevoerd van de collateralberekening
-- Vergelijk subtaak 7.1 van programma 173 br-Opt Fut posities(Sessie)
procedure ma_collateral_fonds_loop
(i_be_bi_nummer_vanaf       in     beleggingsinstrument.be_bi_nummer%type
,i_be_bi_nummer_tm          in     beleggingsinstrument.be_bi_nummer%type
,i_ms_valuta                in     temp_margin_wb_sessie.tms_valuta%type
,i_margin_bedrag            in     temp_margin_wb_sessie.tms_margin_required%type
,io_collateral_bedrag       in out temp_margin_wb_sessie.tms_collateral_bedrag%type
)

-- Inkomende parameters zijn: i_be_bi_nummer_vanaf    = Het beleggingsinstrument type vanaf
--                            i_be_bi_nummer_tm       = Het beleggingsinstrument type t/m
--                            i_ms_valuta             = De muntsoort van het fonds waarvoor de margin geldt
--                            i_margin_bedrag         = De optelling van ms_margin_required + ms_spread_bedrag +
--                                                      ms_straddle_bedrag + ms_cross_bedrag
-- Inkomende/uitgaande parameters zijn:
--                            io_collateral_bedrag    = Het collateral bedrag dat al is berekend (als inkomende parameter)
--                                                      Het collateral bedrag dat is berekend in deze procedure
--                                                      (als uitgaande parameter)

is

   v_geblokkeerd_obl_aand            werkbestand.wk_waarde_1%type                         := 0;
   v_collateral_aantal_aanwezig      temp_ap_werkbest_sessie.tas_saldo_positie%type       := 0;
   v_collateral_waarde_aanwezig      number(17,6)                                         := 0;
   v_collateral_waarde_nodig         number(17,6)                                         := 0;
   v_collateral_voor_update          temp_ap_werkbest_sessie.tas_collateral_used%type     := 0;
   v_koers_be_valuta                 fn_quotes_vw.quot_midden%type                        := 0;
   v_factor_be_valuta                fn_quotes_vw.quot_factor%type                        := 0;
   v_reciproke_be_valuta             fn_quotes_vw.quot_reciproke%type                     := 0;
   v_laat_koers                      fn_quotes_vw.quot_laat%type                          := 0;
   v_koers_ms_valuta                 fn_quotes_vw.quot_midden%type                        := 0;
   v_factor_ms_valuta                fn_quotes_vw.quot_factor%type                        := 0;
   v_reciproke_ms_valuta             fn_quotes_vw.quot_reciproke%type                     := 0;
   v_notatie_ms_valuta               muntsoorten.mu_notatie%type                          := 0;
   v_wegingsfactor_perc              wegingsfactoren.wg_interne_perc%type                 := 0;
   v_rente_factor                    number(14,9)                                         := 0;
   v_lopende_rente                   positie_werkbestand.pwb_lopende_rente_vv%type        := 0;
   
   v_positie_werk_aantal             positie_werkbestand.pwb_werk_aantal_port%type        := 0;
   v_positie_dekk_waarde_rapv        positie_werkbestand.pwb_dekk_waarde_rapv%type        := 0;
   v_positie_dekk_waarde_vv          positie_werkbestand.pwb_dekk_waarde_vv_sl%type       := 0;

cursor ap is

select   a.tas_relatienr,       a.tas_symbool,       a.tas_optietype,         a.tas_expiratiedatum,
         a.tas_exerciseprijs,   a.tas_saldo_positie, a.tas_in_collateral,     a.tas_in_cover_used,
         a.tas_collateral_used, a.tas_ref_relatie,   a.tas_bi_type,           a.tas_rekeningnr,
         a.tas_rekening_soort,  a.rowid,
         b.be_muntsoort,        b.be_wg_factor,      b.be_referentiesymbool,  b.be_aantal_cijfers_display,
         b.be_nominaal,         b.be_prijs_factor
from     temp_ap_werkbest_sessie a, beleggingsinstrument b
where    a.tas_relatienr          =  gv_terminalnummer
and      a.tas_rekening_soort     =  0
and      a.tas_rekeningnr         =  ' '
and      a.tas_rekening_munts     =  ' '
and      a.tas_bi_type            between i_be_bi_nummer_vanaf and i_be_bi_nummer_tm
and      a.tas_saldo_positie      >= 1
and      a.tas_runnummer          =  gv_runnummer
and      b.be_symbool             =  a.tas_symbool
and      b.be_optietype           =  a.tas_optietype
and      b.be_exerciseprijs       =  0
and      b.be_expiratiedatum      =  '00000000'
order by a.tas_relatienr, a.tas_rekening_soort, a.tas_rekening_munts, a.tas_rekeningnr, a.tas_symbool,
         a.tas_optietype, a.tas_expiratiedatum, a.tas_exerciseprijs, a.tas_productnummer, a.tas_product_volgnummer;

begin

   for r_ap in ap
   loop

      -- bepalen van het aantal dat vrij is voor gebruik in collateral
      if gv_cl_margin in (3,4)
      then
         -- bepalen geblokkeerd. Omdat het hier allemaal op economische positie is dan ook geblokkeerd
         -- op economische positie ophalen:
         ma_get_put_geblokkeerd(r_ap.tas_symbool, 'G', gv_dummy, v_geblokkeerd_obl_aand, gv_dummy);

         v_collateral_aantal_aanwezig := r_ap.tas_saldo_positie - v_geblokkeerd_obl_aand - r_ap.tas_in_cover_used -
                                       r_ap.tas_collateral_used;
      else
         v_collateral_aantal_aanwezig := r_ap.tas_in_collateral - r_ap.tas_collateral_used;
      end if;
      
      if gv_runnummer <> 0     -- uitvoeren voor de berekening bij orders
      then
         -- ophalen van de wegingsfactor
         begin
            select w.wg_interne_perc
            into   v_wegingsfactor_perc
            from   wegingsfactoren w
            where  w.wg_nummer    = r_ap.be_wg_factor;
         exception
            when no_data_found
            then
               v_wegingsfactor_perc := 0;
         end;
         -- afhankelijk van de kredietbrief instellingen de wegingsfactor bepalen
         if v_wegingsfactor_perc <> 0
         then
            if rtrim(gv_rel_onld_omschrijving) = 'P'
            then
               v_wegingsfactor_perc := gv_rel_onld_percentage/100;
            else
               v_wegingsfactor_perc := v_wegingsfactor_perc/100;
            end if;
            
            if rtrim(gv_rel_onld_omschrijving) = 'D' or rtrim(gv_rel_onld_omschrijving) = 'L'
            then
               v_wegingsfactor_perc := v_wegingsfactor_perc * gv_rel_onld_percentage/100;
            end if;
         end if;
      elsif gv_runnummer = 0         -- uitvoeren bij de berekening van de portefeuille margin
      then
         select p.pwb_werk_aantal_port, p.pwb_dekk_waarde_rapv,     p.pwb_dekk_waarde_vv_sl
         into   v_positie_werk_aantal,  v_positie_dekk_waarde_rapv, v_positie_dekk_waarde_vv 
         from   positie_werkbestand p
         where  p.pwb_relatie_nummer    = gv_relatienummer
         and    p.pwb_rekening_nummer   = r_ap.tas_rekeningnr
         and    p.pwb_rekening_soort    = r_ap.tas_rekening_soort
         and    p.pwb_symbool           = r_ap.tas_symbool
         and    p.pwb_optietype         = r_ap.tas_optietype
         and    p.pwb_expiratiedatum    = r_ap.tas_expiratiedatum
         and    p.pwb_exerciseprijs     = r_ap.tas_exerciseprijs;
      end if;
      
      if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in collateral fonds loop');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Het onderhanden zijnde fonds:');
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'symbool                       : '||r_ap.tas_symbool||
                                                 ' ; optietype : '||r_ap.tas_optietype);
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'saldo positie                 : '||to_char(r_ap.tas_saldo_positie)||
                                                 ' ; in cover used : '||to_char(r_ap.tas_in_cover_used));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in collateral                 : '||to_char(r_ap.tas_in_collateral)||
                                                 ' ; in collateral used : '||to_char(r_ap.tas_collateral_used));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'collateral aantal aanwezig    : '||to_char(v_collateral_aantal_aanwezig)||
                                                 ' ; v_wegingspercentage : '||to_char(v_wegingsfactor_perc));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'geblokkeerd obligatie/aandeel : '||to_char(v_geblokkeerd_obl_aand)||
                                                 ' ; be nominaal  : '||to_char(r_ap.be_nominaal));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'positie werk aantal : '||to_char(v_positie_werk_aantal)||
                                                 ' ; positie dekkingswaarde rapv : '||to_char(v_positie_dekk_waarde_rapv));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'positie dekkingswaarde vv : '||to_char(v_positie_dekk_waarde_vv));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
      end if;
      
      -- Alleen doorgaan als er een positief collateral aantal aanwezig is en het wegings% groter dan 0 is
      -- en er nog een bedrag openstaat om af te dekken (let op wel >= 0 aan houden!)
      if v_collateral_aantal_aanwezig > 0 and v_collateral_waarde_nodig >= 0
         and (v_wegingsfactor_perc > 0 and gv_runnummer <> 0            -- bij berekening voor orders
              or
              v_positie_dekk_waarde_rapv > 0 and gv_runnummer = 0)      -- bij berekening voor porefeuille
      then
         if gv_runnummer <> 0            -- bij berekening voor orders
         then
            -- ophalen van de verschillende koersen:
            -- Muntkoersen alleen als de muntsoorten van elkaar verschillen:
            if i_ms_valuta <> r_ap.be_muntsoort
            then
               -- met de middenkoers
               FIAT_ALGEMEEN.valutagegevens_bepalen (i_ms_valuta,             gv_relatie_pr_id, gv_relatie_ppr_id,  gv_systspreadcodecategorie,
                                                     gv_bank2mrktqchangedate, gv_debuggen,      gv_debug_user,      gv_dummy,
                                                     v_koers_ms_valuta,       gv_dummy,         v_factor_ms_valuta, v_reciproke_ms_valuta,
                                                     v_notatie_ms_valuta);
               
               -- met de middenkoers
               FIAT_ALGEMEEN.valutagegevens_bepalen (r_ap.be_muntsoort,       gv_relatie_pr_id, gv_relatie_ppr_id,  gv_systspreadcodecategorie,
                                                     gv_bank2mrktqchangedate, gv_debuggen,      gv_debug_user,      gv_dummy,
                                                     v_koers_be_valuta,       gv_dummy,         v_factor_be_valuta, v_reciproke_be_valuta,
                                                     gv_dummy);
            end if;
            
            begin
               select k.quot_laat
               into   v_laat_koers
               from   fn_quotes_vw k
               where  k.quot_symbool        = r_ap.tas_symbool
               and    k.quot_optietype      = ' '
               and    k.quot_expiratiedatum = '00000000'
               and    k.quot_exerciseprijs  = 0
               and    k.quot_soort          = 'SLOT'
               and    k.quot_datum          <= to_char(SYSDATE,'yyyymmdd')
               and    rownum              <= 1
               order by k.quot_symbool, k.quot_optietype, k.quot_expiratiedatum, k.quot_exerciseprijs, k.quot_soort,
                        k.quot_datum desc, k.quot_tijd desc;  -- order by om de laatste koers op te halen
            exception
               when no_data_found
               then
                  v_laat_koers := 0;
            end;
            
            -- Aanpassen van de koers en lopende rente berekenen als het obligaties betreffen:
            if i_be_bi_nummer_vanaf = 200
            then
               v_laat_koers := v_laat_koers/100;
               
               -- resetten van de variabelen:
               v_rente_factor  := 0;
               
               select FIAT_ALGEMEEN.rente_factor_berek(r_ap.tas_symbool, to_char(SYSDATE,'yyyymmdd'),gv_debuggen,gv_debug_user)
               into v_rente_factor
               from dual;
               
               v_rente_factor := round(v_rente_factor,9);
               
               v_lopende_rente := v_collateral_aantal_aanwezig * nvl(v_rente_factor,0) * r_ap.be_prijs_factor;
               v_lopende_rente := round(v_lopende_rente, 2);
               
               if gv_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Bepaling rente');
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'rente factor : '||to_char(v_rente_factor)||
                                                          ' ; aantal : '||to_char(v_collateral_aantal_aanwezig));
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'prijs factor : '||to_char(r_ap.be_prijs_factor)||
                                                          ' ; lopende rente : '||to_char(v_lopende_rente));
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
               end if;
            end if;
         -- ophalen van margin muntgegevens bij berekeningen voor portefeuille (let op  hier biedkoers bepalen en geen middenkoers !)
         elsif i_ms_valuta <> gv_rel_rapp_valuta and gv_runnummer = 0   
         then
            FIAT_ALGEMEEN.valutagegevens_bepalen (i_ms_valuta,             gv_relatie_pr_id, gv_relatie_ppr_id,  gv_systspreadcodecategorie,
                                                  gv_bank2mrktqchangedate, gv_debuggen,      gv_debug_user,      v_koers_ms_valuta,
                                                  gv_dummy,                gv_dummy,         v_factor_ms_valuta, v_reciproke_ms_valuta,
                                                  v_notatie_ms_valuta);
         end if;
            
         -- Berekenen welk bedrag er vrij is voor het afdekken middels collateral:
         -- Voor fractiefondsen ook nog maal  de prijsfactor ...
         if gv_runnummer = 0        -- bij berekening voor de portefeuille
         then
            v_collateral_waarde_aanwezig := v_collateral_aantal_aanwezig/v_positie_werk_aantal * v_positie_dekk_waarde_rapv;
         else                       -- bij berekening voor de orders
            if r_ap.be_aantal_cijfers_display <> 0
            then
               v_collateral_waarde_aanwezig := (nvl(v_lopende_rente,0) + (v_collateral_aantal_aanwezig * v_laat_koers
                                                                          * r_ap.be_prijs_factor)) * v_wegingsfactor_perc;
            else
               v_collateral_waarde_aanwezig := (nvl(v_lopende_rente,0) + (v_collateral_aantal_aanwezig * v_laat_koers))
                                                * v_wegingsfactor_perc;
            end if;
         end if;
         
         if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'slot laatkoers van het fonds : '||to_char(v_laat_koers)||
                                                    ' ; collateral waarde aanwezig : '||to_char(v_collateral_waarde_aanwezig));
         end if;
         
         -- Alleen verder gaan als de collateral waarde aanwezig groter dan 0 is:
         if v_collateral_waarde_aanwezig > 0
         then
            -- Dit bedrag omrekenen als de muntsoorten van elkaar verschillen; hier voor de berekeningen bij orders
            if i_ms_valuta <> r_ap.be_muntsoort and gv_runnummer <> 0
            then
               select FIAT_ALGEMEEN.omrekenen_bedrag_vv(v_collateral_waarde_aanwezig, v_reciproke_be_valuta,
                                                        v_factor_be_valuta,           v_koers_be_valuta,
                                                        v_koers_be_valuta,            v_reciproke_ms_valuta,
                                                        v_factor_ms_valuta,           v_koers_ms_valuta,
                                                        v_koers_ms_valuta,            v_notatie_ms_valuta)
               into   v_collateral_waarde_aanwezig
               from   dual;
            elsif i_ms_valuta <> gv_rel_rapp_valuta and gv_runnummer = 0      -- en hier voor de berekening bij de portefeuille
            then
               select FIAT_ALGEMEEN.omrekenen_bedrag_vv(v_collateral_waarde_aanwezig, gv_rel_rapp_reciproke,
                                                        gv_rel_rapp_factor,           gv_rel_rapp_laatkoers,
                                                        gv_rel_rapp_laatkoers,        v_reciproke_ms_valuta,
                                                        v_factor_ms_valuta,           v_koers_ms_valuta,
                                                        v_koers_ms_valuta,            v_notatie_ms_valuta)
               into   v_collateral_waarde_aanwezig
               from   dual;
            end if;
            -- Berekenen hoeveel er nodig is om alle marginbedragen af te dekken
            v_collateral_waarde_nodig := i_margin_bedrag - io_collateral_bedrag;

            if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'margin bedrag nodig : '||to_char(i_margin_bedrag)||
                                                       ' ; collateral waarde nodig : '||to_char(v_collateral_waarde_nodig));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'muntkoers fonds     : '||to_char(v_koers_be_valuta)||
                                                       ' ; muntkoers ms     : '||to_char(v_koers_ms_valuta));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
            end if;

            -- Als er meer aanwezig is dan nodig, dit aanwezige aantal aanpassen aan wat nodig is:
            if v_collateral_waarde_aanwezig > v_collateral_waarde_nodig
            then
               -- Berekening van aantallen gebeurd gesplits i.v.m. de impliciete
               -- afronding i.v.m. BW die Num 9 is.
               -- Vb: deling geeft 4,25 => 4,25 + 0,499999 = 4,749999 = 5
               --     deling geeft 4,65 => 4,65 + 0,499999 = 5,149999 = 5 (vroeger 6)
               --     deling geeft 4,00 => 4,00 + 0,499999 = 4,499999 = 4
               v_collateral_aantal_aanwezig := ROUND((v_collateral_waarde_nodig/v_collateral_waarde_aanwezig*
                                                      v_collateral_aantal_aanwezig+0.499999),0);

               if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
               then
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'collateral aantal aanwezig : '||to_char(v_collateral_aantal_aanwezig));
                  FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
               end if;
               
               -- Aanpassen voor obligaties (alleen bij berekeningen bij orders)
               if r_ap.tas_bi_type between 200 and 299 and gv_runnummer <> 0
               then
                  v_collateral_aantal_aanwezig := ROUND(((v_collateral_aantal_aanwezig + (r_ap.be_nominaal/2)-1)/
                                                                                      r_ap.be_nominaal),0)*r_ap.be_nominaal;
                  
                  -- op dit punt ook de lopende rente opnieuw berekenen voor het nieuw aantal:
                  v_lopende_rente := v_collateral_aantal_aanwezig * nvl(v_rente_factor,0) * r_ap.be_prijs_factor;
                  v_lopende_rente := round(v_lopende_rente, 2);
                  
                  if gv_debuggen = 1
                  then
                     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Bepaling rente');
                     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'rente factor : '||to_char(v_rente_factor)||
                                                             ' ; aantal : '||to_char(v_collateral_aantal_aanwezig));
                     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'prijs factor : '||to_char(r_ap.be_prijs_factor)||
                                                             ' ; lopende rente : '||to_char(v_lopende_rente));
                     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                  end if;
               end if;
               
               -- Opnieuw berekenen van de collateral waarde aanwezig, nu met het werkelijke berekende aantal:
               if gv_runnummer = 0         -- bij berekeningen voor de portefeuille
               then
                  v_collateral_waarde_aanwezig := v_collateral_aantal_aanwezig/v_positie_werk_aantal * v_positie_dekk_waarde_rapv;
               else                        -- bij berekeningen voor de orders
                  if r_ap.be_aantal_cijfers_display <> 0
                  then
                     v_collateral_waarde_aanwezig := (v_lopende_rente + (v_collateral_aantal_aanwezig * v_laat_koers
                                                                         * r_ap.be_prijs_factor)) * v_wegingsfactor_perc;
                  else
                     v_collateral_waarde_aanwezig := (v_lopende_rente + (v_collateral_aantal_aanwezig * v_laat_koers))
                                                      * v_wegingsfactor_perc;
                  end if;
               end if;
               
               -- Dit bedrag omrekenen als de muntsoorten van elkaar verschillen (alleen bij berekeningen voor orders)
               if i_ms_valuta <> r_ap.be_muntsoort and gv_runnummer <> 0
               then
                  select FIAT_ALGEMEEN.omrekenen_bedrag_vv(v_collateral_waarde_aanwezig, v_reciproke_be_valuta,
                                                           v_factor_be_valuta,           v_koers_be_valuta,
                                                           v_koers_be_valuta,            v_reciproke_ms_valuta,
                                                           v_factor_ms_valuta,           v_koers_ms_valuta,
                                                           v_koers_ms_valuta,            v_notatie_ms_valuta)
                  into   v_collateral_waarde_aanwezig
                  from   dual;
               elsif i_ms_valuta <> gv_rel_rapp_valuta and gv_runnummer = 0
               then
                  select FIAT_ALGEMEEN.omrekenen_bedrag_vv(v_collateral_waarde_aanwezig, gv_rel_rapp_reciproke,
                                                           gv_rel_rapp_factor,           gv_rel_rapp_laatkoers,
                                                           gv_rel_rapp_laatkoers,        v_reciproke_ms_valuta,
                                                           v_factor_ms_valuta,           v_koers_ms_valuta,
                                                           v_koers_ms_valuta,            v_notatie_ms_valuta)
                  into   v_collateral_waarde_aanwezig
                  from   dual;
               end if;
            end if;

            -- Ter voorkoming van het dubbel of drievoudig doortellen van het aantal in collateral
            -- op deze plek 1 keer bepalen wat de nieuwe collateral waarde voor de bestanden wordt...
            v_collateral_voor_update := r_ap.tas_collateral_used + v_collateral_aantal_aanwezig;

            io_collateral_bedrag := io_collateral_bedrag + v_collateral_waarde_aanwezig;

            if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'collateral voor update : '||to_char(v_collateral_voor_update)||
                                                       ' ; io collateral bedrag : '||to_char(io_collateral_bedrag));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'collateral aantal aanwezig : '||to_char(v_collateral_aantal_aanwezig));
            end if;

            -- Bijwerken van de totalen alleen als v_collateral_aantal_aanwezig groter is dan 0
            -- Zie subtaak 7.1.3
            if v_collateral_aantal_aanwezig > 0
            then
               if gv_cl_margin not in (3,4)
               then
                  -- Bijwerken van de gegevens van het werkbestand
                  update temp_ap_werkbest_sessie
                  set    tas_collateral_used = v_collateral_voor_update
                  where  rowid              = r_ap.rowid;
                  -- Bijwerken gegevens met als fondsgegevens AS_SYMBOOL en AS_OPTIETYPE
                  update temp_ap_werkbest_sessie
                  set    tas_collateral_used =  v_collateral_voor_update
                  where  tas_relatienr       =  gv_terminalnummer
                  and    tas_rekening_soort  =  0
                  and    tas_rekening_munts  =  ' '
                  and    tas_rekeningnr      =  ' '
                  and    tas_symbool         =  r_ap.tas_symbool
                  and    tas_optietype       =  r_ap.tas_optietype
                  and    tas_expiratiedatum  =  '00000000'
                  and    tas_exerciseprijs   >= 0
                  and    tas_runnummer       =  gv_runnummer
                  and    tas_ref_relatie     =  r_ap.tas_ref_relatie;
                  -- Bijwerken gegevens met als fondsgegevens met BE_REFERENTIESYMBOOL en AS_OPTETYPE
                  update temp_ap_werkbest_sessie
                  set    tas_collateral_used =  v_collateral_voor_update
                  where  tas_relatienr       =  gv_terminalnummer
                  and    tas_rekening_soort  =  0
                  and    tas_rekening_munts  =  ' '
                  and    tas_rekeningnr      =  ' '
                  and    tas_symbool         =  r_ap.be_referentiesymbool
                  and    tas_optietype       =  r_ap.tas_optietype
                  and    tas_expiratiedatum  =  '00000000'
                  and    tas_exerciseprijs   >= 0
                  and    tas_runnummer       =  gv_runnummer
                  and    tas_ref_relatie     =  r_ap.tas_ref_relatie;
               else
                  -- Bijwerken van de gegevens van het werkbestand
                  update temp_ap_werkbest_sessie
                  set    tas_collateral_used = v_collateral_voor_update,
                         tas_in_collateral   = v_collateral_voor_update
                  where  rowid               = r_ap.rowid;
                  -- Bijwerken gegevens met als fondsgegevens AS_SYMBOOL en AS_OPTIETYPE
                  update temp_ap_werkbest_sessie
                  set    tas_collateral_used =  v_collateral_voor_update,
                         tas_in_collateral   =  v_collateral_voor_update
                  where  tas_relatienr       =  gv_terminalnummer
                  and    tas_rekening_soort  =  0
                  and    tas_rekening_munts  =  ' '
                  and    tas_rekeningnr      =  ' '
                  and    tas_symbool         =  r_ap.tas_symbool
                  and    tas_optietype       =  r_ap.tas_optietype
                  and    tas_expiratiedatum  =  '00000000'
                  and    tas_exerciseprijs   >= 0
                  and    tas_runnummer       =  gv_runnummer
                  and    tas_ref_relatie     =  r_ap.tas_ref_relatie;
                  -- Bijwerken gegevens met als fondsgegevens met BE_REFERENTIESYMBOOL en AS_OPTETYPE
                  update temp_ap_werkbest_sessie
                  set    tas_collateral_used =  v_collateral_voor_update,
                         tas_in_collateral   =  v_collateral_voor_update
                  where  tas_relatienr       =  gv_terminalnummer
                  and    tas_rekening_soort  =  0
                  and    tas_rekening_munts  =  ' '
                  and    tas_rekeningnr      =  ' '
                  and    tas_symbool         =  r_ap.be_referentiesymbool
                  and    tas_optietype       =  r_ap.tas_optietype
                  and    tas_expiratiedatum  =  '00000000'
                  and    tas_exerciseprijs   >= 0
                  and    tas_runnummer       =  gv_runnummer
                  and    tas_ref_relatie     =  r_ap.tas_ref_relatie;
               end if;
            end if;

            if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
            then
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'collateral waarde nodig         : '||to_char(v_collateral_waarde_nodig));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'geexporteerde collateral bedrag : '||to_char(io_collateral_bedrag));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'collateral voor update          : '||to_char(v_collateral_voor_update));
               FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'  ');
            end if;

         end if;
      end if;
      -- Herberekenen hoeveel er nodig is om alle marginbedragen af te dekken (dit om
      -- te bekijken of de conditie voor eindigen van deze procedure is gehaald)
      -- Omdat dit een berkening is met min of meer vaste waarden kan die hier opnieuw
      -- worden uitgevoerd!
      v_collateral_waarde_nodig := i_margin_bedrag - io_collateral_bedrag;

      if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'collateral waarde nodig    : '||to_char(v_collateral_waarde_nodig));
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
      end if;

      if v_collateral_waarde_nodig <= 0
      then
         exit;
      end if;

   end loop; -- einde van loop r_ap

end ma_collateral_fonds_loop;
-- EINDE CODE PROCEDURE MA_COLLATERAL_FONDS_LOOP


-- DE CODE VOOR DE PROCEDURE MA_REGISTRATIE
-- In deze procedure wordt de totaaltellingen berekend van de marginberekening
-- Vergelijk subtaak 8 van programma 173 br-Opt Fut posities(Sessie)
procedure ma_registratie
(i_slot_of_laatste_koers   in  varchar2
,i_trekkingswaarde_actief  in  number
,o_optie_margin            out temp_margin_wb_sessie.tms_margin_required%type
,o_collateral_bedrag       out temp_margin_wb_sessie.tms_collateral_bedrag%type
,o_future_margin           out temp_margin_wb_sessie.tms_margin_required%type
)

is

  v_cover_bedrag               werkbestand.wk_waarde_1%type              := 0;
  v_cover_bedrag_vv            werkbestand.wk_waarde_2%type              := 0;
  v_fonds_omschrijving         beleggingsinstrument.be_oms_1%type        := ' ';
  v_wegingsfactor              wegingsfactoren.wg_interne_perc%type      := 0;
  v_fonds_biedkoers            fn_quotes_vw.quot_bied%type               := 0;
  v_fonds_biedkoers_ow_mnd     fn_quotes_vw.quot_bied%type               := 0;  
  v_dummy                      fn_quotes_vw.quot_laat%type               := 0;
  v_ow_is_mandje               number(1);
  v_ref_symb_volgnummer        beleggingsinstrument.be_volgnummer%type   := 0;
  v_koersverhouding            number(15,9)                              := 0;
  v_koersverhouding_neg        number(15,9)                              := 0;
  v_valuta_onderhanden         muntsoorten.mu_code%type                  := ' ';
  v_val_biedkoers              muntsoorten.mu_biedkoers%type             := 0;
  v_val_laatkoers              muntsoorten.mu_laatkoers%type             := 0;
  v_val_factor                 muntsoorten.mu_factor%type                := 0;
  v_val_reciproke              muntsoorten.mu_reciproke%type             := 0;
  v_val_notatie                muntsoorten.mu_notatie%type               := 0;
  
  v_positie_port_waarde_rapv   positie_werkbestand.pwb_port_waarde_rapv%type;
  v_positie_dekk_waarde_rapv   positie_werkbestand.pwb_dekk_waarde_rapv%type;
  
cursor ms is

select   m.tms_relatienr,       m.tms_refsymbool,        m.tms_soort,     m.tms_exerciseprijs,
         m.tms_blocksize,       m.tms_margin_required,   m.tms_gecovered, m.tms_spread_bedrag,
         m.tms_straddle_bedrag, m.tms_collateral_bedrag, m.tms_valuta,    m.tms_pricing_unit,
         m.tms_cross_bedrag,    m.rowid
from     temp_margin_wb_sessie m
where    m.tms_relatienr  = gv_terminalnummer
and      m.tms_runnnummer = gv_runnummer
order by m.tms_relatienr, m.tms_valuta;

begin
   -- resetten van de output parameters:
   o_collateral_bedrag := 0;
   o_future_margin     := 0;
   o_optie_margin      := 0;

   if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In procedure ma_registratie ');
   end if;
   
   for r_ms in ms
   loop
      -- Eerst bepalen of de optie meerdere onderliggende waardes heeft
      select b.be_volgnummer
      into   v_ref_symb_volgnummer
      from   beleggingsinstrument b
      where  b.be_symbool        = r_ms.tms_refsymbool
      and    b.be_optietype      = ' '
      and    b.be_expiratiedatum = '00000000'
      and    b.be_exerciseprijs  = 0;
     
      begin
         select 1
         into   v_ow_is_mandje
         from   mandje_onderliggende_waarde m
         where  m.mnd_volgnummer = v_ref_symb_volgnummer
         and    rownum           <= 1;                    -- Er hoeft maar 1 record opgehaald te worden !
     exception
         when no_data_found
         then
            v_ow_is_mandje := 0;
     end;
     
     if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
     then
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Referentie symbool volgnummer : '||to_char(v_ref_symb_volgnummer)||' ;  OW is mandje : '||to_char(v_ow_is_mandje));
        FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
     end if;
        
     -- Bepalen van de v_koersverhouding:
     if v_valuta_onderhanden = ' ' or v_valuta_onderhanden is null or v_valuta_onderhanden <> r_ms.tms_valuta
     then
        v_valuta_onderhanden := r_ms.tms_valuta;
        -- bepalen van de valuta gegevens om mee om te rekenen:
        if v_valuta_onderhanden = gv_rel_rapp_valuta
        then
           v_koersverhouding     := 1;
           v_koersverhouding_neg := 1;
           v_val_notatie         := gv_rel_rapp_notatie;
        else
           -- ophalen van de muntkoers gegevens van de valuta onderhanden:
           FIAT_ALGEMEEN.valutagegevens_bepalen (v_valuta_onderhanden,    gv_relatie_pr_id,  gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                                 gv_bank2mrktqchangedate, gv_debuggen,       gv_debug_user,     v_val_biedkoers,
                                                 gv_dummy,                v_val_laatkoers,   v_val_factor,      v_val_reciproke,
                                                 v_val_notatie);
           -- omrekenen van de waarde -1 in de v_koersverhouding (en dan later weer positief maken)
           select FIAT_ALGEMEEN.omrekenen_bedrag_vv (-1,                 v_val_reciproke,       v_val_factor,
                                                     v_val_biedkoers,    v_val_laatkoers,       gv_rel_rapp_reciproke,
                                                     gv_rel_rapp_factor, gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers,
                                                     9)
           into   v_koersverhouding
           from   dual;
           v_koersverhouding := v_koersverhouding * -1;
           -- voor de negatieve margin bedragen een 1 v_koersverhouding ophalen
           select FIAT_ALGEMEEN.omrekenen_bedrag_vv (1,                  v_val_reciproke,       v_val_factor,
                                                     v_val_biedkoers,    v_val_laatkoers,       gv_rel_rapp_reciproke,
                                                     gv_rel_rapp_factor, gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers,
                                                     9)
           into   v_koersverhouding_neg
           from   dual;
              
        end if;
     end if;

     -- de bepaalde koersverhouding wegschrijven....
     update temp_margin_wb_sessie t
     set    t.tms_price_ratio     = v_koersverhouding,
            t.tms_price_ratio_neg = v_koersverhouding_neg
     where  t.rowid               = r_ms.rowid;
          
     -- De bepaling van de totaal gegevens valt uiteen in een future en een niet future gedeelte:
     -- Het future gedeelte:
     if r_ms.tms_soort = 'FUT'
     then
        -- De totaaltelling bijwerken met de omgerekende future margin:
        o_future_margin := o_future_margin + round(r_ms.tms_margin_required   * v_koersverhouding_neg,gv_rel_rapp_notatie)
                                           + round(r_ms.tms_spread_bedrag     * v_koersverhouding_neg,gv_rel_rapp_notatie)
                                           + round(r_ms.tms_straddle_bedrag   * v_koersverhouding_neg,gv_rel_rapp_notatie)
                                           + round(r_ms.tms_cross_bedrag      * v_koersverhouding_neg,gv_rel_rapp_notatie)
                                           - round(r_ms.tms_collateral_bedrag * v_koersverhouding_neg,gv_rel_rapp_notatie);
     
     -- Het niet future gedeelte:
     else
        -- Hier de totaal tellling al doen. De berekeningen van de coverbedragen hebben geen invloed op deze optellingen
        o_optie_margin      := o_optie_margin + round(r_ms.tms_margin_required * v_koersverhouding_neg,gv_rel_rapp_notatie) 
                                              + round(r_ms.tms_spread_bedrag   * v_koersverhouding_neg,gv_rel_rapp_notatie) 
                                              + round(r_ms.tms_straddle_bedrag * v_koersverhouding_neg,gv_rel_rapp_notatie) 
                                              + round(r_ms.tms_cross_bedrag    * v_koersverhouding_neg,gv_rel_rapp_notatie);
        o_collateral_bedrag := o_collateral_bedrag + round(r_ms.tms_collateral_bedrag * v_koersverhouding_neg,gv_rel_rapp_notatie);
        
        
       -- Berekenen waarde van in cover gegeven stukken. Dit wordt alleen
       -- gedaan als de module definitie TRKW (Trekkingswaarde) actief is.
       -- Daarnaast hoeft dit alleen uitgevoerd te worden bij de berekeningen voor de portefeuille (runnummer = 0)
       if i_trekkingswaarde_actief = 1 and r_ms.tms_gecovered > 0 and gv_runnummer = 0
       then

           -- Gegevens berekenen als de ow geen mandje is
           if v_ow_is_mandje = 0
           then      
              -- op 0 zetten van de verschillende waarden
              v_cover_bedrag      := 0;
              v_cover_bedrag_vv   := 0;
              
              -- Bepalen van een aantal gegevens aan de hand van de positie in de onderliggende waarde
              select p.pwb_port_waarde_rapv,     p.pwb_dekk_waarde_rapv
              into   v_positie_port_waarde_rapv, v_positie_dekk_waarde_rapv
              from   positie_werkbestand p
              where  p.pwb_relatie_nummer  = gv_relatienummer
              and    p.pwb_rekening_nummer = ' '
              and    p.pwb_rekening_soort  = 0
              and    p.pwb_symbool         = r_ms.tms_refsymbool
              and    p.pwb_optietype       = ' '
              and    p.pwb_expiratiedatum  = '00000000'
              and    p.pwb_exerciseprijs   = 0;
              
              -- De wegingsfactor berekenen aan de hand van de berekende dekkings- en portefeuillewaarde
              if v_positie_port_waarde_rapv <> 0
              then
                 v_wegingsfactor := round(v_positie_dekk_waarde_rapv / v_positie_port_waarde_rapv * 100,3);
              -- Als de portefeuille waarde 0 is, dan is de wegingsfactor ook 0
              else
                 v_wegingsfactor := 0;
              end if;
              
              -- Ophalen van de gegevens van de onderliggende waarde:
              select b.be_oms_1
              into   v_fonds_omschrijving
              from   beleggingsinstrument b
              where  b.be_symbool        = r_ms.tms_refsymbool
              and    b.be_optietype      = ' '
              and    b.be_expiratiedatum = '00000000'
              and    b.be_exerciseprijs  = 0;
              
              -- Als de wegingsfactor <> 0, dan kunnen berekeningen uitgevoerd worden
              if v_wegingsfactor <> 0
              then
                 -- ophalen van de biedkoers van de onderliggende waarde
                 FIAT_ALGEMEEN.fondskoersen (r_ms.tms_refsymbool, ' ', '00000000', 0, i_slot_of_laatste_koers,
                                             v_fonds_biedkoers, v_dummy);
                                            
                 -- De berekening van de trekkingswaarde (coverwaarde mbv exerciseprijs of fonds biedkoers):
                 if r_ms.tms_exerciseprijs > v_fonds_biedkoers
                 then
                    v_cover_bedrag    := round(r_ms.tms_gecovered * r_ms.tms_blocksize * r_ms.tms_pricing_unit * v_fonds_biedkoers *
                                               v_wegingsfactor/100 * v_koersverhouding, gv_rel_rapp_notatie);
                    v_cover_bedrag_vv := round(r_ms.tms_gecovered * r_ms.tms_blocksize * r_ms.tms_pricing_unit * v_fonds_biedkoers *
                                               v_wegingsfactor/100, v_val_notatie);
                 else
                    v_cover_bedrag    := round(r_ms.tms_gecovered * r_ms.tms_blocksize * r_ms.tms_pricing_unit * r_ms.tms_exerciseprijs *
                                               v_wegingsfactor/100 * v_koersverhouding, gv_rel_rapp_notatie);
                    v_cover_bedrag_vv := round(r_ms.tms_gecovered * r_ms.tms_blocksize * r_ms.tms_pricing_unit * r_ms.tms_exerciseprijs *
                                               v_wegingsfactor/100, v_val_notatie);
                 end if;
              -- Als de wegingsfactor 0 is, dan is het coverbedrag ook 0.
              else
                 v_cover_bedrag    := 0;
                 v_cover_bedrag_vv := 0;
              end if;
              
              -- proberen weg te schrijven van deze waarde in het werkbestand:
              update werkbestand w
              set    w.wk_waarde_1    = w.wk_waarde_1 + -1 * v_cover_bedrag,
                     w.wk_waarde_2    = w.wk_waarde_2 + -1 * v_cover_bedrag_vv
              where  w.wk_terminal    = gv_terminalnummer
              and    w.wk_soort       = 'COVR'
              and    w.wk_categorie_1 = ' '
              and    w.wk_categorie_2 = 'Cover'
              and    w.wk_categorie_3 = r_ms.tms_refsymbool
              and    w.wk_categorie_4 = SUBSTR(v_fonds_omschrijving,1,26)
              and    w.wk_datum_1     = '00000000';
                               
              -- als de update niet lukt dan een nieuw record wegschrijven
              if sql%notfound
              then
                 insert into werkbestand
                 (wk_terminal,         wk_soort,                        wk_categorie_1, wk_categorie_2,
                  wk_categorie_3,      wk_categorie_4,                  wk_datum_1,     wk_waarde_1,
                  wk_waarde_2)
                 values
                 (gv_terminalnummer,    'COVR',                          ' ',            'Cover',
                  r_ms.tms_refsymbool, SUBSTR(v_fonds_omschrijving,1,26), '00000000',     -1*v_cover_bedrag,
                  -1*v_cover_bedrag_vv);
              end if;
           
           else  -- Begin van wel ow is mandje !
              declare
              
                 v_koersverhouding_ow          number(15,9);
                 v_val_biedkoers_ow            muntsoorten.mu_biedkoers%type; 
                 v_val_laatkoers_ow            muntsoorten.mu_laatkoers%type;
                 v_val_factor_ow               muntsoorten.mu_factor%type;
                 v_val_reciproke_ow            muntsoorten.mu_reciproke%type;
              
                 cursor mo is
                    select m.mnd_factor,        b.be_symbool,       b.be_optietype,
                           b.be_expiratiedatum, b.be_exerciseprijs, b.be_oms_1,
                           b.be_bi_nummer,      b.be_muntsoort
                    from   mandje_onderliggende_waarde m, beleggingsinstrument b
                    where  m.mnd_volgnummer            = v_ref_symb_volgnummer
                    and    m.mnd_ref_volgnr            = b.be_volgnummer
                    order by b.be_muntsoort;           -- op volgorde van de muntsoort leggen
                 
              begin
              
                 if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
                 then
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In deel van cover met mand je als ow');
                 end if;
        
                 -- ophalen van de samengestelde biedkoers van de onderliggende waarde (mandje). Hoeft maar 1 keer per mandje...
                 FIAT_ALGEMEEN.fondskoers_meerdere_ow (v_ref_symb_volgnummer, r_ms.tms_blocksize, i_slot_of_laatste_koers, gv_debuggen, gv_debug_user,
                                                       v_fonds_biedkoers,     v_dummy);

                 for r_mo in mo
                 loop
                    -- Bepalen van de v_koersverhouding ten opzichte van de muntsoort van het referentiefonds:
                    -- bepalen van de valuta gegevens om mee om te rekenen:
                    if r_mo.be_muntsoort = gv_rel_rapp_valuta
                    then
                       v_koersverhouding_ow     := 1;
                       v_val_notatie            := gv_rel_rapp_notatie;
                    else
                       -- ophalen van de muntkoers gegevens van de valuta onderhanden:
                       FIAT_ALGEMEEN.valutagegevens_bepalen (r_mo.be_muntsoort,       gv_relatie_pr_id,   gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                                             gv_bank2mrktqchangedate, gv_debuggen,        gv_debug_user,     v_val_biedkoers_ow,
                                                             gv_dummy,                v_val_laatkoers_ow, v_val_factor_ow,   v_val_reciproke_ow,
                                                             v_val_notatie);
                       -- omrekenen van de waarde -1 in de v_koersverhouding (en dan later weer positief maken)
                       select FIAT_ALGEMEEN.omrekenen_bedrag_vv (-1,                 v_val_reciproke_ow,    v_val_factor_ow,
                                                                 v_val_biedkoers_ow, v_val_laatkoers_ow,    gv_rel_rapp_reciproke,
                                                                 gv_rel_rapp_factor, gv_rel_rapp_biedkoers, gv_rel_rapp_laatkoers,
                                                                 9)
                       into   v_koersverhouding_ow
                       from   dual;
                       v_koersverhouding_ow := v_koersverhouding_ow * -1;
                    end if;
                    
                    if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
                    then
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'OW factor        : '||r_mo.mnd_factor||' ;  OW symbool : '||r_mo.be_symbool);
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'OW optietype     : '||r_mo.be_optietype||' ; OW expiratiedatum : '||r_mo.be_expiratiedatum);
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'OW exerciseprijs : '||to_char(r_mo.be_exerciseprijs)||' ; OW omschrijving : '||r_mo.be_oms_1);
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'OW be bi nummer  : '||to_char(r_mo.be_bi_nummer)||' ; OW muntsoort : '||r_mo.be_muntsoort);
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                    end if;
                    
                    -- Bepalen van een aantal gegevens aan de hand van de positie in de onderliggende waarde
                    select p.pwb_port_waarde_rapv,     p.pwb_dekk_waarde_rapv
                    into   v_positie_port_waarde_rapv, v_positie_dekk_waarde_rapv
                    from   positie_werkbestand p
                    where  p.pwb_relatie_nummer  = gv_relatienummer
                    and    p.pwb_rekening_nummer = ' '
                    and    p.pwb_rekening_soort  = 0
                    and    p.pwb_symbool         = r_mo.be_symbool
                    and    p.pwb_optietype       = r_mo.be_optietype
                    and    p.pwb_expiratiedatum  = r_mo.be_expiratiedatum
                    and    p.pwb_exerciseprijs   = r_mo.be_exerciseprijs;
                                          
                    -- Bepalen van de wegingsfactor:
                    if v_positie_port_waarde_rapv <> 0
                    then
                       v_wegingsfactor := round(v_positie_dekk_waarde_rapv / v_positie_port_waarde_rapv * 100, 3);
                    else
                       v_wegingsfactor := 0;
                    end if;
                    
                    -- De berekening van de trekkingswaarde (coverwaarde mbv exerciseprijs of fonds biedkoers)
                    -- De check moet plaats vinden met behulp van de samengestelde fonds biedkoers van het mandje:
                    -- echter hierbij moet nog bepaald worden hoe er gerekend moet worden als de exerciseprijs kleiner dan de fonds biedkoers is.
                    -- Daarom is in overleg met Asam de berekening voor de OW uit mandjes even uit gezet totdat een correcte exerciseprijs berekend kan worden.
                    -- Voor de duidelijkheid is de uitgecommentarieerde code verwijderd.
                    if v_wegingsfactor <> 0
                    then  
                       FIAT_ALGEMEEN.fondskoersen (r_mo.be_symbool, r_mo.be_optietype, r_mo.be_expiratiedatum, r_mo.be_exerciseprijs,
                                                   i_slot_of_laatste_koers, v_fonds_biedkoers_ow_mnd, v_dummy);  
                                                   
                       -- Het coverbedrag moet niet met de samengestelde biedkoers worden berekend, maar met de biedkoers van het daadwerkelijke fonds
                       v_cover_bedrag    := round(r_ms.tms_gecovered * r_ms.tms_blocksize * r_mo.mnd_factor * r_ms.tms_pricing_unit * v_fonds_biedkoers_ow_mnd *
                                                  v_wegingsfactor/100 * v_koersverhouding_ow, gv_rel_rapp_notatie);
                       v_cover_bedrag_vv := round(r_ms.tms_gecovered * r_ms.tms_blocksize * r_mo.mnd_factor * r_ms.tms_pricing_unit * v_fonds_biedkoers_ow_mnd *
                                                  v_wegingsfactor/100, v_val_notatie);                        
                    -- Als de wegingsfactor 0 is, dan kan het cover bedrag ook alleen maar 0 zijn
                    else
                       v_cover_bedrag    := 0;
                       v_cover_bedrag_vv := 0;
                    end if;
                    
                    if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
                    then
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Wegingsfactor        : '||to_char(v_wegingsfactor));
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'exerciseprijs optie  : '||to_char(r_ms.tms_exerciseprijs)
                                                               ||' ; OW fondsbiedkoers : '||to_char(v_fonds_biedkoers_ow_mnd));
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Mandje biedkoers     : '||to_char(v_fonds_biedkoers)||' ; cover bedrag  : '||to_char(v_cover_bedrag));
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Cover bedrag vv      : '||to_char(v_cover_bedrag_vv));
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                    end if;
                    
                    -- proberen weg te schrijven van deze waarde in het werkbestand:
                    update werkbestand w
                    set    w.wk_waarde_1    = w.wk_waarde_1 + -1*v_cover_bedrag,
                           w.wk_waarde_2    = w.wk_waarde_2 + -1*v_cover_bedrag_vv
                    where  w.wk_terminal    = gv_terminalnummer
                    and    w.wk_soort       = 'COVR'
                    and    w.wk_categorie_1 = ' '
                    and    w.wk_categorie_2 = 'Cover'
                    and    w.wk_categorie_3 = r_mo.be_symbool 
                    and    w.wk_categorie_4 = SUBSTR(r_mo.be_oms_1,1,26)
                    and    w.wk_datum_1     = '00000000';
                       
                    -- als de update niet lukt dan een nieuw record wegschrijven
                    if sql%notfound
                    then
                       insert into werkbestand
                       (wk_terminal,       wk_soort,                   wk_categorie_1, wk_categorie_2,
                        wk_categorie_3,    wk_categorie_4,             wk_datum_1,     wk_waarde_1,
                        wk_waarde_2)
                       values                                          
                       (gv_terminalnummer, 'COVR',                     ' ',            'Cover',
                        r_mo.be_symbool,   SUBSTR(r_mo.be_oms_1,1,26), '00000000',     -1*v_cover_bedrag,
                        v_cover_bedrag_vv);
                    end if;
              
                 end loop;  -- Einde loop r_mo
              end;          -- Einde van de Declare van o.a. de cursir r_mo
           end if;          -- Einde van wel ow is mandje
        end if;             -- Einde van trekkingswaarde moet berekend worden
     end if;                -- Einde van het niet futuregedeelte
  end loop;                 -- Einde van loop r_ms (hoofdloop)
  
  if gv_debuggen = 1 and gv_runnummer = gv_debug_runnummer
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Einde procedure ma_registratie ');
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
  end if;
   
end ma_registratie;
-- EINDE CODE PROCEDURE MA_REGISTRATIE


-- DE CODE VOOR DE PROCEDURE MA_TOT_FUTURE_MARGIN
-- Deze procedure totaliseert alle required margin voor een relatie (en zal dan het totaal
-- van de future waarborgen weergeven (vergelijk Magic programma 171, subtaak 5 Bereken margin future).
procedure ma_tot_future_margin
(o_future_margin              out    temp_margin_wb_sessie.tms_margin_required%type
)
-- In deze procedure wordt het totaal van de future margin bepaalt als de klant verder geen margin hoeft te berekenen.
-- Inkomende parameters zijn: i_terminalnr    = terminalnummer waarbij de gegevens zijn weggeschreven
--                            i_runnummer     = het runnummer waarvoor de berekening wordt uitgevoerd
-- Uitgaande parameters zijn: o_future_margin = het totale future margin bedrag in rapportage valuta

is

       v_val_biedkoers       muntsoorten.mu_biedkoers%type   := 0;
       v_val_laatkoers       muntsoorten.mu_laatkoers%type   := 0;
       v_val_reciproke       muntsoorten.mu_reciproke%type   := 0;
       v_val_factor          muntsoorten.mu_factor%type      := 0;

cursor mw is

       select   m.tms_valuta, sum(m.tms_margin_required) future_margin_sum
       from     temp_margin_wb_sessie m
       where    m.tms_relatienr  = gv_terminalnummer
       and      m.tms_runnnummer = gv_runnummer
       group by m.tms_valuta;

begin
     -- future margin op 0 stellen.
     o_future_margin := 0;

     for r_mw in mw
     loop

       if gv_rel_rapp_valuta <> r_mw.tms_valuta
       then
          FIAT_ALGEMEEN.valutagegevens_bepalen (r_mw.tms_valuta,         gv_relatie_pr_id, gv_relatie_ppr_id, gv_systspreadcodecategorie,
                                                gv_bank2mrktqchangedate, gv_debuggen,      gv_debug_user,     v_val_biedkoers,
                                                gv_dummy,                v_val_laatkoers,  v_val_factor,      v_val_reciproke,
                                                gv_dummy);
          
          select FIAT_ALGEMEEN.omrekenen_bedrag_vv(r_mw.future_margin_sum, v_val_reciproke,        v_val_factor,
                                                   v_val_biedkoers,        v_val_laatkoers,        gv_rel_rapp_reciproke,
                                                   gv_rel_rapp_factor,     gv_rel_rapp_biedkoers , gv_rel_rapp_laatkoers,
                                                   gv_rel_rapp_notatie)
          into   r_mw.future_margin_sum
          from   dual;
       end if;

       o_future_margin := o_future_margin + round(r_mw.future_margin_sum, gv_rel_rapp_notatie);
     end loop;

end ma_tot_future_margin;
-- EINDE CODE PROCEDURE MA_TOT_FUTURE_MARGIN


-- DE CODE VOOR DE FUNCTION VERSION
function Version
return varchar2
is

begin
      return gv_versie;
end version;
-- EINDE CODE FUNCTION VERSION

end FIAT_MARGIN;
/
