<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/art/banner-dark-en.svg">
  <img src="docs/art/banner-light-en.svg" width="100%" alt="Sweax Terrain: generate, erase and build worlds in Roblox Studio">
</picture>

[![Download](https://img.shields.io/github/v/release/Sweax3169/sweaxterrain?label=download&color=4C7D29&style=for-the-badge)](https://github.com/Sweax3169/sweaxterrain/releases/latest)
[![Roblox Studio plugin](https://img.shields.io/badge/Roblox%20Studio-plugin-2A679A?style=for-the-badge)](#install)
[![Luau](https://img.shields.io/badge/Luau-8%20modules-6B7075?style=for-the-badge)](#project-layout)
[![License](https://img.shields.io/badge/license-MIT-C9501F?style=for-the-badge)](LICENSE)

[Website and live demo](https://sweax3169.github.io/sweaxterrain/) · [Türkçe](README.tr.md) · [Download](https://github.com/Sweax3169/sweaxterrain/releases/latest)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/media/gif/generate-dark.gif">
  <img src="docs/media/gif/generate-light.gif" width="760" alt="An Alpine world appears in 24 by 24 column parcels, in the order the plugin writes them to Roblox terrain">
</picture>

</div>

Sweax Terrain is a Roblox Studio plugin for building terrain. It generates whole worlds from nine
biomes that blend into each other, with lakes, rivers, an ocean edge and caves; it erases terrain with
a brush or by picking two corners; and it places 44 ready-made structures and 10 landforms with a
ghost preview that sits on the ground. Every step can be undone with <kbd>Ctrl</kbd> + <kbd>Z</kbd>.

The panel speaks English and Turkish and follows Studio's light or dark theme. It makes no web
requests and needs no assets: the structures are built from plain parts.

## Try it in your browser

The [website](https://sweax3169.github.io/sweaxterrain/) has a copy of the plugin's panel driving
the plugin's own generator, ported line by line from Luau to JavaScript. Roblox's `math.noise` is
reproduced bit for bit, so a seed gives the same world in the browser as in Studio. You can generate,
use the brush, erase a region and place structures there.

The port is checked against Studio itself: [`tools/check_generator.mjs`](tools/check_generator.mjs)
generates a world from the settings the plugin used and compares every column with the voxels Studio
wrote. Across the 22 worlds made for this page (238,848 columns) every surface height, surface
material and water level matched; the largest height difference was 0.016 studs, the rounding of an
8-bit occupancy.

## At a glance

<table>
<tr>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/art/card-biomes-dark-en.svg"><img src="docs/art/card-biomes-light-en.svg" width="100%" alt="Nine biomes: each is its own height function and they blend by weight"></picture></td>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/art/card-worlds-dark-en.svg"><img src="docs/art/card-worlds-light-en.svg" width="100%" alt="Eight ready-made worlds and a new seed on every run"></picture></td>
</tr>
<tr>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/art/card-caves-dark-en.svg"><img src="docs/art/card-caves-light-en.svg" width="100%" alt="A real slice through generated hills showing the cave tunnels"></picture></td>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/art/card-erase-dark-en.svg"><img src="docs/art/card-erase-light-en.svg" width="100%" alt="The brush eraser and the region eraser on real terrain"></picture></td>
</tr>
<tr>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/art/card-structures-dark-en.svg"><img src="docs/art/card-structures-light-en.svg" width="100%" alt="A watchtower drops into place as a ghost and turns solid"></picture></td>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/art/card-undo-dark-en.svg"><img src="docs/art/card-undo-light-en.svg" width="100%" alt="Ctrl+Z brings erased terrain back"></picture></td>
</tr>
</table>

Every picture on this page is real plugin output. The terrain and structures were generated in
Roblox Studio, read back voxel by voxel and part by part, and drawn with Blender; the panel shots
are Studio's own screen captures. The scripts that do this are in [`tools/`](tools).

## Eight worlds to start from

A ready-made world turns on a set of biomes and sets water and detail for you. Everything else on
the panel stays yours to change, and every press of **Generate world** rolls a new seed.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/media/gif/worlds-dark.gif">
    <img src="docs/media/gif/worlds-light.gif" width="680" alt="The eight ready-made worlds one after another">
  </picture>
</p>

<table>
<tr>
<td align="center" width="25%"><img src="docs/media/world-alp.webp" alt="Alpine"><br><b>Alpine</b><br><sub>mountains, hills, plains, lakes · snow line 0.56 · seed 8927</sub></td>
<td align="center" width="25%"><img src="docs/media/world-nehir.webp" alt="River plains"><br><b>River plains</b><br><sub>plains, hills, lakes, two rivers · seed 314159</sub></td>
<td align="center" width="25%"><img src="docs/media/world-kanyon.webp" alt="Desert canyon"><br><b>Desert canyon</b><br><sub>canyons, dunes, plateaus · terracing 0.35 · seed 77001</sub></td>
<td align="center" width="25%"><img src="docs/media/world-volkan.webp" alt="Volcanic"><br><b>Volcanic</b><br><sub>volcanoes, mountains, caves · seed 40404</sub></td>
</tr>
<tr>
<td align="center"><img src="docs/media/world-arktik.webp" alt="Arctic"><br><b>Arctic</b><br><sub>arctic, mountains, frozen lakes · snow line 0.30 · seed 23571</sub></td>
<td align="center"><img src="docs/media/world-bataklik.webp" alt="Swamp"><br><b>Swamp</b><br><sub>swamp, plains, lakes, rivers · seed 662607</sub></td>
<td align="center"><img src="docs/media/world-sahil.webp" alt="Coast"><br><b>Coast</b><br><sub>plains, hills, dunes, lakes, ocean edge · seed 141421</sub></td>
<td align="center"><img src="docs/media/world-karisik.webp" alt="Random mix"><br><b>Random mix</b><br><sub>a random set of biomes and weights · seed 299792</sub></td>
</tr>
</table>

Type a seed from this table into the panel, keep the same settings, and you get the same world.

## Nine biomes

Each biome is a height function of its own. With several turned on, a low-frequency mask per biome
decides where each one rules; the masks are cubed before blending, so regions separate cleanly but
still flow into each other at the edges. A biome's weight scales its mask, so a higher weight means
more land.

<table>
<tr>
<td align="center" width="33%"><img src="docs/media/biome-ova.webp" alt="Plains"><br><b>Plains</b><br><sub>Low, gentle ground. Grass with leafy patches.</sub></td>
<td align="center" width="33%"><img src="docs/media/biome-tepe.webp" alt="Hills"><br><b>Hills</b><br><sub>Rolling hills; rock shows where slopes get steep.</sub></td>
<td align="center" width="33%"><img src="docs/media/biome-dag.webp" alt="Mountains"><br><b>Mountains</b><br><sub>Ridged noise, squared. Snow above the snow line.</sub></td>
</tr>
<tr>
<td align="center"><img src="docs/media/biome-plato.webp" alt="Plateaus"><br><b>Plateaus</b><br><sub>Flat steps with short ramps between them.</sub></td>
<td align="center"><img src="docs/media/biome-kanyon.webp" alt="Canyons"><br><b>Canyons</b><br><sub>A dry plateau cut by terraced, winding gorges.</sub></td>
<td align="center"><img src="docs/media/biome-volkan.webp" alt="Volcanic"><br><b>Volcanic</b><br><sub>Separate cones, each with a crater and a lava lake.</sub></td>
</tr>
<tr>
<td align="center"><img src="docs/media/biome-col.webp" alt="Desert dunes"><br><b>Desert dunes</b><br><sub>Long dune waves in sand and sandstone.</sub></td>
<td align="center"><img src="docs/media/biome-arktik.webp" alt="Arctic"><br><b>Arctic</b><br><sub>U-shaped glacial valleys. Lakes freeze over.</sub></td>
<td align="center"><img src="docs/media/biome-bataklik.webp" alt="Swamp"><br><b>Swamp</b><br><sub>Ground just under the water line: mud and pools.</sub></td>
</tr>
</table>

## Water and caves

<table>
<tr>
<td width="33%"><img src="docs/media/world-nehir.webp" alt="Rivers"><br><b>Lakes and rivers</b><br><sub>Lakes are dug only into low ground. Up to five rivers, each with its own width and meander. Sand banks appear only where there is real water, as wide as the beach width you set.</sub></td>
<td width="33%"><img src="docs/media/world-sahil.webp" alt="Ocean edge"><br><b>Ocean edge</b><br><sub>Pick west, east, north or south. The land slopes into the sea across 38% of the area in that direction, with a beach along the shore.</sub></td>
<td width="33%"><img src="docs/media/caves.webp" alt="Caves"><br><b>Caves</b><br><sub>Worm tunnels where two 3D noise fields both cross zero, at least 6 studs under the surface. Cut open here to show them.</sub></td>
</tr>
</table>

In the volcanic biome water turns into lava, and arctic lakes get a lid of ice.

## Erasing

The eraser works on any terrain in the place, not only on what Sweax Terrain made.

<table>
<tr>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/media/gif/erase-dark.gif"><img src="docs/media/gif/erase-light.gif" width="100%" alt="The red brush ball carves a path across river plains"></picture><br><b>Brush.</b> Turn the brush on and click or drag in the scene. A red ball shows its size (radius 4 to 80 studs); one drag is one undo step.</td>
<td width="50%"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/media/gif/region-dark.gif"><img src="docs/media/gif/region-light.gif" width="100%" alt="Two corners are picked, a red box grows between them and the terrain inside is gone"></picture><br><b>Region.</b> Click two corners, then <b>Erase selection</b>. The box reaches above and below the corners by the vertical margin (10 to 200 studs).</td>
</tr>
</table>

**Erase the last generated area** clears what the last run made. **Erase all terrain in this place**
asks for a second click within five seconds. All of it comes back with <kbd>Ctrl</kbd> + <kbd>Z</kbd>.

## Structures and landforms

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/media/gif/structures-dark.gif">
    <img src="docs/media/gif/structures-light.gif" width="760" alt="Ten structures are placed on generated hills one by one, each first as a see-through ghost">
  </picture>
</p>

Pick a structure, then **Click to place**: a see-through ghost follows the mouse and, with **Snap to
ground** on, sits on the terrain under it. Click to place it; <kbd>Shift</kbd> + click turns it 45°
first. **Place in front of the camera** drops one where you are looking.

Every placement gets its own seed, so two watchtowers are never quite the same; type a seed to get
one back. **Moss** grows patches on stone, **Ruin** shifts, tilts and drops loose blocks, **Scale**
goes from 0.4× to 3×, and **Lights** turns torches and lamps on or off. Structures go into a
`SweaxYapilar` folder in Workspace, each a model with `SweaxStructure` and `SweaxSeed` attributes.
**Undo last structure** and **Remove all structures** sit under the grid.

Landforms are different: they carve or raise terrain where you click (a quarry pit, a plateau, a
cave mouth, a pond...), so they have no ghost preview.

<details>
<summary><b>All 54</b></summary>
<br>

<table>
<tr><td align="center" width="16%"><img src="docs/media/structures/kademeliKaide.webp" width="110" alt="Stepped Plinth"><br><sub><b>Stepped Plinth</b><br>Architecture</sub></td><td align="center" width="16%"><img src="docs/media/structures/heykelKaidesi.webp" width="110" alt="Miner Statue"><br><sub><b>Miner Statue</b><br>Architecture</sub></td><td align="center" width="16%"><img src="docs/media/structures/taskemer.webp" width="110" alt="Stone Arch"><br><sub><b>Stone Arch</b><br>Architecture</sub></td><td align="center" width="16%"><img src="docs/media/structures/sutunlar.webp" width="110" alt="Broken Columns"><br><sub><b>Broken Columns</b><br>Ruins</sub></td><td align="center" width="16%"><img src="docs/media/structures/kalintiDuvar.webp" width="110" alt="Ruined Wall"><br><sub><b>Ruined Wall</b><br>Ruins</sub></td><td align="center" width="16%"><img src="docs/media/structures/merdivenSeti.webp" width="110" alt="Stone Stairs"><br><sub><b>Stone Stairs</b><br>Architecture</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/dikiliTaslar.webp" width="110" alt="Standing Stones"><br><sub><b>Standing Stones</b><br>Ruins</sub></td><td align="center" width="16%"><img src="docs/media/structures/gozetlemeKulesi.webp" width="110" alt="Watchtower"><br><sub><b>Watchtower</b><br>Architecture</sub></td><td align="center" width="16%"><img src="docs/media/structures/taskopru.webp" width="110" alt="Stone Bridge"><br><sub><b>Stone Bridge</b><br>Architecture</sub></td><td align="center" width="16%"><img src="docs/media/structures/suKanali.webp" width="110" alt="Water Channel"><br><sub><b>Water Channel</b><br>Water</sub></td><td align="center" width="16%"><img src="docs/media/structures/kayaOlusum.webp" width="110" alt="Rock Formation"><br><sub><b>Rock Formation</b><br>Nature</sub></td><td align="center" width="16%"><img src="docs/media/structures/avluDuvari.webp" width="110" alt="Courtyard Wall"><br><sub><b>Courtyard Wall</b><br>Architecture</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/meydanZemini.webp" width="110" alt="Plaza Floor"><br><sub><b>Plaza Floor</b><br>Ground</sub></td><td align="center" width="16%"><img src="docs/media/structures/madenGirisi.webp" width="110" alt="Mine Entrance"><br><sub><b>Mine Entrance</b><br>Mining</sub></td><td align="center" width="16%"><img src="docs/media/structures/madenTuneli.webp" width="110" alt="Mine Tunnel"><br><sub><b>Mine Tunnel</b><br>Mining</sub></td><td align="center" width="16%"><img src="docs/media/structures/vincKulesi.webp" width="110" alt="Crane Tower"><br><sub><b>Crane Tower</b><br>Mining</sub></td><td align="center" width="16%"><img src="docs/media/structures/rayHatti.webp" width="110" alt="Rail Line"><br><sub><b>Rail Line</b><br>Mining</sub></td><td align="center" width="16%"><img src="docs/media/structures/cevherVagonu.webp" width="110" alt="Ore Cart"><br><sub><b>Ore Cart</b><br>Mining</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/cevherDamari.webp" width="110" alt="Ore Vein"><br><sub><b>Ore Vein</b><br>Mining</sub></td><td align="center" width="16%"><img src="docs/media/structures/kuyuAgzi.webp" width="110" alt="Shaft Head"><br><sub><b>Shaft Head</b><br>Mining</sub></td><td align="center" width="16%"><img src="docs/media/structures/madenciKampi.webp" width="110" alt="Miners' Camp"><br><sub><b>Miners' Camp</b><br>Mining</sub></td><td align="center" width="16%"><img src="docs/media/structures/cevherDeposu.webp" width="110" alt="Ore Depot"><br><sub><b>Ore Depot</b><br>Mining</sub></td><td align="center" width="16%"><img src="docs/media/structures/konveyorIskele.webp" width="110" alt="Conveyor Gantry"><br><sub><b>Conveyor Gantry</b><br>Mining</sub></td><td align="center" width="16%"><img src="docs/media/structures/eritmeOcagi.webp" width="110" alt="Smelting Furnace"><br><sub><b>Smelting Furnace</b><br>Mining</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/cevherYigini.webp" width="110" alt="Ore Pile"><br><sub><b>Ore Pile</b><br>Mining</sub></td><td align="center" width="16%"><img src="docs/media/structures/asansorKulesi.webp" width="110" alt="Lift Tower"><br><sub><b>Lift Tower</b><br>Mining</sub></td><td align="center" width="16%"><img src="docs/media/structures/susMesale.webp" width="110" alt="Torch"><br><sub><b>Torch</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susFener.webp" width="110" alt="Lamp Post"><br><sub><b>Lamp Post</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susSandik.webp" width="110" alt="Crate Stack"><br><sub><b>Crate Stack</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susVaril.webp" width="110" alt="Barrels"><br><sub><b>Barrels</b><br>Props</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/susDestek.webp" width="110" alt="Timber Prop"><br><sub><b>Timber Prop</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susIskele.webp" width="110" alt="Scaffold"><br><sub><b>Scaffold</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susCevherYigin.webp" width="110" alt="Ore Heap"><br><sub><b>Ore Heap</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susMoloz.webp" width="110" alt="Rubble Pile"><br><sub><b>Rubble Pile</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susKampAtesi.webp" width="110" alt="Campfire"><br><sub><b>Campfire</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susAletStandi.webp" width="110" alt="Tool Rack"><br><sub><b>Tool Rack</b><br>Props</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/susTabela.webp" width="110" alt="Signpost"><br><sub><b>Signpost</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susCadir.webp" width="110" alt="Tent"><br><sub><b>Tent</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susCit.webp" width="110" alt="Fence Line"><br><sub><b>Fence Line</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susDinamit.webp" width="110" alt="Dynamite Crate"><br><sub><b>Dynamite Crate</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susSuOlugu.webp" width="110" alt="Water Trough"><br><sub><b>Water Trough</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susOdun.webp" width="110" alt="Woodpile"><br><sub><b>Woodpile</b><br>Props</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/susElArabasi.webp" width="110" alt="Wheelbarrow"><br><sub><b>Wheelbarrow</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/susBayrak.webp" width="110" alt="Flagpole"><br><sub><b>Flagpole</b><br>Props</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanDuzle.webp" width="110" alt="Flatten"><br><sub><b>Flatten</b><br>Landforms</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanTemizle.webp" width="110" alt="Clear"><br><sub><b>Clear</b><br>Landforms</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanPlato.webp" width="110" alt="Mining Plateau"><br><sub><b>Mining Plateau</b><br>Landforms</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanTasOcagi.webp" width="110" alt="Quarry Pit"><br><sub><b>Quarry Pit</b><br>Landforms</sub></td></tr>
<tr><td align="center" width="16%"><img src="docs/media/structures/alanKanyon.webp" width="110" alt="Canyon Rift"><br><sub><b>Canyon Rift</b><br>Landforms</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanMagaraAgzi.webp" width="110" alt="Cave Mouth"><br><sub><b>Cave Mouth</b><br>Landforms</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanKayaSirti.webp" width="110" alt="Rock Ridge"><br><sub><b>Rock Ridge</b><br>Landforms</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanTepe.webp" width="110" alt="Hill"><br><sub><b>Hill</b><br>Landforms</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanGolet.webp" width="110" alt="Pond"><br><sub><b>Pond</b><br>Landforms</sub></td><td align="center" width="16%"><img src="docs/media/structures/alanCevherYatagi.webp" width="110" alt="Ore Bed"><br><sub><b>Ore Bed</b><br>Landforms</sub></td></tr>
</table>

</details>

## The panel

Real Studio captures of the panel: Generate (top and bottom of the tab, mid-run), Erase and Structures.

<table>
<tr>
<td width="25%"><img src="docs/media/panel-generate-en.png" alt="Generate tab: ready-made worlds, area, seed and biomes"></td>
<td width="25%"><img src="docs/media/panel-generate-bottom-en.png" alt="Generate tab while generating: shape, water, caves and the progress bar"></td>
<td width="25%"><img src="docs/media/panel-erase-en.png" alt="Erase tab: brush, region and erase-all buttons"></td>
<td width="25%"><img src="docs/media/panel-structures-en.png" alt="Structures tab: category filters, structure grid and placement settings"></td>
</tr>
</table>

The toolbar button opens a floating panel you can dock anywhere. **EN · TR** at the top switches the
language; the first time, it follows Studio's own language. A status line at the bottom says what to
do next in every tab.

## Install

1. Download [`SweaxTerrain.rbxmx`](https://github.com/Sweax3169/sweaxterrain/releases/latest/download/SweaxTerrain.rbxmx) from the latest release.
2. Put it in your Studio plugins folder. In Studio: **Plugins** tab → **Plugins Folder**.
   - Windows: `%LOCALAPPDATA%\Roblox\Plugins`
   - macOS: `~/Documents/Roblox/Plugins`
3. Restart Roblox Studio.
4. Open the **Plugins** tab and click **Sweax Terrain**.

To update, replace the file and restart Studio. To remove it, delete the file.

Each release lists the SHA-256 of the file in `SHA256SUMS.txt`. On Windows:

```powershell
Get-FileHash SweaxTerrain.rbxmx -Algorithm SHA256
```

### Build from source

The plugin is plain Luau in [`src/`](src). Python 3 packs it into one `.rbxmx`:

```bash
python tools/build.py
```

```bash
python tools/build.py --install
```

The first writes `dist/SweaxTerrain.rbxmx`; the second also copies it into your plugins folder.

## Using it

**Generate.** Pick a ready-made world or tick biomes yourself, press **Centre in front of the camera**
so the world lands where you are looking, then **Generate world**. A progress bar runs while the
voxels are written and **Cancel** stops it. Not happy? <kbd>Ctrl</kbd> + <kbd>Z</kbd>, or just press
**Generate world** again for a new seed.

<details>
<summary><b>Every setting</b></summary>
<br>

| Group | Setting | Range | Default |
| --- | --- | --- | --- |
| Area | Width (X), Depth (Z) | 128 – 2048 studs, steps of 32 | 512 |
| | Centre X · Y · Z | any; Y is the base height | 0 · 40 · 0 |
| Seed | Seed | any whole number; 🎲 rolls one | 618033988 |
| | New seed on every run | on / off | on |
| Biomes | Plains · Hills · Mountains | on / off, weight 0.05 – 1 | on · 0.8 · 0.7 · 0.9 |
| | Plateaus · Canyons · Volcanic · Desert dunes · Arctic · Swamp | on / off, weight 0.05 – 1 | off |
| Shape | Height scale | 0.3 – 2.5 | 1.0 |
| | Roughness | 0 – 1 | 0.5 |
| | Flow (domain warp) | 0 – 1 | 0.5 |
| | Terracing | 0 – 1 | 0 |
| | Biome region size | 120 – 900 studs | 320 |
| Water | Water level above base | −10 – 20 studs | 0 |
| | Lakes · density · depth · beach width | on / off · 0 – 1 · 3 – 30 · 0 – 16 studs | on · 0.5 · 10 · 6 |
| | Rivers · count · width · meander | on / off · 1 – 5 · 6 – 40 studs · 0 – 1 | off · 2 · 14 · 0.6 |
| | Ocean edge · side | on / off · west, east, north, south | off · west |
| Caves and detail | Caves · density · size | on / off · 0 – 1 · 0 – 1 | off · 0.5 · 0.5 |
| | Rock outcrops | 0 – 1 | 0.35 |
| | Surface patches | 0 – 1 | 0.6 |
| | Snow line (low = snowier) | 0.1 – 1 | 0.72 |
| Erase | Brush radius | 4 – 80 studs | 16 |
| | Vertical margin (±) | 10 – 200 studs | 80 |
| Structures | Scale · Moss · Ruin | 0.4 – 3 · 0 – 1 · 0 – 1 | 1 · 0.5 · 0.35 |
| | Rotation | 0° – 315°, steps of 45° | 0° |
| | Lights · Snap to ground · New seed on every placement | on / off | on · on · on |

A ready-made world resets the world settings (biomes, shape, water, caves, detail) before applying
its own, and leaves area, centre, seed, eraser and structure settings alone.

</details>

**Speed.** On a Ryzen 5 7600 in Studio, a 512 × 512 world takes 0.30 s, 1024 × 1024 takes 0.95 s
and 2048 × 2048 takes 3.6 s (Alpine, measured with `os.clock`).

## How it works

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/art/architecture-dark-en.svg">
  <img src="docs/art/architecture-light-en.svg" width="100%" alt="Architecture: the panel, the two-pass generator, the tools and the structure library, writing into workspace.Terrain and workspace.SweaxYapilar">
</picture>

1. The area is split into 4-stud columns, the size of a Roblox terrain voxel. The corner is snapped to
   the voxel grid, so `WriteVoxels` always gets arrays of exactly the size it expects.
2. **Pass one, height map.** Each column's coordinates are bent by domain warp (two fBm fields), every
   enabled biome returns a height, and the cubed biome masks blend them. Height scale, roughness and
   terracing apply, then lakes (only in low ground), rivers and the ocean edge dig in.
3. **Beaches.** Columns under the water line are dilated by the beach width, so sand lands only where
   land meets real water.
4. **Pass two, voxels.** For every voxel the material comes from the biome's set (surface, slope,
   deep, patches), the snow line, beaches and the volcano's lava lakes; rock outcrops and caves bend
   the occupancy with 3D noise. The world is written in 24 × 24 column parcels with a progress bar
   between them and a check for **Cancel**.
5. **Undo.** Generating, every brush stroke, region erase and placement ends with a
   `ChangeHistoryService` waypoint, so <kbd>Ctrl</kbd> + <kbd>Z</kbd> works as it does for everything else.

Seeds are mixed (`seed × 7919 mod 100000`) before they offset the noise, so neighbouring seeds such
as 571 and 572 give unrelated worlds. Everything random in the generator comes from `math.noise`, not
from `Random`, which is what lets the website reproduce a world exactly.

## Project layout

```
src/
  Ana.server.lua     toolbar button, dock widget, brush / region / placement tools, undo waypoints
  Arayuz.lua         the panel: tabs, sliders, presets, theme colours, EN · TR
  Dil.lua            every English and Turkish string, structure and category names
  Uretici.lua        the generator: biomes, water, beaches, materials, caves, WriteVoxels
  Yapilar.lua        structure library index, placement, ground snapping, undo stack
  YapiTemel.lua      13 architecture, ruin, water, nature and ground pieces
  YapiMaden.lua      13 mining structures
  YapiSus.lua        18 props
  YapiAlan.lua       10 landforms that carve or raise terrain
tools/
  build.py           packs src/ into dist/SweaxTerrain.rbxmx (--install copies it to Studio)
  bridge.py          local HTTP bridge between Studio and this folder (127.0.0.1 only)
  studio_dump.lua    reads terrain voxels and part models out of Studio through the bridge
  check_generator.mjs, check_noise.mjs   compare the JavaScript port with Studio dumps
  render_blender.py  draws dumps with Blender (surface nets on the voxel occupancy)
  art_jobs.py, art.py, svgart.py, render_map.py, site_data.py, voxels.py   README and website art
docs/                the website (GitHub Pages): js/noise.js, js/generator.js, js/view.js, js/panel.js
```

The code is commented in Turkish; identifiers are Turkish too (`Uretici` is "generator", `Arayuz`
"interface", `Yapilar` "structures").

## Questions

**Will it touch terrain I already have?** Generating clears and rewrites only the area you set, in a
band from 60 studs under the new terrain to 220 studs over it. The eraser removes only what you point
at. <kbd>Ctrl</kbd> + <kbd>Z</kbd> undoes either.

**Does it need HTTP or any assets?** No. It makes no web requests and the structures are plain parts.

**Can I share it?** Yes, send the `.rbxmx` or a link to this page. It is MIT licensed.

**What are placed structures called in the Explorer?** Their name in the panel's language
(Watchtower, or Gözetleme Kulesi in Turkish). The `SweaxStructure` attribute keeps the internal id.

## License

[MIT](LICENSE) © 2026 Sweax Studios
