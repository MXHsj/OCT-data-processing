%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: ThorlabsOCTDataManager.m
% author: Xihan Ma
% description: manage .oct file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [handle] = ThorlabsOCTDataManager(data_id)
addpath(genpath('matlab_OCT_bridge/'));
data_folder = '../data/';

oct_data = ...
{
    '24-Mar-2022_volume{humanA}.oct', ...   % 1
    '05-May-2022_volume{humanA}.oct'        % 2
};

handle = OCTFileOpen([data_folder,oct_data{data_id}]);

rmpath(genpath('matlab_OCT_bridge/'))