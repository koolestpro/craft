# Craft

The Craft App Suite: free, open-source, agent-drivable creative tools from the
ArtCraft team, each a clean-room reimplementation of an Adobe product in pure Rust.
This repo is the **umbrella**: it pins every app as a git submodule and builds their
CLIs into one shared `bin/`, so any project on this machine can use the whole suite
without vendoring it.

This is a shared, cross-project tool, exactly like `video-gen`. Projects connect to
it; they do not copy it in.

## Apps

| App | Adobe product | Package / CLI |
|---|---|---|
| FilmCraft | Premiere Pro | `filmcraft` / `filmcraft-cli` |
| PhotoCraft | Photoshop | `photocraft` / `photocraft-cli` |
| VectorCraft | Illustrator | `vectorcraft` / `vectorcraft-cli` |
| LightCraft | Lightroom | `lightcraft` / `lightcraft-cli` |
| EffectCraft | After Effects | `effectcraft` / `effectcraft-cli` |
| DesignCraft | InDesign | `designcraft` / `designcraft-cli` |
| PdfCraft | Acrobat | `pdfcraft` / `pdfcraft-cli` |
| WordCraft | Word | `wordcraft` / `wordcraft-cli` |
| CadCraft | CAD | `cadcraft` / `cadcraft-cli` |
| ArtCraft Launcher | Creative Cloud launcher | `artcraft-launcher` |

Upstream is `storytold/*`; these submodules point at our `koolestpro/*` forks.

## Layout

```
craft/
  README.md            <- this file (suite overview + connect instructions)
  AGENTS.md            <- rules for agents working in the suite
  build.sh             <- build every app's CLI into ./bin
  bin/                 <- built CLIs, on PATH (gitignored)
  docs/                <- cross-app notes
    FILMCRAFT_SETUP.md <- FilmCraft readiness, build and role in the video pipeline
  <app>/               <- one git submodule per app (its own repo)
```

## Setup on a new machine

```sh
git clone --recurse-submodules git@github.com:koolestpro/craft.git ~/craft
# or, if already cloned:
git submodule update --init --recursive

# Rust >= 1.95 (edition 2024) is required.
rustup default stable

# Build every CLI into ./bin
./build.sh

# Put the suite on PATH (add to ~/.zshrc or ~/.bashrc)
export PATH="$HOME/craft/bin:$PATH"
```

If you prefer to build a single app:

```sh
cd filmcraft
cargo build --release -p filmcraft-cli --features whisper
cp target/release/filmcraft-cli ../bin/
```

## Using it from any project

There are two connection methods, mirroring `video-gen`:

1. **CLI on PATH.** After `./build.sh` and the PATH export, `<app>-cli` is available in
   every shell. Project scripts should resolve it in this order:
   `$<APP>_CLI`, then `$HOME/craft/bin/<app>-cli`, then `PATH`. See
   `khutba/pipeline/designcraft/make_poster.py` in the nasheed project for the pattern.
2. **MCP (user scope).** Register once and every project sees the server. Rebuild the
   CLI first, then:

   ```sh
   claude mcp add -s user filmcraft -- "$HOME/craft/bin/filmcraft-cli" mcp --demo
   # or bridge to a running app (needed for FilmCraft's built-in TTS):
   claude mcp add -s user filmcraft -- "$HOME/craft/bin/filmcraft-cli" mcp --bridge 127.0.0.1:9876
   ```

   Headless mode needs no window; the bridge needs the desktop app started with
   `filmcraft --control 9876`.

## Staying up to date with the original builder

Upstream is the ArtCraft team's `storytold/*` repos (each app has an `upstream` remote).
Our forks carry no local patches, so updates are fast-forwards.

```sh
./update.sh            # report: what is new upstream per app (safe, read-only)
./update.sh --check    # same, exit 1 if anything is behind (used by CI)
./update.sh --apply    # fast-forward our forks, push them, re-pin the submodules, commit
```

- `.github/workflows/upstream-check.yml` runs daily, compares our pinned submodule
  commits to upstream `main`, and opens or comments on an issue when upstream moves.
- Agents: run `./update.sh` at the start of any session that touches Craft, and
  `./update.sh --apply` when the user wants the suite current. If an app ever has local
  commits ahead of upstream (a real fork), `--apply` refuses for that app and says so.

## Rules

- Submodules are pinned; to update an app, commit inside it, then commit the new pin here.
- Never commit built binaries (`bin/` is gitignored) or `target/`.
- Keep project-specific content (job files, styles, lecture content) in the project,
  never in an app submodule.
- No em dashes or en dashes anywhere.
