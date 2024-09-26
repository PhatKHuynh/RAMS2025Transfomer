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
% Assuming `sequenceLabels` contains all possible labels
classNames = categories(sequenceLabels);
numClasses = numel(classNames);

% Prepare feature matrix and labels for ML models
featureData = table2array(transformerData(:, 1:end-1));
featureLabels = categorical(transformerData.Labels);

% Define k-fold cross-validation
k = 5;
cv = cvpartition(sequenceLabels, 'KFold', k);

% Initialize performance storage
metrics = {'Accuracy', 'Precision', 'Recall', 'F1Score'};
models = {'Transformer', 'Advanced SVM', 'Subspace KNN', 'Random Forest', 'Gradient Boosting'};
resultsMean = array2table(zeros(5, 4), 'VariableNames', metrics, 'RowNames', models);
resultsStd = array2table(zeros(5, 4), 'VariableNames', metrics, 'RowNames', models);

% Loop over the folds for each model
for modelIdx = 1:length(models)
    accuracies = zeros(k, 1);
    precisions = zeros(k, 1);
    recalls = zeros(k, 1);
    f1Scores = zeros(k, 1);

    for i = 1:k
        idxTrain = training(cv, i);
        idxTest = test(cv, i);

        % Define the network architecture
         switch models{modelIdx}
            case 'Transformer'
                % Assuming sequenceData and sequenceLabels are preprocessed and available
                XTrain = sequenceData(idxTrain);
                YTrain = sequenceLabels(idxTrain);
                XTest = sequenceData(idxTest);
                YTest = sequenceLabels(idxTest);
        
                % layers = [
                %     sequenceInputLayer(numTimePoints, 'Name', 'input')
                %     bilstmLayer(50, 'OutputMode', 'last', 'Name', 'bilstm1')
                %     dropoutLayer(0.5, 'Name', 'dropout1')
                %     selfAttentionLayer(4, 64, 'Name', 'attention')
                %     bilstmLayer(50, 'OutputMode', 'last', 'Name', 'bilstm2')
                %     dropoutLayer(0.5, 'Name', 'dropout2')
                %     fullyConnectedLayer(3, 'Name', 'fc')
                %     softmaxLayer('Name', 'softmax')
                %     classificationLayer('Name', 'output')
                % ];

                layers = [
                    sequenceInputLayer(numTimePoints, 'Name', 'input')
                    bilstmLayer(50, 'OutputMode', 'last', 'Name', 'bilstm1')
                    dropoutLayer(0.5, 'Name', 'dropout1')
                    bilstmLayer(50, 'OutputMode', 'last', 'Name', 'bilstm2')
                    fullyConnectedLayer(3, 'Name', 'fc')
                    softmaxLayer('Name', 'softmax')
                    classificationLayer('Name', 'output')
                ];
        
            otherwise
                % For ML models, use the feature data
                XTrain = featureData(idxTrain, :);
                YTrain = featureLabels(idxTrain);
                XTest = featureData(idxTest, :);
                YTest = featureLabels(idxTest);
                
            % Handling various ML models
            switch models{modelIdx}
                case 'Advanced SVM'
                    % Create an SVM template specifying the kernel function and standardization
                    t = templateSVM('KernelFunction', 'rbf', 'Standardize', true);
                    % Train the ECOC model using the SVM template
                    svmModel = fitcecoc(XTrain, YTrain, 'Learners', t);
                    YPred = predict(svmModel, XTest);
                    
                case 'Subspace KNN'
                    knnModel = fitcknn(XTrain, YTrain, 'NumNeighbors', 5, 'NSMethod', 'exhaustive', 'Distance', 'euclidean', 'IncludeTies', true, 'BreakTies', 'nearest');
                    YPred = predict(knnModel, XTest);
                    
                case 'Random Forest'
                    rfModel = TreeBagger(100, XTrain, YTrain, 'OOBPrediction', 'On', 'Method', 'classification');
                    YPred = predict(rfModel, XTest);
                    YPred = categorical(YPred);
                    
                case 'Gradient Boosting'
                    % Configure the boosting model using 'AdaBoostM2' for multiclass classification
                    gbModel = fitcensemble(XTrain, YTrain, 'Method', 'AdaBoostM2', 'NumLearningCycles', 30, 'Learners', templateTree('MaxNumSplits', 20));
                    YPred = predict(gbModel, XTest);
                  
                otherwise
                    error('Unknown model: %s', models{modelIdx});
            end

         end

        % Training options and train the network only for the Transformer
        if strcmp(models{modelIdx}, 'Transformer')
            options = trainingOptions('adam', ...
                'MaxEpochs', 500, ...
                'GradientThreshold', 1, ...
                'Shuffle', 'every-epoch', ...
                'Verbose', false);

                % 'InitialLearnRate',0.001,...
                % 'MiniBatchSize',64,...
            net = trainNetwork(XTrain, YTrain, layers, options);
            YPred = classify(net, XTest);
        end
        % Ensure YPred is a column vector if it might not be
        YPred = reshape(YPred, numel(YPred), 1);
        % Compute evaluation metrics
        confMat = confusionmat(YTest, YPred);
        [precision, recall, f1, ~] = precisionRecallF1(confMat);
        accuracy = sum(YPred == YTest) / numel(YTest);

        accuracies(i) = accuracy;
        precisions(i) = precision;
        recalls(i) = recall;
        f1Scores(i) = f1;
    end

    % Store mean and std dev of metrics
    resultsMean{modelIdx, :} = [mean(accuracies), mean(precisions), mean(recalls), mean(f1Scores)];
    resultsStd{modelIdx, :} = [std(accuracies), std(precisions), std(recalls), std(f1Scores)];
end

% Save results to file
writetable(resultsMean, 'meanResults.xlsx');
writetable(resultsStd, 'stdResults.xlsx');
disp('Training complete and results saved.');
resultsMean(1,1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [precision, recall, f1, support] = precisionRecallF1(confMat)
    numClasses = size(confMat,1);
    % Extract true positives, false positives, and false negatives
    TP = diag(confMat);
    FP = sum(confMat, 1)' - TP;
    FN = sum(confMat, 2) - TP;
    TN = sum(confMat(:)) - (TP + FP + FN);

    % Calculate precision, recall, and F1 score
    precision = NaN(numClasses, 1);
    recall = NaN(numClasses, 1);
    f1 = NaN(numClasses, 1);

    for i = 1:numClasses
        if TP(i) + FP(i) > 0
            precision(i) = TP(i) / (TP(i) + FP(i));
        end
        if TP(i) + FN(i) > 0
            recall(i) = TP(i) / (TP(i) + FN(i));
        end
        if precision(i) + recall(i) > 0
            f1(i) = 2 * (precision(i) * recall(i)) / (precision(i) + recall(i));
        end
    end

    % Calculate support (number of true cases for each class)
    support = sum(confMat, 2);

    % Return the mean of the metrics across all classes
    precision = nanmean(precision);
    recall = nanmean(recall);
    f1 = nanmean(f1);
end
