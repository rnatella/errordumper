#!/bin/bash

#-------------------------------------USER CONFIGURATION---------------------------------------------


# FAULTYDIR: the path of the directory in which the faulty executables are stored

# SAVEDIR: the path of the directory in which the test results will be stored

# BINARY: the path of the binary executable which has to be replaced by a faulty executable

# TEST: the command to be executed to run a test (e.g., "./run_workload.sh param1 param2")

# FAULTLIST: the path of the file with the list of faults which have been "injected". Each line
# of this file is the identifier of an individual faulty version (i.e., the name of the binary faulty
# file without the "programname_" prefix and the ".diff" suffix)

# TIMEOUT: it is the maximum allowed execution time for an experiment (in seconds)

export FAULTYDIR
export SAVEDIR
export BINARY
export TEST
export FAULTLIST
export TIMEOUT
export OUTPUTS


case "$1" in

# --- ASTAR ---
"astar")
BINARY="astar"
FAULTYDIR="/Faults/$BINARY"
SAVEDIR="/Results/$BINARY"
WORKDIR="/workdir/$BINARY"
TEST="/workdir/dump.sh $BINARY $WORKDIR"
FAULTLIST="/Lists/$BINARY-list.txt"
OUTPUTS=()
TIMEOUT=180
;;


# --- BZIP2 ---
"bzip2")
BINARY="bzip2"
FAULTYDIR="/Faults/$BINARY"
SAVEDIR="/Results/$BINARY"
WORKDIR="/workdir/$BINARY"
TEST="/workdir/dump.sh $BINARY $WORKDIR"
FAULTLIST="/Lists/$BINARY-list.txt"
OUTPUTS=()
TIMEOUT=180
;;


# --- GOBMK ---
"gobmk")
BINARY="gobmk"
FAULTYDIR="/Faults/$BINARY"
SAVEDIR="/Results/$BINARY"
WORKDIR="/workdir/$BINARY"
TEST="/workdir/dump.sh $BINARY $WORKDIR"
FAULTLIST="/Lists/$BINARY-list.txt"
OUTPUTS=()
TIMEOUT=240
;;


# --- H264REF ---
"h264ref")
BINARY="h264ref"
FAULTYDIR="/Faults/$BINARY"
SAVEDIR="/Results/$BINARY"
WORKDIR="/workdir/$BINARY"
TEST="/workdir/dump.sh $BINARY $WORKDIR"
FAULTLIST="/Lists/$BINARY-list.txt"
OUTPUTS=("foreman_qcif.264" "foreman_test_baseline_leakybucketparam.cfg")
TIMEOUT=65
;;


# --- HMMER ---
"hmmer")
BINARY="hmmer"
FAULTYDIR="/Faults/$BINARY"
SAVEDIR="/Results/$BINARY"
WORKDIR="/workdir/$BINARY"
TEST="/workdir/dump.sh $BINARY $WORKDIR"
FAULTLIST="/Lists/$BINARY-list.txt"
OUTPUTS=()
TIMEOUT=70
;;


# --- LIBQUANTUM ---
"libquantum")
BINARY="libquantum"
FAULTYDIR="/Faults/$BINARY"
SAVEDIR="/Results/$BINARY"
WORKDIR="/workdir/$BINARY"
TEST="/workdir/dump.sh $BINARY $WORKDIR"
FAULTLIST="/Lists/$BINARY-list.txt"
OUTPUTS=()
TIMEOUT=10
;;


# --- MCF ---
"mcf")
BINARY="mcf"
FAULTYDIR="/Faults/$BINARY"
SAVEDIR="/Results/$BINARY"
WORKDIR="/workdir/$BINARY"
TEST="/workdir/dump.sh $BINARY $WORKDIR"
FAULTLIST="/Lists/$BINARY-list.txt"
OUTPUTS=("mcf.out")
TIMEOUT=90
;;


# --- OMNETPP ---
"omnetpp")
BINARY="omnetpp"
FAULTYDIR="/Faults/$BINARY"
SAVEDIR="/Results/$BINARY"
WORKDIR="/workdir/$BINARY"
TEST="/workdir/dump.sh $BINARY $WORKDIR"
FAULTLIST="/Lists/$BINARY-list.txt"
OUTPUTS=("omnetpp.sca")
TIMEOUT=180
;;


# --- SJENG ---
"sjeng")
BINARY="sjeng"
FAULTYDIR="/Faults/$BINARY"
SAVEDIR="/Results/$BINARY"
WORKDIR="/workdir/$BINARY"
TEST="/workdir/dump.sh $BINARY $WORKDIR"
FAULTLIST="/Lists/$BINARY-list.txt"
OUTPUTS=()
TIMEOUT=60
;;


# --- XALAN ---
"xalan")
BINARY="xalan"
FAULTYDIR="/Faults/$BINARY"
SAVEDIR="/Results/$BINARY"
WORKDIR="/workdir/$BINARY"
TEST="/workdir/dump.sh $BINARY $WORKDIR"
FAULTLIST="/Lists/$BINARY-list.txt"
#OUTPUTS=()
OUTPUTS=("test.html")
TIMEOUT=360
;;


*)

echo "Usage: $0 <program name> [fault list]"
exit 1
;;

esac



if [ "x$2" != "x" ]
then
	if [ -f $2 ]
	then
		FAULTLIST=$2
	else
		echo "Fault list '$2' not found"
		exit 1
	fi
fi





# The "handle_timeout()" function has to be adapted to kill the test after a timeout is expired

handle_timeout() {

	echo
	echo "----------- Test Timeout (Forced exit) ------------"
	echo

	while [ 1 ]
	do

		ps aux | grep -P "gdb" | grep -v "\.sh" | grep -v grep | awk '{print $2}' | xargs rkill -9 > /dev/null 2>&1


		if [ $? -ne 0 ]
		then

			ZOMBIES=`ps aux | grep -P "gdb" | grep -v "\.sh" | grep -v grep | wc -l`

			if [ $ZOMBIES -eq 0 ]
			then
				echo "No process to kill"
				return 0
			else
				echo "Kill failed; retrying..."
				sleep 5
			fi

		else
			return 0
		fi

		sleep 1

	done

}




# The "clear_testbed()" function has to be adapted to clear the testbed before an experiment
# (e.g., remove old log file, deallocate stale resources)
clear_testbed() {

	sync

	while [ 1 ]
	do

		ps aux | grep "gdb" | grep -v "\.sh" | grep -v grep | awk '{print $2}' | xargs rkill -9 >/dev/null 2>&1


		if [ $? -ne 0 ]
		then

			ZOMBIES=`ps aux | grep -P "gdb" | grep -v "\.sh" | grep -v grep | wc -l`

			if [ $ZOMBIES -eq 0 ]
			then
				echo "No process to kill"
				break
			else
				echo "Kill failed; retrying..."
				sleep 5
			fi

		else
			break
		fi

		sleep 1

	done


	rm -f $WORKDIR/mtrace.out
	rm -f $WORKDIR/breakpoints.gdb
	rm -f $WORKDIR/dump.txt
	/bin/ls $WORKDIR/ | grep ".dump" | xargs  rm -f

	rm -f $STDOUT_FILE
	rm -f $STDERR_FILE
	rm -f $KILLED_FILE

}


# The "save_results()" function has to be adapted to clear the testbed before an experiment
# (e.g., remove old log file, deallocate stale resources)
# PARAMETERS:
# - $1 is the directory in which to store the results
# - $2 is the file in which the stdout of the test has been saved
# - $3 is the file in which the stderr of the test has been saved
# - $4 is the file which is (potentially) created if the test has exceeded the timeout
save_results() {


	RESULTDIR=$1
	STDOUT=$2
	STDERR=$3
	KILLED=$4

	TESTNAME=`basename $RESULTDIR`

	echo "Saving results from test $TESTNAME"


	if [ "x$KILLED" != "x" ]
	then
		if [ -e $KILLED ]
		then
			mv $KILLED $RESULTDIR
		fi
	fi



	mv $STDOUT $RESULTDIR
	mv $STDERR $RESULTDIR



	cd $WORKDIR

	for OUTFILE in "${OUTPUTS[@]}"
	do
		if [ -e $OUTFILE ]
		then
			mv $OUTFILE $RESULTDIR
		fi
	done



	ls -U | grep -l ".dump" 1>/dev/null 2>&1 

	if [ $? -eq 0 ]
	then
		tar jcf $RESULTDIR/dump.tar.bz2  *.dump
	fi

	ls -U | grep ".dump" | xargs rm -f



	if [ -e dump.txt ]
	then
		tail -n 15 dump.txt > dump_tail.txt
		mv dump_tail.txt $RESULTDIR

		bzip2 dump.txt
		mv dump.txt.bz2 $RESULTDIR
	fi

	cd -

}








#----------------------------------------------------------------------------------------------------


if [ "x$SAVEDIR" == "x" ]
then
echo 'Please insert a path in $SAVEDIR'
exit 1
fi


if [ ! -e $SAVEDIR ]
then
mkdir -p $SAVEDIR

if [ $? -ne 0 ]
then
echo "Error creating directory $SAVEDIR"
exit 1
fi
fi


if [ "x$FAULTYDIR" == "x" ]
then
echo 'Please insert a path in $FAULTYDIR'
exit 1
fi


if [ ! -d $FAULTYDIR ]
then
echo "Directory $FAULTYDIR not found (or it is not a directory)"
exit 1
fi


if [ "x$FAULTLIST" == "x" ]
then
echo 'Please insert a path in $FAULTLIST'
exit 1
fi


if [ ! -e $FAULTLIST ]
then
echo "Fault list '$FAULTLIST' not found"
exit 1
fi


if [ "x$TEST" == "x" ]
then
echo 'Please insert a command in $TEST'
exit 1
fi






PROGDIR=`cd $(dirname $0); pwd`

cd $PROGDIR





STDOUT_FILE=/tmp/stdout.txt
STDERR_FILE=/tmp/stderr.txt
KILLED_FILE=/tmp/killed.txt




# BINARYNAME is the name of the binary file with a software fault
# (only the file name, without the path)
BINARYNAME=`basename $BINARY`



# FAULTFREEBIN is the path of the fault-free version of the program
FAULTFREEBIN="$FAULTYDIR/${BINARYNAME}_fault_free"



echo "Start campaign: "`date`



rm -f /tmp/__freeze.txt



echo "Generating test list..."


# List of experiments already executed
ls $SAVEDIR | sort > /tmp/__faults_done.txt

# List of experiments requested by the user
perl -n -l -e 'if(m|(?:'${BINARYNAME}'_)?([^/]+?)(\.[a-zA-Z]+)?$|) { print $1 }' $FAULTLIST | sort > /tmp/__faults_all.txt

# Get the experiments not already executed
join -v 1 /tmp/__faults_all.txt /tmp/__faults_done.txt > /tmp/__faults_todo.txt










I=0

while [ 1 ]
do

		# Backdoor for pausing tests
		if [ -e /tmp/__freeze.txt ]
		then
			echo "Tests are paused"
			sleep 1000000000
		fi


		if [ ! -e /tmp/__faults_todo.txt ]
		then
			echo "Test list not found"
			sleep 1000000000
			continue
		fi


		I=$(($I+1))


		FAULT=`awk 'NR=='$I' {print $0}' /tmp/__faults_todo.txt`

                if [ $? -ne 0 ] || [ "x$FAULT" == "x" ]
                then
                        echo "All experiments have been executed"
			break
                fi


		# Skip the experiment if the faulty binary does not exist
		# if [ ! -e $FAULTYDIR/$BINARYNAME_$FAULT ]				# no compression
		if [ ! -e $FAULTYDIR/"${BINARYNAME}_${FAULT}.diff" ] 	# with compression
		then
			echo "Fault not found, skipping: $FAULT"
			continue
		fi


		# Skip the experiment if is has already been executed and the
		# results have been stored
		if [ -e $SAVEDIR/$FAULT ]
		then
			echo "Test already done: $FAULT"
			continue
		fi


		# Stop if there is no available space
		FREE_SPACE_KB=`df $SAVEDIR | perl -a -n -l -e 'if(++$NR>1) { print $F[$#F-2] }'`
		if [ $FREE_SPACE_KB -lt 10000 ]
		then
			echo "Low free disk space in $SAVEDIR !"
			sleep 1000000000
		fi



		echo
		echo "---------------------------------------------------------------"
		echo

		echo "Running test: $FAULT"
		date


		# Clear the testing environment

		echo "Clearing the testbed"

		clear_testbed
		rm -f $STDOUT_FILE $STDERR_FILE $KILLED_FILE


		echo "Installing faulty version"

		rm -f $WORKDIR/$BINARY

		# uncompress the executable of the current test
		# $ bspatch oldfile newfile patchfile
		#bspatch $FAULTFREEBIN $WORKDIR/$BINARY $FAULTYDIR/"${BINARYNAME}_${FAULT}.diff"
		bspatch $FAULTFREEBIN $SAVEDIR/"${BINARYNAME}_${FAULT}" $FAULTYDIR/"${BINARYNAME}_${FAULT}.diff"

		if [ $? -ne 0 ]
		then
			echo "Unable to install faulty executable"
			sleep 1000000000
		fi

		chmod +x $SAVEDIR/"${BINARYNAME}_${FAULT}"
		sync
		mv $SAVEDIR/"${BINARYNAME}_${FAULT}" $WORKDIR/$BINARY

		if [ $? -ne 0 ]
		then
			echo "Unable to copy faulty executable"
			sleep 1000000000
		fi




		# Start the test and a watchdog timer:
		# - launch $TEST as a background process ("&")
		# - register a signal handler ("handler_timeout")
		# - launch a command that sends a signal to this script after a timeout ("(sleep $TIMEOUT ; kill -SIGUSR1 $PID)") as a background process
		# - wait() for the $TEST program; wait() fails ("$? -ne 0") if this script is awakened by a signal

		echo "Starting Test"

		$TEST > >(perl -n -e 'BEGIN{$NR=0} next if($NR++>10000); print' |tee ${STDOUT_FILE}) 2> >(tee ${STDERR_FILE} >&2) &


		CMDPID=$!
		export CMDPID

		# PID: the pid of this script
		export PID=$$

		trap handle_timeout SIGUSR1

		# Starting timer in subshell; it sends a SIGUSR1 to the father if it timeouts
		export TIMEOUT
		(sleep $TIMEOUT ; kill -SIGUSR1 $PID) &
		TPID=$!

		# wait for all processes to finish
		wait ${CMDPID}

		if [ $? -ne 0 ]
		then
			# This script has been awakened by a signal

			# Let the program be killed by the signal handler
			sleep 3

			# An empty file "killed.txt" is created to remember that the timeout expired
			touch $KILLED_FILE
		else
			# kill timer
			kill $TPID
		fi



		echo "Saving results"

		mkdir -p $SAVEDIR/$FAULT

		# Call user-defined routine for saving results
		save_results "$SAVEDIR/$FAULT" "${STDOUT_FILE}" "${STDERR_FILE}" "${KILLED_FILE}"

done


echo "End campaign: "`date`

rm -f /tmp/__faults_*.txt

