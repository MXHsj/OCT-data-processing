%% evaluation of pointcloud registration

clc; clear; close all

% load data
id1 = 6;
id2 = 7;
tic;
data1 = DataManagerOCT(id1);
data2 = DataManagerOCT(id1);
clear data_tmp id
fprintf('read data took %f sec\n',toc);

%% extract pointcloud
tic;
pc_x = []; pc_y = []; pc_z = []; 
pc_x_int = []; pc_y_int = []; pc_z_int = [];        % intensity

yrange = 5e-3; zrange = 7e-3;
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
           
        [xglobal, yglobal, zglobal] = transformPoints(T,xlocal,ylocal,zlocal);
        % downsample by 30%
        xglobal = downsample(xglobal,ceil(dwnSmpRate*length(xglobal)));
        yglobal = downsample(yglobal,ceil(dwnSmpRate*length(yglobal)));
        zglobal = downsample(zglobal,ceil(dwnSmpRate*length(zglobal)));
        xint = downsample(xint,ceil(dwnSmpRate*length(xint)));
        yint = downsample(yint,ceil(dwnSmpRate*length(yint)));
        zint = downsample(zint,ceil(dwnSmpRate*length(zint)));
        % append
        pc_x = [pc_x, xglobal];
        pc_y = [pc_y, yglobal];
        pc_z = [pc_z, zglobal];
        pc_x_int = [pc_x_int, xint];
        pc_y_int = [pc_y_int, yint];
        pc_z_int = [pc_z_int, zint];
    else
        continue
    end
    fprintf('read %dth image ... \n', item);
end
pc_x = single(pc_x);
pc_y = single(pc_y);
pc_z = single(pc_z);
fprintf('processing data takes %f sec \n', toc);
clear BScan row col T xlocal ylocal zlocal xglobal yglobal zglobal