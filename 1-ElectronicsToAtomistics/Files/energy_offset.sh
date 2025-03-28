#!/bin/bash -x



######################### INPUT FILE ##########################
### define input file variables
ELEMENT_NAME="Fe" # Periodic Table identifier of element
ELEMENT_AMU=55.845 # [g/mol], literature value for element
PSEUDOPOTENTIAL_FILENAME="Fe.pbe-spn-kjpaw_psl.0.2.1.UPF"
ELEMENT_POS=(
    0.00 # x
    0.00 # y
    0.00 # z
)
REFERENCE_STRUCTURE="bcc" # body-centered cubic
LATTICE_PARAMETER=2.866 # [angstrom], literature value for element
CUTOFF_ENERGY=90 # [Ry], make sufficiently large
MAX_ITER=500
MIXING_BETA=0.5
KPOINT=12 # k-points for convergence
KPOINTS=( # number of k-points (think as mesh grid element count)
    $KPOINT # x
    $KPOINT # y
    $KPOINT # z
)
KPOINTS_SHIFT=( # shift of `KPOINTS` in some direction
    0 # x
    0 # y
    0 # z
)
# working language to perform calculations and plot results
COMPUTING_LANGUAGE="Julia" # (recommended); can also be "Python"
NUM_PROC=$(nproc)   # grabs all cores available by default
UNDER_PROC=2        # number of cores to under-subscribe, if possible





# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# - - - - - - - END OF HUMAN EDITABLE SECTION - - - - - - - - #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #





set +x # turn script tracing off
computing_language=$(echo $COMPUTING_LANGUAGE | tr '[:upper:]' '[:lower:]')
if [[ "$computing_language" == "julia" ]]; then
    cl_ext="jl"
elif [[ "$computing_language" == "python" ]]; then
    cl_ext="py"
else
    echo "Variable COMPUTING_LANGUAGE=$COMPUTING_LANGUAGE \
        not understood. Must be either 'Julia' or 'Python'."
    exit
fi
num_proc=$(echo "$NUM_PROC - $UNDER_PROC" | bc)
if [[ $(nproc) -eq 1 ]]; then
    num_proc=1
elif [[ $num_proc -lt 1 ]]; then
    echo "(NUM_PROC=$NUM_PROC) - (UNDER_PROC=$UNDER_PROC) = \
        $num_proc which must be greater than 1."
    exit
# elif [[ $NUM_PROC - $UNDER_PROC -le $(nproc) ]]; then
    # num_proc=$NUM_PROC - $UNDER_PROC
fi



######################### INPUT FILE ##########################
### automatically define other `.in` file variables from inputs
reference_structure=$(echo $REFERENCE_STRUCTURE | tr '[:upper:]' '[:lower:]')
if [[ "$reference_structure" == "fcc" ]]; then
    ibrav=2
elif [[ "$reference_structure" == "bcc" ]]; then
    ibrav=3
else
    echo "Variable REFERENCE_STRUCTURE=$REFERENCE_STRUCTURE \
        not understood. Must be either 'fcc' or 'bcc'."
    exit
fi
echo "Based on $reference_structure, ibrav=$ibrav"
# '*1.88973' converts [angstrom] to [bohr]
# '*4' sets large value for offset
lattice_parameter_bohr=$(echo "$LATTICE_PARAMETER*1.88973*4" | bc -l)
input_filename="${ELEMENT_NAME}_offset" # name input file


### write input file
# input file
echo """ &control
    prefix=''
    outdir='temp'
    pseudo_dir = '../',
 /
 &system
    ibrav=  $ibrav, celldm(1) =$lattice_parameter_bohr, nat=  1, ntyp=  1,
    ecutwfc =$CUTOFF_ENERGY,
    occupations='smearing', smearing='mp', degauss=0.06
 /
 &electrons
    electron_maxstep =$MAX_ITER,
    mixing_beta =$MIXING_BETA,
 /
ATOMIC_SPECIES
 $ELEMENT_NAME  $ELEMENT_AMU $PSEUDOPOTENTIAL_FILENAME
ATOMIC_POSITIONS (alat)
 $ELEMENT_NAME ${ELEMENT_POS[0]} ${ELEMENT_POS[1]} ${ELEMENT_POS[2]}
K_POINTS (automatic)
 ${KPOINTS[0]} ${KPOINTS[1]} ${KPOINTS[2]} ${KPOINTS_SHIFT[0]} ${KPOINTS_SHIFT[1]} ${KPOINTS_SHIFT[2]}\
""" > "$input_filename.in"
# print input file to terminal
echo "========== Contents of $input_filename.in =========="
cat "$input_filename.in"
echo "========================================"



################### CALCULATE OFFSET ENERGY ###################
### execute QE with input parameters
echo "Executing QE according to $input_filename.in..."
(set -x;
    mpirun -np $num_proc --use-hwthread-cpus pw.x -in "$input_filename.in" \
        > "$input_filename.out" 2> /dev/null
)
rm -r "temp/" # remove calculations temporary folder


### grab `total energy`, which is in [Ry], from `.out` file
energy_offset=$( # grabs only the [Ry] value
    sed -n "s%\![[:space:]]*total energy[[:space:]]* = [[:space:]]*%%p" \
        "$input_filename.out" | head -1 | sed "s% Ry$%%"
)
# '*-13.6057' converts [Ry] to [eV]
energy_offset=$(echo "$energy_offset*-13.6057" | bc)
echo "Energy offset found to be $energy_offset eV"


### replace offset energies in companion scripts
sed -i "s%^energy_offset = [[:digit:]]*\.*[[:digit:]]*[^ #]%energy_offset = $energy_offset%" \
    "../0-Scripts/EvA_EvV_plot.$cl_ext"
sed -i "s%^ENERGY_OFFSET=[[:digit:]]*\.*[[:digit:]]*[^ #]%ENERGY_OFFSET=$energy_offset%" \
    "../2-KPointStudy/kpoint_study.sh"
sed -i "s%^ENERGY_OFFSET=[[:digit:]]*\.*[[:digit:]]*[^ #]%ENERGY_OFFSET=$energy_offset%" \
    "../3-GSFE/gsfe_create.sh"
sed -i "s%^ENERGY_OFFSET=[[:digit:]]*\.*[[:digit:]]*[^ #]%ENERGY_OFFSET=$energy_offset%" \
    "../3-GSFE/gsfe_process.sh"


### run Fortran codes on input files
# create appropriate input file to `ev_curve`
cp "$input_filename.in" "../0-Scripts/$reference_structure.ev.in"

# move to Scripts folder
cd "../0-Scripts"
gfortran -std=legacy -O2 "evfit.f" -o "evfit" 2> /dev/null # compiles `evfit.f` outputs `evfit`
# this outputs `evfit.4`: reference structure, lattice parameter
./ev_curve $reference_structure $LATTICE_PARAMETER 2> /dev/null
if [[ "$computing_language" == "julia" ]]; then
    julia "EvA_EvV_plot.jl" # generate plots
elif [[ "$computing_language" == "python" ]]; then
    python3 "EvA_EvV_plot.py" # generate plots
else
    echo "Variable COMPUTING_LANGUAGE=$COMPUTING_LANGUAGE \
        not understood. Must be either 'Julia' or 'Python'."
    exit
fi

# move all output files back to working directory
mv "$reference_structure.ev.in" "../1-EnergyOffset/"
mv "evfit" "../1-EnergyOffset/"
mv "EvsA" "../1-EnergyOffset/EvsA_offset"
mv "EvsV" "../1-EnergyOffset/EvsV_offset"
mv "SUMMARY" "../1-EnergyOffset/SUMMARY_offset"
mv "evfit.4" "../1-EnergyOffset/"
mv "pw_ev.out" "../1-EnergyOffset/"
mv "Name_of_EvA.png" "../1-EnergyOffset/"
mv "Name_of_EvV.png" "../1-EnergyOffset/"
mv "Name_of_Combined.png" "../1-EnergyOffset/"
rm -r "temp/" # remove calculations temporary folder


### post-process output files
# move back to working directory
cd "../1-EnergyOffset"
declare -a inputs=(
    "EvsA_offset"
    "EvsV_offset"
)
for input in "${inputs[@]}"; do
    echo -e -n "Opening $input to offset by $energy_offset eV...\r"
    i=1
    readarray file < $input
    for line in "${file[@]}"; do
        IFS=" " read -a elem <<< "$line"
        energy=${elem[1]}
        offset_energy=$(echo "$energy+$energy_offset" | bc)
        sed -i "${i}s% \-[[:digit:]]*\.[[:digit:]]*% $offset_energy%" "$input"
        i=$(echo "$i+1" | bc) # end line `i`
    done # end of `input` file
    echo -e -n "Closing $input...\r"
done # end of processing

# adjust summary file
echo -e -n "Adjusting summary files by $energy_offset eV...\r"
# previous energy value
energy=$(sed -n "s%^Equilibrium Energy per Atom    = %%p" "SUMMARY_offset")
# offset energy value
offset_energy=$(echo "$energy+$energy_offset" | bc)
# replace energy value
sed -i "s%^Equilibrium Energy per Atom    = \-[[:digit:]]*\.[[:digit:]]*%Equilibrium Energy per Atom    = $offset_energy%" \
    "SUMMARY_offset"
# get lattice parameter [angstrom]
lattice_parameter=$(sed -n "s%^Equilibrium lattice constant   = %%p" "SUMMARY_offset")
# previous bulk modulus [kbar]
bulk=$(sed -n "s%^Bulk Modulus (kbar)            = %%p" "SUMMARY_offset")
# convert to [GPa]
bulk_gpa=$(echo "scale=9;$bulk/10" | bc)
# replace bulk modulus
sed -i "s%^Bulk Modulus (kbar)            = [[:digit:]]*\.[[:digit:]]*%Bulk Modulus (GPa)             = $bulk_gpa%" \
    "SUMMARY_offset"

# print study summary to terminal
echo "                                                        "
cat "SUMMARY_offset"
echo -e -n "\nEnergy offset found to be $energy_offset eV\n"





# that's all folks