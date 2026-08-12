# AGENTS

Persistent project rules for coding agents working in Biosigmat:

1. Biosigmat is the MATLAB implementation of the Biosiglib contracts. The pinned Biosiglib JSON specifications and shared cases define normative behavior.
2. Public functions under `src/` require specifications; functions inside `private/` do not.
3. Preserve formulas, units, defaults, filtering direction and phase, NaN behavior, edge cases, physiological meaning, and reference results. Ask the maintainer before changing scientific behavior.
4. Use idiomatic MATLAB APIs and internals when they do not alter the contract. MATLAB-specific API, toolbox, error, and private-function tests remain local.
5. `biosiglib.lock` contains one exact lowercase Biosiglib commit. Merged code must pass every specification and shared case in that commit; partial work belongs in issues or pull requests.
6. Resolve Biosiglib from `BIOSIGLIB_ROOT`, falling back to a sibling `../biosiglib` checkout. Consume its fixtures and cases directly rather than copying them here.
7. The normal full MATLAB suite must validate the lock, verify the checkout commit, and execute all discovered shared cases.
8. Put examples under `examples/` and describe what they teach a user, not their implementation ancestry.
9. Documentation under `docs/api/` comes from MATLAB headers and links directly to example source files. Edit the source and run `scripts/docs/updateDocs.m`; do not commit generated Markdown.
10. Use English for code, comments, filenames, and technical documentation. Avoid generic resource APIs and unnecessary cross-language infrastructure.
