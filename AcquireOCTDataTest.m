%% test stream data using C lib
% add path 
clc; clear; close all
addpath(genpath('C:\Program Files\Thorlabs\SpectralRadar'))

%%
ProbeConfigFile = 'C:\Program Files\Thorlabs\ThorImageOCT\DefaultSettings\ExternalProgramSettings.ini';
% OCTFileName = 'test.OCT';

% make sure the path to the directory is known from Matlab!
loadlibrary('SpectralRadar', 'SpectralRadar.h')

%% initialization of device and data
Dev = calllib('SpectralRadar','initDevice');
Probe = calllib('SpectralRadar','initProbe', Dev, ProbeConfigFile);
RawData = calllib('SpectralRadar','createRawData');
Data = calllib('SpectralRadar','createData');
% VideoImg = calllib('SpectralRadar','createColoredData');
Proc = calllib('SpectralRadar','createProcessingForDevice', Dev);
% OCTFile = calllib('SpectralRadar','createOCTFile', 0);

% creating a scan pattern with a range of 5.0mm and 1024 AScans
ScanPattern = calllib('SpectralRadar','createBScanPattern', Probe, 5.0, 1024);

%% starting the measurement
calllib('SpectralRadar','startMeasurement', Dev, ScanPattern, 0);
% calllib('SpectralRadar','getCameraImage', Dev, VideoImg);

%% real-time stream
% grabbing the data can be done as long as you want until you call
% 'stopMeasurement'
figure(1)
it = 1;
while it < 100
    tic
    calllib('SpectralRadar','getRawData', Dev, RawData);

    % processing the data
    calllib('SpectralRadar','setProcessedDataOutput', Proc, Data);
    calllib('SpectralRadar','executeProcessing', Proc, RawData);

    % copy the data to have access with Matlab to it directly
    SizeZ = calllib('SpectralRadar','getDataPropertyInt', Data, 1);
    SizeX = calllib('SpectralRadar','getDataPropertyInt', Data, 2);
    SizeY = calllib('SpectralRadar','getDataPropertyInt', Data, 3);
    DataBuffer = libpointer('singlePtr',zeros(SizeZ * SizeX * SizeY, 1)); 
    calllib('SpectralRadar','copyDataContent', Data, DataBuffer);

    % display
    BScan = DataBuffer.Value;
    BScan = reshape(BScan, SizeZ, SizeX, SizeY);
    imagesc(BScan)
    it = it + 1;
    colormap gray
    pause(1e-6)
    toc
end

%% stop measurement and clear configuration
calllib('SpectralRadar','stopMeasurement', Dev);

% save data as a .oct file
% calllib('SpectralRadar','saveCalibrationToFile', OCTFile, Proc);
% calllib('SpectralRadar','addFileRawData', OCTFile, RawData, 'data\Spectral0.data');
% calllib('SpectralRadar','addFileText', OCTFile, ['C:\Program Files\Thorlabs\SpectralRadar\config\', ProbeConfigFile, '.ini'], 'data\Probe.ini');
% calllib('SpectralRadar','addFileRealData', OCTFile, Data, 'data\Intensity.data');
% calllib('SpectralRadar','addFileRealData', OCTFile, Data, 'data\PreviewImage.data');
% calllib('SpectralRadar','addFileColoredData', OCTFile, VideoImg, 'data\VideoImage.data');
% calllib('SpectralRadar','setFileMetadataString', OCTFile, 5, 'Mode2D');
% calllib('SpectralRadar','saveFileMetadata', OCTFile, Dev, Proc, Probe, ScanPattern);
% calllib('SpectralRadar', 'saveFile', OCTFile, OCTFileName);

% % clean up
% calllib('SpectralRadar','clearOCTFile', OCTFile);
calllib('SpectralRadar','clearScanPattern', ScanPattern);
calllib('SpectralRadar','clearData', Data);
% calllib('SpectralRadar','clearColoredData', VideoImg);
calllib('SpectralRadar','clearRawData', RawData); 
calllib('SpectralRadar','clearProcessing', Proc); 
calllib('SpectralRadar','closeProbe', Probe); 
calllib('SpectralRadar','closeDevice', Dev);

clear SizeZ SizeX SizeY Dev Probe ScanPattern VideoImg DataBuffer OCTFile Data RawData Proc;
unloadlibrary SpectralRadar 
