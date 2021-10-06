%%
% read data
clc; clear; close all
BScan_raw = imread('../data/05-Oct-2021_BScan{detector_card}.png');
BScan = rgb2gray(BScan_raw(100:end-100,100:end-100,:));

% =============== main workflow ===============
% binary thresholding
AScan_peak = max(BScan);
global_peak = max(AScan_peak);
threshold = 0.8*global_peak;
BScan_bw = BScan > threshold;
% find surface
[~,ind] = max(BScan_bw(:,:));
% fit line to surface using A = xB
x = [ones(size(BScan,2),1), (1:size(BScan,2))'];
B = x\(ind');
% =============================================

% visualization
imagesc(BScan)
hold on
% plot surface contour
plot(1:size(BScan,2),ind,'-r','LineWidth',2)
% plot surface fitting
plot(1:size(BScan,2),B(1)+B(2)*(1:size(BScan,2)),'-c','LineWidth',1);
legend('surface contour', 'fitted slope')
colormap gray