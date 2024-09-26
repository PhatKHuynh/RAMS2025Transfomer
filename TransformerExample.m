clc, clear all, close all
load('WaveformData.mat')

numChannels = size(data{1},1);

idx = [3 4 5 12];
figure
tiledlayout(2,2)
for i = 1:4
    nexttile
    stackedplot(data{idx(i)}', ...
        DisplayLabels="Channel " + string(1:numChannels))
    
    xlabel("Time Step")
    title("Class: " + string(labels(idx(i))))
end