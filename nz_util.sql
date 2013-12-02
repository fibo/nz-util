--nz-util
--=======
--
--> Netezza utility functions
--

/* Update version number */
COMMENT ON DATABASE util
--**Version 2013-12-02**
IS 'Version 2013-12-02, http://www.g14n.info/nz-util/, MIT License';

--# Installation
--
--## Download the code
--
--If you are on a Linux box (for example the Netezza frontend itself), you can try with this command
--
--```bash
--wget --no-check-certificate --timestamping https://raw.github.com/fibo/nz-util/master/nz_util.sql
--```
--
--## Install
--
--```bash
--nzsql -u admin -d system -c 'CREATE DATABASE util COLLECT HISTORY OFF'
--nzsql -u admin -d util -f nz_util.sql
--```
--
--## Update
--
--Check current version
--
--```bash
--nzsql -u admin -d util -c '\dd util'
--```
--
--Update *Netezza utilities*.
--
--```bash
--nzsql -u admin -d util -f nz_util.sql
--```

--
--# Utilities
--

--
--## Type checking
--


/* this procedures is private by now */

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

--
--## class_of
--
--Return the object class.
--
--```sql
--CALL util..class_of('FOO');
--```
--

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
--* *object_name* is not case sensitive
      WHERE objname = UPPER(object_name)
      AND objdb = (
        SELECT objid
        FROM _T_OBJECT
        WHERE objname = CURRENT_CATALOG
      )
    );

    RETURN class_name;
  END;
END_PROC;

/* available classes

select objname from _T_OBJECT
where objid in (
select distinct objclass from _T_OBJECT
)

VIRGILIO_DEV_SK(ADMIN)-> \g
     OBJNAME
------------------
 GLOBAL
 DATABASE
 GROUP
 USER
 TABLE
 VIEW
 RELATION
 BASE VIEW
 LIBRARY
 VERSIONED TABLE
 BASE TABLE SET
 TABLE VERSION
 SEQUENCE
 EXTERNAL TABLE
 SYNONYM
 PROCEDURE
 AGGREGATE
 FUNCTION
 SYSTEM TABLE
 SYSTEM VIEW
 SYSTEM INDEX
 SYSTEM SEQ
 DATATYPE
 VIRTUAL TABLE
 MANAGEMENT TABLE
 MANAGEMENT VIEW
 MANAGEMENT INDEX
 MANAGEMENT SEQ
(28 rows)

*/

/* this procedures is private by now */

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
      --* *object_name* is not case sensitive
      WHERE objname = UPPER(object_name)
      AND objdb = (
        SELECT objid
        FROM _T_OBJECT
        WHERE objname = catalog
      )
    );

    RETURN class_name;
  END;
END_PROC;

/* this procedures is private by now */

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

/* this procedures is private by now */

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

/* this procedures is private by now */

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

/* this procedures is private by now */

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

/* this procedures is private by now */

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

--
--## Groups and grants management
--

/* grant_object_privilege is private */

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

/* grant_admin_privilege is private */

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

--
--### create_or_update_group
--
--Create a group safely. If group already exists, it will be granted to list current catalog.
--Please note that since Netezza grants permissions contextually to current catalog,
--you need to connect manually to catalog.
--
--```sql
--\c mydatabase
--CALL util..create_or_update_group('GROUP_NAME');
--```
--

CREATE OR REPLACE PROCEDURE create_or_update_group(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    catalog NAME := CURRENT_CATALOG;

    group_name ALIAS FOR $1;

    group_exists BOOLEAN;
  BEGIN
--* avoids creating groups in reserved catalogs
    IF 'SYSTEM' = catalog THEN
      RAISE EXCEPTION '% is a reserved catalog', catalog;
    END IF;

--* checks if group already exists
    group_exists := util..is_group(group_name);

    IF group_exists THEN
      EXECUTE IMMEDIATE 'GRANT LIST ON ' || catalog || ' TO ' || group_name;
    ELSE
      EXECUTE IMMEDIATE 'CREATE GROUP ' || group_name;
      EXECUTE IMMEDIATE 'GRANT LIST ON ' || catalog || ' TO ' || group_name;
    END IF;


    RETURN TRUE;
  END;
END_PROC;

--
--### grant_readonly
--
--Grant a group to read data in current catalog.
--
--```sql
--\c mydatabase
--CALL util..grant_readonly('GROUP_NAME');
--```
--

CREATE OR REPLACE PROCEDURE grant_readonly(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    group_name ALIAS FOR $1;
  BEGIN
--* creates group if it does not exists
    CALL util..create_or_update_group(group_name);

--* grants *list, select* object privileges on *table, view, sequence*
    CALL util..grant_object_privilege(group_name, ' LIST, SELECT ', ' TABLE, VIEW, SEQUENCE ');

    RETURN TRUE;
  END;
END_PROC;

--
--### grant_external
--
--Grant a group to create, read and write external tables in current catalog.
--
--```sql
--\c mydatabase
--CALL util..grant_external('GROUP_NAME');
--```
--

CREATE OR REPLACE PROCEDURE grant_external(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    group_name ALIAS FOR $1;
  BEGIN
--* creates group if it does not exists
    CALL util..create_or_update_group(group_name);

--* grants *list, select, drop* object privileges on *external table*
    CALL util..grant_object_privilege(group_name, ' LIST, SELECT, DROP ', ' EXTERNAL TABLE ');

--* grants *create external table* admin privilege
    CALL util..grant_admin_privilege(group_name, ' CREATE EXTERNAL TABLE ');

    RETURN TRUE;
  END;
END_PROC;

--### grant_systemview
--
--Grant a group to read system views in current catalog.
--
--```sql
--\c mydatabase
--CALL util..grant_systemview('GROUP_NAME');
--```
--

CREATE OR REPLACE PROCEDURE grant_systemview(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    group_name ALIAS FOR $1;
  BEGIN
--* creates group if it does not exists
    CALL util..create_or_update_group(group_name);

--* grants *list, select* object privileges on *system view*
    CALL util..grant_object_privilege(group_name, ' LIST, SELECT ', ' SYSTEM VIEW ');

    RETURN TRUE;
  END;
END_PROC;

--
--### grant_readwrite
--
--Grant a group to read and write data in current catalog.
--
--```sql
--\c mydatabase
--CALL util..grant_readwrite('GROUP_NAME');
--```
--

CREATE OR REPLACE PROCEDURE grant_readwrite(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    group_name ALIAS FOR $1;

/* TODO questo per ora lo lascio
    object_privilege_list VARCHAR(1000) := ' LIST, SELECT, INSERT, UPDATE, DELETE, TRUNCATE, LOCK, ALTER, DROP, ABORT, LOAD, GENSTATS, GROOM ';

    object_list           VARCHAR(1000) := ' TABLE, VIEW, SEQUENCE ';
*/
  BEGIN
--* creates group if it does not exists
    CALL util..create_or_update_group(group_name);

--* calls [grant_readonly](#grant_readonly)
    CALL util..grant_readonly(group_name);

--* calls [grant_external](#grant_external)
    CALL util..grant_external(group_name);

--* calls [grant_systemview](#grant_systemview)
    CALL util..grant_systemview(group_name);

--* grants *insert, update, delete, truncate, alter, drop, genstats, groom* object privileges on *table*
    CALL util..grant_object_privilege(group_name, ' INSERT, UPDATE, DELETE, TRUNCATE, ALTER, DROP, GENSTATS, GROOM ', ' TABLE ');

/* TODO questo per ora lo lascio
    CALL util..grant_object_privilege(group_name, object_privilege_list, object_list);
*/

--* grants *create table, create view, create sequence* admin privilege
    CALL util..grant_admin_privilege(group_name, ' CREATE TABLE, CREATE VIEW, CREATE SEQUENCE ');
    RETURN TRUE;
  END;
END_PROC;

--
--
--### grant_execute
--
--Grant a group to edit and call stored procedures and functions in current catalog.
--
--```sql
--\c mydatabase
--CALL util..grant_execute('GROUP_NAME');
--```
--

CREATE OR REPLACE PROCEDURE grant_execute(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    group_name ALIAS FOR $1;

    object_privilege_list VARCHAR(1000) := ' LIST, SELECT, UPDATE, DROP, EXECUTE ';

    admin_privilege_list  VARCHAR(1000) := ' CREATE FUNCTION, CREATE PROCEDURE ';
  BEGIN
--* creates group if it does not exists
    CALL util..create_or_update_group(group_name);

--* grants *list, select, update, drop, execute* object privileges on *function, procedure*
    CALL util..grant_object_privilege(group_name, object_privilege_list, ' FUNCTION, PROCEDURE ');

--* grants *create function, create procedure* admin privilege
    CALL util..grant_admin_privilege(group_name, ' CREATE FUNCTION, CREATE PROCEDURE ');

    RETURN TRUE;
  END;
END_PROC;

/*

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

*/

--# Development
--
--## Generate docs
--
--Documentation is generated extracting comments with a `--` in the beginning of line.
--
--```sql
--/* This kind of comments will be ignored */
--```
--The following commands work also from Git shell on Windows.
--
--### Generate README.md
--
--```bash
--grep -E '^--' nz_util.sql | sed -e 's/--//' > README.md
--```
--
--### Generate html docs
--
--Install [marked](https://github.com/chjj/marked) globally **only once**.
--
--```bash
--npm install marked -g
--```
--
--Create docs/index.html from README.md
--
--```bash
--marked -o docs/index.html README.md
--```
--
--Update site
--
--```bash
--git subtree --prefix docs push origin gh-pages
--```
--

