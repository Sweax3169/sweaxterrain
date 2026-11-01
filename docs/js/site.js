import { generate } from "./generator.js";
import { TerrainView } from "./view.js";
import { Panel, MATERIAL_RGB } from "./panel.js";

const WORLDS = [
  ["alp", 8927, ["Snow", "Rock", "Grass", "Water"]],
  ["nehir", 314159, ["Grass", "LeafyGrass", "Sand", "Water"]],
  ["kanyon", 77001, ["Sandstone", "Sand", "Rock", "Ground"]],
  ["volkan", 40404, ["Basalt", "Rock", "CrackedLava", "Basalt"]],
  ["arktik", 23571, ["Snow", "Glacier", "Ice", "Rock"]],
  ["bataklik", 662607, ["LeafyGrass", "Mud", "Ground", "Water"]],
  ["sahil", 141421, ["Grass", "Sand", "Water", "Water"]],
  ["karisik", 299792, ["Grass", "Sandstone", "Snow", "Basalt"]],
];
const BIOMES = ["ova", "tepe", "dag", "plato", "kanyon", "volkan", "col", "arktik", "bataklik"];

const TR = {
  "nav.try": "Dene", "nav.worlds": "Dünyalar", "nav.erase": "Silme", "nav.structures": "Yapılar", "nav.install": "Kurulum",
  "hero.lead": "Roblox Studio için bir eklenti: koca dünyalar üretir, araziyi fırçayla ya da kutuyla siler ve 54 hazır yapıyı tek tıkla yerleştirir.",
  "hero.download": "v1.0.0'ı indir", "hero.try": "Burada dene",
  "hero.small": "SweaxTerrain.rbxmx · Windows ve macOS'ta Roblox Studio · MIT lisansı",
  "facts.biomes": "biyom, ağırlıkla karışır", "facts.worlds": "hazır dünya", "facts.structures": "yapı ve arazi alanı", "facts.undo": "her adımı geri alır",
  "try.title": "Burada dene",
  "try.lead": "Bu, eklentinin paneli ve JavaScript'e taşınmış kendi üreticisi. Aynı tohum ve ayarlar Studio'dakiyle aynı dünyayı üretir.",
  "try.hint": "Döndürmek için sürükle · yakınlaşmak için tekerlek",
  "try.nogl": "Tarayıcında WebGL 2 kapalı olduğu için 3B görünüm açılamıyor.",
  "try.note": "Studio ile karşılaştırıldı: 22 dünyada (238.848 sütun) her yüzey yüksekliği, yüzey malzemesi ve su seviyesi aynı. Studio'da genişlik ve derinlik 2048 studa kadar çıkar; tarayıcı 1024'te durur.",
  "worlds.title": "Başlamak için sekiz dünya",
  "worlds.lead": "Her biri biyomları, suyu ve detayı senin yerine ayarlar. Dünyayı üret'e her basışta yeni bir tohum gelir, iki üretim aynı olmaz.",
  "worlds.open": "Denemede aç", "worlds.seed": "Tohum",
  "biomes.title": "Ağırlıkla karışan dokuz biyom",
  "biomes.lead": "Her biyom kendi yükseklik fonksiyonu. Birkaçını açınca bölgeleri birbirine akar; ağırlık o biyomun ne kadar yer kaplayacağını belirler.",
  "water.title": "Göller, nehirler, kıyı ve mağaralar",
  "water.rivers": "Nehirler", "water.riversText": "Beşe kadar, her birinin kendi genişliği ve kıvrımı var. Kıyıya kum yalnız gerçek su olan yerde gelir.",
  "water.coast": "Okyanus kenarı", "water.coastText": "Bir kenar seç. Kara, alanın yaklaşık üçte biri boyunca denize iner; kıyı boyunca kumsal oluşur.",
  "water.caves": "Mağaralar", "water.cavesText": "Yüzeyin en az 6 stud altında solucan tüneller. Görebilesin diye burada kesilerek açıldı.",
  "erase.title": "Çizer gibi sil",
  "erase.lead": "Silgi haritadaki her araziyi siler, yalnız Sweax Terrain'in yaptığını değil.",
  "erase.brush": "Fırça", "erase.brushText": "Fırçayı aç, tıkla ya da sürükle. Yarıçap 4 ile 80 stud arası; kırmızı küre nereyi sileceğini gösterir.",
  "erase.region": "Bölge", "erase.regionText": "İki köşeye tıkla, aradaki her şey gider; dikey payı sen belirlersin.",
  "erase.note": "Son üretilen bölgeyi ya da haritadaki tüm araziyi sil (o iki kez sorar). Ctrl+Z hepsini geri getirir.",
  "structures.title": "44 yapı, 10 arazi alanı",
  "structures.lead": "Düz parçalardan yapıldılar, yüklenecek bir şey yok. Yarı saydam önizleme fareyi izler ve zemine oturur; her kurulum kendi tohumunu alır, yosun, yıkıklık, ölçek ve dönüş senin elinde.",
  "how.title": "Nasıl çalışır",
  "how.s1": "Alan, Roblox arazi vokseli boyunda 4 studluk sütunlara bölünür.",
  "how.s2": "Birinci geçiş: her sütunun koordinatı domain warp ile bükülür, açık her biyom bir yükseklik verir ve ağırlıklar (bölgeler ayrışsın diye küpü alınarak) bunları karıştırır. Sonra göller, nehirler ve kıyı bu yükseklik haritasını oyar.",
  "how.s3": "Kumsal yalnız karanın gerçek suyla buluştuğu yere, kumsal genişliği kadar gelir.",
  "how.s4": "İkinci geçiş: malzeme her voksel için eğime, derinliğe, kar çizgisine ve beneklere göre seçilir; kaya çıkıntıları ve mağaralar doluluğu büker; sonra 24 × 24 sütunluk parçalar sırayla WriteVoxels'a gider, ilerleme çubuğu ve İptal düğmesiyle.",
  "how.s5": "Her üretim, silme ve yerleştirme bir ChangeHistory noktası koyar; Ctrl+Z Studio'daki her şeyde olduğu gibi çalışır.",
  "install.title": "Kurulum", "install.s1": "İndir:", "install.s2": "Studio eklenti klasörüne koy:",
  "install.s2b": "Klasörü Studio'da Plugins sekmesindeki Plugins Folder düğmesiyle de açabilirsin.",
  "install.s3": "Roblox Studio'yu kapatıp aç.",
  "install.s4": "Plugins sekmesinde Sweax Terrain'e tıkla. Panel Studio'nun dilini ve temasını izler; EN · TR düğmesi dili değiştirir.",
  "install.src": "Kaynaktan:",
  "faq.title": "Sorular",
  "faq.q1": "Var olan arazime dokunur mu?",
  "faq.a1": "Üretim yalnız belirlediğin alanı (ve üstündeki boşluğu) temizleyip yeniden yazar. Silgi yalnız gösterdiğin yeri siler. Gerisi kalır ve Ctrl+Z her adımı geri alır.",
  "faq.q2": "HTTP ya da asset gerekiyor mu?",
  "faq.a2": "Hayır. Hiçbir web isteği yapmaz ve yapılar düz parçalardan oluşur; yüklenecek ya da onaylanacak bir şey yok.",
  "faq.q3": "Dünya ne kadar büyük olabilir?",
  "faq.a3": "Bir üretimde 2048 × 2048 studa kadar. 512 × 512'lik bir dünya bir saniyeden çok daha kısa sürer; büyükler ilerleme gösterir ve iptal edilebilir.",
  "faq.q4": "Kurulan yapılar nereye gider?",
  "faq.a4": "Workspace'te SweaxYapilar adlı klasöre. Her modelde SweaxStructure ve SweaxSeed nitelikleri durur; birini sonra bulabilir ya da yeniden kurabilirsin.",
  "faq.q5": "Arkadaşımla paylaşabilir miyim?",
  "faq.a5": "Evet. .rbxmx dosyasını ya da bu sayfayı gönder. MIT lisanslı.",
};
const BIOME_TEXT = {
  en: {
    ova: "Low, gentle ground. Grass with leafy patches.",
    tepe: "Rolling hills; rock shows where slopes get steep.",
    dag: "Ridged noise, squared. Snow above the snow line.",
    plato: "Flat steps with short ramps between them.",
    kanyon: "A dry plateau cut by terraced, winding gorges.",
    volkan: "Separate cones, each with a crater and a lava lake.",
    col: "Long dune waves in sand and sandstone.",
    arktik: "U-shaped glacial valleys. Lakes freeze over.",
    bataklik: "Ground just under the water line: mud and pools.",
  },
  tr: {
    ova: "Alçak, yumuşak zemin. Yaprak lekeli çim.",
    tepe: "Dalgalı tepeler; yamaç dikleşince kaya görünür.",
    dag: "Sırtlı gürültünün karesi. Kar çizgisinin üstü kar.",
    plato: "Aralarında kısa rampalar olan düz basamaklar.",
    kanyon: "Teraslı, kıvrılan yarıklarla kesilmiş kuru plato.",
    volkan: "Ayrı ayrı koniler; her birinin tepesinde krater ve lav gölü.",
    col: "Kum ve kumtaşında uzun kumul dalgaları.",
    arktik: "U biçimli buzul vadileri. Göller donar.",
    bataklik: "Su seviyesinin hemen altında gezinen zemin: çamur ve gölcükler.",
  },
};

const MSG = {
  en: {
    landform: "Landforms carve terrain in Studio. The picture shows what %s makes; in the browser only structures can be placed.",
    sample: "In Studio every placement gets its own seed, moss and ruin. The browser places one sample of each.",
  },
  tr: {
    landform: "Arazi alanları Studio'da araziyi oyar. Resim %s'nin ne yaptığını gösteriyor; tarayıcıda yalnız yapılar kurulabilir.",
    sample: "Studio'da her kurulum kendi tohumunu, yosununu ve yıkıklığını alır. Tarayıcı her yapının bir örneğini kurar.",
  },
};
const $ = (s) => document.querySelector(s);
const EN = {};
document.querySelectorAll("[data-i18n]").forEach((n) => { EN[n.dataset.i18n] = n.textContent; });

let lang = (() => {
  try { const s = localStorage.getItem("sweaxterrain-lang"); if (s === "en" || s === "tr") return s; } catch { /* private mode */ }
  return (navigator.language || "").toLowerCase().startsWith("tr") ? "tr" : "en";
})();
const t = (k) => (lang === "tr" ? TR[k] : EN[k]) || EN[k] || k;

const [strings, structures] = await Promise.all([
  fetch("data/strings.json").then((r) => r.json()),
  fetch("data/structures.json").then((r) => r.json()),
]);
const S = (k) => strings[lang][k] || strings.en[k] || k;

// ---------------------------------------------------------------- galleries
function renderWorlds() {
  const grid = $("#worldGrid");
  grid.innerHTML = "";
  for (const [id, seed, mats] of WORLDS) {
    const f = document.createElement("figure");
    f.className = "world";
    f.innerHTML = `<div class="pic"><img src="media/world-${id}.webp" loading="lazy" width="1400" height="900" alt=""></div>
      <figcaption><span class="mats">${mats.map((m) => `<i style="background:rgb(${MATERIAL_RGB[m]})"></i>`).join("")}</span>
      <b>${S(`p_${id}`)}</b><span class="seed">${t("worlds.seed")} ${seed}</span><button type="button">${t("worlds.open")} →</button></figcaption>`;
    f.querySelector("img").alt = S(`p_${id}`);
    f.querySelector("button").addEventListener("click", () => openWorld(id, seed));
    grid.append(f);
  }
}

function renderBiomes() {
  const grid = $("#biomeGrid");
  grid.innerHTML = "";
  for (const b of BIOMES) {
    const f = document.createElement("figure");
    f.className = "biome";
    f.innerHTML = `<div class="pic"><img src="media/biome-${b}.webp" loading="lazy" width="900" height="640" alt=""></div>
      <figcaption><b>${S(`b_${b}`)}</b><span>${BIOME_TEXT[lang][b]}</span></figcaption>`;
    f.querySelector("img").alt = S(`b_${b}`);
    grid.append(f);
  }
}

let structFilter = "all";
function renderStructures() {
  const cats = ["all", ...new Set(structures.map((s) => s.cat))];
  const fl = $("#structFilters");
  fl.innerHTML = "";
  for (const c of cats) {
    const b = document.createElement("button");
    b.type = "button";
    b.textContent = c === "all" ? S("f_hepsi") : lang === "tr" ? c : structures.find((s) => s.cat === c).catEn;
    b.classList.toggle("on", c === structFilter);
    b.addEventListener("click", () => { structFilter = c; renderStructures(); });
    fl.append(b);
  }
  const grid = $("#structGrid");
  grid.innerHTML = "";
  for (const s of structures) {
    const f = document.createElement("figure");
    f.className = "struct";
    f.hidden = !(structFilter === "all" || structFilter === s.cat);
    const name = lang === "tr" ? s.tr : s.en;
    const cat = lang === "tr" ? s.cat : s.catEn;
    f.innerHTML = `<div class="pic"><img src="media/structures/${s.id}.webp" loading="lazy" width="520" height="520" alt=""></div><figcaption>${name}<span>${cat}</span></figcaption>`;
    f.querySelector("img").alt = name;
    grid.append(f);
  }
}

function applyLang() {
  document.documentElement.lang = lang;
  document.querySelectorAll("[data-i18n]").forEach((n) => { n.textContent = t(n.dataset.i18n); });
  $("#lang").innerHTML = lang === "en" ? "<b>EN</b> TR" : "EN <b>TR</b>";
  const dark = matchMedia("(prefers-color-scheme: dark)").matches;
  $("#arch").src = `art/architecture-${dark ? "dark" : "light"}-${lang}.svg`;
  renderWorlds();
  renderBiomes();
  renderStructures();
  if (panel) { panel.setLang(lang); panel.sampleNote.textContent = MSG[lang].sample; }
}

$("#lang").addEventListener("click", () => {
  lang = lang === "en" ? "tr" : "en";
  try { localStorage.setItem("sweaxterrain-lang", lang); } catch { /* ignore */ }
  applyLang();
});

// ---------------------------------------------------------------- demo
let panel = null;
const view = new TerrainView($("#view"));
panel = new Panel($("#panel"), strings, structures, lang);
applyLang();
if (!view.ok) $("#vpFallback").hidden = false;

let world = null;
let lastSettings = null;
const undo = [];
let placed = [];
const snapshot = () => {
  if (!view.g) return;
  undo.push([Float32Array.from(view.top), Float32Array.from(view.water), placed.slice()]);
  if (undo.length > 40) undo.shift();
};

function runGenerate() {
  const d = panel.d;
  if (d.otoZar) { d.cekirdek = Math.floor(Math.random() * 999999999) + 1; panel.refresh(); }
  const s = panel.settings();
  if (Object.keys(s.biyomlar).length === 0) { panel.status(panel.L("st_biyomSec"), true); return; }
  panel.genBtn.textContent = panel.L("b_uretiliyor");
  panel.progress(0.05, `5%  ${panel.L("i_yukseklik")}`);
  setTimeout(() => {
    world = generate(s);
    lastSettings = s;
    undo.length = 0;
    placed = [];
    view.setStructures(placed);
    view.setWorld(world);
    $("#seedLabel").textContent = `seed ${s.cekirdek}`;
    // reveal the parcels in the order the plugin writes them
    const total = Math.ceil(world.Nx / 24) * Math.ceil(world.Nz / 24);
    let k = 0;
    const step = () => {
      k += Math.max(1, Math.round(total / 30));
      view.reveal = k >= total ? Infinity : k;
      view.build();
      const f = Math.min(1, k / total);
      panel.progress(0.35 + 0.65 * f, `${Math.round((0.35 + 0.65 * f) * 100)}%  ${panel.L("i_voksel")}`);
      if (k < total) requestAnimationFrame(step);
      else {
        panel.genBtn.textContent = panel.L("b_uret");
        panel.progress(1, "");
        panel.status(panel.L("st_uretildi"));
      }
    };
    view.reveal = 0;
    requestAnimationFrame(step);
  }, 30);
}

function openWorld(id, seed, scroll = true) {
  panel.preset(id);
  panel.d.cekirdek = seed;
  panel.d.otoZar = false;
  panel.d.boyutX = panel.d.boyutZ = 512;
  panel.d.merkezX = panel.d.merkezZ = 0;
  panel.d.merkezY = 0;
  panel.refresh();
  panel.tab("uret");
  if (scroll) $("#try").scrollIntoView({ behavior: "smooth" });
  runGenerate();
}

// tools: brush, corner picking, structure placing
let tool = null;
let corners = [];
let boxSel = null;
const canvas = $("#view");
const setTool = (name) => {
  tool = name;
  canvas.classList.toggle("tool", !!tool);
  panel.brushBtn.textContent = panel.L(tool === "brush" ? "b_fircaKapat" : "b_fircaAc");
  panel.pickBtn.textContent = panel.L(tool === "pick" ? "b_secIptal" : "b_secBasla");
  panel.placeBtn.textContent = panel.L(tool === "place" ? "b_tiklaKapat" : "b_tikla");
  if (tool !== "brush") view.setBall(null);
  if (tool !== "place") view.setGhost(null);
};

let painting = false;
view.onTool = (kind, e) => {
  if (!tool) return false;
  const p = view.pick(e.clientX, e.clientY);
  if (tool === "brush") {
    const r = panel.d.fircaYaricap;
    if (kind === "leave") { view.setBall(null); return true; }
    if (p) view.setBall(p, r);
    if (kind === "down" && p) { painting = true; snapshot(); view.carve(p, r); }
    else if (kind === "move" && painting && p) view.carve(p, r);
    else if (kind === "up") painting = false;
    return kind !== "leave";
  }
  if (tool === "place") {
    if (kind === "leave") { view.setGhost(null); return true; }
    if (!p || !current) return kind === "down";
    const s = { rows: current.rows, pos: p, rot: panel.d.yapiDonus, scale: panel.d.yapiOlcek };
    if (kind === "down") {
      if (e.shiftKey) { panel.d.yapiDonus = (panel.d.yapiDonus + 45) % 360; panel.refresh(); s.rot = panel.d.yapiDonus; }
      snapshot();
      placed = [...placed, s];
      view.setStructures(placed);
      panel.status(panel.L("st_kuruldu", structName(current.s)));
    } else view.setGhost(s);
    return true;
  }
  if (tool === "pick" && kind === "down" && p) {
    corners.push(p);
    if (corners.length === 1) { panel.status(panel.L("st_kose2")); view.setBall(p, 4); }
    else {
      const pay = panel.d.dikeyPay, [a, b] = corners;
      boxSel = [[Math.min(a[0], b[0]), Math.min(a[1], b[1]) - pay, Math.min(a[2], b[2])], [Math.max(a[0], b[0]), Math.max(a[1], b[1]) + pay, Math.max(a[2], b[2])]];
      view.setBall(null);
      view.setBox(boxSel[0], boxSel[1]);
      panel.status(panel.L("st_secimHazir"));
      corners = [];
      setTool(null);
    }
    return true;
  }
  return kind === "down";
};

panel.on.generate = runGenerate;
panel.on.preset = (id) => { panel.preset(id); panel.status(panel.L("st_preset", panel.L(`p_${id}`))); };
panel.on.brush = () => {
  if (tool === "brush") { setTool(null); panel.status(panel.L("st_fircaKapandi")); return; }
  setTool("brush");
  panel.status(panel.L("st_fircaAcik"));
};
panel.on.pick = () => {
  if (tool === "pick") { setTool(null); corners = []; view.setBall(null); panel.status(panel.L("st_secimIptal")); return; }
  corners = []; boxSel = null; view.setBox(null);
  setTool("pick");
  panel.status(panel.L("st_kose1"));
};
panel.on.eraseSelection = () => {
  if (!boxSel) { panel.status(panel.L("st_onceKose"), true); return; }
  snapshot();
  view.eraseBox(boxSel[0], boxSel[1]);
  panel.status(panel.L("st_secimSilindi", Math.floor(boxSel[1][0] - boxSel[0][0]), Math.floor(boxSel[1][2] - boxSel[0][2])));
  boxSel = null;
  view.setBox(null);
};
const clearAll = (key) => {
  if (!view.g) { panel.status(panel.L("st_sonYok")); return; }
  snapshot();
  view.top.fill(NaN); view.water.fill(NaN); view.build();
  panel.status(panel.L(key));
};
panel.on.eraseLast = () => clearAll("st_sonSilindi");
panel.on.eraseAll = () => clearAll("st_hepsiSilindi");
panel.on.tab = (id) => {
  if (tool && !((tool === "brush" || tool === "pick") && id === "sil") && !(tool === "place" && id === "yapi")) setTool(null);
  $("#vpStruct").hidden = id !== "yapi" || !panel.selected;
};
const structName = (s) => (lang === "tr" ? s.tr : s.en);
let current = null;
const partsCache = new Map();
async function loadParts(s) {
  if (!partsCache.has(s.id)) partsCache.set(s.id, fetch(`data/parts/${s.id}.json`).then((r) => r.json()));
  return partsCache.get(s.id);
}
panel.on.structure = async (s) => {
  const box = $("#vpStruct");
  box.hidden = false;
  box.querySelector("img").src = `media/structures/${s.id}.webp`;
  box.querySelector("figcaption").textContent = structName(s);
  if (s.landform) {
    current = null;
    if (tool === "place") setTool(null);
    panel.status(MSG[lang].landform.replace("%s", structName(s)));
    return;
  }
  current = { s, rows: await loadParts(s) };
};
panel.on.place = () => {
  if (tool === "place") { setTool(null); view.setGhost(null); panel.status(panel.L("st_yerlestirmeKapandi")); return; }
  if (!current) { panel.status(panel.selected ? MSG[lang].landform.replace("%s", panel.L("tab_yapi")) : panel.L("st_onceYapi"), true); return; }
  setTool("place");
  panel.status(panel.L("st_tiklaKur"));
};
panel.on.placeFront = () => {
  if (!current || !view.g) { panel.status(panel.L("st_onceYapi"), true); return; }
  const r = canvas.getBoundingClientRect();
  const p = view.pick(r.left + r.width / 2, r.top + r.height * 0.55);
  if (!p) return;
  snapshot();
  placed = [...placed, { rows: current.rows, pos: p, rot: panel.d.yapiDonus, scale: panel.d.yapiOlcek }];
  view.setStructures(placed);
  panel.status(panel.L("st_kurulduKamera", structName(current.s)));
};
panel.on.undoStructure = () => {
  if (!placed.length) { panel.status(panel.L("st_geriYok")); return; }
  snapshot();
  placed = placed.slice(0, -1);
  view.setStructures(placed);
  panel.status(panel.L("st_geriAlindi", ""));
};
panel.on.removeStructures = () => {
  const n = placed.length;
  snapshot();
  placed = [];
  view.setStructures(placed);
  panel.status(panel.L("st_yapiSilindi", n));
};

// Ctrl+Z, like Studio: every brush stroke, erase and placement is one step
document.addEventListener("keydown", (e) => {
  if (!((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "z") || !undo.length) return;
  const r = canvas.getBoundingClientRect();
  if (r.bottom < 0 || r.top > innerHeight) return;
  e.preventDefault();
  const [top, water, p] = undo.pop();
  view.top = top; view.water = water; placed = p;
  view.setStructures(placed);
  view.build();
});

window.__sweax = { view, panel, generate }; // handy in the console

// first world: the same Alpine world as the render above it
openWorld("alp", 8927, false);
