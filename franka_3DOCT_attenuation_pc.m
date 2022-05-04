%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: franka_3DOCT_attenuation_pc.m
% author: Xihan Ma
% description: get extinction coefficient from A-scans & generate 2D map
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
addpath(genpath('utilities/'));

% load BScan & pose data
data2load = 44:47;
[data, data_sizes] = FrankaOCTDataManager(data2load); 

%% extract extinction coefficient
probe = ProbeConfigOCT(); % get OCT probe configuration
enCalibTune = true;
T_flange_probe_new = CompCalibErr(probe.T_flange_probe);

pc_x = []; pc_y = []; 
ext_coeff = []; % single scattering model

dwnSmpInterv = 0.00;
imgFiltThresh = 40;  % 48
fit_window = 150;
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
        ext_coeff = cat(2, ext_coeff, ec(~isnan(ec)));
    end 
end
pc_x = single(pc_x); pc_y = single(pc_y);
ext_coeff = single(ext_coeff);
fprintf('processing data takes %f sec \n', toc);

%% crop scan area
x_preserve = [508, 550]; y_preserve = [-28, -7];       % [mm] area to preserve
x2remove = pc_x.*1e3 < x_preserve(1) | pc_x.*1e3 > x_preserve(end);
y2remove = pc_y.*1e3 < y_preserve(1) | pc_y.*1e3 > y_preserve(end);
pc_x(x2remove|y2remove) = [];
pc_y(x2remove|y2remove) = [];
ext_coeff(x2remove|y2remove) = [];

%% limit extinction coeff value range
lowBound = 0; % median(scatter_coeff) - 1.0*std(scatter_coeff);
upBound = mean(ext_coeff) + 0.15*std(ext_coeff);
outlier_ind = find(ext_coeff < lowBound | ext_coeff > upBound);
ext_coeff(outlier_ind) = nan;

%% visualize 2D extinction coefficient map
figure('Position',[500,120,1000,600])
scatter(pc_x*1e3,pc_y*1e3,ones(1,length(pc_x)),ext_coeff*1.4,'filled')
colormap(gca,'parula') % parula jet gray
cb = colorbar('Ticks',linspace(min(ext_coeff),max(ext_coeff),5));
cb.Label.String = 'extinction coefficient [mm^{-1}]'; cb.Label.FontSize = 14;
xlim([min(pc_x*1e3),max(pc_x*1e3)]);
ylim([min(pc_y*1e3),max(pc_y*1e3)]);
xlabel('x [mm]'); ylabel('y [mm]');
axis equal tight
% axis off
clim = caxis;
caxis([clim(1) 1.02*clim(2)]);

%% project pcd to occupancy grid
map = zeros(1024, 2000, 'single');
res_x = size(map,2)/(max(pc_x)-min(pc_x));
res_y = size(map,1)/(max(pc_y)-min(pc_y));
tic
for i = 1:length(pc_x)
    x_ind = round(pc_x(i)*res_x - min(pc_x)*res_x) + 1;
    y_ind = round(pc_y(i)*res_y - min(pc_y)*res_y) + 1;
    map(y_ind, x_ind) = ext_coeff(i);
%     fprintf('processing map(%d, %d) (%d/%d)\n',x_ind,y_ind,i,length(ext_coeff))
end
toc
map = flipud(map);
figure('Position',[500,120,1000,600])
imagesc(map)
