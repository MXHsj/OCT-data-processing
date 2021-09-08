%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: franka_OCT_bridge.m
% author: Xihan Ma
% description: communication between OCT and robot, OCT images are captured
% using matlab_OCT_bridge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
clc; clear; close all
rosshutdown

% ----------------- ROS network -----------------
setenv('ROS_MASTER_URI','http://130.215.219.126:11311') % ip of robot desktop
% [~, local_ip] = system('ipconfig');
setenv('ROS_IP','130.215.212.203')   % ip of this machine
rosinit

% ----------------- control flow -----------------
freq = 25;
rate = rateControl(freq);
isStartScan = false;                % robot start scanning flag

% ----------------- receive message from robot -----------------
OCT_clk_ctrl_sub = rossubscriber('OCT_clk_ctrl', 'std_msgs/Int16', @OCT_clk_ctrl_callback);
franka_pos_sub = rossubscriber('franka_state_custom', 'std_msgs/Float64MultiArray');
global OCT_clk_ctrl franka_pose
OCT_clk_ctrl = -1;
franka_pose = zeros(4,4);
% last_franka_pose = zeros(4,4);

% ----------------- send message to robot -----------------
OCT_img_pub = rospublisher('OCT_img_fb', 'std_msgs/Float64MultiArray');
OCT_img_msg = rosmessage(OCT_img_pub);
% height, in-plane slope, out-of-plane slope
height = 1024; width = 1024;
OCT_img_msg.Data = [height, 0.0, 0.0];
last_surf_height = 0;
threshold = 55;

%% ----------------- initialize OCT -----------------
[Dev, RawData, Data, Proc, Probe, ScanPattern] = LoadSpectralRadar();

%% main loop
% pre-allocation
BScan_bw = zeros(height,width,'logical');
surf_row_ind = zeros(1,width);
queue_size = 500;
BScan_queue = zeros(width,height,queue_size);
pose_queue = zeros(4,4,queue_size);
data_count = 1;
while true
    tic;
%     curr_time = rate.TotalElapsedTime;
    % ----------------- receive from robot ----------------
%     franka_pose_msg = receive(franka_pos_sub);
%     franka_pose = reshape([franka_pose_msg.Data],4,4)';

    if OCT_clk_ctrl == 1
        isStartScan = true;
        disp('robot start scanning')
    end
    if OCT_clk_ctrl == 0
        isStartScan = false;
        disp('robot finish scanning')
    end
    % -----------------------------------------------------
    
    % ----------------- get OCT image -----------------
    BScan = AcquireSingleBScan(Dev, RawData, Data, Proc);
    % convert to binary image
   
%     BScan_norm = normalize(BScan, 'range', [0 1]);
    BScan_bw(BScan(:,:) > threshold) = 1;
    BScan_bw(BScan(:,:) <= threshold) = 0;
    imagesc(BScan_bw)
    % find target surface
    surf_height = find(sum(BScan_bw,2)>10,1,'first');
    surf_height(isempty(surf_height)) = height;
    % find slope
    for i = 1:width
        if sum(BScan_bw(:,i))>1
            surf_row_ind(i) = find(BScan_bw(:,i) == 1,1,'first');
        else
            surf_row_ind(i) = nan;
        end
    end
    surf_row_ind_valid = height - surf_row_ind(~isnan(surf_row_ind));
    if length(surf_row_ind_valid) > 5
        p = polyfit(1:length(surf_row_ind_valid),surf_row_ind_valid,1);
    else
        p = [0, height];
    end
    % -------------------------------------------------
    
    % ----------------- record OCT & pose data ----------------
    if isStartScan
        BScan_queue(:,:,data_count) = BScan;
        pose_queue(:,:,data_count) = franka_pose;
        data_count = data_count + 1;
        if data_count >= queue_size
            break
        end
    end
    % ---------------------------------------------------------
    
    % ----------------- send to robot ----------------
    OCT_img_msg.Data(1) = 1-surf_height/height;       % surface height
    OCT_img_msg.Data(2) = p(1);                       % in-plane slope
%     obj_slope = (last_franka_pose(3,4) - last_surf_height*0.01) - ...
%                 (franka_pose(3,4) - surf_height*0.01);
%     traj_slope = last_franka_pose(3,4) - franka_pose(3,4);
%     fprintf('obj_slope: %f \t traj_slope: %f \n', obj_slope, traj_slope)
%     OCT_img_msg.Data(3) = obj_slope - traj_slope;   % out-of-plane slope
%     last_surf_height = surf_height;
%     last_franka_pose = franka_pose;
    % send message
    send(OCT_img_pub, OCT_img_msg)
    % ------------------------------------------------
    waitfor(rate);
    toc
end

%% finish
UnloadSpectralRadar(Dev, RawData, Data, Proc, Probe, ScanPattern);
clear Dev RawData Data Proc Probe ScanPattern
unloadlibrary SpectralRadar 

%% utilities
function OCT_clk_ctrl_callback(~,message)
global OCT_clk_ctrl
OCT_clk_ctrl = [message.Data];
end

% function franka_pos_callback(~,message)
% global franka_pose
% franka_pose = reshape([message.Data],4,4)';
% end
