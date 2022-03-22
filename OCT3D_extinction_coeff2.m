%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: OCT3D_mosaicing.m
% author: Xihan Ma
% description: perform lateral mosaicing in 2D, then generate 3D volume,
% then generate extinction coefficient map
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
% load BScan & pose data
data2load = 53:55;
[data, data_sizes] = DataManagerOCT(data2load);
fprintf('total frames: %d\n',sum(data_sizes))

%% lateral blending
height = size(data.OCT(:,:,1),1);
width = size(data.OCT(:,:,1),2);
BScan_blend = zeros(height,width*length(data_sizes),min(data_sizes)-1,'uint8');
overlap = round(0.55*width/7.6); % [pix] 0.5 mm overlap
imgFiltThresh = 0.7;    % normalized threshold
blend_flags.isBlend = false;
blend_flags.doAxial = true;
blend_flags.doLateral = false;
blend_flags.vis = true;
if blend_flags.vis
    figure('Position',[1920/4,1080/4,1000,500])
end
tic;
for frm = 100%:min(data_sizes)-1
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
    [ec, ~] = GetExtCoeff(BScan_blend(:,:,i), 53, false);
    ext_coeff_map(:,i) = ec;
    fprintf('process (%d/%d) slice ... \n', i,size(BScan_blend,3));
end
fprintf('processing data takes %f sec \n', toc);

%% visualize extinction coefficient map
grid = ext_coeff_map;
lowBound = 0;
upBound = mean(grid,'all','omitnan') + 3*std(grid,[],'all','omitnan');
outlier_ind = find(grid < lowBound | grid > upBound);
grid(outlier_ind) = nan;
figure('Position',[1920/4,1080/4,1200,500])
imagesc(grid); colormap gray

%% rearrange extinction coefficient map based on NCC
sec1 = (grid(1:1024,:));
sec2 = (grid(1024+1:1024*2,:));
sec3 = (grid(1024*2+1:1024*3,:));
sec1(isnan(sec1)) = 0; sec2(isnan(sec2)) = 0; sec3(isnan(sec3)) = 0;

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

% figure; imagesc(c12); colormap gray; colorbar;
% figure; imagesc(c23); colormap gray; colorbar;
% figure; imagesc(section1); axis off; hold on
% drawrectangle(gca,'Position',[xoffSet,yoffSet,size(section2_crop,2),size(section2_crop,1)],'FaceAlpha',0);
% figure; imagesc(section2); axis off; hold on
% drawrectangle(gca,'Position',[xoffSet,yoffSet,size(section3_crop,2),size(section3_crop,1)],'FaceAlpha',0);

% combined = zeros(size(grid));
% combined(1:1024,:) = sec1;
% sec2 = imtranslate(sec2,[xoffSet12,0]);
% combined(yoffSet12:yoffSet12+1023,:) = sec2;
% sec3 = imtranslate(sec3,[xoffSet23,0]);
% combined(yoffSet12+yoffSet23:yoffSet12+yoffSet23+1023,:) = sec3;
sec2 = imtranslate(sec2,[xoffSet12,0]);
sec3 = imtranslate(sec3,[xoffSet23,0]);
combined = [sec1(1:yoffSet12,:); ...
            ((sec1(yoffSet12+1:end,:)+sec2(1:1024-yoffSet12,:))./2).^1; ...
            sec2(1024-yoffSet12+1:yoffSet23,:);
            ((sec2(yoffSet23+1:end,:)+sec3(1:1024-yoffSet23,:))./2).^1; ...
            sec3(1024-yoffSet23+1:end,:)];
combined = imfilter(combined,eye(3));
combined = flipud(combined);

figure('Position',[1920/4,1080/4,1200,500]); imagesc(combined); colormap gray;
