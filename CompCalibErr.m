%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: CompCalibErr.m
% author: Xihan Ma
% description: compensate eef calibration error during 3D OCT registration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function T_flange_probe_new = CompCalibErr(T_flange_probe)

rpy_flange_probe = rotm2eul(T_flange_probe(1:3,1:3));

% compensate rotation
% rot z +0.025
rpy_flange_probe(1) = rpy_flange_probe(1) + 0.025;  
% rot y
rpy_flange_probe(2) = rpy_flange_probe(2) + 0.0;   
% rot x +0.048
rpy_flange_probe(3) = rpy_flange_probe(3) - 0.045; 

R_flange_probe_new = eul2rotm(rpy_flange_probe);
T_flange_probe_new = T_flange_probe;
T_flange_probe_new(1:3,1:3) = R_flange_probe_new;

% compensate translation
% trans x
T_flange_probe_new(1,end) = T_flange_probe(1,end) + 0.001;  
% trans y
T_flange_probe_new(2,end) = T_flange_probe(2,end) - 0.00028;     
% trans z
T_flange_probe_new(3,end) = T_flange_probe(3,end) + 0.001;    