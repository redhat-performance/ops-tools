from dateutil.parser import parse
from datetime import timedelta
from datetime import datetime
from elasticsearch import Elasticsearch
import argparse


class MyParser(argparse.ArgumentParser):
    """Custom parser class."""

    def error(self, message):
        """Print help on argument parse error."""
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)


def parse_args():
    """Parse input args and returns an args dict."""
    parser = MyParser(description='Automated node tagging script for \
                                   large OpenStack deployments')

    parser.add_argument(
        '-d',
        '--days',
        dest='days',
        type=int,
        help='The archive period for logs in days',
        required=True)

    parser.add_argument('-e', '--elastic', dest='host', type=str,
                        help='The Elasticsearch host address', required=True)

    parser.add_argument('-i', '--index', dest='index', type=str,
                        help='The index pattern to archive', required=True)

    parser.add_argument('-p', '--port', dest='port', type=int, default=9200,
                        help='The Elasticsearch port', required=False)

    parser.add_argument('--delete', dest='delete', default=False, type=bool,
                        help='Delete old indexes. Use with caution')

    args = parser.parse_args()
    return args


args = parse_args()

es = Elasticsearch([
    {'host': args.host,
     'port': args.port}],
    send_get_body_as='POST',
    retries=True,
    sniff_on_start=True,
    sniff_on_connection_fail=True,
    sniff_timeout=10,
    sniffer_timeout=120,
    timeout=120)

now = datetime.utcnow()

archive_date = timedelta(days=args.days)

for index in es.indices.get_alias("{}*".format(args.index)):
    index_date_str = index.split('-')[1]
    try:
        index_date = parse(index_date_str)
        if now - index_date > archive_date:
            print("{}".format(index))
            if args.delete:
                print("Look at me deleting things!")
                es.indices.delete(index=index, ignore=[400, 404])
    except ValueError:
        continue
