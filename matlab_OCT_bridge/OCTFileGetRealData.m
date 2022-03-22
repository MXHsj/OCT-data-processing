function [ RealData ] = OCTFileGetRealData( handle, dataName )
% OCTFILEGETREALDATA  Get real data from .oct file.
%   data = OCTFILEGETREALDATA( handle, dataName ) Get real data from .oct file
%
%   dataName is the name of the real data file inside the OCT file. For
%   instance to access the Intensity.data file on can call
%   OCTFILEGETREALDATA( 'Intensity.data' )
%

L = length(handle.head.DataFiles.DataFile);
filepath = [];
sizes = ones(1,3);

for k = 1:L
   % Get the label element. In this file, each
   % listitem contains only one label.
   thisList = handle.head.DataFiles;
   node = thisList.DataFile{k};
   % Check whether this is the label you want.
   % The text is in the first child node.
   if ~isempty(node) && ~isempty(strfind(node.Text, dataName))
          sizes(1) = str2double(node.Attributes.SizeZ);
          try
            sizes(2) = str2double(node.Attributes.SizeX);
          end
          try
            sizes(3) = str2double(node.Attributes.SizeY);
          end
          filepath = node.Text;
       break;
   end
end
if ~isempty(strfind(dataName, 'Complex'))
    sizes(1) = 2 * sizes(1);
end
if sizes(3) == 1
   sizes = sizes(1:2);
end

fid = fopen([handle.path, filepath]);
RealData = fread(fid, prod(sizes), 'float32');
RealData = reshape(RealData, sizes);
fclose(fid);

end

