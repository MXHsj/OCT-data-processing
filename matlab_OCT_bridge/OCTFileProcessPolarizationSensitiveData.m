function [ PSData ] = OCTFileProcessPolarizationSensitiveData( handle, PolarizationOutputSelection )
% OCTFileGetPolarizationSensitiveData  Get Parameter - Retardation, OpticAxis, DOPU or one of the Stokes Parameters Q, U or V - data from .oct file.
%   data = OCTFileGetPolarizationSensitiveData( handle, Parameter ) Get Parameter data from .oct file
%
%   handle is the data handle which can be obtained with OCTFileOpen
%
% PolarizationOutputSelection - 'Retardation', 'OpticAxis', 'DOPU', 'Q',
% 'U' or 'V' ot the total intensity with 'Intensity'

loadlibrary('SpectralRadar', 'SpectralRadar.h')
SizeX = 0;
Data = calllib('SpectralRadar','createData');
RawData = calllib('SpectralRadar','createRawData');
SingleComplexData = calllib('SpectralRadar','createComplexData');
ComplexData{1} = calllib('SpectralRadar','createComplexData');
ComplexData{2} = calllib('SpectralRadar','createComplexData');

OCTFile = calllib('SpectralRadar','createOCTFile', 0);
calllib('SpectralRadar','loadFile', OCTFile, handle.filename);

PolarizationProcessing = calllib('SpectralRadar','createPolarizationProcessingForFile', OCTFile);

L = length(handle.head.DataFiles.DataFile);

for CameraIdx = 0:1
    if (CameraIdx == 0)
        cameraIdxStr = '';
    elseif CameraIdx == 1
        cameraIdxStr = '_Cam1';
    end 

    Processing{CameraIdx+1} = calllib('SpectralRadar','createProcessingForOCTFileEx', OCTFile, CameraIdx);
    SizeY = 0; indexY = 0;
    for k = 1:L
        thisList = handle.head.DataFiles;
        node = thisList.DataFile{k};
        ApoEnd = 0; SizeX = 1;

         if ~isempty(node) && strcmpi(node.Attributes.Type, 'Raw')
            if ~isempty(strfind(node.Text, ['data\Spectral', int2str(indexY),cameraIdxStr,'.data']))
                try
                    ApoEnd = str2double(node.Attributes.ApoRegionEnd0);
                end
                try
                    SizeX = str2double(node.Attributes.SizeX);
                end

                idx = int32(calllib('SpectralRadar','findFileDataObject', OCTFile, ['Spectral', int2str(indexY),cameraIdxStr]));
                calllib('SpectralRadar','getFileRawData', OCTFile, RawData, idx);

                calllib('SpectralRadar','setComplexDataOutput', Processing{CameraIdx+1}, SingleComplexData);
                calllib('SpectralRadar','executeProcessing', Processing{CameraIdx+1}, RawData);

                if (ApoEnd == SizeX)
                    indexY = indexY +1; 
                    continue;
                end
                
                SizeZ = calllib('SpectralRadar','getComplexDataPropertyInt', SingleComplexData, 1);
                SizeX = calllib('SpectralRadar','getComplexDataPropertyInt', SingleComplexData, 2);
                Size3 = calllib('SpectralRadar','getComplexDataPropertyInt', SingleComplexData, 3);
                % TODO: Fix in SDK - this should not be necessary
                calllib('SpectralRadar','resizeComplexData', SingleComplexData, SizeZ, SizeX, 1);

                calllib('SpectralRadar','appendComplexData', ComplexData{CameraIdx+1}, SingleComplexData, 2);
                SizeY = SizeY + 1;
                indexY = indexY +1;
            end
         end
    
      
    end
end

SizeZ = calllib('SpectralRadar','getComplexDataPropertyInt', ComplexData{1}, 1);
SizeX = calllib('SpectralRadar','getComplexDataPropertyInt', ComplexData{1}, 2);
Size3 = calllib('SpectralRadar','getComplexDataPropertyInt', ComplexData{1}, 3);

SizeZ2 = calllib('SpectralRadar','getComplexDataPropertyInt', ComplexData{2}, 1);
SizeX2 = calllib('SpectralRadar','getComplexDataPropertyInt', ComplexData{2}, 2);
Size32 = calllib('SpectralRadar','getComplexDataPropertyInt', ComplexData{2}, 3);

if strcmp(PolarizationOutputSelection, 'Q')
    calllib('SpectralRadar','setPolarizationOutputQ', PolarizationProcessing, Data);
elseif strcmp(PolarizationOutputSelection, 'U')
    calllib('SpectralRadar','setPolarizationOutputU', PolarizationProcessing, Data); 
elseif strcmp(PolarizationOutputSelection, 'V')
    calllib('SpectralRadar','setPolarizationOutputV', PolarizationProcessing, Data);
elseif strcmp(PolarizationOutputSelection, 'Retardation')
    calllib('SpectralRadar','setPolarizationOutputRetardation', PolarizationProcessing, Data);
elseif strcmp(PolarizationOutputSelection, 'OpticAxis')
    calllib('SpectralRadar','setPolarizationOutputOpticAxis', PolarizationProcessing, Data);
elseif strcmp(PolarizationOutputSelection, 'DOPU')
    calllib('SpectralRadar','setPolarizationOutputDOPU', PolarizationProcessing, Data);
elseif strcmp(PolarizationOutputSelection, 'Intensity')
    calllib('SpectralRadar','setPolarizationOutputI', PolarizationProcessing, Data);   
end

if (strcmp(PolarizationOutputSelection, 'Complex0') || strcmp(PolarizationOutputSelection, 'Complex1'))
    if (strcmp(PolarizationOutputSelection, 'Complex0'))
        cameraIdx = 0;
    elseif (strcmp(PolarizationOutputSelection, 'Complex1'))
        cameraIdx = 1;
    end 
    calllib('SpectralRadar','realComplexData', ComplexData{cameraIdx + 1}, Data);   
    RealBuffer = libpointer('singlePtr',zeros(SizeZ * SizeX * SizeY, 1)); 
    calllib('SpectralRadar','copyDataContent', Data, RealBuffer);
    RealData = RealBuffer.Value;
    RealData = reshape(RealData, SizeZ, SizeX, SizeY);
    
    calllib('SpectralRadar','imagComplexData', ComplexData{cameraIdx + 1}, Data);   
    ImagBuffer = libpointer('singlePtr',zeros(SizeZ * SizeX * SizeY, 1)); 
    calllib('SpectralRadar','copyDataContent', Data, ImagBuffer);
    ImagData = ImagBuffer.Value;
    ImagData = reshape(ImagData, SizeZ, SizeX, SizeY);

    PSData = complex(RealData, ImagData);
else
    calllib('SpectralRadar','executePolarizationProcessing', PolarizationProcessing, ComplexData{2}, ComplexData{1});

    SizeZ = calllib('SpectralRadar','getDataPropertyInt', Data, 1);
    SizeX = calllib('SpectralRadar','getDataPropertyInt', Data, 2);
    SizeY = calllib('SpectralRadar','getDataPropertyInt', Data, 3);

    DataBuffer = libpointer('singlePtr',zeros(SizeZ * SizeX * SizeY, 1)); 
    calllib('SpectralRadar','copyDataContent', Data, DataBuffer);

    PSData = DataBuffer.Value;
    PSData = reshape(PSData, SizeZ, SizeX, SizeY);
end
calllib('SpectralRadar','clearProcessing', Processing{1});
calllib('SpectralRadar','clearProcessing', Processing{2});
calllib('SpectralRadar','clearPolarizationProcessing', PolarizationProcessing);
calllib('SpectralRadar','clearOCTFile', OCTFile);
calllib('SpectralRadar','clearComplexData', ComplexData{2});
calllib('SpectralRadar','clearComplexData', ComplexData{1});
calllib('SpectralRadar','clearData', Data);
calllib('SpectralRadar','clearRawData', RawData);
clear idx SizeZ SizeX SizeY DataBuffer PolarizationProcessing OCTFile ComplexData SingleComplexData Data RawData Processing;
unloadlibrary SpectralRadar 

end