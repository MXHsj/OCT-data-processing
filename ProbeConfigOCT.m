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

% probe.y = 7.8e-3;                    % [m]
% probe.z = 2.45e-3;                   % [m]

probe.hori_res = 0.0076*1e-3;     % [m/pix]
probe.vert_res = 0.0035*1e-3;     % [m/pix]
probe.y = probe.hori_res*probe.width;
probe.z = probe.vert_res*probe.height;

% probe calibration
probe.T_flange_probe = [0.8653, -0.5011, -0.0044, 0;
                        0.5009, 0.8651, -0.0238, 0;
                        0.0061, -0.0016, 0.9997, 0;
                        0.0954, -0.0607, 0.2549, 1];
