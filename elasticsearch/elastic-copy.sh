#!/bin/bash
. elastic-func.sh

# Copy the data in one Elasticsearch to another
# ES URL's must be in full https format including port
# Usage ./elastic-copy.sh FROM_ES TO_ES

FROM_ES=$1
TO_ES=$2

for idx in $(curl -s -X GET "$FROM_ES/_cat/indices" | grep -vF .kibana | sort -n -k 6 | awk '{print $3}') ; do
    copy_index $idx $FROM_ES $TO_ES
done
