# LUSE_ENGR851_ICME

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jmanthony3.github.io/LUSE_ENGR851_ICME)

Instructions to install Linux codes for Liberty University School of Engineering course ENGR 851: Integrated Computational Materials Engineering.
If host operating system is Windows, then use the Windows Subsystem for Linux (WSL) to install Ubuntu 20.04.

_This does not currently install the MATLAB tools MPCCalibration nor DMGfit._

The folders `1-ElectronicsToAtomistics`, `2-AtomisticsToDislocationMobility`, and `3-DislocationMobilityToCrystalPlasticity` each represent the first three bridges from lower length scales up to the continuum length scale and have similar, local file structures for homogeneous navigation at the Linux terminal.
The `setup.sh` script under each bridge has, at the top, user-defined variables to control the installation of codes and scripts and build the infrastructure to work at those length scales.
By default, the repository-level `setup.sh` (next to this README), executes each bridge `setup.sh` script with the user-defined variables at the top of those scripts.
To modify the installation of each bridge, modify the appropriate user-defined variables in each bridge-level `setup.sh` and either execute the repository-level `setup.sh` or run the bridge-level `setup.sh` as desired.

See the [documentation](https://jmanthony3.github.io/LUSE_ENGR851_ICME) for more details on installing the infrastructure and building of each bridge.