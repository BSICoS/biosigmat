function hSlider = slider(varargin)
% Creates and adds a scroll slider to a figure with time-based plots
%
% This function adds a horizontal slider at the bottom of a figure to allow
% scrolling through time-based plots. It works with both numeric and datetime
% time vectors and integrates with zoom and pan functionality.
%
% Usage:
%   slider                - Adds a slider to current figure with auto-detected time vector
%   slider(timeVector)    - Adds a slider to current figure with specified time vector
%   slider(figHandler)    - Adds a slider to specified figure with auto-detected time vector
%   slider(figHandler, timeVector) - Adds a slider to specified figure with specified time vector
%
% Inputs (optional):
%   figHandler - Handle to the figure where the slider will be added
%   timeVector - Vector containing the time values (numeric or datetime)
%
% Outputs:
%   hSlider - Handle to the created slider object
%
% Example:
%   t = 0:0.01:100;
%   y = sin(t);
%   figure;
%   plot(t, y);
%   hSlider = slider;  % Automatically uses current figure and time vector
%
% See also: zoom, pan, uicontrol

% Parse inputs based on number of arguments
switch nargin
    case 0
        % No arguments provided - use current figure and auto-detect time
        figHandler = gcf;
        timeVector = getTimeVectorFromFigure(figHandler);
        
    case 1
        % One argument could be either a figure handle or time vector
        if isobject(varargin{1}) && ishandle(varargin{1})
            % Check if it's a figure handle
            figType = get(varargin{1}, 'Type');
            if strcmp(figType, 'figure')
                % It's a figure handle
                figHandler = varargin{1};
                timeVector = getTimeVectorFromFigure(figHandler);
            else
                % It's some other handle, assume time vector
                figHandler = gcf;
                timeVector = varargin{1};
            end
        else
            % Not a handle, assume it's a time vector
            figHandler = gcf;
            timeVector = varargin{1};
        end
        
    case 2
        % Two arguments - figure handle and time vector
        figHandler = varargin{1};
        timeVector = varargin{2};
        
    otherwise
        error('Too many input arguments');
end

% Input validation
if ~ishandle(figHandler) || ~strcmp(get(figHandler, 'Type'), 'figure')
    error('First parameter must be a valid figure handle');
end

if isempty(timeVector)
    error('Time vector cannot be determined. Please provide a valid time vector.');
end

% Find all axes in the figure
axesAll = findobj(figHandler, 'Type', 'axes');

% If multiple axes exist, choose the one at the bottom
if length(axesAll) > 1
    positions = cell2mat(get(axesAll, 'Position'));
    [~, idxMin] = min(positions(:,2));
    currentAxes = axesAll(idxMin);
elseif ~isempty(axesAll)
    currentAxes = axesAll;
else
    error('No axes found in the figure');
end

% Create and configure the slider
hSlider = setupSlider(currentAxes, timeVector);

% Enable zoom functionality
zoom on;
end

function timeVector = getTimeVectorFromFigure(figHandler)
% Extracts time vector from the current plot in the figure
axesAll = findobj(figHandler, 'Type', 'axes');
timeVector = [];

if ~isempty(axesAll)
    % Choose the first axes or bottom-most one if multiple exist
    if length(axesAll) > 1
        positions = cell2mat(get(axesAll, 'Position'));
        [~, idxMin] = min(positions(:,2));
        currentAxes = axesAll(idxMin);
    else
        currentAxes = axesAll;
    end
    
    % Find line objects in the axes
    lineObjects = findobj(currentAxes, 'Type', 'line');
    
    if ~isempty(lineObjects)
        % Get XData from the first line object
        timeVector = get(lineObjects(1), 'XData');
        
        % Convert to column vector if it's a row vector
        if size(timeVector, 1) == 1
            timeVector = timeVector(:);
        end
    end
end

% If no time vector found, try to use XLim as a fallback
if isempty(timeVector)
    axisLimits = xlim(currentAxes);
    timeVector = linspace(axisLimits(1), axisLimits(2), 100)';
end
end

function hSlider = setupSlider(axesHandle, timeVector)
    % Sets up zoom/pan functionality and creates the slider control
    
    % Define overlap percentage for slider step size
    overlapPercent = 0.05;
    
    % Determine if timeVector contains datetime values
    isDatetime = isdatetime(timeVector);
    timeStart = timeVector(1);
    timeEnd = timeVector(end);
    
    % Set the axes limits to show the entire range initially
    if isDatetime
        xlim(axesHandle, [timeStart timeEnd]);
        totalDuration = seconds(timeEnd - timeStart);
    else
        xlim(axesHandle, [timeStart timeEnd]);
        totalDuration = timeEnd - timeStart;
    end
    
    % Store required information in axes appdata
    setappdata(axesHandle, 'totalDuration', totalDuration);
    setappdata(axesHandle, 'timeStart', timeStart);
    setappdata(axesHandle, 'timeEnd', timeEnd);
    setappdata(axesHandle, 'isDatetime', isDatetime);
    
    % Get zoom and pan objects
    figHandle = ancestor(axesHandle, 'figure');
    zoomObj = zoom(figHandle);
    panObj = pan(figHandle);
    
    % Get axes position
    axesPosition = get(axesHandle, 'Position');
    
    % Define button and spacing parameters
    buttonWidth = 0.06;
    buttonHeight = 0.03;
    margin = 0.01;
    sliderHeight = 0.03;
    
    % For subplots, ensure proper alignment
    sliderLeft = axesPosition(1);
    
    % Important: When working with subplots, calculate slider width based on
    % the actual axes width to ensure proper spanning
    sliderWidth = axesPosition(3) - buttonWidth - margin;
    
    % If this is a subplot, adjust for the shared space
    % Check if we have multiple subplot axes in the figure
    if length(findobj(figHandle, 'Type', 'axes')) > 1
        % Get the current subplot configuration
        subplotLayout = getSubplotLayout(figHandle, axesHandle);
        
        % If this is a subplot spanning multiple columns, adjust width accordingly
        if ~isempty(subplotLayout) && subplotLayout.colSpan > 1
            % Use the full width of the spanned columns
            sliderWidth = axesPosition(3) - buttonWidth - margin;
        end
    end
    
    % Create the slider control with explicit parent and correct width alignment
    hSlider = uicontrol(figHandle, 'Style', 'slider', ...
        'Units', 'normalized', ...
        'Position', [sliderLeft, 0.01, sliderWidth, sliderHeight], ...
        'Min', 0, 'Max', 1, 'Value', 0, ...
        'Callback', @(src, ~) sliderCallback(axesHandle, src));
    
    % Add reset view button with explicit parent and tag
    resetButton = uicontrol(figHandle, 'Style', 'pushbutton', ...
        'Units', 'normalized', ...
        'Position', [sliderLeft + sliderWidth + margin, 0.01, buttonWidth, buttonHeight], ...
        'String', 'Reset', ...
        'Tag', 'SliderResetButton', ...
        'Callback', @(~,~) resetViewCallback(axesHandle, hSlider, overlapPercent));
    
    % Store button handle
    setappdata(axesHandle, 'resetButton', resetButton);
    
    % Set callbacks
    set(zoomObj, 'ActionPostCallback', @(~,~) updateSlider(axesHandle, hSlider, overlapPercent));
    set(panObj, 'ActionPostCallback', @(~,~) updateSlider(axesHandle, hSlider, overlapPercent));
    
    % Initialize slider
    updateSlider(axesHandle, hSlider, overlapPercent);
end

function resetViewCallback(axesHandle, sliderHandle, overlapPercent)
% Resets the view to the original time range
timeStart = getappdata(axesHandle, 'timeStart');
timeEnd = getappdata(axesHandle, 'timeEnd');

% Reset the axis limits to the original range
xlim(axesHandle, [timeStart timeEnd]);

% Update the slider configuration
updateSlider(axesHandle, sliderHandle, overlapPercent);
end

function sliderCallback(axesHandle, sliderSource)
% Callback function executed when the slider value changes
timeStart = getappdata(axesHandle, 'timeStart');
isDatetime = getappdata(axesHandle, 'isDatetime');
totalDuration = getappdata(axesHandle, 'totalDuration');

% Get current limits and convert to numeric for calculations
currentLimits = xlim(axesHandle);
[~, windowWidth] = convertLimitsToNumeric(currentLimits, timeStart, isDatetime);

% Calculate new position based on slider value, ensuring we stay within bounds
newStart = sliderSource.Value;
newStart = max(0, min(newStart, totalDuration - windowWidth));

% Convert numeric position back to appropriate x-axis limits
newLimits = convertNumericToLimits(newStart, windowWidth, timeStart, isDatetime);
xlim(axesHandle, newLimits);
end

function updateSlider(axesHandle, sliderHandle, overlapPercent)
    % Updates slider properties based on current axes view
    
    % Retrieve stored data
    timeStart = getappdata(axesHandle, 'timeStart');
    timeEnd = getappdata(axesHandle, 'timeEnd');
    isDatetime = getappdata(axesHandle, 'isDatetime');
    totalDuration = getappdata(axesHandle, 'totalDuration');
    
    % Get current view limits and numeric equivalents
    currentLimits = xlim(axesHandle);
    [limitsNumeric, windowWidth] = convertLimitsToNumeric(currentLimits, timeStart, isDatetime);
    
    % Check if view is out of range
    viewOutOfRange = false;
    if (isDatetime && (currentLimits(2) < timeStart || currentLimits(1) > timeEnd)) || ...
       (~isDatetime && (currentLimits(2) < timeStart || currentLimits(1) > timeEnd))
        viewOutOfRange = true;
    end
    
    % Get reset button and figure handles
    resetButton = getappdata(axesHandle, 'resetButton');
    figHandle = ancestor(axesHandle, 'figure');
    
    % Handle slider display and interaction
    if viewOutOfRange
        % Update reset button appearance
        set(resetButton, 'BackgroundColor', [1 0.6 0.6]);
        
        % Add warning annotation
        warningText = findobj(figHandle, 'Tag', 'OutOfRangeWarning');
        if isempty(warningText)
            annotation(figHandle, 'textbox', [0.5, 0.95, 0.4, 0.05], ...
                'String', 'View outside data range. Click "Reset" to return.', ...
                'FitBoxToText', 'on', ...
                'BackgroundColor', [1 1 0.8], ...
                'Tag', 'OutOfRangeWarning', ...
                'HorizontalAlignment', 'center');
        end
        
        % Disable slider when view is out of range
        set(sliderHandle, 'Enable', 'off');
    else
        % Re-enable slider and update appearance
        set(resetButton, 'BackgroundColor', [0.94 0.94 0.94]);
        
        % Remove warning if it exists
        warningText = findobj(figHandle, 'Tag', 'OutOfRangeWarning');
        if ~isempty(warningText)
            delete(warningText);
        end
        
        % Check if showing entire range (or nearly so)
        if abs(windowWidth - totalDuration) < 0.001
            % When showing all data, disable slider
            set(sliderHandle, 'Enable', 'off');
        else
            % Normal slider operation - enable and configure
            set(sliderHandle, 'Enable', 'on');
            
            % Critical: Set max value based on how much we can scroll
            maxScrollRange = max(totalDuration - windowWidth, 0.001);
            set(sliderHandle, 'Min', 0);
            set(sliderHandle, 'Max', maxScrollRange);
            set(sliderHandle, 'Value', limitsNumeric(1));
            
            % Set slider thumb size proportional to visible portion
            visiblePortion = windowWidth / totalDuration;
            
            % Adjust slider step sizes based on visible portion
            if totalDuration > windowWidth
                % When zoomed in: thumb size represents visible proportion
                smallStep = min(visiblePortion, 0.1);
                largeStep = min(visiblePortion * 5, 1);
            else
                % When showing all data: use default steps
                smallStep = 0.1;
                largeStep = 0.5;
            end
            
            % Apply the step sizes (controls thumb size)
            set(sliderHandle, 'SliderStep', [smallStep largeStep]);
        end
    end
end

function [limitsNumeric, windowWidth] = convertLimitsToNumeric(limits, timeStart, isDatetime)
% Converts axis limits to a numeric scale for calculations
if isDatetime
    limitsNumeric = seconds(limits - timeStart);
else
    limitsNumeric = limits - timeStart;
end
windowWidth = diff(limitsNumeric);
end

function newLimits = convertNumericToLimits(startValue, windowWidth, timeStart, isDatetime)
% Converts numeric values back to appropriate axis limits
if isDatetime
    newLimits = [timeStart + seconds(startValue), timeStart + seconds(startValue + windowWidth)];
else
    newLimits = [timeStart + startValue, timeStart + startValue + windowWidth];
end
end

function subplotInfo = getSubplotLayout(figHandle, axesHandle)
    % Helper function to determine subplot configuration
    subplotInfo = struct('rows', 0, 'cols', 0, 'index', 0, 'rowSpan', 1, 'colSpan', 1);
    
    % Get all axes in the figure
    allAxes = findobj(figHandle, 'Type', 'axes');
    numAxes = length(allAxes);
    
    if numAxes <= 1
        return;  % Not a subplot
    end
    
    % Get positions of all axes
    positions = arrayfun(@(ax) get(ax, 'Position'), allAxes, 'UniformOutput', false);
    positions = cell2mat(positions);
    
    % Check for spanned subplots based on position and size
    currPos = get(axesHandle, 'Position');
    
    % Detect row and column spanning by comparing sizes
    widths = positions(:, 3);
    heights = positions(:, 4);
    
    % Estimate typical width and height of single subplot
    typicalWidth = min(widths(widths > 0.01));
    typicalHeight = min(heights(heights > 0.01));
    
    % Calculate spanning
    widthRatio = currPos(3) / typicalWidth;
    heightRatio = currPos(4) / typicalHeight;
    
    subplotInfo.colSpan = round(widthRatio);
    subplotInfo.rowSpan = round(heightRatio);
end