#!/bin/bash

# Get the directory where the script is stored
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Generate the binaries
#
# Clean old packaging files if they exist
mkdir -p ${DIR}/packaging/libs
rm -rf ${DIR}/packaging/libs/*

# Clone tensorflow_cc
cd ${DIR}
git clone https://github.com/FloopCZ/tensorflow_cc/

# Clean up
cd ${DIR}/tensorflow_cc/ || exit 1
git clean -fdx
git reset --hard
git co 419eb9d9d34575b05e80e0e81aa67f5fa75a4fc7
mkdir -p build && mkdir -p install && cd build || exit 1

export GCC_HOST_COMPILER_PATH=/usr/bin/gcc
export CC_OPT_FLAGS="-march=skylake"
export TF_CUDA_COMPUTE_CAPABILITIES=6.1,7.5
cmake -DTENSORFLOW_STATIC=OFF -DTENSORFLOW_SHARED=ON -DTENSORFLOW_TAG=v1.13.1 \
      -DCMAKE_INSTALL_PREFIX=${DIR}/tensorflow_cc/install -B. -H../tensorflow_cc || exit 1
make && make install || exit 1

# Copy/prepare the final binaries
cp ${DIR}/tensorflow_cc/install/lib/tensorflow_cc/libtensorflow_cc.so ${DIR}/packaging/libs/ || exit 1
cp ${DIR}/tensorflow_cc/install/lib/tensorflow_cc/libprotobuf.a ${DIR}/packaging/libs/ || exit 1

echo READY! Libraries are extracted to ${DIR}/packaging/libs/
