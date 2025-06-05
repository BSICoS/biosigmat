% sliderTest.m - Test class for the slider function
% 
% Tests covering:
%   - Basic functionality with numeric time vector
%   - Basic functionality with datetime time vector
%   - Auto-detection of time vector
%   - UI element positioning and properties
%   - Reset button functionality
%   - Pan/Zoom out-of-range handling
%   - Error handling with invalid inputs
%   - Input argument parsing

classdef sliderTest < matlab.unittest.TestCase
    
    properties
        FigNumeric
        FigDatetime
        FigAutoDetect
        TimeVector
        DatetimeVector
    end
    
    methods (TestClassSetup)
        function addCodeToPath(~)
            % Add source path for the function under test
            addpath('../../src/tools');
        end
    end
    
    methods (TestMethodSetup)
        function createTestFigures(testCase)
            % Create test figures for each test
            
            % Numeric time vector figure
            testCase.FigNumeric = figure('Name', 'Slider Test - Numeric', 'Visible', 'off');
            testCase.TimeVector = 0:0.01:10;
            testSignal = sin(2*pi*testCase.TimeVector);
            plot(testCase.TimeVector, testSignal);
            title('Test Plot with Numeric Time');
            
            % Datetime time vector figure
            testCase.FigDatetime = figure('Name', 'Slider Test - Datetime', 'Visible', 'off');
            startTime = datetime('now') - hours(24);
            timeStep = minutes(5);
            testCase.DatetimeVector = startTime:timeStep:(startTime + hours(24));
            testSignal = sin(linspace(0, 2*pi, length(testCase.DatetimeVector)));
            plot(testCase.DatetimeVector, testSignal);
            title('Test Plot with Datetime');
            
            % Auto-detection test figure
            testCase.FigAutoDetect = figure('Name', 'Slider Test - Auto Detect', 'Visible', 'off');
            autoTimeVector = 1:0.5:20;
            autoTestSignal = cos(autoTimeVector);
            plot(autoTimeVector, autoTestSignal);
            title('Test Plot for Auto-Detection');
        end
    end
    
    methods (TestMethodTeardown)
        function closeFigures(~)
            % Close all figures after each test
            close all;
        end
    end
    
    methods (Test)
        function testDependenciesExist(testCase)
            % Test if required function exists
            testCase.verifyTrue(exist('slider', 'file') == 2, 'Slider function does not exist');
        end
        
        function testNumericTimeVector(testCase)
            % Test slider creation with numeric time vector
            hSlider = slider(testCase.FigNumeric, testCase.TimeVector);
            
            testCase.verifyTrue(ishandle(hSlider), 'Slider was not created successfully');
            testCase.verifyEqual(get(hSlider, 'Style'), 'slider', 'Created UI element is not a slider');
            
            % Verify x-axis limits match time vector bounds
            axHandle = findobj(testCase.FigNumeric, 'Type', 'axes');
            currentLimits = xlim(axHandle);
            testCase.verifyEqual(currentLimits(1), testCase.TimeVector(1), 'AbsTol', 0.01, 'X-axis lower limit does not match time vector start');
            testCase.verifyEqual(currentLimits(2), testCase.TimeVector(end), 'AbsTol', 0.01, 'X-axis upper limit does not match time vector end');
        end
        
        function testDatetimeTimeVector(testCase)
            % Test slider creation with datetime time vector
            hSlider = slider(testCase.FigDatetime, testCase.DatetimeVector);
            
            testCase.verifyTrue(ishandle(hSlider), 'Slider was not created successfully with datetime vector');
            testCase.verifyEqual(get(hSlider, 'Style'), 'slider', 'Created UI element is not a slider');
            
            % Verify x-axis limits match time vector bounds
            axHandle = findobj(testCase.FigDatetime, 'Type', 'axes');
            currentLimits = xlim(axHandle);
            testCase.verifyEqual(currentLimits(1), testCase.DatetimeVector(1), 'X-axis lower limit does not match datetime vector start');
            testCase.verifyEqual(currentLimits(2), testCase.DatetimeVector(end), 'X-axis upper limit does not match datetime vector end');
        end
        
        function testAutoDetectionNoArgs(testCase)
            % Test auto-detection with no arguments
            figure(testCase.FigAutoDetect); % Make current figure
            
            hSlider = slider();
            testCase.verifyTrue(ishandle(hSlider), 'Slider was not created successfully with no arguments');
            testCase.verifyEqual(get(hSlider, 'Style'), 'slider', 'Created UI element is not a slider');
        end
        
        function testAutoDetectionFigureHandle(testCase)
            % Test auto-detection with only figure handle
            hSlider = slider(testCase.FigAutoDetect);
            
            testCase.verifyTrue(ishandle(hSlider), 'Slider was not created successfully with figure handle only');
            testCase.verifyEqual(get(hSlider, 'Style'), 'slider', 'Created UI element is not a slider');
        end
        
        function testTimeVectorOnly(testCase)
            % Test calling with time vector only, using current figure
            figTimeOnly = figure('Name', 'Slider Test - Time Only', 'Visible', 'off');
            plot(1:10, sin(1:10)); % Add a basic plot so axes are created
            
            % Set current figure and provide only time vector
            figure(figTimeOnly);
            timeOnlyVector = 5:0.1:15;
            hSlider = slider(timeOnlyVector);
            
            % Test if slider was created correctly
            testCase.verifyTrue(ishandle(hSlider), 'Slider was not created successfully with time vector only');
            testCase.verifyEqual(get(hSlider, 'Style'), 'slider', 'Created UI element is not a slider');
        end
        
        function testUIElementPositioning(testCase)
            % Test slider and reset button positioning
            hSlider = slider(testCase.FigNumeric, testCase.TimeVector);
            
            % Get the axes handle and positions
            axHandle = findobj(testCase.FigNumeric, 'Type', 'axes');
            axPosition = get(axHandle(1), 'Position');
            sliderPosition = get(hSlider, 'Position');
            
            % Check slider left alignment with axes
            testCase.verifyLessThan(abs(sliderPosition(1) - axPosition(1)), 0.01, 'Slider not properly aligned with left edge of axes');
            
            % Find reset button
            resetButton = findobj(testCase.FigNumeric, 'Tag', 'SliderResetButton');
            testCase.verifyFalse(isempty(resetButton), 'Reset button not found');
            
            % Check button positioning if it exists
            if ~isempty(resetButton)
                buttonPosition = get(resetButton, 'Position');
                
                % Check reset button is at the right edge of axes
                testCase.verifyLessThan(abs((buttonPosition(1) + buttonPosition(3)) - (axPosition(1) + axPosition(3))), 0.01, ...
                    'Reset button not properly positioned at right edge of axes');
                
                % Check no overlap between slider and button
                testCase.verifyLessThanOrEqual(sliderPosition(1) + sliderPosition(3), buttonPosition(1), ...
                    'Slider and reset button overlap');
            end
        end
        
        function testResetButtonFunctionality(testCase)
            % Test reset button functionality
            hSlider = slider(testCase.FigNumeric, testCase.TimeVector);
            
            % Get axes handle
            axHandle = findobj(testCase.FigNumeric, 'Type', 'axes');
            
            % Record initial x-axis limits
            initialXlim = xlim(axHandle(1));
            
            % Change x-axis limits to simulate zooming
            newXlim = [3, 6]; % Zoomed in view
            xlim(axHandle(1), newXlim);
            
            % Find and simulate clicking reset button
            resetButton = findobj(testCase.FigNumeric, 'Tag', 'SliderResetButton');
            testCase.verifyFalse(isempty(resetButton), 'Reset button not found');
            
            % Get and execute callback function
            resetButtonCallback = get(resetButton, 'Callback');
            resetButtonCallback();
            
            % Check if limits were reset correctly
            currentXlim = xlim(axHandle(1));
            testCase.verifyEqual(currentXlim(1), initialXlim(1), 'AbsTol', 0.01, 'X-axis lower limit not reset correctly');
            testCase.verifyEqual(currentXlim(2), initialXlim(2), 'AbsTol', 0.01, 'X-axis upper limit not reset correctly');
        end
        
        function testOutOfRangeHandling(testCase)
            % Test pan/zoom out-of-range handling
            hSlider = slider(testCase.FigNumeric, testCase.TimeVector);
            
            % Get axes handle
            axHandle = findobj(testCase.FigNumeric, 'Type', 'axes');
            
            % Pan outside range
            xlim(axHandle(1), [15, 20]); % Way outside the range
            
            % Get the pan callback
            panObj = pan(testCase.FigNumeric);
            panCallback = get(panObj, 'ActionPostCallback');
            
            % Trigger the callback
            panCallback([],[]);
            
            % Check if slider is disabled
            testCase.verifyEqual(get(hSlider, 'Enable'), 'off', 'Slider was not disabled when view is out of range');
            
            % Check if reset button is highlighted
            resetButton = findobj(testCase.FigNumeric, 'Tag', 'SliderResetButton');
            bgColor = get(resetButton, 'BackgroundColor');
            testCase.verifyNotEqual(bgColor, [0.94 0.94 0.94], 'Reset button was not highlighted when view is out of range');
            
            % Find warning text
            warningText = findobj(testCase.FigNumeric, 'Tag', 'OutOfRangeWarning');
            testCase.verifyFalse(isempty(warningText), 'Warning text was not shown when view is out of range');
        end
        
        function testEmptyTimeVectorError(testCase)
            % Test error handling with empty time vector
            figEmpty = figure('Name', 'Slider Test - Empty', 'Visible', 'off');
            plot(1:10); % Simple plot
            
            % Verify error thrown with empty time vector
            testCase.verifyError(@() slider(figEmpty, []), '', 'Empty time vector did not throw an error');
        end
        
        function testInvalidFigureHandleError(testCase)
            % Test error handling with invalid figure handle
            testCase.verifyError(@() slider(-999, 1:10), '', 'Invalid figure handle did not throw an error');
        end
        
        function testTooManyInputsError(testCase)
            % Test error handling with too many inputs
            testCase.verifyError(@() slider(testCase.FigNumeric, testCase.TimeVector, 'extra', 'args'), ...
                '', 'Too many input arguments did not throw an error');
        end
        
        function testSubplotHandling(testCase)
            % Test slider works correctly with subplots
            figSubplots = figure('Name', 'Slider Test - Subplots', 'Visible', 'off');
            
            % Create subplots
            subplot(2,2,1);
            plot(1:10, sin(1:10));
            title('Plot 1');
            
            subplot(2,2,2);
            plot(1:10, cos(1:10));
            title('Plot 2');
            
            % Create a subplot spanning multiple columns
            subplot(2,2,[3,4]);
            multiColTimeVector = 0:0.01:5;
            plot(multiColTimeVector, sin(2*pi*multiColTimeVector));
            title('Subplot Spanning Multiple Columns');
            
            % Add slider to the spanning subplot
            hSlider = slider(figSubplots);
            
            % Verify slider exists
            testCase.verifyTrue(ishandle(hSlider), 'Slider not created for subplot figure');
            
            % Verify slider width matches the subplot width
            axHandle = subplot(2,2,[3,4]);
            axPosition = get(axHandle, 'Position');
            sliderPosition = get(hSlider, 'Position');
            
            % Check that slider width is appropriate for the spanning subplot
            testCase.verifyLessThan(abs(sliderPosition(3) - (axPosition(3) - 0.06 - 0.01)), 0.07, ...
                'Slider width not properly matched to spanning subplot');
        end
        
        function testSliderThumbSizeWithZoom(testCase)
            % Test that slider thumb size changes with zoom level
            hSlider = slider(testCase.FigNumeric, testCase.TimeVector);
            
            % Get initial slider step (proportional to thumb size)
            initialStep = get(hSlider, 'SliderStep');
            
            % Zoom in to show only 20% of the data
            axHandle = findobj(testCase.FigNumeric, 'Type', 'axes');
            timeRange = testCase.TimeVector(end) - testCase.TimeVector(1);
            zoomStart = testCase.TimeVector(1) + timeRange * 0.4;
            zoomEnd = testCase.TimeVector(1) + timeRange * 0.6;
            xlim(axHandle, [zoomStart, zoomEnd]);
            
            % Call the zoom callback to update the slider
            zoomObj = zoom(testCase.FigNumeric);
            zoomCallback = get(zoomObj, 'ActionPostCallback');
            zoomCallback([],[]);
            
            % Get updated slider step
            zoomedStep = get(hSlider, 'SliderStep');
            
            % Verify thumb size is larger when zoomed in (smaller step means larger thumb)
            testCase.verifyGreaterThan(zoomedStep(1), initialStep(1), ...
                'Slider thumb size did not increase when zoomed in');
        end
        
        function testSliderScrolling(testCase)
            % Test actually scrolling the view using the slider
            hSlider = slider(testCase.FigNumeric, testCase.TimeVector);
            
            % Get axes handle
            axHandle = findobj(testCase.FigNumeric, 'Type', 'axes');
            
            % Zoom in to show only part of the data
            timeRange = testCase.TimeVector(end) - testCase.TimeVector(1);
            zoomWindow = timeRange * 0.3; % Show 30% of data
            xlim(axHandle, [testCase.TimeVector(1), testCase.TimeVector(1) + zoomWindow]);
            
            % Call zoom callback to update slider
            zoomObj = zoom(testCase.FigNumeric);
            zoomCallback = get(zoomObj, 'ActionPostCallback');
            zoomCallback([],[]);
            
            % Record current view
            initialView = xlim(axHandle);
            
            % Simulate moving the slider to 50% position
            targetPos = (timeRange - zoomWindow) * 0.5;
            set(hSlider, 'Value', targetPos);
            
            % Call slider callback
            sliderCallback = get(hSlider, 'Callback');
            sliderCallback(hSlider, []);
            
            % Get new view
            newView = xlim(axHandle);
            
            % Verify view has moved by the expected amount
            expectedStart = testCase.TimeVector(1) + targetPos;
            testCase.verifyEqual(newView(1), expectedStart, 'AbsTol', 0.01, ...
                'Slider did not correctly scroll the view');
            testCase.verifyEqual(diff(newView), diff(initialView), 'AbsTol', 0.01, ...
                'View width changed after scrolling');
        end
        
        function testMultipleFigureHandling(testCase)
            % Test slider works correctly when multiple figures are open
            fig1 = figure('Name', 'Slider Test - Fig1', 'Visible', 'off');
            plot(1:10, sin(1:10));
            title('Figure 1');
            
            fig2 = figure('Name', 'Slider Test - Fig2', 'Visible', 'off');
            plot(1:20, cos(1:20));
            title('Figure 2');
            
            % Add sliders to both figures
            hSlider1 = slider(fig1);
            hSlider2 = slider(fig2);
            
            % Verify both sliders exist
            testCase.verifyTrue(ishandle(hSlider1), 'Slider not created for figure 1');
            testCase.verifyTrue(ishandle(hSlider2), 'Slider not created for figure 2');
            
            % Verify sliders are in their respective figures
            testCase.verifyEqual(ancestor(hSlider1, 'figure'), fig1, 'Slider 1 not in figure 1');
            testCase.verifyEqual(ancestor(hSlider2, 'figure'), fig2, 'Slider 2 not in figure 2');
        end
    end
end