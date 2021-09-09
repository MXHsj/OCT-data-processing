%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: OCT_3D_pointcloud_display.m
% author: Xihan Ma
% description: display 3D pointcloud by extracting points from b-mode OCT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
isGenVid = false;
% prepare data
oct_data = ...
{
    '08-Sep-2021_BScan.mat', ...
    '08-Sep-2021_BScan{breadboard}.mat', ...
};
pose_data = ...
{
    '08-Sep-2021_franka_pose.mat', ...
    '08-Sep-2021_franka_pose{breadboard}.mat', ...
};

% read data
data_id = 2;
data_folder = '../data/';
load([data_folder,oct_data{data_id}]);
load([data_folder,pose_data{data_id}]);

%% extract ROI
tic;
pc_x = []; pc_y = []; pc_z = []; 
pc_x_int = []; pc_y_int = []; pc_z_int = [];        % intensity
    
% zlocal_min = 0; zlocal_max = 2.56e-3;
% ylocal_min = -2.5e-3; ylocal_max = 2.5e-3;
yrange = 5e-3; zrange = 10e-3;
height = size(BScan2save,1); width = size(BScan2save,2);
threshold = 55;

for item = 1:size(BScan2save,3)
    BScan = BScan2save(:,:,item);
%     BScan = RawBScanFilter(BScan);
    
    [row,col] = find(BScan >= threshold);
    xlocal = zeros(length(row),1);
    ylocal = yrange/width.*col - yrange/width;
    zlocal = yrange/height.*row - zrange/height;
    
    xint = zeros(1,length(row),'uint8');
    yint = zeros(1,length(row),'uint8');
    zint = zeros(1,length(row),'uint8');
    for i = 1:length(row)
        xint(i) = BScan(row(i),col(i));
        yint(i) = BScan(row(i),col(i));
        zint(i) = BScan(row(i),col(i));
    end
    T = pose2save(:,:,item);
    [xglobal, yglobal, zglobal] = transformPoints(T,xlocal,ylocal,zlocal);
    
    % downsample
    xglobal = downsample(xglobal,10);
    yglobal = downsample(yglobal,10);
    zglobal = downsample(zglobal,10);
    xint = downsample(xint,10);
    yint = downsample(yint,10);
    zint = downsample(zint,10);
    
    % append
    pc_x = [pc_x, xglobal];
    pc_y = [pc_y, yglobal];
    pc_z = [pc_z, zglobal];
    pc_x_int = [pc_x_int, xint];
    pc_y_int = [pc_y_int, yint];
    pc_z_int = [pc_z_int, zint];
    fprintf('read %dth image ... \n', item);
end
pc_x = single(pc_x);
pc_y = single(pc_y);
pc_z = single(pc_z);
pc_x_int = normalize(single(pc_x_int),'range',[0 1]);
pc_y_int = normalize(single(pc_y_int),'range',[0 1]);
pc_z_int = normalize(single(pc_z_int),'range',[0 1]);

fprintf('processing data takes %f sec \n', toc);

%% create pointcloud
pc_xyz = [pc_x; pc_y; pc_z]';
pc_int = [pc_x_int; pc_y_int; pc_z_int]';       % intensity
pntcloud = pointCloud(pc_xyz,'Color',pc_int);
pntcloud = pcdenoise(pntcloud);     % denoise
pntcloud_ds = pcdownsample(pntcloud,'random',0.5);
pcshow(pntcloud_ds)
xlabel('x [m]')
ylabel('y [m]')
zlabel('z [m]')