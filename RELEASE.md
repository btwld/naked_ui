# Manual Release Process

This repository uses a simple, manual release flow. We manage versions and tags by hand, and rely on a single tag-triggered GitHub Actions workflow (`.github/workflows/release.yml`) to publish to pub.dev via OIDC.

## One-time setup (per package)
- Enable automated publishing on pub.dev:
  - Go to your package on pub.dev → Admin → Automated publishing.
  - Enable “Publishing from GitHub Actions”.
  - Repository: `btwld/naked_ui`.
  - Tag pattern: `v{{version}}`.
  - Optional: Require a GitHub Actions Environment for added protection (configure the same environment name in the workflow if you enable this).
  - If you enable an environment requirement on pub.dev, set it to match the job environment in `release.yml` (currently `Production`), or update the workflow to use your preferred name.

- Note: The first-ever publish of a brand-new package must be done manually using `dart pub publish`.

Official docs: https://dart.dev/tools/pub/automated-publishing

## Release steps (each release)
1) Update the version in `pubspec.yaml` (e.g., `version: 1.2.3`). Make sure the version matches the tag you’ll create.
2) (Optional) Update `CHANGELOG.md` and any release notes.
3) Commit and push your changes to `main` (or the target branch):
   - `git commit -am "chore: release v1.2.3"`
   - `git push`
4) Create and push a tag that matches the configured pattern:
   - `git tag v1.2.3 && git push origin v1.2.3`

## What happens next
- Pushing the tag triggers `.github/workflows/release.yml`.
- The workflow sets up OIDC (via `dart-lang/setup-dart@v1`), installs Flutter, runs analyze/tests, performs a publish dry run, then publishes to pub.dev (`dart pub publish --force`).
- Publication will be accepted by pub.dev only if automated publishing is enabled and the tag matches the `v{{version}}` pattern, and the version in `pubspec.yaml` matches the tag.

## Troubleshooting
- Workflow didn’t trigger: Ensure the tag matches the pattern in `release.yml` (`v[0-9]+.[0-9]+.[0-9]+*`).
- Publish rejected by pub.dev: Verify automated publishing is enabled for this repo and tag pattern, and that `pubspec.yaml` version matches the tag.
- First-time publish: Must be done manually once using `dart pub publish` before automation works for that package.

## Security recommendations
- Add Tag Protection Rules on GitHub to restrict who can push `v*` tags.
- Optionally use a GitHub Actions Environment (with required reviewers) to gate publishing runs.

## Rationale
- Keeps the pipeline minimal (no release-please). You control versioning and tags directly, while CI publishes only on explicit tag pushes.

