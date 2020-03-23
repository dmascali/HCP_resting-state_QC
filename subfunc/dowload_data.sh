#!/bin/bash

#set -e

SUBLIST=subject_list.txt
PATHAWS=/home/local/LAB_G1/danielem/.local/bin

declare -a PHASE_array=("LR" "RL")

while read -r subject
do
    echo "doing $subject"
	mkdir -p DATA/$subject
    
    for PHASE in "${PHASE_array[@]}"
    do
        for RUN in {1..2}
        do
            echo "$PHASE RUN$RUN"

            ${PATHAWS}/aws s3 cp \
            s3://hcp-openaccess/HCP_1200/$subject/MNINonLinear/Results/rfMRI_REST${RUN}_${PHASE}/Movement_Regressors.txt \
            DATA/$subject/rfMRI_REST${RUN}_${PHASE}_Movement_Regressors.txt \
            --region us-east-1

        done
    done

done < $SUBLIST

