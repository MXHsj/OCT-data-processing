%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: model_AScan.m
% author: Xihan Ma
% description: AScan axial attenuation modeling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all
load('generated/AScan.mat')
load('generated/BScan.mat')

%% load AScan
AScan = double(AScan); [~, peak_ind] = max(AScan);
res = 0.0035; window = 200;
z = (1:size(AScan,1))*res;

%% linear single scattering model 
z_fit = (peak_ind:min(peak_ind+window,size(AScan,1)))*res;
logAScan = 10*log10(AScan.^2);
x = [ones(length(AScan(peak_ind:min(peak_ind+window,end))),1), ... 
    (peak_ind:min(peak_ind+window,size(AScan,1)))'*res];
f = x\logAScan(peak_ind:min(peak_ind+window,end));
mu_t = f(end)/(-2*10*log10(exp(1)));
amp = 10^(f(1)/10);
AScan_fit = 10*log10(amp)-8.7*mu_t*z_fit;  % fitted intensity
residual = rms(AScan_fit' - logAScan(peak_ind:min(peak_ind+window,size(AScan,1))));
fprintf('coeff: %f, residual err: %f\n', mu_t, residual)
visAScanFit(z,logAScan,z_fit,AScan_fit)
 
%% single scattering model
% parameters:
% p(1) -- C:    scaler
% p(2) -- mu_t: attenuation coefficient
param0 = [500, 4.0];
modelfun = @(p,z) p(1)*sqrt(exp(-2*p(2).*z));
z_fit = (peak_ind:min(peak_ind+window,size(AScan,1)))*res;
mdl = fitnlm(z_fit,AScan(peak_ind:min(peak_ind+window,size(AScan,1))),modelfun,param0);
mu_t = mdl.Coefficients.Estimate(2);
AScan_fit = modelfun(mdl.Coefficients.Estimate, z_fit);   % fitted intensity
residual = rms(AScan_fit' - AScan(peak_ind:min(peak_ind+window,size(AScan,1))));
fprintf('coeff: %f, residual err: %f\n', mu_t, residual)
visAScanFit(z,AScan,z_fit,AScan_fit)

%% single scattering + confocal PSF model
% parameters:
% p(1) -- z_f:  focus location
% p(2) -- z_r:  apparent Rayleigh length
% p(3) -- mu_t: attenuation coefficient
% p(4) -- C:    scaling constant
param0 = [0.5, 1.8, 4.0, 500];
modelfun = @(p,z) p(4)*sqrt(1./(((z-p(1))/p(2)).^2+1).*exp(-2*p(3).*z));
z_fit = (peak_ind:min(peak_ind+window,size(AScan,1)))*res;
mdl = fitnlm(z_fit,AScan(peak_ind:min(peak_ind+window,size(AScan,1))),modelfun,param0);
mu_t = mdl.Coefficients.Estimate(3);
AScan_fit = modelfun(mdl.Coefficients.Estimate, z_fit);   % fitted intensity
residual = rms(AScan_fit' - AScan(peak_ind:min(peak_ind+window,size(AScan,1))));
fprintf('coeff: %f, residual err: %f\n', mu_t, residual)
visAScanFit(z,AScan,z_fit,AScan_fit)

%% depth-resolved attenuation model
BScan = double(BScan);
dmu_t = zeros(size(BScan));
for j = 1:size(BScan,2)
    AScan_temp = BScan(:,j);
    [~, ind] = max(AScan_temp);
    for i = ind:min(ind+window,length(AScan_temp)-10)
        dmu_t(i,j) = 1/(2*res)*log(1+AScan_temp(i)/sum(AScan_temp(i+1:end)));
    end
end
subplot(3,1,1)
imagesc(BScan, [0.3, 1.2].*max(BScan(:))); colormap gray;
subplot(3,1,2)
imagesc(dmu_t, [0, 0.3].*max(dmu_t(:))); colormap gray;
subplot(3,1,3)
plot(mean(dmu_t))

%% utilities
function visAScanFit(z, AScan, z_fit, AScan_fit)
    figure('Position',[1920/3, 1080/3, 800, 300])
    plot(z, AScan, 'k', 'LineWidth', 1); hold on
    plot(z_fit, AScan_fit, '--r', 'LineWidth', 2);
    patch([min(z_fit),min(z_fit),max(z_fit),max(z_fit)], ...
          [min(AScan),max(AScan),max(AScan),min(AScan)], ...
          'red','FaceAlpha',.1,'EdgeColor','none')
    xlabel('depth (in-air) [mm]'); ylabel('intensity [a.u.]');
    legend('intensity','fitted intensity','Location','southwest')
    axis tight
end
