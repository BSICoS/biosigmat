% sliderTest.m - Test for the slider function
%
% This script tests the slider function with different test cases:
% 1. Dependencies check (checks if required functions are available)
% 2. Basic functionality with numeric time vector 
% 3. Basic functionality with datetime time vector
% 4. Auto-detection of time vector (no time vector provided)
% 5. UI element positioning and properties
% 6. Reset button functionality
% 7. Pan/Zoom out-of-range handling
% 8. Error handling with invalid inputs

%% Add source path if needed
addpath('../../src/tools');

%% Print header
fprintf('\n=========================================================\n');
fprintf('             RUNNING SLIDER TEST CASES\n');
fprintf('=========================================================\n\n');

%% Test 1: Dependencies check
fprintf('Test 1: Dependencies check\n');

% Test if all required dependencies are available
dependenciesOk = true;
missingDependencies = {};

% Check for required functions
if ~exist('slider', 'file')
  dependenciesOk = false;
  missingDependencies{end+1} = 'slider';
end

% Print test results
if dependenciesOk
  fprintf('Test 1: Dependencies check: passed\n\n');
else
  fprintf('Test 1: Dependencies check: failed\n');
  fprintf(' - Missing dependencies: ');
  for i = 1:length(missingDependencies)
    if i > 1
      fprintf(', ');
    end
    fprintf('%s', missingDependencies{i});
  end
  fprintf('\n\n');
end

%% Test 2: Basic functionality with numeric time vector
fprintf('Test 2: Basic functionality with numeric time vector\n');

% Create a figure with a simple plot
figNumeric = figure('Name', 'Slider Test - Numeric', 'Visible', 'off');
timeVector = 0:0.01:10;
testSignal = sin(2*pi*timeVector);
plot(timeVector, testSignal);
title('Test Plot with Numeric Time');

% Try to add a slider
try
    hSlider = slider(figNumeric, timeVector);
    numericTest = isgraphics(hSlider) && strcmp(get(hSlider, 'Style'), 'slider');
    fprintf('Test 2: Slider creation with numeric time: passed\n\n');
catch ME
    numericTest = false;
    fprintf('Test 2: Slider creation with numeric time: failed\n');
    fprintf(' - Error message: %s\n\n', ME.message);
end

%% Test 3: Basic functionality with datetime time vector
fprintf('Test 3: Basic functionality with datetime time vector\n');

% Create a figure with a datetime plot
figDatetime = figure('Name', 'Slider Test - Datetime', 'Visible', 'off');
startTime = datetime('now') - hours(24);
timeStep = minutes(5);
datetimeVector = startTime:timeStep:(startTime + hours(24));
testSignal = sin(linspace(0, 2*pi, length(datetimeVector)));
plot(datetimeVector, testSignal);
title('Test Plot with Datetime');

% Try to add a slider
try
    hSliderDatetime = slider(figDatetime, datetimeVector);
    datetimeTest = isgraphics(hSliderDatetime) && strcmp(get(hSliderDatetime, 'Style'), 'slider');
    fprintf('Test 3: Slider creation with datetime: passed\n\n');
catch ME
    datetimeTest = false;
    fprintf('Test 3: Slider creation with datetime: failed\n');
    fprintf(' - Error message: %s\n\n', ME.message);
end

%% Test 4: Auto-detection of time vector
fprintf('Test 4: Auto-detection of time vector\n');

% Create a figure with a simple plot without providing time vector to slider
figAutoDetect = figure('Name', 'Slider Test - Auto Detect', 'Visible', 'off');
autoTimeVector = 1:0.5:20;
autoTestSignal = cos(autoTimeVector);
plot(autoTimeVector, autoTestSignal);
title('Test Plot for Auto-Detection');

% Test 4a: Auto-detection with no arguments
try
    % Set as current figure
    figure(figAutoDetect);
    
    % Call slider with no arguments
    hSliderAuto1 = slider();
    autoDetectTest1 = isgraphics(hSliderAuto1) && strcmp(get(hSliderAuto1, 'Style'), 'slider');
    fprintf('Test 4a: Slider creation with no arguments: passed\n');
catch ME
    autoDetectTest1 = false;
    fprintf('Test 4a: Slider creation with no arguments: failed\n');
    fprintf(' - Error message: %s\n', ME.message);
end

% Test 4b: Auto-detection with figure handle only
try
    % Create a new figure
    figAutoDetect2 = figure('Name', 'Slider Test - Auto Detect 2', 'Visible', 'off');
    plot(autoTimeVector * 2, autoTestSignal);
    
    % Call slider with figure handle only
    hSliderAuto2 = slider(figAutoDetect2);
    autoDetectTest2 = isgraphics(hSliderAuto2) && strcmp(get(hSliderAuto2, 'Style'), 'slider');
    fprintf('Test 4b: Slider creation with figure handle only: passed\n\n');
catch ME
    autoDetectTest2 = false;
    fprintf('Test 4b: Slider creation with figure handle only: failed\n');
    fprintf(' - Error message: %s\n\n', ME.message);
end

%% Test 5: UI element positioning and properties
fprintf('Test 5: UI element positioning and properties\n');

% Check slider positioning
try
    % Get the axes handle
    axHandle = findobj(figNumeric, 'Type', 'axes');
    axPosition = get(axHandle(1), 'Position');
    sliderPosition = get(hSlider, 'Position');
    
    % Check slider left alignment with axes
    sliderAligned = abs(sliderPosition(1) - axPosition(1)) < 0.01;
    
    % Find reset button
    resetButton = findobj(figNumeric, 'Style', 'pushbutton', 'String', 'Reset');
    resetButtonExists = ~isempty(resetButton);
    
    if resetButtonExists
        % Check that reset button is positioned correctly
        buttonPosition = get(resetButton, 'Position');
        buttonAtRight = abs((buttonPosition(1) + buttonPosition(3)) - (axPosition(1) + axPosition(3))) < 0.01;
        
        % Check for non-overlap between slider and button
        noOverlap = sliderPosition(1) + sliderPosition(3) <= buttonPosition(1);
        
        positioningCorrect = sliderAligned && buttonAtRight && noOverlap;
    else
        positioningCorrect = false;
    end
    
    if positioningCorrect
        fprintf('Test 5: UI element positioning: passed\n\n');
    else
        fprintf('Test 5: UI element positioning: failed\n');
        if ~sliderAligned
            fprintf(' - Slider not properly aligned with axes\n');
        end
        if ~resetButtonExists
            fprintf(' - Reset button not found\n');
        elseif ~buttonAtRight
            fprintf(' - Reset button not properly positioned at right\n');
        elseif ~noOverlap
            fprintf(' - Slider and reset button overlap\n');
        end
        fprintf('\n');
    end
catch ME
    positioningCorrect = false;
    fprintf('Test 5: UI element positioning: failed\n');
    fprintf(' - Error message: %s\n\n', ME.message);
end

%% Test 6: Reset button functionality
fprintf('Test 6: Reset button functionality\n');

try
    % Get axes from numeric figure
    axHandle = findobj(figNumeric, 'Type', 'axes');
    
    % First zoom in to change the view
    initialXlim = xlim(axHandle(1));
    newXlim = [3, 6]; % Zoomed in view
    xlim(axHandle(1), newXlim);
    
    % Find and simulate clicking the reset button
    resetButton = findobj(figNumeric, 'Style', 'pushbutton', 'String', 'Reset');
    resetButtonCallback = get(resetButton, 'Callback');
    resetButtonCallback();
    
    % Check if xlim has been reset
    currentXlim = xlim(axHandle(1));
    resetWorked = abs(currentXlim(1) - initialXlim(1)) < 0.01 && ...
                  abs(currentXlim(2) - initialXlim(2)) < 0.01;
                  
    if resetWorked
        fprintf('Test 6: Reset button functionality: passed\n\n');
    else
        fprintf('Test 6: Reset button functionality: failed\n');
        fprintf(' - View not properly reset\n\n');
    end
catch ME
    resetWorked = false;
    fprintf('Test 6: Reset button functionality: failed\n');
    fprintf(' - Error message: %s\n\n', ME.message);
end

%% Test 7: Pan/Zoom out-of-range handling
fprintf('Test 7: Pan/Zoom out-of-range handling\n');

try
    % Get axes from numeric figure
    axHandle = findobj(figNumeric, 'Type', 'axes');
    
    % Pan outside range
    xlim(axHandle(1), [15, 20]); % Way outside the range
    
    % Get the pan callback
    panObj = pan(figNumeric);
    panCallback = get(panObj, 'ActionPostCallback');
    % Trigger the callback
    panCallback([],[]);
    
    % Check if slider is disabled
    sliderEnabled = strcmp(get(hSlider, 'Enable'), 'on');
    
    % Find warning text
    warningText = findobj(figNumeric, 'Tag', 'OutOfRangeWarning');
    warningShown = ~isempty(warningText);
    
    outOfRangeHandled = ~sliderEnabled && warningShown;
    
    if outOfRangeHandled
        fprintf('Test 7: Out-of-range handling: passed\n\n');
    else
        fprintf('Test 7: Out-of-range handling: failed\n');
        if sliderEnabled
            fprintf(' - Slider not disabled when view is out of range\n');
        end
        if ~warningShown
            fprintf(' - Warning text not shown when view is out of range\n');
        end
        fprintf('\n');
    end
catch ME
    outOfRangeHandled = false;
    fprintf('Test 7: Out-of-range handling: failed\n');
    fprintf(' - Error message: %s\n\n', ME.message);
end

%% Test 8: Error handling with empty time vector
fprintf('Test 8: Error handling with empty time vector\n');

figEmpty = figure('Name', 'Slider Test - Empty', 'Visible', 'off');
plot(1:10); % Simple plot without specifying time vector

% Try with empty time vector
emptyTest = false;
try
    hSlider = slider(figEmpty, []);
    fprintf('Test 8: Empty time vector handling: failed (should have thrown an error)\n\n');
catch ME
    emptyTest = true;
    fprintf('Test 8: Empty time vector handling: passed (correctly threw error)\n');
    fprintf(' - Error message: %s\n\n', ME.message);
end

%% Test 9: Error handling with invalid figure handle
fprintf('Test 9: Error handling with invalid figure handle\n');

% Try with invalid figure handle
invalidHandleTest = false;
try
    hSlider = slider(-999, 1:10);
    fprintf('Test 9: Invalid figure handle: failed (should have thrown an error)\n\n');
catch ME
    invalidHandleTest = true;
    fprintf('Test 9: Invalid figure handle: passed (correctly threw error)\n');
    fprintf(' - Error message: %s\n\n', ME.message);
end

%% Test 10: Calling with time vector only (using current figure)
fprintf('Test 10: Calling with time vector only\n');

figTimeOnly = figure('Name', 'Slider Test - Time Only', 'Visible', 'off');
axes; % Create empty axes
timeOnlyTest = false;

try
    % Set current figure and provide only time vector
    figure(figTimeOnly);
    timeOnlyVector = 5:0.1:15;
    hSliderTimeOnly = slider(timeOnlyVector);
    
    timeOnlyTest = isgraphics(hSliderTimeOnly) && strcmp(get(hSliderTimeOnly, 'Style'), 'slider');
    
    if timeOnlyTest
        fprintf('Test 10: Calling with time vector only: passed\n\n');
    else
        fprintf('Test 10: Calling with time vector only: failed\n\n');
    end
catch ME
    fprintf('Test 10: Calling with time vector only: failed\n');
    fprintf(' - Error message: %s\n\n', ME.message);
end

%% Summarize all results
totalTests = 10;
passedTests = sum([dependenciesOk, numericTest, datetimeTest, autoDetectTest1, autoDetectTest2, ...
                  positioningCorrect, resetWorked, outOfRangeHandled, emptyTest, invalidHandleTest, ...
                  timeOnlyTest]);

fprintf('\n---------------------------------------------------------\n');
fprintf('  SUMMARY: %i of %i tests passed\n', passedTests, totalTests);
fprintf('---------------------------------------------------------\n\n');

% Close all test figures
close all;