# Tensorflow C/C++ inference with Debian packages on Ubuntu x86_64 and Raspberry Pi

- The build is based on the "TensorFlow Makefile" component in tensorflow/contrib/makefile directory.
- Two targets were tested: Ubuntu Xenial (x86_64) and Raspberry Pi (armhf).
- Both static and shared Tensorflow libraries. The choice is on your side.
- Only CPU can be used for inference.
- Debian packages are generated from the built binary files for distribution.
- The build contains e.g. the C/C++ API to load model "snapshots". New ops can be easily added by modifying the [tf_tensor_fix.txt](tf_tensor_fix.txt).

## Status

I trained a simple CNN model with TFLearn for a 2-label classification and the inference works on Ubuntu and Raspberry Pi, however, there are differences in the accuracies:

| Platform         | Class 1 | Class 2 |
|------------------|:-------:|:-------:|
| Python           | 95.26 % | 95.69 % |
| Ubuntu C/C++     | 95.12 % | 95.57 % |
| Raspberry Pi C++ | 97.23 % | 83.73 % |

These results are generated with the same frozen graph (.pb file). As you can see, the C/C++ inference does not provide 100 % reproducible results vs. the Python inference.

## Releases

- You can download the releases from [here](https://github.com/kecsap/tensorflow_cpp_packaging/releases/latest).

## Manual compilation

### Requirements

- Basic dependencies must be installed like make, g++, cmake...:
```
sudo apt-get install make g++-6 cmake git dpkg-dev debhelper quilt python3
```
   Note: Gcc 6 is needed for the build process because gcc 5 has a linking bug and Tensorflow does not compile with the shipped gcc 5 in Ubuntu Xenial. Gcc 6 can be installed from [this PPA](https://launchpad.net/~ubuntu-toolchain-r/+archive/ubuntu/test).
   
- The cross-compiled binary for Raspberry does not work, it crashes, therefore, Tensorflow must be compiled natively on the Raspberry Pi. It takes a lot time (6-8 hours?), but extra swap space is not necessary. I restricted the build process to 2 parallel jobs to avoid unresponsive Raspberry Pi because of running out of memory.

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

## Save a checkpoint in Python (TFLearn)

The standard, saved checkpoints in TFLearn are not good because they contain the training ops and those must be deleted before saving a checkpoint. I provide an example how the checkpoints can be saved inside a TFLearn callback:

```
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
```
./tf_freezer.py -c my_checkpoint -p final_model.pb -i Input/X -o Fc2/Sigmoid
```
The above example assumes that you have three files related to a checkpoint inside the directory with my_checkpoint prefix (e.g. my_checkpoint.meta). The script will create a frozen protobuf model (final_model.pb). You must specify the input and output tensors with -i and -o. The default input tensor name is Input/X and the default output tensor name is FullyConnected/Sigmoid.

## CMake support

Once you installed the Debian package of this project, CMake support is provided for Tensorflow inference in your C++ project.

```
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

```
#include <tensorflow/core/protobuf/meta_graph.pb.h>
#include <tensorflow/core/public/session.h>

tensorflow::MetaGraphDef GraphDef;
tensorflow::Session* Session = nullptr;

void LoadGraph()
{
  const std::string PathToGraph = "my_checkpoint.meta";
  const std::string CheckpointPrefix = "my_checkpoint";

  Session = tensorflow::NewSession(tensorflow::SessionOptions());
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
  tensorflow::Tensor 
  
  Tensor(tensorflow::DT_STRING, tensorflow::TensorShape());

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
}
```

## Load a frozen model in C++

Loading a frozen model is much more simple than loading a checkpoint:
```
#include <tensorflow/core/protobuf/meta_graph.pb.h>
#include <tensorflow/core/public/session.h>

tensorflow::GraphDef GraphDef;
tensorflow::Session* Session = nullptr;

void LoadGraph()
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
}
```

## Inference in C++

```
void Predict()
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
}
```

## Load a frozen model in C

Loading a frozen model is with the C API:
```
#include <tensorflow/c/c_api.h>

TF_Status* Status = NULL;
TF_Graph* Graph = NULL;
TF_ImportGraphDefOptions* GraphDefOpts = NULL;
TF_Session* Session = NULL;
TF_SessionOptions* SessionOpts = NULL;
TF_Buffer* GraphDef = NULL;

void LoadGraph()
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
}
```

## Inference in C

```
void Predict()
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
}
```

Remember to release the allocated resources in the end:

```
  TF_DeleteGraph(Graph);
  TF_DeleteSession(Session, Status);
  TF_DeleteSessionOptions(SessionOpts);
  TF_DeleteStatus(Status);
  TF_DeleteImportGraphDefOptions(GraphDefOpts);
```



## Conclusion
- The tensorflow/contrib/makefile is not really tested officially, only some demos were run on iOS/Android. If you don't mind the minor differences in performance, it is suitable for you.

## Contact
Open an issue or drop an email: csaba.kertesz@gmail.com
