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

const = (-2*10*log10(exp(1)));  % ~ -8.7

% 0->confocal PSF; 1->linear model;
modelID = 1;    
probe = ProbeConfigOCT(BScan);
res = probe.vert_res*1e3;   % change unit to [mm]
BScan = double(BScan);
mu_t = zeros(1,size(BScan,2)); amp = zeros(1,size(BScan,2));

if modelID == 0
    % ===== single scattering model =====
    % parameters:
    % p(1) -- C:    scaling constant
    % p(2) -- mu_t: attenuation coefficient
    param0 = [200, 1.0];  % initial guessing
    modelfun = @(p,z) p(1)*sqrt(exp(-2*p(2).*z));
    tic;
    for col = 1:size(BScan,2)
        AScan = BScan(:,col);
        [peak_val, peak_ind] = max(AScan);   % find peak
        if size(AScan,1)>peak_ind && peak_val>intThresh
            AScan2fit = AScan(peak_ind:min(peak_ind+window,end));
            z = (peak_ind:min(peak_ind+window,length(AScan)))'*res;
            try
                mdl = fitnlm(z,AScan2fit,modelfun,param0);
                amp(col) = mdl.Coefficients.Estimate(1);
                mu_t(col) = mdl.Coefficients.Estimate(2);
            catch
                disp('fit failed')
                amp(col) = nan; mu_t(col) = nan;
            end
        else
            amp(col) = nan; mu_t(col) = nan; 
        end
    end
    toc;
    % ================================================
elseif modelID == 1
    % ===== single scattering linear model ===== 
    for col = 1:size(BScan,2)
        AScan = BScan(:,col);
        [peak_val, peak_ind] = max(AScan);   % find peak
        AScan = 10*log10(AScan.^2);
    %     [peak_val, peak_ind] = max(AScan(AScan~=max(AScan)));   % find second peak
        % solve for Y = xB
        x = [ones(length(AScan(peak_ind:min(peak_ind+window,end))),1), ... 
            (peak_ind:min(peak_ind+window,size(AScan,1)))'*res];
        if length(x)>1 && peak_val>intThresh % && peak_ind+window<size(BScan,1)
            f = x\AScan(peak_ind:min(peak_ind+window,end));
            mu_t(col) = f(end)/const;
%             mu_s(col) = (f(end)/-8.7) / (peak_ind/size(BScan,1));   % compensate for height difference
            amp(col) = 10^(f(1)/10);
        else
            mu_t(col) = nan; amp(col) = nan;
        end
    end
    % ==========================================
end

% ==================== visualization ====================
if isVisualize
    f = figure('Position',[1920/4,1080/4,0.3*size(BScan,2),0.9*size(BScan,1)]);
    % ===== plot B-mode =====
    subplot(2,1,1); 
    colororder({'b','m'})
    yyaxis left; 
    imagesc(BScan, [0.25, 1.1]*max(BScan(:))); colormap gray
    ylabel('image height [pix]')
    yyaxis right; 
    plot(1:length(mu_t),mu_t,'.','MarkerSize',3.3); 
    xlabel('image width [pix]'); ylabel('extinction coefficient \mu_t [mm^{-1}]')
    if sum(isnan(mu_t)) < length(mu_t)
        ylim([mean(mu_t,'omitnan')-3*std(mu_t,'omitnan'),mean(mu_t,'omitnan')+3*std(mu_t,'omitnan')])
    end
    title('BScan')
    
    % ===== plot A-mode =====
    subplot(2,1,2)
    AScanInd = round(size(BScan,2)/2);
    z = (1:size(BScan,1))*res;      % z in AScan
    int = BScan(:,AScanInd);        % intensity in AScan
    [~, peak_ind] = max(int);
    z_fit = (peak_ind:min(peak_ind+window,size(BScan,1)))*res;      % z in AScan to be fitted
    if modelID == 0
        plot(z, int, 'k', 'LineWidth', 1); hold on
        int_fit = modelfun([amp(AScanInd), mu_t(AScanInd)], z_fit);       % fitted intensity
    elseif modelID == 1
        % plot(z, int, 'k', 'LineWidth', 1); hold on
        plot(z, 10*log10(int.^2), 'k', 'LineWidth', 1); hold on
        int_fit = 10*log10(amp(AScanInd))+const*mu_t(AScanInd)*z_fit;     % fitted intensity
    end
    plot(z_fit, int_fit,'r--','LineWidth',2);
    xlabel('depth (in-air) [mm]'); ylabel('[dB]');
    legend('intensity',['fitted intensity {\mu_t = }',num2str(mu_t(AScanInd))],'Location','southwest')
    grid on; axis tight
    title(['AScan at ','col = ',num2str(AScanInd)]);
%     waitfor(f)
end
