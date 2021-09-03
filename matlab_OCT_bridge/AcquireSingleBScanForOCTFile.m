% example run:
% AcquireSingleBScanForOCTFile('C:\Program Files\Thorlabs\ThorImageOCT\DefaultSettings\ExternalProgramSettings.ini','test.OCT')
function[] = AcquireOCTData(ProbeConfigFile, OCTFileName)
% AcquireOCTData( ProbeConfigFile, OCTFileName )  Acquires and process polarization sensitive volume 
% data and save it as an .oct-file to the specified file.
%
%   ProbeConfigFile contains the specified Probe configuration file,
%   e.g. ProbeLSM04.ini
%   OCTFileName is the path and name for the .oct-file which will be created
%   within this script. 
%   
% This file shows some example usage of the calling the C-SDK out of 
% Matlab using the ability of Matlab of loading a C-library. 
% Please note that this is for advanced programmers only. The scripts 
% is loading a C-librabry and calling those functions directly. The handling
% with different data types and allocating memory buffers is necessary.
%
% Adding the path 'C:\Program Files\Thorlabs\SpectralRadar' to Matlab
% with "Set Path" -> "Add with Subfolders..." before running the scripts 
% is necessary. 
%
% Please use the documentation of the C-SDK for further information which
% is located at 'C:\Program Files\Thorlabs\SpectralRadar\Manual'
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% make sure the path to the directory is known from Matlab!
loadlibrary('SpectralRadar', 'SpectralRadar.h')

%% initialization of device and data
Dev = calllib('SpectralRadar','initDevice');
Probe = calllib('SpectralRadar','initProbe', Dev, ProbeConfigFile);
RawData = calllib('SpectralRadar','createRawData');
Data = calllib('SpectralRadar','createData');
VideoImg = calllib('SpectralRadar','createColoredData');
Proc = calllib('SpectralRadar','createProcessingForDevice', Dev);
OCTFile = calllib('SpectralRadar','createOCTFile', 0);

% creating a scan pattern with a range of 2.0mm and 1024 AScans
ScanPattern = calllib('SpectralRadar','createBScanPattern', Probe, 2.0, 1024);

%% starting the measurement
calllib('SpectralRadar','startMeasurement', Dev, ScanPattern, 0);
calllib('SpectralRadar','getCameraImage', Dev, VideoImg);

% grabbing the data can be done as long as you want until you call
% 'stopMeasurement'
calllib('SpectralRadar','getRawData', Dev, RawData);

% processing the data
calllib('SpectralRadar','setProcessedDataOutput', Proc, Data);
calllib('SpectralRadar','executeProcessing', Proc, RawData);

%% stop measurement
calllib('SpectralRadar','stopMeasurement', Dev);

%% copy the data to have access with Matlab to it directly
SizeZ = calllib('SpectralRadar','getDataPropertyInt', Data, 1);
SizeX = calllib('SpectralRadar','getDataPropertyInt', Data, 2);
SizeY = calllib('SpectralRadar','getDataPropertyInt', Data, 3);
DataBuffer = libpointer('singlePtr',zeros(SizeZ * SizeX * SizeY, 1)); 
calllib('SpectralRadar','copyDataContent', Data, DataBuffer);

% display
BScan = DataBuffer.Value;
BScan = reshape(BScan, SizeZ, SizeX, SizeY);

figure(1)
imagesc(BScan(:,:,1))
colormap gray
axis image

%% save data as a .oct file
calllib('SpectralRadar','saveCalibrationToFile', OCTFile, Proc);
calllib('SpectralRadar','addFileRawData', OCTFile, RawData, 'data\Spectral0.data');
calllib('SpectralRadar','addFileText', OCTFile, ['C:\Program Files\Thorlabs\SpectralRadar\config\', ProbeConfigFile, '.ini'], 'data\Probe.ini');
calllib('SpectralRadar','addFileRealData', OCTFile, Data, 'data\Intensity.data');
calllib('SpectralRadar','addFileRealData', OCTFile, Data, 'data\PreviewImage.data');
calllib('SpectralRadar','addFileColoredData', OCTFile, VideoImg, 'data\VideoImage.data');
calllib('SpectralRadar','setFileMetadataString', OCTFile, 5, 'Mode2D');
calllib('SpectralRadar','saveFileMetadata', OCTFile, Dev, Proc, Probe, ScanPattern);
calllib('SpectralRadar', 'saveFile', OCTFile, OCTFileName);

% clean up
calllib('SpectralRadar','clearOCTFile', OCTFile);
calllib('SpectralRadar','clearScanPattern', ScanPattern);
calllib('SpectralRadar','clearData', Data);
calllib('SpectralRadar','clearColoredData', VideoImg);
calllib('SpectralRadar','clearRawData', RawData); 
calllib('SpectralRadar','clearProcessing', Proc); 
calllib('SpectralRadar','closeProbe', Probe); 
calllib('SpectralRadar','closeDevice', Dev);

clear SizeZ SizeX SizeY Dev Probe ScanPattern VideoImg DataBuffer OCTFile Data RawData Proc;
unloadlibrary SpectralRadar 

end