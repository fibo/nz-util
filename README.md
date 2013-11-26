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

 # create_group_system_view

 Create a group that can query system views

 ```sql
 util..create_group_system_view('GROUP_NAME')
 ```

# Development

Generate README.md

    $ grep -E '^--' nz_util.sql | sed -e 's/--//' > README.md

Install docco

    npm install docco -g

Create annotated sources

    mkdir docs
    $ docco -o docs nz_util.sql
    $ mv docs/nz_util.sql docs/index.html

