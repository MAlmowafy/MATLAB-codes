% function to plot the subplots of CME effect on T, Tp, and Ep

function subplots_CME_saber(FileName, Var, StartDay, EndDay, MonthName, cLim, VarName)

% inputs should be: 
% 1. FileName = file name like 'SABER_CME_GW_T_092024.mat'
% 2. Var = string of variable to plot; e.g. 'Ep' 
% 3. StartDay = number indicating the starting date of the plot
% 4. EndDay = number indicating the ending date of the plot
% 5. MonthName = string for the month to plot in 3 char  e.g., 'Sep' 
% 6. cLim = colorbar limits in squarw brackets e.g., [180 300]
% 7. VarName = string on the colorbar indicating the label and the unit e.g, 'T [K]'

% FileName = 'SABER_CME_GW_T_092024.mat';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load(FileName);

Store = GWs;

LatStep = 5;
LevStep = 1;
[yi, zi] = meshgrid(-90:LatStep:90, 20:LevStep:120);

numDays = StartDay:EndDay;
nDays = numel(numDays);
nCols = 4;
nRows = ceil(nDays / nCols);

figure
t = tiledlayout(nRows, nCols, 'TileSpacing', 'compact', 'Padding', 'compact');

for i = 1:nDays
    days = numDays(i);

    timeIdx = find(nanmean(Store.Time,2) > datenum(sprintf('%0d-%03s-2024',days,MonthName)) & ...
                   nanmean(Store.Time,2) < datenum(sprintf('%0d-%03s-2024',days+1,MonthName)));

    disp(datestr(minmax(Store.Time(timeIdx))))

    Lat = Store.Lat(timeIdx,:);
    var2plot = Store.(Var)(timeIdx,:);
    Alt = Store.Alt(timeIdx,:);

    Map_day = bin2matN(2, Lat(:), Alt(:), var2plot(:), yi, zi, '@nanmean');

    ax = nexttile;
    pcolor(yi, zi, Map_day); shading interp
    title(sprintf('%03s %0d',MonthName, days))
    ylim([50 120])
    xlim([-80 80])
    xline(0, '--','LineWidth',1.5)
    ax.XTickLabelMode = 'auto';

    % Only add x-label on the bottom row
    if i > nDays - nCols
        xlabel('Latitude')
    else
        ax.XTickLabel = [];  % Hide x-tick labels
    end
    
    ylabel('Altitude [km]')
    clim(cLim)
    colormap(jet(20))
    set(gca, 'FontSize', 12)
end

% Shared colorbar
cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = VarName;