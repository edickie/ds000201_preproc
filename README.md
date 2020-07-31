# ds000201_preproc
preprocessing and feature extraction for ds0000201

pulling the datalad container into envs to version control content

location of this repo on the SCC is:


```sh
singularity pull shub://datalad/datalad:fullmaster
```

clone the input data source as a submodule into this repo.

```sh
singularity run envs/datalad_fullmaster.sif clone --dataset . ///openneuro/ds000201 data/inputs/bids
```

pulling the T1w data

```sh
cd data/inputs/bids

```

