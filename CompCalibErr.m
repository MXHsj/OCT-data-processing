%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: CompCalibErr.m
% author: Xihan Ma
% description: compensate calibration error
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function T_flange_probe_new = CompCalibErr(T_flange_probe)

rpy_flange_probe = rotm2eul(T_flange_probe(1:3,1:3));
% compensate rotation
rpy_flange_probe(1) = rpy_flange_probe(1) + 0.0;
rpy_flange_probe(2) = rpy_flange_probe(2) + 0.0;
rpy_flange_probe(3) = rpy_flange_probe(3) + 0.10;
R_flange_probe_new = eul2rotm(rpy_flange_probe);
T_flange_probe_new = T_flange_probe;
T_flange_probe_new(1:3,1:3) = R_flange_probe_new;

% compensate translation
T_flange_probe_new(1,end) = T_flange_probe(1,end) + 0.0;
T_flange_probe_new(2,end) = T_flange_probe(2,end) + 0.0;
T_flange_probe_new(3,end) = T_flange_probe(3,end) + 0.0;