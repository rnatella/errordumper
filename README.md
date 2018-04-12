# ErrorDumper
A tool for tracing and pretty-printing interface data structures produced by C/C++ APIs.

This tool has been developed for the research paper "Analyzing the Effects of Bugs on Software Interfaces", by R. Natella, S. Winter, D. Cotroneo, and N. Suri.

# Overview

The ErrorDumper tool records the data structures that are used by a program when it calls functions of a component (e.g., a library) linked to the program.

The main part of the ErrorDumper tool is reprented by the script "dump.sh". In turn, this script runs the program under analysis using GDB, with a set of Python scripts to pretty-print data structures. The script "dump.sh" is configured to work on programs from the SPEC CPU 2006 benchmark suite, and can be configured to work on other C/C++ programs, by specifying the program name, arguments, and list of functions to be analyzed.

The ErrorDumper tool also includes a scripts ("execute_tests.sh") that can be used to automate a large number of experiments (i.e., executions with a faulty version of the program), and two scripts ("run_fault.sh" and "run_fault_free.sh") to perform individual faulty and fault-free runs.


# Requirements

The tool has been tested and used on the following environment:

- Ubuntu Linux 12.04.5 (with Linux kernel version 3.13 for x86_64)
- Docker version 1.9.1, build a34a1d5
- GNU bash version 4.2.25
- GNU GCC version 4.8.1 


# Compiling and storing the binary executables to analyze

The tool requires that both the fault-free version and the faulty versions of the program are ready to be executed as binary executables. These executables should all be stored in the same directory.

The tool adopts the following structure of directories ("gobmk" is an example program from the SPEC CPU 2006 benchmark suite):

```
|
+- Faults/ -+
|           |
|           +- gobmk/ -+
|           |          |
|           |          +- gobmk_FAULTNAME1.diff
|           |          +- gobmk_FAULTNAME2.diff
|           |          +- gobmk_FAULTNAME3.diff
|           |          +- ...
|           |          +- gobmk_fault_free
|           ...
|
+- Results/ -+
|            |
|            +- gobmk/ -+
|            |          |
|            |          +- FAULTNAME1/
|            |          +- FAULTNAME2/
|            |          +- FAULTNAME3/
|            |          +- ...
|	     ...
|            |
|            +- FaultFree/ -+
|            |              |
|            |              +- gobmk/
|            |              +- ...
|            |
|            +- SporadicRuns/ -+
|                              |
|                              +- gobmk/ -+
|                              |          |
|                              |          +- FAULTNAMEx/
|                              |          +- ...
|                              ...
|
+- Lists/ -+
           |
           +- gobmk-list.txt
           +- ...
```

The tool makes the assumption that the faulty versions are *not* stored as full binary executables. Instead, it looks for the "binary diff" between the fault-free binary and the faulty version. The "binary diff" should be generated using the command "bsdiff". For example:

```
bsdiff $FAULTFREEBIN $FAULTYBIN $FAULTSDIR/$PROGRAM/${PROGRAM}_${FAULTNAME}.diff
```

where:
- $FAULTFREEBIN is the binary executable of the fault-free version
- $FAULTYBIN is the binary executable of a faulty version
- $FAULTSDIR is the folder that stores the binaries and the diffs
- $PROGRAM is a prefix that represents the name of the program under analysis (such as "astar", "bzip2", etc.)
- $FAULTNAME is an unique identifier for the fault (an arbitrary string with an acronym and an incremental ID number, such as "OMIFS_15")

For each experiment, the tool will reverse one binary diff, using the "bspatch" command. For example:

```
bspatch $FAULTFREEBIN $FAULTYBIN $FAULTSDIR/$PROGRAM/${PROGRAM}_${FAULT}.diff
```

Note that the binary executable with fault-free version of the program should be called "${PROGRAM}_fault_free", and should stored in the same folder of the .diff files.


The tool makes the assumption that the faulty and fault-free version of the program are modified and compiled to use the "asan_trace" dynamic library included in the tool (under the sub-folder "dump/asan_trace"), and the AddressSanitizer tool. The program should be modified to include "mcheck.h" and to call "mtrace()" and "muntrace()" respectively at the beginning and at the end of the main(). For example:

```
#include <mcheck.h>

int
main(int argc, char *argv[])
{

  mtrace();

  ... THE PROGRAM ...

  muntrace();

  return 0;
}
```

and by compiling it with the following parameters:

```
CFLAGS+=-fno-omit-frame-pointer -fsanitize=address
LDFLAGS+=-L/path/to/folder/ErrorDumper/dump/asan_trace/ -lasan_trace
```


# Running the tool

Set the following environment variables:

```
# Path to the folder with the faulty
# and fault-free version of the program
# (it will be read from a Docker container)
export FAULTSDIR=/path/to/dir/Faults

# Path to a folder with a list of
# the faulty versions to be analyzed
# (it will be read from a Docker container).
export LISTSDIR=/path/to/dir/Lists

# Create a new directory for storing results
# (it will be written from a Docker container)
export RESULTSDIR=/path/to/dir/Results

chmod ugo+r $FAULTSDIR
chmod ugo+r $LISTSDIR
chmod ugo+rwx $RESULTSDIR

# This variable represents the program to be analyzed
# (possible values:  "astar", "bzip2", "hmmer", "h264ref",
# "libquantum", "mcf", "omnetpp", "sjeng", "gobmk", "xalan")
export PROGRAM="gobmk"
```

Then, build a Docker container with the tool:

```
$ docker build -t errordumper /path/to/folder/ErrorDumper
```

You can run the program under analysis from inside the container, together with the tool, in three alternative ways.

## Single fault-free execution

Run the fault-free version of the program, using the script "run_fault_free.sh", which takes in input the name of the program ($PROGRAM).

```
$ docker run -u nobody -v $FAULTSDIR:/Faults/  -v $RESULTSDIR:/Results/  --rm  errordumper  /workdir/run_fault_free.sh $PROGRAM
```

This script will store the results of the experiments in the folder "$RESULTSDIR/FaultFree/$PROGRAM/".


## Single faulty execution

Run an individual faulty version of the program, using the script "run_fault.sh", which takes in input the name of the program and the name of the faulty version (e.g., "FAULTNAME1").

```
$ docker run -u nobody  -v $FAULTSDIR:/Faults/  -v $RESULTSDIR:/Results/  --rm  errordumper  /workdir/run_fault.sh  $PROGRAM  $FAULTNAME
```

This script will store the results of the experiments in the folder "$RESULTSDIR/SporadicRuns/$PROGRAM/$FAULTNAME/".


## Multiple faulty executions

Run a set of experiments on a list of faulty versions. First, create a file with the list of faulty versions in the folder $LISTSDIR, and call it "${PROGRAM}-list.txt". The file should include one line for each faulty version, and should follow the format "${PROGRAM}_${FAULTNAME}" (as the .diff files in "$FAULTSDIR/$PROGRAM/"). The ".diff" extension after the name of the faulty version is optional. If you want to run every faulty version in the $FAULTSDIR folder, you can write in the file the output of "ls". For example:

```
$ cd $FAULTSDIR/gobmk/

$ ls *.diff > $LISTSDIR/gobmk-list.txt

$ cat $LISTSDIR/gobmk-list.txt
gobmk_FAULTNAME1.diff
gobmk_FAULTNAME2.diff
gobmk_FAULTNAME3.diff
...
```

Then, run the experiments using the "execute_tests.sh" script, which takes in input the name of the program and the file with the list of faulty versions.

```
$ docker run -u nobody -v $FAULTSDIR:/Faults/  -v $RESULTSDIR:/Results/  -v $LISTSDIR:/Lists/  --name $PROGRAM  -d  errordumper  bash -c "/workdir/execute_tests.sh  $PROGRAM  /Lists/${PROGRAM}-list.txt 2>&1 | tee $RESULTSDIR/${PROGRAM}-experiments.log"
```

This script will store the results of each faulty version in a distinct folder under "$RESULTSDIR/$PROGRAM/$FAULTNAME/". Since the execution of tests can take a long time, the above example runs the container in detatched mode, and forwards the outputs to a log file in "$RESULTSDIR".


For each experiment, the tool stores the following output files:

- "dump.txt.bz2": The raw output from GDB, with the dump of every data structure in the scope of a function call site.

- "stdout.txt" and "stderr.txt": The output of the program under analysis on STDOUT and STDERR.

- "dump_tail.txt": The last rows of the raw output from GDB. This file is meant for quickly analyzing the termination status of the experiment (without uncompressing "dump.txt.bz2").

- "dump.tar.bz2": If the program uses very large arrays of data (such as, arrays with thousands of integers), the tool does not store their content from GDB (because of performance reasons), but in separate binary files within this TAR archive. The script "dump.sh" contains a configuration variable to control which the size of arrays that should be dumped in binary files (note that the Docker container should be rebuilt if any script is modified).

