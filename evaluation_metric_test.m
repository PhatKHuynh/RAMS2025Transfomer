clc;
clear;
close all;

% Define metrics
metrics = {'Accuracy', 'Precision', 'Recall', 'F1-Score'};
rng(1)
% Classifiers and their expected accuracy levels
classifiers = {'Softmax', 'Random Forest', 'SVM', 'Gradient Boosting'};
accuracyLevels = [0.80, 0.85, 0.89, 0.91]-0.05; % Adjusted target accuracy with random noise
stdLevels = [0.08, 0.15, 0.05, 0.16];

% Number of data points per class in the test set and number of classes
numDataPoints = 30;
numClasses = 3;
totalPoints = numDataPoints * numClasses; % Total data points

% Number of folds
numFolds = 5;

% Initialize matrices to store results
results = zeros(numFolds, length(classifiers), length(metrics));
errors = zeros(length(classifiers), length(metrics));

% Generate true class labels
trueLabels = repmat(1:numClasses, numDataPoints, 1);
trueLabels = trueLabels(:);

% Simulate metrics for each classifier across fold
for i = 1:length(classifiers)
    accuracy = accuracyLevels(i);
    for fold = 1:numFolds
        accuracy = accuracy + stdLevels(i)*randn;
        % Simulate predictions based on classifier accuracy
        correctPredictions = rand(totalPoints, 1) < accuracy;
        predictedLabels = trueLabels;
        % Randomly assign incorrect predictions
        incorrectIndices = find(~correctPredictions);
        wrongPredictions = mod(predictedLabels(incorrectIndices) + randi([1, numClasses-1], length(incorrectIndices), 1), numClasses) + 1;
        predictedLabels(incorrectIndices) = wrongPredictions;

        % Calculate metrics
        C = confusionmat(trueLabels, predictedLabels);
        accuracyScore = sum(diag(C)) / sum(C(:));
        precisionScore = mean(diag(C) ./ sum(C, 2));
        recallScore = mean(diag(C) ./ sum(C, 1)');
        f1Score = 2 * (precisionScore * recallScore) / (precisionScore + recallScore);

        % Store results
        results(fold, i, :) = [accuracyScore, precisionScore, recallScore, f1Score];
    end

    % Calculate errors as standard deviation of folds
    errors(i, :) = std(results(:, i, :));
end

% Average results across folds
meanResults = squeeze(mean(results, 1));

% Plot results
figure;
hold on;
colors = lines(numel(classifiers));

% Distance between groups
groupSpacing = 0.5;

for m = 1:numel(metrics)
    % Offset each group by an additional space
    groupXBase = (m-1) * (numel(classifiers) + groupSpacing);
    for c = 1:numel(classifiers)
        % Compute the bar index within the group
        barX = groupXBase + c;
        bar(barX, meanResults(c, m), 'FaceColor', colors(c, :), 'BarWidth', 0.8);
    end
end

for m = 1:numel(metrics)
    % Offset each group by an additional space
    groupXBase = (m-1) * (numel(classifiers) + groupSpacing);
    for c = 1:numel(classifiers)
        % Compute the bar index wi
        % thin the group
        barX = groupXBase + c;
        errorbar(barX, meanResults(c, m), errors(c, m), 'k');
        text(barX, meanResults(c, m) + errors(c, m), sprintf('%.4f', meanResults(c, m)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12);
    end
end

% Adjust the axes and add labels
xticks = 1 + numel(classifiers)/2 : numel(classifiers) + groupSpacing : numel(metrics) * (numel(classifiers) + groupSpacing);
set(gca, 'XTick', xticks-0.5);
set(gca, 'XTickLabel', metrics);
ylabel('Metric Value');
ylim([0.7 1.05])
title('Performance Metrics Across Different Classifiers');
legend([classifiers], 'Location', 'northoutside', 'Orientation', 'horizontal');
grid on;

% Adjust figure settings for publication quality
set(gcf, 'Units', 'Inches', 'Position', [0, 0, 12, 6], 'PaperUnits', 'Inches', 'PaperSize', [12, 6]);
print(gcf, 'PerformanceMetricsComparison.png', '-dpng', '-r300');
