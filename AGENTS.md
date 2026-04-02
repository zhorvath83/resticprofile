# AGENTS.md - AI Assistant Guidance for resticprofile

This file is the operational guide for working in this repository. Treat it as the authoritative source for agent behavior inside `resticprofile`.

## Non-Negotiables

- Treat this repository as potentially public and durable. Do not introduce plaintext credentials, access tokens, passwords, or private infrastructure details.
- Do not commit secrets into workflows, Docker build arguments, documentation, examples, or future config files.
- Keep the image non-root by default unless the task explicitly requires a justified exception.
- Preserve compatibility with a read-only root filesystem unless the task explicitly changes that requirement.
- Do not switch pinned dependencies or image references to floating `latest` tags.
- Keep checksum verification for downloaded release assets when touching upstream binary download logic.

## Scope And Priorities

Use these sources in this order:

1. The current files in the repository
2. This `AGENTS.md`
3. More specific `AGENTS.md` files in subdirectories
4. `Dockerfile`
5. `.github/workflows/*`
6. `.github/renovate.json5`
7. `README.md` for the project overview
8. `docs/runtime.md`, `docs/scheduling.md`, `docs/development.md`, and `docs/release.md` for operational detail

## Guide Traversal Rule

When working on any file or subtree, always read `AGENTS.md` files from the repository root down to the target directory.

Practical rule:

1. start at the root guide
2. descend through each parent directory on the path
3. apply the most specific guide last

Today this repository has only the root guide, but keep the traversal rule if more guides appear later.

## Current Repository Shape

This repository currently manages a single container image definition with these main areas:

- `Dockerfile`: multi-stage image build for `resticprofile`, `restic`, and `rclone`
- `.github/workflows/build.yml`: GitHub Actions workflow for multi-arch build, GHCR publish, and vulnerability scanning
- `.github/renovate.json5`: Renovate policy for Dockerfile pins and workflow dependencies
- `README.md`: project overview and quick-start usage
- `docs/`: detailed runtime, scheduling, development, and release documentation
- `.dockerignore`: Docker build context filtering

## Working Rules

- Inspect the touched area before editing; do not assume docs are current.
- Keep changes minimal and consistent with the current image hardening model.
- Prefer the existing download, checksum, and packaging flow over inventing a different build path.
- Preserve inline `# renovate:` annotations when touching version pins.
- When changing runtime paths, user IDs, or filesystem expectations, update `README.md` in the same change.
- Update the matching `docs/*.md` file when changing runtime, maintenance, or release behavior.
- Keep writable runtime paths explicit and minimal. Avoid writing under `/` or introducing implicit stateful locations.
- Prefer deterministic, pinned versions for external binaries and GitHub Actions.
- Keep the workflow publish target on GHCR unless the task explicitly changes registry strategy.
- Avoid image bloat. Add packages only when they are required for actual runtime or build behavior.

## Repo-Wide Anti-Patterns

- Replacing pinned versions with `latest` or untracked floating references
- Downloading external binaries without checksum validation
- Reintroducing root as the default container user
- Adding runtime write requirements outside `/resticprofile` and `/tmp` without documenting them
- Adding implicit Docker `VOLUME` declarations that hide runtime mount behavior
- Introducing registry credentials or other secrets directly in the repository
- Changing workflow or Renovate behavior without checking the related Dockerfile annotations and README expectations

## State To Assume Today

- The repository builds and publishes a hardened `resticprofile` container image to GHCR.
- The image bundles `resticprofile`, `restic`, and `rclone` from upstream release assets.
- The primary use case is non-root scheduled container execution with `supercronic`.
- The image is intended to run as the `restic` user with UID/GID `65532:65532` by default, but orchestration may override that at runtime.
- Read-only root filesystem compatibility is a design goal; writable runtime paths are expected to be `/resticprofile` and `/tmp`.
- Renovate is expected to keep Dockerfile pins and GitHub Action references current.

## Validation And Routing

- After edits, run the smallest relevant validation available for the touched area.
- For workflow-only changes, at minimum check YAML syntax and inspect expressions carefully.
- For Dockerfile changes, prefer a real `docker build` when the local daemon is available.
- When validation cannot run, say which dependency is missing: Docker daemon, network access, credentials, or another environment requirement.
- If a change affects runtime behavior, verify that documentation and image expectations still match.

## Commit Conventions

If the user asks for a commit, follow the existing personal convention style:

- format: `<emoji> <type>(<scope>): <subject>`
- keep the subject short and imperative
- use focused commits instead of bundling unrelated changes

Common types:

- `✨ feat`
- `🐛 fix`
- `📝 docs`
- `♻️ refactor`
- `🔧 build`
- `👷 ci`
- `🧹 chore`
- `🔥 remove`
