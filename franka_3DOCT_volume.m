%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: franka_3DOCT_volume.m
% author: Xihan Ma
% description: generate 3D volumetric data from 2D OCT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
addpath(genpath('utilities/'));

% load BScan & pose data
data2load = 3;
[data, data_sizes] = FrankaOCTDataManager(data2load);
fprintf('total frames: %d\n',sum(data_sizes))

%% generate pointcloud
% TODO: implement batch based processing
MAX_BATCH_SIZE = 500;

% ========== parameters ==========
probe = ProbeConfigOCT();   % get OCT probe configuration
enCalibTune = false;         % if compensate for calibration error
T_flange_probe_new = CompCalibErr(probe.T_flange_probe);
HEIGHT_BEGIN = 200;
WIDTH_BEGIN = 1;
HEIGHT = size(data.OCT(:,:,1),1)-(HEIGHT_BEGIN-1) - 200;
WIDTH = size(data.OCT(:,:,1),2)-(WIDTH_BEGIN-1) - 0;
FRM_NUM = size(data.OCT,3);
assert(HEIGHT > 0,'frame height less than 0'); 
assert(WIDTH > 0,'frame wdith less than 0');
% ================================

% pre-allocate point coordinates
pc_x = zeros(1,HEIGHT*WIDTH*FRM_NUM,'single'); 
pc_y = zeros(1,HEIGHT*WIDTH*FRM_NUM,'single');
pc_z = zeros(1,HEIGHT*WIDTH*FRM_NUM,'single'); 
pc_int = zeros(1,HEIGHT*WIDTH*FRM_NUM,'single'); % intensity

% calculate pixel local coordinates
[row,col] = meshgrid(HEIGHT_BEGIN : HEIGHT_BEGIN+HEIGHT-1, ...
                     WIDTH_BEGIN : WIDTH_BEGIN+WIDTH-1);
row = reshape(row,HEIGHT*WIDTH,1);
col = reshape(col,HEIGHT*WIDTH,1);
xlocal = zeros(length(row),1);
ylocal = -(probe.y/probe.width).*(col-1) + probe.y/2;
zlocal = (probe.z/probe.height).*(row-1);

tic;
for frm = 1:500%FRM_NUM-1
    fprintf('process (%d/%d) frame ... \n', frm, FRM_NUM);
    slice = data.OCT(:,:,frm);
    intensity = zeros(1,length(row),'uint8');
    for i = 1:length(row)
        intensity(i) = slice(row(i),col(i));
    end
    
    % transform points to robot base frame
    T = data.pose(:,:,frm);
    if enCalibTune
        T_base_flange = T/probe.T_flange_probe; % T*inv(probe.T_flange_probe)
        T = T_base_flange * T_flange_probe_new;
    end
    assert(abs(det(T)-1.0) < 1e-3,'not a valid transformation')
    [xglobal, yglobal, zglobal] = TransformPoints(T,xlocal,ylocal,zlocal);

    % store coordinates
    pc_x((frm-1)*HEIGHT*WIDTH+1 : frm*HEIGHT*WIDTH) = xglobal*1e3;
    pc_y((frm-1)*HEIGHT*WIDTH+1 : frm*HEIGHT*WIDTH) = yglobal*1e3;
    pc_z((frm-1)*HEIGHT*WIDTH+1 : frm*HEIGHT*WIDTH) = zglobal*1e3;
    pc_int((frm-1)*HEIGHT*WIDTH+1 : frm*HEIGHT*WIDTH) = intensity;
end
invalid_ind = find(pc_x==0 & pc_y==0 & pc_z==0);
pc_x(invalid_ind) = [];
pc_y(invalid_ind) = [];
pc_z(invalid_ind) = [];
pc_int(invalid_ind) = [];
fprintf('generate pointcloud took %f sec \n', toc);
clear xlocal ylocal zlocal xglobal yglobal zglobal
clear invalid_ind intensity row col slice probe

%% generate volume data from pointcloud
tic;
scale = 0.5;
VOLUME_HEIGHT = round(HEIGHT*scale);
VOLUME_WIDTH = round(WIDTH*length(data_sizes)*scale);
VOLUME_CHANNEL = round(min(data_sizes)*scale);
volume_raw = zeros(VOLUME_HEIGHT,VOLUME_WIDTH,VOLUME_CHANNEL,'uint8');

res_ele = floor(size(volume_raw,3)/(max(pc_x)-min(pc_x)));
res_lat = floor(size(volume_raw,2)/(max(pc_y)-min(pc_y)));
res_axi = floor(size(volume_raw,1)/(max(pc_z)-min(pc_z)));
ind_axi = round((pc_z - min(pc_z)) * res_axi);
ind_lat = round((pc_y - min(pc_y)) * res_lat);
ind_ele = round((pc_x - min(pc_x)) * res_ele);
ind_ele(ind_ele == 0) = 1;
ind_lat(ind_lat == 0) = 1;
ind_axi(ind_axi == 0) = 1;

for i = 1:length(pc_int)
    volume_raw(ind_axi(i), ind_lat(i), ind_ele(i)) = pc_int(i);
end
clear ind_axi ind_lat ind_ele
fprintf('generate volume took %f sec \n', toc);

%% post-processing on volume
tic;
% interpolation
interp_step = 0.7;
[X_raw,Y_raw,Z_raw] = meshgrid(single(1:VOLUME_WIDTH), ...
                               single(1:VOLUME_HEIGHT), ...
                               single(1:VOLUME_CHANNEL));
[X, Y, Z] = meshgrid(single(1:interp_step:VOLUME_WIDTH), ...
                     single(1:interp_step:VOLUME_HEIGHT), ...
                     single(1:interp_step:VOLUME_CHANNEL));
volume = interp3(X_raw,Y_raw,Z_raw,single(volume_raw),X,Y,Z);
fprintf('post processing took %f sec \n', toc);

%% visualize volume
intensity = [-3024,-16.45,641.38,3071];
alpha = [0, 0, 0.72, 0.72];
color = ([0 0 0; 43 0 0; 103 37 20; 199 155 97]) ./ 255;
queryPoints = linspace(min(intensity),max(intensity),256);
alphamap = interp1(intensity,alpha,queryPoints)';
colormap = interp1(intensity,color,queryPoints);
figure();
vol=volshow(volume_raw,'BackgroundColor',[1 1 1],'Lighting',false, ...
            'Colormap',colormap,'Alphamap',alphamap,'Renderer','isosurface');
% volumeViewer(volume)
% save('generated/03-May-2022_vol{humanA}.mat','volume','-v7.3')
