#!/bin/bash

# Copyright (c) 2010 Csaba Kiraly
# Copyright (c) 2010 Luca Abeni
# This is free software; see gpl-3.0.txt

# Run a whole set of experimets cycling thourh variuos parameter values,
# and gather statistics.

# see cycletest.config.exampe, for configuration parameters and examples!

usage()
{
  echo "Usage: $0 <configfile>"
}

[ -e "$1" ] || { usage; exit 1; }
. $1

# Kill everything we've started on exit (with trap).
bashkilltrap()
{
  # ok that's the end
  # you can add here all possible postprocessing,

  $LIMITBW end $IFDEV

  ps -o pid= --ppid $$ | xargs kill 2>/dev/null
}
trap bashkilltrap 0

WAIT=${WAIT:-30}

rm -f stderr.[0-9]*

for CYCLE in `eval echo $CYCLEs`; do
for CHBUF in `eval echo $CHBUFs`; do
for REORDBUF in `eval echo $REORDBUFs`; do
for PEERNUM  in `eval echo $PEERNUMs` ; do
for PEERNUM1 in `eval echo $PEERNUM1s`; do
for PEERNUM2 in `eval echo $PEERNUM2s`; do
for NEIGH in `eval echo $NEIGHs`; do
for UPRATE  in `eval echo $UPRATEs` ; do
for UPRATEPART1  in `eval echo $UPRATEPART1s` ; do
for UPRATE1 in `eval echo $UPRATE1s`; do
for UPRATE2 in `eval echo $UPRATE2s`; do
for DELAY in `eval echo $DELAYs`; do
for SRCCOPIES in `eval echo $SRCCOPIESs`; do
for CPS in `eval echo $CPSs`; do
for BIN in `eval echo $BINs`; do

  SCENARIO_HDR="protocol,peers,uprateavg,upratepart1"\
",peers1,neighsize1,uprate1,updelay1,uploss1"\
",peers2,neighsize2,uprate2,updelay2,uploss2"\
",srccopies"\
",offerthreads,chbuf,reordbuf,cycle"
  export SCENARIO="$BIN,$PEERNUM,$UPRATE,$UPRATEPART1"\
",$PEERNUM1,$NEIGH,$UPRATE1,$DELAY,0"\
",$PEERNUM2,$NEIGH,$UPRATE2,$DELAY,0"\
",$SRCCOPIES"\
",$CPS,$CHBUF,$REORDBUF,$CYCLE"
  CSV=published.${SCENARIO/,/_}.csv

  echo "running $SCENARIO"

  if [ ! -e $CSV ] ; then
  mpstat 5 | tee cpu.${SCENARIO/,/_}.txt &
  MPSTAT_PID="$!"

  $LIMITBW init $IFDEV

  $LIMITBW peers $IFDEV 6667 $((6667+$PEERNUM1-1)) $UPRATE1 0 $DELAY
  $TESTSH -v $VIDEO -I $IFDEV -f abouttopub -p "--measure_start $MEASURE_START --measure_every $MEASURE_EVERY -c $CPS -b $CHBUF -o $REORDBUF -M $NEIGH -n stun_server=0 $PEER_EXTRAPARAM" -s "-M 0 -n stun_server=0 -m $SRCCOPIES $SOURCE_EXTRAPARAM" -X 0 -e ${BINPREFIX}${BIN}${BINPOSTFIX} -N $PEERNUM1 >a &
  PIDS="$!"

  if [ $PEERNUM2 -ge 1 ]; then 
    $LIMITBW peers $IFDEV $((6667+$PEERNUM1)) $((6667+$PEERNUM1+$PEERNUM2-1)) $UPRATE2 0 $DELAY
    $TESTSH -I $IFDEV -f abouttopub -p "--measure_start $MEASURE_START --measure_every $MEASURE_EVERY -c $CPS -b $CHBUF -o $REORDBUF -M $NEIGH -n stun_server=0 $PEER_EXTRAPARAM" -X 0 -e ${BINPREFIX}${BIN}${BINPOSTFIX} -N $PEERNUM2 -P $((6667+$PEERNUM1)) -Z >a &
    PIDS+=" $!"
  fi

  sleep $DURATION
  kill $PIDS
  $LIMITBW end $IFDEV
  sleep $WAIT

  echo -e "#dummy,src,from,to,measure,value,stringval,channel,time,peergrp,$SCENARIO_HDR\n" >$CSV
  for PORT in `seq 6667 $((6667+$PEERNUM1-1))`; do
    awk '/aboutto/ { print $0",1,"ENVIRON["SCENARIO"] }' stderr.$PORT >>$CSV
  done;
  for PORT in `seq $((6667+$PEERNUM1)) $((6667+$PEERNUM1+$PEERNUM2-1))`; do
    awk '/aboutto/ { print $0",2,"ENVIRON["SCENARIO"] }' stderr.$PORT >>$CSV
  done;

  kill $MPSTAT_PID
  rm -f stderr.[0-9]*

  fi

done
done
done
done
done
done
done
done
done
done
done
done
done
done
done
