function appHandles = createConfigurableApp()
    addpath(pwd); 
    
    % Define function handles using full class name strings
    h_plotBtn = @(src, event) HandlerFunctions.handlePlotButton(src, event);
    h_slider  = @(src, event) HandlerFunctions.handleSlider(src, event);
    h_checkbox = @(src, event) HandlerFunctions.handleCheckbox(src, event);
    h_switch1 = @(src, event) HandlerFunctions.handleToggleSwitch1(src, event);
    h_switch2 = @(src, event) HandlerFunctions.handleToggleSwitch2(src, event);
    h_toggleswitch_mask_update_3 = @(src, event) HandlerFunctions.handle_toggleswitch_mask_update_3(src, event);
    h_toggleswitch_mask_update_2 = @(src, event) HandlerFunctions.handle_toggleswitch_mask_update_2(src, event);
    h_toggleswitch_mask_update_1 = @(src, event) HandlerFunctions.handle_toggleswitch_mask_update_1(src, event);
    h_toggleswitch_mask_reset_1 = @(src, event) HandlerFunctions.handle_toggleswitch_mask_reset_1(src, event);
    h_toggleswitch_mask_reset_2 = @(src, event) HandlerFunctions.handle_toggleswitch_mask_reset_2(src, event);
    h_toggleswitch_mask_reset_3 = @(src, event) HandlerFunctions.handle_toggleswitch_mask_reset_3(src, event);
    h_toggleswitch_reference_1 = @(src, event) HandlerFunctions.handle_toggleswitch_reference_1(src, event);
    h_toggleswitch_reference_2 = @(src, event) HandlerFunctions.handle_toggleswitch_reference_2(src, event);
    h_toggleswitch_reference_3 = @(src, event) HandlerFunctions.handle_toggleswitch_reference_3(src, event);
    h_toggleswitch_run_stop = @(src, event) HandlerFunctions.handle_toggleswitch_run_stop(src, event);


    configData = jsondecode(fileread('app_config.json')); 
    screenSize = get(0, 'ScreenSize');
    figWidth = screenSize(3) * 0.6; figHeight = screenSize(4) * 0.7; figPos = [(screenSize(3)-figWidth)/2, (screenSize(4)-figHeight)/2, figWidth, figHeight];
    fig = uifigure('Name', 'Configurable MATLAB App', 'Position', figPos, 'DeleteFcn', @(~,~)delete(timerfind)); 

    fig.UserData = struct(); 
    mainGrid = uigridlayout(fig, [1 1]);
    mainGrid.RowHeight = {'1x'}; mainGrid.ColumnWidth = {'1x'};
    tabGroup = uitabgroup(mainGrid);
    appHandles.fig = fig; appHandles.tabGroup = tabGroup; appHandles.components = struct(); 

    for t_idx = 1:length(configData.tabs) 
        tabConfig = configData.tabs(t_idx);
        if istable(tabConfig.components); tabConfig.components = table2struct(tabConfig.components); end
        currentTab = uitab(tabGroup, 'Title', tabConfig.title);
        tabGrid = uigridlayout(currentTab, [4 4]); 
        tabGrid.RowHeight = {'1x', '1x', '1x', '1x'}; %{'fit', 'fit', '1x'}; 
        tabGrid.ColumnWidth = {'1x', '1x', '1x', '1x'}; 
        tabGrid.Padding = [10 10 10 10];
        
        for c_idx = 1:length(tabConfig.components)
            if iscell(tabConfig.components); compConfig = tabConfig.components{c_idx}; else; compConfig = tabConfig.components(c_idx); end
            
            currentCallback = [];
            if isfield(compConfig, 'callbackName')
                switch compConfig.callbackName
                    case 'handlePlotButton'; currentCallback = h_plotBtn; 
                    case 'handleSlider'; currentCallback = h_slider;
                    case 'handleCheckbox'; currentCallback = h_checkbox; 
                    case 'handleToggleSwitch1'; currentCallback = h_switch1;
                    case 'handleToggleSwitch2'; currentCallback = h_switch2;
                    case 'handle_toggleswitch_mask_update_3'; currentCallback = h_toggleswitch_mask_update_3;
                    case 'handle_toggleswitch_mask_reset_3'; currentCallback = h_toggleswitch_mask_reset_3;
                    case 'handle_toggleswitch_reference_3'; currentCallback = h_toggleswitch_reference_3;
                    case 'handle_toggleswitch_mask_update_2'; currentCallback = h_toggleswitch_mask_update_2;
                    case 'handle_toggleswitch_mask_reset_2'; currentCallback = h_toggleswitch_mask_reset_2;
                    case 'handle_toggleswitch_reference_2'; currentCallback = h_toggleswitch_reference_2;
                    case 'handle_toggleswitch_mask_update_1'; currentCallback = h_toggleswitch_mask_update_1;
                    case 'handle_toggleswitch_mask_reset_1'; currentCallback = h_toggleswitch_mask_reset_1;
                    case 'handle_toggleswitch_reference_1'; currentCallback = h_toggleswitch_reference_1;
                    case 'handle_toggleswitch_run_stop'; currentCallback = h_toggleswitch_run_stop;

                    
                end
            end

            switch compConfig.type
                case 'button'; comp = uibutton(tabGrid, 'Text', compConfig.text, 'ButtonPushedFcn', currentCallback);
                case 'axes'; comp = uiaxes(tabGrid);
                case 'slider'; comp = uislider(tabGrid, 'Limits', [0 10], 'Value', 5, 'ValueChangedFcn', currentCallback);
                case 'checkbox'; comp = uicheckbox(tabGrid, 'Text', compConfig.text, 'ValueChangedFcn', currentCallback);
                case 'textarea'; comp = uitextarea(tabGrid, 'Value', compConfig.text);
                case 'text'; comp = uilabel(tabGrid, 'Text', compConfig.text);
                case 'toggleswitch'; comp = uiswitch(tabGrid, 'toggle', 'ValueChangedFcn', currentCallback);
                    lbl = uilabel(tabGrid, 'Text', compConfig.text); lbl.Layout.Row = compConfig.row; lbl.Layout.Column = compConfig.col + 1;
                case 'led'; comp = uilamp(tabGrid, 'Color', 'red'); 
                    lbl = uilabel(tabGrid, 'Text', compConfig.text); lbl.Layout.Row = compConfig.row; lbl.Layout.Column = compConfig.col + 1;
                case 'image'; comp = uiimage(tabGrid);
            end

            if ~strcmp(compConfig.type, 'led') && ~strcmp(compConfig.type, 'toggleswitch')
                comp.Layout.Row = compConfig.row; comp.Layout.Column = compConfig.col; 
            elseif strcmp(compConfig.type, 'toggleswitch'); comp.Layout.Row = compConfig.row; comp.Layout.Column = compConfig.col;
            end
            
            if isfield(compConfig, 'tag'); appHandles.components.(compConfig.tag) = comp; end
        end
    end

    fig.UserData = appHandles; 
    
    % CRITICAL FIX 2: Ensure GUI is fully rendered before timer starts
    drawnow;

    % imgHandle = appHandles.components.visualImage;
    % initialImageData = zeros(100, 300, 3); 
    % imgHandle.ImageSource = initialImageData;
    
    t = timer('Period', 1.0, 'ExecutionMode', 'fixedRate', 'TimerFcn', @timerUpdateCallback); 
    start(t);
    appHandles.timerObj = t; 

    % --- Nested Timer Callback Function (Guarantees scope access to appHandles) ---
    function timerUpdateCallback(~, ~)
        % This function has access to the outer function's workspace (appHandles)
        handles = appHandles; 
        
        s1_val = handles.components.switch1.Value; % 'On' or 'Off'
        s2_val = handles.components.switch2.Value; % 'On' or 'Off'
        
        RED = [1 0 0]; GREEN = [0 1 0]; BLUE = [0 0 1]; 

        currentImage = handles.components.visualImage.ImageSource;
        [imgHeight, imgWidth, ~] = size(currentImage);

        if strcmp(s1_val, 'Off') && strcmp(s2_val, 'Off'); newLineColor = RED;
        elseif strcmp(s1_val, 'Off') && strcmp(s2_val, 'On'); newLineColor = GREEN;
        elseif strcmp(s1_val, 'On') && strcmp(s2_val, 'Off'); newLineColor = BLUE;
        else; newLineColor = squeeze(currentImage(1, 1, :))'; end

        newImage = zeros(imgHeight, imgWidth, 3);
        newImage(2:end, :, :) = currentImage(1:end-1, :, :);
        for col = 1:imgWidth; newImage(1, col, :) = newLineColor; end
        
        handles.components.visualImage.ImageSource = newImage;
    end
end
