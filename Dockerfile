# Set the base image to Ubuntu
FROM ubuntu:12.04


### INSTALLING DEPENDENCIES ###

ADD ubuntu-toolchain-r-test-precise.list  /etc/apt/sources.list.d/

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1E9377A2BA9EF27F

RUN apt-get update && apt-get install -y \
make \
patch \
sudo \
build-essential \
bspatch \
libc6-dbg \
libncurses5-dev \
texinfo \
python-dev 



### COMPILING AND INSTALLING GDB ###

#ADD gdb-7.12.tar.gz  /usr/src/
ADD https://ftp.gnu.org/gnu/gdb/gdb-7.12.tar.gz /usr/src/gdb-7.12.tar.gz
ADD strip_typedef_gdb-7.12.patch  /usr/src/
ADD cpp_virtual_method_pointers-7.12.patch  /usr/src/

WORKDIR /usr/src/

RUN tar zxf /usr/src/gdb-7.12.tar.gz  && \
patch -f -p0 < strip_typedef_gdb-7.12.patch  && \
patch -f -p0 < cpp_virtual_method_pointers-7.12.patch

WORKDIR /usr/src/gdb-7.12/

RUN mkdir -p /opt/gdb &&  ./configure  x86_64-linux-gnu --prefix=/opt/gdb/ && make && make install
ENV PATH /opt/gdb/bin:$PATH



### INSTALL DEPENDENCIES USED BY ERROR PROFILING TOOLS

RUN apt-get update && apt-get install -y \
realpath \
pslist \
lsof \
gcc-4.8-base \
llvm-3.4 \
libasan0 \
binutils \
python-pip

#...pip install intervaltree

ADD intervaltree-2.1.0.tar.gz /usr/src/
ADD sortedcontainers-1.5.9.tar.gz /usr/src/

WORKDIR /usr/src/sortedcontainers-1.5.9/
RUN python setup.py install

WORKDIR /usr/src/intervaltree-2.1.0/
RUN python setup.py install




### MOUNT POINTS FOR EXTERNAL VOLUMES ###

RUN mkdir -p /Faults
RUN mkdir -p /Results
RUN mkdir -p /Lists




### COPY TEST SCRIPTS AND FILES ###

RUN mkdir -p /workdir

ADD dump.sh /workdir/
ADD dump /workdir/dump

ADD astar /workdir/astar
ADD bzip2 /workdir/bzip2
ADD gobmk /workdir/gobmk
ADD h264ref /workdir/h264ref
ADD hmmer /workdir/hmmer
ADD libquantum /workdir/libquantum
ADD mcf /workdir/mcf
ADD omnetpp /workdir/omnetpp
ADD sjeng /workdir/sjeng
ADD xalan /workdir/xalan

ADD execute_tests.sh /workdir/

RUN chown -R nobody:nogroup /workdir/astar
RUN chmod 555 /workdir/astar/*

RUN chown -R nobody:nogroup /workdir/bzip2
RUN chmod 555 /workdir/bzip2/*

RUN chown -R nobody:nogroup /workdir/gobmk
RUN chmod 555 /workdir/gobmk/*

RUN chown -R nobody:nogroup /workdir/h264ref
RUN chmod 555 /workdir/h264ref/*

RUN chown -R nobody:nogroup /workdir/hmmer
RUN chmod 555 /workdir/hmmer/*

RUN chown -R nobody:nogroup /workdir/libquantum
#RUN chmod 555 /workdir/libquantum/*

RUN chown -R nobody:nogroup /workdir/mcf
RUN chmod 555 /workdir/mcf/*

RUN chown -R nobody:nogroup /workdir/omnetpp
RUN chmod 555 /workdir/omnetpp/*

RUN chown -R nobody:nogroup /workdir/sjeng
RUN chmod 555 /workdir/sjeng/*

RUN chown -R nobody:nogroup /workdir/xalan
RUN chmod 555 /workdir/xalan/*

#RUN usermod -G nogroup,sudo nobody
#RUN echo "sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers


ADD run_fault_free.sh /workdir/
ADD run_fault.sh /workdir/

WORKDIR /workdir/




### RUN TEST ###

CMD ["/workdir/execute_tests.sh"]



