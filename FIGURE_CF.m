clc;
clear;
close all;

% Load the transformer data
load('F:\Research\RAMS 2025\RAM_prognostic_modeling\Code\CleanedTrainingDataTrans_RF15.mat');

% Extract sequences and labels for the transformer model
numObservations = height(transformerData);
numTimePoints = 4;  
numChannels = (width(transformerData)-1) / 4;   

% Prepare the sequences for the transformer model
sequenceData = cell(numObservations, 1);
for i = 1:numObservations
    matrix = reshape(table2array(transformerData(i, 1:end-1)), numTimePoints, numChannels);
    sequenceData{i} = matrix;
end
sequenceLabels = categorical(transformerData.Labels);

% Randomly select 80% of the data for training and 20% for testing
cv = cvpartition(sequenceLabels, 'HoldOut', 0.20);
idxTrain = training(cv);
idxTest = test(cv);

XTrain = sequenceData(idxTrain);
YTrain = sequenceLabels(idxTrain);
XTest = sequenceData(idxTest);
YTest = sequenceLabels(idxTest);

% Rename categories for "failed_AC_circuit" to "failed AC circuit"
YTrain = renamecats(YTrain, 'failed_AC_circuit', 'failed AC circuit');
YTest = renamecats(YTest, 'failed_AC_circuit', 'failed AC circuit');

% Define the network architecture
layers = [
sequenceInputLayer(numTimePoints, 'Name', 'input')
bilstmLayer(50, 'OutputMode', 'last', 'Name', 'bilstm1')
dropoutLayer(0.5, 'Name', 'dropout1')
selfAttentionLayer(4, 64, 'Name', 'attention')
bilstmLayer(50, 'OutputMode', 'last', 'Name', 'bilstm2')
dropoutLayer(0.5, 'Name', 'dropout2')
fullyConnectedLayer(3, 'Name', 'fc')
softmaxLayer('Name', 'softmax')
classificationLayer('Name', 'output')
];


% layers = [
%     sequenceInputLayer(numTimePoints, 'Name', 'input')
%     bilstmLayer(50, 'OutputMode', 'last', 'Name', 'bilstm1')
%     dropoutLayer(0.5, 'Name', 'dropout1')
%     bilstmLayer(50, 'OutputMode', 'last', 'Name', 'bilstm2')
%     fullyConnectedLayer(3, 'Name', 'fc')
%     softmaxLayer('Name', 'softmax')
%     classificationLayer('Name', 'output')
% ];

% Training options for the Transformer
options = trainingOptions('adam', ...
    'MaxEpochs', 500, ...
    'GradientThreshold', 1, ...
    'Shuffle', 'every-epoch', ...
    'Verbose', false);

% Train the network
net = trainNetwork(XTrain, YTrain, layers, options);
YPred = classify(net, XTest);

% Compute evaluation metrics
confMat = confusionmat(YTest, YPred);
confMatPercentage = 100 * confMat ./ sum(confMat, 'all');

% Display the confusion matrix in percentage
plotconfusion(YTest,YPred)

% Calculate precision, recall, and F1 score
accuracy = sum(YPred == YTest) / numel(YTest);

% Display results
disp('Training complete and results displayed.');
disp(['Accuracy: ', num2str(accuracy * 100), '%']);
