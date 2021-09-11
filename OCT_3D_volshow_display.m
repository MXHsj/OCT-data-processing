%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: OCT_3D_volshow_display_old.m
% author: Xihan Ma
% description: display 2D b-mode OCT by stitching them in 3D
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

%% load all images and set background to 0
BScan = data.OCT;
threshold = 55;
for item = 1:size(BScan,3)
    BScan_curr = BScan(:,:,item);
    BScan_curr(BScan_curr <= threshold) = 0;
    BScan(:,:,item) = BScan_curr;
    fprintf('read %dth image ... \n', item);
end
clear BScan_curr

%% transform images to common coordinate frame
res = 0.008;  % mm/pix 0.0044
FOV.x = 6;    % mm 
FOV.y = 8;    % mm
FOV.z = 3;    % mm
yrange = 5e-3; zrange = 10e-3;
height = size(BScan,1); width = size(BScan,2);
b_mode_volume = zeros(round(FOV.x/res),round(FOV.y/res),round(FOV.z/res),'uint8');
T_init = data.pose(:,:,1);   % initial position

% transform pixels
tic;
for item = 1:size(BScan,3)
    [row,col] = find(BScan(:,:,item)~=0);
    xlocal = zeros(length(row),1);
    ylocal = yrange/width.*col - yrange/width;
    zlocal = yrange/height.*row - zrange/height;
    
    T = data.pose(:,:,item);
    [xglobal, yglobal, zglobal] = transformPoints(T,xlocal,ylocal,zlocal);
    for i = 1:length(row)
        xgrid = ceil(((xglobal(i)-T_init(1,end))*1e3)/res);
        ygrid = ceil(((yglobal(i)-T_init(2,end))*1e3+FOV.y)/res);
        zgrid = ceil(((T_init(3,end)-zglobal(i))*1e3)/res);
        xgrid(xgrid <= 0) = 1;
        ygrid(ygrid <= 0) = 1;
        zgrid(zgrid <= 0) = 1;
        b_mode_volume(xgrid, ygrid, zgrid) = BScan(row(i),col(i),item);
    end
    fprintf('transform %dth slice\n', item);
end
fprintf('processing data takes %f sec \n', toc);

%%
volshow(b_mode_volume,'CameraUpVector',[0 0 -1]);
