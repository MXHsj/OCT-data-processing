%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: LoadSpectralRadar.m
% author: Xihan Ma
% description: stop measurement and unload the SpectralRadar C library,
% modified from AcquireSingleBScanForOCTFile.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function UnloadSpectralRadar(Dev, RawData, Data, Proc, Probe, ScanPattern)

% stop measurement and clear configuration
calllib('SpectralRadar','stopMeasurement', Dev);

% clean up
calllib('SpectralRadar','clearScanPattern', ScanPattern);
calllib('SpectralRadar','clearData', Data);
% calllib('SpectralRadar','clearColoredData', VideoImg);
calllib('SpectralRadar','clearRawData', RawData); 
calllib('SpectralRadar','clearProcessing', Proc); 
calllib('SpectralRadar','closeProbe', Probe); 
calllib('SpectralRadar','closeDevice', Dev);

% unloadlibrary SpectralRadar 