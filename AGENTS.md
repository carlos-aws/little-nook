# Little Nook: agent guide

This guide applies to this repository. Run commands from the `little-nook/`
root unless stated otherwise. This is an independent Git repository beside
`pixel-pals/`; changes here do not require changes to that sibling project.
Keep this guide current when files, workflows, or project conventions change.

## Project and technical baseline

Little Nook is a cozy educational companion game about caring for Pip, a
woodland bear. Its loop is learn, care, earn stars and leaf coins, and decorate
a room. It targets desktop and landscape tablets, with mouse, touch, and
keyboard interaction.

- Engine: Godot **4.7.2 standard**, matching the README and CI workflows.
  The project feature declaration is `4.7`; the .NET editor is not required.
- Language and UI: GDScript, native Godot `Control` nodes, one root scene.
- Rendering: GL Compatibility, a 1440 × 900 logical canvas, and
  aspect-preserving scaling.
- Distribution: Linux x86-64 and single-threaded WebAssembly/WebGL 2 browser
  exports, including an installable offline PWA.
- Tooling: Bash and Python 3 standard-library scripts; optional Node 22+
  and Chromium for browser verification.
- Runtime scope: one local companion and one room. There are no third-party
  plugins, cloud accounts, backend services, ads, or paid items.

Read [README.md](README.md) for player-facing behavior,
[docs/design.md](docs/design.md) for design intent, and
[docs/verification.md](docs/verification.md) for the dated verification record.
That record describes past checks; it is not evidence that a new change passes.

## Annotated directory tree

The tree lists every tracked file at the time this guide was added, plus this
guide. `.import` files are tracked Godot import settings and resource metadata;
their imported binary products live in the ignored `.godot/` cache.
`.gd.uid` files hold stable script resource identifiers.

```text
little-nook/
├── AGENTS.md                         # Agent workflow, architecture, and file map.
├── .gitattributes                    # Line endings, binary types, license whitespace.
├── .gitignore                       # Generated caches, exports, logs, credentials.
├── .github/                         # Repository automation.
│   └── workflows/                   # GitHub Actions workflow definitions.
│       ├── check.yml                # Checks the game and exports Web and Linux.
│       └── pages.yml                # Checks, exports, and publishes Web on main.
├── LICENSE                          # MIT license for original project material.
├── README.md                        # Gameplay, setup, saves, exports, and commands.
├── THIRD_PARTY.md                   # Third-party credits and distribution notices.
├── project.godot                    # Entry scene, renderer, display, audio settings.
├── export_presets.cfg               # Web/PWA and Linux release export presets.
├── play.sh                          # Launches a Linux build or the Godot project.
├── assets/                          # Bundled game art, audio, and fonts.
│   ├── art/                         # Editable illustrations and derived boot image.
│   │   ├── apple.svg                # Apple lesson and tidying artwork.
│   │   ├── apple.svg.import         # Apple texture import settings.
│   │   ├── arrow.svg                # Navigation arrow artwork.
│   │   ├── arrow.svg.import         # Arrow texture import settings.
│   │   ├── bag.svg                  # Bag/shop artwork.
│   │   ├── bag.svg.import           # Bag texture import settings.
│   │   ├── ball.svg                 # Ball/play and tidying artwork.
│   │   ├── ball.svg.import          # Ball texture import settings.
│   │   ├── book.svg                 # Book/English and tidying artwork.
│   │   ├── book.svg.import          # Book texture import settings.
│   │   ├── broom.svg                # Tidying action artwork.
│   │   ├── broom.svg.import         # Broom texture import settings.
│   │   ├── carrot.svg               # Maths/snack artwork.
│   │   ├── carrot.svg.import        # Carrot texture import settings.
│   │   ├── check.svg                # Completion checkmark artwork.
│   │   ├── check.svg.import         # Checkmark texture import settings.
│   │   ├── coin.svg                 # Leaf coin reward artwork.
│   │   ├── coin.svg.import          # Coin texture import settings.
│   │   ├── cushion.svg              # Purchasable cushion decoration.
│   │   ├── cushion.svg.import       # Cushion texture import settings.
│   │   ├── flower.svg               # Flower lesson/shop artwork.
│   │   ├── flower.svg.import        # Flower texture import settings.
│   │   ├── heart.svg                # Care and progress artwork.
│   │   ├── heart.svg.import         # Heart texture import settings.
│   │   ├── home.svg                 # Home navigation artwork.
│   │   ├── home.svg.import          # Home texture import settings.
│   │   ├── icon.svg                 # Application icon and splash source.
│   │   ├── icon.svg.import          # Application icon import settings.
│   │   ├── lamp.svg                 # Reading light decoration.
│   │   ├── lamp.svg.import          # Lamp texture import settings.
│   │   ├── leaf.svg                 # Nature/curiosity artwork.
│   │   ├── leaf.svg.import          # Leaf texture import settings.
│   │   ├── moon.svg                 # Rest/night artwork.
│   │   ├── moon.svg.import          # Moon texture import settings.
│   │   ├── mushroom.svg             # Mushroom decoration artwork.
│   │   ├── mushroom.svg.import      # Mushroom texture import settings.
│   │   ├── picture.svg              # Pressed-leaf picture decoration.
│   │   ├── picture.svg.import       # Picture texture import settings.
│   │   ├── pip.svg                  # Awake companion illustration.
│   │   ├── pip.svg.import           # Awake companion import settings.
│   │   ├── pip_sleep.svg            # Sleeping companion illustration.
│   │   ├── pip_sleep.svg.import     # Sleeping companion import settings.
│   │   ├── plant.svg                # Plant decoration and lesson artwork.
│   │   ├── plant.svg.import         # Plant texture import settings.
│   │   ├── room.svg                 # Main illustrated room background.
│   │   ├── room.svg.import          # Room texture import settings.
│   │   ├── settings.svg             # Grown-ups' settings artwork.
│   │   ├── settings.svg.import      # Settings texture import settings.
│   │   ├── sound.svg                # Sound control artwork.
│   │   ├── sound.svg.import         # Sound texture import settings.
│   │   ├── splash.png               # Boot PNG generated from icon.svg.
│   │   ├── splash.png.import        # Splash texture import settings.
│   │   ├── star.svg                 # Growth star artwork.
│   │   ├── star.svg.import          # Star texture import settings.
│   │   ├── yarn.svg                 # Yarn/play-basket tidying artwork.
│   │   └── yarn.svg.import          # Yarn texture import settings.
│   ├── audio/                       # Original synthesized WAV effects.
│   │   ├── buy.wav                  # Purchase feedback sound.
│   │   ├── buy.wav.import           # Purchase audio import settings.
│   │   ├── complete.wav             # Activity completion sound.
│   │   ├── complete.wav.import      # Completion audio import settings.
│   │   ├── correct.wav              # Correct-answer feedback sound.
│   │   ├── correct.wav.import       # Correct-answer audio import settings.
│   │   ├── soft.wav                 # Gentle interaction sound.
│   │   ├── soft.wav.import          # Gentle audio import settings.
│   │   ├── tap.wav                  # Button/tap feedback sound.
│   │   └── tap.wav.import           # Tap audio import settings.
│   └── fonts/                       # Bundled fonts and original license notices.
│       ├── Fraunces.ttf             # Heading font.
│       ├── Fraunces.ttf.import      # Heading font import settings.
│       ├── Nunito.ttf               # Body/interface font.
│       ├── Nunito.ttf.import        # Body font import settings.
│       ├── OFL-Fraunces.txt          # Fraunces SIL Open Font License notice.
│       └── OFL-Nunito.txt            # Nunito SIL Open Font License notice.
├── docs/                            # Design, verification, and reference images.
│   ├── .gdignore                    # Excludes documentation from Godot importing.
│   ├── design.md                    # Visual direction, interaction, scope.
│   ├── home.png                     # Home screen reference.
│   ├── home.png.import              # Existing tracked home-image import metadata.
│   ├── journal.png                  # Journal/progress screen reference.
│   ├── lesson.png                   # Individual question screen reference.
│   ├── lessons.png                  # Lesson selection screen reference.
│   ├── native.png                   # Native Linux rendering reference.
│   ├── pixel-pals-analysis.md        # Sibling game's architecture and design context.
│   ├── settings.png                 # Grown-ups' preferences screen reference.
│   ├── shop.png                     # Decoration shop screen reference.
│   ├── tidy.png                     # Tidying activity screen reference.
│   └── verification.md              # Dated checks, screenshots, platform limits.
├── licenses/                        # Godot notices copied into exported builds.
│   ├── Godot-COPYRIGHT.txt           # Godot third-party attribution notices.
│   └── Godot-MIT.txt                 # Godot engine MIT license notice.
├── scenes/                          # Godot scene resources.
│   └── main.tscn                    # Root Control node attached to main.gd.
├── scripts/                         # Runtime GDScript.
│   ├── lessons.gd                   # Questions, explanations, seeded generation.
│   ├── lessons.gd.uid               # Stable Lessons script resource identifier.
│   ├── main.gd                      # UI, navigation, interaction, sound, UI checks.
│   ├── main.gd.uid                  # Stable main script resource identifier.
│   ├── nook_state.gd                # Care, rewards, growth, shop, save validation.
│   ├── nook_state.gd.uid            # Stable NookState script resource identifier.
│   ├── save_store.gd                # JSON persistence and backup recovery.
│   ├── save_store.gd.uid            # Stable SaveStore script resource identifier.
│   ├── tidy_bin.gd                  # Native drag-and-drop destination Button.
│   ├── tidy_bin.gd.uid              # Stable TidyBin script resource identifier.
│   ├── tidy_item.gd                 # Draggable Button and drag preview.
│   └── tidy_item.gd.uid             # Stable TidyItem script resource identifier.
├── tests/                           # Tests executed by the Godot runtime.
│   ├── test_rules.gd                # Rules, content, shop, validation, disk saves.
│   └── test_rules.gd.uid            # Stable test script resource identifier.
└── tools/                           # Development scripts, excluded from imports.
    ├── .gdignore                    # Keeps development tools out of asset imports.
    ├── browser_check.mjs            # Chromium/CDP interaction and offline checks.
    ├── check.sh                     # Isolated import, rule, and UI verification.
    ├── export.sh                    # Release exports, notices, Web finalization.
    ├── finalize_web.py              # Generates a scoped, content-versioned worker.
    ├── make_art.py                  # Generates editable SVGs and synthesized WAVs.
    ├── make_splash.gd               # Converts the application icon to boot PNG.
    └── serve.py                     # Local HTTP server for build/web/.
```

Generated or local-only locations, which may appear after running tools:

```text
.git/                         # Git repository metadata.
.godot/                       # Godot editor/import cache; ignored.
build/                        # Release output; ignored.
├── .gdignore                 # Created by export.sh to exclude builds from imports.
├── web/                      # HTML, JS, WASM, PCK, PWA files, and license notices.
└── linux/                    # little-nook.x86_64 executable and license notices.
tools/out/                    # Browser screenshots and diagnostic output; ignored.
export_credentials.cfg        # Local Godot export credentials; ignored.
```

## Architecture and change locations

1. `project.godot` loads `scenes/main.tscn`, whose root runs `scripts/main.gd`.
   Most UI nodes are built in code. Change layout, screen routing, focus,
   dialogs, and input behavior in `main.gd`.
2. `NookState` owns the game model and validation. Keep reward calculations,
   progression, care decay, and purchases here instead of duplicating them in
   UI callbacks. Its explicit `now` arguments allow deterministic rule tests.
3. `Lessons.build(subject, level, rng)` owns lesson content and shuffling.
   Use the supplied `RandomNumberGenerator` so seeded checks remain repeatable.
4. `SaveStore` handles disk operations. The UI displays its error/recovery
   messages; the model validates decoded data.
5. `TidyItem` supplies drag data and previews; `TidyBin` emits destination
   signals. Correct-category checks, tap selection, and completion live in
   `main.gd`.

Follow the existing tab-indented GDScript style, descriptive snake_case names,
typed fields where useful, and existing UI helpers. Preserve tracked script
UIDs when moving or renaming scripts. Keep changes to game rules, UI, content,
and generated artwork easy to review.

## Gameplay and content contracts

These describe current behavior. If a task intentionally changes a rule,
update its implementation, affected tests, and player documentation together.

| Activity | Content | Care provided |
| --- | --- | --- |
| Snack time | Three maths questions | Food |
| Story time | Three English questions | Joy |
| Wonder time | Three science questions | Curiosity |
| Tidy time | Six objects sorted into three destinations | Tidiness |
| A little rest | Rest over real time | Energy |

- Each lesson has three distinct questions. Each question has three distinct
  choices and exactly one correct answer. The question dictionary contains
  `prompt`, `answer`, `choices`, `icon`, and `fact` (the explanation).
- Maths progresses from addition/counting to subtraction and equal groups.
  English covers letters, rhymes, spelling, vocabulary, sentences, and grammar.
  Science covers nature, animals, plants, senses, weather, and basic physics.
- Wrong answers allow retries. After two misses, a hint identifies the correct
  option; the player still selects it. Reward only completed activities,
  once per round, including completion with help.
- A completed activity restores 30 points of the related need and costs
  3 energy. Default daily growth allowance is six stars; the preferences UI
  offers three, six, or nine. A round earns one star while below the cap.
- Coins are three per starred round or one per practice round, plus two for
  a perfect round. The star cap never disables care or further practice.
- Needs have a 25-point floor. Time-away calculation is capped at 48 hours;
  sleeping restores 18 energy per hour and ends when energy reaches 100.
- Five growth stages use total-star thresholds of 0, 12, 36, 75, and 120.
  Advancing also requires 2, 5, 10, and 14 days respectively in the preceding
  stage; these are not simply days since first installation.
- Subjects have three adaptive levels. Two perfect rounds raise a subject
  one level; a round with a mistake lowers it one level. Preferences can
  choose a fixed lesson level.
- Keep the forgiving, untimed activity design, readable explanations, large
  controls, visible focus, read-aloud support, and reduced-motion preference.
  Tidying must remain usable through both dragging and selecting/tapping.
- Shop IDs are persisted in `owned` and `equipped`; changing them requires
  considering existing saves. Bought decorations can be toggled for free.

## Saves and test isolation

The current save schema is version 1. `NookState.fresh()` supplies defaults;
`NookState.validate()` checks types, clamps ranges, and filters stored IDs.
Preserve existing progress when adding fields or changing the schema, with
explicit migration behavior if needed.

- Active save: `user://progress.json`.
- On a default Linux installation:
  `~/.local/share/Little Nook/progress.json`.
- Browser progress uses Godot's IndexedDB-backed storage for the site's
  origin. Native and browser saves are independent.
- Writes go through `.tmp`, preserve a valid previous save as `.bak`, then
  rename the new file into place. Loading falls back to `.bak`; an
  unrecoverable primary is preserved as `.corrupt`.
- Preserve checks for failed writes, valid-backup retention, and recovery.
  Do not replace player saves with test fixtures.
- Autosave runs every 30 seconds and on relevant actions and lifecycle events.
  `--demo` and `--ui-test` use fresh in-memory game state and skip normal saves.
  `tools/check.sh` also isolates XDG data/config/cache locations in a temporary
  directory.

## Development commands

Godot and the matching export templates must already be installed for exports.
The wrapper scripts accept `GODOT_BIN=/path/to/godot`. Direct `godot` commands
below assume the executable is on `PATH`.

| Task | Command |
| --- | --- |
| Run from source | `godot --path .` |
| Open editor | `godot --editor --path .` |
| Run existing Linux build, or source fallback | `./play.sh` |
| Import and run rule/UI checks | `./tools/check.sh` |
| Export browser build | `./tools/export.sh Web` |
| Serve browser build on port 8081 | `python3 tools/serve.py` |
| Export Linux executable | `./tools/export.sh Linux` |
| Regenerate SVG art and WAV effects | `python3 tools/make_art.py` |
| Regenerate boot splash | `godot --headless --path . --script tools/make_splash.gd` |
| Capture home with disposable progress | `godot --path . -- --demo --capture=/tmp/little-nook.png` |
| Capture shop with disposable progress | `godot --path . -- --demo --screen=shop --capture=/tmp/little-nook-shop.png` |

Browser checks require Node 22+ and Chromium. Export Web, start
`python3 tools/serve.py` in one terminal, then run this in another:

```bash
node tools/browser_check.mjs
```

`GAME_URL` changes the target from `http://127.0.0.1:8081`; `CHROMIUM_BIN`
selects Chromium. The script uses a temporary browser profile, CDP port 9337,
and writes screenshots/logs to `tools/out/`. It does not use Playwright.

## Verification workflow

- For runtime GDScript or content changes, run `./tools/check.sh`. It imports
  the project, executes `tests/test_rules.gd`, and runs the UI checks embedded
  in `main.gd` via `--ui-test`. Import errors, script errors, and leaked-resource
  warnings fail the wrapper. There is no third-party test framework.
- Add focused regression coverage for changed rewards, clocks, validation,
  persistence, or question generation. Prefer seeded RNG and injected times.
- For UI/input changes, inspect the changed screens and use the browser check
  when browser behavior is affected. Its coverage includes lessons, retries,
  shop, drag/tap tidying, settings, persistence, touch, and offline reload.
- For exports, assets, renderer, or offline changes, build the affected targets.
  Test the Web export over HTTP; opening its HTML as a local file is insufficient.
  Headless tests alone do not verify actual rendering or touch behavior.
- For documentation-only changes, check file references, command accuracy,
  and `git diff --check`; game execution is unnecessary.
- Report checks actually run and any missing tool/template/browser constraints.
  Update the dated verification record only with work actually performed.

## Artwork, distribution, and maintenance

- `tools/make_art.py` is the generator for the committed SVG and WAV assets.
  Change the generator and regenerate the affected assets together so a later
  run does not overwrite a one-off manual change. Review generated diffs.
- `assets/art/icon.svg` supplies the splash through `tools/make_splash.gd`.
  Let Godot manage import metadata; avoid unrelated importer churn.
- Keep the cream/sage palette, brown outlines, Fraunces headings, Nunito body
  text, and gentle sound design consistent with `docs/design.md`.
- Preserve original font license notices verbatim. `tools/export.sh` copies
  project and third-party notices into both export directories.
- Use `tools/export.sh Web` for complete Web builds: it runs
  `tools/finalize_web.py`, which replaces the generated worker with a scoped
  cache keyed by exported content. Edit the source tool rather than files in
  `build/web/`. Preserve offline access through both directory and index URLs.
- Web exports deliberately disable threads and cross-origin-isolation header
  requirements. Keep compatibility with ordinary static hosting when changing
  export settings. Offline installation requires localhost or HTTPS.
- CI checks and exports Web/Linux on pushes and pull requests. The Pages
  workflow checks and publishes Web when `main` is updated.
- Keep `.godot/`, `build/`, and `tools/out/` untracked. If adding an exportable
  resource, check its inclusion; tools, tests, docs, and build outputs are
  excluded by the current export presets.
- Before handing off, review `git status --short` and `git diff --check`,
  summarize the behavior changed and validation performed, and update this
  file's tree when adding, moving, or removing source files.
