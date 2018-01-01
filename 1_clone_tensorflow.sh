#!/bin/bash

# Get the directory where the script is stored
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo Usage: 1_clone_tensorflow.sh [branch_or_tag]
BRANCH=master
if [ "$#" -eq 1 ]; then
    BRANCH=$1
fi

#
# Clone the repository
#
cd $DIR
git clone https://github.com/tensorflow/tensorflow
cd tensorflow
git checkout $BRANCH
cd $DIR
