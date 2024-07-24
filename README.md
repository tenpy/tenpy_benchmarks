# Benchmarks for TeNPy

This repo contains a few benchmarks for [TeNPy](https://github.com/tenpy/tenpy) with a comparison to [ITensor](https://github.com/ITensor/ITensors.jl).


## Setup
- Download this git repo, including submodules (i.e. call `git submodule init` and `git submodule update` if needed)
- Setup a python environment you want to use, e.g. via one of the following:

  - ```bash
    conda create ./env_conda python pip numpy scipy mkl libblas=*=*mkl
    cd TeNpy
    pip install -e .
    ```
  - ```bash
    python -m venv env_pip
    . env_pip/bin/activate
    pip install physics-tenpy h5py
    ```
  If needed, adjust the `environment:` section in the submit scripts to load the environment.

## Running the benchmarks
The setup is based on the [`cluster_jobs.py` file](https://github.com/jhauschild/cluster_jobs/tree/main/multi_yaml) for easy submission to the cluster,
and can be submitted like this:
```bash
./> # edit submit files as necessary
./> mkdir run
./> cd run
run/> ../cluster_jobs.py submit ../submit_1D_DMRG.yml
```


## Comparing with ITensor
The DMRG sweep is setup for a comparison to ITensor in the `itensors/` subfolder.
We provide the resulting log files with the timings in the repo. To re-run this part, follow these steps:
- Install [Julia](https://julialang.org).
- Run julia interactively, enter the package manager by pressing "]" and install the necessary packages:
  ```
  julia> ]
  pkg> add ITensors
  pkg> add ITensorMPS
  pkg> add MKL
  ```
- To manually run the julia script, go to the `itensor` directory and run `julia run_itensor_comparison.jl`
- The stdout contains timings per sweep and is the output file we use for plotting.
- To submit this as a job to the cluster, you can use `cluster_jobs.py submit submit_itensor_benchmark.yml`.

## Plotting and analyzing results
See the [jupyter](https://jupyter.org) notebooks in the `plots/` folder.

