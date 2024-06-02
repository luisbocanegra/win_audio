#!/bin/sh

# Remove the build directory if it exists
if [ -d "build" ]; then
    rm -rf build
fi


# install plasmoid only
cmake -B build -S . -DINSTALL_SCRIPT=ON -DCMAKE_INSTALL_PREFIX=~/.local

# Build the project
cmake --build build

# Install the built project
cmake --install build
