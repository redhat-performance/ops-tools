Elasticsearch utility scripts
-----------------------------

elastic-backup.sh

A script to dump and compress all data from an Elasticsearch instance. Requires pxz and elasticdump. Both of which you can install from yum. Index files are dumped to your pwd.

Usage:

    ./elastic-backup.sh http://elasticsearch:9200

elastic-copy.sh

A direct elasticsearch to elasticsearch copy tool. Requires elasticdump

Usage:

    ./elastic-copy.sh http://es_from:9200 http://es_to:9200

elastic-restore.sh

Restores elasticsearch indexies backed up using elastic-backup.sh. Uses the files in the pwd, rquires xz and elasticsearch.

Usage:

    ./elastic-restore.sh http://elasticsearch:9200

elastic-maint.sh

Used to rotate logstash indexes by automatically archiving to disk and deleting remote indicies. Requirements elasticsearch pxe and python virtualenv/pip It will create a virtualenv in your pwd to install python-elasticsearch and python-dateutil. The default dump size limit and cores parameter to pxz are setup to prevent crashing the ES cluster, if your cluster can handle it you may want to increase them.

Usage:

    #configure retention period and es
    vim elastic-maint.sh
    ./elastic-maint.sh
