# Changelog

## 1.0.0 — 2026-11-01

First public release.

- Generate: 9 biomes blended by weight, 8 ready-made worlds, lakes, rivers, an ocean edge, caves,
  rock outcrops, surface patches and a snow line; up to 2048 × 2048 studs per run, written in
  24 × 24 column parcels with progress and Cancel.
- Erase: brush (radius 4–80 studs), two-corner region with a vertical margin, last generated area,
  all terrain (asks twice).
- Structures: 44 part structures and 10 landforms with a ghost preview, ground snapping, seeds,
  moss, ruin, scale, rotation and lights.
- Every step is one Ctrl+Z.
- English and Turkish panel (follows Studio's language the first time), light and dark Studio themes.
- Ready-made worlds now redraw the panel and reset the previous world's settings first.
- Beaches appear only next to real water; the ocean edge covers 38% of the area; volcanoes are
  separate cones with a crater and a lava lake.
- Neighbouring seeds give unrelated worlds; rivers come from the seed instead of `Random`, so the
  website's JavaScript copy makes the same world.
- Placed structures are named in the panel's language; attributes are `SweaxStructure` and `SweaxSeed`.
