load WaveformData 
numChannels = size(data{1},2);

idx = [3 4 5 12];
figure
tiledlayout(2,2)
for i = 1:4
    nexttile
    stackedplot(data{idx(i)},DisplayLabels="Channel "+string(1:numChannels))
    
    xlabel("Time Step")
    title("Class: " + string(labels(idx(i))))
end

classNames = categories(labels)

numObservations = numel(data);
[idxTrain,idxTest] = trainingPartitions(numObservations,[0.9 0.1]);
XTrain = data(idxTrain);
TTrain = labels(idxTrain);

XTest = data(idxTest);
TTest = labels(idxTest);

numObservations = numel(XTrain);
for i=1:numObservations
    sequence = XTrain{i};
    sequenceLengths(i) = size(sequence,1);
end

[sequenceLengths,idx] = sort(sequenceLengths);
XTrain = XTrain(idx);
TTrain = TTrain(idx);

figure
bar(sequenceLengths)
xlabel("Sequence")
ylabel("Length")
title("Sorted Data")

numHiddenUnits = 120;
numClasses = 4;

layers = [
    sequenceInputLayer(numChannels)
    bilstmLayer(numHiddenUnits,OutputMode="last")
    fullyConnectedLayer(numClasses)
    softmaxLayer]

options = trainingOptions("adam", ...
    MaxEpochs=200, ...
    InitialLearnRate=0.002,...
    GradientThreshold=1, ...
    Shuffle="never", ...
    Plots="training-progress", ...
    Metrics="accuracy", ...
    Verbose=false);

net = trainnet(XTrain,TTrain,layers,"crossentropy",options);

acc = testnet(net,XTest,TTest,"accuracy")

scores = minibatchpredict(net,XTest);
YTest = scores2label(scores,classNames);

figure
confusionchart(TTest,YTest)