%% test stitch & visualize OCT images
clc; clear; close all

% read data
OCT_data_folder = '../data/OCT_3D_scan/2021-04-20/';
OCT_data_info = dir(OCT_data_folder);

tic;
% volume_data = [];
volume_data = single(zeros(1024,1573,numel(OCT_data_info)-2));
threshold = 50;
for item = 1:numel(OCT_data_info)
    if ~OCT_data_info(item).isdir
        img_rgb = imread([OCT_data_folder, OCT_data_info(item).name]);
        img_gray = single(rgb2gray(img_rgb));
        img_gray(img_gray(:,:) <= threshold) = nan;
%         volume_data = cat(3, volume_data, img_gray);
        volume_data(:,:,item-2) = img_gray;
        fprintf('read %dth image ... \n', item);
    end
end
fprintf('reading data takes %f sec\n', toc);

%% visualize
V_cropped = volume_data(:,:,1:50);  % show partial data to save time
% volshow(V_cropped)

x = linspace(-2.5, 2.5, 1573);
y = linspace(-2, 0, 1024);
z = linspace(0, 5*size(V_cropped,3)/514, size(V_cropped,3));
figure
[X,Y,Z] = meshgrid(x,y,z);

xslice = [];
yslice = [];
zslice = 0:0.01:max(z);
h = slice(X,Y,Z,V_cropped,xslice,yslice,zslice,'nearest');
xlabel('y [mm]')
ylabel('z [mm]')
zlabel('x [mm]')
set(h, 'EdgeColor', 'none', 'FaceColor', 'interp')
set(gca,'YDir','reverse')
zlim([0,5])
colormap gray
