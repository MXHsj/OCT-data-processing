%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file name: DataManagerOCT.m
% author: Xihan Ma
% description: mannage OCT Bscans and robot pose data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function data = DataManagerOCT(data_id)

oct_data = ...
{
    '08-Sep-2021_BScan{breadboard}.mat', ...        % 1
    '09-Sep-2021_BScan{cuboid1}.mat', ...           % 2
    '09-Sep-2021_BScan{cuboid2}.mat', ...           % 3
    '09-Sep-2021_BScan{cuboid3}.mat', ...           % 4
    '09-Sep-2021_BScan{cuboid4}.mat', ...           % 5
    '10-Sep-2021_BScan{cuboid1}.mat', ...           % 6
    '10-Sep-2021_BScan{cuboid2}.mat', ...           % 7
    '10-Sep-2021_BScan{cuboid3}.mat', ...           % 8
    '10-Sep-2021_BScan{cuboid4}.mat', ...           % 9
    '10-Sep-2021_BScan{cuboid5}.mat', ...           % 10
    '10-Sep-2021_BScan{cuboid6}.mat', ...           % 11
    '10-Sep-2021_BScan{tube1}.mat', ...             % 12
    '10-Sep-2021_BScan{tube2}.mat', ...             % 13
};

pose_data = ...
{
    '08-Sep-2021_franka_pose{breadboard}.mat', ...  % 1
    '09-Sep-2021_franka_pose{cuboid1}.mat', ...     % 2
    '09-Sep-2021_franka_pose{cuboid2}.mat', ...     % 3 
    '09-Sep-2021_franka_pose{cuboid3}.mat', ...     % 4
    '09-Sep-2021_franka_pose{cuboid4}.mat', ...     % 5
    '10-Sep-2021_franka_pose{cuboid1}.mat', ...     % 6
    '10-Sep-2021_franka_pose{cuboid2}.mat', ...     % 7
    '10-Sep-2021_franka_pose{cuboid3}.mat', ...     % 8
    '10-Sep-2021_franka_pose{cuboid4}.mat', ...     % 9
    '10-Sep-2021_franka_pose{cuboid5}.mat', ...     % 10
    '10-Sep-2021_franka_pose{cuboid6}.mat', ...     % 11
    '10-Sep-2021_franka_pose{tube1}.mat', ...       % 12
    '10-Sep-2021_franka_pose{tube2}.mat', ...       % 13
};

if data_id <= length(oct_data)
    % read data
    data_folder = '../data/';
    load([data_folder,oct_data{data_id}],'BScan2save');
    load([data_folder,pose_data{data_id}],'pose2save');

    data.OCT = BScan2save;
    data.pose = pose2save;
else
    data = [];
    disp('data_id out of range');
end