#! /bin/bash

set -ex

VER_HTSLIB=1.18

# get the location to install to
INST_PATH=$1
mkdir -p $1
INST_PATH=`(cd $1 && pwd)`
echo $INST_PATH

# get current directory
INIT_DIR=`pwd`

CPU=`grep -c ^processor /proc/cpuinfo`
if [ $? -eq 0 ]; then
  if [ "$CPU" -gt "6" ]; then
    CPU=6
  fi
else
  CPU=1
fi
echo "Max compilation CPUs set to $CPU"

SETUP_DIR=$INIT_DIR/install_tmp
mkdir -p $SETUP_DIR/distro # don't delete the actual distro directory until the very end
mkdir -p $INST_PATH/bin
cd $SETUP_DIR

# make sure tools installed can see the install loc of libraries
set +u
export LD_LIBRARY_PATH=`echo $INST_PATH/lib:$LD_LIBRARY_PATH | perl -pe 's/:\$//;'`
export PATH=`echo $INST_PATH/bin:$PATH | perl -pe 's/:\$//;'`
export MANPATH=`echo $INST_PATH/man:$INST_PATH/share/man:$MANPATH | perl -pe 's/:\$//;'`
set -u

SOURCE_HTSLIB="https://github.com/samtools/htslib/releases/download/${VER_HTSLIB}/htslib-${VER_HTSLIB}.tar.bz2"

cd $SETUP_DIR

echo "Downloading htslib ..."
if [ ! -e $SETUP_DIR/htslibGet.success ]; then
  cd $SETUP_DIR
  wget $SOURCE_HTSLIB
  touch $SETUP_DIR/htslibGet.success
fi

echo "Building htslib ..."
if [ ! -e $SETUP_DIR/htslib.success ]; then
  mkdir -p htslib
  tar --strip-components 1 -C htslib -jxf htslib-${VER_HTSLIB}.tar.bz2
  cd htslib
  ./configure --enable-plugins --enable-libcurl --with-libdeflate --prefix=$INST_PATH \
  CPPFLAGS="-I$INST_PATH/include" \
  LDFLAGS="-L${INST_PATH}/lib -Wl,-R${INST_PATH}/lib"
  make -j$CPU
  make install
  cd $SETUP_DIR
  touch $SETUP_DIR/htslib.success
fi

echo "Building samtools"
if [ ! -e $SETUP_DIR/samtools.success ]; then
  cd $INST_PATH
  wget https://github.com/samtools/samtools/releases/download/${VER_HTSLIB}/samtools-${VER_HTSLIB}.tar.bz2
  tar -vxjf samtools-${VER_HTSLIB}.tar.bz2
  cd samtools-${VER_HTSLIB}
  ./configure --prefix=$INST_PATH
  make
  make install
  cd $INIT_DIR
  touch $SETUP_DIR/samtools.success
fi
