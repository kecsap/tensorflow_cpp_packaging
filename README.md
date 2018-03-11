# Scripts to create Debian packages with the Tensorflow C++ API for Ubuntu x86_64 and Raspberry Pi

- The build is based upon the "TensorFlow Makefile" component in tensorflow/contrib/makefile directory.
- Two targets were tested: Ubuntu Xenial 64 bit and Raspberry Pi.
- Debian packages are generated from the built binary files for distribution.
- The build contains e.g. the C++ API to load model "snapshots". New ops can be easily added by modifying the [tf_tensor_fix.txt](tf_tensor_fix.txt).

# Status
- I trained model simple CNN topology with Tflearn and the inference works on Ubuntu and Raspberry Pi, however, there is a minor difference in the accuracies:

| Platform         | Class 1 | Class 2 |
|------------------|:-------:|:-------:|
| Python           | 94.75 % | 90.12 % |
| Ubuntu C++       | 92.79 % | 91.32 % |
| Raspberry Pi C++ | 90.02 % | 88.46 % |

These results are generated with the same frozen graph (.pb file). As you can see, the C++ inference does not provide 100 % reproducible results vs. the Python inference.

# Releases
- You can download the releases from [here](https://github.com/kecsap/tensorflow_cpp_packaging/releases/latest).

# Requirements
- Basic dependencies must be installed like make, g++, cmake...:

  sudo apt-get install make g++-6 cmake git dpkg-dev debhelper quilt
  
  Note: gcc 6 is needed for the build process because gcc 5 has a linking bug and Tensorflow does not compile with the shipped gcc 5 in Ubuntu Xenial. Gcc 6 can be installed from [this PPA](https://launchpad.net/~ubuntu-toolchain-r/+archive/ubuntu/test).
  
- The cross-compiled binary for Raspberry does not work, it crashes. Tensorflow must be compiled natively on the Raspberry Pi. It takes a lot time (6-8 hours?), but you don't need extra swap space with USB stick or similar. I restricted the build process to 2 parallel jobs to avoid unresponsive Raspberry Pi because of running out of memory.

# Conclusion
- The tensorflow/contrib/makefile is not really tested officially, only some demos were run on iOS/Android. If you don't mind the minor differences in performance, it is suitable for you.

# Contact
Open an issue or drop an email: csaba.kertesz@gmail.com
