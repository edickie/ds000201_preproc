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

----

We wish this would work - but it did not.

clone the input data source as a submodule into this repo.

```sh
singularity pull shub://datalad/datalad:fullmaster
singularity run envs/datalad_fullmaster.sif clone --dataset . ///openneuro/ds000201 data/inputs/bids
```

---
