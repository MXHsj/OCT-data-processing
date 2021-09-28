%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: GetScatterCoef.m
% author: Xihan Ma
% description: solve for scattering coefficient from A-scans in B-mode img
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [mu_s, a] = GetScatterCoeff(BScan, intThresh, isVisualize)
if nargin == 1
    intThresh = 50;         % intensity threshold to calculate scatter-coeff
    isVisualize = false;
elseif nargin == 2
    isVisualize = false;
end
tic;
% ftype = fittype('a*exp(-2*mu_s*x)');  % if intensity not in dB
mu_s = zeros(1,size(BScan,2)); a = zeros(1,size(BScan,2));
for col = 1:size(BScan,2)
    AScan_filt = BScan(:,col);
    [peak_val, peak_ind] = max(AScan_filt);
    x = (1:length(AScan_filt(peak_ind:end)))';
    if length(x) > 1 && peak_val > intThresh  % assure enough data points
%         f = fit(x,double(AScan_filt(peak_ind:end)),ftype,'StartPoint',[0.5; 0.0015]);
%         mu_s(col) = f.mu_s; a(col) = f.a;
        f = polyfit(x,double(AScan_filt(peak_ind:end)),1);
        mu_s(col) = f(1)/-8.7; a(col) = 10^(f(end)/10);
    else
        mu_s(col) = nan; a(col) = nan;
    end
end
toc
% visualization
if isVisualize
    figure('Position',[500,95,850,400])
    subplot(1,2,1)
    imagesc(BScan)
    title('raw B-scan')

    subplot(1,2,2)
    plot((AScan_filt), 1:length(AScan_filt))
    hold on
    [~, peak_ind] = max(AScan_filt);
    z = peak_ind:length(AScan_filt);
%     plot(a(end)*exp(-2*mu_s(end)*(z-peak_ind)),z,'--','LineWidth',2);
    plot(10*log10(a(end))-(8.7*mu_s(end)*(z-peak_ind)),z,'--','LineWidth',2);
    ylabel('pixel'); xlabel('intensity')
    title('A-scan of last column')
    legend('intensity','fitted intensity')
    axis('tight','ij')
end
