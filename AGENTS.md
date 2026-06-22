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
