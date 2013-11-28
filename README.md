nz-util
=======

Netezza utility functions

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


## class_of

Return the object class.

```sql
CALL util..class_of('FOO');
```

* *object_name* is not case sensitive

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
* checks if group already exists

### grant_readonly

Grant a group to read data in current catalog.

```sql
\c mydatabase
CALL util..grant_readonly('GROUP_NAME');
```

* creates group if it does not exists

### grant_readwrite

Grant a group to read and write data in current catalog.

```sql
\c mydatabase
CALL util..grant_readwrite('GROUP_NAME');
```

* creates group if it does not exists

### grant_systemview

Grant a group to read system views in current catalog.

```sql
\c mydatabase
CALL util..grant_systemview('GROUP_NAME');
```

* creates group if it does not exists

### grant_execute

Grant a group to edit and call stored procedures in current catalog.

```sql
\c mydatabase
CALL util..grant_execute('GROUP_NAME');
```

* creates group if it does not exists
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

Update site

```bash
git subtree --prefix docs push origin gh-pages
```

