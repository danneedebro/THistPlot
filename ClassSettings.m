classdef ClassSettings < handle
    % Holds settings for plots
    
    properties
        BoxPosition
        BoxLineWidth
        MainTitleFontSize
        PlotTitleFontSize
        PlotTitleFont
        LegendPosition
        LegendLocation
        LegendBox
        LegendFontSize
        XLabelFontSize
        YLabelFontSize
        XGrid
        YGrid
        Colors1
        LineWidth
        Colors2
    end
    
    methods
        function obj = ClassSettings()
            % Construct an instance of this class
            %   Detailed explanation goes here
            obj.BoxLineWidth = 1.0;
            obj.MainTitleFontSize = 20;
            obj.PlotTitleFontSize = 12;
            obj.Colors1 = {[1,0,0],[0,0,0],[0,0,1],[0,1,0]};
            obj.Colors2 = {[1,0,0],[0,0,0],[0,0,1],[0,1,0]};
            obj.LineWidth = 1.5;
            obj.BoxPosition = [0.0800,0.5,0.7750,0.3412]; % Left, Bottom, Width, Height
            obj.LegendPosition = [0.8000,-1,-1,-1]; % Left, Bottom, Width, Height
            obj.LegendLocation = 'northeastoutside'; % empty, none, best, northeastoutside, etc
            obj.LegendBox = 'on';
            obj.LegendFontSize = 10;
            obj.XLabelFontSize = 10;
            obj.YLabelFontSize = 10;
            obj.XGrid = 'on';
            obj.YGrid = 'on';
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

