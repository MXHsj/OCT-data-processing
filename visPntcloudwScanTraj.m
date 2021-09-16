%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: OCT_3D_pointcloud_display.m
% author: Xihan Ma
% description: display 3D pointcloud by extracting points from b-mode OCT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
isGenVid = false;
% load data
data2load = 20:22;
data.OCT = []; data.pose = []; data_size = [];
tic;
for id = data2load
    data_tmp = DataManagerOCT(id);
    data.OCT = cat(3,data.OCT,data_tmp.OCT);
    data.pose = cat(3,data.pose,data_tmp.pose);
    data_size = cat(1,data_size,size(data_tmp.OCT,3));
end
clear data_tmp id
fprintf('read data took %f sec\n',toc);

probe = probeConfigOCT();                       % get OCT probe configuration
load('generated/15-Sep-2021_pc{letters}.mat');  % load generated pointcloud

%% visualization
% show pointcloud
figure('Position',[500,100,1200,600])
pcshow(pntcloud,'MarkerSize',4)
% xlabel('x [mm]'); ylabel('y [mm]'); zlabel('z [mm]')
axis equal tight
view(-5,74)
% change background and axis color
set(gcf,'color','w');
% set(gca,'color','w','XColor',[0.15 0.15 0.15],'YColor',[0.15 0.15 0.15],'ZColor',[0.15 0.15 0.15]);
set(gca,'color','w','XColor',[1 1 1],'YColor',[1 1 1],'ZColor',[1 1 1]);    % supress axes
% plot robot trajectory
hold on
position = reshape(data.pose(1:3,end,:),3,[]).*1e3;
position(:,position(1,:)==0&position(2,:)==0&position(1,:)==0) = [];
scatter3(position(1,:),position(2,:),position(3,:),repmat(5,1,length(position)),1:length(position))
cb = colorbar('Ticks',[1,length(position)]);
cb.Label.String = 'B-scan index'; cb.Label.FontSize = 12;
