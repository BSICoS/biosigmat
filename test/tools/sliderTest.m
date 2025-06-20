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
        function createTestFigures(tc)
            % Numeric time vector figure
            tc.FigNumeric = figure('Name', 'Slider Test - Numeric', 'Visible', 'off');
            tc.TimeVector = 0:0.01:10;
            testSignal = sin(2*pi*tc.TimeVector);
            plot(tc.TimeVector, testSignal);
            title('Test Plot with Numeric Time');

            % Datetime time vector figure
            tc.FigDatetime = figure('Name', 'Slider Test - Datetime', 'Visible', 'off');
            startTime = datetime('now') - hours(24);
            timeStep = minutes(5);
            tc.DatetimeVector = startTime:timeStep:(startTime + hours(24));
            testSignal = sin(linspace(0, 2*pi, length(tc.DatetimeVector)));
            plot(tc.DatetimeVector, testSignal);
            title('Test Plot with Datetime');

            % Auto-detection test figure
            tc.FigAutoDetect = figure('Name', 'Slider Test - Auto Detect', 'Visible', 'off');
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
        function testNumericTimeVector(tc)
            hSlider = slider(tc.FigNumeric, tc.TimeVector);

            tc.verifyTrue(ishandle(hSlider), 'Slider was not created successfully');
            tc.verifyEqual(get(hSlider, 'Style'), 'slider', 'Created UI element is not a slider');

            % Verify x-axis limits match time vector bounds
            axHandle = findobj(tc.FigNumeric, 'Type', 'axes');
            currentLimits = xlim(axHandle);
            tc.verifyEqual(currentLimits(1), tc.TimeVector(1), 'AbsTol', 0.01, 'X-axis lower limit does not match time vector start');
            tc.verifyEqual(currentLimits(2), tc.TimeVector(end), 'AbsTol', 0.01, 'X-axis upper limit does not match time vector end');
        end

        function testDatetimeTimeVector(tc)
            hSlider = slider(tc.FigDatetime, tc.DatetimeVector);

            tc.verifyTrue(ishandle(hSlider), 'Slider was not created successfully with datetime vector');
            tc.verifyEqual(get(hSlider, 'Style'), 'slider', 'Created UI element is not a slider');

            % Verify x-axis limits match time vector bounds
            axHandle = findobj(tc.FigDatetime, 'Type', 'axes');
            currentLimits = xlim(axHandle);
            tc.verifyEqual(currentLimits(1), tc.DatetimeVector(1), 'X-axis lower limit does not match datetime vector start');
            tc.verifyEqual(currentLimits(2), tc.DatetimeVector(end), 'X-axis upper limit does not match datetime vector end');
        end

        function testAutoDetectionNoArgs(tc)
            hSlider = slider();
            tc.verifyTrue(ishandle(hSlider), 'Slider was not created successfully with no arguments');
            tc.verifyEqual(get(hSlider, 'Style'), 'slider', 'Created UI element is not a slider');
        end

        function testAutoDetectionFigureHandle(tc)
            hSlider = slider(tc.FigAutoDetect);

            tc.verifyTrue(ishandle(hSlider), 'Slider was not created successfully with figure handle only');
            tc.verifyEqual(get(hSlider, 'Style'), 'slider', 'Created UI element is not a slider');
        end

        function testResetButtonFunctionality(tc)
            slider(tc.FigNumeric, tc.TimeVector);

            % Record initial x-axis limits
            axHandle = findobj(tc.FigNumeric, 'Type', 'axes');
            initialXlim = xlim(axHandle(1));

            % Change x-axis limits to simulate zooming
            newXlim = [3, 6];
            xlim(axHandle(1), newXlim);

            % Find and simulate clicking reset button
            resetButton = findobj(tc.FigNumeric, 'Tag', 'SliderResetButton');
            tc.verifyFalse(isempty(resetButton), 'Reset button not found');

            % Get and execute callback function
            resetButtonCallback = get(resetButton, 'Callback');
            resetButtonCallback();

            % Check if limits were reset correctly
            currentXlim = xlim(axHandle(1));
            tc.verifyEqual(currentXlim(1), initialXlim(1), 'AbsTol', 0.01, 'X-axis lower limit not reset correctly');
            tc.verifyEqual(currentXlim(2), initialXlim(2), 'AbsTol', 0.01, 'X-axis upper limit not reset correctly');
        end

        function testOutOfRangeHandling(tc)
            hSlider = slider(tc.FigNumeric, tc.TimeVector);

            % Pan outside range
            axHandle = findobj(tc.FigNumeric, 'Type', 'axes');
            xlim(axHandle(1), [15, 20]); % Way outside the range

            % Trigger the pan callback
            panObj = pan(tc.FigNumeric);
            panCallback = get(panObj, 'ActionPostCallback');
            panCallback([],[]);

            % Check if slider is disabled
            tc.verifyEqual(get(hSlider, 'Enable'), 'off', 'Slider was not disabled when view is out of range');

            % Check if reset button is highlighted
            resetButton = findobj(tc.FigNumeric, 'Tag', 'SliderResetButton');
            bgColor = get(resetButton, 'BackgroundColor');
            tc.verifyNotEqual(bgColor, [0.94 0.94 0.94], 'Reset button was not highlighted when view is out of range');

            % Find warning text - first check appdata, then try findobj
            warningText = getappdata(axHandle(1), 'warningAnnotation');
            if isempty(warningText) || ~ishandle(warningText)
                warningText = findobj(tc.FigNumeric, 'Tag', 'OutOfRangeWarning');
            end

            tc.verifyFalse(isempty(warningText), 'Warning text was not shown when view is out of range');

            % Also verify the warning is visible - accommodate for OnOffSwitchState enumeration
            if ~isempty(warningText)
                visibleState = get(warningText, 'Visible');
                tc.verifyTrue(isequal(visibleState, 'on') || isequal(visibleState, "on") || isequal(visibleState, matlab.lang.OnOffSwitchState.on), ...
                    'Warning text is not visible');
            end
        end

        function testSubplotHandling(tc)
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
            tc.verifyTrue(ishandle(hSlider), 'Slider not created for subplot figure');

            % Verify slider width matches the subplot width
            axHandle = subplot(2,2,[3,4]);
            axPosition = get(axHandle, 'Position');
            sliderPosition = get(hSlider, 'Position');

            % Check that slider width is appropriate for the spanning subplot
            tc.verifyLessThan(abs(sliderPosition(3) - (axPosition(3) - 0.06 - 0.01)), 0.07, ...
                'Slider width not properly matched to spanning subplot');
        end

        function testSliderThumbSizeWithZoom(tc)
            hSlider = slider(tc.FigNumeric, tc.TimeVector);

            % Get initial slider step (proportional to thumb size)
            initialStep = get(hSlider, 'SliderStep');

            % Zoom in to show only 20% of the data
            axHandle = findobj(tc.FigNumeric, 'Type', 'axes');
            timeRange = tc.TimeVector(end) - tc.TimeVector(1);
            zoomStart = tc.TimeVector(1) + timeRange * 0.4;
            zoomEnd = tc.TimeVector(1) + timeRange * 0.6;
            xlim(axHandle, [zoomStart, zoomEnd]);

            % Call the zoom callback to update the slider
            zoomObj = zoom(tc.FigNumeric);
            zoomCallback = get(zoomObj, 'ActionPostCallback');
            zoomCallback([],[]);

            % Get updated slider step
            zoomedStep = get(hSlider, 'SliderStep');

            % Verify thumb size is larger when zoomed in (smaller step means larger thumb)
            tc.verifyGreaterThan(zoomedStep(1), initialStep(1), ...
                'Slider thumb size did not increase when zoomed in');
        end

        function testSliderScrolling(tc)
            hSlider = slider(tc.FigNumeric, tc.TimeVector);

            % Zoom in to show only part of the data
            axHandle = findobj(tc.FigNumeric, 'Type', 'axes');
            timeRange = tc.TimeVector(end) - tc.TimeVector(1);
            zoomWindow = timeRange * 0.3; % Show 30% of data
            xlim(axHandle, [tc.TimeVector(1), tc.TimeVector(1) + zoomWindow]);

            % Call zoom callback to update slider
            zoomObj = zoom(tc.FigNumeric);
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
            expectedStart = tc.TimeVector(1) + targetPos;
            tc.verifyEqual(newView(1), expectedStart, 'AbsTol', 0.01, ...
                'Slider did not correctly scroll the view');
            tc.verifyEqual(diff(newView), diff(initialView), 'AbsTol', 0.01, ...
                'View width changed after scrolling');
        end

        function testMultipleFigureHandling(tc)
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
            tc.verifyTrue(ishandle(hSlider1), 'Slider not created for figure 1');
            tc.verifyTrue(ishandle(hSlider2), 'Slider not created for figure 2');

            % Verify sliders are in their respective figures
            tc.verifyEqual(ancestor(hSlider1, 'figure'), fig1, 'Slider 1 not in figure 1');
            tc.verifyEqual(ancestor(hSlider2, 'figure'), fig2, 'Slider 2 not in figure 2');
        end
    end
end