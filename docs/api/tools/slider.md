# `slider` - Creates and adds a scroll slider to a figure with time-based plots

## Syntax

```matlab
function hSlider = slider(varargin)
slider(timeVector)    - Adds a slider to current figure with specified time vector
slider(figHandler)    - Adds a slider to specified figure with auto-detected time vector
slider(figHandler, timeVector) - Adds a slider to specified figure with specified time vector
```

## Description

Creates and adds a scroll slider to a figure with time-based plots

## Source Code

[View source code](../../../src/tools/slider.m)

## Input Arguments

- **arg1**: Optional parameter
- **arg2**: Optional parameter

## Output Arguments

- **hSlider**: Handle to the created slider object

## Examples

```matlab
t = 0:0.01:100;
y = sin(t);
figure;
plot(t, y);
hSlider = slider;   Automatically uses current figure and time vector
See also: zoom, pan, uicontrol
```

## See Also

- [TOOLS Module](README.md)
- [API Reference](../README.md)

---

**Module**: TOOLS | **Status**: 🔄 Auto-generated | **Last Updated**: 2025-07-25
