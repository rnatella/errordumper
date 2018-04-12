#include <dlfcn.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <execinfo.h>
#include <bfd.h>
#include <link.h>

//#define setvbuf(s, b, f, l) _IO_setvbuf (s, b, f, l)
//#define fwrite(buf, size, count, fp) _IO_fwrite (buf, size, count, fp)

#define TRACE_BUFFER_SIZE 512

typedef unsigned long uptr;

static FILE *mallstream;
static const char mallenv[] = "MALLOC_TRACE";
static char *malloc_trace_buffer;





void * internal_memset (void * dest, register int val, register size_t len)
{
  register unsigned char *ptr = (unsigned char*)dest;
  while (len-- > 0)
    *ptr++ = val;
  return dest;
}




int recursive = 0;

void * asan_malloc_func_ptr;


#ifdef __cplusplus
extern "C" {
#endif

void __asan_malloc_hook(void *ptr, uptr size) {

	if(recursive)
		return;

	recursive = 1;

	if(mallstream) {

		void *bt[5];
		int bt_size;
		int i;

		bt_size = backtrace(bt, 5);

		fprintf (mallstream, "@ %p/%p + %p %#lx\n", bt[3], bt[4], ptr, (unsigned long int) size);
	}


	if(!asan_malloc_func_ptr) {

		void *bt[1024];
		int bt_size;
		char **bt_syms;
		int i;

		bt_size = backtrace(bt, 1024);
		bt_syms = backtrace_symbols(bt, bt_size);


		for (i = 1; i < bt_size; i++) {

			//printf("bt syms %d: %s\n [%p]", i, bt_syms[i], bt[i]);

			if(strlen(bt_syms[i]) && strstr(bt_syms[i], "asan11asan_malloc")) {

				asan_malloc_func_ptr = bt[i];
			}
		}
	}


	if(asan_malloc_func_ptr &&  asan_malloc_func_ptr == __builtin_return_address(0)) {

		internal_memset(ptr, 0xbe, size);
	}

	recursive = 0;
}

void __asan_free_hook(void *ptr) {

	if(mallstream)
		fprintf (mallstream, "@ @ - %p\n", ptr);
}

#ifdef __cplusplus
} // extern "C"
#endif










void
mtrace (void)
{
  char *mallfile;

  /* Don't panic if we're called more than once.  */
  if (mallstream != NULL)
    return;

#ifdef _LIBC
  /* When compiling the GNU libc we use the secure getenv function
     which prevents the misuse in case of SUID or SGID enabled
     programs.  */
  mallfile = __libc_secure_getenv (mallenv);
#else
  mallfile = getenv (mallenv);
#endif
  if (mallfile != NULL)
    {
      char *mtb = (char *)malloc (TRACE_BUFFER_SIZE);
      if (mtb == NULL)
        return;

      mallstream = fopen (mallfile != NULL ? mallfile : "/dev/null", "wce");
      if (mallstream != NULL)
        {
#ifndef __ASSUME_O_CLOEXEC
          /* Make sure we close the file descriptor on exec.  */
          int flags = fcntl (fileno (mallstream), F_GETFD, 0);
          if (flags >= 0)
            {
              flags |= FD_CLOEXEC;
              fcntl (fileno (mallstream), F_SETFD, flags);
            }
#endif
          /* Be sure it doesn't malloc its buffer!  */
          malloc_trace_buffer = mtb;
          setvbuf (mallstream, malloc_trace_buffer, _IOFBF, TRACE_BUFFER_SIZE);
          fprintf (mallstream, "= Start\n");
        }
      else
        free (mtb);
    }
}

void
muntrace (void)
{
  if (mallstream == NULL)
    return;

  /* Do the reverse of what done in mtrace: first reset the hooks and
     MALLSTREAM, and only after that write the trailer and close the
     file.  */
  FILE *f = mallstream;
  mallstream = NULL;

  fprintf (f, "= End\n");
  fclose (f);
}
