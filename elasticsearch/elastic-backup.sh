#!/bin/bash
. elastic-func.sh

# Backup all indicies in an Elasticsearch cluster

# ES URL's must be in full https format including port
# Uses nice to run in the background without disrupting anything
# requirements elasticdump, pxz

# Usage ./elastic-backup.sh ES

ES=$1


for idx in $(curl -s -X GET "$ES/_cat/indices" | grep -vF .kibana | sort -n -k 6 | awk '{print $3}') ; do
    backup_index $idx $idx.mapping.json.xz $idx.json.xz
done
