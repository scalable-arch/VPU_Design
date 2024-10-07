#!/bin/bash

cd ${VPU_HOME}/sim
rm -rf testvector

cd ${VPU_HOME}/sw/C/Goldenmodel/test_vector
python3 test_vector_gen.py
python3 test_vector_only_positive.py
cd ../
make clean
make run
