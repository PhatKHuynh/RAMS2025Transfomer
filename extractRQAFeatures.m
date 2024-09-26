function rqaFeatures = extractRQAFeatures(signal)
    % Extract RQA features from a PMU time series

    % Embedding parameters
    dim = 3;  % Embedding dimension
    tau = 5;  % Time delay

    % Reconstruct the phase space
    embeddedSignal = phaseSpaceReconstruction(signal, dim, tau);
    
    % Compute the recurrence plot
    RP = computeRecurrencePlot(embeddedSignal);
    
    % Compute RQA measures
    [RR, DET, LAM, TT, ENT, Trend, Drift, Divergence, RP_DENS_ENT] = computeRQAMeasures(RP);

    % Output vector of features
    rqaFeatures = [RR, DET, LAM, TT, ENT, Trend, Drift, Divergence, RP_DENS_ENT];
end

function embeddedSignal = phaseSpaceReconstruction(signal, dim, tau)
    % Phase space reconstruction using delay embedding theorem
    N = length(signal);
    M = N - (dim - 1) * tau;
    embeddedSignal = zeros(M, dim);
    for i = 1:dim
        embeddedSignal(:, i) = signal((1:M) + (i-1) * tau);
    end
end

function RP = computeRecurrencePlot(embeddedSignal)
    % Compute a recurrence plot using a fixed threshold
    threshold = 0.1 * std(embeddedSignal(:));
    N = size(embeddedSignal, 1);
    RP = zeros(N, N);
    for i = 1:N
        for j = 1:N
            if norm(embeddedSignal(i,:) - embeddedSignal(j,:)) < threshold
                RP(i, j) = 1;
            end
        end
    end
end

function [RR, DET, LAM, TT, ENT, Trend, Drift, Divergence, RP_DENS_ENT] = computeRQAMeasures(RP)
    % Calculate RQA measures from a recurrence plot
    N = size(RP, 1);
    RR = sum(RP(:)) / (N^2);  % Recurrence Rate

    % Diagonal statistics
    [DET, diagonalLengths] = calculateDiagonalStats(RP);
    
    % Vertical statistics
    [LAM, verticalLengths] = calculateVerticalStats(RP);
    
    TT = mean(verticalLengths);  % Mean Trapping Time
    ENT = -sum((diagonalLengths / sum(diagonalLengths)) .* log(diagonalLengths / sum(diagonalLengths) + eps));
    
    % Trend as correlation of sum of recurrences over time
    Trend = corr((1:N)', sum(RP, 2));  
    Drift = std(diff(sum(RP, 1)));  % Drift as the standard deviation of the differences of column sums
    Divergence = 1 / max(diagonalLengths, [], 'omitnan');  % Divergence as inverse of the longest diagonal
    
    RP_DENS_ENT = -sum((verticalLengths / sum(verticalLengths)) .* log(verticalLengths / sum(verticalLengths) + eps));
end

function [DET, lineLengths] = calculateDiagonalStats(RP)
    % Calculate statistics from diagonal lines of RP
    N = size(RP, 1);
    lineLengths = [];
    for k = -N+1:N-1
        diagLine = diag(RP, k);
        lengths = diff([0; find(diagLine == 0); length(diagLine)+1]) - 1;
        lineLengths = [lineLengths; lengths(lengths > 1)];
    end
    DET = sum(lineLengths) / sum(RP(:));  % Determinism
end

function [LAM, lineLengths] = calculateVerticalStats(RP)
    % Calculate statistics from vertical lines of RP
    N = size(RP, 1);
    lineLengths = [];
    for i = 1:N
        col = RP(:, i);
        lengths = diff([0; find(col == 0); length(col)+1]) - 1;
        lineLengths = [lineLengths; lengths(lengths > 1)];
    end
    LAM = sum(lineLengths) / sum(RP(:));  % Laminarity
end
