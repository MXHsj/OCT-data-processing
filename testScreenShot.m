%% get realtime screenshots of selected window
% dependencies: python3.8, Pillow (PIL), opencv

clc; clear; close all

win_name = 'MATLAB R2021a - academic use';
hwnd = py.win32gui.FindWindow(py.None, win_name);
win_size_raw = py.win32gui.GetWindowRect(hwnd);
win_size = cellfun(@double,cell(win_size_raw));
left = py.int(py.float(win_size(1))); top = py.int(py.float(win_size(2))); 
right = py.int(py.float(win_size(3))); bot = py.int(py.float(win_size(4)));
width = py.int(py.float(right - left));
height = py.int(py.float(bot - top));

py.win32gui.SetForegroundWindow(hwnd)
hdesktop = py.win32gui.GetDesktopWindow();
hwndDC = py.win32gui.GetWindowDC(hdesktop);
mfcDC  = py.win32ui.CreateDCFromHandle(hwndDC);
saveDC = mfcDC.CreateCompatibleDC();
 
saveBitMap = py.win32ui.CreateBitmap();
saveBitMap.CreateCompatibleBitmap(mfcDC, width, height)
saveDC.SelectObject(saveBitMap);

result = saveDC.BitBlt(py.tuple({py.int(0),py.int(0)}), ...
                       py.tuple({width,height}), ...
                       mfcDC, ...
                       py.tuple({left,top}),py.win32con.SRCCOPY);

bmpinfo = saveBitMap.GetInfo();
bmpstr = saveBitMap.GetBitmapBits(py.bool(true));       

im = py.PIL.Image.frombuffer('RGB', ...
    py.tuple({bmpinfo{'bmWidth'}, bmpinfo{'bmHeight'}}), ...
    bmpstr, 'raw', 'BGRX', py.int(0), py.int(1));

im.show()
% im.save('img.png');
screen = py.list(im.getdata());

