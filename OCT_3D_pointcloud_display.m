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
OCT_data_folder = ['OCT_2D_scan/', oct_data{data_id}];
robot_pose_log = csvread(pose_data{data_id});
load(time_data{data_id});
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
zlocal_min = 0; zlocal_max = 2.56e-3;
ylocal_min = -2.5e-3; ylocal_max = 2.5e-3;
height = 575; width = 1124;
T_offset = round(length(robot_pose_log)/4-n_kept)-1;
threshold = 160;
% figure()
for item = n_discarded+2:n_discarded+n_kept+2 - 600
    img_rgb = imread([OCT_data_folder, OCT_data_info(item).name]);
    img_gray = rgb2gray(img_rgb);
    img_bw = imbinarize(img_gray);
%     img_bw = zeros(size(img_gray,1),size(img_gray,2),'logical');
%     img_bw(img_gray(:,:) > threshold) = 1;
%     img_bw(img_gray(:,:) <= threshold) = 0;
    img_bw = medfilt2(img_bw,[50,100]);
    [row,col] = find(img_bw == 1);
    xlocal_raw = zeros(length(row),1);
    ylocal_raw = 5e-3/(width-1).*col - 5e-3/(width-1);
    zlocal_raw = 2.56e-3/(height-1).*row -2.56e-3/(height-1);
    
    % downsample
    xlocal = resample(xlocal_raw,1,3);
    ylocal = resample(ylocal_raw,1,3);
    zlocal = resample(zlocal_raw,1,3);
    
    T = robot_poses(:,:,4*(T_offset+item-n_discarded-2));
    [xglobal, yglobal, zglobal] = transformPoints(T,xlocal,ylocal,zlocal);
    pc_x = [pc_x, xglobal];
    pc_y = [pc_y, yglobal];
    pc_z = [pc_z, zglobal];
%     plot3(xglobal,yglobal,zglobal,'.k')
%     hold on
%     pause(0.0001)
    fprintf('read %dth image ... \n', item);
end

fprintf('reading data takes %f sec \n', toc);

%% create pointcloud
pc_xyz = [pc_x; pc_y; pc_z]';
pntcloud = pointCloud(pc_xyz);
pc_color = ones(size(pntcloud.Location)).*[1 1 1];
pntcloud = pointCloud(pc_xyz,'Color',pc_color);
pntcloud = pcdenoise(pntcloud);     % denoise
pntcloud_DS = pcdownsample(pntcloud,'random',0.5);
pcshow(pntcloud_DS)
xlabel('x [m]')
ylabel('y [m]')
zlabel('z [m]')

%% random tests here
% x = rand(100,1)*4-2;
% y = rand(100,1)*4-2;
% z = x.*exp(-x.^2-y.^2);

% figure
% patch('XData', pc_x, 'YData', pc_y, 'ZData', pc_z)
% view(3)

k = boundary(pc_x',pc_y',pc_z',0.8);
trisurf(k,pc_x',pc_y',pc_z', 'Facecolor','cyan','FaceAlpha',0.8); 
axis equal;
% hold on
% plot3(x,y,z,'.r')