#!/bin/bash

# Get the directory where the script is stored
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -d $DIR/tensorflow ]; then
  echo Clone the appropriate tensorflow branch or tag with 1_clone_tensorflow.sh script
  exit 1
fi

#
# Generate the binaries
#
# Clean old packaging files if they exist
mkdir -p $DIR/packaging/libs
rm -rf $DIR/packaging/libs/*

cd $DIR/tensorflow
# Clean up
git clean -fdx
git reset --hard
cat $DIR/tf_tensor_fix.txt >> tensorflow/contrib/makefile/tf_op_files.txt
git apply < $DIR/tf_arm_crosscompiling.patch || exit 1

# Download the dependencies
tensorflow/contrib/makefile/download_dependencies.sh || exit 1

# Build and extract native protoc for the host machine
cd $DIR/tensorflow/tensorflow/contrib/makefile/downloads/protobuf/
./autogen.sh || exit 1
./configure || exit 1
make clean || exit 1
make -j8 || exit 1
cd src || exit 1
cp -r google $DIR/tensorflow/ || exit 1
cd .libs/ || exit 1
cp protoc $DIR/tensorflow/ || exit 1
cp libprotobuf.so* $DIR/tensorflow/ || exit 1
cp libprotoc.so* $DIR/tensorflow/ || exit 1

# Build the protobuf library
export CXX=arm-linux-gnueabihf-g++-5
export CC=arm-linux-gnueabihf-gcc-5
export HOST_OS=PI
export TARGET=PI
export PROTOC=$DIR/tensorflow/protoc
export PATH=$DIR/tensorflow/:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DIR/tensorflow/
export CUSTOM_HOST_LIBS="-L$DIR/tensorflow/ -Wl,-rpath,$DIR/tensorflow/"

cd $DIR/tensorflow/tensorflow/contrib/makefile/downloads/protobuf/
./autogen.sh || exit 1
CFLAGS="$CFLAGS -fPIC" CXXFLAGS="$CXXFLAGS -fPIC" ./configure --host=arm-linux --with-protoc=$PROTOC || exit 1
make clean || exit 1
make -j8 || exit 1
mkdir -p $DIR/tensorflow/tensorflow/contrib/makefile/gen/protobuf/lib/ || exit 1
cp src/.libs/libprotobuf.a $DIR/tensorflow/tensorflow/contrib/makefile/gen/protobuf/lib/ || exit 1

# Compile nsync for Raspberry Pi
cd $DIR/tensorflow
export HOST_NSYNC_LIB=`$DIR/tensorflow/tensorflow/contrib/makefile/compile_nsync.sh`
export TARGET_NSYNC_LIB="$DIR/tensorflow/tensorflow/contrib/makefile/downloads/nsync/builds/arm.linux.gcc.lrt/libnsync.a"

cp $DIR/rpi_crosscompiling_fixes/Makefile $DIR/tensorflow/tensorflow/contrib/makefile/downloads/nsync/builds/arm.linux.gcc.lrt/ || exit 1
make -C $DIR/tensorflow/tensorflow/contrib/makefile/downloads/nsync/builds/arm.linux.gcc.lrt/ || exit 1

# Build Tensorflow (this trial will fail because of a problem of the linking flags
export CUSTOM_HOST_LIBS="-L$DIR/tensorflow/ -Wl,-rpath,$DIR/tensorflow/"

make -j8 -f tensorflow/contrib/makefile/Makefile \
  OPTFLAGS="-Os -mfpu=neon-vfpv4 -funsafe-math-optimizations -ftree-vectorize" \
  HOST_CXXFLAGS="--std=c++11" \
  MAKEFILE_DIR=$DIR/tensorflow/tensorflow/contrib/makefile/

# Build Tensorflow #2
export CUSTOM_HOST_LIBS="$DIR/rpi_crosscompiling_fixes/libz.a -L$DIR/tensorflow/tensorflow/contrib/makefile/downloads/protobuf/src/.libs/"
export CUSTOM_TARGET_LIBS="-L$DIR/tensorflow/ -Wl,-rpath,$DIR/tensorflow/"

make -j8 -f tensorflow/contrib/makefile/Makefile \
  OPTFLAGS="-Os -mfpu=neon-vfpv4 -funsafe-math-optimizations -ftree-vectorize" \
  HOST_CXXFLAGS="--std=c++11" \
  MAKEFILE_DIR=$DIR/tensorflow/tensorflow/contrib/makefile/


# Copy/prepare the final binaries
cp tensorflow/contrib/makefile/gen/protobuf/lib/libprotobuf.a $DIR/packaging/libs/libprotobuf-tf-static.a || exit 1
arm-linux-gnueabihf-g++-5 -shared -o $DIR/packaging/libs/libprotobuf-tf.so -Wl,--whole-archive -l:libprotobuf-tf-static.a -L$DIR/packaging/libs/ -Wl,--no-whole-archive || exit 1
cp tensorflow/contrib/makefile/downloads/nsync/builds/arm.linux.gcc.lrt/nsync.a $DIR/packaging/libs/libnsync-tf.a || exit 1
cp tensorflow/contrib/makefile/gen/lib/libtensorflow-core.a $DIR/packaging/libs/libtensorflow-core-static.a || exit 1
arm-linux-gnueabihf-g++-5 -shared -o $DIR/packaging/libs/libtensorflow-core.so -Wl,--whole-archive -l:libtensorflow-core-static.a -L$DIR/packaging/libs/ -Wl,--no-whole-archive || exit 1

echo READY! Libraries are extracted to $DIR/packaging/libs/
