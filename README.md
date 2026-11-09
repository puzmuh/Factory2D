# Factory2D — Ro2DEngine Roblox starter

A **playable, desktop-first, top-down 2D factory prototype** using [Ro2DEngine](https://github.com/nrmu9/Ro2DEngine) for the world renderer and **Rojo + Aftman** for the Roblox Studio workflow.

**Working title:** Factory2D. It is inspired by the *genre* of automation/factory-building games, but uses original code-generated art and no Factorio game assets.

## Included

- Actual software-rendered 2D canvas via Ro2DEngine/`EditableImage` (not a camera trick).
- Ore patches, drills, directional conveyor belts, furnaces, assemblers, and storage chests.
- Live production line already set up when you press Play: `drill → 3 belts → furnace → 2 belts → assembler → belt → chest`.
- Production rules: **ore → plate → gear**; each gear requires **2 plates**. Gears accumulate in storage and the HUD counts them.
- Mouse-controlled grid placement, 90-degree rotation, removing/rotating existing machines, WASD camera pan, zoom, tool hotbar.
- Server-validated build requests and independent *per-player* factory simulation.
- Simple original procedural world art: no sprite, font, texture, or model asset IDs necessary.
- Pinned, reproducible Ro2DEngine dependency with one-time download scripts.

**Not included yet:** persistent save data, crafting costs, combat, multiplayer co-building, inserters, power networks, train logistics, terrain mining, or robust touch/console UX. Current mode is **creative**: machine placement has no costs; ore deposits do not deplete.

## 1. Install tools and sync with Rojo

Clone the repository and install [Rojo](https://rojo.space/) 7.7.1 (or install [Aftman](https://github.com/LPGhatguy/aftman) and run `aftman install`). Install the Rojo Studio plugin.

```powershell
git clone https://github.com/puzmuh/Factory2D.git
cd Factory2D
aftman install
rojo serve default.project.json
```

**No engine setup script is needed**: the pinned, MIT-licensed Ro2DEngine source is now committed at `vendor/Ro2DEngine/src`. Its source is directly mapped by Rojo to `ReplicatedStorage.Ro2DEngine`; upstream license is in `vendor/Ro2DEngine/LICENSE`. Upstream commit: `f97a2711e869caa2b29fbf810e5f60d60e63ca10`. To verify the Rojo project, run `rojo build default.project.json -o build/Factory2D.rbxlx`.

## 2. Studio setup

1. Open Roblox Studio and create an **empty Baseplate** experience. Publish it to Roblox.
2. Under Studio **Game Settings / Experience Settings → Security**, enable **Allow Mesh / Image APIs**. In the Creator Dashboard this is **Configure → Settings → Enable Mesh / Image APIs**. Your Roblox account and experience must satisfy the platform's requirements for EditableImage use.
3. Start `rojo serve`, click **Connect** inside the Rojo Studio plugin, and confirm the sync.
4. Press **Play**. The game's UI creates its own full-screen 2D canvas, and the engine isolates the 2D experience from the 3D Roblox character.

If the screen is blank, first check the Mesh / Image API permission, `ReplicatedStorage/Ro2DEngine` in Studio, then the output window for `[Ro2D]` warnings. A device can also reject EditableImage allocations when out of its image-memory budget.

## 3. Controls

| Input | Action |
| --- | --- |
| Left click | Build selected machine on empty grid tile |
| Right click | Remove machine |
| 1–5 | Conveyor, drill, furnace, assembler, storage |
| 6 | Remove tool |
| R | Rotate selected machine blueprint clockwise |
| F | Rotate existing machine under cursor clockwise |
| WASD / Arrow keys | Pan around world |
| Mouse wheel / Q / E | Zoom out / in |
| Click bottom toolbar | Select a building tool |

To build another production line, find an **ore deposit**, place a **drill** there, point its output toward a belt, and place belts that point into a **furnace**. From the furnace, direct plates along belts into an **assembler**, and direct the resulting gears into a **storage chest**. Machines can feed adjacent compatible machines without an intervening belt.

The server won't allow placing a drill off ore, overlapping any machine, or placing outside the map. Machines don't rotate the underlying ground deposit.

## 4. GitHub

This project is already at https://github.com/puzmuh/Factory2D. You can clone, edit, commit, and push from your usual local Git workflow.

## Project layout

```text
Factory2D/
├── aftman.toml                 # Rojo tool version
├── default.project.json        # Rojo -> Roblox tree mapping
├── src/
│   ├── shared/Config.luau      # World, tools, timing, directions
│   ├── server/
│   │   ├── FactoryServer.server.lua # RemoteEvent and sim ticks
│   │   └── FactoryWorld.luau   # Server-owned world state and recipes
│   └── client/
│       ├── FactoryClient.client.lua # Camera, HUD, controls
│       └── FactoryRenderer.luau  # Ro2D draw calls + procedural art
└── vendor/Ro2DEngine/         # Vendored upstream engine, included in Git
```

## Architecture notes

- `FactoryWorld` holds machines and item counts, and `FactoryServer` advances every player's world in fixed 0.2-second steps. Client input is validated by the server.
- Conveyor transfers use a two-phase update so a resource can't teleport across an entire belt line in one simulation step. Machines hold their output until the destination is available.
- `FactoryRenderer` only renders authoritative state snapshots; the native Roblox `ScreenGui` is deliberately used for text/buttons because Ro2DEngine's native `UI` API is still changing.
- This is a teaching/starter architecture, not a high-scale finished automation simulation. At thousands of machines, change from sending full snapshots every 0.25 seconds to **delta packets** and from scanning all machines to **active/chunk queues**.
- We use `Parallel = false` initially to simplify integration; after verification, compare `Parallel = true` with 2–4 workers on real devices. The renderer is independent from the server sim, so this is only a client-side setting.

## License and credits

Original template code: available for you to adapt in your Roblox projects. Ro2DEngine is Copyright (c) 2026 nrmu and MIT-licensed. The upstream engine is fetched unmodified at the pinned commit and its own `LICENSE` is preserved in that clone. No licensed Factorio art/code is used or distributed.
