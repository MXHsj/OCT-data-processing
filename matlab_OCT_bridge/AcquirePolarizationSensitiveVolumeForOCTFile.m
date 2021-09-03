function[] = AcquirePSVolumeData(ProbeConfigFile, OCTFileName)
% ACQUIREPSVOLUMEDATA( ProbeConfigFile, OCTFileName )  Acquires and process polarization sensitive volume 
% data and save it as an .oct-file to the specified file.
%
%   ProbeConfigFile contains the specified Probe configuration file,
%   e.g. ProbeLSM04.ini
%   OCTFile is the path and name for the .oct-file which will be created
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

NumberCameras = 2;
% initialization of device, processing and data
Dev = calllib('SpectralRadar','initDevice');
Probe = calllib('SpectralRadar','initProbe', Dev, ProbeConfigFile);
VolumeData = calllib('SpectralRadar','createData');
VideoImg = calllib('SpectralRadar','createColoredData');
OCTFile = calllib('SpectralRadar','createOCTFile', 0);
PolProc = calllib('SpectralRadar','createPolarizationProcessing');
RetardationData = calllib('SpectralRadar','createData');
OpticalAxisData = calllib('SpectralRadar','createData');
SingleRetardationData = calllib('SpectralRadar','createData');
SingleOpticalAxisData = calllib('SpectralRadar','createData');
Data = calllib('SpectralRadar','createData');
for camIdx = 1:NumberCameras
    RawData{camIdx} = calllib('SpectralRadar','createRawData');
    CompData{camIdx} = calllib('SpectralRadar','createComplexData');
    Proc{camIdx} = calllib('SpectralRadar','createProcessingForDevice', Dev);
    CollectedCompData{camIdx} = calllib('SpectralRadar','createComplexData');
end

% creating a scan pattern
SizeY = 16;
ScanPattern = calllib('SpectralRadar','createVolumePattern', Probe, 2.0, 1024, 2.0, SizeY, 1, 0);

% starting the measurement
calllib('SpectralRadar','startMeasurement', Dev, ScanPattern, 1);
calllib('SpectralRadar','getCameraImage', Dev, VideoImg);

for y = 1:SizeY
    for camIdx = 1:NumberCameras
        % grabbing the data
        calllib('SpectralRadar','getRawDataEx', Dev, RawData{camIdx}, camIdx - 1);
        
          % processing the single data slices from one camera 
        calllib('SpectralRadar','setComplexDataOutput', Proc{camIdx}, CompData{camIdx});
        calllib('SpectralRadar','executeProcessing', Proc{camIdx}, RawData{camIdx});
        
        % adding it to the file
        if camIdx == 1 
            calllib('SpectralRadar','addFileRawData', OCTFile, RawData{camIdx}, ['data\Spectral', num2str(y -1), '.data']);
        else 
            calllib('SpectralRadar','addFileRawData', OCTFile, RawData{camIdx}, ['data\Spectral', num2str(y -1), '_Cam1.data']);
        end
        calllib('SpectralRadar','appendComplexData', CollectedCompData{camIdx}, CompData{camIdx}, 2);
    end
     % polarization processing using the data from both cameras
     calllib('SpectralRadar','setPolarizationOutputI', PolProc, Data);
     calllib('SpectralRadar','setPolarizationOutputRetardation', PolProc, SingleRetardationData);
     calllib('SpectralRadar','setPolarizationOutputOpticAxis', PolProc, SingleOpticalAxisData);
     calllib('SpectralRadar','executePolarizationProcessing', PolProc, CompData{1}, CompData{2});
     
     calllib('SpectralRadar','appendData', VolumeData, Data, 2);
     calllib('SpectralRadar','appendData', RetardationData, SingleRetardationData, 2);
     calllib('SpectralRadar','appendData', OpticalAxisData, SingleOpticalAxisData, 2);
end

% stop measurement
calllib('SpectralRadar','stopMeasurement', Dev);

% save data as a .oct file
calllib('SpectralRadar','saveCalibrationToFile', OCTFile, Proc{1});
calllib('SpectralRadar','addFileText', OCTFile, ['C:\Program Files\Thorlabs\SpectralRadar\config\', ProbeConfigFile, '.ini'], 'data\Probe.ini');
calllib('SpectralRadar','addFileRealData', OCTFile, VolumeData, 'data\Intensity.data');
calllib('SpectralRadar','addFileRealData', OCTFile, RetardationData, 'data\Retardation.data');
calllib('SpectralRadar','addFileRealData', OCTFile, OpticalAxisData, 'data\OpticalAxis.data');
calllib('SpectralRadar','addFileRealData', OCTFile, Data, 'data\PreviewImage.data');
calllib('SpectralRadar','addFileColoredData', OCTFile, VideoImg, 'data\VideoImage.data');
calllib('SpectralRadar','addFileComplexData', OCTFile, CollectedCompData{1}, 'data\Complex.data');
calllib('SpectralRadar','addFileComplexData', OCTFile, CollectedCompData{2}, 'data\Complex_Cam1.data');
calllib('SpectralRadar','setFileMetadataString', OCTFile, 5, 'ModePolarization3D');
calllib('SpectralRadar','saveFileMetadata', OCTFile, Dev, Proc{1}, Probe, ScanPattern);
calllib('SpectralRadar', 'saveFile', OCTFile, OCTFileName);

% clean up
for camIdx = 1:NumberCameras
    calllib('SpectralRadar','clearRawData', RawData{camIdx});
    calllib('SpectralRadar','clearProcessing', Proc{camIdx});
    calllib('SpectralRadar','clearComplexData', CompData{camIdx});
    calllib('SpectralRadar','clearComplexData', CollectedCompData{camIdx});
end
clear RawData Proc CompData CollectedCompData;

calllib('SpectralRadar','clearData', Data); clear Data;
calllib('SpectralRadar','clearPolarizationProcessing', PolProc); clear PolProc;
calllib('SpectralRadar','clearData', SingleRetardationData); clear SingleRetardationData;
calllib('SpectralRadar','clearData', SingleOpticalAxisData); clear SingleOpticalAxisData;
calllib('SpectralRadar','clearData', RetardationData); clear RetardationData;
calllib('SpectralRadar','clearData', OpticalAxisData); clear OpticalAxisData;
calllib('SpectralRadar','clearOCTFile', OCTFile); clear OCTFile;
calllib('SpectralRadar','clearScanPattern', ScanPattern); clear ScanPattern;
calllib('SpectralRadar','clearData', VolumeData); clear VolumeData;
calllib('SpectralRadar','clearColoredData', VideoImg); clear VideoImg;
calllib('SpectralRadar','closeProbe', Probe); clear Probe;
calllib('SpectralRadar','closeDevice', Dev); clear Dev;

unloadlibrary SpectralRadar 

end