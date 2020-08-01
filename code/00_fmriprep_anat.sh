#!/bin/bash
#SBATCH --job-name=fmriprep_anat
#SBATCH --output=logs/%x_%j.out 
#SBATCH --nodes=1
#SBATCH --cpus-per-task=40
#SBATCH --time=24:00:00


SUB_SIZE=5 ## number of subjects to run
CORES=40
export THREADS_PER_COMMAND=2

STUDY='ds000201_preproc'

## set up a trap that will clear the ramdisk if it is not cleared
function cleanup_ramdisk {
    echo -n "Cleaning up ramdisk directory /$SLURM_TMPDIR/ on "
    date
    rm -rf /$SLURM_TMPDIR
    echo -n "done at "
    date
}

#trap the termination signal, and call the function 'trap_term' when
# that happens, so results may be saved.
trap "cleanup_ramdisk" TERM

# input is BIDS_DIR
export BIDS_DIR=${SCRATCH}/${STUDY}/data/input/bids

## these folders envs need to be set up for this script to run properly - see top README
export FMRIPREP_HOME=$SCRATCH/fmriprep_home
export SING_CONTAINER=${SCRATCH}/${STUDY}/envs/fmriprep-20.1.1.simg


## setting up the output folders
export OUTPUT_DIR=${SCRATCH}/${STUDY}/data/derived/
# export LOCAL_FREESURFER_DIR=${SCRATCH}/${STUDY}/data/derived/freesurfer-6.0.1
export WORK_DIR=${BBUFFER}/${STUDY}/fmriprep
export LOGS_DIR=${SCRATCH}/${STUDY}/logs
mkdir -vp ${OUTPUT_DIR} ${WORK_DIR} ${LOGS_DIR} # ${LOCAL_FREESURFER_DIR}

## get the subject list from a combo of the array id, the participants.tsv and the chunk size
bigger_bit=`echo "($SLURM_ARRAY_TASK_ID + 1) * ${SUB_SIZE}" | bc`
SUBJECTS=`sed -n -E "s/sub-(\S*)\>.*/\1/gp" ${BIDS_DIR}/participants.tsv | head -n ${bigger_bit} | tail -n ${SUB_SIZE}`

## set singularity environment variables that will point to the freesurfer license and the templateflow bits
export SINGULARITYENV_TEMPLATEFLOW_HOME=/home/fmriprep/.cache/templateflow
# Make sure FS_LICENSE is defined in the container.
export SINGULARITYENV_FS_LICENSE=/home/fmriprep/.freesurfer.txt

# # Remove IsRunning files from FreeSurfer
# for subject in $SUBJECTS: do
#     find ${LOCAL_FREESURFER_DIR}/sub-$subject/ -name "*IsRunning*" -type f -delete
# done

cd ${SCRATCH}/${STUDY}

singularity run --cleanenv \
    -B ${SCRATCH}/fmriprep_home:/home/fmriprep --home /home/fmriprep \
    -B ${WORK_DIR}:/work \
    ${SING_CONTAINER} \
    data/input/bids data/derived participant \
    --participant_label ${SUBJECTS} \
    -w /work \
    --skip-bids-validation \
    --omp-nthreads 8 \
    --output-space T1w MNI152NLin2009cAsym \
    --use-aroma \
    --notrack \
    --cifti-output 91k \
    --anat-only 

exitcode=$?

 #   -B ${BIDS_DIR}:/bids \
 #   -B ${OUTPUT_DIR}:/out \
 #   -B ${LOCAL_FREESURFER_DIR}:/fsdir \

# Output results to a table
for subject in $SUBJECTS; do
echo "sub-$subject   ${SLURM_ARRAY_TASK_ID}    $exitcode" \
      >> ${LOGS_DIR}/${SLURM_JOB_NAME}.${SLURM_ARRAY_JOB_ID}.tsv
done
echo Finished tasks ${SLURM_ARRAY_TASK_ID} with exit code $exitcode
exit $exitcode
