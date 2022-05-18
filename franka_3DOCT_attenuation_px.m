%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: franka_3DOCT_attenuation_px.m
% author: Xihan Ma
% description: get extinction coefficient from A-scans & generate 2D map
% using 2D grid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
addpath(genpath('utilities/'));

% load BScan & pose data
data2load = 51:54;
[data, data_sizes] = FrankaOCTDataManager(data2load);

%% extract extinction coefficient

% ========== parameters ==========
probe = ProbeConfigOCT(); % get OCT probe configuration
enCalibTune = true; % if compensate for calibration error
T_flange_probe_new = CompCalibErr(probe.T_flange_probe);
WIDTH_BEGIN = 1;
WIDTH = size(data.OCT(:, :, 1), 2) - (WIDTH_BEGIN - 1) - 0;
FRM_NUM = size(data.OCT, 3);
assert(WIDTH > 0, 'frame wdith less than 0');
imgFiltThresh = 50; % 48
fit_window = 110;
isVisualize = false;
% ================================

% pre-allocate point coordinates
pc_x = zeros(1, WIDTH * FRM_NUM, 'single');
pc_y = zeros(1, WIDTH * FRM_NUM, 'single');
ext_coeff_raw = zeros(1, WIDTH * FRM_NUM, 'single');

% calculate pixel local coordinates in one frame
col = WIDTH_BEGIN:WIDTH_BEGIN + WIDTH - 1;
row = ones(1, WIDTH);
xlocal = zeros(1, length(col));
ylocal =- (probe.y / probe.width) .* (col - 1) + probe.y / 2;
zlocal = (probe.z / probe.height) .* (row - 1);

tic;

for frm = 1:FRM_NUM % 4200
    fprintf('process (%d/%d) image ... \n', frm, size(data.OCT, 3));
    BScan = data.OCT(:, :, frm);
    % get extinction coefficient
    [ec, ~] = GetExtCoeff(BScan, imgFiltThresh, fit_window, isVisualize);
    T = data.pose(:, :, frm);
    % compensate for calibration err
    if enCalibTune
        T_base_flange = T / probe.T_flange_probe; % T*inv(probe.T_flange_probe)
        T = T_base_flange * T_flange_probe_new;
    end

    if abs(det(T) - 1.0) > 1e-3
        warning('frm %d does not have a valid transformation', frm)
        continue
    end

    [xglobal, yglobal, ~] = TransformPoints(T, xlocal, ylocal, zlocal);
    % store coordinates
    pc_x((frm - 1) * WIDTH + 1:frm * WIDTH) = xglobal * 1e3; % mm
    pc_y((frm - 1) * WIDTH + 1:frm * WIDTH) = yglobal * 1e3;
    ext_coeff_raw((frm - 1) * WIDTH + 1:frm * WIDTH) = ec;
end

valid_ind = find(pc_x == 0 & pc_y == 0, 1);
pc_x(valid_ind:end) = [];
pc_y(valid_ind:end) = [];
ext_coeff_raw(valid_ind:end) = [];

fprintf('processing data takes %f sec \n', toc);
clear xlocal ylocal zlocal xglobal yglobal zglobal
clear ec row col BScan probe

%% project pointcloud to 2D grid
% limit extinction coeff value range
ext_coeff = ext_coeff_raw;
lowBound = 0;
upBound = mean(ext_coeff) + 1.0 * std(ext_coeff);
outlier_ind = find(ext_coeff < lowBound | ext_coeff > upBound);
ext_coeff(outlier_ind) = nan;

tic;
scale = 0.7;
GRID_HEIGHT = round(WIDTH * length(data_sizes) * scale);
GRID_WIDTH = round(min(data_sizes) * scale);
map_raw = zeros(GRID_HEIGHT, GRID_WIDTH, 'single');

res_ele = GRID_WIDTH / (max(pc_x) - min(pc_x));
res_lat = GRID_HEIGHT / (max(pc_y) - min(pc_y));
ind_ele = round((pc_x - min(pc_x)) * res_ele);
ind_lat = round((pc_y - min(pc_y)) * res_lat);
ind_ele(ind_ele == 0) = 1;
ind_lat(ind_lat == 0) = 1;

for i = 1:length(pc_x)
    map_raw(ind_lat(i), ind_ele(i)) = ext_coeff(i);
end

% clear ind_ele ind_lat
fprintf('generate extinction coeff map took %f sec \n', toc);

%% visualize 2D attenuation map (grid)
% interpolation
interp_step = 0.5;
[X_raw, Y_raw] = meshgrid(single(1:GRID_WIDTH), single(1:GRID_HEIGHT));
[X, Y] = meshgrid(single(1:interp_step:GRID_WIDTH), single(1:interp_step:GRID_HEIGHT));
map = interp2(X_raw, Y_raw, single(map_raw), X, Y);
fprintf('post processing took %f sec \n', toc);

xrange = [min(pc_x), max(pc_x)];
yrange = [min(pc_y), max(pc_y)];
figure('Position', [1920/4, 1080/4, 1200, 500])
% map = flipud(map);
imagesc(xrange, yrange, map, [0 1.5]); colormap gray; axis tight
xlabel('x [mm]'); ylabel('y [mm]');
colorbar
