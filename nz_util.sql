
DROP DATABASE UTIL;
CREATE DATABASE UTIL;

CREATE OR REPLACE PROCEDURE grant_object_privilege(VARCHAR(100), VARCHAR(1000), VARCHAR(1000))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    group_name            ALIAS FOR $1;

    object_privilege_list ALIAS FOR $2;

    object_list           ALIAS FOR $3;
  BEGIN
    EXECUTE IMMEDIATE 'GRANT '
    || object_privilege_list
    || ' ON ' || object_list
    || ' TO ' || group_name;

    RETURN TRUE;
  END;
END_PROC;

-------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE grant_admin_privilege(VARCHAR(100), VARCHAR(1000))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    group_name           ALIAS FOR $1;

    admin_privilege_list ALIAS FOR $2;
  BEGIN
    EXECUTE IMMEDIATE 'GRANT '
    || admin_privilege_list
    || ' TO ' || group_name;

    RETURN TRUE;
  END;
END_PROC;

-------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE create_group(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    catalog NAME := CURRENT_CATALOG;
    group_name            ALIAS FOR $1;
  BEGIN
    -- Avoid creating groups in reserved catalogs
    IF 'SYSTEM' = catalog THEN
      RAISE EXCEPTION 'Reserved catalog: %', catalog;
    END IF;

    EXECUTE IMMEDIATE 'CREATE GROUP ' || group_name;

    RETURN TRUE;
  END;
END_PROC;

-------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE create_group_readonly(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    group_name ALIAS FOR $1;

    object_privilege_list VARCHAR(1000) := ' LIST, SELECT ';

    object_list           VARCHAR(1000) := ' TABLE, VIEW, SEQUENCE ';
  BEGIN
    CALL util..create_group(group_name);

    CALL util..grant_object_privilege(group_name, object_privilege_list, object_list);

    RETURN TRUE;
  END;
END_PROC;

-------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE create_group_readwrite(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    group_name ALIAS FOR $1;

    object_privilege_list VARCHAR(1000) := ' LIST, SELECT, INSERT, UPDATE, DELETE, TRUNCATE, LOCK, ALTER, DROP, ABORT, LOAD, GENSTATS, GROOM ';

    object_list           VARCHAR(1000) := ' TABLE, VIEW, SEQUENCE ';

    admin_privilege_list  VARCHAR(1000) := ' CREATE TABLE, CREATE SEQUENCE, CREATE VIEW, CREATE EXTERNAL TABLE ';
  BEGIN
    CALL util..create_group(group_name);

    CALL util..grant_object_privilege(group_name, object_privilege_list, object_list);

    CALL util..grant_admin_privilege(group_name, admin_privilege_list);

    RETURN TRUE;
  END;
END_PROC;

-------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE create_group_execute(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    group_name ALIAS FOR $1;

    object_privilege_list VARCHAR(1000) := ' LIST, SELECT, UPDATE, DROP, EXECUTE ';

    object_list           VARCHAR(1000) := ' FUNCTION, PROCEDURE ';

    admin_privilege_list  VARCHAR(1000) := ' CREATE FUNCTION, CREATE PROCEDURE ';
  BEGIN
    CALL util..create_group(group_name);

    CALL util..grant_object_privilege(group_name, object_privilege_list, object_list);

    CALL util..grant_admin_privilege(group_name, admin_privilege_list);

    RETURN TRUE;
  END;
END_PROC;

