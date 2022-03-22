function [ Chirp ] = OCTFileGetChirp( handle, cameraIndex )
% OCTFILEGETCHIRP Get the chirp vector in an OCT file
%   data = OCTFILEGETCHIRP( handle ) Get the chirp vector in an OCT file
%
%   The chirp vector describes the lambda to k mapping. This vector is only
%   stored in the OCT file if raw data storage is used.
%
if nargin < 2 || cameraIndex == 0
    Chirp = OCTFileGetRealData( handle, 'data\Chirp.data' );
elseif cameraIndex == 1
    Chirp = OCTFileGetRealData( handle, 'data\Chirp_Cam1.data' );
end
end

