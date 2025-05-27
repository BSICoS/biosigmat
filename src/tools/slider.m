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
        if ishandle(varargin{1}) && strcmp(get(varargin{1}, 'Type'), 'figure')
            % It's a figure handle
            figHandler = varargin{1};
            timeVector = getTimeVectorFromFigure(figHandler);
        else
            % Assume it's a time vector
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

% Maximize the figure window
set(figHandler, 'WindowState', 'maximized');

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
hSlider = setupZoomAndSlider(currentAxes, timeVector);

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

function hSlider = setupZoomAndSlider(axesHandle, timeVector)
% Sets up zoom/pan functionality and creates the slider control

% Define overlap percentage for slider step size
overlapPercent = 0.05;

% Determine if timeVector contains datetime values
isDatetime = isdatetime(timeVector);
timeStart = timeVector(1);
timeEnd = timeVector(end);

% Set the axes limits to show the entire range initially
if isDatetime
    % For datetime values, xlim can directly use datetime
    xlim(axesHandle, [timeStart timeEnd]);
    totalDuration = seconds(timeEnd - timeStart); % Convert to seconds for calculations
else
    % For numeric time values
    xlim(axesHandle, [timeStart timeEnd]);
    totalDuration = timeEnd - timeStart;
end

% Store required information in the axes' application data for later use
setappdata(axesHandle, 'totalDuration', totalDuration);
setappdata(axesHandle, 'timeStart', timeStart);
setappdata(axesHandle, 'timeEnd', timeEnd);
setappdata(axesHandle, 'isDatetime', isDatetime);

% Get handles to zoom and pan objects for the figure
zoomObj = zoom(ancestor(axesHandle, 'figure'));
panObj = pan(ancestor(axesHandle, 'figure'));

% Get axes position
axesPosition = get(axesHandle, 'Position');

% Define button size and spacing
buttonWidth = 0.07;
buttonHeight = 0.04;
margin = 0.01;

% Create the slider control - adjust width to leave space for button
hSlider = uicontrol('Style', 'slider', ...
    'Units', 'normalized', ...
    'Position', [axesPosition(1), 0.01, axesPosition(3)-buttonWidth-margin, 0.04], ...
    'Min', 0, 'Max', 1, 'Value', 0, ...
    'Callback', @(src, ~) sliderCallback(axesHandle, src));

% Add reset view button - positioned right after slider with margin
resetButton = uicontrol('Style', 'pushbutton', ...
    'Units', 'normalized', ...
    'Position', [axesPosition(1)+axesPosition(3)-buttonWidth, 0.01, buttonWidth, buttonHeight], ...
    'String', 'Reset', ...
    'Callback', @(~,~) resetViewCallback(axesHandle, hSlider, overlapPercent));

% Store the button handle in axes appdata for access in other functions
setappdata(axesHandle, 'resetButton', resetButton);

% Set callback functions for zoom and pan events
set(zoomObj, 'ActionPostCallback', @(~,~) updateSlider(axesHandle, hSlider, overlapPercent));
set(panObj, 'ActionPostCallback', @(~,~) panZoomCallback(axesHandle, hSlider, overlapPercent));

% Initialize the slider configuration
updateSlider(axesHandle, hSlider, overlapPercent);
end

function resetViewCallback(axesHandle, sliderHandle, overlapPercent)
% Resets the view to the original time range
timeStart = getappdata(axesHandle, 'timeStart');
timeEnd = getappdata(axesHandle, 'timeEnd');

% Reset the axis limits to the original range
xlim(axesHandle, [timeStart timeEnd]);

% Update the slider to match the reset view
updateSlider(axesHandle, sliderHandle, overlapPercent);
end

function panZoomCallback(axesHandle, sliderHandle, overlapPercent)
% Special callback for pan/zoom that checks if we're inside valid bounds
timeStart = getappdata(axesHandle, 'timeStart');
timeEnd = getappdata(axesHandle, 'timeEnd');
isDatetime = getappdata(axesHandle, 'isDatetime');
currentLimits = xlim(axesHandle);

% Check if current view is completely outside the valid range
if (isDatetime && (currentLimits(2) < timeStart || currentLimits(1) > timeEnd)) || ...
   (~isDatetime && (currentLimits(2) < timeStart || currentLimits(1) > timeEnd))
    
    % Make the slider invisible and show a warning
    set(sliderHandle, 'Enable', 'off');
    
    % Get the reset button handle
    resetButton = getappdata(axesHandle, 'resetButton');
    
    % Highlight the reset button
    set(resetButton, 'BackgroundColor', [1 0.6 0.6], 'FontWeight', 'bold');
    
    % Display a small warning on the plot
    figHandler = ancestor(axesHandle, 'figure');
    warningText = findobj(figHandler, 'Tag', 'OutOfRangeWarning');
    
    if isempty(warningText)
        annotation(figHandler, 'textbox', [0.5, 0.95, 0.4, 0.05], ...
            'String', 'View outside data range. Click "Reset View" to return.', ...
            'FitBoxToText', 'on', ...
            'BackgroundColor', [1 1 0.8], ...
            'Tag', 'OutOfRangeWarning', ...
            'HorizontalAlignment', 'center');
    end
else
    % If we're back in range, remove warning and update slider
    resetButton = getappdata(axesHandle, 'resetButton');
    set(resetButton, 'BackgroundColor', [0.94 0.94 0.94], 'FontWeight', 'normal');
    
    % Remove warning text if it exists
    warningText = findobj(ancestor(axesHandle, 'figure'), 'Tag', 'OutOfRangeWarning');
    if ~isempty(warningText)
        delete(warningText);
    end
    
    % Update the slider
    updateSlider(axesHandle, sliderHandle, overlapPercent);
end
end

function sliderCallback(axesHandle, sliderSource)
% Callback function executed when the slider value changes

% Get stored data from the axes
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
isDatetime = getappdata(axesHandle, 'isDatetime');
totalDuration = getappdata(axesHandle, 'totalDuration');

% Get current view limits and their numeric equivalents
currentLimits = xlim(axesHandle);
[limitsNumeric, windowWidth] = convertLimitsToNumeric(currentLimits, timeStart, isDatetime);

% If the view shows the entire data, disable the slider
if abs(windowWidth - totalDuration) < 1e-9
    set(sliderHandle, 'Enable', 'off');
else
    % Enable slider and configure its range and value
    set(sliderHandle, 'Enable', 'on');
    set(sliderHandle, 'Min', 0, 'Max', max((totalDuration - windowWidth), 0), 'Value', limitsNumeric(1));
    
    % Calculate appropriate step sizes based on the window width
    if totalDuration - windowWidth > 0
        smallStep = (windowWidth * overlapPercent) / (totalDuration - windowWidth);
        largeStep = min(1, (windowWidth * overlapPercent * 5) / (totalDuration - windowWidth));
    else
        smallStep = 0;
        largeStep = 1;
    end
    
    % Set the step sizes
    set(sliderHandle, 'SliderStep', [smallStep largeStep]);
end
end

function [limitsNumeric, windowWidth] = convertLimitsToNumeric(limits, timeStart, isDatetime)
% Converts axis limits to a numeric scale for calculations

if isDatetime
    % For datetime values, convert to seconds from timeStart
    limitsNumeric = seconds(limits - timeStart);
else
    % For numeric values, calculate offset from timeStart
    limitsNumeric = limits - timeStart;
end
windowWidth = diff(limitsNumeric);
end

function newLimits = convertNumericToLimits(startValue, windowWidth, timeStart, isDatetime)
% Converts numeric values back to appropriate axis limits

if isDatetime
    % For datetime values, convert from seconds to datetime
    newLimits = [timeStart + seconds(startValue), timeStart + seconds(startValue + windowWidth)];
else
    % For numeric values, add offset to timeStart
    newLimits = [timeStart + startValue, timeStart + startValue + windowWidth];
end
end