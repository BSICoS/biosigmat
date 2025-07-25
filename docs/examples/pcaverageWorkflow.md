# PCAVERAGE WORKFLOW

## Description

PCAVERAGE WORKFLOW

**Type**: Workflow

## Workflow Steps

1. Loads respiratory signal from edr_signals.csv
2. Applies detrend to remove linear trends
3. Slices the signal
4. Computes power spectral density segments using nanpwelch

## Usage

Run the workflow from the MATLAB command window:

```matlab
run('examples/workflows/pcaverageWorkflow.m');
```

## File Location

`examples/workflows/pcaverageWorkflow.m`

## See Also

- [Workflows Overview](README.md#workflows)
- [Examples Overview](README.md)

---

**Type**: Workflow | **Last Updated**: 2025-07-25
