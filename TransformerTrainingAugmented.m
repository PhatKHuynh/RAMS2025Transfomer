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

% Split data into training and testing sets
[idxTrain, idxTest] = trainingPartitions(numObservations, [0.8 0.2]);
XTrain = data(idxTrain);
YTrain = labels(idxTrain);
XTest = data(idxTest);
YTest = labels(idxTest);

% Define the network architecture
% Define the network architecture
layers = [
    sequenceInputLayer(numTimePoints, 'Name', 'input')
    bilstmLayer(50, 'OutputMode', 'last', 'Name', 'bilstm1')
    dropoutLayer(0.5, 'Name', 'dropout1')
    bilstmLayer(50, 'OutputMode', 'last', 'Name', 'bilstm2')
    fullyConnectedLayer(3, 'Name', 'fc')
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'output')
];

% Training options
options = trainingOptions('adam', ...
     'ExecutionEnvironment', 'gpu', ...
    'MaxEpochs', 300, ...
    'GradientThreshold', 1, ...
    'Shuffle', 'every-epoch', ...
    'Verbose', false, ...
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
