nz-util
=======


Netezza utility functions

# Installation

## Download the code

If you are on a Linux box (for example the Netezza frontend itself), you can try with this command

    wget --no-check-certificate --timestamping https://raw.github.com/fibo/nz-util/master/nz_util.sql

## Install utilities

   $ nzsql -u admin -d system -c 'CREATE DATABASE util COLLECT HISTORY OFF'
   $ nzsql -u admin -d util -f nz_util.sql

# Utilities


## class_of(VARCHAR(100), VARCHAR(100))


## create_group(VARCHAR(100))

 # create_group_system_view

 Create a group that can query system views

 ```sql
 util..create_group_system_view('GROUP_NAME')
 ```

# Development

## Generate docs

The following command work also from Git shell on Windows.

### Generate README.md

```bash
grep -E '^--' nz_util.sql | sed -e 's/--//' > README.md
```

### Generate html docs

Install *marked* globally (only once).

```bash
npm install marked -g
```

Create index.html from README.md

```bash
marked -o docs/index.html README.md
```

Update site

```bash
git subtree --prefix docs pull origin gh-pages
```

Install docco

    npm install docco -g

Create annotated sources

    mkdir docs
    $ docco -o docs nz_util.sql
    $ mv docs/nz_util.sql docs/index.html

