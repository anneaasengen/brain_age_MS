# Master's Thesis Repository
This repository contains code developed during my master thesis project titled "Brain Age Prediction from Gray Matter Asymmetry in Multiple Sclerosis". The project investigates whether voxel-wise gray matter asymmetry maps derived from T1-weighted MRI data can be used to predict brain age, and whether asymmetry-based brain age measures may have clinical relevance in multiple sclerosis.


## Table of Contents

- [Repository Structure](#repository-structure)
- [Methods](#methods)
- [Requirements](#requirements)
- [Usage](#usage)

---

## Repository Structure

```text
brain_age_MS
│
├── VBM
│   ├── Scripts_VBM
│   └── extra_material
│
├── brain_age_models
│   ├── unsmoothed_model
│   └── smoothed_model
│
├── Notebooks
│   ├── MS_prediction_ntebooks
│   └── smoothed_notebooks_MS
│
├── predictions_csv_files
│   ├── healthy_predictions_csv
│   │  
│   └── MS_predictions_csv
│       ├── MS_unsmoothed_predictions
│       └── MS_smoothed_predictions
│
├── Results
│   ├── Model_results
│   └── MS_results
│       ├── baseline_analysis
│       └── longitudinal_analysis
│
└── README.md
```

### Folder descriptions

- **VBM/**  
  Contains MATLAB scripts and supporting files used for voxel-based morphometry (VBM) preprocessing and generation of asymmetry maps.

- **brain_age_models/**  
  Contains notebooks for training and externally testing the brain age prediction models (unsmoothed and smoothed model), as well as saved model weights.

- **Notebooks/**  
  Contains notebooks used for predicting brain age in MS patients at different longitudinal timepoints using both smoothed and unsmoothed asymmetry maps.

- **predictions_csv_files/**  
  Contains CSV files with predictions for both healthy and MS subjects, for both models. The CSV files are used in subsequent analyses.

- **Results/**  
  Contains notebooks used for visualization, statistical analyses, and investigation of clinical associations with brain age gap (BAG), including both baseline and longitudinal analyses.

### Folder descriptions

- **VBM/**  
  Contains MATLAB scripts used for voxel-based morphometry (VBM) preprocessing and generation of asymmetry maps from T1-weighted MRI data.

- **brain_age_models/**  
  Contains notebooks for training and externally testing the brain age prediction models, as well as the trained model weights (`.pth` files).

- **Notebooks/**  
  Contains notebooks used for predicting brain age in MS patients at different longitudinal timepoints using both unsmoothed and smoothed asymmetry maps.

- **predictions_csv_files/**  
  Contains exported prediction results and processed CSV files used in subsequent analyses.

- **Results/**  
  Contains notebooks used for visualization, statistical analyses, and investigation of clinical associations with brain age gap (BAG), including baseline and longitudinal analyses.















## Data
Short note about which datasets were used, and that MRI data are not included due to privacy/data access restrictions.

## Methods
Short overview:
- VBM preprocessing
- asymmetry map generation
- brain age prediction model
- prediction in MS patients
- clinical/longitudinal analyses

## Requirements
To run the code in this repository, the following software and libraries are required:

MATLAB (version R2025a or higher)
Python (version 3.11.14 or higher)

**Python libraries:**
- fastai (v2.8.3)
- fastMONAI (v0.5.2)
- matplotlib (v3.10.7)
- MONAI (v1.5.0)
- nibabel (v5.3.3)
- NumPy (v2.2.6)
- pandas (v2.3.3)
- PyTorch (v3.11.14)
- scikit-learn (v1.7.2)
- SciPy (v1.16.3)

## Usage
To use the code in this repository, follow the instructions below:

Clone this repository to your local machine using the following command:

```bash
git clone https://github.com/anneaasengen/brain_age_MS.git
```
Any important limitations, e.g. paths must be adapted locally.




## Contact

If you have any questions or need further assistance, feel free to contact me at anne_aasengen@yahoo.no

## Author
Anne Aasengen



