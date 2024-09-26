function tsnePlotByWindow(featuresStruct, dimensions, isCombined, labels)
    windowLengths = fieldnames(featuresStruct);
    numWindows = length(windowLengths);
    metric = 'chebychev';
    figure;
    if isCombined
        % Combine all features into one array for a single plot
        combinedFeatures = [];
        combinedLabels = [];
        
        % Concatenate features from all windows
        for i = 1:numWindows
            combinedFeatures = [combinedFeatures; featuresStruct.(windowLengths{i})];
            combinedLabels = [combinedLabels; labels];
        end
        
        % Remove rows containing NaN values
        nanRows = any(isnan(combinedFeatures), 2);
        combinedFeatures = combinedFeatures(~nanRows, :);
        combinedLabels = combinedLabels(~nanRows, :);
        
        sgtitle(sprintf('%dD t-SNE Visualization - Combined', dimensions));
        Y = tsne(combinedFeatures, 'NumDimensions', dimensions,'Distance',metric);
        if dimensions == 2
            gscatter(Y(:,1), Y(:,2), combinedLabels,[],[],10);
            xlabel('Dim1');
            ylabel('Dim 2');
            grid on
        else
            cmap = lines(numel(unique(combinedLabels))); % Create a colormap
            labelIDs = grp2idx(combinedLabels); % Convert labels to numeric indices
            scatter3(Y(:,1), Y(:,2), Y(:,3), 10, cmap(labelIDs,:), 'filled');
            xlabel('Dim 1');
            ylabel('Dim 2');
            zlabel('Dim 3');
            grid on;
        end
    else
        % Separate windows in subplots
        sgtitle(sprintf('%dD t-SNE Visualization - Separate Windows', dimensions));
        for i = 1:numWindows
            subplot(2, 2, i);
            windowFeatures = featuresStruct.(windowLengths{i});
            
            % Remove rows containing NaN values
            nanRows = any(isnan(windowFeatures), 2);
            windowFeatures = windowFeatures(~nanRows, :);
            windowLabels = labels(~nanRows); % Adjust labels to match feature set
            
            Y = tsne(windowFeatures, 'NumDimensions', dimensions,'Distance',metric);
            if dimensions == 2
                gscatter(Y(:,1), Y(:,2), windowLabels,[],[],10);
                xlabel('Dim 1');
                ylabel('Dim 2');
                grid on
            else
                cmap = lines(numel(unique(windowLabels))); % Create a colormap
                labelIDs = grp2idx(windowLabels); % Convert labels to numeric indices
                scatter3(Y(:,1), Y(:,2), Y(:,3), 10, cmap(labelIDs,:), 'filled');
                xlabel('Dim 1');
                ylabel('Dim 2');
                zlabel('Dim 3');
                grid on;
            end
            title(sprintf('%s seconds window', windowLengths{i}(4:end)));
        end
    end
end