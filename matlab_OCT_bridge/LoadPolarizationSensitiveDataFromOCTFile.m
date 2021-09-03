function [] = LoadPolarizationSensitiveData(OCTFile)
% LoadPolarizationSensitiveData( OCTFile )  loads an already acquired 
% .oct-file with ThorImageOCT containing processed polarization sensitive data.
%
%   OCTFile is the path and name for the .oct-file which was acquired with
%   ThorImageOCT.
%
%   To acquire such data a Polarization Sensitive system of the TEL2xxPS 
%   series is required.

handle = OCTFileOpen(OCTFile);

%%%%% read dataset properties %%%%%%

disp( OCTFileGetProperty(handle, 'AcquisitionMode') );
disp( OCTFileGetProperty(handle, 'RefractiveIndex') );
disp( OCTFileGetProperty(handle, 'Comment') );
disp( OCTFileGetProperty(handle, 'Study') );
disp( OCTFileGetProperty(handle, 'ExperimentNumber') );

%% Processed data only
% Please note that the dataset needs to contain processed data to use 
% the function 'OCTFileGetPolarizationSensitiveData' properly

%%%%% reading retardation data %%%%%%

Retardation = OCTFileGetPolarizationSensitiveData(handle, 'Retardation');

figure(1);clf;
imagesc(Retardation(:,:,1));
title('Retardation')

%%%%% reading optic axis data %%%%%%

OpticAxis = OCTFileGetPolarizationSensitiveData(handle, 'OpticAxis');

figure(2);clf;
imagesc(OpticAxis(:,:,1));
title('Optic Axis')

%%%%% reading DOPU data %%%%%%

DOPU = OCTFileGetPolarizationSensitiveData(handle, 'DOPU');

figure(3);clf;
imagesc(DOPU(:,:,1));
title('DOPU')


%% Spectral raw data only
% Please note that the dataset needs to contain spectral raw data to use 
% the function 'OCTFileProcessPolarizationSensitiveData' properly

%%%%% reprocess retardation data from an oct-file containing spectral raw data %%%%%%

Retardation = OCTFileProcessPolarizationSensitiveData(handle, 'Retardation');

figure(4);clf;
imagesc(Retardation(:,:,1));
title('Retardation')

%%%%% close OCT file (deletes temporary files) %%%%%%

OCTFileClose(handle);

end
