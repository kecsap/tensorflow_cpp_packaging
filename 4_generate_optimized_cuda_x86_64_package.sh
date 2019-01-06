#!/bin/bash

# Get the directory where the script is stored
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -d $DIR/packaging/headers ]; then
  echo Get the Tensorflow C++ headers with 2_make_wheel_for_headers.sh script
  exit 1
fi
if [ ! -d $DIR/packaging/libs ]; then
  echo Get the Tensorflow C++ libraries with the 3_build_tensorflow_cpp_optimized_cuda_x86_64.sh script
  exit 1
fi

#
# Generate the Debian package
#

# Get some git information
cd $DIR/tensorflow
TAG=1.10.0fix2
COMMIT=56e4ea405d
DATE=20180810

# Configure & build the package
cd $DIR/packaging
rm -rf debian/.debhelper debian/tensorflow-cpp-*
rm -rf debian/debhelper-build-stamp debian/files
cmake . -DGIT_TAG=${TAG} -DGIT_COMMIT=${COMMIT} -DGIT_DATE=${DATE} -DPKG_SUFFIX=optimized-cuda -DCMAKE_INSTALL_PREFIX=/usr -DPKG_ARCH=amd64 -DRELEASE_MODE=OFF
dpkg-buildpackage -rfakeroot -b -nc

# Make a plain tar file
tar -C ./debian/tensorflow-cpp-optimized-cuda/ -cf ../tensorflow-cpp-optimized-cuda_${TAG}~git${DATE}~${COMMIT}.tar usr/
pxz -9 ../tensorflow-cpp-optimized-cuda_${TAG}~git${DATE}~${COMMIT}.tar

echo READY! Optimized/CUDA x86_64 package is generated!
