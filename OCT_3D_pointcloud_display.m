%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: OCT_3D_pointcloud_display.m
% author: Xihan Ma
% description: display 3D pointcloud by extracting points from b-mode OCT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
isGenVid = false;
% load data
data2load = 12:13;
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

%% extract pointcloud
tic;
pc_x = []; pc_y = []; pc_z = []; 
pc_x_int = []; pc_y_int = []; pc_z_int = [];        % intensity

yrange = 5e-3; zrange = 6.68e-3;
height = size(data.OCT,1); width = size(data.OCT,2); frames = size(data.OCT,3);
dispPerc = 1.0;
imgFiltThresh = 50;
dwnSmpRate = 0.012;

for item = 1:round(dispPerc*frames)
    BScan = data.OCT(:,:,item);
    [row,col] = find(BScan >= imgFiltThresh);
    if ~isempty(row) && ~isempty(col)
        xlocal = zeros(length(row),1);
        ylocal = -(yrange/width).*(col-1) + yrange/2;
        zlocal = (zrange/height).*(row-1);

        xint = zeros(1,length(row),'uint8');
        yint = zeros(1,length(row),'uint8');
        zint = zeros(1,length(row),'uint8');
        for i = 1:length(row)
            xint(i) = BScan(row(i),col(i));
            yint(i) = BScan(row(i),col(i));
            zint(i) = BScan(row(i),col(i));
        end
        T = data.pose(:,:,item);        
        % compensate for calibration err
        if item > data_size(1)
%         T = T*[1.0, 0.0012, 0.0045, -0.5606*1e-3;
%                -0.0013, 0.9997, 0.0045, -2.2921*1e-3;
%                -0.0044, -0.0238, 0.9997, 1.9615*1e-3;
%                0.0, 0.0, 0.0, 1.0];
            T = T * ...
               [1.0000    0.0013   -0.0014    0.0900*1e-3;  % 0.1713
               -0.0014    0.9973   -0.0739   -1.3164*1e-3;  % 9.7064
                0.0013    0.0739    0.9973   -0.2411*1e-3;
                     0         0         0    1.0000];
        end
           
        [xglobal, yglobal, zglobal] = transformPoints(T,xlocal,ylocal,zlocal);
        % downsample
        xglobal = downsample(xglobal,ceil(dwnSmpRate*length(xglobal)));
        yglobal = downsample(yglobal,ceil(dwnSmpRate*length(yglobal)));
        zglobal = downsample(zglobal,ceil(dwnSmpRate*length(zglobal)));
        xint = downsample(xint,ceil(dwnSmpRate*length(xint)));
        yint = downsample(yint,ceil(dwnSmpRate*length(yint)));
        zint = downsample(zint,ceil(dwnSmpRate*length(zint)));
        % append
        pc_x = cat(2, pc_x, xglobal);
        pc_y = cat(2, pc_y, yglobal);
        pc_z = cat(2, pc_z, zglobal);
        pc_x_int = cat(2, pc_x_int, xint);
        pc_y_int = cat(2, pc_y_int, yint);
        pc_z_int = cat(2, pc_z_int, zint);
    end
    fprintf('read %dth image ... \n', item);
end
pc_x = single(pc_x);
pc_y = single(pc_y);
pc_z = single(pc_z);
fprintf('processing data takes %f sec \n', toc);
clear BScan row col T xlocal ylocal zlocal xglobal yglobal zglobal

%% create pointcloud
pc_xyz = [pc_x.*1e3; pc_y.*1e3; pc_z.*1e3]';
pc_int = [pc_x_int; pc_y_int; pc_z_int]';       % intensity
pntcloud = pointCloud(pc_xyz,'Color',pc_int);
pntcloud = pcdenoise(pntcloud);     % denoise
pntcloud = pcdownsample(pntcloud,'random',0.9);
pcshow(pntcloud,'MarkerSize',4)
xlabel('x [mm]'); ylabel('y [mm]'); zlabel('z [mm]')
axis equal tight
% make background white
set(gcf,'color','w'); 
set(gca,'color','w','XColor',[0.15 0.15 0.15],'YColor',[0.15 0.15 0.15],'ZColor',[0.15 0.15 0.15]);


%% top view
figure
plot(pc_x.*1e3, pc_y.*1e3, '.k')
axis equal tight
grid on
xlabel('x [mm]'); ylabel('y [mm]')
title('top view')
% convert top view to image
% snpshot = getframe;
% imagesc(snpshot.cdata);