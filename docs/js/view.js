// WebGL2 view of a generated world: a smooth surface over the 4-stud columns, strata walls on
// every open edge (outer sides and erased holes), water, a brush ball and a selection box.
// Drag to orbit, wheel or pinch to zoom. Heights and materials come from generator.js.

export const COLORS = {
  Grass: [92, 128, 50], LeafyGrass: [78, 112, 46], Ground: [118, 98, 68], Rock: [112, 114, 116],
  Slate: [86, 92, 92], Snow: [236, 240, 248], Glacier: [168, 210, 238], Ice: [176, 220, 240],
  Sand: [214, 192, 140], Sandstone: [176, 116, 82], Mud: [80, 64, 50], Basalt: [50, 48, 54],
  CrackedLava: [255, 108, 24], Water: [46, 110, 168],
};
const GLOW = { CrackedLava: 1 };

const VS = `#version 300 es
in vec3 aPos; in vec3 aNor; in vec4 aCol;
uniform mat4 uVP;
out vec3 vNor; out vec4 vCol; out vec3 vPos;
void main(){ vNor=aNor; vCol=aCol; vPos=aPos; gl_Position=uVP*vec4(aPos,1.0); }`;
const FS = `#version 300 es
precision highp float;
in vec3 vNor; in vec4 vCol; in vec3 vPos;
uniform vec3 uSun; uniform vec3 uSky; uniform vec3 uGround; uniform float uAlpha;
out vec4 o;
float h(vec3 p){ return fract(sin(dot(floor(p*0.9),vec3(12.9898,78.233,37.719)))*43758.5453); }
void main(){
  vec3 n=normalize(vNor);
  float d=max(dot(n,uSun),0.0);
  vec3 amb=mix(uGround,uSky,n.y*0.5+0.5);
  float grain=0.92+0.12*h(vPos);
  vec3 base=vCol.rgb*grain;
  float glow=vCol.a>1.5?1.0:0.0;
  vec3 c=base*(amb*0.62+vec3(1.0,0.96,0.9)*d*0.85);
  c=mix(c,base*1.25,glow);
  float a=vCol.a>1.5?1.0:vCol.a;
  o=vec4(pow(c,vec3(1.0/1.08)),a*uAlpha);
}`;

function mat4mul(a, b) {
  const o = new Float32Array(16);
  for (let i = 0; i < 4; i++) for (let j = 0; j < 4; j++) {
    let s = 0;
    for (let k = 0; k < 4; k++) s += a[k * 4 + j] * b[i * 4 + k];
    o[i * 4 + j] = s;
  }
  return o;
}
function perspective(fov, asp, n, f) {
  const t = 1 / Math.tan(fov / 2);
  return new Float32Array([t / asp, 0, 0, 0, 0, t, 0, 0, 0, 0, (f + n) / (n - f), -1, 0, 0, (2 * f * n) / (n - f), 0]);
}
function lookAt(e, c, up) {
  let zx = e[0] - c[0], zy = e[1] - c[1], zz = e[2] - c[2];
  let l = Math.hypot(zx, zy, zz); zx /= l; zy /= l; zz /= l;
  let xx = up[1] * zz - up[2] * zy, xy = up[2] * zx - up[0] * zz, xz = up[0] * zy - up[1] * zx;
  l = Math.hypot(xx, xy, xz); xx /= l; xy /= l; xz /= l;
  const yx = zy * xz - zz * xy, yy = zz * xx - zx * xz, yz = zx * xy - zy * xx;
  return new Float32Array([xx, yx, zx, 0, xy, yy, zy, 0, xz, yz, zz, 0,
    -(xx * e[0] + xy * e[1] + xz * e[2]), -(yx * e[0] + yy * e[1] + yz * e[2]), -(zx * e[0] + zy * e[1] + zz * e[2]), 1]);
}
function invert(m) {
  const a = m, o = new Float32Array(16);
  const b00 = a[0] * a[5] - a[1] * a[4], b01 = a[0] * a[6] - a[2] * a[4], b02 = a[0] * a[7] - a[3] * a[4];
  const b03 = a[1] * a[6] - a[2] * a[5], b04 = a[1] * a[7] - a[3] * a[5], b05 = a[2] * a[7] - a[3] * a[6];
  const b06 = a[8] * a[13] - a[9] * a[12], b07 = a[8] * a[14] - a[10] * a[12], b08 = a[8] * a[15] - a[11] * a[12];
  const b09 = a[9] * a[14] - a[10] * a[13], b10 = a[9] * a[15] - a[11] * a[13], b11 = a[10] * a[15] - a[11] * a[14];
  let det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
  if (!det) return null;
  det = 1 / det;
  o[0] = (a[5] * b11 - a[6] * b10 + a[7] * b09) * det; o[1] = (a[2] * b10 - a[1] * b11 - a[3] * b09) * det;
  o[2] = (a[13] * b05 - a[14] * b04 + a[15] * b03) * det; o[3] = (a[10] * b04 - a[9] * b05 - a[11] * b03) * det;
  o[4] = (a[6] * b08 - a[4] * b11 - a[7] * b07) * det; o[5] = (a[0] * b11 - a[2] * b08 + a[3] * b07) * det;
  o[6] = (a[14] * b02 - a[12] * b05 - a[15] * b01) * det; o[7] = (a[8] * b05 - a[10] * b02 + a[11] * b01) * det;
  o[8] = (a[4] * b10 - a[5] * b08 + a[7] * b06) * det; o[9] = (a[1] * b08 - a[0] * b10 - a[3] * b06) * det;
  o[10] = (a[12] * b04 - a[13] * b02 + a[15] * b00) * det; o[11] = (a[9] * b02 - a[8] * b04 - a[11] * b00) * det;
  o[12] = (a[5] * b07 - a[4] * b09 - a[6] * b06) * det; o[13] = (a[0] * b09 - a[1] * b07 + a[2] * b06) * det;
  o[14] = (a[13] * b01 - a[12] * b03 - a[14] * b00) * det; o[15] = (a[8] * b03 - a[9] * b01 + a[10] * b00) * det;
  return o;
}

const lin = (c) => c.map((v) => v / 255);

// unit shapes (-0.5..0.5), faces as vertex index lists
const UNIT = (() => {
  const box = { v: [], f: [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]] };
  for (const x of [-0.5, 0.5]) for (const y of [-0.5, 0.5]) for (const z of [-0.5, 0.5]) box.v.push([x, y, z]);
  const cyl = { v: [], f: [] };
  const n = 14;
  for (const x of [-0.5, 0.5]) for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2;
    cyl.v.push([x, Math.cos(a) * 0.5, Math.sin(a) * 0.5]);
  }
  for (let i = 0; i < n; i++) cyl.f.push([i, (i + 1) % n, n + (i + 1) % n, n + i]);
  cyl.f.push([...Array(n).keys()].reverse(), [...Array(n).keys()].map((i) => i + n));
  const ball = { v: [], f: [] };
  const la = 7, lo = 12;
  for (let i = 0; i <= la; i++) for (let j = 0; j < lo; j++) {
    const t = (i / la) * Math.PI, p = (j / lo) * Math.PI * 2;
    ball.v.push([Math.sin(t) * Math.cos(p) * 0.5, Math.cos(t) * 0.5, Math.sin(t) * Math.sin(p) * 0.5]);
  }
  for (let i = 0; i < la; i++) for (let j = 0; j < lo; j++) {
    const a = i * lo + j, b = i * lo + (j + 1) % lo;
    ball.f.push([a, b, b + lo, a + lo]);
  }
  const wedge = {
    v: [[-0.5, -0.5, -0.5], [0.5, -0.5, -0.5], [0.5, -0.5, 0.5], [-0.5, -0.5, 0.5], [-0.5, 0.5, 0.5], [0.5, 0.5, 0.5]],
    f: [[0, 1, 2, 3], [3, 2, 5, 4], [0, 4, 5, 1], [0, 3, 4], [1, 5, 2]],
  };
  return [box, cyl, ball, wedge];
})();

function partTriangles(s, P, N, C, tP, tN, tC, ghostAlpha) {
  const th = ((s.rot || 0) * Math.PI) / 180, cs = Math.cos(th), sn = Math.sin(th), k = s.scale || 1;
  const ry = (v) => [v[0] * cs + v[2] * sn, v[1], -v[0] * sn + v[2] * cs];
  for (const r of s.rows) {
    const u = UNIT[r[0]] || UNIT[0];
    const R = r.slice(4, 13), size = r.slice(13, 16);
    const col = [r[16] / 255, r[17] / 255, r[18] / 255];
    const alpha = ghostAlpha ?? 1 - r[19];
    const glow = r[20] && ghostAlpha == null ? 2 : alpha;
    const W = u.v.map((v) => {
      const l = [v[0] * size[0], v[1] * size[1], v[2] * size[2]];
      const w = [R[0] * l[0] + R[1] * l[1] + R[2] * l[2] + r[1], R[3] * l[0] + R[4] * l[1] + R[5] * l[2] + r[2], R[6] * l[0] + R[7] * l[1] + R[8] * l[2] + r[3]];
      const q = ry([w[0] * k, w[1] * k, w[2] * k]);
      return [q[0] + s.pos[0], q[1] + s.pos[1], q[2] + s.pos[2]];
    });
    const [OP, ON, OC] = alpha < 0.99 && ghostAlpha == null ? [tP, tN, tC] : [P, N, C];
    for (const f of u.f) {
      const a = W[f[0]], b = W[f[1]], c = W[f[2]];
      let nx = (b[1] - a[1]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[1] - a[1]);
      let ny = (b[2] - a[2]) * (c[0] - a[0]) - (b[0] - a[0]) * (c[2] - a[2]);
      let nz = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
      const l = Math.hypot(nx, ny, nz) || 1; nx /= l; ny /= l; nz /= l;
      for (let i = 1; i < f.length - 1; i++) {
        for (const vi of [f[0], f[i], f[i + 1]]) {
          OP.push(...W[vi]); ON.push(nx, ny, nz); OC.push(col[0], col[1], col[2], glow);
        }
      }
    }
  }
}

export class TerrainView {
  constructor(canvas) {
    this.canvas = canvas;
    const gl = canvas.getContext("webgl2", { antialias: true, alpha: true, premultipliedAlpha: false });
    this.gl = gl;
    if (!gl) return;
    const sh = (t, s) => { const x = gl.createShader(t); gl.shaderSource(x, s); gl.compileShader(x); return x; };
    const p = gl.createProgram();
    gl.attachShader(p, sh(gl.VERTEX_SHADER, VS));
    gl.attachShader(p, sh(gl.FRAGMENT_SHADER, FS));
    gl.linkProgram(p);
    this.prog = p;
    this.loc = {
      aPos: gl.getAttribLocation(p, "aPos"), aNor: gl.getAttribLocation(p, "aNor"), aCol: gl.getAttribLocation(p, "aCol"),
      uVP: gl.getUniformLocation(p, "uVP"), uSun: gl.getUniformLocation(p, "uSun"), uSky: gl.getUniformLocation(p, "uSky"),
      uGround: gl.getUniformLocation(p, "uGround"), uAlpha: gl.getUniformLocation(p, "uAlpha"),
    };
    this.meshes = {};
    this.yaw = -0.66; this.pitch = 0.58; this.dist = 900;
    this.target = [0, 20, 0];
    this.ball = null; this.box = null;
    this.reveal = Infinity;
    this.bindInput();
    new ResizeObserver(() => this.draw()).observe(canvas);
  }

  get ok() { return !!this.gl; }

  // ---------------------------------------------------------------- world
  setWorld(g) {
    this.g = g;
    const n = g.Nx * g.Nz;
    this.top = Float32Array.from(g.top);
    this.mat = g.topMat.slice();
    this.water = Float32Array.from(g.water);
    this.stacks = new Map(); // column index -> {mats, occ} for strata walls
    const cx = g.x0 + g.Nx * 2, cz = g.z0 + g.Nz * 2;
    this.target = [cx, g.tabanY + 18, cz];
    const aspect = this.canvas.clientWidth / Math.max(this.canvas.clientHeight, 1);
    this.dist = Math.max(g.Nx, g.Nz) * 4 * (aspect < 1.1 ? 2.3 : 1.75);
    this.reveal = Infinity;
    this.build();
    return n;
  }

  stack(ix, iz) {
    const k = ix * this.g.Nz + iz;
    if (!this.stacks.has(k)) this.stacks.set(k, this.g.column(ix, iz));
    return this.stacks.get(k);
  }

  visible(ix, iz) {
    if (ix < 0 || iz < 0 || ix >= this.g.Nx || iz >= this.g.Nz) return false;
    if (this.reveal !== Infinity) {
      // the plugin writes 24 x 24 parcels, outer loop over x
      const P = 24, per = Math.ceil(this.g.Nz / P);
      const order = Math.floor(ix / P) * per + Math.floor(iz / P);
      if (order >= this.reveal) return false;
    }
    return !Number.isNaN(this.top[ix * this.g.Nz + iz]);
  }

  build() {
    const g = this.g, gl = this.gl;
    if (!g || !gl) return;
    const Nx = g.Nx, Nz = g.Nz, R = 4;
    const H = (ix, iz) => this.top[ix * Nz + iz];
    // corner heights: average of the existing columns around each corner
    const CH = new Float32Array((Nx + 1) * (Nz + 1));
    for (let i = 0; i <= Nx; i++) for (let j = 0; j <= Nz; j++) {
      let s = 0, c = 0;
      for (const [a, b] of [[i - 1, j - 1], [i, j - 1], [i - 1, j], [i, j]]) {
        if (this.visible(a, b)) { s += H(a, b); c++; }
      }
      CH[i * (Nz + 1) + j] = c ? s / c : NaN;
    }
    const ch = (i, j) => CH[i * (Nz + 1) + j];
    const pos = [], nor = [], col = [];
    const wpos = [], wnor = [], wcol = [];
    const push = (P, N, C, x, y, z, nx, ny, nz, c, a) => { P.push(x, y, z); N.push(nx, ny, nz); C.push(c[0], c[1], c[2], a); };
    const colorOf = (m) => lin(COLORS[m] || [255, 0, 255]);
    const quad = (P, N, C, v, n, c, a) => {
      for (const k of [0, 1, 2, 0, 2, 3]) push(P, N, C, v[k][0], v[k][1], v[k][2], n[0], n[1], n[2], c, a);
    };
    const X = (i) => g.x0 + i * R, Z = (j) => g.z0 + j * R;
    // surface
    for (let ix = 0; ix < Nx; ix++) for (let iz = 0; iz < Nz; iz++) {
      if (!this.visible(ix, iz)) continue;
      const m = this.mat[ix * Nz + iz];
      const c = colorOf(m);
      const a = GLOW[m] ? 2 : 1;
      const h00 = ch(ix, iz), h10 = ch(ix + 1, iz), h01 = ch(ix, iz + 1), h11 = ch(ix + 1, iz + 1);
      const nx = (h00 + h01 - h10 - h11) / (2 * R), nz = (h00 + h10 - h01 - h11) / (2 * R);
      const l = Math.hypot(nx, 1, nz);
      quad(pos, nor, col, [[X(ix), h00, Z(iz)], [X(ix), h01, Z(iz + 1)], [X(ix + 1), h11, Z(iz + 1)], [X(ix + 1), h10, Z(iz)]],
        [nx / l, 1 / l, nz / l], c, a);
      const w = this.water[ix * Nz + iz];
      if (!Number.isNaN(w)) {
        quad(wpos, wnor, wcol, [[X(ix), w, Z(iz)], [X(ix), w, Z(iz + 1)], [X(ix + 1), w, Z(iz + 1)], [X(ix + 1), w, Z(iz)]],
          [0, 1, 0], colorOf("Water"), 0.72);
      }
      // walls on open edges: strata of this column, from the bottom up to the surface
      const edges = [[ix - 1, iz, [ix, iz], [ix, iz + 1], [-1, 0, 0]], [ix + 1, iz, [ix + 1, iz + 1], [ix + 1, iz], [1, 0, 0]],
        [ix, iz - 1, [ix + 1, iz], [ix, iz], [0, 0, -1]], [ix, iz + 1, [ix, iz + 1], [ix + 1, iz + 1], [0, 0, 1]]];
      for (const [ax, az, p, q, n] of edges) {
        if (this.visible(ax, az)) continue;
        const s = this.stack(ix, iz);
        const hp = ch(p[0], p[1]), hq = ch(q[0], q[1]);
        const topH = this.top[ix * Nz + iz];
        for (let j = 0; j < s.mats.length; j++) {
          const m2 = s.mats[j];
          if (m2 === "Air" || m2 === "Water") continue;
          const y0 = g.y0 + j * R;
          if (y0 >= topH) break;
          let y1 = Math.min(y0 + R * (s.occ[j] < 1 ? s.occ[j] : 1), topH);
          const yp = Math.min(y1, hp), yq = Math.min(y1, hq);
          const top1 = (y1 >= topH - 0.01);
          const cc = colorOf(m2).map((v) => v * 0.82);
          quad(pos, nor, col, [[X(p[0]), y0, Z(p[1])], [X(q[0]), y0, Z(q[1])], [X(q[0]), top1 ? hq : yq, Z(q[1])], [X(p[0]), top1 ? hp : yp, Z(p[1])]],
            n, cc, GLOW[m2] ? 2 : 1);
        }
        const w = this.water[ix * Nz + iz];
        if (!Number.isNaN(w)) {
          const lo = Math.min(hp, hq);
          quad(wpos, wnor, wcol, [[X(p[0]), lo, Z(p[1])], [X(q[0]), lo, Z(q[1])], [X(q[0]), w, Z(q[1])], [X(p[0]), w, Z(p[1])]],
            n, colorOf("Water"), 0.6);
        }
      }
    }
    this.upload("land", pos, nor, col);
    this.upload("water", wpos, wnor, wcol);
    this.draw();
  }

  upload(name, pos, nor, col) {
    const gl = this.gl;
    let m = this.meshes[name];
    if (!m) {
      m = { vao: gl.createVertexArray(), b: [gl.createBuffer(), gl.createBuffer(), gl.createBuffer()], n: 0 };
      gl.bindVertexArray(m.vao);
      const attrs = [[this.loc.aPos, 3], [this.loc.aNor, 3], [this.loc.aCol, 4]];
      attrs.forEach(([loc, size], i) => {
        gl.bindBuffer(gl.ARRAY_BUFFER, m.b[i]);
        gl.enableVertexAttribArray(loc);
        gl.vertexAttribPointer(loc, size, gl.FLOAT, false, 0, 0);
      });
      this.meshes[name] = m;
    }
    [pos, nor, col].forEach((arr, i) => {
      gl.bindBuffer(gl.ARRAY_BUFFER, m.b[i]);
      gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(arr), gl.DYNAMIC_DRAW);
    });
    m.n = pos.length / 3;
  }

  // ---------------------------------------------------------------- overlays
  setBall(p, r) {
    this.ball = p ? { p, r } : null;
    if (p) {
      const pos = [], nor = [], col = [];
      const S = 18, c = [0.92, 0.35, 0.31, 0.38];
      const v = (a, b) => [Math.cos(a) * Math.sin(b), Math.cos(b), Math.sin(a) * Math.sin(b)];
      for (let i = 0; i < S * 2; i++) for (let j = 0; j < S; j++) {
        const a0 = (i / (S * 2)) * Math.PI * 2, a1 = ((i + 1) / (S * 2)) * Math.PI * 2;
        const b0 = (j / S) * Math.PI, b1 = ((j + 1) / S) * Math.PI;
        for (const [a, b] of [[a0, b0], [a0, b1], [a1, b1], [a0, b0], [a1, b1], [a1, b0]]) {
          const n = v(a, b);
          pos.push(p[0] + n[0] * r, p[1] + n[1] * r, p[2] + n[2] * r);
          nor.push(...n);
          col.push(...c);
        }
      }
      this.upload("ball", pos, nor, col);
    }
    this.draw();
  }

  setBox(mn, mx) {
    this.box = mn ? { mn, mx } : null;
    if (mn) {
      const pos = [], nor = [], col = [];
      const c = [0.92, 0.35, 0.31, 0.24];
      const faces = [
        [[mn[0], mn[1], mn[2]], [mn[0], mx[1], mn[2]], [mx[0], mx[1], mn[2]], [mx[0], mn[1], mn[2]], [0, 0, -1]],
        [[mx[0], mn[1], mx[2]], [mx[0], mx[1], mx[2]], [mn[0], mx[1], mx[2]], [mn[0], mn[1], mx[2]], [0, 0, 1]],
        [[mn[0], mn[1], mx[2]], [mn[0], mx[1], mx[2]], [mn[0], mx[1], mn[2]], [mn[0], mn[1], mn[2]], [-1, 0, 0]],
        [[mx[0], mn[1], mn[2]], [mx[0], mx[1], mn[2]], [mx[0], mx[1], mx[2]], [mx[0], mn[1], mx[2]], [1, 0, 0]],
        [[mn[0], mx[1], mn[2]], [mn[0], mx[1], mx[2]], [mx[0], mx[1], mx[2]], [mx[0], mx[1], mn[2]], [0, 1, 0]],
      ];
      for (const f of faces) for (const k of [0, 1, 2, 0, 2, 3]) { pos.push(...f[k]); nor.push(...f[4]); col.push(...c); }
      this.upload("box", pos, nor, col);
    }
    this.draw();
  }

  // ---------------------------------------------------------------- structures (plain parts)
  // rows: [shape, x, y, z, r00..r22, sx, sy, sz, r, g, b, transparency, neon] relative to the base
  setStructures(list) {
    this.placed = list;
    const P = [], N = [], C = [], tP = [], tN = [], tC = [];
    for (const s of list) partTriangles(s, P, N, C, tP, tN, tC, null);
    this.upload("parts", P, N, C);
    this.upload("partsT", tP, tN, tC);
    this.draw();
  }

  setGhost(s) {
    this.ghost = s;
    if (s) {
      const P = [], N = [], C = [];
      partTriangles(s, P, N, C, P, N, C, 0.42);
      this.upload("ghost", P, N, C);
    }
    this.draw();
  }

  // ---------------------------------------------------------------- editing
  carve(p, r) {
    const g = this.g, Nz = g.Nz;
    let changed = false;
    for (let ix = 0; ix < g.Nx; ix++) {
      const x = g.x0 + (ix + 0.5) * 4;
      if (Math.abs(x - p[0]) > r) continue;
      for (let iz = 0; iz < Nz; iz++) {
        const z = g.z0 + (iz + 0.5) * 4;
        const d2 = (x - p[0]) ** 2 + (z - p[2]) ** 2;
        if (d2 > r * r) continue;
        const dy = Math.sqrt(r * r - d2);
        const i = ix * Nz + iz;
        const lo = p[1] - dy, hi = p[1] + dy;
        if (!Number.isNaN(this.water[i]) && this.water[i] > lo) { this.water[i] = NaN; changed = true; }
        if (this.top[i] > lo) {
          this.top[i] = lo <= g.y0 ? NaN : lo;
          changed = true;
        }
        if (hi < lo) continue;
      }
    }
    if (changed) this.build();
    return changed;
  }

  eraseBox(mn, mx) {
    const g = this.g, Nz = g.Nz;
    for (let ix = 0; ix < g.Nx; ix++) for (let iz = 0; iz < Nz; iz++) {
      const x = g.x0 + (ix + 0.5) * 4, z = g.z0 + (iz + 0.5) * 4;
      if (x < mn[0] || x > mx[0] || z < mn[2] || z > mx[2]) continue;
      const i = ix * Nz + iz;
      this.water[i] = NaN;
      if (this.top[i] > mn[1]) this.top[i] = mn[1] <= g.y0 ? NaN : mn[1];
    }
    this.build();
  }

  // ---------------------------------------------------------------- camera + input
  matrices() {
    const c = this.canvas;
    const w = c.clientWidth, h = c.clientHeight;
    const e = [this.target[0] + Math.sin(this.yaw) * Math.cos(this.pitch) * this.dist,
      this.target[1] + Math.sin(this.pitch) * this.dist,
      this.target[2] + Math.cos(this.yaw) * Math.cos(this.pitch) * this.dist];
    const P = perspective(0.62, w / Math.max(h, 1), 4, 20000);
    const V = lookAt(e, this.target, [0, 1, 0]);
    return { VP: mat4mul(P, V), eye: e };
  }

  pick(clientX, clientY) {
    if (!this.g) return null;
    const r = this.canvas.getBoundingClientRect();
    const nx = ((clientX - r.left) / r.width) * 2 - 1, ny = 1 - ((clientY - r.top) / r.height) * 2;
    const { VP, eye } = this.matrices();
    const inv = invert(VP);
    const un = (x, y, z) => {
      const v = [inv[0] * x + inv[4] * y + inv[8] * z + inv[12], inv[1] * x + inv[5] * y + inv[9] * z + inv[13],
        inv[2] * x + inv[6] * y + inv[10] * z + inv[14], inv[3] * x + inv[7] * y + inv[11] * z + inv[15]];
      return [v[0] / v[3], v[1] / v[3], v[2] / v[3]];
    };
    const far = un(nx, ny, 1);
    let d = [far[0] - eye[0], far[1] - eye[1], far[2] - eye[2]];
    const l = Math.hypot(...d); d = d.map((v) => v / l);
    const g = this.g;
    const heightAt = (x, z) => {
      const ix = Math.floor((x - g.x0) / 4), iz = Math.floor((z - g.z0) / 4);
      if (!this.visible(ix, iz)) return -Infinity;
      const w = this.water[ix * g.Nz + iz];
      return Math.max(this.top[ix * g.Nz + iz], Number.isNaN(w) ? -Infinity : w);
    };
    let t = 0, prev = null;
    for (let s = 0; s < 4000; s++) {
      const p = [eye[0] + d[0] * t, eye[1] + d[1] * t, eye[2] + d[2] * t];
      const h = heightAt(p[0], p[2]);
      if (p[1] <= h) {
        if (prev) { // refine
          let a = t - 2, b = t;
          for (let k = 0; k < 8; k++) {
            const m = (a + b) / 2;
            const q = [eye[0] + d[0] * m, eye[1] + d[1] * m, eye[2] + d[2] * m];
            if (q[1] <= heightAt(q[0], q[2])) b = m; else a = m;
          }
          t = b;
        }
        return [eye[0] + d[0] * t, eye[1] + d[1] * t, eye[2] + d[2] * t];
      }
      prev = p;
      t += 2;
      if (t > this.dist * 4) break;
    }
    return null;
  }

  bindInput() {
    const c = this.canvas;
    let drag = null;
    const pts = new Map();
    c.addEventListener("pointerdown", (e) => {
      pts.set(e.pointerId, [e.clientX, e.clientY]);
      if (this.onTool && e.button === 0 && pts.size === 1 && this.onTool("down", e)) return;
      drag = { x: e.clientX, y: e.clientY, yaw: this.yaw, pitch: this.pitch };
      c.setPointerCapture(e.pointerId);
    });
    c.addEventListener("pointermove", (e) => {
      const prev = pts.get(e.pointerId);
      if (prev) pts.set(e.pointerId, [e.clientX, e.clientY]);
      if (pts.size === 2 && prev) {
        const [a, b] = [...pts.values()];
        const d = Math.hypot(a[0] - b[0], a[1] - b[1]);
        if (this._pinch) this.zoom(this._pinch / d);
        this._pinch = d;
        return;
      }
      if (this.onTool && this.onTool("move", e)) return;
      if (!drag) return;
      this.yaw = drag.yaw - (e.clientX - drag.x) * 0.006;
      this.pitch = Math.min(1.35, Math.max(0.12, drag.pitch + (e.clientY - drag.y) * 0.005));
      this.draw();
    });
    const up = (e) => {
      pts.delete(e.pointerId);
      this._pinch = null;
      if (this.onTool) this.onTool("up", e);
      drag = null;
    };
    c.addEventListener("pointerup", up);
    c.addEventListener("pointercancel", up);
    c.addEventListener("pointerleave", (e) => { if (this.onTool) this.onTool("leave", e); });
    c.addEventListener("wheel", (e) => { e.preventDefault(); this.zoom(Math.exp(e.deltaY * 0.0012)); }, { passive: false });
  }

  zoom(f) {
    const base = this.g ? Math.max(this.g.Nx, this.g.Nz) * 4 : 600;
    this.dist = Math.min(base * 3, Math.max(base * 0.35, this.dist * f));
    this.draw();
  }

  draw() {
    if (!this.gl || this._raf) return;
    this._raf = requestAnimationFrame(() => { this._raf = 0; this.render(); });
  }

  render() {
    const gl = this.gl;
    if (!gl) return;
    {
      const c = this.canvas;
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      const w = Math.round(c.clientWidth * dpr), h = Math.round(c.clientHeight * dpr);
      if (c.width !== w || c.height !== h) { c.width = w; c.height = h; }
      gl.viewport(0, 0, w, h);
      gl.clearColor(0, 0, 0, 0);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
      gl.enable(gl.DEPTH_TEST);
      gl.useProgram(this.prog);
      const { VP } = this.matrices();
      gl.uniformMatrix4fv(this.loc.uVP, false, VP);
      const sun = [-0.42, 0.72, -0.55], l = Math.hypot(...sun);
      gl.uniform3f(this.loc.uSun, sun[0] / l, sun[1] / l, sun[2] / l);
      gl.uniform3f(this.loc.uSky, 0.78, 0.86, 0.96);
      gl.uniform3f(this.loc.uGround, 0.42, 0.38, 0.33);
      gl.uniform1f(this.loc.uAlpha, 1);
      gl.disable(gl.BLEND);
      const m = this.meshes;
      const drawMesh = (k) => { if (m[k] && m[k].n) { gl.bindVertexArray(m[k].vao); gl.drawArrays(gl.TRIANGLES, 0, m[k].n); } };
      drawMesh("land");
      drawMesh("parts");
      gl.enable(gl.BLEND);
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
      gl.depthMask(false);
      drawMesh("water");
      drawMesh("partsT");
      if (this.ghost) drawMesh("ghost");
      if (this.ball) drawMesh("ball");
      if (this.box) drawMesh("box");
      gl.depthMask(true);
    }
  }
}
