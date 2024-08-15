CREATE OR REPLACE PACKAGE EPPLUS_APPLICATION_INFO
IS
  --
  -- Procedure: SetModule
  PROCEDURE SetModule(p_module IN VARCHAR2);
  --
  -- Procedure: SetAction
  PROCEDURE SetAction(p_action IN VARCHAR2);
  --
  -- Procedure: GetModule
  PROCEDURE GetModule(p_module OUT VARCHAR2,p_action OUT VARCHAR2);
  --
  -- Procedure: SetUserInfo
  PROCEDURE SetUserInfo(p_user IN VARCHAR2);
  --
  -- Procedure: GetUserInfo
  PROCEDURE GetUserInfo(p_user OUT VARCHAR2);
  --
  -- Procedure: GetPCName
  PROCEDURE GetPCName(pc_name OUT VARCHAR2);
  --
  -- Function: Version
  FUNCTION Version RETURN VARCHAR2;
  -- Returns version# from this package.
  pragma restrict_references(Version, WNDS, WNPS, RNDS);
  --
  gv_err_num           NUMBER;
  -- variabele die het laatste versienummer bevat:
  gv_versie constant varchar2(80) default 'VERSIE-CHANGESET';
  
  --
  -- LOG-history  Date        Author  Changes
  -- 04.00        21-11-2001   LTA    Initial version
  -- 04.04        01-05-2003   LTA    Added procedure GetModule
  -- 04.04        02-05-2003   LTA    Added procedure SetAction
  -- 04.05.02     25-08-2003   LTA    Added gv_err_num filled in every exception from SQLCODE
  --                                  and added usage of lv_buffer in procedure GetUserInfo
  -- 04.05.02     26-08-2003   LTA    Added usage of RTRIM to procedure GetUserInfo
  -- 04.07.00     14-01-2004   LTA    Changed procedure SetUserInfo : only execute procedure
  --                                  SetUserInfo if the input parameter is not null.
  -- 04.09.00     04-08-2004   LTA    Removed procedure SetClientInfo.
  --                                  Added procedure GetPCName.
  -- 05.10.00     11-11-2009   LTA    Enlarged the size for the username within client_info
  --                                  from 10 to 30 positions.
  -- 08.nn.00     23-09-2020   WK     Package no longer a SYS-package
END EPPLUS_APPLICATION_INFO;
/
CREATE OR REPLACE PACKAGE BODY EPPLUS_APPLICATION_INFO
IS
  --
  -- Procedure: SetModule
  PROCEDURE SetModule(p_module IN VARCHAR2) IS
  BEGIN
      DBMS_APPLICATION_INFO.SET_MODULE(p_module,'');
  EXCEPTION
      WHEN OTHERS THEN
           gv_err_num := SQLCODE;
           RAISE_APPLICATION_ERROR (-20001,'PROC: SetModule '||gv_err_num);
  END SetModule;
  --
  -- Procedure: SetAction
  PROCEDURE SetAction(p_action IN VARCHAR2) IS
  BEGIN
      DBMS_APPLICATION_INFO.SET_ACTION(p_action);
  EXCEPTION
      WHEN OTHERS THEN
           gv_err_num := SQLCODE;
           RAISE_APPLICATION_ERROR (-20001,'PROC: SetAction '||gv_err_num);
  END SetAction;
  --
  -- Procedure: GetModule
  PROCEDURE GetModule(p_module OUT VARCHAR2,p_action OUT VARCHAR2) IS
  BEGIN
      DBMS_APPLICATION_INFO.READ_MODULE(p_module,p_action);
  EXCEPTION
      WHEN OTHERS THEN
           gv_err_num := SQLCODE;
           RAISE_APPLICATION_ERROR (-20001,'PROC: GetModule '||gv_err_num);
  END GetModule;
  --
  -- Procedure: SetUserInfo
  PROCEDURE SetUserInfo(p_user IN VARCHAR2) IS
  BEGIN
    IF p_user IS NOT NULL
    THEN
      DBMS_APPLICATION_INFO.SET_CLIENT_INFO(p_user);
    END IF;
  EXCEPTION
      WHEN OTHERS THEN
           gv_err_num := SQLCODE;
           RAISE_APPLICATION_ERROR (-20001,'PROC: SetUserInfo '||gv_err_num);
  END SetUserInfo;
  --
  -- Procedure: GetUserInfo
  PROCEDURE GetUserInfo(p_user OUT VARCHAR2) IS
      lv_buffer   CHAR(64);
  BEGIN
      DBMS_APPLICATION_INFO.READ_CLIENT_INFO(lv_buffer);
      p_user := RTRIM(SUBSTR(lv_buffer,1,30));
  EXCEPTION
      WHEN OTHERS THEN
           gv_err_num := SQLCODE;
           RAISE_APPLICATION_ERROR (-20001,'PROC: GetUserInfo '||gv_err_num);
  END GetUserInfo;
  --
  -- Procedure: GetPCName
  PROCEDURE GetPCName(pc_name OUT VARCHAR2) IS
      lv_buffer   CHAR(64);
  BEGIN
      DBMS_APPLICATION_INFO.READ_CLIENT_INFO(lv_buffer);
      pc_name := RTRIM(SUBSTR(lv_buffer,35,32));
  EXCEPTION
      WHEN OTHERS THEN
           gv_err_num := SQLCODE;
           RAISE_APPLICATION_ERROR (-20001,'PROC: GetPCName '||gv_err_num);
  END GetPCName;
  --
  -- Function: Version
  FUNCTION Version RETURN VARCHAR2 IS
  BEGIN
      RETURN gv_versie;
  END version;
END EPPLUS_APPLICATION_INFO;
/
