clc;
clear;
close all;
disp('Starting the analysis...');

% Define the directory path where the MAT files are stored
basePath = 'F:\Research\RAMS 2025\RAM_prognostic_modeling\Code\';

% Names of MAT files to load
featureFiles = {'TimeDomainFeas.mat', 'FreqDomainFeas.mat', 'InfoTheoryFeas.mat', ...
                'SystDynFeas.mat', 'WaveletFeas.mat', 'ChangePointFeas.mat'};

% Feature names for each category
featureNames = {
    'Time-domain', {'Mean', 'Median', 'Variance', 'Skewness', 'Kurtosis', 'PeakToPeak', 'RMS', ...
                    'ZeroCrossingRate', 'CrestFactor', 'ImpulseFactor', 'AutoCorrelation', 'TrAsym'}, ...
    'Frequency-domain', {'FundamentalFreq', 'SpectralEntropy', 'Harmonics', 'InterharmonicDistortion', ...
                         'SpectralFlatness', 'SpectralKurtosis', 'SpectralSkewness'}, ...
    'Information-theoretic', {'Entropy', 'MutualInformation', 'ConditionalEntropy', 'Perplexity', 'Complexity'}, ...
    'System Dynamics', {'LyapunovExponent', 'FractalDimension', 'HurstExponent', 'CorrelationDimension'}, ...
    'Wavelet-based', {'EnergyL1','EnergyL2','EnergyL3','EnergyL4','EnergyL5' 'WaveletEntropy', 'WaveletVariance', 'TotalWaveletCoeff', 'WaveletKurtosis', 'WaveletSkewness'}, ...
    'Change Detection', {'ChangePoints', 'CUSUMScores', 'MannKendallTrend', 'MannKendallPValue', 'BayesianCP'}
};

% Initialize a table for all features
allFeaturesTable = [];

% Process each feature file
for i = 1:length(featureFiles)
    data = load(fullfile(basePath, featureFiles{i}));  % Load the feature data
    dataFields = {'min30', 'min60', 'min120', 'min240'};
    numPMUs = 18;  % Number of PMUs per feature
    
    for j = 1:length(dataFields)
        fieldData = data.allFeatures.(dataFields{j});
        numEpisodes = length(data.labels);  % Number of episodes
        numFeatures = size(fieldData, 2) / (numPMUs*numEpisodes);  % Number of features per PMU

        % Reshape the data to have one row per episode and features spread across columns
        reshapedData = reshape(fieldData.', numFeatures * numPMUs, numEpisodes).';
        
        % Create column names
        colNames = {};
        for pmu = 1:numPMUs
            for k = 1:numFeatures
                colNames{end+1} = sprintf('PMU%d_%s_%s', pmu, featureNames{1,i*2}{1,k}, dataFields{1,j});
            end
        end

        % Append the features to the table
        if isempty(allFeaturesTable)
            allFeaturesTable = array2table(reshapedData, 'VariableNames', colNames);
        else
            tempTable = array2table(reshapedData, 'VariableNames', colNames);
            allFeaturesTable = [allFeaturesTable, tempTable];
        end
    end
end

% Add labels to the feature table
allFeaturesTable.Labels = data.labels;

