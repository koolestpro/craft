# AGENTS.md - working in the Craft suite

The umbrella repo pins every Craft app as a submodule and builds their CLIs into one
shared `bin/`. Read this before changing anything here.

## What this repo is

- One independent repo, `koolestpro/craft`, holding the whole ArtCraft suite so any
  project on this machine can connect to it. It is shared, like `video-gen`.
- The apps are submodules (`storytold` upstream, `koolestpro` forks). Their real work
  happens inside each app repo, not here.

## Session rules

- **Start:** `git submodule update --init --recursive` (or `git pull --rebase` plus
  the same) so every app is present at its pinned commit.
- **Build:** `./build.sh` builds every CLI into `bin/`. Building one app: `cd <app>`
  then `cargo build --release -p <app>-cli`.
- **Do not commit binaries or `target/`.** `bin/` is gitignored on purpose.
- **Updating an app:** commit and push inside the app repo first, then in the umbrella
  `git add <app>` and commit the new pin with a clear message.
- **Never force-push** this repo or any submodule's `main`.
- **Projects connect, they do not vendor.** Project scripts resolve a CLI via
  `$<APP>_CLI`, then `$HOME/craft/bin/<app>-cli`, then `PATH`.

## Documentation

- Update this README and `docs/` in the same session as a change.
- Cross-app setup notes live in `docs/` here. App-specific details live in that app's
  own repo.
- No em dashes or en dashes anywhere. Use a comma, colon or hyphen.

## Machine prerequisites

- Rust >= 1.95 (edition 2024), via rustup.
- macOS: Xcode Command Line Tools.
- Disk: a full release build of the suite needs tens of GB. Keep the disk healthy.
