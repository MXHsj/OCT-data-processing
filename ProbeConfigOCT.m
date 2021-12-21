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

probe.hori_res = 0.0076*1e-3;     % [m/pix]
probe.vert_res = 0.0035*1e-3;     % [m/pix]
% probe.y = probe.hori_res*probe.width;
% probe.z = probe.vert_res*probe.height;
probe.y = 7.80e-3;                   % 7.80 [mm]
probe.z = 2.45e-3;                   % 2.45 [mm]

% probe calibration
% OCT old end-effector: apply to data before Oct 2021
% probe.T_flange_probe = [0.8653, -0.5011, -0.0044, 0;
%                         0.5009, 0.8651, -0.0238, 0;
%                         0.0061, -0.0016, 0.9997, 0;
%                         0.0954, -0.0607, 0.2549, 1];

% OCT new end-effector
probe.T_flange_probe = [0.8653, 0.5009, 0.0061, 0.1182;
                        -0.5011, 0.8651, -0.0016, -0.0035;
                        -0.0044, -0.0238, 0.9997, 0.2430;
                        0.0000, 0.0000, 0.0000, 1.0000];
                    