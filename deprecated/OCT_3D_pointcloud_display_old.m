%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: OCT_3D_pointcloud_display_old.m
% author: Xihan Ma
% description: display 3D pointcloud by extracting points from b-mode OCT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
isGenVid = false;
% prepare data
oct_data = ...
{
    '2021-05-05_GP_phantom/', ...
    '2021-05-05_breast_phantom/', ...
};
pose_data = ...
{
    '2021-05-05_GP_phantom.csv', ...
    '2021-05-05_breast_phantom.csv', ...
};
time_data = ...
{
    '2021-05-05_GP_phantom.mat', ...
    '2021-05-05_breast_phantom.mat', ...
};

% read data
data_id = 1;
OCT_data_folder = ['../../data/OCT_2D_scan/', oct_data{data_id}];
pose_data_folder = '../../data/';
time_data_folder = '../../data/';
robot_pose_log = csvread([pose_data_folder, pose_data{data_id}]);
load([time_data_folder, time_data{data_id}]);
OCT_data_info = dir(OCT_data_folder);

robot_poses = zeros(4,4,size(robot_pose_log,1));
for i = 1:size(robot_pose_log,1)
    robot_poses(:,:,i) = reshape(robot_pose_log(i,:), 4, 4)';
end

startRecordTime = timings{1};
startScanTime = timings{2};
endScanTime = timings{3};
endRecordTime = timings{4};

avg_fps = 1/((endRecordTime - startRecordTime)/(numel(OCT_data_info)-2));
n_discarded = round((startScanTime - startRecordTime)*avg_fps);
n_kept = round((endScanTime - startScanTime)*avg_fps);

%% extract ROI
tic;
pc_x = []; pc_y = []; pc_z = []; 
pc_x_int = []; pc_y_int = []; pc_z_int = [];        % intensity
    
zlocal_min = 0; zlocal_max = 2.56e-3;
ylocal_min = -2.5e-3; ylocal_max = 2.5e-3;
height = 575; width = 1124;
T_offset = round(length(robot_pose_log)/4-n_kept)-1;
threshold = 255*0.7;

for item = n_discarded+2:n_discarded+n_kept+2
    BScan = imread([OCT_data_folder, OCT_data_info(item).name]);
    BScan_gray = uint8(rgb2gray(BScan));
    
    [row,col] = find(BScan_gray >= threshold);
    xlocal = zeros(length(row),1);
    ylocal = 5e-3/(width-1).*col - 5e-3/(width-1);
    zlocal = 2.56e-3/(height-1).*row -2.56e-3/(height-1);
    
    xint = zeros(1,length(row),'uint8');
    yint = zeros(1,length(row),'uint8');
    zint = zeros(1,length(row),'uint8');
    for i = 1:length(row)
        xint(i) = BScan_gray(row(i),col(i));
        yint(i) = BScan_gray(row(i),col(i));
        zint(i) = BScan_gray(row(i),col(i));
    end
    
    T = robot_poses(:,:,4*(T_offset+item-n_discarded-2));
    [xglobal, yglobal, zglobal] = transformPoints(T,xlocal,ylocal,zlocal);
    
    pc_x = [pc_x, xglobal];
    pc_y = [pc_y, yglobal];
    pc_z = [pc_z, zglobal];
    pc_x_int = [pc_x_int, xint];
    pc_y_int = [pc_y_int, yint];
    pc_z_int = [pc_z_int, zint];
    fprintf('read %dth image ... \n', item);
end
pc_x_int = normalize(single(pc_x_int),'range',[0 1]);
pc_y_int = normalize(single(pc_y_int),'range',[0 1]);
pc_z_int = normalize(single(pc_z_int),'range',[0 1]);

fprintf('reading data takes %f sec \n', toc);

%% create pointcloud
pc_xyz = single([pc_x; pc_y; pc_z]');
pc_int = [pc_x_int; pc_y_int; pc_z_int]';       % intensity
pntcloud = pointCloud(pc_xyz,'Color',pc_int);
pntcloud = pcdenoise(pntcloud);     % denoise
pntcloud_ds = pcdownsample(pntcloud,'random',0.5);
pcshow(pntcloud_ds)
xlabel('x [m]')
ylabel('y [m]')
zlabel('z [m]')