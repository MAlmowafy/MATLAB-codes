%select one day
clc
%load('C:\Work\MATLAB_New\SABER\Coronal mass ejection\SABER_PWs_2012d091_Lat_[-90_90]_Lz=0-50km.mat')
load('C:\Work\MATLAB_New\SABER\Coronal mass ejection\CME_SABER_5-15May2012')
%load('C:\Work\MATLAB_New\SABER\Coronal mass ejection\CME_Temp_SABER_Sep2024.mat')
%%
myVideo = VideoWriter('CME_May2024_Tp_10-18May2024_pcolor2','MPEG-4'); %open video file
myVideo.FrameRate = 1;  %can adjust this, 5 - 10 works well for me
open(myVideo)
figure

%%
figure
for days = 10:25
    timeIdx = find(nanmean(Store.Time,2) > datenum(sprintf('%0d-Sep-2024',days)) & nanmean(Store.Time,2) < datenum(sprintf('%0d-Sep-2024',days+1)));
    disp(datestr(minmax(Store.Time(timeIdx))))
  
    Lat = Store.Lat(timeIdx,:);
    Lon = Store.Lon(timeIdx,:);
    %Ep = Store.Ep(timeIdx,:);
    %BgT = Store.BgT(timeIdx,:);
    Tp = Store.Tp(timeIdx,:);
    Alt = Store.Alt(timeIdx,:);
    time = Store.Time(timeIdx,:);
    
    LatStep = 5;
    LevStep = 1;
    
     [yi,zi] = meshgrid(-90:LatStep:90, 20:LevStep:120);

    Map_day = bin2matN(2, Lat(:), Alt(:), Tp(:), yi,zi, '@nanmean');
    pcolor(yi,zi, Map_day); shading interp
    
    title(sprintf('Saber Temp v2.0 2024 Sep %0d',days))
    ylim([50 150])
    ylabel('altitude [km]')
    xlabel('Latitude')
    %clim([50 1000])  % for Ep
    %clim([150 280])  % for BG T
    clim([-5 5])      % for Tp

    cb = colorbar;
    %cb.Label.String = 'Ep [J/Kg]';
    cb.Label.String = 'Tp [K]';
    colormap(jet(11))
    set(gca,'FontSize',12)
    hold on
    pause(1.5)
  
end 

%close(myVideo)

