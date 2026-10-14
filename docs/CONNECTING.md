# Connecting Craft to any project

Craft is shared, like `video-gen`. A project connects to it; it never vendors it. There
are two connection methods, and most projects use both.

## 1. CLI on PATH (works everywhere on this machine)

`~/craft/bin` is on `PATH` (added to `~/.zshrc`), so any shell or project can call
`filmcraft-cli`, `photocraft-cli`, `vectorcraft-cli`, `designcraft-cli`, and so on.

In a project script, resolve the CLI in this order (see
`nasheed/khutba/pipeline/designcraft/make_poster.py` for a working example):

```python
CLI_CANDIDATES = [os.environ.get("FILMCRAFT_CLI"),
                  os.path.expanduser("~/craft/bin/filmcraft-cli"),
                  "/Users/mac/craft/bin/filmcraft-cli",
                  shutil.which("filmcraft-cli")]
```

Set a per-project override when needed, for example in a `.env`:
`FILMCRAFT_CLI=/Users/mac/craft/bin/filmcraft-cli`.

## 2. MCP at user scope (register once, every project sees it)

```sh
# headless (no window)
claude mcp add -s user filmcraft -- "$HOME/craft/bin/filmcraft-cli" mcp --demo
# bridge to a running desktop app (needed for the built-in TTS / Text to Speech panel)
filmcraft --control 9876 &
claude mcp add -s user filmcraft -- "$HOME/craft/bin/filmcraft-cli" mcp --bridge 127.0.0.1:9876
```

Registered on this machine (2026-10-14) in Claude (user scope), Codex
(`~/.codex/config.toml`) and opencode (`~/.config/opencode/opencode.jsonc`): `filmcraft`,
`cadcraft`, `designcraft`, `effectcraft`, `lightcraft`, `pdfcraft`, `photocraft`,
`vectorcraft`, `wordcraft`. Because it is user scope, they are available in every
Cowork/Claude/Codex/opencode project with no per-project config.

To register on a new machine, loop the apps:

```sh
for app in filmcraft cadcraft designcraft effectcraft lightcraft pdfcraft photocraft vectorcraft wordcraft; do
  claude mcp add -s user "$app" -- "$HOME/craft/bin/$app-cli" mcp
done
```

(Add `--demo` to the filmcraft args if you want it to open the demo project.)

## 3. On a new machine

```sh
git clone --recurse-submodules git@github.com:koolestpro/craft.git ~/craft
cd ~/craft && ./build.sh
# then add to the shell profile:
export PATH="$HOME/craft/bin:$PATH"
```

## Per-project pointer (recommended)

Drop a short file in the project so agents and humans know Craft is available, without
copying anything. Pattern, mirroring how `video-gen` is referenced:

> Craft (shared tool, not vendored): repo `~/craft`; CLIs on `PATH` from `~/craft/bin`;
> MCP registered at user scope. See `~/craft/README.md` and
> `~/craft/docs/CONNECTING.md`.

## Keeping current

```sh
~/craft/update.sh          # is upstream ahead of us?
~/craft/update.sh --apply  # pull the builder's latest into our forks and re-pin
```
