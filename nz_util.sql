--nz-util
--=======
--
--
--Netezza utility functions
--
--# Installation
--
--## Download the code
--
--If you are on a Linux box (for example the Netezza frontend itself), you can try with this command
--
--    wget --no-check-certificate --timestamping https://raw.github.com/fibo/nz-util/master/nz_util.sql
--
--## Install utilities
--
--   $ nzsql -u admin -d system -c 'CREATE DATABASE util COLLECT HISTORY OFF'
--   $ nzsql -u admin -d util -f nz_util.sql
--
--# Utilities
--

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

--
--## class_of(VARCHAR(100), VARCHAR(100))
--

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
--## create_group(VARCHAR(100))
--

CREATE OR REPLACE PROCEDURE create_group(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    catalog NAME := CURRENT_CATALOG;

    group_name ALIAS FOR $1;

    group_exists BOOLEAN;
  BEGIN
    --* Avoids creating groups in reserved catalogs
    IF 'SYSTEM' = catalog THEN
      RAISE EXCEPTION '% is a reserved catalog', catalog;
    END IF;

    --* checks that group does not exists yet
    group_exists := util..is_group(group_name);

    IF group_exists THEN
      RAISE EXCEPTION 'group % already exists', group_name;
    END IF;

    EXECUTE IMMEDIATE 'CREATE GROUP ' || group_name;

    RETURN TRUE;
  END;
END_PROC;

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

-- # create_group_system_view
--
-- Create a group that can query system views
--
-- ```sql
-- util..create_group_system_view('GROUP_NAME')
-- ```
--

CREATE OR REPLACE PROCEDURE create_group_systemview(VARCHAR(100))
  RETURNS BOOLEAN
  LANGUAGE NZPLSQL
AS
BEGIN_PROC
  DECLARE
    group_name ALIAS FOR $1;

    object_privilege_list VARCHAR(1000) := ' LIST, SELECT ';

    object_list           VARCHAR(1000) := ' SYSTEM VIEW ';

  BEGIN
    CALL util..create_group(group_name);

    CALL util..grant_object_privilege(group_name, object_privilege_list, object_list);

    RETURN TRUE;
  END;
END_PROC;

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
--The following command work also from Git shell on Windows.
--
--### Generate README.md
--
--```bash
--grep -E '^--' nz_util.sql | sed -e 's/--//' > README.md
--```
--
--### Generate html docs
--
--Install *marked* globally (only once).
--
--```bash
--npm install marked -g
--```
--
--Create index.html from README.md
--
--```bash
--marked -o docs/index.html README.md
--```
--
--Update site
--
--```bash
--git subtree --prefix docs pull origin gh-pages
--```
--
--Install docco
--
--    npm install docco -g
--
--Create annotated sources
--
--    mkdir docs
--    $ docco -o docs nz_util.sql
--    $ mv docs/nz_util.sql docs/index.html
--

