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
            if ~startsWith(fevalString,'feval(') || ~endsWith(fevalString,')'); return; end
            
            % Parse the feval arguments using textscan
            argsStr = fevalString(6+1:length(fevalString)-1);
            args = textscan(argsStr, '%s', 'delimiter', {','},'MultipleDelimsAsOne',1);
            
            % First argument must be the function name
            if isempty(args{1,1}); return; else; func = args{1,1}{1}; end
            
            % Loop through rest of args and if it is a channel name, read
            % data from DataSource
            fevalArgs = cell(1,size(args{1,1},1));
            fevalArgs{1,1} = func;
            
            for i = 2:size(args{1,1},1)
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
                y=feval(fevalArgs{1,1},fevalArgs{1,2:size(fevalArgs,2)});
            catch ME
                fprintf('Error: Failed evaluating feval-expression ''%s'' with \n       message ''%s''\n',fevalString,ME.message);
            end
            
        end
        
        
        
        
    end
end

