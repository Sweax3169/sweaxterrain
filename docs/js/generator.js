// Port of src/Uretici.lua (the plugin's terrain core) to JavaScript. Same seed + same settings
// gives the same heights and surface materials as the plugin writes in Roblox Studio
// (checked against Studio voxel dumps with tools/check_generator.mjs).
// The website only needs the top surface of each 4-stud column, the liquid above it, and full
// voxel stacks for the columns on the walls of the diorama, so pass 2 runs per column on demand.
import { noise } from "./noise.js";

const COZ = 4;
const clamp = (v, a, b) => Math.min(Math.max(v, a), b);

function fbm(x, z, ok, f, kaz) {
  let top = 0, gen = 1, tf = f, nrm = 0;
  for (let i = 0; i < ok; i++) {
    top += noise(x * tf, kaz * 7.31, z * tf) * gen;
    nrm += gen;
    gen *= 0.5;
    tf *= 2.03;
  }
  return top / nrm;
}

function ridged(x, z, ok, f, kaz) {
  let top = 0, gen = 1, tf = f, nrm = 0;
  for (let i = 0; i < ok; i++) {
    const n = 1 - Math.abs(noise(x * tf, kaz * 3.77, z * tf));
    top += n * n * gen;
    nrm += gen;
    gen *= 0.52;
    tf *= 2.11;
  }
  return top / nrm;
}

function tohumSayi(K, i, kanal) {
  const n = noise(i * 0.7317 + 0.1234, kanal * 1.618 + 0.377, K * 0.913 + 0.5);
  const a = n * 43758.5453;
  return a - Math.floor(a);
}

const VOLKAN_HUCRE = 230;
const BIYOM = {
  ova: (u, v, K) => [4 + fbm(u, v, 3, 1 / 90, K + 1) * 5, 0],
  tepe: (u, v, K) => {
    const n = fbm(u, v, 4, 1 / 150, K + 2);
    return [12 + n * 16 + Math.abs(fbm(u, v, 3, 1 / 55, K + 2.5)) * 6, 0];
  },
  dag: (u, v, K) => {
    const sirt = ridged(u, v, 4, 1 / 260, K + 3);
    return [14 + sirt * sirt * 130 + fbm(u, v, 3, 1 / 60, K + 3.5) * 10, 0];
  },
  plato: (u, v, K) => {
    const n = (fbm(u, v, 3, 1 / 200, K + 4) + 1) / 2;
    const kat = Math.floor(n * 4.6);
    const kesir = n * 4.6 - kat;
    const kenar = clamp((kesir - 0.82) / 0.18, 0, 1);
    return [6 + (kat + kenar) * 14, 0];
  },
  kanyon: (u, v, K) => {
    let taban = 30 + fbm(u, v, 3, 1 / 160, K + 5) * 8;
    const m = Math.abs(fbm(u, v, 2, 1 / 240, K + 5.5));
    if (m < 0.24) {
      const d = 1 - m / 0.24;
      let derin = Math.min(d * 1.6, 1);
      derin = Math.floor(derin * 4) / 4 + ((derin * 4) % 1) * 0.12;
      taban -= derin * 42;
    }
    return [Math.max(taban, 1.5), 0];
  },
  volkan: (u, v, K) => {
    const hx0 = Math.floor(u / VOLKAN_HUCRE), hz0 = Math.floor(v / VOLKAN_HUCRE);
    let koni = 0;
    for (let dx = -1; dx <= 1; dx++) {
      for (let dz = -1; dz <= 1; dz++) {
        const hx = hx0 + dx, hz = hz0 + dz;
        const vr = noise(hx * 0.71 + 0.13, hz * 0.59 + 0.41, K + 6.1);
        if (vr > -0.2) {
          const px = (hx + 0.5 + clamp(noise(hx * 0.37 + 0.29, hz * 0.83 + 0.17, K + 6.2), -0.5, 0.5) * 0.6) * VOLKAN_HUCRE;
          const pz = (hz + 0.5 + clamp(noise(hx * 0.91 + 0.53, hz * 0.27 + 0.61, K + 6.3), -0.5, 0.5) * 0.6) * VOLKAN_HUCRE;
          const yaricap = 92 + (vr + 0.2) * 40;
          const d = Math.sqrt((u - px) ** 2 + (v - pz) ** 2);
          koni = Math.max(koni, 1 - d / yaricap);
        }
      }
    }
    koni = clamp(koni, 0, 1);
    let h = 8 + koni ** 1.7 * 120;
    let lav = 0;
    if (koni > 0.72) {
      const kr = (koni - 0.72) / 0.28;
      h = 8 + 0.72 ** 1.7 * 120 - Math.min(kr * 2.4, 1) * 24;
      lav = clamp((kr - 0.3) / 0.15, 0, 1);
    }
    return [h + ridged(u, v, 3, 1 / 70, K + 6.5) * 9 * (1 - lav), lav];
  },
  col: (u, v, K) => {
    const yon = fbm(u, v, 2, 1 / 500, K + 7) * 0.7;
    const dalga = Math.sin(u * 0.045 + yon * 8 + fbm(u, v, 2, 1 / 120, K + 7.3) * 3);
    return [7 + (dalga * 0.5 + 0.5) * 12 + fbm(u, v, 3, 1 / 200, K + 7.6) * 4, 0];
  },
  arktik: (u, v, K) => {
    const n = fbm(u, v, 4, 1 / 190, K + 8);
    const vadi = Math.abs(fbm(u, v, 2, 1 / 300, K + 8.4));
    return [10 + n * 14 + vadi * vadi * 42, 0];
  },
  bataklik: (u, v, K) => [-0.5 + fbm(u, v, 4, 1 / 70, K + 9) * 2.6, 0],
};

// biome material sets: surface, slope, deep, patches
export const TAKIM = {
  ova: ["Grass", "Ground", "Ground", "LeafyGrass"],
  tepe: ["Grass", "Rock", "Ground", "LeafyGrass"],
  dag: ["Rock", "Slate", "Rock", "Ground"],
  plato: ["Ground", "Sandstone", "Sandstone", "Grass"],
  kanyon: ["Sandstone", "Sandstone", "Rock", "Ground"],
  volkan: ["Basalt", "Basalt", "Rock", "Rock"],
  col: ["Sand", "Sandstone", "Sandstone", "Sand"],
  arktik: ["Snow", "Glacier", "Rock", "Snow"],
  bataklik: ["LeafyGrass", "Mud", "Ground", "Mud"],
};

export const DEFAULTS = {
  cekirdek: 618033988,
  merkez: [0, 40, 0],
  boyutX: 512,
  boyutZ: 512,
  yukOlcek: 1.0,
  puruz: 0.5,
  warp: 0.5,
  teras: 0,
  biyomBoyut: 320,
  biyomlar: { ova: 1, tepe: 0.7, dag: 0.6 },
  su: {
    seviye: 0,
    gol: { etkin: true, yogunluk: 0.5, derinlik: 10, kum: 6 },
    nehir: { etkin: false, adet: 1, genislik: 10, kivrim: 0.5, derinlik: 5 },
    okyanus: { etkin: false, yon: "bati", plaj: 40 },
  },
  magara: { etkin: false, yogunluk: 0.5, boyut: 0.5 },
  detay: { cikinti: 0.35, benek: 0.6, karCizgisi: 0.72 },
};

function merge(base, over) {
  const out = structuredClone(base);
  for (const [k, v] of Object.entries(over || {})) {
    if (k === "biyomlar") out[k] = { ...v };
    else if (v && typeof v === "object" && !Array.isArray(v) && typeof out[k] === "object") out[k] = merge(out[k], v);
    else out[k] = v;
  }
  return out;
}

export function generate(settings) {
  const A = merge(DEFAULTS, settings);
  const s0 = ((A.cekirdek % 100000) + 100000) % 100000; // Lua's % is floored
  const K = ((s0 * 7919) % 100000) / 977.0;
  let adlar = Object.keys(A.biyomlar).filter((ad) => BIYOM[ad] && A.biyomlar[ad] > 0.02).sort();
  const w = {};
  for (const ad of adlar) w[ad] = A.biyomlar[ad];
  if (adlar.length === 0) { adlar = ["ova"]; w.ova = 1; }

  const tabanY = A.merkez[1];
  const suSeviye = tabanY + A.su.seviye;
  const Nx = Math.max(8, Math.floor(A.boyutX / COZ + 0.5));
  const Nz = Math.max(8, Math.floor(A.boyutZ / COZ + 0.5));
  const x0 = Math.floor((A.merkez[0] - (Nx * COZ) / 2) / COZ) * COZ;
  const z0 = Math.floor((A.merkez[2] - (Nz * COZ) / 2) / COZ) * COZ;
  const W = Nx + 2, D = Nz + 2;
  const at = (ix, iz) => ix * D + iz;
  const H = new Float64Array(W * D);
  const ANA = new Array(W * D);
  const SUALT = new Uint8Array(W * D);
  const LAV = new Float64Array(W * D);
  const OKY = new Uint8Array(W * D);
  const warpS = A.warp * 60;
  const golA = A.su.gol, nehirA = A.su.nehir, okyA = A.su.okyanus;
  const nehirler = [];
  if (nehirA.etkin) {
    for (let i = 1; i <= Math.max(1, Math.floor(nehirA.adet)); i++) {
      nehirler.push({ zTaban: 0.15 + 0.7 * tohumSayi(K, i, 1), faz: 1000 * tohumSayi(K, i, 2) });
    }
  }
  const bf = 1 / Math.max(60, A.biyomBoyut);

  for (let ix = 0; ix <= Nx + 1; ix++) {
    const x = x0 + ix * COZ;
    for (let iz = 0; iz <= Nz + 1; iz++) {
      const z = z0 + iz * COZ;
      const u = x + fbm(x, z, 2, 1 / 180, K + 11) * warpS;
      const v = z + fbm(x, z, 2, 1 / 180, K + 12) * warpS;
      let topW = 0, enAd = adlar[0], enW = -1, hTop = 0, lavTop = 0;
      for (let i = 0; i < adlar.length; i++) {
        const ad = adlar[i];
        let m = (fbm(u, v, 2, bf, K + 20 + (i + 1) * 4) + 1) / 2;
        m = m * m * m * w[ad];
        if (adlar.length === 1) m = 1;
        if (m > 0.001) {
          const [hb, ek] = BIYOM[ad](u, v, K);
          hTop += hb * m;
          lavTop += ek * m;
          topW += m;
          if (m > enW) { enW = m; enAd = ad; }
        }
      }
      let h = topW > 0.001 ? hTop / topW : 4;
      h *= A.yukOlcek;
      h += fbm(u, v, 3, 1 / 26, K + 13) * (A.puruz * 4.5);
      if (A.teras > 0.03) {
        const q = Math.floor(h / 10) * 10;
        h = h + (q - h) * Math.min(A.teras, 1) * 0.85;
      }
      let suKazisi = false;
      if (golA.etkin) {
        const g = (fbm(u, v, 2, 1 / 150, K + 14) + 1) / 2;
        const esik = 0.66 - golA.yogunluk * 0.14;
        if (g > esik) {
          const alcak = clamp(1 - (h - 14) / 26, 0, 1);
          const d = Math.min(((g - esik) / (1 - esik)) * 1.5, 1) * alcak;
          const hedef = suSeviye - tabanY - golA.derinlik * d;
          const yeni = Math.min(h, 3 + hedef);
          h = h + (yeni - h) * Math.min(d * 1.8, 1);
          if (h + tabanY < suSeviye + 0.5) suKazisi = true;
        }
      }
      if (nehirA.etkin) {
        for (const n of nehirler) {
          const yolZ = z0 + n.zTaban * Nz * COZ + fbm(x, n.faz, 2, 1 / 150, K + 15) * (nehirA.kivrim * 140);
          const dz = Math.abs(z - yolZ);
          const yariGen = nehirA.genislik / 2;
          if (dz < yariGen + 10) {
            let d = clamp(1 - (dz - yariGen) / 10, 0, 1);
            if (dz < yariGen) d = 1;
            const hedef = suSeviye - tabanY - nehirA.derinlik;
            const yeni = Math.min(h, hedef + (1 - d) * 6);
            h = h + (yeni - h) * d;
            if (dz < yariGen + 4) suKazisi = true;
          }
        }
      }
      let okyanusta = false;
      if (okyA.etkin) {
        let dKenar, boy;
        if (okyA.yon === "bati") { dKenar = x - x0; boy = Nx * COZ; }
        else if (okyA.yon === "dogu") { dKenar = x0 + Nx * COZ - x; boy = Nx * COZ; }
        else if (okyA.yon === "kuzey") { dKenar = z - z0; boy = Nz * COZ; }
        else { dKenar = z0 + Nz * COZ - z; boy = Nz * COZ; }
        const plaj = Math.max(okyA.plaj, 8);
        const deniz = Math.max(plaj * 1.6, boy * 0.38);
        if (dKenar < deniz) {
          okyanusta = true;
          let t = clamp(dKenar / deniz, 0, 1);
          const kiyiN = fbm(0, okyA.yon === "kuzey" || okyA.yon === "guney" ? x : z, 2, 1 / 150, K + 16) * 0.25;
          t = clamp(t + kiyiN, 0, 1);
          const hedef = suSeviye - tabanY - 18 * (1 - t);
          h = Math.min(h, hedef + t * t * (h - hedef));
          if (h + tabanY < suSeviye + 0.5) suKazisi = true;
        }
      }
      const k = at(ix, iz);
      H[k] = tabanY + h;
      ANA[k] = enAd;
      SUALT[k] = suKazisi ? 1 : 0;
      LAV[k] = topW > 0.001 ? lavTop / topW : 0;
      OKY[k] = okyanusta ? 1 : 0;
    }
  }

  // beaches: land next to real water, a little above the water line
  const KIYI = new Uint8Array(W * D);
  {
    const kum = golA.kum || 0;
    const adim = clamp(Math.ceil(kum / COZ), 0, 4);
    const islak = new Uint8Array(W * D);
    for (let ix = 0; ix < W; ix++) for (let iz = 0; iz < D; iz++) {
      const k = at(ix, iz);
      islak[k] = H[k] < suSeviye - 0.3 && ANA[k] !== "volkan" ? 1 : 0;
    }
    let yayil = islak;
    for (let s = 0; s < adim; s++) {
      const yeni = new Uint8Array(W * D);
      for (let ix = 0; ix < W; ix++) for (let iz = 0; iz < D; iz++) {
        const k = at(ix, iz);
        yeni[k] = yayil[k] || (iz > 0 && yayil[k - 1]) || (iz < D - 1 && yayil[k + 1]) ||
          (ix > 0 && yayil[k - D]) || (ix < W - 1 && yayil[k + D]) ? 1 : 0;
      }
      yayil = yeni;
    }
    for (let ix = 0; ix < W; ix++) for (let iz = 0; iz < D; iz++) {
      const k = at(ix, iz);
      const h = H[k];
      const plajBoy = OKY[k] ? Math.max(kum, 5) : kum;
      KIYI[k] = !islak[k] && h >= suSeviye - 0.5 && h < suSeviye + plajBoy &&
        (yayil[k] || (OKY[k] && h < suSeviye + 3)) ? 1 : 0;
    }
  }

  let minH = Infinity, maxH = -Infinity;
  for (let k = 0; k < W * D; k++) { minH = Math.min(minH, H[k]); maxH = Math.max(maxH, H[k]); }
  minH = Math.min(minH, suSeviye) - 14;
  maxH = Math.max(maxH, suSeviye) + 6;
  const y0 = Math.floor(minH / COZ) * COZ;
  const Ny = Math.ceil((maxH - y0) / COZ) + 1;
  const magA = A.magara, cik = A.detay.cikinti, karC = A.detay.karCizgisi, benekS = A.detay.benek;

  // Pass 2 for one column (0 <= ix < Nx, 0 <= iz < Nz): voxel materials and occupancies bottom-up,
  // exactly as the plugin writes them. stopAtSurface: only scan down from the top until solid ground.
  function column(ix, iz, stopAtSurface) {
    const x = x0 + (ix + 0.5) * COZ, z = z0 + (iz + 0.5) * COZ;
    const k = at(ix, iz);
    const h = H[k];
    const egim = Math.max(Math.abs(H[at(ix + 1, iz)] - h), Math.abs(H[k + 1] - h)) / COZ;
    const ana = ANA[k];
    const takim = TAKIM[ana] || TAKIM.ova;
    const suKazisi = SUALT[k], kiyi = KIYI[k], lav = LAV[k];
    const benek = benekS > 0.05 ? fbm(x, z, 2, 1 / 34, K + 17) > 0.62 - benekS * 0.3 : false;
    const mats = new Array(Ny).fill("Air");
    const occ = new Float32Array(Ny);
    for (let j = Ny; j >= 1; j--) {
      const yAlt = y0 + (j - 1) * COZ;
      const yUst = yAlt + COZ;
      let doluluk = clamp((h - yAlt) / COZ, 0, 1);
      if ((cik > 0.03 && doluluk > 0 && doluluk < 1) || (cik > 0.03 && Math.abs(yAlt - h) < 10)) {
        if ((ana === "dag" || ana === "kanyon" || ana === "volkan") && egim > 0.55) {
          const n3 = noise(x / 23, yAlt / 23, z / 23);
          doluluk = clamp(doluluk + n3 * cik * 1.3, 0, 1);
        }
      }
      if (magA.etkin && doluluk > 0 && h - yUst > 6 && yAlt > y0 + 4) {
        if (stopAtSurface) break; // caves start 6 studs under the surface: the top is already found
        const f = 1 / (30 + magA.boyut * 40);
        const c1 = noise(x * f, yAlt * f * 1.6, z * f);
        const c2 = noise(x * f + 91.7, yAlt * f * 1.6 + 12.9, z * f + 47.3);
        const esik = 0.055 + magA.yogunluk * 0.075;
        if (Math.abs(c1) < esik && Math.abs(c2) < esik) doluluk = 0;
      }
      if (doluluk > 0.01) {
        const derinlik = h - yUst;
        let m;
        if (derinlik > 7) m = takim[2];
        else if (egim > 1.1) m = takim[1];
        else m = benek ? takim[3] : takim[0];
        if ((ana === "dag" || ana === "tepe" || ana === "arktik") && h > tabanY + (30 + karC * 35) * A.yukOlcek && derinlik < 6) {
          m = ana === "arktik" ? "Glacier" : "Snow";
        }
        if (ana === "dag" && derinlik < 4 && h < tabanY + 26 && egim < 0.9) m = benek ? "Grass" : "Ground";
        if (ana === "volkan" && lav > 0.5 && derinlik < 6) m = "CrackedLava";
        if (kiyi && ana !== "volkan" && derinlik < 4) m = ana === "arktik" ? "Snow" : ana === "bataklik" ? "Mud" : "Sand";
        if (suKazisi && derinlik < 5) m = ana === "bataklik" ? "Mud" : "Sand";
        mats[j - 1] = m;
        occ[j - 1] = doluluk;
      }
      if (yAlt >= h - COZ && yUst <= suSeviye + COZ) {
        const suDoluluk = clamp((suSeviye - yAlt) / COZ, 0, 1);
        if (suDoluluk > 0.05 && doluluk < 0.5) {
          if (ana === "volkan") { mats[j - 1] = "CrackedLava"; occ[j - 1] = 1; }
          else if (ana === "arktik" && suDoluluk < 1) { mats[j - 1] = "Ice"; occ[j - 1] = 1; }
          else { mats[j - 1] = "Water"; occ[j - 1] = suDoluluk; }
        }
      }
      // surface scan: stop a few voxels below the first solid one
      if (stopAtSurface && mats[j - 1] !== "Air" && mats[j - 1] !== "Water" && yUst < h - 8) break;
    }
    return { mats, occ };
  }

  // top surface of every column: solid top (height + material) and the water surface above it
  const top = new Float32Array(Nx * Nz);
  const topMat = new Array(Nx * Nz);
  const water = new Float32Array(Nx * Nz).fill(NaN);
  for (let ix = 0; ix < Nx; ix++) {
    for (let iz = 0; iz < Nz; iz++) {
      const c = column(ix, iz, true);
      const i = ix * Nz + iz;
      top[i] = NaN;
      for (let j = Ny - 1; j >= 0; j--) {
        const m = c.mats[j];
        if (m === "Air") continue;
        const ya = y0 + j * COZ;
        if (m === "Water") {
          if (Number.isNaN(water[i])) water[i] = ya + c.occ[j] * COZ;
          continue;
        }
        top[i] = ya + c.occ[j] * COZ;
        topMat[i] = m;
        break;
      }
    }
  }

  return {
    settings: A, Nx, Nz, Ny, x0, z0, y0, res: COZ, suSeviye, tabanY,
    top, topMat, water, column: (ix, iz) => column(ix, iz, false),
    biome: (ix, iz) => ANA[at(ix, iz)],
  };
}
