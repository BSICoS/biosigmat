# Contributing

## Set up a development checkout

Clone Biosigmat next to Biosiglib and add the source directory to the MATLAB path:

```matlab
addpath(genpath('src'));
```

The commit in `biosiglib.lock` is the scientific contract used by the test suite. Documentation dependencies are listed in `requirements-docs.txt`.

## Run the checks

```bash
matlab -batch "addpath('scripts/local'); runTests"
```

Every change must preserve the pinned Biosiglib specifications and shared conformance cases. Add or update focused MATLAB tests for implementation-specific behavior.

## Documentation

Public API documentation comes from MATLAB function headers. Put runnable examples under `examples/`; the generator links them from the corresponding API page.

```bash
matlab -batch "addpath('scripts/docs'); updateDocs"
python -m mkdocs build --strict
```

Generated Markdown under `docs/api/` is a build artifact and must not be committed.

## Project rules

- Keep changes small and focused.
- Use English for code, comments, filenames, and technical documentation.
- Preserve scientific formulas, units, defaults, edge cases, and NaN behavior.
- Public functions require tests and Biosiglib specifications; examples are expected outside `tools/`.
- Do not copy specifications, fixtures, or shared cases from Biosiglib.
- Open a pull request only after the complete test suite passes.

Before tagging a release, move its entries from `Unreleased` to a dated version section in `CHANGELOG.md`. The [release workflow](.github/workflows/release.yml) uses that section as the GitHub release notes.
