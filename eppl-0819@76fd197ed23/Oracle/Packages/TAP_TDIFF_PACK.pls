CREATE OR REPLACE package TAP_TDIFF_PACK
is

/*-------------------------------------------------------------------------------------------------------
file        : TAP_TIFF_PACK.pls
description : Specification of TAP_TDIFF_PACK
author      : Able BV, Gert Nijenhuis
history     : 01-JUN-2018, GN Initial creation.
              22-MAR-2022, GN Package modified due to changes in tabel definition of TRANSACTIONS
		      	  12-APR-2022, GN Package modified due to the fact that table TRANS_BELASTINGCOMPONENTEN
			                  has been removed from the database.
			        12-MAY-2023, GN Package modified due to new added tables TAP_POST_ACTION_BATCH and
                              TAP_TR_REL_ACCOUNT_INFO and changes in table definition of TAP_BPS_REGISTER
                              and TRANSACTIONCURRENCYQUOTES
			        7-SEP-2023, GN Package modified due to modification of table TRANSACTIONS.	
              function   version		  
-------------------------------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';

-- procedure tdiff_new_insert:
   procedure tdiff_new_insert
		(i_guid					varchar2
		,i_tr_volgnummer_een	number
		,i_tr_volgnummer_twee	number
		,i_tabelnaam			varchar2
		,i_volgnr				number
		,i_rowid_een			varchar2
		,i_rowid_twee			varchar2
		,i_kolomnaam			varchar2
		,i_kolomwaarde_een		varchar2
		,i_kolomwaarde_twee		varchar2
		);
    
-- procedure tdiff_new:
   procedure tdiff_new
		(i_guid varchar2
,		 i_tr_volgnummer_een number
,		 i_tr_volgnummer_twee number
		);

-- function version
   function version
   return                             varchar2;

END TAP_TDIFF_PACK;
/
CREATE OR REPLACE package body TAP_TDIFF_PACK
is

procedure tdiff_new_insert
	(i_guid					varchar2
,	 i_tr_volgnummer_een	number
,	 i_tr_volgnummer_twee	number
,	 i_tabelnaam			varchar2
,	 i_volgnr				number
,	 i_rowid_een			varchar2
,	 i_rowid_twee			varchar2
,	 i_kolomnaam			varchar2
,	 i_kolomwaarde_een		varchar2
,	 i_kolomwaarde_twee		varchar2
	)
as

begin
	insert
	  into tap_tdiff_table
	values (i_guid
	,i_tr_volgnummer_een
	,i_tr_volgnummer_twee
	,i_tabelnaam
	,i_volgnr
	,i_rowid_een
	,i_rowid_twee
	,i_kolomnaam
	,i_kolomwaarde_een
	,i_kolomwaarde_twee);
end tdiff_new_insert;


procedure tdiff_new
    (i_guid varchar2
,	 i_tr_volgnummer_een number
,	 i_tr_volgnummer_twee number
	)
as

s1	number;

rid_1	rowid;
rid_2	rowid;

r1	TRANSACTIONS%rowtype;
r2	TRANSACTIONS%rowtype;

cursor	c4a is
  SELECT t1.*, ROWID
    FROM DEELTRANSACTIES t1
   WHERE     t1.DT_TRANSACTIEVOLGNR = i_tr_volgnummer_een
         AND NOT EXISTS
                 (SELECT 1
                    FROM DEELTRANSACTIES t2
                   WHERE     t2.DT_TRANSACTIEVOLGNR = i_tr_volgnummer_twee
                         AND t1.dt_deeltransnr = t2.dt_deeltransnr)
ORDER BY t1.DT_TRANSACTIEVOLGNR, t1.DT_DEELTRANSNR;

cursor	c4b is
  SELECT t1.*, ROWID
    FROM DEELTRANSACTIES t1
   WHERE     t1.DT_TRANSACTIEVOLGNR = i_tr_volgnummer_twee
         AND NOT EXISTS
                 (SELECT 1
                    FROM DEELTRANSACTIES t2
                   WHERE     t2.DT_TRANSACTIEVOLGNR = i_tr_volgnummer_een
                         AND t1.dt_deeltransnr = t2.dt_deeltransnr)
ORDER BY t1.DT_TRANSACTIEVOLGNR, t1.DT_DEELTRANSNR;

cursor	c4c is
  SELECT t1.DT_TRANSACTIEVOLGNR     AS DT_TRANSACTIEVOLGNR_OUD,
         t1.DT_DEELTRANSNR          AS DT_DEELTRANSNR_OUD,
         t1.DT_AANTAL               AS DT_AANTAL_OUD,
         t1.DT_PRIJS                AS DT_PRIJS_OUD,
         t1.DT_BEURSPRIJS           AS DT_BEURSPRIJS_OUD,
         t1.DT_EXPORT               AS DT_EXPORT_OUD,
         t1.DT_COMMENTAAR           AS DT_COMMENTAAR_OUD,
         t1.DT_BEURS                AS DT_BEURS_OUD,
         t1.DT_MICO_ID              AS DT_MICO_ID_OUD,
         t1.ROWID                   AS ROWID_OUD,
         t2.DT_TRANSACTIEVOLGNR     AS DT_TRANSACTIEVOLGNR_NW,
         t2.DT_DEELTRANSNR          AS DT_DEELTRANSNR_NW,
         t2.DT_AANTAL               AS DT_AANTAL_NW,
         t2.DT_PRIJS                AS DT_PRIJS_NW,
         t2.DT_BEURSPRIJS           AS DT_BEURSPRIJS_NW,
         t2.DT_EXPORT               AS DT_EXPORT_NW,
         t2.DT_COMMENTAAR           AS DT_COMMENTAAR_NW,
         t2.DT_BEURS                AS DT_BEURS_NW,
         t2.DT_MICO_ID              AS DT_MICO_ID_NW,
         t2.ROWID                   AS ROWID_NW
    FROM DEELTRANSACTIES t1, DEELTRANSACTIES t2
   WHERE     t1.DT_TRANSACTIEVOLGNR = i_tr_volgnummer_een
         AND t2.DT_TRANSACTIEVOLGNR = i_tr_volgnummer_twee
         AND t1.DT_DEELTRANSNR = t2.DT_DEELTRANSNR
ORDER BY t1.DT_TRANSACTIEVOLGNR, t1.DT_DEELTRANSNR;

cursor	c5a is
 SELECT t1.*, ROWID
    FROM TRANS_OMSCHRIJVING t1
   WHERE     t1.TO_TRANSACTIEVOLGNR = i_tr_volgnummer_een
         AND NOT EXISTS
                 (SELECT 1
                    FROM TRANS_OMSCHRIJVING t2
                   WHERE t2.TO_TRANSACTIEVOLGNR = i_tr_volgnummer_twee)
ORDER BY t1.TO_TRANSACTIEVOLGNR;

cursor	c5b is
  SELECT t1.*, ROWID
    FROM TRANS_OMSCHRIJVING t1
   WHERE     t1.TO_TRANSACTIEVOLGNR = i_tr_volgnummer_twee
         AND NOT EXISTS
                 (SELECT 1
                    FROM TRANS_OMSCHRIJVING t2
                   WHERE t2.TO_TRANSACTIEVOLGNR = i_tr_volgnummer_een)
ORDER BY t1.TO_TRANSACTIEVOLGNR;

cursor	c5c is
  SELECT t1.TO_TRANSACTIEVOLGNR            AS TO_TRANSACTIEVOLGNR_OUD,
         t1.TO_OMSCHRIJVING1               AS TO_OMSCHRIJVING1_OUD,
         t1.TO_EXPORT                      AS TO_EXPORT_OUD,
         t1.TO_RELATIE_OW                  AS TO_RELATIE_OW_OUD,
         t1.TO_REK1_OW                     AS TO_REK1_OW_OUD,
         t1.TO_REKSRT1_OW                  AS TO_REKSRT1_OW_OUD,
         t1.TO_UITVOERINGSKOSTEN           AS TO_UITVOERINGSKOSTEN_OUD,
         t1.TO_ALGEMENEKOSTEN              AS TO_ALGEMENEKOSTEN_OUD,
         t1.TO_ORDERBEHANDKOSTEN           AS TO_ORDERBEHANDKOSTEN_OUD,
         t1.TO_ITEM_PROVCOMP1              AS TO_ITEM_PROVCOMP1_OUD,
         t1.TO_BEDR_PROVCOMP1              AS TO_BEDR_PROVCOMP1_OUD,
         t1.TO_ITEM_PROVCOMP2              AS TO_ITEM_PROVCOMP2_OUD,
         t1.TO_BEDR_PROVCOMP2              AS TO_BEDR_PROVCOMP2_OUD,
         t1.TO_ITEM_PROVCOMP3              AS TO_ITEM_PROVCOMP3_OUD,
         t1.TO_BEDR_PROVCOMP3              AS TO_BEDR_PROVCOMP3_OUD,
         t1.TO_ITEM_PROVCOMP4              AS TO_ITEM_PROVCOMP4_OUD,
         t1.TO_BEDR_PROVCOMP4              AS TO_BEDR_PROVCOMP4_OUD,
         t1.TO_ITEM_PROVCOMP5              AS TO_ITEM_PROVCOMP5_OUD,
         t1.TO_BEDR_PROVCOMP5              AS TO_BEDR_PROVCOMP5_OUD,
         t1.TO_ITEM_PROVCOMP6              AS TO_ITEM_PROVCOMP6_OUD,
         t1.TO_BEDR_PROVCOMP6              AS TO_BEDR_PROVCOMP6_OUD,
         t1.TO_ITEM_PROVCOMP7              AS TO_ITEM_PROVCOMP7_OUD,
         t1.TO_BEDR_PROVCOMP7              AS TO_BEDR_PROVCOMP7_OUD,
         t1.TO_ITEM_PROVCOMP8              AS TO_ITEM_PROVCOMP8_OUD,
         t1.TO_BEDR_PROVCOMP8              AS TO_BEDR_PROVCOMP8_OUD,
         t1.TO_ITEM_PROVCOMP9              AS TO_ITEM_PROVCOMP9_OUD,
         t1.TO_BEDR_PROVCOMP9              AS TO_BEDR_PROVCOMP9_OUD,
         t1.TO_ITEM_PROVCOMP10             AS TO_ITEM_PROVCOMP10_OUD,
         t1.TO_BEDR_PROVCOMP10             AS TO_BEDR_PROVCOMP10_OUD,
         t1.TO_ITEM_PROVCOMP11             AS TO_ITEM_PROVCOMP11_OUD,
         t1.TO_BEDR_PROVCOMP11             AS TO_BEDR_PROVCOMP11_OUD,
         t1.TO_ITEM_PROVCOMP12             AS TO_ITEM_PROVCOMP12_OUD,
         t1.TO_BEDR_PROVCOMP12             AS TO_BEDR_PROVCOMP12_OUD,
         t1.TO_OMSCHRIJVING2               AS TO_OMSCHRIJVING2_OUD,
         t1.TO_OMSCHRIJVING3               AS TO_OMSCHRIJVING3_OUD,
         t1.TO_OMSCHRIJVING4               AS TO_OMSCHRIJVING4_OUD,
         t1.TO_OPDRGEVER_BEGUNST           AS TO_OPDRGEVER_BEGUNST_OUD,
         t1.TO_OPDRACHT_BEG_BANK           AS TO_OPDRACHT_BEG_BANK_OUD,
         t1.TO_EXTERNREKENINGNR            AS TO_EXTERNREKENINGNR_OUD,
         t1.TO_WOONPLAATS                  AS TO_WOONPLAATS_OUD,
         t1.TO_OMSCHRIJVING5               AS TO_OMSCHRIJVING5_OUD,
         t1.TO_CONCEPT_STORNERING          AS TO_CONCEPT_STORNERING_OUD,
         t1.TO_AFWIJKING_TRANS_PROFIEL     AS TO_AFWIJKING_TRANS_PROFIEL_OUD,
         t1.TO_STORNO_REASON               AS TO_STORNO_REASON_OUD,
         t1.ROWID                          AS ROWID_OUD,
         t2.TO_TRANSACTIEVOLGNR            AS TO_TRANSACTIEVOLGNR_NW,
         t2.TO_OMSCHRIJVING1               AS TO_OMSCHRIJVING1_NW,
         t2.TO_EXPORT                      AS TO_EXPORT_NW,
         t2.TO_RELATIE_OW                  AS TO_RELATIE_OW_NW,
         t2.TO_REK1_OW                     AS TO_REK1_OW_NW,
         t2.TO_REKSRT1_OW                  AS TO_REKSRT1_OW_NW,
         t2.TO_UITVOERINGSKOSTEN           AS TO_UITVOERINGSKOSTEN_NW,
         t2.TO_ALGEMENEKOSTEN              AS TO_ALGEMENEKOSTEN_NW,
         t2.TO_ORDERBEHANDKOSTEN           AS TO_ORDERBEHANDKOSTEN_NW,
         t2.TO_ITEM_PROVCOMP1              AS TO_ITEM_PROVCOMP1_NW,
         t2.TO_BEDR_PROVCOMP1              AS TO_BEDR_PROVCOMP1_NW,
         t2.TO_ITEM_PROVCOMP2              AS TO_ITEM_PROVCOMP2_NW,
         t2.TO_BEDR_PROVCOMP2              AS TO_BEDR_PROVCOMP2_NW,
         t2.TO_ITEM_PROVCOMP3              AS TO_ITEM_PROVCOMP3_NW,
         t2.TO_BEDR_PROVCOMP3              AS TO_BEDR_PROVCOMP3_NW,
         t2.TO_ITEM_PROVCOMP4              AS TO_ITEM_PROVCOMP4_NW,
         t2.TO_BEDR_PROVCOMP4              AS TO_BEDR_PROVCOMP4_NW,
         t2.TO_ITEM_PROVCOMP5              AS TO_ITEM_PROVCOMP5_NW,
         t2.TO_BEDR_PROVCOMP5              AS TO_BEDR_PROVCOMP5_NW,
         t2.TO_ITEM_PROVCOMP6              AS TO_ITEM_PROVCOMP6_NW,
         t2.TO_BEDR_PROVCOMP6              AS TO_BEDR_PROVCOMP6_NW,
         t2.TO_ITEM_PROVCOMP7              AS TO_ITEM_PROVCOMP7_NW,
         t2.TO_BEDR_PROVCOMP7              AS TO_BEDR_PROVCOMP7_NW,
         t2.TO_ITEM_PROVCOMP8              AS TO_ITEM_PROVCOMP8_NW,
         t2.TO_BEDR_PROVCOMP8              AS TO_BEDR_PROVCOMP8_NW,
         t2.TO_ITEM_PROVCOMP9              AS TO_ITEM_PROVCOMP9_NW,
         t2.TO_BEDR_PROVCOMP9              AS TO_BEDR_PROVCOMP9_NW,
         t2.TO_ITEM_PROVCOMP10             AS TO_ITEM_PROVCOMP10_NW,
         t2.TO_BEDR_PROVCOMP10             AS TO_BEDR_PROVCOMP10_NW,
         t2.TO_ITEM_PROVCOMP11             AS TO_ITEM_PROVCOMP11_NW,
         t2.TO_BEDR_PROVCOMP11             AS TO_BEDR_PROVCOMP11_NW,
         t2.TO_ITEM_PROVCOMP12             AS TO_ITEM_PROVCOMP12_NW,
         t2.TO_BEDR_PROVCOMP12             AS TO_BEDR_PROVCOMP12_NW,
         t2.TO_OMSCHRIJVING2               AS TO_OMSCHRIJVING2_NW,
         t2.TO_OMSCHRIJVING3               AS TO_OMSCHRIJVING3_NW,
         t2.TO_OMSCHRIJVING4               AS TO_OMSCHRIJVING4_NW,
         t2.TO_OPDRGEVER_BEGUNST           AS TO_OPDRGEVER_BEGUNST_NW,
         t2.TO_OPDRACHT_BEG_BANK           AS TO_OPDRACHT_BEG_BANK_NW,
         t2.TO_EXTERNREKENINGNR            AS TO_EXTERNREKENINGNR_NW,
         t2.TO_WOONPLAATS                  AS TO_WOONPLAATS_NW,
         t2.TO_OMSCHRIJVING5               AS TO_OMSCHRIJVING5_NW,
         t2.TO_CONCEPT_STORNERING          AS TO_CONCEPT_STORNERING_NW,
         t2.TO_AFWIJKING_TRANS_PROFIEL     AS TO_AFWIJKING_TRANS_PROFIEL_NW,
         t2.TO_STORNO_REASON               AS TO_STORNO_REASON_NW,
         t2.ROWID                          AS ROWID_NW
    FROM TRANS_OMSCHRIJVING t1, TRANS_OMSCHRIJVING t2
   WHERE     t1.TO_TRANSACTIEVOLGNR = i_tr_volgnummer_een
         AND t2.TO_TRANSACTIEVOLGNR = i_tr_volgnummer_twee
ORDER BY t1.TO_TRANSACTIEVOLGNR;

cursor	c7a is
  SELECT t1.*, ROWID
    FROM TAP_BPS_REGISTER t1
   WHERE     t1.BPSR_TR_VOLGNUMMER = i_tr_volgnummer_een
         AND NOT EXISTS
                 (SELECT 1
                    FROM TAP_BPS_REGISTER t2
                   WHERE t2.BPSR_TR_VOLGNUMMER = i_tr_volgnummer_twee)
ORDER BY t1.BPSR_TR_VOLGNUMMER;

cursor	c7b is
  SELECT t1.*, ROWID
    FROM TAP_BPS_REGISTER t1
   WHERE     t1.BPSR_TR_VOLGNUMMER = i_tr_volgnummer_twee
         AND NOT EXISTS
                 (SELECT 1
                    FROM TAP_BPS_REGISTER t2
                   WHERE t2.BPSR_TR_VOLGNUMMER = i_tr_volgnummer_een)
ORDER BY t1.BPSR_TR_VOLGNUMMER;

cursor	c7c is
  SELECT t1.BPSR_PPR_ID                AS BPSR_PPR_ID_OUD,
         t1.BPSR_YEAR                  AS BPSR_YEAR_OUD,
         t1.BPSR_SEQ                   AS BPSR_SEQ_OUD,
         t1.BPSR_TR_VOLGNUMMER         AS BPSR_TR_VOLGNUMMER_OUD,
         t1.BPSR_USER_ID               AS BPSR_USER_ID_OUD,
         t1.BPSR_REFERENCE_DATE        AS BPSR_REFERENCE_DATE_OUD,
         t1.BPSR_ID                    AS BPSR_ID_OUD,
         t1.BPSR_BE_VOLGNUMMER         AS BPSR_BE_VOLGNUMMER_OUD,
         t1.BPSR_REGISTERINDICATOR     AS BPSR_REGISTERINDICATOR_OUD,
         t1.BPSR_EXPORT_DATE_TIME      AS BPSR_EXPORT_DATE_TIME_OUD,
         t1.BPSR_REPORT                AS BPSR_REPORT_OUD,
		 t1.BPSR_IS_CONVERTED		   AS BPSR_IS_CONVERTED_OUD,
		 t1.BPSR_ID_ORIGIN			   AS BPSR_ID_ORIGIN_OUD,
         t1.ROWID                      AS ROWID_OUD,
         t2.BPSR_PPR_ID                AS BPSR_PPR_ID_NW,
         t2.BPSR_YEAR                  AS BPSR_YEAR_NW,
         t2.BPSR_SEQ                   AS BPSR_SEQ_NW,
         t2.BPSR_TR_VOLGNUMMER         AS BPSR_TR_VOLGNUMMER_NW,
         t2.BPSR_USER_ID               AS BPSR_USER_ID_NW,
         t2.BPSR_REFERENCE_DATE        AS BPSR_REFERENCE_DATE_NW,
         t2.BPSR_ID                    AS BPSR_ID_NW,
         t2.BPSR_BE_VOLGNUMMER         AS BPSR_BE_VOLGNUMMER_NW,
         t2.BPSR_REGISTERINDICATOR     AS BPSR_REGISTERINDICATOR_NW,
         t2.BPSR_EXPORT_DATE_TIME      AS BPSR_EXPORT_DATE_TIME_NW,
         t2.BPSR_REPORT                AS BPSR_REPORT_NW,
		 t2.BPSR_IS_CONVERTED		   AS BPSR_IS_CONVERTED_NW,
		 t2.BPSR_ID_ORIGIN			   AS BPSR_ID_ORIGIN_NW,	 
         t2.ROWID                      AS ROWID_NW
    FROM TAP_BPS_REGISTER t1, TAP_BPS_REGISTER t2
   WHERE     t1.BPSR_TR_VOLGNUMMER = i_tr_volgnummer_een
         AND t2.BPSR_TR_VOLGNUMMER = i_tr_volgnummer_twee
ORDER BY t1.BPSR_TR_VOLGNUMMER;

cursor	c10a is
  SELECT t1.*, ROWID
    FROM TRANSACTIONCURRENCYQUOTES t1
   WHERE     t1.TR_VOLGNUMMER = i_tr_volgnummer_een
         AND NOT EXISTS
                 (SELECT 1
                    FROM TRANSACTIONCURRENCYQUOTES t2
                   WHERE     t2.tr_volgnummer = i_tr_volgnummer_twee
                         AND t1.class = t2.class)
ORDER BY t1.tr_volgnummer, t1.class;

cursor	c10b is
  SELECT t1.*, ROWID
    FROM TRANSACTIONCURRENCYQUOTES t1
   WHERE     t1.TR_VOLGNUMMER = i_tr_volgnummer_twee
         AND NOT EXISTS
                 (SELECT 1
                    FROM TRANSACTIONCURRENCYQUOTES t2
                   WHERE     t2.tr_volgnummer = i_tr_volgnummer_een
                         AND t1.class = t2.class)
ORDER BY t1.tr_volgnummer, t1.class;

cursor	c10c is
  SELECT t1.TR_VOLGNUMMER     AS TR_VOLGNUMMER_OUD,
         t1.CLASS             AS CLASS_OUD,
         t1.CURRENCY          AS CURRENCY_OUD,
         t1.FACTOR            AS FACTOR_OUD,
         t1.QUOTE             AS QUOTE_OUD,
         t1.RECIPROKE         AS RECIPROKE_OUD,
		 t1.SPREAD			  AS SPREAD_OUD,
         t1.ROWID             AS ROWID_OUD,
         t2.TR_VOLGNUMMER     AS TR_VOLGNUMMER_NW,
         t2.CLASS             AS CLASS_NW,
         t2.CURRENCY          AS CURRENCY_NW,
         t2.FACTOR            AS FACTOR_NW,
         t2.QUOTE             AS QUOTE_NW,
         t2.RECIPROKE         AS RECIPROKE_NW,
		 t2.SPREAD			  AS SPREAD_NW,
         t2.ROWID             AS ROWID_NW
    FROM TRANSACTIONCURRENCYQUOTES t1, TRANSACTIONCURRENCYQUOTES t2
   WHERE     t1.TR_VOLGNUMMER = i_tr_volgnummer_een
         AND t2.tr_volgnummer = i_tr_volgnummer_twee
         AND t1.class = t2.class
ORDER BY t1.tr_volgnummer, t1.class;

cursor	c11a is
  SELECT t1.*, ROWID
    FROM TRANS_KOSTENCOMPONENTEN t1
   WHERE     t1.TKC_VOLGNUMMER = i_tr_volgnummer_een
         AND NOT EXISTS
                 (SELECT 1
                    FROM TRANS_KOSTENCOMPONENTEN t2
                   WHERE     t2.tkc_volgnummer = i_tr_volgnummer_twee
                         AND t1.TKC_COMPONENTCODE = t2.TKC_COMPONENTCODE)
ORDER BY t1.TKC_VOLGNUMMER, t1.TKC_COMPONENTCODE;

cursor	c11b is
  SELECT t1.*, ROWID
    FROM TRANS_KOSTENCOMPONENTEN t1
   WHERE     t1.TKC_VOLGNUMMER = i_tr_volgnummer_twee
         AND NOT EXISTS
                 (SELECT 1
                    FROM TRANS_KOSTENCOMPONENTEN t2
                   WHERE     t2.tkc_volgnummer = i_tr_volgnummer_een
                         AND t1.TKC_COMPONENTCODE = t2.TKC_COMPONENTCODE)
ORDER BY t1.TKC_VOLGNUMMER, t1.TKC_COMPONENTCODE;

cursor	c11c is
  SELECT t1.TKC_VOLGNUMMER           AS TKC_VOLGNUMMER_OUD,
         t1.TKC_COMPONENTCODE        AS TKC_COMPONENTCODE_OUD,
         t1.TKC_BEDRAG               AS TKC_BEDRAG_OUD,
         t1.TKC_MUNTSOORT            AS TKC_MUNTSOORT_OUD,
         t1.TKC_BEDRAG_TRANS_VAL     AS TKC_BEDRAG_TRANS_VAL_OUD,
         t1.TKC_BOEK_BEDRAG          AS TKC_BOEK_BEDRAG_OUD,
         t1.TKC_BOEK_VALUTA          AS TKC_BOEK_VALUTA_OUD,
         t1.TKC_RE_ID                AS TKC_RE_ID_OUD,
         t1.TKC_MUT_GEMAAKT          AS TKC_MUT_GEMAAKT_OUD,
         t1.ROWID                    AS ROWID_OUD,
         t2.TKC_VOLGNUMMER           AS TKC_VOLGNUMMER_NW,
         t2.TKC_COMPONENTCODE        AS TKC_COMPONENTCODE_NW,
         t2.TKC_BEDRAG               AS TKC_BEDRAG_NW,
         t2.TKC_MUNTSOORT            AS TKC_MUNTSOORT_NW,
         t2.TKC_BEDRAG_TRANS_VAL     AS TKC_BEDRAG_TRANS_VAL_NW,
         t2.TKC_BOEK_BEDRAG          AS TKC_BOEK_BEDRAG_NW,
         t2.TKC_BOEK_VALUTA          AS TKC_BOEK_VALUTA_NW,
         t2.TKC_RE_ID                AS TKC_RE_ID_NW,
         t2.TKC_MUT_GEMAAKT          AS TKC_MUT_GEMAAKT_NW,
         t2.ROWID                    AS ROWID_NW
    FROM TRANS_KOSTENCOMPONENTEN t1, TRANS_KOSTENCOMPONENTEN t2
   WHERE     t1.TKC_VOLGNUMMER = i_tr_volgnummer_een
         AND t2.TKC_VOLGNUMMER = i_tr_volgnummer_twee
         AND t1.TKC_COMPONENTCODE = t2.TKC_COMPONENTCODE
ORDER BY t1.TKC_VOLGNUMMER, t1.TKC_COMPONENTCODE;

cursor	c12a is
  SELECT t1.*, ROWID
    FROM TRANS_CALC_COMPONENTS t1
   WHERE     t1.TCC_TR_ID = i_tr_volgnummer_een
         AND NOT EXISTS
                 (SELECT 1
                    FROM TRANS_CALC_COMPONENTS t2
                   WHERE     t2.TCC_TR_ID = i_tr_volgnummer_twee
                         AND t1.TCC_CFCU_ID = t2.TCC_CFCU_ID)
ORDER BY t1.TCC_TR_ID, t1.TCC_CFCU_ID;

cursor	c12b is
  SELECT t1.*, ROWID
    FROM TRANS_CALC_COMPONENTS t1
   WHERE     t1.TCC_TR_ID = i_tr_volgnummer_twee
         AND NOT EXISTS
                 (SELECT 1
                    FROM TRANS_CALC_COMPONENTS t2
                   WHERE     t2.TCC_TR_ID = i_tr_volgnummer_een
                         AND t1.TCC_CFCU_ID = t2.TCC_CFCU_ID)
ORDER BY t1.TCC_TR_ID, t1.TCC_CFCU_ID;

cursor	c12c is
  SELECT t1.TCC_TR_ID              AS TCC_TR_ID_OUD,
         t1.TCC_CFCU_ID            AS TCC_CFCU_ID_OUD,
         t1.TCC_COMPONENT_CODE     AS TCC_COMPONENT_CODE_OUD,
         t1.TCC_DISCOUNT_PERC      AS TCC_DISCOUNT_PERC_OUD,
         t1.TCC_RE_ID              AS TCC_RE_ID_OUD,
         t1.BASE_AMOUNT_SYST       AS BASE_AMOUNT_SYST_OUD,
         t1.BASE_AMOUNT_PARTY      AS BASE_AMOUNT_PARTY_OUD,
         t1.BASE_AMOUNT_TRANS      AS BASE_AMOUNT_TRANS_OUD,
         t1.BASE_QUANTITY          AS BASE_QUANTITY_OUD,
         t1.BASE_QTY_FACTOR        AS BASE_QTY_FACTOR_OUD,
         t1.BASE_QTY_SCALE         AS BASE_QTY_SCALE_OUD,
         t1.TARIFF_AMOUNT          AS TARIFF_AMOUNT_OUD,
         t1.TARIFF_PERCENTAGE      AS TARIFF_PERCENTAGE_OUD,
         t1.TARIFF_METHOD          AS TARIFF_METHOD_OUD,
         t1.ROWID                  AS ROWID_OUD,
         t2.TCC_TR_ID              AS TCC_TR_ID_NW,
         t2.TCC_CFCU_ID            AS TCC_CFCU_ID_NW,
         t2.TCC_COMPONENT_CODE     AS TCC_COMPONENT_CODE_NW,
         t2.TCC_DISCOUNT_PERC      AS TCC_DISCOUNT_PERC_NW,
         t2.TCC_RE_ID              AS TCC_RE_ID_NW,
         t2.BASE_AMOUNT_SYST       AS BASE_AMOUNT_SYST_NW,
         t2.BASE_AMOUNT_PARTY      AS BASE_AMOUNT_PARTY_NW,
         t2.BASE_AMOUNT_TRANS      AS BASE_AMOUNT_TRANS_NW,
         t2.BASE_QUANTITY          AS BASE_QUANTITY_NW,
         t2.BASE_QTY_FACTOR        AS BASE_QTY_FACTOR_NW,
         t2.BASE_QTY_SCALE         AS BASE_QTY_SCALE_NW,
         t2.TARIFF_AMOUNT          AS TARIFF_AMOUNT_NW,
         t2.TARIFF_PERCENTAGE      AS TARIFF_PERCENTAGE_NW,
         t2.TARIFF_METHOD          AS TARIFF_METHOD_NW,
         t2.ROWID                  AS ROWID_NW
    FROM TRANS_CALC_COMPONENTS t1, TRANS_CALC_COMPONENTS t2
   WHERE     t1.TCC_TR_ID = i_tr_volgnummer_een
         AND t2.TCC_TR_ID = i_tr_volgnummer_twee
         AND t1.TCC_CFCU_ID = t2.TCC_CFCU_ID
ORDER BY t1.TCC_TR_ID, t1.TCC_CFCU_ID;

cursor  c13a is
  SELECT t1.*, ROWID
    FROM TRANS_SUBCALC_COMPONENTS t1
   WHERE     t1.TSCC_TCC_TR_ID = i_tr_volgnummer_een
         AND NOT EXISTS
                 (SELECT 1
                    FROM TRANS_SUBCALC_COMPONENTS t2
                   WHERE     t2.TSCC_TCC_TR_ID = i_tr_volgnummer_twee
                         AND t1.TSCC_TCC_CFCU_ID = t2.TSCC_TCC_CFCU_ID
                         AND t1.TSCC_AMOUNT_TYPE = t2.TSCC_AMOUNT_TYPE)
ORDER BY t1.TSCC_TCC_TR_ID, t1.TSCC_TCC_CFCU_ID, t1.TSCC_AMOUNT_TYPE;

cursor  c13b is
  SELECT t1.*, ROWID
    FROM TRANS_SUBCALC_COMPONENTS t1
   WHERE     t1.TSCC_TCC_TR_ID = i_tr_volgnummer_twee
         AND NOT EXISTS
                 (SELECT 1
                    FROM TRANS_SUBCALC_COMPONENTS t2
                   WHERE     t2.TSCC_TCC_TR_ID = i_tr_volgnummer_een
                         AND t1.TSCC_TCC_CFCU_ID = t2.TSCC_TCC_CFCU_ID
                         AND t1.TSCC_AMOUNT_TYPE = t2.TSCC_AMOUNT_TYPE)
ORDER BY t1.TSCC_TCC_TR_ID, t1.TSCC_TCC_CFCU_ID, t1.TSCC_AMOUNT_TYPE;

cursor  c13c is
  SELECT t1.TSCC_TCC_TR_ID        AS TSCC_TCC_TR_ID_OUD,
         t1.TSCC_TCC_CFCU_ID      AS TSCC_TCC_CFCU_ID_OUD,
         t1.TSCC_AMOUNT_TYPE      AS TSCC_AMOUNT_TYPE_OUD,
         t1.TSCC_AMOUNT_SYST      AS TSCC_AMOUNT_SYST_OUD,
         t1.TSCC_AMOUNT_TRANS     AS TSCC_AMOUNT_TRANS_OUD,
         t1.TSCC_AMOUNT_PARTY     AS TSCC_AMOUNT_PARTY_OUD,
         t1.ROWID                 AS ROWID_OUD,
         t2.TSCC_TCC_TR_ID        AS TSCC_TCC_TR_ID_NW,
         t2.TSCC_TCC_CFCU_ID      AS TSCC_TCC_CFCU_ID_NW,
         t2.TSCC_AMOUNT_TYPE      AS TSCC_AMOUNT_TYPE_NW,
         t2.TSCC_AMOUNT_SYST      AS TSCC_AMOUNT_SYST_NW,
         t2.TSCC_AMOUNT_TRANS     AS TSCC_AMOUNT_TRANS_NW,
         t2.TSCC_AMOUNT_PARTY     AS TSCC_AMOUNT_PARTY_NW,
         t2.ROWID                 AS ROWID_NW
    FROM TRANS_SUBCALC_COMPONENTS t1, TRANS_SUBCALC_COMPONENTS t2
   WHERE     t1.TSCC_TCC_TR_ID = i_tr_volgnummer_een
         AND t2.TSCC_TCC_TR_ID = i_tr_volgnummer_twee
         AND t1.TSCC_TCC_CFCU_ID = t2.TSCC_TCC_CFCU_ID
         AND t1.TSCC_AMOUNT_TYPE = t2.TSCC_AMOUNT_TYPE
ORDER BY t1.TSCC_TCC_TR_ID, t1.TSCC_TCC_CFCU_ID, t1.TSCC_AMOUNT_TYPE;

cursor  c14a is
  SELECT t1.*, ROWID
    FROM TAP_TR_REL_ACCOUNT_INFO t1
   WHERE     t1.TRAI_TR_VOLGNUMMER = i_tr_volgnummer_een
         AND NOT EXISTS
                 (SELECT 1
                    FROM TAP_TR_REL_ACCOUNT_INFO t2
                   WHERE     t2.TRAI_TR_VOLGNUMMER = i_tr_volgnummer_twee
                         AND t1.TRAI_TR_ACCOUNT_CODE = t2.TRAI_TR_ACCOUNT_CODE)
ORDER BY t1.TRAI_TR_VOLGNUMMER, t1.TRAI_TR_ACCOUNT_CODE;

cursor  c14b is
  SELECT t1.*, ROWID
    FROM TAP_TR_REL_ACCOUNT_INFO t1
   WHERE     t1.TRAI_TR_VOLGNUMMER = i_tr_volgnummer_twee
         AND NOT EXISTS
                 (SELECT 1
                    FROM TAP_TR_REL_ACCOUNT_INFO t2
                   WHERE     t2.TRAI_TR_VOLGNUMMER = i_tr_volgnummer_een
                         AND t1.TRAI_TR_ACCOUNT_CODE = t2.TRAI_TR_ACCOUNT_CODE)
ORDER BY t1.TRAI_TR_VOLGNUMMER, t1.TRAI_TR_ACCOUNT_CODE;

cursor	c14c is
  SELECT t1.TRAI_TR_VOLGNUMMER      AS TRAI_TR_VOLGNUMMER_OUD,
         t1.TRAI_TR_ACCOUNT_CODE    AS TRAI_TR_ACCOUNT_CODE_OUD,
         t1.TRAI_TR_CL_ID     		AS TRAI_TR_CL_ID_OUD,
         t1.TRAI_TR_RE_ID      		AS TRAI_TR_RE_ID_OUD,
         t1.ROWID                  	AS ROWID_OUD,
         t2.TRAI_TR_VOLGNUMMER      AS TRAI_TR_VOLGNUMMER_NW,
         t2.TRAI_TR_ACCOUNT_CODE    AS TRAI_TR_ACCOUNT_CODE_NW,
         t2.TRAI_TR_CL_ID     		AS TRAI_TR_CL_ID_NW,
         t2.TRAI_TR_RE_ID      		AS TRAI_TR_RE_ID_NW,
         t2.ROWID                   AS ROWID_NW
    FROM TAP_TR_REL_ACCOUNT_INFO t1, TAP_TR_REL_ACCOUNT_INFO t2
   WHERE     t1.TRAI_TR_VOLGNUMMER = i_tr_volgnummer_een
         AND t2.TRAI_TR_VOLGNUMMER = i_tr_volgnummer_twee
         AND t1.TRAI_TR_ACCOUNT_CODE = t2.TRAI_TR_ACCOUNT_CODE
ORDER BY t1.TRAI_TR_VOLGNUMMER, t1.TRAI_TR_ACCOUNT_CODE;

cursor  c15a is
  SELECT t1.*, ROWID
    FROM TAP_POST_ACTION_BATCH t1
   WHERE     t1.TR_ID = i_tr_volgnummer_een
         AND NOT EXISTS
                 (SELECT 1
                    FROM TAP_POST_ACTION_BATCH t2
                   WHERE     t2.TR_ID = i_tr_volgnummer_twee
                         AND t1.POST_ACTION = t2.POST_ACTION)
ORDER BY t1.TR_ID, t1.POST_ACTION;

cursor  c15b is
  SELECT t1.*, ROWID
    FROM TAP_POST_ACTION_BATCH t1
   WHERE     t1.TR_ID = i_tr_volgnummer_twee
         AND NOT EXISTS
                 (SELECT 1
                    FROM TAP_POST_ACTION_BATCH t2
                   WHERE     t2.TR_ID = i_tr_volgnummer_een
                         AND t1.POST_ACTION = t2.POST_ACTION)
ORDER BY t1.TR_ID, t1.POST_ACTION;

cursor	c15c is
  SELECT t1.TR_ID      	AS TR_ID_OUD,
         t1.POST_ACTION AS POST_ACTION_OUD,
         t1.ROWID       AS ROWID_OUD,
         t2.TR_ID       AS TR_ID_NW,
         t2.POST_ACTION AS POST_ACTION_NW,
         t2.ROWID       AS ROWID_NW
    FROM TAP_POST_ACTION_BATCH t1, TAP_POST_ACTION_BATCH t2
   WHERE     t1.TR_ID = i_tr_volgnummer_een
         AND t2.TR_ID = i_tr_volgnummer_twee
         AND t1.POST_ACTION = t2.POST_ACTION
ORDER BY t1.TR_ID, t1.POST_ACTION;

begin

--
-- TRANSACTIONS
--

   begin
     select rowid into rid_1 from TRANSACTIONS where tr_volgnummer =  i_tr_volgnummer_een;
   exception
     when others then raise_application_error(-20000,'Unknown Transaction One : ' || to_char(i_tr_volgnummer_een));
   end;

   begin
     select rowid into rid_2 from TRANSACTIONS where tr_volgnummer =  i_tr_volgnummer_twee;
   exception
     when others then raise_application_error(-20000,'Unknown Transaction Two : ' || to_char(i_tr_volgnummer_twee));
   end;

   begin
     select * into r1 from TRANSACTIONS where rowid = rid_1;
   exception
     when others then null;
   end;

   begin
     select * into r2 from TRANSACTIONS where rowid = rid_2;
   exception
     when others then null;
   end;

   s1 := 1;

   if nvl(to_char(r1.TR_TRANSNUMMER),'NULL') <> nvl(to_char(r2.TR_TRANSNUMMER),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TRANSNUMMER',r1.TR_TRANSNUMMER,r2.TR_TRANSNUMMER);end if;
--   if nvl(to_char(r1.TR_INVOERNUMMER),'NULL') <> nvl(to_char(r2.TR_INVOERNUMMER),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_INVOERNUMMER',r1.TR_INVOERNUMMER,r2.TR_INVOERNUMMER);end if;
--   if nvl(to_char(r1.TR_TERMINALNUMMER),'NULL')	<> nvl(to_char(r2.TR_TERMINALNUMMER),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TERMINALNUMMER',r1.TR_TERMINALNUMMER,r2.TR_TERMINALNUMMER);end if;
   if nvl(to_char(r1.TR_REL1),'NULL') <> nvl(to_char(r2.TR_REL1),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1',r1.TR_REL1,r2.TR_REL1);end if;
   if nvl(to_char(r1.TR_REL1_REK1),'NULL') <> nvl(to_char(r2.TR_REL1_REK1),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_REK1',r1.TR_REL1_REK1,r2.TR_REL1_REK1);end if;
   if nvl(to_char(r1.TR_REL1_REK1_SOORT),'NULL') <> nvl(to_char(r2.TR_REL1_REK1_SOORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_REK1_SOORT',r1.TR_REL1_REK1_SOORT,r2.TR_REL1_REK1_SOORT);end if;
   if nvl(to_char(r1.TR_REL1_RAP_MUNTS),'NULL')	<> nvl(to_char(r2.TR_REL1_RAP_MUNTS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_RAP_MUNTS',r1.TR_REL1_RAP_MUNTS,r2.TR_REL1_RAP_MUNTS);end if;
   if nvl(to_char(r1.TR_REL1_RAP_KRS),'NULL') <> nvl(to_char(r2.TR_REL1_RAP_KRS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_RAP_KRS',r1.TR_REL1_RAP_KRS,r2.TR_REL1_RAP_KRS);end if;
   if nvl(to_char(r1.TR_REL1_RAP_FAC),'NULL') <> nvl(to_char(r2.TR_REL1_RAP_FAC),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_RAP_FAC',r1.TR_REL1_RAP_FAC,r2.TR_REL1_RAP_FAC);end if;
   if nvl(to_char(r1.TR_REL1_REK2),'NULL') <> nvl(to_char(r2.TR_REL1_REK2),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_REK2',r1.TR_REL1_REK2,r2.TR_REL1_REK2);end if;
   if nvl(to_char(r1.TR_REL1_REK2_SOORT),'NULL') <> nvl(to_char(r2.TR_REL1_REK2_SOORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_REK2_SOORT',r1.TR_REL1_REK2_SOORT,r2.TR_REL1_REK2_SOORT);end if;
   if nvl(to_char(r1.TR_REL1_REK2_MUNTS),'NULL') <> nvl(to_char(r2.TR_REL1_REK2_MUNTS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_REK2_MUNTS',r1.TR_REL1_REK2_MUNTS,r2.TR_REL1_REK2_MUNTS);end if;
   if nvl(to_char(r1.TR_REL1_REK2_KANT_NR),'NULL') <> nvl(to_char(r2.TR_REL1_REK2_KANT_NR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_REK2_KANT_NR',r1.TR_REL1_REK2_KANT_NR,r2.TR_REL1_REK2_KANT_NR);end if;
   if nvl(to_char(r1.TR_REL1_MUNTS_KRS),'NULL')	<> nvl(to_char(r2.TR_REL1_MUNTS_KRS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_MUNTS_KRS',r1.TR_REL1_MUNTS_KRS,r2.TR_REL1_MUNTS_KRS);end if;
   if nvl(to_char(r1.TR_REL1_MUNTS_FAC),'NULL')	<> nvl(to_char(r2.TR_REL1_MUNTS_FAC),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_MUNTS_FAC',r1.TR_REL1_MUNTS_FAC,r2.TR_REL1_MUNTS_FAC);end if;
   if nvl(to_char(r1.TR_REL1_CAT),'NULL') <> nvl(to_char(r2.TR_REL1_CAT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_CAT',r1.TR_REL1_CAT,r2.TR_REL1_CAT);end if;
   if nvl(to_char(r1.TR_INSTRUKTIE),'NULL')	<> nvl(to_char(r2.TR_INSTRUKTIE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_INSTRUKTIE',r1.TR_INSTRUKTIE,r2.TR_INSTRUKTIE);end if;
   if nvl(to_char(r1.TR_REL2),'NULL') <> nvl(to_char(r2.TR_REL2),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2',r1.TR_REL2,r2.TR_REL2);end if;
   if nvl(to_char(r1.TR_REL2_REK1),'NULL') <> nvl(to_char(r2.TR_REL2_REK1),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_REK1',r1.TR_REL2_REK1,r2.TR_REL2_REK1);end if;
   if nvl(to_char(r1.TR_REL2_REK1_SOORT),'NULL') <> nvl(to_char(r2.TR_REL2_REK1_SOORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_REK1_SOORT',r1.TR_REL2_REK1_SOORT,r2.TR_REL2_REK1_SOORT);end if;
   if nvl(to_char(r1.TR_REL2_RAP_MUNTS),'NULL')	<> nvl(to_char(r2.TR_REL2_RAP_MUNTS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_RAP_MUNTS',r1.TR_REL2_RAP_MUNTS,r2.TR_REL2_RAP_MUNTS);end if;
   if nvl(to_char(r1.TR_REL2_RAP_KRS),'NULL') <> nvl(to_char(r2.TR_REL2_RAP_KRS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_RAP_KRS',r1.TR_REL2_RAP_KRS,r2.TR_REL2_RAP_KRS);end if;
   if nvl(to_char(r1.TR_REL2_RAP_FAC),'NULL') <> nvl(to_char(r2.TR_REL2_RAP_FAC),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_RAP_FAC',r1.TR_REL2_RAP_FAC,r2.TR_REL2_RAP_FAC);end if;
   if nvl(to_char(r1.TR_REL2_REK2),'NULL') <> nvl(to_char(r2.TR_REL2_REK2),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_REK2',r1.TR_REL2_REK2,r2.TR_REL2_REK2);end if;
   if nvl(to_char(r1.TR_REL2_REK2_SOORT),'NULL') <> nvl(to_char(r2.TR_REL2_REK2_SOORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_REK2_SOORT',r1.TR_REL2_REK2_SOORT,r2.TR_REL2_REK2_SOORT);end if;
   if nvl(to_char(r1.TR_REL2_REK2_MUNTS),'NULL') <> nvl(to_char(r2.TR_REL2_REK2_MUNTS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_REK2_MUNTS',r1.TR_REL2_REK2_MUNTS,r2.TR_REL2_REK2_MUNTS);end if;
   if nvl(to_char(r1.TR_REL2_MUNTS_KRS),'NULL')	<> nvl(to_char(r2.TR_REL2_MUNTS_KRS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_MUNTS_KRS',r1.TR_REL2_MUNTS_KRS,r2.TR_REL2_MUNTS_KRS);end if;
   if nvl(to_char(r1.TR_REL2_MUNTS_FAC),'NULL')	<> nvl(to_char(r2.TR_REL2_MUNTS_FAC),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_MUNTS_FAC',r1.TR_REL2_MUNTS_FAC,r2.TR_REL2_MUNTS_FAC);end if;
   if nvl(to_char(r1.TR_REL2_CAT),'NULL') <> nvl(to_char(r2.TR_REL2_CAT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_CAT',r1.TR_REL2_CAT,r2.TR_REL2_CAT);end if;
   if nvl(to_char(r1.TR_REL2_INSTRUCTIE),'NULL') <> nvl(to_char(r2.TR_REL2_INSTRUCTIE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_INSTRUCTIE',r1.TR_REL2_INSTRUCTIE,r2.TR_REL2_INSTRUCTIE);end if;
   if nvl(to_char(r1.TR_SYMBOOL),'NULL') <> nvl(to_char(r2.TR_SYMBOOL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_SYMBOOL',r1.TR_SYMBOOL,r2.TR_SYMBOOL);end if;
   if nvl(to_char(r1.TR_OPTIETYPE),'NULL') <> nvl(to_char(r2.TR_OPTIETYPE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_OPTIETYPE',r1.TR_OPTIETYPE,r2.TR_OPTIETYPE);end if;
   if nvl(to_char(r1.TR_EXPIRATIEDATUM),'NULL') <> nvl(to_char(r2.TR_EXPIRATIEDATUM),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_EXPIRATIEDATUM',r1.TR_EXPIRATIEDATUM,r2.TR_EXPIRATIEDATUM);end if;
   if nvl(to_char(r1.TR_EXERCISEPRIJS),'NULL') <> nvl(to_char(r2.TR_EXERCISEPRIJS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_EXERCISEPRIJS',r1.TR_EXERCISEPRIJS,r2.TR_EXERCISEPRIJS);end if;
   if nvl(to_char(r1.TR_BE_MUNTSOORT),'NULL') <> nvl(to_char(r2.TR_BE_MUNTSOORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BE_MUNTSOORT',r1.TR_BE_MUNTSOORT,r2.TR_BE_MUNTSOORT);end if;
   if nvl(to_char(r1.TR_BE_MUNT_KRS),'NULL') <> nvl(to_char(r2.TR_BE_MUNT_KRS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BE_MUNT_KRS',r1.TR_BE_MUNT_KRS,r2.TR_BE_MUNT_KRS);end if;
   if nvl(to_char(r1.TR_BE_MUNT_FAC),'NULL') <> nvl(to_char(r2.TR_BE_MUNT_FAC),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BE_MUNT_FAC',r1.TR_BE_MUNT_FAC,r2.TR_BE_MUNT_FAC);end if;
   if nvl(to_char(r1.TR_SYMB_CAT),'NULL') <> nvl(to_char(r2.TR_SYMB_CAT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_SYMB_CAT',r1.TR_SYMB_CAT,r2.TR_SYMB_CAT);end if;
   if nvl(to_char(r1.TR_INDICATIE),'NULL') <> nvl(to_char(r2.TR_INDICATIE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_INDICATIE',r1.TR_INDICATIE,r2.TR_INDICATIE);end if;
   if nvl(to_char(r1.TR_LONG_SHORT_IND),'NULL')	<> nvl(to_char(r2.TR_LONG_SHORT_IND),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_LONG_SHORT_IND',r1.TR_LONG_SHORT_IND,r2.TR_LONG_SHORT_IND);end if;
   if nvl(to_char(r1.TR_TRANS_MUNTS),'NULL') <> nvl(to_char(r2.TR_TRANS_MUNTS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TRANS_MUNTS',r1.TR_TRANS_MUNTS,r2.TR_TRANS_MUNTS);end if;
   if nvl(to_char(r1.TR_TRANS_MUNTS_KRS),'NULL') <> nvl(to_char(r2.TR_TRANS_MUNTS_KRS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TRANS_MUNTS_KRS',r1.TR_TRANS_MUNTS_KRS,r2.TR_TRANS_MUNTS_KRS);end if;
   if nvl(to_char(r1.TR_TRANS_MUNTS_FAC),'NULL') <> nvl(to_char(r2.TR_TRANS_MUNTS_FAC),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TRANS_MUNTS_FAC',r1.TR_TRANS_MUNTS_FAC,r2.TR_TRANS_MUNTS_FAC);end if;
   if nvl(to_char(r1.TR_TRANSDATUM),'NULL')	 <> nvl(to_char(r2.TR_TRANSDATUM),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TRANSDATUM',r1.TR_TRANSDATUM,r2.TR_TRANSDATUM);end if;
   if nvl(to_char(r1.TR_VALDATUM),'NULL') <> nvl(to_char(r2.TR_VALDATUM),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VALDATUM',r1.TR_VALDATUM,r2.TR_VALDATUM);end if;
   if nvl(to_char(r1.TR_BOEKDATUM),'NULL') <> nvl(to_char(r2.TR_BOEKDATUM),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BOEKDATUM',r1.TR_BOEKDATUM,r2.TR_BOEKDATUM);end if;
   if nvl(to_char(r1.TR_SETTLEMENTDATUM),'NULL') <> nvl(to_char(r2.TR_SETTLEMENTDATUM),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_SETTLEMENTDATUM',r1.TR_SETTLEMENTDATUM,r2.TR_SETTLEMENTDATUM);end if;
   if nvl(to_char(r1.TR_AANTAL),'NULL')	<> nvl(to_char(r2.TR_AANTAL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_AANTAL',r1.TR_AANTAL,r2.TR_AANTAL);end if;
   if nvl(to_char(r1.TR_PRIJS_TR_MNTSRT),'NULL') <> nvl(to_char(r2.TR_PRIJS_TR_MNTSRT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_PRIJS_TR_MNTSRT',r1.TR_PRIJS_TR_MNTSRT,r2.TR_PRIJS_TR_MNTSRT);end if;
   if nvl(to_char(r1.TR_BEURS_PRIJS_TRM),'NULL') <> nvl(to_char(r2.TR_BEURS_PRIJS_TRM),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BEURS_PRIJS_TRM',r1.TR_BEURS_PRIJS_TRM,r2.TR_BEURS_PRIJS_TRM);end if;
   if nvl(to_char(r1.TR_PRIJS_FACTOR),'NULL') <> nvl(to_char(r2.TR_PRIJS_FACTOR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_PRIJS_FACTOR',r1.TR_PRIJS_FACTOR,r2.TR_PRIJS_FACTOR);end if;
   if nvl(to_char(r1.TR_EXASS_FACTOR),'NULL') <> nvl(to_char(r2.TR_EXASS_FACTOR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_EXASS_FACTOR',r1.TR_EXASS_FACTOR,r2.TR_EXASS_FACTOR);end if;
   if nvl(to_char(r1.TR_MUT_KOSTEN_PLUS_BTW),'NULL') <> nvl(to_char(r2.TR_MUT_KOSTEN_PLUS_BTW),'NULL')		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_MUT_KOSTEN_PLUS_BTW',r1.TR_MUT_KOSTEN_PLUS_BTW,r2.TR_MUT_KOSTEN_PLUS_BTW);end if;
   if nvl(to_char(r1.TR_BTW_MUT_KOSTEN),'NULL')	<> nvl(to_char(r2.TR_BTW_MUT_KOSTEN),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BTW_MUT_KOSTEN',r1.TR_BTW_MUT_KOSTEN,r2.TR_BTW_MUT_KOSTEN);end if;
   if nvl(to_char(r1.TR_KOSTEN),'NULL')	<> nvl(to_char(r2.TR_KOSTEN),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_KOSTEN',r1.TR_KOSTEN,r2.TR_KOSTEN);end if;
   if nvl(to_char(r1.TR_PROVISIE),'NULL') <> nvl(to_char(r2.TR_PROVISIE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_PROVISIE',r1.TR_PROVISIE,r2.TR_PROVISIE);end if;
   if nvl(to_char(r1.TR_RESTITUTIEPROVISI),'NULL') <> nvl(to_char(r2.TR_RESTITUTIEPROVISI),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_RESTITUTIEPROVISI',r1.TR_RESTITUTIEPROVISI,r2.TR_RESTITUTIEPROVISI);end if;
   if nvl(to_char(r1.TR_REALLOWANCE),'NULL') <> nvl(to_char(r2.TR_REALLOWANCE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REALLOWANCE',r1.TR_REALLOWANCE,r2.TR_REALLOWANCE);end if;
   if nvl(to_char(r1.TR_NOTABEDRAG),'NULL')	<> nvl(to_char(r2.TR_NOTABEDRAG),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_NOTABEDRAG',r1.TR_NOTABEDRAG,r2.TR_NOTABEDRAG);end if;
   if nvl(to_char(r1.TR_MUT_GEMAAKT),'NULL') <> nvl(to_char(r2.TR_MUT_GEMAAKT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_MUT_GEMAAKT',r1.TR_MUT_GEMAAKT,r2.TR_MUT_GEMAAKT);end if;
   if nvl(to_char(r1.TR_RENTE_METHODE),'NULL') <> nvl(to_char(r2.TR_RENTE_METHODE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_RENTE_METHODE',r1.TR_RENTE_METHODE,r2.TR_RENTE_METHODE);end if;
   if nvl(to_char(r1.TR_RENTE_DAGEN),'NULL') <> nvl(to_char(r2.TR_RENTE_DAGEN),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_RENTE_DAGEN',r1.TR_RENTE_DAGEN,r2.TR_RENTE_DAGEN);end if;
   if nvl(to_char(r1.TR_RENTE),'NULL') <> nvl(to_char(r2.TR_RENTE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_RENTE',r1.TR_RENTE,r2.TR_RENTE);end if;
   if nvl(to_char(r1.TR_BELASTING),'NULL') <> nvl(to_char(r2.TR_BELASTING),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BELASTING',r1.TR_BELASTING,r2.TR_BELASTING);end if;
   if nvl(to_char(r1.TR_REF_SYMBOOL),'NULL') <> nvl(to_char(r2.TR_REF_SYMBOOL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REF_SYMBOOL',r1.TR_REF_SYMBOOL,r2.TR_REF_SYMBOOL);end if;
   if nvl(to_char(r1.TR_NOTANUMMER),'NULL')	<> nvl(to_char(r2.TR_NOTANUMMER),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_NOTANUMMER',r1.TR_NOTANUMMER,r2.TR_NOTANUMMER);end if;
   if nvl(to_char(r1.TR_ORDERNR_ORDSUBNR),'NULL') <> nvl(to_char(r2.TR_ORDERNR_ORDSUBNR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_ORDERNR_ORDSUBNR',r1.TR_ORDERNR_ORDSUBNR,r2.TR_ORDERNR_ORDSUBNR);end if;
   if nvl(to_char(r1.TR_ORDERUITVOERNR),'NULL')	<> nvl(to_char(r2.TR_ORDERUITVOERNR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_ORDERUITVOERNR',r1.TR_ORDERUITVOERNR,r2.TR_ORDERUITVOERNR);end if;
   if nvl(to_char(r1.TR_MUTATIECODE),'NULL') <> nvl(to_char(r2.TR_MUTATIECODE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_MUTATIECODE',r1.TR_MUTATIECODE,r2.TR_MUTATIECODE);end if;
   if nvl(to_char(r1.TR_ADVISEUR),'NULL') <> nvl(to_char(r2.TR_ADVISEUR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_ADVISEUR',r1.TR_ADVISEUR,r2.TR_ADVISEUR);end if;
   if nvl(to_char(r1.TR_BEURS),'NULL') <> nvl(to_char(r2.TR_BEURS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BEURS',r1.TR_BEURS,r2.TR_BEURS);end if;
   if nvl(to_char(r1.TR_COURTAGE),'NULL') <> nvl(to_char(r2.TR_COURTAGE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_COURTAGE',r1.TR_COURTAGE,r2.TR_COURTAGE);end if;
   if nvl(to_char(r1.TR_EXPORT),'NULL')	<> nvl(to_char(r2.TR_EXPORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_EXPORT',r1.TR_EXPORT,r2.TR_EXPORT);end if;
   if nvl(to_char(r1.TR_ORIGNOTASTORNO),'NULL')	<> nvl(to_char(r2.TR_ORIGNOTASTORNO),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_ORIGNOTASTORNO',r1.TR_ORIGNOTASTORNO,r2.TR_ORIGNOTASTORNO);end if;
   if nvl(to_char(r1.TR_REF_TRANSNUMMER),'NULL') <> nvl(to_char(r2.TR_REF_TRANSNUMMER),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REF_TRANSNUMMER',r1.TR_REF_TRANSNUMMER,r2.TR_REF_TRANSNUMMER);end if;
   if nvl(to_char(r1.TR_HANDELSSYSTEEM),'NULL')	<> nvl(to_char(r2.TR_HANDELSSYSTEEM),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_HANDELSSYSTEEM',r1.TR_HANDELSSYSTEEM,r2.TR_HANDELSSYSTEEM);end if;
   if nvl(to_char(r1.TR_OPTREDEND_ALS),'NULL') <> nvl(to_char(r2.TR_OPTREDEND_ALS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_OPTREDEND_ALS',r1.TR_OPTREDEND_ALS,r2.TR_OPTREDEND_ALS);end if;
   if nvl(to_char(r1.TR_OPDRACHTGEVER),'NULL') <> nvl(to_char(r2.TR_OPDRACHTGEVER),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_OPDRACHTGEVER',r1.TR_OPDRACHTGEVER,r2.TR_OPDRACHTGEVER);end if;
   if nvl(to_char(r1.TR_BRIEFCODE),'NULL') <> nvl(to_char(r2.TR_BRIEFCODE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BRIEFCODE',r1.TR_BRIEFCODE,r2.TR_BRIEFCODE);end if;
   if nvl(to_char(r1.TR_HERKOMST_CODE_TR),'NULL') <> nvl(to_char(r2.TR_HERKOMST_CODE_TR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_HERKOMST_CODE_TR',r1.TR_HERKOMST_CODE_TR,r2.TR_HERKOMST_CODE_TR);end if;
   if nvl(to_char(r1.TR_SETTLEMENT_KOSTEN),'NULL') <> nvl(to_char(r2.TR_SETTLEMENT_KOSTEN),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_SETTLEMENT_KOSTEN',r1.TR_SETTLEMENT_KOSTEN,r2.TR_SETTLEMENT_KOSTEN);end if;
   if nvl(to_char(r1.TR_PROVISIEKORTING),'NULL') <> nvl(to_char(r2.TR_PROVISIEKORTING),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_PROVISIEKORTING',r1.TR_PROVISIEKORTING,r2.TR_PROVISIEKORTING);end if;
   if nvl(to_char(r1.TR_WAARBORGSOM_FUT),'NULL') <> nvl(to_char(r2.TR_WAARBORGSOM_FUT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_WAARBORGSOM_FUT',r1.TR_WAARBORGSOM_FUT,r2.TR_WAARBORGSOM_FUT);end if;
   if nvl(to_char(r1.TR_BELASTFYSLEV_KB),'NULL') <> nvl(to_char(r2.TR_BELASTFYSLEV_KB),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BELASTFYSLEV_KB',r1.TR_BELASTFYSLEV_KB,r2.TR_BELASTFYSLEV_KB);end if;
   if nvl(to_char(r1.TR_DEP_RENTE_INFO),'NULL')	<> nvl(to_char(r2.TR_DEP_RENTE_INFO),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_DEP_RENTE_INFO',r1.TR_DEP_RENTE_INFO,r2.TR_DEP_RENTE_INFO);end if;
   if nvl(to_char(r1.TR_STOP_KOERS),'NULL')	<> nvl(to_char(r2.TR_STOP_KOERS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_STOP_KOERS',r1.TR_STOP_KOERS,r2.TR_STOP_KOERS);end if;
   if nvl(to_char(r1.TR_REF_NOTANR),'NULL')	<> nvl(to_char(r2.TR_REF_NOTANR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REF_NOTANR',r1.TR_REF_NOTANR,r2.TR_REF_NOTANR);end if;
   if nvl(to_char(r1.TR_TIJDINGEVOERD),'NULL') <> nvl(to_char(r2.TR_TIJDINGEVOERD),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TIJDINGEVOERD',r1.TR_TIJDINGEVOERD,r2.TR_TIJDINGEVOERD);end if;
   if nvl(to_char(r1.TR_USERID),'NULL')	<> nvl(to_char(r2.TR_USERID),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_USERID',r1.TR_USERID,r2.TR_USERID);end if;
   if nvl(to_char(r1.TR_CONCEPTGEPRINT),'NULL')	<> nvl(to_char(r2.TR_CONCEPTGEPRINT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_CONCEPTGEPRINT',r1.TR_CONCEPTGEPRINT,r2.TR_CONCEPTGEPRINT);end if;
   if nvl(to_char(r1.TR_DEP_STARTDATUM),'NULL')	<> nvl(to_char(r2.TR_DEP_STARTDATUM),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_DEP_STARTDATUM',r1.TR_DEP_STARTDATUM,r2.TR_DEP_STARTDATUM);end if;
   if nvl(to_char(r1.TR_TPRF_RELATIE),'NULL') <> nvl(to_char(r2.TR_TPRF_RELATIE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPRF_RELATIE',r1.TR_TPRF_RELATIE,r2.TR_TPRF_RELATIE);end if;
   if nvl(to_char(r1.TR_TPRF_REK1),'NULL') <> nvl(to_char(r2.TR_TPRF_REK1),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPRF_REK1',r1.TR_TPRF_REK1,r2.TR_TPRF_REK1);end if;
   if nvl(to_char(r1.TR_TPRF_REK1SOORT),'NULL')	<> nvl(to_char(r2.TR_TPRF_REK1SOORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPRF_REK1SOORT',r1.TR_TPRF_REK1SOORT,r2.TR_TPRF_REK1SOORT);end if;
   if nvl(to_char(r1.TR_ORIGTR_STORNO),'NULL') <> nvl(to_char(r2.TR_ORIGTR_STORNO),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_ORIGTR_STORNO',r1.TR_ORIGTR_STORNO,r2.TR_ORIGTR_STORNO);end if;
   if nvl(to_char(r1.TR_BOEKINGSNR_STUKAD),'NULL') <> nvl(to_char(r2.TR_BOEKINGSNR_STUKAD),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BOEKINGSNR_STUKAD',r1.TR_BOEKINGSNR_STUKAD,r2.TR_BOEKINGSNR_STUKAD);end if;
   if nvl(to_char(r1.TR_GEJOURNALISEERD),'NULL') <> nvl(to_char(r2.TR_GEJOURNALISEERD),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_GEJOURNALISEERD',r1.TR_GEJOURNALISEERD,r2.TR_GEJOURNALISEERD);end if;
   if nvl(to_char(r1.TR_DISTRIBUTIEKANAAL),'NULL') <> nvl(to_char(r2.TR_DISTRIBUTIEKANAAL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_DISTRIBUTIEKANAAL',r1.TR_DISTRIBUTIEKANAAL,r2.TR_DISTRIBUTIEKANAAL);end if;
   if nvl(to_char(r1.TR_FX_DEP_CONTRACTNR),'NULL') <> nvl(to_char(r2.TR_FX_DEP_CONTRACTNR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_FX_DEP_CONTRACTNR',r1.TR_FX_DEP_CONTRACTNR,r2.TR_FX_DEP_CONTRACTNR);end if;
   if nvl(to_char(r1.TR_BERICHT_ONDERDRUK),'NULL') <> nvl(to_char(r2.TR_BERICHT_ONDERDRUK),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BERICHT_ONDERDRUK',r1.TR_BERICHT_ONDERDRUK,r2.TR_BERICHT_ONDERDRUK);end if;
   if nvl(to_char(r1.TR_CORRECTIEBOEKING),'NULL') <> nvl(to_char(r2.TR_CORRECTIEBOEKING),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_CORRECTIEBOEKING',r1.TR_CORRECTIEBOEKING,r2.TR_CORRECTIEBOEKING);end if;
   if nvl(to_char(r1.TR_BATCHCODE),'NULL') <> nvl(to_char(r2.TR_BATCHCODE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BATCHCODE',r1.TR_BATCHCODE,r2.TR_BATCHCODE);end if;
   if nvl(to_char(r1.TR_BATCHREGEL),'NULL')	<> nvl(to_char(r2.TR_BATCHREGEL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BATCHREGEL',r1.TR_BATCHREGEL,r2.TR_BATCHREGEL);end if;
   if nvl(to_char(r1.TR_VERWERKEN),'NULL') <> nvl(to_char(r2.TR_VERWERKEN),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VERWERKEN',r1.TR_VERWERKEN,r2.TR_VERWERKEN);end if;
   if nvl(to_char(r1.TR_TIJD_DOORGEBOEKT),'NULL') <> nvl(to_char(r2.TR_TIJD_DOORGEBOEKT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TIJD_DOORGEBOEKT',r1.TR_TIJD_DOORGEBOEKT,r2.TR_TIJD_DOORGEBOEKT);end if;
   if nvl(to_char(r1.TR_DEALINGTIJD),'NULL') <> nvl(to_char(r2.TR_DEALINGTIJD),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_DEALINGTIJD',r1.TR_DEALINGTIJD,r2.TR_DEALINGTIJD);end if;
   if nvl(to_char(r1.TR_DEP_PERCENTAGE),'NULL')	<> nvl(to_char(r2.TR_DEP_PERCENTAGE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_DEP_PERCENTAGE',r1.TR_DEP_PERCENTAGE,r2.TR_DEP_PERCENTAGE);end if;
   if nvl(to_char(r1.TR_VOLGNUMMER),'NULL')	<> nvl(to_char(r2.TR_VOLGNUMMER),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VOLGNUMMER',r1.TR_VOLGNUMMER,r2.TR_VOLGNUMMER);end if;
   if nvl(to_char(r1.TR_REL1_RAP_RCP),'NULL') <> nvl(to_char(r2.TR_REL1_RAP_RCP),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_RAP_RCP',r1.TR_REL1_RAP_RCP,r2.TR_REL1_RAP_RCP);end if;
   if nvl(to_char(r1.TR_REL1_MUNTS_RCP),'NULL')	<> nvl(to_char(r2.TR_REL1_MUNTS_RCP),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL1_MUNTS_RCP',r1.TR_REL1_MUNTS_RCP,r2.TR_REL1_MUNTS_RCP);end if;
   if nvl(to_char(r1.TR_REL2_RAP_RCP),'NULL') <> nvl(to_char(r2.TR_REL2_RAP_RCP),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_RAP_RCP',r1.TR_REL2_RAP_RCP,r2.TR_REL2_RAP_RCP);end if;
   if nvl(to_char(r1.TR_REL2_MUNTS_RCP),'NULL')	<> nvl(to_char(r2.TR_REL2_MUNTS_RCP),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REL2_MUNTS_RCP',r1.TR_REL2_MUNTS_RCP,r2.TR_REL2_MUNTS_RCP);end if;
   if nvl(to_char(r1.TR_BE_MUNT_RCP),'NULL') <> nvl(to_char(r2.TR_BE_MUNT_RCP),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BE_MUNT_RCP',r1.TR_BE_MUNT_RCP,r2.TR_BE_MUNT_RCP);end if;
   if nvl(to_char(r1.TR_TRANS_MUNTS_RCP),'NULL') <> nvl(to_char(r2.TR_TRANS_MUNTS_RCP),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TRANS_MUNTS_RCP',r1.TR_TRANS_MUNTS_RCP,r2.TR_TRANS_MUNTS_RCP);end if;
   if nvl(to_char(r1.TR_AANBRENGER),'NULL')	<> nvl(to_char(r2.TR_AANBRENGER),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_AANBRENGER',r1.TR_AANBRENGER,r2.TR_AANBRENGER);end if;
   if nvl(to_char(r1.TR_BELASTINGVERDRAG),'NULL') <> nvl(to_char(r2.TR_BELASTINGVERDRAG),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BELASTINGVERDRAG',r1.TR_BELASTINGVERDRAG,r2.TR_BELASTINGVERDRAG);end if;
   if nvl(to_char(r1.TR_AFSPR_NR_REL1),'NULL') <> nvl(to_char(r2.TR_AFSPR_NR_REL1),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_AFSPR_NR_REL1',r1.TR_AFSPR_NR_REL1,r2.TR_AFSPR_NR_REL1);end if;
   if nvl(to_char(r1.TR_VERDRAGGROEPCODE),'NULL') <> nvl(to_char(r2.TR_VERDRAGGROEPCODE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VERDRAGGROEPCODE',r1.TR_VERDRAGGROEPCODE,r2.TR_VERDRAGGROEPCODE);end if;
   if nvl(to_char(r1.TR_AFSPR_NR_REL2),'NULL') <> nvl(to_char(r2.TR_AFSPR_NR_REL2),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_AFSPR_NR_REL2',r1.TR_AFSPR_NR_REL2,r2.TR_AFSPR_NR_REL2);end if;
   if nvl(to_char(r1.TR_FA_LOOPTIJD),'NULL') <> nvl(to_char(r2.TR_FA_LOOPTIJD),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_FA_LOOPTIJD',r1.TR_FA_LOOPTIJD,r2.TR_FA_LOOPTIJD);end if;
   if nvl(to_char(r1.TR_BELASTINGPERCENT),'NULL') <> nvl(to_char(r2.TR_BELASTINGPERCENT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BELASTINGPERCENT',r1.TR_BELASTINGPERCENT,r2.TR_BELASTINGPERCENT);end if;
   if nvl(to_char(r1.TR_BRUTOBEDRAG),'NULL') <> nvl(to_char(r2.TR_BRUTOBEDRAG),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BRUTOBEDRAG',r1.TR_BRUTOBEDRAG,r2.TR_BRUTOBEDRAG);end if;
   if nvl(to_char(r1.TR_TPRF_REK2),'NULL') <> nvl(to_char(r2.TR_TPRF_REK2),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPRF_REK2',r1.TR_TPRF_REK2,r2.TR_TPRF_REK2);end if;
   if nvl(to_char(r1.TR_TPRF_REK2SOORT),'NULL')	<> nvl(to_char(r2.TR_TPRF_REK2SOORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPRF_REK2SOORT',r1.TR_TPRF_REK2SOORT,r2.TR_TPRF_REK2SOORT);end if;
   if nvl(to_char(r1.TR_TPRF_REK2MUNTS),'NULL')	<> nvl(to_char(r2.TR_TPRF_REK2MUNTS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPRF_REK2MUNTS',r1.TR_TPRF_REK2MUNTS,r2.TR_TPRF_REK2MUNTS);end if;
   if nvl(to_char(r1.TR_TPRF_INSTRUCTIE),'NULL') <> nvl(to_char(r2.TR_TPRF_INSTRUCTIE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPRF_INSTRUCTIE',r1.TR_TPRF_INSTRUCTIE,r2.TR_TPRF_INSTRUCTIE);end if;
   if nvl(to_char(r1.TR_AFSPR_NR_TPRF),'NULL') <> nvl(to_char(r2.TR_AFSPR_NR_TPRF),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_AFSPR_NR_TPRF',r1.TR_AFSPR_NR_TPRF,r2.TR_AFSPR_NR_TPRF);end if;
   if nvl(to_char(r1.TR_TPRF_CAT),'NULL') <> nvl(to_char(r2.TR_TPRF_CAT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPRF_CAT',r1.TR_TPRF_CAT,r2.TR_TPRF_CAT);end if;
   if nvl(to_char(r1.TR_VRUCHTRELATIE),'NULL') <> nvl(to_char(r2.TR_VRUCHTRELATIE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTRELATIE',r1.TR_VRUCHTRELATIE,r2.TR_VRUCHTRELATIE);end if;
   if nvl(to_char(r1.TR_VRUCHTREK_NR),'NULL') <> nvl(to_char(r2.TR_VRUCHTREK_NR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTREK_NR',r1.TR_VRUCHTREK_NR,r2.TR_VRUCHTREK_NR);end if;
   if nvl(to_char(r1.TR_VRUCHTREK_SOORT),'NULL') <> nvl(to_char(r2.TR_VRUCHTREK_SOORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTREK_SOORT',r1.TR_VRUCHTREK_SOORT,r2.TR_VRUCHTREK_SOORT);end if;
   if nvl(to_char(r1.TR_VRUCHTREK_MUNTSRT),'NULL') <> nvl(to_char(r2.TR_VRUCHTREK_MUNTSRT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTREK_MUNTSRT',r1.TR_VRUCHTREK_MUNTSRT,r2.TR_VRUCHTREK_MUNTSRT);end if;
   if nvl(to_char(r1.TR_TRANSFERPROV),'NULL') <> nvl(to_char(r2.TR_TRANSFERPROV),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TRANSFERPROV',r1.TR_TRANSFERPROV,r2.TR_TRANSFERPROV);end if;
   if nvl(to_char(r1.TR_CHEQUEKOSTEN),'NULL') <> nvl(to_char(r2.TR_CHEQUEKOSTEN),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_CHEQUEKOSTEN',r1.TR_CHEQUEKOSTEN,r2.TR_CHEQUEKOSTEN);end if;
   if nvl(to_char(r1.TR_KOSTENBET_VERK),'NULL')	<> nvl(to_char(r2.TR_KOSTENBET_VERK),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_KOSTENBET_VERK',r1.TR_KOSTENBET_VERK,r2.TR_KOSTENBET_VERK);end if;
   if nvl(to_char(r1.TR_OVERIGE_KOSTEN),'NULL')	<> nvl(to_char(r2.TR_OVERIGE_KOSTEN),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_OVERIGE_KOSTEN',r1.TR_OVERIGE_KOSTEN,r2.TR_OVERIGE_KOSTEN);end if;
   if nvl(to_char(r1.TR_KOSTEN_MUNTSRT),'NULL')	<> nvl(to_char(r2.TR_KOSTEN_MUNTSRT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_KOSTEN_MUNTSRT',r1.TR_KOSTEN_MUNTSRT,r2.TR_KOSTEN_MUNTSRT);end if;
   if nvl(to_char(r1.TR_KOSTEN_MUNTKOERS),'NULL') <> nvl(to_char(r2.TR_KOSTEN_MUNTKOERS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_KOSTEN_MUNTKOERS',r1.TR_KOSTEN_MUNTKOERS,r2.TR_KOSTEN_MUNTKOERS);end if;
   if nvl(to_char(r1.TR_KOSTEN_MUNTFACT),'NULL') <> nvl(to_char(r2.TR_KOSTEN_MUNTFACT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_KOSTEN_MUNTFACT',r1.TR_KOSTEN_MUNTFACT,r2.TR_KOSTEN_MUNTFACT);end if;
   if nvl(to_char(r1.TR_KOSTEN_MUNT_RCP),'NULL') <> nvl(to_char(r2.TR_KOSTEN_MUNT_RCP),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_KOSTEN_MUNT_RCP',r1.TR_KOSTEN_MUNT_RCP,r2.TR_KOSTEN_MUNT_RCP);end if;
   if nvl(to_char(r1.TR_DIVIDENDCODE),'NULL') <> nvl(to_char(r2.TR_DIVIDENDCODE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_DIVIDENDCODE',r1.TR_DIVIDENDCODE,r2.TR_DIVIDENDCODE);end if;
   if nvl(to_char(r1.TR_DIV_UITK_DATUM),'NULL')	<> nvl(to_char(r2.TR_DIV_UITK_DATUM),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_DIV_UITK_DATUM',r1.TR_DIV_UITK_DATUM,r2.TR_DIV_UITK_DATUM);end if;
   if nvl(to_char(r1.TR_VRUCHTREL_CAT),'NULL') <> nvl(to_char(r2.TR_VRUCHTREL_CAT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTREL_CAT',r1.TR_VRUCHTREL_CAT,r2.TR_VRUCHTREL_CAT);end if;
   if nvl(to_char(r1.TR_VRUCHTREL_RAP_MUNTS),'NULL') <> nvl(to_char(r2.TR_VRUCHTREL_RAP_MUNTS),'NULL')		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTREL_RAP_MUNTS',r1.TR_VRUCHTREL_RAP_MUNTS,r2.TR_VRUCHTREL_RAP_MUNTS);end if;
   if nvl(to_char(r1.TR_VRUCHTREL_RAP_KRS),'NULL') <> nvl(to_char(r2.TR_VRUCHTREL_RAP_KRS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTREL_RAP_KRS',r1.TR_VRUCHTREL_RAP_KRS,r2.TR_VRUCHTREL_RAP_KRS);end if;
   if nvl(to_char(r1.TR_VRUCHTREL_RAP_FAC),'NULL') <> nvl(to_char(r2.TR_VRUCHTREL_RAP_FAC),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTREL_RAP_FAC',r1.TR_VRUCHTREL_RAP_FAC,r2.TR_VRUCHTREL_RAP_FAC);end if;
   if nvl(to_char(r1.TR_VRUCHTREL_RAP_RCP),'NULL') <> nvl(to_char(r2.TR_VRUCHTREL_RAP_RCP),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTREL_RAP_RCP',r1.TR_VRUCHTREL_RAP_RCP,r2.TR_VRUCHTREL_RAP_RCP);end if;
   if nvl(to_char(r1.TR_VRUCHTREK_MNT_KRS),'NULL') <> nvl(to_char(r2.TR_VRUCHTREK_MNT_KRS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTREK_MNT_KRS',r1.TR_VRUCHTREK_MNT_KRS,r2.TR_VRUCHTREK_MNT_KRS);end if;
   if nvl(to_char(r1.TR_VRUCHTREK_MNT_FAC),'NULL') <> nvl(to_char(r2.TR_VRUCHTREK_MNT_FAC),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTREK_MNT_FAC',r1.TR_VRUCHTREK_MNT_FAC,r2.TR_VRUCHTREK_MNT_FAC);end if;
   if nvl(to_char(r1.TR_VRUCHTREK_MNT_RCP),'NULL') <> nvl(to_char(r2.TR_VRUCHTREK_MNT_RCP),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTREK_MNT_RCP',r1.TR_VRUCHTREK_MNT_RCP,r2.TR_VRUCHTREK_MNT_RCP);end if;
   if nvl(to_char(r1.TR_NOTAVRUCHTBEDRAG),'NULL') <> nvl(to_char(r2.TR_NOTAVRUCHTBEDRAG),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_NOTAVRUCHTBEDRAG',r1.TR_NOTAVRUCHTBEDRAG,r2.TR_NOTAVRUCHTBEDRAG);end if;
   if nvl(to_char(r1.TR_TPRF_RAP_MUNTS),'NULL')	<> nvl(to_char(r2.TR_TPRF_RAP_MUNTS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPRF_RAP_MUNTS',r1.TR_TPRF_RAP_MUNTS,r2.TR_TPRF_RAP_MUNTS);end if;
   if nvl(to_char(r1.TR_TPRF_RAP_KRS),'NULL') <> nvl(to_char(r2.TR_TPRF_RAP_KRS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPRF_RAP_KRS',r1.TR_TPRF_RAP_KRS,r2.TR_TPRF_RAP_KRS);end if;
   if nvl(to_char(r1.TR_TPRF_RAP_FAC),'NULL') <> nvl(to_char(r2.TR_TPRF_RAP_FAC),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPRF_RAP_FAC',r1.TR_TPRF_RAP_FAC,r2.TR_TPRF_RAP_FAC);end if;
   if nvl(to_char(r1.TR_TPRF_RAP_RCP),'NULL') <> nvl(to_char(r2.TR_TPRF_RAP_RCP),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPRF_RAP_RCP',r1.TR_TPRF_RAP_RCP,r2.TR_TPRF_RAP_RCP);end if;
   if nvl(to_char(r1.TR_VRUCHTREL_INSTRUCTIE),'NULL') <> nvl(to_char(r2.TR_VRUCHTREL_INSTRUCTIE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTREL_INSTRUCTIE',r1.TR_VRUCHTREL_INSTRUCTIE,r2.TR_VRUCHTREL_INSTRUCTIE);end if;
   if nvl(to_char(r1.TR_VRUCHTREL_AFSPR_NR),'NULL')	<> nvl(to_char(r2.TR_VRUCHTREL_AFSPR_NR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VRUCHTREL_AFSPR_NR',r1.TR_VRUCHTREL_AFSPR_NR,r2.TR_VRUCHTREL_AFSPR_NR);end if;
   if nvl(to_char(r1.TR_PRODUCTCODE),'NULL') <> nvl(to_char(r2.TR_PRODUCTCODE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_PRODUCTCODE',r1.TR_PRODUCTCODE,r2.TR_PRODUCTCODE);end if;
   if nvl(to_char(r1.TR_CONVERSIESOORT),'NULL')	<> nvl(to_char(r2.TR_CONVERSIESOORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_CONVERSIESOORT',r1.TR_CONVERSIESOORT,r2.TR_CONVERSIESOORT);end if;
   if nvl(to_char(r1.TR_VERREKENBEDRAG_OUD_FONDS),'NULL') <> nvl(to_char(r2.TR_VERREKENBEDRAG_OUD_FONDS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VERREKENBEDRAG_OUD_FONDS',r1.TR_VERREKENBEDRAG_OUD_FONDS,r2.TR_VERREKENBEDRAG_OUD_FONDS);end if;
   if nvl(to_char(r1.TR_VERREKENVALUTA_OUD_FONDS),'NULL') <> nvl(to_char(r2.TR_VERREKENVALUTA_OUD_FONDS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VERREKENVALUTA_OUD_FONDS',r1.TR_VERREKENVALUTA_OUD_FONDS,r2.TR_VERREKENVALUTA_OUD_FONDS);end if;
   if nvl(to_char(r1.TR_VERREKENBEDRAG_NIEUW_FONDS),'NULL')	<> nvl(to_char(r2.TR_VERREKENBEDRAG_NIEUW_FONDS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VERREKENBEDRAG_NIEUW_FONDS',r1.TR_VERREKENBEDRAG_NIEUW_FONDS,r2.TR_VERREKENBEDRAG_NIEUW_FONDS);end if;
   if nvl(to_char(r1.TR_VERREKENVALUTA_NIEUW_FONDS),'NULL')	<> nvl(to_char(r2.TR_VERREKENVALUTA_NIEUW_FONDS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VERREKENVALUTA_NIEUW_FONDS',r1.TR_VERREKENVALUTA_NIEUW_FONDS,r2.TR_VERREKENVALUTA_NIEUW_FONDS);end if;
   if nvl(to_char(r1.TR_REAL_BROKERAGE_COST),'NULL') <> nvl(to_char(r2.TR_REAL_BROKERAGE_COST),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REAL_BROKERAGE_COST',r1.TR_REAL_BROKERAGE_COST,r2.TR_REAL_BROKERAGE_COST);end if;
   if nvl(to_char(r1.TR_FISCAAL_LAND),'NULL') <> nvl(to_char(r2.TR_FISCAAL_LAND),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_FISCAAL_LAND',r1.TR_FISCAAL_LAND,r2.TR_FISCAAL_LAND);end if;
   if nvl(to_char(r1.TR_FRACTIEFONDS),'NULL') <> nvl(to_char(r2.TR_FRACTIEFONDS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_FRACTIEFONDS',r1.TR_FRACTIEFONDS,r2.TR_FRACTIEFONDS);end if;
   if nvl(to_char(r1.TR_FRACTIES_AFRONDING),'NULL') <> nvl(to_char(r2.TR_FRACTIES_AFRONDING),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_FRACTIES_AFRONDING',r1.TR_FRACTIES_AFRONDING,r2.TR_FRACTIES_AFRONDING);end if;
   if nvl(to_char(r1.TR_FRACTIES_FACTOR),'NULL') <> nvl(to_char(r2.TR_FRACTIES_FACTOR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_FRACTIES_FACTOR',r1.TR_FRACTIES_FACTOR,r2.TR_FRACTIES_FACTOR);end if;
   if nvl(to_char(r1.TR_AANTAL_FRACTIES),'NULL') <> nvl(to_char(r2.TR_AANTAL_FRACTIES),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_AANTAL_FRACTIES',r1.TR_AANTAL_FRACTIES,r2.TR_AANTAL_FRACTIES);end if;
   if nvl(to_char(r1.TR_LAND_TRANS_PROFIEL),'NULL')	<> nvl(to_char(r2.TR_LAND_TRANS_PROFIEL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_LAND_TRANS_PROFIEL',r1.TR_LAND_TRANS_PROFIEL,r2.TR_LAND_TRANS_PROFIEL);end if;
   if nvl(to_char(r1.TR_SOLLICITED_UNSOLLICITED),'NULL') <> nvl(to_char(r2.TR_SOLLICITED_UNSOLLICITED),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_SOLLICITED_UNSOLLICITED',r1.TR_SOLLICITED_UNSOLLICITED,r2.TR_SOLLICITED_UNSOLLICITED);end if;
   if nvl(to_char(r1.TR_EXTRA_PRIJS_TRM),'NULL') <> nvl(to_char(r2.TR_EXTRA_PRIJS_TRM),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_EXTRA_PRIJS_TRM',r1.TR_EXTRA_PRIJS_TRM,r2.TR_EXTRA_PRIJS_TRM);end if;
   if nvl(to_char(r1.TR_REK_GEG_PRINTEN),'NULL') <> nvl(to_char(r2.TR_REK_GEG_PRINTEN),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_REK_GEG_PRINTEN',r1.TR_REK_GEG_PRINTEN,r2.TR_REK_GEG_PRINTEN);end if;
   if nvl(to_char(r1.TR_OPDRACHTNUMMER),'NULL')	<> nvl(to_char(r2.TR_OPDRACHTNUMMER),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_OPDRACHTNUMMER',r1.TR_OPDRACHTNUMMER,r2.TR_OPDRACHTNUMMER);end if;
   if nvl(to_char(r1.TR_AANTAL_TE_ONTVANGEN),'NULL') <> nvl(to_char(r2.TR_AANTAL_TE_ONTVANGEN),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_AANTAL_TE_ONTVANGEN',r1.TR_AANTAL_TE_ONTVANGEN,r2.TR_AANTAL_TE_ONTVANGEN);end if;
   if nvl(to_char(r1.TR_AANTAL_IN_TE_LEVEREN),'NULL') <> nvl(to_char(r2.TR_AANTAL_IN_TE_LEVEREN),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_AANTAL_IN_TE_LEVEREN',r1.TR_AANTAL_IN_TE_LEVEREN,r2.TR_AANTAL_IN_TE_LEVEREN);end if;
   if nvl(to_char(r1.TR_GELDBLOK_IND_REL1),'NULL') <> nvl(to_char(r2.TR_GELDBLOK_IND_REL1),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_GELDBLOK_IND_REL1',r1.TR_GELDBLOK_IND_REL1,r2.TR_GELDBLOK_IND_REL1);end if;
   if nvl(to_char(r1.TR_GELDBLOK_IND_REL2),'NULL') <> nvl(to_char(r2.TR_GELDBLOK_IND_REL2),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_GELDBLOK_IND_REL2',r1.TR_GELDBLOK_IND_REL2,r2.TR_GELDBLOK_IND_REL2);end if;
   if nvl(to_char(r1.TR_SEGMENTEN_PER_JAAR),'NULL')	<> nvl(to_char(r2.TR_SEGMENTEN_PER_JAAR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_SEGMENTEN_PER_JAAR',r1.TR_SEGMENTEN_PER_JAAR,r2.TR_SEGMENTEN_PER_JAAR);end if;
   if nvl(to_char(r1.TR_BLOKKERINGSDUUR),'NULL') <> nvl(to_char(r2.TR_BLOKKERINGSDUUR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BLOKKERINGSDUUR',r1.TR_BLOKKERINGSDUUR,r2.TR_BLOKKERINGSDUUR);end if;
   if nvl(to_char(r1.TR_PROV_REL),'NULL') <> nvl(to_char(r2.TR_PROV_REL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_PROV_REL',r1.TR_PROV_REL,r2.TR_PROV_REL);end if;
   if nvl(to_char(r1.TR_PROV_REK),'NULL') <> nvl(to_char(r2.TR_PROV_REK),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_PROV_REK',r1.TR_PROV_REK,r2.TR_PROV_REK);end if;
   if nvl(to_char(r1.TR_PROV_REK_SOORT),'NULL')	<> nvl(to_char(r2.TR_PROV_REK_SOORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_PROV_REK_SOORT',r1.TR_PROV_REK_SOORT,r2.TR_PROV_REK_SOORT);end if;
   if nvl(to_char(r1.TR_PROV_REK_VAL),'NULL') <> nvl(to_char(r2.TR_PROV_REK_VAL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_PROV_REK_VAL',r1.TR_PROV_REK_VAL,r2.TR_PROV_REK_VAL);end if;
   if nvl(to_char(r1.TR_BV_REL),'NULL')	<> nvl(to_char(r2.TR_BV_REL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BV_REL',r1.TR_BV_REL,r2.TR_BV_REL);end if;
   if nvl(to_char(r1.TR_BV_REK),'NULL')	<> nvl(to_char(r2.TR_BV_REK),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BV_REK',r1.TR_BV_REK,r2.TR_BV_REK);end if;
   if nvl(to_char(r1.TR_BV_REK_SOORT),'NULL') <> nvl(to_char(r2.TR_BV_REK_SOORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BV_REK_SOORT',r1.TR_BV_REK_SOORT,r2.TR_BV_REK_SOORT);end if;
   if nvl(to_char(r1.TR_BV_REK_VAL),'NULL')	<> nvl(to_char(r2.TR_BV_REK_VAL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BV_REK_VAL',r1.TR_BV_REK_VAL,r2.TR_BV_REK_VAL);end if;
   if nvl(to_char(r1.TR_VV_REL),'NULL')	<> nvl(to_char(r2.TR_VV_REL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VV_REL',r1.TR_VV_REL,r2.TR_VV_REL);end if;
   if nvl(to_char(r1.TR_VV_REK),'NULL')	<> nvl(to_char(r2.TR_VV_REK),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VV_REK',r1.TR_VV_REK,r2.TR_VV_REK);end if;
   if nvl(to_char(r1.TR_VV_REK_SOORT),'NULL') <> nvl(to_char(r2.TR_VV_REK_SOORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VV_REK_SOORT',r1.TR_VV_REK_SOORT,r2.TR_VV_REK_SOORT);end if;
   if nvl(to_char(r1.TR_VV_REK_VAL),'NULL')	<> nvl(to_char(r2.TR_VV_REK_VAL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_VV_REK_VAL',r1.TR_VV_REK_VAL,r2.TR_VV_REK_VAL);end if;
   if nvl(to_char(r1.TR_CK_BEDRAG),'NULL') <> nvl(to_char(r2.TR_CK_BEDRAG),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_CK_BEDRAG',r1.TR_CK_BEDRAG,r2.TR_CK_BEDRAG);end if;
   if nvl(to_char(r1.TR_CK_REL),'NULL')	<> nvl(to_char(r2.TR_CK_REL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_CK_REL',r1.TR_CK_REL,r2.TR_CK_REL);end if;
   if nvl(to_char(r1.TR_CK_REK),'NULL')	<> nvl(to_char(r2.TR_CK_REK),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_CK_REK',r1.TR_CK_REK,r2.TR_CK_REK);end if;
   if nvl(to_char(r1.TR_CK_REK_SOORT),'NULL') <> nvl(to_char(r2.TR_CK_REK_SOORT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_CK_REK_SOORT',r1.TR_CK_REK_SOORT,r2.TR_CK_REK_SOORT);end if;
   if nvl(to_char(r1.TR_CK_REK_VAL),'NULL')	<> nvl(to_char(r2.TR_CK_REK_VAL),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_CK_REK_VAL',r1.TR_CK_REK_VAL,r2.TR_CK_REK_VAL);end if;
   if nvl(to_char(r1.TR_COSTCOMPONENTCOUNT),'NULL')	<> nvl(to_char(r2.TR_COSTCOMPONENTCOUNT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_COSTCOMPONENTCOUNT',r1.TR_COSTCOMPONENTCOUNT,r2.TR_COSTCOMPONENTCOUNT);end if;
   if nvl(to_char(r1.TR_COVERMUTATIONCOUNT),'NULL')	<> nvl(to_char(r2.TR_COVERMUTATIONCOUNT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_COVERMUTATIONCOUNT',r1.TR_COVERMUTATIONCOUNT,r2.TR_COVERMUTATIONCOUNT);end if;
   if nvl(to_char(r1.TR_TPC_ACTIONS),'NULL') <> nvl(to_char(r2.TR_TPC_ACTIONS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPC_ACTIONS',r1.TR_TPC_ACTIONS,r2.TR_TPC_ACTIONS);end if;
   if nvl(to_char(r1.TR_CLASS_TYPE),'NULL')	<> nvl(to_char(r2.TR_CLASS_TYPE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_CLASS_TYPE',r1.TR_CLASS_TYPE,r2.TR_CLASS_TYPE);end if;
   if nvl(to_char(r1.TR_MICO_ID),'NULL') <> nvl(to_char(r2.TR_MICO_ID),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_MICO_ID',r1.TR_MICO_ID,r2.TR_MICO_ID);end if;
   if nvl(to_char(r1.TR_DEALINGTIMEMICROSECONDS),'NULL') <> nvl(to_char(r2.TR_DEALINGTIMEMICROSECONDS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_DEALINGTIMEMICROSECONDS',r1.TR_DEALINGTIMEMICROSECONDS,r2.TR_DEALINGTIMEMICROSECONDS);end if;
   if nvl(to_char(r1.TR_CURRENCY_COST_CNT),'NULL') <> nvl(to_char(r2.TR_CURRENCY_COST_CNT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_CURRENCY_COST_CNT',r1.TR_CURRENCY_COST_CNT,r2.TR_CURRENCY_COST_CNT);end if;
   if nvl(to_char(r1.TR_EFFECTIVE_AMOUNT),'NULL') <> nvl(to_char(r2.TR_EFFECTIVE_AMOUNT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_EFFECTIVE_AMOUNT',r1.TR_EFFECTIVE_AMOUNT,r2.TR_EFFECTIVE_AMOUNT);end if;
   if nvl(to_char(r1.TR_USUFRUCT_EFFECTIVE_AMOUNT),'NULL') <> nvl(to_char(r2.TR_USUFRUCT_EFFECTIVE_AMOUNT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_USUFRUCT_EFFECTIVE_AMOUNT',r1.TR_USUFRUCT_EFFECTIVE_AMOUNT,r2.TR_USUFRUCT_EFFECTIVE_AMOUNT);end if;
   if nvl(to_char(r1.TR_CONTEXT_ENUM),'NULL') <> nvl(to_char(r2.TR_CONTEXT_ENUM),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_CONTEXT_ENUM',r1.TR_CONTEXT_ENUM,r2.TR_CONTEXT_ENUM);end if;
   if nvl(to_char(r1.TR_UPDATEREGISTERINDICATOR),'NULL') <> nvl(to_char(r2.TR_UPDATEREGISTERINDICATOR),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_UPDATEREGISTERINDICATOR',r1.TR_UPDATEREGISTERINDICATOR,r2.TR_UPDATEREGISTERINDICATOR);end if;
   if nvl(to_char(r1.TR_SUB_CONTEXT),'NULL') <> nvl(to_char(r2.TR_SUB_CONTEXT),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_SUB_CONTEXT',r1.TR_SUB_CONTEXT,r2.TR_SUB_CONTEXT);end if;
   if nvl(to_char(r1.TR_PRICE_SPREAD),'NULL') <> nvl(to_char(r2.TR_PRICE_SPREAD),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_PRICE_SPREAD',r1.TR_PRICE_SPREAD,r2.TR_PRICE_SPREAD);end if;
   if nvl(to_char(r1.TR_TAXABLE_INCOME_PER_SHARE),'NULL') <> nvl(to_char(r2.TR_TAXABLE_INCOME_PER_SHARE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TAXABLE_INCOME_PER_SHARE',r1.TR_TAXABLE_INCOME_PER_SHARE,r2.TR_TAXABLE_INCOME_PER_SHARE);end if;
   if nvl(to_char(r1.TR_SBC_ID),'NULL')	<> nvl(to_char(r2.TR_SBC_ID),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_SBC_ID',r1.TR_SBC_ID,r2.TR_SBC_ID);end if;
   if nvl(to_char(r1.TR_BOOK_DATE),'NULL') <> nvl(to_char(r2.TR_BOOK_DATE),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_BOOK_DATE',r1.TR_BOOK_DATE,r2.TR_BOOK_DATE);end if;
   if nvl(to_char(r1.TR_TPC_POST_ACTIONS),'NULL') <> nvl(to_char(r2.TR_TPC_POST_ACTIONS),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_TPC_POST_ACTIONS',r1.TR_TPC_POST_ACTIONS,r2.TR_TPC_POST_ACTIONS);end if;
   if nvl(to_char(r1.TR_ORIN_ID),'NULL') <> nvl(to_char(r2.TR_ORIN_ID),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_ORIN_ID',r1.TR_ORIN_ID,r2.TR_ORIN_ID);end if;
   if nvl(to_char(r1.TR_CHANGEOFBENOWNER),'NULL') <> nvl(to_char(r2.TR_CHANGEOFBENOWNER),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONS',s1,rid_1,rid_2,'TR_CHANGEOFBENOWNER',r1.TR_CHANGEOFBENOWNER,r2.TR_CHANGEOFBENOWNER);end if;
--
-- DEELTRANSACTIES
--

/*

Wel in EEN maar niet in TWEE

*/

   s1 := 0;

   for rc4a in c4a loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4a.rowid,null,'DT_TRANSACTIEVOLGNR',rc4a.DT_TRANSACTIEVOLGNR,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4a.rowid,null,'DT_DEELTRANSNR',rc4a.DT_DEELTRANSNR,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4a.rowid,null,'DT_AANTAL',rc4a.DT_AANTAL,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4a.rowid,null,'DT_PRIJS',rc4a.DT_PRIJS,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4a.rowid,null,'DT_BEURSPRIJS',rc4a.DT_BEURSPRIJS,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4a.rowid,null,'DT_EXPORT',rc4a.DT_EXPORT,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4a.rowid,null,'DT_COMMENTAAR',rc4a.DT_COMMENTAAR,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4a.rowid,null,'DT_BEURS',rc4a.DT_BEURS,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4a.rowid,null,'DT_MICO_ID',rc4a.DT_MICO_ID,null);

   end loop;

/*

Wel in TWEE maar niet in EEN

*/

   s1 := 0;

   for rc4b in c4b loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,null,rc4b.rowid,'DT_TRANSACTIEVOLGNR',null,rc4b.DT_TRANSACTIEVOLGNR);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,null,rc4b.rowid,'DT_DEELTRANSNR',null,rc4b.DT_DEELTRANSNR);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,null,rc4b.rowid,'DT_AANTAL',null,rc4b.DT_AANTAL);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,null,rc4b.rowid,'DT_PRIJS',null,rc4b.DT_PRIJS);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,null,rc4b.rowid,'DT_BEURSPRIJS',null,rc4b.DT_BEURSPRIJS);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,null,rc4b.rowid,'DT_EXPORT',null,rc4b.DT_EXPORT);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,null,rc4b.rowid,'DT_COMMENTAAR',null,rc4b.DT_COMMENTAAR);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,null,rc4b.rowid,'DT_BEURS',null,rc4b.DT_BEURS);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,null,rc4b.rowid,'DT_MICO_ID',null,rc4b.DT_MICO_ID);

   end loop;

/*

Zowel in EEN als in TWEE

*/

   s1 := 0;

   for rc4c in c4c loop

      s1 := s1 + 1;

      if nvl(to_char(rc4c.DT_TRANSACTIEVOLGNR_OUD),'NULL')  <> nvl(to_char(rc4c.DT_TRANSACTIEVOLGNR_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4c.rowid_oud,rc4c.rowid_nw,'DT_TRANSACTIEVOLGNR',rc4c.DT_TRANSACTIEVOLGNR_OUD,rc4c.DT_TRANSACTIEVOLGNR_NW);end if;
      if nvl(to_char(rc4c.DT_DEELTRANSNR_OUD),'NULL') <> nvl(to_char(rc4c.DT_DEELTRANSNR_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4c.rowid_oud,rc4c.rowid_nw,'DT_DEELTRANSNR',rc4c.DT_DEELTRANSNR_OUD,rc4c.DT_DEELTRANSNR_NW);end if;
      if nvl(to_char(rc4c.DT_AANTAL_OUD),'NULL') <> nvl(to_char(rc4c.DT_AANTAL_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4c.rowid_oud,rc4c.rowid_nw,'DT_AANTAL',rc4c.DT_AANTAL_OUD,rc4c.DT_AANTAL_NW);end if;
      if nvl(to_char(rc4c.DT_PRIJS_OUD),'NULL')  <> nvl(to_char(rc4c.DT_PRIJS_NW),'NULL')  then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4c.rowid_oud,rc4c.rowid_nw,'DT_PRIJS',rc4c.DT_PRIJS_OUD,rc4c.DT_PRIJS_NW);end if;
      if nvl(to_char(rc4c.DT_BEURSPRIJS_OUD),'NULL') <> nvl(to_char(rc4c.DT_BEURSPRIJS_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4c.rowid_oud,rc4c.rowid_nw,'DT_BEURSPRIJS',rc4c.DT_BEURSPRIJS_OUD,rc4c.DT_BEURSPRIJS_NW);end if;
      if nvl(to_char(rc4c.DT_EXPORT_OUD),'NULL') <> nvl(to_char(rc4c.DT_EXPORT_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4c.rowid_oud,rc4c.rowid_nw,'DT_EXPORT',rc4c.DT_EXPORT_OUD,rc4c.DT_EXPORT_NW);end if;
      if nvl(to_char(rc4c.DT_COMMENTAAR_OUD),'NULL') <> nvl(to_char(rc4c.DT_COMMENTAAR_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4c.rowid_oud,rc4c.rowid_nw,'DT_COMMENTAAR',rc4c.DT_COMMENTAAR_OUD,rc4c.DT_COMMENTAAR_NW);end if;
      if nvl(to_char(rc4c.DT_BEURS_OUD),'NULL') <> nvl(to_char(rc4c.DT_BEURS_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4c.rowid_oud,rc4c.rowid_nw,'DT_BEURS',rc4c.DT_BEURS_OUD,rc4c.DT_BEURS_NW);end if;
      if nvl(to_char(rc4c.DT_MICO_ID_OUD),'NULL') <> nvl(to_char(rc4c.DT_MICO_ID_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'DEELTRANSACTIES',s1,rc4c.rowid_oud,rc4c.rowid_nw,'DT_MICO_ID',rc4c.DT_MICO_ID_OUD,rc4c.DT_MICO_ID_NW);end if;

   end loop;

--
-- TRANS_OMSCHRIJVING
--

   s1 := 0;

   for rc5a in c5a loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_TRANSACTIEVOLGNR',rc5a.TO_TRANSACTIEVOLGNR,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_OMSCHRIJVING1',rc5a.TO_OMSCHRIJVING1,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_EXPORT',rc5a.TO_EXPORT,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_RELATIE_OW',rc5a.TO_RELATIE_OW,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_REK1_OW',rc5a.TO_REK1_OW,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_REKSRT1_OW',rc5a.TO_REKSRT1_OW,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_UITVOERINGSKOSTEN',rc5a.TO_UITVOERINGSKOSTEN,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ALGEMENEKOSTEN',rc5a.TO_ALGEMENEKOSTEN,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ORDERBEHANDKOSTEN',rc5a.TO_ORDERBEHANDKOSTEN,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ITEM_PROVCOMP1',rc5a.TO_ITEM_PROVCOMP1,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_BEDR_PROVCOMP1',rc5a.TO_BEDR_PROVCOMP1,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ITEM_PROVCOMP2',rc5a.TO_ITEM_PROVCOMP2,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_BEDR_PROVCOMP2',rc5a.TO_BEDR_PROVCOMP2,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ITEM_PROVCOMP3',rc5a.TO_ITEM_PROVCOMP3,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_BEDR_PROVCOMP3',rc5a.TO_BEDR_PROVCOMP3,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ITEM_PROVCOMP4',rc5a.TO_ITEM_PROVCOMP4,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_BEDR_PROVCOMP4',rc5a.TO_BEDR_PROVCOMP4,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ITEM_PROVCOMP5',rc5a.TO_ITEM_PROVCOMP5,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_BEDR_PROVCOMP5',rc5a.TO_BEDR_PROVCOMP5,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ITEM_PROVCOMP6',rc5a.TO_ITEM_PROVCOMP6,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_BEDR_PROVCOMP6',rc5a.TO_BEDR_PROVCOMP6,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ITEM_PROVCOMP7',rc5a.TO_ITEM_PROVCOMP7,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_BEDR_PROVCOMP7',rc5a.TO_BEDR_PROVCOMP7,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ITEM_PROVCOMP8',rc5a.TO_ITEM_PROVCOMP8,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_BEDR_PROVCOMP8',rc5a.TO_BEDR_PROVCOMP8,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ITEM_PROVCOMP9',rc5a.TO_ITEM_PROVCOMP9,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_BEDR_PROVCOMP9',rc5a.TO_BEDR_PROVCOMP9,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ITEM_PROVCOMP10',rc5a.TO_ITEM_PROVCOMP10,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_BEDR_PROVCOMP10',rc5a.TO_BEDR_PROVCOMP10,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ITEM_PROVCOMP11',rc5a.TO_ITEM_PROVCOMP11,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_BEDR_PROVCOMP11',rc5a.TO_BEDR_PROVCOMP11,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_ITEM_PROVCOMP12',rc5a.TO_ITEM_PROVCOMP12,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_BEDR_PROVCOMP12',rc5a.TO_BEDR_PROVCOMP12,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_OMSCHRIJVING2',rc5a.TO_OMSCHRIJVING2,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_OMSCHRIJVING3',rc5a.TO_OMSCHRIJVING3,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_OMSCHRIJVING4',rc5a.TO_OMSCHRIJVING4,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_OPDRGEVER_BEGUNST',rc5a.TO_OPDRGEVER_BEGUNST,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_OPDRACHT_BEG_BANK',rc5a.TO_OPDRACHT_BEG_BANK,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_EXTERNREKENINGNR',rc5a.TO_EXTERNREKENINGNR,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_WOONPLAATS',rc5a.TO_WOONPLAATS,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_OMSCHRIJVING5',rc5a.TO_OMSCHRIJVING5,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_CONCEPT_STORNERING',rc5a.TO_CONCEPT_STORNERING,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_AFWIJKING_TRANS_PROFIEL',rc5a.TO_AFWIJKING_TRANS_PROFIEL,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5a.rowid,null,'TO_STORNO_REASON',rc5a.TO_STORNO_REASON,null);

   end loop;

   s1 := 0;

   for rc5b in c5b loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_TRANSACTIEVOLGNR',null,rc5b.TO_TRANSACTIEVOLGNR);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_OMSCHRIJVING1',null,rc5b.TO_OMSCHRIJVING1);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_EXPORT',null,rc5b.TO_EXPORT);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_RELATIE_OW',null,rc5b.TO_RELATIE_OW);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_REK1_OW',null,rc5b.TO_REK1_OW);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_REKSRT1_OW',null,rc5b.TO_REKSRT1_OW);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_UITVOERINGSKOSTEN',null,rc5b.TO_UITVOERINGSKOSTEN);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ALGEMENEKOSTEN',null,rc5b.TO_ALGEMENEKOSTEN);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ORDERBEHANDKOSTEN',null,rc5b.TO_ORDERBEHANDKOSTEN);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ITEM_PROVCOMP1',null,rc5b.TO_ITEM_PROVCOMP1);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_BEDR_PROVCOMP1',null,rc5b.TO_BEDR_PROVCOMP1);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ITEM_PROVCOMP2',null,rc5b.TO_ITEM_PROVCOMP2);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_BEDR_PROVCOMP2',null,rc5b.TO_BEDR_PROVCOMP2);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ITEM_PROVCOMP3',null,rc5b.TO_ITEM_PROVCOMP3);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_BEDR_PROVCOMP3',null,rc5b.TO_BEDR_PROVCOMP3);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ITEM_PROVCOMP4',null,rc5b.TO_ITEM_PROVCOMP4);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_BEDR_PROVCOMP4',null,rc5b.TO_BEDR_PROVCOMP4);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ITEM_PROVCOMP5',null,rc5b.TO_ITEM_PROVCOMP5);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_BEDR_PROVCOMP5',null,rc5b.TO_BEDR_PROVCOMP5);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ITEM_PROVCOMP6',null,rc5b.TO_ITEM_PROVCOMP6);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_BEDR_PROVCOMP6',null,rc5b.TO_BEDR_PROVCOMP6);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ITEM_PROVCOMP7',null,rc5b.TO_ITEM_PROVCOMP7);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_BEDR_PROVCOMP7',null,rc5b.TO_BEDR_PROVCOMP7);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ITEM_PROVCOMP8',null,rc5b.TO_ITEM_PROVCOMP8);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_BEDR_PROVCOMP8',null,rc5b.TO_BEDR_PROVCOMP8);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ITEM_PROVCOMP9',null,rc5b.TO_ITEM_PROVCOMP9);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_BEDR_PROVCOMP9',null,rc5b.TO_BEDR_PROVCOMP9);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ITEM_PROVCOMP10',null,rc5b.TO_ITEM_PROVCOMP10);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_BEDR_PROVCOMP10',null,rc5b.TO_BEDR_PROVCOMP10);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ITEM_PROVCOMP11',null,rc5b.TO_ITEM_PROVCOMP11);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_BEDR_PROVCOMP11',null,rc5b.TO_BEDR_PROVCOMP11);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_ITEM_PROVCOMP12',null,rc5b.TO_ITEM_PROVCOMP12);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_BEDR_PROVCOMP12',null,rc5b.TO_BEDR_PROVCOMP12);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_OMSCHRIJVING2',null,rc5b.TO_OMSCHRIJVING2);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_OMSCHRIJVING3',null,rc5b.TO_OMSCHRIJVING3);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_OMSCHRIJVING4',null,rc5b.TO_OMSCHRIJVING4);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_OPDRGEVER_BEGUNST',null,rc5b.TO_OPDRGEVER_BEGUNST);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_OPDRACHT_BEG_BANK',null,rc5b.TO_OPDRACHT_BEG_BANK);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_EXTERNREKENINGNR',null,rc5b.TO_EXTERNREKENINGNR);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_WOONPLAATS',null,rc5b.TO_WOONPLAATS);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_OMSCHRIJVING5',null,rc5b.TO_OMSCHRIJVING5);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_CONCEPT_STORNERING',null,rc5b.TO_CONCEPT_STORNERING);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_AFWIJKING_TRANS_PROFIEL',null,rc5b.TO_AFWIJKING_TRANS_PROFIEL);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,null,rc5b.rowid,'TO_STORNO_REASON',null,rc5b.TO_STORNO_REASON);

   end loop;

   s1 := 0;

   for rc5c in c5c loop

      s1 := s1 + 1;

      if nvl(to_char(rc5c.TO_TRANSACTIEVOLGNR_OUD),'NULL')       	<> nvl(to_char(rc5c.TO_TRANSACTIEVOLGNR_NW),'NULL')     		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_TRANSACTIEVOLGNR',rc5c.TO_TRANSACTIEVOLGNR_OUD,rc5c.TO_TRANSACTIEVOLGNR_NW);end if;
      if nvl(to_char(rc5c.TO_OMSCHRIJVING1_OUD),'NULL')  		<> nvl(to_char(rc5c.TO_OMSCHRIJVING1_NW),'NULL')        		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_OMSCHRIJVING1',rc5c.TO_OMSCHRIJVING1_OUD,rc5c.TO_OMSCHRIJVING1_NW);end if;
      if nvl(to_char(rc5c.TO_EXPORT_OUD),'NULL') 			<> nvl(to_char(rc5c.TO_EXPORT_NW),'NULL')       			then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_EXPORT',rc5c.TO_EXPORT_OUD,rc5c.TO_EXPORT_NW);end if;
      if nvl(to_char(rc5c.TO_RELATIE_OW_OUD),'NULL')     		<> nvl(to_char(rc5c.TO_RELATIE_OW_NW),'NULL')   			then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_RELATIE_OW',rc5c.TO_RELATIE_OW_OUD,rc5c.TO_RELATIE_OW_NW);end if;
      if nvl(to_char(rc5c.TO_REK1_OW_OUD),'NULL')        		<> nvl(to_char(rc5c.TO_REK1_OW_NW),'NULL')      			then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_REK1_OW',rc5c.TO_REK1_OW_OUD,rc5c.TO_REK1_OW_NW);end if;
      if nvl(to_char(rc5c.TO_REKSRT1_OW_OUD),'NULL')     		<> nvl(to_char(rc5c.TO_REKSRT1_OW_NW),'NULL')   			then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_REKSRT1_OW',rc5c.TO_REKSRT1_OW_OUD,rc5c.TO_REKSRT1_OW_NW);end if;
      if nvl(to_char(rc5c.TO_UITVOERINGSKOSTEN_OUD),'NULL')      	<> nvl(to_char(rc5c.TO_UITVOERINGSKOSTEN_NW),'NULL')    		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_UITVOERINGSKOSTEN',rc5c.TO_UITVOERINGSKOSTEN_OUD,rc5c.TO_UITVOERINGSKOSTEN_NW);end if;
      if nvl(to_char(rc5c.TO_ALGEMENEKOSTEN_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_ALGEMENEKOSTEN_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ALGEMENEKOSTEN',rc5c.TO_ALGEMENEKOSTEN_OUD,rc5c.TO_ALGEMENEKOSTEN_NW);end if;
      if nvl(to_char(rc5c.TO_ORDERBEHANDKOSTEN_OUD),'NULL')      	<> nvl(to_char(rc5c.TO_ORDERBEHANDKOSTEN_NW),'NULL')    		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ORDERBEHANDKOSTEN',rc5c.TO_ORDERBEHANDKOSTEN_OUD,rc5c.TO_ORDERBEHANDKOSTEN_NW);end if;
      if nvl(to_char(rc5c.TO_ITEM_PROVCOMP1_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_ITEM_PROVCOMP1_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ITEM_PROVCOMP1',rc5c.TO_ITEM_PROVCOMP1_OUD,rc5c.TO_ITEM_PROVCOMP1_NW);end if;
      if nvl(to_char(rc5c.TO_BEDR_PROVCOMP1_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_BEDR_PROVCOMP1_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_BEDR_PROVCOMP1',rc5c.TO_BEDR_PROVCOMP1_OUD,rc5c.TO_BEDR_PROVCOMP1_NW);end if;
      if nvl(to_char(rc5c.TO_ITEM_PROVCOMP2_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_ITEM_PROVCOMP2_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ITEM_PROVCOMP2',rc5c.TO_ITEM_PROVCOMP2_OUD,rc5c.TO_ITEM_PROVCOMP2_NW);end if;
      if nvl(to_char(rc5c.TO_BEDR_PROVCOMP2_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_BEDR_PROVCOMP2_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_BEDR_PROVCOMP2',rc5c.TO_BEDR_PROVCOMP2_OUD,rc5c.TO_BEDR_PROVCOMP2_NW);end if;
      if nvl(to_char(rc5c.TO_ITEM_PROVCOMP3_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_ITEM_PROVCOMP3_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ITEM_PROVCOMP3',rc5c.TO_ITEM_PROVCOMP3_OUD,rc5c.TO_ITEM_PROVCOMP3_NW);end if;
      if nvl(to_char(rc5c.TO_BEDR_PROVCOMP3_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_BEDR_PROVCOMP3_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_BEDR_PROVCOMP3',rc5c.TO_BEDR_PROVCOMP3_OUD,rc5c.TO_BEDR_PROVCOMP3_NW);end if;
      if nvl(to_char(rc5c.TO_ITEM_PROVCOMP4_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_ITEM_PROVCOMP4_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ITEM_PROVCOMP4',rc5c.TO_ITEM_PROVCOMP4_OUD,rc5c.TO_ITEM_PROVCOMP4_NW);end if;
      if nvl(to_char(rc5c.TO_BEDR_PROVCOMP4_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_BEDR_PROVCOMP4_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_BEDR_PROVCOMP4',rc5c.TO_BEDR_PROVCOMP4_OUD,rc5c.TO_BEDR_PROVCOMP4_NW);end if;
      if nvl(to_char(rc5c.TO_ITEM_PROVCOMP5_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_ITEM_PROVCOMP5_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ITEM_PROVCOMP5',rc5c.TO_ITEM_PROVCOMP5_OUD,rc5c.TO_ITEM_PROVCOMP5_NW);end if;
      if nvl(to_char(rc5c.TO_BEDR_PROVCOMP5_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_BEDR_PROVCOMP5_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_BEDR_PROVCOMP5',rc5c.TO_BEDR_PROVCOMP5_OUD,rc5c.TO_BEDR_PROVCOMP5_NW);end if;
      if nvl(to_char(rc5c.TO_ITEM_PROVCOMP6_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_ITEM_PROVCOMP6_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ITEM_PROVCOMP6',rc5c.TO_ITEM_PROVCOMP6_OUD,rc5c.TO_ITEM_PROVCOMP6_NW);end if;
      if nvl(to_char(rc5c.TO_BEDR_PROVCOMP6_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_BEDR_PROVCOMP6_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_BEDR_PROVCOMP6',rc5c.TO_BEDR_PROVCOMP6_OUD,rc5c.TO_BEDR_PROVCOMP6_NW);end if;
      if nvl(to_char(rc5c.TO_ITEM_PROVCOMP7_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_ITEM_PROVCOMP7_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ITEM_PROVCOMP7',rc5c.TO_ITEM_PROVCOMP7_OUD,rc5c.TO_ITEM_PROVCOMP7_NW);end if;
      if nvl(to_char(rc5c.TO_BEDR_PROVCOMP7_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_BEDR_PROVCOMP7_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_BEDR_PROVCOMP7',rc5c.TO_BEDR_PROVCOMP7_OUD,rc5c.TO_BEDR_PROVCOMP7_NW);end if;
      if nvl(to_char(rc5c.TO_ITEM_PROVCOMP8_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_ITEM_PROVCOMP8_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ITEM_PROVCOMP8',rc5c.TO_ITEM_PROVCOMP8_OUD,rc5c.TO_ITEM_PROVCOMP8_NW);end if;
      if nvl(to_char(rc5c.TO_BEDR_PROVCOMP8_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_BEDR_PROVCOMP8_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_BEDR_PROVCOMP8',rc5c.TO_BEDR_PROVCOMP8_OUD,rc5c.TO_BEDR_PROVCOMP8_NW);end if;
      if nvl(to_char(rc5c.TO_ITEM_PROVCOMP9_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_ITEM_PROVCOMP9_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ITEM_PROVCOMP9',rc5c.TO_ITEM_PROVCOMP9_OUD,rc5c.TO_ITEM_PROVCOMP9_NW);end if;
      if nvl(to_char(rc5c.TO_BEDR_PROVCOMP9_OUD),'NULL') 		<> nvl(to_char(rc5c.TO_BEDR_PROVCOMP9_NW),'NULL')       		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_BEDR_PROVCOMP9',rc5c.TO_BEDR_PROVCOMP9_OUD,rc5c.TO_BEDR_PROVCOMP9_NW);end if;
      if nvl(to_char(rc5c.TO_ITEM_PROVCOMP10_OUD),'NULL')        	<> nvl(to_char(rc5c.TO_ITEM_PROVCOMP10_NW),'NULL')      		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ITEM_PROVCOMP10',rc5c.TO_ITEM_PROVCOMP10_OUD,rc5c.TO_ITEM_PROVCOMP10_NW);end if;
      if nvl(to_char(rc5c.TO_BEDR_PROVCOMP10_OUD),'NULL')        	<> nvl(to_char(rc5c.TO_BEDR_PROVCOMP10_NW),'NULL')      		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_BEDR_PROVCOMP10',rc5c.TO_BEDR_PROVCOMP10_OUD,rc5c.TO_BEDR_PROVCOMP10_NW);end if;
      if nvl(to_char(rc5c.TO_ITEM_PROVCOMP11_OUD),'NULL')        	<> nvl(to_char(rc5c.TO_ITEM_PROVCOMP11_NW),'NULL')      		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ITEM_PROVCOMP11',rc5c.TO_ITEM_PROVCOMP11_OUD,rc5c.TO_ITEM_PROVCOMP11_NW);end if;
      if nvl(to_char(rc5c.TO_BEDR_PROVCOMP11_OUD),'NULL')        	<> nvl(to_char(rc5c.TO_BEDR_PROVCOMP11_NW),'NULL')      		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_BEDR_PROVCOMP11',rc5c.TO_BEDR_PROVCOMP11_OUD,rc5c.TO_BEDR_PROVCOMP11_NW);end if;
      if nvl(to_char(rc5c.TO_ITEM_PROVCOMP12_OUD),'NULL')        	<> nvl(to_char(rc5c.TO_ITEM_PROVCOMP12_NW),'NULL')      		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_ITEM_PROVCOMP12',rc5c.TO_ITEM_PROVCOMP12_OUD,rc5c.TO_ITEM_PROVCOMP12_NW);end if;
      if nvl(to_char(rc5c.TO_BEDR_PROVCOMP12_OUD),'NULL')        	<> nvl(to_char(rc5c.TO_BEDR_PROVCOMP12_NW),'NULL')      		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_BEDR_PROVCOMP12',rc5c.TO_BEDR_PROVCOMP12_OUD,rc5c.TO_BEDR_PROVCOMP12_NW);end if;
      if nvl(to_char(rc5c.TO_OMSCHRIJVING2_OUD),'NULL')  		<> nvl(to_char(rc5c.TO_OMSCHRIJVING2_NW),'NULL')        		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_OMSCHRIJVING2',rc5c.TO_OMSCHRIJVING2_OUD,rc5c.TO_OMSCHRIJVING2_NW);end if;
      if nvl(to_char(rc5c.TO_OMSCHRIJVING3_OUD),'NULL')  		<> nvl(to_char(rc5c.TO_OMSCHRIJVING3_NW),'NULL')        		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_OMSCHRIJVING3',rc5c.TO_OMSCHRIJVING3_OUD,rc5c.TO_OMSCHRIJVING3_NW);end if;
      if nvl(to_char(rc5c.TO_OMSCHRIJVING4_OUD),'NULL')  		<> nvl(to_char(rc5c.TO_OMSCHRIJVING4_NW),'NULL')        		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_OMSCHRIJVING4',rc5c.TO_OMSCHRIJVING4_OUD,rc5c.TO_OMSCHRIJVING4_NW);end if;
      if nvl(to_char(rc5c.TO_OPDRGEVER_BEGUNST_OUD),'NULL')      	<> nvl(to_char(rc5c.TO_OPDRGEVER_BEGUNST_NW),'NULL')    		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_OPDRGEVER_BEGUNST',rc5c.TO_OPDRGEVER_BEGUNST_OUD,rc5c.TO_OPDRGEVER_BEGUNST_NW);end if;
      if nvl(to_char(rc5c.TO_OPDRACHT_BEG_BANK_OUD),'NULL')      	<> nvl(to_char(rc5c.TO_OPDRACHT_BEG_BANK_NW),'NULL')    		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_OPDRACHT_BEG_BANK',rc5c.TO_OPDRACHT_BEG_BANK_OUD,rc5c.TO_OPDRACHT_BEG_BANK_NW);end if;
      if nvl(to_char(rc5c.TO_EXTERNREKENINGNR_OUD),'NULL')       	<> nvl(to_char(rc5c.TO_EXTERNREKENINGNR_NW),'NULL')     		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_EXTERNREKENINGNR',rc5c.TO_EXTERNREKENINGNR_OUD,rc5c.TO_EXTERNREKENINGNR_NW);end if;
      if nvl(to_char(rc5c.TO_WOONPLAATS_OUD),'NULL')     		<> nvl(to_char(rc5c.TO_WOONPLAATS_NW),'NULL')   			then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_WOONPLAATS',rc5c.TO_WOONPLAATS_OUD,rc5c.TO_WOONPLAATS_NW);end if;
      if nvl(to_char(rc5c.TO_OMSCHRIJVING5_OUD),'NULL')  		<> nvl(to_char(rc5c.TO_OMSCHRIJVING5_NW),'NULL')        		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_OMSCHRIJVING5',rc5c.TO_OMSCHRIJVING5_OUD,rc5c.TO_OMSCHRIJVING5_NW);end if;
      if nvl(to_char(rc5c.TO_CONCEPT_STORNERING_OUD),'NULL')     	<> nvl(to_char(rc5c.TO_CONCEPT_STORNERING_NW),'NULL')   		then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_CONCEPT_STORNERING',rc5c.TO_CONCEPT_STORNERING_OUD,rc5c.TO_CONCEPT_STORNERING_NW);end if;
      if nvl(to_char(rc5c.TO_AFWIJKING_TRANS_PROFIEL_OUD),'NULL')        <> nvl(to_char(rc5c.TO_AFWIJKING_TRANS_PROFIEL_NW),'NULL')      then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_AFWIJKING_TRANS_PROFIEL',rc5c.TO_AFWIJKING_TRANS_PROFIEL_OUD,rc5c.TO_AFWIJKING_TRANS_PROFIEL_NW);end if;
      if nvl(to_char(rc5c.TO_STORNO_REASON_OUD),'NULL')  		<> nvl(to_char(rc5c.TO_STORNO_REASON_NW),'NULL')        	then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_OMSCHRIJVING',s1,rc5c.rowid_oud,rc5c.rowid_nw,'TO_STORNO_REASON',rc5c.TO_STORNO_REASON_OUD,rc5c.TO_STORNO_REASON_NW);end if;

   end loop;

--
-- TAP_BPS_REGISTER
--

   s1 := 0;

   for rc7a in c7a loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7a.rowid,null,'BPSR_PPR_ID',rc7a.BPSR_PPR_ID,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7a.rowid,null,'BPSR_YEAR',rc7a.BPSR_YEAR,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7a.rowid,null,'BPSR_SEQ',rc7a.BPSR_SEQ,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7a.rowid,null,'BPSR_TR_VOLGNUMMER',rc7a.BPSR_TR_VOLGNUMMER,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7a.rowid,null,'BPSR_USER_ID',rc7a.BPSR_USER_ID,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7a.rowid,null,'BPSR_REFERENCE_DATE',rc7a.BPSR_REFERENCE_DATE,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7a.rowid,null,'BPSR_ID',rc7a.BPSR_ID,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7a.rowid,null,'BPSR_BE_VOLGNUMMER',rc7a.BPSR_BE_VOLGNUMMER,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7a.rowid,null,'BPSR_REGISTERINDICATOR',rc7a.BPSR_REGISTERINDICATOR,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7a.rowid,null,'BPSR_EXPORT_DATE_TIME',rc7a.BPSR_EXPORT_DATE_TIME,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7a.rowid,null,'BPSR_REPORT',rc7a.BPSR_REPORT,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7a.rowid,null,'BPSR_IS_CONVERTED',rc7a.BPSR_IS_CONVERTED,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7a.rowid,null,'BPSR_ID_ORIGIN',rc7a.BPSR_ID_ORIGIN,null);

   end loop;

   s1 := 0;

   for rc7b in c7b loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,null,rc7b.rowid,'BPSR_PPR_ID',null,rc7b.BPSR_PPR_ID);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,null,rc7b.rowid,'BPSR_YEAR',null,rc7b.BPSR_YEAR);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,null,rc7b.rowid,'BPSR_SEQ',null,rc7b.BPSR_SEQ);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,null,rc7b.rowid,'BPSR_TR_VOLGNUMMER',null,rc7b.BPSR_TR_VOLGNUMMER);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,null,rc7b.rowid,'BPSR_USER_ID',null,rc7b.BPSR_USER_ID);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,null,rc7b.rowid,'BPSR_REFERENCE_DATE',null,rc7b.BPSR_REFERENCE_DATE);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,null,rc7b.rowid,'BPSR_ID',null,rc7b.BPSR_ID);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,null,rc7b.rowid,'BPSR_BE_VOLGNUMMER',null,rc7b.BPSR_BE_VOLGNUMMER);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,null,rc7b.rowid,'BPSR_REGISTERINDICATOR',null,rc7b.BPSR_REGISTERINDICATOR);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,null,rc7b.rowid,'BPSR_EXPORT_DATE_TIME',null,rc7b.BPSR_EXPORT_DATE_TIME);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,null,rc7b.rowid,'BPSR_REPORT',null,rc7b.BPSR_REPORT);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,null,rc7b.rowid,'BPSR_IS_CONVERTED',null,rc7b.BPSR_IS_CONVERTED);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,null,rc7b.rowid,'BPSR_ID_ORIGIN',null,rc7b.BPSR_ID_ORIGIN);

   end loop;

   s1 := 0;

   for rc7c in c7c loop

      s1 := s1 + 1;

      if nvl(to_char(rc7c.BPSR_PPR_ID_OUD),'NULL') <> nvl(to_char(rc7c.BPSR_PPR_ID_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7c.rowid_oud,rc7c.rowid_nw,'BPSR_PPR_ID',rc7c.BPSR_PPR_ID_OUD,rc7c.BPSR_PPR_ID_NW);end if;
      if nvl(to_char(rc7c.BPSR_YEAR_OUD),'NULL') <> nvl(to_char(rc7c.BPSR_YEAR_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7c.rowid_oud,rc7c.rowid_nw,'BPSR_YEAR',rc7c.BPSR_YEAR_OUD,rc7c.BPSR_YEAR_NW);end if;
      if nvl(to_char(rc7c.BPSR_SEQ_OUD),'NULL') <> nvl(to_char(rc7c.BPSR_SEQ_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7c.rowid_oud,rc7c.rowid_nw,'BPSR_SEQ',rc7c.BPSR_SEQ_OUD,rc7c.BPSR_SEQ_NW);end if;
      if nvl(to_char(rc7c.BPSR_TR_VOLGNUMMER_OUD),'NULL') <> nvl(to_char(rc7c.BPSR_TR_VOLGNUMMER_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7c.rowid_oud,rc7c.rowid_nw,'BPSR_TR_VOLGNUMMER',rc7c.BPSR_TR_VOLGNUMMER_OUD,rc7c.BPSR_TR_VOLGNUMMER_NW);end if;
      if nvl(to_char(rc7c.BPSR_USER_ID_OUD),'NULL')	<> nvl(to_char(rc7c.BPSR_USER_ID_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7c.rowid_oud,rc7c.rowid_nw,'BPSR_USER_ID',rc7c.BPSR_USER_ID_OUD,rc7c.BPSR_USER_ID_NW);end if;
      if nvl(to_char(rc7c.BPSR_REFERENCE_DATE_OUD),'NULL') <> nvl(to_char(rc7c.BPSR_REFERENCE_DATE_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7c.rowid_oud,rc7c.rowid_nw,'BPSR_REFERENCE_DATE',rc7c.BPSR_REFERENCE_DATE_OUD,rc7c.BPSR_REFERENCE_DATE_NW);end if;
      if nvl(to_char(rc7c.BPSR_ID_OUD),'NULL') <> nvl(to_char(rc7c.BPSR_ID_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7c.rowid_oud,rc7c.rowid_nw,'BPSR_ID',rc7c.BPSR_ID_OUD,rc7c.BPSR_ID_NW);end if;
      if nvl(to_char(rc7c.BPSR_BE_VOLGNUMMER_OUD),'NULL') <> nvl(to_char(rc7c.BPSR_BE_VOLGNUMMER_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7c.rowid_oud,rc7c.rowid_nw,'BPSR_BE_VOLGNUMMER',rc7c.BPSR_BE_VOLGNUMMER_OUD,rc7c.BPSR_BE_VOLGNUMMER_NW);end if;
      if nvl(to_char(rc7c.BPSR_REGISTERINDICATOR_OUD),'NULL') <> nvl(to_char(rc7c.BPSR_REGISTERINDICATOR_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7c.rowid_oud,rc7c.rowid_nw,'BPSR_REGISTERINDICATOR',rc7c.BPSR_REGISTERINDICATOR_OUD,rc7c.BPSR_REGISTERINDICATOR_NW);end if;
      if nvl(to_char(rc7c.BPSR_EXPORT_DATE_TIME_OUD),'NULL') <> nvl(to_char(rc7c.BPSR_EXPORT_DATE_TIME_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7c.rowid_oud,rc7c.rowid_nw,'BPSR_EXPORT_DATE_TIME',rc7c.BPSR_EXPORT_DATE_TIME_OUD,rc7c.BPSR_EXPORT_DATE_TIME_NW);end if;
      if nvl(to_char(rc7c.BPSR_REPORT_OUD),'NULL') <> nvl(to_char(rc7c.BPSR_REPORT_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7c.rowid_oud,rc7c.rowid_nw,'BPSR_REPORT',rc7c.BPSR_REPORT_OUD,rc7c.BPSR_REPORT_NW);end if;
      if nvl(to_char(rc7c.BPSR_IS_CONVERTED_OUD),'NULL') <> nvl(to_char(rc7c.BPSR_IS_CONVERTED_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7c.rowid_oud,rc7c.rowid_nw,'BPSR_IS_CONVERTED',rc7c.BPSR_IS_CONVERTED_OUD,rc7c.BPSR_IS_CONVERTED_NW);end if;
      if nvl(to_char(rc7c.BPSR_ID_ORIGIN_OUD),'NULL') <> nvl(to_char(rc7c.BPSR_ID_ORIGIN_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_BPS_REGISTER',s1,rc7c.rowid_oud,rc7c.rowid_nw,'BPSR_ID_ORIGIN',rc7c.BPSR_ID_ORIGIN_OUD,rc7c.BPSR_ID_ORIGIN_NW);end if;

   end loop;

--
-- TRANSACTIONCURRENCYQUOTES
--

/*

Wel in EEN maar niet in TWEE

*/

   s1 := 0;

   for rc10a in c10a loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10a.rowid,null,'TR_VOLGNUMMER',rc10a.TR_VOLGNUMMER,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10a.rowid,null,'CLASS',rc10a.CLASS,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10a.rowid,null,'CURRENCY',rc10a.CURRENCY,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10a.rowid,null,'FACTOR',rc10a.FACTOR,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10a.rowid,null,'QUOTE',rc10a.QUOTE,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10a.rowid,null,'RECIPROKE',rc10a.RECIPROKE,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10a.rowid,null,'SPREAD',rc10a.SPREAD,null);

   end loop;

/*

Wel in TWEE maar niet in EEN

*/

   s1 := 0;

   for rc10b in c10b loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,null,rc10b.rowid,'TR_VOLGNUMMER',null,rc10b.TR_VOLGNUMMER);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,null,rc10b.rowid,'CLASS',null,rc10b.CLASS);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,null,rc10b.rowid,'CURRENCY',null,rc10b.CURRENCY);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,null,rc10b.rowid,'FACTOR',null,rc10b.FACTOR);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,null,rc10b.rowid,'QUOTE',null,rc10b.QUOTE);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,null,rc10b.rowid,'RECIPROKE',null,rc10b.RECIPROKE);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,null,rc10b.rowid,'SPREAD',null,rc10b.SPREAD);

   end loop;

/*

Zowel in EEN als in TWEE

*/

   s1 := 0;

   for rc10c in c10c loop

      s1 := s1 + 1;

      if nvl(to_char(rc10c.TR_VOLGNUMMER_OUD),'NULL')    <> nvl(to_char(rc10c.TR_VOLGNUMMER_NW),'NULL')  then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10c.rowid_oud,rc10c.rowid_nw,'TR_VOLGNUMMER',rc10c.TR_VOLGNUMMER_OUD,rc10c.TR_VOLGNUMMER_NW);end if;
      if nvl(to_char(rc10c.CLASS_OUD),'NULL')    	<> nvl(to_char(rc10c.CLASS_NW),'NULL')  	then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10c.rowid_oud,rc10c.rowid_nw,'CLASS',rc10c.CLASS_OUD,rc10c.CLASS_NW);end if;
      if nvl(to_char(rc10c.CURRENCY_OUD),'NULL') 	<> nvl(to_char(rc10c.CURRENCY_NW),'NULL')       then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10c.rowid_oud,rc10c.rowid_nw,'CURRENCY',rc10c.CURRENCY_OUD,rc10c.CURRENCY_NW);end if;
      if nvl(to_char(rc10c.FACTOR_OUD),'NULL')   	<> nvl(to_char(rc10c.FACTOR_NW),'NULL') 	then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10c.rowid_oud,rc10c.rowid_nw,'FACTOR',rc10c.FACTOR_OUD,rc10c.FACTOR_NW);end if;
      if nvl(to_char(rc10c.QUOTE_OUD),'NULL')    	<> nvl(to_char(rc10c.QUOTE_NW),'NULL')  	then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10c.rowid_oud,rc10c.rowid_nw,'QUOTE',rc10c.QUOTE_OUD,rc10c.QUOTE_NW);end if;
      if nvl(to_char(rc10c.RECIPROKE_OUD),'NULL')        <> nvl(to_char(rc10c.RECIPROKE_NW),'NULL')      then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10c.rowid_oud,rc10c.rowid_nw,'RECIPROKE',rc10c.RECIPROKE_OUD,rc10c.RECIPROKE_NW);end if;
      if nvl(to_char(rc10c.SPREAD_OUD),'NULL')        <> nvl(to_char(rc10c.SPREAD_NW),'NULL')      then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANSACTIONCURRENCYQUOTES',s1,rc10c.rowid_oud,rc10c.rowid_nw,'SPREAD',rc10c.SPREAD_OUD,rc10c.SPREAD_NW);end if;

   end loop;

--
-- TRANS_KOSTENCOMPONENTEN
--

/*

Wel in EEN maar niet in TWEE

*/

   s1 := 0;

   for rc11a in c11a loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11a.rowid,null,'TKC_VOLGNUMMER',rc11a.TKC_VOLGNUMMER,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11a.rowid,null,'TKC_COMPONENTCODE',rc11a.TKC_COMPONENTCODE,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11a.rowid,null,'TKC_BEDRAG',rc11a.TKC_BEDRAG,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11a.rowid,null,'TKC_MUNTSOORT',rc11a.TKC_MUNTSOORT,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11a.rowid,null,'TKC_BEDRAG_TRANS_VAL',rc11a.TKC_BEDRAG_TRANS_VAL,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11a.rowid,null,'TKC_BOEK_BEDRAG',rc11a.TKC_BOEK_BEDRAG,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11a.rowid,null,'TKC_BOEK_VALUTA',rc11a.TKC_BOEK_VALUTA,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11a.rowid,null,'TKC_RE_ID',rc11a.TKC_RE_ID,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11a.rowid,null,'TKC_MUT_GEMAAKT',rc11a.TKC_MUT_GEMAAKT,null);

   end loop;

/*

Wel in TWEE maar niet in EEN

*/

   s1 := 0;

   for rc11b in c11b loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,null,rc11b.rowid,'TKC_VOLGNUMMER',null,rc11b.TKC_VOLGNUMMER);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,null,rc11b.rowid,'TKC_COMPONENTCODE',null,rc11b.TKC_COMPONENTCODE);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,null,rc11b.rowid,'TKC_BEDRAG',null,rc11b.TKC_BEDRAG);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,null,rc11b.rowid,'TKC_MUNTSOORT',null,rc11b.TKC_MUNTSOORT);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,null,rc11b.rowid,'TKC_BEDRAG_TRANS_VAL',null,rc11b.TKC_BEDRAG_TRANS_VAL);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,null,rc11b.rowid,'TKC_BOEK_BEDRAG',null,rc11b.TKC_BOEK_BEDRAG);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,null,rc11b.rowid,'TKC_BOEK_VALUTA',null,rc11b.TKC_BOEK_VALUTA);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,null,rc11b.rowid,'TKC_RE_ID',null,rc11b.TKC_RE_ID);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,null,rc11b.rowid,'TKC_MUT_GEMAAKT',null,rc11b.TKC_MUT_GEMAAKT);

   end loop;

/*

Zowel in EEN als in TWEE

*/
   s1 := 0;

   for rc11c in c11c loop

      s1 := s1 + 1;

      if nvl(to_char(rc11c.TKC_VOLGNUMMER_OUD),'NULL') <> nvl(to_char(rc11c.TKC_VOLGNUMMER_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11c.rowid_oud,rc11c.rowid_nw,'TKC_VOLGNUMMER',rc11c.TKC_VOLGNUMMER_OUD,rc11c.TKC_VOLGNUMMER_NW);end if;
      if nvl(to_char(rc11c.TKC_COMPONENTCODE_OUD),'NULL') <> nvl(to_char(rc11c.TKC_COMPONENTCODE_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11c.rowid_oud,rc11c.rowid_nw,'TKC_COMPONENTCODE',rc11c.TKC_COMPONENTCODE_OUD,rc11c.TKC_COMPONENTCODE_NW);end if;
      if nvl(to_char(rc11c.TKC_BEDRAG_OUD),'NULL') <> nvl(to_char(rc11c.TKC_BEDRAG_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11c.rowid_oud,rc11c.rowid_nw,'TKC_BEDRAG',rc11c.TKC_BEDRAG_OUD,rc11c.TKC_BEDRAG_NW);end if;
      if nvl(to_char(rc11c.TKC_MUNTSOORT_OUD),'NULL') <> nvl(to_char(rc11c.TKC_MUNTSOORT_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11c.rowid_oud,rc11c.rowid_nw,'TKC_MUNTSOORT',rc11c.TKC_MUNTSOORT_OUD,rc11c.TKC_MUNTSOORT_NW);end if;
      if nvl(to_char(rc11c.TKC_BEDRAG_TRANS_VAL_OUD),'NULL') <> nvl(to_char(rc11c.TKC_BEDRAG_TRANS_VAL_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11c.rowid_oud,rc11c.rowid_nw,'TKC_BEDRAG_TRANS_VAL',rc11c.TKC_BEDRAG_TRANS_VAL_OUD,rc11c.TKC_BEDRAG_TRANS_VAL_NW);end if;
      if nvl(to_char(rc11c.TKC_BOEK_BEDRAG_OUD),'NULL') <> nvl(to_char(rc11c.TKC_BOEK_BEDRAG_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11c.rowid_oud,rc11c.rowid_nw,'TKC_BOEK_BEDRAG',rc11c.TKC_BOEK_BEDRAG_OUD,rc11c.TKC_BOEK_BEDRAG_NW);end if;
      if nvl(to_char(rc11c.TKC_BOEK_VALUTA_OUD),'NULL')	<> nvl(to_char(rc11c.TKC_BOEK_VALUTA_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11c.rowid_oud,rc11c.rowid_nw,'TKC_BOEK_VALUTA',rc11c.TKC_BOEK_VALUTA_OUD,rc11c.TKC_BOEK_VALUTA_NW);end if;
      if nvl(to_char(rc11c.TKC_RE_ID_OUD),'NULL') <> nvl(to_char(rc11c.TKC_RE_ID_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11c.rowid_oud,rc11c.rowid_nw,'TKC_RE_ID',rc11c.TKC_RE_ID_OUD,rc11c.TKC_RE_ID_NW);end if;
      if nvl(to_char(rc11c.TKC_MUT_GEMAAKT_OUD),'NULL')	<> nvl(to_char(rc11c.TKC_MUT_GEMAAKT_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_KOSTENCOMPONENTEN',s1,rc11c.rowid_oud,rc11c.rowid_nw,'TKC_MUT_GEMAAKT',rc11c.TKC_MUT_GEMAAKT_OUD,rc11c.TKC_MUT_GEMAAKT_NW);end if;

   end loop;

--
-- TRANS_CALC_COMPONENTS
--

/*

Wel in EEN maar niet in TWEE

*/

   s1 := 0;

   for rc12a in c12a loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'TCC_TR_ID',rc12a.TCC_TR_ID,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'TCC_COMPONENT_CODE',rc12a.TCC_COMPONENT_CODE,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'TCC_CFCU_ID',rc12a.TCC_CFCU_ID,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'TCC_DISCOUNT_PERC',rc12a.TCC_DISCOUNT_PERC,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'TCC_RE_ID',rc12a.TCC_RE_ID,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'BASE_AMOUNT_SYST',rc12a.BASE_AMOUNT_SYST,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'BASE_AMOUNT_PARTY',rc12a.BASE_AMOUNT_PARTY,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'BASE_AMOUNT_TRANS',rc12a.BASE_AMOUNT_TRANS,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'BASE_QUANTITY',rc12a.BASE_QUANTITY,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'BASE_QTY_FACTOR',rc12a.BASE_QTY_FACTOR,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'BASE_QTY_SCALE',rc12a.BASE_QTY_SCALE,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'TARIFF_AMOUNT',rc12a.TARIFF_AMOUNT,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'TARIFF_PERCENTAGE',rc12a.TARIFF_PERCENTAGE,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12a.rowid,null,'TARIFF_METHOD',rc12a.TARIFF_METHOD,null);

   end loop;

/*

Wel in TWEE maar niet in EEN

*/

   s1 := 0;

   for rc12b in c12b loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'TCC_TR_ID',null,rc12b.TCC_TR_ID);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'TCC_COMPONENT_CODE',null,rc12b.TCC_COMPONENT_CODE);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'TCC_CFCU_ID',null,rc12b.TCC_CFCU_ID);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'TCC_DISCOUNT_PERC',null,rc12b.TCC_DISCOUNT_PERC);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'TCC_RE_ID',null,rc12b.TCC_RE_ID);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'BASE_AMOUNT_SYST',null,rc12b.BASE_AMOUNT_SYST);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'BASE_AMOUNT_PARTY',null,rc12b.BASE_AMOUNT_PARTY);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'BASE_AMOUNT_TRANS',null,rc12b.BASE_AMOUNT_TRANS);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'BASE_QUANTITY',null,rc12b.BASE_QUANTITY);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'BASE_QTY_FACTOR',null,rc12b.BASE_QTY_FACTOR);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'BASE_QTY_SCALE',null,rc12b.BASE_QTY_SCALE);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'TARIFF_AMOUNT',null,rc12b.TARIFF_AMOUNT);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'TARIFF_PERCENTAGE',null,rc12b.TARIFF_PERCENTAGE);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,null,rc12b.rowid,'TARIFF_METHOD',null,rc12b.TARIFF_METHOD);

   end loop;

/*

Zowel in EEN als in TWEE

*/

   s1 := 0;

   for rc12c in c12c loop

      s1 := s1 + 1;

      if nvl(to_char(rc12c.TCC_TR_ID_OUD),'NULL')  	<> nvl(to_char(rc12c.TCC_TR_ID_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'TCC_TR_ID',rc12c.TCC_TR_ID_OUD,rc12c.TCC_TR_ID_NW);end if;
      if nvl(to_char(rc12c.TCC_COMPONENT_CODE_OUD),'NULL') 	<> nvl(to_char(rc12c.TCC_COMPONENT_CODE_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'TCC_COMPONENT_CODE',rc12c.TCC_COMPONENT_CODE_OUD,rc12c.TCC_COMPONENT_CODE_NW);end if;
      if nvl(to_char(rc12c.TCC_CFCU_ID_OUD),'NULL') <> nvl(to_char(rc12c.TCC_CFCU_ID_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'TCC_CFCU_ID',rc12c.TCC_CFCU_ID_OUD,rc12c.TCC_CFCU_ID_NW);end if;
      if nvl(to_char(rc12c.TCC_DISCOUNT_PERC_OUD),'NULL') 	<> nvl(to_char(rc12c.TCC_DISCOUNT_PERC_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'TCC_DISCOUNT_PERC',rc12c.TCC_DISCOUNT_PERC_OUD,rc12c.TCC_DISCOUNT_PERC_NW);end if;
      if nvl(to_char(rc12c.TCC_RE_ID_OUD),'NULL')   <> nvl(to_char(rc12c.TCC_RE_ID_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'TCC_RE_ID',rc12c.TCC_RE_ID_OUD,rc12c.TCC_RE_ID_NW);end if;
      if nvl(to_char(rc12c.BASE_AMOUNT_SYST_OUD),'NULL')   <> nvl(to_char(rc12c.BASE_AMOUNT_SYST_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'BASE_AMOUNT_SYST',rc12c.BASE_AMOUNT_SYST_OUD,rc12c.BASE_AMOUNT_SYST_NW);end if;
      if nvl(to_char(rc12c.BASE_AMOUNT_PARTY_OUD),'NULL')   <> nvl(to_char(rc12c.BASE_AMOUNT_PARTY_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'BASE_AMOUNT_PARTY',rc12c.BASE_AMOUNT_PARTY_OUD,rc12c.BASE_AMOUNT_PARTY_NW);end if;
      if nvl(to_char(rc12c.BASE_AMOUNT_TRANS_OUD),'NULL')   <> nvl(to_char(rc12c.BASE_AMOUNT_TRANS_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'BASE_AMOUNT_TRANS',rc12c.BASE_AMOUNT_TRANS_OUD,rc12c.BASE_AMOUNT_TRANS_NW);end if;
      if nvl(to_char(rc12c.BASE_QUANTITY_OUD),'NULL')   <> nvl(to_char(rc12c.BASE_QUANTITY_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'BASE_QUANTITY',rc12c.BASE_QUANTITY_OUD,rc12c.BASE_QUANTITY_NW);end if;
      if nvl(to_char(rc12c.BASE_QTY_FACTOR_OUD),'NULL')   <> nvl(to_char(rc12c.BASE_QTY_FACTOR_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'BASE_QTY_FACTOR',rc12c.BASE_QTY_FACTOR_OUD,rc12c.BASE_QTY_FACTOR_NW);end if;
      if nvl(to_char(rc12c.BASE_QTY_SCALE_OUD),'NULL')   <> nvl(to_char(rc12c.BASE_QTY_SCALE_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'BASE_QTY_SCALE',rc12c.BASE_QTY_SCALE_OUD,rc12c.BASE_QTY_SCALE_NW);end if;
      if nvl(to_char(rc12c.TARIFF_AMOUNT_OUD),'NULL')   <> nvl(to_char(rc12c.TARIFF_AMOUNT_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'TARIFF_AMOUNT',rc12c.TARIFF_AMOUNT_OUD,rc12c.TARIFF_AMOUNT_NW);end if;
      if nvl(to_char(rc12c.TARIFF_PERCENTAGE_OUD),'NULL')   <> nvl(to_char(rc12c.TARIFF_PERCENTAGE_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'TARIFF_PERCENTAGE',rc12c.TARIFF_PERCENTAGE_OUD,rc12c.TARIFF_PERCENTAGE_NW);end if;
      if nvl(to_char(rc12c.TARIFF_METHOD_OUD),'NULL')   <> nvl(to_char(rc12c.TARIFF_METHOD_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_CALC_COMPONENTS',s1,rc12c.rowid_oud,rc12c.rowid_nw,'TARIFF_METHOD',rc12c.TARIFF_METHOD_OUD,rc12c.TARIFF_METHOD_NW);end if;

   end loop;

--
-- TRANS_SUBCALC_COMPONENTS
--

/*

Wel in EEN maar niet in TWEE

*/

   s1 := 0;

   for rc13a in c13a loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,rc13a.rowid,null,'TSCC_TCC_TR_ID',rc13a.TSCC_TCC_TR_ID,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,rc13a.rowid,null,'TSCC_TCC_CFCU_ID',rc13a.TSCC_TCC_CFCU_ID,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,rc13a.rowid,null,'TSCC_AMOUNT_TYPE',rc13a.TSCC_AMOUNT_TYPE,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,rc13a.rowid,null,'TSCC_AMOUNT_SYST',rc13a.TSCC_AMOUNT_SYST,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,rc13a.rowid,null,'TSCC_AMOUNT_TRANS',rc13a.TSCC_AMOUNT_TRANS,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,rc13a.rowid,null,'TSCC_AMOUNT_PARTY',rc13a.TSCC_AMOUNT_PARTY,null);
   end loop;

/*

Wel in TWEE maar niet in EEN

*/

   s1 := 0;

   for rc13b in c13b loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,null,rc13b.rowid,'TSCC_TCC_TR_ID',null,rc13b.TSCC_TCC_TR_ID);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,null,rc13b.rowid,'TSCC_TCC_CFCU_ID',null,rc13b.TSCC_TCC_CFCU_ID);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,null,rc13b.rowid,'TSCC_AMOUNT_TYPE',null,rc13b.TSCC_AMOUNT_TYPE);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,null,rc13b.rowid,'TSCC_AMOUNT_SYST',null,rc13b.TSCC_AMOUNT_SYST);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,null,rc13b.rowid,'TSCC_AMOUNT_TRANS',null,rc13b.TSCC_AMOUNT_TRANS);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,null,rc13b.rowid,'TSCC_AMOUNT_PARTY',null,rc13b.TSCC_AMOUNT_PARTY);
   end loop;

/*

Zowel in EEN als in TWEE

*/

   s1 := 0;

   for rc13c in c13c loop

      s1 := s1 + 1;

      if nvl(to_char(rc13c.TSCC_TCC_TR_ID_OUD),'NULL') <> nvl(to_char(rc13c.TSCC_TCC_TR_ID_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,rc13c.rowid_oud,rc13c.rowid_nw,'TSCC_TCC_TR_ID',rc13c.TSCC_TCC_TR_ID_OUD,rc13c.TSCC_TCC_TR_ID_NW);end if;
      if nvl(to_char(rc13c.TSCC_TCC_CFCU_ID_OUD),'NULL') <> nvl(to_char(rc13c.TSCC_TCC_CFCU_ID_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,rc13c.rowid_oud,rc13c.rowid_nw,'TSCC_TCC_CFCU_ID',rc13c.TSCC_TCC_CFCU_ID_OUD,rc13c.TSCC_TCC_CFCU_ID_NW);end if;
      if nvl(to_char(rc13c.TSCC_AMOUNT_TYPE_OUD),'NULL') <> nvl(to_char(rc13c.TSCC_AMOUNT_TYPE_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,rc13c.rowid_oud,rc13c.rowid_nw,'TSCC_AMOUNT_TYPE',rc13c.TSCC_AMOUNT_TYPE_OUD,rc13c.TSCC_AMOUNT_TYPE_NW);end if;
      if nvl(to_char(rc13c.TSCC_AMOUNT_SYST_OUD),'NULL') <> nvl(to_char(rc13c.TSCC_AMOUNT_SYST_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,rc13c.rowid_oud,rc13c.rowid_nw,'TSCC_AMOUNT_SYST',rc13c.TSCC_AMOUNT_SYST_OUD,rc13c.TSCC_AMOUNT_SYST_NW);end if;
      if nvl(to_char(rc13c.TSCC_AMOUNT_TRANS_OUD),'NULL') <> nvl(to_char(rc13c.TSCC_AMOUNT_TRANS_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,rc13c.rowid_oud,rc13c.rowid_nw,'TSCC_AMOUNT_TRANS',rc13c.TSCC_AMOUNT_TRANS_OUD,rc13c.TSCC_AMOUNT_TRANS_NW);end if;
      if nvl(to_char(rc13c.TSCC_AMOUNT_PARTY_OUD),'NULL') <> nvl(to_char(rc13c.TSCC_AMOUNT_PARTY_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TRANS_SUBCALC_COMPONENTS',s1,rc13c.rowid_oud,rc13c.rowid_nw,'TSCC_AMOUNT_PARTY',rc13c.TSCC_AMOUNT_PARTY_OUD,rc13c.TSCC_AMOUNT_PARTY_NW);end if;
   end loop;

--
-- TAP_TR_REL_ACCOUNT_INFO
--

/*

Wel in EEN maar niet in TWEE

*/

   s1 := 0;

   for rc14a in c14a loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_TR_REL_ACCOUNT_INFO',s1,rc14a.rowid,null,'TRAI_TR_VOLGNUMMER',rc14a.TRAI_TR_VOLGNUMMER,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_TR_REL_ACCOUNT_INFO',s1,rc14a.rowid,null,'TRAI_TR_ACCOUNT_CODE',rc14a.TRAI_TR_ACCOUNT_CODE,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_TR_REL_ACCOUNT_INFO',s1,rc14a.rowid,null,'TRAI_TR_CL_ID',rc14a.TRAI_TR_CL_ID,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_TR_REL_ACCOUNT_INFO',s1,rc14a.rowid,null,'TRAI_TR_RE_ID',rc14a.TRAI_TR_RE_ID,null);
   end loop;

/*

Wel in TWEE maar niet in EEN

*/

   s1 := 0;

   for rc14b in c14b loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_TR_REL_ACCOUNT_INFO',s1,null,rc14b.rowid,'TRAI_TR_VOLGNUMMER',null,rc14b.TRAI_TR_VOLGNUMMER);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_TR_REL_ACCOUNT_INFO',s1,null,rc14b.rowid,'TRAI_TR_ACCOUNT_CODE',null,rc14b.TRAI_TR_ACCOUNT_CODE);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_TR_REL_ACCOUNT_INFO',s1,null,rc14b.rowid,'TRAI_TR_CL_ID',null,rc14b.TRAI_TR_CL_ID);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_TR_REL_ACCOUNT_INFO',s1,null,rc14b.rowid,'TRAI_TR_RE_ID',null,rc14b.TRAI_TR_RE_ID);
   end loop;

/*

Zowel in EEN als in TWEE

*/

   s1 := 0;

   for rc14c in c14c loop

      s1 := s1 + 1;

      if nvl(to_char(rc14c.TRAI_TR_VOLGNUMMER_OUD),'NULL') <> nvl(to_char(rc14c.TRAI_TR_VOLGNUMMER_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_TR_REL_ACCOUNT_INFO',s1,rc14c.rowid_oud,rc14c.rowid_nw,'TRAI_TR_VOLGNUMMER',rc14c.TRAI_TR_VOLGNUMMER_OUD,rc14c.TRAI_TR_VOLGNUMMER_NW);end if;
      if nvl(to_char(rc14c.TRAI_TR_ACCOUNT_CODE_OUD),'NULL') <> nvl(to_char(rc14c.TRAI_TR_ACCOUNT_CODE_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_TR_REL_ACCOUNT_INFO',s1,rc14c.rowid_oud,rc14c.rowid_nw,'TRAI_TR_ACCOUNT_CODE',rc14c.TRAI_TR_ACCOUNT_CODE_OUD,rc14c.TRAI_TR_ACCOUNT_CODE_NW);end if;
      if nvl(to_char(rc14c.TRAI_TR_CL_ID_OUD),'NULL') <> nvl(to_char(rc14c.TRAI_TR_CL_ID_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_TR_REL_ACCOUNT_INFO',s1,rc14c.rowid_oud,rc14c.rowid_nw,'TRAI_TR_CL_ID',rc14c.TRAI_TR_CL_ID_OUD,rc14c.TRAI_TR_CL_ID_NW);end if;
      if nvl(to_char(rc14c.TRAI_TR_RE_ID_OUD),'NULL') <> nvl(to_char(rc14c.TRAI_TR_RE_ID_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_TR_REL_ACCOUNT_INFO',s1,rc14c.rowid_oud,rc14c.rowid_nw,'TRAI_TR_RE_ID',rc14c.TRAI_TR_RE_ID_OUD,rc14c.TRAI_TR_RE_ID_NW);end if;
   end loop;

--
-- TAP_POST_ACTION_BATCH
--

/*

Wel in EEN maar niet in TWEE

*/

   s1 := 0;

   for rc15a in c15a loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_POST_ACTION_BATCH',s1,rc15a.rowid,null,'TR_ID',rc15a.TR_ID,null);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_POST_ACTION_BATCH',s1,rc15a.rowid,null,'POST_ACTION',rc15a.POST_ACTION,null);
   end loop;

/*

Wel in TWEE maar niet in EEN

*/

   s1 := 0;

   for rc15b in c15b loop

      s1 := s1 + 1;

      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_POST_ACTION_BATCH',s1,null,rc15b.rowid,'TR_ID',null,rc15b.TR_ID);
      tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_POST_ACTION_BATCH',s1,null,rc15b.rowid,'POST_ACTION',null,rc15b.POST_ACTION);
   end loop;

/*

Zowel in EEN als in TWEE

*/

   s1 := 0;

   for rc15c in c15c loop

      s1 := s1 + 1;

      if nvl(to_char(rc15c.TR_ID_OUD),'NULL') <> nvl(to_char(rc15c.TR_ID_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_POST_ACTION_BATCH',s1,rc15c.rowid_oud,rc15c.rowid_nw,'TR_ID',rc15c.TR_ID_OUD,rc15c.TR_ID_NW);end if;
      if nvl(to_char(rc15c.POST_ACTION_OUD),'NULL') <> nvl(to_char(rc15c.POST_ACTION_NW),'NULL') then tdiff_new_insert(i_guid,i_tr_volgnummer_een,i_tr_volgnummer_twee,'TAP_POST_ACTION_BATCH',s1,rc15c.rowid_oud,rc15c.rowid_nw,'POST_ACTION',rc15c.POST_ACTION_OUD,rc15c.POST_ACTION_NW);end if;
   end loop;
   
   commit;

end tdiff_new;

-- DE CODE VOOR DE FUNCTION VERSION
function Version
return varchar2
is

begin
      return gv_versie;
end version;
-- EINDE CODE FUNCTION VERSION

end TAP_TDIFF_PACK;
/
