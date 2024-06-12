## Innovus Scripts

This directory contains the Innovus scripts used for the evaluation of the MBFF solution. We downloaded the scripts from the [MacroPlacement](https://github.com/TILOS-AI-Institute/MacroPlacement) repo and modified it accordingly for our requirements. The required inputs are (1) design name and (2) handoff directory. The handoff directory should contain the following files:
- `<design>.v`: Updated netlist with the MBFF cells.
- `<design>_placed.def`: Updated DEF file with the MBFF cells.
- `<design>.sdc`: SDC file.

Please use the following command to launch the evaluation flow:
```
./run.sh <design> <handoff_dir>
```