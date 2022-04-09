%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: franka_3DOCT_volume.m
% author: Xihan Ma
% description: generate 3D volumetric data from 2D OCT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
addpath(genpath('utilities/'));

% load BScan & pose data
data2load = 8:10;
[data, data_sizes] = DataManagerOCT(data2load);
fprintf('total frames: %d\n',sum(data_sizes))

%% generate pointcloud
probe = ProbeConfigOCT();           % get OCT probe configuration
enCalibTune = true;
T_flange_probe_new = CompCalibErr(probe.T_flange_probe);
pc_x = []; pc_y = []; pc_z = []; 
pc_x_int = []; pc_y_int = []; pc_z_int = [];        % intensity

imgFiltThresh = 70;
dwnSmpInterv = -1; % 0.015;
tic;
for item = 1:size(data.OCT,3)
    fprintf('process %dth image ... \n', item);
    slice = data.OCT(:,:,item);
%     [row,col] = meshgrid(1:height,1:width); row = reshape(row,height*width,1); col = reshape(col,height*width,1);
    [row,col] = find(slice > imgFiltThresh);
    if ~isempty(row) && ~isempty(col)
        xlocal = zeros(length(row),1);
        ylocal = -(probe.y/probe.width).*(col-1) + probe.y/2;
        zlocal = (probe.z/probe.height).*(row-1);
        intensity = zeros(1,length(row),'uint8');
        for i = 1:length(row)
            intensity(i) = slice(row(i),col(i));
        end
        T = data.pose(:,:,item);
        % compensate for calibration err
        if enCalibTune
            T_base_flange = T/probe.T_flange_probe; % T*inv(probe.T_flange_probe)
            T = T_base_flange * T_flange_probe_new;
        end
        [xglobal, yglobal, zglobal] = TransformPoints(T,xlocal,ylocal,zlocal);
        % downsample
        if dwnSmpInterv > 0
            xglobal = downsample(xglobal,ceil(dwnSmpInterv*length(xglobal)));
            yglobal = downsample(yglobal,ceil(dwnSmpInterv*length(yglobal)));
            zglobal = downsample(zglobal,ceil(dwnSmpInterv*length(zglobal)));
            intensity = downsample(intensity,ceil(dwnSmpInterv*length(intensity)));
        end
        % append
        pc_x = cat(2, pc_x, xglobal);
        pc_y = cat(2, pc_y, yglobal);
        pc_z = cat(2, pc_z, zglobal);
        pc_x_int = cat(2, pc_x_int, intensity);
        pc_y_int = cat(2, pc_y_int, intensity);
        pc_z_int = cat(2, pc_z_int, intensity);
    end 
end
pc_x = single(pc_x); pc_y = single(pc_y); pc_z = single(pc_z);
fprintf('processing data takes %f sec \n', toc);

% generate pointcloud
pc_xyz = [pc_x.*1e3; pc_y.*1e3; pc_z.*1e3]';
pc_int = [pc_x_int; pc_y_int; pc_z_int]';       % intensity
pntcloud = pointCloud(pc_xyz,'Color',pc_int);
pntcloud = pcdenoise(pntcloud);                 % denoise
pntcloud = pcdownsample(pntcloud,'random',0.78);
% pcshow(pntcloud)

%% generate volume data from pointcloud
height = size(data.OCT(:,:,1),1);
width = size(data.OCT(:,:,1),2);
% volume = zeros(height,width*length(data_sizes),min(data_sizes),'uint8');
volume = zeros(500,500,120,'uint8');
res_x = floor(size(volume,3)/diff(pntcloud.XLimits));
res_y = floor(size(volume,2)/diff(pntcloud.YLimits));
res_z = floor(size(volume,1)/diff(pntcloud.ZLimits));
relative_x = pntcloud.Location(:,1)-pntcloud.XLimits(1);
relative_y = pntcloud.Location(:,2)-pntcloud.YLimits(1);
relative_z = pntcloud.Location(:,3)-pntcloud.ZLimits(1);
tic;
for i = 1:length(relative_x)
    x_ind = floor(relative_z(i)*res_z)+1;
    y_ind = floor(relative_y(i)*res_y)+1;
    z_ind = floor(relative_x(i)*res_x)+1;
    volume(x_ind, y_ind, z_ind) = pc_int(i,1);
    fprintf('processing (%d, %d, %d) (%d/%d)\n',x_ind,y_ind,z_ind,i,length(relative_x))
end
toc;
volshow(volume,'ScaleFactors',[1 1 20],'BackgroundColor',[1 1 1],'Lighting',false);
% volumeViewer(volume)
