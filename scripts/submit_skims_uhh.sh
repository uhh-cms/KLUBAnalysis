#!/usr/bin/env bash
(return 0 2>/dev/null) && echo "This script must be run, not sourced. Try './' or 'bash'" && return 1

### Defaults
NO_LISTS="0"
STITCHING_OFF="0"
DRYRUN="0"
RESUBMIT="0"
OUT_TAG=""
IN_TAG="uhh_2017_v6"
DATA_PERIOD="UL17"
DATA_USER="${USER}"
DATA_PERIOD_CHOICES=( "UL2016preVFP" "UL2016postVFP" "UL17" "UL18" )

### Argument parsing
HELP_STR="Prints this help message."
DRYRUN_STR="(Boolean) Prints all the commands to be launched but does not launch them. Defaults to ${DRYRUN}."
RESUBMIT_STR="(Boolean) Resubmits failed jobs listed in 'badfiles.txt'"
OUT_TAG_STR="(String) Defines tag for the output. Defaults to '${OUT_TAG}'."
IN_TAG_STR="(String) Chooses tag for the input (big ntuples). Defaults to '${IN_TAG}'."
STITCHING_OFF_STR="(Boolean) Drell-Yan stitching weights will *not* be used. Defaults to ${STITCHING_OFF}."
NO_LISTS_STR="(Boolean) Whether to run the list production script before each submission. Defaults to ${NO_LISTS}."
DATAPERIOD_STR="(String) Which data period to consider: ${DATA_PERIOD_CHOICES}. Defaults to '${DATA_PERIOD}'."
DATAUSER_STR="(String) Which user produced the data. Defaults to '${DATA_USER}'."
function print_usage_submit_skims {
    USAGE="
        Run example: bash $(basename "$0") -t out_test --in_tag Jan2023 --user bfontana --dryrun

    -h / --help            [ ${HELP_STR} ]
    --dryrun            [ ${DRYRUN_STR} ]
    --resubmit            [ ${RESUBMIT_STR} ]
    -t / --tag            [ ${OUT_TAG_STR} ]
    --in_tag                [ ${IN_TAG_STR} ]
    -s / --no_stitching             [ ${STITCHING_OFF_STR} ]
    -n / --no_lists                 [ ${NO_LISTS_STR} ]
    -d / --data_period              [ ${DATAPERIOD_STR} ]
    -u / --user                     [ ${DATAUSER_STR} ]
"
    printf "${USAGE}"
}

while [[ $# -gt 0 ]]; do
    key=${1}
    case $key in
    -h|--help)
        print_usage_submit_skims
        exit 1
        ;;
    --dryrun)
        DRYRUN="1"
        shift;
        ;;
    --resubmit)
        RESUBMIT="1"
        shift;
        ;;
    -t|--tag)
        OUT_TAG=${2}
        shift; shift;
        ;;
    --in_tag)
        IN_TAG=${2}
        shift; shift;
        ;;
    -s|--no_stitching)
        STITCHING_OFF="1"
        shift;
        ;;
    -n|--no_lists)
        NO_LISTS="1"
        shift;
        ;;
    -d|--data_period)
        DATA_PERIOD=${2}
        if [[ ! " ${DATA_PERIOD_CHOICES[*]} " =~ " ${DATA_PERIOD} " ]]; then
            echo "Currently the following data periods are supported:"
            for dp in ${DATA_PERIOD_CHOICES[@]}; do
                echo "- ${dp}" # bash string substitution
            done
            exit 1;
        fi
        shift; shift;
        ;;
    -u|--user)
        DATA_USER=${2}
        shift; shift;
        ;;
    *)  # unknown option
        echo "Wrong parameter ${1}."
        exit 1
        ;;
    esac
done

declare -A REGEX_MAP
REGEX_MAP=(
    # Data
    ["SingleElectron_Run2017B"]="EGammaB"
    ["SingleElectron_Run2017C"]="EGammaC"
    ["SingleElectron_Run2017D"]="EGammaD"
    ["SingleElectron_Run2017E"]="EGammaE"
    ["SingleElectron_Run2017F"]="EGammaF"
    ["Tau_Run2017B"]="TauB"
    ["Tau_Run2017C"]="TauC"
    ["Tau_Run2017D"]="TauD"
    ["Tau_Run2017E"]="TauE"
    ["Tau_Run2017F"]="TauF"
    ["SingleMuon_Run2017B"]="MuonB"
    ["SingleMuon_Run2017C"]="MuonC"
    ["SingleMuon_Run2017D"]="MuonD"
    ["SingleMuon_Run2017E"]="MuonE"
    ["SingleMuon_Run2017F"]="MuonF"

    ["MET_Run2017B"]="METB"
    ["MET_Run2017C"]="METC"
    ["MET_Run2017D"]="METD"
    ["MET_Run2017E"]="METE"
    ["MET_Run2017F"]="METF"

    # Signal
    ["GluGluToRadionToHHTo2B2Tau_M-250_"]="Rad250"
    ["GluGluToRadionToHHTo2B2Tau_M-260_"]="Rad260"
    ["GluGluToRadionToHHTo2B2Tau_M-270_"]="Rad270"
    ["GluGluToRadionToHHTo2B2Tau_M-280_"]="Rad280"
    ["GluGluToRadionToHHTo2B2Tau_M-300_"]="Rad300"
    ["GluGluToRadionToHHTo2B2Tau_M-320_"]="Rad320"
    ["GluGluToRadionToHHTo2B2Tau_M-350_"]="Rad350"
    ["GluGluToRadionToHHTo2B2Tau_M-400_"]="Rad400"
    ["GluGluToRadionToHHTo2B2Tau_M-450_"]="Rad450"
    ["GluGluToRadionToHHTo2B2Tau_M-500_"]="Rad500"
    ["GluGluToRadionToHHTo2B2Tau_M-550_"]="Rad550"
    ["GluGluToRadionToHHTo2B2Tau_M-600_"]="Rad600"
    ["GluGluToRadionToHHTo2B2Tau_M-650_"]="Rad650"
    ["GluGluToRadionToHHTo2B2Tau_M-700_"]="Rad700"
    ["GluGluToRadionToHHTo2B2Tau_M-750_"]="Rad750"
    ["GluGluToRadionToHHTo2B2Tau_M-800_"]="Rad800"
    ["GluGluToRadionToHHTo2B2Tau_M-850_"]="Rad850"
    ["GluGluToRadionToHHTo2B2Tau_M-900_"]="Rad900"
    ["GluGluToRadionToHHTo2B2Tau_M-1000_"]="Rad1000"
    ["GluGluToRadionToHHTo2B2Tau_M-1250_"]="Rad1250"
    ["GluGluToRadionToHHTo2B2Tau_M-1500_"]="Rad1500"
    ["GluGluToRadionToHHTo2B2Tau_M-1750_"]="Rad1750"
    ["GluGluToRadionToHHTo2B2Tau_M-2000_"]="Rad2000"
    ["GluGluToRadionToHHTo2B2Tau_M-2500_"]="Rad2500"
    ["GluGluToRadionToHHTo2B2Tau_M-3000_"]="Rad3000"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-250_"]="Grav250"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-260_"]="Grav260"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-270_"]="Grav270"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-280_"]="Grav280"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-300_"]="Grav300"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-320_"]="Grav320"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-350_"]="Grav350"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-400_"]="Grav400"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-450_"]="Grav450"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-500_"]="Grav500"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-550_"]="Grav550"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-600_"]="Grav600"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-650_"]="Grav650"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-700_"]="Grav700"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-750_"]="Grav750"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-800_"]="Grav800"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-850_"]="Grav850"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-900_"]="Grav900"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-1000_"]="Grav1000"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-1250_"]="Grav1250"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-1500_"]="Grav1500"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-1750_"]="Grav1750"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-2000_"]="Grav2000"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-2500_"]="Grav2500"
    ["GluGluToBulkGravitonToHHTo2B2Tau_M-3000_"]="Grav3000"
    # Background
    ["TTToHadronic"]="TT_Hadronic"
    ["TTTo2L2Nu"]="TT_FullyLep"
    ["TTToSemiLeptonic"]="TT_SemiLep"

    ["DYJetsToLL_M-50_TuneCP5_13TeV-amc"]="DY_Incl"
    ["DYJetsToLL_LHEFilterPtZ-0To50"]="DY_PtZ0To50"
    ["DYJetsToLL_LHEFilterPtZ-50To100"]="DY_PtZ50To100"
    ["DYJetsToLL_LHEFilterPtZ-100To250"]="DY_PtZ100To250"
    ["DYJetsToLL_LHEFilterPtZ-250To400"]="DY_PtZ250To400"
    ["DYJetsToLL_LHEFilterPtZ-400To650"]="DY_PtZ400To650"
    ["DYJetsToLL_LHEFilterPtZ-650ToInf"]="DY_PtZ650ToInf"
    ["DYJetsToLL_0J"]="DY_0J"
    ["DYJetsToLL_1J"]="DY_1J"
    ["DYJetsToLL_2J"]="DY_2J"

    ["WJetsToLNu_TuneCP5_13TeV-madgraph"]="WJets_HT0To70" # for 0 < HT < 70
    ["WJetsToLNu_HT-70To100"]="WJets_HT70To100"
    ["WJetsToLNu_HT-100To200"]="WJets_HT100To200"
    ["WJetsToLNu_HT-200To400"]="WJets_HT200To400"
    ["WJetsToLNu_HT-400To600"]="WJets_HT400To600"
    ["WJetsToLNu_HT-600To800"]="WJets_HT600To800"
    ["WJetsToLNu_HT-800To1200"]="WJets_HT800To1200"
    ["WJetsToLNu_HT-1200To2500"]="WJets_HT1200To2500"
    ["WJetsToLNu_HT-2500ToInf"]="WJets_HT2500ToInf"

    ["EWKWPlus2Jets_WToLNu"]="EWKWPlus2Jets_WToLNu"
    ["EWKWMinus2Jets_WToLNu"]="EWKWMinus2Jets_WToLNu"
    ["EWKZ2Jets_ZToLL"]="EWKZ2Jets_ZToLL"

    ["ST_tW_antitop_5f_inclusive"]="ST_tW_antitop"
    ["ST_tW_top_5f_inclusive"]="ST_tW_top"
    ["ST_t-channel_antitop"]="ST_t-channel_antitop"
    ["ST_t-channel_top"]="ST_t-channel_top"

    ["GluGluHToTauTau"]="GluGluHToTauTau"
    ["VBFHToTauTau"]="VBFHToTauTau"
    ["WplusHToTauTau"]="WplusHToTauTau"
    ["WminusHToTauTau"]="WminusHToTauTau"
    ["ZHToTauTau"]="ZHToTauTau"

    ["ZH_HToBB_ZToLL"]="ZH_HToBB_ZToLL"
    ["ZH_HToBB_ZToQQ"]="ZH_HToBB_ZToQQ"

    ["ttHToNonbb"]="ttHToNonbb"
    ["ttHTobb"]="ttHTobb"
    ["ttHToTauTau"]="ttHToTauTau"

    ["WW_TuneCP5"]="WW"
    ["WZ_TuneCP5"]="WZ"
    ["ZZ_TuneCP5"]="ZZ"

    ["WWW"]="WWW"
    ["WWZ"]="WWZ"
    ["WZZ"]="WZZ"
    ["ZZZ"]="ZZZ"

    ["TTWJetsToLNu"]="TTWJetsToLNu"
    ["TTWJetsToQQ"]="TTWJetsToQQ"
    ["TTZToLLNuNu"]="TTZToLLNuNu"
    ["TTZToQQ"]="TTZToQQ"
    ["TTWW"]="TTWW"
    ["TTZZ"]="TTZZ"
    ["TTWZ"]="TTWZ"

    ["TTWH"]="TTWH"
    ["TTZH"]="TTZH"

    ["GluGluToHHTo2B2Tau_TuneCP5_PSWeights_node_SM"]="GluGluToHHTo2B2Tau"
)

### Setup variables
THIS_FILE="${BASH_SOURCE[0]}"
THIS_DIR="$( cd "$( dirname ${THIS_FILE} )" && pwd )"
KLUB_DIR="$( cd "$( dirname ${THIS_DIR} )" && pwd )"

EXEC_FILE="${KLUB_DIR}/bin"
SUBMIT_SCRIPT="scripts/skimNtuple_uhh.py"
LIST_SCRIPT="scripts/makeListOnStorage_uhh.py"
LIST_DIR="/pnfs/desy.de/cms/tier2/store/user/${DATA_USER}/"

EXEC_FILE="${EXEC_FILE}/skimNtuple_HHbtag.exe"
LIST_DIR=${LIST_DIR}"hbt_resonant_run2/HHNtuples/"

### Check if the voms command was run
eval `scram unsetenv -sh` # unset CMSSW environment
declare -a VOMS_CHECK=( $(gfal-ls -lH ${LIST_DIR} 2>/dev/null | awk '{{printf $9" "}}') )
if [ ${#VOMS_CHECK[@]} -eq 0 ]; then
    echo "Folder ${LIST_DIR} seems empty. Check the following:"
    echo "  - Are you sure you run 'voms-proxy-init -voms cms'?"
    echo "  - Are you sure '${DATA_USER}' is your right data storage username? (change it via the '-u / --user' option."
    exit 1
fi
cmsenv # set CMSSW environment
#voms-proxy-init -voms cms

SKIM_DIR="/nfs/dust/cms/user/${USER}/hbt_resonant_run2/HHSkims/"

IN_DIR=${KLUB_DIR}"/inputFiles/"
SIG_DIR=${IN_DIR}${DATA_PERIOD}"_Sig/"
BKG_DIR=${IN_DIR}${DATA_PERIOD}"_MC/"
DATA_DIR=${IN_DIR}${DATA_PERIOD}"_Data/"

if [ ${DATA_PERIOD} == "UL18" ]; then
    PU_DIR="weights/PUreweight/UL_Run2_PU_SF/2018/PU_UL2018_SF.txt"
    YEAR="2018"
elif [ ${DATA_PERIOD} == "UL17" ]; then
    PU_DIR="weights/PUreweight/UL_Run2_PU_SF/2017/PU_UL2017_SF.txt"
    YEAR="2017"
elif [ ${DATA_PERIOD} == "UL16preVFP" ]; then
    PU_DIR="weights/PUreweight/UL_Run2_PU_SF/2016/PU_UL2016_SF.txt"
    YEAR="2016preVFP"
elif [ ${DATA_PERIOD} == "UL16postVFP" ]; then
    PU_DIR="weights/PUreweight/UL_Run2_PU_SF/2016APV/PU_UL2016APV_SF.txt"
    YEAR="2016postVFP"
fi
CFG="config/skim_${DATA_PERIOD}.cfg"
PREF="SKIMS_"
TAG_DIR=${PREF}${DATA_PERIOD}"_"${OUT_TAG}
declare -a ERRORS=()
SEARCH_SPACE=".+\s.+" # trick to capture return values with error messages

declare -A IN_LIST DATA_MAP MC_MAP
declare -a DATA_LIST RUNS MASSES

### Argument parsing sanity checks
if [[ -z ${OUT_TAG} ]]; then
    printf "Select the tag via the '--tag' option. "
    declare -a tags=( $(/bin/ls -1 ${SKIM_DIR}) )
    if [ ${#tags[@]} -ne 0 ]; then
    echo "The following tags are currently available:"
    for tag in ${tags[@]}; do
        echo "- ${tag/${PREF}${DATA_PERIOD}_/}" # bash string substitution
    done
    else
    echo "No tags are currently available. Everything looks clean!"
    fi
    return 1;
fi
if [[ -z ${DATA_PERIOD} ]]; then
    echo "Select the data period via the '--d / --data_period' option."
    exit 1;
fi

mkdir -p ${SKIM_DIR}
OUTSKIM_DIR=${SKIM_DIR}/${TAG_DIR}/
if [ -d ${OUTSKIM_DIR} ] && [[ ${RESUBMIT} -eq 0 ]]; then
    echo "Directory ${OUTSKIM_DIR} already exists."
    echo "If you want to resubmit some jobs, add the '--resubmit' flag."
    echo "If not, you might want to remove the directory with: 'rm -r ${OUTSKIM_DIR}'."
    echo "Exiting."
    exit 1
else
    mkdir -p ${OUTSKIM_DIR}
fi
ERR_FILE=${OUTSKIM_DIR}"/bad_patterns.o"

if ((STITCHING_OFF)); then # test for True
    STITCHING_ON="0"
else
    STITCHING_ON="1"
fi

### Argument parsing: information for the user
echo "------ Arguments --------------"
echo "=== Passed by the user:"
printf "DRYRUN\t\t\t= ${DRYRUN}\n"
printf "RESUBMIT\t\t= ${RESUBMIT}\n"
printf "NO_LISTS\t\t= ${NO_LISTS}\n"
printf "OUT_TAG\t\t\t= ${OUT_TAG}\n"
printf "IN_TAG\t\t\t= ${IN_TAG}\n"
printf "STITCHING_OFF\t\t= ${STITCHING_OFF}\n"
printf "STITCHING_ON\t\t= ${STITCHING_ON}\n"
printf "DATA_PERIOD\t\t= ${DATA_PERIOD}\n"
printf "DATA_USER\t\t= ${DATA_USER}\n"
echo "=== Others:"
printf "OUTSKIM_DIR\t\t= ${OUTSKIM_DIR}\n"
echo "-------------------------------"

#### Source additional setup
make -j10 && make exe -j10
source scripts/setup.sh
#source /opt/exp_soft/cms/t3/t3setup
echo "-------- Run: $(date) ---------------" >> ${ERR_FILE}

### Submission command
function run_skim() {
    cmsenv # set CMSSW environment
    comm="python ${KLUB_DIR}/${SUBMIT_SCRIPT} --tag ${TAG_DIR} -o ${OUTSKIM_DIR} -c ${KLUB_DIR}/${CFG} "
    [[ ${RESUBMIT} -eq 1 ]] && comm+="--resub "
    comm+="--exec_file ${EXEC_FILE} -Y ${YEAR} -k 1 --pu ${PU_DIR} $@"
    [[ ${DRYRUN} -eq 1 ]] && echo ${comm} || ${comm}
}

### Input file list production command
function produce_list() {
    eval `scram unsetenv -sh` # unset CMSSW environment
    comm="python ${KLUB_DIR}/${LIST_SCRIPT} -t ${IN_TAG} --data_period ${DATA_PERIOD} --user ${DATA_USER} $@"
    echo $comm
    if [[ ${RESUBMIT} -eq 0 ]]; then
        [[ ${DRYRUN} -eq 1 ]] && echo ${comm} || ${comm}
    fi
    cmsenv # set CMSSW environment
}

### Extract sample full name
function find_sample() {
    nargs=$(( ${3}+3 ))
    if [ $# -ne ${nargs} ]; then
        echo "Wrong number of arguments - ${nargs} expected, $# provided"
        exit 1
    fi
    pattern=${1}
    list_dir=${2}
    lists=${@:4}
    sample=""
    nmatches=0
    for ldata in ${lists[@]}; do
        [[ ${ldata} =~ ${pattern} ]] && { sample=${BASH_REMATCH[0]}; nmatches=$(( ${nmatches} + 1 )); }
    done
    if [ ${nmatches} -eq 0 ]; then
        mes="The ${pattern} pattern was not found in ${list_dir} ."
        echo ${mes} >> ${ERR_FILE}
        echo ${mes}
        return 1
    elif [ ${nmatches} -gt 1 ]; then
        mes="The ${pattern} pattern had ${nmatches} matches in ${list_dir} ."
        echo ${mes} >> ${ERR_FILE}
        echo ${mes}
        return 1
    fi
    echo $sample
}

### Run on data samples
LIST_DATA_DIR=${LIST_DIR}${IN_TAG}
eval `scram unsetenv -sh` # unset CMSSW environment
declare -a LISTS_DATA=( $(gfal-ls -lH ${LIST_DATA_DIR} | awk '{{printf $9" "}}') )
cmsenv # set CMSSW environment

DATA_MAP=(
    ["SingleElectron_Run2017B"]="-n 50 --rt 24"
    ["SingleElectron_Run2017C"]="-n 50 --rt 24"
    ["SingleElectron_Run2017D"]="-n 50 --rt 24"
    ["SingleElectron_Run2017E"]="-n 50 --rt 24"
    ["SingleElectron_Run2017F"]="-n 50 --rt 24"

    ["Tau_Run2017B"]="-n 50 --rt 24 --datasetType 2"
    ["Tau_Run2017C"]="-n 50 --rt 24 --datasetType 2"
    ["Tau_Run2017D"]="-n 50 --rt 24 --datasetType 2"
    ["Tau_Run2017E"]="-n 50 --rt 24 --datasetType 2"
    ["Tau_Run2017F"]="-n 50 --rt 24 --datasetType 2"

    ["SingleMuon_Run2017B"]="-n 50 --rt 24"
    ["SingleMuon_Run2017C"]="-n 50 --rt 24"
    ["SingleMuon_Run2017D"]="-n 50 --rt 24"
    ["SingleMuon_Run2017E"]="-n 50 --rt 24"
    ["SingleMuon_Run2017F"]="-n 50 --rt 24"

    ["MET_Run2017B"]="-n 50 --rt 24 --datasetType 1"
    ["MET_Run2017C"]="-n 50 --rt 24 --datasetType 1"
    ["MET_Run2017D"]="-n 50 --rt 24 --datasetType 1"
    ["MET_Run2017E"]="-n 50 --rt 24 --datasetType 1"
    ["MET_Run2017F"]="-n 50 --rt 24 --datasetType 1"
)

# Skimming submission
for ds in ${!DATA_MAP[@]}; do
    if [ ${#LISTS_DATA[@]} -eq 0 ]; then
        echo "WARNING: No files found in "${LIST_DATA_DIR}"."
    fi
    sample=$(find_sample ${ds} ${LIST_DATA_DIR} ${#LISTS_DATA[@]} ${LISTS_DATA[@]})
    if [[ ${sample} =~ ${SEARCH_SPACE} ]]; then
        ERRORS+=( ${sample} )
    else
        eval `scram unsetenv -sh` # unset CMSSW environment
        [[ ${NO_LISTS} -eq 0 ]] && produce_list --kind Data --sample ${sample} --outtxt ${REGEX_MAP[${sample}]}
        cmsenv # set CMSSW environment
        run_skim --isdata 1 -i ${DATA_DIR} --sample ${REGEX_MAP[${sample}]} ${DATA_MAP[${ds}]}
        cmsenv # set CMSSW environment
    fi
done

### Run on HH resonant signal samples
LIST_SIG_DIR=${LIST_DIR}${IN_TAG}
eval `scram unsetenv -sh` # unset CMSSW environment
declare -a LISTS_SIG=( $(gfal-ls -lH ${LIST_SIG_DIR} | awk '{{printf $9" "}}') )
cmsenv # set CMSSW environment

DATA_LIST=( "GluGluToRad" "GluGluToBulkGrav" )
MASSES=("250" "260" "270" "280" "300" "320" "350" "400" "450" "500" "550" "600" "650" "700" "750" "800" "850" "900" "1000" "1250" "1500" "1750" "2000" "2500" "3000")
for ds in ${DATA_LIST[@]}; do
    for mass in ${MASSES[@]}; do
        pattern="${ds}.+_M-${mass}_";
        sample=$(find_sample ${pattern} ${LIST_SIG_DIR} ${#LISTS_SIG[@]} ${LISTS_SIG[@]})
        if [[ ${sample} =~ ${SEARCH_SPACE} ]]; then
            ERRORS+=( ${sample} )
        else
            [[ ${NO_LISTS} -eq 0 ]] && produce_list --kind Sig --sample ${sample} --outtxt ${REGEX_MAP[${sample}]}
            echo ${sample}
            run_skim -n 5 -i ${SIG_DIR} --sample ${REGEX_MAP[${sample}]} -x 1. --rt 4
        fi
    done
done

### Run on backgrounds samples
# ttbar inclusive cross-section: 791 +- 25 pb (https://arxiv.org/pdf/2108.02803.pdf)
# https://twiki.cern.ch/twiki/pub/CMSPublic/PhysicsResultsTOPSummaryFigures/tt_xsec_cms_13TeV.pdf
FullyHadXSec=`echo "791.0 * 0.6741 * 0.6741" | bc`
FullyLepXSec=`echo "791.0 * (1-0.6741) * (1-0.6741)" | bc`
SemiLepXSec=`echo "791.0 * 2 * (1-0.6741) * 0.6741" | bc`

ZH_HToBB_ZToQQ_BR=`echo "0.69911*0.5824" | bc`
ZH_HToBB_ZToLL_BR=`echo "(0.033696 +0.033662 + 0.033632)*0.5824" | bc`

MC_MAP=(
    ["TTToHadronic"]="-n 100 -x ${FullyHadXSec} --rt 4 --isTTlike"
    ["TTTo2L2Nu"]="-n 100 -x ${FullyLepXSec} --rt 24 --isTTlike"
    ["TTToSemiLeptonic"]="-n 100 -x ${SemiLepXSec} --rt 24 --isTTlike"

    ["DYJets.+_M-50_T.+amc"]="-n 300 -x 6077.22 -g ${STITCHING_ON} --DY 0 --rt 4 --isDYlike" # inclusive NLO
    ["DYJets.+_M-10to50"]="-n 300 -x 20490.0 --DY 0 --rt 4 --isDYlike" # low mass
    ["DYJetsToLL_LHEFilterPtZ-0To50"]="-n 300    -x 1409.22 -g ${STITCHING_ON} --DY 0 --rt 24 --isDYlike"
    ["DYJetsToLL_LHEFilterPtZ-50To100"]="-n 300  -x 377.12  -g ${STITCHING_ON} --DY 0 --rt 24 --isDYlike"
    ["DYJetsToLL_LHEFilterPtZ-100To250"]="-n 300 -x 92.24   -g ${STITCHING_ON} --DY 0 --rt 24 --isDYlike"
    ["DYJetsToLL_LHEFilterPtZ-250To400"]="-n 300 -x 3.512   -g ${STITCHING_ON} --DY 0 --rt 4 --isDYlike" # some jobs are killed even with a single file (in the short queue)
    ["DYJetsToLL_LHEFilterPtZ-400To650"]="-n 300 -x 0.4826  -g ${STITCHING_ON} --DY 0 --rt 4 --isDYlike"
    ["DYJetsToLL_LHEFilterPtZ-650ToInf"]="-n 300 -x 0.04487 -g ${STITCHING_ON} --DY 0 --rt 4 --isDYlike"
    ["DYJetsToLL_0J"]="-n 300 -x 4867.28  -g ${STITCHING_ON} --DY 0 --rt 4 --isDYlike"
    ["DYJetsToLL_1J"]="-n 300 -x 902.95   -g ${STITCHING_ON} --DY 0 --rt 4 --isDYlike"
    ["DYJetsToLL_2J"]="-n 300 -x 342.96   -g ${STITCHING_ON} --DY 0 --rt 4 --isDYlike"

    ["WJetsToLNu_T.+madgraph"]="-n 20 -x 48917.48 -y 1.213784 -z 70 --rt 4 --isDYlike" # for 0 < HT < 70
    ["WJetsToLNu_HT-70To100"]="-n 20 -x 1362 -y 1.213784 --rt 4 --isDYlike"
    ["WJetsToLNu_HT-100To200"]="-n 20 -x 1345 -y 1.213784 --rt 4 --isDYlike"
    ["WJetsToLNu_HT-200To400"]="-n 20 -x 359.7 -y 1.213784 --rt 4 --isDYlike"
    ["WJetsToLNu_HT-400To600"]="-n 20 -x 48.91 -y 1.213784 --rt 4 --isDYlike"
    ["WJetsToLNu_HT-600To800"]="-n 20 -x 12.05 -y 1.213784 --rt 4 --isDYlike"
    ["WJetsToLNu_HT-800To1200"]="-n 20 -x 5.501 -y 1.213784 --rt 4 --isDYlike"
    ["WJetsToLNu_HT-1200To2500"]="-n 20 -x 1.329 -y 1.213784 --rt 4 --isDYlike"
    ["WJetsToLNu_HT-2500ToInf"]="-n 20 -x 0.03216 -y 1.213784 --rt 4 --isDYlike"

    ["EWKWPlus2Jets_WToLNu"]="-n 100 -x 25.62 --rt 4 --isDYlike"
    ["EWKWMinus2Jets_WToLNu"]="-n 100 -x 20.25 --rt 4 --isDYlike"
    ["EWKZ2Jets_ZToLL"]="-n 100 -x 3.987 --rt 4 --isDYlike"

    ["ST_tW_antitop_5f_inclusive"]="-n 80 -x 35.85 --rt 4 --isTTlike"
    ["ST_tW_top_5f_inclusive"]="-n 80 -x 35.85 --rt 4 --isTTlike"
    ["ST_t-channel_antitop"]="-n 80 -x 80.95 --rt 4 --isTTlike"
    ["ST_t-channel_top"]="-n 80 -x 136.02 --rt 4 --isTTlike"

    ["GluGluHToTauTau"]="-n 30 -x 48.68 -y 0.06272 --rt 4 --isDYlike"
    ["VBFHToTauTau"]="-n 30 -x 3.766 -y 0.06272 --rt 4 --isDYlike"
    ["WplusHToTauTau"]="-n 30 -x 0.831 -y 0.06272 --rt 4 --isDYlike"
    ["WminusHToTauTau"]="-n 30 -x 0.527 -y 0.06272 --rt 4 --isDYlike"
    ["ZHToTauTau"]="-n 30 -x 0.880 -y 0.06272 --rt 4 --isDYlike"

    ["^ZH_HToBB_ZToLL"]="-n 30 -x 0.880 -y ${ZH_HToBB_ZToLL_BR} --rt 4 --isDYlike"
    ["ZH_HToBB_ZToQQ"]="-n 30 -x 0.880 -y ${ZH_HToBB_ZToQQ_BR} --rt 4 --isDYlike"

    ["ttHToNonbb"]="-n 100 -x 0.5071 -y 0.3598 --rt 4 --isTTlike"
    ["ttHTobb"]="-n 100 -x 0.5071 -y 0.577 --rt 4 --isTTlike"
    ["ttHToTauTau"]="-n 500 -x 0.5071 -y 0.0632 --rt 4 --isTTlike"

    ["^WW_TuneCP5"]="-n 30 -x 118.7 --rt 4 --isDYlike"
    ["^WZ_TuneCP5"]="-n 30 -x 47.13 --rt 4 --isDYlike"
    ["^ZZ_TuneCP5"]="-n 30 -x 16.523 --rt 4 --isDYlike"

    ["WWW"]="-n 20 -x 0.209 --rt 4 --isDYlike"
    ["WWZ"]="-n 20 -x 0.168 --rt 4 --isDYlike"
    ["WZZ"]="-n 20 -x 0.057 --rt 4 --isDYlike"
    ["ZZZ"]="-n 20 -x 0.0147 --rt 4 --isDYlike"

    ["TTWJetsToLNu"]="-n 20 -x 0.2043 --rt 4 --isTTlike"
    ["TTWJetsToQQ"]="-n 20 -x 0.4062 --rt 4 --isTTlike"
    ["TTZToLLNuNu"]="-n 20 -x 0.2529 --rt 24 --isTTlike"
    ["TTZToQQ"]="-n 20 -x 0.5104 --rt 24 --isTTlike"
    ["TTWW"]="-n 20 -x 0.006979 --rt 4 --isTTlike"
    ["TTZZ"]="-n 20 -x 0.001386 --rt 4 --isTTlike"
    ["TTWZ"]="-n 20 -x 0.00158 --rt 4 --isTTlike"

    ["TTWH"]="-n 20 -x 0.001143 --rt 4 --isTTlike"
    ["TTZH"]="-n 20 -x 0.001136 --rt 4 --isTTlike"

    ["GluGluToHHTo2B2Tau_TuneCP5_PSWeights_node_SM"]="-n 20 -x 0.01618 --rt 5 --isDYlike"
)

# Sanity checks for Drell-Yan stitching
DY_PATTERN=".*DY.*"
dy_counter=0

LIST_MC_DIR=${LIST_DIR}${IN_TAG}
eval `scram unsetenv -sh` # unset CMSSW environment
declare -a LISTS_MC=( $(gfal-ls -lH ${LIST_MC_DIR} | awk '{{printf $9" "}}') )
cmsenv # set CMSSW environment

for ds in ${!MC_MAP[@]}; do
    sample=$(find_sample ${ds} ${LIST_MC_DIR} ${#LISTS_MC[@]} ${LISTS_MC[@]})
    if [[ ${sample} =~ ${DY_PATTERN} ]]; then
        dy_counter=$(( dy_counter+1 ))
    fi
done
if [ ${STITCHING_OFF} -eq 0 ]; then
    if [ ${dy_counter} -eq 0 ]; then
        echo "The DY stitching is on while considering no DY samples. Did you forget to include the '-s' flag?"
        exit 1
    elif [ ${dy_counter} -eq 1 ]; then
        echo "You set the DY stitching on while considering a single DY sample. This is incorrect."
        exit 1
    fi
fi

# Skimming submission
for ds in ${!MC_MAP[@]}; do
    sample=$(find_sample ${ds} ${LIST_MC_DIR} ${#LISTS_MC[@]} ${LISTS_MC[@]})
    if [[ ${sample} =~ ${SEARCH_SPACE} ]]; then
        ERRORS+=( ${sample} )
    else
        eval `scram unsetenv -sh` # unset CMSSW environment
        [[ ${NO_LISTS} -eq 0 ]] && produce_list --kind MC --sample ${sample} --outtxt ${REGEX_MAP[${sample}]}
        cmsenv # set CMSSW environment
        run_skim -i ${BKG_DIR} --sample ${REGEX_MAP[${sample}]} ${MC_MAP[${ds}]}
        cmsenv # set CMSSW environment
    fi
done

### Print pattern matching issues
nerr=${#ERRORS[@]}
if [ ${nerr} -ne 0 ]; then
    echo "WARNING: The following pattern matching errors were observed:"
fi
for ((i = 0; i < ${nerr}; i++)); do
    echo "  - ${ERRORS[$i]}"
done

if [ ${DRYRUN} -eq 1 ]; then
    echo "Dry run. The commands above were not run."
fi

###### Cross-section information ######

### TT
# xsec from HTT http://cms.cern.ch/iCMS/user/noteinfo?cmsnoteid=CMS%20AN-2019/109
# TT x section: 831.76 for inclusive sample, W->had 67,60% , W->l nu 3*10,8% = 32,4% (sum over all leptons)
# hh = 45.7%, ll = 10.5%, hl = 21.9% (x2 for permutation t-tbar)

### DY
# xsec from https://twiki.cern.ch/twiki/bin/viewauth/CMS/SummaryTable1G25ns#DY_Z

### Electroweak
# xsec from HTT http://cms.cern.ch/iCMS/user/noteinfo?cmsnoteid=CMS%20AN-2019/109

### Single Top
# xsec from HTT http://cms.cern.ch/iCMS/user/noteinfo?cmsnoteid=CMS%20AN-2019/109

### SM Higgs
# from https://twiki.cern.ch/twiki/bin/view/LHCPhysics/CERNHLHE2019

### HXSWG: xs(ZH) = 0.880 pb, xs(W+H) = 0.831 pb, xs(W-H) = 0.527 pb, xs(ggH) = 48.61 pb, xs(VBFH) = 3.766 pb, xs(ttH) = 0.5071 pb
# Z->qq : 69.91% , Z->ll : 3,3658% (x3 for all the leptons), H->bb : 57.7%  , H->tautau : 6.32%
# ZH (Zll, Hbb) : XSBD (xs ZH * BR Z) * H->bb, ZH (Zqq, Hbb) : XSBD (xs ZH * BR Z) * H->bb
# ZH (Zall, Htautau) : XS teor ZH * BR H->tautau

### Multiboson
# xsec from https://arxiv.org/abs/1408.5243 (WW), https://twiki.cern.ch/twiki/bin/viewauth/CMS/SummaryTable1G25ns#Diboson (WZ,ZZ)
# Some XS Taken from HTT http://cms.cern.ch/iCMS/user/noteinfo?cmsnoteid=CMS%20AN-2019/109
# Some other XS taken from http://cms.cern.ch/iCMS/jsp/db_notes/noteInfo.jsp?cmsnoteid=CMS%20AN-2019/111
