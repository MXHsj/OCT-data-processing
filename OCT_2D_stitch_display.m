%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: OCT_2D_stitch_display.m
% author: Xihan Ma
% description: display 2D b-mode OCT by stitching them in 3D
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
isGenVid = false;

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
data_id = 2;
OCT_data_folder = ['../data/OCT_2D_scan/', oct_data{data_id}];
pose_data_folder = '../data/';
time_data_folder = '../data/';
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

%% load all images and pre-process
b_mode = uint8(zeros(575,1124,numel(OCT_data_info)-2));
for item = 1:numel(OCT_data_info)-2
    b_mode_tmp = imread([OCT_data_folder, OCT_data_info(item+2).name]);
    b_mode_tmp = rgb2gray(b_mode_tmp);
    % remove scale bar
    b_mode_tmp(415:570,955:1090) = ~(b_mode_tmp(415:570,955:1090) > 250);
    b_mode(:,:,item) = b_mode_tmp;
    fprintf('read %dth image ... \n', item);
end

%% visualization
tic;
T_offset = round(length(robot_pose_log)/4-n_kept)-1;
ax_len = 0.0005;
h = figure('Name',oct_data{data_id}(1:end-1),'Position', [300 150 1124 575]);
if isGenVid
    aviObj = VideoWriter(oct_data{data_id}(1:end-1),'MPEG-4');
    aviObj.FrameRate = 20;
    aviObj.Quality = 100;
    open(aviObj);
end

for item = n_discarded+2:n_discarded+n_kept+2-650   % first two ele: ., .., 
%     b_mode = imread([OCT_data_folder, OCT_data_info(item).name]);
    T = robot_poses(:,:,4*(T_offset+item-n_discarded-2));
    xCorn = [T(1,4)*1000 T(1,4)*1000; T(1,4)*1000 T(1,4)*1000];                    % x-coord of corners
    yCorn = [T(2,4)*1000-2.5 T(2,4)*1000+2.5; T(2,4)*1000-2.5 T(2,4)*1000+2.5];    % y-coord of corners
    zCorn = [T(3,4)*1000 T(3,4)*1000; T(3,4)*1000-2.56 T(3,4)*1000-2.56];          % z-coord of corners
    surf(xCorn,yCorn,zCorn,'CData',b_mode(:,:,item), 'FaceColor','texturemap');    % render image
    view(-249, 8)
    fprintf('render %dth image ... \n', item);
    axis equal tight; hold on;
    xlabel('x [mm]'); ylabel('y [mm]'); zlabel('z [mm]');
    % draw coord-frame
    axX = plot3([T(1,4) T(1,4)+ax_len].*1000, [T(2,4) T(2,4)].*1000, [T(3,4) T(3,4)].*1000,'r','LineWidth',4);
    axY = plot3([T(1,4) T(1,4)].*1000, [T(2,4) T(2,4)+ax_len].*1000, [T(3,4) T(3,4)].*1000,'g','LineWidth',4);
    axZ = plot3([T(1,4) T(1,4)].*1000, [T(2,4) T(2,4)].*1000, [T(3,4) T(3,4)-ax_len].*1000,'b','LineWidth',4);
    if isGenVid
        writeVideo(aviObj, getframe(h));
    end
    pause(0.005)
    delete(axX); delete(axY); delete(axZ);
end
% draw coord-frame
axX = plot3([T(1,4) T(1,4)+ax_len].*1000, [T(2,4) T(2,4)].*1000, [T(3,4) T(3,4)].*1000,'r','LineWidth',4);
axY = plot3([T(1,4) T(1,4)].*1000, [T(2,4) T(2,4)+ax_len].*1000, [T(3,4) T(3,4)].*1000,'g','LineWidth',4);
axZ = plot3([T(1,4) T(1,4)].*1000, [T(2,4) T(2,4)].*1000, [T(3,4) T(3,4)-ax_len].*1000,'b','LineWidth',4);
colormap gray

if isGenVid
    close(aviObj);
end
fprintf('reading data takes %f sec \n', toc);