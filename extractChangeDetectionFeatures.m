function changeDetectionFeatures = extractChangeDetectionFeatures(signal)
    % Extract change detection features from a PMU time series
    % Input:
    %   signal - vector containing the PMU time series data
    % Output:
    %   changeDetectionFeatures - a numeric vector containing the extracted change detection features

    % Detect Change Points using the Cumulative Sum (CUSUM) method
    changePoints = detectChangePoints(signal);
    
    % Compute CUSUM Scores and reduce to a single scalar value
    cusumScores = max(abs(cusum(signal)));  % Maximum deviation in cumulative sum
    
    % Perform Mann-Kendall Trend Test
    [mkTrend, mkPValue] = mannKendallTest(signal);
    
    % Bayesian Change Point Analysis
    bayesianCP = bayesianChangePoint(signal);
    
    % Aggregate features into a vector
    changeDetectionFeatures = [changePoints, cusumScores, mkTrend, mkPValue, bayesianCP];
end

function points = detectChangePoints(signal)
    % Detect change points in the signal using a simple CUSUM method
    meanSig = mean(signal);
    stdSig = std(signal);
    cusumVec = cumsum(signal - meanSig);
    points = sum(abs(diff(sign(cusumVec))) > 0);  % Count zero-crossings
end

function scores = cusum(signal)
    % Compute the cumulative sum of deviations from the mean
    meanSig = mean(signal);
    scores = cumsum(signal - meanSig);
end

function [trend, pValue] = mannKendallTest(signal)
    % Perform the Mann-Kendall trend test
    n = length(signal);
    S = 0;
    for k = 1:n-1
        for j = k+1:n
            S = S + sign(signal(j) - signal(k));
        end
    end
    % Calculate the test statistic
    varS = (n * (n - 1) * (2 * n + 5)) / 18;
    trend = S / sqrt(varS);
    pValue = normcdf(trend);  % Approximation
end

function cpIndex = bayesianChangePoint(signal)
    % Placeholder for Bayesian change point detection
    % Use a simple moving average to simulate Bayesian inference
    windowSize = round(length(signal) / 10);
    movingAvg = movmean(signal, windowSize);
    residuals = signal - movingAvg;
    cpIndex = sum(abs(diff(sign(residuals))) > 0);  % Count changes in sign
end
