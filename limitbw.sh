#!/bin/bash

# Copyright (c) 2010 Luca Abeni
# Copyright (c) 2010 Csaba Kiraly
# This is free software; see gpl-3.0.txt

tc='sudo tc'
PROTOCOL=0x11 #0x11 for UDP; 0x6 for TCP

usage()
{
  echo "Usage: $0 ... see file"
}

limitupdown_init()
{
  ${tc} qdisc del dev $IFDEV root 2>/dev/null
  ${tc} qdisc add dev $IFDEV root handle 1: htb default 1
  ${tc} class add dev $IFDEV parent 1: classid 1:1 htb rate 10000mbit burst 15k
}

limitupdown()
{
  PORT=$1
  UP_SPEED=$5 #mbit/s
  UP_LOSS=$6 #%
  UP_DELAY=$7 #msec

   # limit uplink
  HANDLE=$(($PORT))
  ${tc} class add dev $IFDEV parent 1:1 classid 1:$HANDLE htb rate ${UP_SPEED}mbit burst 15k || exit
  ${tc} qdisc add dev $IFDEV parent 1:$HANDLE handle $HANDLE: netem loss ${UP_LOSS}% delay ${UP_DELAY}msec || exit
  ${tc} filter add dev $IFDEV protocol ip parent 1:0 prio 1 u32 \
    match ip protocol $PROTOCOL 0xff \
    match ip sport $PORT 0xffff \
    flowid 1:$HANDLE || exit
}

[ $# -ge 1 ] || { usage; exit 1; }

COMMAND=$1
shift

if [ "$COMMAND" == "init" ]; then
  [ $# -eq 1 ] || { usage; exit 1; }

  IFDEV=$1
  limitupdown_init

elif [ "$COMMAND" == "peers" ]; then
  [ $# -eq 7 ] || { usage; exit 1; }

  IFDEV=$1
  PORT1=$2
  PORT2=$3
  UPRATE=$4 #mbit/s
  LOSS=$5 #%
  DELAY=$6 #msec

  for PORT in `seq $PORT1 $PORT2`; do
    limitupdown $PORT $UPRATE $LOSS $DELAY
  done;

elif [ "$COMMAND" == "end" ]; then
  [ $# -eq 1 ] || { usage; exit 1; }

  IFDEV=$1

  ${tc} qdisc del dev $IFDEV root 2>/dev/null
else
  usage; exit 1;
fi
