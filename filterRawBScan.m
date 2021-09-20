%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: RawBScanFilter.m
% author: Xihan Ma
% description: filter raw BScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [BScan_filtered] = filterRawBScan(BScan, filter_id)
if nargin < 2
    filter_id = 1;
end
BScan = single(BScan);
% filter_id == 1 ---> svd filtering
% filter_id == 2 ---> blur-deblur
% filter_id == 3 ---> blur-deblur + svd

if filter_id == 1
    % svd filtering -- faster
    [U,S,V] = svd(BScan);
    eigen_begin = round(0.12*min(size(BScan)));
    eigen_range = round(0.7*(min(size(BScan))-eigen_begin));
    S(eigen_begin:eigen_range,eigen_begin:eigen_range) = 0;
    BScan_filtered = U*S*V';
    BScan_filtered = normalize(BScan_filtered, 'range', [0 1]);
    
elseif filter_id == 2
    % blur-deblur 
    BScan_norm = normalize(BScan, 'range', [0 1]); 
    PSF = fspecial('gaussian',7,10);
    V = 0.0001;
    BScan_blurred = imnoise(imfilter(BScan_norm,PSF),'gaussian',0,V);
%     WT = zeros(size(BScan_bin)); WT(5:end-4,5:end-4) = 1;
    BScan_filtered = deconvlucy(double(BScan_blurred),PSF,20,sqrt(V));
    BScan_filtered = imadjust(BScan_filtered,[0.58 0.9],[]);
    
elseif filter_id == 3
    % svd + blur-deblur
    [U,S,V] = svd(BScan);
    eigen_begin = round(0.15*min(size(BScan)));
    eigen_range = round(0.55*(min(size(BScan))-eigen_begin));
    S(eigen_begin:eigen_range,eigen_begin:eigen_range) = 0;
    BScan_svd = U*S*V';
    BScan_norm = normalize(BScan_svd, 'range', [0 1]); 
    PSF = fspecial('gaussian',7,10);
    V = 0.0001;
    BScan_blurred = imnoise(imfilter(BScan_norm,PSF),'gaussian',0,V);
    BScan_filtered = deconvlucy(double(BScan_blurred),PSF,20,sqrt(V));
    BScan_filtered = imadjust(BScan_filtered,[0.5 0.95],[]);
end