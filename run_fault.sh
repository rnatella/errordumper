#!/bin/bash

PROGRAM=$1
FAULT=$2
RESMOUNT="/Results/"
FAULTMOUNT="/Faults/"


if [ "x$PROGRAM" == "x" ] || [ ! -e "./$PROGRAM/" ]
then
	echo "Usage: $0 <program name> <fault>"
	exit 1
fi


if [ "x$FAULT" == "x" ] || [ ! -e $FAULTMOUNT/$PROGRAM/${PROGRAM}_${FAULT}.diff ]
then
	echo "Usage: $0 <program name> <fault>"
	exit 1
fi


if [ ! -d $RESMOUNT/SporadicRuns ]
then
	mkdir $RESMOUNT/SporadicRuns

	if [ $? -ne 0 ]
	then
		echo "Cannot create '$RESMOUNT/SporadicRuns'"
		exit 1
	fi
fi


if [ ! -d $RESMOUNT/SporadicRuns/$PROGRAM ]
then
        mkdir $RESMOUNT/SporadicRuns/$PROGRAM

        if [ $? -ne 0 ]
        then
                echo "Cannot create '$RESMOUNT/SporadicRuns/$PROGRAM'"
                exit 1
        fi
fi


if [ ! -d $RESMOUNT/SporadicRuns/$PROGRAM/$FAULT ]
then
	mkdir $RESMOUNT/SporadicRuns/$PROGRAM/$FAULT

	if [ $? -ne 0 ]
	then
		echo "Cannot create '$RESMOUNT/SporadicRuns/$PROGRAM/$FAULT'"
		exit 1
	fi
else

	rm $RESMOUNT/SporadicRuns/$PROGRAM/$FAULT/*
fi




bspatch $FAULTMOUNT/$PROGRAM/${PROGRAM}_fault_free $PROGRAM/$PROGRAM $FAULTMOUNT/$PROGRAM/${PROGRAM}_${FAULT}.diff

chmod +x $PROGRAM/$PROGRAM

./dump.sh $PROGRAM  > >(tee /tmp/stdout.txt) 2> >(tee /tmp/stderr.txt >&2)  


mv /tmp/stdout.txt /tmp/stderr.txt  $RESMOUNT/SporadicRuns/$PROGRAM/$FAULT




cd $PROGRAM



if [ "$PROGRAM" == "h264ref" ]
then
	mv foreman_qcif.264 foreman_test_baseline_leakybucketparam.cfg   $RESMOUNT/SporadicRuns/$PROGRAM/$FAULT

elif [ "$PROGRAM" == "mcf" ]
then

	mv mcf.out  $RESMOUNT/SporadicRuns/$PROGRAM/$FAULT

elif [ "$PROGRAM" == "omnetpp" ]
then

	mv omnetpp.sca  $RESMOUNT/SporadicRuns/$PROGRAM/$FAULT

elif [ "$PROGRAM" == "xalan" ]
then

	mv test.html  $RESMOUNT/SporadicRuns/$PROGRAM/$FAULT

fi





ls |grep ".dump" >/dev/null 2>&1

if [ $? -eq 0 ]
then
	tar jcf dump.tar.bz2  *.dump
	mv dump.tar.bz2  $RESMOUNT/SporadicRuns/$PROGRAM/$FAULT
fi


bzip2 dump.txt
mv dump.txt.bz2  $RESMOUNT/SporadicRuns/$PROGRAM/$FAULT




