classdef ClassDataSource < handle 
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Data        % A MxN matrix with data
        Channels    % A 1xM cell array with unique channel names
    end
    
    methods
        function obj = ClassDataSource(data,channels)
            % Construct an instance of this class
            %   Detailed explanation goes here
            if size(data,2) ~= size(channels,2)
                fprintf('Error: Number of channels in ''data''(%d) and ''channels''(%d) doesn''t match.',size(data,2),size(channels,2));
            end
            obj.Data = data;
            obj.Channels = channels;
        end
        
        function [minVal,maxVal] = GetMaxMin(obj,ChannelName)
            % Returns the max min of the channel
            
            minVal = [];
            maxVal = [];
            
            vals = obj.GetValues(ChannelName);
            if ~isempty(vals)
                minVal = min(vals);
                maxVal = max(vals);
            end
        end
        
        function found = ChannelExist(obj,ChannelName)
            % Returns a vector with the data points. y = [] if not found.
            found = false;
            for i = 1:length(obj.Channels)
                Channel = obj.Channels{i};
                if strcmpi(Channel,ChannelName) == 1
                    found = true;
                end
            end
        end
        
        function y = GetValue(obj,inputString)
            y = [];
            valueTry = obj.FunctionEvaluater(inputString);

            % Value is not a valid feval expression or a valid with len > 1
            if isempty(valueTry) || length(valueTry) > 1
                valueTry = str2double(inputString);
                if isnan(valueTry)
                    fprintf('Error: Could not find or evaluate value of vertical line ''%s''\n',inputString);
                    return;
                else
                    y = valueTry;
                end
            else
                y=valueTry;
            end
        end
        
        function y = GetValues(obj,ChannelName)
            % Returns a vector with the data points. y = [] if not found.
            
            % First try a feval evaluation on channelname
            y = obj.FunctionEvaluater(ChannelName);
            if ~isempty(y); return; end
            
            ind = [];
            for i = 1:length(obj.Channels)
                Channel = obj.Channels{i};
                if strcmpi(Channel,ChannelName) == 1
                    ind = i;
                end
            end
            
            % If ChannelName doesn't exist inside DataSource, return zero
            % vector with same length as time vector.
            if isempty(ind)
                y = [];
            else
                y = obj.Data(:,ind);
            end
        end
        
        
        function y = FunctionEvaluater(obj,fevalString)
            % parses a feval string
            % feval(smooth,cntrlvar-9,15)   smooths values in cntrlvar-9
            
            y = [];
            
            % Exit with y = -1 if not a feval string
            if ~strncmpi(fevalString,'@',1) || ~strncmpi(fevalString(end),')',1); return; end
            
            % Parse the feval arguments using textscan
            exprStr = fevalString(2:end-1);
            tmp = textscan(exprStr, '%s', 'delimiter', {'('},'MultipleDelimsAsOne',0);
            if isempty(tmp{1,1}); return; else; functionName = tmp{1,1}{1}; end
            
            if size(tmp{1,1},1) > 1; argsStr = tmp{1,1}{2}; else; argsStr = ' '; end
            
            args = textscan(argsStr, '%s', 'delimiter', {','},'MultipleDelimsAsOne',1);
            
            % Loop through rest of args and if it is a channel name, read
            % data from DataSource
            fevalArgs = cell(1,size(args{1,1},1));
            
            for i = 1:size(args{1,1},1)
                arg = args{1,1}{i,1};
                
                if obj.ChannelExist(arg)
                    fevalArgs{1,i} = obj.GetValues(arg);
                elseif isnan(str2double(arg))
                    fevalArgs{1,i} = arg;
                else
                    fevalArgs{1,i} = str2double(arg);
                end
            end
            
            % Try running feval command
            try
                if size(args,1) > 0
                    y=feval(functionName,fevalArgs{1,1:size(fevalArgs,2)});
                else
                    y=feval(functionName);
                end
            catch ME
                fprintf('Error: Failed evaluating feval-expression ''%s'' with \n       message ''%s''\n',fevalString,ME.message);
            end
            
        end
        
        
        
        
    end
end

