# Releasing Biosigmat

Biosigmat implementation versions are independent from Biosiglib releases.
Releases are source archives from reviewed commits on `main`; MATLAB File
Exchange and `.mltbx` distribution remain outside this procedure.

## Release checklist

1. Update the single version returned by `src/+biosigmat/version.m`.
2. Move user-visible changes from `Unreleased` into a dated changelog entry and
   add `docs/releases/vX.Y.Z.md`.
3. Confirm that `biosiglib.lock` pins the intended exact Biosiglib commit and
   that Biosiglib has not yet released a different commit for this coordinated change.
4. Run the complete MATLAB suite, header validation, and example checks. The
   suite validates the lock and every shared case.
5. Regenerate API/example documentation and run `mkdocs build --strict` with
   `requirements-docs.txt`.
6. Merge the reviewed release PR into `main` and wait for all `main` checks.
7. Create an annotated `vX.Y.Z` tag on that exact merge commit and push it.
8. Verify that the tag workflow creates a prefixed source ZIP using
   `git archive`, extracts it, reruns the MATLAB suite and documentation build
   from the archive, and publishes it with `SHA256SUMS` and committed notes.

The workflow rejects a tag that does not match `biosigmat.version()` and never
introduces a top-level `version.m` that could shadow MATLAB's built-in function.
