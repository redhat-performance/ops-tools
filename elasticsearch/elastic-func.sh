#!/bin/bash
# Utility functions for Elasticsearch

# Restores an index in the .json.xz format using no scratch space
# usage restore_index <index name> <file location mapping> <file location data>
function restore_index {
    echo "Restore $1, mapping"
    xzcat $2 | nice elasticdump \
      --input=$ \
      --output=$ES/$1 \
      --type=mapping
    echo "Restore $1, data"
    xzcat $3 | nice elasticdump \
      --input=$ \
      --output=$ES/$1 \
      --type=data \
      --limit=1000
}

# Backs up an index in the .json.xz format using no scratch space
# usage backup_index <index name> <file location mapping> <file location data>
function backup_index {
    echo "Dump $1, mapping"
    nice elasticdump \
      --input=$ES/$1 \
      --output=$ \
      --type=mapping | nice pxz > $2
    echo "Dump $1, data"
    nice elasticdump \
      --input=$ES/$1 \
      --output=$ \
      --type=data \
      --limit=1000 | nice pxz > $3
}

# Usage copy_index <index> <from> <to>
function copy_index {
    echo "Dump $1, mapping"
    elasticdump \
      --input=$2/$1 \
      --output=$3/$1 \
      --type=mapping
    echo "Dump $1, data"
    elasticdump \
      --input=$2/$1 \
      --output=$3/$1 \
      --type=data \
      --limit=1000
}
