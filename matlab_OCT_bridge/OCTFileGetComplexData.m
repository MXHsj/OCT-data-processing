function [ data ] = OCTFileGetComplexData( handle , cameraIndex)
% OCTFILEGETCOMPLEXDATA  Get the complex data from an .oct file.
%   data = OCTFILEGETCOMPLEXDATA( handle, dataName ) Get the intensity data from an .oct file.
%

if (nargin < 2 || cameraIndex == 0)
    cameraIdxStr = '';
elseif cameraIndex == 1
    cameraIdxStr = '_Cam1';
end 

data_orig = OCTFileGetRealData( handle, ['data\Complex', cameraIdxStr, '.data'] );
data = complex(data_orig(1:2:end, :, :), data_orig(2:2:end, :, :));
end

