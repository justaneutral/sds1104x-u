classdef HandlerFunctions
    methods (Static)
        function handlePlotButton(src, event); 
            handles = HandlerFunctions.getHandles(src); 
            ax = handles.components.mainAxes; 
            slider = handles.components.ampSlider; 
            x = linspace(0, 2*pi, 100); 
            y = sin(x) * slider.Value; 
            plot(ax, x, y); title(ax, 'Sine Wave Plot'); 
            HandlerFunctions.logMsg(handles, 'Plot button pushed.'); 
        end

        function handleSlider(src, event); 
            handles = HandlerFunctions.getHandles(src); 
            msg = sprintf('Slider value changed to: %.2f', src.Value); 
            HandlerFunctions.logMsg(handles, msg); 
        end

        function handleCheckbox(src, event); 
            handles = HandlerFunctions.getHandles(src); 
            ax = handles.components.mainAxes; 
            if src.Value; grid(ax, 'on');
                msg = 'Grid enabled.'; 
            else; 
                grid(ax, 'off'); 
                msg = 'Grid disabled.'; 
            end; 
            HandlerFunctions.logMsg(handles, msg); 
        end
        
        function handleToggleSwitch1(src, event); 
            handles = HandlerFunctions.getHandles(src); 
            if strcmp(src.Value, 'On'); 
                handles.components.led1.Color = 'green'; 
            else; 
                handles.components.led1.Color = 'red'; 
            end; 
        end

        function handleToggleSwitch2(src, event); 
            handles = HandlerFunctions.getHandles(src); 
            if strcmp(src.Value, 'On'); 
                handles.components.led2.Color = 'blue'; 
            else; 
                handles.components.led2.Color = 'red'; 
            end; 
        end

        % Note: updateImageCallback is moved to createConfigurableApp.m

        function handles = getHandles(src)
             % This function assumes src is a UI component and finds the figure via Parent chain
             fig = ancestor(src, 'figure');
             if isstruct(fig.UserData) && isfield(fig.UserData, 'components'); handles = fig.UserData;
             else; error('Handles structure is incomplete.'); end
        end

        function logMsg(handles, message)
            logArea = handles.components.logArea; currentText = logArea.Value; newEntry = [datestr(now, 'HH:MM:SS'), ' - ', message];
            if ischar(currentText); logArea.Value = {currentText; newEntry};
            else; logArea.Value = [currentText; {newEntry}]; end
        end
    end
end
