%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: FilterRawBScan.m
% author: Xihan Ma
% description: filter raw BScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [BScan_filtered] = FilterRawBScan(BScan, filter_id)
if nargin < 2
    filter_id = 1;
end

% filter_id == 1 ---> svd filtering (fastest)
% filter_id == 2 ---> blur-deblur
% filter_id == 3 ---> blur-deblur + svd

if filter_id == 1
    BScan = single(BScan);
    [U,S,V] = svd(BScan);
    eigen_begin = round(0.08*min(size(BScan)));
    eigen_range = round(0.99*(min(size(BScan))-eigen_begin));
    % set eigen values in [begin, begin+range] to 0
    S(eigen_begin:eigen_range,eigen_begin:eigen_range) = 0;
    BScan_filtered = U*S*V';
%     BScan_filtered = normalize(BScan_filtered, 'range', [0 1]);
    
elseif filter_id == 2
    % blur-deblur 
    BScan = single(BScan);
    BScan_norm = normalize(BScan, 'range', [0 1]); 
    PSF = fspecial('gaussian',7,10);
    V = 0.0001;
    BScan_blurred = imnoise(imfilter(BScan_norm,PSF),'gaussian',0,V);
    BScan_filtered = deconvlucy(double(BScan_blurred),PSF,20,sqrt(V));
    BScan_filtered = imadjust(BScan_filtered,[0.33 0.9],[]);
    
elseif filter_id == 3
    BScan = single(BScan);
    % svd + blur-deblur
    [U,S,V] = svd(BScan);
    eigen_begin = round(0.26*min(size(BScan)));
    eigen_range = round(0.98*(min(size(BScan))-eigen_begin));
    S(eigen_begin:eigen_range,eigen_begin:eigen_range) = 0;
    BScan_svd = U*S*V';
    BScan_norm = normalize(BScan_svd, 'range', [0 1]); 
    PSF = fspecial('gaussian',7,10);
    V = 0.0001;
    BScan_blurred = imnoise(imfilter(BScan_norm,PSF),'gaussian',0,V);
    BScan_filtered = deconvlucy(double(BScan_blurred),PSF,20,sqrt(V));
    BScan_filtered = imadjust(BScan_filtered,[0.5 0.95],[]);

elseif filter_id == 4
    % test built-in image processing API
%     BScan = imsharpen(BScan,'Radius',2.0,'Amount',0.5,'Threshold',0.55);
    BScan = adapthisteq(BScan);
    BScan = localcontrast(BScan);
%     sigma = 0.2;
%     alpha = 5.0;
%     BScan_filtered = locallapfilt(BScan, sigma, alpha);
    BScan = imfilter(double(BScan),[100, 100],'conv','same');
    BScan_norm = normalize(BScan, 'range', [0 1]);
    BScan_filtered = imadjust(BScan_norm,[0.5 0.9],[]);
end

