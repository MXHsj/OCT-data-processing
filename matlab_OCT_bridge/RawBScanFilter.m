function [] = RawBScanFilter()
 % filter
%     BScan_bin = normalize(BScan, 'range', [0 1]); 
%     PSF = fspecial('gaussian',7,10);
%     V = 0.0001;
%     BScan_blurred = imnoise(imfilter(BScan_bin,PSF),'gaussian',0,V);
%     WT = zeros(size(BScan_bin));
%     WT(5:end-4,5:end-4) = 1;
%     BScan_filtered = deconvlucy(double(BScan_blurred),PSF,20,sqrt(V));
%     BScan_filtered = imadjust(BScan_filtered,[0.4 0.9],[]);
%     imagesc(BScan_filtered)