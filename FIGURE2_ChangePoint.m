clc;
clear;
close all;

% Define mechanisms with specific paths, log names, and cases
mechanisms = {
    'Weather', 'F:\Research\RAMS 2025\RAM_prognostic_modeling\PMU_data\Weather - Oct 27th 2020', 'Oct 27th 2020_failure_log.xlsx', [408, 83; 495, 245];
    'Lightning', 'F:\Research\RAMS 2025\RAM_prognostic_modeling\PMU_data\lightning - Sep 1st 2020', 'Sep 1st 2020_failure_log.xlsx', [975, 106; 1453, 277];
    'Failed AC Circuit Equip', 'F:\Research\RAMS 2025\RAM_prognostic_modeling\PMU_data\Failed AC Circuit Equip - Oct 28th 2020', 'Oct 28th 2020_failure_log.xlsx', [1172, 33; 1338, 85]
};

fig = figure;
globalLegends = {};

% Process each mechanism
for m = 1:size(mechanisms, 1)
    folderPath = mechanisms{m, 2};
    failureLogPath = fullfile(folderPath, mechanisms{m, 3});
    cases = mechanisms{m, 4};

    % Load failure events and terminal information
    opts = detectImportOptions(failureLogPath, 'Sheet', 'failure_event_log');
    opts = setvartype(opts, {'SectionID'}, 'double');
    opts = setvartype(opts, {'Date', 'time'}, 'datetime');
    opts = setvaropts(opts, {'time', 'Date'}, 'InputFormat', 'MM/dd/yyyy hh:mm:ss a');
    failureEvents = readtable(failureLogPath, opts);

    % Process each case
    for i = 1:size(cases, 1)
        sectionID = cases(i, 1);
        termID = cases(i, 2);
        dateStr = datestr(failureEvents.Date(1), 'yyyy-mm-dd');

        pmuDataPath = fullfile(folderPath, sprintf('%d %s.csv', termID, dateStr));
        if ~isfile(pmuDataPath)
            warning('Missing PMU data file: %s', pmuDataPath);
            continue;
        end

        pmuData = readtable(pmuDataPath);
        pmuData.UTC = datetime(pmuData.UTC, 'InputFormat', 'HH:mm:ss.S');

        selectedEvents = failureEvents(failureEvents.SectionID == sectionID, :);
        if isempty(selectedEvents)
            warning('No events found for Section ID %d in %s.', sectionID, mechanisms{m, 1});
            continue;
        end

        % Define time window around the event
        eventTime = selectedEvents.Date(1) + timeofday(selectedEvents.time(1));
        
        % Set pre-disturbance duration based on mechanism type
        if m == 2  % For Lightning
            preDisturbanceDuration = minutes(4);
        else  % For Severe Weather and Failed AC Circuit Equip
            preDisturbanceDuration = seconds(30);  % Adjusted to 30 seconds
        end
        postDisturbanceDuration = seconds(30);

        % Extract PMU data around the disturbance
        startTime = eventTime - preDisturbanceDuration;
        endTime = eventTime + postDisturbanceDuration;
        idx = pmuData.UTC >= startTime & pmuData.UTC <= endTime;
        
        % Extracted sub-table for analysis
        relevantData = pmuData(idx, :);

        % Change point detection with fixed number of changes
        % vChangePts = findchangepts(relevantData.VP_M, 'MaxNumChanges', 3, 'Statistic','rms');

        % Plotting
        subplot(3, 2, (m-1)*2 + i);
        yyaxis left;
        plot(relevantData.UTC, relevantData.VP_M/1000, 'DisplayName', 'Voltage (VP_M in kV)');
        ylabel('VP_M Voltage (kV)','FontSize',14);
        
        yyaxis right;
        plot(relevantData.UTC, relevantData.IP_M, 'DisplayName', 'Current (IP_M in A)');
        ylabel('IP_M Current (A)','FontSize',14);
        ylim([min(relevantData.IP_M)-5 max(relevantData.IP_M)]+5)
        
        % Mark change points and disturbance
        hold on;
        xline(eventTime, '--r', 'LineWidth', 2);
        % for cp = vChangePts
        %     xline(relevantData.UTC(cp), '--k', 'LineWidth', 1.5);
        % end

        title(sprintf('%s - Terminal ID %d', mechanisms{m, 1}, termID),'FontSize',14);
        xlabel('Time');
        grid on;
    end

    % Adding global legends
    if isempty(globalLegends)
        yyaxis left;
        globalLegends = [globalLegends, {'Voltage (VP_M in kV)'}];
        yyaxis right;
        globalLegends = [globalLegends, {'Current (IP_M in A)'}];
    end
end

% Unified legend for all subplots
% legend(globalLegends, 'Location', 'northoutside', 'Orientation', 'horizontal');

% Save figure with high quality for publication
set(fig, 'Units', 'Inches', 'Position', [0, 0, 16, 9], 'PaperUnits', 'Inches', 'PaperSize', [16, 9]);
% print(fig, 'ChangePointDetectionResults.png', '-dpng', '-r600');