#!/bin/sh
# This monitors a Gerrit instance for new patchsets and
# announces updates and merges
# Requires: Supybot and notify plugin, git

PROJECTDIR=/home/quads/git/quads
LISTING_STATEDIR=/home/quads/review
LOCK=/home/quads/.quads.cron.lock
COMMITURL="https://github.com/redhat-performance/quads/commit"

cd $PROJECTDIR

# note that prior to proceeding, an account was
# manually created and verified on github and
# authorized on the gerrit server.

# also run: git config --global color.ui false
# otherwise this script breaks

if [ -f $LOCK ]; then
  exit 0
fi

touch $LOCK

LISTING=$(mktemp /tmp/git-review-XXXXXXX)

git reset --hard origin/master
git pull origin master
git review -l | egrep -v '^Found.*items for review' > $LISTING

for review in $(awk '{ print $1 }' $LISTING) ; do
  git review -d $review
  latestline="$(git log --pretty=oneline | head -1)"
  info="$(egrep ^$review $LISTING)"
  id=$(echo "$info" | awk '{ print $1 }')
  branch=$(echo "$info" | awk '{ print $2 }')

  git checkout master

  if [ "$(git log --pretty=oneline | grep "$latestline")" ]; then
    :
  else
    if [ ! -f $LISTING_STATEDIR/$review ]; then
      msg="$(echo "$info" | sed 's/[0-9][0-9]*[ ][ ]*[^ ][^ ]*[ ][ ]*\(.*\)/\1/g')"
      echo "#quads New Review  :: https://review.gerrithub.io/#/c/$id/  || branch: $branch || $msg" | nc 127.0.0.1 5556
    else
      if [ x"$(echo "$latestline" | awk '{ print $1 }')" != x"$(head -1 $LISTING_STATEDIR/$review | awk '{ print $1 }')" ]; then
        msg="$(echo "$latestline" | sed 's/[^ ][^ ]*[ ][ ]*\(.*\)/\1/g')"
        echo "#quads Review Updated :: https://review.gerrithub.io/#/c/$id/  || branch: $branch || $msg" | nc 127.0.0.1 5556
      fi
    fi
  fi
  echo "$latestline" > $LISTING_STATEDIR/$review
done

git checkout master

for review in $(cd /home/quads/review ; ls ) ; do
  if [ "$(git log --pretty=oneline | grep "$(cat /home/quads/review/$review)")" ]; then
    msg="$(cat /home/quads/review/$review)"
    echo "#quads Review Merged :: https://review.gerrithub.io/#/c/$id/  || branch: $branch || $COMMITURL/$msg" | nc 127.0.0.1 5556
    rm -f /home/quads/review/$review
  fi
done

rm -f $LISTING $LOCK
