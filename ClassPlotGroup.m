classdef ClassPlotGroup < handle
    %PlotGroup Contains information about a plot group
    %   Detailed explanation goes here
    
    properties
        YInterval       % The Y-interval [min, max]
        XInterval       % The X-interval [min, max]
        YSpanMin        % The minimum YSpan
        Title           % The plot title
        YLabel          % The Y-axis label
        XLabel          % The X-axis label
        XYLabelDefaults % A cell array with the default legends
        XTickFormat     % The format spec for the X-ticks (%5.2f)
        YTickFormat     % The format spec for the Y-ticks (%5.2f)
        YScale          % The scale factor for the Y-values
        XScale          % The scale factor for the X-values
        YOffset         % The offset to apply to the Y-values
        YOffsetRead     % Indicates the Y-offset is parsed first (sets YOffsetFirst = 1)
        YOffsetFirst    % If true, Y-offset is first applied then scaling
        XOffset         % The offset to apply to the X-values
        ConstantLines   % A
        VLines          % Vertical lines
        HLines          % Horizontal lines
        LineGroups      % A cell array of the ClassLineGroup objects in the plotgroup
        DataSource      % A ClassDataSource object that contains the data.
    end
    
    methods
        function obj = ClassPlotGroup(BaseGroup,DataSource)
            % Creates a ClassPlotGroup object with information about a
            % group of properties
            
            if  nargin >= 2
                if isempty(BaseGroup)
                    obj.LineGroups = {};
                    obj.ConstantLines = {};
                    obj.VLines = {};
                    obj.HLines = {};
                    obj.Title = '';
                    obj.XTickFormat = '';
                    obj.YTickFormat = '';
                    obj.YSpanMin = [];
                    obj.YLabel = '';
                    obj.XLabel = '';
                    obj.XYLabelDefaults = {};
                    obj.YOffsetRead = 0;
                    obj.YOffsetFirst = 0;
                    obj.YScale = 1;
                    obj.YOffset = 0;
                    obj.XScale = 1;
                    obj.XOffset = 0;
                    obj.XInterval = [-9999,9999];
                    obj.YInterval = [-9999,9999];
                else
                    obj.LineGroups = {};
                    obj.ConstantLines = {};
                    obj.VLines = BaseGroup.VLines;
                    obj.HLines = BaseGroup.HLines;
                    obj.Title = BaseGroup.Title;
                    obj.YSpanMin = BaseGroup.YSpanMin;
                    obj.YLabel = BaseGroup.YLabel;
                    obj.XLabel = BaseGroup.XLabel;
                    obj.XTickFormat = BaseGroup.XTickFormat;
                    obj.YTickFormat = BaseGroup.YTickFormat;
                    obj.XYLabelDefaults = BaseGroup.XYLabelDefaults;
                    obj.YOffsetRead = BaseGroup.YOffsetRead;
                    obj.YOffsetFirst = BaseGroup.YOffsetFirst;
                    obj.YScale = BaseGroup.YScale;
                    obj.YOffset = BaseGroup.YOffset;
                    obj.XScale = BaseGroup.XScale;
                    obj.XOffset = BaseGroup.XOffset;
                    obj.XInterval = BaseGroup.XInterval;
                    obj.YInterval = BaseGroup.YInterval;
                end
                obj.DataSource = DataSource;
            end
        end
        
        function obj = AppendLineGroup(obj,lineGroup)
            % Appends a linegroup to current plotgroup
            obj.LineGroups{length(obj.LineGroups)+1} = lineGroup;
        end
        
        function obj = ParseInput(obj,inputString,ParseChannel)
            % Parses input for current plotgroup
            try
                [word1, rem] = strtok(inputString);

                switch lower(word1)
                    case '*title:'  % e.g. "*Title: Mass flows"
                        obj.Title = strtrim(rem);

                    case '*ylabel:'  % e.g. "*YLabel: Pressure (bar a)"
                        obj.YLabel = strtrim(rem);

                    case '*xlabel:'  % e.g. "*XLabel: Time (s)"
                        obj.XLabel = strtrim(rem);
                        
                    case '*ytickformat:' % "*YTickFormat: %5.1f"
                        obj.YTickFormat = strtrim(rem);
                        
                    case '*xtickformat:' % "*XTickFormat: %5.1f"
                        obj.XTickFormat = strtrim(rem);

                    case '*yscale:'  % e.g. "*YScale: 1e-5"
                        tmp = textscan(rem, '%f', 'delimiter', {' '},'MultipleDelimsAsOne',1);
                        if isempty(tmp{1,1}); return; else; num = tmp{1,1}; end 
                        obj.YScale = num;
                        
                        % If YOffset already read, set YOffsetFirst = 1
                        if obj.YOffsetRead == 1; obj.YOffsetFirst = 1; else; obj.YOffsetFirst = 0; end
                        
                    case '*xylabeldefaults:' % e.g. "*XYLabelDefaults: mflowj- Mass flow (kg/s)"
                        tmp = textscan(rem, '%s%[^\n]', 'delimiter', {' '},'MultipleDelimsAsOne',1);
                        if isempty(tmp{1,1}); return; else; channelFirstPart = tmp{1,1}{1}; end
                        if isempty(tmp{1,2}); return; else; xyLabelString = tmp{1,2}{1}; end
                        obj.XYLabelDefaults{end+1} = {channelFirstPart,xyLabelString};

                    case '*yoffset:'  % e.g. "*YOffset: -1e5"
                        tmp = textscan(rem, '%f', 'delimiter', {' '},'MultipleDelimsAsOne',1);
                        if isempty(tmp{1,1}); return; else; num = tmp{1,1}; end 
                        obj.YOffset = num;
                        obj.YOffsetRead = 1;

                    case '*xscale:'  % e.g. "*XScale: 0.016666667"
                        tmp = textscan(rem, '%f', 'delimiter', {' '},'MultipleDelimsAsOne',1);
                        if isempty(tmp{1,1}); return; else; num = tmp{1,1}; end 
                        obj.XScale = num;

                    case '*yspanmin:'  % e.g. "*YSpanMin: 0.1e5"
                        tmp = textscan(rem, '%f', 'delimiter', {' '},'MultipleDelimsAsOne',1);
                        if isempty(tmp{1,1}); return; else; num = tmp{1,1}; end 
                        obj.YSpanMin = num;

                    case {'*xint:','*yint:'}  % e.g. "*XInt: -9999 9999"
                        tmp = textscan(rem, '%s%s', 'delimiter', {' '},'MultipleDelimsAsOne',1);
                        if isempty(tmp{1,1}); obj.FailRead(inputString); return; else; valMinStr = tmp{1,1}{1}; end 
                        if isempty(tmp{1,2}); obj.FailRead(inputString); return; else; valMaxStr = tmp{1,2}{1}; end
                        valMin = obj.DataSource.GetValue(valMinStr);
                        valMax = obj.DataSource.GetValue(valMaxStr);
                        if isempty(valMin); obj.FailParse(valMinStr,inputString); return; end
                        if isempty(valMax); obj.FailParse(valMaxStr,inputString); return; end
                        switch lower(word1)
                            case '*xint:'
                                obj.XInterval = [valMin, valMax];
                            case '*yint:'
                                obj.YInterval = [valMin, valMax];
                        end

                    case '*vline:'
                        tmp = textscan(rem, '%s%[^\n]', 'delimiter', {' '},'MultipleDelimsAsOne',1);
                        if isempty(tmp{1,1}); return; else; valStr = tmp{1,1}{1}; end
                        if isempty(tmp{1,2}); descr = 'line'; else; descr = tmp{1,2}{1}; end
                        
                        % Try to fetch value from Datasource (if feval-expression)
                        val = obj.DataSource.GetValue(valStr);
                        
                        if isempty(val); obj.FailParse(valStr,inputString); return; end 
                        obj.VLines{length(obj.VLines)+1} = {val,descr};
                        
                    case '*line:'  % e.g. "*line 250 Max value"
                        tmp = textscan(rem, '%f%[^\n]', 'delimiter', {' '},'MultipleDelimsAsOne',1);
                        if isempty(tmp{1,1}); return; else; value = tmp{1,1}; end
                        if isempty(tmp{1,2}); descr = ''; else; descr = tmp{1,2}{1}; end
                        obj.ConstantLines{length(obj.ConstantLines)+1} = {value,descr};
                        
                    case '*curve:'  % e.g. "*Curve: time-0 cntrlvar-3 Volume in tank"
                        if ParseChannel == 0; return; end 
                        tmp = textscan(rem, '%s%s%[^\n]', 'delimiter', {' '},'MultipleDelimsAsOne',1);
                        if isempty(tmp{1,1}); return; else; xChannel = tmp{1,1}{1}; end
                        if isempty(tmp{1,2}); return; else; yChannel = tmp{1,2}{1}; end
                        if isempty(tmp{1,3}); description = yChannel; else; description = tmp{1,3}{1}; end
                        
                        % Create a new lineGroup object, append channels and
                        % description to it and append to this plotgroup
                        lineGroup = ClassLineGroup(obj,obj.DataSource);
                        lineGroup.AppendChannel(xChannel,yChannel,description);
                        obj.AppendLineGroup(lineGroup);

                    otherwise
                        % Read strings like this: "1104 cntrlvar 3 * Legend"
                        num = str2double(word1);
                        if isnan(num) == 0 && num >= 1001 && num <= 1999 && ParseChannel == 1
                            tmp = textscan(rem, '%s%d*%[^\n]', 'delimiter', {' '},'MultipleDelimsAsOne',1);
                            if isempty(tmp{1,1}); return; else; plotalf = tmp{1,1}{1}; end
                            if isempty(tmp{1,2}); return; else; plotnum = tmp{1,2}; end
                            yChannel = sprintf('%s-%d',plotalf,plotnum);
                            if isempty(tmp{1,3}); description = yChannel; else; description = tmp{1,3}{1}; end
                            
                            % Create a new lineGroup object, append channels and
                            % description to it and append to this plotgroup
                            lineGroup = ClassLineGroup(obj,obj.DataSource);
                            lineGroup.AppendChannel('time-0',yChannel,description);
                            obj.AppendLineGroup(lineGroup);
                        end

                end % switch
            catch ME
                fprintf('Error: unexpected error parsing ''%s''\n',inputString);
                fprintf('       ''%s''\n',ME.message);
            end
        end
        
        function WriteSummary(obj)
            % Writes out a summary of the plotproperties of plotgroup
            indentStr = repmat(' ',[1,4]);
            fprintf('Title: ''%s''\n',obj.Title);
            fprintf('YScale: %f, YOffset: %f, YOffsetFirst: %d, YLabel: ''%s''\n',obj.YScale,obj.YOffset,obj.YOffsetFirst,obj.YLabel);
            fprintf('XScale: %f, XOffset: %f, XLabel: ''%s''\n',obj.XScale,obj.XOffset,obj.XLabel);
            fprintf('XInterval: [%f,%f], YInterval: [%f,%f]\n\n',obj.XInterval(1),obj.XInterval(2),obj.YInterval(1),obj.YInterval(2));
            
            for i = 1:length(obj.LineGroups)
                lineGroup = obj.LineGroups{i};
                fprintf('\n%s LineGroup %d:\n',indentStr,i);
                lineGroup.WriteSummary();
                for j = 1:length(lineGroup.Channels)
                    channel = lineGroup.Channels{j}{1,2};
                    fprintf('%s%s %s\n',indentStr,indentStr,channel);
                end
            end
        end
        
    end % methods
    
    methods (Static)
        function FailRead(inputString)
            fprintf('Error: Failed reading input: ''%s''\n',inputString);
        end
        
        function FailParse(strToParse, inputString)
            fprintf('Error: Failed getting value from string ''%s'' in ''%s''\n',strToParse,inputString);
        end
        
        
    end % methods static
    
end

