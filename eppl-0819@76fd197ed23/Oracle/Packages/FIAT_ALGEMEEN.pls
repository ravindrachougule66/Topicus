create or replace package FIAT_ALGEMEEN
is

/*------------------------------------------------------------------------------
Package     : FIAT_ALGEMEEN
description : code voor de package FIAT_ALGEMEEN waarbinnen de volgende functions en
              procedures aanwezig zijn:
              function   aflossingskoers
              procedure  fondskoersen
              procedure  fondsprijzen
              procedure  inital_margin
              function   instell_ophalen
              procedure  muntkoers_bepalen
              function   omrekenen_bedrag
              function   omrekenen_bedrag_vv
              function   rente_factor_berek
              function   transsatus
              procedure  fiat_debug
              procedure  fiat_acties
              procedure  version_uitvraag
              function   version
              function   instell_bepalen
------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';

-- function aflossingskoers:
   function aflossingskoers
   (i_symbool                         beleggingsinstrument.be_symbool%type
   ,i_datum_uitkeren                  transakties.tr_boekdatum%type
   )
   return                             renteschemas.ra_afloskoers_va%type;

-- procedure fondskoersen:
   procedure fondskoersen
   (i_symbool                    in   beleggingsinstrument.be_symbool%type
   ,i_optietype                  in   beleggingsinstrument.be_optietype%type
   ,i_expiratiedatum             in   beleggingsinstrument.be_expiratiedatum%type
   ,i_exerciseprijs              in   beleggingsinstrument.be_exerciseprijs%type
   ,i_slot_of_last               in   varchar2
   ,o_koers_bied                 out  fn_quotes_vw.quot_bied%type
   ,o_koers_laat                 out  fn_quotes_vw.quot_laat%type
   );

-- procedure fondskoers_meerdere_ow:
   procedure fondskoers_meerdere_ow
   (i_referentie_be_volgnummer   in   beleggingsinstrument.be_volgnummer%type
   ,i_block_size_optie           in   beleggingsinstrument.be_prijs_factor%type
   ,i_slot_of_last               in   varchar2
   ,i_debuggen                   in   relatie_fiattering.rf_debug_j_n%type
   ,i_debug_user                 in   relatie_fiattering.rf_debug_user%type
   ,o_koers_bied                 out  fn_quotes_vw.quot_bied%type
   ,o_koers_laat                 out  fn_quotes_vw.quot_laat%type
   );

-- procedure fondsprijzen:
   procedure fondsprijzen
   (i_fondssymbool               in   beleggingsinstrument.be_symbool%type
   ,i_optietype                  in   beleggingsinstrument.be_optietype%type
   ,i_expiratiedatum             in   beleggingsinstrument.be_expiratiedatum%type
   ,i_exerciseprijs              in   beleggingsinstrument.be_exerciseprijs%type
   ,i_transactie_soort           in   kosten_werkbestand.kst_trans_indicatie%type
   ,i_transactie_soort_tb_waarde in   transactiesoorten.ts_koop_verkoop_ind%type
   ,i_order_soort                in   orders.ord_ordersoort%type
   ,i_limiet_toegestaan          in   number
   ,i_limietprijs                in   orders.ord_limiet%type
   ,i_afwijkende_koers_gebruiken in   number
   ,i_afwijkende_koers           in   fn_quotes_vw.quot_bied%type
   ,i_emissie_inschrijfprijs     in   emissies.emi_inschr_hoog%type
   ,i_order_provisie_perc_abs    in   orders.ord_provisie_absoluut%type
   ,i_order_provisieps_bv        in   orders.ord_provisieps_bv%type
   ,i_slot_of_last_koers         in   varchar2
   ,i_debuggen                   in   relatie_fiattering.rf_debug_j_n%type
   ,i_debug_user                 in   relatie_fiattering.rf_debug_user%type
   ,o_klantprijs                 out  fn_quotes_vw.quot_bied%type
   ,o_beursprijs                 out  fn_quotes_vw.quot_bied%type
   ,o_dekkingsprijs              out  fn_quotes_vw.quot_bied%type
   );

-- procedure initial_margin:
   procedure initial_margin
   (i_optietype                  in   beleggingsinstrument.be_optietype%type
   ,i_exerciseprijs              in   beleggingsinstrument.be_exerciseprijs%type
   ,i_pricing_unit               in   beleggingsinstrument.be_pricing_unit%type
   ,i_prijs_factor               in   beleggingsinstrument.be_prijs_factor%type
   ,i_fonds_laat_koers           in   fn_quotes_vw.quot_laat%type
   ,i_margin_factor              in   beleggingsinstrument.be_margin_factor%type
   ,i_opslag_naked_margin        in   beleggingsinstrument.be_margin_opslag%type
   ,i_ow_bied_koers              in   fn_quotes_vw.quot_bied%type
   ,i_aantal                     in   transakties.tr_aantal%type
   ,i_sys_toeslag_optiemarg      in   tabelgegevens.tb_waarde%type
   ,i_rel_toeslag_optiemarg      in   producten.pr_toeslag_percentage%type
   ,i_naked_margin_methode       in   number
   ,i_factor_naked_margin        in   number
   ,i_pr_blokkeren_short_call    in   number
   ,i_pr_blokkeren_short_put     in   number
   ,i_debuggen                   in   relatie_fiattering.rf_debug_j_n%type
   ,i_debug_user                 in   relatie_fiattering.rf_debug_user%type
   ,o_margin                     out  temp_margin_wb_sessie.tms_margin_required%type
   );

-- function instell_ophalen:
   function instell_ophalen
   (i_module_prefix                   instellingen.inst_appl_prefix%type
   ,i_functiecode                     instellingen.inst_functiecode%type
   ,i_instelling_oms                  instellingen_detail.key%type
   ,i_type_waarde                     varchar2
   ,i_debuggen                        relatie_fiattering.rf_debug_j_n%type
   ,i_debug_user                      relatie_fiattering.rf_debug_user%type
   )
   return                             varchar2;

-- procedure muntkoers_bepalen:
   procedure muntkoers_bepalen
   (i_trans_koop_verk_ind        in   transactiesoorten.ts_koop_verkoop_ind%type
   ,i_omrekening_EUR_VV          in   number
   ,i_muntsoort_reciproke        in   muntsoorten.mu_reciproke%type
   ,i_muntsoort_biedkoers        in   muntsoorten.mu_biedkoers%type
   ,i_muntsoort_middenkoers      in  muntsoorten.mu_middenkoers%type
   ,i_muntsoort_laatkoers        in   muntsoorten.mu_laatkoers%type
   ,o_te_gebruiken_muntkoers     out  muntsoorten.mu_laatkoers%type
   );

-- function omrekenen_bedrag:
   function omrekenen_bedrag
   (i_bedrag                          number
   ,i_reciproke                       muntsoorten.mu_reciproke%type
   ,i_factor                          muntsoorten.mu_factor%type
   ,i_biedkoers                       muntsoorten.mu_biedkoers%type
   ,i_laatkoers                       muntsoorten.mu_laatkoers%type
   ,i_notatie                         muntsoorten.mu_notatie%type
   )
   return                             number;

-- function omrekenen_bedrag_vv
   function omrekenen_bedrag_vv
   (i_bedrag_in                       number
   ,i_reciproke_van                   muntsoorten.mu_reciproke%type
   ,i_factor_van                      muntsoorten.mu_factor%type
   ,i_biedkoers_van                   muntsoorten.mu_biedkoers%type
   ,i_laatkoers_van                   muntsoorten.mu_laatkoers%type
   ,i_reciproke_naar                  muntsoorten.mu_reciproke%type
   ,i_factor_naar                     muntsoorten.mu_factor%type
   ,i_biedkoers_naar                  muntsoorten.mu_biedkoers%type
   ,i_laatkoers_naar                  muntsoorten.mu_laatkoers%type
   ,i_notatie_naar                    muntsoorten.mu_notatie%type
   )
   return                             number;

-- function gld_omrekenen_bedrag_vv
   function gld_omrekenen_bedrag_vv
   (i_geldsaldo                       number
   ,i_reciproke_van                   muntsoorten.mu_reciproke%type
   ,i_factor_van                      muntsoorten.mu_factor%type
   ,i_biedkoers_van                   muntsoorten.mu_biedkoers%type
   ,i_laatkoers_van                   muntsoorten.mu_laatkoers%type
   ,i_reciproke_naar                  muntsoorten.mu_reciproke%type
   ,i_factor_naar                     muntsoorten.mu_factor%type
   ,i_biedkoers_naar                  muntsoorten.mu_biedkoers%type
   ,i_laatkoers_naar                  muntsoorten.mu_laatkoers%type
   ,i_notatie_naar                    muntsoorten.mu_notatie%type
   )
   return                             number;

-- function rente_factor_bereken
   function rente_factor_berek
   (i_symbool                         beleggingsinstrument.be_symbool%type
   ,i_bereken_dat                     transakties.tr_boekdatum%type
   ,i_debuggen                        relatie_fiattering.rf_debug_j_n%type
   ,i_debug_user                      relatie_fiattering.rf_debug_user%type
   )
   return                             number;

-- function transstatus
   function transstatus
   (i_status                          number
   ,i_tpc_actions                     number
   ,i_partij                          number
   ,i_positie                         number
   )
   return                             number;

-- procedure fiat_debug
   procedure fiat_debug
   (i_debug_user                      beleggingsadviseurs.ba_magic_user_id%type
   ,i_debug_informatie                varchar2
   );

-- procedure bereken_settl_dat
   procedure bereken_settl_dat
   (i_beursnummer                in   beurzen.brs_nummer%type
   ,i_koop_verkoop               in   number
   ,i_trans_datum                in   transakties.tr_transdatum%type
   ,o_settl_dat                  out  transakties.tr_settlementdatum%type
   );

-- procedure version_uitvraag
   procedure version_uitvraag
   (i_debug_user                      beleggingsadviseurs.ba_magic_user_id%type
   );

-- function version
   function version
   return                             varchar2;

-- function instell_bepalen
   function instell_bepalen
   (i_instelling_string          varchar2
   ,i_op_te_halen_instel         varchar2
   ,i_type_waarde                varchar2
   ,i_debuggen                   relatie_fiattering.rf_debug_j_n%type
   ,i_debug_user                 relatie_fiattering.rf_debug_user%type
   )
   return varchar2;

-- procedure valutagegevens_bepalen
   procedure valutagegevens_bepalen
   (i_muntcode              in  muntsoorten.mu_code%type
   ,i_pr_id                 in  producten.pr_id%type
   ,i_ppr_id                in  producten_per_relatie.ppr_id%type
   ,i_sys_spread_categorie  in  valutaspread_cat_muntsoort.vscm_id%type
   ,i_bank2marketchangedate in  muntsoorten.mu_update%type
   ,i_debuggen              in  relatie_fiattering.rf_debug_j_n%type
   ,i_debug_user            in  relatie_fiattering.rf_debug_user%type
   ,o_biedkoers             out muntsoorten.mu_biedkoers%type
   ,o_middenkoers           out muntsoorten.mu_middenkoers%type
   ,o_laatkoers             out muntsoorten.mu_laatkoers%type
   ,o_factor                out muntsoorten.mu_factor%type
   ,o_reciproke             out muntsoorten.mu_reciproke%type
   ,o_notatie               out muntsoorten.mu_notatie%type
   );

end FIAT_ALGEMEEN;
/
create or replace package body FIAT_ALGEMEEN
is

/*----------------------------------------------------------------------------------------
Package body : FIAT_ALGEMEEN
description  : code voor de package body FIAT_ALGEMEEN waarbinnen de volgende
               functions en procedures aanwezig zijn:
               function   aflossingskoers
               procedure  fondskoersen
               procedure  inital_margin
               function   instell_ophalen
               procedure  muntkoers_bepalen
               function   omrekenen_bedrag
               function   omrekenen_bedrag_vv
               function   gld_omrekenen_bedrag_vv
               function   rente_factor_berek
               function   transsatus
               procedure  fiat_debug
               procedure  fiat_acties
               procedure  tabelgegevens_ophalen
               function   module_definitie_uitvraag
               function   version
----------------------------------------------------------------------------------------*/

-- DE CODE VOOR DE FUNCTION AFLOSSINGSKOERS:
-- Bepalen van de aflossingskoers voor obligaties.
function aflossingskoers
(i_symbool             beleggingsinstrument.be_symbool%type
,i_datum_uitkeren      transakties.tr_boekdatum%type
)
return                 renteschemas.ra_afloskoers_va%type

as

  v_afloskoers_na          renteschemas.ra_afloskoers_va%type;
  v_datum_uitkeren_na      transakties.tr_boekdatum%type;
  v_afloskoers_va          renteschemas.ra_afloskoers_va%type;
  v_datum_uitkeren_va      transakties.tr_boekdatum%type;
  v_afloskoers             renteschemas.ra_afloskoers_va%type;

begin

  select r.ra_afloskoers_va, r.ra_datum_uitkeren
  into   v_afloskoers_na,    v_datum_uitkeren_na
  from   renteschemas r
  where  r.ra_symbool        =  i_symbool
  and    r.ra_type_rb_na_va  =  'NA'
  and    r.ra_datum_uitkeren >= i_datum_uitkeren
  and    rownum              <= 1;

  select s.ra_afloskoers_va, s.ra_datum_uitkeren
  into   v_afloskoers_va,    v_datum_uitkeren_va
  from   renteschemas s
  where  s.ra_symbool        =  i_symbool
  and    s.ra_type_rb_na_va  =  'VA'
  and    s.ra_datum_uitkeren >= i_datum_uitkeren
  and    rownum              <=1;

  if v_afloskoers_na <> 0
     and (v_datum_uitkeren_na < v_datum_uitkeren_va or v_datum_uitkeren_va = '00000000')
  then
     v_afloskoers := v_afloskoers_na;
  else
     if v_afloskoers_va <> 0 and
        (v_datum_uitkeren_va < v_datum_uitkeren_na or v_datum_uitkeren_na = '00000000')
     then
        v_afloskoers := v_afloskoers_va;
     else
        v_afloskoers := 0;
     end if;
  end if;

  exception
         when no_data_found
         then
         v_afloskoers := 0;

  return v_afloskoers;

end aflossingskoers;
-- EINDE CODE FUNCTION AFLOSSINGSKOERS


-- DE CODE VOOR DE PROCEDURE FONDSKOERSEN:
-- In deze procedure worden de bied en laat koers van het meegestuurde fonds bepaalt aan de hand
-- van de instelling voor slot of laatste koers...
procedure fondskoersen
(i_symbool        in  beleggingsinstrument.be_symbool%type
,i_optietype      in  beleggingsinstrument.be_optietype%type
,i_expiratiedatum in  beleggingsinstrument.be_expiratiedatum%type
,i_exerciseprijs  in  beleggingsinstrument.be_exerciseprijs%type
,i_slot_of_last   in  varchar2
,o_koers_bied     out fn_quotes_vw.quot_bied%type
,o_koers_laat     out fn_quotes_vw.quot_laat%type
)

-- inkomende parameters zijn: i_symbool        = fondssymbool van het fonds waarvoor de koers bepaald moet worden
--                            i_optietype      = optietype van het fonds waarvoor de koers bepaald moet worden
--                            i_expiratiedatum = expiratiedatum van het fonds waarvoor de koers bepaald moet worden
--                            i_exerciseprijs  = exerciseprijs van het fonds waarvoor de koers bepaald moet worden
--                            i_slot_of_last   = indicatie voor de slot (S) of laatste (L) koers die opgehaald moet worden
-- uitgaande parameters zijn: o_koers_bied     = biedkoers van het fonds waarvoor de koers bepaald moet worden
--                            o_koers_laat     = laatkoers van het fonds waarvoor de koers bepaald moet worden

is
   v_max_k_datum     fn_quotes_vw.quot_datum%type;
   v_max_k_tijd      fn_quotes_vw.quot_tijd%type;
   v_maxd_slot       varchar2(14);
   v_maxd_last       varchar2(14);

begin
   begin
      select quot_datum,      quot_tijd
      into   v_max_k_datum, v_max_k_tijd
      from   (
              select quot_datum, quot_tijd
              from   fn_quotes_vw
              where  quot_soort          =  'SLOT'
              and    quot_symbool        =  i_symbool
              and    quot_optietype      =  i_optietype
              and    quot_expiratiedatum =  i_expiratiedatum
              and    quot_exerciseprijs  =  i_exerciseprijs
              and    quot_datum          <= to_char(SYSDATE,'yyyymmdd')
              order by quot_symbool, quot_optietype, quot_expiratiedatum, quot_exerciseprijs, quot_soort, quot_datum desc, quot_tijd desc
             )
      where rownum <= 1;
   exception
      when no_data_found
      then
         v_max_k_datum := ' ';
         v_max_k_tijd  := ' ';
   end;

   v_maxd_slot := v_max_k_datum||v_max_k_tijd;

   if v_maxd_slot is null
   then
      v_maxd_slot := ' ';
   end if;

   if i_slot_of_last <> 'S'
   then
      begin
         select max(quot_datum || quot_tijd)
         into   v_maxd_last
         from   fn_quotes_vw
         where  quot_soort          =  'LAST'
         and    quot_symbool        =  i_symbool
         and    quot_optietype      =  i_optietype
         and    quot_expiratiedatum =  i_expiratiedatum
         and    quot_exerciseprijs  =  i_exerciseprijs
         and    quot_datum          <= to_char(SYSDATE,'yyyymmdd');
      exception
         when no_data_found
         then
            v_maxd_last := ' ';
      end;

      if v_maxd_last is null
      then
         v_maxd_last := ' ';
      end if;
   end if;

   if (v_maxd_slot <> ' ' and v_maxd_last < v_maxd_slot or i_slot_of_last = 'S')
   then
      select quot_bied,      quot_laat
      into   o_koers_bied, o_koers_laat
      from   fn_quotes_vw
      where  quot_soort            = 'SLOT'
      and    quot_symbool          = i_symbool
      and    quot_optietype        = i_optietype
      and    quot_expiratiedatum   = i_expiratiedatum
      and    quot_exerciseprijs    = i_exerciseprijs
      and    quot_datum || quot_tijd = v_maxd_slot;
   else
      if v_maxd_last <> ' '
      then
         select   quot_bied,      quot_laat
         into     o_koers_bied, o_koers_laat
         from     fn_quotes_vw
         where    quot_soort            = 'LAST'
         and      quot_symbool          = i_symbool
         and      quot_optietype        = i_optietype
         and      quot_expiratiedatum   = i_expiratiedatum
         and      quot_exerciseprijs    = i_exerciseprijs
         and      quot_datum || quot_tijd = v_maxd_last;
      else
         o_koers_bied := 0;
         o_koers_laat := 0;
      end if;
   end if;

exception
   when no_data_found
   then
      o_koers_bied := 0;
      o_koers_laat := 0;

end fondskoersen;
-- EINDE CODE PROCEDURE FONDSKOERSEN


-- DE CODE VOOR PROCEDURE FONDSKOERS_MEERDERE_OW:
-- In deze procedure wordt voor een optie op een mandje de bied- en laatkoers
-- van de "onderliggende waarde" bepaalt aan de hand van de koersen van de
-- all fondsen uit het mandje
procedure fondskoers_meerdere_ow
(i_referentie_be_volgnummer   in   beleggingsinstrument.be_volgnummer%type
,i_block_size_optie           in   beleggingsinstrument.be_prijs_factor%type
,i_slot_of_last               in   varchar2
,i_debuggen                   in   relatie_fiattering.rf_debug_j_n%type
,i_debug_user                 in   relatie_fiattering.rf_debug_user%type
,o_koers_bied                 out  fn_quotes_vw.quot_bied%type
,o_koers_laat                 out  fn_quotes_vw.quot_laat%type
)

-- Inkomende parameters zijn : i_referentie_be_volgnummer = het beleggingsinstrument volgnummer van het mandje
--                             i_block_size_optie         = de blocksize van de optie op het mandje. Dit is de waarde
--                                                          waardoor de som van de koersen wordt gedeeld
--                             i_slot_of_last             = indicatie voor de slot (S) of laatste (L) koers die opgehaald moet worden
--                             i_debuggen                 = vlag die aangeeft of debuginformatie moet worden getoond
--                             i_debug_user               = de gebruiker waarvoor de debuginformatie gemaakt moet worden
-- Uitgaande parameters zijn : o_koers_bied               = de berekende biedkoers van de "onderliggende waarde"
--                             o_koers_laat               = de berekende laatkoers van de "onderliggende waarde"

is

   cursor mo is
      select m.mnd_factor,        b.be_symbool,      b.be_optietype,
             b.be_expiratiedatum, b.be_exerciseprijs
      from   mandje_onderliggende_waarde m, beleggingsinstrument b
      where  m.mnd_volgnummer = i_referentie_be_volgnummer
      and    m.mnd_ref_volgnr = b.be_volgnummer;

   v_bied_koers              fn_quotes_vw.quot_bied%type;
   v_laat_koers              fn_quotes_vw.quot_laat%type;
   v_bied_koers_totaal       fn_quotes_vw.quot_bied%type;
   v_laat_koers_totaal       fn_quotes_vw.quot_laat%type;

begin
   -- resetten voor het begin
   v_bied_koers_totaal  := 0;
   v_laat_koers_totaal  := 0;

for r_mo in mo
loop
   -- resetten op loopniveau
   v_bied_koers           := 0;
   v_laat_koers           := 0;

   -- Bepaal voor de gevonden ow uit het mandje de fondskoersen:
   FIAT_ALGEMEEN.fondskoersen (r_mo.be_symbool, r_mo.be_optietype, r_mo.be_expiratiedatum, r_mo.be_exerciseprijs,
                               i_slot_of_last,  v_bied_koers, v_laat_koers);

   -- De totale mandjes koers bijwerken:
   v_bied_koers_totaal := v_bied_koers_totaal + r_mo.mnd_factor * i_block_size_optie * v_bied_koers;
   v_laat_koers_totaal := v_laat_koers_totaal + r_mo.mnd_factor * i_block_size_optie * v_laat_koers;

   if i_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'In procedure FIAT_ALGEEN.fondskoers_meerdere_ow');
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'referentie be_volgnummer : '||to_char(i_referentie_be_volgnummer));
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'OW symbool               : '||r_mo.be_symbool||' ; OW optietype : '||r_mo.be_optietype);
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'OW expiratiedatum        : '||r_mo.be_expiratiedatum||' ; OW exerciseprijs : '||to_char(r_mo.be_exerciseprijs));
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'OW factor in mandje      : '||to_char(r_mo.mnd_factor)||' ; blocksize : '||to_char(i_block_size_optie));
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'biedkoers                : '||to_char(v_bied_koers)||' ; laatkoers : '||to_char(v_laat_koers));
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'biedkoers totaal         : '||to_char(v_bied_koers_totaal)||' ; laatkoers totaal : '||to_char(v_laat_koers_totaal));
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,' ');
   end if;

end loop;

   o_koers_bied := round(v_bied_koers_totaal / i_block_size_optie ,6);
   o_koers_laat := round(v_laat_koers_totaal / i_block_size_optie ,6);

end fondskoers_meerdere_ow;
-- EINDE CODE PROCEDURE FONDSKOERS_MEERDERE_OW


-- DE CODE VOOR DE PROCEDURE FONDSPRIJZEN:
-- In deze procedure worden de klant, beurs en dekkingskoers (prijs) van het meegestuurde fonds
-- bepaalt aan de hand van de diverse meegestuurde gegevens....
procedure fondsprijzen
(i_fondssymbool               in   beleggingsinstrument.be_symbool%type
,i_optietype                  in   beleggingsinstrument.be_optietype%type
,i_expiratiedatum             in   beleggingsinstrument.be_expiratiedatum%type
,i_exerciseprijs              in   beleggingsinstrument.be_exerciseprijs%type
,i_transactie_soort           in   kosten_werkbestand.kst_trans_indicatie%type
,i_transactie_soort_tb_waarde in   transactiesoorten.ts_koop_verkoop_ind%type
,i_order_soort                in   orders.ord_ordersoort%type
,i_limiet_toegestaan          in   number
,i_limietprijs                in   orders.ord_limiet%type
,i_afwijkende_koers_gebruiken in   number
,i_afwijkende_koers           in   fn_quotes_vw.quot_bied%type
,i_emissie_inschrijfprijs     in   emissies.emi_inschr_hoog%type
,i_order_provisie_perc_abs    in   orders.ord_provisie_absoluut%type
,i_order_provisieps_bv        in   orders.ord_provisieps_bv%type
,i_slot_of_last_koers         in   varchar2
,i_debuggen                   in   relatie_fiattering.rf_debug_j_n%type
,i_debug_user                 in   relatie_fiattering.rf_debug_user%type
,o_klantprijs                 out  fn_quotes_vw.quot_bied%type
,o_beursprijs                 out  fn_quotes_vw.quot_bied%type
,o_dekkingsprijs              out  fn_quotes_vw.quot_bied%type
)

is

  v_fonds_koers_bied          fn_quotes_vw.quot_bied%type      := 0;
  v_fonds_koers_laat          fn_quotes_vw.quot_laat%type      := 0;
  v_werk_provisie_ps          orders.ord_provisieps_bv%type ;

  v_klantprijs                fn_quotes_vw.quot_bied%type      := 0;
  v_dekkingsprijs             fn_quotes_vw.quot_bied%type      := 0;
  v_beursprijs                fn_quotes_vw.quot_bied%type      := 0;

begin
   -- bepalen van de v_klantprijs en de v_beursprijs. Als de waarde voor i_afwijkende_koers_gebruiken 0 is
   -- dan moet gerekend worden met de limiet of koers, Als de waarde voor i_afwijkende_koers_gebruiken 1
   -- is dan moet er worden gerekend met 0 voor de koersen.
   if i_transactie_soort not in ('EX C','EX P')
   then
      if i_afwijkende_koers_gebruiken = 0
         or
         i_afwijkende_koers_gebruiken = 1 and i_afwijkende_koers = 0
      then
         FIAT_ALGEMEEN.fondskoersen(i_fondssymbool, i_optietype, i_expiratiedatum, i_exerciseprijs,
                                    i_slot_of_last_koers, v_fonds_koers_bied, v_fonds_koers_laat);
         
         -- Limiet orders:
         if i_order_soort = 'L' or i_limiet_toegestaan = 1
         then
            -- De ongunstigste koersen nemen voor de klant, dus
            -- Koopachtigen    : notabedrag zo hoog mogelijk, dekkingswaarde zo laag mogelijk
            -- Verkoopachtigen : notabedrag zo laag mogelijk, dekkingswaarde zo hoog mogelijk
            -- Uitzonderingen zijn limiet-emissies, daarbij altijd de limiet gebruiken
            if i_transactie_soort = 'EMIS'
            then
               v_klantprijs    := i_limietprijs;
               v_dekkingsprijs := i_limietprijs;
            elsif i_transactie_soort_tb_waarde = 1
            then
               v_klantprijs := i_limietprijs;
               if i_limietprijs > v_fonds_koers_bied
               then
                  v_dekkingsprijs := v_fonds_koers_bied;
               else
                  v_dekkingsprijs := i_limietprijs;
               end if;
            else
               v_klantprijs := i_limietprijs;
               if i_limietprijs < v_fonds_koers_laat
               then
                  v_dekkingsprijs := v_fonds_koers_laat;
               else
                  v_dekkingsprijs := i_limietprijs;
               end if;
            end if;
         else
            -- Geen limiet of v_limiet_toegestaan <> 1
            -- Bij emissies de inschrijfprijs gebruiken
            if i_transactie_soort = 'EMIS'
            then
               v_klantprijs    := i_emissie_inschrijfprijs;
               v_dekkingsprijs := i_emissie_inschrijfprijs;
            elsif i_transactie_soort_tb_waarde = 1
            then
               v_klantprijs    := v_fonds_koers_laat;
               v_dekkingsprijs := v_fonds_koers_bied;
            else
               v_klantprijs    := v_fonds_koers_bied;
               v_dekkingsprijs := v_fonds_koers_laat;
            end if;
         end if;
      else -- i_afwijkende_koers_gebruiken <> 0 en i_afwijkende_koers <> 0
         v_klantprijs    := i_afwijkende_koers;
         v_beursprijs    := i_afwijkende_koers;
         v_dekkingsprijs := i_afwijkende_koers;
      end if;
   else
      -- Voor exercises wordt voor de prijzen gebruik gemaakt van de exerciseprijs
      v_klantprijs    := i_exerciseprijs;
      v_beursprijs    := i_exerciseprijs;
      v_dekkingsprijs := i_exerciseprijs;
   end if;
   
   -- Als afwijkende koers gebruiken <> 0 en afwijkende koers = 0, dan de klant en beursprijs de afwijkende koers geven:
   if i_afwijkende_koers_gebruiken = 1 and i_afwijkende_koers = 0
   then
      v_klantprijs    := i_afwijkende_koers;
      v_beursprijs    := i_afwijkende_koers;
   end if;
   
   if i_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'In procedure FIAT_ALGEMEEN.fondsprijzen, bepalen van de te gebruiken fondsprijzen');
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'fondssymbool : '||i_fondssymbool||' ; optietype : '||i_optietype);
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'expiratiedatum : '||i_expiratiedatum||' ; exerciseprijs : '||to_char(i_exerciseprijs));
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'transactiesoort : '||i_transactie_soort||' ; klantprijs : '||to_char(v_klantprijs));
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'beursprijs : '||to_char(v_beursprijs)||' ; dekkingsprijs : '||to_char(v_dekkingsprijs));
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'  ');
   end if;

   -- Omzetting van % naar bedrag als prov_perc_of_abs <> 0
   -- anders het absolute bedrag.
   if i_transactie_soort in ('KN','VN')
   then
      -- omzetten van percentage naar bedrag:
      if i_order_provisie_perc_abs = 0
      then
         select decode(i_order_soort,'B',v_beursprijs * i_order_provisieps_bv/100,'L', i_limietprijs * i_order_provisieps_bv/100,0)
         into   v_werk_provisie_ps
         from   dual;
      else
         v_werk_provisie_ps := i_order_provisieps_bv;
      end if;
   end if;

   -- Uitzonderingen: Bestens en KN/VN/EMIS
   if i_order_soort = 'B' and i_transactie_soort in ('KN','VN','EMIS')
   then
      if v_beursprijs = 0
      then
         v_beursprijs := v_klantprijs;
      end if;

      if i_transactie_soort = 'KN'
      then
         if i_limietprijs <> 0
         then
            v_klantprijs := i_limietprijs;
         else
            v_klantprijs := v_beursprijs + v_werk_provisie_ps;
         end if;
      elsif i_transactie_soort = 'VN'
      then
         if i_limietprijs <> 0
         then
            v_klantprijs := i_limietprijs;
         else
            v_klantprijs := v_beursprijs - v_werk_provisie_ps;
         end if;
      end if;
   end if;

   -- Uitzondering: Limiet en KN/VN
   if (i_order_soort = 'L' or i_limiet_toegestaan = 1) and i_transactie_soort in ('KN','VN')
   then
      v_beursprijs := i_limietprijs;

      if i_transactie_soort = 'KN'
      then
         v_klantprijs := v_beursprijs + v_werk_provisie_ps;
      else
         v_klantprijs := v_beursprijs - v_werk_provisie_ps;
      end if;
   end if;

   -- Als de uiteindelijke prijzen bepaald zijn deze terug geven
   o_klantprijs      := v_klantprijs;
   o_beursprijs      := v_beursprijs;
   o_dekkingsprijs   := v_dekkingsprijs;

   if i_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'na uitzondering limiet en KN/VN, de uiteindelijke prijzen :');
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'klantprijs    : '||to_char(o_klantprijs)||' ; beursprijs : '||to_char(o_beursprijs));
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'dekkingsprijs : '||to_char(o_dekkingsprijs));
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'  ');
   end if;
end fondsprijzen;
-- EINDE CODE PROCEDURE FONDSPRIJZEN


-- DE CODE VOOR DE PROCEDURE INITIAL_MARGIN:
-- In deze procedure wordt de bruto (initial) margin berekend aan de hand van de gegevens die
-- worden aangeleverd middels de parameters.
procedure initial_margin
(i_optietype               in   beleggingsinstrument.be_optietype%type
,i_exerciseprijs           in   beleggingsinstrument.be_exerciseprijs%type
,i_pricing_unit            in   beleggingsinstrument.be_pricing_unit%type
,i_prijs_factor            in   beleggingsinstrument.be_prijs_factor%type
,i_fonds_laat_koers        in   fn_quotes_vw.quot_laat%type
,i_margin_factor           in   beleggingsinstrument.be_margin_factor%type
,i_opslag_naked_margin     in   beleggingsinstrument.be_margin_opslag%type
,i_ow_bied_koers           in   fn_quotes_vw.quot_bied%type
,i_aantal                  in   transakties.tr_aantal%type
,i_sys_toeslag_optiemarg   in   tabelgegevens.tb_waarde%type
,i_rel_toeslag_optiemarg   in   producten.pr_toeslag_percentage%type
,i_naked_margin_methode    in   number
,i_factor_naked_margin     in   number
,i_pr_blokkeren_short_call in   number
,i_pr_blokkeren_short_put  in   number
,i_debuggen                in   relatie_fiattering.rf_debug_j_n%type
,i_debug_user              in   relatie_fiattering.rf_debug_user%type
,o_margin                  out  temp_margin_wb_sessie.tms_margin_required%type
)

is

begin

    if i_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug( i_debug_user,'in procedure FIAT_ALGEMEEN.initial_margin');
       FIAT_ALGEMEEN.fiat_debug( i_debug_user,'optie type       : '||i_optietype||
                                              ' ; exerciseprijs : '||i_exerciseprijs);
       FIAT_ALGEMEEN.fiat_debug( i_debug_user,'pricing unit     : '||i_pricing_unit||
                                              ' ; prijs factor : '||i_prijs_factor);
       FIAT_ALGEMEEN.fiat_debug( i_debug_user,'fonds laat koers : '||i_fonds_laat_koers||
                                              ' ; margin factor : '||i_margin_factor);
       FIAT_ALGEMEEN.fiat_debug( i_debug_user,'ow bied koers    : '||i_ow_bied_koers||' ; aantal : '||i_aantal);
       FIAT_ALGEMEEN.fiat_debug( i_debug_user,'sys toeslag      : '||i_sys_toeslag_optiemarg||
                                              ' ; rel toeslag : '||i_rel_toeslag_optiemarg);
       FIAT_ALGEMEEN.fiat_debug( i_debug_user,'blokkeren short call : '||i_pr_blokkeren_short_call||
                                              ' ; blokkeren short put : '||i_pr_blokkeren_short_put);
       FIAT_ALGEMEEN.fiat_debug( i_debug_user,'naked margin methode : '||i_naked_margin_methode||
                                              ' ; factor naked margin : '||i_factor_naked_margin);
       FIAT_ALGEMEEN.fiat_debug( i_debug_user,'opslag naked margin : '||i_opslag_naked_margin);
    end if;

    -- blokkeren niet actief of relatie heeft geen margin volgens product
    if i_optietype = 'CALL' and i_pr_blokkeren_short_call = 0
       or
       i_optietype = 'PUT' and i_pr_blokkeren_short_put = 0
    then
       -- Berekenen van de initial (bruto) margin
       if i_optietype = 'CALL'
       then
          -- voor call:
          o_margin := 2 * i_ow_bied_koers - (i_exerciseprijs / i_pricing_unit);
       else
          -- voor put:
          o_margin := 2 * (i_exerciseprijs / i_pricing_unit) - i_ow_bied_koers;
       end if;

       if o_margin <0
       then
          o_margin := 0;
       end if;

       o_margin := i_margin_factor/100 * o_margin;
       o_margin := i_fonds_laat_koers/i_pricing_unit + o_margin;

       if i_debuggen = 1
       then
          FIAT_ALGEMEEN.fiat_debug( i_debug_user,'margin bedrag voor de toeslagen : '||o_margin);
       end if;

       -- Als de naked margin methode 1 (verscherpte naked margin) is dan moet nog een extra check
       -- plaats vinden om te bepalen wat de naked margin moet worden
       if i_naked_margin_methode = 1
       then
          select greatest (o_margin,
                           (i_fonds_laat_koers/i_pricing_unit) * (1 + (i_factor_naked_margin/100)),
                           (i_fonds_laat_koers + i_opslag_naked_margin)/i_pricing_unit
                          )
          into   o_margin
          from   dual;
       end if;

       o_margin := i_prijs_factor * i_pricing_unit * o_margin;
       o_margin := ABS(i_aantal) * o_margin;
       -- Maximale margin voor put-opties is Exerciseprijs * aantal * blocksize
       if i_optietype = 'PUT' and o_margin > i_exerciseprijs * ABS (i_aantal) * i_prijs_factor
       then
          o_margin := i_exerciseprijs * ABS (i_aantal) * i_prijs_factor;
       end if;
       -- Toeslagen toepassen op de berekende margin
       o_margin := (1 + (i_sys_toeslag_optiemarg/100)) * o_margin;
       o_margin := (1 + (i_rel_toeslag_optiemarg/100)) * o_margin;

    elsif i_optietype = 'CALL' and i_pr_blokkeren_short_call = 1
          or
          i_optietype = 'PUT' and i_pr_blokkeren_short_put = 1
    then
       -- Bij blokkeren aktief voor relaties met margin volgens product,
       -- dan altijd exerciseprijs * prijs factor * aantal
       o_margin := i_exerciseprijs * i_prijs_factor * ABS(i_aantal);
    end if;

    if i_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug( i_debug_user,'margin bedrag : '||o_margin);
       FIAT_ALGEMEEN.fiat_debug( i_debug_user,' ');
    end if;

end initial_margin;
-- EINDE CODE PROCEDURE INITIAL_MARGIN


-- DE CODE VOOR DE FUNCTION INSTELL_OPHALEN:
-- Functie voor het ophalen van gegevens uit het bestand instellingen_detail.
-- Dit wordt in Magic gedaan door het programma GetSettings.
function instell_ophalen
(i_module_prefix              instellingen.inst_appl_prefix%type
,i_functiecode                instellingen.inst_functiecode%type
,i_instelling_oms             instellingen_detail.key%type
,i_type_waarde                varchar2
,i_debuggen                   relatie_fiattering.rf_debug_j_n%type
,i_debug_user                 relatie_fiattering.rf_debug_user%type
)

return varchar2

as

   v_opgehaalde_instelling                  varchar2(100);
   v_goede_instelling_oms                   varchar2(42);
   v_database_instelling_getallen           varchar2(2);

begin
   v_opgehaalde_instelling  := ' ';
   v_goede_instelling_oms   := upper(i_instelling_oms);

   -- ophalen van de instelling uit instellingen_details
   begin
       select d.value
       into   v_opgehaalde_instelling
       from   instellingen_detail d, instellingen i
       where  i.inst_appl_prefix = i_module_prefix
       and    i.inst_functiecode = i_functiecode
       and    i.inst_id          = d.id
       and    d.key              = v_goede_instelling_oms;
   exception
       when no_data_found
       then
          v_opgehaalde_instelling  := ' ';
   end;

   -- als er een numerieke waarde wordt gevraagd (i_type_waarde = 'N') dan checken hoe de database instellingen
   -- voor decimaal scheidingsteken is, zodat daar rekening meegehouden kan worden.
   if i_type_waarde = 'N'
      and
      (instr(v_opgehaalde_instelling,',',1)<>0
       or
       instr(v_opgehaalde_instelling,'.',1)<>0)
   then
      select n.value
      into   v_database_instelling_getallen
      from   nls_session_parameters n
      where  n.parameter = 'NLS_NUMERIC_CHARACTERS';

      if i_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( i_debug_user,'in procedure FIAT_ALGMEEN.instell_ophalen');
         FIAT_ALGEMEEN.fiat_debug( i_debug_user,'module prefix : '||i_module_prefix||' ; functiecode : '||i_functiecode);
         FIAT_ALGEMEEN.fiat_debug( i_debug_user,'instelling omschrijving : '||i_instelling_oms);
         FIAT_ALGEMEEN.fiat_debug( i_debug_user,'opgehaalde instelling : '||v_opgehaalde_instelling);
         FIAT_ALGEMEEN.fiat_debug( i_debug_user,'database instelling getallen : '||v_database_instelling_getallen);
         FIAT_ALGEMEEN.fiat_debug( i_debug_user,' ');
      end if;

      -- alleen maar de komma wijzigen als het decimaal teken een punt is
      if substr(v_database_instelling_getallen,1,1)='.' and instr(v_opgehaalde_instelling,',',1)<>0
      then
         v_opgehaalde_instelling := replace(v_opgehaalde_instelling,',','.');
      end if;
      -- alleen maar de punt wijzigen als het decimaal teken een komma is:
      if substr(v_database_instelling_getallen,1,1)=',' and instr(v_opgehaalde_instelling,'.',1)<>0
      then
         v_opgehaalde_instelling := replace(v_opgehaalde_instelling,'.',',');
      end if;

   end if;

   if i_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'in procedure FIAT_ALGMEEN.instell_ophalen');
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'module prefix : '||i_module_prefix||' ; functiecode : '||i_functiecode);
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'instelling omschrijving : '||i_instelling_oms);
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'opgehaalde instelling : '||v_opgehaalde_instelling);
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,' ');
   end if;

   return v_opgehaalde_instelling;

end instell_ophalen;
-- EINDE CODE FUNCTION INSTELL_OPHALEN


-- DE CODE VOOR DE PROCEDURE MUNTKOERS_BEPALEN
-- procedure om te bepalen of de bied of laat koers gebruikt moet worden bij omrekeningen
-- De gewenste koers wordt als uitgaande parameter teruggeven
procedure muntkoers_bepalen
(i_trans_koop_verk_ind        in  transactiesoorten.ts_koop_verkoop_ind%type
,i_omrekening_EUR_VV          in  number
,i_muntsoort_reciproke        in  muntsoorten.mu_reciproke%type
,i_muntsoort_biedkoers        in  muntsoorten.mu_biedkoers%type
,i_muntsoort_middenkoers      in  muntsoorten.mu_middenkoers%type
,i_muntsoort_laatkoers        in  muntsoorten.mu_laatkoers%type
,o_te_gebruiken_muntkoers     out muntsoorten.mu_laatkoers%type
)

is
   v_geld_verschuldigd_ontvangen   varchar2(1);
   v_te_gebruiken_koerssoort       varchar2(1);

begin
   -- In de fiattering zijn de volgende transactie indicaties van belang:
   -- K, V, KN, VN, OK, OV, SK, SV, OK F, OV F, SK F, SV F en EMIS
   -- Deze hebben in principe koop/verkoop indicatie 1 of 2

   if i_trans_koop_verk_ind = 1
   then
      v_geld_verschuldigd_ontvangen := 'V';
   elsif i_trans_koop_verk_ind = 2
   then
      v_geld_verschuldigd_ontvangen := 'O';
   else
      v_geld_verschuldigd_ontvangen := ' ';
   end if;

   -- Aan de hand van de indicatie bepalen welke koers teruggegeven
   -- moet worden
   if v_geld_verschuldigd_ontvangen = 'V'
   then
      if i_muntsoort_reciproke = 1 and i_omrekening_EUR_VV <> 1
         or
         i_muntsoort_reciproke <> 1 and i_omrekening_EUR_VV = 1
      then
         v_te_gebruiken_koerssoort := 'B';
      else
         v_te_gebruiken_koerssoort := 'L';
      end if;
   elsif v_geld_verschuldigd_ontvangen = 'O'
   then
      if i_muntsoort_reciproke <> 1 and i_omrekening_EUR_VV <> 1
         or
         i_muntsoort_reciproke = 1 and i_omrekening_EUR_VV = 1
      then
         v_te_gebruiken_koerssoort := 'B';
      else
         v_te_gebruiken_koerssoort := 'L';
      end if;
   else
      v_te_gebruiken_koerssoort := 'M';
   end if;

   -- Hier de koers teruggeven:
   if v_te_gebruiken_koerssoort = 'B'
   then
      o_te_gebruiken_muntkoers := i_muntsoort_biedkoers;
   elsif v_te_gebruiken_koerssoort = 'L'
   then
      o_te_gebruiken_muntkoers := i_muntsoort_laatkoers;
   elsif v_te_gebruiken_koerssoort = 'M'
   then
      o_te_gebruiken_muntkoers := i_muntsoort_middenkoers;
   end if;

end muntkoers_bepalen;
-- EINDE CODE PROCEDURE MUNTKOERS_BEPALEN

-- DE CODE VOOR DE FUNCTION OMREKENEN_BEDRAG
-- functie voor het omrekenen van een vv bedrag naar bv. De valuta gegevens (reciproke, factor,
-- bied- en laatkoers en notatie) moeten dan ook van de vv muntsoort zijn.
function omrekenen_bedrag
(i_bedrag         number
,i_reciproke      muntsoorten.mu_reciproke%type
,i_factor         muntsoorten.mu_factor%type
,i_biedkoers      muntsoorten.mu_biedkoers%type
,i_laatkoers      muntsoorten.mu_laatkoers%type
,i_notatie        muntsoorten.mu_notatie%type
)
return            number

as

  v_bedrag    number(20,9);

begin

  if i_bedrag <> 0 and i_factor <> 0
  then

     -- bedrag_in > 0:
     --               de koers van  --> i_biedkoers_van

     -- bedrag_in < 0:
     --               de koers van  --> i_laatkoers_van

     -- reciproke van:
     --               = 1  -->  1 / koers
     --               <> 1 --> koers

     if i_bedrag > 0
     then
        if i_reciproke = 1 and i_biedkoers <> 0
        then
           v_bedrag := round((i_bedrag * 1/i_biedkoers / i_factor), i_notatie);
        elsif i_reciproke = 1 and i_biedkoers = 0
        then
           v_bedrag := 0;
        elsif i_reciproke <> 1
        then
           v_bedrag := round((i_bedrag * i_biedkoers / i_factor), i_notatie);
        end if;
     -- bedrag < 0
     elsif i_bedrag < 0
     then
        if i_reciproke = 1 and i_laatkoers <> 0
        then
           v_bedrag := round((i_bedrag * 1/i_laatkoers / i_factor), i_notatie);
        elsif i_reciproke = 1 and i_laatkoers = 0
        then
           v_bedrag := 0;
        elsif i_reciproke <> 1
        then
           v_bedrag := round((i_bedrag * i_laatkoers / i_factor), i_notatie);
        end if;
     end if;

  else
     v_bedrag := 0;
  end if;

  return v_bedrag;

end omrekenen_bedrag;
-- EINDE CODE FUNCTION OMREKENEN_BEDRAG


-- DE CODE VOOR DE FUNCTION OMREKENEN_BEDRAG_VV:
-- Deze functie rekent het bedrag in om met behulp van de meegestuurde koersen (van en naar).
function omrekenen_bedrag_vv
(i_bedrag_in       number
,i_reciproke_van   muntsoorten.mu_reciproke%type
,i_factor_van      muntsoorten.mu_factor%type
,i_biedkoers_van   muntsoorten.mu_biedkoers%type
,i_laatkoers_van   muntsoorten.mu_laatkoers%type
,i_reciproke_naar  muntsoorten.mu_reciproke%type
,i_factor_naar     muntsoorten.mu_factor%type
,i_biedkoers_naar  muntsoorten.mu_biedkoers%type
,i_laatkoers_naar  muntsoorten.mu_laatkoers%type
,i_notatie_naar    muntsoorten.mu_notatie%type
)
return number

as

  v_bedrag         number(20,9);

begin
  if i_bedrag_in <> 0 and i_factor_van <> 0
  then

     -- bedrag_in > 0:
     --               de koers van  --> i_biedkoers_van
     --               de koers naar --> i_laatkoers_naar

     -- bedrag_in < 0:
     --               de koers van  --> i_laatkoers_van
     --               de koers naar --> i_biedkoers_naar

     -- reciproke van:
     --               = 1  -->  1 / koers
     --               <> 1 --> koers

     -- reciproke naar:
     --               = 1  --> koers
     --               <> 1 --> 1/koers

     -- als 1 van de in de berekeningen gebruikte koersen 0 is, dan niets berekenen (0 teruggeven)

     if i_bedrag_in > 0 and i_biedkoers_van <> 0 and i_laatkoers_naar <> 0
     then
        if i_reciproke_van = 1 and i_reciproke_naar = 1
        then
           v_bedrag := round((i_bedrag_in * 1/i_biedkoers_van / i_factor_van * i_laatkoers_naar * i_factor_naar),
                             i_notatie_naar);
        elsif i_reciproke_van <> 1 and i_reciproke_naar = 1
        then
           v_bedrag := round((i_bedrag_in * i_biedkoers_van / i_factor_van * i_laatkoers_naar * i_factor_naar),
                             i_notatie_naar);
        elsif i_reciproke_van = 1 and i_reciproke_naar <> 1
        then
           v_bedrag := round((i_bedrag_in * 1/i_biedkoers_van / i_factor_van * 1/i_laatkoers_naar * i_factor_naar),
                             i_notatie_naar);
        elsif i_reciproke_van <> 1 and i_reciproke_naar <> 1
        then
           v_bedrag := round((i_bedrag_in * i_biedkoers_van / i_factor_van * 1/i_laatkoers_naar * i_factor_naar),
                             i_notatie_naar);
        end if;
     elsif i_bedrag_in > 0 and (i_biedkoers_van = 0 or i_laatkoers_naar = 0)
     then
        v_bedrag := 0;
     -- bedrag < 0:
     elsif i_bedrag_in < 0 and i_laatkoers_van <> 0 and i_biedkoers_naar <> 0
     then
        if i_reciproke_van = 1 and i_reciproke_naar = 1
        then
           v_bedrag := round((i_bedrag_in * 1/i_laatkoers_van / i_factor_van * i_biedkoers_naar * i_factor_naar),
                             i_notatie_naar);
        elsif i_reciproke_van <> 1 and i_reciproke_naar = 1
        then
           v_bedrag := round((i_bedrag_in * i_laatkoers_van / i_factor_van * i_biedkoers_naar * i_factor_naar),
                             i_notatie_naar);
        elsif i_reciproke_van = 1 and i_reciproke_naar <> 1
        then
           v_bedrag := round((i_bedrag_in * 1/i_laatkoers_van / i_factor_van * 1/i_biedkoers_naar * i_factor_naar),
                             i_notatie_naar);
        elsif i_reciproke_van <> 1 and i_reciproke_naar <> 1
        then
           v_bedrag := round((i_bedrag_in * i_laatkoers_van / i_factor_van * 1/i_biedkoers_naar * i_factor_naar),
                             i_notatie_naar);
        end if;
     elsif i_bedrag_in < 0 and (i_laatkoers_van = 0 or i_biedkoers_naar = 0)
     then
        v_bedrag := 0;
     end if;
  else
     v_bedrag := 0;
  end if;

  return v_bedrag;

end omrekenen_bedrag_vv;
-- EINDE CODE FUNCTION OMREKENEN_BEDRAG_VV


-- DE CODE VOOR DE FUNCTION GLD_OMREKENEN_BEDRAG_VV:
-- Deze functie rekent een geldsaldo om met behulp van de meegestuurde koersen (van en naar).
-- Alleen te gebruiken als het om pure geldbedragen gaat (dus niet portefeuille waardes, etc...)
function gld_omrekenen_bedrag_vv
(i_geldsaldo       number
,i_reciproke_van   muntsoorten.mu_reciproke%type
,i_factor_van      muntsoorten.mu_factor%type
,i_biedkoers_van   muntsoorten.mu_biedkoers%type
,i_laatkoers_van   muntsoorten.mu_laatkoers%type
,i_reciproke_naar  muntsoorten.mu_reciproke%type
,i_factor_naar     muntsoorten.mu_factor%type
,i_biedkoers_naar  muntsoorten.mu_biedkoers%type
,i_laatkoers_naar  muntsoorten.mu_laatkoers%type
,i_notatie_naar    muntsoorten.mu_notatie%type
)
return number

as

  v_bedrag         number(20,9);

begin
  if i_geldsaldo <> 0 and i_factor_van <> 0
  then

     -- geldsaldo > 0:
     --               de koers van  --> i_laatkoers_van
     --               de koers naar --> i_biedkoers_naar

     -- geldsaldo < 0:
     --               de koers van  --> i_biedkoers_van
     --               de koers naar --> i_laatkoers_naar

     -- reciproke van:
     --               = 1  -->  1 / koers
     --               <> 1 --> koers

     -- reciproke naar:
     --               = 1  --> koers
     --               <> 1 --> 1/koers

     -- als 1 van de in de berekeningen gebruikte koersen 0 is, dan niets berekenen (0 teruggeven)

     if i_geldsaldo > 0 and i_laatkoers_van <> 0 and i_biedkoers_naar <> 0
     then
        if i_reciproke_van = 1 and i_reciproke_naar = 1
        then
           v_bedrag := round((i_geldsaldo * 1/i_laatkoers_van / i_factor_van * i_biedkoers_naar * i_factor_naar),
                             i_notatie_naar);
        elsif i_reciproke_van <> 1 and i_reciproke_naar = 1
        then
           v_bedrag := round((i_geldsaldo * i_laatkoers_van / i_factor_van * i_biedkoers_naar * i_factor_naar),
                             i_notatie_naar);
        elsif i_reciproke_van = 1 and i_reciproke_naar <> 1
        then
           v_bedrag := round((i_geldsaldo * 1/i_laatkoers_van / i_factor_van * 1/i_biedkoers_naar * i_factor_naar),
                             i_notatie_naar);
        elsif i_reciproke_van <> 1 and i_reciproke_naar <> 1
        then
           v_bedrag := round((i_geldsaldo * i_laatkoers_van / i_factor_van * 1/i_biedkoers_naar * i_factor_naar),
                             i_notatie_naar);
        end if;
     elsif i_geldsaldo > 0 and (i_laatkoers_van = 0 or i_biedkoers_naar = 0)
     then
        v_bedrag := 0;
     -- bedrag < 0:
     elsif i_geldsaldo < 0 and i_biedkoers_van <> 0 and i_laatkoers_naar <> 0
     then
        if i_reciproke_van = 1 and i_reciproke_naar = 1
        then
           v_bedrag := round((i_geldsaldo * 1/i_biedkoers_van / i_factor_van * i_laatkoers_naar * i_factor_naar),
                             i_notatie_naar);
        elsif i_reciproke_van <> 1 and i_reciproke_naar = 1
        then
           v_bedrag := round((i_geldsaldo * i_biedkoers_van / i_factor_van * i_laatkoers_naar * i_factor_naar),
                             i_notatie_naar);
        elsif i_reciproke_van = 1 and i_reciproke_naar <> 1
        then
           v_bedrag := round((i_geldsaldo * 1/i_biedkoers_van / i_factor_van * 1/i_laatkoers_naar * i_factor_naar),
                             i_notatie_naar);
        elsif i_reciproke_van <> 1 and i_reciproke_naar <> 1
        then
           v_bedrag := round((i_geldsaldo * i_biedkoers_van / i_factor_van * 1/i_laatkoers_naar * i_factor_naar),
                             i_notatie_naar);
        end if;
     elsif i_geldsaldo < 0 and (i_biedkoers_van = 0 or i_laatkoers_naar = 0)
     then
        v_bedrag := 0;
     end if;
  else
     v_bedrag := 0;
  end if;

  return v_bedrag;

end gld_omrekenen_bedrag_vv;
-- EINDE CODE FUNCTION GLD_OMREKENEN_BEDRAG_VV


-- DE CODE VOOR DE FUNCTION RENTE_FACTOR_BEREK
-- In deze functie wordt aan de hand van het doorgegeven fondssymbool en de berekendatum
-- de rentefactor voor de berekening van de lopende rente van het fonds bepaalt.
function rente_factor_berek
(i_symbool          beleggingsinstrument.be_symbool%type
,i_bereken_dat      transakties.tr_boekdatum%type
,i_debuggen         relatie_fiattering.rf_debug_j_n%type
,i_debug_user       relatie_fiattering.rf_debug_user%type
)
return number

as begin

declare
   v_uitkeerdatum             date;
   v_next_uitkeerdatum        date;
   v_uitgifte_datum           date;
   v_uitgifte_datum_char      renteschemas.ra_datum_uitkeren%type;
   v_start_coupon_periode     date;
   v_einde_coupon_periode     date;
   v_start_rente_periode      date;
   v_einde_rente_periode      date;
   v_boekdatum                date;
   v_eerste_dag_bereken_jaar  date;
   v_aantal_dagen_berekenjaar int;
   v_dagtel_boekdat           number(5);
   v_percentage               beleggingsinstrument.be_renteperc%type;
   v_ra_percentage            renteschemas.ra_renteperc_divbedr%type;
   v_interesttype             beleggingsinstrument.be_interest_type%type;
   v_interest_berekening      beleggingsinstrument.be_interest_berekening%type;
   v_coupon_vervaldag         beleggingsinstrument.be_coupon_vervaldat%type;
   v_frequentie               number(2,0);
   v_rentefactor              number(14,9);
   v_floating_rate            number(1);
   v_samengestelde_exponent   number(14,9);
   v_dirty_priced_obli        beleggingsinstrument.be_dirtypricing%type;
   v_temp_dag                 int;
   v_temp_dag2                int;
   v_dagtel_uitkeerdat        int;

begin

   v_boekdatum   := to_date(i_bereken_dat,'yyyymmdd');
   v_rentefactor := 0;

   select be_interest_type,     be_renteperc,
          be_frequentie,        be_floating_rate,
          to_date(decode(be_uitgifte_uitk_dat,'00000000','00010101',be_uitgifte_uitk_dat),'yyyymmdd'),
          be_dirtypricing,      be_uitgifte_uitk_dat,  be_interest_berekening
   into   v_interesttype,       v_percentage,
          v_frequentie,         v_floating_rate,
          v_uitgifte_datum,
          v_dirty_priced_obli,  v_uitgifte_datum_char, v_interest_berekening
   from   beleggingsinstrument
   where  be_symbool   = i_symbool
   and    be_bi_nummer between 200 and 299;

   -- bepalen van de laaste uitkeringsdatum
   select to_date(max(ra_datum_uitkeren),'yyyymmdd')
   into   v_uitkeerdatum
   from   renteschemas
   where  ra_symbool                             =  i_symbool
   and    to_date(ra_datum_uitkeren ,'yyyymmdd') <= v_boekdatum
   and    ra_type_rb_na_va                       =  'RB';

   if i_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'In functie FIAT_ALGEMEEN.rente_factor_berek');
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Betreft symbool : '||i_symbool||' ; voor boekdatum : '||i_bereken_dat);
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_boekdatum (date) : '||to_char(v_boekdatum,'yyyymmdd')||
                                              ' ; v_uitkeerdatum : '||to_char(v_uitkeerdatum,'yyyymmdd'));
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_uitkeerdatum char : '||v_uitgifte_datum_char);
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
   end if;

   -- Als er geen uitgiftedatum is ingevuld bij de obligatie en de uitkeerdatum uit het renteschema
   -- is niet bekend dan is er voor de obligatie geen berekening mogelijk --> 0 teruggeven.
   if v_uitgifte_datum_char = '00000000' and v_uitkeerdatum is null
   then
      return 0;
   end if;

   -- mogelijk is dit de eerste uitkeringsperiode en zijn er tot nu toe nog geen betalingen geweest..
   if v_uitkeerdatum is null
   then
      select to_date(be_uitgifte_uitk_dat,'yyyymmdd'), nvl(be_coupon_vervaldat,'00000000')
      into   v_uitkeerdatum,                           v_coupon_vervaldag
      from   beleggingsinstrument
      where  be_symbool                                =  i_symbool
      and    be_uitgifte_uitk_dat                      <> '00000000'
      and    to_date(be_uitgifte_uitk_dat ,'yyyymmdd') <= v_boekdatum
      and    be_bi_nummer                              between 200 and 299;

      if v_uitkeerdatum is null
      then
         return 0;
      end if;

      if i_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_uitkeerdatum : '||to_char(v_uitkeerdatum,'yyyymmdd')||
                                                 ' ; v_coupon_vervaldag : '||v_coupon_vervaldag);
      end if;
   end if;

   -- bepalen van de daarop volgende uitkeringsdatum
   select to_date(min(ra_datum_uitkeren),'yyyymmdd')
   into   v_next_uitkeerdatum
   from   renteschemas
   where  ra_symbool                             = i_symbool
   and    to_date(ra_datum_uitkeren ,'yyyymmdd') > v_uitkeerdatum
   and    ra_type_rb_na_va                       = 'RB';

   -- bepalen van het bijbehorende coupon percentage:
   select ra_renteperc_divbedr
   into   v_ra_percentage
   from   renteschemas
   where  ra_symbool                             = i_symbool
   and    to_date(ra_datum_uitkeren ,'yyyymmdd') = v_next_uitkeerdatum
   and    ra_type_rb_na_va                       = 'RB';

   if v_uitkeerdatum = v_boekdatum
   then
      return 0;
   end if;

   if v_next_uitkeerdatum is null
   then
      return 0;
   end if;

   if i_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_next_uitkeerdatum : '||to_char(v_next_uitkeerdatum,'yyyymmdd')||
                                              ' ; v_ra_percentage     : '||to_char(v_ra_percentage));
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_interesttype      : '||v_interesttype||
                                              ' ; v_rentepercentage : '||to_char(v_percentage));
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_frequentie        : '||to_char(v_frequentie)||
                                              ' ; v_floating_rate : '||to_char(v_floating_rate));
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_uitgifte_datum    : '||to_char(v_uitgifte_datum,'yyyymmdd')||
                                              ' ; dirty pricing   : '||to_char(v_dirty_priced_obli));
      FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
   end if;

   -- Dirty priced obligaties hebben de rente al verwerkt in de koers, dus daar geen rentefactor
   -- voor berekenen!!
   -- Alleen "normale" obligaties doorlaten:
   if v_dirty_priced_obli = 0
   then
      if v_interesttype in ('RT01','RT02','RT03', 'RT04') and v_floating_rate = 1
      then
         v_percentage := v_ra_percentage * v_frequentie;
      end if;

      if v_interesttype = 'RT05' and v_uitkeerdatum > v_uitgifte_datum
      then
         v_percentage := v_ra_percentage;
      elsif v_interesttype = 'RT05' and v_uitkeerdatum = v_uitgifte_datum
      then
         if v_floating_rate = 1
         then
            v_percentage := v_ra_percentage;
         elsif v_floating_rate <> 1
         then
            v_percentage := v_percentage / v_frequentie;
         end if;
      end if;

      -- berekenen van de rentefactor voor interresttype RT01: 365/365 - 365,365 dagen
      if v_interesttype = 'RT01'
      then
         v_rentefactor            := ((v_boekdatum - v_uitkeerdatum) * v_percentage )/365;
         v_samengestelde_exponent := (v_boekdatum - v_uitkeerdatum)/365;

         if i_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'In RT01');
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_boekdatum  : '||to_char(v_boekdatum,'yyyymmdd')||
                                                    ' ; v_uitkeerdatum : '||to_char(v_uitkeerdatum,'yyyymmdd'));
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_percentage : '||to_char(v_percentage)||
                                                    ' ; v_rentefactor : '||to_char(v_rentefactor));
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_samangestelde exponent : '||to_char(v_samengestelde_exponent));
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Einde RT01');
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
         end if;
      -- berekenen van de rentefactor voor interresttype RT02: 365/360 - 365,360 dagen
      elsif v_interesttype = 'RT02'
      then
         v_rentefactor            := ((v_boekdatum - v_uitkeerdatum) * v_percentage)/360;
         v_samengestelde_exponent := (v_boekdatum - v_uitkeerdatum)/360;

         if i_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'In RT02');
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_boekdatum  : '||to_char(v_boekdatum,'yyyymmdd')||
                                                    ' ; v_uitkeerdatum : '||to_char(v_uitkeerdatum,'yyyymmdd'));
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_percentage : '||to_char(v_percentage)||
                                                    ' ; v_rentefactor : '||to_char(v_rentefactor));
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_samengestelde exponent : '||to_char(v_samengestelde_exponent));
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Einde RT02');
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
         end if;
      -- berekenen van de rentefactor voor interresttype RT03: 30/360 - 30,360 dagen
      elsif v_interesttype = 'RT03'
      then
         v_dagtel_boekdat := (to_char(v_boekdatum,'mm')-1)*30;
         v_temp_dag       := to_char(v_boekdatum ,'dd');
         if v_temp_dag > 30
         then
            v_temp_dag := 30;
         end if;
         v_dagtel_boekdat:= v_dagtel_boekdat + v_temp_dag;

         v_dagtel_uitkeerdat := (to_char(v_uitkeerdatum,'mm')-1)*30;
         v_temp_dag2         := to_char(v_uitkeerdatum ,'dd');
         if v_temp_dag2 > 30
         then
            v_temp_dag2 := 30;
         end if;
         v_dagtel_uitkeerdat:= v_dagtel_uitkeerdat + v_temp_dag2;

         if to_char(v_boekdatum,'yyyy') <> to_char(v_uitkeerdatum,'yyyy')
         then
            v_dagtel_boekdat := v_dagtel_boekdat + ( 360 * (to_number(to_char(v_boekdatum,'yyyy')) -
                                                            to_number(to_char(v_uitkeerdatum,'yyyy'))));
         end if ;

         v_rentefactor            := ((v_dagtel_boekdat-v_dagtel_uitkeerdat) * v_percentage)/360;
         v_samengestelde_exponent := (v_dagtel_boekdat-v_dagtel_uitkeerdat)/360;

         if i_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'In RT03');
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_dagtel_boekdatum  : '||to_char(v_dagtel_boekdat)||
                                                    ' ; v_dagtel_uitkeerdatum : '||to_char(v_dagtel_uitkeerdat));
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_percentage : '||to_char(v_percentage)||
                                                    ' ; v_rentefactor : '||to_char(v_rentefactor));
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_samengestelde exponent : '||to_char(v_samengestelde_exponent));
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Einde RT03');
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
         end if;
      -- berekenen van de rentefactor voor interresttype RT04: 30/365 - 30,365 dagen
      elsif v_interesttype = 'RT04'
      then
         v_dagtel_boekdat := (to_char(v_boekdatum,'mm')-1)*30;
         v_temp_dag       := to_char(v_boekdatum ,'dd');
         if v_temp_dag > 30
         then
            v_temp_dag := 30;
         end if;
         v_dagtel_boekdat:= v_dagtel_boekdat + v_temp_dag;

         v_dagtel_uitkeerdat := (to_char(v_uitkeerdatum,'mm')-1)*30;
         v_temp_dag2         := to_char(v_uitkeerdatum ,'dd');
         if v_temp_dag2 > 30
         then
            v_temp_dag2 := 30;
         end if;
         v_dagtel_uitkeerdat:= v_dagtel_uitkeerdat + v_temp_dag2;

         if to_char(v_boekdatum,'yyyy') <> to_char(v_uitkeerdatum,'yyyy')
         then
            v_dagtel_boekdat := v_dagtel_boekdat + ( 360 * (to_number(to_char(v_boekdatum,'yyyy')) -
                                                            to_number(to_char(v_uitkeerdatum,'yyyy'))));
         end if ;

         v_rentefactor            := ((v_dagtel_boekdat-v_dagtel_uitkeerdat) * v_percentage)/365;
         v_samengestelde_exponent := (v_dagtel_boekdat-v_dagtel_uitkeerdat)/365;

         if i_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'In RT04');
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_dagtel_boekdatum  : '||to_char(v_dagtel_boekdat)||
                                                    ' ; v_dagtel_uitkeerdatum : '||to_char(v_dagtel_uitkeerdat));
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_percentage : '||to_char(v_percentage)||
                                                    ' ; v_rentefactor : '||to_char(v_rentefactor));
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_samengestelde exponent : '||to_char(v_samengestelde_exponent));
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Einde RT04');
            FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
         end if;
      -- berekenen van de rentefactor voor interresttype RT05: act/act - actual ISMA berekening
      elsif v_interesttype = 'RT05'
      then
         if v_uitkeerdatum > v_uitgifte_datum
         then
            v_rentefactor             := ((v_boekdatum - v_uitkeerdatum) * v_percentage)/(v_next_uitkeerdatum - v_uitkeerdatum);
            v_samengestelde_exponent  := (v_boekdatum - v_uitkeerdatum)/(v_next_uitkeerdatum - v_uitkeerdatum);
            
            if i_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'In RT05 bij v_uitkeerdatum > v_uitgifte_datum');
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_boekdatum         : '||to_char(v_boekdatum,'yyyymmdd')||
                                                       ' ; v_uitkeerdatum : '||to_char(v_uitkeerdatum,'yyyymmdd'));
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_next uitkeerdatum : '||to_char(v_next_uitkeerdatum,'yyyymmdd'));
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_percentage        : '||to_char(v_percentage)||
                                                       ' ; v_rentefactor : '||to_char(v_rentefactor));
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_samengestelde exponent : '||to_char(v_samengestelde_exponent));
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Einde RT05 bij v_uitkeerdatum > v_uitgifte_datum');
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
            end if;
         end if;

         if v_uitkeerdatum = v_uitgifte_datum
         then
            v_start_coupon_periode := v_next_uitkeerdatum;
            -- bepalen van de start rentedatum
            while v_start_coupon_periode > v_uitgifte_datum
            loop
               -- er wordt telkens 1 jaar teruggegaan totdat de uitgiftedatum is bereikt
               v_start_coupon_periode := add_months (v_start_coupon_periode,-12);
            end loop;
            v_einde_coupon_periode := add_months (v_start_coupon_periode, 12);

            while v_start_coupon_periode < v_boekdatum
            loop
               if v_uitgifte_datum > v_start_coupon_periode
               then
                  v_start_rente_periode := v_uitgifte_datum;
               else
                  v_start_rente_periode := v_start_coupon_periode;
               end if;

               if v_boekdatum > v_einde_coupon_periode
               then
                  v_einde_rente_periode := v_einde_coupon_periode;
               else
                  v_einde_rente_periode := v_boekdatum;
               end if;

               v_rentefactor            := v_rentefactor +(((v_einde_rente_periode - v_start_rente_periode) * v_percentage) /
                                                           (v_einde_coupon_periode - v_start_coupon_periode));
               v_samengestelde_exponent := v_samengestelde_exponent + ((v_einde_rente_periode - v_start_rente_periode) /
                                                                       (v_einde_coupon_periode - v_start_coupon_periode));
               if i_debuggen = 1
               then
                  FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'In RT05 bij v_uitkeerdatum = v_uitgifte_datum');
                  FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_einde_rente_periode  : '||to_char(v_einde_rente_periode)||
                                                          ' ; v_start_rente_periode : '||to_char(v_start_rente_periode));
                  FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_einde_coupon_periode : '||to_char(v_einde_coupon_periode)||
                                                          ' ; v_start_coupon_periode : '||to_char(v_start_coupon_periode));
                  FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_percentage           : '||to_char(v_percentage)||
                                                          ' ; v_rentefactor : '||to_char(v_rentefactor));
                  FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_samengestelde exponentn : '||to_char(v_samengestelde_exponent));
                  FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
               end if;

               v_start_coupon_periode := v_einde_coupon_periode;
               v_einde_coupon_periode := add_months (v_einde_coupon_periode,12);

            end loop;

            if i_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Uiteindelijk berekende gegevens');
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_rentefactor ; '||to_char(v_rentefactor));
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Einde RT05 bij v_uitkeerdatum = v_uitgifte_datum');
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
            end if;
         end if;
      -- berekenen van de rentefactor voor interresttype RT06: act/act - actual French berekening
      elsif v_interesttype = 'RT06'
      then
         v_start_coupon_periode    := v_boekdatum - (v_boekdatum - v_uitkeerdatum);
         v_eerste_dag_bereken_jaar := to_date(to_char(v_start_coupon_periode,'YYYY')||'0101','yyyymmdd');
         while v_boekdatum < v_eerste_dag_bereken_jaar
         loop
            if v_start_coupon_periode > to_date(to_char(v_eerste_dag_bereken_jaar,'YYYY')-1||'1231','yyyymmdd')
            then
               v_start_rente_periode := v_start_coupon_periode;
            else
               v_start_rente_periode := to_date(to_char(v_eerste_dag_bereken_jaar,'YYYY')-1||'1231','yyyymmdd');
            end if;

            if v_boekdatum < to_date(to_char(v_eerste_dag_bereken_jaar,'YYYY')||'1231','yyyymmdd')
            then
               v_einde_rente_periode := v_boekdatum;
            else
               v_einde_rente_periode := to_date(to_char(v_eerste_dag_bereken_jaar,'YYYY')||'1231','yyyymmdd');
            end if;

            v_aantal_dagen_berekenjaar := to_date(to_char(v_eerste_dag_bereken_jaar,'YYYY')+1||
                                          to_char(v_eerste_dag_bereken_jaar,'mmdd'),'yyyymmdd') - v_eerste_dag_bereken_jaar;

            v_rentefactor              := v_rentefactor + (v_einde_rente_periode - v_start_rente_periode) *
                                          v_percentage / v_aantal_dagen_berekenjaar;
            v_samengestelde_exponent   := v_samengestelde_exponent + (v_einde_rente_periode - v_start_rente_periode)/v_aantal_dagen_berekenjaar;

            if i_debuggen = 1
            then
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'In RT06');
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_einde_rente_periode : '||to_char(v_einde_rente_periode)||
                                                       ' ; v_start_rente_periode : '||to_char(v_start_rente_periode));
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_percentage          : '||to_char(v_percentage)||
                                                       ' ; v_aantal_dagen_berekenjaar : '||to_char(v_aantal_dagen_berekenjaar));
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_rentefactor         : '||to_char(v_rentefactor));
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'v_samengestelde_exponent : '||to_char(v_samengestelde_exponent));
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, 'Einde RT06');
               FIAT_ALGEMEEN.fiat_debug (i_debug_user, ' ');
            end if;

            v_eerste_dag_bereken_jaar  := to_date(to_char(v_eerste_dag_bereken_jaar,'YYYY')+1||
                                          to_char(v_eerste_dag_bereken_jaar,'mmdd'),'yyyymmdd');
         end loop;
      else
          v_rentefactor := 0;
      end if;
      
      -- Samengestelde rente
      if v_interest_berekening = 1
      then
         v_rentefactor := (power(1 + v_percentage/100 ,v_samengestelde_exponent) - 1) * 100;
      
         if i_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug (i_debug_user,'In deel van samengestelde rente berekening');
            FIAT_ALGEMEEN.fiat_debug (i_debug_user,'herberekende rentefactor : '||to_char(v_rentefactor));
            FIAT_ALGEMEEN.fiat_debug (i_debug_user,' ');
         end if;
      end if;
   end if;

return v_rentefactor;
end;

end rente_factor_berek;
-- EINDE CODE FUNCTION RENTE_FACTOR_BEREK


-- DE CODE VOOR DE FUNCTION TRANSSTATUS
-- In deze functie wordt aan de hand van de transactie status bepaalt welke onderdelen al dan niet nog verwerkt
-- moeten worden bij het doorboeken. Dit is van belang bij het bepalen of een mutatie al is uitgevoerd en dus
-- verwerkt is in de positie.
function transstatus
(i_status      number
,i_tpc_actions number
,i_partij      number
,i_positie     number
)
return number

-- inkomende parameters zijn: status:      transactie status.
--                            tpc_actions: de waarde van het veld tr_tpc_actions
--                            partij:      1 = rel1, 2 = rel2, 3 = vruchtrelatie
--                            positie:     1 = stukken, 2 = geld, 3 = open posten stukken, 4 = open posten geld

-- uitgaande waarde         : return_waarde --> een 1 houdt in uitgevoerd, een 0 houdt in niet uitgevoerd.

as

  v_partij_macht           float;
  v_positie_macht          float;
  v_tussen_waarde          float;
  v_return_waarde          number(1);

begin

  v_partij_macht  := 16**(i_partij-1);
  v_positie_macht := 2**i_positie;

  --1e stap, na de komma afkappen en dat deel op 0 zetten, er mag geen afronding plaats vinden..
  v_tussen_waarde := trunc(i_status/(2 * v_positie_macht * v_partij_macht));
  --2e stap, voor de komma afkappen en dat deel op 0 zetten.
  v_tussen_waarde := v_tussen_waarde/2;
  v_tussen_waarde := mod(v_tussen_waarde, trunc(v_tussen_waarde));

  if v_tussen_waarde <> 0 and (i_tpc_actions = 0 or i_tpc_actions is null)
     or
     v_tussen_waarde = 0 and i_tpc_actions <> 0
  then
     v_return_waarde := 1;
  else
     v_return_waarde := 0;
  end if;

  return v_return_waarde;

end transstatus;
-- EINDE CODE FUNCTION TRANSSTATUS


-- DE CODE VOOR DE PROCEDURE FIAT_DEBUG
-- Een procedure voor het aanmaken van debug informatie.
-- Afhankelijk van de user wordt de debug informatie naar een file geschreven of naar PL/SQL (dbms_output)
procedure fiat_debug
(i_debug_user               beleggingsadviseurs.ba_magic_user_id%type
,i_debug_informatie         varchar2
)

-- inkomende parameters zijn: i_debug_user       = de user die de debug informatie aanvraagd
--                            i_debug_informatie = de informatie die  getoond of weggeschreven moet worden


is


begin

  if i_debug_user = 'PL/SQL'
  then
     -- bij de user PL/SQL is dbms_output.put_line voldoende en handig:
     dbms_output.put_line('[DEBUG] '||to_char(SYSDATE,'YYYY-MM-DD')||' '||to_char(SYSTIMESTAMP,'HH24:MI:SS.sssss')||' - '||i_debug_informatie);
  end if;

end fiat_debug;
-- EINDE CODE PROCEDURE FIAT_DEBUG


-- DE CODE VOOR DE PROCEDURE BEREKEN_SETTL_DAT
-- In deze procedure wordt de settlementdatum bepaalt. Dit is van belang voor het berekenen van
-- de lopende rente voor obligaties, indien de instelling van het fonds tot valutadatum is.
-- Deze procedure maakt onderdeel uit van de procedures voor bepalen van het geschatte notabedrag
-- van lopende orders.
procedure bereken_settl_dat
(i_beursnummer     in         beurzen.brs_nummer%type
,i_koop_verkoop    in         number
,i_trans_datum     in         transakties.tr_transdatum%type
,o_settl_dat       out        transakties.tr_settlementdatum%type
)

-- inkomende parameters zijn: i_beursnummer  = beursnummer waarvoor de datum berekend moet worden
--                            i_koop_verkoop = koop/verkoop indicatie (koop = 1, verkoop =2)
--                            i_trans_datum  = de transactiedatum waarvoor de settlementdatum berekend moet worden
-- uitgaande parameters zijn: o_settl_dat    = de settlementdatum die berekend is.

is

    v_ak_aantal_dagen     number(2);
    v_ak_ind_werk_kal     number(1);
    v_vk_aantal_dagen     number(2);
    v_vk_ind_werk_kal     number(1);
    v_werk_aantal_dagen   number(2);
    v_werk_ind_werk_kal   number(1);
    v_settl_dat_datum     date;
    v_dummy_dat           char(8);
    v_counter             number(2);

begin
    -- eerste initiatie, als er niets gevonden wordt, dan in ieder geval de trans_dat teruggeven
    v_werk_aantal_dagen := 0;
    v_settl_dat_datum   := to_date(i_trans_datum, 'yyyymmdd');

    begin
        select b.brs_ak_aantal_dagen, b.brs_ak_ind_werk_kal, b.brs_vk_aantal_dagen,
               b.brs_vk_ind_werk_kal
        into   v_ak_aantal_dagen,       v_ak_ind_werk_kal,       v_vk_aantal_dagen,
               v_vk_ind_werk_kal
        from   beurzen b
        where  b.brs_nummer = i_beursnummer;

        exception
        when no_data_found
        then
           v_ak_aantal_dagen := 0;
           v_ak_ind_werk_kal := 0;
           v_vk_aantal_dagen := 0;
           v_vk_ind_werk_kal := 0;
    end;

    if i_koop_verkoop = 1
    then
       v_werk_aantal_dagen := v_ak_aantal_dagen;
       v_werk_ind_werk_kal := v_ak_ind_werk_kal;
    end if;

    if i_koop_verkoop = 2
    then
       v_werk_aantal_dagen := v_vk_aantal_dagen;
       v_werk_ind_werk_kal := v_vk_ind_werk_kal;
    end if;

    -- als indicatie 2 is, dan is het kalenderdagen, dus gewoon optellen:
    if v_werk_ind_werk_kal = 2
    then
       v_settl_dat_datum := v_settl_dat_datum + v_werk_aantal_dagen;
    end if;

    -- als indicatie 1 is, dan is het werkdagen en moet dus door de kalender gelopen worden:
    if v_werk_ind_werk_kal = 1
    then
       if v_werk_aantal_dagen > 0
       then
          v_settl_dat_datum := v_settl_dat_datum + 1;
          v_counter         := v_werk_aantal_dagen + 31;

          loop
             begin
                 select nwb_niet_werkdag
                 into   v_dummy_dat
                 from   kalender_per_beurs
                 where  nwb_beursnummer = i_beursnummer
                 and    nwb_niet_werkdag = to_char(v_settl_dat_datum,'yyyymmdd');

                 -- als het een werkdag is (dus boven staande select lukt niet),
                 -- dan 1 dag van werk_aantal_dagen afhalen.
                 exception
                 when no_data_found
                 then
                    v_werk_aantal_dagen := v_werk_aantal_dagen -1;
             end;

             -- zolang het werk_aantal_dagen ongelijk aan 0 is 1 dag bij de settlementdatum optellen.
             if v_werk_aantal_dagen <> 0
             then
                v_settl_dat_datum := v_settl_dat_datum + 1;
             end if;

             -- de counter per loop met 1 terug tellen om maximaal een maand te doorlopen
             -- ter voorkoming van een eindeloze loop.
             v_counter := v_counter - 1;

             exit when v_werk_aantal_dagen = 0 or v_counter = 0;

          end loop;
       end if;
    end if;

    -- als laatste de bepaalde datum teruggeven
    o_settl_dat := to_char(v_settl_dat_datum,'yyyymmdd');

end bereken_settl_dat;
-- EINDE CODE VOOR DE PROCEDURE BEREKEN_SETTL_DAT


-- DE CODE VOOR DE PROCEDURE VERSION_UITVRAAG
-- script voor het uitvragen van de versie van de fiatteringspackages die
-- zijn geladen in de database.
procedure version_uitvraag
(i_debug_user               beleggingsadviseurs.ba_magic_user_id%type
)

is
    sql_stmt            varchar2(100);
    v_versienummer      varchar2(80);

cursor op is 

       select package_name
       from   lc_oracle_packages;

begin
  
  for r_op in op
  loop
  
    v_versienummer := ' ';
    
    sql_stmt := 'select ' || r_op.package_name || '.version from dual';
    execute immediate sql_stmt into v_versienummer;
     
  FIAT_ALGEMEEN.fiat_debug(i_debug_user, r_op.package_name||' : ' ||v_versienummer);
  
  end loop;

end version_uitvraag;
-- EINDE CODE PROCEDURE VERSION_UITVRAAG


-- DE CODE VOOR DE FUNCTION INSTELL_OPHALEN:
-- Functie voor het ophalen van gegevens uit het bestand instellingen.
-- Dit wordt in Magic gedaan door het programma 260 SUB-Ophalen Instellingen
function instell_bepalen
(i_instelling_string          varchar2
,i_op_te_halen_instel         varchar2
,i_type_waarde                varchar2
,i_debuggen                   relatie_fiattering.rf_debug_j_n%type
,i_debug_user                 relatie_fiattering.rf_debug_user%type
)

return varchar2

as

   v_opgehaalde_instelling                  varchar2(100);
   v_samengestelde_string                   varchar2(10000);
   v_goede_instelling_oms                   varchar2(42);
   v_begin_positie_instelling               number(5);
   v_length_instelling                      number(3);
   v_volg_inst_begin_positie                number(5);
   v_lengte_waarde                          number(5);
   v_database_instelling_getallen           varchar2(2);

begin
   v_opgehaalde_instelling  := ' ';
   v_samengestelde_string   := i_instelling_string;
   v_lengte_waarde          := 0;
   v_goede_instelling_oms   := '['||i_op_te_halen_instel||':';


   -- bepalen van het begin van de instelling (aan de hand van de <GOEDE_INSTELLING_OMS>)
   v_begin_positie_instelling := instr(v_samengestelde_string,v_goede_instelling_oms);

   if v_begin_positie_instelling <> 0
   then
      v_length_instelling        := length(v_goede_instelling_oms);
      v_begin_positie_instelling := v_begin_positie_instelling + v_length_instelling;

      v_volg_inst_begin_positie  := instr(v_samengestelde_string,']',v_begin_positie_instelling);

      if v_volg_inst_begin_positie = 0
      then
         v_volg_inst_begin_positie := length(v_samengestelde_string) + 1;
      end if;

      -- bepalen van de lengte van de waarde van de instelling:
      v_lengte_waarde := v_volg_inst_begin_positie - v_begin_positie_instelling;

      -- bepalen van de instelling:
      v_opgehaalde_instelling := substr(v_samengestelde_string,v_begin_positie_instelling, v_lengte_waarde);
   else
      v_opgehaalde_instelling := ' ';
   end if;

   -- als er een numerieke waarde wordt gevraagd (i_type_waarde = 'N') dan checken hoe de database instellingen
   -- voor decimaal scheidingsteken is, zodat daar rekening meegehouden kan worden.
   if i_type_waarde = 'N'
      and
      (instr(v_opgehaalde_instelling,',',1)<>0
       or
       instr(v_opgehaalde_instelling,'.',1)<>0)
   then
      select n.value
      into   v_database_instelling_getallen
      from   nls_session_parameters n
      where  n.parameter = 'NLS_NUMERIC_CHARACTERS';

      if i_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( i_debug_user,'in procedure FIAT_ALGMEEN.instell_bepalen');
         FIAT_ALGEMEEN.fiat_debug( i_debug_user,'op te halen instelling : '||i_op_te_halen_instel);
         FIAT_ALGEMEEN.fiat_debug( i_debug_user,'opgehaalde instelling : '||v_opgehaalde_instelling);
         FIAT_ALGEMEEN.fiat_debug( i_debug_user,'database instelling getallen : '||v_database_instelling_getallen);
         FIAT_ALGEMEEN.fiat_debug( i_debug_user,' ');
      end if;

      -- alleen maar de komma wijzigen als het decimaal teken een punt is
      if substr(v_database_instelling_getallen,1,1)='.' and instr(v_opgehaalde_instelling,',',1)<>0
      then
         v_opgehaalde_instelling := replace(v_opgehaalde_instelling,',','.');
      end if;
      -- alleen maar de punt wijzigen als het decimaal teken een komma is:
      if substr(v_database_instelling_getallen,1,1)=',' and instr(v_opgehaalde_instelling,'.',1)<>0
      then
         v_opgehaalde_instelling := replace(v_opgehaalde_instelling,'.',',');
      end if;

   end if;

   if i_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'in procedure FIAT_ALGMEEN.instell_bepalen');
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'op te halen instelling : '||i_op_te_halen_instel);
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,'opgehaalde instelling : '||v_opgehaalde_instelling);
      FIAT_ALGEMEEN.fiat_debug( i_debug_user,' ');
   end if;

   return v_opgehaalde_instelling;

end instell_bepalen;
-- EINDE CODE FUNCTION INSTELL_OPHALEN


-- DE CODE VOOR DE PROCEDURE VALUTAGEGEVENS_BEPALEN
-- Procedure om valutagegevens voor een muntsoort te bepalen. Als de gegevens al aanwezig
-- zijn in de tabel FIAT_MUNTSOORTEN, dan worden die teruggeven. Als ze daar nog niet
-- in zitten, dan worden eerst de actuele muntsoortgegevens opgehaald en dan worden daarmee
-- de acutele bank-valutakoersen voor de relatie voor die muntsoort bepaald.
procedure valutagegevens_bepalen
(i_muntcode              in  muntsoorten.mu_code%type
,i_pr_id                 in  producten.pr_id%type
,i_ppr_id                in  producten_per_relatie.ppr_id%type
,i_sys_spread_categorie  in  valutaspread_cat_muntsoort.vscm_id%type
,i_bank2marketchangedate in  muntsoorten.mu_update%type
,i_debuggen              in  relatie_fiattering.rf_debug_j_n%type
,i_debug_user            in  relatie_fiattering.rf_debug_user%type
,o_biedkoers             out muntsoorten.mu_biedkoers%type
,o_middenkoers           out muntsoorten.mu_middenkoers%type
,o_laatkoers             out muntsoorten.mu_laatkoers%type
,o_factor                out muntsoorten.mu_factor%type
,o_reciproke             out muntsoorten.mu_reciproke%type
,o_notatie               out muntsoorten.mu_notatie%type
)

-- inkomende parameters zijn: i_muntcode             = de code van de muntsoort waarvoor de gegevens opgehaald moeten worden
--                            i_pr_id                = product id om valutaspread mee te bepalen
--                            i_ppr_id               = product-per-relatie id om valutaspread mee te bepalen
--                            i_sys_spread_categorie = categorie van het systeem om valutaspread mee te bepalen
--                            i_debuggen             = geeft aan of debug informatie aangemaakt moet worden
--                            i_debug_user           = geeft aan wie de gebruiker is die de request uitvoert
-- uitgaande parameters zijn: o_biedkoers            = de bank-biedkoers van de gevraagde muntsoort
--                            o_middenkoers          = de bank-middenkoers van de gevraagde muntsoort
--                            o_laatkoers            = de bank-laatkoers van de gevraagde muntsoort
--                            o_factor               = de factor van de gevraagde muntsoort
--                            o_reciproke            = de reciproke van de gevraagde muntsoort
--                            o_notatie              = de notatie van de gevraagde muntsoort

is
  v_muntsoort_gevonden        number(1);
  v_spread_pr_gevonden        number(1);
  v_spread_ppr_gevonden       number(1);
  v_spread_cat_id             valutaspread_cat_muntsoort.vscm_vsca_id%type;
  v_opslag_percentage         valutaspread_cat_muntsoort.vscm_opslag_perc%type;
  v_afslag_percentage         valutaspread_cat_muntsoort.vscm_afslag_perc%type;
  v_valutaspread_gevonden     number(1);
  v_debuggen                  number(1);

begin
  v_debuggen   := i_debuggen;  
  v_debuggen   := 2;  -- even de logging uitzetten zodat deze niet veel onnodige data toont.
  
  if v_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,'start procedure FIAT_ALGMEEN.valutagegevens_bepalen');
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,'Muntcode        : '||i_muntcode||' ; pr_id  : '||to_char(i_pr_id));
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,'ppr_id          : '||to_char(i_ppr_id)||' ; sys spread categorie : '||to_char(i_sys_spread_categorie));
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,'bank2marketchange date : '||i_bank2marketchangedate);
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,' ');
  end if;

  -- initialiseren van de outputparameters met de hardcoded basisvaluta gegevens
  o_biedkoers             := 1;
  o_middenkoers           := 1;
  o_laatkoers             := 1;
  o_factor                := 1;
  o_reciproke             := 1;
  o_notatie               := 2;
  v_muntsoort_gevonden    := 1;
  v_opslag_percentage     := 0;
  v_afslag_percentage     := 0;

  -- Als eerste kijken of de muntsoortgegevens al aanwezig zijn in de fiat_muntsoorten tabel
  begin
     select m.fimu_biedkoers, m.fimu_middenkoers, m.fimu_laatkoers,
            m.fimu_factor,    m.fimu_reciproke,   m.fimu_notatie
     into   o_biedkoers,      o_middenkoers,      o_laatkoers,
            o_factor,         o_reciproke,        o_notatie
     from   fiat_muntsoorten m
     where  m.fimu_code  = i_muntcode;

  exception
    when no_data_found
    then
       v_muntsoort_gevonden := 0;
  end;
  if v_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,'Muntsoort gevonden 1=Ja,0=Nee : '||to_char(v_muntsoort_gevonden));
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,'biedkoers   : '||to_char(o_biedkoers)||' ; middenkoers : '||to_char(o_middenkoers));
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,'laatkoers   : '||to_char(o_laatkoers)||' ; factor      : '||to_char(o_factor));
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,'reciproke   : '||to_char(o_reciproke)||' ; notatie     : '||to_char(o_notatie));
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,' ');
  end if;

  -- Als er geen muntsoort gegevens zijn gevonden, dan deze hier gaan bepalen en de bankkoersen berekenen
  if v_muntsoort_gevonden = 0
  then
     v_spread_cat_id         := 0;
     v_spread_pr_gevonden    := 1;
     v_spread_ppr_gevonden   := 1;
     v_valutaspread_gevonden := 0;

    -- eerst de muntsoort gegevens ophalen (nu wel uit de muntsoorten tabel !):
     select m.mu_biedkoers, m.mu_middenkoers, m.mu_laatkoers,
            m.mu_factor,    m.mu_reciproke,   m.mu_notatie
     into   o_biedkoers,    o_middenkoers,    o_laatkoers,
            o_factor,       o_reciproke,      o_notatie
     from   muntsoorten m
     where  m.mu_code  = i_muntcode;

     -- Als de huidige datum kleiner is dan de bank 2 market change date, dan is de gewone muntsoorten koers voldoende
     if to_char(sysdate,'yyyymmdd') >= i_bank2marketchangedate
     then
        -- Nu gaan bepalen of er valutaspread gegevens zijn voor de verschillende id's. Eerst PPR, dan PR als laatste SYS.
        begin
          select v.vsck_vsca_id
          into   v_spread_cat_id
          from   valutaspread_cat_klantproduct v
          where  v.vsck_ppr_id = i_ppr_id;
        exception
          when no_data_found
          then
             v_spread_ppr_gevonden := 0;
        end;

        if v_spread_ppr_gevonden = 0
        then
          begin
            select v.vscp_vsca_id
            into   v_spread_cat_id
            from   valutaspread_cat_product v
            where  v.vscp_pr_id = i_pr_id;
          exception
            when no_data_found
            then
               v_spread_pr_gevonden :=0;
          end;
        end if;

        -- Is er nog niets gevonden, dan de syst spread categorie gebruiken, als die al <> 0 is:
        if v_spread_ppr_gevonden = 0 and v_spread_pr_gevonden = 0 and i_sys_spread_categorie<>0
        then
           v_spread_cat_id := i_sys_spread_categorie;
        end if;

        -- als er een spread categorie is, dan kijken of er een op/afslag is voor de gevraagde muntsoort
        if nvl(v_spread_cat_id,0) <> 0
        then
           v_valutaspread_gevonden := 1;
           begin
              select v.vscm_afslag_perc,  v.vscm_opslag_perc
              into   v_afslag_percentage, v_opslag_percentage
              from   valutaspread_cat_muntsoort v
              where  v.vscm_vsca_id  = v_spread_cat_id
              and    v.vscm_mu_code  = i_muntcode;
           exception
             when no_data_found
             then
                v_valutaspread_gevonden := 0;
           end;
           -- Als er een valutaspread gevonden is, dan de bied en laatkoersen aanpassen met de gevonden op/afslag
           if v_valutaspread_gevonden = 1
           then
              o_biedkoers := round(o_biedkoers * (1 - (v_afslag_percentage/100)),6);
              o_laatkoers := round(o_laatkoers * (1 + (v_opslag_percentage/100)),6);
           end if;
        end if;
     end if;

     if v_debuggen = 1
     then
        FIAT_ALGEMEEN.fiat_debug( i_debug_user,' spread pr gevonden : '||to_char(v_spread_pr_gevonden)||' ; spread ppr gevonden : '||to_char(v_spread_ppr_gevonden));
        FIAT_ALGEMEEN.fiat_debug( i_debug_user,' valuta spread gevonden : '||to_char(v_valutaspread_gevonden)||' ; spread cat id : '||to_char(v_spread_cat_id));
        FIAT_ALGEMEEN.fiat_debug( i_debug_user,' afslag percentage      : '||to_char(v_afslag_percentage)||' ; opslag percentage : '||to_char(v_opslag_percentage));
        FIAT_ALGEMEEN.fiat_debug( i_debug_user,' ');
     end if;

     -- als laatste stap de bepaalde muntsoort gegevens opslaan, zodat deze later sneller opgehaald kunnen worden:
     insert into fiat_muntsoorten f
     (f.fimu_code,        f.fimu_notatie,        f.fimu_factor,
      f.fimu_reciproke,   f.fimu_biedkoers,      f.fimu_middenkoers,
      f.fimu_laatkoers,   f.fimu_gebruikt,       f.fimu_opslag_perc,
      f.fimu_afslag_perc)
     values
     (i_muntcode,         o_notatie,             o_factor,
      o_reciproke,        o_biedkoers,           o_middenkoers,
      o_laatkoers,        1,                     v_opslag_percentage,
      v_afslag_percentage);
  end if;

  if v_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,'Einde procedure FIAT_ALGEMEEN.valutagegevens_bepalen voor muntcode '||i_muntcode);
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,'biedkoers   : '||to_char(o_biedkoers)||' ; middenkoers : '||to_char(o_middenkoers));
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,'laatkoers   : '||to_char(o_laatkoers)||' ; factor      : '||to_char(o_factor));
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,'reciproke   : '||to_char(o_reciproke)||' ; notatie     : '||to_char(o_notatie));
     FIAT_ALGEMEEN.fiat_debug( i_debug_user,' ');
  end if;

end valutagegevens_bepalen;
-- EINDE CODE PROCEDURE VALUTAGEGEVENS_BEPALEN


-- DE CODE VOOR DE FUNCTION VERSION
function Version
return varchar2
is

begin
      return gv_versie;
end version;
-- EINDE CODE FUNCTION VERSION

end FIAT_ALGEMEEN;
/
