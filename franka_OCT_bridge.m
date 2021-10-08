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
% [~, local_ip] = system('ipconfig');
setenv('ROS_MASTER_URI','http://130.215.121.229:11311') % ip of robot desktop
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
freq = 20;      % max: 22; default: 20
rate = rateControl(freq);
OCT_clk_ctrl = 0;
isStartScan = false;                % robot start scanning flag
queue_size = 2800;
intensity_thresh = 56;
rms_err_thresh = 0.035*height;
store_img_height = 700;
data_count = 1;
% pre-allocation
BScan_bw = zeros(height,width,'logical');
surf_row_ind = zeros(1,width);
BScan_queue = zeros(store_img_height,width,queue_size,'uint8');   % use uint8 to save space
pose_queue = zeros(4,4,queue_size,'double');

while true
    tic;    
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
    % find surface
    [val,ind] = max(BScan);
    ind(val < intensity_thresh) = nan;
    surf_height = min(ind(~isnan(ind))); % top-most tissue
    % fit line to surface using A = xB
    xx = (1:length(ind))'; xx(isnan(ind)) = [];
    x = [ones(length(ind(~isnan(ind))),1), xx];
    B = x\(ind(~isnan(ind))');
    rms_err = rms((ind(~isnan(ind))') - x*B);
    
    imagesc(BScan);
    % plot surface contour
%     plot(1:length(ind),ind,'.r','LineWidth',1);
    % plot surface fitting
%     plot(1:size(BScan,2),B(1)+B(2)*(1:size(BScan,2)),'-c','LineWidth',1);
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
    if ~isempty(surf_height)
        OCT_img_msg.Data(1) = 1-surf_height/height;    % surface height
    else
        OCT_img_msg.Data(1) = 0.0;
    end
    if ~isempty(B) && rms_err < rms_err_thresh
        OCT_img_msg.Data(2) = B(2);                % in-plane slope
    else
        OCT_img_msg.Data(2) = 0.0;
    end
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
tic;
BScan2save = BScan_queue(:,:,1:data_count);
pose2save = pose_queue(:,:,1:data_count);
save(['../data/',date,'_BScan{breast7}.mat'],'BScan2save')
save(['../data/',date,'_franka_pose{breast7}.mat'],'pose2save')
fprintf('save data took: %f sec\n', toc);

%% finish
UnloadSpectralRadar(Dev, RawData, Data, Proc, Probe, ScanPattern);
clear Dev RawData Data Proc Probe ScanPattern
unloadlibrary SpectralRadar

%% utilities
function OCT_clk_ctrl_callback(~,message)
global OCT_clk_ctrl
OCT_clk_ctrl = [message.Data];
end