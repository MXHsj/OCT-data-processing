%% display 2D images in 3D space
clc; clear; close all

% read data
% OCT_data_folder = 'OCT_2D_scan/2021-05-05_breast_phantom/';
% robot_pose_log = csvread('2021-05-05_breast_phantom.csv');
% load('2021-05-05_breast_phantom.mat')
OCT_data_folder = 'OCT_2D_scan/2021-05-05_GP_phantom/';
robot_pose_log = csvread('2021-05-05_GP_phantom.csv');
load('2021-05-05_GP_phantom.mat')
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

%% display images
tic;
T_offset = round(length(robot_pose_log)/4-n_kept)-1;
figure
view(-150, 60)
% set(gca,'ZDir','reverse')
for item = n_discarded+2:n_discarded+n_kept+2
    img_rgb = imread([OCT_data_folder, OCT_data_info(item).name]);
    T = robot_poses(:,:,4*(T_offset+item-n_discarded-2));
    g = hgtransform('Matrix',makehgtform('translate',[T(3,4),T(2,4),T(1,4)]));
    image(g,img_rgb)
    fprintf('read %dth image ... \n', item);
    pause(0.001)
end
fprintf('reading data takes %f sec \n', toc);

% view(3)