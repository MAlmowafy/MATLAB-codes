%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A Script to interpolate ERA5 data like GNSS and get the temperature output 
% in a data structure that is similar to the output of 'get_limbsounder' 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


OUT = '/data1/marwa/GNSS/output_data/out_Era5LikeGnss/'; % output directory on the machine
ListOfYears = 2007:2023;

for Y = ListOfYears
for fileno = 365:-1:1
    
    disp(['calc file no. ',sprintf('%03d',fileno)])
    
    % Where are era5 files?

    %%% Path at the local machine
    %-----------------------------
    %fpath = 'C:\Work\MATLAB_New\ERA5\era5_raw\'; 
    %fpath = 'C:\Work\MATLAB_New\GNSS-RO\paper2-ERA5&GNSS-RO\data\datain\pwfit_data_test\';

    %%% Path on the remote machine
    %-----------------------------
    fpath = sprintf('/data3/ERA5/marwa/%04d/',Y);
    
    %%% Filename of ERA5 data
    %------------------------
    fname =  sprintf('era5_%04dd%03d.nc',Y, fileno);
    
    %disp(['ERA5: ',fname])

    % read the era5 file
     r = nph_getnet([fpath,fname]);
     %disp(minmax(r.Data.t(:)))

     data = r.Data;
     
     clear r
     
     % Convret the levs to alt
     [~,era5.Alt] = ecmwf_prs_v3(137); % data.lnsp; --> we don't need lnsp for stratosphere
     
     % This line is to define the alt range of the era5 data we downloaded  
     era5.Z = era5.Alt(data.model_level(1):data.model_level(end));
 
     % Sort the alt (it is descending according to ECMWF model levels)
     [~,zidx] = sort(era5.Z);
     
     
     % Convert ERA5 time to datetime 
     if contains(fieldnames(data),'time'); disp('yes'); else; data.time = data.valid_time; end
     referenceDate = datetime('1970-01-01 00:00:00');
     % Convert ERA5 time values to dates (new era5 data is done on seconds since 1970-01-01)
     era5Dates = referenceDate + seconds(data.time);
     date = datenum(datestr(era5Dates));
     
     
     % Add all the vars to a struct acoording to alt order from ground to 80 km
     era5.T = data.t(:,:,zidx,:);
     era5.lat = data.latitude;
     era5.lon = data.longitude;
     era5.Z = era5.Z(zidx);
     era5.date = date;
     
    %%%%%%%%%%%%%% PLOTTING Check start %%%%%%%%%%%%%%%%
    % plot to make sure everything is fine
    %
    % % % % 1. map
    % % % figure; 
    % % % load coastlines.mat
    % % % for ii = 1:7:137; pcolor(era5.lon, era5.lat, era5.T(:,:,ii,1)'); colorbar ; clim([180 300]);shading flat; title(era5.Z(ii)); hold on; plot(coastlon, coastlat, 'black', 'LineWidth',2);pause(1); end
    %
    % 2. T-prof
    % figure; plot(squeeze(mean(era5.T,[1,2,4])), era5.Z)
    %
    % now everything looks fine, we need era5 T data to be interpolated to GNSS
    % lat lon points
    %
    %%%%%%%%%%%%%%% PLOTTING Check end %%%%%%%%%%%%%%%%%%

    % Open the same date GNSS file
    
    %%% Path at the local machine
    %-----------------------------
    %gnss_path = 'C:\Work\MATLAB_New\GNSS-RO\inputdata\Aug 2010\';
    %gnss_path = 'C:\Work\MATLAB_New\GNSS-RO\paper2-ERA5&GNSS-RO\data\datain\pwfit_data_test\';
   
    %%% Path on the remote machine
    %-----------------------------
    gnss_path = sprintf('/data1/GNSS/raw_old/%04d/',Y);

    %%% Filename
    %-----------------------------
    gnss_file = sprintf('merged_ro_%04d_%03d.mat',Y,fileno);
    
    disp(['gnss: ', gnss_file])
    r = load([gnss_path, gnss_file]);

     
 
     % Keep only needed fields in our struct
     if ~isfield(r,'Temp'); r.Temp = r.T; r = rmfield(r,"T"); end
     r.Temp(r.Temp >= 400 | r.Temp <= 100)=NaN;
     
     if isfield(r,'Geopotential'); gnss = rmfield(r,{'Bend_ang','Azim','Geopotential','PTRes','MetaData'}); 
     else; gnss = rmfield(r,{'Bend_ang','Azim','PTRes','MetaData'}); end
     
     gnss.Time = r.MetaData.time;
     if size(gnss.Time,2) == 1; gnss.Time = repmat(r.MetaData.time, [1,size(gnss.Lat,2)]); end
     %gnss = outliers_fn(gnss);
     
     if size(gnss.MSL_alt,1) ==1; gnss.MSL_alt = repmat(gnss.MSL_alt, [size(gnss.Lat,1),1]); end
     
     if isfield(gnss,'Settings'); gnss = reduce_struct(gnss,190:401,{'Settings'},2); else; gnss = reduce_struct(gnss,190:401,{''},2); end
 
 
     % Interpolate the era5 data into gnss lat/lon points
     %---------------------------------------------------
     % I prefer using Corwin method since we will need the time footprint in the
     % following analysis of GWs
     
     % Corwin's method
     
     % NOTE: Sample points must be sorted in ascending order for griddedInterpolant
     [latval,latidx] = sort(era5.lat);     
     era5.T = era5.T(:,latidx,:,:);
     era5.lat = latval; 
     
     Interpolant.T = griddedInterpolant({era5.lon,era5.lat,era5.Z,era5.date},era5.T,'nearest');
     
     % Produce output grid
     Lon = double(gnss.Lon);
     Lat = double(gnss.Lat);
     alt = gnss.MSL_alt; 
     t   = double(gnss.Time);
     
     T = Interpolant.T(Lon,Lat,alt,t);
     
     % Store this new ERA5 T into a data struct similar to get_limbsounder 
 
     %%% THIS NEEDS TO BE STORED AS THE OUTPUT OF GET_LIMBSOUNDERS %%%
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %Lat  - latitude
     %Lon  - longitude, using -180 to 180 range
     %Time - time, in Matlab units
     %Temp - temperature, in K
     %Pres - pressure, in hPa
     %Alt  - height, in km
 
     data.Temp = T;
     data.Lat = Lat;
     data.Lon = Lon;
     data.Time = t;
     data.Alt = alt;
     data.Pres = double(gnss.Pres);
     
     % Save the data
  
     FolderPath = fullfile(OUT, num2str(Y)); % Uses OS-compatible separator
     if ~exist(FolderPath, 'dir')
         mkdir(FolderPath);
     end
     OutFile = fullfile(FolderPath, sprintf('ERA5_T_GNSSlike_%04dd%03d.mat', Y, fileno));

     save(OutFile,'data','-v7.3')

end
end