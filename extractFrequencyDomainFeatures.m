function freqFeatures = extractFrequencyDomainFeatures(signal)
    % Extract frequency-domain features from a PMU time series
    %
    % Input:
    %   signal - vector containing the PMU time series data
    %
    % Output:
    %   freqFeatures - a numeric vector containing the extracted frequency-domain features

    % Fixed sampling frequency
    fs = 30;  % Sampling frequency in Hz

    % Compute the Power Spectral Density (PSD)
    [pxx, f] = pwelch(signal, [], [], [], fs, 'power');
    
    % Fundamental Frequency
    [~, idx] = max(pxx);
    fundamentalFreq = f(idx);
    
    % Spectral Entropy
    pxxNorm = pxx / sum(pxx);
    spectralEntropy = -sum(pxxNorm .* log(pxxNorm + eps));
    
    % Harmonics and Interharmonic Distortion
    if fundamentalFreq > 0  % Ensure fundamental frequency is not zero
        harmonicBands = (f > fundamentalFreq & f < 5 * fundamentalFreq);
        interharmonicBands = (f > 5 * fundamentalFreq);
        harmonics = sum(pxx(harmonicBands));  % Sum of harmonics
        interharmonicDistortion = sum(pxx(interharmonicBands));  % Sum of interharmonics
    else
        harmonics = 0;
        interharmonicDistortion = 0;
    end
    
    % Spectral Flatness
    spectralFlatness = geomean(pxxNorm + eps) / mean(pxxNorm + eps);
    
    % Spectral Kurtosis and Skewness
    spectralKurtosis = kurtosis(pxx);
    spectralSkewness = skewness(pxx);
    
    % Aggregate all scalar features into a numeric vector
    freqFeatures = [fundamentalFreq, spectralEntropy, harmonics, interharmonicDistortion,...
        spectralFlatness, spectralKurtosis, spectralSkewness];
end
