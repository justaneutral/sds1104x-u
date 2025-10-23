function state = buttonState(caption)
% BUTTONSTATE  Create multiple instances of a button with unique captions and states.
%   state = BUTTONSTATE(caption) creates a new button with the specified caption.
%   Returns 1 if the button is pressed, 0 if not.
%   Each instance can be created independently using different captions.

    if nargin < 1
        error('Caption is required as input.');
    end
    
    % Persistent variables to hold the state for each button instance
    persistent buttons;
    
    % Check if the caption already exists (i.e., if this is a new button or existing)
    if isempty(buttons)
        buttons = struct();  % Initialize an empty struct if it's the first call
    end
    
    % Check if this caption exists in the buttons struct
    if ~isfield(buttons, caption)
        % Create the figure and button for the first time for this caption
        fig = figure('Name', caption, 'NumberTitle', 'off', 'MenuBar', 'none', ...
                     'Position', [500, 500, 200, 100]);
        btn = uicontrol('Style', 'pushbutton', 'String', caption, ...
                        'Position', [50, 30, 100, 40], 'Callback', @(src, event) buttonCallback(caption));
        % Initialize the button state
        buttons.(caption).state = 0;  % Initially not pressed
        buttons.(caption).fig = fig;
        buttons.(caption).btn = btn;
        
        % Set the close function to remove the button from the struct when closed
        set(fig, 'CloseRequestFcn', @(src, event) closeFigure(caption));
        
        % Return the initial state of the button (0 = not pressed)
        state = 0;
    else
        % If the button already exists, return the current state
        state = buttons.(caption).state;
    end
    
    % Callback function when the button is pressed
    function buttonCallback(caption)
        buttons.(caption).state = 1;  % Mark the button as pressed
        disp([caption, ' button pressed!']);
    end

    % Close the figure and clean up the struct when the window is closed
    function closeFigure(caption)
        delete(buttons.(caption).fig);  % Delete the figure
        rmfield(buttons, caption);      % Remove the button instance from the struct
    end
end
