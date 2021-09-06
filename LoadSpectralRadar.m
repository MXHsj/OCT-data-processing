%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: LoadSpectralRadar.m
% author: Xihan Ma
% description: load the SpectralRadar C library and start measurement,
% modified from AcquireSingleBScanForOCTFile.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 
function [Dev, RawData, Data, Proc, Probe, ScanPattern] = LoadSpectralRadar()

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

% creating a scan pattern with a range of 5.0mm and 1024 AScans
ScanPattern = calllib('SpectralRadar','createBScanPattern', Probe, 5.0, 1024);

% starting the measurement
calllib('SpectralRadar','startMeasurement', Dev, ScanPattern, 0);
% calllib('SpectralRadar','getCameraImage', Dev, VideoImg);