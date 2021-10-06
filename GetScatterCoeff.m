%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: GetScatterCoef.m
% author: Xihan Ma
% description: solve for scattering coefficient from A-scans in B-mode img
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [mu_s, a] = GetScatterCoeff(BScan, intThresh, isVisualize)
if nargin == 2
    isVisualize = false;
end

% tic;
probe = ProbeConfigOCT(BScan);
res = probe.vert_res*1e3;   % change unit to [mm]
mu_s = zeros(1,size(BScan,2)); a = zeros(1,size(BScan,2));

% ====================== fast ver. =======================
for col = 1:size(BScan,2)
    AScan = BScan(:,col);
    [peak_val, peak_ind] = max(AScan);
%     if peak_val
    % solve for Y = xB
    x = [ones(length(AScan(peak_ind:end)),1), (1:length(AScan(peak_ind:end)))'*res];
    if length(x) > 1 && peak_val > intThresh
        f = x\double(AScan(peak_ind:end));
        mu_s(col) = f(end)/-8.7; 
        a(col) = 10^(f(1)/10);
    else
        mu_s(col) = nan; 
        a(col) = nan;
    end
end

% toc
% visualization
if isVisualize
    figure('Position',[600,400,1.2*size(BScan,2),1.2*size(BScan,1)/2])
    subplot(1,2,1)
    yyaxis left; 
    imagesc(BScan); 
    ylabel('image height [pix]')
    yyaxis right; 
    plot(1:length(mu_s),mu_s,'o','MarkerSize',3.5); 
    ylabel('scattering coefficient \mu_s [mm^{-1}]')
    xlabel('image width [pix]')
    ylim([mean(mu_s)-6*std(mu_s),mean(mu_s)+6*std(mu_s)])
    title('BScan')
    
    subplot(1,2,2)
    AScan2plot = 800;
    plot((BScan(:,AScan2plot)), (1:length(BScan(:,AScan2plot)))*res); 
    hold on
    [~, peak_ind] = max(BScan(:,AScan2plot));
    z = (peak_ind:length(BScan(:,AScan2plot)))*res;
    plot(10*log10(a(AScan2plot))-8.7*mu_s(AScan2plot)*(z-peak_ind*res),z,'--','LineWidth',2);
    ylabel('image height [mm]'); 
    xlabel('intensity [dB]')
    legend('intensity',['linear decay {\mu_s = }',num2str(mu_s(AScan2plot))],'Location','northwest')
    axis('tight','ij'); grid on
    title(['AScan at ','col = ',num2str(AScan2plot)]);
end
