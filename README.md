nz-util
=======

Netezza utility functions

Installation
------------

## Download the code

If you are on a Linux box (for example the Netezza frontend itself), you can try with this command

    wget --no-check-certificate --timestamping https://raw.github.com/fibo/nz-util/master/nz_util.sql

## Install utilities

    $ nzsql -u admin -d system -c 'CREATE DATABASE util COLLECT HISTORY OFF'
    $ nzsql -u admin -d util -f nz_util.sql

Utilities
---------

## is_object(VARCHAR(100))

## class_of(VARCHAR(100))

## class_of(VARCHAR(100), VARCHAR(100))

## is_table(VARCHAR(100))

## is_view(VARCHAR(100))

## is_sequence(VARCHAR(100))

## is_group(VARCHAR(100))

## is_user(VARCHAR(100))

## grant_object_privilege(VARCHAR(100), VARCHAR(1000), VARCHAR(1000))

## grant_admin_privilege(VARCHAR(100), VARCHAR(1000))

## create_group(VARCHAR(100))

## create_group_readonly(VARCHAR(100))

## create_group_readwrite(VARCHAR(100))

## create_group_execute(VARCHAR(100))

## users_of_group(VARCHAR(100))

