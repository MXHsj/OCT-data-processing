%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: genPntcloudFrmBScan.m
% author: Xihan Ma
% description: generate pointcloud data from BScan images & robot poses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [pc_xyz, pc_intensity] = genPntcloudFrmBScan(data)
pc_x = []; pc_y = []; pc_z = []; 
pc_x_int = []; pc_y_int = []; pc_z_int = [];        % intensity

yrange = 5e-3; zrange = 7e-3;
height = size(data.OCT,1); width = size(data.OCT,2); frames = size(data.OCT,3);
imgFiltThresh = 50;
dwnSmpRate = 0.012;

for item = 1:frames
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
pc_xyz = single([pc_x.*1e3; pc_y.*1e3; pc_z.*1e3]');
pc_intensity = [pc_x_int; pc_y_int; pc_z_int]';
fprintf('processing data takes %f sec \n', toc);

