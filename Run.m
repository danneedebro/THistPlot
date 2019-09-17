clc

mfilename()


% return

[path,pdfFile]=fileparts(tempname);

psFile = sprintf('%s.ps',pdfFile);
psFile = '';

paramFile = 'Stripfile-groups.strip';
% paramFile = '';

THistPlot('DataFile','Case4.str','ParamFile',paramFile,'PlotFile',psFile,'tmin',250,'tmax',900,'title','Test plotting');

% main = PlotStripFile('Case4.str',0,9999,1,sprintf('%s.ps',pdfFile));
% main.GetXValues()
% main.GetYValues('mflowj-101000000')

% main.ReadParameterFile('Stripfile-groups.strip');
% main.WriteSummary()
% main.PlotIt()


if ~isempty(psFile)
    sound(rand(50,1))

    dos(sprintf('"C:\\Program Files\\gs\\gs9.10\\bin\\gswin64c.exe" -sDEVICE=pdfwrite -o "%1$s.pdf" "%1$s.ps"',pdfFile))
    dos(sprintf('%s.pdf &',pdfFile))
end
