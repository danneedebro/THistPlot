function tx = findTime(t,y,operator,value,varargin)
% Returns the time a certain condition apply
%   tx = findTime(t,y,'>',0.6) returns the first time value where y>0.6
%
%   tx = findTime(t,y,'<',0.8,'after',1) returns the first time value where
%   y<0.8 after t=1
%
%   returns [] if time value not found

    % different result i called with cell array as arguments
    if size(varargin,2)>0
        if iscell(varargin{1,1})
            args = varargin{1,1};
        else
            args = varargin;
        end
    else
        args = {};
    end
    
    t1 = [];
    t2 = [];
    ind1 = 1;           % The index to start the search
    ind2 = length(t);    % The index to stop the search
    
    for i = 1:length(args)
        switch lower(args{i})
            case 'after'
                t1 = args{i+1};
            case 'before'
                t2 = args{i+1};
        end
    end
    
    if ~isempty(t1)
        ind1 = find(t >= t1,1);
    end
    if ~isempty(t2)
        ind2 = find(t >= t2,1);
    end
    
    tx = [];
    
    switch operator
        case '>'
            ind = find(y(ind1:ind2) > value,1);
        case '>='
            ind = find(y(ind1:ind2) >= value,1);
        case '<'
            ind = find(y(ind1:ind2) < value,1);
        case '<='
            ind = find(y(ind1:ind2) <= value,1);
        otherwise
            ind = [];
    end
    if ~isempty(ind); tx = t(ind1+ind-1); end
    
    

end