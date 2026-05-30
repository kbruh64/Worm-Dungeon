# Worm Dungeon

A green worm gets sucked through a wormhole into a computer system and must claw through 30 sectors of digital defenses to defeat the final boss: **The Computer itself**.

Built with [LÖVE 11.x](https://love2d.org/) (Love2D). Pixelated rendering — internal 320x180 canvas scaled to window with nearest-neighbor filtering.

## Run

Install LÖVE 11.x, then from this folder:

```
love .
```

Or drag the folder onto `love.exe` on Windows.

## Controls

| Key            | Action                                       |
| -------------- | -------------------------------------------- |
| WASD           | Move                                         |
| Mouse          | Aim                                          |
| Left click     | Use equipped weapon                          |
| Right click / Space | Dash (i-frames, dashes the way you're moving) |
| Q / E / Wheel  | Cycle equipped weapon                        |
| Enter          | Confirm (menus)                              |
| Esc            | Pause (in game) / back (in menus)            |
| F11            | Fullscreen                                   |

Chain attacks within 0.6s to build a combo — every two combo hits add +1 damage.

### Pause & Settings

Press **Esc** during a run to pause without losing progress. The pause menu and the
title-screen **SETTINGS** entry share the same options: music volume, SFX volume,
fullscreen, screen shake, and CRT glow. Settings persist between sessions.

### Characters

Sectors are dotted with harmless passive characters — a chat-bubble assistant, a
stray cursor, a floppy disk, a debug bug — hiding in the dark. Walk up to one and it
pops a speech bubble with a system tip or a (deliberately bad) joke. They never fight;
they're just there to keep you company on the way down. See
[src/entities/npc.lua](src/entities/npc.lua).

## Audio

All music and sound effects are **synthesized procedurally at runtime** (chiptune
oscillators + noise in [src/audio.lua](src/audio.lua)) — the game ships with no audio
asset files. Tracks switch by context: calm menu theme, driving battle loop, a heavier
boss loop, and a bright victory jingle.

## Project layout

```
main.lua              entry point, canvas scaling, fonts, CRT vignette
conf.lua              LÖVE window config
src/
  state_machine.lua   menu/story/game/victory/settings manager
  progress.lua        current dungeon, unlocked attacks, kill count
  settings.lua        persisted options (volume, fullscreen, shake, crt)
  audio.lua           procedural chiptune music + SFX synthesis
  options.lua         shared options widget (settings + pause menu)
  fx.lua              particles, screen shake, damage popups
  states/             menu, story, game, reward, victory, settings screens
  entities/           worm (player), enemy (8 archetypes)
  dungeons/list.lua   30 dungeons w/ palette + archetype + unlocks
assets/fonts/         drop Mojangles.ttf here (auto-fallback otherwise)
```

Add or rebalance dungeons by editing `src/dungeons/list.lua` — data only, no code changes.

## Font

The storyline uses the **Mojangles** pixel font. Drop `Mojangles.ttf` into `assets/fonts/`. If missing, LÖVE's default font is used.
