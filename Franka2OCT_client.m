%% test communication between OCT and robot
% dependencies: python3.8
clc; clear; close all
rosshutdown

% ----------------- configure ROS network -----------------
setenv('ROS_MASTER_URI','http://130.215.123.207:11311')      
[~, local_ip] = system('ipconfig');
setenv('ROS_IP','130.215.208.97')   % ip of this machine
rosinit

% ----------------- time stuff -----------------
freq = 20;
rate = rateControl(freq);

isStartRecord = false;              % OCT start recording flag
isStartScan = false;                % robot start scanning flag

startRecordTime = -inf;
startScanTime = -inf;
endRecordTime = -inf;
endScanTime = -inf;

% ----------------- detect mouse click -----------------
last_left = py.win32api.GetKeyState(0x01);  % initial mouse state
btnHoriMar = 25;                    % record button horizontal margin
btnVertMar = 50;                    % record button vertical margin

% ----------------- Take screen capture -----------------
left = 130; top = 494;
width = round(1048 * 0.4);   % half screen width
height = round(968 * 0.23);
robot = java.awt.Robot();
pos = [left top width height]; % [left top width height]
rect = java.awt.Rectangle(pos(1),pos(2),pos(3),pos(4));
winCap_rgb = zeros(height,width,3,'uint8');
winCap_bw = zeros(height,width,'logical');

% ----------------- receive message from robot -----------------
OCT_clk_ctrl_sub = rossubscriber('OCT_clk_ctrl', 'std_msgs/Int16', ...
    @OCT_clk_ctrl_callback);
franka_pos_sub = rossubscriber('franka_state_custom', ...
    'std_msgs/Float64MultiArray', @franka_pos_callback);
global OCT_clk_ctrl franka_pose
OCT_clk_ctrl = -1;
franka_pose = zeros(4,4);
% last_franka_pose = zeros(4,4);

% ----------------- send message to robot -----------------
OCT_img_pub = rospublisher('OCT_img_fb', 'std_msgs/Float64MultiArray');
OCT_img_msg = rosmessage(OCT_img_pub);
% height, in-plane slope, out-of-plane slope
OCT_img_msg.Data = [height, 0.0, 0.0];
last_surf_height = 0;
surf_row_ind = zeros(1,width);

totalTime = 100;
% OCT_gray_rec = nan(height,width,freq*totalTime);

while true
    curr_time = rate.TotalElapsedTime;
    % ----------------- receive from robot ----------------
%     franka_pose_msg = receive(franka_pos_sub);
%     franka_pose = reshape([franka_pose_msg.Data],4,4)';
    if OCT_clk_ctrl == 1 && startScanTime == -inf
        startScanTime = curr_time;
        isStartScan = true;
        disp('robot start scanning')
    end
    if OCT_clk_ctrl == 0 && endScanTime == -inf
        endScanTime = curr_time;
        isStartScan = false;
        disp('robot finish scanning')
    end
    % -----------------------------------------------------
    
    % ----------------- detect mouse click ----------------
    curr_left = py.win32api.GetKeyState(0x01);  % get mouse state
    if curr_left ~= last_left
        last_left = curr_left;
        if curr_left < 0
            disp('mouse clicked')
            cursor_pos_raw = py.win32api.GetCursorPos();
            cursor_pos = cellfun(@double,cell(cursor_pos_raw));
            if abs(cursor_pos(1)-168)<=btnHoriMar && ...
                    abs(cursor_pos(2)-109)<=btnVertMar
                if ~isStartRecord
                    isStartRecord = true;
                    disp('OCT start recording')
                    startRecordTime = curr_time;
                else
                    isStartRecord = false;
                    disp('OCT end recording')
                    endRecordTime = curr_time;
                end
            end
        else
            disp('mouse released')
        end
    end
    % -----------------------------------------------------
    
    % ----------------- get OCT image -----------------
    cap = robot.createScreenCapture(rect);
    % convert to an RGB image
    rgb = typecast(cap.getRGB(0,0,cap.getWidth, ...
        cap.getHeight,[],0,cap.getWidth),'uint8');
    winCap_rgb(:,:,1) = reshape(rgb(3:4:end),cap.getWidth,[])';
    winCap_rgb(:,:,2) = reshape(rgb(2:4:end),cap.getWidth,[])';
    winCap_rgb(:,:,3) = reshape(rgb(1:4:end),cap.getWidth,[])';
    % convert to binary image
    threshold = 200;
    winCap_gray = rgb2gray(winCap_rgb);
    winCap_bw(winCap_gray(:,:) > threshold) = 1;
    winCap_bw(winCap_gray(:,:) <= threshold) = 0;
    winCap_bw = medfilt2(winCap_bw,[3,20]);
    % find target surface
    surf_height = find(sum(winCap_bw,2)>10,1,'first');
    surf_height(isempty(surf_height)) = height;
    % find slope
    surf_row_ind = zeros(1,width);
    for i = 1:width
        if sum(winCap_bw(:,i))>1
            surf_row_ind(i) = find(winCap_bw(:,i) == 1,1,'first');
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
    %         row_marked(row_marked <= 0) = 1;
    %         row_marked(row_marked > height) = height;
    %         for i = 1:width
    %             winCap_marked(row_marked(i),i,1) = 0;
    %             winCap_marked(row_marked(i),i,2) = 255;
    %             winCap_marked(row_marked(i),i,3) = 0;
    %         end
    winCap_marked = winCap_rgb;
    winCap_marked(surf_height,:,1) = 0;
    winCap_marked(surf_height,:,2) = 255;
    winCap_marked(surf_height,:,3) = 0;
    imshow(winCap_marked)
    % -------------------------------------------------
    
    % ----------------- send to robot ----------------
    OCT_img_msg.Data(1) = 1-surf_height/height;       % surface height
    OCT_img_msg.Data(2) = p(1);                       % in-plane slope
%     obj_slope = (last_franka_pose(3,4) - last_surf_height*0.01) - ...
%                 (franka_pose(3,4) - surf_height*0.01);
%     traj_slope = last_franka_pose(3,4) - franka_pose(3,4);
%     fprintf('obj_slope: %f \t traj_slope: %f \n', obj_slope, traj_slope)
%     OCT_img_msg.Data(3) = obj_slope - traj_slope;     % out-of-plane slope
%     last_surf_height = surf_height;
%     last_franka_pose = franka_pose;
    % send message
    send(OCT_img_pub, OCT_img_msg)
    % ------------------------------------------------
    waitfor(rate);
end

function OCT_clk_ctrl_callback(~,message)
global OCT_clk_ctrl
OCT_clk_ctrl = [message.Data];
end

function franka_pos_callback(~,message)
global franka_pose
franka_pose = reshape([message.Data],4,4)';
end