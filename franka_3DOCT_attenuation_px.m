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
probe = ProbeConfigOCT(); % get OCT probe configuration
enCalibTune = true;
T_flange_probe_new = CompCalibErr(probe.T_flange_probe);

pc_x = []; pc_y = []; ext_coeff_raw = [];

dwnSmpInterv = -1;
imgFiltThresh = 35;  % 48
fit_window = 100;
isVisualize = false;
tic;
for item = 1:size(data.OCT,3)  % 4200
    fprintf('process (%d/%d) image ... \n', item, size(data.OCT,3));
    BScan = data.OCT(:,:,item);
    % get extinction coefficient
    [ec, ~] = GetExtCoeff(BScan, imgFiltThresh, fit_window, isVisualize);
    % find highest peak in each AScan
    [maxAScan, row] = max(BScan(:,~isnan(ec)));
    col = find(maxAScan > imgFiltThresh);
    row = row(col);
    if ~isempty(row) && ~isempty(col)
        xlocal = zeros(1,length(row));
        ylocal = -(probe.y/probe.width).*(col-1) + probe.y/2;
        zlocal = (probe.z/probe.height).*(row-1);

        T = data.pose(:,:,item);
         % compensate for calibration err
        if enCalibTune
            T_base_flange = T/probe.T_flange_probe; % T*inv(probe.T_flange_probe)
            T = T_base_flange * T_flange_probe_new;
        end
        [xglobal, yglobal, ~] = TransformPoints(T,xlocal,ylocal,zlocal);
        % downsample
        if dwnSmpInterv > 0
            xglobal = downsample(xglobal,ceil(dwnSmpInterv*length(xglobal)));
            yglobal = downsample(yglobal,ceil(dwnSmpInterv*length(yglobal)));
            ec = downsample(ec, ceil(dwnSmpInterv*length(ec)));
        end
        % append
        if length(ec(~isnan(ec))) ~= length(xglobal)
            disp('size discrepency: number of extracted coefficient less than number of points')
            break
        end
        pc_x = cat(2, pc_x, xglobal);
        pc_y = cat(2, pc_y, yglobal);
        ext_coeff_raw = cat(2, ext_coeff_raw, ec(~isnan(ec)));
    end 
end
pc_x = single(pc_x); pc_y = single(pc_y);
ext_coeff_raw = single(ext_coeff_raw);
fprintf('processing data takes %f sec \n', toc);

%% limit extinction coeff value range
ext_coeff = ext_coeff_raw;
lowBound = 0; % median(scatter_coeff) - 1.0*std(scatter_coeff);
upBound = mean(ext_coeff) + 0.1*std(ext_coeff);
outlier_ind = find(ext_coeff < lowBound | ext_coeff > upBound);
ext_coeff(outlier_ind) = nan;

%% project pointcloud to 2D grid
tic
map = zeros(1024, 2000, 'single');
res_x = size(map,2)/(max(pc_x)-min(pc_x));
res_y = size(map,1)/(max(pc_y)-min(pc_y));
x_ind = round((pc_x - min(pc_x))*res_x); x_ind(x_ind == 0) = 1;
y_ind = round((pc_y - min(pc_y))*res_y); y_ind(y_ind == 0) = 1;
for i = 1:length(pc_x)
    map(y_ind(i), x_ind(i)) = ext_coeff(i);
%     fprintf('processing map(%d, %d) (%d/%d)\n',x_ind(i),y_ind(i),i,length(pc_x))
end
clear x_ind y_ind
toc

%% visualize 2D attenuation map (grid)
xrange = [min(pc_x), max(pc_x)];
yrange = [min(pc_y), max(pc_y)];
figure('Position',[1920/4,1080/4,1200,500])
map = flipud(map);
imagesc(xrange*1e3, yrange*1e3, map); colormap gray; axis equal tight
xlabel('x [mm]'); ylabel('y [mm]');
colorbar
