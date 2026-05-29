set -e
set -o pipefail

: "${SPL_TARGET:=60.0}"
: "${IC_DURATION:=100}"
: "${ROUGHNESS:=rough}"
: "${SAVEAT:=2e-5}"

: "${TOTAL_FILES:=700}"
: "${PARALLELISM:=16}"

export SPL_TARGET IC_DURATION ROUGHNESS SAVEAT TOTAL_FILES PARALLELISM

CTL_UP_ID=$(
    SUB_DIR=up \
        bsub < shell_scripts/ctl_process_audio_files/ctl_process_audio_files_hpc.sh |
    grep -oE "[0-9]+"
)
CTL_DOWN_ID=$(
    SUB_DIR=down \
        bsub < shell_scripts/ctl_process_audio_files/ctl_process_audio_files_hpc.sh |
    grep -oE "[0-9]+"
)
CTL_YES_ID=$(
    SUB_DIR=yes \
        bsub < shell_scripts/ctl_process_audio_files/ctl_process_audio_files_hpc.sh |
    grep -oE "[0-9]+"
)
CTL_NO_ID=$(
    SUB_DIR=no \
        bsub < shell_scripts/ctl_process_audio_files/ctl_process_audio_files_hpc.sh |
    grep -oE "[0-9]+"
)

COCHLEOGRAM_DATA_ID=$(
    TOTAL_FILES=$((TOTAL_FILES * 4)) \
        bsub -w "done($CTL_UP_ID) && done($CTL_DOWN_ID) && done($CTL_YES_ID) && done($CTL_NO_ID)" \
        < shell_scripts/cochleogram_process_ctl_files/cochleogram_process_ctl_files_hpc.sh |
    grep -oE "[0-9]+"
)

TOTAL_FILES=$((TOTAL_FILES * 4)) \
    bsub -w "done($COCHLEOGRAM_DATA_ID)" < shell_scripts/plot_cochleogram_data/plot_cochleogram_data_hpc.sh
