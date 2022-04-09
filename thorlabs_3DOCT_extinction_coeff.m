%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: thorlabs_3DOCT_extinction_coeff.m
% author: Xihan Ma
% description: generate BScan data from .OCT files, modified from Thorlabs
% example
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
addpath(genpath('matlab_OCT_bridge/'));
addpath(genpath('utilities/'));

%% load data
handle = ThorlabsOCTDataManager(1);

%%%%% read dataset properties %%%%%%
disp(OCTFileGetProperty(handle, 'AcquisitionMode'));
disp(OCTFileGetProperty(handle, 'RefractiveIndex'));
disp(OCTFileGetProperty(handle, 'Comment'));
disp(OCTFileGetProperty(handle, 'Study'));
disp(OCTFileGetProperty(handle, 'ExperimentNumber'));

%% read video image and Intensity
VideoImage = OCTFileGetColoredData(handle,'VideoImage');
% figure; clf;
% imagesc(VideoImage);

Intensity = OCTFileGetIntensity(handle);
X_range = [str2double(handle.head.Image.CenterX.Text) - str2double(handle.head.Image.SizeReal.SizeX.Text)/2, ...
           str2double(handle.head.Image.CenterX.Text) + str2double(handle.head.Image.SizeReal.SizeX.Text)/2];
Y_range = [str2double(handle.head.Image.CenterY.Text) - str2double(handle.head.Image.SizeReal.SizeY.Text)/2, ...
           str2double(handle.head.Image.CenterY.Text) + str2double(handle.head.Image.SizeReal.SizeY.Text)/2];
Z_range = [0, str2double(handle.head.Image.SizeReal.SizeZ.Text)];

%% inspect individual BScan
frm = 250;
figure()
imagesc(X_range, Z_range, Intensity(:,:,frm), [0, 82]); colormap gray
axis image; xlabel('X [mm]'); ylabel('Z [mm]');
GetExtCoeff(Intensity(:,:,frm), 40, 250, true);
       
%% generate extinction coefficient map
BScan_stack = uint8(Intensity);
ext_coeff_map = zeros(size(BScan_stack,2),size(BScan_stack,3),'single');
fit_window = 250;
tic;
for i = 1:size(BScan_stack,3)
    [ec, ~] = GetExtCoeff(BScan_stack(:,:,i), 40, fit_window, false);
    ext_coeff_map(:,i) = ec;
    fprintf('process (%d/%d) slice ... \n', i,size(BScan_stack,3));
end
fprintf('processing data takes %f sec \n', toc);
% VolumeViewer(BScan_stack)

%% visualize extinction coefficient map
grid = ext_coeff_map;
lowBound = 0;
upBound = mean(grid,'all','omitnan') + 0.3*std(grid,[],'all','omitnan');
outlier_ind = find(grid < lowBound | grid > upBound);
grid(outlier_ind) = nan;
figure
imagesc(Y_range, X_range, grid); colorbar; axis image
colormap gray; 
xlabel('Y [mm]'); ylabel('X [mm]');

%% close OCT file (deletes temporary files)
OCTFileClose(handle);
rmpath(genpath('matlab_OCT_bridge/'))
