clc;
clear;
close all;
disp('Loading data...');

% Load the data table
data = load('F:\Research\RAMS 2025\RAM_prognostic_modeling\Code\AllFeasTable.mat');
allFeaturesTable = data.allFeaturesTable;

% Define feature selection methods
featureSelectionMethods = {'ReliefF', 'MRMR', 'Lasso', 'RandomForest'};
[methodIndex, tf] = listdlg('PromptString', 'Select a feature ranking method:', ...
                            'SelectionMode', 'single', 'ListString', featureSelectionMethods, ...
                            'ListSize', [300, 100]);

if tf == 0
    disp('No method selected. Exiting...');
    return;
end

% Get features and labels
features = allFeaturesTable(:, 1:end-1);
labels = allFeaturesTable.Labels;

% Define number of features to display
k = 10;  % Modify as needed

% Perform feature selection
switch featureSelectionMethods{methodIndex}
    case 'ReliefF'
        [ranking, weights] = relieff(table2array(features), labels, 5);
        [weights, idx] = sort(weights, 'descend');
        ranking = ranking(idx);
    case 'MRMR'
        [idx, weights] = fscmrmr(features, labels);
        [weights, sortIdx] = sort(weights, 'descend');  % Sort scores in descending order
        idx = idx(sortIdx);  % Reorder indices based on sorted scores
    case 'Lasso'
        [B, FitInfo] = lasso(table2array(features), labels, 'CV', 10);
        weights = abs(B(:, FitInfo.Index1SE));
        [weights, idx] = sort(weights, 'descend');
    case 'RandomForest'
        model = TreeBagger(100, features, labels, 'Method', 'classification', 'OOBPrediction', 'On', 'OOBPredictorImportance', 'on');
        weights = model.OOBPermutedPredictorDeltaError;
        [weights, idx] = sort(weights, 'descend');
end

% Extract the top k features
topKFeatures = features.Properties.VariableNames(idx(1:k));
topKWeights = weights(1:k);
topKFeatures = strrep(topKFeatures, 'min', 'win');

k = 5;
% Extract the top k features for t-SNE
selectedFeatures = features(:, idx(1:k));

% Run t-SNE
Y = tsne(table2array(selectedFeatures),'Algorithm','exact','Distance','euclidean','NumDimensions',2,'Perplexity',30);
% Replace NaN values with zeros in t-SNE output
Y(isnan(Y)) = 0;

% Create t-SNE plot
figure;
gscatter(Y(:,1), Y(:,2), labels);
xlabel('t-SNE Dimension 1');
ylabel('t-SNE Dimension 2');
legend('Location', 'bestoutside','Interpreter','none');
set(gca, 'FontSize', 12);
grid on;

% % Create t-SNE plot
% figure;
% scatter3(Y(:,1), Y(:,2), Y(:,3), 10, categorical(labels), 'filled');
% title(sprintf('3D t-SNE Plot by Failure Mode Using Top %d Features from %s', k, featureSelectionMethods{methodIndex}));
% xlabel('t-SNE Dimension 1');
% ylabel('t-SNE Dimension 2');
% zlabel('t-SNE Dimension 3');
% legend(unique(categorical(labels)));
% set(gca, 'FontSize', 12);
% grid on;