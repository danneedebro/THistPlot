function THistPlot(varargin)
% A tool for batch plotting multiple plots to a pdf
%   BatchPlotter('DataFile','myData.dat','ParamFile','Param.txt','PlotFile','Plots.ps')
%   plots the channels specified in 'Param.txt' to 'Plots.ps' (PostScript
%   file easily convertable to pdf)
%   
%   Example parameter file:
%       <GROUP>
%       Title: Temperatures
%       YOffset: 273.15
%       YLabel: Temperature (K)
%       Curve: time tp001 * Temperature 1
%       Curve: time tp002 * Temperature 2
%       Curve: ...   ...  * 
%       Curve: time tp120 * Temperature
%   
%       <GROUP>
%       Title: Pressure
%       YLabel: Pressure (Pa)
%       YScale: 1e5
%       Curve: time p001 * Pressure before filter
%       Curve: time p002 * Pressure after filter
%
%
    clc;

    version = '1.0.0-beta.3';
    scriptPathFull = mfilename('fullpath');
    [scriptPath,~] = fileparts(scriptPathFull);
    fullfile(scriptPath,'/usr/lib')
    addpath(fullfile(scriptPath,'/usr/lib'),'-end');
    
    

    fprintf('THistPlot (v%s)\n\n',version);
    fprintf('(%s)\n',scriptPath);
    fprintf('Date: %s\n',datestr(now,'yyyy-mm-dd HH:MM'));
    fprintf('Working folder: ''%s''\n',pwd);
    
     

    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    fprintf('\nREADING AND CHECKING INPUT ARGUMENTS\n');
    
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
            
    % Default values
    tsamp = 1;
    tmin = 0;
    tmax = 9999;
    mainTitle = '';

    antalArg = size(args,2);
    
    try
        fprintf('Read args: Batch');
        errorMessage = '';
        
        for i = 1:antalArg
            switch lower(args{i})
                case 'datafile'
                    fprintf(', ''DataFile''=''%s''',num2str(args{i+1}));
                    fileData = args{i+1};

                case 'paramfile'
                    fprintf(', ''ParamFile''=''%s''',num2str(args{i+1}));
                    fileParam = args{i+1};

                case 'plotfile'
                    fprintf(', ''PlotFile''=''%s''',num2str(args{i+1}));
                    filePlots = args{i+1};

                case 'tsamp'
                    fprintf(', ''tsamp''=''%s''',num2str(args{i+1}));
                    tsamp = args{i+1};

                case 'tmin'
                    fprintf(', ''tmin''=''%s''',num2str(args{i+1}));
                    if isnumeric(args{i+1})
                        tmin = args{i+1};
                    else
                        errorMessage = sprintf('%sError: Value for ''tmin'' (%s) not numeric.\n',errorMessage,args{i+1});
                        tmin = 0;
                    end
                    

                case 'tmax'
                    fprintf(', ''tmax''=''%s''',num2str(args{i+1}));
                    if isnumeric(args{i+1})
                        tmax = args{i+1};
                    else
                        errorMessage = sprintf('%sError: Value for ''tmax'' (%s) not numeric.\n',errorMessage,args{i+1});
                        tmax = 9999;
                    end

                case 'title'
                    fprintf(', ''Title''=''%s''',num2str(args{i+1}));
                    mainTitle = args{i+1};

            end
        end
    catch ME
        fprintf('Error: Unexpected error reading input arguments: ''%s''\n',ME.message);
        disp(varargin);
    end
    
    if isempty(fileData)
        fprintf('Error: No data file given. Quitting.\n')
    end
    
    fprintf('\n%s\n',errorMessage);
    
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    fprintf('\nREADING AND CONSTRUCTING DATASOURCE\n');
    fprintf('- Reads file ''%s'' using readStripFileGUI.m\n',fileData);
    % Read str file and convert to ClassDataSource object
    rawData = readStripFileGUI('<',{fileData},'>',{'empty'},'tmin',tmin,'tmax',tmax,'tsamp',tsamp,'output');

    data = cell2mat(rawData(3:size(rawData,1), 2:size(rawData,2)));
    channels = cell(1,size(rawData,2)-1);
    for i = 1:length(channels)
        channels{i} = sprintf('%s-%s',rawData{1,i+1},rawData{2,i+1});
    end
    
    fprintf('- Creating data source object\n');
    DataSource = ClassDataSource(data,channels);
    fprintf('     Number of channels: %d\n',length(DataSource.Channels));
    
    
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    fprintf('\nCONSTRUCTING PLOT- AND LINEGROUPS\n');
    % Plot figures
    main = ClassPlotter(DataSource,mainTitle,tmin,tmax);
    if isempty(fileParam)
        main.StagePlotGroups();
    else
        main.StagePlotGroupsFromFile(fileParam);
        fprintf('- Summary:\n');
        for i = 1:length(main.PlotGroups)
            plotGroup = main.PlotGroups{i};
            fprintf('     PlotGroup %2d containing %2d linegroups: Title = ''%s''\n',i,length(plotGroup.LineGroups),plotGroup.Title);
        end
    end
    
        
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    fprintf('\nPLOTTING\n');
    if isempty(filePlots)
        fprintf('- No plot file given, writes summary instead.\n');
%         main.WriteSummary();
        for i = 1:length(main.PlotGroups)
            fprintf('<-------PLOTGROUP %d-------->\n',i);
            plotGroup = main.PlotGroups{i}
%             plotGroup.XYLabelDefaults{:}
        end

    else
        fprintf('- Write plots to ''%s''\n',filePlots);
        main.PlotIt(filePlots);
    end


end

