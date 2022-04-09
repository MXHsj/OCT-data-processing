%% generate video from BScan
clc; clear; close all
addpath(genpath('utilities/'));

% load BScan & pose data
data2load = 53:55;
[data, data_sizes] = FrankaOCTDataManager(data2load);
fprintf('total frames: %d\n',sum(data_sizes))

%%
h = figure('Position',[1920/4,1080/4,800,500]);
aviObj = VideoWriter('generated/BScan','MPEG-4');
aviObj.FrameRate = 120; aviObj.Quality = 100;
open(aviObj);

for frm = 1:data_sizes(1)
    BScan = data.OCT(:,:,frm);
    imagesc(BScan, [40 70]); 
    colormap gray; axis off
    pause(1e-4)
    writeVideo(aviObj, getframe(h));
end
close(aviObj);