% Define the directory containing the PMU files and the failure log
folderPath = 'R:\Research\RAMS 2025\RAM_prognostic_modeling\PMU_data\Weather - Feb 2nd 2022';

% Define import options for reading the failure event log with specific types
opts = detectImportOptions(fullfile(folderPath, '2022-02-02_failure_log.xlsx'), 'Sheet', 'failure_event_log');
opts = setvartype(opts, {'SectionID'}, 'double');
opts = setvartype(opts, {'Date', 'time'}, 'datetime');  % Ensure both are read as datetime
opts = setvaropts(opts, 'time', 'InputFormat', 'hh:mm:ss a');
opts = setvaropts(opts, 'Date', 'InputFormat', 'MM/dd/yyyy');

% Load the log of failure events and sort by event time
failureEvents = readtable(fullfile(folderPath, '2022-02-02_failure_log.xlsx'), opts);
failureEvents.FullTime = failureEvents.Date + timeofday(failureEvents.time);
failureEvents = sortrows(failureEvents, 'FullTime');

% Read terminal info
opts = detectImportOptions(fullfile(folderPath, '2022-02-02_failure_log.xlsx'), 'Sheet', 'terminal_info');
terminalInfo = readtable(fullfile(folderPath, '2022-02-02_failure_log.xlsx'), opts);

% Map terminal IDs to section IDs
sectionToTerminal = containers.Map(terminalInfo.SectionID, terminalInfo.TermID);

% Initialization for figure and subplot management
eventsPerFigure = 3;  % 3 events per figure, 2 subplots each
numFigures = ceil(height(failureEvents) / eventsPerFigure);
currentFigure = 1;
subplotCounter = 0;

% Iterate through each event and plot the corresponding PMU data
for i = 1:height(failureEvents)
    sectionID = failureEvents.SectionID(i);
    if isKey(sectionToTerminal, sectionID)
        termID = sectionToTerminal(sectionID);
        eventTime = failureEvents.FullTime(i);

        % Construct file path
        filePath = fullfile(folderPath, sprintf('%d 2022-02-02.csv', termID));
        
        % Check if the file exists
        if isfile(filePath)
            % Load PMU data
            pmuData = readtable(filePath);
            pmuData.UTC = datetime(pmuData.UTC, 'InputFormat', 'HH:mm:ss.S');  % Correcting the column name to 'UTC'

            % Extract data for the main and zoomed-in plots
            mainStartTime = eventTime - minutes(10);
            mainEndTime = eventTime + minutes(10);
            zoomStartTime = eventTime - minutes(1);
            zoomEndTime = eventTime + minutes(1);

            mainIdx = pmuData.UTC >= mainStartTime & pmuData.UTC <= mainEndTime;
            zoomIdx = pmuData.UTC >= zoomStartTime & pmuData.UTC <= zoomEndTime;

            mainData = pmuData(mainIdx, :);
            zoomData = pmuData(zoomIdx, :);

            % Figure and subplot management
            if subplotCounter == 0 || subplotCounter >= eventsPerFigure
                figure;
                subplotCounter = 0;
                currentFigure = currentFigure + 1;
            end

            % Main Event Plot
            subplot(eventsPerFigure, 2, subplotCounter * 2 + 1);
            plot(mainData.UTC, mainData.VP_M, 'LineWidth', 2);  % Example: Plotting VP_M
            hold on;
            grid on;
            xline(eventTime, '--r', 'LineWidth', 2);
            title(sprintf('10-min Window for Event at %s', datestr(eventTime, 'HH:MM:ss')));

            % Zoomed-in Plot
            subplot(eventsPerFigure, 2, subplotCounter * 2 + 2);
            plot(zoomData.UTC, zoomData.VP_M, 'LineWidth', 2);
            hold on;
            grid on;
            xline(eventTime, '--r', 'LineWidth', 2);
            title(sprintf('1-min Zoom for Event at %s', datestr(eventTime, 'HH:MM:ss')));

            subplotCounter = subplotCounter + 1;
        else
            warning('File %s does not exist.', filePath);
        end
    end
end
