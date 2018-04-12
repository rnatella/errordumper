#!/bin/bash

PROGRAM=$1
RESMOUNT="/Results/"
FAULTMOUNT="/Faults/"


if [ "x$PROGRAM" == "x" ]
then
	echo "Usage: $0 <program name>"
	exit 1
fi


if [ ! -d $RESMOUNT/FaultFree ]
then
	mkdir $RESMOUNT/FaultFree

	if [ $? -ne 0 ]
	then
		echo "Cannot create '$RESMOUNT/FaultFree'"
		exit 1
	fi
fi


if [ ! -d $RESMOUNT/FaultFree/$PROGRAM ]
then
        mkdir $RESMOUNT/FaultFree/$PROGRAM

        if [ $? -ne 0 ]
        then
                echo "Cannot create '$RESMOUNT/FaultFree/$PROGRAM'"
                exit 1
        fi
fi


cp $FAULTMOUNT/$PROGRAM/${PROGRAM}_fault_free  $PROGRAM/$PROGRAM

./dump.sh $PROGRAM  > >(tee /tmp/stdout.txt) 2> >(tee /tmp/stderr.txt >&2)  


mv /tmp/stdout.txt /tmp/stderr.txt  $RESMOUNT/FaultFree/$PROGRAM




cd $PROGRAM



if [ "$PROGRAM" == "h264ref" ]
then
	mv foreman_qcif.264 foreman_test_baseline_leakybucketparam.cfg   $RESMOUNT/FaultFree/$PROGRAM

elif [ "$PROGRAM" == "mcf" ]
then

	mv mcf.out  $RESMOUNT/FaultFree/$PROGRAM

elif [ "$PROGRAM" == "omnetpp" ]
then

	mv omnetpp.sca  $RESMOUNT/FaultFree/$PROGRAM

elif [ "$PROGRAM" == "xalan" ]
then

	mv test.html  $RESMOUNT/FaultFree/$PROGRAM

fi





ls *.dump >/dev/null 2>&1

if [ $? -eq 0 ]
then
	tar jcf dump.tar.bz2  *.dump
	mv dump.tar.bz2  $RESMOUNT/FaultFree/$PROGRAM
fi


bzip2 dump.txt
mv dump.txt.bz2  $RESMOUNT/FaultFree/$PROGRAM




