#!/usr/bin/env bash
set -ex
T="$(dirname "$(readlink -f $)")"
cd $T
crontab=${crontab:-/etc/cron.d/awstatstatic}
cp *crontab $crontab
sed -i -re 's!__DIR__!'$T'!g' "$crontab"
# vim:set et sts=4 ts=4 tw=80:
