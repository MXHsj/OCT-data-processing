%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: GetScatterCoef.m
% author: Xihan Ma
% description: solve for extinction coefficient from A-scans in B-mode img
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [mu_s, a] = GetExtCoeff(BScan, intThresh, isVisualize)
if nargin == 2
    isVisualize = false;
end

% tic;
probe = ProbeConfigOCT(BScan);
res = probe.vert_res*1e3;   % change unit to [mm]
mu_s = zeros(1,size(BScan,2)); a = zeros(1,size(BScan,2));
decay_window = 200;
% ====================== fast ver. =======================
for col = 1:size(BScan,2)
    AScan = BScan(:,col);
    [peak_val, peak_ind] = max(AScan);
%     if peak_val
    % solve for Y = xB
    x = [ones(length(AScan(peak_ind:min(peak_ind+decay_window,end))),1), ...
        (1:length(AScan(peak_ind:min(peak_ind+decay_window,end))))'*res];
    if length(x) > 1 && peak_val > intThresh
        f = x\double(AScan(peak_ind:min(peak_ind+decay_window,end)));
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
    figure('Position',[1920/6,1080/5,1.5*size(BScan,2),0.5*size(BScan,1)])
    subplot(1,2,1)
    yyaxis left; 
    imagesc(BScan); colormap gray
    ylabel('image height [pix]')
    yyaxis right; 
    plot(1:length(mu_s),mu_s,'o','MarkerSize',3.5); 
    xlabel('image width [pix]')
    ylabel('extinction coefficient \mu_s [mm^{-1}]')
    ylim([mean(mu_s,'omitnan')-6*std(mu_s,'omitnan'),mean(mu_s,'omitnan')+6*std(mu_s,'omitnan')])
    title('BScan')
    
    subplot(1,2,2)
    AScan2plot = 850;
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
