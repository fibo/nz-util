nz-util
=======

> Netezza utility functions

**Version 2013-12-10**
# Installation

## Download the code

If you are on a Linux box (for example the Netezza frontend itself), you can try with this command

```bash
wget --no-check-certificate --timestamping https://raw.github.com/fibo/nz-util/master/nz_util.sql
```

## Install

```bash
nzsql -u admin -d system -c 'CREATE DATABASE util COLLECT HISTORY OFF'
nzsql -u admin -d util -f nz_util.sql
```

## Update

Check current version

```bash
nzsql -u admin -d util -c '\dd util'
```

Update *Netezza utilities*.

```bash
nzsql -u admin -d util -f nz_util.sql
```

# Utilities


## Type checking

----------------

### is_table

Returns true if given object is a *TABLE*, otherwise false.

```sql
CALL util..is_table('OBJECT_NAME');
```


### is_view

Returns true if given object is a *VIEW*, otherwise false.

```sql
CALL util..is_view('OBJECT_NAME');
```


### is_sequence

Returns true if given object is a *SEQUENCE*, otherwise false.

```sql
CALL util..is_sequence('OBJECT_NAME');
```


### is_group

Returns true if given object is a *GROUP*, otherwise false.

```sql
CALL util..is_group('OBJECT_NAME');
```


### is_user

Returns true if given object is a *USER*, otherwise false.

```sql
CALL util..is_user('OBJECT_NAME');
```


## Groups and grants management


### create_or_update_group

Create a group safely. If group already exists, it will be granted to list current catalog.
Please note that since Netezza grants permissions contextually to current catalog,
you need to connect manually to catalog.

```sql
\c mydatabase
CALL util..create_or_update_group('GROUP_NAME');
```

* avoids creating groups in reserved catalogs
* if group already exists it just grants *list* on catalog
* creates group if it does not exists and grants *list* on catalog

### grant_readonly

Grant a group to read data in current catalog.

```sql
\c mydatabase
CALL util..grant_readonly('GROUP_NAME');
```

* creates group if it does not exists
* calls [grant_systemview](#grant_systemview)
* grants *list, select* object privileges on *table, view, sequence*

### grant_external

Grant a group to create, read and write external tables in current catalog.

```sql
\c mydatabase
CALL util..grant_external('GROUP_NAME');
```

* creates group if it does not exists
* grants *list, select, drop* object privileges on *external table*
* grants *create external table* admin privilege

### grant_systemview

Grant a group to read system views in current catalog.

```sql
\c mydatabase
CALL util..grant_systemview('GROUP_NAME');
```

* creates group if it does not exists
* grants *list, select* object privileges on *system view*

### grant_readwrite

Grant a group to read and write data in current catalog.

```sql
\c mydatabase
CALL util..grant_readwrite('GROUP_NAME');
```

* creates group if it does not exists
* calls [grant_readonly](#grant_readonly)
* calls [grant_external](#grant_external)
* grants *insert, update, delete, truncate, alter, drop, genstats, groom* object privileges on *table*
* grants *create table, create view, create sequence* admin privilege

### grant_execute

Grant a group to edit and call stored procedures and functions in current catalog.

```sql
\c mydatabase
CALL util..grant_execute('GROUP_NAME');
```

* creates group if it does not exists
* grants *list, select, update, drop, execute* object privileges on *function, procedure*
* grants *create function, create procedure* admin privilege

# Development

## Generate docs

Documentation is generated extracting comments with a `--` in the beginning of line.

```sql
/* This kind of comments will be ignored */
```
The following commands work also from Git shell on Windows.

### Generate README.md

```bash
grep -E '^--' nz_util.sql | sed -e 's/--//' > README.md
```

### Generate html docs

Install [marked](https://github.com/chjj/marked) globally **only once**.

```bash
npm install marked -g
```

Create docs/index.html from README.md

```bash
marked -o docs/index.html README.md
```

Do a `git commit` then update site

```bash
git subtree --prefix docs push origin gh-pages
```

