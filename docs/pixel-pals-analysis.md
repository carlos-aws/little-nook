# How Pixel Pals is set up

Inspected the sibling `../pixel-pals/` before implementing Little Nook.
Pixel Pals is its own Git repository; the `games/` directory is a container
for projects. Its recorded remote is `carlos-aws/pixel-pals`.

## Runtime and presentation

Pixel Pals is a static HTML/CSS/JavaScript application. `package.json` has
development commands but no runtime dependencies or bundling pipeline.
`index.html` loads ES modules, and `src/main.js` coordinates app state,
routing, save operations, and timers.

`src/scene.js` draws a canvas room, pet animation, particles, time-of-day
lighting, and growth effects. `src/sprites.js` encodes hand-authored pixel
sprites as character maps and palettes. `src/audio.js` synthesizes effects
and a looping tune using Web Audio. UI screens are separate modules under
`src/screens/`; three minigames live under `src/minigames/`.

The manifest, service worker, and generated icons make it installable and
available offline after the first successful visit.

## Rules and learning

`src/pet.js` separates pure game rules from browser UI: five care needs,
gentle real-time decay, sleep, growth thresholds, daily stars, and rewards.
Growth requires both stars and minimum time in the current stage.

Care opens short learning rounds:

| Care | Subject |
| --- | --- |
| Feed | Maths |
| Play | English |
| Explore | Science |
| Clean | Review |
| Sleep | Time-based rest |

`src/content/index.js` selects questions, assembles rounds, adapts difficulty,
and remembers missed questions. The separate subject modules provide the
question generators and science fact bank. Parents can choose daily limits,
automatic or fixed difficulty, and audio/read-aloud preferences.

## Persistence and optional infrastructure

`src/storage.js` owns local profiles, migrations, JSON export/import, and
`localStorage`. `src/store.js` presents a common interface for local and
cloud persistence.

The optional `infra/` stack contains S3/CloudFront hosting, Cognito with Google
sign-in, Lambda, and DynamoDB. Cloud sessions use a lease so one device can
control a player at a time. It is an optional operational layer; local play
does not depend on AWS.

## Validation and publication

Node's built-in test runner covers pet rules, generated content, and cloud
lease behavior. All three test files passed during the initial inspection.
ESLint handles static checks. Playwright scripts cover browser flows, cloud
mocks, backups, and screenshots.

The GitHub Actions CI workflow runs lint and tests. The Pages workflow serves
the static project on pushes to `main`. There is no engine export step.

## What Little Nook carries forward

The strongest reusable decisions are the learning/care relationship, gentle
progression, an unhurried daily budget, original art/audio, and keeping
rules separate from UI and storage.

| Concern | Pixel Pals | Little Nook |
| --- | --- | --- |
| Runtime | Browser ES modules | Godot 4.7.2 / GDScript |
| Presentation | Canvas pixel sprites, CSS UI | SVG illustrations, native Godot controls |
| Primary interaction | Care buttons and quizzes | Care lessons plus native drag-and-drop sorting |
| Game rules | Pure JavaScript functions | `NookState`, independently tested |
| Content | Broad generators, levels 1–6, missed-question review | Original questions, levels 1–3, per-subject adaptation |
| Saves | Profiles in localStorage; optional AWS sync | One companion in validated local JSON / browser IndexedDB |
| Audio | Live Web Audio synthesis | Original synthesized WAVs through Godot |
| Build | No build step | Native and Web export presets |
| Verification | Node + Playwright | Godot rules/UI tests + Chromium CDP |
| Publishing | Static source files to Pages | Exported Web artifacts to Pages |

This is a separate game with its own source and art, not a JavaScript wrapper.
No original files in Pixel Pals were modified.

The first version does not reproduce Pixel Pals' complete breadth: multiple
profiles/species, all six learning levels, the three arcade minigames, cloud
authentication/leases, and parent save import/export are not included.
