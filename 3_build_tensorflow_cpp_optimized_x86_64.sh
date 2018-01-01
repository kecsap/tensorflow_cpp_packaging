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
git apply < $DIR/tf_tensor_fix.diff || exit 1
git apply < $DIR/tf_optimized_x86_64.patch || exit 1

# Download the dependencies
tensorflow/contrib/makefile/download_dependencies.sh || exit 1

# Build the shared library
export CXX=g++-6
export CC=gcc-6
tensorflow/contrib/makefile/build_all_linux.sh || exit 1

# Copy/prepare the final binaries
cp tensorflow/contrib/makefile/gen/protobuf/lib/libprotobuf.a $DIR/packaging/libs/libprotobuf-tf-static.a || exit 1
g++-6 -shared -o $DIR/packaging/libs/libprotobuf-tf.so -Wl,--whole-archive -l:libprotobuf-tf-static.a -L$DIR/packaging/libs/ -Wl,--no-whole-archive || exit 1
cp tensorflow/contrib/makefile/downloads/nsync/builds/default.linux.c++11/nsync.a $DIR/packaging/libs/libnsync-tf.a || exit 1
cp tensorflow/contrib/makefile/gen/lib/libtensorflow-core.a $DIR/packaging/libs/libtensorflow-core-static.a || exit 1
g++-6 -shared -o $DIR/packaging/libs/libtensorflow-core.so -Wl,--whole-archive -l:libtensorflow-core-static.a -L$DIR/packaging/libs/ -Wl,--no-whole-archive || exit 1

echo READY! Libraries are extracted to $DIR/packaging/libs/
