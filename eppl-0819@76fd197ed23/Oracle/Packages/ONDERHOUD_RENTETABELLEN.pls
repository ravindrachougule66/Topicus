CREATE OR REPLACE PACKAGE ONDERHOUD_RENTETABELLEN
is

/*------------------------------------------------------------------------------
Package     : ONDERHOUD_RENTETABELLEN
description : code voor de package ONDERHOUD_RENTETABELLEN waarbinnen de volgende
              procedures aanwezig zijn:
               set_globale_var_rentebasis
               set_globale_var_afspraken
               set_globale_var_marges
               set_globale_var_schalen_header
               set_globale_var_schalen_detail
           set_gmunt_gnummer
               bijbehorende_rentebasis
               bijbehorende_rentebasis_NA
               bijbehorende_rentemarge
               bijbehorende_rentemarge_NA
               vul_rente_perc_afspraak
               opbouw_RPA_obv_rentebasisperc
               opbouw_RPA_obv_marges_standen
               opbouw_rente_perc_afspraak
               verwijder_rente_perc_afspraak
               init_rente_perc_afspraak
               bijbehorende_renteschaal
               bijbehorende_renteschaal_NA
               bijbeh_renteschaal_HDR
               bijbeh_renteschaal_HDR_NA
               vul_rente_perc_schaaltarief
               opb_rente_perc_schaaltrf_st3
               opb_rente_perc_schaaltrf_st2
               opbouw_rente_perc_schaaltarief
               verw_rente_perc_schaaltarief
               init_rente_perc_schaaltarief
               bepaal_overlap_datumranges
               bijw_rente_perc_afspraak
               bijw_rente_perc_schaaltarief
               wijziging_rentebasispercentage
               wijziging_rente_afspraken
               wijziging_marges_standen
               wijziging_renteschalen_header
               wijziging_renteschalen_detail
               lock_rentebasispercentage
               lock_rente_afspraken
               lock_marges_standen
               lock_renteschalen_header
               lock_renteschalen_detail
author       : Syntel Financial Software, Bart Hijman / Gert Nijenhuis
code         : 5744-52406-0001
history      : 25-AUG-2011, GN initiele versie
               05-JAN-2011, GN aanpassing procedure verw_rente_perc_schaaltarief
                               zodat schaalbedragen met waarden die decimalen
                               achter de comma hebben ook verwerkt kunnen worden
               08-JUN-2012, WK uitlevering 05.18.00.00
               28-SEP-2012, GN uitlevering 05.19.00.00
               01-FEB-2013, JE uitlevering 05.20.00.00
               11-OKT-2013, WK uitlevering 06.01.00.00
         06-NOV-2014, GN globale variabele g_soort_wijziging 7 pos. lang gemaakt
------------------------------------------------------------------------------*/

 g_inbp_basis_old          re_interest_base_perc.inbp_basis%type;
 g_inbp_basis_new          re_interest_base_perc.inbp_basis%type;
 g_inbp_opslag_old         re_interest_base_perc.inbp_opslag%type;
 g_inbp_opslag_new         re_interest_base_perc.inbp_opslag%type;

 g_inag_debet_rente_old    re_interest_base_perc_hdr.inbph_number%type;
 g_inag_debet_rente_new    re_interest_base_perc_hdr.inbph_number%type;
 g_inag_credit_rente_old   re_interest_base_perc_hdr.inbph_number%type;
 g_inag_credit_rente_new   re_interest_base_perc_hdr.inbph_number%type;

 g_marg_marge_old          re_margin_rates.marg_marge%type;
 g_marg_marge_new          re_margin_rates.marg_marge%type;

 g_insd_basistarief_old    re_interest_base_perc_hdr.inbph_number%type;
 g_insd_basistarief_new    re_interest_base_perc_hdr.inbph_number%type;
 g_insd_rentemarge_old     re_interest_scale_dtl.insd_rentemarge%type;
 g_insd_rentemarge_new     re_interest_scale_dtl.insd_rentemarge%type;
 g_muntsoort               re_interest_base_perc_hdr.inbph_currency%type;
 g_rentebasisnummer        re_interest_base_perc_hdr.inbph_number%type;
 g_afspraaknummer          re_interest_agreement.inag_nummer%type;
 g_schalennummer           re_interest_base_perc_hdr.inbph_number%type;
 g_ingangsdatum            re_interest_base_perc.inbp_ingangsdatum%type;
 g_nieuwe_ingangsdatum     re_interest_base_perc.inbp_ingangsdatum%type;
 g_marg_soort              re_margin_rates.marg_soort%type;
 g_type_credit_debet       re_interest_scale_dtl.insd_type_credit_debet%type;
 g_bedrag_vanaf            re_interest_scale_dtl.insd_bedrag_vanaf%type;
 g_nieuwe_bedrag_vanaf     re_interest_scale_dtl.insd_bedrag_vanaf%type;
 g_soort_wijziging         varchar2(7);
 g_aantal_keer_getriggerd  number(1) :=0 ;
 
-- variabele die het laatste versienummer bevat (naam van de variabele niet aanpassen !):
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';
   
   
PROCEDURE set_globale_var_rentebasis
   ( i_inbp_basis_old               in      re_interest_base_perc.inbp_basis%type
    ,i_inbp_basis_new               in      re_interest_base_perc.inbp_basis%type
    ,i_inbp_opslag_old              in      re_interest_base_perc.inbp_opslag%type
    ,i_inbp_opslag_new              in      re_interest_base_perc.inbp_opslag%type
    ,i_inbp_xxxx_id                 in      re_interest_base_perc.inbp_xxxx_id%type
    ,i_ingangsdatum                 in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_nieuwe_ingangsdatum          in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_soort_wijziging              in      varchar2);
PROCEDURE set_globale_var_afspraken
   ( i_inag_debet_rente_old         in      re_interest_base_perc_hdr.inbph_number%type
    ,i_inag_debet_rente_new         in      re_interest_base_perc_hdr.inbph_number%type
    ,i_inag_credit_rente_old        in      re_interest_base_perc_hdr.inbph_number%type
    ,i_inag_credit_rente_new        in      re_interest_base_perc_hdr.inbph_number%type
    ,i_muntsoort                    in      re_interest_base_perc_hdr.inbph_currency%type
    ,i_afspraaknummer               in      re_interest_agreement.inag_nummer%type
    ,i_soort_wijziging              in      varchar2);
PROCEDURE set_globale_var_marges
   ( i_marg_marge_old               in      re_margin_rates.marg_marge%type
    ,i_marg_marge_new               in      re_margin_rates.marg_marge%type
    ,i_muntsoort                    in      re_interest_base_perc_hdr.inbph_currency%type
    ,i_afspraaknummer               in      re_interest_agreement.inag_nummer%type
    ,i_ingangsdatum                 in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_nieuwe_ingangsdatum          in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_marg_soort                   in      re_margin_rates.marg_soort%type
    ,i_soort_wijziging              in      varchar2);
PROCEDURE set_globale_var_schalen_header
   ( i_muntsoort                    in      re_interest_base_perc_hdr.inbph_currency%type
    ,i_schalennummer                in      re_interest_base_perc_hdr.inbph_number%type
    ,i_ingangsdatum                 in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_nieuwe_ingangsdatum          in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_soort_wijziging              in      varchar2);
PROCEDURE set_globale_var_schalen_detail
   ( i_insd_basistarief_old         in      re_interest_base_perc_hdr.inbph_number%type
    ,i_insd_basistarief_new         in      re_interest_base_perc_hdr.inbph_number%type
    ,i_insd_rentemarge_old          in      re_interest_scale_dtl.insd_rentemarge%type
    ,i_insd_rentemarge_new          in      re_interest_scale_dtl.insd_rentemarge%type
    ,i_muntsoort                    in      re_interest_base_perc_hdr.inbph_currency%type
    ,i_schalennummer                in      re_interest_base_perc_hdr.inbph_number%type
    ,i_ingangsdatum                 in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_type_credit_debet            in      re_interest_scale_dtl.insd_type_credit_debet%type
    ,i_bedrag_vanaf                 in      re_interest_scale_dtl.insd_bedrag_vanaf%type
    ,i_nieuwe_bedrag_vanaf          in      re_interest_scale_dtl.insd_bedrag_vanaf%type
    ,i_soort_wijziging              in      varchar2);
PROCEDURE set_gmunt_gnummer
   ( i_inbph_id                     in      re_interest_base_perc_hdr.inbph_id%type
    ,go_muntsoort                   out     re_interest_base_perc_hdr.inbph_currency%type
    ,go_rentebasisnummer            out     re_interest_base_perc_hdr.inbph_number%type);

 procedure bijbehorende_rentebasis
   (i_muntsoort                     in      re_interest_base_perc_hdr.inbph_currency%type
   ,i_rentebasisnummer              in      re_interest_base_perc_hdr.inbph_number%type
   ,i_referentiedatum               in      re_interest_base_perc.inbp_ingangsdatum%type
   ,o_ingangsdatum_rentebasis       out     re_interest_base_perc.inbp_ingangsdatum%type
   ,o_basisrentepercentage          out     re_interest_base_perc.inbp_basis%type
   ,o_basisopslagpercentage         out     re_interest_base_perc.inbp_opslag%type);
 procedure bijbehorende_rentebasis_NA
   (i_muntsoort                     in      re_interest_base_perc_hdr.inbph_currency%type
   ,i_rentebasisnummer              in      re_interest_base_perc_hdr.inbph_number%type
   ,i_referentiedatum               in      re_interest_base_perc.inbp_ingangsdatum%type
   ,o_ingangsdatum_rentebasis       out     re_interest_base_perc.inbp_ingangsdatum%type);
 procedure bijbehorende_rentemarge
   (i_muntsoort                     in      re_margin_rates.marg_muntsoort%type
   ,i_rentemargenummer              in      re_margin_rates.marg_nummer%type
   ,i_margesoort                    in      re_margin_rates.marg_soort%type
   ,i_referentiedatum               in      re_margin_rates.marg_ingangsdatum%type
   ,o_ingangsdatum_rentemarge       out     re_margin_rates.marg_ingangsdatum%type
   ,o_rentemargepercentage          out     re_margin_rates.marg_marge%type);
 procedure bijbehorende_rentemarge_NA
   (i_muntsoort                     in      re_margin_rates.marg_muntsoort%type
   ,i_rentemargenummer              in      re_margin_rates.marg_nummer%type
   ,i_margesoort                    in      re_margin_rates.marg_soort%type
   ,i_referentiedatum               in      re_margin_rates.marg_ingangsdatum%type
   ,o_ingangsdatum_rentemarge       out     re_margin_rates.marg_ingangsdatum%type);
 procedure vul_rente_perc_afspraak
   (i_muntsoort                     in      rente_perc_afspraak.rpa_muntsoort%type
   ,i_afspraaknummer                in      rente_perc_afspraak.rpa_code%type
   ,i_referentiedatum               in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_DB_basis_opslag_percentage    in      rente_perc_afspraak.rpa_basis_db_opslag%type
   ,i_DB_marge_percentage           in      rente_perc_afspraak.rpa_marge_db%type
   ,i_CR_basis_opslag_percentage    in      rente_perc_afspraak.rpa_basis_cr_opslag%type
   ,i_CR_marge_percentage           in      rente_perc_afspraak.rpa_marge_cr%type);
 procedure opbouw_RPA_obv_rentebasisperc
   (i_muntsoort                     in      re_interest_base_perc_hdr.inbph_currency%type
   ,i_afspraaknummer                in      re_interest_base_perc_hdr.inbph_number%type
   ,i_rentebasisnummer_hoofd        in      re_interest_base_perc_hdr.inbph_number%type
   ,i_rentebasisnummer_sub          in      re_interest_base_perc_hdr.inbph_number%type
   ,i_hoofd_is_debt_kant            in      number
   ,i_aanmaken_vanaf_datum          in      re_interest_base_perc.inbp_ingangsdatum%type
   ,i_aanmaken_tm_datum             in      re_interest_base_perc.inbp_ingangsdatum%type);
 procedure opbouw_RPA_obv_marges_standen
   (i_muntsoort                     in      re_margin_rates.marg_muntsoort%type
   ,i_afspraaknummer                in      re_margin_rates.marg_nummer%type
   ,i_margesoort                    in      re_margin_rates.marg_soort%type
   ,i_rentebasisnummer_debt         in      re_interest_base_perc_hdr.inbph_number%type
   ,i_rentebasisnummer_cred         in      re_interest_base_perc_hdr.inbph_number%type
   ,i_aanmaken_vanaf_datum          in      re_margin_rates.marg_ingangsdatum%type
   ,i_aanmaken_tm_datum             in      re_margin_rates.marg_ingangsdatum%type);
 procedure opbouw_rente_perc_afspraak
   (i_muntsoort                     in      re_interest_agreement.inag_muntsoort%type
   ,i_afspraaknummer                in      re_interest_agreement.inag_nummer%type
   ,i_aanmaken_vanaf_datum          in      re_interest_agreement.inag_ingangsdatum%type
   ,i_aanmaken_tm_datum             in      re_interest_agreement.inag_ingangsdatum%type);
 procedure verwijder_rente_perc_afspraak
   (i_muntsoort                     in      re_interest_agreement.inag_muntsoort%type
   ,i_afspraaknummer                in      re_interest_agreement.inag_nummer%type
   ,i_verwijderen_vanaf_datum       in      re_interest_agreement.inag_ingangsdatum%type
   ,i_verwijderen_tm_datum          in      re_interest_agreement.inag_ingangsdatum%type);
 procedure init_rente_perc_afspraak
   (i_muntsoort                     in      re_interest_agreement.inag_muntsoort%type
   ,i_afspraaknummer                in      re_interest_agreement.inag_nummer%type);
 procedure bijbehorende_renteschaal
   (i_muntsoort                     in      re_interest_scale_dtl.insd_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_dtl.insd_code%type
   ,i_referentiedatum               in      re_interest_scale_dtl.insd_ingangsdatum%type
   ,i_type_debt_cred                in      re_interest_scale_dtl.insd_type_credit_debet%type
   ,i_1_schaalbedrag_gebruiken      in      number
   ,i_schaalbedrag                  in      re_interest_scale_dtl.insd_bedrag_vanaf%type
   ,o_ingangsdatum_renteschaal      out     re_interest_scale_dtl.insd_ingangsdatum%type);
 procedure bijbehorende_renteschaal_NA
   (i_muntsoort                     in      re_interest_scale_dtl.insd_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_dtl.insd_code%type
   ,i_referentiedatum               in      re_interest_scale_dtl.insd_ingangsdatum%type
   ,i_type_debt_cred                in      re_interest_scale_dtl.insd_type_credit_debet%type
   ,i_1_schaalbedrag_gebruiken      in      number
   ,i_schaalbedrag                  in      re_interest_scale_dtl.insd_bedrag_vanaf%type
   ,o_ingangsdatum_renteschaal      out     re_interest_scale_dtl.insd_ingangsdatum%type);
 procedure bijbeh_renteschaal_HDR
   (i_muntsoort                     in      re_interest_scale_hdr.insh_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_hdr.insh_code%type
   ,i_referentiedatum               in      re_interest_scale_hdr.insh_ingangsdatum%type
   ,o_ingangsdatum_renteschaal      out     re_interest_scale_hdr.insh_ingangsdatum%type);
 procedure bijbeh_renteschaal_HDR_NA
   (i_muntsoort                     in      re_interest_scale_hdr.insh_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_hdr.insh_code%type
   ,i_referentiedatum               in      re_interest_scale_hdr.insh_ingangsdatum%type
   ,o_ingangsdatum_renteschaal      out     re_interest_scale_hdr.insh_ingangsdatum%type);
procedure vul_rente_perc_schaaltarief
  (i_muntsoort                      in      rente_perc_schaaltarief.rps_muntsoort%type
  ,i_schaalcode                     in      rente_perc_schaaltarief.rps_code%type
  ,i_debet_credit_indicator         in      rente_perc_schaaltarief.rps_debet_credit_indicator%type
  ,i_SD_Bedrag_vanaf                in      rente_perc_schaaltarief.rps_schaalbedrag%type
  ,i_max_ingangsdatum               in      rente_perc_schaaltarief.rps_valutadatum%type
  ,i_rente_marge                    in      rente_perc_schaaltarief.rps_rente_marge%type
  ,i_basis_opslag                   in      rente_perc_schaaltarief.rps_basis_opslag%type);
procedure opb_rente_perc_schaaltrf_st3
  (i_insh_muntsoort                 in      re_interest_scale_hdr.insh_muntsoort%type
  ,i_schaalcode                     in      re_interest_scale_dtl.insd_code%type
  ,i_insd_basistarief               in      re_interest_scale_dtl.insd_basistarief%type
  ,i_startdatum_rentebasis          in      re_interest_scale_dtl.insd_ingangsdatum%type
  ,i_einddatum_rentebasis           in      re_interest_scale_dtl.insd_ingangsdatum%type
  ,i_debet_credit_indicator         in      rente_perc_schaaltarief.rps_debet_credit_indicator%type
  ,i_SD_bedrag_vanaf                in      re_interest_scale_dtl.insd_bedrag_vanaf%type
  ,i_insd_rentemarge                in      rente_perc_schaaltarief.rps_rente_marge%type
  ,i_insd_ingangsdatum              in      re_interest_scale_dtl.insd_ingangsdatum%type);
PROCEDURE opb_rente_perc_schaaltrf_st2
   (i_muntsoort                     in      re_interest_scale_dtl.insd_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_dtl.insd_code%type
   ,i_type_debt_cred                in      re_interest_scale_dtl.insd_type_credit_debet%type
   ,i_1_schaalbedrag_gebruiken      in      number
   ,i_startdatum_renteschaal        in      re_interest_scale_hdr.insh_ingangsdatum%type
   ,i_aanmaken_tm_datum             in      re_interest_scale_dtl.insd_ingangsdatum%type
   ,i_schaalbedrag                  in      re_interest_scale_dtl.insd_bedrag_vanaf%type);
 procedure opbouw_rente_perc_schaaltarief
   (i_muntsoort                     in      re_interest_scale_hdr.insh_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_hdr.insh_code%type
   ,i_DEBT_CRED                     in      re_interest_scale_dtl.insd_type_credit_debet%type
   ,i_1_schaalbedrag_gebruiken      in      number
   ,i_schaalbedrag                  in      re_interest_scale_dtl.insd_bedrag_vanaf%type
   ,i_aanmaken_vanaf_datum          in      re_interest_scale_hdr.insh_ingangsdatum%type
   ,i_aanmaken_tm_datum             in      re_interest_scale_dtl.insd_ingangsdatum%type);
PROCEDURE verw_rente_perc_schaaltarief
   (i_muntsoort                     in      re_interest_scale_hdr.insh_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_hdr.insh_code%type
   ,i_DEBT_CRED                     in      re_interest_scale_dtl.insd_type_credit_debet%type
   ,i_1_schaalbedrag_gebruiken      in      number
   ,i_schaalbedrag                  in      re_interest_scale_dtl.insd_bedrag_vanaf%type
   ,i_verwijder_vanaf_datum         in      re_interest_scale_hdr.insh_ingangsdatum%type
   ,i_verwijder_tm_datum            in      re_interest_scale_dtl.insd_ingangsdatum%type);
PROCEDURE init_rente_perc_schaaltarief
   (i_muntsoort                     in      re_interest_scale_hdr.insh_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_hdr.insh_code%type);
PROCEDURE bepaal_overlap_datumranges
   (i_verwijderen_vanaf_datum       in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_verwijderen_tm_datum          in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_aanmaken_vanaf_datum          in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_aanmaken_tm_datum             in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,o_overlap_aanwezig              out     number
   ,o_overlap_vanaf_datum           out     rente_perc_afspraak.rpa_ingangsdatum%type
   ,o_overlap_tm_datum              out     rente_perc_afspraak.rpa_ingangsdatum%type);
PROCEDURE bijw_rente_perc_afspraak
   (i_muntsoort                     in      rente_perc_afspraak.rpa_muntsoort%type
   ,i_afspraaknummer                in      rente_perc_afspraak.rpa_code%type
   ,i_verwijderen_vanaf_datum       in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_verwijderen_tm_datum          in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_aanmaken_vanaf_datum          in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_aanmaken_tm_datum             in      rente_perc_afspraak.rpa_ingangsdatum%type);
PROCEDURE bijw_rente_perc_schaaltarief
   (i_muntsoort                     in      rente_perc_schaaltarief.rps_muntsoort%type
   ,i_schaalcode                    in      rente_perc_schaaltarief.rps_code%type
   ,i_DEBT_CRED                     in      rente_perc_schaaltarief.rps_debet_credit_indicator%type
   ,i_1_schaalbedrag_gebruiken      in      number
   ,i_oude_schaalbedrag             in      rente_perc_schaaltarief.rps_schaalbedrag%type
   ,i_nieuwe_schaalbedrag           in      rente_perc_schaaltarief.rps_schaalbedrag%type
   ,i_verwijderen_vanaf_datum       in      rente_perc_schaaltarief.rps_valutadatum%type
   ,i_verwijderen_tm_datum          in      rente_perc_schaaltarief.rps_valutadatum%type
   ,i_aanmaken_vanaf_datum          in      rente_perc_schaaltarief.rps_valutadatum%type
   ,i_aanmaken_tm_datum             in      rente_perc_schaaltarief.rps_valutadatum%type);
PROCEDURE wijziging_rentebasispercentage;
PROCEDURE wijziging_rente_afspraken;
PROCEDURE wijziging_marges_standen;
PROCEDURE wijziging_renteschalen_header;
PROCEDURE wijziging_renteschalen_detail;
PROCEDURE lock_rentebasispercentage
   ( i_inbp_xxxx_id                 in      re_interest_base_perc_hdr.inbph_id%type);
PROCEDURE lock_rente_afspraken
   ( i_muntsoort                    in      re_interest_agreement.inag_muntsoort%type
    ,i_afspraaknummer               in      re_interest_agreement.inag_nummer%type
    ,i_inbp_nummer_DB_old           in      re_interest_base_perc_hdr.inbph_number%type
    ,i_inbp_nummer_DB_new           in      re_interest_base_perc_hdr.inbph_number%type
    ,i_inbp_nummer_CR_old           in      re_interest_base_perc_hdr.inbph_number%type
    ,i_inbp_nummer_CR_new           in      re_interest_base_perc_hdr.inbph_number%type);
PROCEDURE lock_marges_standen
   (i_muntsoort                     in      re_margin_rates.marg_muntsoort%type
   ,i_rentemargenummer              in      re_margin_rates.marg_nummer%type);
PROCEDURE lock_renteschalen_header
   (i_muntsoort                     in      re_interest_scale_hdr.insh_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_hdr.insh_code%type);
PROCEDURE lock_renteschalen_detail
   ( i_muntsoort                    in      re_interest_scale_dtl.insd_muntsoort%type
    ,i_schaalcode                   in      re_interest_scale_dtl.insd_code%type
    ,i_inbp_nummer_old              in      re_interest_base_perc_hdr.inbph_number%type
    ,i_inbp_nummer_new              in      re_interest_base_perc_hdr.inbph_number%type);
PROCEDURE bepalen_renteschalen
   (i_muntsoort                     in      rente_perc_schaaltarief.rps_muntsoort%type
    ,i_schaalcode_basis             in      re_interest_scale_dtl_vw.insd_basistarief%type
    ,i_renteschaal                  in      rente_perc_schaaltarief.rps_code%type
    ,i_bijwerken_vanaf_datum        in      rente_perc_schaaltarief.rps_valutadatum%type);
PROCEDURE ontbrekende_renteschalen
   ( i_muntsoort                    in      rente_perc_schaaltarief.rps_muntsoort%type
    ,i_code                         in      rente_perc_schaaltarief.rps_code%type
    ,i_valutadatum                  in      rente_perc_schaaltarief.rps_valutadatum%type
    ,i_vorige_valutadatum           in      rente_perc_schaaltarief.rps_valutadatum%type
    ,i_debet_credit_indicator       in      rente_perc_schaaltarief.rps_debet_credit_indicator%type);
PROCEDURE vorige_header
   ( i_muntsoort                    in      rente_perc_schaaltarief.rps_muntsoort%type
    ,i_renteschaal                  in      rente_perc_schaaltarief.rps_code%type
    ,i_bijwerken_vanaf_datum        in      rente_perc_schaaltarief.rps_valutadatum%type
    ,o_bijwerken_vanaf_datum        out     rente_perc_schaaltarief.rps_valutadatum%type);
PROCEDURE datum_opbouwen
   ( i_muntsoort                    in      rente_perc_schaaltarief.rps_muntsoort%type,
     i_code                         in      rente_perc_schaaltarief.rps_code%type,
     i_valutadatum                  in      rente_perc_schaaltarief.rps_valutadatum%type,
     i_vorige_valutadatum           in      rente_perc_schaaltarief.rps_valutadatum%type,
     i_debet_credit_indicator       in      rente_perc_schaaltarief.rps_debet_credit_indicator%type,
     o_opbouwen                     out     number);
PROCEDURE aanv_rente_perc_schl_tarief
    (i_muntsoort                    in      rente_perc_schaaltarief.rps_muntsoort%type,
     i_renteschaal                  in      rente_perc_schaaltarief.rps_code%type,
     i_debet_credit                 in      rente_perc_schaaltarief.rps_debet_credit_indicator%type,
     i_bijwerken_vanaf_datum        in      rente_perc_schaaltarief.rps_valutadatum%type);
FUNCTION version
     return                                 varchar2;


end;

/*------------------------------------------------------------------------------
history      : 24-AUG-2011, GN, Initiele versie
             : 05-JUN-2013, GV, renteafspraken vervangen door re_interest_agreement en rt_ door inag_
                                marges_standen vervangen door re_margin_rates
                                renteschalen_header vervangen door re_interest_scale_hdr en sh_ door insh_
                                renteschalen_detail vervangen door re_interest_scale_dtl en sd_ door insd_
                                rentebasispercentage vervangen door re_interest_base_perc en rbp_ door inbp_
                                namen van procedures zijn hiervan uitgezonderd, deze blijven gelijk
               07-NOV-2023, JW, gv_versie en function version toegevoegd zodat deze package ook netjes
                                een versienummer krijgt op basis van de EP+ versie + changeset-id
------------------------------------------------------------------------------*/
/
CREATE OR REPLACE PACKAGE BODY ONDERHOUD_RENTETABELLEN
IS

/*------------------------------------------------------------------------------
Package body : ONDERHOUD_RENTETABELLEN
description  : code voor de package body ONDERHOUD_RENTETABELLEN waarbinnen de
               volgende procedures aanwezig zijn:
               set_globale_var_rentebasis
               set_globale_var_afspraken
               set_globale_var_marges
               set_globale_var_schalen_header
               set_globale_var_schalen_detail
               set_gmunt_gnummer
               bijbehorende_rentebasis
               bijbehorende_rentebasis_NA
               bijbehorende_rentemarge
               bijbehorende_rentemarge_NA
               vul_rente_perc_afspraak
               opbouw_RPA_obv_rentebasisperc
               opbouw_RPA_obv_marges_standen
               opbouw_rente_perc_afspraak
               verwijder_rente_perc_afspraak
               init_rente_perc_afspraak
               bijbehorende_renteschaal
               bijbehorende_renteschaal_NA
               bijbeh_renteschaal_HDR
               bijbeh_renteschaal_HDR_NA
               vul_rente_perc_schaaltarief
               opb_rente_perc_schaaltrf_st3
               opb_rente_perc_schaaltrf_st2
               opbouw_rente_perc_schaaltarief
               verw_rente_perc_schaaltarief
               init_rente_perc_schaaltarief
               bepaal_overlap_datumranges
               bijw_rente_perc_afspraak
               bijw_rente_perc_schaaltarief
               wijziging_rentebasispercentage
               wijziging_rente_afspraken
               wijziging_marges_standen
               wijziging_renteschalen_header
               wijziging_renteschalen_detail
               lock_rentebasispercentage
               lock_rente_afspraken
               lock_marges_standen
               lock_renteschalen_header
               lock_renteschalen_detail
author       : Syntel Financial Software, Bart Hijman / Gert Nijenhuis
code         : 5744-52406-0001
history      : 25-AUG-2011, JJW initiele versie
               05-JAN-2011, GN aanpassing procedure verw_rente_perc_schaaltarief
                               zodat schaalbedragen met waarden die decimalen
                               achter de comma hebben ook verwerkt kunnen worden
               08-JUN-2012, WK uitlering 05.18.00.00
------------------------------------------------------------------------------*/

--
-- Procedure voor het vullen van de globale variabelen bij aanpassing van een re_interest_base_perc
-- Deze procedure wordt aangeroepen door triggers:
-- re_interest_base_perc_TRG_AI_R
-- re_interest_base_perc_TRG_AU_R
-- re_interest_base_perc_TRG_AD_R
--
PROCEDURE set_globale_var_rentebasis
   ( i_inbp_basis_old               in      re_interest_base_perc.inbp_basis%type
    ,i_inbp_basis_new               in      re_interest_base_perc.inbp_basis%type
    ,i_inbp_opslag_old              in      re_interest_base_perc.inbp_opslag%type
    ,i_inbp_opslag_new              in      re_interest_base_perc.inbp_opslag%type
    ,i_inbp_xxxx_id                  in      re_interest_base_perc.inbp_xxxx_id%type
    ,i_ingangsdatum                 in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_nieuwe_ingangsdatum          in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_soort_wijziging              in      varchar2)
AS

BEGIN
   g_inbp_basis_old       := i_inbp_basis_old;
   g_inbp_basis_new     := i_inbp_basis_new;
   g_inbp_opslag_old    := i_inbp_opslag_old;
   g_inbp_opslag_new    := i_inbp_opslag_new;
   g_inag_debet_rente_old := 0;
   g_inag_debet_rente_new := 0;
   g_inag_credit_rente_old:= 0;
   g_inag_credit_rente_new:= 0;
   g_marg_marge_old       := 0;
   g_marg_marge_new       := 0;
   g_insd_basistarief_old := 0;
   g_insd_basistarief_new := 0;
   g_insd_rentemarge_old  := 0;
   g_insd_rentemarge_new  := 0;
   ONDERHOUD_RENTETABELLEN.set_gmunt_gnummer(i_inbp_xxxx_id, g_muntsoort, g_rentebasisnummer);
   g_afspraaknummer       := 0;
   g_schalennummer        := 0;
   g_ingangsdatum         := i_ingangsdatum;
   g_nieuwe_ingangsdatum  := i_nieuwe_ingangsdatum;
   g_marg_soort           := ' ';
   g_type_credit_debet    := ' ';
   g_bedrag_vanaf         := 0;
   g_nieuwe_bedrag_vanaf  := 0;
   g_soort_wijziging      := i_soort_wijziging;
END set_globale_var_rentebasis;


--
-- Procedure voor het vullen van de globale variabelen bij aanpassing van een rente_afspraak
-- Deze procedure wordt aangeroepen door triggers:
-- re_interest_agreement_TRG_AI_R
-- re_interest_agreement_TRG_AU_R
-- re_interest_agreement_TRG_AD_R
--
PROCEDURE set_globale_var_afspraken
   ( i_inag_debet_rente_old         in      re_interest_base_perc_hdr.inbph_number%type
    ,i_inag_debet_rente_new         in      re_interest_base_perc_hdr.inbph_number%type
    ,i_inag_credit_rente_old        in      re_interest_base_perc_hdr.inbph_number%type
    ,i_inag_credit_rente_new        in      re_interest_base_perc_hdr.inbph_number%type
    ,i_muntsoort                    in      re_interest_base_perc_hdr.inbph_currency%type
    ,i_afspraaknummer               in      re_interest_agreement.inag_nummer%type
    ,i_soort_wijziging              in      varchar2)
AS

BEGIN
   g_inbp_basis_old       := 0;
   g_inbp_basis_new     := 0;
   g_inbp_opslag_old    := 0;
   g_inbp_opslag_new    := 0;
   g_inag_debet_rente_old := i_inag_debet_rente_old;
   g_inag_debet_rente_new := i_inag_debet_rente_new;
   g_inag_credit_rente_old:= i_inag_credit_rente_old;
   g_inag_credit_rente_new:= i_inag_credit_rente_new;
   g_marg_marge_old       := 0;
   g_marg_marge_new       := 0;
   g_insd_basistarief_old := 0;
   g_insd_basistarief_new := 0;
   g_insd_rentemarge_old  := 0;
   g_insd_rentemarge_new  := 0;
   g_muntsoort            := i_muntsoort;
   g_rentebasisnummer     := 0;
   g_afspraaknummer       := i_afspraaknummer;
   g_schalennummer        := 0;
   g_ingangsdatum         := '00000000';
   g_nieuwe_ingangsdatum  := '00000000';
   g_marg_soort           := ' ';
   g_type_credit_debet    := ' ';
   g_bedrag_vanaf         := 0;
   g_nieuwe_bedrag_vanaf  := 0;
   g_soort_wijziging      := i_soort_wijziging;
END set_globale_var_afspraken;

--
-- Procedure voor het vullen van de globale variabelen bij aanpassing van een re_margin_rates
-- Deze procedure wordt aangeroepen door triggers:
--  re_margin_rates_TRG_AI_R
--  re_margin_rates_TRG_AU_R
--  re_margin_rates_TRG_AD_R
--
PROCEDURE set_globale_var_marges
   ( i_marg_marge_old               in      re_margin_rates.marg_marge%type
    ,i_marg_marge_new               in      re_margin_rates.marg_marge%type
    ,i_muntsoort                    in      re_interest_base_perc_hdr.inbph_currency%type
    ,i_afspraaknummer               in      re_interest_agreement.inag_nummer%type
    ,i_ingangsdatum                 in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_nieuwe_ingangsdatum          in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_marg_soort                   in      re_margin_rates.marg_soort%type
    ,i_soort_wijziging              in      varchar2)
AS

BEGIN
   g_inbp_basis_old         := 0;
   g_inbp_basis_new       := 0;
   g_inbp_opslag_old      := 0;
   g_inbp_opslag_new      := 0;
   g_inag_debet_rente_old   := 0;
   g_inag_debet_rente_new   := 0;
   g_inag_credit_rente_old  := 0;
   g_inag_credit_rente_new  := 0;
   g_marg_marge_old         := i_marg_marge_old;
   g_marg_marge_new         := i_marg_marge_new;
   g_insd_basistarief_old   := 0;
   g_insd_basistarief_new   := 0;
   g_insd_rentemarge_old    := 0;
   g_insd_rentemarge_new    := 0;
   g_muntsoort              := i_muntsoort;
   g_rentebasisnummer       := 0;
   g_afspraaknummer         := i_afspraaknummer;
   g_schalennummer          := 0;
   g_ingangsdatum           := i_ingangsdatum;
   g_nieuwe_ingangsdatum    := i_nieuwe_ingangsdatum;
   g_marg_soort             := i_marg_soort;
   g_type_credit_debet      := ' ';
   g_bedrag_vanaf           := 0;
   g_nieuwe_bedrag_vanaf    := 0;
   g_soort_wijziging        := i_soort_wijziging;
END set_globale_var_marges;

--
-- Procedure voor het vullen van de globale variabelen bij aanpassing van een schalen_header
-- Deze procedure wordt aangeroepen door triggers:
-- re_interest_scale_hdr_TRG_AI_R
-- re_interest_scale_hdr_TRG_AU_R
-- re_interest_scale_hdr_TRG_AD_R
--
PROCEDURE set_globale_var_schalen_header
   ( i_muntsoort                    in      re_interest_base_perc_hdr.inbph_currency%type
    ,i_schalennummer                in      re_interest_base_perc_hdr.inbph_number%type
    ,i_ingangsdatum                 in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_nieuwe_ingangsdatum          in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_soort_wijziging              in      varchar2)
AS

BEGIN
   g_inbp_basis_old         := 0;
   g_inbp_basis_new       := 0;
   g_inbp_opslag_old      := 0;
   g_inbp_opslag_new      := 0;
   g_inag_debet_rente_old := 0;
   g_inag_debet_rente_new := 0;
   g_inag_credit_rente_old  := 0;
   g_inag_credit_rente_new  := 0;
   g_marg_marge_old         := 0;
   g_marg_marge_new         := 0;
   g_insd_basistarief_old   := 0;
   g_insd_basistarief_new   := 0;
   g_insd_rentemarge_old    := 0;
   g_insd_rentemarge_new    := 0;
   g_muntsoort              := i_muntsoort;
   g_rentebasisnummer       := 0;
   g_afspraaknummer         := 0;
   g_schalennummer          := i_schalennummer;
   g_ingangsdatum           := i_ingangsdatum;
   g_nieuwe_ingangsdatum    := i_nieuwe_ingangsdatum;
   g_marg_soort             := ' ';
   g_type_credit_debet      := ' ';
   g_bedrag_vanaf           := 0;
   g_nieuwe_bedrag_vanaf    := 0;
   g_soort_wijziging        := i_soort_wijziging;
END set_globale_var_schalen_header;

--
-- Procedure voor het vullen van de globale variabelen bij aanpassing van een schalen_detail
-- Deze procedure wordt aangeroepen door triggers:
-- re_interest_scale_dtl_TRG_AI_R
-- re_interest_scale_dtl_TRG_AU_R
-- re_interest_scale_dtl_TRG_AD_R
--
PROCEDURE set_globale_var_schalen_detail
   ( i_insd_basistarief_old         in      re_interest_base_perc_hdr.inbph_number%type
    ,i_insd_basistarief_new         in      re_interest_base_perc_hdr.inbph_number%type
    ,i_insd_rentemarge_old          in      re_interest_scale_dtl.insd_rentemarge%type
    ,i_insd_rentemarge_new          in      re_interest_scale_dtl.insd_rentemarge%type
    ,i_muntsoort                    in      re_interest_base_perc_hdr.inbph_currency%type
    ,i_schalennummer                in      re_interest_base_perc_hdr.inbph_number%type
    ,i_ingangsdatum                 in      re_interest_base_perc.inbp_ingangsdatum%type
    ,i_type_credit_debet            in      re_interest_scale_dtl.insd_type_credit_debet%type
    ,i_bedrag_vanaf                 in      re_interest_scale_dtl.insd_bedrag_vanaf%type
    ,i_nieuwe_bedrag_vanaf          in      re_interest_scale_dtl.insd_bedrag_vanaf%type
    ,i_soort_wijziging              in      varchar2)
AS

BEGIN
   g_inbp_basis_old   := 0;
   g_inbp_basis_new     := 0;
   g_inbp_opslag_old    := 0;
   g_inbp_opslag_new    := 0;
   g_inag_debet_rente_old   := 0;
   g_inag_debet_rente_new   := 0;
   g_inag_credit_rente_old  := 0;
   g_inag_credit_rente_new  := 0;
   g_marg_marge_old   := 0;
   g_marg_marge_new   := 0;
   g_insd_basistarief_old   := i_insd_basistarief_old;
   g_insd_basistarief_new   := i_insd_basistarief_new;
   g_insd_rentemarge_old    := i_insd_rentemarge_old;
   g_insd_rentemarge_new    := i_insd_rentemarge_new;
   g_muntsoort            := i_muntsoort;
   g_rentebasisnummer     := 0;
   g_afspraaknummer       := 0;
   g_schalennummer    := i_schalennummer;
   g_ingangsdatum         := i_ingangsdatum;
   g_nieuwe_ingangsdatum  := '00000000';
   g_marg_soort           := ' ';
   g_type_credit_debet    := i_type_credit_debet;
   g_bedrag_vanaf         := i_bedrag_vanaf;
   g_nieuwe_bedrag_vanaf  := i_nieuwe_bedrag_vanaf;
   g_soort_wijziging      := i_soort_wijziging;
END set_globale_var_schalen_detail;


--  Sub procedure voor het zetten van 2 globale variabelen g_muntsoort en g_rentebasisnummer
--  vanuit re_interest_base_perc_hdr.inbph_id = re_interest_base_perc.inbp_xxx_id
--  Wordt aangeroepen door PROCEDURE set_globale_var_rentebasis

PROCEDURE set_gmunt_gnummer
  (i_inbph_id                      in      re_interest_base_perc_hdr.inbph_id%type
  ,go_muntsoort                    out     re_interest_base_perc_hdr.inbph_currency%type
  ,go_rentebasisnummer             out     re_interest_base_perc_hdr.inbph_number%type)
AS
   v_muntsoort                             re_interest_base_perc_hdr.inbph_currency%type;
   v_rentebasisnummer                      re_interest_base_perc_hdr.inbph_number%type;

cursor smn is
       select inbph_currency,
              inbph_number
       from   re_interest_base_perc_hdr
       where  inbph_id = i_inbph_id;

BEGIN
    open smn;
    fetch smn into
          v_muntsoort,
          v_rentebasisnummer;
       go_muntsoort := v_muntsoort;
       go_rentebasisnummer := v_rentebasisnummer;

    close smn;
END set_gmunt_gnummer;



--
--  Procedure voor het bepalen van het eerste record van tabel re_interest_base_perc welke
--  VOOR een opgegeven referentiedatum ligt
--
PROCEDURE bijbehorende_rentebasis
   (i_muntsoort                     in      re_interest_base_perc_hdr.inbph_currency%type
   ,i_rentebasisnummer              in      re_interest_base_perc_hdr.inbph_number%type
   ,i_referentiedatum               in      re_interest_base_perc.inbp_ingangsdatum%type
   ,o_ingangsdatum_rentebasis       out     re_interest_base_perc.inbp_ingangsdatum%type
   ,o_basisrentepercentage          out     re_interest_base_perc.inbp_basis%type
   ,o_basisopslagpercentage         out     re_interest_base_perc.inbp_opslag%type)
AS
 v_ingangsdatum_rentebasis       re_interest_base_perc.inbp_ingangsdatum%type;
 v_basisrentepercentage          re_interest_base_perc.inbp_basis%type;
 v_basisopslagpercentage         re_interest_base_perc.inbp_opslag%type;

 cursor rdp is
       select inbp_ingangsdatum,
              inbp_basis,
              inbp_opslag
       from   re_interest_base_perc_vw
       where  inbp_muntsoort      = i_muntsoort
       and    inbp_nummer         = i_rentebasisnummer
       and    inbp_ingangsdatum  <= i_referentiedatum
       order by inbp_ingangsdatum desc;

BEGIN
    open rdp;
    fetch rdp into v_ingangsdatum_rentebasis,
                   v_basisrentepercentage,
                   v_basisopslagpercentage ;
    if rdp%notfound
    then
       o_ingangsdatum_rentebasis := '00000000';
       o_basisrentepercentage    := 0;
       o_basisopslagpercentage   := 0;
    else
       o_ingangsdatum_rentebasis := v_ingangsdatum_rentebasis;
       o_basisrentepercentage    := v_basisrentepercentage;
       o_basisopslagpercentage   := v_basisopslagpercentage ;
    end if;
    close rdp;
END bijbehorende_rentebasis;

--
-- Procedure voor het bepalen van het eerste record van tabel re_interest_base_perc
-- welke NA een opgegeven referentiedatum ligt
--
PROCEDURE bijbehorende_rentebasis_NA
   (i_muntsoort                     in      re_interest_base_perc_hdr.inbph_currency%type
   ,i_rentebasisnummer              in      re_interest_base_perc_hdr.inbph_number%type
   ,i_referentiedatum               in      re_interest_base_perc.inbp_ingangsdatum%type
   ,o_ingangsdatum_rentebasis       out     re_interest_base_perc.inbp_ingangsdatum%type)
AS
 v_ingangsdatum_rentebasis re_interest_base_perc.inbp_ingangsdatum%type;

 cursor rdp is
       select inbp_ingangsdatum
       from   re_interest_base_perc_vw
       where  inbp_muntsoort      = i_muntsoort
       and    inbp_nummer         = i_rentebasisnummer
       and    inbp_ingangsdatum   > i_referentiedatum
       order by inbp_ingangsdatum asc;

BEGIN
    open rdp;
    fetch rdp into v_ingangsdatum_rentebasis;
    if rdp%notfound
    then
       o_ingangsdatum_rentebasis := '99991231';
    else
       o_ingangsdatum_rentebasis := v_ingangsdatum_rentebasis;
    end if;
    close rdp;
END bijbehorende_rentebasis_NA;

--
--  Procedure voor het bepalen van het eerste record van tabel RE_MARGIN_RATES
--  welke VOOR een opgegeven referentiedatum ligt
--
PROCEDURE bijbehorende_rentemarge
   (i_muntsoort                     in      re_margin_rates.marg_muntsoort%type
   ,i_rentemargenummer              in      re_margin_rates.marg_nummer%type
   ,i_margesoort                    in      re_margin_rates.marg_soort%type
   ,i_referentiedatum               in      re_margin_rates.marg_ingangsdatum%type
   ,o_ingangsdatum_rentemarge       out     re_margin_rates.marg_ingangsdatum%type
   ,o_rentemargepercentage          out     re_margin_rates.marg_marge%type)
AS
 v_ingangsdatum_rentemarge   re_margin_rates.marg_ingangsdatum%type;
 v_rentemargepercentage      re_margin_rates.marg_marge%type;

 cursor marg is
       select marg_ingangsdatum,marg_marge
       from   re_margin_rates_vw
       where  marg_muntsoort      = i_muntsoort
       and    marg_nummer         = i_rentemargenummer
       and    marg_soort          = i_margesoort
       and    marg_ingangsdatum  <= i_referentiedatum
       order by marg_ingangsdatum desc;

BEGIN
    open marg;
    fetch marg into v_ingangsdatum_rentemarge,
                    v_rentemargepercentage;
    if marg%notfound
    then
       o_ingangsdatum_rentemarge := '00000000';
       o_rentemargepercentage    := 0;
    else
       o_ingangsdatum_rentemarge := v_ingangsdatum_rentemarge;
       o_rentemargepercentage    := v_rentemargepercentage;
  end if;
  close marg;
END bijbehorende_rentemarge;

--
--   Procedure voor het bepalen van het eerste record van tabel RE_MARGIN_RATES welke
--   NA een opgegeven referentiedatum ligt.
--
PROCEDURE bijbehorende_rentemarge_NA
   (i_muntsoort                     in      re_margin_rates.marg_muntsoort%type
   ,i_rentemargenummer              in      re_margin_rates.marg_nummer%type
   ,i_margesoort                    in      re_margin_rates.marg_soort%type
   ,i_referentiedatum               in      re_margin_rates.marg_ingangsdatum%type
   ,o_ingangsdatum_rentemarge       out     re_margin_rates.marg_ingangsdatum%type)
AS
 v_ingangsdatum_rentemarge   re_margin_rates.marg_ingangsdatum%type;

 cursor marg is
       select marg_ingangsdatum
       from   re_margin_rates_vw
       where  marg_muntsoort      = i_muntsoort
       and    marg_nummer         = i_rentemargenummer
       and    marg_soort          = i_margesoort
       and    marg_ingangsdatum   > i_referentiedatum
       order by marg_ingangsdatum asc;

BEGIN
    open marg;
    fetch marg into v_ingangsdatum_rentemarge;
    if marg%notfound
    then
       o_ingangsdatum_rentemarge := '99991231';
    else
       o_ingangsdatum_rentemarge := v_ingangsdatum_rentemarge;
  end if;
  close marg;
END bijbehorende_rentemarge_NA;

--
--   Procedure voor het aanmaken van een record in tabel RENTE_PERC_AFSPRAAK.
--   Bestaat het record al, dan worden de 'percentage kolommen' van dit record ge-update.
--
PROCEDURE vul_rente_perc_afspraak
   (i_muntsoort                     in      rente_perc_afspraak.rpa_muntsoort%type
   ,i_afspraaknummer                in      rente_perc_afspraak.rpa_code%type
   ,i_referentiedatum               in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_DB_basis_opslag_percentage    in      rente_perc_afspraak.rpa_basis_db_opslag%type
   ,i_DB_marge_percentage           in      rente_perc_afspraak.rpa_marge_db%type
   ,i_CR_basis_opslag_percentage    in      rente_perc_afspraak.rpa_basis_cr_opslag%type
   ,i_CR_marge_percentage           in      rente_perc_afspraak.rpa_marge_cr%type)
AS

  v_aantal_gevonden number;

BEGIN
--
--    merge into rente_perc_afspraak rpa
--    using (select 1 from DUAL)
--       on (rpa.rpa_muntsoort = i_muntsoort
--      and  rpa.rpa_code = i_afspraaknummer
--      and  rpa.rpa_ingangsdatum = i_referentiedatum)
--     when matched then
--          update set rpa.rpa_basis_db_opslag = i_DB_basis_opslag_percentage
--,                    rpa.rpa_basis_cr_opslag = i_CR_basis_opslag_percentage
--,                    rpa.rpa_marge_db = i_DB_marge_percentage
--,                    rpa.rpa_marge_cr = i_CR_marge_percentage
--     when not matched then
--          insert (rpa.rpa_muntsoort
--,                 rpa.rpa_code
--,                 rpa.rpa_ingangsdatum
--,                 rpa.rpa_basis_db_opslag
--,                 rpa.rpa_basis_cr_opslag
--,                 rpa.rpa_marge_db
--,                 rpa.rpa_marge_cr)
--          values (i_muntsoort
--,                 i_afspraaknummer
--,                 i_referentiedatum
--,                 i_DB_basis_opslag_percentage
--,                 i_CR_basis_opslag_percentage
--,                 i_DB_marge_percentage
--,                 i_CR_marge_percentage);
--
    v_aantal_gevonden := 0;

    select count(*) into v_aantal_gevonden
      from rente_perc_afspraak rpa
     where rpa.rpa_muntsoort = i_muntsoort
       and rpa.rpa_code = i_afspraaknummer
       and rpa.rpa_ingangsdatum = i_referentiedatum;

    if v_aantal_gevonden > 0 then
       update rente_perc_afspraak rpa
          set rpa.rpa_basis_db_opslag = i_DB_basis_opslag_percentage
,             rpa.rpa_basis_cr_opslag = i_CR_basis_opslag_percentage
,             rpa.rpa_marge_db = i_DB_marge_percentage
,             rpa.rpa_marge_cr = i_CR_marge_percentage
        where rpa.rpa_muntsoort = i_muntsoort
          and rpa.rpa_code = i_afspraaknummer
          and rpa.rpa_ingangsdatum = i_referentiedatum;
    else
        insert into rente_perc_afspraak rpa
               (rpa.rpa_muntsoort
,               rpa.rpa_code
,               rpa.rpa_ingangsdatum
,               rpa.rpa_basis_db_opslag
,               rpa.rpa_basis_cr_opslag
,               rpa.rpa_marge_db
,               rpa.rpa_marge_cr)
        values (i_muntsoort
,               i_afspraaknummer
,               i_referentiedatum
,               i_DB_basis_opslag_percentage
,               i_CR_basis_opslag_percentage
,               i_DB_marge_percentage
,               i_CR_marge_percentage);
    end if;

END vul_rente_perc_afspraak;

--
--   Deze procedure bouwt het gedeelte van de RENTE_PERC_AFSPRAAK op voor de debet of de credit kant
--   welke te maken heeft met veranderingen in tabel re_interest_base_perc / RE_MARGIN_RATES.
--
PROCEDURE opbouw_RPA_obv_rentebasisperc
   (i_muntsoort                     in      re_interest_base_perc_hdr.inbph_currency%type
   ,i_afspraaknummer                in      re_interest_base_perc_hdr.inbph_number%type
   ,i_rentebasisnummer_hoofd        in      re_interest_base_perc_hdr.inbph_number%type
   ,i_rentebasisnummer_sub          in      re_interest_base_perc_hdr.inbph_number%type
   ,i_hoofd_is_debt_kant            in      number
   ,i_aanmaken_vanaf_datum          in      re_interest_base_perc.inbp_ingangsdatum%type
   ,i_aanmaken_tm_datum             in      re_interest_base_perc.inbp_ingangsdatum%type)
AS
 v_inbp_muntsoort         re_interest_base_perc_hdr.inbph_currency%type;
 v_inbp_nummer            re_interest_base_perc_hdr.inbph_number%type;
 v_inbp_ingangsdatum      re_interest_base_perc.inbp_ingangsdatum%type;
 v_inbp_omschrijving      re_interest_base_perc_hdr.inbph_description%type;
 v_inbp_basis             re_interest_base_perc.inbp_basis%type;
 v_inbp_opslag            re_interest_base_perc.inbp_opslag%type;
 v_dummy_datum            re_interest_base_perc.inbp_ingangsdatum%type;
 v_basisrenteperc_sub     re_interest_base_perc.inbp_basis%type;
 v_basisrenteopslag_sub   re_interest_base_perc.inbp_opslag%type;
 v_basis_opslag_DB        re_interest_base_perc.inbp_basis%type;
 v_basis_opslag_CR        re_interest_base_perc.inbp_basis%type;
 v_margeperc_debt         re_margin_rates.marg_marge%type;
 v_margeperc_cred         re_margin_rates.marg_marge%type;

 cursor rbp is
       select inbp_muntsoort
,             inbp_nummer
,             inbp_ingangsdatum
,             inbp_omschrijving
,             inbp_basis
,             inbp_opslag
       from   re_interest_base_perc_vw
       where  inbp_muntsoort  = i_muntsoort
       and    inbp_nummer     = i_rentebasisnummer_hoofd
       and    inbp_ingangsdatum between i_aanmaken_vanaf_datum and i_aanmaken_tm_datum
       order by inbp_ingangsdatum desc;

BEGIN
    open rbp;
    loop
      fetch rbp into v_inbp_muntsoort
,                    v_inbp_nummer
,                    v_inbp_ingangsdatum
,                    v_inbp_omschrijving
,                    v_inbp_basis
,                    v_inbp_opslag;
      exit when rbp%notfound;

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(i_muntsoort, i_rentebasisnummer_sub, v_inbp_ingangsdatum,
                                                      v_dummy_datum, v_basisrenteperc_sub, v_basisrenteopslag_sub);
      if i_hoofd_is_debt_kant = 1 then
        v_basis_opslag_DB := v_inbp_basis + v_inbp_opslag;
        v_basis_opslag_CR := v_basisrenteperc_sub + v_basisrenteopslag_sub;
      else
        v_basis_opslag_DB := v_basisrenteperc_sub + v_basisrenteopslag_sub;
        v_basis_opslag_CR := v_inbp_basis + v_inbp_opslag;
      end if;

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge(i_muntsoort, i_afspraaknummer, 'DEBT', v_inbp_ingangsdatum,
                                                      v_dummy_datum, v_margeperc_debt);

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge(i_muntsoort, i_afspraaknummer, 'CRED', v_inbp_ingangsdatum,
                                                      v_dummy_datum, v_margeperc_cred);

      ONDERHOUD_RENTETABELLEN.vul_rente_perc_afspraak(i_muntsoort, i_afspraaknummer, v_inbp_ingangsdatum,
                                                      v_basis_opslag_DB, v_margeperc_debt, v_basis_opslag_CR,
                                                      v_margeperc_cred);
    end loop;
    close rbp;
END opbouw_RPA_obv_rentebasisperc;

--
--   Deze procedure bouwt het gedeelte van de RENTE_PERC_AFSPRAAK op voor de debet of de credit kant welke
--   te maken heeft met veranderingen in tabel RE_MARGIN_RATES / re_interest_base_perc.
--
PROCEDURE opbouw_RPA_obv_marges_standen
   (i_muntsoort                     in      re_margin_rates.marg_muntsoort%type
   ,i_afspraaknummer                in      re_margin_rates.marg_nummer%type
   ,i_margesoort                    in      re_margin_rates.marg_soort%type
   ,i_rentebasisnummer_debt         in      re_interest_base_perc_hdr.inbph_number%type
   ,i_rentebasisnummer_cred         in      re_interest_base_perc_hdr.inbph_number%type
   ,i_aanmaken_vanaf_datum          in      re_margin_rates.marg_ingangsdatum%type
   ,i_aanmaken_tm_datum             in      re_margin_rates.marg_ingangsdatum%type)
AS
 v_margesoort_sub         re_margin_rates.marg_soort%type;
 v_marg_muntsoort         re_margin_rates.marg_muntsoort%type;
 v_marg_nummer            re_margin_rates.marg_nummer%type;
 v_marg_soort             re_margin_rates.marg_soort%type;
 v_marg_ingangsdatum      re_margin_rates.marg_ingangsdatum%type;
 v_marg_marge             re_margin_rates.marg_marge%type;
 v_margeperc_sub          re_margin_rates.marg_marge%type;
 v_dummy_datum            re_margin_rates.marg_ingangsdatum%type;
 v_basisrenteperc_debt    re_interest_base_perc.inbp_basis%type;
 v_basisrenteopslag_debt  re_interest_base_perc.inbp_basis%type;
 v_basis_opslag_debt      re_interest_base_perc.inbp_basis%type;
 v_basisrenteperc_cred    re_interest_base_perc.inbp_basis%type;
 v_basisrenteopslag_cred  re_interest_base_perc.inbp_basis%type;
 v_basis_opslag_cred      re_interest_base_perc.inbp_basis%type;
 v_margeperc_debt         re_margin_rates.marg_marge%type;
 v_margeperc_cred         re_margin_rates.marg_marge%type;

 cursor ms is
       select marg_muntsoort
,             marg_nummer
,             marg_soort
,             marg_ingangsdatum
,             marg_marge
       from   re_margin_rates_vw
       where  marg_muntsoort = i_muntsoort
       and    marg_nummer = i_afspraaknummer
       and    marg_soort = i_margesoort
       and    marg_ingangsdatum between i_aanmaken_vanaf_datum and i_aanmaken_tm_datum
       order by marg_ingangsdatum desc;

BEGIN
    if i_margesoort = 'DEBT' then
       v_margesoort_sub    := 'CRED';
    else
       v_margesoort_sub    := 'DEBT';
    end if;

    open ms;
    loop
      fetch ms into v_marg_muntsoort
,                   v_marg_nummer
,                   v_marg_soort
,                   v_marg_ingangsdatum
,                   v_marg_marge;
      exit when ms%notfound;

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge(i_muntsoort, i_afspraaknummer, v_margesoort_sub,
                                                      v_marg_ingangsdatum, v_dummy_datum, v_margeperc_sub);
      if i_margesoort = 'DEBT' then
         v_margeperc_debt := v_marg_marge;
         v_margeperc_cred := v_margeperc_sub;
      else
         v_margeperc_debt := v_margeperc_sub;
         v_margeperc_cred := v_marg_marge;
      end if;

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(i_muntsoort, i_rentebasisnummer_debt, v_marg_ingangsdatum,
                                                      v_dummy_datum, v_basisrenteperc_debt, v_basisrenteopslag_debt);

      v_basis_opslag_debt := v_basisrenteperc_debt + v_basisrenteopslag_debt;

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(i_muntsoort, i_rentebasisnummer_cred, v_marg_ingangsdatum,
                                                      v_dummy_datum, v_basisrenteperc_cred, v_basisrenteopslag_cred);

      v_basis_opslag_cred := v_basisrenteperc_cred + v_basisrenteopslag_cred;

      ONDERHOUD_RENTETABELLEN.vul_rente_perc_afspraak(i_muntsoort, i_afspraaknummer, v_marg_ingangsdatum,
                                                      v_basis_opslag_debt, v_margeperc_debt, v_basis_opslag_cred,
                                                      v_margeperc_cred);
    end loop;
    close ms;
END opbouw_RPA_obv_marges_standen;

--
--  Deze procedure bouwt de RENTE_PERC_AFSPRAAK tabel op.
--
PROCEDURE opbouw_rente_perc_afspraak
   (i_muntsoort                     in      re_interest_agreement.inag_muntsoort%type
   ,i_afspraaknummer                in      re_interest_agreement.inag_nummer%type
   ,i_aanmaken_vanaf_datum          in      re_interest_agreement.inag_ingangsdatum%type
   ,i_aanmaken_tm_datum             in      re_interest_agreement.inag_ingangsdatum%type)
AS
 v_inag_nummer      re_interest_agreement.inag_nummer%type;
 v_inag_muntsoort           re_interest_agreement.inag_muntsoort%type;
 v_inag_omschrijving        re_interest_agreement.inag_omschrijving%type;
 v_inag_debet_rente         re_interest_agreement.inag_debet_rente%type;
 v_inag_credit_rente        re_interest_agreement.inag_credit_rente%type;
 v_inag_berekeningsmethod   re_interest_agreement.inag_berekeningsmethod%type;
 v_inag_frequentie          re_interest_agreement.inag_frequentie%type;
 v_inag_ingangsdatum        re_interest_agreement.inag_ingangsdatum%type;
 v_dummy_rentepercentage    re_interest_base_perc.inbp_basis%type;
 v_startdatum_rentebasis    re_interest_agreement.inag_ingangsdatum%type;
 v_startdatum_rentemarge    re_interest_agreement.inag_ingangsdatum%type;

 cursor rt1 is
       select inag_nummer
,             inag_muntsoort
,             inag_omschrijving
,             inag_debet_rente
,             inag_credit_rente
,             inag_berekeningsmethod
,             inag_frequentie
,             inag_ingangsdatum
       from   re_interest_agreement_vw;

 cursor rt2 is
       select inag_nummer
,             inag_muntsoort
,             inag_omschrijving
,             inag_debet_rente
,             inag_credit_rente
,             inag_berekeningsmethod
,             inag_frequentie
,             inag_ingangsdatum
       from   re_interest_agreement_vw
       where  inag_muntsoort = i_muntsoort;

 cursor rt3 is
       select inag_nummer
,             inag_muntsoort
,             inag_omschrijving
,             inag_debet_rente
,             inag_credit_rente
,             inag_berekeningsmethod
,             inag_frequentie
,             inag_ingangsdatum
       from   re_interest_agreement_vw
       where  inag_nummer = i_afspraaknummer;

 cursor rt4 is
       select inag_nummer
,             inag_muntsoort
,             inag_omschrijving
,             inag_debet_rente
,             inag_credit_rente
,             inag_berekeningsmethod
,             inag_frequentie
,             inag_ingangsdatum
       from   re_interest_agreement_vw
       where  inag_muntsoort = i_muntsoort
         and  inag_nummer = i_afspraaknummer;

BEGIN
    case
      when i_muntsoort = ' ' and i_afspraaknummer = 0 then
        BEGIN
          open rt1;
          loop
            fetch rt1 into v_inag_nummer
,                          v_inag_muntsoort
,                          v_inag_omschrijving
,                          v_inag_debet_rente
,                          v_inag_credit_rente
,                          v_inag_berekeningsmethod
,                          v_inag_frequentie
,                          v_inag_ingangsdatum;
            exit when rt1%notfound;

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(v_inag_muntsoort, v_inag_debet_rente, i_aanmaken_vanaf_datum,
                                                            v_startdatum_rentebasis, v_dummy_rentepercentage,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_rentebasisperc(v_inag_muntsoort, v_inag_nummer, v_inag_debet_rente,
                                                                  v_inag_credit_rente, 1, v_startdatum_rentebasis,
                                                                  i_aanmaken_tm_datum);

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(v_inag_muntsoort, v_inag_credit_rente, i_aanmaken_vanaf_datum,
                                                            v_startdatum_rentebasis, v_dummy_rentepercentage,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_rentebasisperc(v_inag_muntsoort, v_inag_nummer, v_inag_credit_rente,
                                                                  v_inag_debet_rente, 0, v_startdatum_rentebasis,
                                                                  i_aanmaken_tm_datum);

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge(v_inag_muntsoort, v_inag_nummer, 'DEBT',
                                                            i_aanmaken_vanaf_datum, v_startdatum_rentemarge,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_marges_standen(v_inag_muntsoort, v_inag_nummer, 'DEBT', v_inag_debet_rente,
                                                                  v_inag_credit_rente, v_startdatum_rentemarge,
                                                                  i_aanmaken_tm_datum);

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge(v_inag_muntsoort, v_inag_nummer, 'CRED',
                                                            i_aanmaken_vanaf_datum, v_startdatum_rentemarge,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_marges_standen(v_inag_muntsoort, v_inag_nummer, 'CRED', v_inag_debet_rente,
                                                                  v_inag_credit_rente, v_startdatum_rentemarge,
                                                                  i_aanmaken_tm_datum);
          end loop;
          close rt1;
        END;
      when i_muntsoort <> ' ' and i_afspraaknummer = 0 then
        BEGIN
          open rt2;
          loop
            fetch rt2 into v_inag_nummer
,                          v_inag_muntsoort
,                          v_inag_omschrijving
,                          v_inag_debet_rente
,                          v_inag_credit_rente
,                          v_inag_berekeningsmethod
,                          v_inag_frequentie
,                          v_inag_ingangsdatum;
            exit when rt2%notfound;

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(v_inag_muntsoort, v_inag_debet_rente, i_aanmaken_vanaf_datum,
                                                            v_startdatum_rentebasis, v_dummy_rentepercentage,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_rentebasisperc(v_inag_muntsoort, v_inag_nummer, v_inag_debet_rente,
                                                                  v_inag_credit_rente, 1, v_startdatum_rentebasis,
                                                                  i_aanmaken_tm_datum);

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(v_inag_muntsoort, v_inag_credit_rente, i_aanmaken_vanaf_datum,
                                                            v_startdatum_rentebasis, v_dummy_rentepercentage,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_rentebasisperc(v_inag_muntsoort, v_inag_nummer, v_inag_credit_rente,
                                                                  v_inag_debet_rente, 0, v_startdatum_rentebasis,
                                                                  i_aanmaken_tm_datum);

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge(v_inag_muntsoort, v_inag_nummer, 'DEBT',
                                                            i_aanmaken_vanaf_datum, v_startdatum_rentemarge,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_marges_standen(v_inag_muntsoort, v_inag_nummer, 'DEBT', v_inag_debet_rente,
                                                                  v_inag_credit_rente, v_startdatum_rentemarge,
                                                                  i_aanmaken_tm_datum);

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge(v_inag_muntsoort, v_inag_nummer, 'CRED',
                                                            i_aanmaken_vanaf_datum, v_startdatum_rentemarge,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_marges_standen(v_inag_muntsoort, v_inag_nummer, 'CRED', v_inag_debet_rente,
                                                                  v_inag_credit_rente, v_startdatum_rentemarge,
                                                                  i_aanmaken_tm_datum);
          end loop;
          close rt2;
        END;
      when i_muntsoort = ' ' and i_afspraaknummer <> 0 then
        BEGIN
          open rt3;
          loop
            fetch rt3 into v_inag_nummer
,                          v_inag_muntsoort
,                          v_inag_omschrijving
,                          v_inag_debet_rente
,                          v_inag_credit_rente
,                          v_inag_berekeningsmethod
,                          v_inag_frequentie
,                          v_inag_ingangsdatum;
            exit when rt3%notfound;

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(v_inag_muntsoort, v_inag_debet_rente, i_aanmaken_vanaf_datum,
                                                            v_startdatum_rentebasis, v_dummy_rentepercentage,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_rentebasisperc(v_inag_muntsoort, v_inag_nummer, v_inag_debet_rente,
                                                                  v_inag_credit_rente, 1, v_startdatum_rentebasis,
                                                                  i_aanmaken_tm_datum);

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(v_inag_muntsoort, v_inag_credit_rente, i_aanmaken_vanaf_datum,
                                                            v_startdatum_rentebasis, v_dummy_rentepercentage,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_rentebasisperc(v_inag_muntsoort, v_inag_nummer, v_inag_credit_rente,
                                                                  v_inag_debet_rente, 0, v_startdatum_rentebasis,
                                                                  i_aanmaken_tm_datum);

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge(v_inag_muntsoort, v_inag_nummer, 'DEBT',
                                                            i_aanmaken_vanaf_datum, v_startdatum_rentemarge,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_marges_standen(v_inag_muntsoort, v_inag_nummer, 'DEBT', v_inag_debet_rente,
                                                                  v_inag_credit_rente, v_startdatum_rentemarge,
                                                                  i_aanmaken_tm_datum);

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge(v_inag_muntsoort, v_inag_nummer, 'CRED',
                                                            i_aanmaken_vanaf_datum, v_startdatum_rentemarge,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_marges_standen(v_inag_muntsoort, v_inag_nummer, 'CRED', v_inag_debet_rente,
                                                                  v_inag_credit_rente, v_startdatum_rentemarge,
                                                                  i_aanmaken_tm_datum);
          end loop;
          close rt3;
        END;
      when i_muntsoort <> ' ' and i_afspraaknummer <> 0 then
        BEGIN
          open rt4;
          loop
            fetch rt4 into v_inag_nummer
,                          v_inag_muntsoort
,                          v_inag_omschrijving
,                          v_inag_debet_rente
,                          v_inag_credit_rente
,                          v_inag_berekeningsmethod
,                          v_inag_frequentie
,                          v_inag_ingangsdatum;
            exit when rt4%notfound;

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(v_inag_muntsoort, v_inag_debet_rente, i_aanmaken_vanaf_datum,
                                                            v_startdatum_rentebasis, v_dummy_rentepercentage,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_rentebasisperc(v_inag_muntsoort, v_inag_nummer, v_inag_debet_rente,
                                                                  v_inag_credit_rente, 1, v_startdatum_rentebasis,
                                                                  i_aanmaken_tm_datum);

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(v_inag_muntsoort, v_inag_credit_rente, i_aanmaken_vanaf_datum,
                                                            v_startdatum_rentebasis, v_dummy_rentepercentage,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_rentebasisperc(v_inag_muntsoort, v_inag_nummer, v_inag_credit_rente,
                                                                  v_inag_debet_rente, 0, v_startdatum_rentebasis,
                                                                  i_aanmaken_tm_datum);

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge(v_inag_muntsoort, v_inag_nummer, 'DEBT',
                                                            i_aanmaken_vanaf_datum, v_startdatum_rentemarge,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_marges_standen(v_inag_muntsoort, v_inag_nummer, 'DEBT', v_inag_debet_rente,
                                                                  v_inag_credit_rente, v_startdatum_rentemarge,
                                                                  i_aanmaken_tm_datum);

            ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge(v_inag_muntsoort, v_inag_nummer, 'CRED',
                                                            i_aanmaken_vanaf_datum, v_startdatum_rentemarge,
                                                            v_dummy_rentepercentage);

            ONDERHOUD_RENTETABELLEN.opbouw_RPA_obv_marges_standen(v_inag_muntsoort, v_inag_nummer, 'CRED', v_inag_debet_rente,
                                                                  v_inag_credit_rente, v_startdatum_rentemarge,
                                                                  i_aanmaken_tm_datum);
          end loop;
          close rt4;
        END;
    end case;
END opbouw_rente_perc_afspraak;

--
--  Deze procedure verwijdert records uit de RENTE_PERC_AFSPRAAK tabel.
--
PROCEDURE verwijder_rente_perc_afspraak
   (i_muntsoort                     in      re_interest_agreement.inag_muntsoort%type
   ,i_afspraaknummer                in      re_interest_agreement.inag_nummer%type
   ,i_verwijderen_vanaf_datum       in      re_interest_agreement.inag_ingangsdatum%type
   ,i_verwijderen_tm_datum          in      re_interest_agreement.inag_ingangsdatum%type)
AS

BEGIN
    case
      when i_muntsoort  = ' ' and i_afspraaknummer = 0 then
           delete from rente_perc_afspraak
            where rpa_ingangsdatum between i_verwijderen_vanaf_datum and i_verwijderen_tm_datum;
      when i_muntsoort  <> ' ' and i_afspraaknummer = 0 then
           delete from rente_perc_afspraak
            where rpa_muntsoort = i_muntsoort
              and rpa_ingangsdatum between i_verwijderen_vanaf_datum and i_verwijderen_tm_datum;
      when i_muntsoort  = ' ' and i_afspraaknummer <> 0 then
           delete from rente_perc_afspraak
            where rpa_code = i_afspraaknummer
              and rpa_ingangsdatum between i_verwijderen_vanaf_datum and i_verwijderen_tm_datum;
      when i_muntsoort  <> ' ' and i_afspraaknummer <> 0 then
           delete from rente_perc_afspraak
            where rpa_muntsoort = i_muntsoort
              and rpa_code = i_afspraaknummer
              and rpa_ingangsdatum between i_verwijderen_vanaf_datum and i_verwijderen_tm_datum;
    end case;
END verwijder_rente_perc_afspraak;

--
--  Deze procedure initialiseert de RENTE_PERC_AFSPRAAK voor de meegegeven muntsoort en afspraaknummer.
--  Wordt als muntsoort ' ' en als afspraaknummer 0 meegestuurd, dan zullen alle afspraken uit tabel
--  're_interest_agreement' opnieuw worden samengesteld.
--
PROCEDURE init_rente_perc_afspraak
   (i_muntsoort                     in      re_interest_agreement.inag_muntsoort%type
   ,i_afspraaknummer                in      re_interest_agreement.inag_nummer%type)
AS

BEGIN

    ONDERHOUD_RENTETABELLEN.verwijder_rente_perc_afspraak(i_muntsoort,i_afspraaknummer,'00000000','99991231');

    ONDERHOUD_RENTETABELLEN.opbouw_rente_perc_afspraak(i_muntsoort,i_afspraaknummer,'00000000','99991231');

END init_rente_perc_afspraak;

--
--  Deze procedure is voor het bepalen van de eerste ingangsdatum van binnen de RENTE_PERC_SCHAALTARIEF welke
--  VOOR een opgegeven referentiedatum ligt.
--
PROCEDURE bijbehorende_renteschaal
   (i_muntsoort                     in      re_interest_scale_dtl.insd_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_dtl.insd_code%type
   ,i_referentiedatum               in      re_interest_scale_dtl.insd_ingangsdatum%type
   ,i_type_debt_cred                in      re_interest_scale_dtl.insd_type_credit_debet%type
   ,i_1_schaalbedrag_gebruiken      in      number
   ,i_schaalbedrag                  in      re_interest_scale_dtl.insd_bedrag_vanaf%type
   ,o_ingangsdatum_renteschaal      out     re_interest_scale_dtl.insd_ingangsdatum%type)
AS

 v_ingangsdatum_renteschaal  re_interest_scale_dtl.insd_ingangsdatum%type;

  cursor sd1 is
     select insd_ingangsdatum
       from re_interest_scale_dtl_vw
      where insd_muntsoort = i_muntsoort
        and insd_code = i_schaalcode
        and insd_ingangsdatum <= i_referentiedatum
      order by insd_ingangsdatum desc;

 cursor sd2 is
     select insd_ingangsdatum
       from re_interest_scale_dtl_vw
      where insd_muntsoort = i_muntsoort
        and insd_code = i_schaalcode
        and insd_type_credit_debet = i_type_debt_cred
        and insd_ingangsdatum <= i_referentiedatum
      order by insd_ingangsdatum desc;

 cursor sd3 is
     select insd_ingangsdatum
       from re_interest_scale_dtl_vw
      where insd_muntsoort = i_muntsoort
        and insd_code = i_schaalcode
        and insd_bedrag_vanaf = i_schaalbedrag
        and insd_ingangsdatum <= i_referentiedatum
      order by insd_ingangsdatum desc;

 cursor sd4 is
     select insd_ingangsdatum
       from re_interest_scale_dtl_vw
      where insd_muntsoort = i_muntsoort
        and insd_code = i_schaalcode
        and insd_type_credit_debet = i_type_debt_cred
        and insd_bedrag_vanaf = i_schaalbedrag
        and insd_ingangsdatum <= i_referentiedatum
      order by insd_ingangsdatum desc;

BEGIN
   case
      when i_type_debt_cred = ' ' and i_1_schaalbedrag_gebruiken = 0 then
         BEGIN
           open sd1;
           fetch sd1 into v_ingangsdatum_renteschaal;
           if sd1%notfound
              then
                 o_ingangsdatum_renteschaal := '00000000';
              else
                 o_ingangsdatum_renteschaal := v_ingangsdatum_renteschaal;
           end if;
           close sd1;
         END;
      when i_type_debt_cred <> ' ' and i_1_schaalbedrag_gebruiken = 0 then
         BEGIN
           open sd2;
           fetch sd2 into v_ingangsdatum_renteschaal;
           if sd2%notfound
              then
                 o_ingangsdatum_renteschaal := '00000000';
              else
                 o_ingangsdatum_renteschaal := v_ingangsdatum_renteschaal;
           end if;
           close sd2;
         END;
      when i_type_debt_cred = ' ' and i_1_schaalbedrag_gebruiken <> 0 then
         BEGIN
           open sd3;
           fetch sd3 into v_ingangsdatum_renteschaal;
           if sd3%notfound
              then
                 o_ingangsdatum_renteschaal := '00000000';
              else
                 o_ingangsdatum_renteschaal := v_ingangsdatum_renteschaal;
           end if;
           close sd3;
         END;
      when i_type_debt_cred <> ' ' and i_1_schaalbedrag_gebruiken <> 0 then
         BEGIN
           open sd4;
           fetch sd4 into v_ingangsdatum_renteschaal;
           if sd4%notfound
              then
                 o_ingangsdatum_renteschaal := '00000000';
              else
                 o_ingangsdatum_renteschaal := v_ingangsdatum_renteschaal;
           end if;
           close sd4;
         END;
     end case;
END bijbehorende_renteschaal;

--
--  Deze procedure is voor het bepalen van de eerste ingangsdatum van binnen de RENTE_PERC_SCHAALTARIEF
--  welke NA een opgegeven referentiedatum ligt.
--
PROCEDURE bijbehorende_renteschaal_NA
   (i_muntsoort                     in      re_interest_scale_dtl.insd_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_dtl.insd_code%type
   ,i_referentiedatum               in      re_interest_scale_dtl.insd_ingangsdatum%type
   ,i_type_debt_cred                in      re_interest_scale_dtl.insd_type_credit_debet%type
   ,i_1_schaalbedrag_gebruiken      in      number
   ,i_schaalbedrag                  in      re_interest_scale_dtl.insd_bedrag_vanaf%type
   ,o_ingangsdatum_renteschaal      out     re_interest_scale_dtl.insd_ingangsdatum%type)
AS

 v_ingangsdatum_renteschaal  re_interest_scale_dtl.insd_ingangsdatum%type;

  cursor sd1 is
     select insd_ingangsdatum
       from re_interest_scale_dtl_vw
      where insd_muntsoort = i_muntsoort
        and insd_code = i_schaalcode
        and insd_ingangsdatum > i_referentiedatum
      order by insd_ingangsdatum asc;

 cursor sd2 is
     select insd_ingangsdatum
       from re_interest_scale_dtl_vw
      where insd_muntsoort = i_muntsoort
        and insd_code = i_schaalcode
        and insd_type_credit_debet = i_type_debt_cred
        and insd_ingangsdatum > i_referentiedatum
      order by insd_ingangsdatum asc;

 cursor sd3 is
     select insd_ingangsdatum
       from re_interest_scale_dtl_vw
      where insd_muntsoort = i_muntsoort
        and insd_code = i_schaalcode
        and insd_bedrag_vanaf = i_schaalbedrag
        and insd_ingangsdatum > i_referentiedatum
      order by insd_ingangsdatum asc;

 cursor sd4 is
     select insd_ingangsdatum
       from re_interest_scale_dtl_vw
      where insd_muntsoort = i_muntsoort
        and insd_code = i_schaalcode
        and insd_type_credit_debet = i_type_debt_cred
        and insd_bedrag_vanaf = i_schaalbedrag
        and insd_ingangsdatum > i_referentiedatum
      order by insd_ingangsdatum asc;

BEGIN
   case
      when i_type_debt_cred = ' ' and i_1_schaalbedrag_gebruiken = 0 then
         BEGIN
           open sd1;
           fetch sd1 into v_ingangsdatum_renteschaal;
           if sd1%notfound
              then
                 o_ingangsdatum_renteschaal := '99991231';
              else
                 o_ingangsdatum_renteschaal := v_ingangsdatum_renteschaal;
           end if;
           close sd1;
         END;
      when i_type_debt_cred <> ' ' and i_1_schaalbedrag_gebruiken = 0 then
         BEGIN
           open sd2;
           fetch sd2 into v_ingangsdatum_renteschaal;
           if sd2%notfound
              then
                 o_ingangsdatum_renteschaal := '99991231';
              else
                 o_ingangsdatum_renteschaal := v_ingangsdatum_renteschaal;
           end if;
           close sd2;
         END;
      when i_type_debt_cred = ' ' and i_1_schaalbedrag_gebruiken <> 0 then
         BEGIN
           open sd3;
           fetch sd3 into v_ingangsdatum_renteschaal;
           if sd3%notfound
              then
                 o_ingangsdatum_renteschaal := '99991231';
              else
                 o_ingangsdatum_renteschaal := v_ingangsdatum_renteschaal;
           end if;
           close sd3;
         END;
      when i_type_debt_cred <> ' ' and i_1_schaalbedrag_gebruiken <> 0 then
         BEGIN
           open sd4;
           fetch sd4 into v_ingangsdatum_renteschaal;
           if sd4%notfound
              then
                 o_ingangsdatum_renteschaal := '99991231';
              else
                 o_ingangsdatum_renteschaal := v_ingangsdatum_renteschaal;
           end if;
           close sd4;
         END;
     end case;
END bijbehorende_renteschaal_NA;


--
--  Deze procedure is voor het bepalen van de eerste ingangsdatum met behulp van de schalen_HEADER tabel
--  welke VOOR een opgegeven referentiedatum ligt.
--
PROCEDURE bijbeh_renteschaal_HDR
   (i_muntsoort                     in      re_interest_scale_hdr.insh_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_hdr.insh_code%type
   ,i_referentiedatum               in      re_interest_scale_hdr.insh_ingangsdatum%type
   ,o_ingangsdatum_renteschaal      out     re_interest_scale_hdr.insh_ingangsdatum%type)
AS

 v_ingangsdatum_renteschaal  re_interest_scale_hdr.insh_ingangsdatum%type;

 cursor sh is
     select insh_ingangsdatum
       from re_interest_scale_hdr_vw
      where insh_muntsoort = i_muntsoort
        and insh_code = i_schaalcode
        and insh_ingangsdatum <= i_referentiedatum
      order by insh_ingangsdatum desc;

BEGIN
    open sh;
    fetch sh into v_ingangsdatum_renteschaal;
    if sh%notfound
    then
       o_ingangsdatum_renteschaal := '00000000';
    else
       o_ingangsdatum_renteschaal := v_ingangsdatum_renteschaal;
    end if;
    close sh;
END bijbeh_renteschaal_HDR;

--
--  Deze procedure is voor het bepalen van de eerste ingangsdatum met behulp van de schalen_HEADER tabel
--  welke NA een opgegeven referentiedatum ligt.
--
PROCEDURE bijbeh_renteschaal_HDR_NA
   (i_muntsoort                     in      re_interest_scale_hdr.insh_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_hdr.insh_code%type
   ,i_referentiedatum               in      re_interest_scale_hdr.insh_ingangsdatum%type
   ,o_ingangsdatum_renteschaal      out     re_interest_scale_hdr.insh_ingangsdatum%type)
AS

 v_ingangsdatum_renteschaal  re_interest_scale_hdr.insh_ingangsdatum%type;

 cursor sh is
     select insh_ingangsdatum
       from re_interest_scale_hdr_vw
      where insh_muntsoort = i_muntsoort
        and insh_code = i_schaalcode
        and insh_ingangsdatum > i_referentiedatum
      order by insh_ingangsdatum asc;

BEGIN
    open sh;
    fetch sh into v_ingangsdatum_renteschaal;
    if sh%notfound
    then
       o_ingangsdatum_renteschaal := '99991231';
    else
       o_ingangsdatum_renteschaal := v_ingangsdatum_renteschaal;
    end if;
    close sh;
END bijbeh_renteschaal_HDR_NA;

--
--   Procedure voor het aanmaken van een record in tabel RENTE_PERC_SCHAALTARIEF.
--   Bestaat het record al, dan worden de 'percentage kolommen' van dit record ge-update.
--
PROCEDURE vul_rente_perc_schaaltarief
   (i_muntsoort                     in      rente_perc_schaaltarief.rps_muntsoort%type
   ,i_schaalcode                    in      rente_perc_schaaltarief.rps_code%type
   ,i_debet_credit_indicator        in      rente_perc_schaaltarief.rps_debet_credit_indicator%type
   ,i_SD_Bedrag_vanaf               in      rente_perc_schaaltarief.rps_schaalbedrag%type
   ,i_max_ingangsdatum              in      rente_perc_schaaltarief.rps_valutadatum%type
   ,i_rente_marge                   in      rente_perc_schaaltarief.rps_rente_marge%type
   ,i_basis_opslag                  in      rente_perc_schaaltarief.rps_basis_opslag%type)
AS

  v_aantal_gevonden number;

BEGIN
--
--  Onderstaande
--    merge into rente_perc_schaaltarief rps
--    using (select 1 from DUAL)
--       on (rps.rps_muntsoort = i_muntsoort
--      and  rps.rps_code = i_schaalcode
--      and  rps.rps_debet_credit_indicator = i_debet_credit_indicator
--      and  rps.rps_schaalbedrag = ABS(i_SD_Bedrag_vanaf)
--      and  rps.rps_valutadatum = i_max_ingangsdatum)
--     when matched then
--          update set rps.rps_rente_marge = i_rente_marge
--,                    rps.rps_basis_opslag = i_basis_opslag
--     when not matched then
--          insert (rps.rps_muntsoort
--,                 rps.rps_code
--,                 rps.rps_debet_credit_indicator
--,                 rps.rps_schaalbedrag
--,                 rps.rps_valutadatum
--,                 rps.rps_rente_marge
--,                 rps.rps_basis_opslag)
--          values (i_muntsoort
--,                 i_schaalcode
--,                 i_debet_credit_indicator
--,                 ABS(i_SD_Bedrag_vanaf)
--,                 i_max_ingangsdatum
--,                 i_rente_marge
--,                 i_basis_opslag);
--
    v_aantal_gevonden := 0;

    select count(*) into v_aantal_gevonden
      from rente_perc_schaaltarief rps
     where rps.rps_muntsoort = i_muntsoort
       and rps.rps_code = i_schaalcode
       and rps.rps_debet_credit_indicator = i_debet_credit_indicator
       and rps.rps_schaalbedrag = ABS(i_SD_Bedrag_vanaf)
       and rps.rps_valutadatum = i_max_ingangsdatum;

    if v_aantal_gevonden > 0 then
       update rente_perc_schaaltarief rps
          set rps.rps_rente_marge = i_rente_marge
,             rps.rps_basis_opslag = i_basis_opslag
        where rps.rps_muntsoort = i_muntsoort
          and rps.rps_code = i_schaalcode
          and rps.rps_debet_credit_indicator = i_debet_credit_indicator
          and rps.rps_schaalbedrag = ABS(i_SD_Bedrag_vanaf)
          and rps.rps_valutadatum = i_max_ingangsdatum;
    else
       insert into rente_perc_schaaltarief rps
             (rps.rps_muntsoort
,             rps.rps_code
,             rps.rps_debet_credit_indicator
,             rps.rps_schaalbedrag
,             rps.rps_valutadatum
,             rps.rps_rente_marge
,             rps.rps_basis_opslag)
      values (i_muntsoort
,             i_schaalcode
,             i_debet_credit_indicator
,             ABS(i_SD_Bedrag_vanaf)
,             i_max_ingangsdatum
,             i_rente_marge
,             i_basis_opslag);
    end if;

END vul_rente_perc_schaaltarief;

--
-- Deel 3 van de procedure voor de opbouw van de 'RENTE_PERC_SCHAALTARIEF' tabel.
-- Hierin wordt per re_interest_base_perc een record toegevoegd/geupdate.
--
PROCEDURE opb_rente_perc_schaaltrf_st3
   (i_insh_muntsoort                in      re_interest_scale_hdr.insh_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_dtl.insd_code%type
   ,i_insd_basistarief              in      re_interest_scale_dtl.insd_basistarief%type
   ,i_startdatum_rentebasis         in      re_interest_scale_dtl.insd_ingangsdatum%type
   ,i_einddatum_rentebasis          in      re_interest_scale_dtl.insd_ingangsdatum%type
   ,i_debet_credit_indicator        in      rente_perc_schaaltarief.rps_debet_credit_indicator%type
   ,i_SD_bedrag_vanaf               in      re_interest_scale_dtl.insd_bedrag_vanaf%type
   ,i_insd_rentemarge               in      rente_perc_schaaltarief.rps_rente_marge%type
   ,i_insd_ingangsdatum             in      re_interest_scale_dtl.insd_ingangsdatum%type)
AS

 v_inbp_muntsoort  re_interest_base_perc_hdr.inbph_currency%type;
 v_inbp_nummer           re_interest_base_perc_hdr.inbph_number%type;
 v_inbp_ingangsdatum     re_interest_base_perc.inbp_ingangsdatum%type;
 v_inbp_basis            re_interest_base_perc.inbp_basis%type;
 v_inbp_opslag           re_interest_base_perc.inbp_opslag%type;
 v_max_ingangsdatum      re_interest_scale_dtl.insd_ingangsdatum%type;
 v_rps_basis_opslag      rente_perc_schaaltarief.rps_basis_opslag%type;

 cursor rbp is
     select inbp_muntsoort
,           inbp_nummer
,           inbp_ingangsdatum
,           inbp_basis
,           inbp_opslag
       from re_interest_base_perc_vw
      where inbp_muntsoort = i_insh_muntsoort
        and inbp_nummer = i_insd_basistarief
        and inbp_ingangsdatum between i_startdatum_rentebasis and i_einddatum_rentebasis;

BEGIN
    open rbp;
    loop
      fetch rbp into v_inbp_muntsoort
,                    v_inbp_nummer
,                    v_inbp_ingangsdatum
,                    v_inbp_basis
,                    v_inbp_opslag;
      exit when rbp%notfound;

      if i_insd_ingangsdatum > v_inbp_ingangsdatum then
         v_max_ingangsdatum := i_insd_ingangsdatum;
      else
         v_max_ingangsdatum := v_inbp_ingangsdatum;
      end if;

      v_rps_basis_opslag := v_inbp_basis + v_inbp_opslag;

      ONDERHOUD_RENTETABELLEN.vul_rente_perc_schaaltarief(v_inbp_muntsoort, i_schaalcode, i_debet_credit_indicator,
                                                          i_SD_bedrag_vanaf, v_max_ingangsdatum, i_insd_rentemarge,
                                                          v_rps_basis_opslag);
    end loop;
    close rbp;

    -- zodra i_startdatum_rentebasis='00000000', dan betekent dit dat er geen basispercentage
    -- is gevonden op of voor i_insd_ingangsdatum, om toch op deze ingangsdatum van een schaaltarief
    -- alle schaalbedragen in RENTE_PERC_SCHAALTARIEF op te nemen wordt dit record alsnog toegevoegd.
    if i_startdatum_rentebasis ='00000000' then
      ONDERHOUD_RENTETABELLEN.vul_rente_perc_schaaltarief(i_insh_muntsoort, i_schaalcode, i_debet_credit_indicator,
                                                          i_SD_bedrag_vanaf, i_insd_ingangsdatum, i_insd_rentemarge,
                                                          0);
    end if;


END opb_rente_perc_schaaltrf_st3;

--
-- Deel 2 van de procedure voor de opbouw van de 'RENTE_PERC_SCHAALTARIEF' tabel.
-- Hierin wordt door de schalen details heen gelopen, waarbij per record deel 3
-- van de procedure(zie hierboven) wordt aangeroepen.
--
PROCEDURE opb_rente_perc_schaaltrf_st2
   (i_muntsoort                     in re_interest_scale_dtl.insd_muntsoort%type
   ,i_schaalcode                    in re_interest_scale_dtl.insd_code%type
   ,i_type_debt_cred                in re_interest_scale_dtl.insd_type_credit_debet%type
   ,i_1_schaalbedrag_gebruiken      in number
   ,i_startdatum_renteschaal        in re_interest_scale_hdr.insh_ingangsdatum%type
   ,i_aanmaken_tm_datum             in re_interest_scale_dtl.insd_ingangsdatum%type
   ,i_schaalbedrag                  in re_interest_scale_dtl.insd_bedrag_vanaf%type)
AS

 v_insd_muntsoort           re_interest_scale_dtl.insd_muntsoort%type;
 v_insd_code                re_interest_scale_dtl.insd_code%type;
 v_insd_bedrag_vanaf        re_interest_scale_dtl.insd_bedrag_vanaf%type;
 v_insd_basistarief         re_interest_scale_dtl.insd_basistarief%type;
 v_insd_ingangsdatum        re_interest_scale_dtl.insd_ingangsdatum%type;
 v_insd_type_credit_debet   re_interest_scale_dtl.insd_type_credit_debet%type;
 v_insd_rentemarge          re_interest_scale_dtl.insd_rentemarge%type;
 v_startdatum_rentebasis    re_interest_base_perc.inbp_ingangsdatum%type;
 v_dummy_rentepercentage    re_interest_base_perc.inbp_ingangsdatum%type;
 v_einddatum_rentebasis     re_interest_scale_dtl.insd_ingangsdatum%type;
 v_vorige_insd_ingangsdatum re_interest_scale_dtl.insd_ingangsdatum%type;

  cursor sd1 is
     select insd_muntsoort
,           insd_code
,           insd_bedrag_vanaf
,           insd_basistarief
,           insd_ingangsdatum
,           insd_type_credit_debet
,           insd_rentemarge
       from re_interest_scale_dtl_vw
      where insd_muntsoort = i_muntsoort
        and insd_code = i_schaalcode
        and insd_ingangsdatum between i_startdatum_renteschaal and i_aanmaken_tm_datum
      order by insd_ingangsdatum desc
,              insd_type_credit_debet asc
,              insd_bedrag_vanaf asc;

 cursor sd2 is
     select insd_muntsoort
,           insd_code
,           insd_bedrag_vanaf
,           insd_basistarief
,           insd_ingangsdatum
,           insd_type_credit_debet
,           insd_rentemarge
       from re_interest_scale_dtl_vw
      where insd_muntsoort = i_muntsoort
        and insd_code = i_schaalcode
        and insd_type_credit_debet = i_type_debt_cred
        and insd_ingangsdatum between i_startdatum_renteschaal and i_aanmaken_tm_datum
      order by insd_ingangsdatum desc
,              insd_type_credit_debet asc
,              insd_bedrag_vanaf asc;

 cursor sd3 is
     select insd_muntsoort
,           insd_code
,           insd_bedrag_vanaf
,           insd_basistarief
,           insd_ingangsdatum
,           insd_type_credit_debet
,           insd_rentemarge
       from re_interest_scale_dtl_vw
      where insd_muntsoort = i_muntsoort
        and insd_code = i_schaalcode
        and insd_bedrag_vanaf = i_schaalbedrag
        and insd_ingangsdatum between i_startdatum_renteschaal and i_aanmaken_tm_datum
      order by insd_ingangsdatum desc
,              insd_type_credit_debet asc
,              insd_bedrag_vanaf asc;

 cursor sd4 is
     select insd_muntsoort
,           insd_code
,           insd_bedrag_vanaf
,           insd_basistarief
,           insd_ingangsdatum
,           insd_type_credit_debet
,           insd_rentemarge
       from re_interest_scale_dtl_vw
      where insd_muntsoort = i_muntsoort
        and insd_code = i_schaalcode
        and insd_type_credit_debet = i_type_debt_cred
        and insd_bedrag_vanaf = i_schaalbedrag
        and insd_ingangsdatum between i_startdatum_renteschaal and i_aanmaken_tm_datum
      order by insd_ingangsdatum desc
,              insd_type_credit_debet asc
,              insd_bedrag_vanaf asc;

BEGIN

    case
      when i_type_debt_cred = ' ' and i_1_schaalbedrag_gebruiken = 0 then
         BEGIN
           open sd1;
           loop
             fetch sd1 into v_insd_muntsoort
,                           v_insd_code
,                           v_insd_bedrag_vanaf
,                           v_insd_basistarief
,                           v_insd_ingangsdatum
,                           v_insd_type_credit_debet
,                           v_insd_rentemarge;
             exit when sd1%notfound;

             ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(v_insd_muntsoort, v_insd_basistarief,
                                                             v_insd_ingangsdatum, v_startdatum_rentebasis,
                                                             v_dummy_rentepercentage, v_dummy_rentepercentage);

--           Bepaal de vorige_insd_ingangsdatum. Omdat we descending door de ingangsdata van de schalen lopen,
--           bepalen we dus de eerste ingangsdatum NA de huidige ingangsdatum.
             ONDERHOUD_RENTETABELLEN.bijbehorende_renteschaal_NA(v_insd_muntsoort, v_insd_code, v_insd_ingangsdatum,
                                                                 v_insd_type_credit_debet,0,0,
                                                                 v_vorige_insd_ingangsdatum);

             v_einddatum_rentebasis := to_char(to_date(v_vorige_insd_ingangsdatum,'YYYYMMDD')-1,'YYYYMMDD');

             ONDERHOUD_RENTETABELLEN.opb_rente_perc_schaaltrf_st3(v_insd_muntsoort, v_insd_code, v_insd_basistarief,
                                                                  v_startdatum_rentebasis, v_einddatum_rentebasis,
                                                                  v_insd_type_credit_debet, v_insd_bedrag_vanaf, v_insd_rentemarge,
                                                                  v_insd_ingangsdatum);
           end loop;
           close sd1;
         END;
      when i_type_debt_cred <> ' ' and i_1_schaalbedrag_gebruiken = 0 then
         BEGIN
           open sd2;
           loop
             fetch sd2 into v_insd_muntsoort
,                           v_insd_code
,                           v_insd_bedrag_vanaf
,                           v_insd_basistarief
,                           v_insd_ingangsdatum
,                           v_insd_type_credit_debet
,                           v_insd_rentemarge;
             exit when sd2%notfound;

             ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(v_insd_muntsoort, v_insd_basistarief,
                                                             v_insd_ingangsdatum, v_startdatum_rentebasis,
                                                             v_dummy_rentepercentage, v_dummy_rentepercentage);

--           Bepaal de vorige_insd_ingangsdatum. Omdat we descending door de ingangsdata van de schalen lopen,
--           bepalen we dus de eerste ingangsdatum NA de huidige ingangsdatum.
             ONDERHOUD_RENTETABELLEN.bijbehorende_renteschaal_NA(v_insd_muntsoort, v_insd_code, v_insd_ingangsdatum,
                                                                 v_insd_type_credit_debet,0,0,
                                                                 v_vorige_insd_ingangsdatum);

             v_einddatum_rentebasis := to_char(to_date(v_vorige_insd_ingangsdatum,'YYYYMMDD')-1,'YYYYMMDD');

             ONDERHOUD_RENTETABELLEN.opb_rente_perc_schaaltrf_st3(v_insd_muntsoort, v_insd_code, v_insd_basistarief,
                                                                  v_startdatum_rentebasis, v_einddatum_rentebasis,
                                                                  v_insd_type_credit_debet, v_insd_bedrag_vanaf, v_insd_rentemarge,
                                                                  v_insd_ingangsdatum);
           end loop;
           close sd2;
         END;
      when i_type_debt_cred = ' ' and i_1_schaalbedrag_gebruiken <> 0 then
         BEGIN
           open sd3;
           loop
             fetch sd3 into v_insd_muntsoort
,                           v_insd_code
,                           v_insd_bedrag_vanaf
,                           v_insd_basistarief
,                           v_insd_ingangsdatum
,                           v_insd_type_credit_debet
,                           v_insd_rentemarge;
             exit when sd3%notfound;

             ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(v_insd_muntsoort, v_insd_basistarief,
                                                             v_insd_ingangsdatum, v_startdatum_rentebasis,
                                                             v_dummy_rentepercentage, v_dummy_rentepercentage);

--           Bepaal de vorige_insd_ingangsdatum. Omdat we descending door de ingangsdata van de schalen lopen,
--           bepalen we dus de eerste ingangsdatum NA de huidige ingangsdatum.
             ONDERHOUD_RENTETABELLEN.bijbehorende_renteschaal_NA(v_insd_muntsoort, v_insd_code, v_insd_ingangsdatum,
                                                                 v_insd_type_credit_debet,0,0,
                                                                 v_vorige_insd_ingangsdatum);

             v_einddatum_rentebasis := to_char(to_date(v_vorige_insd_ingangsdatum,'YYYYMMDD')-1,'YYYYMMDD');

             ONDERHOUD_RENTETABELLEN.opb_rente_perc_schaaltrf_st3(v_insd_muntsoort, v_insd_code, v_insd_basistarief,
                                                                  v_startdatum_rentebasis, v_einddatum_rentebasis,
                                                                  v_insd_type_credit_debet, v_insd_bedrag_vanaf, v_insd_rentemarge,
                                                                  v_insd_ingangsdatum);
           end loop;
           close sd3;
         END;
      when i_type_debt_cred <> ' ' and i_1_schaalbedrag_gebruiken <> 0 then
         BEGIN
           open sd4;
           loop
             fetch sd4 into v_insd_muntsoort
,                           v_insd_code
,                           v_insd_bedrag_vanaf
,                           v_insd_basistarief
,                           v_insd_ingangsdatum
,                           v_insd_type_credit_debet
,                           v_insd_rentemarge;
             exit when sd4%notfound;

             ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(v_insd_muntsoort, v_insd_basistarief,
                                                             v_insd_ingangsdatum, v_startdatum_rentebasis,
                                                             v_dummy_rentepercentage, v_dummy_rentepercentage);

--           Bepaal de vorige_insd_ingangsdatum. Omdat we descending door de ingangsdata van de schalen lopen,
--           bepalen we dus de eerste ingangsdatum NA de huidige ingangsdatum.
             ONDERHOUD_RENTETABELLEN.bijbehorende_renteschaal_NA(v_insd_muntsoort, v_insd_code, v_insd_ingangsdatum,
                                                                 v_insd_type_credit_debet,0,0,
                                                                 v_vorige_insd_ingangsdatum);

             v_einddatum_rentebasis := to_char(to_date(v_vorige_insd_ingangsdatum,'YYYYMMDD')-1,'YYYYMMDD');

             ONDERHOUD_RENTETABELLEN.opb_rente_perc_schaaltrf_st3(v_insd_muntsoort, v_insd_code, v_insd_basistarief,
                                                                  v_startdatum_rentebasis, v_einddatum_rentebasis,
                                                                  v_insd_type_credit_debet, v_insd_bedrag_vanaf, v_insd_rentemarge,
                                                                  v_insd_ingangsdatum);
           end loop;
           close sd4;
         END;
    end case;
END opb_rente_perc_schaaltrf_st2;

--
--  Deze procedure is voor het opbouwen van de tabel 'RENTE_PERC_SCHAALTARIEF'.
--  De totale procedure bestaat uit 3 delen, waarvan deze procedure het begin is.
--
PROCEDURE opbouw_rente_perc_schaaltarief
   (i_muntsoort                in      re_interest_scale_hdr.insh_muntsoort%type
   ,i_schaalcode               in      re_interest_scale_hdr.insh_code%type
   ,i_DEBT_CRED                in      re_interest_scale_dtl.insd_type_credit_debet%type
   ,i_1_schaalbedrag_gebruiken in      number
   ,i_schaalbedrag             in      re_interest_scale_dtl.insd_bedrag_vanaf%type
   ,i_aanmaken_vanaf_datum     in      re_interest_scale_hdr.insh_ingangsdatum%type
   ,i_aanmaken_tm_datum        in      re_interest_scale_dtl.insd_ingangsdatum%type)
AS

 v_insh_muntsoort             re_interest_scale_hdr.insh_muntsoort%type;
 v_insh_code                  re_interest_scale_hdr.insh_code%type;
 v_startdatum_renteschaal     re_interest_scale_hdr.insh_ingangsdatum%type;
 v_einddatum_rentebasis       re_interest_scale_dtl.insd_ingangsdatum%type;
 v_vorige_insd_ingangsdatum   re_interest_scale_dtl.insd_ingangsdatum%type;


 cursor sh1 is
     select insh_muntsoort
,           insh_code
       from re_interest_scale_hdr_vw
      group by insh_muntsoort
,              insh_code;

 cursor sh2 is
     select insh_muntsoort
,           insh_code
       from re_interest_scale_hdr_vw
      where insh_muntsoort = i_muntsoort
      group by insh_muntsoort
,              insh_code;

 cursor sh3 is
     select insh_muntsoort
,           insh_code
       from re_interest_scale_hdr_vw
      where insh_code = i_schaalcode
      group by insh_muntsoort
,              insh_code;

 cursor sh4 is
     select insh_muntsoort
,           insh_code
       from re_interest_scale_hdr_vw
      where insh_muntsoort = i_muntsoort
        and insh_code = i_schaalcode
      group by insh_muntsoort
,              insh_code;

BEGIN
    case
      when i_muntsoort = ' ' and i_schaalcode = 0 then
         BEGIN
           open sh1;
            loop
              fetch sh1 into v_insh_muntsoort
,                           v_insh_code;
              exit when sh1%notfound;

             ONDERHOUD_RENTETABELLEN.bijbehorende_renteschaal(v_insh_muntsoort, v_insh_code,i_aanmaken_vanaf_datum,
                                                              i_DEBT_CRED,i_1_schaalbedrag_gebruiken,i_schaalbedrag,
                                                              v_startdatum_renteschaal);
              v_einddatum_rentebasis := i_aanmaken_tm_datum;
              v_vorige_insd_ingangsdatum := '00000000';

              ONDERHOUD_RENTETABELLEN.opb_rente_perc_schaaltrf_st2(v_insh_muntsoort, v_insh_code,
                                                                   i_DEBT_CRED, i_1_schaalbedrag_gebruiken,
                                                                   v_startdatum_renteschaal, i_aanmaken_tm_datum,
                                                                   i_schaalbedrag);
            end loop;
            close sh1;
         END;
      when i_muntsoort <> ' ' and i_schaalcode = 0 then
         BEGIN
           open sh2;
            loop
              fetch sh2 into v_insh_muntsoort
,                           v_insh_code;
              exit when sh2%notfound;

             ONDERHOUD_RENTETABELLEN.bijbehorende_renteschaal(v_insh_muntsoort, v_insh_code,i_aanmaken_vanaf_datum,
                                                              i_DEBT_CRED,i_1_schaalbedrag_gebruiken,i_schaalbedrag,
                                                               v_startdatum_renteschaal);
              v_einddatum_rentebasis := i_aanmaken_tm_datum;
              v_vorige_insd_ingangsdatum := '00000000';

              ONDERHOUD_RENTETABELLEN.opb_rente_perc_schaaltrf_st2(v_insh_muntsoort, v_insh_code,
                                                                   i_DEBT_CRED, i_1_schaalbedrag_gebruiken,
                                                                   v_startdatum_renteschaal,i_aanmaken_tm_datum,
                                                                   i_schaalbedrag);
            end loop;
            close sh2;
         END;
      when i_muntsoort = ' ' and i_schaalcode <> 0 then
         BEGIN
           open sh3;
            loop
              fetch sh3 into v_insh_muntsoort
,                           v_insh_code;
              exit when sh3%notfound;

             ONDERHOUD_RENTETABELLEN.bijbehorende_renteschaal(v_insh_muntsoort, v_insh_code,i_aanmaken_vanaf_datum,
                                                              i_DEBT_CRED,i_1_schaalbedrag_gebruiken,i_schaalbedrag,
                                                              v_startdatum_renteschaal);
              v_einddatum_rentebasis := i_aanmaken_tm_datum;
              v_vorige_insd_ingangsdatum := '00000000';

              ONDERHOUD_RENTETABELLEN.opb_rente_perc_schaaltrf_st2(v_insh_muntsoort, v_insh_code,
                                                                   i_DEBT_CRED, i_1_schaalbedrag_gebruiken,
                                                                   v_startdatum_renteschaal, i_aanmaken_tm_datum,
                                                                   i_schaalbedrag);
            end loop;
            close sh3;
         END;
      when i_muntsoort <> ' ' and i_schaalcode <> 0 then
         BEGIN
           open sh4;
            loop
              fetch sh4 into v_insh_muntsoort
,                           v_insh_code;
              exit when sh4%notfound;

             ONDERHOUD_RENTETABELLEN.bijbehorende_renteschaal(v_insh_muntsoort, v_insh_code,i_aanmaken_vanaf_datum,
                                                              i_DEBT_CRED,i_1_schaalbedrag_gebruiken,i_schaalbedrag,
                                                              v_startdatum_renteschaal);
              v_einddatum_rentebasis := i_aanmaken_tm_datum;
              v_vorige_insd_ingangsdatum := '00000000';

              ONDERHOUD_RENTETABELLEN.opb_rente_perc_schaaltrf_st2(v_insh_muntsoort, v_insh_code,
                                                                   i_DEBT_CRED, i_1_schaalbedrag_gebruiken,
                                                                   v_startdatum_renteschaal, i_aanmaken_tm_datum,
                                                                   i_schaalbedrag);
            end loop;
            close sh4;
         END;
    end case;
END opbouw_rente_perc_schaaltarief;

--
--  Deze procedure is voor het verwijderen van records uit tabel RENTE_PERC_SCHAALTARIEF.
--
PROCEDURE verw_rente_perc_schaaltarief
   (i_muntsoort                in      re_interest_scale_hdr.insh_muntsoort%type
   ,i_schaalcode               in      re_interest_scale_hdr.insh_code%type
   ,i_DEBT_CRED                in      re_interest_scale_dtl.insd_type_credit_debet%type
   ,i_1_schaalbedrag_gebruiken in      number
   ,i_schaalbedrag             in      re_interest_scale_dtl.insd_bedrag_vanaf%type
   ,i_verwijder_vanaf_datum    in      re_interest_scale_hdr.insh_ingangsdatum%type
   ,i_verwijder_tm_datum       in      re_interest_scale_dtl.insd_ingangsdatum%type)
AS

 filter_item_found  boolean;
 v_sql_stmt             VARCHAR2(1000);
 v_schaalbedrag_alfa    VARCHAR2(16);


BEGIN
    filter_item_found := false;
    v_sql_stmt := 'BEGIN delete from rente_perc_schaaltarief where';
    if i_muntsoort <> ' ' then
       v_sql_stmt := v_sql_stmt || ' rps_muntsoort = ''' || i_muntsoort || '''';
       filter_item_found := true;
    end if;

    if i_schaalcode <> 0 then
       if filter_item_found then
             v_sql_stmt := v_sql_stmt || ' and rps_code = ' || i_schaalcode;
       else
             v_sql_stmt := v_sql_stmt || ' rps_code = ' || i_schaalcode;
             filter_item_found := true;
       end if;
    end if;

    if i_DEBT_CRED <> ' ' then
       if filter_item_found then
             v_sql_stmt := v_sql_stmt || ' and rps_debet_credit_indicator = ''' || i_DEBT_CRED || '''';
       else
             v_sql_stmt := v_sql_stmt || ' rps_debet_credit_indicator = ''' || i_DEBT_CRED || '''';
             filter_item_found := true;
       end if;
    end if;

--
--  Vervang eventuele aanwezigheid van een ',' door een '.'.
--

    v_schaalbedrag_alfa := to_char(i_schaalbedrag);
    v_schaalbedrag_alfa := replace(v_schaalbedrag_alfa,',','.');

    if i_1_schaalbedrag_gebruiken <> 0 then
       if filter_item_found then
             v_sql_stmt := v_sql_stmt || ' and rps_schaalbedrag = ' || v_schaalbedrag_alfa;
       else
             v_sql_stmt := v_sql_stmt || ' rps_schaalbedrag = ' || v_schaalbedrag_alfa;
             filter_item_found := true;
       end if;
    end if;

--    if i_1_schaalbedrag_gebruiken <> 0 then
--       if filter_item_found then
--             v_sql_stmt := v_sql_stmt || ' and rps_schaalbedrag = ' || i_schaalbedrag;
--       else
--             v_sql_stmt := v_sql_stmt || ' rps_schaalbedrag = ' || i_schaalbedrag;
--             filter_item_found := true;
--       end if;
--    end if;

    if filter_item_found then
       v_sql_stmt := v_sql_stmt || ' and rps_valutadatum between ''' || i_verwijder_vanaf_datum || ''' and ''' || i_verwijder_tm_datum || '''; END;';
    else
       v_sql_stmt := v_sql_stmt || ' rps_valutadatum between ''' || i_verwijder_vanaf_datum || ''' and ''' || i_verwijder_tm_datum || '''; END;';
    end if;

    EXECUTE IMMEDIATE v_sql_stmt;



END verw_rente_perc_schaaltarief;

--
--  Deze procedure is voor het initialiseren van tabel RENTE_PERC_SCHAALTARIEF voor de opgegeven muntsoort en schaalcode.
--  Wordt als muntsoort ' ' en als schaalcode 0 meegestuurd, dan zullen alle schalen uit tabel
--  'RE_INTEREST_SCALE_HDR' opnieuw worden samengesteld.
--
PROCEDURE init_rente_perc_schaaltarief
   (i_muntsoort                in      re_interest_scale_hdr.insh_muntsoort%type
   ,i_schaalcode               in      re_interest_scale_hdr.insh_code%type)
AS

BEGIN

    ONDERHOUD_RENTETABELLEN.verw_rente_perc_schaaltarief(i_muntsoort,i_schaalcode,' ',0,0,'00000000','99991231');

    ONDERHOUD_RENTETABELLEN.opbouw_rente_perc_schaaltarief(i_muntsoort,i_schaalcode,' ',0,0,'00000000','99991231');

    ONDERHOUD_RENTETABELLEN.bepalen_renteschalen (nvl(i_muntsoort,' '),0,nvl(to_char(i_schaalcode),0),'00000000');

END init_rente_perc_schaaltarief;

--
-- Deze procedure bepaald of er overlap is tussen de te verwijderen periode en de aan te maken periode.
-- Is er geen overlap dan wordt de te verwijderen periode als overlap periode teruggestuurd.
--
PROCEDURE bepaal_overlap_datumranges
   (i_verwijderen_vanaf_datum       in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_verwijderen_tm_datum          in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_aanmaken_vanaf_datum          in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_aanmaken_tm_datum             in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,o_overlap_aanwezig              out     number
   ,o_overlap_vanaf_datum           out     rente_perc_afspraak.rpa_ingangsdatum%type
   ,o_overlap_tm_datum              out     rente_perc_afspraak.rpa_ingangsdatum%type)
AS

BEGIN
    if (i_aanmaken_vanaf_datum >= i_verwijderen_vanaf_datum and
        i_aanmaken_vanaf_datum <= i_verwijderen_tm_datum) or
       (i_aanmaken_tm_datum    >= i_verwijderen_vanaf_datum and
        i_aanmaken_tm_datum    <= i_verwijderen_tm_datum) then
          o_overlap_aanwezig := 1;

--        Minimale vanaf datum bepalen

          if i_verwijderen_vanaf_datum < i_aanmaken_vanaf_datum then
              o_overlap_vanaf_datum := i_verwijderen_vanaf_datum;
          else
              o_overlap_vanaf_datum := i_aanmaken_vanaf_datum;
          end if;

--        Maximale t/m datum bepalen

          if i_verwijderen_tm_datum > i_aanmaken_tm_datum then
              o_overlap_tm_datum := i_verwijderen_tm_datum;
          else
              o_overlap_tm_datum := i_aanmaken_tm_datum;
          end if;

    else
       o_overlap_aanwezig  := 0;
       o_overlap_vanaf_datum    := i_verwijderen_vanaf_datum;
       o_overlap_tm_datum       := i_verwijderen_tm_datum;
    end if;

END bepaal_overlap_datumranges;

--
--   Deze procedure is voor het bijwerken van de RENTE_PERC_AFSPRAAK tabel
--
PROCEDURE bijw_rente_perc_afspraak
   (i_muntsoort                     in      rente_perc_afspraak.rpa_muntsoort%type
   ,i_afspraaknummer                in      rente_perc_afspraak.rpa_code%type
   ,i_verwijderen_vanaf_datum       in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_verwijderen_tm_datum          in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_aanmaken_vanaf_datum          in      rente_perc_afspraak.rpa_ingangsdatum%type
   ,i_aanmaken_tm_datum             in      rente_perc_afspraak.rpa_ingangsdatum%type)
AS

   v_overlap_aanwezig              number;
   v_overlap_vanaf_datum           rente_perc_afspraak.rpa_ingangsdatum%type;
   v_overlap_tm_datum              rente_perc_afspraak.rpa_ingangsdatum%type;

BEGIN

--  Bepalen of er overlap is in de datum ranges.

   ONDERHOUD_RENTETABELLEN.bepaal_overlap_datumranges(i_verwijderen_vanaf_datum, i_verwijderen_tm_datum,
                                                      i_aanmaken_vanaf_datum, i_aanmaken_tm_datum,
                                                      v_overlap_aanwezig, v_overlap_vanaf_datum,
                                                      v_overlap_tm_datum);

--  Verwijder alle records voor de te verwijderen datum range.

   ONDERHOUD_RENTETABELLEN.verwijder_rente_perc_afspraak(i_muntsoort, i_afspraaknummer,
                                                        v_overlap_vanaf_datum, v_overlap_tm_datum);

--  Bouw de tabel voor de te verwijderen datum range weer op.

   ONDERHOUD_RENTETABELLEN.opbouw_rente_perc_afspraak(i_muntsoort, i_afspraaknummer,
                                                      v_overlap_vanaf_datum, v_overlap_tm_datum);

--  Is er overlap tussen het te verwijderen en het aan te maken deel, dan worden het verwijderen en
--  het aan te maken deel hierboven in 1 keer doorgevoerd. Is dit niet het geval, dan wordt hierboven alleen
--  het te verwijderen gedeelte verwijderd en opnieuw aangemaakt. Hieronder moet dan het aan te maken deel nog
--  worden uitgevoerd.

   if v_overlap_aanwezig = 0 then

--    Verwijder alle records voor de aan te maken datum range.

      ONDERHOUD_RENTETABELLEN.verwijder_rente_perc_afspraak(i_muntsoort, i_afspraaknummer,
                                                            i_aanmaken_vanaf_datum, i_aanmaken_tm_datum);

--    Bouw de tabel voor de aan te maken datum range weer op.

      ONDERHOUD_RENTETABELLEN.opbouw_rente_perc_afspraak(i_muntsoort, i_afspraaknummer,
                                                         i_aanmaken_vanaf_datum, i_aanmaken_tm_datum);
   end if;

END bijw_rente_perc_afspraak;

--
--   Deze procedure is voor het bijwerken van de RENTE_PERC_SCHAALTARIEF
--
PROCEDURE bijw_rente_perc_schaaltarief
   (i_muntsoort                     in      rente_perc_schaaltarief.rps_muntsoort%type
   ,i_schaalcode                    in      rente_perc_schaaltarief.rps_code%type
   ,i_DEBT_CRED                     in      rente_perc_schaaltarief.rps_debet_credit_indicator%type
   ,i_1_schaalbedrag_gebruiken      in      number
   ,i_oude_schaalbedrag             in      rente_perc_schaaltarief.rps_schaalbedrag%type
   ,i_nieuwe_schaalbedrag           in      rente_perc_schaaltarief.rps_schaalbedrag%type
   ,i_verwijderen_vanaf_datum       in      rente_perc_schaaltarief.rps_valutadatum%type
   ,i_verwijderen_tm_datum          in      rente_perc_schaaltarief.rps_valutadatum%type
   ,i_aanmaken_vanaf_datum          in      rente_perc_schaaltarief.rps_valutadatum%type
   ,i_aanmaken_tm_datum             in      rente_perc_schaaltarief.rps_valutadatum%type)
AS

   v_overlap_aanwezig              number;
   v_overlap_vanaf_datum           rente_perc_afspraak.rpa_ingangsdatum%type;
   v_overlap_tm_datum              rente_perc_afspraak.rpa_ingangsdatum%type;

BEGIN

--  Bepalen of er overlap is in de datum ranges.

    ONDERHOUD_RENTETABELLEN.bepaal_overlap_datumranges(i_verwijderen_vanaf_datum, i_verwijderen_tm_datum,
                                                      i_aanmaken_vanaf_datum, i_aanmaken_tm_datum,
                                                      v_overlap_aanwezig, v_overlap_vanaf_datum,
                                                      v_overlap_tm_datum);

--  Verwijder alle records voor de te verwijderen datum range.

    ONDERHOUD_RENTETABELLEN.verw_rente_perc_schaaltarief(i_muntsoort, i_schaalcode, i_DEBT_CRED,
                                                         i_1_schaalbedrag_gebruiken, i_oude_schaalbedrag,
                                                         v_overlap_vanaf_datum, v_overlap_tm_datum);

--  Bouw de tabel voor de te verwijderen datum range weer op.

    ONDERHOUD_RENTETABELLEN.opbouw_rente_perc_schaaltarief(i_muntsoort, i_schaalcode, i_DEBT_CRED,
                                                           i_1_schaalbedrag_gebruiken, i_nieuwe_schaalbedrag,
                                                           v_overlap_vanaf_datum, v_overlap_tm_datum);
--
--  Is er overlap tussen het te verwijderen en het aan te maken deel, dan worden het verwijderen en het
--  aan te maken deel hierboven in 1 keer doorgevoerd. Is dit niet het geval, dan wordt hierboven alleen
--  het te verwijderen gedeelte verwijderd en opnieuw aangemaakt. Hieronder moet dan het aan te maken deel
--  nog worden uitgevoerd.
--
    if v_overlap_aanwezig = 0 then

--     Verwijder alle records voor de aan te maken datum range.

       ONDERHOUD_RENTETABELLEN.verw_rente_perc_schaaltarief(i_muntsoort, i_schaalcode, i_DEBT_CRED,
                                                            0, 0, i_aanmaken_vanaf_datum, i_aanmaken_tm_datum);

--     Bouw de tabel voor de aan te maken datum range weer op.

       ONDERHOUD_RENTETABELLEN.opbouw_rente_perc_schaaltarief(i_muntsoort, i_schaalcode, i_DEBT_CRED,
                                                              0, 0, i_aanmaken_vanaf_datum, i_aanmaken_tm_datum);
    end if;

END bijw_rente_perc_schaaltarief;

--
--  Deze procedure bepaalt welk gedeelte van 'RENTE_PERC_AFSPRAAK' of 'RENTE_PERC_SCHAALTARIEF' opnieuw moet
--  worden opgebouwd als gevolg van een wijziging in een re_interest_base_perc.
--  Het opbouwen van de 'RENTE_PERC_AFSPRAAK' en/of 'RENTE_PERC_SCHAALTARIEF' houdt in dat eerst een periode
--  rond de oude ingangsdatum wordt verwijderd en opnieuw opgebouwd en hierna een periode rond de nieuwe
--  ingangsdatum wordt verwijderd en opnieuw opgebouwd.
--  Deze periodes worden bepaald door de eerste ingangsdatum voor en de eerste ingangsdatum na de oude
--  en de nieuwe ingangsdatum te bepalen. Is er een overlap in deze periodes aanwezig, dan hoeft het
--  verwijderen en opbouwen niet voor oud en nieuw apart te worden gedaan, maar kan dit in 1 keer gebeuren
--  voor de overlap periode. Na het bepalen van deze periodes worden de procedures aangeroepen voor het
--  opnieuw opbouwen van deze tabellen. Het is dus wel noodzakelijk dat de wijziging in het
--  re_interest_base_perc al wel is doorgevoerd, voordat deze procedure wordt aangeroepen.
--
-- Deze procedure wordt aangeroepen door triggers:
-- re_interest_base_perc_TRG_AI
-- re_interest_base_perc_TRG_AU
-- re_interest_base_perc_TRG_AD
PROCEDURE wijziging_rentebasispercentage
AS

   v_datum_voor_oude_ingangsdatum    re_interest_base_perc.inbp_ingangsdatum%type;
   v_datum_voor_nwe_ingangsdatum     re_interest_base_perc.inbp_ingangsdatum%type;
   v_verwijderen_vanaf_datum         re_interest_base_perc.inbp_ingangsdatum%type;
   v_verwijderen_tm_datum            re_interest_base_perc.inbp_ingangsdatum%type;
   v_aanmaken_vanaf_datum            re_interest_base_perc.inbp_ingangsdatum%type;
   v_aanmaken_tm_datum               re_interest_base_perc.inbp_ingangsdatum%type;
   v_dummy_rentepercentage           re_interest_base_perc.inbp_basis%type;
   v_inag_muntsoort                  re_interest_agreement.inag_muntsoort%type;
   v_inag_nummer                     re_interest_agreement.inag_nummer%type;
   v_insd_code                       re_interest_scale_dtl.insd_code%type;
   v_insd_type_credit_debet          re_interest_scale_dtl.insd_type_credit_debet%type;
   v_insd_bedrag_vanaf               re_interest_scale_dtl.insd_bedrag_vanaf%type;



 cursor rt is
     select inag_muntsoort
,           inag_nummer
       from re_interest_agreement_vw
      where inag_muntsoort = g_muntsoort
        and (inag_debet_rente = g_rentebasisnummer or inag_credit_rente = g_rentebasisnummer);

 cursor sd is
     select insd_code
,           insd_type_credit_debet
,           insd_bedrag_vanaf
       from re_interest_scale_dtl_vw
      where insd_muntsoort   = g_muntsoort
        and insd_basistarief = g_rentebasisnummer
      group by insd_code, insd_type_credit_debet, insd_bedrag_vanaf;

BEGIN

     if g_soort_wijziging = 'UPDATE' or g_soort_wijziging = 'DELETE' then

      v_datum_voor_oude_ingangsdatum := to_char(to_date(g_ingangsdatum,'YYYYMMDD')-1,'YYYYMMDD');

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(g_muntsoort, g_rentebasisnummer, v_datum_voor_oude_ingangsdatum,
                                                      v_verwijderen_vanaf_datum, v_dummy_rentepercentage,
                                                      v_dummy_rentepercentage);

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis_NA(g_muntsoort, g_rentebasisnummer,g_ingangsdatum,
                                                         v_verwijderen_tm_datum);
      if g_soort_wijziging = 'DELETE' then
         v_aanmaken_vanaf_datum := v_verwijderen_vanaf_datum;
         v_aanmaken_tm_datum    := v_verwijderen_tm_datum;
      end if;
   end if;

   if g_soort_wijziging = 'UPDATE' or g_soort_wijziging = 'INSERT' then

      v_datum_voor_nwe_ingangsdatum := to_char(to_date(g_nieuwe_ingangsdatum,'YYYYMMDD')-1,'YYYYMMDD');

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis(g_muntsoort, g_rentebasisnummer, v_datum_voor_nwe_ingangsdatum,
                                                      v_aanmaken_vanaf_datum, v_dummy_rentepercentage,
                                                      v_dummy_rentepercentage);

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentebasis_NA(g_muntsoort, g_rentebasisnummer,g_nieuwe_ingangsdatum,
                                                         v_aanmaken_tm_datum);
      if g_soort_wijziging = 'INSERT' then
         v_verwijderen_vanaf_datum := v_aanmaken_vanaf_datum;
         v_verwijderen_tm_datum    := v_aanmaken_tm_datum;
      end if;
   end if;

--
-- Bepaal in welke re_interest_agreement gebruik gemaakt wordt van dit re_interest_base_perc.
--
   open rt;
   loop
      fetch rt into v_inag_muntsoort
,                   v_inag_nummer;
      exit when rt%notfound;

      ONDERHOUD_RENTETABELLEN.bijw_rente_perc_afspraak(v_inag_muntsoort, v_inag_nummer, v_verwijderen_vanaf_datum,
                                                       v_verwijderen_tm_datum, v_aanmaken_vanaf_datum,
                                                       v_aanmaken_tm_datum);
   end loop;
   close rt;

--
-- Bepaal in welke renteschaal tabel gebruik gemaakt wordt van dit re_interest_base_perc
--
   open sd;
   loop
      fetch sd into v_insd_code
,                   v_insd_type_credit_debet
,                   v_insd_bedrag_vanaf;
      exit when sd%notfound;

      ONDERHOUD_RENTETABELLEN.bijw_rente_perc_schaaltarief(g_muntsoort, v_insd_code, v_insd_type_credit_debet, 1,
                                                           v_insd_bedrag_vanaf, v_insd_bedrag_vanaf,
                                                           v_verwijderen_vanaf_datum, v_verwijderen_tm_datum,
                                                           v_aanmaken_vanaf_datum, v_aanmaken_tm_datum);
   end loop;
   close sd;



-- Aanvullen redundante gegevens

ONDERHOUD_RENTETABELLEN.bepalen_renteschalen (g_muntsoort,g_rentebasisnummer,0,least(nvl(v_aanmaken_vanaf_datum,'00000000'),nvl(v_verwijderen_vanaf_datum,'00000000')));


END wijziging_rentebasispercentage;

--
--  Deze procedure bouwt bij wijziging van de INAG_DEBET_RENTE en/of INAG_CREDIT_RENTE uit tabel
--  re_interest_agreement de hierbij behorende tabel 'RENTE_PERC_AFSPRAAK' opnieuw op.
--
-- Deze procedure wordt aangeroepen door triggers:
-- re_interest_agreement_TRG_AI
-- re_interest_agreement_TRG_AU
-- re_interest_agreement_TRG_AD
--
PROCEDURE wijziging_rente_afspraken
AS

BEGIN

    ONDERHOUD_RENTETABELLEN.init_rente_perc_afspraak(g_muntsoort,g_afspraaknummer);

END wijziging_rente_afspraken;

--
-- Deze procedure bepaalt welk gedeelte van 'RENTE_PERC_AFSPRAAK' opnieuw moet worden opgebouwd
-- als gevolg van een wijziging in de marge standen. Na het bepalen van deze periodes worden de
-- procedures aangeroepen voor het opnieuw opbouwen van deze tabel.
-- Het is dus wel noodzakelijk dat de wijziging in de RE_MARGIN_RATES al wel is doorgevoerd,
-- voordat deze procedure wordt aangeroepen.
--
-- Deze procedure wordt aangeroepen door triggers:
-- re_margin_rates_TRG_AI
-- re_margin_rates_TRG_AU
-- re_margin_rates_TRG_AD
--
PROCEDURE wijziging_marges_standen
AS

   v_datum_voor_oude_ingangsdatum    re_margin_rates.marg_ingangsdatum%type;
   v_datum_voor_nwe_ingangsdatum     re_margin_rates.marg_ingangsdatum%type;
   v_verwijderen_vanaf_datum         re_margin_rates.marg_ingangsdatum%type;
   v_verwijderen_tm_datum            re_margin_rates.marg_ingangsdatum%type;
   v_aanmaken_vanaf_datum            re_margin_rates.marg_ingangsdatum%type;
   v_aanmaken_tm_datum               re_margin_rates.marg_ingangsdatum%type;
   v_dummy_rentepercentage           re_interest_base_perc.inbp_basis%type;

BEGIN
    if g_soort_wijziging = 'UPDATE' or g_soort_wijziging = 'DELETE' then

      v_datum_voor_oude_ingangsdatum := to_char(to_date(g_ingangsdatum,'YYYYMMDD')-1,'YYYYMMDD');

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge(g_muntsoort, g_afspraaknummer, g_marg_soort, v_datum_voor_oude_ingangsdatum,
                                                      v_verwijderen_vanaf_datum, v_dummy_rentepercentage);

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge_NA(g_muntsoort, g_afspraaknummer, g_marg_soort, g_ingangsdatum,
                                                         v_verwijderen_tm_datum);
      if g_soort_wijziging = 'DELETE' then
         v_aanmaken_vanaf_datum := v_verwijderen_vanaf_datum;
         v_aanmaken_tm_datum    := v_verwijderen_tm_datum;
      end if;
   end if;

   if g_soort_wijziging = 'UPDATE' or g_soort_wijziging = 'INSERT' then

      v_datum_voor_nwe_ingangsdatum := to_char(to_date(g_nieuwe_ingangsdatum,'YYYYMMDD')-1,'YYYYMMDD');

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge(g_muntsoort, g_afspraaknummer, g_marg_soort, v_datum_voor_nwe_ingangsdatum,
                                                      v_aanmaken_vanaf_datum, v_dummy_rentepercentage);

      ONDERHOUD_RENTETABELLEN.bijbehorende_rentemarge_NA(g_muntsoort, g_afspraaknummer, g_marg_soort, g_nieuwe_ingangsdatum,
                                                         v_aanmaken_tm_datum);
      if g_soort_wijziging = 'INSERT' then
         v_verwijderen_vanaf_datum := v_aanmaken_vanaf_datum;
         v_verwijderen_tm_datum    := v_aanmaken_tm_datum;
      end if;
   end if;

   ONDERHOUD_RENTETABELLEN.bijw_rente_perc_afspraak(g_muntsoort, g_afspraaknummer, v_verwijderen_vanaf_datum,
                                                    v_verwijderen_tm_datum, v_aanmaken_vanaf_datum,
                                                    v_aanmaken_tm_datum);
END wijziging_marges_standen;

--
--   Deze procedure bepaalt welk gedeelte van 'RENTE_PERC_SCHAALTARIEF' opnieuw moet worden opgebouwd als gevolg van een wijziging
--   van de ingangsdatum van de RE_INTEREST_SCALE_HDR. Na het bepalen van deze periodes worden de procedures aangeroepen voor het
--   opnieuw opbouwen van deze tabel. Het is dus wel noodzakelijk dat de wijziging in de RE_INTEREST_SCALE_HDR al wel is doorgevoerd,
--   voordat deze procedure wordt aangeroepen.
--
-- Deze procedure wordt aangeroepen door triggers:
-- re_interest_scale_hdr_TRG_AI
-- re_interest_scale_hdr_TRG_AU
-- re_interest_scale_hdr_TRG_AD
--
PROCEDURE wijziging_renteschalen_header
AS

   v_datum_voor_oude_ingangsdatum    re_interest_scale_hdr.insh_ingangsdatum%type;
   v_datum_voor_nwe_ingangsdatum     re_interest_scale_hdr.insh_ingangsdatum%type;
   v_verwijderen_vanaf_datum         re_interest_scale_hdr.insh_ingangsdatum%type;
   v_verwijderen_tm_datum            re_interest_scale_hdr.insh_ingangsdatum%type;
   v_aanmaken_vanaf_datum            re_interest_scale_hdr.insh_ingangsdatum%type;
   v_aanmaken_tm_datum               re_interest_scale_hdr.insh_ingangsdatum%type;
   v_dummy_rentepercentage           re_interest_base_perc.inbp_basis%type;

BEGIN
    if g_soort_wijziging = 'UPDATE' or g_soort_wijziging = 'DELETE' then

      v_datum_voor_oude_ingangsdatum := to_char(to_date(g_ingangsdatum,'YYYYMMDD')-1,'YYYYMMDD');

      ONDERHOUD_RENTETABELLEN.bijbeh_renteschaal_HDR(g_muntsoort, g_schalennummer, v_datum_voor_oude_ingangsdatum,
                                                     v_verwijderen_vanaf_datum);

      ONDERHOUD_RENTETABELLEN.bijbeh_renteschaal_HDR_NA(g_muntsoort, g_schalennummer, g_ingangsdatum,
                                                        v_verwijderen_tm_datum);
      if g_soort_wijziging = 'DELETE' then
         v_aanmaken_vanaf_datum := v_verwijderen_vanaf_datum;
         v_aanmaken_tm_datum    := v_verwijderen_tm_datum;
      end if;
   end if;

   if g_soort_wijziging = 'UPDATE' or g_soort_wijziging = 'INSERT' or g_soort_wijziging = 'CONFIRM' then

      v_datum_voor_nwe_ingangsdatum := to_char(to_date(g_nieuwe_ingangsdatum,'YYYYMMDD')-1,'YYYYMMDD');

      ONDERHOUD_RENTETABELLEN.bijbeh_renteschaal_HDR(g_muntsoort, g_schalennummer, v_datum_voor_nwe_ingangsdatum,
                                                     v_aanmaken_vanaf_datum);

      ONDERHOUD_RENTETABELLEN.bijbeh_renteschaal_HDR_NA(g_muntsoort, g_schalennummer,g_nieuwe_ingangsdatum,
                                                        v_aanmaken_tm_datum);
      if g_soort_wijziging = 'INSERT' or g_soort_wijziging = 'CONFIRM' then
         v_verwijderen_vanaf_datum := v_aanmaken_vanaf_datum;
         v_verwijderen_tm_datum    := v_aanmaken_tm_datum;
      end if;
   end if;

   ONDERHOUD_RENTETABELLEN.bijw_rente_perc_schaaltarief(g_muntsoort, g_schalennummer, ' ', 0, 0, 0,
                                                        v_verwijderen_vanaf_datum, v_verwijderen_tm_datum,
                                                        v_aanmaken_vanaf_datum, v_aanmaken_tm_datum);

-- Aanvullen redundante gegevens
    ONDERHOUD_RENTETABELLEN.bepalen_renteschalen (g_muntsoort,0,g_schalennummer,least(nvl(v_aanmaken_vanaf_datum,'00000000'),nvl(v_verwijderen_vanaf_datum,'00000000')));

END wijziging_renteschalen_header;

--
--   Deze procedure bepaalt welk gedeelte van 'RENTE_PERC_SCHAALTARIEF' opnieuw moet worden opgebouwd als gevolg van een
--   wijziging in een RE_INTEREST_SCALE_DTL record. Na het bepalen van deze periodes worden de procedures aangeroepen voor
--   het opnieuw opbouwen van deze tabel. Het is dus wel noodzakelijk dat de wijziging in het RE_INTEREST_SCALE_DTL al wel
--   is doorgevoerd, voordat deze procedure wordt aangeroepen.
--
-- Deze procedure wordt aangeroepen door triggers:
-- re_interest_scale_dtl_TRG_AI
-- re_interest_scale_dtl_TRG_AU
-- re_interest_scale_dtl_TRG_AD
--
PROCEDURE wijziging_renteschalen_detail
AS

   v_dummy_insd_code               re_interest_scale_dtl.insd_code%type;
   v_bijwerken_vanaf_datum         re_interest_scale_dtl.insd_ingangsdatum%type;
   v_volgende_ingangsdatum         re_interest_scale_dtl.insd_ingangsdatum%type;
   v_datum_tm                      re_interest_scale_dtl.insd_ingangsdatum%type;

    cursor sd is
     select insd_code
       from re_interest_scale_dtl_vw
      where insd_muntsoort         =  g_muntsoort
        and insd_code              =  g_schalennummer
        and insd_ingangsdatum      =  g_ingangsdatum
        and insd_type_credit_debet =  g_type_credit_debet
        and insd_bedrag_vanaf      <> g_nieuwe_bedrag_vanaf;

BEGIN

   ONDERHOUD_RENTETABELLEN.bijbehorende_renteschaal_NA(g_muntsoort, g_schalennummer, g_ingangsdatum,
                                                       g_type_credit_debet,0,0,
                                                       v_volgende_ingangsdatum);

   v_datum_tm := to_char(to_date(v_volgende_ingangsdatum,'YYYYMMDD')-1,'YYYYMMDD');

   if g_soort_wijziging = 'DELETE' then
--    Bepaal vanaf welke datum er eventueel weer opnieuw moet worden bijgewerkt :
      ONDERHOUD_RENTETABELLEN.bijbehorende_renteschaal(g_muntsoort, g_schalennummer, g_ingangsdatum,
                                                       g_type_credit_debet,0,0,
                                                       v_bijwerken_vanaf_datum);

--    Indien alle details voor Debet of Credit kant verwijderd zijn, dan moet bijgewerkt worden vanaf de vorige ingangsdatum.
--    Er wordt 1 kant (Debet of Credit) bijgewerkt voor alle schalen van de vorige ingangsdatum.
      if v_bijwerken_vanaf_datum < g_ingangsdatum then
         ONDERHOUD_RENTETABELLEN.bijw_rente_perc_schaaltarief(g_muntsoort, g_schalennummer, g_type_credit_debet,
                                                              0,0,0,
                                                              v_bijwerken_vanaf_datum, v_datum_tm, v_bijwerken_vanaf_datum,
                                                              v_datum_tm);
      else
--    Zijn niet alle details voor Debet of Credit verwijderd, dan alleen de betreffende schalen verwijderen
         ONDERHOUD_RENTETABELLEN.verw_rente_perc_schaaltarief(g_muntsoort, g_schalennummer, g_type_credit_debet,
                                                              1, g_bedrag_vanaf, g_ingangsdatum,
                                                              v_datum_tm);

      end if;
   end if;

   if g_soort_wijziging = 'INSERT' or g_soort_wijziging = 'CONFIRM' then
--    Indien er nog GEEN details voor Debet of Credit kant aanwezig waren VOOR de insert, dan moeten alle records
--    tussen de ingangsdatum van het nieuwe record en de volgende ingangsdatum worden verwijderd.
      open sd;
      fetch sd into v_dummy_insd_code;
      if sd%notfound
      then
         ONDERHOUD_RENTETABELLEN.verw_rente_perc_schaaltarief(g_muntsoort, g_schalennummer, g_type_credit_debet,
                                                              0, 0, g_ingangsdatum,
                                                              v_datum_tm);
      end if;

      ONDERHOUD_RENTETABELLEN.opbouw_rente_perc_schaaltarief(g_muntsoort, g_schalennummer, g_type_credit_debet,
                                                             1, g_nieuwe_bedrag_vanaf, g_ingangsdatum,
                                                             v_datum_tm);
   end if;

   if g_soort_wijziging = 'UPDATE' then
      ONDERHOUD_RENTETABELLEN.bijw_rente_perc_schaaltarief(g_muntsoort, g_schalennummer, g_type_credit_debet,
                                                           1, g_bedrag_vanaf, g_nieuwe_bedrag_vanaf,
                                                           g_ingangsdatum, v_datum_tm, g_ingangsdatum,
                                                           v_datum_tm);
   end if;

-- Aanvullen redundante gegevens
    ONDERHOUD_RENTETABELLEN.bepalen_renteschalen (g_muntsoort,0,g_schalennummer,g_ingangsdatum);

END wijziging_renteschalen_detail;

--
-- Procedure voor het locken van de tabellen welke nodig zijn voor de opbouw van de rentetabellen 'RENTE_PERC_AFSPRAAK'
-- en 'RENTE_PERC_SCHAALTARIEF' als gevolg van een wijziging in tabel 're_interest_base_perc'.
-- Deze tabellen moeten worden gelocked om te voorkomen dat er tijdens de opbouw van de rentetabellen
-- door de bovenstaande procedures, iets wijzigt in de tabellen die bij deze opbouw worden gebruikt.
-- Deze procedure wordt aangeroepen door trigger:
-- re_interest_base_perc_TRG
--
PROCEDURE lock_rentebasispercentage
   (i_inbp_xxxx_id                       in      re_interest_base_perc_hdr.inbph_id%type)
as
   cursor c1 is
    Select 1
     from re_interest_base_perc_hdr b, re_interest_scale_hdr_vw h,
          re_interest_scale_dtl_vw d where
          b.inbph_id          = i_inbp_xxxx_id   and
          h.insh_muntsoort    = b.inbph_currency and
          d.insd_muntsoort    = h.insh_muntsoort and
          d.insd_code         = h.insh_code and
          d.insd_ingangsdatum = h.insh_ingangsdatum and
          d.insd_basistarief  = b.inbph_number
      for update nowait;

   cursor c2 is
    Select 1
     from re_interest_agreement_vw r , re_interest_base_perc_hdr b1
         where
         b1.inbph_id         = i_inbp_xxxx_id    and
         r.inag_muntsoort    = b1.inbph_currency and
        (r.inag_debet_rente  = b1.inbph_number or
         r.inag_credit_rente = b1.inbph_number)
      for update nowait;
BEGIN
--
-- Lock de renteschalen en afspraken, welke gebruikmaken van het re_interest_base_perc
-- Schalenheader en bijbehorende details :
--
   open c1;
   close c1;
--
-- Afspraken :
--
   open c2;
   close c2;
END lock_rentebasispercentage;

--
-- Procedure voor het locken van de tabellen welke nodig zijn voor de opbouw van de rentetabellen 'RENTE_PERC_AFSPRAAK'
-- en 'RENTE_PERC_SCHAALTARIEF' als gevolg van een wijziging in tabel 're_interest_agreement'.
-- Deze tabellen moeten worden gelocked om te voorkomen dat er tijdens de opbouw van de rentetabellen
-- door de bovenstaande procedures, iets wijzigt in de tabellen die bij deze opbouw worden gebruikt.
-- Deze procedure wordt aangeroepen door trigger:
-- re_interest_agreement_TRG
--
PROCEDURE lock_rente_afspraken
   ( i_muntsoort                     in      re_interest_agreement.inag_muntsoort%type
    ,i_afspraaknummer                in      re_interest_agreement.inag_nummer%type
    ,i_inbp_nummer_DB_old            in      re_interest_base_perc_hdr.inbph_number%type
    ,i_inbp_nummer_DB_new            in      re_interest_base_perc_hdr.inbph_number%type
    ,i_inbp_nummer_CR_old            in      re_interest_base_perc_hdr.inbph_number%type
    ,i_inbp_nummer_CR_new            in      re_interest_base_perc_hdr.inbph_number%type)
as
   cursor c1 is
      Select 1 from re_interest_base_perc_vw r
         where
            r.inbp_muntsoort = i_muntsoort and
            r.inbp_nummer    = i_inbp_nummer_DB_new
      for update nowait;

   cursor c2 is
      Select 1 from re_interest_base_perc_vw r
         where
            r.inbp_muntsoort = i_muntsoort and
            r.inbp_nummer    = i_inbp_nummer_CR_new
      for update nowait;

   cursor c3 is
      Select 1 from re_margin_rates_vw m
         Where
            m.marg_muntsoort = i_muntsoort and
            m.marg_nummer    = i_afspraaknummer
      for update nowait;
BEGIN
--
-- Lock de rentebasispercentages, welke nieuw aan een afspraak worden gekoppeld :
-- DB
--
   if (i_inbp_nummer_DB_old <> i_inbp_nummer_DB_new and i_inbp_nummer_DB_new <> 0) then
      open c1;
      close c1;
   end if;
-- CR
   if (i_inbp_nummer_CR_old <> i_inbp_nummer_CR_new and i_inbp_nummer_CR_new <> 0) then
      open c2;
      close c2;
   end if;

-- Lock bijbehorende Rentemarges :
   open c3;
   close c3;
END lock_rente_afspraken;

--
-- Procedure voor het locken van de tabellen welke nodig zijn voor de opbouw van de rentetabellen 'RENTE_PERC_AFSPRAAK'
-- en 'RENTE_PERC_SCHAALTARIEF' als gevolg van een wijziging in tabel 'RE_MARGIN_RATES'.
-- Deze tabellen moeten worden gelocked om te voorkomen dat er tijdens de opbouw van de rentetabellen
-- door de bovenstaande procedures, iets wijzigt in de tabellen die bij deze opbouw worden gebruikt.
-- Deze procedure wordt aangeroepen door trigger:
-- re_margin_rates_TRG
--
PROCEDURE lock_marges_standen
   (i_muntsoort                     in      re_margin_rates.marg_muntsoort%type
   ,i_rentemargenummer              in      re_margin_rates.marg_nummer%type)
as
   cursor c1 is
      Select 1 from re_interest_agreement_vw r
         Where
            r.inag_nummer = i_rentemargenummer and
            r.inag_muntsoort = i_muntsoort
      for update nowait;
BEGIN
-- Lock de afspraak behorende bij de marge zodat andere margerecords niet kunnen worden gewijzigd:
   open c1;
   close c1;
END lock_marges_standen;

--
-- Procedure voor het locken van de tabellen welke nodig zijn voor de opbouw van de rentetabellen 'RENTE_PERC_AFSPRAAK'
-- en 'RENTE_PERC_SCHAALTARIEF' als gevolg van een wijziging in tabel 'RE_INTEREST_SCALE_HDR'.
-- Deze tabellen moeten worden gelocked om te voorkomen dat er tijdens de opbouw van de rentetabellen
-- door de bovenstaande procedures, iets wijzigt in de tabellen die bij deze opbouw worden gebruikt.
-- Deze procedure wordt aangeroepen door trigger:
-- re_interest_scale_hdr_TRG
--
PROCEDURE lock_renteschalen_header
   (i_muntsoort                     in      re_interest_scale_hdr.insh_muntsoort%type
   ,i_schaalcode                    in      re_interest_scale_hdr.insh_code%type)
as
   cursor c1 is
      Select 1 from re_interest_scale_dtl d where
         d.insd_muntsoort    = i_muntsoort and
         d.insd_code         = i_schaalcode
      for update nowait;
BEGIN
-- Lock alle bijbehorende details van deze schaalcode:
   open c1;
   close c1;
END lock_renteschalen_header;

--
-- Procedure voor het locken van de tabellen welke nodig zijn voor de opbouw van de rentetabellen 'RENTE_PERC_AFSPRAAK'
-- en 'RENTE_PERC_SCHAALTARIEF' als gevolg van een wijziging in tabel 'RE_INTEREST_SCALE_DTL'.
-- Deze tabellen moeten worden gelocked om te voorkomen dat er tijdens de opbouw van de rentetabellen
-- door de bovenstaande procedures, iets wijzigt in de tabellen die bij deze opbouw worden gebruikt.
-- Deze procedure wordt aangeroepen door trigger:
-- re_interest_scale_dtl_TRG
--
PROCEDURE lock_renteschalen_detail
   ( i_muntsoort                     in re_interest_scale_dtl.insd_muntsoort%type
    ,i_schaalcode                    in re_interest_scale_dtl.insd_code%type
    ,i_inbp_nummer_old               in re_interest_base_perc_hdr.inbph_number%type
    ,i_inbp_nummer_new               in re_interest_base_perc_hdr.inbph_number%type)
as
   cursor c1 is
      Select 1 from re_interest_scale_hdr_vw h where
         h.insh_muntsoort = i_muntsoort and
         h.insh_code      = i_schaalcode
      for update nowait;

   cursor c2 is
      Select 1 from re_interest_base_perc_vw r
         where
            r.inbp_muntsoort = i_muntsoort and
            r.inbp_nummer    = i_inbp_nummer_new
      for update nowait;
BEGIN
-- Lock de bij de detail behorende header om te voorkomen dat er tussentijds andere details van dit schaalnr kunnen
-- worden aangepast:
   open c1;
   close c1;

-- Lock de rentebasispercentages, welke nieuw aan een detailregel worden gekoppeld :
   if (i_inbp_nummer_old <> i_inbp_nummer_new and i_inbp_nummer_new <> 0) then
      open c2;
      close c2;
   end if;
END lock_renteschalen_detail;


-- Deze procedure is de start voor het aanvullen van de redundante gegevens.


PROCEDURE bepalen_renteschalen

(i_muntsoort             in rente_perc_schaaltarief.rps_muntsoort%type,
 i_schaalcode_basis      in re_interest_scale_dtl_vw.insd_basistarief%type,
 i_renteschaal           in rente_perc_schaaltarief.rps_code%type,
 i_bijwerken_vanaf_datum in rente_perc_schaaltarief.rps_valutadatum%type)

 AS

  v_muntsoort               rente_perc_schaaltarief.rps_muntsoort%type;
  v_schaalcode              rente_perc_schaaltarief.rps_code%type;
  v_type_d_c                rente_perc_schaaltarief.rps_debet_credit_indicator%type;

-- Bepalen voor welke renteschalen een aanpassing gedaan moet worden als het basispercentage of renteschaal wordt meegegeven
-- Er zijn 5 mogelijke opties

 cursor sd2 is
     select v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet
       from re_interest_scale_dtl_vw v
   group by v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet
   order by v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet;

 cursor sd3 is
     select v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet
       from re_interest_scale_dtl_vw v
      where v.insd_muntsoort   = i_muntsoort
   group by v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet
   order by v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet;

  cursor sd4 is
     select v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet
       from re_interest_scale_dtl_vw v
      where v.insd_code = i_renteschaal
   group by v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet
   order by v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet;

 cursor sd5 is
     select v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet
       from re_interest_scale_dtl_vw v
      where v.insd_muntsoort   = i_muntsoort
        and v.insd_code = i_renteschaal
   group by v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet
   order by v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet;

 cursor sd6 is
     select v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet
       from re_interest_scale_dtl_vw v
      where v.insd_muntsoort   = i_muntsoort
        and v.insd_basistarief = i_schaalcode_basis
   group by v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet
   order by v.insd_muntsoort,v.insd_code,v.insd_type_credit_debet;


BEGIN

if i_muntsoort = ' ' and i_schaalcode_basis = 0 and i_renteschaal = 0 then

  open sd2;
  loop
    fetch sd2
      into v_muntsoort,v_schaalcode,v_type_d_c;
           exit when sd2%notfound;

  ONDERHOUD_RENTETABELLEN.aanv_rente_perc_schl_tarief (v_muntsoort,v_schaalcode,v_type_d_c,i_bijwerken_vanaf_datum);

  end loop;
  close sd2;

  elsif i_muntsoort <> ' ' and i_schaalcode_basis = 0 and i_renteschaal = 0 then

  open sd3;
  loop
    fetch sd3
      into v_muntsoort,v_schaalcode,v_type_d_c;
           exit when sd3%notfound;

  ONDERHOUD_RENTETABELLEN.aanv_rente_perc_schl_tarief (v_muntsoort,v_schaalcode,v_type_d_c,i_bijwerken_vanaf_datum);

  end loop;
  close sd3;

  elsif i_muntsoort = ' ' and i_schaalcode_basis = 0 and i_renteschaal <> 0 then

  open sd4;
  loop
    fetch sd4
      into v_muntsoort,v_schaalcode,v_type_d_c;
           exit when sd4%notfound;

  ONDERHOUD_RENTETABELLEN.aanv_rente_perc_schl_tarief (v_muntsoort,v_schaalcode,v_type_d_c,i_bijwerken_vanaf_datum);

  end loop;
  close sd4;

  elsif i_muntsoort <> ' ' and i_schaalcode_basis = 0 and i_renteschaal <> 0 then

  open sd5;
  loop
    fetch sd5
      into v_muntsoort,v_schaalcode,v_type_d_c;
           exit when sd5%notfound;

  ONDERHOUD_RENTETABELLEN.aanv_rente_perc_schl_tarief (v_muntsoort,v_schaalcode,v_type_d_c,i_bijwerken_vanaf_datum);

  end loop;
  close sd5;

  elsif i_muntsoort <> ' ' and i_schaalcode_basis <> 0 and i_renteschaal = 0 then

  open sd6;
  loop
    fetch sd6
      into v_muntsoort,v_schaalcode,v_type_d_c;
           exit when sd6%notfound;

  ONDERHOUD_RENTETABELLEN.aanv_rente_perc_schl_tarief (v_muntsoort,v_schaalcode,v_type_d_c,i_bijwerken_vanaf_datum);

  end loop;
  close sd6;

end if;

END bepalen_renteschalen;

-- Deze procedure vult de redundante gegevens aan zodat op elke datum alle schaaltarieven beschikbaar zijn.

PROCEDURE ontbrekende_renteschalen

(i_muntsoort              in rente_perc_schaaltarief.rps_muntsoort%type,
 i_code                   in rente_perc_schaaltarief.rps_code%type,
 i_valutadatum            in rente_perc_schaaltarief.rps_valutadatum%type,
 i_vorige_valutadatum     in rente_perc_schaaltarief.rps_valutadatum%type,
 i_debet_credit_indicator in rente_perc_schaaltarief.rps_debet_credit_indicator%type)

 AS

  v_schaalbedrag rente_perc_schaaltarief.rps_schaalbedrag%type;
  v_rente_marge  rente_perc_schaaltarief.rps_rente_marge%type;
  v_basis_opslag rente_perc_schaaltarief.rps_basis_opslag%type;


-- Record toevoegen indien deze bij de vorige valutadatum niet aanwezig is
  cursor rpst2 is
    select r.rps_schaalbedrag, r.rps_rente_marge, r.rps_basis_opslag
      from rente_perc_schaaltarief r
     where r.rps_muntsoort = i_muntsoort
       and r.rps_code = i_code
       and r.rps_valutadatum = i_vorige_valutadatum
       and r.rps_debet_credit_indicator = i_debet_credit_indicator
  and not exists(
    select 1
      from rente_perc_schaaltarief r2
     where r2.rps_muntsoort = r.rps_muntsoort
       and r2.rps_code = r.rps_code
       and r2.rps_debet_credit_indicator = r.rps_debet_credit_indicator
       and r2.rps_schaalbedrag = r.rps_schaalbedrag
       and r2.rps_valutadatum = i_valutadatum);


BEGIN

  open rpst2;
  loop
    fetch rpst2
      into v_schaalbedrag, v_rente_marge, v_basis_opslag;

    exit when rpst2%notfound;

    ONDERHOUD_RENTETABELLEN.vul_rente_perc_schaaltarief(i_muntsoort,
                                                        i_code,
                                                        i_debet_credit_indicator,
                                                        v_schaalbedrag,
                                                        i_valutadatum,
                                                        v_rente_marge,
                                                        v_basis_opslag);
  end loop;
  close rpst2;

END ontbrekende_renteschalen;

-- Deze procedure bepaald de voorgaande header

PROCEDURE vorige_header
( i_muntsoort                    in      rente_perc_schaaltarief.rps_muntsoort%type
 ,i_renteschaal                  in      rente_perc_schaaltarief.rps_code%type
 ,i_bijwerken_vanaf_datum        in      rente_perc_schaaltarief.rps_valutadatum%type
 ,o_bijwerken_vanaf_datum        out     rente_perc_schaaltarief.rps_valutadatum%type)

 AS

BEGIN

select max (c.insh_ingangsdatum)
      into o_bijwerken_vanaf_datum
      from re_interest_scale_hdr_vw c
     where c.insh_muntsoort = i_muntsoort
       and c.insh_ingangsdatum <= i_bijwerken_vanaf_datum
       and c.insh_code = i_renteschaal;
exception
          when no_data_found
          then
-- Indien een basispercentage wordt gewijzigd/ingevoerd dat voor een ingangsdatum van de eerste header
-- ligt dan pakken we de eerste header van de schaal.

select      min (c.insh_ingangsdatum)
           into o_bijwerken_vanaf_datum
           from re_interest_scale_hdr_vw c
          where c.insh_muntsoort = i_muntsoort
            and c.insh_code = i_renteschaal;

END vorige_header;

-- Deze procedure bepaalt of er opgebouwd moet worden of dat de records moeten worden gedelete
PROCEDURE datum_opbouwen
(    i_muntsoort                    in      rente_perc_schaaltarief.rps_muntsoort%type,
     i_code                         in      rente_perc_schaaltarief.rps_code%type,
     i_valutadatum                  in      rente_perc_schaaltarief.rps_valutadatum%type,
     i_vorige_valutadatum           in      rente_perc_schaaltarief.rps_valutadatum%type,
     i_debet_credit_indicator       in      rente_perc_schaaltarief.rps_debet_credit_indicator%type,
     o_opbouwen                     out     number)

AS



BEGIN

begin


-- Zijn alle records voor deze valutadatum all aanwezig (o_opbouwen = 0 ) bij de vorige valutadatum kijken we verder, anders gaan we opbouwen
 select    count (*)
      into o_opbouwen
      from rente_perc_schaaltarief r3
     where r3.rps_muntsoort = i_muntsoort
       and r3.rps_valutadatum = i_valutadatum
       and r3.rps_code = i_code
       and r3.rps_debet_credit_indicator = i_debet_credit_indicator
       and not exists (select 1
                         from rente_perc_schaaltarief r4
                        where r4.rps_muntsoort              = r3.rps_muntsoort
                          and r4.rps_valutadatum            = i_vorige_valutadatum
                          and r4.rps_code                   = r3.rps_code
                          and r4.rps_debet_credit_indicator = r3.rps_debet_credit_indicator
                          and r4.rps_schaalbedrag           = r3.rps_schaalbedrag
                          and r4.rps_rente_marge            = r3.rps_rente_marge
                          and r4.rps_basis_opslag           = r3.rps_basis_opslag
                          and r4.rps_valutadatum           <> r3.rps_valutadatum);

          if o_opbouwen = 0 then

 -- Alle records zijn aanwezig, maar toch opbouwen als er een ingangsdatum van een basispercentage bij deze datum en schaal hoort
            select count (*) into o_opbouwen
              from rente_perc_schaaltarief r, re_interest_scale_dtl_vw v
             where r.rps_muntsoort              = i_muntsoort
               and r.rps_code                   = i_code
               and r.rps_debet_credit_indicator = i_debet_credit_indicator
               and r.rps_valutadatum            = i_valutadatum

               and v.insd_muntsoort         = r.rps_muntsoort
               and v.insd_code              = r.rps_code
               and v.insd_type_credit_debet = r.rps_debet_credit_indicator
               and v.insd_bedrag_vanaf      = r.rps_schaalbedrag
               and v.insd_ingangsdatum      = (select nvl(max (c.insh_ingangsdatum),'00000000')
                                                 from re_interest_scale_hdr_vw c
                                                where c.insh_muntsoort = r.rps_muntsoort
                                                  and c.insh_ingangsdatum <= i_valutadatum
                                                  and c.insh_code = r.rps_code)
                and exists (select 1
                           from re_interest_base_perc_vw b
                          where b.inbp_muntsoort    = r.rps_muntsoort
                            and b.inbp_nummer       = v.insd_basistarief
                            and b.inbp_ingangsdatum = r.rps_valutadatum) ;
                            end if;
              exception
          when no_data_found
          then o_opbouwen := 0;

           end;

END datum_opbouwen;

PROCEDURE aanv_rente_perc_schl_tarief
  (i_muntsoort             in rente_perc_schaaltarief.rps_muntsoort%type,
   i_renteschaal           in rente_perc_schaaltarief.rps_code%type,
   i_debet_credit          in rente_perc_schaaltarief.rps_debet_credit_indicator%type,
   i_bijwerken_vanaf_datum in rente_perc_schaaltarief.rps_valutadatum%type)

 AS

  v_muntsoort              rente_perc_schaaltarief.rps_muntsoort%type;
  v_code                   rente_perc_schaaltarief.rps_code%type;
  v_debet_credit_indicator rente_perc_schaaltarief.rps_debet_credit_indicator%type;
  v_valutadatum            rente_perc_schaaltarief.rps_valutadatum%type;
  v_vorige_valutadatum     rente_perc_schaaltarief.rps_valutadatum%type;
  v_eerste_keer            varchar2(5);
  v_header                 number(4);
  v_bijwerken_vanaf_datum  rente_perc_schaaltarief.rps_valutadatum%type;
  v_opbouwen               number(5);



-- Per valutadatum in rente_perc_schaaltarief kijken of er iets gedaan moet worden
    cursor rpst is
    select a.rps_muntsoort,
           a.rps_code,
           a.rps_debet_credit_indicator,
           a.rps_valutadatum
      from rente_perc_schaaltarief a
     where a.rps_muntsoort = i_muntsoort
       and a.rps_code = i_renteschaal
       and a.rps_debet_credit_indicator = i_debet_credit
       and a.rps_valutadatum >= v_bijwerken_vanaf_datum

     group by a.rps_muntsoort,
              a.rps_code,
              a.rps_debet_credit_indicator,
              a.rps_valutadatum
     order by a.rps_muntsoort,
              a.rps_code,
              a.rps_debet_credit_indicator,
              a.rps_valutadatum;

BEGIN

v_eerste_keer := 'TRUE';

-- Ophalen van de laatste header in re_interest_scale_hdr, die is sowieso goed, vanuit daar opbouwen
ONDERHOUD_RENTETABELLEN.vorige_header (i_muntsoort,i_renteschaal,i_bijwerken_vanaf_datum,v_bijwerken_vanaf_datum);

if v_bijwerken_vanaf_datum is null -- dit is mogelijk als de laatste header is verwijderd
  then
    v_bijwerken_vanaf_datum := i_bijwerken_vanaf_datum;
end if;

  open rpst;
  loop
    fetch rpst
      into v_muntsoort,
           v_code,
           v_debet_credit_indicator,
           v_valutadatum;

           exit when rpst%notfound;

    if v_eerste_keer = 'TRUE' then
      v_vorige_valutadatum := v_valutadatum;
      v_eerste_keer := 'FALSE';
    end if;


   begin
    select 1
    into v_header
              from re_interest_scale_hdr_vw h
             where h.INSH_MUNTSOORT = v_muntsoort
               and h.INSH_CODE = v_code
               and h.INSH_INGANGSDATUM = v_valutadatum;

     exception
         when no_data_found
         then
         v_header := 0;
       end;

-- Als de datum gelijk valt met een header hoeven we niks te doen, dan is het sowieso goed
if v_header = 1 then
v_vorige_valutadatum := v_valutadatum;
end if;

  if v_header = 0 then


-- Kijken of er voor deze datum moet worden opgebouwd of dat alle records moeten worden verwijderd
-- Verwijderen doen we als alle records al bestaan bij de voorgaande valutadatum

    ONDERHOUD_RENTETABELLEN.datum_opbouwen (v_muntsoort,v_code,v_valutadatum,v_vorige_valutadatum,v_debet_credit_indicator,v_opbouwen);


        if v_opbouwen <>0 then

            ONDERHOUD_RENTETABELLEN.ontbrekende_renteschalen(v_muntsoort,
                                                             v_code,
                                                             v_valutadatum,
                                                             v_vorige_valutadatum,
                                                             v_debet_credit_indicator);

         v_vorige_valutadatum := v_valutadatum;

         else

          delete from rente_perc_schaaltarief rd where rd.rps_muntsoort              = v_muntsoort
                                                   and rd.rps_code                   = v_code
                                                   and rd.rps_debet_credit_indicator = v_debet_credit_indicator
                                                   and rd.rps_valutadatum            = v_valutadatum;
        end if;

  end if;

  end loop;
  close rpst;

END aanv_rente_perc_schl_tarief;

FUNCTION version
return varchar2
is

begin
      return gv_versie;
end version;

END;

/*------------------------------------------------------------------------------
history      : 05-JUN-2013, GV, renteafspraken vervangen door re_interest_agreement en rt_ door inag_
                                marges_standen vervangen door re_margin_rates
                                renteschalen_header vervangen door re_interest_scale_hdr en sh_ door insh_
                                renteschalen_detail vervangen door re_interest_scale_dtl en sd_ door insd_
                                rentebasispercentage vervangen door re_interest_base_perc en rbp_ door inbp_
                                namen van procedures zijn hiervan uitgezonderd, deze blijven gelijk
               19-OKT-2013, CV, Nieuwe header tabel re_interest_base_perc_hdr. Muntsoort, nummer
                                en omschrijving  van re_interest_base_perc naar re_interest_base_perc_hdr
                                verplaatst met currency, number en description.
                                De view re_interest_base_perc_vw werd samengesteld uit re_interest_base_perc_hdr
                                en re_interest_base_perc en blijft ongewijzigd.
                                Data type van bovenstaande 3 kolommen gewijzigd van
                                re_interest_base_perc.inbp_nummer%type naar re_interest_base_perc_hdr.inbph_number%type
                                re_interest_base_perc.inbp_muntsoort%type naar re_interest_base_perc_hdr.inbph_currency%type
                                re_interest_base_perc.inbp_omschrijving%type naar re_interest_base_perc_hdr.inbph_description%type
                                namen van procedures zijn hiervan uitgezonderd, deze blijven gelijk
------------------------------------------------------------------------------*/
/
