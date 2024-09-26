function waveletFeatures = extractWaveletBasedFeatures(signal)
    % Extract wavelet-based features from a PMU time series
    %
    % Input:
    %   signal - vector containing the PMU time series data
    %
    % Output:
    %   waveletFeatures - a vector containing the extracted wavelet-based features

    % Define wavelet function and decomposition level
    waveletFunction = 'db4';
    level = 4;

    % Perform wavelet decomposition
    [C, L] = wavedec(signal, level, waveletFunction);
    
    % Calculate wavelet energy for each level and the total energy
    energy = sum(C.^2);
    energyPerLevel = zeros(1, level + 1);
    for i = 1:level + 1
        index = sum(L(1:i-1)) + 1:sum(L(1:i));
        energyPerLevel(i) = sum(C(index).^2);
    end
    
    % Calculate Wavelet Entropy
    energyDist = energyPerLevel / energy;
    waveletEntropy = -sum(energyDist .* log(energyDist + eps));
    
    % Calculate Wavelet Variance
    waveletVariance = var(C);

    % Calculate Total Wavelet Coefficients
    totalWaveletCoeff = sum(abs(C));

    % Calculate Wavelet Kurtosis and Skewness
    waveletKurtosis = kurtosis(C);
    waveletSkewness = skewness(C);
    
    % Aggregate features
    waveletFeatures = [energyPerLevel, waveletEntropy, waveletVariance, totalWaveletCoeff, waveletKurtosis, waveletSkewness];
end
