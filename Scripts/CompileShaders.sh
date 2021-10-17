#!/bin/bash

cd "$(dirname "$0")"
cd ../Sources/SteelPhoenixEngine/Shaders

for f in *.metal;
do
    echo "Compiling " $f
    xcrun metal -c $f -o $f.air
done

echo "Building test.metallib"
xcrun metal *.air -o test.metallib
