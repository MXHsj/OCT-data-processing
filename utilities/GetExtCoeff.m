%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: GetExtCoef.m
% author: Xihan Ma
% description: solve for extinction coefficient from A-scans in B-mode img
% using single scattering model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [mu_t, amp] = GetExtCoeff(BScan, intThresh, window, isVisualize)
if nargin == 2
    window = 200;
    isVisualize = false;
elseif nargin == 3
    isVisualize = false;
end

modelID = 1;    % 0->linear model; 1->confocal PSF
probe = ProbeConfigOCT(BScan);
res = probe.vert_res*1e3;   % change unit to [mm]
% BScan = FilterRawBScan(BScan,1);
BScan = double(BScan);
mu_t = zeros(1,size(BScan,2)); amp = zeros(1,size(BScan,2));

if modelID == 0
    % ===== single scattering confocal PSF model =====
    % UNFINISHED
    % parameters:
    % p(1) -- z_f:  focus location
    % p(2) -- z_r:  apparent Rayleigh length
    % p(3) -- mu_t: attenuation coefficient
    % p(4) -- C:    scaling constant
    param0 = [1.0, 2.0, 4.0, 1.0];  % initial guessing
    modelfun = @(p, z) log(1./(((z-p(1))/p(2)).^2+1)) + log(p(4)) - 2*p(3)*z;
    for col = 1:size(BScan,2)
        AScan = BScan(:,col);
        [peak_val, peak_ind] = max(AScan);   % find peak
        if size(AScan,1)-50>peak_ind && peak_val>intThresh
            AScan2fit = AScan(peak_ind:min(peak_ind+window,end));
            z = (peak_ind:min(peak_ind+window,length(AScan)))'*res;
            mdl = fitnlm(z,AScan2fit,modelfun,param0);
            mu_t(col) = mdl.Coefficients.Estimate(3);
        else
            mu_t(col) = nan;
        end
%         plot(z,AScan2fit,z,modelfun(mdl.Coefficients.Estimate,z))
        disp(col);
    end
    
    % ================================================
    
elseif modelID == 1
    % ===== single scattering linear model =====
    for col = 1:size(BScan,2)
        AScan = BScan(:,col);  % I(z) = exp(-2uz)
        [peak_val, peak_ind] = max(AScan);   % find peak
    %     [peak_val, peak_ind] = max(AScan(AScan~=max(AScan)));   % find second peak
        % solve for Y = xB
        x = [ones(length(AScan(peak_ind:min(peak_ind+window,end))),1), ... 
            (peak_ind:min(peak_ind+window,size(AScan,1)))'*res];
%         (1:length(AScan(peak_ind:min(peak_ind+window,end))))'*res];
        if length(x)>1 && peak_val>intThresh % && peak_ind+window<size(BScan,1)
            f = x\AScan(peak_ind:min(peak_ind+window,end));
            mu_t(col) = f(end)/-8.7;
    %         mu_s(col) = (f(end)/-8.7) / (peak_ind/size(BScan,1));   % compensate for height difference
            amp(col) = 10^(f(1)/10);
        else
            mu_t(col) = nan;
            amp(col) = nan;
        end
    end
    % ==========================================
end

% ==================== visualization ====================
if isVisualize
    f = figure('Position',[1920/6,1080/5,0.5*size(BScan,2),0.5*size(BScan,1)]);
    % plot B-mode
    subplot(1,2,1); 
    colororder({'b','m'})
    yyaxis left; 
    imagesc(BScan, [0.25, 1.1]*max(BScan(:))); colormap gray
%     imagesc(FilterRawBScan(BScan,4)); colormap gray
    ylabel('image height [pix]')
    yyaxis right; 
    plot(1:length(mu_t),mu_t,'.','MarkerSize',3.3); 
    xlabel('image width [pix]'); ylabel('extinction coefficient \mu_t [mm^{-1}]')
    if sum(isnan(mu_t)) < length(mu_t)
        ylim([mean(mu_t,'omitnan')-4*std(mu_t,'omitnan'),mean(mu_t,'omitnan')+4*std(mu_t,'omitnan')])
    end
    title('BScan')
    
    % plot A-mode
    subplot(1,2,2)
    AScanInd = round(size(BScan,2)/2);
    z = (1:size(BScan,1))*res;      % z in AScan
    int = BScan(:,AScanInd);                    % intensity in AScan
    plot(z, int, 'k', 'LineWidth', 1); hold on
    [~, peak_ind] = max(int);
    z_fit = (peak_ind:min(peak_ind+window,size(BScan,1)))*res;                  % z in AScan to be fitted
    int_fit = 10*log10(amp(AScanInd))-8.7*mu_t(AScanInd)*(z_fit-peak_ind*res);  % fitted intensity
    plot(z_fit, int_fit,'r--','LineWidth',2);
    patch([min(z_fit),min(z_fit),max(z_fit),max(z_fit)],[min(int),max(int),max(int),min(int)], ...
          'red','FaceAlpha',.1,'EdgeColor','none')
    xlabel('image height (in-air) [mm]'); ylabel('[dB]');
    legend('intensity',['intensity decay {\mu_s = }',num2str(mu_t(AScanInd))],'Location','southwest') 
    grid on; axis tight
    title(['AScan at ','col = ',num2str(AScanInd)]);
%     waitfor(f)
end
