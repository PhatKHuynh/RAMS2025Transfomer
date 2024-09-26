clc;
clear;
close all;

% Load the transformer data
load('F:\Research\RAMS 2025\RAM_prognostic_modeling\Code\CleanedTrainingDataTrans_RF15.mat');

% Extract sequences and labels from the table
numObservations = height(transformerData);
numTimePoints = 4;  
numChannels = (width(transformerData)-1)/4;   

% Prepare the sequences
data = cell(numObservations, 1);
for i = 1:numObservations
    matrix = reshape(table2array(transformerData(i, 1:end-1)), numTimePoints, numChannels);
    data{i} = matrix;
end
labels = categorical(transformerData.Labels);

% Define k-fold cross-validation
k = 5;
cv = cvpartition(labels, 'KFold', k);

% Initialize accuracy array
accuracies = zeros(k, 1);

% Loop over the folds
for i = 1:k
    idxTrain = training(cv, i);
    idxTest = test(cv, i);
    XTrain = data(idxTrain);
    YTrain = labels(idxTrain);
    XTest = data(idxTest);
    YTest = labels(idxTest);

    % Define the network architecture
    layers = [
    sequenceInputLayer(numTimePoints, 'Name', 'input')
    bilstmLayer(50, 'OutputMode', 'last', 'Name', 'bilstm1')
    selfAttentionLayer(4, 64, 'Name', 'attention')
    layerNormalizationLayer('Name', 'norm1')
    dropoutLayer(0.5, 'Name', 'dropout1')
    bilstmLayer(50, 'OutputMode', 'last', 'Name', 'bilstm2')
    fullyConnectedLayer(3, 'Name', 'fc')
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'output')
    ];


    % Training options
    options = trainingOptions('adam', ...
        'MaxEpochs', 300, ...
        'MiniBatchSize', 128, ...
        'InitialLearnRate', 0.001, ...
        'L2Regularization', 0.0001, ...
        'GradientThreshold', 2, ...
        'Shuffle', 'every-epoch', ...
        'Verbose', true, ...
        'Verbose', false);

    % Train the network
    net = trainNetwork(XTrain, YTrain, layers, options);

    % Evaluate the network
    YPred = classify(net, XTest);
    accuracies(i) = sum(YPred == YTest) / numel(YTest);
end

% Calculate mean and standard deviation of accuracies
meanAccuracy = mean(accuracies);
stdAccuracy = std(accuracies);
disp(['Mean Accuracy: ', num2str(meanAccuracy)]);
disp(['Standard Deviation of Accuracy: ', num2str(stdAccuracy)]);
