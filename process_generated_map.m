%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: process_generated_map.m
% author: Xihan Ma
% description: post-processing of depth-encoding/extinction coefficient
% map, takes in an RGB image as input.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all

data_folder = './generated';
generated_map = 'map53.mat';
load([data_folder,generated_map],'map53');
generated_map = 'map54.mat';
load([data_folder,generated_map],'map54');
generated_map = 'map55.mat';
load([data_folder,generated_map],'map55');

%% process generated map
% stack and interpolate white area
map_stacked = [map53.^1.07; map54; map55];
map_filtered = smooth_map(map_stacked);

% remove sawtooth on the edge
map_filtered(980:1064,:) = 0;
map_filtered(2011:2098,:) = 0;

% mosaicing
map_final = [map_filtered(1:910,:); ...
             ((map_filtered(911:978,:)+map_filtered(1066,1142,:))./2).^1.08; ...
             map_filtered(1143:1938,:); ...
             ((map_filtered(1939:2004,:)+map_filtered(2104:2169,:))./2); ...
             map_filtered(2170:end,:)];
         
for c = 1:size(map_final,2)
    map_final(:,c) = imfilter(map_final(:,c),ones(10,1));
end
map_final = imfilter(map_final,ones(3));

% vis
figure('Position',[500,120,1200,600])
imagesc(map_final);
cb = colorbar();
cb.Label.String = 'extinction coefficient [mm^{-1}]'; cb.Label.FontSize = 14;

    
%% smoothing image
function [map_filtered] = smooth_map(map_raw)
    map_raw(isnan(map_raw))=0;
    map = map_raw;
    window = 2;
    for r = 1+window:size(map,1)-window
        for c = 1+window:size(map,2)-window
            if map(r,c) == 0
                map(r,c) = median(map_raw(r-window:r+window,c-window:c+window),'all');
            end
        end
    end
    map2 = map;
    for r = 1+window:size(map,1)-window
        for c = 1+window:size(map,2)-window
            if map2(r,c) == 0
                map2(r,c) = median(map(r-window:r+window,c-window:c+window),'all');
            end
        end
    end
    map3 = map2;
    window = 10;
    for r = 1+window:size(map,1)-window
        for c = 1+window:size(map,2)-window
            if map3(r,c) == 0 || isnan(map(r,c))
                map3(r,c) = median(map2(r-window:r+window,c-window:c+window),'all');
            end
        end
    end
    map_filtered = map3;
end
