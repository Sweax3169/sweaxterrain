// HTML copy of the plugin panel (src/Arayuz.lua): same sections, same defaults, same presets,
// same English/Turkish strings (docs/data/strings.json is exported from src/Dil.lua).

export const MATERIAL_RGB = {
  Grass: [106, 127, 63], LeafyGrass: [115, 132, 74], Ground: [102, 92, 59], Rock: [102, 108, 111],
  Sandstone: [137, 90, 71], Basalt: [30, 30, 37], Sand: [143, 126, 95], Snow: [195, 199, 218], Mud: [58, 46, 36],
  Glacier: [101, 176, 234], Ice: [129, 194, 224], CrackedLava: [232, 156, 74], Water: [12, 84, 92],
};
// Roblox's default MaterialColors, as the plugin's swatches show them in a fresh place

const BIYOMLAR = [
  ["ova", "b_ova", true, 0.8, "Grass"], ["tepe", "b_tepe", true, 0.7, "LeafyGrass"], ["dag", "b_dag", true, 0.9, "Rock"],
  ["plato", "b_plato", false, 0.6, "Ground"], ["kanyon", "b_kanyon", false, 0.8, "Sandstone"], ["volkan", "b_volkan", false, 0.8, "Basalt"],
  ["col", "b_col", false, 0.8, "Sand"], ["arktik", "b_arktik", false, 0.8, "Snow"], ["bataklik", "b_bataklik", false, 0.7, "Mud"],
];
const PRESETLER = [
  ["alp", ["Snow", "Rock", "Grass", "Water"]], ["nehir", ["Grass", "LeafyGrass", "Sand", "Water"]],
  ["kanyon", ["Sandstone", "Sand", "Rock", "Ground"]], ["volkan", ["Basalt", "Rock", "CrackedLava", "Basalt"]],
  ["arktik", ["Snow", "Glacier", "Ice", "Rock"]], ["bataklik", ["LeafyGrass", "Mud", "Ground", "Water"]],
  ["sahil", ["Grass", "Sand", "Water", "Water"]], ["karisik", ["Grass", "Sandstone", "Snow", "Basalt"]],
];
const rgb = (m) => `rgb(${(MATERIAL_RGB[m] || [128, 128, 128]).join(",")})`;
const el = (tag, cls, attrs = {}) => {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "text") e.textContent = v;
    else e.setAttribute(k, v);
  }
  return e;
};

export class Panel {
  constructor(root, strings, structures, lang) {
    this.root = root;
    this.S = strings;
    this.structures = structures;
    this.lang = lang;
    this.d = {};
    this.refreshers = [];
    this.texts = [];
    this.on = {};
    this.build();
  }

  L(key, ...args) {
    let s = (this.S[this.lang] && this.S[this.lang][key]) || this.S.en[key] || key;
    for (const a of args) s = s.replace(/%[sd]/, a);
    return s;
  }

  setLang(lang) {
    this.lang = lang;
    for (const [node, key] of this.texts) node.textContent = this.L(key);
    for (const f of this.langRefreshers) f();
    this.refresh();
  }

  t(node, key) { this.texts.push([node, key]); node.textContent = this.L(key); return node; }

  refresh() { for (const f of this.refreshers) f(); }

  status(text, warn) { this.statusNode.textContent = text; this.statusNode.classList.toggle("warn", !!warn); }

  progress(frac, text) { this.barFill.style.width = `${Math.round(frac * 100)}%`; this.barText.textContent = text || ""; }

  build() {
    const r = this.root;
    r.innerHTML = "";
    this.langRefreshers = [];
    const tabs = el("div", "sp-tabs", { role: "tablist" });
    const body = el("div", "sp-body");
    this.statusNode = el("div", "sp-status");
    r.append(tabs, body, this.statusNode);
    this.tabs = {};
    for (const [id, key] of [["uret", "tab_uret"], ["sil", "tab_sil"], ["yapi", "tab_yapi"]]) {
      const b = this.t(el("button", "sp-tab", { role: "tab", type: "button" }), key);
      const pane = el("div", "sp-pane");
      b.addEventListener("click", () => this.tab(id));
      tabs.append(b);
      body.append(pane);
      this.tabs[id] = { b, pane };
    }
    this.buildGenerate(this.tabs.uret.pane);
    this.buildErase(this.tabs.sil.pane);
    this.buildStructures(this.tabs.yapi.pane);
    this.defaults = { ...this.d };
    this.tab("uret");
    this.status(this.L("d_hazir"));
  }

  tab(id) {
    this.active = id;
    for (const [k, v] of Object.entries(this.tabs)) {
      v.b.classList.toggle("on", k === id);
      v.b.setAttribute("aria-selected", k === id);
      v.pane.hidden = k !== id;
    }
    if (this.on.tab) this.on.tab(id);
  }

  // ---------- kit ----------
  head(parent, key) { parent.append(this.t(el("div", "sp-head"), key)); }
  card(parent) { const c = el("div", "sp-card"); parent.append(c); return c; }
  row(card, key) {
    const row = el("div", "sp-row");
    if (key) row.append(this.t(el("span", "sp-label"), key));
    else row.append(el("span", "sp-label"));
    card.append(row);
    return row;
  }

  slider(card, key, name, min, max, value, step, unit = "") {
    this.d[name] = value;
    const row = this.row(card, key);
    const input = el("input", "sp-range", { type: "range", min, max, step, "aria-label": this.L(key) });
    const out = el("span", "sp-val");
    input.addEventListener("input", () => { this.d[name] = Number(input.value); paint(); });
    const paint = () => {
      input.value = this.d[name];
      const f = (this.d[name] - min) / (max - min);
      input.style.setProperty("--f", `${f * 100}%`);
      out.textContent = (step >= 1 ? Math.round(this.d[name]) : Number(this.d[name]).toFixed(2)) + unit;
    };
    this.refreshers.push(paint);
    paint();
    row.append(input, out);
    return row;
  }

  check(card, key, name, value) {
    this.d[name] = value;
    const row = this.row(card, key);
    row.classList.add("sp-checkrow");
    const box = el("button", "sp-check", { type: "button", role: "checkbox" });
    box.addEventListener("click", () => { this.d[name] = !this.d[name]; paint(); });
    const paint = () => { box.classList.toggle("on", !!this.d[name]); box.setAttribute("aria-checked", !!this.d[name]); };
    this.refreshers.push(paint);
    paint();
    row.append(box);
    return box;
  }

  number(row, name, value, width) {
    this.d[name] = value;
    const input = el("input", "sp-num", { type: "text", inputmode: "numeric", style: `width:${width}px` });
    input.addEventListener("change", () => {
      const v = Number(input.value);
      if (Number.isFinite(v)) this.d[name] = v; else input.value = this.d[name];
    });
    this.refreshers.push(() => { input.value = this.d[name]; });
    input.value = value;
    row.append(input);
    return input;
  }

  button(parent, key, kind) {
    const b = this.t(el("button", `sp-btn ${kind || ""}`, { type: "button" }), key);
    parent.append(b);
    return b;
  }

  twice(btn, key, action) {
    let armed = false, timer;
    btn.addEventListener("click", () => {
      if (!armed) {
        armed = true;
        btn.textContent = this.L("b_emin");
        timer = setTimeout(() => { armed = false; btn.textContent = this.L(key); }, 5000);
      } else {
        armed = false;
        clearTimeout(timer);
        btn.textContent = this.L(key);
        action();
      }
    });
  }

  // ---------- Generate ----------
  buildGenerate(p) {
    this.head(p, "h_hazir");
    const pc = this.card(p);
    pc.classList.add("sp-presets");
    for (const [id, mats] of PRESETLER) {
      const b = el("button", "sp-preset", { type: "button" });
      b.append(this.t(el("span"), `p_${id}`));
      const strip = el("i", "sp-strip");
      for (const m of mats) strip.append(el("b", "", { style: `background:${rgb(m)}` }));
      b.append(strip);
      b.addEventListener("click", () => this.on.preset && this.on.preset(id));
      pc.append(b);
    }
    this.head(p, "h_bolge");
    const area = this.card(p);
    this.slider(area, "s_genislik", "boyutX", 128, 1024, 512, 32, " st");
    this.slider(area, "s_derinlik", "boyutZ", 128, 1024, 512, 32, " st");
    const centre = this.row(area, "s_merkez");
    centre.classList.add("sp-centre");
    this.number(centre, "merkezX", 0, 54); this.number(centre, "merkezY", 40, 54); this.number(centre, "merkezZ", 0, 54);
    this.head(p, "h_cekirdek");
    const seed = this.card(p);
    const sr = this.row(seed, "s_cekirdek");
    const dice = el("button", "sp-dice", { type: "button", "aria-label": "Random seed", text: "🎲" });
    dice.addEventListener("click", () => { this.d.cekirdek = Math.floor(Math.random() * 999999999) + 1; this.refresh(); });
    sr.append(dice);
    this.number(sr, "cekirdek", 618033988, 104);
    this.check(seed, "c_otozar", "otoZar", true);
    this.head(p, "h_biyom");
    const bc = this.card(p);
    for (const [id, key, on, w, mat] of BIYOMLAR) {
      const row = el("div", "sp-row sp-biome");
      row.append(el("i", "sp-swatch", { style: `background:${rgb(mat)}` }), this.t(el("span", "sp-label"), key));
      const wname = `bw_${id}`, bname = `b_${id}`;
      this.d[wname] = w;
      const weight = el("input", "sp-range sp-weight", { type: "range", min: 0.05, max: 1, step: 0.01, "aria-label": "weight" });
      weight.addEventListener("input", () => { this.d[wname] = Number(weight.value); paint(); });
      this.d[bname] = on;
      const box = el("button", "sp-check", { type: "button", role: "checkbox" });
      box.addEventListener("click", () => { this.d[bname] = !this.d[bname]; paint(); });
      const paint = () => {
        weight.value = this.d[wname];
        weight.style.setProperty("--f", `${((this.d[wname] - 0.05) / 0.95) * 100}%`);
        weight.classList.toggle("off", !this.d[bname]);
        box.classList.toggle("on", !!this.d[bname]);
        box.setAttribute("aria-checked", !!this.d[bname]);
      };
      this.refreshers.push(paint);
      paint();
      row.append(weight, box);
      bc.append(row);
    }
    this.head(p, "h_sekil");
    const sh = this.card(p);
    this.slider(sh, "s_yuk", "yukOlcek", 0.3, 2.5, 1.0, 0.05);
    this.slider(sh, "s_puruz", "puruz", 0, 1, 0.5, 0.05);
    this.slider(sh, "s_warp", "warp", 0, 1, 0.5, 0.05);
    this.slider(sh, "s_teras", "teras", 0, 1, 0, 0.05);
    this.slider(sh, "s_biyomBoyut", "biyomBoyut", 120, 900, 320, 20, " st");
    this.head(p, "h_su");
    const wc = this.card(p);
    this.slider(wc, "s_suSeviye", "suSeviye", -10, 20, 0, 1, " st");
    this.check(wc, "c_gol", "golEtkin", true);
    this.slider(wc, "s_golYog", "golYogunluk", 0, 1, 0.5, 0.05);
    this.slider(wc, "s_golDer", "golDerinlik", 3, 30, 10, 1, " st");
    this.slider(wc, "s_golKum", "golKum", 0, 16, 6, 1, " st");
    this.check(wc, "c_nehir", "nehirEtkin", false);
    this.slider(wc, "s_nehirAdet", "nehirAdet", 1, 5, 2, 1);
    this.slider(wc, "s_nehirGen", "nehirGen", 6, 40, 14, 1, " st");
    this.slider(wc, "s_nehirKivrim", "nehirKivrim", 0, 1, 0.6, 0.05);
    this.check(wc, "c_oky", "okyEtkin", false);
    this.d.okyYon = "bati";
    const dirs = el("div", "sp-seg");
    for (const y of ["bati", "dogu", "kuzey", "guney"]) {
      const b = this.t(el("button", "", { type: "button" }), `y_${y}`);
      b.addEventListener("click", () => { this.d.okyYon = y; this.refresh(); });
      this.refreshers.push(() => b.classList.toggle("on", this.d.okyYon === y));
      dirs.append(b);
    }
    wc.append(dirs);
    this.head(p, "h_magara");
    const cc = this.card(p);
    this.check(cc, "c_magara", "magEtkin", false);
    this.slider(cc, "s_magYog", "magYogunluk", 0, 1, 0.5, 0.05);
    this.slider(cc, "s_magBoyut", "magBoyut", 0, 1, 0.5, 0.05);
    this.slider(cc, "s_cikinti", "cikinti", 0, 1, 0.35, 0.05);
    this.slider(cc, "s_benek", "benek", 0, 1, 0.6, 0.05);
    this.slider(cc, "s_kar", "karCizgisi", 0.1, 1, 0.72, 0.02);
    this.genBtn = this.button(p, "b_uret", "go big");
    this.genBtn.addEventListener("click", () => this.on.generate && this.on.generate());
    const bar = el("div", "sp-bar");
    this.barFill = el("i");
    this.barText = el("span");
    bar.append(this.barFill, this.barText);
    p.append(bar);
  }

  settings() {
    const d = this.d;
    const biyomlar = {};
    for (const [id] of BIYOMLAR) if (d[`b_${id}`]) biyomlar[id] = d[`bw_${id}`];
    return {
      cekirdek: Math.floor(Number(d.cekirdek) || 42),
      merkez: [Number(d.merkezX) || 0, Number(d.merkezY) || 40, Number(d.merkezZ) || 0],
      boyutX: d.boyutX, boyutZ: d.boyutZ, yukOlcek: d.yukOlcek, puruz: d.puruz, warp: d.warp, teras: d.teras,
      biyomBoyut: d.biyomBoyut, biyomlar,
      su: {
        seviye: d.suSeviye,
        gol: { etkin: d.golEtkin, yogunluk: d.golYogunluk, derinlik: d.golDerinlik, kum: d.golKum },
        nehir: { etkin: d.nehirEtkin, adet: d.nehirAdet, genislik: d.nehirGen, kivrim: d.nehirKivrim, derinlik: 5 },
        okyanus: { etkin: d.okyEtkin, yon: d.okyYon, plaj: 40 },
      },
      magara: { etkin: d.magEtkin, yogunluk: d.magYogunluk, boyut: d.magBoyut },
      detay: { cikinti: d.cikinti, benek: d.benek, karCizgisi: d.karCizgisi },
    };
  }

  // same as api.presetUygula in src/Arayuz.lua
  preset(id) {
    const d = this.d;
    const keep = new Set(["boyutX", "boyutZ", "merkezX", "merkezY", "merkezZ", "cekirdek", "otoZar", "fircaYaricap", "dikeyPay"]);
    for (const [k, v] of Object.entries(this.defaults)) if (!keep.has(k) && !k.startsWith("yapi")) d[k] = v;
    for (const [b] of BIYOMLAR) d[`b_${b}`] = false;
    d.golEtkin = d.nehirEtkin = d.okyEtkin = d.magEtkin = false;
    const on = (list, weights) => list.forEach((b, i) => { d[`b_${b}`] = true; d[`bw_${b}`] = weights[i]; });
    if (id === "alp") { on(["dag", "tepe", "ova"], [1, 0.6, 0.5]); d.golEtkin = true; d.karCizgisi = 0.56; }
    else if (id === "nehir") { on(["ova", "tepe"], [1, 0.5]); d.golEtkin = d.nehirEtkin = true; d.nehirAdet = 2; }
    else if (id === "kanyon") { on(["kanyon", "col", "plato"], [1, 0.9, 0.6]); d.teras = 0.35; }
    else if (id === "volkan") { on(["volkan", "dag"], [1, 0.5]); d.magEtkin = true; }
    else if (id === "arktik") { on(["arktik", "dag"], [1, 0.5]); d.golEtkin = true; d.karCizgisi = 0.3; }
    else if (id === "bataklik") { on(["bataklik", "ova"], [1, 0.5]); d.golEtkin = d.nehirEtkin = true; }
    else if (id === "sahil") { on(["ova", "tepe", "col"], [1, 0.5, 0.4]); d.golEtkin = d.okyEtkin = true; }
    else {
      for (const [b] of BIYOMLAR) { d[`b_${b}`] = Math.random() > 0.45; d[`bw_${b}`] = Math.round((0.4 + Math.random() * 0.6) * 100) / 100; }
      d.b_ova = true; d.golEtkin = true; d.nehirEtkin = Math.random() > 0.5; d.magEtkin = Math.random() > 0.5;
    }
    this.refresh();
  }

  // ---------- Erase ----------
  buildErase(p) {
    this.head(p, "h_firca");
    const bc = this.card(p);
    this.slider(bc, "s_firca", "fircaYaricap", 4, 80, 16, 2, " st");
    bc.append(this.t(el("p", "sp-note"), "n_firca"));
    this.brushBtn = this.button(p, "b_fircaAc", "blue");
    this.brushBtn.addEventListener("click", () => this.on.brush && this.on.brush());
    this.head(p, "h_bolgeSil");
    const rc = this.card(p);
    this.slider(rc, "s_dikeyPay", "dikeyPay", 10, 200, 80, 5, " st");
    rc.append(this.t(el("p", "sp-note"), "n_bolge"));
    this.pickBtn = this.button(p, "b_secBasla", "blue");
    this.pickBtn.addEventListener("click", () => this.on.pick && this.on.pick());
    const del = this.button(p, "b_secSil", "red");
    del.addEventListener("click", () => this.on.eraseSelection && this.on.eraseSelection());
    this.head(p, "h_toptan");
    const last = this.button(p, "b_sonSil", "");
    last.addEventListener("click", () => this.on.eraseLast && this.on.eraseLast());
    const all = this.button(p, "b_hepsiSil", "red");
    this.twice(all, "b_hepsiSil", () => this.on.eraseAll && this.on.eraseAll());
  }

  // ---------- Structures ----------
  buildStructures(p) {
    this.head(p, "h_kutuphane");
    const fc = this.card(p);
    fc.classList.add("sp-filters");
    const cats = ["Hepsi", ...new Set(this.structures.map((s) => s.cat))];
    const order = ["Hepsi", "Mimari", "Maden", "Süs", "Alan", "Kalıntı", "Su", "Doğa", "Zemin"];
    cats.sort((a, b) => order.indexOf(a) - order.indexOf(b));
    this.filter = "Hepsi";
    const fbtn = {};
    for (const c of cats) {
      const b = el("button", "", { type: "button" });
      const name = () => (c === "Hepsi" ? this.L("f_hepsi") : this.lang === "tr" ? c : (this.structures.find((s) => s.cat === c) || {}).catEn || c);
      this.langRefreshers.push(() => { b.textContent = name(); });
      b.textContent = name();
      b.addEventListener("click", () => { this.filter = c; this.refresh(); });
      fbtn[c] = b;
      fc.append(b);
    }
    const grid = el("div", "sp-grid");
    const gc = this.card(p);
    gc.append(grid);
    this.selected = null;
    for (const s of this.structures) {
      const b = el("button", "sp-item", { type: "button" });
      const label = el("span");
      b.append(el("b", "", { text: s.icon }), label);
      this.langRefreshers.push(() => { label.textContent = this.lang === "tr" ? s.tr : s.en; });
      label.textContent = this.lang === "tr" ? s.tr : s.en;
      b.addEventListener("click", () => {
        this.selected = s.id;
        this.refresh();
        this.status(this.L(s.landform ? "st_seciliAlan" : "st_seciliYapi", this.lang === "tr" ? s.tr : s.en));
        if (this.on.structure) this.on.structure(s);
      });
      this.refreshers.push(() => {
        b.hidden = !(this.filter === "Hepsi" || this.filter === s.cat);
        b.classList.toggle("on", this.selected === s.id);
      });
      grid.append(b);
    }
    this.refreshers.push(() => { for (const [c, b] of Object.entries(fbtn)) b.classList.toggle("on", c === this.filter); });
    this.head(p, "h_ayarlar");
    const sc = this.card(p);
    this.slider(sc, "s_olcek", "yapiOlcek", 0.4, 3, 1, 0.05, "×");
    this.sampleNote = el("p", "sp-note");
    sc.append(this.sampleNote);
    this.d.yapiDonus = 0;
    const rot = el("div", "sp-seg sp-rot");
    sc.append(this.t(el("div", "sp-label sp-sub"), "s_donus"), rot);
    for (const deg of [0, 45, 90, 135, 180, 225, 270, 315]) {
      const b = el("button", "", { type: "button", text: `${deg}°` });
      b.addEventListener("click", () => { this.d.yapiDonus = deg; this.refresh(); });
      this.refreshers.push(() => b.classList.toggle("on", this.d.yapiDonus === deg));
      rot.append(b);
    }
    const front = this.button(p, "b_kamKur", "go");
    front.addEventListener("click", () => this.on.placeFront && this.on.placeFront());
    this.placeBtn = this.button(p, "b_tikla", "blue");
    this.placeBtn.addEventListener("click", () => this.on.place && this.on.place());
    const undo = this.button(p, "b_geriAl", "");
    undo.addEventListener("click", () => this.on.undoStructure && this.on.undoStructure());
    const all = this.button(p, "b_yapiSil", "red");
    this.twice(all, "b_yapiSil", () => this.on.removeStructures && this.on.removeStructures());
  }
}
