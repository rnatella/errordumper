asan_trace.so: asan_trace.o
	g++ -g -O0 -shared -Wl,-soname,libasan_trace.so -o libasan_trace.so asan_trace.o

asan_trace.o: asan_trace.c
	g++ -g -O0 -fPIC -o asan_trace.o -c asan_trace.c
