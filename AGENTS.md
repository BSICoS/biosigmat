# AGENTS.md

- Biosigmat is the MATLAB implementation of the language-independent Biosiglib specifications.
- Biosiglib is the source of truth for normative public algorithm behavior, units, defaults, missing-value handling, edge cases, scientific provenance, shared fixtures, and conformance cases.
- Public functions under `src/` require Biosiglib specifications; functions inside `private/` do not.
- Biosigmat may retain an idiomatic MATLAB API and internal architecture while preserving normative behavior.
- Existing public numerical tests should progressively become Biosiglib conformance cases when their behavior is language-independent.
- MATLAB-specific API, type, toolbox, error, private-function, and implementation-detail tests remain local to Biosigmat.
- Examples remain under `examples/`; corresponding examples across implementations should preserve the same scientific workflow where practical.
- `conformance.json` pins an exact Biosiglib commit.
- `conformant` may only be declared after all applicable shared cases pass.
- External manifest validation must use Biosiglib's validator rather than duplicating JSON Schema validation code.
- Shared fixtures and cases must be consumed from a Biosiglib checkout and not copied back into Biosigmat.
- Resolve the Biosiglib checkout from `BIOSIGLIB_ROOT`, falling back to a sibling `../biosiglib` checkout.
- Code, comments, filenames, and technical documentation must be in English.
- Avoid generic resource APIs and unnecessary cross-language infrastructure.
- Do not change scientific or computational behavior without explicit maintainer review. This includes filtering direction and phase behavior, NaN handling, default filters, default parameters, units, physiological interpretation, and reference-result provenance.
- Treat Biosigmat as the mature starting implementation, not as automatically correct. If Biosigmat and Biosigpy disagree in a scientifically meaningful way, document the disagreement and ask the maintainer before changing either implementation or the Biosiglib specification.
- Do not ask about purely idiomatic differences unless they affect scientific behavior. Examples: zero-based versus one-based internal indexing, exception class names, plotting library choices, or local variable names normally do not require maintainer escalation.

## Local change workflow

- Work in a local checkout for multi-file changes.
- Do not edit files one-by-one through the GitHub web/API connector except for tiny metadata-only changes.
- Make related changes locally, run validation locally where possible, and push one coherent commit or a small coherent commit series.

## Generated documentation

- Documentation under `docs/api/` and generated `docs/examples/` is generated from MATLAB headers and example source files.
- Do not manually edit generated documentation files.
- Edit the relevant MATLAB function headers and example `.m` files instead.
- Regenerate documentation with `scripts/local/updateDocs.m`.
- If generated docs change in a PR, the PR description must state that `updateDocs` was run.
- If `updateDocs` cannot be run, do not hand-edit generated docs as a substitute; document the blocker.
