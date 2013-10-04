
-------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE is_object(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    object_name ALIAS FOR $1;

    check_object INT2;
  BEGIN

    SELECT COUNT(objid) INTO check_object
    FROM _T_OBJECT
    WHERE objname = object_name AND
    objdb = (
      SELECT objid
      FROM _T_OBJECT
      WHERE objname = CURRENT_CATALOG
    );

    IF 1 = check_object THEN
      RETURN TRUE;
    END IF;

    RETURN FALSE;
  END;
END_PROC;

-------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE class_of(VARCHAR(100))
  RETURNS VARCHAR(100)
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    object_name ALIAS FOR $1;

    class_name VARCHAR(100);
  BEGIN

    SELECT objname INTO class_name
    FROM _T_OBJECT
    WHERE objid = (
      SELECT objclass
      FROM _T_OBJECT
      WHERE objname = object_name
      AND objdb = (
        SELECT objid
        FROM _T_OBJECT
        WHERE objname = CURRENT_CATALOG
      )
    );

    RETURN class_name;
  END;
END_PROC;

-------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE class_of(VARCHAR(100), VARCHAR(100))
  RETURNS VARCHAR(100)
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    catalog     ALIAS FOR $1;

    object_name ALIAS FOR $2;

    class_name VARCHAR(100);
  BEGIN

    SELECT objname INTO class_name
    FROM _T_OBJECT
    WHERE objid = (
      SELECT objclass
      FROM _T_OBJECT
      WHERE objname = object_name
      AND objdb = (
        SELECT objid
        FROM _T_OBJECT
        WHERE objname = catalog
      )
    );

    RETURN class_name;
  END;
END_PROC;

-------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE is_table(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    object_name ALIAS FOR $1;

    class_name VARCHAR(100);
  BEGIN
    SELECT INTO class_name util..class_of(object_name);

    IF 'TABLE' = class_name THEN
      RETURN TRUE;
    END IF;

    RETURN FALSE;
  END;
END_PROC;

-------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE is_view(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    object_name ALIAS FOR $1;

    class_name VARCHAR(100);
  BEGIN
    SELECT INTO class_name util..class_of(object_name);

    IF 'VIEW' = class_name THEN
      RETURN TRUE;
    END IF;

    RETURN FALSE;
  END;
END_PROC;

-------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE is_sequence(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    object_name ALIAS FOR $1;

    class_name VARCHAR(100);
  BEGIN
    SELECT INTO class_name util..class_of(object_name);

    IF 'SEQUENCE' = class_name THEN
      RETURN TRUE;
    END IF;

    RETURN FALSE;
  END;
END_PROC;

-------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE is_group(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    object_name ALIAS FOR $1;

    class_name VARCHAR(100);
  BEGIN
    SELECT INTO class_name util..class_of('GLOBAL', object_name);

    IF 'GROUP' = class_name THEN
      RETURN TRUE;
    END IF;

    RETURN FALSE;
  END;
END_PROC;

-------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE is_user(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    object_name ALIAS FOR $1;

    class_name VARCHAR(100);
  BEGIN
    SELECT INTO class_name util..class_of('GLOBAL', object_name);

    IF 'USER' = class_name THEN
      RETURN TRUE;
    END IF;

    RETURN FALSE;
  END;
END_PROC;

-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------

DROP PROCEDURE users_of_group(VARCHAR(100));

DROP TABLE tmp_users_of_group;

CREATE TABLE tmp_users_of_group (
  username VARCHAR(100)
);

CREATE PROCEDURE users_of_group(VARCHAR(100))
  RETURNS REFTABLE(tmp_users_of_group)
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    group_name ALIAS FOR $1;
  BEGIN
    RETURN REFTABLE;
  END;
END_PROC;

-------------------------------------------------------------------------------

