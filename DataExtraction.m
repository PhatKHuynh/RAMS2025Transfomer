% Define the directory and file paths
folderPath = 'R:\Research\RAMS 2025\RAM_prognostic_modeling\PMU_data\Weather - Feb 2nd 2022';
outputFolder = fullfile(folderPath, 'ProcessedPMUData');

% Ensure the output directory exists
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Load event log and terminal information
failureLogPath = fullfile(folderPath, '2022-02-02_failure_log.xlsx');
failureEvents = readtable(failureLogPath, 'Sheet', 'failure_event_log');
terminalInfo = readtable(failureLogPath, 'Sheet', 'terminal_info');

% Load the log of failure events with correct import settings
opts = detectImportOptions(fullfile(folderPath, '2022-02-02_failure_log.xlsx'), 'Sheet', 'failure_event_log');
opts = setvartype(opts, {'SectionID'}, 'double');
opts = setvartype(opts, {'Date', 'time'}, 'datetime');  % Ensure both are read as datetime
opts = setvaropts(opts, 'Date', 'InputFormat', 'MM/dd/yyyy');
opts = setvaropts(opts, 'time', 'InputFormat', 'hh:mm:ss a');

failureEvents = readtable(fullfile(folderPath, '2022-02-02_failure_log.xlsx'), opts);

% Correct way to combine Date and time into one datetime
failureEvents.FullTime = failureEvents.Date + timeofday(failureEvents.time);

failureEvents = sortrows(failureEvents, 'FullTime');

% Iterate through each event to process and save relevant PMU data
for i = 1:height(failureEvents)
    sectionID = failureEvents.SectionID(i);
    eventTime = failureEvents.FullTime(i);

    % Find the corresponding terminal ID
    termID = terminalInfo.TermID(terminalInfo.SectionID == sectionID);

    % Load PMU data for this terminal
    filePath = fullfile(folderPath, sprintf('%d 2022-02-02.csv', termID));
    if isfile(filePath)
        pmuData = readtable(filePath);
        pmuData.UTC = datetime(pmuData.UTC, 'InputFormat', 'HH:mm:ss.S');

        % Determine the time range for data extraction
        if i < height(failureEvents)
            nextEventTime = failureEvents.FullTime(i + 1);
        else
            nextEventTime = eventTime + minutes(30);  % Extend if it's the last event
        end

        % Extract data 30 minutes before to 30 minutes after the event
        startTime = eventTime - minutes(30);
        endTime = min(eventTime + minutes(30), nextEventTime);
        relevantData = pmuData(pmuData.UTC >= startTime & pmuData.UTC <= endTime, :);

        % Save extracted data
        outputFile = fullfile(outputFolder, sprintf('Terminal_%d_Event_%s.csv', termID, datestr(eventTime, 'yyyy-mm-dd_HH-MM-SS')));
        writetable(relevantData, outputFile);
    else
        warning('File %s does not exist.', filePath);
    end
end
