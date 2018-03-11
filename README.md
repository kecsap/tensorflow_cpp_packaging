# Tensorflow C++ inference with Debian packages on Ubuntu x86_64 and Raspberry Pi

- The build is based on the "TensorFlow Makefile" component in tensorflow/contrib/makefile directory.
- Two targets were tested: Ubuntu Xenial (x86_64) and Raspberry Pi (armhf).
- Debian packages are generated from the built binary files for distribution.
- The build contains e.g. the C++ API to load model "snapshots". New ops can be easily added by modifying the [tf_tensor_fix.txt](tf_tensor_fix.txt).

## Status
- I trained a simple CNN model with TFLearn and the inference works on Ubuntu and Raspberry Pi, however, there are differences in the accuracies:

| Platform         | Class 1 | Class 2 |
|------------------|:-------:|:-------:|
| Python           | 94.75 % | 90.12 % |
| Ubuntu C++       | 92.79 % | 91.32 % |
| Raspberry Pi C++ | 90.02 % | 88.46 % |

These results are generated with the same frozen graph (.pb file). As you can see, the C++ inference does not provide 100 % reproducible results vs. the Python inference.

## Releases
- You can download the releases from [here](https://github.com/kecsap/tensorflow_cpp_packaging/releases/latest).

## Requirements
- Basic dependencies must be installed like make, g++, cmake...:
```
sudo apt-get install make g++-6 cmake git dpkg-dev debhelper quilt
```
   Note: Gcc 6 is needed for the build process because gcc 5 has a linking bug and Tensorflow does not compile with the shipped gcc 5 in Ubuntu Xenial. Gcc 6 can be installed from [this PPA](https://launchpad.net/~ubuntu-toolchain-r/+archive/ubuntu/test).
   
- The cross-compiled binary for Raspberry does not work, it crashes, therefore, Tensorflow must be compiled natively on the Raspberry Pi. It takes a lot time (6-8 hours?), but extra swap space is not necessary. I restricted the build process to 2 parallel jobs to avoid unresponsive Raspberry Pi because of running out of memory.

## Manual compilation
- Clone this repository and enter to its directory:
```
git clone https://github.com/kecsap/tensorflow_cpp_packaging && cd tensorflow_cpp_packaging
```
- Clone the Tensorflow Github repository:
```
./1_clone_tensorflow.sh
```
  A specific branch or tag can be also checked out, for example Tensorflow 1.6.0:
```
./1_clone_tensorflow.sh v1.6.0
```
- Make the python package to extract include files for C++. This step assumes installed CUDA 9.1, but it can be changed [here](https://github.com/kecsap/tensorflow_cpp_packaging/blob/1abf70412378198fb612307fef57c2d75cbaa03c/2_make_wheel_for_headers.sh#L20):
```
./2_make_wheel_for_headers.sh
```
- Compile the Tensorflow C++ libraries for the desired platform:
Generic build for Ubuntu x86_64, optimized only for SSE 4.2 (post Core 2 Duo processors):
```
./3_build_tensorflow_cpp_generic_x86_64.sh
```
Optimized build for Ubuntu x86_64, optimized only for SSE/AVX1/FMA. AVX2 optimization was left out on purpose to be compatible with the older AMD FX processors:
```
./3_build_tensorflow_cpp_optimized_x86_64.sh
```
Raspberry Pi build:
```
./3_build_tensorflow_cpp_arm_rpi.sh
```
- Generate debian packages:
Generic build for Ubuntu x86_64:
```
./4_generate_generic_x86_64_package.sh
```
Optimized build for Ubuntu x86_64:
```
./4_generate_optimized_x86_64_package.sh
```
Raspberry Pi build:
```
./4_generate_arm_rpi_package.sh
```

## Conclusion
- The tensorflow/contrib/makefile is not really tested officially, only some demos were run on iOS/Android. If you don't mind the minor differences in performance, it is suitable for you.

## Contact
Open an issue or drop an email: csaba.kertesz@gmail.com
