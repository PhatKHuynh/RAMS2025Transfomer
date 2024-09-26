function features = extractTimeDomainFeatures(data)
    % Extract time-domain features from PMU data
    %
    % Input:
    %   data - a numeric vector containing PMU time series data
    %
    % Output:
    %   features - a numeric vector containing the extracted features

    % Basic statistical features
    meanVal = mean(data);
    medianVal = median(data);
    varVal = var(data);
    skewVal = skewness(data);
    kurtVal = kurtosis(data);
    
    % Peak-to-peak
    p2pVal = peak2peak(data);
    
    % Root mean square
    rmsVal = rms(data);
    
    % Zero-crossing rate
    zcrVal = sum(diff(data > mean(data)) ~= 0);
    
    % Crest factor
    crestFactor = max(abs(data)) / rmsVal;
    
    % Impulse factor
    impulseFactor = max(abs(data)) / mean(abs(data));
    
    % Autocorrelation (lag 1)
    if length(data) > 1
        autoCorr = xcorr(data, 1, 'coeff');
        autoCorr = autoCorr(2);  % Lag 1 autocorrelation
    else
        autoCorr = NaN;  % Undefined if data length is 1
    end
    
    % Time reversal asymmetry statistic
    if length(data) > 2
        trAsym = mean((data(3:end) - data(2:end-1)).^3);
    else
        trAsym = NaN;  % Undefined if data length is less than 3
    end

    % Compile all features into a vector
    features = [meanVal, medianVal, varVal, skewVal, kurtVal, ...
                p2pVal, rmsVal, zcrVal, crestFactor, impulseFactor, ...
                autoCorr, trAsym];
end
