# `slider`

Creates and adds a scroll slider to a figure with time-based plots.

## Syntax

```matlab
function hSlider = slider(varargin)
```

## Description

HSLIDER = SLIDER() adds a horizontal slider at the bottom of the current figure to allow scrolling through time-based plots. The function automatically detects the time vector from existing plot data and works with both numeric and datetime time vectors. The slider integrates with MATLAB's zoom and pan functionality.

HSLIDER = SLIDER(TIMEVECTOR) adds a slider to the current figure using the specified time vector TIMEVECTOR instead of auto-detection.

HSLIDER = SLIDER(FIGHANDLE) adds a slider to the specified figure FIGHANDLE with auto-detected time vector.

HSLIDER = SLIDER(FIGHANDLE, TIMEVECTOR) adds a slider to the specified figure FIGHANDLE using the specified time vector TIMEVECTOR.

The slider automatically adjusts its behavior when the view is zoomed or panned, and provides a reset button to return to the full view. When the view is outside the data range, the slider is disabled and a warning message is displayed.

## Source Code

[View source code](https://github.com/BSICoS/biosigmat/tree/main/src/tools/slider.m)

## Examples

```matlab
% Plot the signal
figure;
plot(t, x);
xlabel('Time (s)');
ylabel('Amplitude');
title('Long Time Series with Interactive Slider');

% Add slider for navigation
slider();
```

## See Also

- ZOOM
- PAN
- UICONTROL
- XLIM

- [API Reference](../index.md)

---

**Module**: [TOOLS](index.md) | **Last Updated**: 2025-08-08
