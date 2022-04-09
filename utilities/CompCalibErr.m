%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: CompCalibErr.m
% author: Xihan Ma
% description: compensate eef calibration error during 3D OCT registration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function T_flange_probe_new = CompCalibErr(T_flange_probe)

manualTune = true;
% =================== old eef param =================== 
% % convert rot matrix to euler angle
% rpy_flange_probe = rotm2eul(T_flange_probe(1:3,1:3));
% % compensate rotation
% rpy_flange_probe(1) = rpy_flange_probe(1) + 0.025; % rot z +0.025
% rpy_flange_probe(2) = rpy_flange_probe(2) + 0.0;   % rot y  
% rpy_flange_probe(3) = rpy_flange_probe(3) - 0.045; % rot x +0.048
% % convert euler angle to rot matrix
% R_flange_probe_new = eul2rotm(rpy_flange_probe);
% T_flange_probe_new = T_flange_probe;
% T_flange_probe_new(1:3,1:3) = R_flange_probe_new;
% % compensate translation
% T_flange_probe_new(1,end) = T_flange_probe(1,end) + 0.001;    % trans x
% T_flange_probe_new(2,end) = T_flange_probe(2,end) - 0.00028;  % trans y   
% T_flange_probe_new(3,end) = T_flange_probe(3,end) + 0.001;    % trans z

% =================== new eef param =================== 
if manualTune
    % convert rot matrix to euler angle
    rpy_flange_probe = rotm2eul(T_flange_probe(1:3,1:3));
    % compensate rotation
    rpy_flange_probe(1) = rpy_flange_probe(1) + 0.030;    % rot z +0.030
    rpy_flange_probe(2) = rpy_flange_probe(2) - 0.300;    % rot y -0.300
    rpy_flange_probe(3) = rpy_flange_probe(3) + 0.040;    % rot x +0.040
    % convert euler angle to rot matrix
    R_flange_probe_new = eul2rotm(rpy_flange_probe);
    T_flange_probe_new = T_flange_probe;
    T_flange_probe_new(1:3,1:3) = R_flange_probe_new;
    % compensate translation
    T_flange_probe_new(1,end) = T_flange_probe(1,end) + 0.0000;  % trans x 0.0057
    T_flange_probe_new(2,end) = T_flange_probe(2,end) + 0.0000;  % trans y
    T_flange_probe_new(3,end) = T_flange_probe(3,end) + 0.0050;  % trans z
else
    T_flange_probe_new = [0.9293, 0.3090, -0.2015, 0.10823;
                          -0.3680, 0.8182, -0.4412, -0.02114;
                          0.0269, 0.4649, 0.8849, 0.23727;
                          0, 0, 0, 1];
end