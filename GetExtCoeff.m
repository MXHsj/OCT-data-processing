%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: GetExtCoef.m
% author: Xihan Ma
% description: solve for extinction coefficient from A-scans in B-mode img
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [mu_s, amp] = GetExtCoeff(BScan, intThresh, window, isVisualize)
if nargin == 2
    window = 200;
    isVisualize = false;
elseif nargin == 3
    isVisualize = false;
end

% tic;
probe = ProbeConfigOCT(BScan);
res = probe.vert_res*1e3;   % change unit to [mm]
mu_s = zeros(1,size(BScan,2)); amp = zeros(1,size(BScan,2));
% ====================== fast ver. =======================
% BScan = FilterRawBScan(BScan,1);
for col = 1:size(BScan,2)
    AScan = BScan(:,col);
    [peak_val, peak_ind] = max(AScan);   % find peak
%     [peak_val, peak_ind] = max(AScan(AScan~=max(AScan)));   % find second peak for robustness
    % solve for Y = xB
    x = [ones(length(AScan(peak_ind:min(peak_ind+window,end))),1), ...
        (1:length(AScan(peak_ind:min(peak_ind+window,end))))'*res];
    if length(x)>1 && peak_val>intThresh % && peak_ind+window<size(BScan,1)
        f = x\double(AScan(peak_ind:min(peak_ind+window,end)));
        mu_s(col) = f(end)/-8.7;
%         mu_s(col) = (f(end)/-8.7) / (peak_ind/size(BScan,1));   % compensate for height difference
        amp(col) = 10^(f(1)/10);
    else
        mu_s(col) = nan;
        amp(col) = nan;
    end
end
% toc

% visualization
if isVisualize
    f = figure('Position',[1920/6,1080/5,1.5*size(BScan,2),0.5*size(BScan,1)]);
    % plot B-mode
    subplot(1,2,1)
    yyaxis left; 
    imagesc(BScan, [0 1.2*max(BScan(:))]); colormap gray
%     imagesc(FilterRawBScan(BScan,4)); colormap gray
    ylabel('image height [pix]')
    yyaxis right; 
    plot(1:length(mu_s),mu_s,'x','MarkerSize',3.3); 
    xlabel('image width [pix]')
    ylabel('extinction coefficient \mu_t [mm^{-1}]')
    if sum(isnan(mu_s)) < length(mu_s)
        ylim([mean(mu_s,'omitnan')-6*std(mu_s,'omitnan'),mean(mu_s,'omitnan')+6*std(mu_s,'omitnan')])
    end
    title('BScan')
    % plot A-mode
    subplot(1,2,2)
    AScan2plot = 1024/2;
    plot((BScan(:,AScan2plot)), (1:length(BScan(:,AScan2plot)))*res, 'LineWidth',1.3); 
    hold on
    [~, peak_ind] = max(BScan(:,AScan2plot));
    z = (peak_ind:length(BScan(:,AScan2plot)))*res;
    plot(10*log10(amp(AScan2plot))-8.7*mu_s(AScan2plot)*(z-peak_ind*res),z,'--','LineWidth',2.5);
    ylabel('image height (in-air) [mm]');
    xlabel('[dB]')
    legend('intensity',['intensity decay {\mu_s = }',num2str(mu_s(AScan2plot))],'Location','northwest')
    axis('tight','ij'); grid on
    title(['AScan at ','col = ',num2str(AScan2plot)]);
    waitfor(f)
end
