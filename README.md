nz-util
=======

Netezza utility functions

# Installation

## Download the code

If you are on a Linux box (for example the Netezza frontend itself), you can try with this command

```bash
wget --no-check-certificate --timestamping https://raw.github.com/fibo/nz-util/master/nz_util.sql
```

## Install utilities

```bash
nzsql -u admin -d system -c 'CREATE DATABASE util COLLECT HISTORY OFF'
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


### create_group

Create a group safely.

```sql
CALL util..create_group('GROUP_NAME');
```

* Avoids creating groups in reserved catalogs
* checks that group does not exists yet

### create_group_readonly

Create a group that can read and **can not** modify data.

```sql
CALL util..create_group_readonly('GROUP_NAME');
```


### create_group_readwrite

Create a group that can read and write data.

```sql
CALL util..create_group_readwrite('GROUP_NAME');
```


### create_group_system_view

Create a group that can read system views.

```sql
CALL util..create_group_system_view('GROUP_NAME');
```


### create_group_execute

Create a group that can edit and call stored procedures.

```sql
CALL util..create_group_execute('GROUP_NAME');
```

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

