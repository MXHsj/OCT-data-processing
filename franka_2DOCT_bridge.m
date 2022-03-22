%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: franka_2DOCT_bridge.m
% author: Xihan Ma
% description: communication between OCT and robot, OCT images are captured
% using matlab_OCT_bridge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
clc; clear; close all

%% ----------------- ROS network -----------------
rosshutdown
ros_master_uri = 'http://130.215.211.193:11311';
% [~, local_ip] = system('ipconfig');
local_ip = '130.215.192.168';
setenv('ROS_MASTER_URI',ros_master_uri) % ip of robot desktop
setenv('ROS_IP',local_ip)   % ip of this machine
rosinit

% ----------------- receive message from robot -----------------
OCT_scan_flag_sub = rossubscriber('OCT_scan_flag', 'std_msgs/Int8', @OCT_scan_flag_callback);
franka_pos_sub = rossubscriber('franka_state_custom', 'std_msgs/Float64MultiArray');
franka_pose = zeros(4,4);

% ----------------- send message to robot -----------------
OCT_response_pub = rospublisher('OCT_remote_response', 'std_msgs/Float64MultiArray');
OCT_response_msg = rosmessage(OCT_response_pub);
height = 1024; width = 1024;
isDataSaved = 0;
OCT_response_msg.Data = [height, 0.0, isDataSaved];

%% ----------------- initialize OCT -----------------
[Dev, RawData, Data, Proc, Probe, ScanPattern] = LoadSpectralRadar(false);

% ---------------------------------------------------
%% main loop
% constant
clear BScan_queue pose_queue
sample_name = 'breast';
freq = 20;      % max: 22; default: 20
rate = rateControl(freq);
global OCT_scan_flag
OCT_scan_flag = 0;
isStartScan = false;                % robot start scanning flag
queue_size = 2600;
% empirical values: WPI-UMASS->70; breast->58; kidney->52
intensity_thresh = 60; % threshold above which will be considered as tissue
rms_err_thresh = 0.035*height;
store_img_height = 700;
% counters
global frm_count scan_count
frm_count = 1; scan_count = 1;
% pre-allocation
% BScan_bw = zeros(height,width,'logical');
% surf_row_ind = zeros(1,width);
global BScan_queue pose_queue
BScan_queue = zeros(store_img_height,width,queue_size,'uint8');   % use uint8 to save space
pose_queue = zeros(4,4,queue_size,'double');

while true
    tic;    
    % ----------------- receive from robot ----------------
    franka_pose_msg = receive(franka_pos_sub);
    franka_pose = reshape([franka_pose_msg.Data],4,4)';
    if OCT_scan_flag == 1 && isStartScan == false
        isStartScan = true;
        isDataSaved = 0;
        disp('robot start scanning')
    end
    if OCT_scan_flag == 0 && isStartScan == true
        isStartScan = false;
        disp('robot stop scanning')
        save_data(sample_name);
        isDataSaved=1; frm_count=1; scan_count = scan_count+1;
        % break
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
%     plot(1:length(ind),ind,'.r','MarkerSize',1.0);
    % plot surface fitting
%     plot(1:size(BScan,2),B(1)+B(2)*(1:size(BScan,2)),'-c','LineWidth',1);
    % -------------------------------------------------
    
    % ----------------- record OCT & pose data ----------------
    if isStartScan
        BScan_queue(:,:,frm_count) = uint8(BScan(1:store_img_height,:));
        pose_queue(:,:,frm_count) = franka_pose;
        frm_count = frm_count + 1;
    end
    if frm_count >= queue_size
        disp('reached maximum storage')
        break
    end
    % ---------------------------------------------------------
    
    % ----------------- send to robot ----------------
    if ~isempty(surf_height)
        OCT_response_msg.Data(1) = 1-surf_height/height;    % surface height
    else
        OCT_response_msg.Data(1) = 0.0;
    end
    if ~isempty(B) && rms_err < rms_err_thresh
        OCT_response_msg.Data(2) = B(2);                % in-plane slope
    else
        OCT_response_msg.Data(2) = 0.0;
    end
    OCT_response_msg.Data(3) = isDataSaved;
    % send message
    send(OCT_response_pub, OCT_response_msg)
    % ------------------------------------------------
    waitfor(rate);
%     fprintf('loop time: %f, isStartScan: %d\n', toc, isStartScan);
end

%% finish
UnloadSpectralRadar(Dev, RawData, Data, Proc, Probe, ScanPattern);
clear Dev RawData Data Proc Probe ScanPattern
unloadlibrary SpectralRadar

%% utilities
function OCT_scan_flag_callback(~,message)
global OCT_scan_flag
OCT_scan_flag = [message.Data];
end

function save_data(name)
global BScan_queue pose_queue frm_count scan_count
tic;
BScan2save = BScan_queue(:,:,1:frm_count);
pose2save = pose_queue(:,:,1:frm_count);
save(['../data/',date,'_BScan{',name,num2str(scan_count),'}.mat'],'BScan2save')
save(['../data/',date,'_franka_pose{',name,num2str(scan_count),'}.mat'],'pose2save')
fprintf('scan: %d, frm: %d, save data took: %f sec\n', scan_count, frm_count, toc);
end
