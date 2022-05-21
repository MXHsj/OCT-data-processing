%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: franka_3DOCT_attenuation_px.m
% author: Xihan Ma
% description: perform lateral mosaicing in 2D, then generate extinction coefficient map (overlap must be less than 50%)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
addpath(genpath('utilities/'));

% load BScan & pose data
data2load = 50; % 50:55
[data, data_sizes] = FrankaOCTDataManager(data2load);
fprintf('total frames: %d\n', sum(data_sizes))

clear data2load
height = size(data.OCT(:, :, 1), 1);
width = size(data.OCT(:, :, 1), 2);

%% stack BScans in lateral direction
BScan_blend = zeros(height, width * length(data_sizes), min(data_sizes) - 1, 'uint8');
tic;
for frm = 1:min(data_sizes) - 1
    % stitch images in lateral direction
    for i = 1:length(data_sizes)
        BScan_blend(:, (length(data_sizes) - i) * width + 1:(length(data_sizes) - i) * width + width, frm) ...
            = data.OCT(:, :, frm + sum(data_sizes(1:i - 1)));
    end
    fprintf('process (%d/%d) slice ... \n', frm, min(data_sizes) - 1);
end
clear frm isVis
fprintf('processing data takes %f sec \n', toc);

% volumeViewer(BScan_blend);
% save('mosaiced_volume.mat','BScan_blend','-v7.3');

%% generate attenuation map
ext_coeff_map = zeros(size(BScan_blend, 2), size(BScan_blend, 3), 'single');
tic;
for i = 1:size(BScan_blend, 3)
    [ec, ~] = GetExtCoeff(BScan_blend(:, :, i), 40, 110, false);
    ext_coeff_map(:, i) = ec;
    fprintf('process (%d/%d) slice ... \n', i, size(BScan_blend, 3));
end
clear i ec
fprintf('processing data takes %f sec \n', toc);

%% attenuation map before blending
grid = ext_coeff_map;
lowBound = 0;
upBound = mean(grid, 'all', 'omitnan') + 0.3 * std(grid, [], 'all', 'omitnan');
outlier_ind = grid < lowBound | grid > upBound;
grid(outlier_ind) = nan;
clear lowBound upBound outlier_ind

figure('Position', [1920/4, 1080/4, 1200, 500])
imagesc(grid); colormap gray; axis ij
xlabel('x [mm]'); ylabel('y [mm]')
colorbar

%% blend attenuation coefficient map based on localization info
xdata = squeeze(data.pose(1, end, :)) * 1e3; % robot base x
ydata = squeeze(data.pose(2, end, :)) * 1e3; % robot base y
xrange = [min(xdata), max(xdata)];
yrange = [min(ydata), max(ydata)];
clear xdata ydata

sec = grid; sec(isnan(sec)) = 0;

combined = sec(1:width, :);
x_fixed = mean(data.pose(1, end, 1:data_sizes(1) - 1)) * 1e3; % mm
y_fixed = mean(data.pose(2, end, 1:data_sizes(1) - 1)) * 1e3; % mm
for i = 2:length(data_sizes)
    % load segment
    prev = combined;
    curr = sec((i - 1) * width:i * width, :);
    % calculate offsets
    x_moving = mean(data.pose(1, end, sum(data_sizes(1:i - 1)) + 1:sum(data_sizes(1:i - 1)) + data_sizes(i) - 1)) * 1e3; % mm
    y_moving = mean(data.pose(2, end, sum(data_sizes(1:i - 1)) + 1:sum(data_sizes(1:i - 1)) + data_sizes(i) - 1)) * 1e3; % mm
    ovlp_hori = round(abs(x_fixed - x_moving) * (min(data_sizes) / diff(xrange)));
    ovlp_vert = round(abs(y_fixed - y_moving) * (width / 7.6));
    curr = imtranslate(curr, [-ovlp_hori, 0]);
    combined = [combined(1:end - ovlp_vert, :); curr];
    % mosaic overlapped region
    if ovlp_vert > 0
        w = rescale(1 - tanh(rescale(1:ovlp_vert) - 0.5)); % weighting function
        ovlp_sec = zeros(ovlp_vert, size(sec, 2), 'single');
        for r = 1:ovlp_vert
            ovlp_sec(r, :) = w(r) * prev(end - ovlp_vert + r, :) + (1 - w(r)) * curr(r, :);
        end
        combined(size(prev, 1) - ovlp_vert:size(prev, 1) - 1, :) = ovlp_sec;
    end
    x_fixed = x_moving;
    y_fixed = y_moving;
end
clear prev curr ovlp_sec sec i r x_fixed y_fixed x_moving y_moving

interp_step = 0.7;
[X_raw, Y_raw] = meshgrid(1:size(combined, 2), 1:size(combined, 1));
[X, Y] = meshgrid(1:interp_step:size(combined, 2), 1:interp_step:size(combined, 1));
combined = interp2(X_raw, Y_raw, combined, X, Y);
clear interp_step X_raw Y_raw X Y
figure('Position', [1920/4, 1080/4, 1200, 500]);
imagesc(xrange, yrange, combined); colormap gray;
% imagesc(combined); colormap gray;
xlabel('x [mm]'); ylabel('y [mm]'); colorbar
