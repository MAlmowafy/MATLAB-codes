
function [TF,icycle,unified_Ep, unified_qbo] = get_QboCycleIdx(qbopath, qbofname,gwpath, gwfname, varname)

%qbofname='o_era5_uQBO_2007-2023.mat';
%qbopath='C:\Work\MATLAB_New\ERA5\ERAnew\';

%gwfname='GNSS_tropics_2007-2023_Lz0-20';
%gwpath = 'C:\Work\MATLAB_New\GNSS-RO\2007-2022\'

L = load([qbopath,qbofname]);
M = load([gwpath, gwfname]);

% get the indecies of z=25 and the boundries of the cycles

% 1. QBOs
B = smoothdata(L.Store.uQBO, 2, 'movmean', 100);
t = datetime(datestr(L.Store.date));
[~,iZ] = min(abs(L.Store.Alt-25));
TF = islocalmin(B(iZ,:),'MinSeparation',days(650),'SamplePoints',t);

% 2. GWs
gw = smoothdata(M.mergedData.(varname), 1,'movmean',100);
GW = gw';
B1 = NaN(size(GW,1),length(B));
B1(:,1:length(GW)) = GW;


%t1 = nanmean(M.mergedData.Time,2);
%[~,iZ1] = min(abs(nanmean(M.mergedData.Alt)-25));


icycle = find(TF==1);

% Initialize an empty structure
QBOcycles = struct();
X = 1:850;          %length in days of unified QBO cycle
Z = 18:40;          % altitude in km
unified_qbo = NaN(length(icycle),length(Z),length(X));
%unified_qbo = NaN(length(icycle),length(X));
unified_Ep = unified_qbo;


% For loop to create fields in the structure
for i = 1:length(icycle)-1

    % Field name based on iteration index
    field1 = ['QBOT_' num2str(i)];
    field2 = ['T_' num2str(i)];
    field3 = ['Tfake_' num2str(i)];
% % % 
    for k =1:length(Z)

        % find the altitude index for QBO and GWs
        [~,iZ] = min(abs(L.Store.Alt-Z(k)));
        [~,iZ1] = min(abs(nanmean(M.mergedData.Alt)-Z(k)));

        % Field value (for demonstration, using the iteration index)
        cyc = B(iZ,icycle(i):icycle(i+1));
        Ep_cyc = B1(iZ1,icycle(i):icycle(i+1));
        
        period = t(icycle(i):icycle(i+1));
    
        t_original = linspace(0, 1, length(cyc));
        t_unified = linspace(0, 1, length(X));

        unified_qbo(i,k,:) = interp1(t_original, cyc, t_unified, 'linear');
        unified_Ep(i,k,:) = interp1(t_original, Ep_cyc, t_unified, 'linear');
        
        
       
        %unified_qbo(i,k,:) = interp1(t_original, cyc, t_unified, 'pchip');
        %unified_Ep(i,k,:) = interp1(t_original, Ep_cyc, t_unified, 'pchip');

        %idx = isnan(unified_Ep(i,k,:));
        %unified_Ep(i,k,idx) = nan;
%         idx =  isnan(interp1(tarray,u,t_new));
%         u_newp(idx)=nan;
          
    end

  
    % Add the field to the structure
    QBOcycles.Name.(field1) = cyc;
    QBOcycles.Period.(field2) = period;
    QBOcycles.OrigT.(field3) = t_original;

end
%%
clear i k

%save([pwd,'\QBO_cycles_lookup.mat'],'QBOcycles')