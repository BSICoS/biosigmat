% sliderTest.m - Test class for the slider function
%
% Tests covering:
%   - Basic functionality with numeric time vector
%   - Basic functionality with datetime time vector
%   - Auto-detection of time vector

classdef sliderTest < matlab.unittest.TestCase

    methods (TestClassSetup)
        function addCodeToPath(~)
            addpath('../../src/tools');
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
            figNumeric = figure('Name', 'Slider Test - Numeric', 'Visible', 'off');
            timeVector = 0:0.01:10;
            testSignal = sin(2*pi*timeVector);
            plot(timeVector, testSignal);
            hSlider = slider(figNumeric, timeVector);

            tc.verifyTrue(ishandle(hSlider), 'Slider was not created successfully');
            tc.verifyEqual(get(hSlider, 'Style'), 'slider', 'Created UI element is not a slider');
        end

        function testDatetimeTimeVector(tc)
            figDatetime = figure('Name', 'Slider Test - Datetime', 'Visible', 'off');
            startTime = datetime('now') - hours(1);
            timeStep = minutes(5);
            datetimeVector = startTime:timeStep:(startTime + hours(1));
            testSignal = sin(linspace(0, 2*pi, length(datetimeVector)));
            plot(datetimeVector, testSignal);
            hSlider = slider(figDatetime, datetimeVector);

            tc.verifyTrue(ishandle(hSlider), 'Slider was not created successfully with datetime vector');
            tc.verifyEqual(get(hSlider, 'Style'), 'slider', 'Created UI element is not a slider');
        end

        function testAutoDetectionFigureHandle(tc)
            figAutoDetect = figure('Name', 'Slider Test - Auto Detect', 'Visible', 'off');
            autoTimeVector = 1:0.5:20;
            autoTestSignal = cos(autoTimeVector);
            plot(autoTimeVector, autoTestSignal);
            hSlider = slider(figAutoDetect);

            tc.verifyTrue(ishandle(hSlider), 'Slider was not created successfully with figure handle only');
            tc.verifyEqual(get(hSlider, 'Style'), 'slider', 'Created UI element is not a slider');
        end
    end
end