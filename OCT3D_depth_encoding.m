%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: OCT3D_depth_encoding.m
% author: Xihan Ma
% description: extract first peak from each AScan & generate 2D depth map
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
isGenVid = false;
% load BScan & pose data
data2load = 28:33;
[data, data_sizes] = DataManagerOCT(data2load); 

%% extract first peak from AScan
probe = ProbeConfigOCT(); % get OCT probe configuration
enCalibTune = true;
T_flange_probe_new = CompCalibErr(probe.T_flange_probe);

pc_x = []; pc_y = []; pc_z = []; 
pc_x_int = []; pc_y_int = []; pc_z_int = [];        % intensity

dwnSmpInterv = 0.011;
imgFiltThresh = 47.5;
tic;
for item = 1:size(data.OCT,3)
    fprintf('process %dth image ... \n', item);
    BScan = data.OCT(:,:,item);
    
    % find highest peak in each AScan
    [maxAScan, row] = max(BScan);
    col = find(maxAScan > imgFiltThresh);
    row = row(col);
    
    if ~isempty(row) && ~isempty(col)
        xlocal = zeros(1,length(row));
        ylocal = -(probe.y/probe.width).*(col-1) + probe.y/2;
        zlocal = (probe.z/probe.height).*(row-1);

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
            T_base_flange = T/probe.T_flange_probe; % T*inv(probe.T_flange_probe)
            T = T_base_flange * T_flange_probe_new;
        end
        [xglobal, yglobal, zglobal] = TransformPoints(T,xlocal,ylocal,zlocal);
        % downsample
        if dwnSmpInterv > 0
            xglobal = downsample(xglobal,ceil(dwnSmpInterv*length(xglobal)));
            yglobal = downsample(yglobal,ceil(dwnSmpInterv*length(yglobal)));
            zglobal = downsample(zglobal,ceil(dwnSmpInterv*length(zglobal)));
            xint = downsample(xint,ceil(dwnSmpInterv*length(xint)));
            yint = downsample(yint,ceil(dwnSmpInterv*length(yint)));
            zint = downsample(zint,ceil(dwnSmpInterv*length(zint)));
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
pc_x = single(pc_x); pc_y = single(pc_y); pc_z = single(pc_z);
fprintf('processing data took %f sec \n', toc);

%% visualize 2D depth encoding
figure('Position',[500,120,1000,600])
scatter(pc_x.*1e3,pc_y.*1e3,repmat(4,1,length(pc_x)),pc_z.*1e3,'filled')
colormap(gca,'jet')
cb = colorbar('Ticks',linspace(min(pc_z.*1e3),max(pc_z.*1e3),5));
cb.Label.String = 'depth [mm]'; cb.Label.FontSize = 14;
xlabel('x [mm]'); ylabel('y [mm]');
axis equal tight 
% axis off

%% generate pointcloud
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
% axis off
% make background white
set(gcf,'color','w'); 
set(gca,'color','w','XColor',[0.15 0.15 0.15],'YColor',[0.15 0.15 0.15],'ZColor',[0.15 0.15 0.15]);
view(-90,0)     
% view(0,90)
% plot robot trajectory
hold on
position = reshape(data.pose(1:3,end,:),3,[]).*1e3;
position(:,position(1,:)==0&position(2,:)==0&position(1,:)==0) = [];
scatter3(position(1,:),position(2,:),position(3,:),repmat(5,1,length(position)),1:length(position))
cb = colorbar('Ticks',[1,length(position)]);
cb.Label.String = 'B-scan index'; cb.Label.FontSize = 14;
