clc;
clear;
close all;

% Load your dataset
load('F:\Research\RAMS 2025\RAM_prognostic_modeling\Code\CleanedTrainingDataTrans_mrmr.mat');

% Assuming your data is already loaded as a table named transformerData
% and last column is labels, the rest are features

% Extract features and labels
features = transformerData(:, 1:end-1);
labels = transformerData.Labels;

% Creating a datastore from the table (make sure your features are numeric)
inputDatastore = arrayDatastore(table2array(features), 'OutputType', 'same');

% You might need to handle labels separately depending on the design requirements
labelsDatastore = arrayDatastore(labels, 'OutputType', 'same');

% Combine feature and label datastores into a single datastore
combinedDatastore = combine(inputDatastore, labelsDatastore);

% Save the datastore for use in Deep Network Designer
save('F:\Research\RAMS 2025\RAM_prognostic_modeling\Code\TrainingDatastore.mat', 'combinedDatastore');

disp('Datastore is ready and saved for Deep Network Designer.');
