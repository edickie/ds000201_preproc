# ds000201_preproc
preprocessing and feature extraction for ds0000201

pulling the datalad container into envs to version control content

location of this repo on the CAMH Scientific Computing Cluster (with the data folders) is:

`/external/rprshnas01/netdata_kcni/edlab/ds000201_preproc`

## Getting the raw data

I wanted to pull the data using datalad - but the datalad repo had broken download links.. So instead this data was pulled using the amazon-cli (in a singularity container).

# Pulling the amazon cli container

On the SSC this was Run 2020-07-30, singularity version 3.5.3

```sh
module load singularity
cd /external/rprshnas01/netdata_kcni/edlab/ds000201_preproc/envs
singularity build aws-cli.sif docker://amazon/aws-cli
```

The data download 

```sh
cd /external/rprshnas01/netdata_kcni/edlab/ds000201_preproc/data/input
singularity run ../../envs/aws-cli.sif s3 sync --no-sign-request s3://openneuro.org/ds000201 bids/
```



## Preprossesing

To preprocess we will use the current stable release of fmriprep

```sh
singularity build envs/fmriprep-20.1.1.simg docker://poldracklab/fmriprep:20.1.1
```

----

We wish this would work - but it did not.

clone the input data source as a submodule into this repo.

```sh
singularity pull shub://datalad/datalad:fullmaster
singularity run envs/datalad_fullmaster.sif clone --dataset . ///openneuro/ds000201 data/inputs/bids
```

---
