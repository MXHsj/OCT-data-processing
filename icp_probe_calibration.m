%% calibrate OCT probe

clc; clear; close all

% load data
tic;
data1 = DataManagerOCT(10);
data2 = DataManagerOCT(11);
fprintf('read data took %f sec\n',toc);

%% match pointcloud using icp
[pc1, ~] = genPntcloudFrmBScan(data1);
[pc2, ~] = genPntcloudFrmBScan(data2);

[R,P] = icp(pc2', pc1');
T_star = [R, P]; T_star = [T_star; 0, 0, 0, 1];

%% visualization
pntcloud1 = pointCloud(pc1);
pntcloud1 = pcdenoise(pntcloud1);     % denoise
pntcloud1 = pcdownsample(pntcloud1,'random',0.9);

pntcloud2 = pointCloud(pc2);
pntcloud2 = pcdenoise(pntcloud2);     % denoise
pntcloud2 = pcdownsample(pntcloud2,'random',0.9);

pcshow(pntcloud1)
hold on
pcshow(pntcloud2)
xlabel('x [mm]'); ylabel('y [mm]'); zlabel('z [mm]')
axis equal tight
% make background white
set(gcf,'color','w'); 
set(gca,'color','w','XColor',[0.15 0.15 0.15],'YColor',[0.15 0.15 0.15],'ZColor',[0.15 0.15 0.15]);