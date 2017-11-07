#!/bash
. elastic-func.sh

# Parses dates from logstash indexes, if an index is older than a given number of days
# then the index is archived and then deleted.

# usage ./elastic-maint.sh <es> <days> <index-prefix>

virtualenv venv/
source venv/bin/activate
pip install elasticsearch
pip install python-dateutil

set -eux
# Number of days after which logs are archived
ARCHIVE=$2
# Target Elasticsearch
ES=$1
INDEX=$3

for idx in $(python elastic-maint.py --index $INDEX --elastic $ES --days $ARCHIVE) ; do
    backup_index $idx $idx.mapping.json.xz $idx.json.xz
done

python elastic-maint.py --index $INDEX --elastic $ES --days $ARCHIVE --delete true
