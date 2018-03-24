#!/bin/bash

# Get the directory where the script is stored
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -d $DIR/tensorflow ]; then
  echo Clone the appropriate tensorflow branch or tag with 1_clone_tensorflow.sh script
  exit 1
fi

#
# Generate wheel (Python package) to get the C++ headers
#

mkdir -p $DIR/packaging/headers/
# Clean old packaging files if they exist
rm -rf $DIR/packaging/headers/*
mkdir -p $DIR/packaging/headers/tensorflow/c
rm -rf /tmp/tensorflow_pkg/*

# Comment the following lines to disable python3 and CUDA support
export TF_NEED_CUDA=True
export PYTHON_BIN_PATH=/usr/bin/python3
export TF_CUDA_VERSION=9.1
export TF_CUDA_COMPUTE_CAPABILITIES=5.0,6.1

# Configure
cd $DIR/tensorflow
yes '' | ./configure || exit 1

# Build a generic wheel package
bazel build -c opt --copt=-mfpmath=both --copt=-march=core2 --copt=-msse4.2 --copt=-mavx --copt=-mfma -k //tensorflow/tools/pip_package:build_pip_package
bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
cp tensorflow/c/c_api.h $DIR/packaging/headers/tensorflow/c/
cd /tmp/tensorflow_pkg/
unzip *.whl
cd tensorflow-*.data
cd purelib/tensorflow/include
cp -r * $DIR/packaging/headers
echo READY! Headers are extracted to $DIR/packaging/headers/
