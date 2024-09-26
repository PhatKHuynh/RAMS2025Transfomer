clc, clear all, close all
% Define the directory containing the PMU files and the failure log
folderPath = 'R:\Research\RAMS 2025\RAM_prognostic_modeling\PMU_data\Failed AC Circuit Equip - Oct 28th 2020';

% Load failure events and terminal information
failureLogPath = fullfile(folderPath, 'Oct 28th 2020_failure_log.xlsx');
opts = detectImportOptions(failureLogPath, 'Sheet', 'failure_event_log');
opts = setvartype(opts, {'SectionID'}, 'double');
opts = setvartype(opts, {'Date', 'time'}, 'datetime'); % Ensure both are read as datetime
opts = setvaropts(opts, 'time', 'InputFormat', 'hh:mm:ss a');
opts = setvaropts(opts, 'Date', 'InputFormat', 'MM/dd/yyyy');
failureEvents = readtable(failureLogPath, opts);

terminalInfo = readtable(failureLogPath, 'Sheet', 'terminal_info');

% Extract unique SectionIDs and create a list dialog for selection
sectionIDs = unique(failureEvents.SectionID);
[indx, tf] = listdlg('PromptString', {'Select a Section ID:'},...
                     'SelectionMode', 'single',...
                     'ListString', cellstr(num2str(sectionIDs)));

% Proceed only if a selection is made
if tf
    sectionID = sectionIDs(indx);
    % Create UI to input time interval
    prompt = {'Minutes around the event:'};
    dlgtitle = 'Input Time Interval';
    dims = [1 50];
    definput = {'30'};
    minutesAround = str2double(inputdlg(prompt, dlgtitle, dims, definput));

    % Filter events by selected SectionID
    selectedEvents = failureEvents(failureEvents.SectionID == sectionID, :);
    termIDs = unique(terminalInfo.TermID(terminalInfo.SectionID == sectionID));

    % Sort events by time
    selectedEvents = sortrows(selectedEvents, 'Date');

    % Iterate over each event
    for eventIndex = 1:height(selectedEvents)
        eventTime = selectedEvents.Date(eventIndex) + timeofday(selectedEvents.time(eventIndex));
        figureTitle = sprintf('Event at %s - Section ID %d', datestr(eventTime, 'yyyy-mm-dd HH:MM:ss'), sectionID);
        figure('Name', figureTitle, 'NumberTitle', 'off');
        sgtitle(figureTitle, 'FontSize', 16);

        % Process each terminal for the current event
        for terminalIndex = 1:length(termIDs)
            termID = termIDs(terminalIndex);
            filePath = fullfile(folderPath, sprintf('%d 2020-10-28.csv', termID));
            if isfile(filePath)
                pmuData = readtable(filePath);
                pmuData.UTC = datetime(pmuData.UTC, 'InputFormat', 'HH:mm:ss.S');

                % Time range for plotting
                startTime = eventTime - minutes(minutesAround);
                endTime = eventTime + minutes(minutesAround);
                relevantData = pmuData(pmuData.UTC >= startTime & pmuData.UTC <= endTime, :);

                % Plot Voltage and Current for each terminal
                subplot(length(termIDs), 2, 2*terminalIndex-1);
                plot(relevantData.UTC, [relevantData.VP_M, relevantData.VA_M, relevantData.VB_M, relevantData.VC_M], 'LineWidth', 1);
                title(sprintf('Terminal ID %d - Voltages', termID));
                xlabel('Time');
                ylabel('Voltage (p.u.)');
                hold on
                xline(eventTime, '--r', 'LineWidth', 1.5, 'Label', 'Disturbance', 'LabelOrientation', 'horizontal', 'FontSize', 12, 'Color', 'red');

                grid on;
                legend({'VP_M', 'VA_M', 'VB_M', 'VC_M','Disturbance'}, 'Location', 'best', 'FontSize', 12);

                subplot(length(termIDs), 2, 2*terminalIndex);
                plot(relevantData.UTC, [relevantData.IP_M, relevantData.IA_M, relevantData.IB_M, relevantData.IC_M], 'LineWidth', 1);
                title(sprintf('Terminal ID %d - Currents', termID));
                xlabel('Time');
                ylabel('Current (A)');

                hold on;
                xline(eventTime, '--r', 'LineWidth', 1.5, 'Label', 'Disturbance', 'LabelOrientation', 'horizontal', 'FontSize', 12, 'Color', 'red');
                grid on;
                legend({'IP_M', 'IA_M', 'IB_M', 'IC_M','Disturbance'}, 'Location', 'best', 'FontSize', 12);
            else
                warning('File %s does not exist.', filePath);
            end
        end
    end
else
    disp('No SectionID selected. Exiting...');
end
