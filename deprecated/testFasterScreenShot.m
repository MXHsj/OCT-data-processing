%% get realtime screenshots of selected window (faster ver.)
clc; clear; close all

% Take screen capture
left = 130; top = 494;
width = round(1048 * 0.4);   % half screen width
height = round(968 * 0.23);
robot = java.awt.Robot();
pos = [left top width height]; % [left top width height]
rect = java.awt.Rectangle(pos(1),pos(2),pos(3),pos(4));
winCap_rgb = zeros(height,width,3,'uint8');
winCap_bw = zeros(height,width,'logical');

while 1
    cap = robot.createScreenCapture(rect);
    % convert to an RGB image
    rgb = typecast(cap.getRGB(0,0,cap.getWidth,cap.getHeight,[],0,cap.getWidth),'uint8');
    winCap_rgb(:,:,1) = reshape(rgb(3:4:end),cap.getWidth,[])';
    winCap_rgb(:,:,2) = reshape(rgb(2:4:end),cap.getWidth,[])';
    winCap_rgb(:,:,3) = reshape(rgb(1:4:end),cap.getWidth,[])';
    % convert to binary image
    winCap_gray = rgb2gray(winCap_rgb);
    winCap_bw(winCap_gray(:,:) > 180) = 1;
    winCap_bw(winCap_gray(:,:) <= 180) = 0;
    % find target surface
    row_start = find(sum(winCap_bw,2)>10,1,'first');
    row_start(isempty(row_start)) = height;
    % disp(row_start)
    winCap_marked = winCap_rgb;
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
    if length(surf_row_ind) > 5
        p = polyfit(1:length(surf_row_ind_valid),surf_row_ind_valid,1);
    else
        p = [0, height];
    end
    disp(p)
%     row_marked = ceil(polyval(p, 1:length(surf_row_ind_valid)));
%     if p(1) > 0
%         
%         row_marked = fliplr(row_marked);
%     else
%         row_marked = ceil(polyval(p, 1:length(surf_row_ind_valid)));   
%     end
%     row_marked(row_marked <= 0) = 1;
%     row_marked(row_marked > height) = height;
%     for i = 1:width
%         winCap_marked(row_marked(i),i,1) = 0;
%         winCap_marked(row_marked(i),i,2) = 255;
%         winCap_marked(row_marked(i),i,3) = 0;
%     end
    imshow(winCap_marked)
end