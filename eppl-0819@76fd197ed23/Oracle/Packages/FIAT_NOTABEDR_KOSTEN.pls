create or replace package FIAT_NOTABEDR_KOSTEN
is

/*------------------------------------------------------------------------------
Package     : FIAT_NOTABEDR_KOSTEN
description : code voor de package FIAT_NOTABEDR_KOSTEN
------------------------------------------------------------------------------*/
-- variabele die het laatste versienummer bevat:
   gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';

-- procedure reynderstax_berekenen
   procedure reynderstax_berekenen
   (i_ordernummer           in  kosten_werkbestand.kst_ordernummer%type
   ,i_order_regel           in  kosten_werkbestand.kst_orderregel%type
   ,i_order_detailnummer    in  kosten_werkbestand.kst_detailnummer%type
   ,i_fonds_id              in  beleggingsinstrument.be_volgnummer%type
   ,i_fonds_symbool         in  beleggingsinstrument.be_symbool%type
   ,i_fonds_optietype       in  beleggingsinstrument.be_optietype%type
   ,i_fonds_expiratiedatum  in  beleggingsinstrument.be_expiratiedatum%type
   ,i_fonds_exerciseprijs   in  beleggingsinstrument.be_exerciseprijs%type
   ,i_ppr_id                in  producten_per_relatie.ppr_id%type
   ,i_verkoop_aantal        in  kosten_werkbestand.kst_trans_aantal%type
   ,i_fonds_koers_NAV       in  kosten_werkbestand.kst_trans_prijs%type
   ,i_belasting_percentage  in  tax_tarif_scales.ts_percentage%type
   ,i_gebruik_RT_EuropPass  in  number
   ,i_munt_notatie          in  muntsoorten.mu_notatie%type
   ,i_debuggen              in  relatie_fiattering.rf_debug_j_n%type
   ,i_debug_user            in  relatie_fiattering.rf_debug_user%type
   ,o_belasting_bedrag      out fiat_order_costs_det.focd_total_amt%type
   );

-- function version
   function version
   return             varchar2;

end FIAT_NOTABEDR_KOSTEN;
/
create or replace package body FIAT_NOTABEDR_KOSTEN
is

/*------------------------------------------------------------------------------
Package body : FIAT_NOTABEDR_KOSTEN
description  : code voor de package body FIAT_NOTABEDR_KOSTEN waarbinnen de volgende
               functions en procedures aanwezig zijn:
               procedure  reynderstax_berekenen
               functions  version
------------------------------------------------------------------------------*/

-- globale variabelen (dus te gebruiken over alle procedures nadat de waarden zijn
-- bepaald in de eerst aanroepend procedure)
   gv_debuggen             number(1);
   gv_debug_user           beleggingsadviseurs.ba_magic_user_id%type;
   

-- procedure bepaal_asset_test_perc
   procedure bepaal_asset_test_perc
   (i_fonds_id            in  beleggingsinstrument.be_volgnummer%type
   ,i_test_datum          in  werkbestand.wk_datum_1%type
   ,o_asset_test_perc     out asset_tests.test_percentage%type
   );

-- procedure bepaal_TIS
   procedure bepaal_TIS
   (i_fonds_id            in  beleggingsinstrument.be_volgnummer%type
   ,i_ref_datum           in  werkbestand.wk_datum_1%type
   ,o_TIS_waarde          out taxable_income_per_share.tis_amount%type
   ,o_TIS_bestaat         out number
   );

-- procedure bepaal_NAV
   procedure bepaal_NAV
   (i_fonds_symbool        in  beleggingsinstrument.be_symbool%type
   ,i_fonds_optietype      in  beleggingsinstrument.be_optietype%type
   ,i_fonds_expiratiedatum in  beleggingsinstrument.be_expiratiedatum%type
   ,i_fonds_exerciseprijs  in  beleggingsinstrument.be_exerciseprijs%type
   ,i_ref_datum            in  fn_quotes_table.quot_datum%type
   ,o_NAV_waarde           out fn_quotes_table.quot_midden%type
   );

-- procedure bepaal_schrikkel_aantal
   procedure bepaal_schrikkel_aantal
   (i_datum_vanaf            in  werkbestand.wk_datum_1%type
   ,i_datum_tm               in  werkbestand.wk_datum_1%type
   ,o_aantal_schrikkel_dagen out number
   );

-- DE CODE VOOR DE PROCEDURE REYNDERSTAX_BEREKENEN
procedure reynderstax_berekenen
(i_ordernummer           in  kosten_werkbestand.kst_ordernummer%type
,i_order_regel           in  kosten_werkbestand.kst_orderregel%type
,i_order_detailnummer    in  kosten_werkbestand.kst_detailnummer%type
,i_fonds_id              in  beleggingsinstrument.be_volgnummer%type
,i_fonds_symbool         in  beleggingsinstrument.be_symbool%type
,i_fonds_optietype       in  beleggingsinstrument.be_optietype%type
,i_fonds_expiratiedatum  in  beleggingsinstrument.be_expiratiedatum%type
,i_fonds_exerciseprijs   in  beleggingsinstrument.be_exerciseprijs%type
,i_ppr_id                in  producten_per_relatie.ppr_id%type
,i_verkoop_aantal        in  kosten_werkbestand.kst_trans_aantal%type
,i_fonds_koers_NAV       in  kosten_werkbestand.kst_trans_prijs%type
,i_belasting_percentage  in  tax_tarif_scales.ts_percentage%type
,i_gebruik_RT_EuropPass  in  number
,i_munt_notatie          in  muntsoorten.mu_notatie%type
,i_debuggen              in  relatie_fiattering.rf_debug_j_n%type
,i_debug_user            in  relatie_fiattering.rf_debug_user%type
,o_belasting_bedrag      out fiat_order_costs_det.focd_total_amt%type
)

is

   -- variabelen voor de berekening:
   v_minAcquisitionDateEP    werkbestand.wk_datum_1%type;
   v_minAcquisitionDateNEP   werkbestand.wk_datum_1%type;
   v_fixedNavIncomeTillDate  werkbestand.wk_datum_1%type;
   v_fixedAssetTestLimit     number(6,3);
   v_fixedAssetTestDateLimit werkbestand.wk_datum_1%type;
   v_daysPerYear             number(3);
   v_flatReturnPerYear       Number(8,5);
   v_aantal_verkoop_over     kosten_werkbestand.kst_trans_aantal%type;    
   v_aantal_verkocht         kosten_werkbestand.kst_trans_aantal%type;
   v_record_wegschrijen      number(1);
   
   v_NAV_id                  tap_bps_register_amount_type.bpst_id%type;
   v_TIS_id                  tap_bps_register_amount_type.bpst_id%type;
   
   v_NAV_waarde              number(15,6);
   v_NAV_waarde_bestaat      number(1);
   v_TIS_waarde              number(15,6);
   v_TIS_waarde_bestaat      number(1);
   
   v_volgnummer_sort         number(10);
   
   v_fondssymbool            beleggingsinstrument.be_symbool%type;
   v_fonds_optietype         beleggingsinstrument.be_optietype%type;
   v_fonds_exp_datum         beleggingsinstrument.be_expiratiedatum%type;
   v_fonds_exerc_prijs       beleggingsinstrument.be_exerciseprijs%type;
   v_fonds_creatie_datum     beleggingsinstrument.be_creatie_datum%type;
   v_fonds_asset_test        asset_tests.test_percentage%type;
   v_fonds_asset_test_2013   beleggingsinstrument.be_asset_test_20130630%type;
   v_maximized_asset_test    asset_tests.test_percentage%type;
   v_max_asset_test_20130630 asset_tests.test_percentage%type;

   
cursor tbr is
   select t.bpsr_registerindicator, t.bpsr_ppr_id, t.bpsr_be_volgnummer, t.bpsr_reference_date, 
          t.bpsr_seq,               t.bpsr_id,     t.bpsr_tr_volgnummer,
          h.ryfh_free_to_sell_qty
   from   tap_bps_register t, transactions r, tap_reynders_fifo_admin_header h
   where  t.bpsr_registerindicator       = 'SECU'
   and    t.bpsr_ppr_id                  = i_ppr_id
   and    t.bpsr_be_volgnummer           = i_fonds_id
   and    r.tr_volgnummer (+)            = t.bpsr_tr_volgnummer
   and    (r.tr_volgnummer               is null
           or
           r.tr_mut_gemaakt              = 'J')
   and    h.ryfh_bpsr_id                 = t.bpsr_id
   and    h.ryfh_free_to_sell_qty        > 0
   order by t.bpsr_reference_date, t.bpsr_seq;


begin
   gv_debuggen               := i_debuggen;
   gv_debug_user             := i_debug_user;
   
   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In procedure FIAT_NOTABEDR_KOSTEN.reynderstax_berekenen');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Fonds id       : '||to_char(i_fonds_id)||' ; ppr_id     : '||to_char(i_ppr_id));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Verkoop aantal : '||to_char(i_verkoop_aantal)||' ; fonds koers : '||to_char(i_fonds_koers_NAV));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Belasting %    : '||to_char(i_belasting_percentage)||' ; gebruik RT EuropPass : '||to_char(i_gebruik_RT_EuropPass));
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;

   v_minAcquisitionDateEP    := '20050701';
   v_minAcquisitionDateNEP   := '20080701';
   v_fixedNavIncomeTillDate  := '20130701';
   v_fixedAssetTestLimit     := 25;
   v_fixedAssetTestDateLimit := '20171231';
   v_daysPerYear             := 365;
   v_flatReturnPerYear       := 0.03;
   
   if i_belasting_percentage = 0 
      or 
      i_gebruik_RT_EuropPass = 1 and to_char(sysdate,'yyyymmdd') < v_minAcquisitionDateEP
      or
      i_gebruik_RT_EuropPass = 0 and to_char(sysdate,'yyyymmdd') < v_minAcquisitionDateNEP
   then
      -- Er kan/hoeft geen belasting berekend te worden
      o_belasting_bedrag   := 0;
      
      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Er kan/hoeft geen belasting berekend worden');
      end if;
      
      -- Er moet/kan belasting berekend worden
   else
      v_aantal_verkoop_over  := i_verkoop_aantal;  
      v_volgnummer_sort      := 0;
      
      select t.bpst_id
      into   v_NAV_id 
      from   tap_bps_register_amount_type t
      where  t.bpst_classification = 'NAV'
      and    t.bpst_class_default  = 1;
      
      select t.bpst_id
      into   v_TIS_id 
      from   tap_bps_register_amount_type t
      where  t.bpst_classification = 'TIS'
      and    t.bpst_class_default  = 1;
      
      select b.be_symbool,        b.be_optietype,        b.be_expiratiedatum,
             b.be_exerciseprijs,  b.be_creatie_datum,    b.be_asset_test_20130630
      into   v_fondssymbool,      v_fonds_optietype,     v_fonds_exp_datum,
             v_fonds_exerc_prijs, v_fonds_creatie_datum, v_fonds_asset_test_2013
      from   beleggingsinstrument b
      where  b.be_volgnummer       = i_fonds_id;
      
      v_fonds_asset_test_2013   := v_fonds_asset_test_2013/100;
      if v_fonds_asset_test_2013 <> 0
      then
         v_max_asset_test_20130630 := v_fonds_asset_test_2013;
      else
         v_max_asset_test_20130630 := 1;
      end if;  
      
      if gv_debuggen = 1
      then
         FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'De loop op register');
      end if;
      
      for r_tbr in tbr 
      loop
         v_record_wegschrijen := 0;
         -- Controleren of er een NAV waarde aanwezig is voor de boeking
         begin 
             select t.bpsa_amount, 1
             into   v_NAV_waarde,  v_NAV_waarde_bestaat
             from   tap_bps_register_amount t
             where  t.bpsa_bpsr_id   = r_tbr.bpsr_id
             and    t.bpsa_bpst_id   = v_NAV_id;
         exception
             when no_data_found
             then
                v_NAV_waarde         := 0;
                v_NAV_waarde_bestaat := 0;
         end;
         
         begin
             select t.bpsa_amount, 1
             into   v_TIS_waarde,  v_TIS_waarde_bestaat
             from   tap_bps_register_amount t
             where  t.bpsa_bpsr_id   = r_tbr.bpsr_id
             and    t.bpsa_bpst_id   = v_TIS_id;
         exception
             when no_data_found
             then
                v_TIS_waarde         := 0;
                v_TIS_waarde_bestaat := 0;
         end;
         
         if v_aantal_verkoop_over > 0
         then
            if v_aantal_verkoop_over >= r_tbr.ryfh_free_to_sell_qty
            then
               v_aantal_verkoop_over := v_aantal_verkoop_over - r_tbr.ryfh_free_to_sell_qty;
               v_aantal_verkocht     := r_tbr.ryfh_free_to_sell_qty;
               v_volgnummer_sort     := v_volgnummer_sort + 1;
               v_record_wegschrijen  := 1;   
            elsif v_aantal_verkoop_over <> 0 and v_aantal_verkoop_over < r_tbr.ryfh_free_to_sell_qty
            then
               v_aantal_verkocht     := v_aantal_verkoop_over;
               v_aantal_verkoop_over := 0;   
               v_volgnummer_sort     := v_volgnummer_sort + 1;
               v_record_wegschrijen  := 1;
            end if;  
         end if;
         
         if v_record_wegschrijen = 1
         then
            insert into fiat_tax_register
            (order_number,      order_line,          order_detail_line,
             line_number,       reference_date, 
             number_sold,       nav,                 nav_found,      
             tis,               tis_found)
            values
            (i_ordernummer,     i_order_regel,       i_order_detailnummer,
             v_volgnummer_sort, case when r_tbr.bpsr_reference_date is null then '00000000' else to_char(r_tbr.bpsr_reference_date,'YYYYMMDD') end,
             v_aantal_verkocht, v_NAV_waarde,        v_NAV_waarde_bestaat,
             v_TIS_waarde,      v_TIS_waarde_bestaat);
         end if;

         if gv_debuggen = 1
         then
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Volgnummer sortering : '||to_char(v_volgnummer_sort)||' ; referentiedatum : '||
            case when r_tbr.bpsr_reference_date is null then '00000000' else to_char(r_tbr.bpsr_reference_date,'YYYYMMDD') end);
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'NAV bestaat          : '||to_char(v_NAV_waarde_bestaat)||' ; NAV waarde : '||to_char(v_NAV_waarde));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'TIS bestaat          : '||to_char(v_TIS_waarde_bestaat)||' ; TIS waarde : '||to_char(v_TIS_waarde));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Aantal verkocht      : '||to_char(v_aantal_verkocht)||' ; Record wegschrijven : '||to_char(v_record_wegschrijen));
            FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
         end if;
      end loop;
      
      -- De positiemutaties zijn nu bekend en kunnen gebruikt worden voor de berekening van de belasting
      declare
         v_minimum_acquisition_date        werkbestand.wk_datum_1%type;
         v_gebruik_min_acquis_date         number(1);
         v_uitsluiten_van_berekening       number(1);
         v_asset_test_2017                 number(6,3);
         v_effectiveRealizedCapitalGain    fn_quotes_table.quot_midden%type;
         v_capital_gain                    fn_quotes_table.quot_midden%type;
         v_taxable_base                    fn_quotes_table.quot_midden%type;
         
         v_TIS_koop                        taxable_income_per_share.tis_amount%type;
         v_TIS_koop_bestaat                number(1);
         v_TIS_verkoop                     taxable_income_per_share.tis_amount%type;
         v_TIS_verkoop_bestaat             number(1);
         v_beide_TIS_beschikbaar           number(1);
         v_delta_TIS                       taxable_income_per_share.tis_amount%type;
         
         v_NAV_koop                        fn_quotes_table.quot_midden%type;
         v_delta_NAV                       fn_quotes_table.quot_midden%type;
         v_NAV_op_min_aquis_datum          fn_quotes_table.quot_midden%type;
         v_NAV_per_01_07_2013              fn_quotes_table.quot_midden%type;
         
         v_dagen_in_periode_1              number(5);
         v_aantal_schrikkel_dagen          number(3);
         v_capital_gain_periode_1          fn_quotes_table.quot_midden%type;
         v_capital_gain_periode_2          fn_quotes_table.quot_midden%type;
         
         cursor rt is
            select f.reference_date, f.number_sold, f.nav,
                   f.nav_found,      f.tis,         f.tis_found
            from   fiat_tax_register f
            where  f.order_number      = i_ordernummer
            and    f.order_line        = i_order_regel
            and    f.order_detail_line = i_order_detailnummer    
            order by f.line_number;
            
      begin
        if gv_debuggen = 1
        then  
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In berekening deel van de Reynders tax');
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' '); 
        end if;
        
        -- De TIS van de huidige verkoop hoeft maar eenmalig bepaald te worden.
        bepaal_TIS(i_fonds_id, to_char(sysdate,'yyyymmdd'), v_TIS_verkoop, v_TIS_verkoop_bestaat);
        
        -- setten variabelen die maar 1 keer gezet moeten worden:
        v_taxable_base                    := 0;
        
        for r_rt in rt
        loop
           v_minimum_acquisition_date     := '00000000';
           v_gebruik_min_acquis_date      := 0;
           v_uitsluiten_van_berekening    := 0;
           v_asset_test_2017              := 0;
           v_effectiveRealizedCapitalGain := 0;
           v_capital_gain                 := 0;
           
           v_TIS_koop                     := 0;
           v_TIS_koop_bestaat             := 0;
           v_beide_TIS_beschikbaar        := 0;
           v_delta_TIS                    := 0;
           
           v_NAV_koop                     := 0;
           v_delta_NAV                    := 0;
           v_NAV_op_min_aquis_datum       := 0;
           v_NAV_per_01_07_2013           := 0;
           
           v_dagen_in_periode_1           := 0;
           v_aantal_schrikkel_dagen       := 0;
           v_capital_gain_periode_1       := 0;
           v_capital_gain_periode_2       := 0;
           
           -- Geen aankoopdatum bekend (reference_date = 00000000), dan de Max (greatest) van be_creatie_datum en de minimum acquisitie datum.
           if i_gebruik_RT_EuropPass = 1
           then
              v_minimum_acquisition_date := greatest(r_rt.reference_date, case when r_rt.reference_date = '00000000' then v_fonds_creatie_datum else '00000000' end, v_minAcquisitionDateEP);
              
              if r_rt.reference_date < v_minimum_acquisition_date or v_minimum_acquisition_date = v_fonds_creatie_datum or v_minimum_acquisition_date = v_minAcquisitionDateEP
              then  
                 v_gebruik_min_acquis_date := 1;
              end if;
           else
              v_minimum_acquisition_date := greatest(r_rt.reference_date, case when r_rt.reference_date = '00000000' then v_fonds_creatie_datum else '00000000' end, v_minAcquisitionDateNEP);
              
              if r_rt.reference_date < v_minimum_acquisition_date or v_minimum_acquisition_date = v_fonds_creatie_datum or v_minimum_acquisition_date = v_minAcquisitionDateNEP
              then
                 v_gebruik_min_acquis_date := 1;
              end if;
           end if;
           
           if gv_debuggen = 1
           then
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'register datum        : '||r_rt.reference_date||' ; fonds creatie datum : '||v_fonds_creatie_datum);
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'minim acquis datum EP : '||v_minAcquisitionDateEP||' ; minim acquis datum NEP '||v_minAcquisitionDateNEP);
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'minim acquis datum    : '||v_minimum_acquisition_date||'; gebruik min acquis datum : '||to_char(v_gebruik_min_acquis_date));
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fixed asset test date limit : '||v_fixedAssetTestDateLimit);
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
           end if;
           
           if greatest(v_minimum_acquisition_date,r_rt.reference_date)<=v_fixedAssetTestDateLimit
           then  
              --Kopen voor 1-1-2018 worden uitgesloten als eind 2017 de assettest onder 25% ligt
              bepaal_asset_test_perc(i_fonds_id, v_fixedAssetTestDateLimit, v_asset_test_2017);
              if v_asset_test_2017 < v_fixedAssetTestLimit
              then
                 v_uitsluiten_van_berekening := 1;
              end if;
           end if;
           
           if gv_debuggen = 1
           then
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'asset test 2017 : '||to_char(v_asset_test_2017)||' ; fixed asset test limiet : '||to_char(v_fixedAssetTestLimit));
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'uitsluiten van berekening : '||to_char(v_uitsluiten_van_berekening));
              FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
           end if;
           
           if v_uitsluiten_van_berekening = 0
           then
              if i_gebruik_RT_EuropPass = 1 and v_gebruik_min_acquis_date = 1
              then
                 bepaal_TIS(i_fonds_id, v_minimum_acquisition_date, v_TIS_koop, v_TIS_koop_bestaat);
              else
                 v_TIS_koop         := r_rt.tis;
                 v_TIS_koop_bestaat := r_rt.tis_found;
              end if;
              
              if v_TIS_koop_bestaat = 1 and v_TIS_verkoop_bestaat = 1
              then
                 v_beide_TIS_beschikbaar := 1;
                 v_delta_TIS             := v_TIS_verkoop - v_TIS_koop; 
              end if;
              
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'TIS koop    : '||to_char(v_TIS_koop)||' ; TIS koop bestaat : '||to_char(v_TIS_koop_bestaat));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'TIS verkoop : '||to_char(v_TIS_verkoop)||' ; TIS verkoop bestaat : '||to_char(v_TIS_verkoop_bestaat));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'delta TIS   : '||to_char(v_delta_TIS)||' ; beide TIS beschikbaar : '||to_char(v_beide_TIS_beschikbaar));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
              end if;
              
              -- Als de koop datum voor de Reynders tax startdatum ligt, dan het maximum van NAV koop en NAV bij minimale acquisitin date
              if v_gebruik_min_acquis_date = 1
              then
                 bepaal_NAV(i_fonds_symbool, i_fonds_optietype, i_fonds_expiratiedatum, i_fonds_exerciseprijs, v_minimum_acquisition_date, v_NAV_op_min_aquis_datum); 
                 v_NAV_koop := greatest(v_NAV_op_min_aquis_datum,r_rt.nav);
              else
                 v_NAV_koop := r_rt.nav;
              end if;
              v_delta_NAV                    := i_fonds_koers_NAV - v_NAV_koop;
              v_effectiveRealizedCapitalGain := v_delta_NAV * r_rt.number_sold;
              
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'NAV op min acquisitie datum : '||to_char(v_NAV_op_min_aquis_datum)||' ; NAV koop : '||to_char(v_NAV_koop));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'effectiveRealizedCapitalGain: '||to_char(v_effectiveRealizedCapitalGain)||' ; delta NAV : '||to_char(v_delta_NAV));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
              end if;
              
              -- Reynders Tax Europees Pasport OF koopdatum >= 01-07-2013
              if i_gebruik_RT_EuropPass = 1 or r_rt.reference_date >= v_fixedNavIncomeTillDate
              then
                 if gv_debuggen = 1
                 then
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in Reynders Tax Europees Pasport OF koopdatum >= 01-07-2013');
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                 end if;
                 
                 if v_beide_TIS_beschikbaar = 1
                 then
                    if v_delta_TIS <= 0
                    then
                       v_capital_gain := 0;
                    else
                       if v_delta_NAV <= 0
                       then
                          v_capital_gain := 0;
                       else
                          if v_delta_NAV < v_delta_TIS
                          then
                             v_capital_gain := v_effectiveRealizedCapitalGain;
                          else
                             v_capital_gain := r_rt.number_sold * v_delta_TIS;
                          end if;
                       end if;
                    end if;
                    
                    if gv_debuggen = 1
                    then
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in deel beide TIS beschikbaar');
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'delta TIS    : '||to_char(v_delta_TIS)||' ; delta NAV : '||to_char(v_delta_NAV));
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'capital gain : '||to_char(v_capital_gain));
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                    end if;
                    
                 else -- niet beide TIS beschikbaar
                    if v_delta_NAV <= 0
                    then
                       v_capital_gain := 0;
                    else
                       bepaal_asset_test_perc(i_fonds_id, to_char(sysdate,'yyyymmdd'), v_fonds_asset_test);
                       if v_fonds_asset_test = 0
                       then
                          v_maximized_asset_test := 1;
                       else
                          v_maximized_asset_test := v_fonds_asset_test/100;
                       end if;
                       v_capital_gain := least(r_rt.number_sold * v_delta_NAV * v_maximized_asset_test , v_effectiveRealizedCapitalGain);
                    end if;
                    
                    if gv_debuggen = 1
                    then
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in deel niet beide TIS beschikbaar');
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'delta NAV             : '||to_char(v_delta_NAV)||' ; fonds asset test : '||to_char(v_fonds_asset_test));
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'maximimzed asset test : '||to_char(v_maximized_asset_test)||' ; capital gain : '||to_char(v_capital_gain));
                       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                    end if;
                 end if;  -- einde beide TIS beschikbaar
              
              -- Reynders tax Non Europees pasport EN koopdatum < 01-07-2013 
              else
                 if gv_debuggen = 1
                 then
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Reynders tax non Europees paspoort EN koopdatum < 01-07-2013');
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                 end if;
                 
                 bepaal_NAV(i_fonds_symbool, i_fonds_optietype, i_fonds_expiratiedatum, i_fonds_exerciseprijs, v_fixedNavIncomeTillDate, v_NAV_per_01_07_2013);
                 -- Periode 1 tot 30-06-2013, gecorrigeerd voor schrikkeldagen.
                 bepaal_schrikkel_aantal(v_minimum_acquisition_date, v_fixedNavIncomeTillDate, v_aantal_schrikkel_dagen);
                 
                 v_dagen_in_periode_1 := to_date(v_fixedNavIncomeTillDate,'yyyymmdd')-to_date(v_minimum_acquisition_date,'yyyymmdd') - v_aantal_schrikkel_dagen;
                 v_dagen_in_periode_1 := greatest(0,v_dagen_in_periode_1);
                 
                 v_capital_gain_periode_1 := r_rt.number_sold * v_NAV_koop * v_max_asset_test_20130630 * v_flatReturnPerYear * (v_dagen_in_periode_1/v_daysPerYear);
                 
                 if gv_debuggen = 1
                 then
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'gegevens voor capital gain periode 1');
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'NAV per 01-07-2013 : '||to_char(v_NAV_per_01_07_2013)||' ; aantal schrikkel dagen : '||to_char(v_aantal_schrikkel_dagen));
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'minimum acquisition date : '||v_minimum_acquisition_date||' ; fixed NAV income till date : '||v_fixedNavIncomeTillDate);
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'dagen in periode 1 : '||to_char(v_dagen_in_periode_1)||' ; capital gain periode 1 : '||to_char(v_capital_gain_periode_1));
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'max asset test 20130630 : '||to_char(v_max_asset_test_20130630));
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                 end if;
                 
                 -- Periode 2 vanaf 30-06-2013
                 -- Controleer of er een TIS is van 01-07-2013
                 bepaal_TIS(i_fonds_id, v_fixedNavIncomeTillDate, v_TIS_koop, v_TIS_koop_bestaat);
                 if v_TIS_koop_bestaat = 1 and v_TIS_verkoop_bestaat = 1
                 then
                    v_capital_gain_periode_2 := r_rt.number_sold * (v_TIS_verkoop - v_TIS_koop);
                 else
                    bepaal_asset_test_perc(i_fonds_id, to_char(sysdate,'yyyymmdd'), v_fonds_asset_test);
                    if v_fonds_asset_test = 0
                    then
                       v_maximized_asset_test := 1;
                    else
                       v_maximized_asset_test := v_fonds_asset_test/100;
                    end if;
                    v_capital_gain_periode_2 := r_rt.number_sold * (i_fonds_koers_NAV - v_NAV_per_01_07_2013) * v_maximized_asset_test;
                 end if;
                 v_capital_gain := greatest(least(r_rt.number_sold * v_delta_NAV, v_capital_gain_periode_1 + v_capital_gain_periode_2),0);            
                 
                 if gv_debuggen = 1
                 then
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'gegevens voor capital gain periode 2 en totaal capital gain');
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'TIS Koop    : '||to_char(v_TIS_koop)||' ; TIS koop bestaat : '||to_char(v_TIS_koop_bestaat));
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'TIS verkoop : '||to_char(v_TIS_verkoop)||' ; TIS verkoop bestaat : '||to_char(v_TIS_verkoop_bestaat));
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fonds asset test : '||to_char(v_fonds_asset_test)||' ; maximized asset test : '||to_char(v_maximized_asset_test));
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'NAV per 01-07-2013 : '||to_char(v_NAV_per_01_07_2013)||' ; delta NAV : '||to_char(v_delta_NAV));
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'capital gain periode 2 : '||to_char(v_capital_gain_periode_2)||' ; capital gain : '||to_char(v_capital_gain));
                    FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
                 end if;
              end if;
              
              v_taxable_base := v_taxable_base + v_capital_gain;
              
              if gv_debuggen = 1
              then
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'taxable base : '||to_char(v_taxable_base));
                 FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
              end if;
              
           end if; -- Einde uitsluiten_van_berekening = 0
        end loop;
        o_belasting_bedrag := round( round(v_taxable_base,i_munt_notatie) * i_belasting_percentage/100,i_munt_notatie);
        
        if gv_debuggen = 1
        then
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'o belasting bedrag : '||to_char(o_belasting_bedrag));
           FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
        end if;
        
      end;
   end if;  -- Einde Er moet/kan belasting berekend worden
   
   if gv_debuggen = 1
   then
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Einde procedure FIAT_NOTABEDR_KOSTEN.reynderstax_berekenen');
      FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
   end if;
   
end reynderstax_berekenen;
-- EINDE CODE PROCEDURE REYNDERSTAX_BEREKENEN


-- DE CODE VOOR DE PROCEDURE BEPAAL_ASSET_TEST_PERC
-- procedure voor het bepalen van een asset test percentage voor een fonds
procedure bepaal_asset_test_perc
(i_fonds_id            in  beleggingsinstrument.be_volgnummer%type
,i_test_datum          in  werkbestand.wk_datum_1%type
,o_asset_test_perc     out asset_tests.test_percentage%type
)

is
   
  v_max_date_time      asset_tests.test_date%type;

begin
  v_max_date_time      := null;
  
  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In procedure bepaal_asset_test_perc');
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fonds id      : '||to_char(i_fonds_id)||' ; test datum : '||i_test_datum);
  end if;
    
  begin 
     select test_date
     into   v_max_date_time
     from   (
             select a.test_date
             from   asset_tests a
             where  a.be_id                         = i_fonds_id
             and    to_char(a.test_date,'yyyymmdd') <= i_test_datum
             order by a.test_date desc
            )
     where rownum <= 1;
  exception
     when no_data_found
     then
        v_max_date_time   := null;
        o_asset_test_perc := 0;
  end;

  if v_max_date_time is not null
  then
     select a.test_percentage
     into   o_asset_test_perc
     from   asset_tests a
     where  a.be_id     = i_fonds_id
     and    a.test_date = v_max_date_time;
  end if;
  
  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'max date time : '||to_char(v_max_date_time,'yyyymmdd hh24:mi:ss')||
                                             ' ; bepaald asset test perc : '||to_char(o_asset_test_perc));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
  end if;

end bepaal_asset_test_perc;
-- EINDE VAN DE PROCEDURE BEPAAL_ASSET_TEST_PERC


-- DE CODE VOOR DE PROCEDURE BEPAAL_TIS
-- procedure bepaal_TIS
procedure bepaal_TIS
(i_fonds_id            in  beleggingsinstrument.be_volgnummer%type
,i_ref_datum           in  werkbestand.wk_datum_1%type
,o_TIS_waarde          out taxable_income_per_share.tis_amount%type
,o_TIS_bestaat         out number
)

is 
  v_max_datetime       taxable_income_per_share.tis_datetime%type;


begin
  v_max_datetime   := null;
  begin
      select tis_datetime
      into   v_max_datetime
      from   (
              select t.tis_datetime
              from   taxable_income_per_share t
              where  t.tis_be_id                        = i_fonds_id
              and    t.tis_status                       = 0
              and    to_char(t.tis_datetime,'yyyymmdd') <= i_ref_datum
              order by t.tis_datetime desc
             )
      where rownum <= 1;
  exception
     when no_data_found
     then
        o_TIS_waarde   := 0;
        o_TIS_bestaat  := 0;
        v_max_datetime := null;
  end;  

  if v_max_datetime is not null
  then
     select t.tis_amount, 1 
     into   o_TIS_waarde, o_TIS_bestaat
     from   taxable_income_per_share t
     where  t.tis_be_id    = i_fonds_id
     and    t.tis_status   = 0
     and    t.tis_datetime = v_max_datetime;
  end if;    
  
  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In procedure bepaal_TIS');
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fonds id     : '||to_char(i_fonds_id)||' ; referentie datum : '||i_ref_datum);
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'TIS waarde   : '||to_char(o_TIS_waarde)||' ; TIS bestaat : '||to_char(o_TIS_bestaat));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'MAX datetime : '||to_char(v_max_datetime,'dd-mm-yyyy hh24:mi:ss'));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
  end if; 

end bepaal_TIS;
-- EINDE CODE BEPAAL_TIS


-- DE CODE VOOR DE PROCEDURE BEPAAL_NAV
-- procedure bepaal_NAV
procedure bepaal_NAV
(i_fonds_symbool        in  beleggingsinstrument.be_symbool%type
,i_fonds_optietype      in  beleggingsinstrument.be_optietype%type
,i_fonds_expiratiedatum in  beleggingsinstrument.be_expiratiedatum%type
,i_fonds_exerciseprijs  in  beleggingsinstrument.be_exerciseprijs%type
,i_ref_datum            in  fn_quotes_table.quot_datum%type
,o_NAV_waarde           out fn_quotes_table.quot_midden%type
)

is

  v_max_k_datum           fn_quotes_vw.quot_datum%type;
  v_max_k_tijd            fn_quotes_vw.quot_tijd%type;
  v_maxd_nav              varchar2(14);

begin 
  begin
     select quot_datum, quot_tijd
     into   v_max_k_datum, v_max_k_tijd
     from   (
             select f.quot_datum, f.quot_tijd
             from   fn_quotes_vw f
             where  f.quot_symbool        = i_fonds_symbool
             and    f.quot_optietype      = i_fonds_optietype
             and    f.quot_expiratiedatum = i_fonds_expiratiedatum
             and    f.quot_exerciseprijs  = i_fonds_exerciseprijs
             and    f.quot_soort          = 'SLOT'
             and    f.quot_datum          <= i_ref_datum
             order by f.quot_symbool, f.quot_optietype, f.quot_expiratiedatum, f.quot_exerciseprijs, f.quot_soort, f.quot_datum desc, f.quot_tijd desc
            )
     where  rownum <= 1;
  exception
     when no_data_found
     then
        v_max_k_datum  := 'fo';
        v_max_k_tijd   := 'ut ';
  end;
  
  v_maxd_nav := trim(v_max_k_datum)||trim(v_max_k_tijd);
  if v_maxd_nav is null
  then
     v_maxd_nav := 'fout';
  end if;
  
  if v_maxd_nav <>  'fout'
  then
     select f.quot_midden
     into   o_NAV_waarde
     from   fn_quotes_vw f
     where  f.quot_symbool            = i_fonds_symbool
     and    f.quot_optietype          = i_fonds_optietype
     and    f.quot_expiratiedatum     = i_fonds_expiratiedatum
     and    f.quot_exerciseprijs      = i_fonds_exerciseprijs
     and    f.quot_soort              = 'SLOT'
     and    f.quot_datum||f.quot_tijd = v_maxd_nav;
  end if;  
  
  if gv_debuggen = 1
  then
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'In procedure bepaal_nav');
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fonds symbool   : '||i_fonds_symbool||' ; fonds optietype :  '||i_fonds_optietype);
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'fonds exp.datum : '||i_fonds_expiratiedatum||' ; fonds exerciseprijs : '||to_char(i_fonds_exerciseprijs));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'referentiedatum : '||i_ref_datum||' ; NAV waarde : '||to_char(o_NAV_waarde));
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'max k datum     : '||v_max_k_datum||' ;  max k tijd : '||v_max_k_tijd||' ; maxd nav : '||v_maxd_nav);
     FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' '); 
  end if;
  
end bepaal_nav;
-- EINDE CODE BEPAAL_NAV


-- DE CODE VOOR DE PROCEDURE BEPAAL_SCHRIKKEL_AANTAL
procedure bepaal_schrikkel_aantal
(i_datum_vanaf            in  werkbestand.wk_datum_1%type
,i_datum_tm               in  werkbestand.wk_datum_1%type
,o_aantal_schrikkel_dagen out number
)

is
   v_datum_vanaf          werkbestand.wk_datum_1%type;
   v_datum_tm             werkbestand.wk_datum_1%type;
   v_jaar                 number(4);
   v_jaar_einde           number(4);
   
begin
    if i_datum_vanaf <= i_datum_tm
    then
       v_datum_vanaf := i_datum_vanaf;
       v_datum_tm    := i_datum_tm;
    else
       v_datum_vanaf := i_datum_tm;
       v_datum_tm    := i_datum_vanaf;
    end if;  

    o_aantal_schrikkel_dagen := 0;
    select extract(year from to_date(v_datum_tm,'yyyymmdd'))
    into   v_jaar_einde             
    from   dual;
    
    select extract(year from to_date(v_datum_vanaf,'yyyymmdd'))
    into   v_jaar
    from   dual;
    
    if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'in procedure bepaal_schrikkel_aantal');
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'datum vanaf : '||v_datum_vanaf||' ; datum tm : '||v_datum_tm);
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'jaar einde  : '||to_char(v_jaar_einde)||' ; jaar begin : '||to_char(v_jaar));
    end if;
    
    -- als de datum vanaf al voorbij februari ligt, dan het start jaar 1 opschuiven.
    if v_datum_vanaf >= to_char(v_jaar,'9999')||'0301'
    then
       v_jaar := v_jaar + 1;
    end if; 
    
    -- als de datum tm voor of gelijk 28 februari is, dan eindjaar 1 afnemen
    if v_datum_tm <= to_char(v_jaar_einde,'9999')||'0228'
    then
       v_jaar_einde := v_jaar_einde - 1;
    end if; 
    
    while v_jaar <= v_jaar_einde
    loop   
       if mod(v_jaar,4)= 0 and mod(v_jaar,100)<>0 or mod(v_jaar,400) = 0
       then
          o_aantal_schrikkel_dagen := o_aantal_schrikkel_dagen + 1;
       end if;
       
       if gv_debuggen = 1
       then
          FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'jaar : '||to_char(v_jaar)||' ; aantal schrikkeldagen : '||to_char(o_aantal_schrikkel_dagen));
       end if;
       
       v_jaar := v_jaar + 1;
    end loop;
    
    if gv_debuggen = 1
    then
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'Einde bepaal_schrikkel_aantal');
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,'aantal jaar met schrikkeldagen : '||to_char(o_aantal_schrikkel_dagen));
       FIAT_ALGEMEEN.fiat_debug( gv_debug_user,' ');
    end if;
    
end bepaal_schrikkel_aantal;
-- EINDE CODE BEPAAL_SCHRIKKEL_AANTAL


-- DE CODE VOOR DE FUNCTION VERSION
function Version
return varchar2
is

begin
      return gv_versie;
end version;
-- EINDE CODE FUNCTION VERSION

end FIAT_NOTABEDR_KOSTEN;
/
