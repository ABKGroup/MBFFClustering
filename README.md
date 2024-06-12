# High Quality, Scalable Multi-bit Flip-Flop Clustering

This repository contains all of our source codes and scripts used for our submitted paper, *"Scalable Flip-Flop Clustering Using Divide and Conquer For Capacitated $K$-Means"*.

<!-- #### Please refer to the following bullets for further guidance. -->
Directory Structure:
- [**Ours**](./Ours/README.md): Contains the code of our MBFF clustering method and details on how to run it.
- [**FTray**](./FTray/README.md): Contains the code of the FTray MBFF clustering method and details on how to run it.
- [**MShift**](./MShift/README.md): Contains the code of the MShift MBFF clustering method and details on how to run it.
- [**Scripts**](./Scripts/README.md): Contains the Innovus scripts used for the evaluation of the MBFF solution.
- [**ASAP7**](./ASAP7/README.md): Contains the ASAP7 library, including newly generated MBFF lib and lef files. Also, we provide the python scripts used to generate the MBFF lib and lef files.

```
├── ASAP7
│   ├── lef_3VT_TT
│   ├── lib_3VT_TT
│   ├── mbff_lef
│   ├── qrc
│   ├── README.md
│   └── util
├── FTray
│   ├── CMakeLists.txt
│   ├── FindCplex.cmake
│   ├── mbff.cpp
│   ├── mbff.h
│   └── README.md
├── MShift
│   ├── ArgumentParser.cpp
│   ├── ArgumentParser.h
│   ├── ArgumentParser.o
│   ├── BoostInclude.cpp
│   ├── BoostInclude.h
│   ├── BoostInclude.o
│   ├── Cluster.cpp
│   ├── Cluster.h
│   ├── Cluster.o
│   ├── clust_general.tcl
│   ├── def.cpp
│   ├── def.h
│   ├── def.o
│   ├── FF.cpp
│   ├── FF.h
│   ├── FF.o
│   ├── function_mbff.tcl
│   ├── input.txt
│   ├── LICENSE
│   ├── main.cpp
│   ├── main.o
│   ├── Makefile
│   ├── MeanShift.cpp
│   ├── MeanShift.h
│   ├── MeanShift.o
│   ├── Mgr.cpp
│   ├── Mgr.h
│   ├── Mgr.o
│   ├── out2.txt
│   ├── output.txt
│   ├── ParamMgr.cpp
│   ├── ParamMgr.h
│   ├── ParamMgr.o
│   ├── Parser.cpp
│   ├── Parser.h
│   ├── Parser.o
│   ├── post_process.py
│   ├── README.md
│   ├── StableMatching.cpp
│   ├── StableMatching.h
│   └── StableMatching.o
├── Ours
│   ├── CMakeLists.txt
│   ├── FindCplex.cmake
│   ├── mbff.cpp
│   ├── mbff.h
│   └── README.md
├── README.md
└── Scripts
    ├── design_setup.tcl
    ├── extract_report.tcl
    ├── lib_setup.tcl
    ├── mmmc_setup.tcl
    ├── README.md
    ├── run_invs.tcl
    └── run.sh
```

