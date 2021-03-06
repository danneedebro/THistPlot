classdef ClassLineGroup < handle & ClassPlotGroup
    % Contains information about a collection of lines in a plot
    
    properties
        Channels    % A cell array with the channel names
        Legends     % A cell array with the channel description
        PlotGroup   % A ClassPlotGroup object with plotgroup properties
    end
    
    methods
        function obj = ClassLineGroup(PlotGroup,DataSource)
            % Creates a ClassLineGroup object
            obj.PlotGroup = PlotGroup;
            obj.Legends = {};
            obj.Channels = {};

            obj.DataSource = DataSource;
            
            obj.XInterval = PlotGroup.XInterval;
            obj.YInterval = PlotGroup.YInterval;
            obj.YSpanMin = PlotGroup.YSpanMin;
            obj.Title = PlotGroup.Title;
            obj.YScale = PlotGroup.YScale;
            obj.YOffset = PlotGroup.YOffset;
            obj.YOffsetFirst = PlotGroup.YOffsetFirst;
            obj.XLabel = PlotGroup.XLabel;
            obj.YLabel = PlotGroup.YLabel;
            obj.XTickFormat = PlotGroup.XTickFormat;
            obj.YTickFormat = PlotGroup.YTickFormat;
            obj.XYLabelDefaults = PlotGroup.XYLabelDefaults;
            obj.ConstantLines = PlotGroup.ConstantLines;
            obj.VLines = PlotGroup.VLines;
            obj.HLines = PlotGroup.HLines;
            obj.ChannelDefaults = PlotGroup.ChannelDefaults;
        end
        
        function handleAxes = Plot(obj,settings)
            % Plots the channels in the with specified plot properties
            cla;
            
            obj.FixProperties();
            
            colors = settings.Colors1;
            N = length(obj.Channels);
            N2 = length(obj.ConstantLines);
            N3 = length(obj.VLines);
            lines = zeros(1,N+N2);
            legendArr = {};
            legendInd = [];
            
            
            for i = 1:N
                xChannel = obj.Channels{i}{1,1};
                yChannel = obj.Channels{i}{1,2};
                description = obj.Legends{i};
                legendArr{end+1} = description;
                legendInd(end+1) = i;
                
                % Try getting data to plot
                try
                    x = obj.DataSource.GetValues(xChannel);
                    y = obj.DataSource.GetValues(yChannel);
                    
                    if isempty(x) || isempty(y)
                        fprintf('Error: Failed reading x- or y-values for ''%s''\n',yChannel);
                        x = 0;
                        y = 0;
                    end
                catch ME
                    x = 0;
                    y = 0;
                    fprintf('Error: Unexpected error reading: ''%s''\n       ''%s''',yChannel,ME.message);
                end
                
                % Scale y
                if obj.YOffsetFirst ==1
                    y = (y + obj.YOffset)*obj.YScale;
                else
                    y = y*obj.YScale + obj.YOffset;
                end
                
                if i > 1; hold on; end
                lines(i) = plot(x,y);
                set(lines(i),'Color',colors{i},'LineWidth',1.5);
                
%                 legend(lines(i),obj.Legends{i},'FontSize',settings.LegendFontSize,'Box',settings.LegendBox);
            end
            
            % Loop through all constant lines and plot them
            hold on;
            for i = 1:N2
                val = obj.ConstantLines{i}{1,1};
                description = obj.ConstantLines{i}{1,2};
                legendArr{end+1} = description;
                if ~isempty(description); legendInd(end+1) = N+i; end
                
                lines(N+i)=plot([x(1),x(length(x))],[val,val]);
                set(lines(N+i),'Color',colors{i},'LineWidth',settings.LineWidth,'LineStyle','--');
            end
            
            
            
            handleAxes = get(lines(1),'Parent');
            
            handleTitle = get(handleAxes,'Title');
            %handleLegend = get(handleAxes,'Legend');
            handleYLabel = get(handleAxes,'YLabel');
            handleXLabel = get(handleAxes,'XLabel');
            
            % Set trivial things
            set(handleTitle,'String',obj.Title,'FontSize',settings.PlotTitleFontSize);
            set(handleYLabel,'String',obj.YLabel,'FontSize',settings.YLabelFontSize);
            set(handleXLabel,'String',obj.XLabel,'FontSize',settings.XLabelFontSize);
            set(handleAxes,'LineWidth',settings.BoxLineWidth,'XGrid',settings.XGrid,'YGrid',settings.YGrid);
            
            % Set axes position
            set(handleAxes,'Position',settings.BoxPosition);
            
            
            % Set and X-interval
            setXLim = false;
            xIntAuto = get(handleAxes,'XLim');
            xInt = xIntAuto;
            if obj.XInterval(1) ~= -9999; xInt(1) = obj.XInterval(1); end
            if obj.XInterval(2) ~= 9999; xInt(2) = obj.XInterval(2); end
            
            set(handleAxes,'XLim',xInt)
            
            % Set Y-interval
            setYLim = false;
            yIntAuto = get(handleAxes,'YLim');
            yInt = yIntAuto;
            if obj.YInterval(1) ~= -9999; yInt(1) = obj.YInterval(1); end
            if obj.YInterval(2) ~= 9999; yInt(2) = obj.YInterval(2); end
            if ~isempty(obj.YSpanMin) && diff(yInt) < obj.YSpanMin
                meanVal = mean(yInt);
                yInt(1) = meanVal - obj.YSpanMin/2;
                yInt(2) = meanVal + obj.YSpanMin/2;
            end
            
            try
                set(handleAxes,'YLim',yInt)
            catch ME
                fprintf('Error: setting ''YLim''=[%f,%f] for ''%s''.\n',yInt(1),yInt(2),obj.Channels{1}{1,2});
            end
            
            % Loop through all vertical lines
            for i = 1:N3
                value = obj.VLines{i}{1,1};
                description = obj.VLines{i}{1,2};
                    
                legendArr{end+1} = description;
                if ~isempty(description); legendInd(end+1) = N+N2+i; end
                lines(N+N2+i)=plot([value,value],yInt);
                set(lines(N+N2+i),'Color',colors{i},'LineWidth',settings.LineWidth,'LineStyle','--');
            end
            
            hold off;
            
            
            
            % Set legend settings
            handleLegend = legend(lines(legendInd),legendArr(legendInd),'FontSize',settings.LegendFontSize,'Box',settings.LegendBox);
            if ~isempty(settings.LegendLocation)
                set(handleLegend,'Location',settings.LegendLocation)
            end
            
            boxPos = get(handleAxes,'Position');
            
            legPosDef = get(handleLegend,'Position');
            legPos = settings.LegendPosition;
            if legPos(3) == -1; legPos(3) = legPosDef(3); end % Width
            if legPos(4) == -1; legPos(4) = legPosDef(4); end % Height
            if legPos(2) == -1; legPos(2) = legPosDef(2); end % Set as it aligns with plotbox top

            set(handleLegend,'Position',legPos);
            
            % Set format of X and Y ticklabels
            if ~isempty(obj.XTickFormat); obj.SetTickLabels(handleAxes,'XTick',obj.XTickFormat); end
            if ~isempty(obj.YTickFormat); obj.SetTickLabels(handleAxes,'YTick',obj.YTickFormat); end
        end
        
        function obj = ParseInput(obj,inputString)
            % Parses input for current linegroup
            ParseInput@ClassPlotGroup(obj,inputString,0);
            
            [word1, rem] = strtok(inputString);
            
            switch lower(word1)
                case '*curve:'  % e.g. "*Curve: time-0 cntrlvar-3 Volume in tank"
                    tmp = textscan(rem, '%s%s%[^\n]', 'delimiter', {' '},'MultipleDelimsAsOne',1);
                    if isempty(tmp{1,1}); return; else; xChannel = tmp{1,1}{1}; end
                    if isempty(tmp{1,2}); return; else; yChannel = tmp{1,2}{1}; end
                    if isempty(tmp{1,3}); description = yChannel; else; description = tmp{1,3}{1}; end

                    % Append channels and description to this linegroup 
                    obj.AppendChannel(xChannel,yChannel,description);

                otherwise
                    % Read strings like this: "1104 cntrlvar 3 * Legend"
                    num = str2double(word1);
                    if isnan(num) == 0 && num >= 1001 && num <= 1999
                        tmp = textscan(rem, '%s%d*%[^\n]', 'delimiter', {' '},'MultipleDelimsAsOne',1);
                        if isempty(tmp{1,1}); return; else; plotalf = tmp{1,1}{1}; end
                        if isempty(tmp{1,2}); return; else; plotnum = tmp{1,2}; end
                        yChannel = sprintf('%s-%d',plotalf,plotnum);
                        if isempty(tmp{1,3}); description = yChannel; else; description = tmp{1,3}{1}; end

                        % Append channels and description to this linegroup 
                        obj.AppendChannel('time-0',yChannel,description);
                    end
            end
        end
        
        function obj = AppendLineGroup(obj,~)
            % Does nothing
        end
        
        function FixProperties(obj)
            % Checks and sets plot properties (YScale, YInterval, etc).
            % If they are not set for linegroup inherit plotgroup properties

            % Set default values related to the x-axis
            xChannelName = obj.Channels{end}{1,1};
            for i = 1:length(obj.ChannelDefaults)
                channelDefaults = obj.ChannelDefaults{i};
                if isempty(regexp(xChannelName,channelDefaults.pattern,'once')); continue; end 
                
                if isempty(obj.XLabel) && isfield(channelDefaults,'label'); obj.XLabel = channelDefaults.label; end
                if isempty(obj.XScale) && isfield(channelDefaults,'scale'); obj.XScale = channelDefaults.scale; end
                if isempty(obj.XOffset) && isfield(channelDefaults,'offset'); obj.XOffset = channelDefaults.offset; end
            end
            
            % Set default values related to the y-axis
            yChannelName = obj.Channels{end}{1,2};
            for i = 1:length(obj.ChannelDefaults)
                channelDefaults = obj.ChannelDefaults{i};
                if isempty(regexp(yChannelName,channelDefaults.pattern,'once')); continue; end 
                
                if isempty(obj.YLabel) && isfield(channelDefaults,'label'); obj.YLabel = channelDefaults.label; end
                if isempty(obj.YScale) && isfield(channelDefaults,'scale'); obj.YScale = channelDefaults.scale; end
                if isempty(obj.YOffset) && isfield(channelDefaults,'offset'); obj.YOffset = channelDefaults.offset; end
            end
            
            % Default values for scale and offset.
            if isempty(obj.YScale); obj.YScale = 1; end
            if isempty(obj.YOffset); obj.YOffset = 0; end
            if isempty(obj.XScale); obj.XScale = 1; end
            if isempty(obj.XOffset); obj.XOffset = 0; end
        end
        
        function obj = AppendChannel(obj,XChannel,YChannel, Description)
            % Appends channel name and description to current lineobject
            obj.Channels{length(obj.Channels)+1} = {XChannel,YChannel};
            obj.Legends{length(obj.Legends)+1} = Description;
        end
        
        function [xMin,xMax] = GetXMinMax(obj)
            % Return the x max and min values of current linegroup
            [xMin,xMax] = GetMinMax(1);
        end
        
        function [yMin,yMax] = GetYMinMax(obj)
            % Return the x max and min values of current linegroup
            [yMin,yMax] = GetYMinMax(2);
        end
        
        function [valMin,valMax] = GetMinMax(obj,IndexForXorYChannel)
            % Return the x max and min values of current linegroup
            valMin = []; valMax = []; % Defaults
            valMin0 = 9e19; valMax0 = -9e19;  % High and low values
            
            for i = 1:length(obj.Channels)
                channel = obj.Channels{i}{1,IndexForXorYChannel};
                [valMinTry,valMaxTry] = obj.DataSource.GetMaxMin(channel);
                if ~isempty(valMinTry) && valMinTry < valMin0; valMin0 = valMinTry; end
                if ~isempty(valMaxTry) && valMaxTry > valMax0; valMax0 = valMaxTry; end
            end
            
            if valMin0 ~= 9e19; valMin = valMin0; end
            if valMax0 ~=-9e19; valMax = valMax0; end
        end
        
        function WriteSummary(obj)
            % Writes out a summary of the plotproperties of linegroup
            indentStr = repmat(' ',[1,4]);
            fprintf('%s Title: ''%s''\n',indentStr,obj.Title);
            fprintf('%s YScale: %f, YOffset: %f, YOffsetFirst: %d, YLabel: ''%s''\n',indentStr,obj.YScale,obj.YOffset,obj.YOffsetFirst,obj.YLabel);
            fprintf('%s XScale: %f, XOffset: %f, XLabel: ''%s''\n\n',indentStr,obj.XScale,obj.XOffset,obj.XLabel);
        end
    end % methods
    
    methods (Static)
        
        function SetTickLabels(axes,property,formatSpec)
        % Formats the X- or YTickLabel according to specifications
        %
        
        
            switch lower(property)
                case {'xtick','ytick'}
                    XYTicks = get(axes,property);
                    XYTickLabel = num2cell(XYTicks)';
                    for i = 1:length(XYTickLabel)
                        XYTickLabel{i,1} = sprintf(formatSpec,XYTickLabel{i,1});
                    end
                    set(axes,sprintf('%sLabel',property),XYTickLabel);
                    set(axes,sprintf('%sLabelMode',property),'manual');
                    set(axes,sprintf('%s',property),XYTicks);
            end
        end

    end % methods (static)
end % classdef

