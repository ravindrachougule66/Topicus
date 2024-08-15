CREATE OR REPLACE PACKAGE EPPLUS_UTILITIES
IS
  --
  -- Procedure: TruncateTable
  PROCEDURE TruncateTable(p_table_name IN VARCHAR2);
  --
  -- Procedure: ChildRecordFoundIn
  --
  PROCEDURE ChildRecordFoundIn(pi_table_name IN VARCHAR2,
                               pi_id         IN NUMBER,
                               pi_type       IN VARCHAR2,
                               po_table_list OUT VARCHAR2);
  --
  -- Function: Version
  FUNCTION Version RETURN VARCHAR2;
  -- Returns version# from this package.
  PRAGMA RESTRICT_REFERENCES(Version, WNDS, WNPS, RNDS);
  --
  -- GET_PARAMETER_VALUE
  --
  FUNCTION get_parameter_value (p_parameter in varchar2) RETURN VARCHAR2;
  --
  -- DB_VERSION
  --
  FUNCTION db_version RETURN VARCHAR2;
  --
  -- DB_COMPATIBILITY
  --
  FUNCTION db_compatibility RETURN VARCHAR2;
  --
  gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';
  --
END EPPLUS_UTILITIES;
/
CREATE OR REPLACE PACKAGE BODY EPPLUS_UTILITIES
IS
  --
  -- Procedure: TruncateTable
  PROCEDURE TruncateTable(p_table_name IN VARCHAR2) IS
    V_SQL_STMT VARCHAR2(80);
    V_SQL_ERR  NUMBER;
  BEGIN

    BEGIN
      V_SQL_STMT := 'TRUNCATE TABLE ' || p_table_name;
      EXECUTE IMMEDIATE V_SQL_STMT;
    EXCEPTION  -- If exception is raised, display an error message.
    WHEN OTHERS THEN
       V_SQL_ERR := SQLCODE;
       IF V_SQL_ERR =  -54 THEN
         RAISE_APPLICATION_ERROR (-20054,'Error while trying to truncate table '|| p_table_name || ' ; resource busy');
       ELSE
         RAISE;
       END IF;
    END;
  END TruncateTable;
  --
  -- Procedure: ChildRecordFoundIn
  PROCEDURE ChildRecordFoundIn(pi_table_name IN VARCHAR2,
                               pi_id         IN NUMBER,
                               pi_type       IN VARCHAR2,    
                               po_table_list OUT VARCHAR2) IS

  CURSOR childtable IS
    SELECT r.table_name, c.column_name
      FROM user_constraints t, user_constraints r, user_cons_columns c
     WHERE t.table_name = pi_table_name
       AND t.constraint_type = pi_type
       AND r.r_constraint_name = t.constraint_name
       AND r.constraint_name = c.constraint_name
       AND r.delete_rule = 'NO ACTION';
  childrecord   number := 0;
  t_table_name  user_constraints.table_name%TYPE;
  t_column_name user_cons_columns.column_name%TYPE;
BEGIN
  
  OPEN childtable;
  LOOP
    FETCH childtable
      into t_table_name, t_column_name;
    EXIT WHEN childtable%NOTFOUND;
    childrecord := 0;
    BEGIN
      EXECUTE IMMEDIATE 'SELECT 1  FROM ' || t_table_name ||
                        ' WHERE rownum = 1 AND ' || t_column_name || ' = ' ||
                        pi_id
        INTO childrecord;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        childrecord := 0;
    END;
  
    IF (childrecord > 0) THEN
      IF po_table_list <> ' ' THEN
        po_table_list := po_table_list || ',';
      END IF;
      po_table_list := po_table_list || t_table_name;
    END IF;
  END LOOP;
  CLOSE childtable;
END ChildRecordFoundIn;
  --
  -- Function: Version
  FUNCTION Version RETURN VARCHAR2 IS
  BEGIN
    RETURN gv_versie;
  END Version;
--
-- DB_VERSION
--
  FUNCTION db_version RETURN VARCHAR2 IS
  l_version varchar2(10);
  l_compatibility varchar2(10);
  BEGIN
    DBMS_UTILITY.DB_VERSION(l_version,l_compatibility);
    RETURN l_version;
  END;
--
-- DB_COMPATIBILITY
--
  FUNCTION db_compatibility RETURN VARCHAR2 IS
  l_version varchar2(10);
  l_compatibility varchar2(10);
  BEGIN
    DBMS_UTILITY.DB_VERSION(l_version,l_compatibility);
    RETURN l_compatibility;
  END;
--
-- GET_PARAMETER_VALUE
--
  FUNCTION get_parameter_value (p_parameter in varchar2) RETURN VARCHAR2 IS
  l_value varchar2(256);
  l_intval number;
  l_stringval varchar2(256);
  BEGIN
    l_value := 'NOT SUPPORTED PARAMETER';
    BEGIN
    if ( dbms_utility.get_parameter_value( p_parameter,l_intval,l_stringval ) = 1 )
    then
       l_value := l_stringval;
    else
       l_value := to_char(l_intval);
    end if;
    EXCEPTION
      when others then raise_application_error(-20000,l_value);
    END;
    RETURN l_value;
  END;

END EPPLUS_UTILITIES;
/
