function [ PSData ] = OCTFileGetPolarizationSensitiveData( handle, PolarizationOutputSelection )
% OCTFileGetPolarizationSensitiveData  Get Parameter - Retardation, OpticAxis, DOPU or one of the Stokes Parameters Q, U or V - data from .oct file.
%   data = OCTFileGetPolarizationSensitiveData( handle, Parameter ) Get Parameter data from .oct file
%
%   handle is the data handle which can be obtained with OCTFileOpen
%
% PolarizationOutputSelection - 'Retardation', 'OpticAxis', 'DOPU', 'Q',
% 'U' or 'V' or complex data of one camera 'Complex0' or 'Complex1'


loadlibrary('SpectralRadar', 'SpectralRadar.h')

Data = calllib('SpectralRadar','createData');
ComplexData{1} = calllib('SpectralRadar','createComplexData');
ComplexData{2} = calllib('SpectralRadar','createComplexData');

OCTFile = calllib('SpectralRadar','createOCTFile', 0);
calllib('SpectralRadar','loadFile', OCTFile, handle.filename);

PolarizationProcessing = calllib('SpectralRadar','createPolarizationProcessingForFile', OCTFile);

idx = int32(calllib('SpectralRadar','findFileDataObject', OCTFile, 'Complex'));
idx2 = calllib('SpectralRadar','findFileDataObject', OCTFile, 'Complex_Cam1.data');
if (idx > -1) && (idx2 > -1)
    calllib('SpectralRadar','getFileComplexData', OCTFile, ComplexData{1}, idx);
    calllib('SpectralRadar','getFileComplexData', OCTFile, ComplexData{2}, idx2);

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
    end


    if (strcmp(PolarizationOutputSelection, 'Complex0') || strcmp(PolarizationOutputSelection, 'Complex1'))
        if (strcmp(PolarizationOutputSelection, 'Complex0'))
            cameraIdx = 0;
        elseif (strcmp(PolarizationOutputSelection, 'Complex1'))
            cameraIdx = 1;
        end 
        calllib('SpectralRadar','realComplexData', ComplexData{cameraIdx + 1}, Data); 
        
        SizeZ = calllib('SpectralRadar','getDataPropertyInt', Data, 1);
        SizeX = calllib('SpectralRadar','getDataPropertyInt', Data, 2);
        SizeY = calllib('SpectralRadar','getDataPropertyInt', Data, 3);
        
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
        calllib('SpectralRadar','executePolarizationProcessing', PolarizationProcessing, ComplexData{1}, ComplexData{2});

        SizeZ = calllib('SpectralRadar','getDataPropertyInt', Data, 1);
        SizeX = calllib('SpectralRadar','getDataPropertyInt', Data, 2);
        SizeY = calllib('SpectralRadar','getDataPropertyInt', Data, 3);

        DataBuffer = libpointer('singlePtr',zeros(SizeZ * SizeX * SizeY, 1)); 
        calllib('SpectralRadar','copyDataContent', Data, DataBuffer);

        PSData = DataBuffer.Value;
        PSData = reshape(PSData, SizeZ, SizeX, SizeY);
    end
else 
    PSData = 0;
end


calllib('SpectralRadar','clearPolarizationProcessing', PolarizationProcessing);
calllib('SpectralRadar','clearOCTFile', OCTFile);
calllib('SpectralRadar','clearComplexData', ComplexData{2});
calllib('SpectralRadar','clearComplexData', ComplexData{1});
calllib('SpectralRadar','clearData', Data);
clear idx SizeZ SizeX SizeY DataBuffer PolarizationProcessing OCTFile ComplexData Data;
unloadlibrary SpectralRadar 

end