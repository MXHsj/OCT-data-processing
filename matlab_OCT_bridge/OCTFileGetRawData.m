function [ RawData, Spectrum ] = OCTFileGetRawData( handle, spectrumIndex, cameraIndex)
% OCTFILEGETRAWDATA  Get spectral raw data from .oct file.
%   RawData, Spectrum = OCTFILEGETRAWDATA( handle, spectrumIndex, cameraIndex ) Get spectral raw data from .oct file
%
%   This function outputs the spectral raw data (if existing) from OCT data
%   files. SpectrumIndex describes the BScan number. To get the total number of 
%   available BScans one can call OCTFileGetNrRawData().
%   cameraIndex describes the index of the camera. It doesn't need to be
%   specified for standard systems. Only for systems with two cameras, e.g.
%   the PS-SD-OCT system the index for the second camera need to be set to
%   1. 
%   This function outputs not only the spectral raw data but also the
%   source spectrum that is measured when the galvos are in a position
%   where no signal from the object is backscattered.
%
%   See also OCTFileGetNrRawData
%
if (nargin < 3 || cameraIndex == 0)
    cameraIdxStr = '';
elseif cameraIndex == 1
    cameraIdxStr = '_Cam1';
end 

L = length(handle.head.DataFiles.DataFile);
sizes = ones(1,3);

isSigned = handle.head.Instrument.RawDataIsSigned.Text;

bbPixel = str2double(handle.head.Instrument.BytesPerPixel.Text);

dtype = 'uint8';
if bbPixel == 1
    if strcmpi(isSigned,'False')
        dtype = 'uint8';
    else
        dtype = 'int8';
    end
elseif bbPixel == 2
    if strcmpi(isSigned,'False')
        dtype = 'uint16';
    else
        dtype = 'int16';
    end
elseif bbPixel == 4
    if strcmpi(isSigned,'False')
        dtype = 'uint32';
    else
        dtype = 'int32';
    end
end

if (nargin > 2 && cameraIndex == 1)
    Offset = OCTFileGetRealData( handle, 'data\OffsetErrors_Cam1.data');
else
    Offset = OCTFileGetRealData( handle, 'data\OffsetErrors.data');
end

BinaryToElectronCountScaling = str2double( OCTFileGetProperty(handle, 'BinaryToElectronCountScaling') );

for k = 1:L
   % Get the label element. In this file, each
   % listitem contains only one label.
   thisList = handle.head.DataFiles;
   node = thisList.DataFile{k};
   
    if ~isempty(node) && strcmpi(node.Attributes.Type, 'Raw')
        if ~isempty(strfind(node.Text, ['data\Spectral', int2str(spectrumIndex),cameraIdxStr,'.data']))
            sizes(1) = str2double(node.Attributes.SizeZ);
            try
                sizes(2) = str2double(node.Attributes.SizeX);
            end
            try
                sizes(3) = str2double(node.Attributes.SizeY);
            end

            try
                numApos = str2double(node.Attributes.ApoRegionEnd0);
            catch 
                numApos = 0;
            end
            filepath = node.Text;

            if sizes(3) == 1
                sizes = sizes(1:2);
            end
            
            fid = fopen([handle.path, filepath]);
            RawData = BinaryToElectronCountScaling * double(fread(fid, sizes, dtype));
            fclose(fid);

            for l=1:size(RawData,2)
                RawData(:,l) = RawData(:,l) - Offset;
            end
    
            if (numApos == 0) % look for ApodizationSpectrum.data
                try
                    Spectrum = OCTFileGetRealData( handle, ['data\ApodizationSpectrum', cameraIdxStr, '.data']) - Offset;
                catch
                    Spectrum = mean(RawData(:,1:numApos), 2);
                end
            else
                Spectrum = mean(RawData(:,1:numApos), 2);
            end

            RawData = RawData(:,numApos+1:end);

        end
    end
end


end