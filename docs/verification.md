# Verification — 20 September 2026

Verified with the official Godot **4.7.2 standard Linux editor** and matching
export templates. Both downloaded archives were checked against the release's
SHA-512 checksums.

## Automated checks

`tools/check.sh` passed with no script/import errors or leaked-resource warnings:

- **12,293 assertions** covering rewards, daily caps, gentle need decay,
  rest, time-gated growth, adaptive levels, shop transactions, save validation,
  JSON round trips, failed writes, and recovery from a damaged primary save.
- Content sampling covers **720 generated rounds** across 80 random seeds,
  all three subjects, and all three difficulty levels. Each question has
  three distinct options and exactly one correct answer. Each round has
  three distinct questions.
- **17 UI checks** cover starting/retrying/completing a lesson, personalized
  questions, changing sound during an answered question, duplicate reward
  prevention, wrong/correct tidy destinations, repeated navigation, purchases,
  decoration toggling, sleep/wake, leaving an activity, journal, and preferences.
- Notification timers also expire during the test to catch callbacks pointing
  at replaced UI elements.

The same 17 UI checks passed in the **exported Linux executable**. The native
executable was also launched graphically and produced a rendered screenshot
without requiring the editor.

## Real browser checks

`node tools/browser_check.mjs` passed against the final Web export served from
`tools/serve.py`, with an isolated Chromium profile and WebGL 2 through
SwiftShader.

The script used real mouse/keyboard/touch events to:

1. Load the game at 1440×900.
2. Open and finish a maths activity, including retries.
3. Purchase a plant and show it in the room.
4. Drag a tidy object and finish the six-object sorting activity by tapping.
5. Open the journal and grown-ups' preferences using the keyboard gate.
6. Inspect the browser's saved data and verify two completed activities, two
   stars, one completed tidy, and the purchased plant.
7. Reload and confirm persistent inventory.
8. Resize to a 1024×768 tablet viewport and send touch input.
9. Disable networking, reload the directory URL, and boot the game from the
   offline cache.

The captured browser console had no JavaScript exceptions or Godot runtime
errors. Final browser screenshots are in this directory; intermediate images
and logs are in the ignored `tools/out/` directory.

The export's PWA manifest was checked for `standalone` display and `landscape`
orientation. A project-specific service worker packages the engine, game,
fonts/art pack, loader, splash, and icons; it supports offline navigation
through both the directory URL and `index.html`.

## Distribution checks and limits

- Browser and standalone Linux exports completed successfully.
- Game and third-party license notices are included beside both builds.
- Shell and JavaScript syntax, Python source, and SVG XML were checked.
- This record covers local verification. Hosted CI results and downloadable
  builds are recorded in the repository's **Actions → Check and build** runs.
- Physical Android/iOS hardware, Safari, Windows, and macOS were not tested.
  The mobile check uses Chromium's touch and viewport emulation.
- Native read-aloud depends on an installed English speech voice; this
  environment was not used to validate spoken voice quality.
