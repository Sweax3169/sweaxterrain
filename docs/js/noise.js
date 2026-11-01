// Luau's math.noise: Ken Perlin's improved noise in 32-bit floats, so the website draws the
// same worlds as the plugin. Checked against 3000 values sampled in Roblox Studio (tools/check_noise.mjs).
const P = new Uint8Array([151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69,
  142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32,
  57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146,
  158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161,
  1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173,
  186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58,
  17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9,
  129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238,
  210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84,
  204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66,
  215, 61, 156, 180, 151]);
const G = [[1, 1, 0], [-1, 1, 0], [1, -1, 0], [-1, -1, 0], [1, 0, 1], [-1, 0, 1], [1, 0, -1], [-1, 0, -1],
  [0, 1, 1], [0, -1, 1], [0, 1, -1], [0, -1, -1], [1, 1, 0], [0, -1, 1], [-1, 1, 0], [0, -1, -1]];
const f = Math.fround;

const fade = (t) => f(f(f(t * t) * t) * f(f(t * f(f(t * 6) - 15)) + 10));
const lerp = (t, a, b) => f(a + f(t * f(b - a)));
function grad(h, x, y, z) {
  const g = G[h & 15];
  return f(f(f(g[0] * x) + f(g[1] * y)) + f(g[2] * z));
}

export function noise(x, y = 0, z = 0) {
  x = f(x); y = f(y); z = f(z);
  const xf0 = Math.floor(x), yf0 = Math.floor(y), zf0 = Math.floor(z);
  const xi = xf0 & 255, yi = yf0 & 255, zi = zf0 & 255;
  const xf = f(x - xf0), yf = f(y - yf0), zf = f(z - zf0);
  const u = fade(xf), v = fade(yf), w = fade(zf);
  const a = (P[xi] + yi) & 255, aa = (P[a] + zi) & 255, ab = (P[a + 1] + zi) & 255;
  const b = (P[xi + 1] + yi) & 255, ba = (P[b] + zi) & 255, bb = (P[b + 1] + zi) & 255;
  const x1 = f(xf - 1), y1 = f(yf - 1), z1 = f(zf - 1);
  const la = lerp(u, grad(P[aa], xf, yf, zf), grad(P[ba], x1, yf, zf));
  const lb = lerp(u, grad(P[ab], xf, y1, zf), grad(P[bb], x1, y1, zf));
  const la1 = lerp(u, grad(P[aa + 1], xf, yf, z1), grad(P[ba + 1], x1, yf, z1));
  const lb1 = lerp(u, grad(P[ab + 1], xf, y1, z1), grad(P[bb + 1], x1, y1, z1));
  return lerp(w, lerp(v, la, lb), lerp(v, la1, lb1));
}
