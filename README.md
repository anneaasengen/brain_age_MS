# Master's Thesis Repository
This repository contains code developed during my master thesis project titled "Brain Age Prediction from Gray Matter Asymmetry in Multiple Sclerosis". The project investigates whether voxel-wise gray matter asymmetry maps derived from T1-weighted MRI data can be used to predict brain age, and whether asymmetry-based brain age measures may have clinical relevance in multiple sclerosis (MS).

Two convolutional neural network (CNN) models were developed to predict brain age: one trained on unsmoothed asymmetry maps and one trained on spatially smoothed asymmetry maps. Else, the models are identical. Based on the model evaluation and subsequent analyses, the unsmoothed model was selected as the primary model in this project. Similarly, residual brain age gap (residual BAG) was used as the main brain age measure, while adjusted BAG was included as a supplementary analysis.



## Table of Contents

- [Repository Structure](#repository-structure)
- [Methods Overview](#methods-overview)
- [Data](#data)
- [Requirements](#requirements)
- [Usage](#usage)
- [Contact](#contact)
- [Author](#author)

---

## Repository Structure

```text
brain_age_MS/
│
├── VBM/
│   ├── Scripts_VBM/
│   └── extra_material/
│
├── brain_age_models/
│   ├── unsmoothed_model/
│   └── smoothed_model/
│
├── MS_inference/
│   ├── MS_inference_unsmoothed/
│   └── MS_inference_smoothed/
│
├── predictions_csv_files/
│   ├── healthy_predictions_csv/
│   │  
│   └── MS_predictions_csv/
│       ├── MS_unsmoothed_predictions/
│       └── MS_smoothed_predictions/
│
├── Results/
│   ├── Model_results/
│   └── MS_results/
│       ├── baseline_analysis/
│       └── longitudinal_analysis/
│
└── README.md
```

### Folder descriptions

- **VBM/**  
  Contains MATLAB scripts used for voxel-based morphometry (VBM) preprocessing and generation of asymmetry maps.
  
- **VBM/extra_material/**  
  Contains supporting scripts and template files required for the VBM preprocessing pipeline. These files originate from the VBM framework described by Kurth et al. [1] and were not developed as part of this thesis project.
  
- **brain_age_models/**  
  Contains notebooks for training and externally testing the brain age prediction models (unsmoothed and smoothed model), as well as saved model weights.

- **MS_inference/**  
  Contains notebooks used to apply the trained brain age models to asymmetry maps from MS patients and generate prediction outputs. The generated prediction files are subsequently analyzed in separate notebooks located in the `Results/` folder.

- **predictions_csv_files/**  
  Contains CSV files with predictions for both healthy and MS subjects, for both models. The CSV files are used in subsequent analyses.

- **Results/**  
  Contains notebooks used for visualization, performance evaluation, and statistical analyses of the brain age predictions. This includes model performance in healthy subjects, comparisons between healthy controls and MS patients, as well as baseline and longitudinal analyses of brain age measures in MS patients and their associations with clinical variables.



## Methods Overview
The workflow of this project consisted of several main steps:

1. **Voxel-based morphometry (VBM)** was performed on T1-weighted MRI data from healthy subjects and MS patients in order to generate voxel-wise gray matter asymmetry maps.

2. Two separate **brain age prediction models** were developed and trained using asymmetry maps from healthy subjects. One model was trained using unsmoothed asymmetry maps, while the other used spatially smoothed asymmetry maps. Else, the models are identical.

3. The trained models were subsequently applied to asymmetry maps from MS patients in order to estimate brain age.

4. The prediction results were further analyzed through baseline analyses, longitudinal analyses, and clinical analyses.


## Data

The brain age models were trained using asymmetry maps from healthy subjects derived from MRI data from the Human Connectome Project (HCP) and the Cambridge Centre for Ageing and Neuroscience (CamCAN) datasets. The trained models were subsequently applied to asymmetry maps generated from MRI data from MS patients from the OFAMS dataset.

The original MRI scans and derived asymmetry maps are not included in this repository due to privacy regulations and data access restrictions. Metadata files containing clinical and demographic information are also excluded due to sensitive information.



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

**MATLAB toolboxes:**
- SPM12
- CAT12

## Usage
To use the code in this repository, follow the instructions below:

Clone this repository to your local machine using the following command:

```bash
git clone https://github.com/anneaasengen/brain_age_MS.git
```

After cloning the repository, explore the different folders based on your requirements:

- **VBM/**  
  Execute the MATLAB scripts using MATLAB together with SPM/CAT12.

- **brain_age_models/**  
  Run the relevant notebook cells to train, validate, and externally test the brain age prediction models.

- **MS_inference/**  
  Run the relevant notebook cells to perform brain age prediction in MS patients.

- **Results/**  
  Execute the relevant notebook cells to perform visualization and statistical analyses.

- **predictions_csv_files/**  
  Contains CSV files with predition results used in the analyses.

Make sure to adjust any necessary file paths and environment-specific settings before running the scripts and notebooks.

## Contact

If you have any questions or need further assistance, feel free to contact me at anne_aasengen@yahoo.no

## Author
Anne Aasengen



## References

- [1] F. Kurth, C. Gaser and E. Luders. “A 12-step user guide for analyzing
voxel-wise gray matter asymmetries in statistical parametric mapping
(SPM)”. In: Nature Protocols 10.2 (2015), pp. 293–304. DOI: https://doi.org/10.1038/nprot.2015.014


