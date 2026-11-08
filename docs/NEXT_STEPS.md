# Roadmap after confirming the starter plays in Studio

1. **Power grid** — electricity poles, boilers, turbines, generator/fuel recipes, network consumption and outages.
2. **Inventory/economy** — resource costs for placement, mining by hand, hotbar stock and item transactions.
3. **Inserters and splitter belts** — richer routing than single-item directional belts; filters and priorities.
4. **Recipes and research** — data-driven item definitions, recipe selection, science pack unlock tree.
5. **World generation/chunks** — procedural maps with persistent ore amounts, obstacles and biomes.
6. **Persistence** — ProfileStore or Roblox DataStore with versioned factories and migration strategy.
7. **Co-op factories** — one factory per world, permissions and server-authoritative shared editing.
8. **Optimization** — region dirty snapshots, active-machine scheduling, packed item state and render chunk culling.
9. **Mobile/console** — drag-to-pan, long-press builds, dedicated rotation controls and gamepad focus.

Make each system a module rather than expanding the client controller or server entry script endlessly.
