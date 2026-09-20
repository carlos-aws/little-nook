# Little Nook — design notes

## The promise

A soft place to land and a little friend to care for. A child should be able
to open the game, choose one small activity, and leave having made both Pip's
day and their room a little brighter.

The central loop is **learn → care → earn → make a home**. Three-question
learning rounds take a minute or two. Tidying is a tactile alternative with
no time pressure. There is no failure state, dying pet, paid currency, or
competitive score.

## Art direction

The visual reference is Meox Studio's *Organized Inside*, specifically its
outlined everyday objects, pastel interiors, and calm arrangement of familiar
things. Little Nook uses that broad visual vocabulary with original artwork.
No reference screenshots are shipped as game art.

- **Pip:** a warm hazelnut bear, blushing cheeks, a sage scarf, and a leaf
  behind one ear. A separate closed-eye drawing supports rest.
- **Room:** an open dollhouse reading nook. Arched garden window, striped
  curtains, botanical print, wooden drawers, green armchair, books, teacup,
  woven rug, slippers, and a blanket basket.
- **Palette:** oat paper, cream, sage, muted terracotta, honey, and dusty
  lilac. Brown outlines keep illustrations soft.
- **Type:** Fraunces for expressive headings, Nunito for approachable reading.
  Both are bundled under the OFL.
- **Movement:** small breathing/bobbing movements and a greeting squash.
  The grown-ups' corner can turn them off.
- **Sound:** short, original celesta-like tones. No background music loop.

Art is generated deterministically as readable SVG by `tools/make_art.py`,
then rasterized by Godot's importer. It remains easy to recolour, resize, or
replace. Character and shop decorations are separate from the room painting
and can be animated or toggled independently.

## Interaction and learning

The large care cards are the main entry points. Persistent left navigation
lets older players browse lessons, tidying, shop, and progress directly.
Everything supports mouse or tap. Tidying also uses Godot's real drag-preview
and drop-target APIs. Tap-select then tap-destination provides the same action
without holding a drag. Keyboard focus has a visible sage outline; modal
focus cycles within the dialog.

Answers are shuffled, all questions have exactly one correct option, and
questions do not repeat within a round. Wrong choices are gently disabled.
After a second miss, the correct choice receives a hint. Players must still
select it to proceed. Rewards occur only after finishing all three questions
or placing all six tidy objects. Abandoning a round never awards its reward.

The daily cap affects stars, not care or access. Growth also requires time
in each stage. This prevents a single long session from exhausting the
progression. Completing a round without assistance earns a small coin bonus;
assistance never removes earned currency or stars.

## Technical boundaries

The first release is a complete small local game: one companion, one illustrated
room, three lesson subjects, one tidying scene, six shop decorations, five
growth stages, and five collectible milestones.

The canvas uses a 1440×900 logical layout with aspect-preserving scaling.
Desktop and landscape tablets are the intended presentation. Portrait works
with letterboxing, but a dedicated narrow layout is future work.

The model owns rewards and validates persistence; the UI supplies actions and
presentation. Native and browser builds share the same game code. The browser
uses a single-threaded WebAssembly export so it can run on ordinary static
hosting, including GitHub Pages.

Potential extensions are additional rooms, more sorting arrangements, a larger
question bank, multiple companions/profiles, native mobile exports, and
optional save import/export. Cloud services should remain optional if added.
