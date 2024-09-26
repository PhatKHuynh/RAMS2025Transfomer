function systemDynamicsFeatures = extractSystemDynamicsFeatures(signal)
    % Downsample signal to reduce computational complexity
    if length(signal) > 1000
        signal = downsample(signal, ceil(length(signal)/1000));
    end
    
    % Check if the downsampled signal has no variation
    if all(signal == signal(1))
        % Assign default values if the signal is constant
        lyapunovExponent = 0;
        fractalDimension = 0;
        hurstExponent = 0.5; % Typical value for a completely random process
        correlationDimension = 0;
    else
        % Extract features
        lyapunovExponent = lyapunovExponentEstimate(signal);
        fractalDimension = boxCountingDimension(signal);
        hurstExponent = estimateHurstExponent(signal);
        correlationDimension = correlationDimensionEstimate(signal);
    end

    % Aggregate features into a single vector
    systemDynamicsFeatures = [lyapunovExponent, fractalDimension, hurstExponent, correlationDimension];
end

function lambda = lyapunovExponentEstimate(signal)
    m = 3; % Embedding dimension
    tau = 1; % Time delay
    Y = phaseSpaceReconstruction(signal, m, tau);
    lambda = rosensteinMethod(Y);
    if isnan(lambda) || lambda == 0 % Check if lambda is NaN or zero
        lambda = 0;
        disp('Failed to compute a valid Lyapunov Exponent.');
    end
end

function Y = phaseSpaceReconstruction(signal, m, tau)
    N = length(signal);
    Y = zeros(N - (m-1) * tau, m);
    for i = 1:m
        Y(:, i) = signal((1:N - (m-1) * tau) + (i-1) * tau);
    end
end

function D = boxCountingDimension(signal)
    N = length(signal);
    scales = ceil(logspace(0, log10(N), min(10, N)));
    Ns = arrayfun(@(scale) sum(countBoxes(signal, scale)), scales);
    coeffs = polyfit(log(scales), log(Ns), 1);
    D = -coeffs(1);
end

function count = countBoxes(data, scale)
    edges = linspace(min(data), max(data), ceil((max(data) - min(data)) / scale) + 1);
    count = nnz(histcounts(data, edges) > 0);
end

function H = estimateHurstExponent(signal)
    n = length(signal);
    Y = cumsum(signal - mean(signal));
    R = max(Y) - min(Y);
    S = std(signal);
    H = log(R/(S * sqrt(n))) / log(n);
end

function dim = correlationDimensionEstimate(signal)
    m = 3;  % Embedding dimension
    tau = 1; % Time delay
    Y = phaseSpaceReconstruction(signal, m, tau);
    dim = grassbergerProcacciaMethod(Y);
    if isnan(dim) || isempty(dim) || dim == 0 % Handle NaN, empty, or zero dimension
        dim = 0;
    else
        % Log for debugging
        disp(['Computed dimension: ', num2str(dim)]);
    end
end

function lambda = rosensteinMethod(Y)
    N = size(Y, 1);
    epsilon = 100; % Small initial separation
    minDist = inf(N, 1);
    k = 10; % Forward steps to look at divergence
    deltaT = 1; % Minimum time separation

    % Efficiently find minimal distances using vectorized operations
    for i = 1:N
        distances = vecnorm(Y - Y(i,:), 2, 2);
        % Exclude nearby points in time, handle boundaries
        rangeStart = max(1, i-deltaT);
        rangeEnd = min(N, i+deltaT);
        distances(rangeStart:rangeEnd) = inf; 
        minDist(i) = min(distances);
    end

    % Track divergence only for those pairs that are initially closer than epsilon
    dJ = zeros(N, 1);
    for i = 1:N-k
        for j = (i+deltaT):N-k
            if norm(Y(i,:) - Y(j,:)) < epsilon
                dJ(i) = norm(Y(i+k,:) - Y(j+k,:));
            end
        end
    end

    % Consider only valid divergences
    validDJs = dJ(dJ > 0);  % Ensure we only take into account meaningful divergences
    if isempty(validDJs)
        lambda = NaN;
    else
        lambda = mean(log(validDJs / epsilon)) / (k * deltaT);
    end
end

function dim = grassbergerProcacciaMethod(Y)
    N = size(Y, 1);
    if N < 20  % Ensure there are enough points to calculate
        disp('Not enough data points to estimate dimension.');
        dim = NaN;
        return;
    end

    distances = pdist(Y);
    if isempty(distances) || all(distances == 0)
        disp('Distances computation failed or all distances are zero.');
        dim = NaN;
        return;
    end

    % Establishing a range for r that avoids too narrow range which might lead to inaccurate slopes
    rmin = max(min(distances)*10, 1e-3);
    rmax = max(distances);
    if rmin >= rmax
        disp('Invalid range for r, setting dimension to NaN.');
        dim = NaN;
        return;
    end

    r = logspace(log10(rmin), log10(rmax), 10);
    C = arrayfun(@(x) sum(distances < x), r) / (N * (N - 1) / 2);

    % Check for a sufficient range of C values to fit a line
    if any(diff(log(C)) == 0)
        disp('Insufficient variation in correlation sums.');
        dim = NaN;
        return;
    end

    coeffs = polyfit(log(r), log(C), 1);
    dim = coeffs(1);
    disp(['Log-Log slope (Dimension): ', num2str(dim)]);
end

% Replace NaNs with a specified number
function out = nan_to_num(array, num)
    out = array;
    out(isnan(out)) = num;
end