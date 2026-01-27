# Diagnose (biosigmat)

You are reviewing a MATLAB function in the **biosigmat** library and must produce a concise, actionable diagnosis of what needs to be fixed for it to comply with the repository standards.

## Input
The user will provide one of:
- A file path and/or the full function code
- A selection/snippet of the function code

If the user only provides a snippet, ask for the full file (or at least the header + signature + input parsing region + any sections using time/sample indices).

## Output format
Return:
- **Must fix**: items required by the library standards or that are likely bugs
- **Should fix**: strong recommendations for consistency/maintainability
- **Questions** (optional): only when a design/API decision is ambiguous

Keep each bullet concrete and phrased as an action.

## Standards checklist (apply to this repo)
Use the project conventions defined in `docs/contribute/contribution-guide.md` and `docs/contribute/code-style-guide.md`, and follow patterns in existing functions under `src/`.

### 1) Mandatory function structure
- Ensure the function begins with `narginchk` and `nargoutchk`.
- Ensure an `inputParser` block appears immediately after the header comment.
- Validate all inputs via `addRequired`/`addParameter` and then `parse`.

### 2) Header comment format
- First line: `FUNCTIONNAME` in uppercase + one-line description.
- Main usage paragraph(s) that integrate parameter descriptions (no separate “Inputs/Outputs” sections).
- Include `Example:` with runnable code (and a plot if meaningful).
- Include `See also ...`.
- Optionally include `Status: Alpha/Beta` if that is used in the module.

### 3) API consistency
- Prefer name-value pairs (`varargin`) for optional behavior, consistent with other `src/` functions.
- Avoid positional optional arguments unless the surrounding module consistently uses them.
- Use naming conventions consistent with the repo (short lowercase names for common variables like `fs`, camelCase for longer ones).

### 4) Units and indexing correctness (bug-prone)
- Verify whether time indices are in **seconds** or **samples** and make the doc + code consistent.
- If converting time (s) to samples, use MATLAB 1-based indexing (`1 + round(t*fs)`), consistent with the library.
- Ensure window widths are in seconds and converted using `round(windowSec*fs)`.

### 5) Edge cases and numerical robustness
- Handle empty detections (e.g., empty `nD`) gracefully: return `NaN` outputs consistent with other functions.
- Ensure interpolation has sufficient points (e.g., `interp1` with `pchip` needs ≥2 unique x values).
- Clamp indices to `[1, length(signal)]` and de-duplicate as needed.

### 6) Naming/readability
- Rename cryptic variables to meaningful names aligned with domain meaning (e.g., `searchMatrix`, `windowSec`, `anchorSamples`).
- Keep boolean flags as `isX`/`useX` and validate `islogical(x) && isscalar(x)`.

### 7) Contribution requirements (call out, don’t implement unless asked)
- For functions in `src/` (except `src/tools/`), the repo expects a corresponding test under `test/` and an example under `examples/`.
- **Do not create tests/examples unless the user explicitly asks.** Mention what would be expected and ask if they want them.

## Behavior
- Be direct and specific.
- If you suspect a bug, explain why it’s a bug (units mismatch, off-by-one indexing, etc.).
- Prefer pointing to an existing function in the same module as a style reference (e.g., `src/ppg/pulsedelineation.m`).
