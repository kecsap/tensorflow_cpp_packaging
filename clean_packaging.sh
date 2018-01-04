#!/bin/bash

# Get the directory where the script is stored
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $DIR/packaging
rm -rf debian/.debhelper debian/tensorflow-cpp-*
rm -rf debian/debhelper-build-stamp debian/files
