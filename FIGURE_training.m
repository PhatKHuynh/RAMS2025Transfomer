clc;
clear;
close all;
disp('Loading data...');

% Load the data table
data = load('F:\Research\RAMS 2025\RAM_prognostic_modeling\Code\AllFeasTable.mat');
allFeaturesTable = data.allFeaturesTable;

% Get features and labels
features = allFeaturesTable(:, 1:end-1);
labels = allFeaturesTable.Labels;

% Define number of features to display
k = 20;  % Modify as needed

% Load previously computed indices for the top features
load('feature_idx.mat');

% Extract the top k features
topKFeatures = features(:, idx(1:k));

% Split data into training and testing sets
cv = cvpartition(labels, 'HoldOut', 0.2);
idxTrain = training(cv);
idxTest = test(cv);

XTrain = table2array(topKFeatures(idxTrain, :));
YTrain = labels(idxTrain);
XTest = table2array(topKFeatures(idxTest, :));
YTest = labels(idxTest);

% Standardize the features
mu = mean(XTrain);
sig = std(XTrain);
XTrain = (XTrain - mu) ./ sig;
XTest = (XTest - mu) ./ sig;

% Convert labels to categorical if they aren't already
YTrain = categorical(YTrain);
YTest = categorical(YTest);

% Define the architecture
inputSize = size(XTrain, 2); % Adjusted to use the correct number of features directly
numClasses = numel(categories(YTrain));

layers = [
    featureInputLayer(inputSize, 'Normalization', 'none', 'Name', 'input')
    sinusoidalPositionEncodingLayer(20, 'Name', 'position', 'Positions', 'data-values')
    selfAttentionLayer(4, inputSize, 'Name', 'self_attention')
    layerNormalizationLayer('Name', 'norm1')
    reluLayer('Name', 'relu1')
    fullyConnectedLayer(64, 'Name', 'fc1')
    reluLayer('Name', 'relu2')
    dropoutLayer(0.1, 'Name', 'dropout')
    fullyConnectedLayer(numClasses, 'Name', 'fc2')
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'classification')
];

% Set training options
options = trainingOptions('sgdm', ...
    'MiniBatchSize', 32, ...
    'MaxEpochs', 30, ...
    'InitialLearnRate', 1e-3, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', {XTest, YTest}, ...
    'ValidationFrequency', 30, ...
    'Verbose', false, ...
    'Plots', 'training-progress');

% Train the network
net = trainNetwork(XTrain, YTrain, layers, options);

% Evaluate the network
YPred = classify(net, XTest);
accuracy = sum(YPred == YTest) / numel(YTest);
disp(['Test Accuracy: ', num2str(accuracy)]);

% Display the architecture
analyzeNetwork(net);
