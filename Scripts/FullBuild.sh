#!/bin/bash

cd "$(dirname "$0")" &&
./CompileShaders.sh &&
cd .. &&
swift build