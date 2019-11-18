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

patch -p1 < $DIR/tf_base.patch
if [ $? != 0 ]; then
  echo -e "FATAL: tf_base.patch FAILED!"
  exit 1
fi
patch -p1 < $DIR/tf_generic_x86_64.patch
if [ $? != 0 ]; then
  echo -e "FATAL: tf_generic_x86_64.patch FAILED!"
  exit 1
fi

sudo apt-get install -y python-pip
pip install --user future

# Build the Tensorflow
cd tensorflow/contrib/cmake
cmake . -Dtensorflow_ENABLE_GRPC_SUPPORT=OFF -Dtensorflow_ENABLE_SSL_SUPPORT=OFF -Dtensorflow_BUILD_PYTHON_BINDINGS=OFF -Dsystemlib_ABSEIL_CPP=OFF \
        -Dtensorflow_ENABLE_POSITION_INDEPENDENT_CODE=ON -Dtensorflow_BUILD_SHARED_LIB=ON -Dtensorflow_BUILD_CC_EXAMPLE=OFF -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=${DIR}/tensorflow/install || exit 1
make -j$(nproc --ignore=1) tensorflow install || exit 1

# Copy headers
mkdir -p ${DIR}/tensorflow/install/include/absl || exit 1
find ${DIR}/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl -name '*.h' | cpio -pdm ${DIR}/tensorflow/install/include/absl/ || exit 1
cp ${DIR}/tensorflow/tensorflow/contrib/cmake/protobuf/src/protobuf/src/google/protobuf/port_def.inc ${DIR}/tensorflow/install/include/google/protobuf/ || exit 1
cp ${DIR}/tensorflow/tensorflow/contrib/cmake/protobuf/src/protobuf/src/google/protobuf/port_undef.inc ${DIR}/tensorflow/install/include/google/protobuf/ || exit 1
cd ${DIR}/tensorflow/install/include || exit 1
cp -rf * $DIR/packaging/headers/ || exit 1

# Copy/prepare the final binaries
mkdir -p $DIR/tensorflow/absl_fix || exit 1
rm -rf $DIR/tensorflow/absl_fix/*.o
cd $DIR/tensorflow/absl_fix || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/base/libabsl_base.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/base/libabsl_exponential_biased.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/base/libabsl_raw_logging_internal.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/base/libabsl_spinlock_wait.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/base/libabsl_dynamic_annotations.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/base/libabsl_malloc_internal.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/base/libabsl_throw_delegate.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/numeric/libabsl_int128.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/strings/libabsl_strings.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/strings/libabsl_strings_internal.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/strings/libabsl_str_format_internal.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/hash/libabsl_hash.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/container/libabsl_hashtablez_sampler.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/synchronization/libabsl_synchronization.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/debugging/libabsl_stacktrace.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/debugging/libabsl_symbolize.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/debugging/libabsl_debugging_internal.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/debugging/libabsl_demangle_internal.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/time/libabsl_time.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/time/libabsl_time_zone.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/hash/libabsl_city.a || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/abseil_cpp/src/abseil_cpp_build/absl/types/libabsl_bad_optional_access.a || exit 1
ar -r libabsl.a *.o || exit 1
cp libabsl.a $DIR/packaging/libs/libabsl.a || exit 1

mkdir -p $DIR/tensorflow/fft2d_fix || exit 1
rm -rf $DIR/tensorflow/fft2d_fix/*.o
cd $DIR/tensorflow/fft2d_fix || exit 1
ar -x $DIR/tensorflow/tensorflow/contrib/cmake/fft2d/src/fft2d/libfft2d.a || exit 1
cp $DIR/tensorflow/tensorflow/contrib/cmake/libtensorflow.a $DIR/tensorflow/fft2d_fix/ || exit 1
ar -r $DIR/tensorflow/fft2d_fix/libtensorflow.a *.o || exit 1

cd $DIR/tensorflow || exit 1
cp tensorflow/contrib/cmake/protobuf/src/protobuf/libprotobuf.a $DIR/packaging/libs/libprotobuf-tf-static.a || exit 1
g++ -shared -o $DIR/packaging/libs/libprotobuf-tf.so -Wl,--whole-archive -l:libprotobuf-tf-static.a -L$DIR/packaging/libs/ -Wl,--no-whole-archive || exit 1
cp tensorflow/contrib/cmake/nsync/src/nsync/libnsync.a $DIR/packaging/libs/libnsync-tf.a || exit 1
cp tensorflow/contrib/cmake/nsync/src/nsync/libnsync_cpp.a $DIR/packaging/libs/libnsync-cpp-tf.a || exit 1
cp $DIR/tensorflow/fft2d_fix/libtensorflow.a $DIR/packaging/libs/libtensorflow-core-static.a || exit 1
g++ -shared -o $DIR/packaging/libs/libtensorflow-core.so -Wl,--whole-archive -l:libtensorflow-core-static.a -L$DIR/packaging/libs/ -Wl,--no-whole-archive -Wl,--allow-multiple-definition || exit 1
cp tensorflow/contrib/cmake/libtf_protos_cc.a $DIR/packaging/libs/libtf_protos_cc-static.a || exit 1
g++ -shared -o $DIR/packaging/libs/libtf_protos_cc.so -Wl,--whole-archive -l:libtf_protos_cc-static.a -L$DIR/packaging/libs/ -Wl,--no-whole-archive || exit 1

echo READY! Libraries are extracted to $DIR/packaging/libs/
