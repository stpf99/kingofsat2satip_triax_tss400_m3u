 #!/bin/bash
# configure SATIP server name/IP address, here
#SERVER="192.168.178.42"
SERVER="192.168.1.113"
echo your server ip adress is $SERVER
# T1 = tuner 1,T2 = tuner 2,T3 = tuner3,T4 = tuner 4
# P1 = diseqc A,P2 = diseqc B,P3 = diseqc C,P4 = diseqc D
#tuner 1

T1P1=39.0E
T1P2=42.0E
T1P3=46.0E
T1P4=50.0E

#tuner 2

T2P1=26.0E
T2P2=28.2E
T2P3=31.0E
T2P4=36.0E

#tuner 3

T3P1=16.0E
T3P2=19.2E
T3P3=21.5E
T3P4=23.5E

#tuner 4

T4P1=4.8E
T4P2=7.0E
T4P3=10.0E
T4P4=13.0E

DIR=($T1P1 $T1P2 $T1P3 $T1P4 $T2P1 $T2P2 $T2P3 $T2P4 $T3P1 $T3P2 $T3P3 $T3P4 $T4P1 $T4P2 $T4P3 $T4P4)
echo your configured sat positions "${DIR[@]}"
OUTFILES=(*.php *.m3u /tmp/*.m3u )
echo cleaning 
if [ -f $OUTFILES ]; then
    rm  $OUTFILES

fi
echo cleaned
echo setting positions sources
rm -r "${DIR[@]}"
mkdir "${DIR[@]}"
	    echo '1' > $T1P1/N
	    echo '2' > $T1P2/N
	    echo '3' > $T1P3/N
	    echo '4' > $T1P4/N
	    echo '1' > $T2P1/N
	    echo '2' > $T2P2/N
	    echo '3' > $T2P3/N
	    echo '4' > $T2P4/N
	    echo '1' > $T3P1/N
	    echo '2' > $T3P2/N
	    echo '3' > $T3P3/N
	    echo '4' > $T3P4/N
	    echo '1' > $T4P1/N
	    echo '2' > $T4P2/N
	    echo '3' > $T4P3/N
	    echo '4' > $T4P4/N
echo positions have settings
echo fetching files from site
# download PHP files from kingofsat
for i in "${DIR[@]}";
 do
cd $i
wget https://de.kingofsat.net/tv-$i-fta.php
cd ..
done
echo files fetched
echo creating m3u lists for each position
for i in "${DIR[@]}";
do
cd $i
src=$(cat "N")
python ../getchannels.py $SERVER tv-$i-fta.php $src
cd ..
done
echo basic m3u sat playlist created
echo creating FTA dir with today date
mkdir FTA
mkdir FTA/$(date +%F)
echo Directories setted up
echo apllying necessary corrections
for i in "${DIR[@]}";
do
sed 's/pol=V/pol=v/g' $i/tv-$i-fta.m3u > /tmp/tv-$i-fta.m3u && sed 's/pol=H/pol=h/g' /tmp/tv-$i-fta.m3u > FTA/$(date +%F)/TV-$i-FTA-$(date +%F)-$(date +%M).m3u
done
echo corrections applied succesfully
echo merging m3u to one playlist
cat FTA/$(date +%F)/*.m3u > FTA/$(date +%F)/allChannels.m3u
echo playlists merged
echo corrections for merged playlists
sed 's/pol=V/pol=v/g' FTA/$(date +%F)/allChannels.m3u > /tmp/allChannels.m3u && sed 's/pol=H/pol=h/g'  /tmp/allChannels.m3u > FTA/$(date +%F)/ALL_FTA-$(date +%F)-$(date +%M).m3u
echo all done
echo playlist file for each configured and all in one positions ALL_FTA-$(date +%F)-$(date +%M).m3u is in "FTA / $(date +%F)" Directory
rm FTA/$(date +%F)/allChannels.m3u
rm -r "${DIR[@]}"
mkdir DATABASE
list_new=FTA/$(date +%F)/ALL_FTA-$(date +%F)-*.m3u
list_old=FTA/$(date -d "yesterday" +%F)/ALL_FTA-$(date -d "yesterday" +%F)-*.m3u
grep -Fxvf $list_new $list_old >> DATABASE/removed-$(date +%F)-$(date +%M).m3u
grep -Fxvf $list_old $list_new >> DATABASE/added-$(date +%F)-$(date +%M).m3u
cat DATABASE/removed*.m3u >> AllRemoved.m3u
cat DATABASE/added*.m3u >> Alladded.m3u
echo preparing files for openwrt "uhttpd" service place /www/ on router , TIP: install cmd for uhttpd : "opkg update && opkg install uhttpd" in ssh session on openwrt router
mkdir openwrt_www
IP=$(/sbin/ip route | awk '/default/ { print $3 }')
cp FTA/$(date +%F)/ALL_FTA-$(date +%F)-$(date +%M).m3u openwrt_www/ALL_SAT_FTA.m3u
cp Alladded.m3u AllRemoved.m3u openwrt_www/
for i in "${DIR[@]}";
do
cp FTA/$(date +%F)/TV-$i-FTA-$(date +%F)-$(date +%M).m3u openwrt_www/$i.m3u
done
echo '#EXTM3U' > Master.m3u
echo '#EXTINF:0,source=ALL_SAT_FTA' >> Master.m3u
echo "http://$IP/ALL_SAT_FTA.m3u" >> Master.m3u
echo '#EXTM3U' >> Master.m3u
echo '#EXTINF:0,source=AllRemoved' >> Master.m3u
echo "http://$IP/AllRemoved.m3u" >> Master.m3u
echo '#EXTM3U' >> Master.m3u
echo '#EXTINF:0,source=Alladded' >> Master.m3u
echo "http://$IP/Alladded.m3u" >> Master.m3u
for i in "${DIR[@]}";
do
echo "#EXTINF:0,Sat=${i}" >> Master.m3u
echo "http://$IP/${i}.m3u" >> Master.m3u
done
mv Master.m3u openwrt_www/
echo files for openwrt ready
rm -r FTA/

