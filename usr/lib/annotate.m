
VLines = {{15,'Start'}};

clf
plot(1:150,rand(1,150))
ppos=get(gca,'Position');
xInt = get(gca,'XLim');


SetTickFormat(gca,'YTick','%4.5f');


function SetTickFormat(axes,property,formatSpec)
% Formats the X- or YTickLabel according to specifications
%
    
    switch lower(property)
        case {'xtick','ytick'}
            XYTickLabel = num2cell(get(axes,property))';
            for i = 1:length(XYTickLabel)
                XYTickLabel{i,1} = sprintf(formatSpec,XYTickLabel{i,1});
            end
            set(axes,sprintf('%sLabel',property),XYTickLabel)
    end
end



% function handleAnnotation = VLine(axes,xValue)
% % inserts a vertical line annotation on axes
%     handleAnnotation = [];
% 
%     xInt = get(axes,'XLim');
%     if xValue < xInt(1) && xValue > xInt(2); return; end
%     
%     pos = get(axes,'Position');
%     
%     posX1 = pos(1);
%     posX2 = pos(1)+pos(3);
%     
% %     posX = posX1 + pos(
%     
%     value = VLines{1}{1,1}/(xInt(2)-xInt(1));
%     th=annotation('line',[ppos(1)+value,ppos(1)+ppos(3)+value],[ppos(2),ppos(2)+ppos(4)]);
%     th2=annotation('textbox',ppos,'String','MyText');
% 
% end