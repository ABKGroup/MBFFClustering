# Steps to Run FTray Code
This directory contains the code for the FTray MBFF clustering method. We have 
integrated the FTray method into the OpenROAD infrastructure.

## Steps to Build OpenROAD and Run the PPA-Aware Clustering:
1. Clone OpenROAD using `git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git`
2. Copy the `mbff.cpp` and `mbff.h` files to the `OpenROAD/src/gpl/src/` directory.
3. Copy the `CMakeLists.txt` file to the `OpenROAD/src/gpl/` directory.
4. Copy the `FindCplex.cmake` file to the `OpenROAD/cmake/` directory.
5. Build OpenROAD using the following commands:
```bash
cd OpenROAD
mkdir build
cd build
cmake ..
make -j$(nproc)
```

## Steps to Run the MBFF Clustering:
1. Load the design using OpenROAD.
2. Run the following command to run the MBFF clustering:
```tcl
cluster_flops -tray_weight $env(TRAY_WEIGHT) \
              -timing_weight $env(TIMING_WEIGHT) \
              -max_split_size -1 \
```
3. Here, `TRAY_WEIGHT` and `TIMING_WEIGHT` represent \(\alpha\) and \(\beta\) respectively.