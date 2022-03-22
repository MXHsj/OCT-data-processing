%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: LoadSpectralRadar.m
% author: Xihan Ma
% description: load the SpectralRadar C library and start measurement,
% modified from AcquireSingleBScanForOCTFile.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 
function [Dev, RawData, Data, Proc, Probe, ScanPattern] = LoadSpectralRadar(isGetVol)

% load library
addpath(genpath('C:\Program Files\Thorlabs\SpectralRadar'))
loadlibrary('SpectralRadar', 'SpectralRadar.h')

% initialization of device and data
Dev = calllib('SpectralRadar','initDevice');
ProbeConfigFile = 'C:\Program Files\Thorlabs\ThorImageOCT\DefaultSettings\ExternalProgramSettings.ini';
Probe = calllib('SpectralRadar','initProbe', Dev, ProbeConfigFile);
RawData = calllib('SpectralRadar','createRawData');
Data = calllib('SpectralRadar','createData');
% VideoImg = calllib('SpectralRadar','createColoredData');
Proc = calllib('SpectralRadar','createProcessingForDevice', Dev);

if ~isGetVol
    % lateral 5.0mm with 1024 AScans
    ScanPattern = calllib('SpectralRadar','createBScanPattern',Probe,5.0,1024);
else
%     ApoType = calllib('SpectralRadar','');
%     AcqOrder =calllib('SpectralRadar','');
    ApoType = int32(0);
    AcqOrder = int32(1);
    % lateral 5.0mm with 1024 AScans, 1024 BScans covering 5 mm are stacked
    ScanPattern = calllib('SpectralRadar','createVolumePattern', ...
        Probe, 5.0, 1024, 5.0, 1024, ApoType, AcqOrder);
end

% starting the measurement
calllib('SpectralRadar','startMeasurement', Dev, ScanPattern, 0);
% calllib('SpectralRadar','getCameraImage', Dev, VideoImg);


