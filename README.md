## Transformer-Based Prognostic Modeling for Smart Grid Health Monitoring

This repository contains the MATLAB code and scripts used for the research paper titled "Transformer-Based Prognostic Modeling for Smart Grid Health Monitoring", which leverages Phasor Measurement Unit (PMU) data and transformer models to predict grid disturbances.
Table of Contents

    Overview
    Repository Structure
    Installation
    Data Preparation
    Feature Extraction
    Transformer-Based Model
    Model Training and Evaluation
    License
    References

Overview

This project focuses on developing a transformer-based model to predict grid disturbances such as severe weather, lightning, and AC circuit equipment failures using high-resolution PMU data. The methodology incorporates advanced feature extraction techniques, followed by a transformer model to detect subtle patterns in the PMU data that indicate potential grid failures. The model outperforms several traditional machine learning methods, achieving high accuracy and precision across multiple metrics.
Repository Structure

The repository is organized as follows:

├── Data
│   ├── CleanedTrainingDataTrans_RF15.mat
│   └── AllFeasTable.mat
├── FeatureExtraction
│   ├── AggregateFeatures.m
│   ├── extractTimeDomainFeatures.m
│   ├── extractFrequencyDomainFeatures.m
│   ├── extractSystemDynamicsFeatures.m
│   └── extractWaveletBasedFeatures.m
├── TransformerModel
│   ├── TransformerDataPreparation.m
│   ├── TransformerTraining.m
│   ├── TransformerTrainingAugmented.m
│   └── Transformer_ML_comparison.m
├── Documentation
│   └── RAMS_prognostic_modeling.docx
└── README.md

Key Files

    Data: Contains the .mat files with the processed PMU data.
    FeatureExtraction: MATLAB scripts for extracting different types of features (time-domain, frequency-domain, wavelet-based, system dynamics, etc.) from PMU data.
    TransformerModel: Scripts for preparing data, training the transformer model, and comparing it with traditional machine learning models.

Installation

To use the code in this repository, ensure you have MATLAB (preferably R2024b or later) installed with the necessary toolboxes:

    Deep Learning Toolbox
    Statistics and Machine Learning Toolbox
    Signal Processing Toolbox

Steps:

    Clone this repository:

    bash

git clone https://github.com/PhatKHuynh/RAMS2025Transformer.git

Open MATLAB and navigate to the cloned repository folder.

Ensure the MATLAB path is set correctly to include all subfolders:

matlab

    addpath(genpath(pwd));

Data Preparation

Before training the transformer model, the PMU data is preprocessed and structured using the TransformerDataPreparation.m script. This script selects the top features from PMU data and reshapes them into sequences suitable for the transformer model.

To run the data preparation script:

matlab

run('TransformerModel/TransformerDataPreparation.m');

The script will output a new structured dataset ready for model training.
Feature Extraction

PMU data is processed through various feature extraction methods. These features are critical for understanding grid behavior and predicting disturbances.
Feature Extraction Scripts:

    Time-Domain Features: extractTimeDomainFeatures.m extracts statistical properties like mean, variance, skewness, kurtosis, etc.
    Frequency-Domain Features: extractFrequencyDomainFeatures.m computes features like spectral entropy, harmonics, and interharmonic distortion.
    System Dynamics Features: extractSystemDynamicsFeatures.m extracts nonlinear features like Lyapunov Exponent, Fractal Dimension, Hurst Exponent.
    Wavelet-Based Features: extractWaveletBasedFeatures.m performs wavelet decomposition to capture transient behaviors.

To extract all features:

matlab

run('FeatureExtraction/AggregateFeatures.m');

Transformer-Based Model

The transformer-based model leverages the extracted features to predict grid disturbances. The model is trained using the self-attention mechanism to detect subtle patterns in the data.
Model Training:

To train the transformer model, use TransformerTraining.m:

matlab

run('TransformerModel/TransformerTraining.m');

Alternatively, for data augmentation and advanced training:

matlab

run('TransformerModel/TransformerTrainingAugmented.m');

Model Comparison:

To compare the transformer model against traditional machine learning models (SVM, KNN, Random Forest, etc.), use the script Transformer_ML_comparison.m:

matlab

run('TransformerModel/Transformer_ML_comparison.m');

Results, including accuracy, precision, recall, and F1 score, will be saved in meanResults.xlsx and stdResults.xlsx.
Model Training and Evaluation

The model is trained using 5-fold cross-validation to evaluate its performance across different metrics, including accuracy, precision, recall, and F1 score. The transformer model is benchmarked against several traditional ML models such as Advanced SVM, Subspace KNN, and Random Forest.

Performance metrics can be visualized using confusion matrices, which are plotted during the training process.
