clc;
clear;
close all;

% Load the transformer data
load('F:\Research\RAMS 2025\RAM_prognostic_modeling\Code\CleanedTrainingDataTrans_mrmr.mat');

% Extract sequences and labels from the table
numObservations = height(transformerData);
numTimePoints = 4;  % Defined number of time points per sequence
numChannels = 20;   % Defined number of channels (features)

% Prepare the sequences
data = cell(numObservations, 1);
for i = 1:numObservations
    matrix = reshape(table2array(transformerData(i, 1:end-1)), numTimePoints, numChannels);
    data{i} = matrix';
end
labels = categorical(transformerData.Labels);

% Split data into training and testing sets
[idxTrain, idxTest] = trainingPartitions(numObservations, [0.9 0.1]);
XTrain = data(idxTrain);
YTrain = labels(idxTrain);
XTest = data(idxTest);
YTest = labels(idxTest);

% Define the network architecture
layers = [
    sequenceInputLayer(numChannels, 'Name', 'input')
    bilstmLayer(120, 'OutputMode', 'last', 'Name', 'bilstm')
    fullyConnectedLayer(3, 'Name', 'fc')
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'output')
];

% Training options
options = trainingOptions('adam', ...
    'MaxEpochs', 200, ...
    'MiniBatchSize', 27, ...
    'InitialLearnRate', 0.002, ...
    'GradientThreshold', 1, ...
    'Shuffle', 'never', ...
    'Verbose', 0, ...
    'Plots', 'training-progress');

% Train the network
net = trainNetwork(XTrain, YTrain, layers, options);

% Evaluate the network
YPred = classify(net, XTest);
accuracy = sum(YPred == YTest) / numel(YTest);
disp(['Test Accuracy: ', num2str(accuracy)]);

% Plot confusion matrix
figure;
confusionchart(YTest, YPred);
