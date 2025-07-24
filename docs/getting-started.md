# Getting Started with biosigmat

Welcome to biosigmat! This guide will help you get up and running with the toolbox for biomedical signal processing.

## Key Concepts

### Signal Processing Pipeline
The typical workflow for biomedical signal processing follows these steps:

1. **Load Data** → 2. **Preprocess** → 3. **Detect Features** → 4. **Analyze** → 5. **Visualize**

### Module Organization
biosigmat is organized into specialized modules:

- **ECG**: Electrocardiography processing (`pantompkins`, `baselineremove`, `sloperange`)
- **PPG**: Photoplethysmography analysis (`pulsedetection`, `pulsedelineation`)
- **HRV**: Heart Rate Variability metrics (`tdmetrics`)
- **Tools**: General utilities (`nanfiltfilt`, `findsequences`, `interpgap`)

### NaN Handling
Many functions in biosigmat handle NaN (Not-a-Number) values gracefully:

```matlab
y = nanfiltfilt(b, a, x);
y = nanfilter(b, a, x);
[pxx, f] = nanpwelch(x, window, noverlap, nfft, fs);
```

## Next Steps

Now that you have the basics:

### Explore Examples
- [ECG Processing Examples](examples/ecg-processing.md)
- [PPG Analysis Examples](examples/ppg-analysis.md)
- [HRV Calculation Examples](examples/hrv-analysis.md)

### Read Documentation
- [Complete API Reference](api/README.md)
- [ECG Module Documentation](api/ecg/README.md)
- [Tools Module Documentation](api/tools/README.md)

## Getting Help

- **Examples**: Check the examples directory for similar problems  
- **Issues**: Report bugs on [GitHub](https://github.com/BSICoS/biosigmat/issues)
