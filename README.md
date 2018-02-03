# Scripts to create Debian packages with the Tensorflow C++ API

- The build is based upon the "TensorFlow Makefile" component in tensorflow/contrib/makefile directory.
- Two targets were tested: Ubuntu Xenial 64 bit and Raspberrz Pi.
- Debian packages can be generated from the built binary files for easy distribution.
- The build contains e.g. the C++ API to load model "snapshots". New ops can be easily added by modifying the tf_tensor_fix.txt.

# Status
- It does not work.

### In details
- I tested the system with a simple CNN network what I trained with tflearn.
- I used the same images to verify the network in Python and C++.
- Ubuntu 64 bit: The snapshot can be loaded in C++, but the accuracy is worse than loading the same snapshot in Python. I see degraded accuracy from 98 % -> 90 %.
- Cross-compiled binary for Raspberry: it crashes.
- Binary compiled on Raspberry Pi: The snapshot can be loaded in C++, but the network produces completely wrong results.

# Conclusion
- The tensorflow/contrib/makefile is not really supported officially. The Tensorflow team tested to have some running demos on iOS/Android, but the quality is far from stable production use.
