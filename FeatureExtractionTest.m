clc;
clear;
close all;
disp('Starting the analysis...');

% Input 1: Select Group of Features
featureChoices = {'Time-domain', 'Frequency-domain', 'Information-theoretic', ...
                  'Wavelet-based', 'Recurrence Quantification Analysis (RQA)', ...
                  'System Dynamics', 'Change Detection Features', 'All Features'};
featureChoice = listdlg('PromptString', 'Select a group of features to extract:', ...
                        'SelectionMode', 'single', 'ListString', featureChoices);

disp(['You selected: ', featureChoices{featureChoice}]);

% % Input 2: Plot Options
% plotChoices = {'2D t-SNE for each window length', '3D t-SNE for each window length', ...
%                '2D t-SNE combined (single figure)', '3D t-SNE combined (single figure)','Exit'};
% plotChoice = listdlg('PromptString', 'Choose your plot option:', ...
%                      'SelectionMode', 'single', 'ListString', plotChoices);

% Path to data
basePath = 'G:\\PMU_data';

% Get the failure types
failureTypes = {'weather', 'lightning', 'failed_AC_circuit'};

% Initialize variables for feature collection and labels
allFeatures = struct('min30', [], 'min60', [], 'min120', [], 'min240', []);
labels = {};

% Process each failure type
for i = 1:length(failureTypes)
    failurePath = fullfile(basePath, failureTypes{i});
    disp(['Processing ', failureTypes{i}, '...']);
    [featuresForType, failureLabels] = processFailureType(failurePath, featureChoice, i);
    for fn = fieldnames(featuresForType)'
        allFeatures.(fn{1}) = [allFeatures.(fn{1}) featuresForType.(fn{1})];
    end
    labels = [labels; repmat(failureTypes(i), length(failureLabels)/4, 1)];  % Assume each event produces an entry per window
end

% Perform t-SNE based on plot choice
disp('Performing t-SNE analysis...');
% Input 2: Plot Options
plotChoices = {'2D t-SNE for each window length', '3D t-SNE for each window length', ...
               '2D t-SNE combined (single figure)', '3D t-SNE combined (single figure)'};
plotChoice = listdlg('PromptString', 'Choose your plot option:', ...
                     'SelectionMode', 'single', 'ListString', plotChoices);
if plotChoice == 1 || plotChoice == 2
    tsnePlotByWindow(allFeatures, 2 + plotChoice - 1, false, labels);  % 2D or 3D t-SNE separate
elseif plotChoice == 3 || plotChoice == 4
    tsnePlotByWindow(allFeatures, 2 + plotChoice - 3, true, labels);  % 2D or 3D t-SNE combined
end
disp('Analysis complete.');

function [featuresStruct, failures] = processFailureType(failurePath, featureChoice, failureType)
    dateFolders = dir(fullfile(failurePath, '*'));
    dateFolders = dateFolders([dateFolders.isdir] & ~startsWith({dateFolders.name}, '.'));
    featuresStruct = struct('min30', [], 'min60', [], 'min120', [], 'min240', []);
    failures = [];

    for i = 1:length(dateFolders)
        currentDatePath = fullfile(failurePath, dateFolders(i).name);
        failureLogPath = fullfile(currentDatePath, [dateFolders(i).name, '_failure_log.xlsx']);
        
        opts = detectImportOptions(failureLogPath);
        opts = setvartype(opts, {'Date', 'time'}, 'datetime');  % Import Date and time as datetime
        opts = setvaropts(opts, {'Date'}, 'InputFormat', 'MM/dd/yyyy');
        opts = setvaropts(opts, {'time'}, 'InputFormat', 'hh:mm:ss a');

        failureData = readtable(failureLogPath, opts);
        failureData.time = failureData.time + (failureData.Date - dateshift(failureData.time, 'start', 'day'));

        for j = 1:height(failureData)
            failTime = failureData.time(j);
            fileToRead = fullfile(currentDatePath, [num2str(failureData.TermID(j)), ' ', dateFolders(i).name, '.csv']);
            disp(['Reading file: ', fileToRead]);
            data = readtable(fileToRead);
            data.Time = datetime(data.UTC, 'InputFormat', 'hh:mm:ss.S');
            windows = [4, 2, 1, 0.5]; % Minutes before failure
            windowNames = {'min30', 'min60', 'min120', 'min240'};

            for w = 1:length(windows)
                startTime = failTime - minutes(windows(w));
                relevantData = data(data.Time >= startTime & data.Time < failTime, :);
                tsData = table2array(relevantData(:, 2:end-2));  % Assume the last two columns are not time series data

                for col = 1:size(tsData, 2)  % Iterate over each column/time series
                    timeSeriesData = tsData(:, col);
                    extractedFeatures = extractFeaturesByChoice(timeSeriesData, featureChoice);
                    featuresStruct.(windowNames{w}) = [featuresStruct.(windowNames{w}) extractedFeatures];
                end
                failures = [failures; failureType];
            end
        end
    end
end

function features = extractFeaturesByChoice(data, choice)
    switch choice
        case 1
            features = extractTimeDomainFeatures(data);
        case 2
            features = extractFrequencyDomainFeatures(data);
        case 3
            features = extractInformationTheoreticFeatures(data);
        case 4
            features = extractWaveletBasedFeatures(data);
        case 5
            features = extractRQAFeatures(data);
        case 6
            features = extractSystemDynamicsFeatures(data);
        case 7
            features = extractChangeDetectionFeatures(data);
        case 8
            features = [extractTimeDomainFeatures(data), ...
                        extractFrequencyDomainFeatures(data), ...
                        extractInformationTheoreticFeatures(data), ...
                        extractWaveletBasedFeatures(data), ...
                        extractRQAFeatures(data), ...
                        extractSystemDynamicsFeatures(data), ...
                        extractChangeDetectionFeatures(data)];
    end
end