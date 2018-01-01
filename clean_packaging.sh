#!/bin/bash

# Get the directory where the script is stored
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Configure & build the package
cd $DIR/packaging
rm -rf debian/.debhelper debian/tensorflow-cpp-generic  debian/tensorflow-cpp-generic.debhelper.log debian/tensorflow-cpp-generic.substvars
rm -rf debian/debhelper-build-stamp debian/files
