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

| Key            | Action                                  |
| -------------- | --------------------------------------- |
| WASD           | Move                                    |
| Mouse          | Aim                                     |
| Left click     | Use selected weapon                     |
| Space          | Dash (i-frames, dashes toward cursor)   |
| 1–9            | Select hotbar slot                      |
| Mouse wheel    | Cycle hotbar                            |
| E              | Open / close inventory                  |
| Enter          | Confirm (menus)                         |
| Esc            | Close inventory / back to menu          |
| F11            | Fullscreen                              |

### Inventory

Press **E** to open. Left-click a weapon in the inventory grid to pick it up, then left-click a hotbar slot to assign it. Right-click a hotbar slot to clear it. New weapons unlocked from dungeon clears are auto-added to your inventory and dropped into the first empty hotbar slot.

Chain attacks within 0.6s to build a combo — every two combo hits add +1 damage.

## Project layout

```
main.lua              entry point, canvas scaling, font loading
conf.lua              LÖVE window config
src/
  state_machine.lua   menu/story/game/victory manager
  progress.lua        current dungeon, unlocked attacks, kill count
  states/             menu, story, game, victory screens
  entities/           worm (player), enemy (8 archetypes)
  dungeons/list.lua   30 dungeons w/ palette + archetype + unlocks
assets/fonts/         drop Mojangles.ttf here (auto-fallback otherwise)
```

Add or rebalance dungeons by editing `src/dungeons/list.lua` — data only, no code changes.

## Font

The storyline uses the **Mojangles** pixel font. Drop `Mojangles.ttf` into `assets/fonts/`. If missing, LÖVE's default font is used.
