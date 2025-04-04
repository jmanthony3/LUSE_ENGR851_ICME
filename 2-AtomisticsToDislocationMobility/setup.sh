#!/bin/bash -x



#################### INSTALLATION VARIABLES ###################
# define install path for Ovito
OVITO_INSTALL_LOC=~/Ovito
# encode name and version of tarball
OVITO_VERSION="ovito-basic-3.7.2-x86_64"
# working language to perform calculations and plot results
COMPUTING_LANGUAGE="Julia" # (recommended); can also be "Python"



####################### MEAM PARAMETERS #######################
ELEMENT_NAME="Fe" # Periodic Table identifier of element





# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# - - - - - - - END OF HUMAN EDITABLE SECTION - - - - - - - - #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #





set +x # turn script tracing off
execution_dir=$(pwd) # where script executes from
who=$(whoami) # current user
mkdir "$execution_dir/logs" 2> /dev/null
if [[ "$#" -eq 0 ]]; then
    read -sp 'Password for sudo commands: ' pswd
    echo
else
    pswd=$1
fi



####################### INSTALL SOFTWARE ######################
# ### installing lammps
# # https://docs.lammps.org/Install_linux.html
# (set -x;
#     sudo add-apt-repository ppa:gladky-anton/lammps
#     sudo add-apt-repository ppa:openkim/latest
#     sudo apt-get update
#     sudo apt-get install lammps-stable
#     sudo apt-get update
#     sudo apt-get install lammps-stable-doc
#     sudo apt-get install lammps-stable-data
#     sudo apt-get install openkim-models
# )


### installing ovito
# https://www.ovito.org/linux-downloads/
# https://www.ovito.org/manual/installation.html
# copy tarball into installation directory
mkdir "$OVITO_INSTALL_LOC" 2> /dev/null
cp "Files/$OVITO_VERSION.tar.xz" "$OVITO_INSTALL_LOC/$OVITO_VERSION.tar.xz"
# unzip with `tar xJfv ovito-basic-X.X.X-*.tar.xz`
# show progress of untar and write log
echo "Extracting tarball of $OVITO_VERSION..."
(set -x;
    cd "$OVITO_INSTALL_LOC"
    tar xJfv "$OVITO_VERSION.tar.xz"
) 2> "$execution_dir/logs/ovito_untar.log" | pv -pterb --size 82228 >"$execution_dir/logs/ovito_untar.log"

# # set `ovito` as environment variable; change PATH as needed to Ovito `/bin/` folder
echo "Setting 'ovito' as environment variable..."
echo "export PATH=\"$OVITO_INSTALL_LOC/$OVITO_VERSION/bin:\$PATH\"" >> ~/.bashrc

# # update environment variables for user
echo "Updating environment variables for $who..."
(set -x; source ~/.bashrc)



################## SETUP DISLOCATION VELOCITY #################
### test directory
# copy/paste necessary files for example
cd "$execution_dir/Files"
mkdir "test" 2> /dev/null # make test folder
mkdir "test/RescaleUpload" 2> /dev/null
# copy (in/out)put files to `./test/RescaleUpload/`
cp "Cu.meam" "./test/RescaleUpload/$ELEMENT_NAME.meam"
cp "Dislocation.f90" "./test/RescaleUpload/"
cp "DisVelocity.in" "./test/RescaleUpload/"
cp "library.meam" "./test/RescaleUpload/"
cp "rescale_commands.sh" "./test/RescaleUpload/"
cp "atoms.sh" "./test/RescaleUpload/"


### populate `../Calculations/0-Scripts/`
mkdir "../Calculations/0-Scripts/" 2> /dev/null
cp "rescale_commands.sh" "../Calculations/0-Scripts/"
cp "atoms.sh" "../Calculations/0-Scripts/"
cp "dislocation_velocity.sh" "../Calculations/1-DislocationVelocity/"
cp "dislocation_position.jl" "../Calculations/1-DislocationVelocity/"
cp "dislocation_position.py" "../Calculations/1-DislocationVelocity/"
cp "dislocation_velocity.jl" "../Calculations/1-DislocationVelocity/"
cp "dislocation_velocity.py" "../Calculations/1-DislocationVelocity/"
cp "mddp.sh" "../Calculations/2-MDDP/"
cp "bcc.sh" "../Calculations/2-MDDP/"
cp "fcc.sh" "../Calculations/2-MDDP/"
cp "run.sh" "../Calculations/2-MDDP/"
cp "stress_strain.jl" "../Calculations/2-MDDP/"
cp "stress_strain.py" "../Calculations/2-MDDP/"


### get python3 packages for future scripts
computing_language=$(echo $COMPUTING_LANGUAGE | tr '[:upper:]' '[:lower:]')
if [[ "$computing_language" == "julia" ]]; then
    echo "Adding necessary Julia packages..."
    (set -x; julia "$execution_dir/packages.jl")
    # echo "Adding Ovito's Python API to manipulate data files..."
    # (echo $pswd) 2> /dev/null | sudo -S apt-get -y install python3-pip # install pip3
    # (set -x; python3 -m pip install ovito)
elif [[ "$computing_language" == "python" ]]; then
    (set -x;
        python3 -m pip install engineering_notation joby_m_anthony_iii ovito pandas sympy
    )
else
    echo "Variable COMPUTING_LANGUAGE=$COMPUTING_LANGUAGE \
        not understood. Must be either 'Julia' or 'Python'."
    exit
fi



########################## SETUP MDDP #########################
### populate `../Calculations/2-MDDP/`
# copy input data files to `../Calculations/2-MDDP/`
cp "datain" "../Calculations/2-MDDP/"
cp "data" "../Calculations/2-MDDP/"
(echo $pswd) 2> /dev/null | sudo -S apt-get -y install expect # allow execution of expect scripts

(set -x;
    (echo $pswd) 2> /dev/null | sudo -S apt-get -y install p7zip-full # get `7z` package
    7z x "MDDP.7z" # unarchive
)
# move into unarchived MDDP folder
cd "MDDP"
# ensure binaries are executable
chmod +x "BCCdata"
chmod +x "FCCdata"
chmod +x "MDDP08-2008"
# copy binaries
cp "BCCdata" "../../Calculations/2-MDDP/"
cp "FCCdata" "../../Calculations/2-MDDP/"
cp "MDDP08-2008" "../../Calculations/2-MDDP/"





echo "Bridge (2) installed!"
# that's all folks