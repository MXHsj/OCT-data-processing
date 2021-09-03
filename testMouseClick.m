%% use python win32api to detect mouse click
clc;
clear;
close all

% mouse left 0x01
% mouse right 0x02
% mouse up -> 0/1
% mouse down -> -127/-128

% display -> 1080*1920
% 2D record button -> 168*76

last_left = py.win32api.GetKeyState(0x01);
isStartRecord = false;
startRecordTime = -inf;
endRecordTime = -inf;
btnHoriMar = 25;
btnVertMar = 50;

freq = 20;
rate = rateControl(freq);

while true
    curr_time = rate.TotalElapsedTime;
    curr_left = py.win32api.GetKeyState(0x01);
    if curr_left ~= last_left     % mouse state change
        last_left = curr_left;
        if curr_left < 0
            disp('mouse clicked')              
            cursor_pos_raw = py.win32api.GetCursorPos();
            cursor_pos = cellfun(@double,cell(cursor_pos_raw));
            if abs(cursor_pos(1)-168)<=btnHoriMar && ...
                    abs(cursor_pos(2)-76)<=btnVertMar
                if ~isStartRecord
                    isStartRecord = true;
                    disp('OCT start recording')
                    startRecordTime = curr_time;
                else
                    isStartRecord = false;
                    disp('OCT end recording')
                    endRecordTime = curr_time;
                end
            end
        else
            disp('mouse released')
        end
    end
    waitfor(rate);
end
