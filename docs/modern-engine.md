# Modern engine compatibility (1.6.3)

The current engine removed src.render.GBCFX. EngineCompat treats that old API
as optional and caches its availability, allowing save creation and rendering
without it. Existing native behavior remains when that API exists.

Terrain upload now uses four vertices plus six indices per quad, with both
portable table and optional FFI paths. MeshVisibility is linked to the Gen 2
runtime's maintained implementation in development and copied into release
ZIPs. Camera and light passes cull spatial index ranges independently;
connected maps preserve translations. Draw ranges reset after every pass.
Native Gen 1 shape/profile generation is preserved.

Tests: test_engine_compat.lua, test_indexed_terrain_upload.lua and
test_mesh_visibility.lua. The shared companion live probe also boots current
engine Red and renders house/lab/cave/forest/town/route after this change.
Install KANTO_FIRST_PERSON separately for atmospheric first-person effects.
