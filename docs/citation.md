---
title: Citation
---

# Cite Biosigmat

Research using Biosigmat should cite both the exact released Biosigmat version
that was executed and the original publications for every scientific method
used.

## Identify the version

Obtain the installed version in MATLAB:

```matlab
biosigmat.version()
```

Open the [Biosigmat collection in Zenodo](https://doi.org/10.5281/zenodo.21774532),
select that version, and cite the version-specific DOI displayed by Zenodo.
The concept DOI above is a stable link to the collection of versions; it does
not identify a particular release and should not replace the version-specific
DOI in a research article.

Zenodo and GitHub provide citation formats generated from the project's
structured metadata.

## Cite the methods

Find the original publications for each method in the
[Biosiglib method catalog](https://bsicos.github.io/biosiglib/methods/).
Biosiglib is the language-independent contract and reference catalog, not the
executable software citation.

## Unreleased code

If the analysis used an unreleased commit, cite the
[Biosigmat repository](https://github.com/BSICoS/biosigmat) together with the
full commit SHA instead of a released version DOI.
