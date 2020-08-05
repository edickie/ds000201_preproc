# ds000201_preproc

preprocessing and feature extraction for ds0000201

pulling the datalad container into envs to version control content

# To download the repo to another machine

```
git clone https://github.com/edickie/ds000201_preproc.git
```

location of this repo on the CAMH Scientific Computing Cluster (with the data folders) is:

`/external/rprshnas01/netdata_kcni/edlab/ds000201_preproc`

## Contents

- General Overview and Objectives for the use of this project (given by the data knights)

- Neuroimaging Learning Resources
  - Our recent course for BIDS data organization and proprocessing [here](https://hackmd.io/@O7pajo3zQEeZez6H0a7Y0g/ryEKNEi1w)
  - Our recent course on python neuroimaing anaylsis - with nilearn [here](https://hackmd.io/tTKLXfNtR5-VlqMmiIVJEQ)
- [Downloading the raw data](#getting-the-raw-data)
- [Data Preprocessing Steps](#preprossesing)
  
## General Research Goals

We will be working with data from the  [The Stockholm Sleepy Brain Study open data set](https://openneuro.org/datasets/ds000201/versions/1.0.3).

- [Primary Deliverable] Multiclass Classification of the specific "task" being performed by the subject, based on the fMRI images in the dataset.
- [Stretch Goal #1] Unsupervised Machine Learning feature generation on the full dataset. Looking for correlation between "tasks" being performed by subject with the aim of learning more about how the tasks are represented in the fMRI data.
- [Stretch Goal #2] Identify any correlation of the generated/existing features with the numerical "sleepiness" scale as ranked in the sleepiness task. End goal is to predict "sleepiness" rating based on analyzed fMRI data.

## Neuroimaging Learning Resources

The data is available on openneuro.org and is organized according to the Brain Imaging Data Structure (BIDS). Meaning that certain important peices of information is implied according to the naming convention of the files and/or encoded in specific places (i.e. participant information is in a participants.tsv file). [The BIDS specification is available here](https://bids-specification.readthedocs.io/en/stable/) 

- Our recent course for BIDS data organization and proprocessing [here](https://hackmd.io/@O7pajo3zQEeZez6H0a7Y0g/ryEKNEi1w)
- Our recent course on python neuroimaing anaylsis - with nilearn [here](https://hackmd.io/tTKLXfNtR5-VlqMmiIVJEQ)
- There are also some amazing resources at the ongoing [neurohackademy](https://neurohackademy.org/) course.

## Getting the raw data

Note: the full raw data download is about 176G. I wanted to pull the data using datalad - but the datalad repo had broken download links.. So instead this data was pulled using the amazon-cli (in a singularity container).

### Pulling the amazon cli container

On the SSC this was Run 2020-07-30, singularity version 3.5.3

```sh
# module load singularity
# note run this from the repository root i.e. ds000201_preproc folder
singularity build envs/aws-cli.sif docker://amazon/aws-cli
```

The data download 

```sh
singularity run envs/aws-cli.sif s3 sync --no-sign-request s3://openneuro.org/ds000201 data/input/bids/
```

for reason's i do not understand the dataset_description and participants.tsv did not get pulled down from the s3 bucket - so I will pull those separately..

```sh
cd data/input/bids
wget https://openneuro.org/crn/datasets/ds000201/snapshots/1.0.3/files/participants.tsv
wget https://openneuro.org/crn/datasets/ds000201/snapshots/1.0.3/files/dataset_description.json
```

## Preprossesing

To preprocess we will use the current stable release of fmriprep

```sh
singularity build envs/fmriprep-20.1.1.simg docker://poldracklab/fmriprep:20.1.1
```

Testing and setting up for the singularity run..

we need a copy of the freesurfer license to be in:

```sh
$SCRATCH/fmriprep_home/.freesurfer.license
```
Testing the singularity binds..

```sh
cd $SCRATCH/ds000201_preproc

singularity shell --cleanenv \
    -B ${SCRATCH}/fmriprep_home:/home/fmriprep --home /home/fmriprep \
    envs/fmriprep-20.1.1.simg
```

From inside the container - set up templateflow (note due this before submitting a job)

```
python -c "from templateflow.api import get; get(['MNI152NLin2009cAsym', 'MNI152NLin6Asym'])"
python -c "from templateflow.api import get; get(['fsaverage', 'fsLR'])"
python -c "from templateflow.api import get; get(['OASIS30ANTs'])"
```

### submitting the fmriprep_anat step

```sh
## go to the repo and pull new changes
cd $SCRATCH/ds000201_preproc
git pull

## calculate the length of the array-job given 
SUB_SIZE=5
N_SUBJECTS=$(( $( wc -l data/input/bids/participants.tsv | cut -f1 -d' ' ) - 1 ))
array_job_length=$(echo "$N_SUBJECTS/${SUB_SIZE}" | bc)
echo "number of array is: ${array_job_length}"

## submit the array job to the queue
sbatch --array=0-${array_job_length} $SCRATCH/ds000201_preproc/code/00_fmriprep_anat.sh

```

### How to run the second step - func..

```sh
## go the repo and pull new changes
cd $SCRATCH/ds000201_preproc
git pull

## figuring out appropriate array-job size
SUB_SIZE=1 # for func the sub size is moving to 1 participant because there are two runs and 8 tasks per run..
N_SUBJECTS=$(( $( wc -l data/input/bids/participants.tsv | cut -f1 -d' ' ) - 1 ))
array_job_length=$(echo "$N_SUBJECTS/${SUB_SIZE}" | bc)
echo "number of array is: ${array_job_length}"

## submit the array-job
sbatch --array=0-${array_job_length} $SCRATCH/ds000201_preproc/code/01_fmriprep_func.sh
```

Update - when looking at the QA pages - the fieldmap correction runs look worse than the syth corrected runs - so we will rerun everything with the --ignore-fieldmap flag.. urg

```sh
## go the repo and pull new changes
cd $SCRATCH/ds000201_preproc
git pull

## figuring out appropriate array-job size
SUB_SIZE=1 # for func the sub size is moving to 1 participant because there are two runs and 8 tasks per run..
N_SUBJECTS=$(( $( wc -l data/input/bids/participants.tsv | cut -f1 -d' ' ) - 1 ))
array_job_length=$(echo "$N_SUBJECTS/${SUB_SIZE}" | bc)
echo "number of array is: ${array_job_length}"

## submit the array-job
sbatch --array=0-${array_job_length} $SCRATCH/ds000201_preproc/code/01_fmriprep_func_allsynthSDC.sh
```

## transfering data back from SciNet to the SCC..

```sh
ssh nia-dm2
screen
rsync -av ${SCRATCH}/ds000201_QA_sdc.zip edickie@192.197.205.74:/external/rprshnas01/netdata_kcni/edlab/
rsync -av ${SCRATCH}/ds000201_QA_sdc.zip edickie@192.197.205.74:/external/rprshnas01/tigrlab/scratch/edickie/


rsync -av $SCRATCH/ds000201_preproc/data/derived/fmriprep edickie@192.197.205.74:/external/rprshnas01/tigrlab/scratch/edickie/tmp_sleep_proj/

```

### cp all the QA files into another folder to move them locally..

From the exit codes - only three subjects report a non-zero exit status

sub-9078 - acutally there is no functional data in the input folders - so this person we will just exclude..

sub-9070   57    1 - weird - just no funcitonal processing?
sub-9078   65    1 - weird - just no functional processing? - the scans are missing from the folder?
sub-9100   85    1 - lost connection with the burst buffer? - just re-submit?

```sh
QA_dir=${SCRATCH}/ds000201_QA
FMRIPREP_dir=${SCRATCH}/ds000201_preproc/data/derived/fmriprep

mkdir -p ${QA_dir}

subjects=`cd ${FMRIPREP_dir}; ls -1d sub-* | grep -v html`

cd ${SCRATCH}

for subject in ${subjects}; do
 cp ${FMRIPREP_dir}/${subject}.html ${QA_dir}
 mkdir -p ${QA_dir}/${subject}
 rsync -av ${FMRIPREP_dir}/${subject}/figures ${QA_dir}/${subject}
done


```

Update - these QA images can be viewed from jupyter hub but only using a firefox browser! (Also make sure to add a symplink from your home to the drive where the fmriprep outputs are so that you can view images via the jupyter hub).

However it might be a alot easier to go through everything quickly if the desc-sdc_bold QA images (the most important one to look at) are all in one local folder - so I will write a script to do that..

```sh
QA_dir=${SCRATCH}/ds000201_QA_sdc
FMRIPREP_dir=${SCRATCH}/ds000201_preproc/data/derived/fmriprep

mkdir -p ${QA_dir}

subjects=`cd ${FMRIPREP_dir}; ls -1d sub-* | grep -v html`

cd ${SCRATCH}

rsync -av ${FMRIPREP_dir}/*/figures/*_desc-sdc_bold.svg ${QA_dir}/

```

## QA Notes from visual inspection

**Major** issue, it is clear that:

- the arrows, faces, and hands tasks used different aquisition paremeters than rest and sleepyness
  - the arrows faces and hands tasks do not a full brain coverage - they are cases were both the top and bottom/cerebellum of the brain and omitted.
  - the rest and sleepyness runs appear to have full brain coverage for the most part
- one subject (the last one) need to be rerun
- registration for sub-9038 (only one of the sessions) is very bad (exclude)
- sub-9094 ses-2 anatomical looks odd sometimes.


---

## Appendix - trying to troubleshoot the weird hanging issue

For most fmriprep runs - when I check the resource usage they would hang at full RAM and no CPU usage for hours - and then something happens and they all continue to run normally - 

A couple participants completely time out in this state..

for the fieldmap run - it was 3837049_86 - or sub-9100 - insterestingly - these job was submitted twice - due to an array indexing error..

For many of the most recent runs - the hanging processes all finished between 1-2am - this seems to correspond to the writing of the config-*.toml to the workdir..

- things we could try..
  - one would be to not share the home - mount templateflow separate?
  - another would be to make sure to state explicitly the freesurfer anat derivatives..
  - mount different $BBUFFER for each process?

Mapping the array id to the subject id..

```sh

```



---


----

We wish this would work - but it did not.

clone the input data source as a submodule into this repo.

```sh
singularity pull shub://datalad/datalad:fullmaster
singularity run envs/datalad_fullmaster.sif clone --dataset . ///openneuro/ds000201 data/inputs/bids
```

---
