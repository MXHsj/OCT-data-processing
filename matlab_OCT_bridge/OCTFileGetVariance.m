function [ Variance ] = OCTFileGetVariance( handle )
% OCTFILEGETVARIANCE  Get the variance data from an .oct file.
%   data = OCTFILEGETVARIANCE( handle, dataName ) Get the variance data from an .oct file.
%
    Variance = OCTFileGetRealData( handle, 'data\Variance.data' );
end

