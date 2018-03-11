#!/usr/bin/python3

'''
Tensorflow graph freezer
Converts Tensorflow trained models in .pb
Simplified and adapted by Csaba Kertész (csaba.kertesz@gmail.com)

Code adapted from:
https://gist.github.com/morgangiraud/249505f540a5e53a48b0c1a869d370bf#file-medium-tffreeze-1-py
'''

import os, argparse
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import tensorflow as tf
from tensorflow.python.framework import graph_util
from tensorflow.python.tools import optimize_for_inference_lib

parser = argparse.ArgumentParser(description="Tensorflow graph freezer\nConverts a checkpoint to a .pb file", prefix_chars='-')
parser.add_argument("-c", "--checkpoint", help = "checkpoint to export", type = str, required = True)
parser.add_argument("-p", "--protobuf", help = "output protobuf name", type = str, required = True)
parser.add_argument("-i", "--inputnode", help = "input tensor node name", type = str, default = "input/X")
parser.add_argument("-o", "--outputnode", help = "output tensor node name", type = str, default = "FullyConnected/Sigmoid")
args = parser.parse_args()

print("Input checkpoint:", args.checkpoint)

input_node = args.inputnode
output_nodes = args.outputnode

# We import the meta graph and retrieve a Saver
print("Importing:", args.checkpoint+'.meta')
saver = tf.train.import_meta_graph(args.checkpoint+'.meta', clear_devices = True)

# We retrieve the protobuf graph definition
graph = tf.get_default_graph()
graph_def = graph.as_graph_def()

# We start a session and restore the graph weights
with tf.Session() as sess:
  saver.restore(sess, args.checkpoint)

  # We use a built-in TF helper to export variables to constants
  output_graph_def = graph_util.convert_variables_to_constants(sess, graph_def, output_nodes.split(","))

  # Finally we serialize and dump the output graph to the filesystem
  with tf.gfile.GFile(args.protobuf, "wb") as f:
    f.write(output_graph_def.SerializeToString())

  print("%d ops in the final graph." % len(output_graph_def.node))

  print("Exporting protobuf:", args.protobuf)

  # Optimize for inference
  graph_def = tf.GraphDef()
  with tf.gfile.Open(args.protobuf, "rb") as f:
    data = f.read()
    graph_def.ParseFromString(data)

  print("Exporting optimized protobuf:", args.protobuf+".opt")
  output_graph_def = optimize_for_inference_lib.optimize_for_inference(graph_def, [input_node], [output_nodes],
                                                                       tf.float32.as_datatype_enum)
  # Save the optimized graph
  f = tf.gfile.FastGFile(args.protobuf+".opt", "w")
  f.write(output_graph_def.SerializeToString())

  print("Finished!")
