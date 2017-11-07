#!/bin/bash
. elastic-func.sh

# Restores indicies backed up using the backup script
# looks for backup format files in the pwd

# ES URL's must be in full https format including port
# Uses nice to run in the background without disrupting anything
# requirements elasticdump, pxz

# Usage ./elastic-restore.sh ES

ES=$1


for idx in $(ls *.mapping.json.xz | sed 's/.mapping.json.xz//') ; do
    restore_index $idx $idx.mapping.json.xz $idx.json.xz
done
