%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: FrankaOCTDataManager.m
% author: Xihan Ma
% description: manage OCT Bscans and robot pose data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [data, sizes] = FrankaOCTDataManager(data_id)
data_folder = '../data/';
oct_data = ...
{
    '15-Sep-2021_BScan{letters1}.mat', ...          % 1     WPI-UMASS
    '15-Sep-2021_BScan{letters2}.mat', ...          % 2
    '15-Sep-2021_BScan{letters3}.mat', ...          % 3
    '16-Sep-2021_BScan{exvivo1}.mat', ...           % 4     sliced kidney
    '16-Sep-2021_BScan{exvivo2}.mat', ...           % 5
    '16-Sep-2021_BScan{exvivo3}.mat', ...           % 6
    '16-Sep-2021_BScan{exvivo4}.mat', ...           % 7
    '16-Sep-2021_BScan{exvivo5}.mat', ...           % 8
    '16-Sep-2021_BScan{exvivo6}.mat', ...           % 9
    '22-Sep-2021_BScan{exvivo1}.mat', ...           % 10    cubic-cut kidney
    '22-Sep-2021_BScan{exvivo2}.mat', ...           % 11
    '22-Sep-2021_BScan{exvivo3}.mat', ...           % 12
    '22-Sep-2021_BScan{exvivo4}.mat', ...           % 13
    '22-Sep-2021_BScan{exvivo5}.mat', ...           % 14
    '28-Sep-2021_BScan{exvivo1}.mat', ...           % 15    entire kidney
    '28-Sep-2021_BScan{exvivo2}.mat', ...           % 16
    '28-Sep-2021_BScan{exvivo3}.mat', ...           % 17
    '28-Sep-2021_BScan{exvivo4}.mat', ...           % 18
    '28-Sep-2021_BScan{exvivo5}.mat', ...           % 19
    '08-Dec-2021_BScan{letters1}.mat', ...          % 20    WPI-UMASS
    '08-Dec-2021_BScan{letters2}.mat', ...          % 21
    '08-Dec-2021_BScan{letters3}.mat', ...          % 22
    '08-Dec-2021_BScan{breast1}.mat', ...           % 23    breast w/ rot
    '08-Dec-2021_BScan{breast2}.mat', ...           % 24    
    '08-Dec-2021_BScan{breast3}.mat', ...           % 25    
    '08-Dec-2021_BScan{breast4}.mat', ...           % 26   
    '08-Dec-2021_BScan{breast5}.mat', ...           % 27  
    '08-Dec-2021_BScan{breast6}.mat', ...           % 28  
    '08-Dec-2021_BScan{breast7}.mat', ...           % 29  
    '10-Dec-2021_BScan{slope1}.mat', ...            % 30    flat slope
    '10-Dec-2021_BScan{slope2}.mat', ...            % 31
    '10-Dec-2021_BScan{slope3}.mat', ...            % 32
    '08-Jan-2022_BScan{sliced1}.mat', ...           % 33    sliced kidney
    '08-Jan-2022_BScan{sliced2}.mat', ...           % 34
    '08-Jan-2022_BScan{sliced3}.mat', ...           % 35
    '12-Jan-2022_BScan{sliced1}.mat', ...           % 36    entire sliced kidney
    '12-Jan-2022_BScan{sliced2}.mat', ...           % 37
    '12-Jan-2022_BScan{sliced3}.mat', ...           % 38
    '12-Jan-2022_BScan{sliced4}.mat', ...           % 39
    '12-Jan-2022_BScan{sliced5}.mat', ...           % 40
    '07-Apr-2022_BScan{humanA1}.mat', ...           % 41    human kidney sample A overlap: 0.1 mm
    '07-Apr-2022_BScan{humanA2}.mat', ...           % 42
    '07-Apr-2022_BScan{humanA3}.mat', ...           % 43
    '03-May-2022_BScan{humanA1}.mat', ...           % 44    human kidney sample A overlap: 4.0 mm
    '03-May-2022_BScan{humanA2}.mat', ...           % 45
    '03-May-2022_BScan{humanA3}.mat', ...           % 46
    '03-May-2022_BScan{humanA4}.mat', ...           % 47
    '03-May-2022_BScan{humanA5}.mat', ...           % 48
    '03-May-2022_BScan{humanA6}.mat', ...           % 49
};

pose_data = ...
{
    '15-Sep-2021_franka_pose{letters1}.mat', ...    % 1     WPI-UMASS
    '15-Sep-2021_franka_pose{letters2}.mat', ...    % 2
    '15-Sep-2021_franka_pose{letters3}.mat', ...    % 3
    '16-Sep-2021_franka_pose{exvivo1}.mat', ...     % 4     sliced kidney
    '16-Sep-2021_franka_pose{exvivo2}.mat', ...     % 5
    '16-Sep-2021_franka_pose{exvivo3}.mat', ...     % 6
    '16-Sep-2021_franka_pose{exvivo4}.mat', ...     % 7
    '16-Sep-2021_franka_pose{exvivo5}.mat', ...     % 8
    '16-Sep-2021_franka_pose{exvivo6}.mat', ...     % 9
    '22-Sep-2021_franka_pose{exvivo1}.mat', ...     % 10    cubic-cut kidney
    '22-Sep-2021_franka_pose{exvivo2}.mat', ...     % 11
    '22-Sep-2021_franka_pose{exvivo3}.mat', ...     % 12
    '22-Sep-2021_franka_pose{exvivo4}.mat', ...     % 13
    '22-Sep-2021_franka_pose{exvivo5}.mat', ...     % 14
    '28-Sep-2021_franka_pose{exvivo1}.mat', ...     % 15    entire kidney
    '28-Sep-2021_franka_pose{exvivo2}.mat', ...     % 16
    '28-Sep-2021_franka_pose{exvivo3}.mat', ...     % 17
    '28-Sep-2021_franka_pose{exvivo4}.mat', ...     % 18
    '28-Sep-2021_franka_pose{exvivo5}.mat', ...     % 19
    '08-Dec-2021_franka_pose{letters1}.mat', ...    % 20    WPI-UMASS
    '08-Dec-2021_franka_pose{letters2}.mat', ...    % 21
    '08-Dec-2021_franka_pose{letters3}.mat', ...    % 22
    '08-Dec-2021_franka_pose{breast1}.mat', ...     % 23    breast w/ rot
    '08-Dec-2021_franka_pose{breast2}.mat', ...     % 24    
    '08-Dec-2021_franka_pose{breast3}.mat', ...     % 25    
    '08-Dec-2021_franka_pose{breast4}.mat', ...     % 26   
    '08-Dec-2021_franka_pose{breast5}.mat', ...     % 27  
    '08-Dec-2021_franka_pose{breast6}.mat', ...     % 28   
    '08-Dec-2021_franka_pose{breast7}.mat', ...     % 29
    '10-Dec-2021_franka_pose{slope1}.mat', ...      % 30    flat slope
    '10-Dec-2021_franka_pose{slope2}.mat', ...      % 31
    '10-Dec-2021_franka_pose{slope3}.mat', ...      % 32
    '08-Jan-2022_franka_pose{sliced1}.mat', ...     % 33    sliced kidney
    '08-Jan-2022_franka_pose{sliced2}.mat', ...     % 34
    '08-Jan-2022_franka_pose{sliced3}.mat', ...     % 35
    '12-Jan-2022_franka_pose{sliced1}.mat', ...     % 36    entire sliced kidney
    '12-Jan-2022_franka_pose{sliced2}.mat', ...     % 37
    '12-Jan-2022_franka_pose{sliced3}.mat', ...     % 38
    '12-Jan-2022_franka_pose{sliced4}.mat', ...     % 39
    '12-Jan-2022_franka_pose{sliced5}.mat', ...     % 40
    '07-Apr-2022_franka_pose{humanA1}.mat', ...     % 41    human kidney sample A overlap: 0.1 mm
    '07-Apr-2022_franka_pose{humanA2}.mat', ...     % 42
    '07-Apr-2022_franka_pose{humanA3}.mat', ...     % 43
    '03-May-2022_franka_pose{humanA1}.mat', ...     % 44    human kidney sample A overlap: 4.0 mm
    '03-May-2022_franka_pose{humanA2}.mat', ...     % 45
    '03-May-2022_franka_pose{humanA3}.mat', ...     % 46
    '03-May-2022_franka_pose{humanA4}.mat', ...     % 47
    '03-May-2022_franka_pose{humanA5}.mat', ...     % 48
    '03-May-2022_franka_pose{humanA6}.mat', ...     % 49
};

fprintf('loading %s ... \n',oct_data{data_id});
fprintf('loading %s ... \n',pose_data{data_id});
data.OCT = []; data.pose = []; sizes = 0;

tic;
for id = data_id
    if id <= length(oct_data) && id > 0
        % read data
        load([data_folder,oct_data{id}],'BScan2save');
        load([data_folder,pose_data{id}],'pose2save');
        data_tmp.OCT = BScan2save;
        data_tmp.pose = pose2save;
    else
        data_tmp = [];
        disp('data_id out of range');
    end
    data.OCT = cat(3,data.OCT,data_tmp.OCT);
    data.pose = cat(3,data.pose,data_tmp.pose);
%     sizes = cat(1,sizes,sizes(end)+size(data_tmp.OCT,3));
    sizes = cat(1,sizes,size(data_tmp.OCT,3));
end
sizes(1) = [];
fprintf('read data took %f sec\n',toc);
