%% script to read and plot in a video form the data from SABER to show the NO ver related to the coronal mass ejection
% change the file name and run

% data files location: 
%                       'C:\Work\MATLAB_New\SABER\Coronal mass ejection\datain\'

% Location of videos saved:
%                   'C:\Work\MATLAB_New\SABER\Coronal mass ejection\output_vidoes'        

% Doy for May2024: 131 - 142 corresponding to days: 10 - 21 May 2024
% Doy for Sep2024: 254 - 266 corresponding to days: 10 - 21 September 2024
% Doy for Oct2024: 283 - 288 corresponding to days: 9 - 16 october 2024

% read the data
r = nph_getnet('C:\Work\MATLAB_New\SABER\Coronal mass ejection\datain\SABER_NO_ver_May2024_v2.0.nc');
%r = nph_getnet('C:\Work\MATLAB_New\SABER\Coronal mass ejection\datain\SABER_NO_ver_September2024_v2.0.nc');
%r = nph_getnet('C:\Work\MATLAB_New\SABER\Coronal mass ejection\datain\SABER_NO_ver_October2024_v2.0.nc');

% extract data struct
data = r.Data;
% extract the variables that we need
Alt = data.tpaltitude;
Lat = data.tplatitude;
Lon = data.tplongitude - 180; % change from 0:360 to -180:180
NO_ver = data.NO_ver;
%%
figure
myVideo = VideoWriter('NO_ver_May2024', 'MPEG-4'); %open video file
myVideo.FrameRate = 1;  %can adjust this, 5 - 10 works well for me
open(myVideo)

for d = 131:142
    % select the date index
    idate = find(data.date==str2double(sprintf('2024%d',d)));
    %[~,idate] = min(abs(data.date-str2double(sprintf('20240%d',d))));
    %idate=find(data.date == str2double('2024131'))
    
    % select the vars at the date index
    Alt_day = Alt(:,idate);
    Lat_day = Lat(:,idate);
    %Lon_day = Lon(:,idate);
    NO_ver_day = NO_ver(:,idate);
    
    
    % creating the map plot
    
    % define the lat, lon, alt steps
    LatStep = 10;
    LevStep = 1;
    
    % create the mesh grid
    [xi,yi] = meshgrid(-90:LatStep:90, 10:LevStep:150);
    
    % create the Map
    Map = bin2matN(2, Lat_day(:), Alt_day(:), NO_ver_day(:), xi,yi,'@nanmedian');
    
    % plot
    %figure
    v1 = [1e-9:0.5e-8:9e-8];
    newpoints=50; 
    [xq,yq] = meshgrid(...
            linspace(min(min(xi,[],2)),max(max(xi,[],2)),newpoints ),...
            linspace(min(min(yi,[],1)),max(max(yi,[],1)),newpoints )...
          );
    Map_smth = interp2(xi,yi,Map,xq,yq,'cubic');
    contourf(xq,yq,Map_smth,v1)
    colormap(jet(8))
    clim([0e-8 9e-8])
    ylim([50 150])
    colorbar
    ylabel('Height [km]')
    xlabel('Latitude')
    pause(1)
    title(['NO conc. at ', string(datetime('1-Jan-2024')+d-1)])
    frame = getframe(gcf); %get frame
    writeVideo(myVideo, frame);
end 

close(myVideo)
