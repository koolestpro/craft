# FilmCraft: role in the pipeline, and what it needs to start producing

Decision (2026-10-14): **FilmCraft (the ArtCraft Premiere Pro replica) becomes the
editing and finishing backbone for khutba/lecture videos. video-gen stays the
generative and asset layer.** This doc is the readiness checklist: what to install,
how to build, what FilmCraft takes over, what stays with video-gen, and the TTS
question.

## Why this split

Our raw material is real lecture footage. The job is cut, grade, title, caption,
mix and export. That is a deterministic NLE's job, not a prompt-driven ffmpeg
recipe. FilmCraft is agent-native (650+ engine commands, a JSON control channel
and an MCP server), so it also slots into the one-command pipeline (Phase 7)
instead of fighting it.

FilmCraft and video-gen are layers, not rivals:

- **FilmCraft = the spine.** Import, multicam, trims, Lumetri grade, titles,
  captions, audio mixer and loudness (ITU-R BS.1770 / EBU R128), export to
  ProRes / H.264 / DNxHR, plus interchange (FCP7 XML, FCPXML, OTIO, EDL, AAF, OMF).
- **video-gen = the asset layer.** Fills the gaps FilmCraft does not and should
  not own: generated b-roll and avatars, stock search, SFX/music sourcing, and
  non-English voiceover.

## Source

- On this machine: `/Users/mac/craft/filmcraft`
- Origin: `git@github.com:koolestpro/filmcraft.git` (our fork).
  Upstream: `storytold/filmcraft`. Version 0.6.0, edition 2024, `rust-version 1.95`,
  dual licence MIT OR Apache-2.0.
- Sibling apps in the same suite (not used for video): PhotoCraft (Photoshop),
  VectorCraft (Illustrator), LightCraft (Lightroom), EffectCraft (After Effects),
  DesignCraft (InDesign), PdfCraft (Acrobat), plus CADCraft, WordCraft, DeckCraft,
  GridCraft, SoundCraft.

## Prerequisites (status as of 2026-10-14)

| Need | Status | Action |
|---|---|---|
| Rust toolchain >= 1.95 (edition 2024) | **Missing** (`rustc`/`cargo`/`rustup` not installed) | install rustup, then `rustup default stable` |
| Xcode Command Line Tools (clang 17) | Present (`/Library/Developer/CommandLineTools`, SDK 26.1) | none |
| Network to GitHub (craft-ui git dep) | Reachable (`git ls-remote storytold/craft-libs` OK) | none; first build fetches `craft-ui` and crates.io |
| Disk free space | **66 GiB free (67% full)** after the 2026-10-14 cleanup | none now; was 6.1 GiB |
| ffmpeg | Present (9.0.2) | not needed by FilmCraft at runtime (test oracle only) |
| Optional `CRAFT_FONTS_DIR` | not needed | only for Japanese fonts; skip |

### Disk

A 343k-line Rust workspace with 45 crates, candle (ML), egui and wgpu needs a large
`target/` (roughly 10 to 30 GB for release, more if debug and `cargo xtask ci` are
run). Free space was 6.1 GB (97% full) on 2026-10-14, not enough. After cleanup it is
**66 GiB (67% full)**, enough. Build into the repo `target/` on the same fast disk; do
not move it to an external slow volume. The Kokoro voice pack (336 MB) and any Whisper
models download later, at runtime, separately.

What the cleanup removed (all regenerable): system/app caches (`~/Library/Caches`),
`~/.npm` cache, `~/.cache/codex-runtimes` and `~/.cache/uv`, Claude app caches, Chrome
downloaded models and updater, temp files, the WhatsApp local media cache (61 GB,
re-downloads from the phone), Downloads installers/duplicates, and the anythingllm
workspace. Left in place at the user's choice: the Claude Cowork VM (16 GB) and
sessions (10 GB), Photos analysis (6.6 GB), CapCut projects (8 GB) and Chrome profiles.

## Build

Minimal headless editor (no speech):
```sh
cd /Users/mac/craft/filmcraft
cargo build --release -p filmcraft-cli
```

Headless editor with Whisper speech-to-text:
```sh
cargo build --release -p filmcraft-cli --features whisper
```

Desktop app with both speech features (needed for the built-in TTS):
```sh
cargo build --release -p filmcraft
# features: whisper, neural-voices
cargo build --release -p filmcraft --features whisper,neural-voices
```

Speech features are **off by default** and never built for the web:
- `whisper`: Whisper speech-to-text on candle (CPU), model downloads.
  Models `whisper-tiny` / `whisper-base` (default) / `whisper-small`, multilingual,
  downloaded on request into `<data dir>/models/<id>/`.
- `neural-voices`: Kokoro-82M neural TTS on candle (CPU) plus its download.

Note: `apps/filmcraft-cli/Cargo.toml` only forwards `whisper`, not `neural-voices`,
so **headless TTS over the CLI/MCP is not compiled today**. Two ways to get TTS:
1. Run the desktop app (`filmcraft --control 9876`) and drive it over the MCP bridge.
2. Add one line to our fork: in `apps/filmcraft-cli/Cargo.toml`,
   `neural-voices = ["filmcraft-engine/neural-voices"]`, then build the CLI with it.
   This is the preferred path for the automated pipeline (option 2).

## Drive it (MCP and CLI)

The repo ships `.mcp.json` registering `filmcraft` (bridge) and `filmcraft-headless`
(demo). Both point at `target/release/filmcraft-cli`, so build first.
```sh
# register by hand for another MCP client
claude mcp add filmcraft-headless -- /abs/path/target/release/filmcraft-cli mcp --demo
# bridge to a running desktop app (needed for TTS)
./target/release/filmcraft --control 9876 &
```
Headless CLI examples:
```sh
filmcraft-cli commands razor
filmcraft-cli --project p.fcproj --save import lecture.mp4 vo.wav
filmcraft-cli --project p.fcproj export out.mp4 --preset "YouTube 1080p Full HD"
```

## What FilmCraft takes over vs what stays in video-gen

| Task | Goes to FilmCraft | Stays in video-gen |
|---|---|---|
| Cut, trim, multicam, assemble | yes (timeline, ripple/roll/slip/slide, razor) | - |
| Grade / look | yes (Lumetri Basic/Creative/Curves/Wheels/HSL/Vignette, scopes) | - |
| Titles, lower thirds, captions | yes (text engine, caption tracks, SRT/WebVTT/SCC) | - |
| Audio mix | yes (mixer, EQ/dynamics/limiter, ducking, automation, BS.1770 / R128) | - |
| Export / delivery | yes (H.264+AAC, ProRes 422 HQ, DNxHR, MXF; interchange) | - |
| Thumbnails from a frame | yes (`file.exportFrame`, or keep the ffmpeg step) | - |
| Video / avatar generation | no | yes (inference.sh models, HeyGen) |
| Stock search (Pexels/Pixabay) | import only | yes (search/download) |
| SFX and music sourcing (Freesound) | placement/mix only | yes (search/download) |
| Voiceover, English | yes, native (Kokoro-82M) | fallback (OpenAI/Groq TTS) |
| Voiceover, Arabic / Yoruba | no | yes (Groq Orpheus), then import the WAV |
| Posters | no (that is DesignCraft / PhotoCraft / VectorCraft territory) | poster.py stays |

## The TTS voiceover question

FilmCraft **has** built-in TTS (`crates/tts`, engine commands `tts.*`:
`tts.voices`, `tts.preview`, `tts.create`, `tts.edit`, `tts.inspect`, `tts.render`,
`tts.downloadVoices`). It can synthesize, write `Narration <n>.wav`, import it and
place it on an audio track in one undoable step, with pitch and pace control.

But its scope is narrow:
- **Languages: English (United States) only.** `filmcraft-tts::LANGUAGES` is just
  `en-US`, and `filmcraft-tts-text` (the normalizer and phonemizer) is English only.
  Kokoro-82M's model card lists more languages, but this implementation ships and
  tests English only. **No Arabic, no Yoruba.**
- Nice voices need a download: Kokoro-82M, 9 US English voices, 336 MB, SHA-256
  checked (`tts.downloadVoices`). The no-download built-in voices are robotic.
- Speed: about 2x real time on CPU.

So the answer to "can we move the voiceover into FilmCraft": **English, yes. Arabic
and Yoruba, no, not today.** For the khutba work (Yoruba and English):
- Keep the Yoruba voiceover in video-gen (Groq Orpheus, `text-to-speech.skill`),
  export a WAV, and import it into FilmCraft for placement, ducking and R128 master.
- English narration can be generated natively in FilmCraft with Kokoro, no external key.
- Every external voiceover still gets the FilmCraft mixer, ducking and loudness pass,
  which is the upgrade over the current ffmpeg `amix`/`loudnorm` recipe.

## Known FilmCraft gaps (from its own docs)

- Alpha. Self-reported: ~86% feature breadth, ~56% "ready for real work" against
  Premiere Pro 26.5.2.
- Cannot open `.prproj`; bring sequences over as FCP7 XML / AAF / OTIO.
- No plugin hosting (VST3/AU, OpenFX).
- Lumetri, keys and export rendering still partly CPU; H.265 export is
  hardware-only; no AV1 export.
- Real-world camera/phone media less tested than conformance streams.

## Verify

```sh
cd /Users/mac/craft/filmcraft
./target/release/filmcraft-cli --version
./target/release/filmcraft-cli commands | wc -l        # expect 650+
./target/release/filmcraft-cli --demo inspect sequence
```
Drive the 2026-10-09 khutba source through one real import, one grade, one caption
track and one export, then review the frame with `render_frame`.

## Next

1. ~~Free ~30 GB of disk.~~ Done 2026-10-14 (66 GiB free).
2. Install rustup + Rust >= 1.95.
3. Build `filmcraft-cli` (with `whisper`) and register the MCP server.
4. Add the `neural-voices` passthrough to our fork's CLI so headless TTS works.
5. Pilot: replace the ffmpeg assembly in `khutba/pipeline/khutba.py` for one clip,
   compare against the approved 2026-10-09 clip.
6. Freeze roles and update `docs/ROADMAP_VIDEO_PIPELINE.md` Phase 3/4/7.
