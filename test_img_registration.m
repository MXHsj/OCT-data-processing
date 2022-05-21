%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name:
% author: Xihan Ma
% description:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
addpath(genpath('utilities/'));

% load BScan & pose data
data2load = 51:52;
[data, data_sizes] = FrankaOCTDataManager(data2load);
data_sizes = [0; data_sizes];
fprintf('total frames: %d\n',sum(data_sizes))

%% frame registration
frm_id = 600;
fixed = data.OCT(:,:,frm_id);
moving = data.OCT(:,:,data_sizes(2)+frm_id);

% === intensity-based registration ===
% tic;
% [optimizer,metric] = imregconfig('monomodal');
% movingRegistered = imregister(moving, fixed, 'affine', optimizer, metric);
% toc;
% imshowpair(fixed, movingRegistered,'Scaling','joint');

% === 2D normalized cross-correlation
% tic;
% range = 700;
% c = normxcorr2(moving(:,end-range+1:end), fixed(:,1:range));
% [ypeak,xpeak] = find(c==max(c(:)));
% yoffSet = ypeak-size(moving,1)
% xoffSet = xpeak-size(moving,2)
% toc;
% 
% figure('Position',[1920/3, 1080/3, 1200, 400])
% subplot(1,2,1)
% imagesc(moving(:,end-range+1:end)); colormap gray;
% subplot(1,2,2)
% imagesc(fixed(:,1:range)); colormap gray
% drawrectangle(gca,'Position',[xoffSet,yoffSet,size(moving(:,end-range+1:end),2),size(moving(:,end-range+1:end),1)],'FaceAlpha',0.2);

% === 2D correlation coefficient ===
% tic;
% CC = zeros(1,size(moving,2),'uint8');
% for c = 1:size(moving,2)
%     CC(c) = corr2(moving(:,end-c+1:end), fixed(:,1:c)); 
% end
% toc;
% [~,xoffSet] = max(CC);
% 
% figure('Position',[1920/3, 1080/3, 1200, 400])
% subplot(1,2,1)
% imagesc(moving); colormap gray;
% subplot(1,2,2)
% imagesc(fixed); colormap gray
% drawrectangle(gca,'Position',[-xoffSet,0,size(moving,2),size(moving,1)],'FaceAlpha',0.2);

%% generate volumes

% for vol = 2:length(data_sizes)
%     eval(['vol', num2str(vol-1), '=zeros(1024, 1024, data_sizes(vol));']);
%     for frm = 1:data_sizes(vol)
%         BScan = data.OCT(:,:,data_sizes(vol-1)+frm);
%         imagesc(BScan)
%         evel(['vol', num2str(vol-1), '(:,:,frm)=BScan;']);
%     end
% end

scale = 0.3;
vol1 = zeros(1024,1024,round(data_sizes(3)*scale),'uint8');
vol2 = zeros(1024,1024,round(data_sizes(3)*scale),'uint8');
for frm = 1:size(vol1,3)
    BScan = data.OCT(:,:,data_sizes(1)+frm);
    vol1(:,:,frm) = BScan;
end
for frm = 1:size(vol2,3)
    BScan = data.OCT(:,:,data_sizes(2)+frm);
    vol2(:,:,frm) = BScan;
end

vol1(:,:,1621+1:end) = [];

%% volume registration
[optimizer,metric] = imregconfig('monomodal');

Rfixed  = imref3d(size(vol1));
Rmoving = imref3d(size(vol2));

tic;
movingRegisteredVolume = imregister(vol1,Rmoving,vol2,Rfixed,'rigid',optimizer, metric);
toc;

figure
imshowpair(movingRegisteredVolume(:,:,800), fixedVolume(:,:,800));
title('Axial Slice of Registered Volume')
