classdef ClassPlotter < handle
    %PlotGroup Contains information about a plot group
    %   Detailed explanation goes here
    
    properties
        DataSource
        PlotGroups
        Settings % A ClassSettings object that holds relevant settings
        Title
        XMinGlobal
        XMaxGlobal
    end
    
    methods
        function obj = ClassPlotter(DataSource,Title,XMinGlobal,XMaxGlobal)
            %PlotStripFile Construct an instance of this class
            %   Detailed explanation goes here
            if nargin < 3; XMaxGlobal = 9999; end
            if nargin < 2; XMinGlobal = -9999; end
            obj.XMinGlobal = XMinGlobal;
            obj.XMaxGlobal = XMaxGlobal;
            obj.Settings = ClassSettings();
            obj.DataSource = DataSource;
            obj.Title = Title;
            obj.PlotGroups = {};
        end
        
        function obj = StagePlotGroups(obj)
            % Create one plotgroup and fill with linegroups from DataSource
            baseGroup = ClassPlotGroup([],obj.DataSource);
            baseGroup.XInterval = [obj.XMinGlobal,obj.XMaxGlobal];
            
            obj.PlotGroups{1} = baseGroup;
            xChannel = obj.DataSource.Channels{1};
            
            for i=2:length(obj.DataSource.Channels)
                yChannel = obj.DataSource.Channels{i};
                lineGroup = ClassLineGroup(baseGroup,obj.DataSource);
                lineGroup.AppendChannel(xChannel,yChannel, yChannel);
                baseGroup.AppendLineGroup(lineGroup);
            end
            
        end
        
        
        function obj = StagePlotGroupsFromFile(obj,paramFile)
            % Reads and parses a parameter file.
            % The parameter file consists of a decorated RELAP5 strip-request 
            % file. The decorated file can look like this:
            %
            % =RELAP5 strip-request file
            % 0000100 strip fmtout
            % 0000103 0
            % *<GROUP>
            % *Title: Mass flows
            % *yint: -9999 9998
            % 1001  mflowj    101000000
            % 1002  mflowj    103000000 * Flow at inlet
            % 1003  mflowj    105000000
            % 1004  mflowj    107000000
            % 1005  mflowj    109000000
            % 1006  mflowj    111000000
            % 1007  mflowj    113000000
            % 
            % *<GROUP>
            % *title: Pressure
            % *yoffset: -1e5
            % *yscale: 1e-5
            % *xInt: 500 900
            % 1031  p    100010000
            % 1032  p    102010000
            % *<PLOT>
            % *title: Pressure before and after valve V1
            % 1033  p    102050000
            % 1034  p    106010000
            %
            %
            
            % Create base group with global settings
            baseGroup = ClassPlotGroup([],obj.DataSource);
            baseGroup.XInterval = [obj.XMinGlobal,obj.XMaxGlobal];
            
            plotGroup = baseGroup;
            lineGroup = ClassLineGroup(plotGroup,obj.DataSource);
            obj.PlotGroups{1} = plotGroup;
            indGrp = 1;

            % Read strip-request file
            fid=fopen(paramFile);  % Öppnar parameterfil för inläsning
            run = 1;
            AddToExistingLineGroup = 0;
            while run == 1
                tline = fgetl(fid);

                % Om End-of-file
                if ~ischar(tline)
                    tline = '';
                    run = 0;
                end
                
                % Parse out first word
                [word1, rem] = strtok(tline);
                
                % Skip if empty line and also stop reading properties and 
                % lines/curves into the current linegroup and instead read
                % into the current plotgroup
                if isempty(strtrim(tline))
                    AddToExistingLineGroup = 0;
                    continue;
                end
                
                % If new group - create a new plotGroup and add it to
                % 'PlotGroups'
                if strcmpi(word1,'*<GROUP>') == 1
                    indGrp = indGrp + 1;
                    plotGroup = ClassPlotGroup(baseGroup,obj.DataSource);
                    obj.PlotGroups{indGrp} = plotGroup;
                end
                
                % If *<PLOT> is present. All settings read are considered
                % to belong to the current lineGroup instead of the current
                % plotGroup (until a blank row is read)
                if strcmpi(word1,'*<PLOT>') == 1
                    AddToExistingLineGroup = 1;
                    lineGroup = ClassLineGroup(plotGroup,obj.DataSource);
                    plotGroup.AppendLineGroup(lineGroup);
                end
                
                % Parse plot properties. Store in plotgroup if "*<PLOT> is
                % not read.
                if AddToExistingLineGroup == 0
                    plotGroup.ParseInput(tline,1);
                else
                    lineGroup.ParseInput(tline);
                end
            end
            fclose(fid);
            
            obj.GetGroupLimits();
            
        end
        
        function GetGroupLimits(obj)
            % Finds and sets the min and the max values of plotgroups
            % that uses the group-scale option -+9998
             
            for i = 1:length(obj.PlotGroups)
                plotGroup = obj.PlotGroups{i};
                
                
                for xOrY = 1:2
                    if xOrY == 1
                        if plotGroup.XInterval(1) ~= -9998 && plotGroup.XInterval(2) ~= 9998; continue; end
                        
%                         if plotGroup.XInterval(1) ~= -9998 && plotGroup.XInterval(1) ~= -9999; maxValGrp = plotGroup.XInterval(1); else; maxValGrp = -9e19; end
%                         if plotGroup.XInterval(2) ~= 9998 && plotGroup.XInterval(2) ~= 9999; minValGrp = plotGroup.XInterval(2); else; minValGrp = 9e19; end
                    else
                        if plotGroup.YInterval(1) ~= -9998 && plotGroup.YInterval(2) ~= 9998; continue; end
                    end
                    
                    minValGrp = 9e19;
                    maxValGrp = -9e19;
                    
                    fprintf('Plotgroup %d:\n',i);

                    % Loop through each linegroup in current plotgroup
                    for j = 1:length(plotGroup.LineGroups)
                        lineGroup = plotGroup.LineGroups{j};

                        % Loop through all channels in current lineGroup
                        % (usally just one)
                        for k = 1:length(lineGroup.Channels)
                            channel = lineGroup.Channels{k}{1,xOrY};
                            [minVal,maxVal] = obj.DataSource.GetMaxMin(channel);
                            if minVal < minValGrp; minValGrp = minVal; end
                            if maxVal > maxValGrp; maxValGrp = maxVal; end
                            fprintf('   Linegroup %d, ''%s'': [%f,%f]\n',j,channel,minVal,maxVal);
                        end
                    end

                    if xOrY == 1
                        if plotGroup.XInterval(1) == -9998; plotGroup.XInterval(1) = min(minValGrp,plotGroup.XInterval(2)-0.1); end
                        if plotGroup.XInterval(2) ==  9998; plotGroup.XInterval(2) = max(maxValGrp,plotGroup.XInterval(1)+0.1); end
                        fprintf('Plotgroup %d, new X limits = [%f,%f]\n',i,plotGroup.XInterval(1),plotGroup.XInterval(2));
                    else
                        if plotGroup.YInterval(1) == -9998; plotGroup.YInterval(1) = min(minValGrp,plotGroup.YInterval(2)-0.1); end
                        if plotGroup.YInterval(2) ==  9998; plotGroup.YInterval(2) = max(maxValGrp,plotGroup.YInterval(1)+0.1); end
                        fprintf('Plotgroup %d, new Y limits = [%f,%f]\n',i,plotGroup.YInterval(1),plotGroup.YInterval(2));
                    end
                    
                end
                
               
                
                
            end
            
        end
        
        
        function PlotIt(obj,Filename)
            % Loops through all plotgroups and plots all linegroups in them
            
            settingsUpperPlot = ClassSettings();
            settingsLowerPlot = ClassSettings();
            %settingsLowerPlot.LegendPosition(2) = 0.05;
            settingsLowerPlot.BoxPosition(2) = 0.05;
            
            
            page = 0;
            
            obj.PlotFigure(Filename,page,1); % Run setup to avoid artefacts for annotations
            
            anTitle = annotation(gcf,'textbox','String',obj.Title,'Position', ...
                        [0.000 0.9 1.0 .1],'HorizontalAlignment',...
                        'center','LineStyle','none','FontSize', obj.Settings.MainTitleFontSize);
            anPage = annotation(gcf,'textbox','String','Page','Position', ...
                        [0.900 0.0 0.1 .05],'HorizontalAlignment',...
                        'Left','LineStyle','none','FontSize', 10);
            
            % Loop through all plotgroups
            tstart = tic;
            for i = 1:length(obj.PlotGroups)
                plotGroup = obj.PlotGroups{i};
                
                % Loop through all linegroups in current plotgroup
                for j = 1:2:length(plotGroup.LineGroups)
                    page = page + 1;
                    
                    % Produce the upper plot
                    lineGroup = plotGroup.LineGroups{j};
                    subplot(2,1,1);
                    plotUpper = lineGroup.Plot(settingsUpperPlot);
%                     set(plotUpper,'Position',settingsUpperPlot.BoxPosition);
                    
                    % Produce the lower plot
                    if j+1 <= length(plotGroup.LineGroups)
                        lineGroup = plotGroup.LineGroups{j+1};
                        subplot(2,1,2);
                        plotLower = lineGroup.Plot(settingsLowerPlot);
%                         set(plotLower,'Position',settingsLowerPlot.BoxPosition);
                    else
                        delete(plotLower);
                    end
                    
                    set(anPage,'String',sprintf('Page %d',page));
                    
                    % Print figure
                    obj.PlotFigure(Filename,page, 0);
                end
            end
            fprintf('Elapsed time: %f seconds\n',toc(tstart));
            delete(clf);
        end
        
        
        function PlotFigure(obj,Filename,Page,Setup)
        % Print and append result to a PostScript file containing all plots.
            if Page==1
                set(gcf,'PaperUnits','centimeters')
                set(gcf,'PaperType','a3')   
                set(gcf,'PaperOrientation','landscape')
                set(gcf,'PaperPosition',[0.0 0.0 29.3046 20.2284]);
                set(gcf, 'Visible', 'off')
            end
            
            if Setup == 1
                clf;
                return; 
            end
            
            % If first page, don''t append
            if Page == 1
                print(Filename,'-dpsc','-fillpage','-loose','-r300')
            else
                print(Filename,'-dpsc','-fillpage','-loose','-r300','-append')
                if mod(Page,10) == 0
                    fprintf('     Page %d\n',Page);%
                end
            end

        end
        
        
        
        function WriteSummary(obj)
            for i = 1:length(obj.PlotGroups)
                plotGroup = obj.PlotGroups{i};
                fprintf('------<Plotgroup %d>--------\n',i);
                plotGroup.WriteSummary();
            end
        end
        
    end
end



