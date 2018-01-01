#!/bin/bash

# Get the directory where the script is stored
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -d $DIR/tensorflow ]; then
  echo Clone the appropriate tensorflow branch or tag with 1_clone_tensorflow.sh script
  exit 1
fi
if [ ! -d $DIR/packaging/headers ]; then
  echo Get the Tensorflow C++ headers with 2_make_wheel_for_headers.sh script
  exit 1
fi
if [ ! -d $DIR/packaging/libs ]; then
  echo Get the Tensorflow C++ libraries with a 3_build_tensorflow_cpp_???.sh script
  exit 1
fi

#
# Generate the Debian package
#

# Get some git information
cd $DIR/tensorflow
TAG=$(git describe --tags $(git rev-list --tags --max-count=1) | tr -d 'v')
COMMIT=$(git rev-parse --short HEAD)
DATE=$(git log -1 --date=short --pretty=format:%cd | tr -d '-')

# Configure & build the package
cd $DIR/packaging
rm -rf debian/.debhelper debian/tensorflow-cpp-generic  debian/tensorflow-cpp-generic.debhelper.log debian/tensorflow-cpp-generic.substvars
rm -rf debian/debhelper-build-stamp debian/files
cmake . -DGIT_TAG=${TAG} -DGIT_COMMIT=${COMMIT} -DGIT_DATE=${DATE} -DPKG_SUFFIX=generic -DCMAKE_INSTALL_PREFIX=/usr
dpkg-buildpackage -rfakeroot -b -nc

echo READY! Generic x86_64 package is generated!
