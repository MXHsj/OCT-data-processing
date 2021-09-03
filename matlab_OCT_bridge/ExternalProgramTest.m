% This file shows some example usage of the External Program Feature 
% in ThorImageOCT
% In ThorImageOCt following parameter needs to be inserted to run this
% script:
% Go to "Settings" -> "External Programs" -> "Add" and fill out the
% required fields.
% Name: Specify a name you want to use for this script, e.g. MatlabTest
% Command: Path of Matlab installation, e.g.
% C:\Program Files\MATLAB\R2017a\bin\matlab.exe
% Arguments: -nosplash -nodesktop -minimize -wait -r "ExternalProgramTest %f %z %x %y %i; exit"
% Format: RAW (32-bit floating point)
% Enable "Wait for process to finish", "Delete temporary file",
% "Open modified file after execution finished" and "Delete modified file"

function ExternalProgramTest(FilePathInput, SizeZ, SizeX, SizeY, FilePathOutput)
    % the sizes of the data file
    SizeZ = str2num(SizeZ);
    SizeX = str2num(SizeX);
    SizeY = str2num(SizeY);
    
    % import the file to matlab and reshape it
    fid = fopen(FilePathInput,'r');
    data = fread(fid,SizeZ * SizeX * SizeY,'float'); 
    data = reshape(data, [SizeZ, SizeX, SizeY]);
    fclose(fid);
    
    % modify the data - feel free to modify this section
    % this is a 2D gaussian filter for the xz-slices
    GaussFilter = [ 1 2 1; 2 4 2; 1 2 1] ./ 16;
    for y  = 1:SizeY
        modifiedData(:, :, y) = filter2(GaussFilter, data(:, :, y));
    end
   
    % write the modified data to the specified output file which will be
    % loaded in ThorImageOCT
    fid = fopen(FilePathOutput,'W');
    fwrite(fid, modifiedData, 'float'); 
    fclose(fid);
end

