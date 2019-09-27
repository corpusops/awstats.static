#!/usr/bin/env bash
set -e
DEBUG="${DEBUG-}"
WIPE="${WIPE-}"
if [[ -n $DEBUG ]];then set -x;fi
CFGDIR=${CFGDIR-/etc/awstats}
if [ ! -e $CFGDIR ];then
    echo "NO CFGDIR";exit 1
fi
CFGS=${CFGS-}
while read f;do 
    CFGS="$CFGS $(basename $f .conf|sed -re 's/^awstats.//g')";
done < <(find "$CFGDIR" -type f -name "*.conf"|grep -v awstats.conf)
indexr=/var/www/awstats
indexR=/var/www/awstats/index.html
index=${indexR}.tmp
NO_INNER=${NO_INNER-}
NO_COMPUTE=${NO_COMPUTE-}
echo "<html><body>">$index
stats_knobs="
alldomains
allhosts
alllogins
allrobots
browserdetail
downloads
errors404
keyphrases
keywords
lasthosts
lastlogins
lastrobots
osdetail
refererpages
refererse
unknownbrowser
unknownip
unknownos
urldetail
urlentry
urlexit
"
for cfg in $CFGS;do
	logs="
	$(find /var/log/nginx/ -name "${cfg}*access*.gz" |sort -V|tac)
	/var/log/nginx/${cfg}-access.log.1
	/var/log/nginx/${cfg}-access.log
	"
	Y=$(date +"%Y")
    if [[ -z $NO_INNER ]] ;then
	if [[ -n $WIPE ]];then
		rm -f /var/lib/awstats/awstats*${cfg}*
	fi
    if [[ -z $NO_COMPUTE ]] ;then
        for i in $logs;do
            echo "load $i"
            catter=cat
            if $(echo $i |grep -q gz);then
                catter=zcat
            fi
            awstats -config="${cfg}" -update -LogFile="$catter $i |"
        done
    fi
	echo "<br/>$cfg<br/><ul>">>$index
	for year in $Y $(($Y-1)) $(($Y-2));do
		echo "<br/>">>$index
		awstats -config=${cfg}  -month=all -year=${year} -output -staticlinks > /var/www/awstats/${cfg}-$year.html
		printf  '<li><a href="%s">Annuel %s</a></li>' ./$cfg-${year}.html $year>>$index
		for month in 01 02 03 04 05 06 07 08 09 10 11 12;do
			awstats -config=${cfg} -output -staticlinks -year=${year} -month=${month} > /var/www/awstats/${cfg}-${year}-month-${month}.html
			printf  '&nbsp;-&nbsp;<span><a href="%s">Mensuel %s</a></span>' ./$cfg-${year}-month-${month}.html ${month}>>$index
		done
        printf  '<br/>&nbsp;Annuel: &nbsp;' ${month}>>$index
        for knob in $stats_knobs;do
            hstatref=awstats.${cfg}.${knob}.${year}.html
            hstatf=$indexr/$hstatref
            awstats -config=$cfg -year=$year -month=all -output=${knob} -staticlinks > $hstatf
            printf  '<span>&nbsp;-&nbsp;<a href="%s">%s</a></span>' $hstatref $knob>>$index
        done
		echo "<br/>">>$index
	done
    fi
	echo "<br/><br></ul>">>$index
    for knob in $stats_knobs;do
        awstats -config=$cfg -year=$Y -month=all -output=${knob}     -staticlinks > $indexr/awstats.${cfg}.${knob}.html
    done
done
echo "</body></html>">>$index
cp "${index}" "${indexR}"
# vim:set et sts=4 ts=4 tw=0:
