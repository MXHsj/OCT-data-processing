%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: ProbeConfigOCT.m
% author: Xihan Ma
% description: mannage OCT probe configuration params
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function probe = ProbeConfigOCT(BScan)
if nargin < 1
    probe.height = 700;             % [pix]
    probe.width = 1024;             % [pix]
else
    probe.height = size(BScan,1);
    probe.width = size(BScan,2);
end

probe.y = 7.8e-3;                    % [m]
probe.z = 2.45e-3;                   % [m]

% probe.resolution = 0.0076*1e-3;     % [m/pix]
% probe.y = probe.resolution*probe.width;
% probe.z = probe.resolution*probe.height;

% probe calibration 1
% probe.T_flange_probe = [0.866,-0.5,0,0; 0.5,0.866,0,0; 0,0,1,0; 0.097,-0.059,0.2529,1]';
% probe calibration 2
probe.T_flange_probe = [0.8653, -0.5011, -0.0044, 0;
                        0.5009, 0.8651, -0.0238, 0;
                        0.0061, -0.0016, 0.9997, 0;
                        0.0954, -0.0607, 0.2549, 1];
