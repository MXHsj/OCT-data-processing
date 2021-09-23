%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: camera_view_scan_path.m
% author: Xihan Ma
% description: visualize OCT scan path from RGB-D camera view
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
% load BScan & pose data
data2load = 30:34;
[data, data_sizes] = DataManagerOCT(data2load); 

%% visualization
figure('Position',[500,100,640*1.5,480*1.5])
rgb = imread('../data/22-Sep-2021_color_img{exvivo}.png');
rgb = rgb + 48;    % increase brightness

% get color frame field of view
% tlx = 0.515; tly = 0.08; disty = 0.18;        % 16-09-2021 exvivo
tlx = 0.559; tly = 0.16; disty = 0.325;          % 22-09-2021 exvivo
xCorn = [ tlx; tlx-disty*(3/4) ].*1e3;   % x-coord of corners
yCorn = [ tly; tly-disty ].*1e3;        % y-coord of corners

imagesc(yCorn, xCorn, rgb)
xlabel('Y [mm] (w.r.t robot base)'); ylabel('X [mm] (w.r.t robot base)');
axis xy equal tight
% axis off
% draw scan trajectory
position = reshape(data.pose(1:3,end,:),3,[]).*1e3;
position(:,position(1,:)==0&position(2,:)==0&position(1,:)==0) = [];
hold on
scatter(position(2,:),position(1,:),repmat(2,1,length(position)),1:length(position))
cb = colorbar('Ticks',[1,length(position)]);
cb.Label.String = 'OCT image frame number'; cb.Label.FontSize = 12;