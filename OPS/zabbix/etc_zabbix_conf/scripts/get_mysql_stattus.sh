#!/bin/sh
# The wrapper for Cacti PHP script.
# It runs the script every 5 min. and parses the cache file on each following run.
# Version: 1.1.6
#
# This program is part of Percona Monitoring Plugins
# License: GPL License (see COPYING)
# Copyright: 2016 Percona
# Authors: Roman Vynar

ITEM=$1
HOST=localhost
DIR=`dirname $0`

if [ "$ITEM" = "status" ]; then
    # Check for slave status
    RES=`mysql -uzabbix_agent -pzabbix_agent -e 'SHOW SLAVE STATUS\G' | grep -E '(Slave_IO_Running|Slave_SQL_Running):' | awk -F: '{print $2}' | tr '\n' ','`
    if [ "$RES" = " Yes, Yes," ]; then
        echo 1
    else
        echo 0
    fi
fi
