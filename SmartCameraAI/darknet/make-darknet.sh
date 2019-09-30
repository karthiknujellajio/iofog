#!/usr/bin/env sh

if type nvcc &> /dev/null; then
    echo "Making Darknet..."
    make GPU=1 OPENCV=1 LIBSO=1 -j
else
    echo "Making Darknet without GPU Functionality..."
    make OPENCV=1 LIBSO=1 -j
fi

tail -f /dev/null