# EEGLoc — Thesis Implementation 

[![DOI](https://zenodo.org/badge/1176368408.svg)](https://doi.org/10.5281/zenodo.19209835)

This repository contains the **reference implementation of EEGLoc**, an EEG electrode localization pipeline developed as part of the master's thesis: "*EEG Electrode Coregistration from 3D Head Scans: A Pilot and Main Study Exploration in Persons with Parkinson's Disease*"  

The code in this repository implements the method described in the thesis and is provided to ensure reproducibility of the reported results.

## Project Status

This repository contains the **thesis implementation of EEGLoc** and is not actively maintained.

Future development and maintenance of this project will take place in the main **[EEGLoc](https://github.com/MelissaGallant/EEGLoc)** repository, which will provide a tighter and more user-friendly integration with EEGLAB.

## Overview

EEGLoc is a MATLAB pipeline for **semi-automatic EEG electrode localization from 3D head scans**.

Given a 3D head scan containing visible electrode locations, the pipeline estimates electrode positions and assigns channel labels based on a template montage, requiring minimal user input.

The pipeline performs the following steps:

1. **Automatic electrode detection** from the 3D head scan
2. **Alignment of a template EEG montage** with the detected electrode positions
3. **Automatic electrode labeling** using spatial matching with the template montage
4. **Export of EEGLAB-compatible channel locations**

The resulting channel locations can be stored in an EEGLAB dataset and used to carry out analyses such as source localization.

### Data Requirements

For the pipeline to work, the following conditions should be met:

- The head scan is of **reasonable quality**
- The **electrodes are visible** in the head scan
- A **template montage with labeled electrode positions** is available
- The **number of electrodes in the template corresponds to the electrodes present in the scan**

### Note

EEGLoc was originally developed and tested using **ANT WaveGuard EEG caps (128 electrodes, 10–5 layout)**. While the pipeline is expected to work with other EEG caps and layouts, this has not yet been tested.

## Dependencies

- MATLAB (>= R2017a)
- FieldTrip (used for headshape preparation)
- EEGLAB (used for storing the resulting channel locations in a dataset)

## Usage

The EEGLoc workflow consists of three main stages:

1. Preparing the headshape
2. Running the electrode localization pipeline
3. Applying the resulting channel locations in EEGLAB

### 1 Prepare the headshape

Before running the pipeline, a headshape must be obtained and converted into the format expected by EEGLoc. The underlying utilities rely on a combination of EEGLAB and the FieldTrip toolbox.

#### 1.1 Extract template channel locations from EEGLAB

```matlab
utilities.extract_chanlocs_eeglab('EEGLAB_data.set', 'template_chanlocs.csv')
```

This exports the original template montage from an EEGLAB dataset.

#### 1.2 Prepare the headshape

```matlab
headshape = utilities.prepare_headshape(fullfile('Model','Model.obj'), 'headshape.mat');
```

This converts a 3D head model into a **FieldTrip headshape structure in the CTF coordinate system**, which is saved to `headshape.mat`. During this process, the user is prompted to select the fiducial points on the head scan. An example model for testing is provided in the `examples/` directory.

#### 1.3 Visualize the headshape (optional)

```matlab
utilities.plot_headshape(headshape)
```

This step allows visual inspection of the headshape before continuing.

#### 1.4 Crop the headshape (optional)

```matlab
headshape = utilities.crop_headshape(headshape, [], [-120,500],[]);
```

Cropping can be used to remove parts of the mesh that are not relevant for electrode detection.  
This step may be performed either before or after `prepare_headshape`.

### 2 Run the EEGLoc pipeline

Once the headshape has been prepared and the template montage is available, run the main pipeline:

```matlab
chanlocs = run_pipeline('headshape.mat', 'template_chanlocs.csv');
```

The pipeline launches a user interface for the automatic detection and labeling of electrodes, and allows the user to modify the positions and labels in the process.

For a full example, see the `examples/` directory. The pipeline can then be run using the provided files:

```matlab
chanlocs = run_pipeline(fullfile('examples','headshape.mat'), ...
                        fullfile('examples','template_chanlocs.csv'));
```

### 3 Store the channel locations in EEGLAB

Once the electrodes have been located and labeled on the head scan, they can be applied to a corresponding EEGLAB dataset.

#### Option 1: Apply `chanlocs` struct directly

```matlab
EEG = utilities.override_chanlocs_eeglab(EEG, chanlocs)
```

#### Option 2: Apply from an exported file

```matlab
EEG = utilities.override_chanlocs_eeglab(EEG, 'new_chanlocs.txt')
```

## Acknowledgements

This work was carried out as part of a **master's thesis at Maastricht University** and was conducted during an internship at **Radboudumc**, in collaboration with the research group UNITE-PD.

The author would like to thank the supervisors and staff involved in the thesis project for their guidance and for providing access to the EEG and 3D scanning infrastructure used in this work.

## Citation

If you use this software in academic work, please cite the associated thesis:

> Gallant, M. M. (2025). *EEG Electrode coregistration from 3D head scans: A pilot and main study exploration in persons with Parkinson's disease* [Master's thesis, Maastricht University].

Citation metadata is also provided in `CITATION.cff`.

## License

This project is released under the **MIT License**.

See the `LICENSE` file for details.
