# Tensorflow C/C++ inference with Debian packages on Ubuntu x86_64 and Raspberry Pi

- The generic and optimized x86_64 builds are based on the "TensorFlow CMake" component in tensorflow/contrib/cmake directory.
- The CUDA x86_64 build is based on [tensorflow_cc project](https://github.com/FloopCZ/tensorflow_cc), thanks to FloopCZ.
- The Raspberry Pi build is based on the "TensorFlow Makefile" component in tensorflow/contrib/makefile directory.
- Two targets were tested: Ubuntu Bionic (x86_64) and Raspberry Pi Ubuntu MATE Xenial (armhf).
- Generic, optimized and Raspberry Pi packages contain both static and shared Tensorflow libraries. The choice is on your side. However, the CUDA builds only ship shared libraries.
- CPU can be used for inference, GPU support is only in the CUDA packages.
- Debian packages are generated from the built binary files for distribution.
- The build contains e.g. the C/C++ API to load model "snapshots" or frozen models. Other parts of the C++ API is included, but they are untested.
- CUDA support with Tensorflow 1.13.1 requires to all GPU memory available for inference by default otherwise it drops error message. To allow_growth option must be set to allow multiple processes doing inference on the same GPU. See in the example codes below.

## Status

I trained a simple CNN model with TFLearn (and Tensorflow 1.10) for a 2-label classification and the inference works on Ubuntu and Raspberry Pi, however, there are differences in the accuracies:

| Platform         | Class 1 | Class 2 |
|------------------|:-------:|:-------:|
| Python           | 95.26 % | 95.69 % |
| Ubuntu C/C++     | 95.12 % | 95.57 % |
| Raspberry Pi C++ | 97.23 % | 83.73 % |

These results are generated with the same frozen graph (.pb file). The C/C++ inference does not provide 100 % reproducible results vs. the Python inference.

## Releases

### Dependencies for generic and optimized packages

- You must install some dependencies for **Ubuntu Bionic x86_64**:
```
sudo apt-get install libdouble-conversion-dev libfarmhash-dev libre2-dev libgif-dev libpng-dev libsqlite3-dev libsnappy-dev liblmdb-dev libicu-dev python
```

### Dependencies for the latest CUDA packages

You must install CUDA 10.1 from the official Nvidia repositories and Bazel 0.21.0 for Tensorflow. Other configurations are not supported.

### Dependencies for Raspberry Pi packages

Nothing.

### Installation

- You can download the releases from [here](https://github.com/kecsap/tensorflow_cpp_packaging/releases/latest).

## Manual compilation

### Requirements

- Install Bazel: https://docs.bazel.build/versions/master/install-ubuntu.html
- These build dependencies must be installed on **Ubuntu Bionic x86_64**:
```
sudo apt-get install make g++-6 gcc-6 cmake git dpkg-dev debhelper quilt python3 autogen autoconf libtool fakeroot golang pxz
```

Current Protobuf in Tensorflow 1.13.1 does not compile with gcc 7.3+/8. We must install gcc 6 to build Tensorflow. Be sure that "gcc -v" and "g++ -v" shows a 6.x version: e.g. "gcc version 6.5.0 20181026 (Ubuntu 6.5.0-2ubuntu1~18.04)" before building the packages. Using the packages does not require these specific gcc/g++ versions.

- These build dependencies must be installed on **Raspberry Pi**:
```
sudo apt-get install make g++-6 cmake git dpkg-dev debhelper quilt python3 autogen autoconf libtool fakeroot
```
   Note: Gcc 6 is needed for the build process on the Raspberry Pi because gcc 5 has a linking bug and Tensorflow does not compile with the shipped gcc 5 in Ubuntu Xenial. Gcc 6 can be installed from [this PPA](https://launchpad.net/~ubuntu-toolchain-r/+archive/ubuntu/test).
   
- Tensorflow must be compiled natively on the Raspberry Pi. It takes a lot time (6-8 hours?), but extra swap space is not necessary over the usual 1 GB. I restricted the build process to 2 parallel jobs to avoid unresponsive Raspberry Pi because of running out of memory.

### Compilation steps

- Clone this repository and enter to its directory:
```
git clone https://github.com/kecsap/tensorflow_cpp_packaging && cd tensorflow_cpp_packaging
```
- Clone the Tensorflow Github repository.

Latest master:
```
./1_clone_tensorflow.sh
```
  A specific branch or tag can be also checked out, for example Tensorflow 1.6.0:
```
./1_clone_tensorflow.sh v1.6.0
```
- Make the python package to extract include files for C++:
```
./2_make_wheel_for_headers.sh
```
- Compile the Tensorflow C++ libraries for the desired platform:

Generic build for Ubuntu x86_64, optimized for minimum Haswell of Intel and Piledriver of AMD (AVX, FMA instructions):
```
./3_build_tensorflow_cpp_generic_x86_64.sh
```
Optimized build for Ubuntu x86_64, optimized for minimum Skylake of Intel and Excavator of AMD (AVX, AVX2, FMA instructions):
```
./3_build_tensorflow_cpp_optimized_x86_64.sh
```
Generic/CUDA build for Ubuntu x86_64, optimized for minimum Haswell of Intel and Piledriver of AMD (AVX, FMA instructions). The generic build had to be compiled first to get all C++ headers correctly:
```
./3_build_tensorflow_cpp_generic_x86_64.sh
./3_build_tensorflow_cpp_generic_cuda_x86_64.sh
```
Optimized/CUDA build for Ubuntu x86_64, optimized for minimum Skylake of Intel and Excavator of AMD (AVX, AVX2, FMA instructions). The optimized build had to be compiled first to get all C++ headers correctly:
```
./3_build_tensorflow_cpp_optimized_x86_64.sh
./3_build_tensorflow_cpp_optimized_cuda_x86_64.sh
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
Generic/CUDA build for Ubuntu x86_64:
```
./4_generate_generic_cuda_x86_64_package.sh
```
Optimized/CUDA build for Ubuntu x86_64:
```
./4_generate_optimized_cuda_x86_64_package.sh
```
Raspberry Pi build:
```
./4_generate_arm_rpi_package.sh
```

## Save a checkpoint in Python (TFLearn)

The standard, saved checkpoints in TFLearn are not good because they contain the training ops and those must be deleted before saving a checkpoint. I provide an example how the checkpoints can be saved inside a TFLearn callback:

```python
...
model = tflearn.DNN(network)

class MonitorCallback(tflearn.callbacks.Callback):
  # Create an other session to clone the model and avoid effecting the training process
  with tf.Session() as second_sess:
    # Clone the current model
    model2 = model
    # Delete the training ops
    del tf.get_collection_ref(tf.GraphKeys.TRAIN_OPS)[:]
    # Save the checkpoint
    model2.save('checkpoint_'+str(training_state.step)+".ckpt")
    # Write a text protobuf to have a human-readable form of the model
    tf.train.write_graph(second_sess.graph_def, '.', 'checkpoint_'+str(training_state.step)+".pbtxt", as_text = True)
  return

mycb = MonitorCallback()
model.fit({'input': X}, {'target': Y}, n_epoch=500, run_id="mymodel", callbacks=mycb)
...
```

## Freeze a checkpoint (snapshot) into a model in Python

Use the provided utility script in this repository at [utils/tf_freezer.py](https://github.com/kecsap/tensorflow_cpp_packaging/blob/master/utils/tf_freezer.py):
```bash
./tf_freezer.py -c my_checkpoint -p final_model.pb -i Input/X -o Fc2/Sigmoid
```
The above example assumes that you have three files related to a checkpoint inside the directory with my_checkpoint prefix (e.g. my_checkpoint.meta). The script will create a frozen protobuf model (final_model.pb). You must specify the input and output tensors with -i and -o. The default input tensor name is Input/X and the default output tensor name is FullyConnected/Sigmoid.

## CMake support

Once you installed the Debian package of this project, CMake support is provided for Tensorflow inference in your C++ project.

```cmake
# Find tensorflow-cpp
FIND_PACKAGE(TensorFlowCpp REQUIRED PATHS /usr/lib/cmake/tensorflow-cpp)

# Add the tensorflow-cpp paths to the include directories
INCLUDE_DIRECTORIES(${TENSORFLOWCPP_INCLUDE_DIRS})

# Add a target with your inference codes
ADD_EXECUTABLE(my_nice_app my_nice_app.cpp)

# Link your application against the shared Tensorflow C++ library
TARGET_LINK_LIBRARIES(my_nice_app ${TENSORFLOWCPP_LIBRARIES})
# OR link your application against the static Tensorflow C++ library
#TARGET_LINK_LIBRARIES(my_nice_app ${TENSORFLOWCPP_STATIC_LIBRARIES})
```

## Load a checkpoint in C++

```c++
#include <tensorflow/core/protobuf/meta_graph.pb.h>
#include <tensorflow/core/public/session.h>

tensorflow::MetaGraphDef GraphDef;
tensorflow::Session* Session = nullptr;

bool LoadGraph()
{
  const std::string PathToGraph = "my_checkpoint.meta";
  const std::string CheckpointPrefix = "my_checkpoint";
  // Ignore info logs
  char EnvStr[] = "TF_CPP_MIN_LOG_LEVEL=1";
  
  putenv(EnvStr);
  // Dynamic GPU memory allocation
  tensorflow::SessionOptions SessionOptions;
  
  SessionOptions.config.mutable_gpu_options()->set_allow_growth(true);
  Session = tensorflow::NewSession(SessionOptions);
  if (Session == nullptr)
  {
    printf("Could not create Tensorflow session.\n");
    return false;
  }

  // Read in the protobuf graph
  tensorflow::Status Status;

  Status = ReadBinaryProto(tensorflow::Env::Default(), PathToGraph, &GraphDef);
  if (!Status.ok())
  {
    printf("Error reading graph definition from %s: %s\n", PathToGraph.c_str(), Status.ToString().c_str());
    return false;
  }

  // Add the graph to the session
  Status = Session->Create(GraphDef.graph_def());
  if (!Status.ok())
  {
    printf("Error creating graph: %s\n", Status.ToString().c_str());
    return false;
  }

  // Read weights from the saved checkpoint
  tensorflow::Tensor CheckpointPathTensor(tensorflow::DT_STRING, tensorflow::TensorShape());

  CheckpointPathTensor.scalar<std::string>()() = CheckpointPrefix;
  Status = Session->Run(
        {{ GraphDef.saver_def().filename_tensor_name(), CheckpointPathTensor },},
        {},
        { GraphDef.saver_def().restore_op_name() },
        nullptr);

  if (!Status.ok())
  {
    printf("Error loading checkpoint from %s: %s\n", CheckpointPrefix.c_str(), Status.ToString().c_str());
    return false;
  }
  return true;
}
```

## Load a frozen model in C++

Loading a frozen model is much more simple than loading a checkpoint:
```c++
#include <tensorflow/core/protobuf/meta_graph.pb.h>
#include <tensorflow/core/public/session.h>

tensorflow::GraphDef GraphDef;
tensorflow::Session* Session = nullptr;

bool LoadGraph()
{
  // Read in the protobuf graph we exported
  tensorflow::Status Status;

  Status = tensorflow::ReadBinaryProto(tensorflow::Env::Default(), "my_model.pb", &GraphDef);
  if (!Status.ok())
  {
    printf("Error reading graph definition from %s: %s\n", "my_model.pb", Status.ToString().c_str());
    return false;
  }

  Session = tensorflow::NewSession(tensorflow::SessionOptions());
  if (Session == nullptr)
  {
    printf("Could not create Tensorflow session.\n");
    return false;
  }

  // Add the graph to the session
  Status = Session->Create(GraphDef);
  if (!Status.ok())
  {
    printf("Error creating graph: %s\n", Status.ToString().c_str());
    return false;
  }
  return true;
}
```

## Inference in C++

```c++
int Predict()
{
  // The input tensor in this example is an image with resolution 160x96
  tensorflow::Tensor X(tensorflow::DT_FLOAT, tensorflow::TensorShape({ 1, 96, 160, 1 }));
  // Replace YOUR_INPUT_TENSOR with the input tensor name in your network.
  std::vector<std::pair<std::string, tensorflow::Tensor>> Input = { { "YOUR_INPUT_TENSOR", X} };
  std::vector<tensorflow::Tensor> Outputs;
  float* XData = X.flat<float>().data();

  for (int i = 0; i < 160*96; ++i)
  {
    // Read your image and set the input data
    XData[i] = (float)YOUR_PIXELS;
  }

  // Replace YOUR_OUTPUT_TENSOR with your output tensor name
  tensorflow::Status Status = Session->Run(Input, { "YOUR_OUTPUT_TENSOR" }, {}, &Outputs);

  if (!Status.ok())
  {
    printf("Error in prediction: %s\n", Status.ToString().c_str());
    return -1;
  }
  if (Outputs.size() != 1)
  {
    printf("Missing prediction! (%d)\n", (int)Outputs.size());
    return -1;
  }

  // This example has a final, output layer with two neurons for classification with softmax.
  // The two neurons are inspected in this example instead of the softmax tensor
  auto Item = Outputs[0].shaped<float, 2>({ 1, 2 }); // { 1, 2 } -> One sample+2 label classes

  printf("First neuron output: %1.4\n", (float)Item(0, 0));
  printf("Second neuron output: %1.4\n", (float)Item(0, 1));
  if ((float)Item(0, 0) > (float)Item(0, 1))
  {
    return 0;
  }
  return 1;
}
```

## Load a frozen model in C

Loading a frozen model is with the C API:
```c
#include <tensorflow/c/c_api.h>

TF_Status* Status = NULL;
TF_Graph* Graph = NULL;
TF_ImportGraphDefOptions* GraphDefOpts = NULL;
TF_Session* Session = NULL;
TF_SessionOptions* SessionOpts = NULL;
TF_Buffer* GraphDef = NULL;

bool LoadGraph()
{
  // The protobuf is loaded with C API here
  unsigned char CurrentFile[YOUR_BUFFER_SIZE];
  
  LOAD YOUR PROTOBUF FILE HERE TO CurrentFile

  Status = TF_NewStatus();
  Graph = TF_NewGraph();
  GraphDef.reset(TF_NewBuffer());
  GraphDef->data = &CurrentFile;
  GraphDef->length = YOUR_BUFFER_SIZE;
  // Deallocator is skipped in this example
  GraphDef->data_deallocator = NULL;
  GraphDefOpts = TF_NewImportGraphDefOptions();
  TF_GraphImportGraphDef(Graph, GraphDef.get(), GraphDefOpts, Status);
  if (TF_GetCode(Status) != TF_OK)
  {
    printf("Tensorflow status %d - %s\n", TF_GetCode(Status), TF_Message(Status));
    return false;
  }
  SessionOpts = TF_NewSessionOptions();
  Session = TF_NewSession(Graph, SessionOpts, Status);
  if (TF_GetCode(Status) != TF_OK)
  {
    printf("Tensorflow status %d - %s\n", TF_GetCode(Status), TF_Message(Status));
    return false;
  }
  return true;
}
```

## Inference in C

```c
int Predict()
{
  // Make prediction with C API
  float* InputData = (float*)malloc(sizeof(float)*96*160);

  for (int i = 0; i < image.GetImageDataSize(); ++i)
  {
    InputData[i] = (float)YOUR_PIXELS;
  }

  // Input node
  int64_t InputDim[] = { 1, 96, 160, 1 };
  TF_Tensor* ImageTensor = TF_NewTensor(TF_FLOAT, InputDim, 4, InputData, 96*160*sizeof(float), NULL, NULL);
  TF_Output Input = { TF_GraphOperationByName(Graph, "YOUR_INPUT_TENSOR") };
  TF_Tensor* InputValues[] = { ImageTensor };

  // Output node
  TF_Output Output = { TF_GraphOperationByName(Graph, "YOUR_OUTPUT_TENSOR") };
  TF_Tensor* OutputValues = NULL;

  // Run prediction
  TF_SessionRun(Session, NULL,
                &Input, &InputValues[0], 1,
                &Output, &OutputValues, 1,
                NULL, 0, NULL, Status);

  delete InputData;
  InputData = NULL;
  if (TF_GetCode(Status) != TF_OK)
  {
    printf("Tensorflow status %d - %s\n", TF_GetCode(Status), TF_Message(Status));
    return false;
  }
  // This example has a final in argmax classification.
  int Result = (int)*(long long*)TF_TensorData(OutputValues);
  
  printf("Argmax output: %d\n", Result);
  return Result;
}
```

Remember to release the allocated resources in the end:

```c
  TF_DeleteGraph(Graph);
  TF_DeleteSession(Session, Status);
  TF_DeleteSessionOptions(SessionOpts);
  TF_DeleteStatus(Status);
  TF_DeleteImportGraphDefOptions(GraphDefOpts);
```



## Conclusion
- The tensorflow/contrib/makefile/cmake is not really tested officially, only some demos were run on iOS/Android. If you don't mind the minor differences in performance, it is suitable for you.

## Contact
Open an issue or drop an email: csaba.kertesz@gmail.com
