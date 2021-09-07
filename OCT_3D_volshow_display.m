%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: OCT_3D_volshow_display.m
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
data_id = 1;
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
BScan = single(zeros(575,1124,n_kept));
nan_thresh = 0.68;
for item = n_discarded+2:n_discarded+n_kept+2
    BScan_curr = imread([OCT_data_folder, OCT_data_info(item).name]);
    BScan_curr = single(rgb2gray(BScan_curr));
    BScan_curr = normalize(BScan_curr,'range',[0 1]);
    % remove scale bar
%     b_mode_tmp(415:570,955:1090) = ~(b_mode_tmp(415:570,955:1090) > 250);
    % set background to nan
    BScan_curr(BScan_curr <= nan_thresh) = nan;
    BScan(:,:,item-n_discarded-1) = BScan_curr;
    fprintf('read %dth image ... \n', item);
end

%% transform images to common coordinate frame
res = 0.009;  % mm/pix 0.0044
FOV.x = 40;    % mm 
FOV.y = 7;    % mm
FOV.z = 3;    % mm
height = 575; width = 1124; % pix
T_offset = round(size(robot_poses,3)/4-n_kept)-1;    % include sample freq diff
T_init = robot_poses(:,:,4*(T_offset+1));            % initial position
b_mode_volume = NaN(round(FOV.x/res),round(FOV.y/res),round(FOV.z/res),'single');

% transform pixels
for item = 1:size(BScan,3)
%     normalize(BScan_curr, 'range', [0 1]);
    [row,col] = find(~isnan(BScan(:,:,item)));
    xlocal = zeros(length(row),1);
    ylocal = 5e-3/(width-1).*col - 5e-3/(width-1);
    zlocal = 2.56e-3/(height-1).*row -2.56e-3/(height-1);
    
    T = robot_poses(:,:,4*(T_offset+item));
    [xglobal, yglobal, zglobal] = transformPoints(T,xlocal,ylocal,zlocal);
    for i = 1:length(row)
        xgrid = ceil(abs(xglobal(i)-T_init(1,end))*1e3/res);
        ygrid = ceil((yglobal(i)-T_init(2,end))*1e3/res+ceil(FOV.y/res)/2);
        zgrid = ceil(abs(T_init(3,end)-zglobal(i))*1e3/res);
        xgrid(xgrid <= 0) = 1;
        ygrid(ygrid <= 0) = 1;
        zgrid(zgrid <= 0) = 1;
        b_mode_volume(xgrid, ygrid, zgrid) = BScan(row(i),col(i),item);
    end
    
    fprintf('transform %dth slice ... \n', item);
end

%%
volshow(uint8(b_mode_volume),'CameraUpVector',[0 1 0]);
