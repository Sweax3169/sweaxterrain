// node tools/check_noise.mjs dumps/noise.txt
// Compares docs/js/noise.js with math.noise values sampled in Roblox Studio ("x y z value" per line).
import { readFileSync } from "node:fs";
import { noise } from "../docs/js/noise.js";

const rows = readFileSync(process.argv[2] || "dumps/noise.txt", "utf8").trim().split("\n");
let worst = 0, exact = 0;
for (const r of rows) {
  const [x, y, z, v] = r.split(" ").map(Number);
  const d = Math.abs(noise(x, y, z) - v);
  if (d === 0) exact++;
  worst = Math.max(worst, d);
}
console.log(`${rows.length} samples, ${exact} exact, worst difference ${worst.toExponential(2)}`);
process.exit(worst < 1e-6 ? 0 : 1);
