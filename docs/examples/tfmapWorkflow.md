# TFMAP WORKFLOW

## Description

TFMAP WORKFLOW

**Type**: Workflow

## Workflow Steps

1. Generates a synthetic chirp signal with variable dominant frequency
2. Slices the signal into 20-second segments with 50 overlap
3. Computes power spectral density matrix using nanpwelch
4. Creates a time-frequency plot

## Usage

Run the workflow from the MATLAB command window:

```matlab
run('examples/workflows/tfmapWorkflow.m');
```

## File Location

`examples/workflows/tfmapWorkflow.m`

## See Also

- [Workflows Overview](README.md#workflows)
- [Examples Overview](README.md)

---

**Type**: Workflow | **Last Updated**: 2025-07-24
