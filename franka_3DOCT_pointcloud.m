%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: franka_3DOCT_pointcloud_display.m
% author: Xihan Ma
% description: display 3D pointcloud by extracting points from b-mode OCT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
addpath(genpath('utilities/'));

isGenVid = false;
% load BScan & pose data
data2load = 8:10;
[data, data_sizes] = DataManagerOCT(data2load);

%% generate pointcloud
probe = ProbeConfigOCT();           % get OCT probe configuration
enCalibTune = true;
T_flange_probe_new = CompCalibErr(probe.T_flange_probe);

pc_x = []; pc_y = []; pc_z = []; 
pc_x_int = []; pc_y_int = []; pc_z_int = [];        % intensity

imgFiltThresh = 55;
dwnSmpInterv = 0.012;
tic;
for item = 1:size(data.OCT,3)
    fprintf('process %dth image ... \n', item);
    BScan = data.OCT(:,:,item);
    [row,col] = find(BScan >= imgFiltThresh);
    if ~isempty(row) && ~isempty(col)
        xlocal = zeros(length(row),1);
        ylocal = -(probe.y/probe.width).*(col-1) + probe.y/2;
        zlocal = (probe.z/probe.height).*(row-1);

        xint = zeros(1,length(row),'uint8');
        yint = zeros(1,length(row),'uint8');
        zint = zeros(1,length(row),'uint8');
        for i = 1:length(row)
            xint(i) = BScan(row(i),col(i));
            yint(i) = BScan(row(i),col(i));
            zint(i) = BScan(row(i),col(i));
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
            xint = downsample(xint,ceil(dwnSmpInterv*length(xint)));
            yint = downsample(yint,ceil(dwnSmpInterv*length(yint)));
            zint = downsample(zint,ceil(dwnSmpInterv*length(zint)));
        end
        % append
        pc_x = cat(2, pc_x, xglobal);
        pc_y = cat(2, pc_y, yglobal);
        pc_z = cat(2, pc_z, zglobal);
        pc_x_int = cat(2, pc_x_int, xint);
        pc_y_int = cat(2, pc_y_int, yint);
        pc_z_int = cat(2, pc_z_int, zint);
    end 
end
pc_x = single(pc_x); pc_y = single(pc_y); pc_z = single(pc_z);
fprintf('processing data takes %f sec \n', toc);
% clear BScan row col T xlocal ylocal zlocal xglobal yglobal zglobal

%% down sample 50% in overlapping area
overlap_ind = find((pc_y>-3.59e-3 & pc_y<-1.69e-3)| ...
                   (pc_y>-9.92e-3 & pc_y<-8.13e-3)| ...
                   (pc_y>-15.68e-3 & pc_y<-13.67e-3)| ...
                   (pc_y>-21.80e-3 & pc_y<-19.33e-3)| ...
                   (pc_y>-27.59e-3 & pc_y<-25.62e-3));
pc_x_overlap = pc_x(overlap_ind); pc_x(overlap_ind) = [];
pc_y_overlap = pc_y(overlap_ind); pc_y(overlap_ind) = [];
pc_z_overlap = pc_z(overlap_ind); pc_z(overlap_ind) = [];
pc_x_overlap = downsample(pc_x_overlap,2);
pc_y_overlap = downsample(pc_y_overlap,2);
pc_z_overlap = downsample(pc_z_overlap,2);
pc_x = [pc_x, pc_x_overlap];
pc_y = [pc_y, pc_y_overlap];
pc_z = [pc_z, pc_z_overlap];
% downsample intensities
pc_x_int_overlap = pc_x_int(overlap_ind); pc_x_int(overlap_ind) = [];
pc_y_int_overlap = pc_y_int(overlap_ind); pc_y_int(overlap_ind) = [];
pc_z_int_overlap = pc_z_int(overlap_ind); pc_z_int(overlap_ind) = [];
pc_x_int_overlap = downsample(pc_x_int_overlap,2);
pc_y_int_overlap = downsample(pc_y_int_overlap,2);
pc_z_int_overlap = downsample(pc_z_int_overlap,2);
pc_x_int = [pc_x_int, pc_x_int_overlap];
pc_y_int = [pc_y_int, pc_y_int_overlap];
pc_z_int = [pc_z_int, pc_z_int_overlap];

%% generate pointcloud
pc_xyz = [pc_x.*1e3; pc_y.*1e3; pc_z.*1e3]';
pc_int = [pc_x_int; pc_y_int; pc_z_int]';       % intensity
pntcloud = pointCloud(pc_xyz,'Color',pc_int);
pntcloud = pcdenoise(pntcloud);                 % denoise
pntcloud = pcdownsample(pntcloud,'random',0.9);

%% 2D views
figure('Position',[500,100,1200,600])
subplot(2,2,1)
plot(pc_x.*1e3, pc_y.*1e3, '.','MarkerSize', 0.01)
xlabel('x [mm]'); ylabel('y [mm]')
title('X-Y plane'); axis equal tight; grid on

subplot(2,2,2)
plot(pc_y.*1e3, pc_z.*1e3, '.', 'MarkerSize', 0.01);
xlabel('y [mm]'); ylabel('z [mm]')
title('Y-Z plane'); axis equal tight; grid on;

subplot(2,2,3)
plot(pc_x.*1e3, pc_z.*1e3, '.', 'MarkerSize', 0.01);
xlabel('x [mm]'); ylabel('z [mm]')
title('X-Z plane'); axis equal tight; grid on;

%% visualize pointcloud
figure('Position',[500,100,1200,600])
pcshow(pntcloud,'MarkerSize',4)
xlabel('x [mm]'); ylabel('y [mm]'); zlabel('z [mm]')
axis equal tight 
axis off
% make background white
set(gcf,'color','w');
set(gca,'color','w','XColor',[0.15 0.15 0.15],'YColor',[0.15 0.15 0.15],'ZColor',[0.15 0.15 0.15]);
view(0,54)
% plot robot trajectory
hold on
position = reshape(data.pose(1:3,end,:),3,[]).*1e3;
position(:,position(1,:)==0&position(2,:)==0&position(1,:)==0) = [];
scatter3(position(1,:),position(2,:),position(3,:),repmat(5,1,length(position)),1:length(position))
cb = colorbar('Ticks',[1,length(position)]);
cb.Label.String = 'B-scan index'; cb.Label.FontSize = 14;
