# ds000201_preproc
preprocessing and feature extraction for ds0000201

pulling the datalad container into envs to version control content

# To download the repo to another machine

```
git clone https://github.com/edickie/ds000201_preproc.git
```

location of this repo on the CAMH Scientific Computing Cluster (with the data folders) is:

`/external/rprshnas01/netdata_kcni/edlab/ds000201_preproc`

## Getting the raw data

I wanted to pull the data using datalad - but the datalad repo had broken download links.. So instead this data was pulled using the amazon-cli (in a singularity container).

# Pulling the amazon cli container

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


----

We wish this would work - but it did not.

clone the input data source as a submodule into this repo.

```sh
singularity pull shub://datalad/datalad:fullmaster
singularity run envs/datalad_fullmaster.sif clone --dataset . ///openneuro/ds000201 data/inputs/bids
```

---
