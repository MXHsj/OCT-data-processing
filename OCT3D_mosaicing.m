%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: OCT3D_mosaicing.m
% author: Xihan Ma
% description: perform lateral mosaicing in 2D, then generate 3D volume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
% load BScan & pose data
data2load = 8:10;
[data, data_sizes] = DataManagerOCT(data2load);
fprintf('total frames: %d\n',sum(data_sizes))

%% lateral blending
figure()
height = size(data.OCT(:,:,1),1);
width = size(data.OCT(:,:,1),2);
BScan_blend = zeros(height,width*length(data_sizes),min(data_sizes)-1,'uint8');
tic;
for frm = 1:min(data_sizes)-1
    BScan_blend = zeros(height,width*length(data_sizes),'uint8');
    for i = 1:length(data_sizes)
        BScan_blend(:,(length(data_sizes)-i)*width+1:(length(data_sizes)-i)*width+width,frm) = ...
            data.OCT(:,:,frm+sum(data_sizes(1:i-1)));    
    end
    % step1 surface extraction
    % step2 lateral blending
    imagesc(BScan_blend(:,:,frm));
    pause(0.005)
end
fprintf('processing data takes %f sec \n', toc);

