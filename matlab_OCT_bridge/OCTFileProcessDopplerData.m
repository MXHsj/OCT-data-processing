function [Amplitude, Phase] = ProcessDopplerOCTData(OCTFileName, Index)
% ProcessDopplerOCTData( OCTFileName, Index )  Processes Doppler 
% data which were already acquired with ThorImageOCT and give it back as a
% Matlab matrices
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
OCTFile = calllib('SpectralRadar', 'createOCTFile', 0);

calllib('SpectralRadar', 'loadFile', OCTFile, OCTFileName);
% Probe = calllib('SpectralRadar','initProbeFromOCTFile', libpointer('voidPtrPtr',[]), OCTFile);
Probe = calllib('SpectralRadar','initProbeFromOCTFile', libpointer(), OCTFile);

RawData = calllib('SpectralRadar','createRawData');
AmplitudeData = calllib('SpectralRadar','createData');
PhaseData = calllib('SpectralRadar','createData');
ComplexData = calllib('SpectralRadar','createComplexData');
VideoImg = calllib('SpectralRadar','createColoredData');

Proc = calllib('SpectralRadar','createProcessingForOCTFile', OCTFile);
calllib('SpectralRadar','setProcessingParameterInt', Proc, 0, 3);

DopplerProc = calllib('SpectralRadar','createDopplerProcessing');
calllib('SpectralRadar','setDopplerPropertyInt', DopplerProc, 1, 3);

currentIndexInFile = calllib('SpectralRadar', 'findFileDataObject', OCTFile, ['Spectral', num2str(Index)]);
calllib('SpectralRadar', 'getFileRawData', OCTFile, RawData, currentIndexInFile);
calllib('SpectralRadar', 'setComplexDataOutput', Proc, ComplexData);
calllib('SpectralRadar', 'executeProcessing', Proc, RawData);

calllib('SpectralRadar', 'setDopplerPhaseOutput', DopplerProc, PhaseData);
calllib('SpectralRadar', 'setDopplerAmplitudeOutput', DopplerProc, AmplitudeData);
calllib('SpectralRadar', 'executeDopplerProcessing', DopplerProc, ComplexData);

%% copy the data to have access with Matlab to it directly

SizeZ = calllib('SpectralRadar','getDataPropertyInt', AmplitudeData, 1);
SizeX = calllib('SpectralRadar','getDataPropertyInt', AmplitudeData, 2);
SizeY = calllib('SpectralRadar','getDataPropertyInt', AmplitudeData, 3);
DataBuffer = libpointer('singlePtr',zeros(SizeZ * SizeX * SizeY, 1)); 
calllib('SpectralRadar','copyDataContent', AmplitudeData, DataBuffer);

Amplitude = DataBuffer.Value;
Amplitude = reshape(Amplitude, SizeZ, SizeX, SizeY);

SizeZ = calllib('SpectralRadar','getDataPropertyInt', PhaseData, 1);
SizeX = calllib('SpectralRadar','getDataPropertyInt', PhaseData, 2);
SizeY = calllib('SpectralRadar','getDataPropertyInt', PhaseData, 3);
DataBuffer = libpointer('singlePtr',zeros(SizeZ * SizeX * SizeY, 1)); 
calllib('SpectralRadar','copyDataContent', PhaseData, DataBuffer);

Phase = DataBuffer.Value;
Phase = reshape(Phase, SizeZ, SizeX, SizeY);

% clean up
calllib('SpectralRadar','clearOCTFile', OCTFile); 

calllib('SpectralRadar','clearData', AmplitudeData); 
calllib('SpectralRadar','clearData', PhaseData); 
calllib('SpectralRadar','clearComplexData', ComplexData); 
calllib('SpectralRadar','clearColoredData', VideoImg); 
calllib('SpectralRadar','clearRawData', RawData); 
calllib('SpectralRadar','clearProcessing', Proc); 
calllib('SpectralRadar','closeProbe', Probe); 

clear Probe VideoImg OCTFile ComplexData PhaseData AmplitudeData RawData DopplerProc Proc DataBuffer SizeZ SizeX SizeY;
unloadlibrary SpectralRadar 

% end