clc

mfilename()

addpath('../../','-end')


pdfFile = tempname();

psFile = sprintf('%s.ps',pdfFile);
% psFile = '';

strFile = 'Case1.str';
% strFile = '';

paramFile = 'Stripfile.strip';
% paramFile = '';

THistPlot('DataFile',strFile,'ParamFile',paramFile,'PlotFile',psFile,'tmin',250,'tmax',900,'title','Test plotting');


if ~isempty(psFile)
    sound(rand(50,1))

    dos(sprintf('"C:\\Program Files\\gs\\gs9.10\\bin\\gswin64c.exe" -sDEVICE=pdfwrite -o "%1$s.pdf" "%1$s.ps"',pdfFile));
    dos(sprintf('%s.pdf &',pdfFile));
end
