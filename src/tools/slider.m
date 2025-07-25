function hSlider = slider(varargin)
% SLIDER Creates and adds a scroll slider to a figure with time-based plots
%
% HSLIDER = SLIDER() This function adds a horizontal slider at the bottom of a figure to allow
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
% EXAMPLE:
%   t = 0:0.01:100;
%   y = sin(t);
%   figure;
%   plot(t, y);
%   hSlider = slider;  % Automatically uses current figure and time vector
%
% See also: zoom, pan, uicontrol
%
% STATUS: Beta

% Argument validation
narginchk(0, 2);
nargoutchk(0, 1);

% Input validation
parser = inputParser;
parser.FunctionName = 'slider';
addOptional(parser, 'arg1', [], @(v) isempty(v) || (isobject(v) && ishandle(v) && strcmp(get(v, 'Type'), 'figure')) || isnumeric(v) || isdatetime(v));
addOptional(parser, 'arg2', [], @(v) isempty(v) || isnumeric(v) || isdatetime(v));

parse(parser, varargin{:});
arg1 = parser.Results.arg1;
arg2 = parser.Results.arg2;

% Determine figHandler and timeVector based on parsed inputs
if isempty(arg1) && isempty(arg2)
    figHandler = gcf;
    timeVector = getTimeVectorFromFigure(figHandler);
elseif isempty(arg2)
    if isobject(arg1) && ishandle(arg1) && strcmp(get(arg1, 'Type'), 'figure')
        figHandler = arg1;
        timeVector = getTimeVectorFromFigure(figHandler);
    else
        figHandler = gcf;
        timeVector = arg1;
    end
else
    figHandler = arg1;
    timeVector = arg2;
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
    'Callback', @(~,~) resetViewCallback(axesHandle, hSlider));

% Store button handle
setappdata(axesHandle, 'resetButton', resetButton);

% Set callbacks
set(zoomObj, 'ActionPostCallback', @(~,~) updateSlider(axesHandle, hSlider));
set(panObj, 'ActionPostCallback', @(~,~) updateSlider(axesHandle, hSlider));

% Initialize slider
updateSlider(axesHandle, hSlider);
end

function resetViewCallback(axesHandle, sliderHandle)
% Resets the view to the original time range
timeStart = getappdata(axesHandle, 'timeStart');
timeEnd = getappdata(axesHandle, 'timeEnd');

% Reset the axis limits to the original range
xlim(axesHandle, [timeStart timeEnd]);

% Remove warning text if it exists
warningAnnotation = getappdata(axesHandle, 'warningAnnotation');
if ~isempty(warningAnnotation) && ishandle(warningAnnotation)
    delete(warningAnnotation);
    setappdata(axesHandle, 'warningAnnotation', []);
end

% Reset button appearance
resetButton = getappdata(axesHandle, 'resetButton');
set(resetButton, 'BackgroundColor', [0.94 0.94 0.94]);

% Update the slider configuration
updateSlider(axesHandle, sliderHandle);
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

function updateSlider(axesHandle, sliderHandle)
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

    % First delete any existing warning to avoid duplicates
    warningAnnotation = getappdata(axesHandle, 'warningAnnotation');
    if ~isempty(warningAnnotation) && ishandle(warningAnnotation)
        delete(warningAnnotation);
    end

    % Create warning using text object instead of annotation for better compatibility
    warningText = uicontrol(figHandle, 'Style', 'text', ...
        'Units', 'normalized', ...
        'Position', [0.3, 0.95, 0.4, 0.04], ...
        'String', 'View outside data range. Click "Reset" to return.', ...
        'BackgroundColor', [1 1 0.8], ...
        'HorizontalAlignment', 'center', ...
        'Tag', 'OutOfRangeWarning');

    % Store the warning text handle in appdata for easy access
    setappdata(axesHandle, 'warningAnnotation', warningText);

    % Disable slider when view is out of range
    set(sliderHandle, 'Enable', 'off');
else
    % Re-enable slider and update appearance
    set(resetButton, 'BackgroundColor', [0.94 0.94 0.94]);

    % Remove warning if it exists
    warningAnnotation = getappdata(axesHandle, 'warningAnnotation');
    if ~isempty(warningAnnotation) && ishandle(warningAnnotation)
        delete(warningAnnotation);
        setappdata(axesHandle, 'warningAnnotation', []);
    end

    % Check if showing entire range (or nearly so)
    if abs(windowWidth - totalDuration) < 0.001
        % When showing all data, disable slider
        set(sliderHandle, 'Enable', 'off');
    else
        % Normal slider operation - enable and configure
        set(sliderHandle, 'Enable', 'on');

        % Set range and position values
        maxScrollRange = max(totalDuration - windowWidth, 0.001);
        set(sliderHandle, 'Min', 0);
        set(sliderHandle, 'Max', maxScrollRange);
        set(sliderHandle, 'Value', limitsNumeric(1));

        % Set slider thumb size proportional to visible portion
        visiblePortion = windowWidth / totalDuration;
        smallStep = min(visiblePortion, 0.1);
        largeStep = min(visiblePortion * 5, 1);
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