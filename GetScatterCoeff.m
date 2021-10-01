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
% tic;
mu_s = zeros(1,size(BScan,2)); a = zeros(1,size(BScan,2));

% ====================== fast ver. =======================
for col = 1:size(BScan,2)
    AScan = BScan(:,col);
    [peak_val, peak_ind] = max(AScan);
%     if peak_val
    % solve for Y = xB
    x = [ones(length(AScan(peak_ind:end)),1), (1:length(AScan(peak_ind:end)))'];
    if length(x) > 1 && peak_val > intThresh
        f = x\double(AScan(peak_ind:end));
        mu_s(col) = f(end)/-8.7; 
        a(col) = 10^(f(1)/10);
    else
        mu_s(col) = nan; 
        a(col) = nan;
    end
end

% ====================== slower ver. =======================
% for col = 1:size(BScan,2)
%     AScan_filt = BScan(:,col);
%     [peak_val, peak_ind] = max(AScan_filt);
%     x = (1:length(AScan_filt(peak_ind:end)))';
%     if length(x) > 1 && peak_val > intThresh
%         f = polyfit(x,double(AScan_filt(peak_ind:end)),1);
%         mu_s(col) = f(1)/-8.7; 
%         a(col) = 10^(f(end)/10);
%     else
%         mu_s(col) = nan; 
%         a(col) = nan;
%     end
% %     mu_s = filloutliers(mu_s,'previous');
% end

% toc
% visualization
if isVisualize
    figure('Position',[600,400,1.2*size(BScan,2),1.2*size(BScan,1)/2])
    subplot(1,2,1)
    yyaxis left; 
    imagesc(BScan); 
    ylabel('image height [row]')
    yyaxis right; 
    plot(1:length(mu_s),mu_s,'o','MarkerSize',3.5); 
    ylabel('scattering coefficient \mu_s [pix^{-1}]')
    xlabel('image width [col]')
    title('BScan')
    
    subplot(1,2,2)
    AScan2plot = 30;
    plot((BScan(:,AScan2plot)), 1:length(BScan(:,AScan2plot))); hold on
    [~, peak_ind] = max(BScan(:,AScan2plot));
    z = (peak_ind:length(BScan(:,AScan2plot)));
    plot(10*log10(a(AScan2plot))-(8.7*mu_s(AScan2plot)*(z-peak_ind)),z,'--','LineWidth',2);
    ylabel('image height [row]'); 
    xlabel('intensity [dB]')
    legend('intensity',['linear decay {\mu_s = }',num2str(mu_s(AScan2plot))],'Location','northwest')
    axis('tight','ij')
    title(['AScan at ','col = ',num2str(AScan2plot)]);
end
