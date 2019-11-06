function DataGroup = ReadStripfile(filename,tmin,tmax,tsamp)
%ReadStripfile Reads a RELAP5 strip file and stores data as a 1xT arrays of
%structs with the following fields:
%   ChannelNames    A 1xN cell array containing strings with the unique
%                   channel names
%   Values          A 1xN cell array containing the arrays 
%

    % Read str file and convert to ClassDataSource object
    rawData = readStripFileGUI('<',{filename},'>',{'empty'},'tmin',tmin,'tmax',tmax,'tsamp',tsamp,'output');

    DataGroup = struct();
    DataGroup.ChannelNames = cell(1,size(rawData,2)-1);
    for i = 1:length(DataGroup.ChannelNames)
        DataGroup.ChannelNames{i} = sprintf('%s-%s',rawData{1,i+1},rawData{2,i+1});
    end
    
    data = cell2mat(rawData(3:size(rawData,1), 2:size(rawData,2)));
    
    for i = 1:size(data,2)
        DataGroup.Values{i} = data(:,i)';
    end
    

end

