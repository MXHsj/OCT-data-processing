%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: franka_3DOCT_extinction_coeff2.m
% author: Xihan Ma
% description: perform lateral mosaicing in 2D, then generate 3D volume,
% then generate extinction coefficient map
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
addpath(genpath('utilities/'));

% load BScan & pose data
data2load = 61:63;
[data, data_sizes] = FrankaOCTDataManager(data2load);
fprintf('total frames: %d\n',sum(data_sizes))

height = size(data.OCT(:,:,1),1);
width = size(data.OCT(:,:,1),2);
xdata = squeeze(data.pose(1,end,:))*1e3;    % robot base x
ydata = squeeze(data.pose(2,end,:))*1e3;    % robot base y
xrange = [min(xdata), max(xdata)];
yrange = [min(ydata), max(ydata)];

%% lateral blending
BScan_blend = zeros(height,width*length(data_sizes),min(data_sizes)-1,'uint8');
overlap = round(0.5*width/7.8); % [pix] 0.1 mm overlap
imgFiltThresh = 0.7;    % normalized threshold
blend_flags.isBlend = false;    % set to true to enbale axial/lateral direction blending
blend_flags.doAxial = true;     % set to true to enable depth compensation in axial direction
blend_flags.doLateral = false;  % set to true to enable automatic overlapping
blend_flags.vis = false;        % set to true to enable frame-by-frame visualization
if blend_flags.vis
    figure('Position',[1920/4,1080/4,1000,500])
end
tic;
for frm = 1:min(data_sizes)-1
    % stitch images in lateral direction
    for i = 1:length(data_sizes)
        BScan_blend(:,(length(data_sizes)-i)*width+1:(length(data_sizes)-i)*width+width,frm) ...
            = data.OCT(:,:,frm+sum(data_sizes(1:i-1)));
    end
    if blend_flags.isBlend
        % blend images based on surface depth
        BScan_ref = BScan_blend(:,1:width,frm);
        temp = zeros(size(BScan_blend,1),size(BScan_blend,2),'uint8');
        temp(:,1:width) = BScan_ref;
        for i = 2:length(data_sizes)
            BScan_raw = BScan_blend(:,(i-1)*width+1:(i-1)*width+width,frm);
            if blend_flags.doAxial
                [max_raw, row_raw] = max(FilterRawBScan(BScan_raw,4));
                [max_ref, row_ref] = max(FilterRawBScan(BScan_ref,4));
                if max_raw(1) > imgFiltThresh && max_ref(end) > imgFiltThresh
                    axial_offset = mean(row_ref(end-1:end)) - mean(row_raw(1:2));
                else
                    axial_offset = 0;
                end
            else
                axial_offset = 0;
            end
            if blend_flags.doLateral
                lateral_offset = -overlap*(i-1);
            else
                lateral_offset = 0;
            end
            BScan_warp = imtranslate(BScan_raw,[lateral_offset,axial_offset]);
            temp(:,(i-1)*width+1+lateral_offset:i*width+lateral_offset) = BScan_warp;
            BScan_ref = BScan_warp;
        end
        BScan_blend(:,:,frm) = temp;
    end
    fprintf('process (%d/%d) slice ... \n', frm,min(data_sizes)-1);
    if blend_flags.vis
        imagesc(BScan_blend(:,:,frm));
        pause(0.01)
    end
end
fprintf('processing data takes %f sec \n', toc);

% volumeViewer(BScan_blend);
% save('mosaiced_volume.mat','BScan_blend','-v7.3');

%% generate extinction coefficient map
ext_coeff_map = zeros(size(BScan_blend,2),size(BScan_blend,3),'single');
tic;
for i = 1:size(BScan_blend,3)
    [ec, ~] = GetExtCoeff(BScan_blend(:,:,i), 40, 150, false);
    ext_coeff_map(:,i) = ec;
    fprintf('process (%d/%d) slice ... \n', i,size(BScan_blend,3));
end
fprintf('processing data takes %f sec \n', toc);

%% visualize extinction coefficient map
grid = ext_coeff_map;
lowBound = 0;
upBound = mean(grid,'all','omitnan') + 0.3*std(grid,[],'all','omitnan');
outlier_ind = find(grid < lowBound | grid > upBound);
grid(outlier_ind) = nan;
figure('Position',[1920/4,1080/4,1200,500])
grid = flipud(grid);        % flip bottom up
imagesc(xrange, yrange, grid); colormap gray; 
xlabel('x [mm]'); ylabel('y [mm]')
colorbar

%% stack extinction coefficient map based on NCC
sec1 = (grid(1:width,:));
sec2 = (grid(width+1:width*2,:));
sec3 = (grid(width*2+1:width*3,:));
sec1(isnan(sec1)) = 0; sec2(isnan(sec2)) = 0; sec3(isnan(sec3)) = 0;

doNCCBlend = false;
visNCC = false;

if doNCCBlend
    sec2_crop = sec2(1:100,:);
    sec3_crop = sec3(1:100,:);
    c12 = normxcorr2(sec2_crop, sec1);
    c23 = normxcorr2(sec3_crop, sec2);

    [ypeak12,xpeak12] = find(c12==max(c12(:)));
    yoffSet12 = ypeak12-size(sec2_crop,1);
    xoffSet12 = xpeak12-size(sec2_crop,2);

    [ypeak23,xpeak23] = find(c23==max(c23(:)));
    yoffSet23 = ypeak23-size(sec3_crop,1);
    xoffSet23 = xpeak23-size(sec3_crop,2);
    
    if visNCC
        figure; imagesc(c12); colormap gray; colorbar;
        figure; imagesc(c23); colormap gray; colorbar;
        figure; imagesc(sec1); axis off; hold on
        drawrectangle(gca,'Position',[xoffSet12,yoffSet12,size(sec2_crop,2),size(sec2_crop,1)],'FaceAlpha',0);
        figure; imagesc(sec2); axis off; hold on
        drawrectangle(gca,'Position',[xoffSet23,yoffSet23,size(sec3_crop,2),size(sec3_crop,1)],'FaceAlpha',0);
    end
    % sec2 = imtranslate(sec2,[xoffSet12,0]);       % lateral translation
    % sec3 = imtranslate(sec3,[xoffSet23,0]);
else
    yoffSet12 = width - overlap;
    yoffSet23 = width - overlap;
end

combined = [sec1(1:yoffSet12,:); ...
            ((sec1(yoffSet12+1:end,:)+sec2(1:1024-yoffSet12,:))./2).^1; ...
            sec2(1024-yoffSet12+1:yoffSet23,:);
            ((sec2(yoffSet23+1:end,:)+sec3(1:1024-yoffSet23,:))./2).^1; ...
            sec3(1024-yoffSet23+1:end,:)];
combined = imfilter(combined,eye(3));
% combined = flipud(combined);        % flip bottom up

figure('Position',[1920/4,1080/4,1200,500]); 
imagesc(xrange, yrange, combined); colormap gray; 
xlabel('x [mm]'); ylabel('y [mm]')
colorbar
