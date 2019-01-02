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

# Clean the repository
cd $DIR/tensorflow
git clean -fdx
git reset --hard

# Comment the following lines to disable python3
export PYTHON_BIN_PATH=/usr/bin/python3
pip3 install --user keras_applications

# Uncomment the following lines to enable CUDA support
#export TF_NEED_CUDA=True
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-10.0/extras/CUPTI/lib64
#export CUDA_TOOLKIT_PATH=/usr/local/cuda-10.0
#export TF_CUDA_VERSION=10.0
#export TF_CUDA_COMPUTE_CAPABILITIES=5.0,6.1,7.5
#export TF_NCCL_VERSION=2.3.7
#export NCCL_INSTALL_PATH=/usr/
# NOTE! This patch is not needed anymore for Tensorflow 1.12.0
#git apply < $DIR/tf_nccl.patch || exit 1

# The build fail with the default g++-7 on Ubuntu Bionic
export CC=gcc-6
export CXX=g++-6

export OPT_STR="--copt=-mavx --copt=-mfma"

yes '' | ./configure || exit 1

# Build a wheel package
bazel build -c opt --copt=-mfpmath=both --copt=-march=core2 --copt=-msse4.2 $OPT_STR --copt=-O3 --verbose_failures -k //tensorflow/tools/pip_package:build_pip_package || exit 1
bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg || exit 1
cp tensorflow/c/c_api.h $DIR/packaging/headers/tensorflow/c/
cd /tmp/tensorflow_pkg/
unzip *.whl
cd tensorflow-*.data
cd purelib/tensorflow/include
cp -r * $DIR/packaging/headers
echo READY! Headers are extracted to $DIR/packaging/headers/
