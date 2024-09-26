function infoFeatures = extractInformationTheoreticFeatures(signal)
    % Extract information-theoretic features from a PMU time series
    %
    % Input:
    %   signal - vector containing the PMU time series data
    %
    % Output:
    %   infoFeatures - a vector containing the extracted features
    
    % Calculate Shannon Entropy
    probDist = histcounts(signal, 'Normalization', 'probability');
    entropy = -sum(probDist .* log2(probDist + eps));
    
    % Calculate Mutual Information (placeholder example)
    % For demonstration, assuming signal has been split or compared to a delayed version
    mutualInfo = mutualInformation(signal, circshift(signal, 1));  % Shift signal by one for simplicity
    
    % Calculate Conditional Entropy (also placeholder)
    condEntropy = conditionalEntropy(signal, circshift(signal, 1));
    
    % Calculate Perplexity
    perplexity = 2^entropy;
    
    % Calculate Complexity (Simplified example)
    complexity = std(signal) * entropy;
    
    % Aggregate features
    infoFeatures = [entropy, mutualInfo, condEntropy, perplexity, complexity];
end

function MI = mutualInformation(X, Y)
    % Simple estimation of mutual information using histogram counts
    jointHist = histcounts2(X, Y, 'Normalization', 'probability');
    margX = sum(jointHist, 1);
    margY = sum(jointHist, 2);
    HX = -sum(margX .* log2(margX + eps));
    HY = -sum(margY .* log2(margY + eps));
    HXY = -sum(jointHist(:) .* log2(jointHist(:) + eps));
    MI = HX + HY - HXY;
end

function H = conditionalEntropy(X, Y)
    % Calculate conditional entropy H(X|Y)
    jointHist = histcounts2(X, Y, 'Normalization', 'probability');
    sumJointHist = sum(jointHist, 1);  % Sum over rows to get the marginal probabilities of Y

    % Initialize conditional probabilities
    condProb = zeros(size(jointHist));

    % Calculate conditional probabilities where sumJointHist is not zero
    valid = sumJointHist > 0;
    condProb(:, valid) = bsxfun(@rdivide, jointHist(:, valid), sumJointHist(valid));

    % Compute conditional entropy
    jointProb = jointHist(:);  % Flatten the joint histogram for easier computation
    logCondProb = log2(condProb + eps);  % Use eps to avoid log(0)
    H = -sum(jointProb .* logCondProb(:));  % Sum over all entries
end
