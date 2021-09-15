%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: OCT_3D_pointcloud_display.m
% author: Xihan Ma
% description: display 3D pointcloud by extracting points from b-mode OCT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
isGenVid = false;
% load data
data2load = 17:19;
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
probe = probeConfigOCT();       % get OCT probe configuration

%% generate pointcloud
enCalibTune = true;
rpy_flange_probe = rotm2eul(probe.T_flange_probe(1:3,1:3));
rpy_flange_probe(1) = rpy_flange_probe(1) + 0;
rpy_flange_probe(2) = rpy_flange_probe(2) - 0;
rpy_flange_probe(3) = rpy_flange_probe(3) + 0.1;
R_flange_probe_new = eul2rotm(rpy_flange_probe);
T_flange_probe_new = probe.T_flange_probe;
T_flange_probe_new(1:3,1:3) = R_flange_probe_new;
T_flange_probe_new(1:3,end) = [0.0948;-0.0658;0.2543];

pc_x = []; pc_y = []; pc_z = []; 
pc_x_int = []; pc_y_int = []; pc_z_int = [];        % intensity

yrange = 7.5e-3; zrange = 6.68e-3;
height = size(data.OCT,1); width = size(data.OCT,2); frames = size(data.OCT,3);
dispPerc = 1.0;
imgFiltThresh = 50;
dwnSmpRate = 0.012;

tic;
for item = 1:round(dispPerc*frames)
    fprintf('process %dth image ... \n', item);
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
        if enCalibTune
            T_base_flange = T*inv(probe.T_flange_probe);
            T = T_base_flange * T_flange_probe_new;
        end
        
        [xglobal, yglobal, zglobal] = transformPoints(T,xlocal,ylocal,zlocal);
        % downsample
        if dwnSmpRate > 0
            xglobal = downsample(xglobal,ceil(dwnSmpRate*length(xglobal)));
            yglobal = downsample(yglobal,ceil(dwnSmpRate*length(yglobal)));
            zglobal = downsample(zglobal,ceil(dwnSmpRate*length(zglobal)));
            xint = downsample(xint,ceil(dwnSmpRate*length(xint)));
            yint = downsample(yint,ceil(dwnSmpRate*length(yint)));
            zint = downsample(zint,ceil(dwnSmpRate*length(zint)));
        end
        % append
        pc_x = cat(2, pc_x, xglobal);
        pc_y = cat(2, pc_y, yglobal);
        pc_z = cat(2, pc_z, zglobal);
        pc_x_int = cat(2, pc_x_int, xint);
        pc_y_int = cat(2, pc_y_int, yint);
        pc_z_int = cat(2, pc_z_int, zint);
    end 
end
pc_x = single(pc_x);
pc_y = single(pc_y);
pc_z = single(pc_z);
fprintf('processing data takes %f sec \n', toc);
clear BScan row col T xlocal ylocal zlocal xglobal yglobal zglobal

%% down sample 50% in overlapping area
overlap_ind = find((pc_y>1.221e-3 & pc_y<3.019e-3)|(pc_y>-4.762e-3 & pc_y<-2.981e-3));
pc_x_overlap = pc_x(overlap_ind); pc_x(overlap_ind) = [];
pc_y_overlap = pc_y(overlap_ind); pc_y(overlap_ind) = [];
pc_z_overlap = pc_z(overlap_ind); pc_z(overlap_ind) = [];
pc_x_overlap = downsample(pc_x_overlap,2);
pc_y_overlap = downsample(pc_y_overlap,2);
pc_z_overlap = downsample(pc_z_overlap,2);
pc_x = [pc_x, pc_x_overlap];
pc_y = [pc_y, pc_y_overlap];
pc_z = [pc_z, pc_z_overlap];
% downsample intensity values in overlapping area
pc_x_int_overlap = pc_x_int(overlap_ind); pc_x_int(overlap_ind) = [];
pc_y_int_overlap = pc_y_int(overlap_ind); pc_y_int(overlap_ind) = [];
pc_z_int_overlap = pc_z_int(overlap_ind); pc_z_int(overlap_ind) = [];
pc_x_int_overlap = downsample(pc_x_int_overlap,2);
pc_y_int_overlap = downsample(pc_y_int_overlap,2);
pc_z_int_overlap = downsample(pc_z_int_overlap,2);
pc_x_int = [pc_x_int, pc_x_int_overlap];
pc_y_int = [pc_y_int, pc_y_int_overlap];
pc_z_int = [pc_z_int, pc_z_int_overlap];

%% generate pointcloud type
pc_xyz = [pc_x.*1e3; pc_y.*1e3; pc_z.*1e3]';
pc_int = [pc_x_int; pc_y_int; pc_z_int]';       % intensity
pntcloud = pointCloud(pc_xyz,'Color',pc_int);
pntcloud = pcdenoise(pntcloud);                 % denoise
pntcloud = pcdownsample(pntcloud,'random',0.9);
% visualize pointcloud
figure('Position',[500,100,1200,600])
pcshow(pntcloud,'MarkerSize',4)
xlabel('x [mm]'); ylabel('y [mm]'); zlabel('z [mm]')
axis equal tight
% make background white
set(gcf,'color','w'); 
set(gca,'color','w','XColor',[0.15 0.15 0.15],'YColor',[0.15 0.15 0.15],'ZColor',[0.15 0.15 0.15]);
view(3);

%% 2D views
figure('Position',[500,100,1200,600])
subplot(2,2,1)
plot(pc_x.*1e3, pc_y.*1e3, '.k','MarkerSize', 0.02)
xlabel('x [mm]'); ylabel('y [mm]')
title('X-Y plane'); axis equal tight; grid on

subplot(2,2,2)
plot(pc_y.*1e3, pc_z.*1e3, '.k', 'MarkerSize', 0.02);
xlabel('y [mm]'); ylabel('z [mm]')
title('Y-Z plane'); axis equal tight; grid on;

subplot(2,2,3)
plot(pc_x.*1e3, pc_z.*1e3, '.k', 'MarkerSize', 0.02);
xlabel('x [mm]'); ylabel('z [mm]')
title('X-Z plane'); axis equal tight; grid on;

% snpshot = getframe;
% imagesc(snpshot.cdata);