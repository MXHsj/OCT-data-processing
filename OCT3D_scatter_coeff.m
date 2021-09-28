%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: OCT3D_scatter_coeff.m
% author: Xihan Ma
% description: get scattering coefficient from A-scans & generate 2D map
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
isGenVid = false;
% load BScan & pose data
data2load = 16:18;
[data, data_sizes] = DataManagerOCT(data2load); 

%% extract first peak from AScan
probe = ProbeConfigOCT(); % get OCT probe configuration
enCalibTune = true;
T_flange_probe_new = CompCalibErr(probe.T_flange_probe);

pc_x = []; pc_y = []; pc_z = []; 
scatter_coeff = [];     % single scattering model

dwnSmpInterv = 0;
imgFiltThresh = 50;
tic;
for item = 1:100%size(data.OCT,3)
    fprintf('process %dth image ... \n', item);
    BScan = data.OCT(:,:,item);
    % get scattering coefficient
    [sc, ~] = GetScatterCoeff(BScan, imgFiltThresh, 0);   
    % TODO: only find peak once
    % find highest peak in each AScan
    [maxAScan, row] = max(BScan(:,~isnan(sc)));
    col = find(maxAScan > imgFiltThresh);
    row = row(col);
    if ~isempty(row) && ~isempty(col)
        xlocal = zeros(1,length(row));
        ylocal = -(probe.y/probe.width).*(col-1) + probe.y/2;
        zlocal = (probe.z/probe.height).*(row-1);

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
            sc = downsample(sc, ceil(dwnSmpInterv*length(sc)));
        end
        
        % append
        if length(sc(~isnan(sc))) ~= length(xglobal)
            disp('size discrepency')
            break
        end
        pc_x = cat(2, pc_x, xglobal);
        pc_y = cat(2, pc_y, yglobal);
        pc_z = cat(2, pc_z, zglobal);
        scatter_coeff = cat(2, scatter_coeff, sc(~isnan(sc)));
    end 
end
pc_x = single(pc_x); pc_y = single(pc_y); pc_z = single(pc_z);
fprintf('processing data takes %f sec \n', toc);

%% visualize 2D scattering coefficient map
figure('Position',[500,120,1000,600])
scatter(pc_x.*1e3,pc_y.*1e3,repmat(5,1,length(pc_x)),scatter_coeff,'filled')
colormap(gca,'jet')
cb = colorbar('Ticks',linspace(min(scatter_coeff),max(scatter_coeff),5));
cb.Label.String = 'scattering coefficient '; cb.Label.FontSize = 14;
xlabel('x [mm]'); ylabel('y [mm]');
axis equal tight 
axis off
