CREATE OR REPLACE PACKAGE PC_SET_DAY_QUOTES is

  /*------------------------------------------------------------------------------
  Package     : PC_SET_DAY_QUOTES
  description : code voor de package PC_SET_DAY_QUOTES waarbinnen de volgende
                functions en procedures aanwezig zijn:
                procedure  set_day quotes
                procedure  set_single_quote
                procedure  set_single_indirect_costs
                procedure  historize_day_quotes
				procedure set_calculation_storage_type
				function  get_calcualtion_storage_type
                function   version
  ------------------------------------------------------------------------------*/
  -- variabele die het laatste versienummer bevat:
  gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';

  procedure SET_DAY_QUOTES;
  procedure set_single_quote(p_instrument_id number,
                             p_date          char,
                             p_date_till     char);
  procedure set_single_indirect_cost(p_instrument_id number);
  -- function version
  function version return varchar2;
  PROCEDURE LOCK_PERFORMANCE_CALC(do_lock number);
  
  PROCEDURE HISTORIZE_DAY_QUOTES(p_date_till char);

  PROCEDURE SET_CALCULATION_STORAGE_TYPE(p_type char);
  
  FUNCTION GET_CALCULATION_STORAGE_TYPE return varchar2;

end PC_SET_DAY_QUOTES;
/

CREATE OR REPLACE PACKAGE BODY PC_SET_DAY_QUOTES is
  --global variables
   gv_nmbr_of_parallel_processes varchar2(3);
   gv_start_date_quotes_char varchar2(8);
   gv_start_date_quotes_prev_char varchar2(8);
   gv_start_date_quotes date;
   gv_table_name_new all_tables.table_name%type;
   gv_table_name_old all_tables.table_name%type;
   gv_index_name all_objects.object_name%type;

  -- local function and procedure ceclarations

  PROCEDURE CREATE_DAY_QUOTES_TABLE;
  PROCEDURE INSERT_CLOSE_QUOTES;
  PROCEDURE INSERT_FIXI_QUOTES;
  FUNCTION GET_TABLENAME_VARIANT(p_type char) return char;
  procedure reload_indirect_costs (p_variant char, p_instrument_id number);
  procedure get_object_names_quotes;
  function get_type_of_action return number;

  -- DE CODE VOOR DE FUNCTION VERSION
function Version
return varchar2
is

begin
      return gv_versie;
end version;
-- EINDE CODE FUNCTION VERSION

function get_type_of_action return number
  is
  v_type_of_action number(1);
begin
      select nvl(tb_waarde, 0)
      into v_type_of_action
      from tabelgegevens t
     where t.tb_soort = 'ICCA'
       and t.tb_symbool = 'TYPE';
       return v_type_of_action;
end;
  --procedure reload_indirect_costs (p_variant char);
  -- Function and procedure implementations
  PROCEDURE SET_DAY_QUOTES is
    v_type_of_action number(1);
    v_variant_c char;
    v_test number;
  begin
    v_type_of_action := get_type_of_action;
    select trim(to_char(nvl(tb_waarde, 1)))
      into gv_nmbr_of_parallel_processes
      from tabelgegevens t
     where t.tb_soort = 'ICCA'
       and t.tb_symbool = 'PROC';

    select (nvl(tb_datum, '20180101'))
      into gv_start_date_quotes_char
      from tabelgegevens t
     where t.tb_soort = 'ICCA'
       and t.tb_symbool = 'STRT';

    gv_start_date_quotes := to_date(gv_start_date_quotes_char,'YYYYMMDD');
    gv_start_date_quotes_prev_char := to_char(gv_start_date_quotes-1,'YYYYMMDD');

    get_object_names_quotes();

    execute immediate ('alter session enable parallel dml');
    -- we have the choice depending on TABELGEVENS 'ICCA', 'TYPE'
    -- 1 we recreate the table
    if v_type_of_action = 1 then

       CREATE_DAY_QUOTES_TABLE;

    else
      lock_performance_calc(1);

      -- we truncate and insert
      execute immediate 'truncate table '|| gv_table_name_new;
      execute immediate 'drop index '|| gv_index_name;
      INSERT_CLOSE_QUOTES;
      commit;
      INSERT_FIXI_QUOTES;
      commit;
    end if;
    -- for both options
    v_variant_c := GET_TABLENAME_VARIANT('C');
    reload_indirect_costs(v_variant_c, null);
    execute immediate 'CREATE UNIQUE INDEX '||gv_index_name||' on '||gv_table_name_new||' (be_id, quote_date) parallel '||gv_nmbr_of_parallel_processes;
    execute immediate 'ALTER INDEX '||gv_index_name||' NOPARALLEL';
    execute immediate ('alter session disable parallel dml');
    if v_type_of_action = 1 then
      lock_performance_calc(1);
      execute immediate 'create or replace view PC_QUOTE_PER_DAY_VW as select * from '|| gv_table_name_new ||' union all select * from pc_quote_per_day_hist';
      select count(*) into v_test from user_tables t where t.table_name = gv_table_name_old;
      if v_test>0 then
        execute immediate 'drop table '||gv_table_name_old||' purge';
      end if;
    end if;
    execute immediate 'create or replace view PC_IC_BY_PERIOD_VW as select * from PC_IC_PER_INSTRUMENT_'||v_variant_c;
    if v_variant_c = 'A' then
      gv_table_name_old := 'PC_IC_PER_INSTRUMENT_B';
    else
      gv_table_name_old := 'PC_IC_PER_INSTRUMENT_A';
    end if;
    execute immediate 'truncate table '|| gv_table_name_old;
    lock_performance_calc(0);
  end;
  PROCEDURE LOCK_PERFORMANCE_CALC(do_lock number) is
  begin
    UPDATE TABELGEGEVENS T
       SET T.TB_STATUS = do_lock,
           T.TB_DATUM = to_char(systimestamp, 'YYYYMMDD'),
           T.TB_WAARDE = to_number(to_char(systimestamp,'HH24MISS'))
     where T.TB_SOORT = 'ICCA'
       and tb_SYMBOOL = 'LOCK';
    if (do_lock = 0) then
      UPDATE TABELGEGEVENS T
         SET T.TB_DATUM = to_char(systimestamp, 'YYYYMMDD')
       where T.TB_SOORT = 'ICCA'
         and tb_SYMBOOL = 'DATE';

    end if;
    commit;
  end;


  PROCEDURE CREATE_DAY_QUOTES_TABLE is

  v_test number;
  begin
      -- make sure the new table does not exists.
   select count(*) into v_test from user_tables t where t.table_name = gv_table_name_new;
   if v_test>0 then
            execute immediate 'drop table '||gv_table_name_new||' purge';
    end if;
    execute immediate 'CREATE TABLE '||gv_table_name_new||' parallel '||gv_nmbr_of_parallel_processes||' AS
          select /*+ USE_MERGE (q d) */ q.be_volgnummer be_id, d.calc_date quote_date, q.quot_midden quote from
          (
          select to_date(''20000101'', ''YYYYMMDD'') + (level - 1) as
            calc_date
                  from dual
                  -- en dan beperken tot de gewenste periode
          where to_date(''20000101'', ''YYYYMMDD'') + (level - 1) between
            to_date('||gv_start_date_quotes_char||', ''YYYYMMDD'') and sysdate
                  -- 300*366 dagen sinds 01/01/2000 ofwel iets meer dan 300 jaar.
                  connect by level <= (300*366)) d,
          (select * from
                (
          select f.quot_datum, f.quot_optietype, f.quot_expiratiedatum,
            lead(to_char(to_date(f.quot_datum,''YYYYMMDD'')-1,''YYYYMMDD''), 1, ''99991231'')
            over ( partition by b.be_volgnummer
          order by b.be_volgnummer, f.quot_soort, f.quot_datum, f.quot_tijd) as quot_next_date
                      , f.quot_midden, b.be_volgnummer
                from   fn_quotes_vw f
                inner join beleggingsinstrument b on
                b.be_symbool = f.quot_symbool
                and b.be_optietype = f.quot_optietype
                and b.be_expiratiedatum = f.quot_expiratiedatum
                and b.be_exerciseprijs = f.quot_exerciseprijs

                and (b.be_volgnummer in    (select distinct A.AP_BE_VOLGNUMMER
                                          from aktuele_posities a
                                          where (a.AP_SALDO_POSITIE <> 0 or A.AP_TRANSDATUM >= '||gv_start_date_quotes_char||')
                                         and  a.ap_rekening_soort between 100 and 999
                                          AND  a.AP_BE_VOLGNUMMER IS NOT NULL
                                          and   A.AP_EXPIRATIEDATUM NOT BETWEEN ''00000001'' AND '||gv_start_date_quotes_prev_char||')
                     and f.quot_soort =  ''SLOT'')
                )
             where quot_next_date >=  '||gv_start_date_quotes_char||'
          ) q
          -- notice 10 is used to keep quotes of expired options foor 10 extra days.
          where d.calc_date between to_date(q.quot_datum, ''YYYYMMDD'') and to_date(q.quot_next_date, ''YYYYMMDD'') and  (q.quot_optietype not in (''CALL'',''PUT'', ''FUT'') or to_char(d.calc_date-10,''YYYYMMDD'') <= q.quot_expiratiedatum)'
          ;

    execute immediate 'ALTER TABLE '||gv_table_name_new||' NOPARALLEL';

    INSERT_FIXI_QUOTES;

  end;
  procedure INSERT_FIXI_QUOTES
    is
    v_stmt varchar2(4000);
  begin
    v_stmt := 'insert /*+parallel '||gv_nmbr_of_parallel_processes||' (q) */
    into '||gv_table_name_new||' q (be_id, quote_date, quote)
      (select q.be_volgnummer, d.calc_date, q.quot_midden
         from (select to_date(''20000101'', ''YYYYMMDD'') + (level - 1) as calc_date
                 from dual
                  -- en dan beperken tot de gewenste periode
          where to_date(''20000101'', ''YYYYMMDD'') + (level - 1) between
            to_date('||gv_start_date_quotes_char||', ''YYYYMMDD'') and sysdate
                  -- 300*366 dagen sinds 01/01/2000 ofwel iets meer dan 300 jaar.
                  connect by level <= (300*366)) d,
              (select /*+parallel '||gv_nmbr_of_parallel_processes||'*/
                *
                 from (select /*+parallel '||gv_nmbr_of_parallel_processes||' (fn_quotes_vw, beleggingsinstrument) */
                        f.quot_datum,
                        lead(to_char(to_date(f.quot_datum, ''YYYYMMDD'') - 1,
                                     ''YYYYMMDD''),
                             1,
                             ''99991231'') over(partition by b.be_volgnummer order by b.be_volgnummer, f.quot_soort, f.quot_datum, f.quot_tijd) as quot_next_date,
                        f.quot_midden,
                        b.be_volgnummer
                         from fn_quotes_vw f
                        inner join beleggingsinstrument b
                           on b.be_symbool = f.quot_symbool
                          and b.be_optietype = f.quot_optietype
                          and b.be_expiratiedatum = f.quot_expiratiedatum
                          and b.be_exerciseprijs = f.quot_exerciseprijs
                          and f.quot_soort = ''FIXI''
                          and f.quot_datum <> ''00000000'')
                where quot_next_date >=  '||gv_start_date_quotes_char||') q
        where d.calc_date between to_date(q.quot_datum, ''YYYYMMDD'') and
              to_date(q.quot_next_date, ''YYYYMMDD''))';
    execute immediate v_stmt;
  end;
  PROCEDURE INSERT_CLOSE_QUOTES is
  begin
    execute immediate 'insert /*+parallel '||gv_nmbr_of_parallel_processes||' (q)*/
    into '||gv_table_name_new||' q
      (be_id, quote_date, quote)
      (select q.be_volgnummer, d.calc_date, q.quot_midden
         from (select to_date(''20000101'', ''YYYYMMDD'') + (level - 1) as calc_date
                 from dual
                  -- en dan beperken tot de gewenste periode
          where to_date(''20000101'', ''YYYYMMDD'') + (level - 1) between
            to_date('||gv_start_date_quotes_char||', ''YYYYMMDD'') and sysdate
                  -- 300*366 dagen sinds 01/01/2000 ofwel iets meer dan 300 jaar.
                  connect by level <= (300*366)) d,
               (select *
                  from (select f.quot_datum,
                               lead(to_char(to_date(f.quot_datum, ''YYYYMMDD'') - 1,
                                            ''YYYYMMDD''),
                                    1,
                                    ''99991231'') over(partition by b.be_volgnummer order by b.be_volgnummer, f.quot_soort, f.quot_datum, f.quot_tijd) as quot_next_date,
                               f.quot_midden,
                               b.be_volgnummer
                          from fn_quotes_vw f
                         inner join beleggingsinstrument b
                            on b.be_symbool = f.quot_symbool
                           and b.be_optietype = f.quot_optietype
                           and b.be_expiratiedatum = f.quot_expiratiedatum
                           and b.be_exerciseprijs = f.quot_exerciseprijs

                           and (b.be_volgnummer in
                               (select distinct A.AP_BE_VOLGNUMMER
                                   from aktuele_posities a
                                  where (a.AP_SALDO_POSITIE <> 0 or
                                        A.AP_TRANSDATUM >= gv_start_date_quotes_char)
                                    and a.ap_rekening_soort between 100 and 999
                                    AND a.AP_BE_VOLGNUMMER IS NOT NULL
                                    and A.AP_EXPIRATIEDATUM NOT BETWEEN
                                        ''00000001'' AND gv_start_date_quotes_prev_char) and
                               f.quot_soort = ''SLOT''))
                 where quot_next_date >=  '||gv_start_date_quotes_char||') q
        where d.calc_date between to_date(q.quot_datum, ''YYYYMMDD'') and
              to_date(q.quot_next_date, ''YYYYMMDD''))';
  end;

procedure set_single_indirect_cost(p_instrument_id number)

is
  v_variant char;
begin
  v_variant := GET_TABLENAME_VARIANT('C');
  --Switch the variant. we want to update the existing table.
  if v_variant = 'A' then
    v_variant := 'B';
  else
    v_variant := 'A';
  end if;

  reload_indirect_costs (v_variant, p_instrument_id);
end;

procedure reload_indirect_costs (p_variant char, p_instrument_id number)
          is
begin

    declare
        v_table_name_icf_new all_tables.table_name%type;
        e_error exception;
           pragma exception_init (e_error, -1840);

    begin
        v_table_name_icf_new:= 'PC_IC_PER_INSTRUMENT_'||p_variant;

        if nvl(p_instrument_id,0)<>0 then
        begin
              execute immediate 'delete from '|| v_table_name_icf_new ||' where be_id = '||to_char(p_instrument_id);
        end;
        else
            execute immediate 'truncate table '|| v_table_name_icf_new;
        end if;
        dbms_output.put_line('instrument_id '|| to_char(nvl(p_instrument_id,-1)));

        execute immediate 'insert into ' || v_table_name_icf_new || '
        select icf_be_id be_id
        ,      icf_date_since date_since
        ,      icf_date_till date_till
        ,      listagg (rule_id, '';'') within group (order by rule_id) || '';'' type_list
        ,      listagg (nvl(icf_amount, 0), '';'') within group (order by rule_id) || '';'' amount_list
        ,      listagg (nvl(icf_percentage, 0), '';'') within group (order by rule_id) || '';'' percentage_list
        from (
               select rsd.icf_be_id, q3.rule_id, q3.icf_ex_ante_ex_post_ind, rsd.icf_date_since, rsd.icf_date_till, q3.icf_amount, q3.icf_percentage
               from
                    (select icf_be_id,
                            icf_date_since,
                            nvl(lead(icf_date_since-1) over ( partition by icf_be_id order by icf_date_since), to_date(''29991231'', ''YYYYMMDD'')) as icf_date_till
                    from (
                          select distinct ic.icf_be_id, icf_date_since
                          from   INDIRECT_COSTS_PER_FUND_VW ic
                          where  ic.icf_cfcu_id IN (SELECT cfcu_id from deduction_definition  d inner join calculationrules r ON r.cfcu_dedu_id = d.id where do_persist = 1)
                         )
                    ) rsd,
                    (select ic.icf_id,
                            ic.icf_be_id,
                            c.id rule_id,
                            ic.icf_date_since,
                            NVL (
                                 LEAD (ic.icf_date_since)
                                     OVER (
                                           PARTITION BY ic.icf_be_id, ic.icf_cfcu_id
                                           ORDER BY     ic.icf_be_id, ic.icf_cfcu_id, ic.icf_date_since
                                          )
                                 - 1,
                                 TO_DATE (''29991231'', ''YYYYMMDD'')
                               ) AS icf_date_next,
                            ic.icf_date_till,
                            ic.icf_amount,
                            ic.icf_currency,
                            ic.icf_percentage,
                            ic.icf_ex_ante_ex_post_ind
                     from   indirect_costs_per_fund_vw ic
                     inner join calculationrules r on r.cfcu_id = ic.icf_cfcu_id
                     inner join deduction_definition d on d.id = r.cfcu_dedu_id
                     inner join map_calcrule_perf_cat m on m.cfcu_id = ic.icf_cfcu_id
                     inner join pc_category c on c.code = m.pcc_cat
                     where d.do_persist = 1
                    ) q3
               where  q3.icf_be_id = rsd.icf_be_id
               and 	  q3.icf_date_next >= rsd.icf_date_till
               and    q3.icf_date_since <= rsd.icf_date_since
        ) l
        where l.icf_be_id = ' || to_char(nvl(p_instrument_id, -1)) || ' or ' || to_char(nvl(p_instrument_id, -1)) || ' = -1
        group by l.icf_be_id, l.ICF_DATE_SINCE, l.ICF_DATE_TILL';

    exception
        when e_error then
          dbms_output.put_line('reload_indirect_costs, variant : ' || p_variant || ' , instrument : ' || p_instrument_id);
     end;

     commit;
end;


function GET_TABLENAME_VARIANT (p_type char) return char
  is
    v_current_table all_tables.table_name%type;
    v_count_a number;
    v_count_b number;
begin
  if p_type = 'Q' then
    select REFERENCED_NAME into v_current_table from user_dependencies where name  = 'PC_QUOTE_PER_DAY_VW' and REFERENCED_NAME  <> 'PC_QUOTE_PER_DAY_HIST';
    if v_current_table = 'PC_QUOTE_PER_DAY_A' then
      return 'A';
    else
      return 'B';
    end if;
  else
    select count(*) into v_count_a from PC_IC_PER_INSTRUMENT_A;
    select count(*) into v_count_b from PC_IC_PER_INSTRUMENT_B;
    if v_count_a>0 then
      return 'B';
    else
      return 'A';
    end if;
  end if;
    exception
      when no_data_found then
        return 'X';
end;

procedure set_single_quote(p_instrument_id number, p_date char, p_date_till char)
  is
  v_new_quote number (15,6);
  v_sql_stmt varchar2(4000);

  begin
    get_object_names_quotes;
    select q.quot_midden
    into v_new_quote
    from fn_quotes_vw q
    inner join beleggingsinstrument bi on
    bi.be_symbool = q.quot_symbool
    and bi.be_optietype = q.quot_optietype
    and bi.be_expiratiedatum = q.quot_expiratiedatum
    and bi.be_exerciseprijs = q.quot_exerciseprijs
    and q.quot_datum = p_date
    and q.quot_soort = decode(bi.be_bi_nummer, 4000, 'FIXI','SLOT')
    and bi.be_volgnummer = p_instrument_id;
    v_sql_stmt := 'update '||gv_table_name_old||' set quote='||to_char(v_new_quote,'999999999.999999')||
                  ' where be_id = '||to_char(p_instrument_id)||
                  ' and quote_date between to_date('||p_date||',''YYYYMMDD'') and
                    to_date('||p_date_till||',''YYYYMMDD'')';
    execute immediate v_sql_stmt;
    exception
      when NO_DATA_FOUND then
        dbms_output.put_line('No data found');
    commit;
  end;

procedure get_object_names_quotes
is
    v_variant_q char;

begin
    v_variant_q := GET_TABLENAME_VARIANT('Q');

    if get_type_of_action() = 1 then
    begin
      if v_variant_q = 'A' then
        gv_table_name_new := 'PC_QUOTE_PER_DAY_B';
        gv_table_name_old := 'PC_QUOTE_PER_DAY_A';
        gv_index_name := 'PQPDB_UK01';
      elsif v_variant_q = 'B' then
        gv_table_name_new := 'PC_QUOTE_PER_DAY_A';
        gv_table_name_old := 'PC_QUOTE_PER_DAY_B';
        gv_index_name := 'PQPDA_UK01';
      else
        gv_table_name_new := 'PC_QUOTE_PER_DAY_A';
        gv_table_name_old := 'PC_QUOTE_PER_DAY';
        gv_index_name := 'PQPDA_UK01';
      end if;

      end;
    else
      if v_variant_q = 'X' then
        gv_table_name_new := 'PC_QUOTE_PER_DAY';
        gv_index_name := 'PQPD_UK01';
      else
        gv_table_name_new := 'PC_QUOTE_PER_DAY_'||v_variant_q;
        gv_index_name := 'PQPD'||v_variant_q||'_UK01';
      end if;
   end if;

end;

procedure HISTORIZE_DAY_QUOTES(p_date_till char)
is
    v_date_last_hist date;
    v_date_last_hist_str varchar2(8);
    v_current_table all_tables.table_name%type;
    v_statement varchar2(2000);
begin
    select REFERENCED_NAME into v_current_table from user_dependencies where name  = 'PC_QUOTE_PER_DAY_VW' and REFERENCED_NAME  <> 'PC_QUOTE_PER_DAY_HIST';
    select trim(to_char(nvl(tb_waarde, 1)))
      into gv_nmbr_of_parallel_processes
      from tabelgegevens t
     where t.tb_soort = 'ICCA'
       and t.tb_symbool = 'PROC';
    select nvl(max(quote_date),to_date('1970-01-01','YYYY-MM-DD'))+1 into v_date_last_hist from pc_quote_per_day_hist;
    execute immediate ('alter session enable parallel dml');
    v_date_last_hist_str := to_char(v_date_last_hist,'YYYYMMDD');
        v_statement := 'insert /*+parallel '||gv_nmbr_of_parallel_processes||' (q)*/
    into pc_quote_per_day_hist q
      (be_id, quote_date, quote) (select be_id, quote_date, quote from '||v_current_table||' where quote_date between to_date('||v_date_last_hist_str||',''YYYYMMDD'') AND to_date('||p_date_till||',''YYYYMMDD'')) ';
    execute immediate v_statement;

    update tabelgegevens t
        set tb_datum = to_char(to_date(p_date_till,'YYYYMMDD')+1,'YYYYMMDD')
        where t.tb_soort = 'ICCA'
        and t.tb_symbool = 'STRT';
    commit;
    execute immediate ('alter session disable parallel dml');
end;

PROCEDURE SET_CALCULATION_STORAGE_TYPE(p_type char)
is
begin      
  dbms_output.put_line('Type:'|| p_type);
  if upper(p_type) != 'MAGIC' and upper(p_type)!= 'IGNITE' then
     raise_application_error(-20000, 'Invalid type');
  else
    if upper(p_type) = GET_CALCULATION_STORAGE_TYPE  then
        dbms_output.put_line('Nothing to do in SET_CALCULATION_STORAGE_TYPE');
        --null;
    else 
        dbms_output.put_line('Type:'|| p_type);
        if upper(p_type) ='IGNITE' then
            dbms_output.put_line('SET_CALCULATION_STORAGE_TYPE start replacing views on ignite_tables');
            execute immediate 'create or replace view PC_PORTFOLIO_AMOUNT_VW as select * from PC_PORTFOLIO_AMOUNT_IGNITE';
            execute immediate 'create or replace view PC_PORTFOLIO_BASE_VW as select * from PC_PORTFOLIO_BASE_IGNITE';  
            dbms_output.put_line('SET_CALCULATION_STORAGE_TYPE finished replacing views on ignite_tables');
        else
            dbms_output.put_line('SET_CALCULATION_STORAGE_TYPE start replacing views on original_tables');
            execute immediate 'create or replace view PC_PORTFOLIO_AMOUNT_VW as select * from PC_PORTFOLIO_AMOUNT';
            execute immediate 'create or replace view PC_PORTFOLIO_BASE_VW as select * from PC_PORTFOLIO_BASE';
            dbms_output.put_line('SET_CALCULATION_STORAGE_TYPE finished replacing views on original_tables');
        end if;
    end if;
  end if;  
  exception
        when others then
        begin
            dbms_output.put_line('Error in SET_CALCULATION_STORAGE_TYPE');
            raise_application_error(-20000,'Error creating the view');
        end;
  commit;
end;

FUNCTION GET_CALCULATION_STORAGE_TYPE return varchar2
  is
   v_type varchar2(8);
   v_current_amount_table all_tables.table_name%type;
   v_current_base_table all_tables.table_name%type;
begin
      select REFERENCED_NAME into v_current_amount_table from user_dependencies where name  = 'PC_PORTFOLIO_AMOUNT_VW';
      select REFERENCED_NAME into v_current_base_table from user_dependencies where name  = 'PC_PORTFOLIO_BASE_VW';
      if (v_current_amount_table = 'PC_PORTFOLIO_AMOUNT' and v_current_base_table = 'PC_PORTFOLIO_BASE')
      then return 'MAGIC';
      elsif (v_current_amount_table = 'PC_PORTFOLIO_AMOUNT_IGNITE' and v_current_base_table = 'PC_PORTFOLIO_BASE_IGNITE')
      then  return 'IGNITE';
      else
        return 'ERROR';
      end if;
end;

end PC_SET_DAY_QUOTES;
/

