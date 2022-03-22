%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: AcquireSingleVolume.m
% author: Xihan Ma
% description: acquire single B-mode OCT image, modified from 
% AcquireSingleBScanForOCTFile.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function Volume = AcquireSingleVolume(Dev, RawData, Data, Proc)

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

% get output
Volume = DataBuffer.Value;
Volume = reshape(Volume, SizeZ, SizeX, SizeY);
