%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: GetScatterCoef.m
% author: Xihan Ma
% description: solve for scattering coefficient from A-scans in B-mode img
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
% load BScan & pose data
data2load = 23;
[data, data_sizes] = DataManagerOCT(data2load); 

%% get AScan
BScan = data.OCT(:,:,200);
BScan_filt = FilterRawBScan(BScan,1);
ftype = fittype('a*exp(-2*mu_s*x)');
mu_s = zeros(1,size(BScan,2)); a = zeros(1,size(BScan,2));
tic;
for col = 1:size(BScan,2)
    AScan = BScan(:,col);
    AScan_filt = BScan_filt(:,col);
    [~, peak_ind] = max(AScan_filt);
    x = (1:length(AScan_filt(peak_ind:end)))';
    if length(x) > 2    % make sure at least 2 data points
        f = fit(x,double(AScan_filt(peak_ind:end)),ftype,'StartPoint',[0.5; 0.0015]);
        mu_s(col) = f.mu_s; a(col) = f.a;
    else
        mu_s(col) = nan; a(col) = nan;
    end
end
fprintf('scatter-coefficient fitting took %f[sec]\n',toc);

%% visualization
figure('Position',[500,95,800,850])
subplot(2,2,1)
imagesc(BScan)
title('raw B-scan')

subplot(2,2,2)
imagesc(BScan_filt)
title('filtered B-scan')

subplot(2,2,3)
plot((AScan), 1:length(AScan))
ylabel('pixel'); xlabel('intensity')
title('A-scan of last column')
axis('tight','ij')

subplot(2,2,4)
plot((AScan_filt), 1:length(AScan_filt))
hold on
[~, peak_ind] = max(AScan_filt);
z = peak_ind:length(AScan_filt);
plot(a(end)*exp(-2*mu_s(end)*(z-peak_ind)),z,'--','LineWidth',2);
ylabel('pixel'); xlabel('intensity (normalized)')
title('A-scan of last column')
legend('intensity','fitted intensity')
axis('tight','ij')

