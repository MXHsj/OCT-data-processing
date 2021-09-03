%%
clc; clear; close all;

[Dev, RawData, Data, Proc, Probe, ScanPattern] = LoadSpectralRadar();

figure
it = 1;
while it < 100
    tic

    BScan = AcquireSingleBScan(Dev, RawData, Data, Proc);

    imagesc(BScan)
    it = it + 1;
    colormap gray
    pause(1e-6)
    
    toc
end

% finish

UnloadSpectralRadar(Dev, RawData, Data, Proc, Probe, ScanPattern);
clear Dev RawData Data Proc Probe ScanPattern
unloadlibrary SpectralRadar 