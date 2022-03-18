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
    truncation = round(0.10*length(S));
    BScan_filtered = U(:,1:truncation)*S(1:truncation,1:truncation)*V(:,1:truncation)';
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
    truncation = round(0.26*length(S));
    BScan_svd = U(:,1:truncation)*S(1:truncation,1:truncation)*V(:,1:truncation)';
    BScan_norm = normalize(BScan_svd, 'range', [0 1]); 
    PSF = fspecial('gaussian',7,10);
    V = 0.0001;
    BScan_blurred = imnoise(imfilter(BScan_norm,PSF),'gaussian',0,V);
    BScan_filtered = deconvlucy(double(BScan_blurred),PSF,20,sqrt(V));
    BScan_filtered = imadjust(BScan_filtered,[0.5 0.95],[]);

elseif filter_id == 4
    % built-in image processing API
%     BScan = imsharpen(BScan,'Radius',2.0,'Amount',0.5,'Threshold',0.55);
%     BScan = adapthisteq(BScan);
%     BScan = localcontrast(BScan);
%     sigma = 0.2;
%     alpha = 5.0;
%     BScan_filtered = locallapfilt(BScan, sigma, alpha);
    BScan = imfilter(double(BScan),[5, 5],'conv','same');
    BScan_norm = normalize(BScan, 'range', [0 1]);
    BScan_filtered = imadjust(BScan_norm,[0.3 0.9],[]); % dynamic range
end

