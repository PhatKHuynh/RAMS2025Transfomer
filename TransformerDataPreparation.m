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

[~, sortedIndices] = sort(importanceScores, 'descend');
featureNames = featuresFilled.Properties.VariableNames(sortedIndices);

uniqueFeatures = {};
for i = 1:length(featureNames)
    currentName = featureNames{i};
    cleanName = regexprep(currentName, '_min(30|60|120|240)$', '');
    if ~ismember(cleanName, uniqueFeatures)
        uniqueFeatures{end + 1} = cleanName;
    end
end
k = 10;
selectedFeatures = uniqueFeatures(1:k);

% Prepare data structure for transformer
transformerData = zeros(height(featuresFilled), numel(selectedFeatures) * numel(timeWindows));
colNames = {};

% Build column names and fill data
index = 1;
for i = 1:numel(selectedFeatures)
    for j = 1:numel(timeWindows)
        currentFeature = strcat(selectedFeatures{i}, '_', timeWindows{j});
        colName = strcat(selectedFeatures{i}, '_', num2str(j)); % Correct column name for storage
        colNames{index} = colName;
        if ismember(currentFeature, featuresFilled.Properties.VariableNames)
            transformerData(:, index) = table2array(featuresFilled(:, currentFeature));
        else
            disp(['Warning: ', currentFeature, ' not found in the filled table.']);
        end
        index = index + 1;
    end
end

if any(all(transformerData == 0, 1))
    disp('Some features are still all zeros after attempted filling.');
end

% Convert to table and add labels
transformerData = array2table(transformerData, 'VariableNames', colNames);
transformerData.Labels = labels;

disp('Data restructuring complete and ready for transformer-based training.');