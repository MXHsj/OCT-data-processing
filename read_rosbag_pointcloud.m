%%
clc; clear; close all

bagfile = rosbag('../data/2021-09-27-22-56-08.bag');

pcloud_topic = select(bagfile,'Topic','camera/depth/color/points');
pcloud_msg = readMessages(pcloud_topic);
pcloud_msg = pcloud_msg{1};
xyz = readXYZ(pcloud_msg);
rgb = readRGB(pcloud_msg);

%% trim
[row2disc, ~] = find(xyz(:,end)>=0.292);
xyz(row2disc,:) = [];
rgb(row2disc,:) = [];

%% vis
pntcloud = pointCloud(-xyz,'Color',rgb);
% pntcloud = pcdenoise(pntcloud);                 % denoise
% pntcloud = pcdownsample(pntcloud,'random',0.9);
% visualize pointcloud
figure('Position',[500,100,1200,600])
pcshow(pntcloud,'MarkerSize',3)
xlabel('x [m]'); ylabel('y [m]'); zlabel('z [m]')
axis equal tight 
% axis off
% make background white
set(gcf,'color','w');
set(gca,'color','w','XColor',[0.15 0.15 0.15],'YColor',[0.15 0.15 0.15],'ZColor',[0.15 0.15 0.15]);
view(0,90)