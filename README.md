# LUSE_ENGR851_ICME

<!-- [![Documentation](https://github.com/jmanthony3/LUSE_ENGR851_ICME/actions/workflows/Documentation.yml/badge.svg)](https://github.com/jmanthony3/LUSE_ENGR851_ICME/actions/workflows/Documentation.yml) -->

Instructions to install Linux codes for Liberty University School of Engineering course ENGR 851: Integrated Computational Materials Engineering.
If host operating system is Windows, then use the Windows Subsystem for Linux (WSL) to install Ubuntu 20.04.

_This does not currently install the MATLAB tools MPCCalibration nor DMGfit._

The folders `1-ElectronicsToAtomistics`, `2-AtomisticsToDislocationMobility`, and `3-DislocationMobilityToCrystalPlasticity` each represent the first three bridges from lower length scales up to the continuum length scale and have similar, local file structures for homogeneous navigation at the Linux terminal.
The `setup.sh` script under each bridge has, at the top, user-defined variables to control the installation of codes and scripts and build the infrastructure to work at those length scales.
By default, the repository-level `setup.sh` (next to this README), executes the bridge `setup.sh` scripts with the user-defined variables at the top of those scripts.
To modify the installation of each bridge, then modify the appropriate user-defined variables and either execute the repository-level `setup.sh` or run the bridge-level `setup.sh` as desired.

See the 