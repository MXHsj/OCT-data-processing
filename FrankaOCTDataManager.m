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
    '08-Sep-2021_BScan{breadboard}.mat', ...        % 1
    '10-Sep-2021_BScan{cuboid1}.mat', ...           % 2     w/ 4 holes
    '10-Sep-2021_BScan{cuboid2}.mat', ...           % 3
    '10-Sep-2021_BScan{cuboid3}.mat', ...           % 4
    '10-Sep-2021_BScan{cuboid4}.mat', ...           % 5
    '10-Sep-2021_BScan{cuboid5}.mat', ...           % 6
    '10-Sep-2021_BScan{cuboid6}.mat', ...           % 7
    '15-Sep-2021_BScan{letters1}.mat', ...          % 8     WPI-UMASS
    '15-Sep-2021_BScan{letters2}.mat', ...          % 9
    '15-Sep-2021_BScan{letters3}.mat', ...          % 10
    '16-Sep-2021_BScan{exvivo1}.mat', ...           % 11    sliced kidney
    '16-Sep-2021_BScan{exvivo2}.mat', ...           % 12
    '16-Sep-2021_BScan{exvivo3}.mat', ...           % 13
    '16-Sep-2021_BScan{exvivo4}.mat', ...           % 14
    '16-Sep-2021_BScan{exvivo5}.mat', ...           % 15
    '16-Sep-2021_BScan{exvivo6}.mat', ...           % 16
    '22-Sep-2021_BScan{exvivo1}.mat', ...           % 17    cubic kidney
    '22-Sep-2021_BScan{exvivo2}.mat', ...           % 18
    '22-Sep-2021_BScan{exvivo3}.mat', ...           % 19
    '22-Sep-2021_BScan{exvivo4}.mat', ...           % 20
    '22-Sep-2021_BScan{exvivo5}.mat', ...           % 21
    '28-Sep-2021_BScan{exvivo1}.mat', ...           % 22    entire kidney
    '28-Sep-2021_BScan{exvivo2}.mat', ...           % 23
    '28-Sep-2021_BScan{exvivo3}.mat', ...           % 24
    '28-Sep-2021_BScan{exvivo4}.mat', ...           % 25
    '28-Sep-2021_BScan{exvivo5}.mat', ...           % 26
    '08-Dec-2021_BScan{letters1}.mat', ...          % 27    WPI-UMASS
    '08-Dec-2021_BScan{letters2}.mat', ...          % 28
    '08-Dec-2021_BScan{letters3}.mat', ...          % 29
    '08-Dec-2021_BScan{breast1}.mat', ...           % 30    breast w/ rot
    '08-Dec-2021_BScan{breast2}.mat', ...           % 31    
    '08-Dec-2021_BScan{breast3}.mat', ...           % 32    
    '08-Dec-2021_BScan{breast4}.mat', ...           % 33   
    '08-Dec-2021_BScan{breast5}.mat', ...           % 34  
    '08-Dec-2021_BScan{breast6}.mat', ...           % 35  
    '08-Dec-2021_BScan{breast7}.mat', ...           % 36  
    '11-Dec-2021_BScan{breast1}.mat', ...           % 37    breast w/ rot
    '11-Dec-2021_BScan{breast2}.mat', ...           % 38    
    '11-Dec-2021_BScan{breast3}.mat', ...           % 39
    '11-Dec-2021_BScan{letters1}.mat', ...          % 40    WPI-UMASS on slope
    '11-Dec-2021_BScan{letters2}.mat', ...          % 41
    '11-Dec-2021_BScan{letters3}.mat', ...          % 42
    '11-Dec-2021_BScan{letters4}.mat', ...          % 43
    '11-Dec-2021_BScan{letters5}.mat', ...          % 44
    '10-Dec-2021_BScan{slope1}.mat', ...            % 45    flat slope
    '10-Dec-2021_BScan{slope2}.mat', ...            % 46
    '10-Dec-2021_BScan{slope3}.mat', ...            % 47
    '13-Dec-2021_BScan{slope4}.mat', ...            % 48
    '13-Dec-2021_BScan{breast1}.mat', ...           % 49    breast w/ rot on-cart
    '13-Dec-2021_BScan{breast2}.mat', ...           % 50
    '13-Dec-2021_BScan{breast3}.mat', ...           % 51
    '13-Dec-2021_BScan{breast4}.mat', ...           % 52
    '08-Jan-2022_BScan{sliced1}.mat', ...           % 53    sliced kidney
    '08-Jan-2022_BScan{sliced2}.mat', ...           % 54
    '08-Jan-2022_BScan{sliced3}.mat', ...           % 55
    '12-Jan-2022_BScan{sliced1}.mat', ...           % 56    large sliced kidney
    '12-Jan-2022_BScan{sliced2}.mat', ...           % 57
    '12-Jan-2022_BScan{sliced3}.mat', ...           % 58
    '12-Jan-2022_BScan{sliced4}.mat', ...           % 59
    '12-Jan-2022_BScan{sliced5}.mat', ...           % 60
};

pose_data = ...
{
    '08-Sep-2021_franka_pose{breadboard}.mat', ...  % 1
    '10-Sep-2021_franka_pose{cuboid1}.mat', ...     % 2
    '10-Sep-2021_franka_pose{cuboid2}.mat', ...     % 3
    '10-Sep-2021_franka_pose{cuboid3}.mat', ...     % 4
    '10-Sep-2021_franka_pose{cuboid4}.mat', ...     % 5
    '10-Sep-2021_franka_pose{cuboid5}.mat', ...     % 6
    '10-Sep-2021_franka_pose{cuboid6}.mat', ...     % 7
    '15-Sep-2021_franka_pose{letters1}.mat', ...    % 8
    '15-Sep-2021_franka_pose{letters2}.mat', ...    % 9
    '15-Sep-2021_franka_pose{letters3}.mat', ...    % 10
    '16-Sep-2021_franka_pose{exvivo1}.mat', ...     % 11
    '16-Sep-2021_franka_pose{exvivo2}.mat', ...     % 12
    '16-Sep-2021_franka_pose{exvivo3}.mat', ...     % 13
    '16-Sep-2021_franka_pose{exvivo4}.mat', ...     % 14
    '16-Sep-2021_franka_pose{exvivo5}.mat', ...     % 15
    '16-Sep-2021_franka_pose{exvivo6}.mat', ...     % 16
    '22-Sep-2021_franka_pose{exvivo1}.mat', ...     % 17
    '22-Sep-2021_franka_pose{exvivo2}.mat', ...     % 18
    '22-Sep-2021_franka_pose{exvivo3}.mat', ...     % 19
    '22-Sep-2021_franka_pose{exvivo4}.mat', ...     % 20
    '22-Sep-2021_franka_pose{exvivo5}.mat', ...     % 21
    '28-Sep-2021_franka_pose{exvivo1}.mat', ...     % 22
    '28-Sep-2021_franka_pose{exvivo2}.mat', ...     % 23
    '28-Sep-2021_franka_pose{exvivo3}.mat', ...     % 24
    '28-Sep-2021_franka_pose{exvivo4}.mat', ...     % 25
    '28-Sep-2021_franka_pose{exvivo5}.mat', ...     % 26
    '08-Dec-2021_franka_pose{letters1}.mat', ...    % 27    WPI-UMASS
    '08-Dec-2021_franka_pose{letters2}.mat', ...    % 28
    '08-Dec-2021_franka_pose{letters3}.mat', ...    % 29
    '08-Dec-2021_franka_pose{breast1}.mat', ...     % 30    breast w/ rot
    '08-Dec-2021_franka_pose{breast2}.mat', ...     % 31    
    '08-Dec-2021_franka_pose{breast3}.mat', ...     % 32    
    '08-Dec-2021_franka_pose{breast4}.mat', ...     % 33   
    '08-Dec-2021_franka_pose{breast5}.mat', ...     % 34  
    '08-Dec-2021_franka_pose{breast6}.mat', ...     % 35   
    '08-Dec-2021_franka_pose{breast7}.mat', ...     % 36
    '11-Dec-2021_franka_pose{breast1}.mat', ...     % 37    breast w/ rot
    '11-Dec-2021_franka_pose{breast2}.mat', ...     % 38    
    '11-Dec-2021_franka_pose{breast3}.mat', ...     % 39
    '11-Dec-2021_franka_pose{letters1}.mat', ...    % 40    WPI-UMASS on slope
    '11-Dec-2021_franka_pose{letters2}.mat', ...    % 41
    '11-Dec-2021_franka_pose{letters3}.mat', ...    % 42
    '11-Dec-2021_franka_pose{letters4}.mat', ...    % 43
    '11-Dec-2021_franka_pose{letters5}.mat', ...    % 44
    '10-Dec-2021_franka_pose{slope1}.mat', ...      % 45    flat slope
    '10-Dec-2021_franka_pose{slope2}.mat', ...      % 46
    '10-Dec-2021_franka_pose{slope3}.mat', ...      % 47
    '13-Dec-2021_franka_pose{slope4}.mat', ...      % 48
    '13-Dec-2021_franka_pose{breast1}.mat', ...     % 49    breast w/o rot on-cart
    '13-Dec-2021_franka_pose{breast2}.mat', ...     % 50
    '13-Dec-2021_franka_pose{breast3}.mat', ...     % 51
    '13-Dec-2021_franka_pose{breast4}.mat', ...     % 52
    '08-Jan-2022_franka_pose{sliced1}.mat', ...     % 53    sliced kidney
    '08-Jan-2022_franka_pose{sliced2}.mat', ...     % 54
    '08-Jan-2022_franka_pose{sliced3}.mat', ...     % 55
    '12-Jan-2022_franka_pose{sliced1}.mat', ...     % 56    large sliced kidney
    '12-Jan-2022_franka_pose{sliced2}.mat', ...     % 57
    '12-Jan-2022_franka_pose{sliced3}.mat', ...     % 58
    '12-Jan-2022_franka_pose{sliced4}.mat', ...     % 59
    '12-Jan-2022_franka_pose{sliced5}.mat', ...     % 60
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
