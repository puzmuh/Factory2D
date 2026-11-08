# Manual Studio verification checklist

Ro2DEngine is a Roblox-runtime dependency and cannot be executed outside Roblox Studio. After you have installed the engine, built or synced with Rojo, and enabled the Mesh/Image API permission:

- [ ] Play: the game switches from the Roblox 3D world to the full-screen top-down factory canvas.
- [ ] The starting ore drill, belts, furnace, assembler and chest are visible in one straight row.
- [ ] Wait approximately 12–25 seconds. Ore moves through the line and the gear counter starts increasing.
- [ ] Hover over the storage chest; the bottom-right info should display gear count.
- [ ] Select belt with `1`, place it on an empty tile, and confirm its direction arrow appears.
- [ ] Press `R`, place another belt, and confirm its arrow faces the next direction.
- [ ] Press `F` over a placed belt: it rotates without disappearing.
- [ ] Right-click a belt: it disappears. Try to place a drill off the ore patch: placement is rejected.
- [ ] Pan with `WASD`, zoom with the mouse wheel, and confirm the hovered grid cell matches the pointer.
- [ ] Launch a second test player. Each player should have their **own** independent starter factory.
- [ ] Inspect the Studio Output pane for `[Ro2D]` warnings or script errors.

If the canvas is empty, first verify that the EditableImage permission is enabled and that `ReplicatedStorage.Ro2DEngine` contains its upstream ModuleScript children after Rojo sync. For an allocation problem, try temporarily reducing `Config.CANVAS` to `Vector2.new(640, 360)`.

**Validation performed before packaging:** static file checks, Rojo project JSON parsing and cross-file reference checks. **Not performed:** in-Studio playtest, Luau typecheck, interactive controller test or in-engine visual verification. Test inside Studio before publishing.
