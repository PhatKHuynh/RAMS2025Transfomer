clc;
clear;
close all;

% Load the data
load('F:\Research\RAMS 2025\RAM_prognostic_modeling\Code\AllFeasTable.mat');

% Define feature selection methods
selectionMethods = {'Random Forest', 'MRMR', 'NCA'};
[methodIndex, tf] = listdlg('PromptString', 'Select a feature ranking method:', ...
                            'SelectionMode', 'single', 'ListString', selectionMethods);

if tf == 0
    disp('No method selected. Exiting...');
    return;
end

% Define time windows
timeWindows = {'min30', 'min60', 'min120', 'min240'};

labels = categorical(allFeaturesTable.Labels); % Convert labels to categorical
features = allFeaturesTable(:, 1:end-1); % Exclude label column

% Replace NaNs with the mean of each column
featuresFilled = varfun(@(x) fillmissing(x, 'constant', mean(x, 'omitnan')), features);

% Feature selection based on the chosen method
k = 20; % Number of features to select
switch selectionMethods{methodIndex}
    case 'Random Forest'
        rng(1); % For reproducibility
        rfModel = TreeBagger(100, featuresFilled, labels, 'Method', 'classification', 'OOBPrediction', 'On', 'OOBVarImp', 'On');
        importanceScores = rfModel.OOBPermutedVarDeltaError;
    case 'MRMR'
        [idx, ~] = fscmrmr(featuresFilled, labels);
        importanceScores = 1:numel(idx); % Use index order as importance for MRMR
    case 'NCA'
        nca = fscnca(featuresFilled, labels, 'Verbose', 0);
        importanceScores = nca.FeatureWeights;
end

% Sorting and selecting top k features
k = 15;
[~, sortedIndices] = sort(importanceScores, 'descend');
topKFeatureNames = featuresFilled.Properties.VariableNames(sortedIndices(1:k));

% Create a table with these top k features
topKFeaturesTable = features(:, sortedIndices(1:k));

% Save the table to a .mat file
save('F:\Research\RAMS 2025\RAM_prognostic_modeling\Code\TopKFeaturesTable.mat', 'topKFeaturesTable');

disp('Top k features saved successfully.');
