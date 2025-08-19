%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% old code to get QBO cycles in unified period
% replaced by 'get_QboCycleIx'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fpath = 'C:\Work\MATLAB_New\ERA5\ERAnew\qbo_no_disruption\';
load([fpath,'era5_uQBO_2007-2015'])

minLz = 0;
maxLz = 20;
load(['C:\Work\MATLAB_New\GNSS-RO\2007-2022\',sprintf('GNSS_tropics_2007-2022_Lz%d-%d.mat',minLz, maxLz)])

% get the indecies of z=25 and the boundries of the cycles

% 2. QBOs
B = smoothdata(Store.uQBO, 2, 'movmean', 200);
t = datetime(datestr(Store.date));
[~,iZ] = min(abs(Store.Alt-25));
TF = islocalmax(B(iZ,:),'MinSeparation',days(700),'SamplePoints',t);

% 1. GWs
B1 = smoothdata(mergedData.Ep, 1,'movmean',100);
t1 = mergedData.Time;
iZ1 = find(nanmean(mergedData.Alt)==25);


icycle = find(TF==1);

%%

% Initialize an empty structure
QBOcycles = struct();
X = 1:850;
Z = 18:40;
unified_data = NaN(length(icycle),length(Z),length(X));
%unified_Ep = unified_data;

% For loop to create fields in the structure
for i = 1:length(icycle)-1
    

    % Field name based on iteration index
    field1 = ['QBOT_' num2str(i)];
    field2 = ['T_' num2str(i)];
    field3 = ['Tfake_' num2str(i)];

    for k =1:length(Z)

        % find the altitude index for QBO and GWs
        [~,iZ] = min(abs(Store.Alt-Z(k)));
      %  iZ1 = find(nanmean(mergedData.Alt)==Z(k));

        % Field value (for demonstration, using the iteration index)
        cyc = B(iZ,icycle(i):icycle(i+1));
      %  Ep = B1(icycle(i):icycle(i+1), iZ1)';
        period = t(icycle(i):icycle(i+1));
    
        t_original = linspace(0, 1, length(cyc));
        t_unified = linspace(0, 1, length(X));
    
        unified_data(i,k,:) = interp1(t_original, cyc, t_unified, 'linear');
       % unified_Ep(i,:) = interp1(t_original, Ep, t_unified, 'linear');
    
    
    end

    % Add the field to the structure
    QBOcycles.Name.(field1) = cyc;
    QBOcycles.Period.(field2) = period;
    QBOcycles.OrigT.(field3) = t_original;

end

% Display the resulting structure
%disp(QBOcycles);


%%

[Time, Altitude] = meshgrid(X, Z);
figure; pcolor(Time, Altitude, squeeze(nanmean(unified_data)))
shading interp