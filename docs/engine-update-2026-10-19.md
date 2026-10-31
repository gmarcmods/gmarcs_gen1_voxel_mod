# Engine update compatibility

1.6.4 routes Horde's legacy color-effect restore through EngineCompat. Modern
engines no longer expose GBCFX; the missing optional module must not abort the
rest of the restore block before options are written. Older releases retain
the original clear/restore levels. The focused compatibility regression covers
both module shapes and cached lookup.

The original monolithic dramatic_shape_test.lua suite still contains direct
GBCFX calls and legacy VR expectations. Those checks are obsolete on the
current engine; its failure is not a clean renderer compatibility result.
Current validation uses the EngineCompat regression and real native Red voxel
and first-person rendering probes. No authored geometry was changed.
