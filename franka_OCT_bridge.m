%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: franka_OCT_bridge.m
% author: Xihan Ma
% description: communication between OCT and robot, OCT images are captured
% using matlab_OCT_bridge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
clc; clear; close all

%% ----------------- ROS network -----------------
rosshutdown
setenv('ROS_MASTER_URI','http://130.215.223.132:11311') % ip of robot desktop
% [~, local_ip] = system('ipconfig');
setenv('ROS_IP','130.215.192.178')   % ip of this machine
rosinit

% ----------------- receive message from robot -----------------
OCT_clk_ctrl_sub = rossubscriber('OCT_clk_ctrl', 'std_msgs/Int8', @OCT_clk_ctrl_callback);
franka_pos_sub = rossubscriber('franka_state_custom', 'std_msgs/Float64MultiArray');
global OCT_clk_ctrl
franka_pose = zeros(4,4);
% last_franka_pose = zeros(4,4);

% ----------------- send message to robot -----------------
OCT_img_pub = rospublisher('OCT_img_fb', 'std_msgs/Float64MultiArray');
OCT_img_msg = rosmessage(OCT_img_pub);
% height, in-plane slope, out-of-plane slope
height = 1024; width = 1024;
OCT_img_msg.Data = [height, 0.0, 0.0];
last_surf_height = 0;

%% ----------------- initialize OCT -----------------
[Dev, RawData, Data, Proc, Probe, ScanPattern] = LoadSpectralRadar();

% ---------------------------------------------------
%% main loop
% constant
freq = 22;
rate = rateControl(freq);
OCT_clk_ctrl = 0;
isStartScan = false;                % robot start scanning flag
queue_size = 3200;
store_img_height = 700;
threshold = 56;
data_count = 1;
% pre-allocation
BScan_bw = zeros(height,width,'logical');
surf_row_ind = zeros(1,width);
BScan_queue = zeros(store_img_height,width,queue_size,'uint8');   % use uint8 to save space
pose_queue = zeros(4,4,queue_size,'double');

while true
    tic;    
%     curr_time = rate.TotalElapsedTime;
    % ----------------- receive from robot ----------------
    franka_pose_msg = receive(franka_pos_sub);
    franka_pose = reshape([franka_pose_msg.Data],4,4)';

    if OCT_clk_ctrl == 1 && isStartScan == false
        isStartScan = true;
        disp('robot start scanning')
    end
    if OCT_clk_ctrl == 0 && isStartScan == true
        isStartScan = false;
        disp('robot stop scanning')
        break
    end
    % -----------------------------------------------------
    
    % ----------------- get OCT image -----------------
    BScan = AcquireSingleBScan(Dev, RawData, Data, Proc);
    % convert to binary image
    BScan_bw(BScan(:,:) > threshold) = 1;
    BScan_bw(BScan(:,:) <= threshold) = 0;
    imagesc(BScan_bw)
    % find target surface
    surf_height = find(sum(BScan_bw,2) > 5, 1, 'first');
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
        BScan_queue(:,:,data_count) = uint8(BScan(1:store_img_height,:));
        pose_queue(:,:,data_count) = franka_pose;
        if data_count >= queue_size
            disp('reached maximum storage')
            break
        end
        data_count = data_count + 1;
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
    fprintf('loop time: %f, isStartScan: %d\n', toc, isStartScan);
end

%% save data
BScan2save = BScan_queue(:,:,1:data_count);
pose2save = pose_queue(:,:,1:data_count);
save(['../data/',date,'_BScan{exvivo5-1}.mat'],'BScan2save')
save(['../data/',date,'_franka_pose{exvivo5-1}.mat'],'pose2save')

%% finish
UnloadSpectralRadar(Dev, RawData, Data, Proc, Probe, ScanPattern);
clear Dev RawData Data Proc Probe ScanPattern
unloadlibrary SpectralRadar

%% utilities
function OCT_clk_ctrl_callback(~,message)
global OCT_clk_ctrl
OCT_clk_ctrl = [message.Data];
end