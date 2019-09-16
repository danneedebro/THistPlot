function output = readStripFileGUI(varargin)
%
% readStripFileGUI   ver 1.2
%
% Script som l�ser in RELAP5 stripfil (plotvariabler i textformat)
%
%
% syntax: readStripFileGUI(argument)
% 
% readStripFileGUI kan kallas med ett eller flera av f�ljande argument. Om
% dessa n�got av dessa argument saknas f�r man ist�llet upp en dialogruta.
%
% arg1 - Filer att l�sa in: '<' f�ljt av en 1xN string-cell inneh�llande 
%  filnamn (ex: readStripFileGUI('<',{'filnamn1','filnamn2'})
% arg2 - Spara som variabler: '>' f�ljt av en 1xN string-cell inneh�llande
%  variabelnamn (ex: readStripFileGUI('>',{'varnamn1','varnamn2'})
% arg3 - tMin: 'tmin',24 l�s in data fr�n och med denna tidpunkt (default = 0.0)
% arg4 - tMax: 'tmax',32 l�s in data till och med denna tidpunkt (default = 9999.0)
% arg5 - tSamp: 'tSamp',2 sampla med denna frekvens (ex: l�s in var annan punkt)
% arg6 - output: Om str�ngen 'output' ges som argument. Returnera output.
%
%
%
% ex 1: starta i GUI-l�ge. Dialogruta kommer upp och fr�gar vilken fil man
% vill l�sa in
% readStripFileGUI
%
% ex 2: starta med hj�lp av argument. Filnamn som ska l�sas in ges
%
% readStripFileGUI('<',{'path\filnamn1.str','path\filnamn1.str'},'>',{'varname1,varname2'},'tMin=0.00','tMax=9999.0','tsamp=1')
%
%
% Daniel Edebro
%
% ver 1.0
% Inl�sning med argument s�v�l som GUI
%
% ver 1.1
% �ndringar i argument. Ist�llet f�r att ange tmin p� formen 'tmin=14'
% anges den med tv� argument enligt: 'tmin',14
%
% ver 1.2
% B�ttre minneshantering f�r att slippa minnesproblem. Mellanlagring i
% tempor�ra filer p� disk.
%
% ver 1.3
% �ndrat p� rad 118 (&& returnOutput == 0)
%
% Indatakontroll
antalArg = size(varargin,2);
filenames = [];
varnames = [];
pathname = [];
minTime = 0.0;
maxTime = 9999.0;
tsamp = 1;
timeInput = 0;
returnOutput = 0;
output = 0;

for i = 1:antalArg
    
    % om inl�st argument �r av typen cell - hoppa till n�sta
    if iscell(varargin{i})
        continue;
    % om '<' l�ses antas att n�sta argument �r filnamn
    elseif strcmp(varargin{i},'<')
        filenames = varargin{i+1};
        i = i + 1;
    % om '>' l�ses antas att n�sta argument �r variabelnamn        
    elseif strcmp(varargin{i},'>')
        varnames = varargin{i+1};
        i = i + 1;
    % om 'tMin=' l�ses. Spara start-tid i 'minTime'
    elseif strcmpi(varargin{i},'tmin')
        minTime = varargin{i+1};
        i = i + 1;
        timeInput = 1;
    % om 'tMax=' l�ses. Spara start-tid i 'maxTime'
    elseif strcmpi(varargin{i},'tmax')
        maxTime = varargin{i+1};
        i = i + 1;
        timeInput = 1;
    % om 'tsamp=' l�ses. Spara start-tid i 'maxTime'
    elseif strcmpi(varargin{i},'tsamp')
        tsamp = varargin{i+1};
        i = i + 1;
        timeInput = 1;
    elseif strcmpi(varargin{i},'Output')
        returnOutput = 1;
    end
end
disp(sprintf('readStripFileGUI ver 1.2  (%s)\n',mfilename('fullpath')));


% Om filnamn inte givet som argument - �ppna en dialogruta som fr�gar efter
% detta.
if isempty(filenames)
    [filenames, pathname] = uigetfile({'*.str','Stripfiler (*.str)';'*.*','Alla filer (*.*)'},'V�lj stripfiler att l�sa in...','MultiSelect', 'on');
    if ~iscell(filenames)
       if filenames == 0, return; end
    end
end

antalFiler = size(filenames,2);

% Om bara en fil l�sts in returneras filname ej som en cell-variabel.
% Lagrar indata i en cell
if ischar(filenames)
    antalFiler = 1;
    filenames = {filenames,'empty'};
end



% Om variabelnamn inte givet som argument - �ppna en dialogruta som fr�gar efter
% detta.
if isempty(varnames) && returnOutput == 0
    numlines = antalFiler;
    
    tmp = filenames;
    for i = 1:antalFiler, tmp{1,i} = fixName(tmp{1,i}); end
    
    defaultVarNames = genvarname(tmp);
    
    prompt = filenames(1:antalFiler);
    name='Ange variabelnamn';
    
    varnames=inputdlg(prompt,name,numlines,defaultVarNames(1:antalFiler));
end


% Kolla om tidintervall och samplingsfrekvens givet som input. Om inte
% �ppnas en dialogruta.
if timeInput == 0
    timeData=inputdlg({'t min =','t max =','Samplingsfrekvens'},'readStripFileGUI',1,{num2str(minTime),num2str(maxTime),num2str(tsamp)});
    if ~isempty(timeData)
        minTime = str2double(timeData{1});
        maxTime = str2double(timeData{2});
        tsamp = str2double(timeData{3});
    else
        return;
    end
end



% 
% ------- start for-loop ---------
for fileNumber = 1:antalFiler

    % Open file for output
    if isempty(pathname)
        fid = fopen([filenames{fileNumber}]);
    else
        fid = fopen([pathname,filenames{fileNumber}]);
    end


    % Define cells to store data in
    data = cell(0);
    
    % loop through file in search for number of plot-variables
    % indicated by number after the string 'plotinf'
    tmpString = '';


    firstLine = 1;
    run = 1;
    rad = 1;
    sampInd = tsamp - 1;
    tic
    dataArray = [];
    fileCount = 0;
    blockSize = 2000;
    randomString = sprintf('%04d%s',round(rand(1)*1000),datestr(now,'MMSS'));
    
    % ------- start while-loop ---------
    while run
        tline = fgetl(fid);  % L�s in rad

        % Om sista raden
        if ~ischar(tline)
            tline = 'plotrec'; 
            run=0;
            lastRow = rad;
        end
    
    
        % ------- start if-block 1 ---------
        % Om 'plotinf' l�ses (plotinformation, integer)
        if ~isempty(findstr('plotinf',tline))
            readPlotinf = strread(tline,'%s');
            tmpString = '';
       
        elseif ~isempty(findstr('plotalf',tline))
            tmpString = tline;
        
        % Om 'plotnum' (variabelnummer, integer) l�ses ska tidigare inl�st data lagras
        % som 'plotalf' (plotnamn, str�ng)
        elseif ~isempty(findstr('plotnum',tline)) 
            readPlotalf = strread(tmpString,'%s');
            N = size(readPlotalf,1);
            for i = 1:N, data{1,i} = readPlotalf{i,1}; end   % l�s in 'plotalf' till rad 1 i 'data'
            tmpString = tline;   % reset 'tmpString' 
            dataArray = zeros(blockSize,size(data,2)-1);
            
        % Om 'plotrec' l�ses (datapunkter).
        elseif ~isempty(findstr('plotrec',tline))
        % Om f�rsta 'plotrec' ska tidigare inl�st data lagras som 'plotnum'
            
            % ------- start if-block 2 ---------
            if firstLine == 1
                readPlotnum = strread(tmpString,'%s');
                N = size(readPlotnum,1);
                for i = 1:N, data{2,i} = readPlotnum{i,1}; end   % l�s in 'plotnum' till rad 2 i 'data'
                tmpString = tline;   % reset 'tmpString' 
                disp(sprintf('L�ser (%d st plotvariabler)         ',N-2));
                firstLine = 0;

                % Om 'plotrec' l�ses. Processa tidigare inl�st datarad
            else
                sampInd = sampInd + 1;

                readPlotrec = strread(tmpString,'%s');
                N = size(readPlotrec,1);

                time = str2double(readPlotrec{2});
                %'disp(sprintf('sampInd=%f, time=%f, minTime=%f, maxTime=%f',sampInd,time,minTime,maxTime))
                
                if isempty(time), disp('error'); end
                
                % ------- start if-block 3 ---------
                 % Spara bara data om tiden �r inom aktuellt omr�de.
                if time >= minTime && time <= maxTime  && sampInd == tsamp
                    sampInd = 0;
                    for i = 2:N
                        dataArray(rad,i-1) = str2double(readPlotrec{i,1});
                    end
                    rad = rad + 1;
                    if rad == blockSize + 1
                        fileCount = fileCount + 1;
                        save(sprintf('tmpFileName_%s_%04d.mat',randomString,fileCount),'dataArray');
                        dataArray = zeros(blockSize,size(data,2)-1);
                        rad = 1;
                        % Plotta progress-bar. 
                        disp(sprintf('\b\b\b\b\b\b\b\b\b\b.t=%7.2f',time));
                    end
                    
                    tmpString = tline;  % reset 'tmpString' 
                elseif time > maxTime
                    run = 0;
                else
                    
                    tmpString = tline;  % reset 'tmpString'
                    %'sampInd = sampInd - 1;
                    if sampInd > tsamp, sampInd = 0; end
                end
                % ------- slut if-block 3 ---------
            
            end
            % ------- slut if-block 2 ---------
        
            % Om blank rad    
        elseif isempty(tline)
            tmpString = tmpString;  
        else
            tmpString = [tmpString,tline];  % ut�ka 'tmpString'
        end % while
        % ------- slut if-block 1 ---------
    end
    % ------- slut while-loop ---------

    fclose(fid);
    
    fileCount = fileCount + 1;
    save(sprintf('tmpFileName_%s_%04d.mat',randomString,fileCount),'dataArray');
    
    lastRow = rad;
        
    
    % Redovisa tids�tg�ng
    tid = toc;
    timeHour = floor(tid/3600);
    timeMinute = floor( (tid - timeHour*3600)/60 );
    timeSecond = floor( (tid - timeHour*3600 - timeMinute*60) );
    disp(sprintf('\nTids�tg�ng (hh:mm:ss): %02d:%02d:%02d',timeHour,timeMinute,timeSecond));

    
    antalRader = fileCount*blockSize-(blockSize-lastRow) - 1;
    antalCols = size(data,2);
    data{2+antalRader,antalCols} = [];
    
    % Loopa igenom och l�s in alla tempor�ra filer och lagra dessa i 'data'
    for i = 1:fileCount
        load(sprintf('tmpFileName_%s_%04d.mat',randomString,i),'dataArray');
        delete(sprintf('tmpFileName_%s_%04d.mat',randomString,i));
        M = 2+(i-1)*blockSize;
        if i < fileCount
            maxSize = blockSize;
        else
            maxSize = antalRader - blockSize*(fileCount-1);
        end
        for j = 1:maxSize
            for k = 1:size(dataArray,2)
                data{M+j,1+k} = dataArray(j,k);
            end
        end
    end

    
    
    
    % returnera output om str�ngen 'output' given som argument. 
    if returnOutput == 1
        if fileNumber == 1, output = data; end
        clear data
    else
        % Skapar variabler
        varName = genvarname(varnames{fileNumber});
        disp(sprintf('Skapar variabel = %s\n\n',varName));
        assignin('base',varName,data);
        clear data
        output = 0;
    end
        

end
% ------- slut for-loop ---------



function outString = fixName(inString)
% Fixa till filnamn
%
%
fixList = {'-','_';'�','a';'�','a';' ','_';'.','_'};
outString = inString;
for j = 1:size(fixList,1)
    run = 1;
    while run
        subsList = findstr(outString,fixList{j,1});
        if ~isempty(subsList)
            n1 = subsList(1)-1;
            n2 = subsList(1)+1;
            n3 = length(outString);
            outString = [outString(1:n1),fixList{j,2},outString(n2:n3)];
        else
            run = 0;
        end
    end
end


