// node tools/check_generator.mjs dumps/alp
// Generates a world with docs/js/generator.js from dumps/<name>.json (the settings the plugin used
// in Studio) and compares every column with the voxels Studio wrote (dumps/<name>.vox).
import { readFileSync } from "node:fs";
import { generate } from "../docs/js/generator.js";

function readVox(path) {
  const text = readFileSync(path, "utf8");
  const nl = text.indexOf("\n");
  const h = JSON.parse(text.slice(0, nl));
  const lines = text.slice(nl + 1).split("\n");
  const { nx, ny, nz } = h;
  const mat = new Uint8Array(nx * ny * nz);
  const occ = new Float32Array(nx * ny * nz);
  let i = 0;
  for (let x = 0; x < nx; x++) for (let z = 0; z < nz; z++) {
    let y = 0;
    for (const run of lines[i++].split(",")) {
      const [m, o, n] = run.split(":").map(Number);
      for (let k = 0; k < n; k++, y++) { const idx = (x * ny + y) * nz + z; mat[idx] = m - 1; occ[idx] = o / 255; }
    }
  }
  return { ...h, mat, occ };
}

const name = process.argv[2];
const v = readVox(name + ".vox");
const s = JSON.parse(readFileSync(name + ".json", "utf8"));
const g = generate(s);
const ox = Math.round((g.x0 - v.x0) / 4), oz = Math.round((g.z0 - v.z0) / 4);
let same = 0, sameMat = 0, total = 0, worst = 0, wet = 0, wetSame = 0;
for (let ix = 0; ix < g.Nx; ix++) for (let iz = 0; iz < g.Nz; iz++) {
  const vx = ix + ox, vz = iz + oz;
  if (vx < 0 || vz < 0 || vx >= v.nx || vz >= v.nz) continue;
  // studio top solid surface
  let top = NaN, topMat = null, water = NaN;
  for (let y = v.ny - 1; y >= 0; y--) {
    const idx = (vx * v.ny + y) * v.nz + vz;
    const m = v.materials[v.mat[idx]];
    if (m === "Air") continue;
    if (m === "Water") { if (Number.isNaN(water)) water = v.y0 + y * 4 + v.occ[idx] * 4; continue; }
    top = v.y0 + y * 4 + v.occ[idx] * 4; topMat = m; break;
  }
  const i = ix * g.Nz + iz;
  total++;
  const d = Math.abs(top - g.top[i]);
  worst = Math.max(worst, d);
  if (d < 0.05) same++;
  if (topMat === g.topMat[i]) sameMat++;
  if (!Number.isNaN(water) || !Number.isNaN(g.water[i])) { wet++; if (Math.abs(water - g.water[i]) < 0.05) wetSame++; }
}
const pct = (a, b) => (100 * a / Math.max(b, 1)).toFixed(2) + "%";
console.log(`${name}: ${total} columns · height ${pct(same, total)} · material ${pct(sameMat, total)} · water ${pct(wetSame, wet)} of ${wet} · worst ${worst.toFixed(3)}`);
