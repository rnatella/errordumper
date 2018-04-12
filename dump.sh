#!/bin/bash

# --- USAGE ---

# $0 <benchmark name> [working directory path]



# --- CONFIGURATION ---

# WORKDIR: Work directory, in which the program is launched
# TOFILTER: POSIX regex (used by "grep -E") to filter the list of library functions from "nm"
# PROGNAME: The full path of the executable
# PROGARGS: Array of input parameters to the executable program
# BINARYDUMP: Threshold for avoiding pretty-pritting of very large arrays
# MALLOC_TRACE: Temporary file created to record heap memory allocations
# DUMP_FILE: Output file generated by the GDB tracer

export WORKDIR=
export TOFILTER=
export PROGNAME=
export PROGARGS=
export BINARYDUMP=




case "$1" in

# --- BZIP2 ---
"bzip2")

WORKDIR=`pwd`/bzip2/
PROGNAME=bzip2
PROGARGS=("dryer.jpg" "2")
TOFILTER="\b(BZ2_bzCompress|BZ2_bzCompressInit|BZ2_bzCompressEnd|BZ2_bzDecompress|BZ2_bzDecompressInit|BZ2_bzDecompressEnd)\b"
BINARYDUMP=0
;;



# --- H264REF ---
"h264ref")

WORKDIR=`pwd`/h264ref/
PROGNAME=h264ref
PROGARGS=("-d" "foreman_test_encoder_baseline.cfg")
TOFILTER="\b(AllocNalPayloadBuffer|Clear_Motion_Search_Module|Configure|DefineThreshold|FmoUninit|FreeNalPayloadBuffer|FreeParameterSets|GenerateParameterSets|Init_Motion_Search_Module|Init_QMatrix|Init_QOffsetMatrix|PatchInputNoFrames|RandomIntraUninit|calc_buffer|clear_gop_structure|clear_rdopt|create_context_memory|create_pyramid|encode_enhancement_layer|encode_one_frame|flush_dpb|free_colocated|free_context_memory|free_dpb|free_global_buffers|free_img|free_picture|information_init|init_dpb|init_global_buffers|init_gop_structure|init_img|init_out_buffer|init_poc|init_rdopt|interpret_gop_structure|malloc_picture|process_2nd_IGOP|rc_init_GOP|rc_init_seq|report|report_frame_statistic|report_stats_on_error|start_sequence|terminate_sequence|uninit_out_buffer)\b"
BINARYDUMP=1024
;;



# --- LIBQUANTUM ---
"libquantum")

WORKDIR=`pwd`/libquantum/
PROGNAME=libquantum
PROGARGS=("33" "5")
TOFILTER="\b(quantum_addscratch|quantum_bmeasure|quantum_cnot|quantum_delete_qureg|quantum_exp_mod_n|quantum_frac_approx|quantum_gcd|quantum_getwidth|quantum_hadamard|quantum_ipow|quantum_measure|quantum_new_qureg|quantum_qft)\b"
BINARYDUMP=1024
;;



# --- HMMER ---
"hmmer")

WORKDIR=`pwd`/hmmer/
PROGNAME=hmmer
PROGARGS=("--fixed" "0" "--mean" "325" "--num" "500" "--sd" "200" "--seed" "0" "bombesin.hmm")
TOFILTER="\b(SetAutocuts|HMMFileClose|HMMFileRead|HMMFileRewind|P7Logoddsify|P7Viterbi|P7ViterbiSize|PValue|TraceScoreCorrection|P7PrintTrace|PostprocessSignificantHit|FreePlan7)\b"
BINARYDUMP=1024
;;



# --- MCF ---
"mcf")

WORKDIR=`pwd`/mcf/
PROGNAME=mcf
PROGARGS=("inp.in")
TOFILTER="\b(flow_cost|price_out_impl|primal_net_simplex|suspend_impl|read_min|primal_start_artificial|write_circulations)\b"
BINARYDUMP=1024
;;



# --- GOBMK ---
"gobmk")

WORKDIR=`pwd`/gobmk/
PROGNAME=gobmk
PROGARGS=("--quiet" "--mode" "gtp")
STDIN_FILE="dniwog.tst"
TOFILTER="\b(gnugo_add_stone|gnugo_attack|gnugo_clear_board|gnugo_estimate_score|gnugo_examine_position|gnugo_find_defense|gnugo_genmove|gnugo_get_board|gnugo_get_boardsize|gnugo_get_komi|gnugo_get_move_number|gnugo_is_legal|gnugo_is_pass|gnugo_is_suicide|gnugo_placehand|gnugo_play_move|gnugo_play_sgfnode|gnugo_play_sgftree|gnugo_recordboard|gnugo_remove_stone|gnugo_undo_move|gnugo_who_wins|genmove_conservative|genmove)\b"
BINARYDUMP=0
;;



# --- SJENG ---
"sjeng")

WORKDIR=`pwd`/sjeng/
PROGNAME=sjeng
PROGARGS=("test.txt")
TOFILTER="\b(BegForPartner|CheckBadFlow|HandlePartner|HandlePtell|ProcessHoldings|PutPiece|ResetHandValue|check_phase|clear_tt|comp_to_coord|display_board|eval|free_ecache|free_hash|init_game|initialize_hash|initialize_zobrist|is_draw|is_move|make|perft|proofnumbersearch|rdifftime|read_rcfile|reset_board|reset_ecache|reset_piece_square|search|setup_epd_line|start_up|think|toggle_bool|unmake|verify_coord)\b"
BINARYDUMP=0
;;




# --- OMNETPP ---
"omnetpp")

WORKDIR=`pwd`/omnetpp/
PROGNAME=omnetpp
PROGARGS=("omnetpp.ini")
TOFILTER="\b(cSimpleModule::|cChannel::|cMessage::|cPar::|cGate::)\b"
BINARYDUMP=0
;;



# --- ASTAR ---
"astar")

WORKDIR=`pwd`/astar/
PROGNAME=astar
PROGARGS=("lake.cfg")
TOFILTER="\b(regwayobj::|regmngobj::|wayobj::|way2obj::)\b"
BINARYDUMP=1024
;;



# --- XALAN ---
"xalan")

WORKDIR=`pwd`/xalan/
PROGNAME=xalan
PROGARGS=("-t" "-v" "-o" "test.html" "test.xml" "xalanc.xsl")
TOFILTER="\b(XMLPlatformUtils::|XalanTransformer::|Params::)\b"
BINARYDUMP=0
;;


*)

echo "Usage: $0 <program name> [work dir path]"
exit 1
;;

esac




if [ "x$2" != "x" ]
then

	if [ ! -d $2 ]
	then

		echo
		echo "Dir '$2' not found"
		echo
		echo "Usage: $0 <program name> [work dir path]"
		echo

		exit 1
	fi


	WORKDIR=`realpath $2`
fi





export DUMP_FILE=$WORKDIR"/dump.txt"

export MALLOC_TRACE=$WORKDIR"/mtrace.out"




# ---------------------



# The directory of this script

export SCRIPTDIR=`cd $(dirname $0); pwd`

cd $SCRIPTDIR








# Clean up temporary files

rm -f $DUMP_FILE
rm -f $WORKDIR/breakpoints.gdb
rm -f $MALLOC_TRACE


touch $MALLOC_TRACE



# Check mtrace on the program

nm -C $WORKDIR/$PROGNAME | grep -E "\bmtrace\b" >/dev/null

if [ $? -ne 0 ]
then
	echo "Cannot find mtrace() on $WORKDIR/$PROGNAME"
	exit 1
fi




# Set breakpoints

echo "set height 0" >> $WORKDIR/breakpoints.gdb
echo "set print pretty on" >> $WORKDIR/breakpoints.gdb
echo "set logging file ${DUMP_FILE}" >> $WORKDIR/breakpoints.gdb
echo "set logging redirect on" >> $WORKDIR/breakpoints.gdb
echo "set logging on" >> $WORKDIR/breakpoints.gdb
echo "python execfile('$SCRIPTDIR/dump/GenericPrinter.py')" >> $WORKDIR/breakpoints.gdb
echo "source $SCRIPTDIR/dump/AutoDump.py" >> $WORKDIR/breakpoints.gdb
echo "set print elements 0" >> $WORKDIR/breakpoints.gdb
#echo "set print symbol-filename off" >> $WORKDIR/breakpoints.gdb
echo "set print object on" >> $WORKDIR/breakpoints.gdb
echo "set output-radix 16" >> $WORKDIR/breakpoints.gdb
echo "set print repeats unlimited" >> $WORKDIR/breakpoints.gdb
echo "set verbose off" >> $WORKDIR/breakpoints.gdb
#gdb.execute('handle SIGTRAP nostop')




cat << 'EOF' >> $WORKDIR/breakpoints.gdb

set $i = 0

define dump_call

echo ### Breakpoint \ 
set $i = $i+1
output/u $i
echo \ : \ 
python print gdb.selected_frame().name()
echo \n

init_stack

disable
python prev_sal = str(gdb.selected_frame().older().find_sal())
finish
python if( prev_sal == str(gdb.selected_frame().find_sal()) ): gdb.execute('next')
python stack_end_address = long(str(gdb.selected_frame().read_register('rsp')).split()[0],16)
enable

echo ---------\n

python print '\nSTACK: ['+hex(stack_end_address)+', '+hex(stack_begin_address)+']\n'
python address_dict={}
update_mtrace
eval "python heap_dump(%d)", $i
python printVariables()

echo ---------\n

continue
end



define update_mtrace
set $foo = muntrace()
python update_mtrace()
set $foo = mtrace()
end


define init_stack
python stack=long(str(gdb.selected_frame().read_register('rsp')).split()[0],16); off=0xf000; gdb.selected_inferior().write_memory(stack-off, '\xbe' * off, off)
end


break *&main
commands
silent
init_stack
continue
end


break main
commands
python stack_begin_address = long(str(gdb.selected_frame().read_register('rbp')).split()[0],16)+0x1000

python import re; sec=gdb.execute('maint info section .data', to_string=True);  m=re.search( r'(0x[0-9a-fA-F]+)->(0x[0-9a-fA-F]+)', sec); data_begin_address=long(m.group(1),16); data_end_address = long(m.group(2),16)
python import re; sec=gdb.execute('maint info section .rodata', to_string=True);  m=re.search( r'(0x[0-9a-fA-F]+)->(0x[0-9a-fA-F]+)', sec); rodata_begin_address=long(m.group(1),16); rodata_end_address = long(m.group(2),16)
python import re; sec=gdb.execute('maint info section .bss', to_string=True);  m=re.search( r'(0x[0-9a-fA-F]+)->(0x[0-9a-fA-F]+)', sec); bss_begin_address=long(m.group(1),16); bss_end_address = long(m.group(2),16)
python import re; sec=gdb.execute('maint info section .text', to_string=True);  m=re.search( r'(0x[0-9a-fA-F]+)->(0x[0-9a-fA-F]+)', sec); text_begin_address=long(m.group(1),16); text_end_address = long(m.group(2),16)

set $foo = mtrace()
continue
end



EOF



nm -C $WORKDIR/$PROGNAME | awk '($2=="T" || $2=="t")' | grep -E "$TOFILTER" | while read -r STRING
do

	FUNC_ADDR=`echo $STRING | awk '{print "0x"$1}'`
	FUNC_SIGN=`echo $STRING | perl -p -e 's/^[0-9a-z]*\s*T\s//'`

	echo "# ${FUNC_SIGN}" >> $WORKDIR/breakpoints.gdb
	echo "break * ${FUNC_ADDR}" >> $WORKDIR/breakpoints.gdb

	echo "commands" >> $WORKDIR/breakpoints.gdb
	echo "silent" >> $WORKDIR/breakpoints.gdb
	echo "dump_call" >> $WORKDIR/breakpoints.gdb

	echo "end" >> $WORKDIR/breakpoints.gdb
	echo >> $WORKDIR/breakpoints.gdb

done


echo  >> $WORKDIR/breakpoints.gdb
echo 'echo \n--- START ---\n' >> $WORKDIR/breakpoints.gdb
echo >> $WORKDIR/breakpoints.gdb


echo 'run' >> $WORKDIR/breakpoints.gdb



# --- ADDRESS SANITIZER ---

export ASAN_SYMBOLIZER_PATH=/usr/bin/llvm-symbolizer-3.4
export ASAN_OPTIONS=symbolize=1:alloc_dealloc_mismatch=0




# --- MTRACE ---

export LD_LIBRARY_PATH=$SCRIPTDIR/dump/asan_trace:${LD_LIBRARY_PATH}




# --- RUN PROGRAM + GDB ---

cd $WORKDIR


if [ "x${STDIN_FILE}" != "x" ]
then

	gdb -batch-silent -x $WORKDIR/breakpoints.gdb --args $WORKDIR/$PROGNAME ${PROGARGS[*]} < ${STDIN_FILE}
else

	gdb -batch-silent -x $WORKDIR/breakpoints.gdb --args $WORKDIR/$PROGNAME ${PROGARGS[*]}
fi

